/*
 * The HNSW build happens in two phases:
 *
 * 1. In-memory phase
 *
 * In this first phase, the graph is held completely in memory. When the graph
 * is fully built, or we run out of memory reserved for the build (determined
 * by maintenance_work_mem), we materialize the graph to disk (see
 * FlushPages()), and switch to the on-disk phase.
 *
 * In a parallel build, a large contiguous chunk of shared memory is allocated
 * to hold the graph. Each worker process has its own HnswBuildState struct in
 * private memory, which contains information that doesn't change throughout
 * the build, and pointers to the shared structs in shared memory. The shared
 * memory area is mapped to a different address in each worker process, and
 * 'HnswBuildState.hnswarea' points to the beginning of the shared area in the
 * worker process's address space. All pointers used in the graph are
 * "relative pointers", stored as an offset from 'hnswarea'.
 *
 * Each element is protected by an LWLock. It must be held when reading or
 * modifying the element's neighbors or 'heaptids'.
 *
 * In a non-parallel build, the graph is held in backend-private memory. All
 * the elements are allocated in a dedicated memory context, 'graphCtx', and
 * the pointers used in the graph are regular pointers.
 *
 * 2. On-disk phase
 *
 * In the on-disk phase, the index is built by inserting each vector to the
 * index one by one, just like on INSERT. The only difference is that we don't
 * WAL-log the individual inserts. If the graph fit completely in memory and
 * was fully built in the in-memory phase, the on-disk phase is skipped.
 *
 * After we have finished building the graph, we perform one more scan through
 * the index and write all the pages to the WAL.
 */
#include "postgres.h"

#include "access/genam.h"
#include "access/parallel.h"
#include "access/relscan.h"
#include "access/table.h"
#include "access/tableam.h"
#include "access/tupdesc.h"
#include "access/xact.h"
#include "access/xloginsert.h"
#include "catalog/index.h"
#include "catalog/pg_type_d.h"
#include "commands/progress.h"
#include "hnsw.h"
#include "miscadmin.h"
#include "nodes/execnodes.h"
#include "optimizer/optimizer.h"
#include "rust_ffi.h"
#include "storage/bufmgr.h"
#include "tcop/tcopprot.h"
#include "utils/datum.h"
#include "utils/memutils.h"
#include "utils/rel.h"
#include "utils/snapmgr.h"

#if PG_VERSION_NUM >= 160000
#include "varatt.h"
#endif

#if PG_VERSION_NUM >= 140000
#include "utils/backend_progress.h"
#else
#include "pgstat.h"
#endif

#if PG_VERSION_NUM >= 140000
#include "utils/backend_status.h"
#include "utils/wait_event.h"
#endif

#define PARALLEL_KEY_HNSW_SHARED		UINT64CONST(0xA000000000000001)
#define PARALLEL_KEY_HNSW_AREA			UINT64CONST(0xA000000000000002)
#define PARALLEL_KEY_QUERY_TEXT			UINT64CONST(0xA000000000000003)

static bool HnswShouldFallbackWithoutWorkers(int workersLaunched, bool useRust);
static bool HnswShouldLeaderParticipate(bool leaderParticipates, bool useRust);
static bool HnswShouldUseDebugQueryString(bool hasDebugQueryString, bool useRust);
static bool HnswShouldHaveDebugQueryString(const char *debugQueryString, bool useRust);
static bool HnswShouldUseNonConcurrentSnapshot(bool isConcurrent, bool useRust);
static bool HnswShouldUseNonConcurrentLockModes(bool isConcurrent, bool useRust);
static bool HnswShouldFallbackWithoutDsmSegment(bool hasDsmSegment, bool useRust);
static bool HnswShouldReserveGraphMemory(int64 estHnswArea, int64 estOther, bool useRust);
static bool HnswShouldLogLeaderProgress(bool progressIsLeader, bool useRust);
static bool HnswShouldRejectVarbitType(Oid typeOid, bool useRust);
static bool HnswShouldRejectMissingDimensions(int32 dimensions, bool useRust);
static bool HnswShouldRejectExcessDimensions(int32 dimensions, int32 maxDimensions, bool useRust);
static bool HnswShouldRejectLowEfConstruction(int32 efConstruction, int32 m, bool useRust);
static bool HnswShouldTreatForkAsInit(int32 forkNum, bool useRust);
static bool HnswShouldWriteWalPage(bool needsWal, bool isInitFork, bool useRust);
static bool HnswShouldSkipNullBuildTuple(bool isNull, bool useRust);
static bool HnswShouldUpdateProgressAfterInsert(bool tupleInserted, bool useRust);
static bool HnswShouldStoreNeighborsOnSamePage(int64 combinedSize, int64 maxSize, bool useRust);
static bool HnswShouldRejectOversizedElementTuple(int64 tupleSize, int64 allocSize, bool useRust);
static bool HnswShouldAppendNeighborPage(int64 freeSpace, int64 neighborTupleSize, bool useRust);
static bool HnswShouldAppendElementPage(int64 freeSpace, int64 elementTupleSize, int64 combinedSize, int64 maxSize, bool useRust);
static bool HnswShouldRejectUnexpectedItemOffset(int32 insertedOffset, int32 expectedOffset, bool useRust);
static bool HnswShouldRejectNeighborOverwrite(bool overwriteSucceeded, bool useRust);
static bool HnswShouldUnregisterMVCCSnapshot(bool snapshotIsMVCC, bool useRust);
static bool HnswShouldFinishParallelHeapScan(int participantsDone, int participantCount, bool useRust);
static bool HnswShouldRejectInMemoryDuplicateHeapTid(int32 heaptidsLength, int32 maxHeaptids, bool useRust);

/*
 * Create the metapage
 */
static void
CreateMetaPage(HnswBuildState * buildstate)
{
	Relation	index = buildstate->index;
	ForkNumber	forkNum = buildstate->forkNum;
	Buffer		buf;
	Page		page;
	HnswMetaPage metap;

	buf = HnswNewBuffer(index, forkNum);
	page = BufferGetPage(buf);
	HnswInitPage(buf, page);

	/* Set metapage data */
	metap = HnswPageGetMeta(page);
	metap->magicNumber = HNSW_MAGIC_NUMBER;
	metap->version = HNSW_VERSION;
	metap->dimensions = buildstate->dimensions;
	metap->m = buildstate->m;
	metap->efConstruction = buildstate->efConstruction;
	metap->entryBlkno = InvalidBlockNumber;
	metap->entryOffno = InvalidOffsetNumber;
	metap->entryLevel = -1;
	metap->insertPage = InvalidBlockNumber;
	((PageHeader) page)->pd_lower =
		((char *) metap + sizeof(HnswMetaPageData)) - (char *) page;

	MarkBufferDirty(buf);
	UnlockReleaseBuffer(buf);
}

/*
 * Add a new page
 */
static void
HnswBuildAppendPage(Relation index, Buffer *buf, Page *page, ForkNumber forkNum)
{
	/* Add a new page */
	Buffer		newbuf = HnswNewBuffer(index, forkNum);

	/* Update previous page */
	HnswPageGetOpaque(*page)->nextblkno = BufferGetBlockNumber(newbuf);

	/* Commit */
	MarkBufferDirty(*buf);
	UnlockReleaseBuffer(*buf);

	/* Can take a while, so ensure we can interrupt */
	/* Needs to be called when no buffer locks are held */
	LockBuffer(newbuf, BUFFER_LOCK_UNLOCK);
	CHECK_FOR_INTERRUPTS();
	LockBuffer(newbuf, BUFFER_LOCK_EXCLUSIVE);

	/* Prepare new page */
	*buf = newbuf;
	*page = BufferGetPage(*buf);
	HnswInitPage(*buf, *page);
}

/*
 * Create graph pages
 */
static void
CreateGraphPages(HnswBuildState * buildstate)
{
	Relation	index = buildstate->index;
	ForkNumber	forkNum = buildstate->forkNum;
	Size		maxSize;
	HnswElementTuple etup;
	HnswNeighborTuple ntup;
	BlockNumber insertPage;
	HnswElement entryPoint;
	Buffer		buf;
	Page		page;
	HnswElementPtr iter = buildstate->graph->head;
	char	   *base = buildstate->hnswarea;

	/* Calculate sizes */
	maxSize = HNSW_MAX_SIZE;

	/* Allocate once */
	etup = palloc0(HNSW_TUPLE_ALLOC_SIZE);
	ntup = palloc0(HNSW_TUPLE_ALLOC_SIZE);

	/* Prepare first page */
	buf = HnswNewBuffer(index, forkNum);
	page = BufferGetPage(buf);
	HnswInitPage(buf, page);

	while (!HnswPtrIsNull(base, iter))
	{
		HnswElement element = HnswPtrAccess(base, iter);
		Size		etupSize;
		Size		ntupSize;
		Size		combinedSize;
		Pointer		valuePtr = HnswPtrAccess(base, element->value);

		/* Update iterator */
		iter = element->next;

		/* Zero memory for each element */
		MemSet(etup, 0, HNSW_TUPLE_ALLOC_SIZE);

		/* Calculate sizes */
		etupSize = HNSW_ELEMENT_TUPLE_SIZE(VARSIZE_ANY(valuePtr));
		ntupSize = HNSW_NEIGHBOR_TUPLE_SIZE(element->level, buildstate->m);
		combinedSize = etupSize + ntupSize + sizeof(ItemIdData);

		/* Initial size check */
		if (HnswShouldRejectOversizedElementTuple((int64) etupSize, (int64) HNSW_TUPLE_ALLOC_SIZE, true))
			ereport(ERROR,
					(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
					 errmsg("index tuple too large")));

		HnswSetElementTuple(base, etup, element);

		/* Keep element and neighbors on the same page if possible */
		if (HnswShouldAppendElementPage((int64) PageGetFreeSpace(page), (int64) etupSize, (int64) combinedSize, (int64) maxSize, true))
			HnswBuildAppendPage(index, &buf, &page, forkNum);

		/* Calculate offsets */
		element->blkno = BufferGetBlockNumber(buf);
		element->offno = OffsetNumberNext(PageGetMaxOffsetNumber(page));
		if (HnswShouldStoreNeighborsOnSamePage((int64) combinedSize, (int64) maxSize, true))
		{
			element->neighborPage = element->blkno;
			element->neighborOffno = OffsetNumberNext(element->offno);
		}
		else
		{
			element->neighborPage = element->blkno + 1;
			element->neighborOffno = FirstOffsetNumber;
		}

		ItemPointerSet(&etup->neighbortid, element->neighborPage, element->neighborOffno);

		/* Add element */
		if (HnswShouldRejectUnexpectedItemOffset((int32) PageAddItem(page, (Item) etup, etupSize, InvalidOffsetNumber, false, false), (int32) element->offno, true))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));

		/* Add new page if needed */
		if (HnswShouldAppendNeighborPage((int64) PageGetFreeSpace(page), (int64) ntupSize, true))
			HnswBuildAppendPage(index, &buf, &page, forkNum);

		/* Add placeholder for neighbors */
		if (HnswShouldRejectUnexpectedItemOffset((int32) PageAddItem(page, (Item) ntup, ntupSize, InvalidOffsetNumber, false, false), (int32) element->neighborOffno, true))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));
	}

	insertPage = BufferGetBlockNumber(buf);

	/* Commit */
	MarkBufferDirty(buf);
	UnlockReleaseBuffer(buf);

	entryPoint = HnswPtrAccess(base, buildstate->graph->entryPoint);
	HnswUpdateMetaPage(index, HNSW_UPDATE_ENTRY_ALWAYS, entryPoint, insertPage, forkNum, true);

	pfree(etup);
	pfree(ntup);
}

/*
 * Write neighbor tuples
 */
static void
WriteNeighborTuples(HnswBuildState * buildstate)
{
	Relation	index = buildstate->index;
	ForkNumber	forkNum = buildstate->forkNum;
	int			m = buildstate->m;
	HnswElementPtr iter = buildstate->graph->head;
	char	   *base = buildstate->hnswarea;
	HnswNeighborTuple ntup;

	/* Allocate once */
	ntup = palloc0(HNSW_TUPLE_ALLOC_SIZE);

	while (!HnswPtrIsNull(base, iter))
	{
		HnswElement element = HnswPtrAccess(base, iter);
		Buffer		buf;
		Page		page;
		Size		ntupSize = HNSW_NEIGHBOR_TUPLE_SIZE(element->level, m);

		/* Update iterator */
		iter = element->next;

		/* Zero memory for each element */
		MemSet(ntup, 0, HNSW_TUPLE_ALLOC_SIZE);

		/* Can take a while, so ensure we can interrupt */
		/* Needs to be called when no buffer locks are held */
		CHECK_FOR_INTERRUPTS();

		buf = ReadBufferExtended(index, forkNum, element->neighborPage, RBM_NORMAL, NULL);
		LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
		page = BufferGetPage(buf);

		HnswSetNeighborTuple(base, ntup, element, m);

		if (HnswShouldRejectNeighborOverwrite(PageIndexTupleOverwrite(page, element->neighborOffno, (Item) ntup, ntupSize), true))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));

		/* Commit */
		MarkBufferDirty(buf);
		UnlockReleaseBuffer(buf);
	}

	pfree(ntup);
}

/*
 * Flush pages
 */
static void
FlushPages(HnswBuildState * buildstate)
{
#ifdef HNSW_MEMORY
	elog(INFO, "memory: %zu MB", buildstate->graph->memoryUsed / (1024 * 1024));
#endif

	CreateMetaPage(buildstate);
	CreateGraphPages(buildstate);
	WriteNeighborTuples(buildstate);

	buildstate->graph->flushed = true;
	MemoryContextReset(buildstate->graphCtx);
}

static bool
HnswCanAddDuplicateHeapTid(int heaptidsLength, int maxHeaptids, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_can_add_duplicate_heap_tid_kernel(heaptidsLength, maxHeaptids);

	return heaptidsLength < maxHeaptids;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_can_add_duplicate_heap_tid);
Datum
vector_hnsw_can_add_duplicate_heap_tid(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswCanAddDuplicateHeapTid(heaptidsLength, maxHeaptids, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_can_add_duplicate_heap_tid);
Datum
vector_rust_hnsw_can_add_duplicate_heap_tid(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswCanAddDuplicateHeapTid(heaptidsLength, maxHeaptids, true));
}

static bool
HnswShouldStopDuplicateSearchOnValueMismatch(bool valuesEqual, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_stop_duplicate_search_on_value_mismatch_kernel(valuesEqual);

	return !valuesEqual;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_duplicate_search_on_value_mismatch);
Datum
vector_hnsw_should_stop_duplicate_search_on_value_mismatch(PG_FUNCTION_ARGS)
{
	int32		valuesEqual = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopDuplicateSearchOnValueMismatch(valuesEqual != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_duplicate_search_on_value_mismatch);
Datum
vector_rust_hnsw_should_stop_duplicate_search_on_value_mismatch(PG_FUNCTION_ARGS)
{
	int32		valuesEqual = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopDuplicateSearchOnValueMismatch(valuesEqual != 0, true));
}

static bool
HnswShouldReturnAfterDuplicateInsert(bool duplicateInserted, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_return_after_duplicate_insert_kernel(duplicateInserted);

	return duplicateInserted;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_after_duplicate_insert);
Datum
vector_hnsw_should_return_after_duplicate_insert(PG_FUNCTION_ARGS)
{
	int32		duplicateInserted = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnAfterDuplicateInsert(duplicateInserted != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_after_duplicate_insert);
Datum
vector_rust_hnsw_should_return_after_duplicate_insert(PG_FUNCTION_ARGS)
{
	int32		duplicateInserted = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnAfterDuplicateInsert(duplicateInserted != 0, true));
}

static bool
HnswShouldSkipUpdateGraphForDuplicate(bool duplicateFound, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_update_graph_for_duplicate_kernel(duplicateFound);

	return duplicateFound;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_update_graph_for_duplicate);
Datum
vector_hnsw_should_skip_update_graph_for_duplicate(PG_FUNCTION_ARGS)
{
	int32		duplicateFound = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipUpdateGraphForDuplicate(duplicateFound != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_update_graph_for_duplicate);
Datum
vector_rust_hnsw_should_skip_update_graph_for_duplicate(PG_FUNCTION_ARGS)
{
	int32		duplicateFound = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipUpdateGraphForDuplicate(duplicateFound != 0, true));
}

static bool
HnswShouldFlushGraph(Size memoryUsed, Size memoryTotal, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_flush_graph_kernel((int64) memoryUsed, (int64) memoryTotal);

	return memoryUsed >= memoryTotal;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_flush_graph);
Datum
vector_hnsw_should_flush_graph(PG_FUNCTION_ARGS)
{
	int64		memoryUsed = PG_GETARG_INT64(0);
	int64		memoryTotal = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldFlushGraph((Size) memoryUsed, (Size) memoryTotal, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_flush_graph);
Datum
vector_rust_hnsw_should_flush_graph(PG_FUNCTION_ARGS)
{
	int64		memoryUsed = PG_GETARG_INT64(0);
	int64		memoryTotal = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldFlushGraph((Size) memoryUsed, (Size) memoryTotal, true));
}

static bool
HnswShouldUseOnDiskPhase(bool graphFlushed, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_use_ondisk_phase_kernel(graphFlushed);

	return graphFlushed;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_ondisk_phase);
Datum
vector_hnsw_should_use_ondisk_phase(PG_FUNCTION_ARGS)
{
	int32		graphFlushed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseOnDiskPhase(graphFlushed != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_ondisk_phase);
Datum
vector_rust_hnsw_should_use_ondisk_phase(PG_FUNCTION_ARGS)
{
	int32		graphFlushed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseOnDiskPhase(graphFlushed != 0, true));
}

static bool
HnswShouldSkipInvalidIndexValue(bool indexValueFormed, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(indexValueFormed);

	return !indexValueFormed;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_invalid_index_value);
Datum
vector_hnsw_should_skip_invalid_index_value(PG_FUNCTION_ARGS)
{
	int32		indexValueFormed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipInvalidIndexValue(indexValueFormed != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_invalid_index_value);
Datum
vector_rust_hnsw_should_skip_invalid_index_value(PG_FUNCTION_ARGS)
{
	int32		indexValueFormed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipInvalidIndexValue(indexValueFormed != 0, true));
}

static bool
HnswShouldUpdateEntryPoint(bool entryPointIsNull, int elementLevel, int entryLevel, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_entry_point_kernel(entryPointIsNull, elementLevel, entryLevel);

	return entryPointIsNull || elementLevel > entryLevel;
}

static bool
HnswShouldUseDefaultEntryLevel(bool hasEntryPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasEntryPoint);

	return !hasEntryPoint;
}

static int
HnswGetEntryLevelForUpdate(HnswElement entryPoint, bool useRust)
{
	if (HnswShouldUseDefaultEntryLevel(entryPoint != NULL, useRust))
		return -1;

	return entryPoint->level;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_entry_point);
Datum
vector_hnsw_should_update_entry_point(PG_FUNCTION_ARGS)
{
	int32		entryPointIsNull = PG_GETARG_INT32(0);
	int32		elementLevel = PG_GETARG_INT32(1);
	int32		entryLevel = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldUpdateEntryPoint(entryPointIsNull != 0, elementLevel, entryLevel, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_entry_point);
Datum
vector_rust_hnsw_should_update_entry_point(PG_FUNCTION_ARGS)
{
	int32		entryPointIsNull = PG_GETARG_INT32(0);
	int32		elementLevel = PG_GETARG_INT32(1);
	int32		entryLevel = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldUpdateEntryPoint(entryPointIsNull != 0, elementLevel, entryLevel, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_default_entry_level);
Datum
vector_hnsw_should_use_default_entry_level(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultEntryLevel(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_default_entry_level);
Datum
vector_rust_hnsw_should_use_default_entry_level(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultEntryLevel(hasEntryPoint != 0, true));
}

static bool
HnswShouldFlushPagesInBuild(bool graphFlushed, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_flush_pages_in_build_kernel(graphFlushed);

	return !graphFlushed;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_flush_pages_in_build);
Datum
vector_hnsw_should_flush_pages_in_build(PG_FUNCTION_ARGS)
{
	int32		graphFlushed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFlushPagesInBuild(graphFlushed != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_flush_pages_in_build);
Datum
vector_rust_hnsw_should_flush_pages_in_build(PG_FUNCTION_ARGS)
{
	int32		graphFlushed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFlushPagesInBuild(graphFlushed != 0, true));
}

static bool
HnswShouldFlushGraphPagesAtEnd(bool graphFlushed, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_flush_graph_pages_at_end_kernel(graphFlushed);

	return !graphFlushed;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_flush_graph_pages_at_end);
Datum
vector_hnsw_should_flush_graph_pages_at_end(PG_FUNCTION_ARGS)
{
	int32		graphFlushed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFlushGraphPagesAtEnd(graphFlushed != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_flush_graph_pages_at_end);
Datum
vector_rust_hnsw_should_flush_graph_pages_at_end(PG_FUNCTION_ARGS)
{
	int32		graphFlushed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFlushGraphPagesAtEnd(graphFlushed != 0, true));
}

static bool
HnswShouldBeginParallelBuild(int parallelWorkers, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_begin_parallel_build_kernel(parallelWorkers);

	return parallelWorkers > 0;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_begin_parallel_build);
Datum
vector_hnsw_should_begin_parallel_build(PG_FUNCTION_ARGS)
{
	int32		parallelWorkers = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldBeginParallelBuild(parallelWorkers, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_begin_parallel_build);
Datum
vector_rust_hnsw_should_begin_parallel_build(PG_FUNCTION_ARGS)
{
	int32		parallelWorkers = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldBeginParallelBuild(parallelWorkers, true));
}

static bool
HnswShouldEndParallelBuild(bool hasLeader, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_end_parallel_build_kernel(hasLeader);

	return hasLeader;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_end_parallel_build);
Datum
vector_hnsw_should_end_parallel_build(PG_FUNCTION_ARGS)
{
	int32		hasLeader = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldEndParallelBuild(hasLeader != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_end_parallel_build);
Datum
vector_rust_hnsw_should_end_parallel_build(PG_FUNCTION_ARGS)
{
	int32		hasLeader = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldEndParallelBuild(hasLeader != 0, true));
}

static bool
HnswShouldScanHeapForBuild(bool hasHeap, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_scan_heap_for_build_kernel(hasHeap);

	return hasHeap;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_scan_heap_for_build);
Datum
vector_hnsw_should_scan_heap_for_build(PG_FUNCTION_ARGS)
{
	int32		hasHeap = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldScanHeapForBuild(hasHeap != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_scan_heap_for_build);
Datum
vector_rust_hnsw_should_scan_heap_for_build(PG_FUNCTION_ARGS)
{
	int32		hasHeap = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldScanHeapForBuild(hasHeap != 0, true));
}

static bool
HnswShouldUseParallelHeapScan(bool hasLeader, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_use_parallel_heap_scan_kernel(hasLeader);

	return hasLeader;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_parallel_heap_scan);
Datum
vector_hnsw_should_use_parallel_heap_scan(PG_FUNCTION_ARGS)
{
	int32		hasLeader = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseParallelHeapScan(hasLeader != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_parallel_heap_scan);
Datum
vector_rust_hnsw_should_use_parallel_heap_scan(PG_FUNCTION_ARGS)
{
	int32		hasLeader = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseParallelHeapScan(hasLeader != 0, true));
}

static bool
HnswShouldRejectInMemoryDuplicateHeapTid(int32 heaptidsLength, int32 maxHeaptids, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_can_add_duplicate_heap_tid_kernel(heaptidsLength, maxHeaptids);

	return heaptidsLength >= maxHeaptids;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_inmemory_duplicate_heaptid);
Datum
vector_hnsw_should_reject_inmemory_duplicate_heaptid(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectInMemoryDuplicateHeapTid(heaptidsLength, maxHeaptids, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_inmemory_duplicate_heaptid);
Datum
vector_rust_hnsw_should_reject_inmemory_duplicate_heaptid(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectInMemoryDuplicateHeapTid(heaptidsLength, maxHeaptids, true));
}

/*
 * Add a heap TID to an existing element
 */
static bool
AddDuplicateInMemory(HnswElement element, HnswElement dup)
{
	LWLockAcquire(&dup->lock, LW_EXCLUSIVE);

	if (HnswShouldRejectInMemoryDuplicateHeapTid(dup->heaptidsLength, HNSW_HEAPTIDS, true))
	{
		LWLockRelease(&dup->lock);
		return false;
	}

	HnswAddHeapTid(dup, &element->heaptids[0]);

	LWLockRelease(&dup->lock);

	return true;
}

/*
 * Find duplicate element
 */
static bool
FindDuplicateInMemory(char *base, HnswElement element)
{
	HnswNeighborArray *neighbors = HnswGetNeighbors(base, element, 0);
	Datum		value = HnswGetValue(base, element);

	for (int i = 0; i < neighbors->length; i++)
	{
		HnswCandidate *neighbor = &neighbors->items[i];
		HnswElement neighborElement = HnswPtrAccess(base, neighbor->element);
		Datum		neighborValue = HnswGetValue(base, neighborElement);

		/* Exit early since ordered by distance */
		if (HnswShouldStopDuplicateSearchOnValueMismatch(datumIsEqual(value, neighborValue, false, -1), true))
			return false;

		/* Check for space */
		if (HnswShouldReturnAfterDuplicateInsert(AddDuplicateInMemory(element, neighborElement), true))
			return true;
	}

	return false;
}

/*
 * Add to element list
 */
static void
AddElementInMemory(char *base, HnswGraph * graph, HnswElement element)
{
	SpinLockAcquire(&graph->lock);
	element->next = graph->head;
	HnswPtrStore(base, graph->head, element);
	SpinLockRelease(&graph->lock);
}

/*
 * Update neighbors
 */
static void
UpdateNeighborsInMemory(char *base, HnswSupport * support, HnswElement e, int m)
{
	for (int lc = e->level; lc >= 0; lc--)
	{
		int			lm = HnswGetLayerM(m, lc);
		Size		neighborsSize = HNSW_NEIGHBOR_ARRAY_SIZE(lm);
		HnswNeighborArray *neighbors = palloc(neighborsSize);

		/* Copy neighbors to local memory */
		LWLockAcquire(&e->lock, LW_SHARED);
		memcpy(neighbors, HnswGetNeighbors(base, e, lc), neighborsSize);
		LWLockRelease(&e->lock);

		for (int i = 0; i < neighbors->length; i++)
		{
			HnswCandidate *hc = &neighbors->items[i];
			HnswElement neighborElement = HnswPtrAccess(base, hc->element);

			/* Keep scan-build happy on Mac x86-64 */
			Assert(neighborElement);

			LWLockAcquire(&neighborElement->lock, LW_EXCLUSIVE);
			HnswUpdateConnection(base, HnswGetNeighbors(base, neighborElement, lc), e, hc->distance, lm, NULL, NULL, support);
			LWLockRelease(&neighborElement->lock);
		}
	}
}

/*
 * Update graph in memory
 */
static void
UpdateGraphInMemory(HnswSupport * support, HnswElement element, int m, HnswElement entryPoint, HnswBuildState * buildstate)
{
	HnswGraph  *graph = buildstate->graph;
	char	   *base = buildstate->hnswarea;

	/* Look for duplicate */
	if (HnswShouldSkipUpdateGraphForDuplicate(FindDuplicateInMemory(base, element), true))
		return;

	/* Add element */
	AddElementInMemory(base, graph, element);

	/* Update neighbors */
	UpdateNeighborsInMemory(base, support, element, m);

	/* Update entry point if needed (already have lock) */
	if (HnswShouldUpdateEntryPoint(entryPoint == NULL, element->level, HnswGetEntryLevelForUpdate(entryPoint, true), true))
		HnswPtrStore(base, graph->entryPoint, element);
}

/*
 * Insert tuple in memory
 */
static void
InsertTupleInMemory(HnswBuildState * buildstate, HnswElement element)
{
	HnswGraph  *graph = buildstate->graph;
	HnswSupport *support = &buildstate->support;
	HnswElement entryPoint;
	LWLock	   *entryLock = &graph->entryLock;
	LWLock	   *entryWaitLock = &graph->entryWaitLock;
	int			efConstruction = buildstate->efConstruction;
	int			m = buildstate->m;
	char	   *base = buildstate->hnswarea;

	/* Wait if another process needs exclusive lock on entry lock */
	LWLockAcquire(entryWaitLock, LW_EXCLUSIVE);
	LWLockRelease(entryWaitLock);

	/* Get entry point */
	LWLockAcquire(entryLock, LW_SHARED);
	entryPoint = HnswPtrAccess(base, graph->entryPoint);

	/* Prevent concurrent inserts when likely updating entry point */
	if (HnswShouldUpdateEntryPoint(entryPoint == NULL, element->level, HnswGetEntryLevelForUpdate(entryPoint, true), true))
	{
		/* Release shared lock */
		LWLockRelease(entryLock);

		/* Tell other processes to wait and get exclusive lock */
		LWLockAcquire(entryWaitLock, LW_EXCLUSIVE);
		LWLockAcquire(entryLock, LW_EXCLUSIVE);
		LWLockRelease(entryWaitLock);

		/* Get latest entry point after lock is acquired */
		entryPoint = HnswPtrAccess(base, graph->entryPoint);
	}

	/* Find neighbors for element */
	HnswFindElementNeighbors(base, element, entryPoint, NULL, support, m, efConstruction, false);

	/* Update graph in memory */
	UpdateGraphInMemory(support, element, m, entryPoint, buildstate);

	/* Release entry lock */
	LWLockRelease(entryLock);
}

/*
 * Insert tuple
 */
static bool
InsertTuple(Relation index, Datum *values, bool *isnull, ItemPointer heaptid, HnswBuildState * buildstate)
{
	HnswGraph  *graph = buildstate->graph;
	HnswElement element;
	HnswAllocator *allocator = &buildstate->allocator;
	HnswSupport *support = &buildstate->support;
	Size		valueSize;
	Pointer		valuePtr;
	LWLock	   *flushLock = &graph->flushLock;
	char	   *base = buildstate->hnswarea;
	Datum		value;

	/* Form index value */
	if (HnswShouldSkipInvalidIndexValue(HnswFormIndexValue(&value, values, isnull, buildstate->typeInfo, support), true))
		return false;

	/* Get datum size */
	valueSize = VARSIZE_ANY(DatumGetPointer(value));

	/* Ensure graph not flushed when inserting */
	LWLockAcquire(flushLock, LW_SHARED);

	/* Are we in the on-disk phase? */
	if (HnswShouldUseOnDiskPhase(graph->flushed, true))
	{
		LWLockRelease(flushLock);

		return HnswInsertTupleOnDisk(index, support, value, heaptid, true);
	}

	/*
	 * In a parallel build, the HnswElement is allocated from the shared
	 * memory area, so we need to coordinate with other processes.
	 */
	LWLockAcquire(&graph->allocatorLock, LW_EXCLUSIVE);

	/*
	 * Check that we have enough memory available for the new element now that
	 * we have the allocator lock, and flush pages if needed.
	 */
	if (HnswShouldFlushGraph(graph->memoryUsed, graph->memoryTotal, true))
	{
		LWLockRelease(&graph->allocatorLock);

		LWLockRelease(flushLock);
		LWLockAcquire(flushLock, LW_EXCLUSIVE);

		if (HnswShouldFlushPagesInBuild(graph->flushed, true))
		{
			ereport(NOTICE,
					(errmsg("hnsw graph no longer fits into maintenance_work_mem after " INT64_FORMAT " tuples", (int64) graph->indtuples),
					 errdetail("Building will take significantly more time."),
					 errhint("Increase maintenance_work_mem to speed up builds.")));

			FlushPages(buildstate);
		}

		LWLockRelease(flushLock);

		return HnswInsertTupleOnDisk(index, support, value, heaptid, true);
	}

	/* Ok, we can proceed to allocate the element */
	element = HnswInitElement(base, heaptid, buildstate->m, buildstate->ml, buildstate->maxLevel, allocator);
	valuePtr = HnswAlloc(allocator, valueSize);

	/*
	 * We have now allocated the space needed for the element, so we don't
	 * need the allocator lock anymore. Release it and initialize the rest of
	 * the element.
	 */
	LWLockRelease(&graph->allocatorLock);

	/* Copy the datum */
	memcpy(valuePtr, DatumGetPointer(value), valueSize);
	HnswPtrStore(base, element->value, (char *) valuePtr);

	/* Create a lock for the element */
	LWLockInitialize(&element->lock, hnsw_lock_tranche_id);

	/* Insert tuple */
	InsertTupleInMemory(buildstate, element);

	/* Release flush lock */
	LWLockRelease(flushLock);

	return true;
}

/*
 * Callback for table_index_build_scan
 */
static void
BuildCallback(Relation index, ItemPointer tid, Datum *values,
			  bool *isnull, bool tupleIsAlive, void *state)
{
	HnswBuildState *buildstate = (HnswBuildState *) state;
	HnswGraph  *graph = buildstate->graph;
	MemoryContext oldCtx;

	/* Skip nulls */
	if (HnswShouldSkipNullBuildTuple(isnull[0], true))
		return;

	/* Use memory context */
	oldCtx = MemoryContextSwitchTo(buildstate->tmpCtx);

	/* Insert tuple */
	if (HnswShouldUpdateProgressAfterInsert(InsertTuple(index, values, isnull, tid, buildstate), true))
	{
		/* Update progress */
		SpinLockAcquire(&graph->lock);
		pgstat_progress_update_param(PROGRESS_CREATEIDX_TUPLES_DONE, ++graph->indtuples);
		SpinLockRelease(&graph->lock);
	}

	/* Reset memory context */
	MemoryContextSwitchTo(oldCtx);
	MemoryContextReset(buildstate->tmpCtx);
}

/*
 * Initialize the graph
 */
static void
InitGraph(HnswGraph * graph, char *base, Size memoryTotal)
{
	/* Initialize the lock tranche if needed */
	HnswInitLockTranche();

	HnswPtrStore(base, graph->head, (HnswElement) NULL);
	HnswPtrStore(base, graph->entryPoint, (HnswElement) NULL);
	graph->memoryUsed = 0;
	graph->memoryTotal = memoryTotal;
	graph->flushed = false;
	graph->indtuples = 0;
	SpinLockInit(&graph->lock);
	LWLockInitialize(&graph->entryLock, hnsw_lock_tranche_id);
	LWLockInitialize(&graph->entryWaitLock, hnsw_lock_tranche_id);
	LWLockInitialize(&graph->allocatorLock, hnsw_lock_tranche_id);
	LWLockInitialize(&graph->flushLock, hnsw_lock_tranche_id);
}

/*
 * Initialize an allocator
 */
static void
InitAllocator(HnswAllocator * allocator, void *(*alloc) (Size size, void *state), void *state)
{
	allocator->alloc = alloc;
	allocator->state = state;
}

/*
 * Memory context allocator
 */
static void *
HnswMemoryContextAlloc(Size size, void *state)
{
	HnswBuildState *buildstate = (HnswBuildState *) state;
	void	   *chunk = MemoryContextAlloc(buildstate->graphCtx, size);

	buildstate->graphData.memoryUsed = MemoryContextMemAllocated(buildstate->graphCtx, false);

	return chunk;
}

/*
 * Shared memory allocator
 */
static void *
HnswSharedMemoryAlloc(Size size, void *state)
{
	HnswBuildState *buildstate = (HnswBuildState *) state;
	void	   *chunk = buildstate->hnswarea + buildstate->graph->memoryUsed;

	buildstate->graph->memoryUsed += MAXALIGN(size);
	return chunk;
}

/*
 * Initialize the build state
 */
static void
InitBuildState(HnswBuildState * buildstate, Relation heap, Relation index, IndexInfo *indexInfo, ForkNumber forkNum)
{
	buildstate->heap = heap;
	buildstate->index = index;
	buildstate->indexInfo = indexInfo;
	buildstate->forkNum = forkNum;
	buildstate->typeInfo = HnswGetTypeInfo(index);

	buildstate->m = HnswGetM(index);
	buildstate->efConstruction = HnswGetEfConstruction(index);
	buildstate->dimensions = TupleDescAttr(index->rd_att, 0)->atttypmod;

	/* Disallow varbit since require fixed dimensions */
	if (HnswShouldRejectVarbitType(TupleDescAttr(index->rd_att, 0)->atttypid, true))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("type not supported for hnsw index")));

	/* Require column to have dimensions to be indexed */
	if (HnswShouldRejectMissingDimensions(buildstate->dimensions, true))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("column does not have dimensions")));

	if (HnswShouldRejectExcessDimensions(buildstate->dimensions, buildstate->typeInfo->maxDimensions, true))
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("column cannot have more than %d dimensions for hnsw index", buildstate->typeInfo->maxDimensions)));

	if (HnswShouldRejectLowEfConstruction(buildstate->efConstruction, buildstate->m, true))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("ef_construction must be greater than or equal to 2 * m")));

	buildstate->reltuples = 0;
	buildstate->indtuples = 0;

	/* Get support functions */
	HnswInitSupport(&buildstate->support, index);

	InitGraph(&buildstate->graphData, NULL, (Size) maintenance_work_mem * 1024L);
	buildstate->graph = &buildstate->graphData;
	buildstate->ml = HnswGetMl(buildstate->m);
	buildstate->maxLevel = HnswGetMaxLevel(buildstate->m);

	buildstate->graphCtx = GenerationContextCreate(CurrentMemoryContext,
												   "Hnsw build graph context",
#if PG_VERSION_NUM >= 150000
												   1024 * 1024, 1024 * 1024,
#endif
												   1024 * 1024);
	buildstate->tmpCtx = AllocSetContextCreate(CurrentMemoryContext,
											   "Hnsw build temporary context",
											   ALLOCSET_DEFAULT_SIZES);

	InitAllocator(&buildstate->allocator, &HnswMemoryContextAlloc, buildstate);

	buildstate->hnswleader = NULL;
	buildstate->hnswshared = NULL;
	buildstate->hnswarea = NULL;
}

/*
 * Free resources
 */
static void
FreeBuildState(HnswBuildState * buildstate)
{
	MemoryContextDelete(buildstate->graphCtx);
	MemoryContextDelete(buildstate->tmpCtx);
}

/*
 * Within leader, wait for end of heap scan
 */
static double
ParallelHeapScan(HnswBuildState * buildstate)
{
	HnswShared *hnswshared = buildstate->hnswleader->hnswshared;
	int			nparticipanttuplesorts;
	double		reltuples;

	nparticipanttuplesorts = buildstate->hnswleader->nparticipanttuplesorts;
	for (;;)
	{
		SpinLockAcquire(&hnswshared->mutex);
		if (HnswShouldFinishParallelHeapScan(hnswshared->nparticipantsdone, nparticipanttuplesorts, true))
		{
			buildstate->graph = &hnswshared->graphData;
			buildstate->hnswarea = buildstate->hnswleader->hnswarea;
			reltuples = hnswshared->reltuples;
			SpinLockRelease(&hnswshared->mutex);
			break;
		}
		SpinLockRelease(&hnswshared->mutex);

		ConditionVariableSleep(&hnswshared->workersdonecv,
							   WAIT_EVENT_PARALLEL_CREATE_INDEX_SCAN);
	}

	ConditionVariableCancelSleep();

	return reltuples;
}

/*
 * Perform a worker's portion of a parallel insert
 */
static void
HnswParallelScanAndInsert(Relation heapRel, Relation indexRel, HnswShared * hnswshared, char *hnswarea, bool progress)
{
	HnswBuildState buildstate;
	TableScanDesc scan;
	double		reltuples;
	IndexInfo  *indexInfo;

	/* Join parallel scan */
	indexInfo = BuildIndexInfo(indexRel);
	indexInfo->ii_Concurrent = hnswshared->isconcurrent;
	InitBuildState(&buildstate, heapRel, indexRel, indexInfo, MAIN_FORKNUM);
	buildstate.graph = &hnswshared->graphData;
	buildstate.hnswarea = hnswarea;
	InitAllocator(&buildstate.allocator, &HnswSharedMemoryAlloc, &buildstate);
	scan = table_beginscan_parallel(heapRel,
									ParallelTableScanFromHnswShared(hnswshared));
	reltuples = table_index_build_scan(heapRel, indexRel, indexInfo,
									   true, progress, BuildCallback,
									   (void *) &buildstate, scan);

	/* Record statistics */
	SpinLockAcquire(&hnswshared->mutex);
	hnswshared->nparticipantsdone++;
	hnswshared->reltuples += reltuples;
	SpinLockRelease(&hnswshared->mutex);

	/* Log statistics */
	if (HnswShouldLogLeaderProgress(progress, true))
		ereport(DEBUG1, (errmsg("leader processed " INT64_FORMAT " tuples", (int64) reltuples)));
	else
		ereport(DEBUG1, (errmsg("worker processed " INT64_FORMAT " tuples", (int64) reltuples)));

	/* Notify leader */
	ConditionVariableSignal(&hnswshared->workersdonecv);

	FreeBuildState(&buildstate);
}

/*
 * Perform work within a launched parallel process
 */
void
HnswParallelBuildMain(dsm_segment *seg, shm_toc *toc)
{
	char	   *sharedquery;
	HnswShared *hnswshared;
	char	   *hnswarea;
	Relation	heapRel;
	Relation	indexRel;
	LOCKMODE	heapLockmode;
	LOCKMODE	indexLockmode;

	/* Set debug_query_string for individual workers first */
	sharedquery = shm_toc_lookup(toc, PARALLEL_KEY_QUERY_TEXT, true);
	debug_query_string = sharedquery;

	/* Report the query string from leader */
	pgstat_report_activity(STATE_RUNNING, debug_query_string);

	/* Look up shared state */
	hnswshared = shm_toc_lookup(toc, PARALLEL_KEY_HNSW_SHARED, false);

	/* Open relations using lock modes known to be obtained by index.c */
	if (HnswShouldUseNonConcurrentLockModes(hnswshared->isconcurrent, true))
	{
		heapLockmode = ShareLock;
		indexLockmode = AccessExclusiveLock;
	}
	else
	{
		heapLockmode = ShareUpdateExclusiveLock;
		indexLockmode = RowExclusiveLock;
	}

	/* Open relations within worker */
	heapRel = table_open(hnswshared->heaprelid, heapLockmode);
	indexRel = index_open(hnswshared->indexrelid, indexLockmode);

	hnswarea = shm_toc_lookup(toc, PARALLEL_KEY_HNSW_AREA, false);

	/* Perform inserts */
	HnswParallelScanAndInsert(heapRel, indexRel, hnswshared, hnswarea, false);

	/* Close relations within worker */
	index_close(indexRel, indexLockmode);
	table_close(heapRel, heapLockmode);
}

/*
 * End parallel build
 */
static void
HnswEndParallel(HnswLeader * hnswleader)
{
	/* Shutdown worker processes */
	WaitForParallelWorkersToFinish(hnswleader->pcxt);

	/* Free last reference to MVCC snapshot, if one was used */
	if (HnswShouldUnregisterMVCCSnapshot(IsMVCCSnapshot(hnswleader->snapshot), true))
		UnregisterSnapshot(hnswleader->snapshot);
	DestroyParallelContext(hnswleader->pcxt);
	ExitParallelMode();
}

/*
 * Return size of shared memory required for parallel index build
 */
static Size
ParallelEstimateShared(Relation heap, Snapshot snapshot)
{
	return add_size(BUFFERALIGN(sizeof(HnswShared)), table_parallelscan_estimate(heap, snapshot));
}

/*
 * Within leader, participate as a parallel worker
 */
static void
HnswLeaderParticipateAsWorker(HnswBuildState * buildstate)
{
	HnswLeader *hnswleader = buildstate->hnswleader;

	/* Perform work common to all participants */
	HnswParallelScanAndInsert(buildstate->heap, buildstate->index, hnswleader->hnswshared, hnswleader->hnswarea, true);
}

/*
 * Begin parallel build
 */
static void
HnswBeginParallel(HnswBuildState * buildstate, bool isconcurrent, int request)
{
	ParallelContext *pcxt;
	Snapshot	snapshot;
	Size		esthnswshared;
	Size		esthnswarea;
	Size		estother;
	HnswShared *hnswshared;
	char	   *hnswarea;
	HnswLeader *hnswleader = (HnswLeader *) palloc0(sizeof(HnswLeader));
	bool		leaderparticipates = true;
	int			querylen;

#ifdef DISABLE_LEADER_PARTICIPATION
	leaderparticipates = false;
#endif

	/* Enter parallel mode and create context */
	EnterParallelMode();
	Assert(request > 0);
	pcxt = CreateParallelContext("vector", "HnswParallelBuildMain", request);

	/* Get snapshot for table scan */
	if (HnswShouldUseNonConcurrentSnapshot(isconcurrent, true))
		snapshot = SnapshotAny;
	else
		snapshot = RegisterSnapshot(GetTransactionSnapshot());

	/* Estimate size of workspaces */
	esthnswshared = ParallelEstimateShared(buildstate->heap, snapshot);
	shm_toc_estimate_chunk(&pcxt->estimator, esthnswshared);

	/* Leave space for other objects in shared memory */
	/* Docker has a default limit of 64 MB for shm_size */
	/* which happens to be the default value of maintenance_work_mem */
	esthnswarea = maintenance_work_mem * 1024L;
	estother = 3 * 1024 * 1024;
	if (HnswShouldReserveGraphMemory((int64) esthnswarea, (int64) estother, true))
		esthnswarea -= estother;

	shm_toc_estimate_chunk(&pcxt->estimator, esthnswarea);
	shm_toc_estimate_keys(&pcxt->estimator, 2);

	/* Finally, estimate PARALLEL_KEY_QUERY_TEXT space */
	if (HnswShouldUseDebugQueryString(HnswShouldHaveDebugQueryString(debug_query_string, true), true))
	{
		querylen = strlen(debug_query_string);
		shm_toc_estimate_chunk(&pcxt->estimator, querylen + 1);
		shm_toc_estimate_keys(&pcxt->estimator, 1);
	}
	else
		querylen = 0;			/* keep compiler quiet */

	/* Everyone's had a chance to ask for space, so now create the DSM */
	InitializeParallelDSM(pcxt);

	/* If no DSM segment was available, back out (do serial build) */
	if (HnswShouldFallbackWithoutDsmSegment(pcxt->seg != NULL, true))
	{
		if (HnswShouldUnregisterMVCCSnapshot(IsMVCCSnapshot(snapshot), true))
			UnregisterSnapshot(snapshot);
		DestroyParallelContext(pcxt);
		ExitParallelMode();
		return;
	}

	/* Store shared build state, for which we reserved space */
	hnswshared = (HnswShared *) shm_toc_allocate(pcxt->toc, esthnswshared);
	/* Initialize immutable state */
	hnswshared->heaprelid = RelationGetRelid(buildstate->heap);
	hnswshared->indexrelid = RelationGetRelid(buildstate->index);
	hnswshared->isconcurrent = isconcurrent;
	ConditionVariableInit(&hnswshared->workersdonecv);
	SpinLockInit(&hnswshared->mutex);
	/* Initialize mutable state */
	hnswshared->nparticipantsdone = 0;
	hnswshared->reltuples = 0;
	table_parallelscan_initialize(buildstate->heap,
								  ParallelTableScanFromHnswShared(hnswshared),
								  snapshot);

	hnswarea = (char *) shm_toc_allocate(pcxt->toc, esthnswarea);
	/* Report less than allocated so never fails */
	InitGraph(&hnswshared->graphData, hnswarea, esthnswarea - 1024 * 1024);

	/*
	 * Avoid base address for relptr for Postgres < 14.5
	 * https://github.com/postgres/postgres/commit/7201cd18627afc64850537806da7f22150d1a83b
	 */
#if PG_VERSION_NUM < 140005
	hnswshared->graphData.memoryUsed += MAXALIGN(1);
#endif

	shm_toc_insert(pcxt->toc, PARALLEL_KEY_HNSW_SHARED, hnswshared);
	shm_toc_insert(pcxt->toc, PARALLEL_KEY_HNSW_AREA, hnswarea);

	/* Store query string for workers */
	if (HnswShouldUseDebugQueryString(HnswShouldHaveDebugQueryString(debug_query_string, true), true))
	{
		char	   *sharedquery;

		sharedquery = (char *) shm_toc_allocate(pcxt->toc, querylen + 1);
		memcpy(sharedquery, debug_query_string, querylen + 1);
		shm_toc_insert(pcxt->toc, PARALLEL_KEY_QUERY_TEXT, sharedquery);
	}

	/* Launch workers, saving status for leader/caller */
	LaunchParallelWorkers(pcxt);
	hnswleader->pcxt = pcxt;
	hnswleader->nparticipanttuplesorts = pcxt->nworkers_launched;
	if (HnswShouldLeaderParticipate(leaderparticipates, true))
		hnswleader->nparticipanttuplesorts++;
	hnswleader->hnswshared = hnswshared;
	hnswleader->snapshot = snapshot;
	hnswleader->hnswarea = hnswarea;

	/* If no workers were successfully launched, back out (do serial build) */
	if (HnswShouldFallbackWithoutWorkers(pcxt->nworkers_launched, true))
	{
		HnswEndParallel(hnswleader);
		return;
	}

	/* Log participants */
	ereport(DEBUG1, (errmsg("using %d parallel workers", pcxt->nworkers_launched)));

	/* Save leader state now that it's clear build will be parallel */
	buildstate->hnswleader = hnswleader;

	/* Join heap scan ourselves */
	if (HnswShouldLeaderParticipate(leaderparticipates, true))
		HnswLeaderParticipateAsWorker(buildstate);

	/* Wait for all launched workers */
	WaitForParallelWorkersToAttach(pcxt);
}

/*
 * Compute parallel workers
 */
static bool
HnswShouldSkipParallelWorkers(int parallelWorkers, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_parallel_workers_kernel(parallelWorkers);

	return parallelWorkers == 0;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_parallel_workers);
Datum
vector_hnsw_should_skip_parallel_workers(PG_FUNCTION_ARGS)
{
	int32		parallelWorkers = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipParallelWorkers(parallelWorkers, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_parallel_workers);
Datum
vector_rust_hnsw_should_skip_parallel_workers(PG_FUNCTION_ARGS)
{
	int32		parallelWorkers = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipParallelWorkers(parallelWorkers, true));
}

static bool
HnswShouldUseRelationParallelWorkers(int parallelWorkers, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_use_relation_parallel_workers_kernel(parallelWorkers);

	return parallelWorkers != -1;
}

static bool
HnswShouldFallbackWithoutWorkers(int workersLaunched, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_fallback_without_workers_kernel(workersLaunched);

	return workersLaunched == 0;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_fallback_without_workers);
Datum
vector_hnsw_should_fallback_without_workers(PG_FUNCTION_ARGS)
{
	int32		workersLaunched = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFallbackWithoutWorkers(workersLaunched, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_fallback_without_workers);
Datum
vector_rust_hnsw_should_fallback_without_workers(PG_FUNCTION_ARGS)
{
	int32		workersLaunched = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFallbackWithoutWorkers(workersLaunched, true));
}

static bool
HnswShouldLeaderParticipate(bool leaderParticipates, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_leader_participate_kernel(leaderParticipates);

	return leaderParticipates;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_leader_participate);
Datum
vector_hnsw_should_leader_participate(PG_FUNCTION_ARGS)
{
	int32		leaderParticipates = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLeaderParticipate(leaderParticipates != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_leader_participate);
Datum
vector_rust_hnsw_should_leader_participate(PG_FUNCTION_ARGS)
{
	int32		leaderParticipates = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLeaderParticipate(leaderParticipates != 0, true));
}

static bool
HnswShouldUseDebugQueryString(bool hasDebugQueryString, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_use_debug_query_string_kernel(hasDebugQueryString);

	return hasDebugQueryString;
}

static bool
HnswShouldHaveDebugQueryString(const char *debugQueryString, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(debugQueryString != NULL);

	return debugQueryString != NULL;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_debug_query_string);
Datum
vector_hnsw_should_use_debug_query_string(PG_FUNCTION_ARGS)
{
	int32		hasDebugQueryString = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDebugQueryString(hasDebugQueryString != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_debug_query_string);
Datum
vector_rust_hnsw_should_use_debug_query_string(PG_FUNCTION_ARGS)
{
	int32		hasDebugQueryString = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDebugQueryString(hasDebugQueryString != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_debug_query_string);
Datum
vector_hnsw_should_have_debug_query_string(PG_FUNCTION_ARGS)
{
	int32		hasDebugQueryString = PG_GETARG_INT32(0);
	const char *debugQueryString = hasDebugQueryString != 0 ? "debug" : NULL;

	PG_RETURN_BOOL(HnswShouldHaveDebugQueryString(debugQueryString, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_debug_query_string);
Datum
vector_rust_hnsw_should_have_debug_query_string(PG_FUNCTION_ARGS)
{
	int32		hasDebugQueryString = PG_GETARG_INT32(0);
	const char *debugQueryString = hasDebugQueryString != 0 ? "debug" : NULL;

	PG_RETURN_BOOL(HnswShouldHaveDebugQueryString(debugQueryString, true));
}

static bool
HnswShouldFinishParallelHeapScan(int participantsDone, int participantCount, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_finish_parallel_heap_scan_kernel(participantsDone, participantCount);

	return participantsDone == participantCount;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_finish_parallel_heap_scan);
Datum
vector_hnsw_should_finish_parallel_heap_scan(PG_FUNCTION_ARGS)
{
	int32		participantsDone = PG_GETARG_INT32(0);
	int32		participantCount = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldFinishParallelHeapScan(participantsDone, participantCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_finish_parallel_heap_scan);
Datum
vector_rust_hnsw_should_finish_parallel_heap_scan(PG_FUNCTION_ARGS)
{
	int32		participantsDone = PG_GETARG_INT32(0);
	int32		participantCount = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldFinishParallelHeapScan(participantsDone, participantCount, true));
}

static bool
HnswShouldUnregisterMVCCSnapshot(bool snapshotIsMVCC, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_unregister_mvcc_snapshot_kernel(snapshotIsMVCC);

	return snapshotIsMVCC;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_unregister_mvcc_snapshot);
Datum
vector_hnsw_should_unregister_mvcc_snapshot(PG_FUNCTION_ARGS)
{
	int32		snapshotIsMVCC = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUnregisterMVCCSnapshot(snapshotIsMVCC != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_unregister_mvcc_snapshot);
Datum
vector_rust_hnsw_should_unregister_mvcc_snapshot(PG_FUNCTION_ARGS)
{
	int32		snapshotIsMVCC = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUnregisterMVCCSnapshot(snapshotIsMVCC != 0, true));
}

static bool
HnswShouldFallbackWithoutDsmSegment(bool hasDsmSegment, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_fallback_without_dsm_segment_kernel(hasDsmSegment);

	return !hasDsmSegment;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_fallback_without_dsm_segment);
Datum
vector_hnsw_should_fallback_without_dsm_segment(PG_FUNCTION_ARGS)
{
	int32		hasDsmSegment = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFallbackWithoutDsmSegment(hasDsmSegment != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_fallback_without_dsm_segment);
Datum
vector_rust_hnsw_should_fallback_without_dsm_segment(PG_FUNCTION_ARGS)
{
	int32		hasDsmSegment = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFallbackWithoutDsmSegment(hasDsmSegment != 0, true));
}

static bool
HnswShouldReserveGraphMemory(int64 estHnswArea, int64 estOther, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reserve_graph_memory_kernel(estHnswArea, estOther);

	return estHnswArea > estOther;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reserve_graph_memory);
Datum
vector_hnsw_should_reserve_graph_memory(PG_FUNCTION_ARGS)
{
	int64		estHnswArea = PG_GETARG_INT64(0);
	int64		estOther = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldReserveGraphMemory(estHnswArea, estOther, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reserve_graph_memory);
Datum
vector_rust_hnsw_should_reserve_graph_memory(PG_FUNCTION_ARGS)
{
	int64		estHnswArea = PG_GETARG_INT64(0);
	int64		estOther = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldReserveGraphMemory(estHnswArea, estOther, true));
}

static bool
HnswShouldLogLeaderProgress(bool progressIsLeader, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_log_leader_progress_kernel(progressIsLeader);

	return progressIsLeader;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_log_leader_progress);
Datum
vector_hnsw_should_log_leader_progress(PG_FUNCTION_ARGS)
{
	int32		progressIsLeader = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLogLeaderProgress(progressIsLeader != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_log_leader_progress);
Datum
vector_rust_hnsw_should_log_leader_progress(PG_FUNCTION_ARGS)
{
	int32		progressIsLeader = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLogLeaderProgress(progressIsLeader != 0, true));
}

static bool
HnswShouldRejectVarbitType(Oid typeOid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_varbit_type_kernel((int32) typeOid, (int32) VARBITOID);

	return typeOid == VARBITOID;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_varbit_type);
Datum
vector_hnsw_should_reject_varbit_type(PG_FUNCTION_ARGS)
{
	int32		typeOid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectVarbitType((Oid) typeOid, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_varbit_type);
Datum
vector_rust_hnsw_should_reject_varbit_type(PG_FUNCTION_ARGS)
{
	int32		typeOid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectVarbitType((Oid) typeOid, true));
}

static bool
HnswShouldRejectMissingDimensions(int32 dimensions, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_missing_dimensions_kernel(dimensions);

	return dimensions < 0;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_missing_dimensions);
Datum
vector_hnsw_should_reject_missing_dimensions(PG_FUNCTION_ARGS)
{
	int32		dimensions = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectMissingDimensions(dimensions, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_missing_dimensions);
Datum
vector_rust_hnsw_should_reject_missing_dimensions(PG_FUNCTION_ARGS)
{
	int32		dimensions = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectMissingDimensions(dimensions, true));
}

static bool
HnswShouldRejectExcessDimensions(int32 dimensions, int32 maxDimensions, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_excess_dimensions_kernel(dimensions, maxDimensions);

	return dimensions > maxDimensions;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_excess_dimensions);
Datum
vector_hnsw_should_reject_excess_dimensions(PG_FUNCTION_ARGS)
{
	int32		dimensions = PG_GETARG_INT32(0);
	int32		maxDimensions = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectExcessDimensions(dimensions, maxDimensions, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_excess_dimensions);
Datum
vector_rust_hnsw_should_reject_excess_dimensions(PG_FUNCTION_ARGS)
{
	int32		dimensions = PG_GETARG_INT32(0);
	int32		maxDimensions = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectExcessDimensions(dimensions, maxDimensions, true));
}

static bool
HnswShouldRejectLowEfConstruction(int32 efConstruction, int32 m, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_low_ef_construction_kernel(efConstruction, m);

	return efConstruction < 2 * m;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_low_ef_construction);
Datum
vector_hnsw_should_reject_low_ef_construction(PG_FUNCTION_ARGS)
{
	int32		efConstruction = PG_GETARG_INT32(0);
	int32		m = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectLowEfConstruction(efConstruction, m, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_low_ef_construction);
Datum
vector_rust_hnsw_should_reject_low_ef_construction(PG_FUNCTION_ARGS)
{
	int32		efConstruction = PG_GETARG_INT32(0);
	int32		m = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectLowEfConstruction(efConstruction, m, true));
}

static bool
HnswShouldTreatForkAsInit(int32 forkNum, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_match_neighbor_connection_kernel(forkNum, 0, INIT_FORKNUM, 0);

	return forkNum == INIT_FORKNUM;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_treat_fork_as_init);
Datum
vector_hnsw_should_treat_fork_as_init(PG_FUNCTION_ARGS)
{
	int32		forkNum = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTreatForkAsInit(forkNum, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_treat_fork_as_init);
Datum
vector_rust_hnsw_should_treat_fork_as_init(PG_FUNCTION_ARGS)
{
	int32		forkNum = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTreatForkAsInit(forkNum, true));
}

static bool
HnswShouldWriteWalPage(bool needsWal, bool isInitFork, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_write_wal_page_kernel(needsWal, isInitFork);

	return needsWal || isInitFork;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_write_wal_page);
Datum
vector_hnsw_should_write_wal_page(PG_FUNCTION_ARGS)
{
	int32		needsWal = PG_GETARG_INT32(0);
	int32		isInitFork = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldWriteWalPage(needsWal != 0, isInitFork != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_write_wal_page);
Datum
vector_rust_hnsw_should_write_wal_page(PG_FUNCTION_ARGS)
{
	int32		needsWal = PG_GETARG_INT32(0);
	int32		isInitFork = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldWriteWalPage(needsWal != 0, isInitFork != 0, true));
}

static bool
HnswShouldSkipNullBuildTuple(bool isNull, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_null_build_tuple_kernel(isNull);

	return isNull;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_null_build_tuple);
Datum
vector_hnsw_should_skip_null_build_tuple(PG_FUNCTION_ARGS)
{
	int32		isNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNullBuildTuple(isNull != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_null_build_tuple);
Datum
vector_rust_hnsw_should_skip_null_build_tuple(PG_FUNCTION_ARGS)
{
	int32		isNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNullBuildTuple(isNull != 0, true));
}

static bool
HnswShouldUpdateProgressAfterInsert(bool tupleInserted, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(tupleInserted);

	return tupleInserted;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_progress_after_insert);
Datum
vector_hnsw_should_update_progress_after_insert(PG_FUNCTION_ARGS)
{
	int32		tupleInserted = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdateProgressAfterInsert(tupleInserted != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_progress_after_insert);
Datum
vector_rust_hnsw_should_update_progress_after_insert(PG_FUNCTION_ARGS)
{
	int32		tupleInserted = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdateProgressAfterInsert(tupleInserted != 0, true));
}

static bool
HnswShouldRejectOversizedElementTuple(int64 tupleSize, int64 allocSize, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_oversized_element_tuple_kernel(tupleSize, allocSize);

	return tupleSize > allocSize;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_oversized_element_tuple);
Datum
vector_hnsw_should_reject_oversized_element_tuple(PG_FUNCTION_ARGS)
{
	int64		tupleSize = PG_GETARG_INT64(0);
	int64		allocSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldRejectOversizedElementTuple(tupleSize, allocSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_oversized_element_tuple);
Datum
vector_rust_hnsw_should_reject_oversized_element_tuple(PG_FUNCTION_ARGS)
{
	int64		tupleSize = PG_GETARG_INT64(0);
	int64		allocSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldRejectOversizedElementTuple(tupleSize, allocSize, true));
}

static bool
HnswShouldAppendNeighborPage(int64 freeSpace, int64 neighborTupleSize, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_append_neighbor_page_kernel(freeSpace, neighborTupleSize);

	return freeSpace < neighborTupleSize;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_append_neighbor_page);
Datum
vector_hnsw_should_append_neighbor_page(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		neighborTupleSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldAppendNeighborPage(freeSpace, neighborTupleSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_append_neighbor_page);
Datum
vector_rust_hnsw_should_append_neighbor_page(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		neighborTupleSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldAppendNeighborPage(freeSpace, neighborTupleSize, true));
}

static bool
HnswShouldAppendElementPage(int64 freeSpace, int64 elementTupleSize, int64 combinedSize, int64 maxSize, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_append_element_page_kernel(freeSpace, elementTupleSize, combinedSize, maxSize);

	return freeSpace < elementTupleSize || (combinedSize <= maxSize && freeSpace < combinedSize);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_append_element_page);
Datum
vector_hnsw_should_append_element_page(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		elementTupleSize = PG_GETARG_INT64(1);
	int64		combinedSize = PG_GETARG_INT64(2);
	int64		maxSize = PG_GETARG_INT64(3);

	PG_RETURN_BOOL(HnswShouldAppendElementPage(freeSpace, elementTupleSize, combinedSize, maxSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_append_element_page);
Datum
vector_rust_hnsw_should_append_element_page(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		elementTupleSize = PG_GETARG_INT64(1);
	int64		combinedSize = PG_GETARG_INT64(2);
	int64		maxSize = PG_GETARG_INT64(3);

	PG_RETURN_BOOL(HnswShouldAppendElementPage(freeSpace, elementTupleSize, combinedSize, maxSize, true));
}

static bool
HnswShouldRejectUnexpectedItemOffset(int32 insertedOffset, int32 expectedOffset, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_unexpected_item_offset_kernel(insertedOffset, expectedOffset);

	return insertedOffset != expectedOffset;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_unexpected_item_offset);
Datum
vector_hnsw_should_reject_unexpected_item_offset(PG_FUNCTION_ARGS)
{
	int32		insertedOffset = PG_GETARG_INT32(0);
	int32		expectedOffset = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectUnexpectedItemOffset(insertedOffset, expectedOffset, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_unexpected_item_offset);
Datum
vector_rust_hnsw_should_reject_unexpected_item_offset(PG_FUNCTION_ARGS)
{
	int32		insertedOffset = PG_GETARG_INT32(0);
	int32		expectedOffset = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectUnexpectedItemOffset(insertedOffset, expectedOffset, true));
}

static bool
HnswShouldRejectNeighborOverwrite(bool overwriteSucceeded, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_neighbor_overwrite_kernel(overwriteSucceeded);

	return !overwriteSucceeded;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_neighbor_overwrite);
Datum
vector_hnsw_should_reject_neighbor_overwrite(PG_FUNCTION_ARGS)
{
	int32		overwriteSucceeded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectNeighborOverwrite(overwriteSucceeded != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_neighbor_overwrite);
Datum
vector_rust_hnsw_should_reject_neighbor_overwrite(PG_FUNCTION_ARGS)
{
	int32		overwriteSucceeded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectNeighborOverwrite(overwriteSucceeded != 0, true));
}

static bool
HnswShouldStoreNeighborsOnSamePage(int64 combinedSize, int64 maxSize, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_store_neighbors_on_same_page_kernel(combinedSize, maxSize);

	return combinedSize <= maxSize;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_store_neighbors_on_same_page);
Datum
vector_hnsw_should_store_neighbors_on_same_page(PG_FUNCTION_ARGS)
{
	int64		combinedSize = PG_GETARG_INT64(0);
	int64		maxSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldStoreNeighborsOnSamePage(combinedSize, maxSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_store_neighbors_on_same_page);
Datum
vector_rust_hnsw_should_store_neighbors_on_same_page(PG_FUNCTION_ARGS)
{
	int64		combinedSize = PG_GETARG_INT64(0);
	int64		maxSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldStoreNeighborsOnSamePage(combinedSize, maxSize, true));
}

static bool
HnswShouldUseNonConcurrentLockModes(bool isConcurrent, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_use_non_concurrent_lock_modes_kernel(isConcurrent);

	return !isConcurrent;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_non_concurrent_lock_modes);
Datum
vector_hnsw_should_use_non_concurrent_lock_modes(PG_FUNCTION_ARGS)
{
	int32		isConcurrent = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNonConcurrentLockModes(isConcurrent != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_non_concurrent_lock_modes);
Datum
vector_rust_hnsw_should_use_non_concurrent_lock_modes(PG_FUNCTION_ARGS)
{
	int32		isConcurrent = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNonConcurrentLockModes(isConcurrent != 0, true));
}

static bool
HnswShouldUseNonConcurrentSnapshot(bool isConcurrent, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_use_non_concurrent_snapshot_kernel(isConcurrent);

	return !isConcurrent;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_non_concurrent_snapshot);
Datum
vector_hnsw_should_use_non_concurrent_snapshot(PG_FUNCTION_ARGS)
{
	int32		isConcurrent = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNonConcurrentSnapshot(isConcurrent != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_non_concurrent_snapshot);
Datum
vector_rust_hnsw_should_use_non_concurrent_snapshot(PG_FUNCTION_ARGS)
{
	int32		isConcurrent = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNonConcurrentSnapshot(isConcurrent != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_relation_parallel_workers);
Datum
vector_hnsw_should_use_relation_parallel_workers(PG_FUNCTION_ARGS)
{
	int32		parallelWorkers = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseRelationParallelWorkers(parallelWorkers, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_relation_parallel_workers);
Datum
vector_rust_hnsw_should_use_relation_parallel_workers(PG_FUNCTION_ARGS)
{
	int32		parallelWorkers = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseRelationParallelWorkers(parallelWorkers, true));
}

static int
ComputeParallelWorkers(Relation heap, Relation index)
{
	int			parallel_workers;

	/* Make sure it's safe to use parallel workers */
	parallel_workers = plan_create_index_workers(RelationGetRelid(heap), RelationGetRelid(index));
	if (HnswShouldSkipParallelWorkers(parallel_workers, true))
		return 0;

	/* Use parallel_workers storage parameter on table if set */
	parallel_workers = RelationGetParallelWorkers(heap, -1);
	if (HnswShouldUseRelationParallelWorkers(parallel_workers, true))
		return Min(parallel_workers, max_parallel_maintenance_workers);

	return max_parallel_maintenance_workers;
}

/*
 * Build graph
 */
static void
BuildGraph(HnswBuildState * buildstate)
{
	int			parallel_workers = 0;

	pgstat_progress_update_param(PROGRESS_CREATEIDX_SUBPHASE, PROGRESS_HNSW_PHASE_LOAD);

	/* Calculate parallel workers */
	if (HnswShouldScanHeapForBuild(buildstate->heap != NULL, true))
		parallel_workers = ComputeParallelWorkers(buildstate->heap, buildstate->index);

	/* Attempt to launch parallel worker scan when required */
	if (HnswShouldBeginParallelBuild(parallel_workers, true))
		HnswBeginParallel(buildstate, buildstate->indexInfo->ii_Concurrent, parallel_workers);

	/* Add tuples to graph */
	if (HnswShouldScanHeapForBuild(buildstate->heap != NULL, true))
	{
		if (HnswShouldUseParallelHeapScan(buildstate->hnswleader != NULL, true))
			buildstate->reltuples = ParallelHeapScan(buildstate);
		else
			buildstate->reltuples = table_index_build_scan(buildstate->heap, buildstate->index, buildstate->indexInfo,
														   true, true, BuildCallback, (void *) buildstate, NULL);

		buildstate->indtuples = buildstate->graph->indtuples;
	}

	/* Flush pages */
	if (HnswShouldFlushGraphPagesAtEnd(buildstate->graph->flushed, true))
		FlushPages(buildstate);

	/* End parallel build */
	if (HnswShouldEndParallelBuild(buildstate->hnswleader != NULL, true))
		HnswEndParallel(buildstate->hnswleader);
}

/*
 * Build the index
 */
static void
BuildIndex(Relation heap, Relation index, IndexInfo *indexInfo,
		   HnswBuildState * buildstate, ForkNumber forkNum)
{
	bool		isInitFork;

#ifdef HNSW_MEMORY
	SeedRandom(42);
#endif

	InitBuildState(buildstate, heap, index, indexInfo, forkNum);

	BuildGraph(buildstate);
	isInitFork = HnswShouldTreatForkAsInit((int32) forkNum, true);

	if (HnswShouldWriteWalPage(RelationNeedsWAL(index), isInitFork, true))
		log_newpage_range(index, forkNum, 0, RelationGetNumberOfBlocksInFork(index, forkNum), true);

	FreeBuildState(buildstate);
}

/*
 * Build the index for a logged table
 */
IndexBuildResult *
hnswbuild(Relation heap, Relation index, IndexInfo *indexInfo)
{
	IndexBuildResult *result;
	HnswBuildState buildstate;

	BuildIndex(heap, index, indexInfo, &buildstate, MAIN_FORKNUM);

	result = (IndexBuildResult *) palloc(sizeof(IndexBuildResult));
	result->heap_tuples = buildstate.reltuples;
	result->index_tuples = buildstate.indtuples;

	return result;
}

/*
 * Build the index for an unlogged table
 */
void
hnswbuildempty(Relation index)
{
	IndexInfo  *indexInfo = BuildIndexInfo(index);
	HnswBuildState buildstate;

	BuildIndex(NULL, index, indexInfo, &buildstate, INIT_FORKNUM);
}
