#include "postgres.h"

#include <math.h>

#include "access/genam.h"
#include "access/generic_xlog.h"
#include "common/hashfn.h"
#include "fmgr.h"
#include "hnsw.h"
#include "lib/pairingheap.h"
#include "nodes/pg_list.h"
#include "port/atomics.h"
#include "rust_ffi.h"
#include "sparsevec.h"
#include "storage/bufmgr.h"
#include "utils/datum.h"
#include "utils/memdebug.h"
#include "utils/rel.h"
#include "vector.h"

#if PG_VERSION_NUM >= 160000
#include "varatt.h"
#endif

#if PG_VERSION_NUM < 170000
static inline uint64
murmurhash64(uint64 data)
{
	uint64		h = data;

	h ^= h >> 33;
	h *= 0xff51afd7ed558ccd;
	h ^= h >> 33;
	h *= 0xc4ceb9fe1a85ec53;
	h ^= h >> 33;

	return h;
}
#endif

/* TID hash table */
static uint32
hash_tid(ItemPointerData tid)
{
	union
	{
		uint64		i;
		ItemPointerData tid;
	}			x;

	/* Initialize unused bytes */
	x.i = 0;
	x.tid = tid;

	return murmurhash64(x.i);
}

#define SH_PREFIX		tidhash
#define SH_ELEMENT_TYPE	TidHashEntry
#define SH_KEY_TYPE		ItemPointerData
#define	SH_KEY			tid
#define SH_HASH_KEY(tb, key)	hash_tid(key)
#define SH_EQUAL(tb, a, b)		ItemPointerEquals(&a, &b)
#define	SH_SCOPE		extern
#define SH_DEFINE
#include "lib/simplehash.h"

/* Pointer hash table */
static uint32
hash_pointer(uintptr_t ptr)
{
#if SIZEOF_VOID_P == 8
	return murmurhash64((uint64) ptr);
#else
	return murmurhash32((uint32) ptr);
#endif
}

#define SH_PREFIX		pointerhash
#define SH_ELEMENT_TYPE	PointerHashEntry
#define SH_KEY_TYPE		uintptr_t
#define	SH_KEY			ptr
#define SH_HASH_KEY(tb, key)	hash_pointer(key)
#define SH_EQUAL(tb, a, b)		(a == b)
#define	SH_SCOPE		extern
#define SH_DEFINE
#include "lib/simplehash.h"

/* Offset hash table */
static uint32
hash_offset(Size offset)
{
#if SIZEOF_SIZE_T == 8
	return murmurhash64((uint64) offset);
#else
	return murmurhash32((uint32) offset);
#endif
}

#define SH_PREFIX		offsethash
#define SH_ELEMENT_TYPE	OffsetHashEntry
#define SH_KEY_TYPE		Size
#define	SH_KEY			offset
#define SH_HASH_KEY(tb, key)	hash_offset(key)
#define SH_EQUAL(tb, a, b)		(a == b)
#define	SH_SCOPE		extern
#define SH_DEFINE
#include "lib/simplehash.h"

static bool HnswShouldAddSearchCandidate(float8 candidateDistance, float8 frontierDistance, bool alwaysAdd, bool useRust);
static bool HnswShouldStopSearchLayer(float8 candidateDistance, float8 frontierDistance, bool useRust);
static bool HnswShouldAppendNeighborWithoutPrune(int neighborsLength, int maxNeighbors, bool useRust);
static bool HnswShouldSkipLowerLevelCandidate(int candidateLevel, int searchLevel, bool useRust);
static bool HnswShouldKeepPrunedConnection(int wdoff, int wdlen, int resultLength, int maxNeighbors, bool useRust);
static bool HnswShouldSetPrunedFromArray(int wdoff, int wdlen, bool useRust);
static bool HnswShouldTrackDiscardedCandidates(bool hasDiscardedHeap, bool useRust);
static bool HnswShouldLoadElementWithMaxDistanceCap(bool alwaysAdd, bool trackDiscarded, bool useRust);
static bool HnswShouldTrackUpdateIndex(bool hasUpdateIndexPointer, bool useRust);
static bool HnswShouldProcessPrunedCandidate(bool hasPrunedCandidate, bool useRust);
static bool HnswShouldTrimCandidateList(int candidateCount, int ef, bool useRust);
static bool HnswShouldAlwaysAddCandidate(int candidateCount, int ef, bool useRust);
static bool HnswShouldLoadElementVector(bool shouldLoadVector, bool useRust);
static bool HnswShouldLoadElementHeapTids(bool shouldLoadHeaptids, bool useRust);
static bool HnswShouldStopLoadingElementHeapTids(bool heaptidValid, bool useRust);
static bool HnswShouldCountWithoutSkipElement(bool hasSkipElement, bool useRust);
static bool HnswShouldAppendUnvisitedNeighbor(bool found, bool useRust);
static bool HnswShouldAppendUnvisitedDiskNeighbor(bool found, bool useRust);
static bool HnswShouldStopLoadingDiskNeighbor(bool isValidIndexTid, bool useRust);
static bool HnswShouldAbortUnvisitedDiskLoad(bool neighborTidsLoaded, bool useRust);
static bool HnswShouldRejectStaleNeighborTuple(bool tupleConsistent, bool useRust);
static bool HnswShouldInitializeDiscardedHeap(bool hasDiscardedHeap, bool useRust);
static bool HnswShouldTrackTupleCounter(bool hasTupleCounter, bool useRust);
static bool HnswShouldInitializeVisitedHash(bool hasVisitedHash, bool useRust);
static bool HnswShouldInitializeVisitedState(bool initVisited, bool useRust);
static bool HnswShouldUseTidVisitedHash(bool inMemory, bool useRust);
static bool HnswShouldUseOffsetVisitedHash(bool hasBasePointer, bool useRust);
static bool HnswShouldUsePointerVisitedHash(bool hasBasePointer, bool useRust);
static bool HnswShouldUseMemoryEntryDistance(bool inMemory, bool useRust);
static bool HnswShouldUseInMemorySearchPath(bool inMemory, bool useRust);
static bool HnswShouldReturnWithoutEntryPoint(bool hasEntryPoint, bool useRust);
static bool HnswShouldPrecomputeHashForNeighbors(bool inMemory, bool useRust);
static bool HnswShouldIncrementEfForExistingElement(bool existing, bool useRust);
static bool HnswShouldRemoveDiskOnlyElementsBeforeSelect(bool inMemory, bool useRust);
static bool HnswShouldClampNeighborSearchLevel(int level, int entryLevel, bool useRust);
static bool HnswShouldUsePointerHashForBase(bool hasBasePointer, bool useRust);
static bool HnswShouldKeepElementWithHeapTids(int heaptidsLength, bool useRust);
static bool HnswShouldCountCandidateWithHeapTids(int heaptidsLength, bool useRust);
static bool HnswShouldSkipSelfForVacuumUpdate(bool hasSkipElement, int elementBlkno, int elementOffno, int skipBlkno, int skipOffno, bool useRust);
static bool HnswShouldUseSkipElementForExisting(bool existing, bool useRust);
static bool HnswShouldUseDefaultSkipElementTid(bool hasSkipElement, bool useRust);
static int HnswGetSkipElementBlknoForCompare(HnswElement skipElement, bool useRust);
static int HnswGetSkipElementOffnoForCompare(HnswElement skipElement, bool useRust);
static bool HnswShouldUseDefaultTypeInfo(bool hasProcInfo, bool useRust);
static bool HnswShouldRejectSparsevecExcessNnz(int nnz, int maxNnz, bool useRust);
static bool HnswShouldSortNeighborCandidates(bool sortCandidates, bool useRust);
static bool HnswShouldSortPointerCandidates(bool hasBasePointer, bool useRust);
static bool HnswShouldCalculateNeighborCloser(bool mustCalculate, bool useRust);
static bool HnswShouldReuseAddedCandidates(int addedCount, bool useRust);
static bool HnswShouldDefineCloserStateForBase(bool hasBasePointer, bool useRust);
static bool HnswShouldAppendCloserCandidate(bool isCloser, bool useRust);
static bool HnswShouldRecheckCandidateAfterRemoval(bool removedAny, bool useRust);
static bool HnswShouldReturnPrunedOutput(bool hasPrunedOutput, bool useRust);
static bool HnswShouldProcessNewCandidateBranch(bool isNewCandidate, bool useRust);
static bool HnswShouldReplacePrunedNeighbor(bool matchesPrunedNeighbor, bool useRust);
static bool HnswShouldAbortWithoutPrunedCandidate(bool hasPrunedCandidate, bool useRust);
static bool HnswShouldEnqueueCountedCandidate(bool countedCandidate, bool useRust);
static bool HnswShouldSkipMissingSearchElement(bool hasSearchElement, bool useRust);
static bool HnswShouldCopyTupleSlotByIndex(int slotIndex, int slotLimit, bool useRust);
static bool HnswShouldCapElementLevel(int level, int maxLevel, bool useRust);
static bool HnswShouldUseIndexOptions(bool hasOptions, bool useRust);
static bool HnswShouldHaveIndexOptionsFlag(bool hasOptions, bool useRust);
static bool HnswShouldHaveIndexOptions(HnswOptions *opts, bool useRust);
static bool HnswShouldReturnMissingOptionalProc(bool hasProcOid, bool useRust);
static bool HnswShouldUseCustomAllocator(bool hasAllocator, bool useRust);
static bool HnswShouldHaveCustomAllocatorFlag(bool hasAllocator, bool useRust);
static bool HnswShouldHaveCustomAllocator(HnswAllocator *allocator, bool useRust);
static bool HnswShouldLoadMetaM(bool hasMOutputPointer, bool useRust);
static bool HnswShouldLoadMetaEntrypoint(bool hasEntrypointOutputPointer, bool useRust);
static bool HnswShouldUseMetaEntryBlock(bool hasValidEntryBlock, bool useRust);
static bool HnswShouldUpdateMetaEntryInfo(int updateEntry, bool useRust);
static bool HnswShouldResetMetaEntrypoint(bool hasEntrypoint, bool useRust);
static bool HnswShouldForceMetaEntryUpdate(int updateEntry, bool useRust);
static bool HnswShouldWriteMetaEntrypoint(bool hasEntrypoint, int entryLevel, int currentEntryLevel, int updateEntry, bool useRust);
static bool HnswShouldWriteMetaInsertPage(bool hasValidInsertPage, bool useRust);
static bool HnswShouldUseBuildBufferPath(bool building, bool useRust);
static bool HnswShouldCheckTypeValue(bool hasCheckValueFunction, bool useRust);
static bool HnswShouldHaveTypeCheckFunctionFlag(bool hasCheckValueFunction, bool useRust);
static bool HnswShouldHaveTypeCheckFunction(void (*checkValue) (Pointer v), bool useRust);
static bool HnswShouldNormalizeIndexValue(bool hasNormProcInfo, bool useRust);
static bool HnswShouldHaveNormProcInfoFlag(bool hasNormProcInfo, bool useRust);
static bool HnswShouldHaveNormProcInfo(FmgrInfo *normprocinfo, bool useRust);
static bool HnswShouldRejectInvalidNorm(bool hasValidNorm, bool useRust);
static bool HnswShouldPrioritizeLowerDistance(double leftDistance, double rightDistance, bool useRust);
static bool HnswShouldPrioritizePointerTiebreak(bool leftPointerPrecedes, bool useRust);
static bool HnswShouldPrioritizeOffsetTiebreak(bool leftOffsetPrecedes, bool useRust);
static bool HnswShouldRejectInvalidMetaMagic(bool hasExpectedMagic, bool useRust);

/*
 * Get the max number of connections in an upper layer for each element in the index
 */
int
HnswGetM(Relation index)
{
	HnswOptions *opts = (HnswOptions *) index->rd_options;

	if (HnswShouldUseIndexOptions(HnswShouldHaveIndexOptions(opts, true), true))
		return opts->m;

	return HNSW_DEFAULT_M;
}

/*
 * Get the size of the dynamic candidate list in the index
 */
int
HnswGetEfConstruction(Relation index)
{
	HnswOptions *opts = (HnswOptions *) index->rd_options;

	if (HnswShouldUseIndexOptions(HnswShouldHaveIndexOptions(opts, true), true))
		return opts->efConstruction;

	return HNSW_DEFAULT_EF_CONSTRUCTION;
}

/*
 * Get proc
 */
FmgrInfo *
HnswOptionalProcInfo(Relation index, uint16 procnum)
{
	if (HnswShouldReturnMissingOptionalProc(OidIsValid(index_getprocid(index, 1, procnum)), true))
		return NULL;

	return index_getprocinfo(index, 1, procnum);
}

/*
 * Init support functions
 */
void
HnswInitSupport(HnswSupport * support, Relation index)
{
	support->procinfo = index_getprocinfo(index, 1, HNSW_DISTANCE_PROC);
	support->collation = index->rd_indcollation[0];
	support->normprocinfo = HnswOptionalProcInfo(index, HNSW_NORM_PROC);
}

/*
 * Normalize value
 */
Datum
HnswNormValue(const HnswTypeInfo * typeInfo, Oid collation, Datum value)
{
	return DirectFunctionCall1Coll(typeInfo->normalize, collation, value);
}

/*
 * Check if non-zero norm
 */
bool
HnswCheckNorm(HnswSupport * support, Datum value)
{
	return DatumGetFloat8(FunctionCall1Coll(support->normprocinfo, support->collation, value)) > 0;
}

/*
 * New buffer
 */
Buffer
HnswNewBuffer(Relation index, ForkNumber forkNum)
{
	Buffer		buf = ReadBufferExtended(index, forkNum, P_NEW, RBM_NORMAL, NULL);

	LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
	return buf;
}

/*
 * Init page
 */
void
HnswInitPage(Buffer buf, Page page)
{
	PageInit(page, BufferGetPageSize(buf), sizeof(HnswPageOpaqueData));
	HnswPageGetOpaque(page)->nextblkno = InvalidBlockNumber;
	HnswPageGetOpaque(page)->page_id = HNSW_PAGE_ID;
}

/*
 * Allocate a neighbor array
 */
HnswNeighborArray *
HnswInitNeighborArray(int lm, HnswAllocator * allocator)
{
	HnswNeighborArray *a = HnswAlloc(allocator, HNSW_NEIGHBOR_ARRAY_SIZE(lm));

	a->length = 0;
	a->closerSet = false;
	return a;
}

/*
 * Allocate neighbors
 */
void
HnswInitNeighbors(char *base, HnswElement element, int m, HnswAllocator * allocator)
{
	int			level = element->level;
	HnswNeighborArrayPtr *neighborList = (HnswNeighborArrayPtr *) HnswAlloc(allocator, sizeof(HnswNeighborArrayPtr) * (level + 1));

	HnswPtrStore(base, element->neighbors, neighborList);

	for (int lc = 0; lc <= level; lc++)
		HnswPtrStore(base, neighborList[lc], HnswInitNeighborArray(HnswGetLayerM(m, lc), allocator));
}

/*
 * Allocate memory from the allocator
 */
void *
HnswAlloc(HnswAllocator * allocator, Size size)
{
	if (HnswShouldUseCustomAllocator(HnswShouldHaveCustomAllocator(allocator, true), true))
		return (*(allocator)->alloc) (size, (allocator)->state);

	return palloc(size);
}

/*
 * Allocate an element
 */
HnswElement
HnswInitElement(char *base, ItemPointer heaptid, int m, double ml, int maxLevel, HnswAllocator * allocator)
{
	HnswElement element = HnswAlloc(allocator, sizeof(HnswElementData));

	int			level = (int) (-log(RandomDouble()) * ml);

	/* Cap level */
	if (HnswShouldCapElementLevel(level, maxLevel, true))
		level = maxLevel;

	element->heaptidsLength = 0;
	HnswAddHeapTid(element, heaptid);

	element->level = level;
	element->deleted = 0;
	/* Start at one to make it easier to find issues */
	element->version = 1;

	HnswInitNeighbors(base, element, m, allocator);

	HnswPtrStore(base, element->value, (char *) NULL);

	return element;
}

/*
 * Add a heap TID to an element
 */
void
HnswAddHeapTid(HnswElement element, ItemPointer heaptid)
{
	element->heaptids[element->heaptidsLength++] = *heaptid;
}

/*
 * Allocate an element from block and offset numbers
 */
HnswElement
HnswInitElementFromBlock(BlockNumber blkno, OffsetNumber offno)
{
	HnswElement element = palloc(sizeof(HnswElementData));
	char	   *base = NULL;

	element->blkno = blkno;
	element->offno = offno;
	HnswPtrStore(base, element->neighbors, (HnswNeighborArrayPtr *) NULL);
	HnswPtrStore(base, element->value, (char *) NULL);
	return element;
}

/*
 * Get the metapage info
 */
void
HnswGetMetaPageInfo(Relation index, int *m, HnswElement * entryPoint)
{
	Buffer		buf;
	Page		page;
	HnswMetaPage metap;

	buf = ReadBuffer(index, HNSW_METAPAGE_BLKNO);
	LockBuffer(buf, BUFFER_LOCK_SHARE);
	page = BufferGetPage(buf);
	metap = HnswPageGetMeta(page);

	if (unlikely(HnswShouldRejectInvalidMetaMagic(metap->magicNumber == HNSW_MAGIC_NUMBER, true)))
		elog(ERROR, "hnsw index is not valid");

	if (HnswShouldLoadMetaM(m != NULL, true))
		*m = metap->m;

	if (HnswShouldLoadMetaEntrypoint(entryPoint != NULL, true))
	{
		if (HnswShouldUseMetaEntryBlock(BlockNumberIsValid(metap->entryBlkno), true))
		{
			*entryPoint = HnswInitElementFromBlock(metap->entryBlkno, metap->entryOffno);
			(*entryPoint)->level = metap->entryLevel;
		}
		else
			*entryPoint = NULL;
	}

	UnlockReleaseBuffer(buf);
}

/*
 * Get the entry point
 */
HnswElement
HnswGetEntryPoint(Relation index)
{
	HnswElement entryPoint;

	HnswGetMetaPageInfo(index, NULL, &entryPoint);

	return entryPoint;
}

/*
 * Update the metapage info
 */
static void
HnswUpdateMetaPageInfo(Page page, int updateEntry, HnswElement entryPoint, BlockNumber insertPage)
{
	HnswMetaPage metap = HnswPageGetMeta(page);

	if (HnswShouldUpdateMetaEntryInfo(updateEntry, true))
	{
		if (HnswShouldResetMetaEntrypoint(entryPoint != NULL, true))
		{
			metap->entryBlkno = InvalidBlockNumber;
			metap->entryOffno = InvalidOffsetNumber;
			metap->entryLevel = -1;
		}
		else if (HnswShouldWriteMetaEntrypoint(entryPoint != NULL, entryPoint->level, metap->entryLevel, updateEntry, true))
		{
			metap->entryBlkno = entryPoint->blkno;
			metap->entryOffno = entryPoint->offno;
			metap->entryLevel = entryPoint->level;
		}
	}

	if (HnswShouldWriteMetaInsertPage(BlockNumberIsValid(insertPage), true))
		metap->insertPage = insertPage;
}

/*
 * Update the metapage
 */
void
HnswUpdateMetaPage(Relation index, int updateEntry, HnswElement entryPoint, BlockNumber insertPage, ForkNumber forkNum, bool building)
{
	Buffer		buf;
	Page		page;
	GenericXLogState *state;

	buf = ReadBufferExtended(index, forkNum, HNSW_METAPAGE_BLKNO, RBM_NORMAL, NULL);
	LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
	if (HnswShouldUseBuildBufferPath(building, true))
	{
		state = NULL;
		page = BufferGetPage(buf);
	}
	else
	{
		state = GenericXLogStart(index);
		page = GenericXLogRegisterBuffer(state, buf, 0);
	}

	HnswUpdateMetaPageInfo(page, updateEntry, entryPoint, insertPage);

	if (HnswShouldUseBuildBufferPath(building, true))
		MarkBufferDirty(buf);
	else
		GenericXLogFinish(state);
	UnlockReleaseBuffer(buf);
}

/*
 * Form index value
 */
bool
HnswFormIndexValue(Datum *out, Datum *values, bool *isnull, const HnswTypeInfo * typeInfo, HnswSupport * support)
{
	/* Detoast once for all calls */
	Datum		value = PointerGetDatum(PG_DETOAST_DATUM(values[0]));

	/* Check value */
	if (HnswShouldCheckTypeValue(HnswShouldHaveTypeCheckFunction(typeInfo->checkValue, true), true))
		typeInfo->checkValue(DatumGetPointer(value));

	/* Normalize if needed */
	if (HnswShouldNormalizeIndexValue(HnswShouldHaveNormProcInfo(support->normprocinfo, true), true))
	{
		if (HnswShouldRejectInvalidNorm(HnswCheckNorm(support, value), true))
			return false;

		value = HnswNormValue(typeInfo, support->collation, value);
	}

	*out = value;

	return true;
}

/*
 * Set element tuple, except for neighbor info
 */
void
HnswSetElementTuple(char *base, HnswElementTuple etup, HnswElement element)
{
	Pointer		valuePtr = HnswPtrAccess(base, element->value);

	etup->type = HNSW_ELEMENT_TUPLE_TYPE;
	etup->level = element->level;
	etup->deleted = 0;
	etup->version = element->version;
	for (int i = 0; i < HNSW_HEAPTIDS; i++)
	{
		if (HnswShouldCopyTupleSlotByIndex(i, element->heaptidsLength, true))
			etup->heaptids[i] = element->heaptids[i];
		else
			ItemPointerSetInvalid(&etup->heaptids[i]);
	}
	memcpy(&etup->data, valuePtr, VARSIZE_ANY(valuePtr));
}

/*
 * Set neighbor tuple
 */
void
HnswSetNeighborTuple(char *base, HnswNeighborTuple ntup, HnswElement e, int m)
{
	int			idx = 0;

	ntup->type = HNSW_NEIGHBOR_TUPLE_TYPE;

	for (int lc = e->level; lc >= 0; lc--)
	{
		HnswNeighborArray *neighbors = HnswGetNeighbors(base, e, lc);
		int			lm = HnswGetLayerM(m, lc);

		for (int i = 0; i < lm; i++)
		{
			ItemPointer indextid = &ntup->indextids[idx++];

			if (HnswShouldCopyTupleSlotByIndex(i, neighbors->length, true))
			{
				HnswCandidate *hc = &neighbors->items[i];
				HnswElement hce = HnswPtrAccess(base, hc->element);

				ItemPointerSet(indextid, hce->blkno, hce->offno);
			}
			else
				ItemPointerSetInvalid(indextid);
		}
	}

	ntup->count = idx;
	ntup->version = e->version;
}

/*
 * Load an element from a tuple
 */
void
HnswLoadElementFromTuple(HnswElement element, HnswElementTuple etup, bool loadHeaptids, bool loadVec)
{
	element->level = etup->level;
	element->deleted = etup->deleted;
	element->version = etup->version;
	element->neighborPage = ItemPointerGetBlockNumber(&etup->neighbortid);
	element->neighborOffno = ItemPointerGetOffsetNumber(&etup->neighbortid);
	element->heaptidsLength = 0;

	if (HnswShouldLoadElementHeapTids(loadHeaptids, true))
	{
		for (int i = 0; i < HNSW_HEAPTIDS; i++)
		{
			/* Can stop at first invalid */
			if (HnswShouldStopLoadingElementHeapTids(ItemPointerIsValid(&etup->heaptids[i]), true))
				break;

			HnswAddHeapTid(element, &etup->heaptids[i]);
		}
	}

	if (HnswShouldLoadElementVector(loadVec, true))
	{
		char	   *base = NULL;
		Datum		value = datumCopy(PointerGetDatum(&etup->data), false, -1);

		HnswPtrStore(base, element->value, (char *) DatumGetPointer(value));
	}
}

/*
 * Calculate the distance between values
 */
static inline double
HnswGetDistance(Datum a, Datum b, HnswSupport * support)
{
	return DatumGetFloat8(FunctionCall2Coll(support->procinfo, support->collation, a, b));
}

static bool
HnswShouldZeroDistanceForNullQueryValue(bool hasQueryValue, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasQueryValue);

	return !hasQueryValue;
}

static bool
HnswShouldCalculateElementDistance(bool hasDistancePointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasDistancePointer);

	return hasDistancePointer;
}

static bool
HnswShouldUpdateElementMaxDistance(bool hasDistancePointer, bool hasMaxDistancePointer, double distanceValue, double maxDistanceValue, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_element_max_distance_kernel(hasDistancePointer, hasMaxDistancePointer, distanceValue, maxDistanceValue);

	return !hasDistancePointer || !hasMaxDistancePointer || distanceValue < maxDistanceValue;
}

static bool
HnswShouldUseDefaultDistanceValue(bool hasDistancePointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasDistancePointer);

	return !hasDistancePointer;
}

static bool
HnswShouldUseDefaultMaxDistanceValue(bool hasMaxDistancePointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasMaxDistancePointer);

	return !hasMaxDistancePointer;
}

static bool
HnswShouldInitializeLoadedElement(bool hasElement, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasElement);

	return !hasElement;
}

static bool
HnswShouldLoadElementVector(bool shouldLoadVector, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(shouldLoadVector);

	return shouldLoadVector;
}

static bool
HnswShouldLoadElementHeapTids(bool shouldLoadHeaptids, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(shouldLoadHeaptids);

	return shouldLoadHeaptids;
}

static bool
HnswShouldStopLoadingElementHeapTids(bool heaptidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(heaptidValid);

	return !heaptidValid;
}

static bool
HnswShouldCountWithoutSkipElement(bool hasSkipElement, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasSkipElement);

	return !hasSkipElement;
}

static bool
HnswShouldAppendUnvisitedNeighbor(bool found, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(found);

	return !found;
}

static bool
HnswShouldAppendUnvisitedDiskNeighbor(bool found, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(found);

	return !found;
}

static bool
HnswShouldStopLoadingDiskNeighbor(bool isValidIndexTid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(isValidIndexTid);

	return !isValidIndexTid;
}

static bool
HnswShouldAbortUnvisitedDiskLoad(bool neighborTidsLoaded, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(neighborTidsLoaded);

	return !neighborTidsLoaded;
}

static bool
HnswShouldRejectStaleNeighborTuple(bool tupleConsistent, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(tupleConsistent);

	return !tupleConsistent;
}

static bool
HnswShouldInitializeDiscardedHeap(bool hasDiscardedHeap, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasDiscardedHeap);

	return hasDiscardedHeap;
}

static bool
HnswShouldTrackTupleCounter(bool hasTupleCounter, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasTupleCounter);

	return hasTupleCounter;
}

static bool
HnswShouldInitializeVisitedHash(bool hasVisitedHash, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasVisitedHash);

	return !hasVisitedHash;
}

static bool
HnswShouldInitializeVisitedState(bool initVisited, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(initVisited);

	return initVisited;
}

static bool
HnswShouldUseTidVisitedHash(bool inMemory, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(inMemory);

	return !inMemory;
}

static bool
HnswShouldUseOffsetVisitedHash(bool hasBasePointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasBasePointer);

	return hasBasePointer;
}

static bool
HnswShouldUsePointerVisitedHash(bool hasBasePointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasBasePointer);

	return !hasBasePointer;
}

static bool
HnswShouldUseMemoryEntryDistance(bool inMemory, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(inMemory);

	return inMemory;
}

static bool
HnswShouldUseInMemorySearchPath(bool inMemory, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(inMemory);

	return inMemory;
}

static bool
HnswShouldReturnWithoutEntryPoint(bool hasEntryPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasEntryPoint);

	return !hasEntryPoint;
}

static bool
HnswShouldPrecomputeHashForNeighbors(bool inMemory, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(inMemory);

	return inMemory;
}

static bool
HnswShouldIncrementEfForExistingElement(bool existing, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(existing);

	return existing;
}

static bool
HnswShouldRemoveDiskOnlyElementsBeforeSelect(bool inMemory, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(inMemory);

	return !inMemory;
}

static bool
HnswShouldClampNeighborSearchLevel(int level, int entryLevel, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_entry_point_kernel(false, level, entryLevel);

	return level > entryLevel;
}

static bool
HnswShouldUsePointerHashForBase(bool hasBasePointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasBasePointer);

	return !hasBasePointer;
}

static bool
HnswShouldKeepElementWithHeapTids(int heaptidsLength, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(heaptidsLength != 0);

	return heaptidsLength != 0;
}

static bool
HnswShouldCountCandidateWithHeapTids(int heaptidsLength, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(heaptidsLength != 0);

	return heaptidsLength != 0;
}

static bool
HnswShouldSkipSelfForVacuumUpdate(bool hasSkipElement, int elementBlkno, int elementOffno, int skipBlkno, int skipOffno, bool useRust)
{
	if (useRust)
	{
		bool		hasElementToSkip = vector_rust_hnsw_should_update_progress_after_insert_kernel(hasSkipElement);
		bool		matchesSkipElement = vector_rust_hnsw_should_match_neighbor_connection_kernel(elementBlkno, elementOffno, skipBlkno, skipOffno);

		return hasElementToSkip && matchesSkipElement;
	}

	return hasSkipElement && elementBlkno == skipBlkno && elementOffno == skipOffno;
}

static bool
HnswShouldUseSkipElementForExisting(bool existing, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(existing);

	return existing;
}

static bool
HnswShouldUseDefaultSkipElementTid(bool hasSkipElement, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasSkipElement);

	return !hasSkipElement;
}

static int
HnswGetSkipElementBlknoForCompare(HnswElement skipElement, bool useRust)
{
	if (HnswShouldUseDefaultSkipElementTid(skipElement != NULL, useRust))
		return 0;

	return skipElement->blkno;
}

static int
HnswGetSkipElementOffnoForCompare(HnswElement skipElement, bool useRust)
{
	if (HnswShouldUseDefaultSkipElementTid(skipElement != NULL, useRust))
		return 0;

	return skipElement->offno;
}

static bool
HnswShouldUseDefaultTypeInfo(bool hasProcInfo, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasProcInfo);

	return !hasProcInfo;
}

static bool
HnswShouldRejectSparsevecExcessNnz(int nnz, int maxNnz, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_excess_dimensions_kernel(nnz, maxNnz);

	return nnz > maxNnz;
}

static bool
HnswShouldSortNeighborCandidates(bool sortCandidates, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(sortCandidates);

	return sortCandidates;
}

static bool
HnswShouldSortPointerCandidates(bool hasBasePointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasBasePointer);

	return !hasBasePointer;
}

static bool
HnswShouldCalculateNeighborCloser(bool mustCalculate, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(mustCalculate);

	return mustCalculate;
}

static bool
HnswShouldReuseAddedCandidates(int addedCount, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(addedCount > 0);

	return addedCount > 0;
}

static bool
HnswShouldDefineCloserStateForBase(bool hasBasePointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasBasePointer);

	return hasBasePointer;
}

static bool
HnswShouldAppendCloserCandidate(bool isCloser, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isCloser);

	return isCloser;
}

static bool
HnswShouldRecheckCandidateAfterRemoval(bool removedAny, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(removedAny);

	return removedAny;
}

static bool
HnswShouldReturnPrunedOutput(bool hasPrunedOutput, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasPrunedOutput);

	return hasPrunedOutput;
}

static bool
HnswShouldProcessNewCandidateBranch(bool isNewCandidate, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isNewCandidate);

	return isNewCandidate;
}

static bool
HnswShouldReplacePrunedNeighbor(bool matchesPrunedNeighbor, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(matchesPrunedNeighbor);

	return matchesPrunedNeighbor;
}

static bool
HnswShouldAbortWithoutPrunedCandidate(bool hasPrunedCandidate, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasPrunedCandidate);

	return !hasPrunedCandidate;
}

static bool
HnswShouldEnqueueCountedCandidate(bool countedCandidate, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(countedCandidate);

	return countedCandidate;
}

static bool
HnswShouldSkipMissingSearchElement(bool hasSearchElement, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasSearchElement);

	return !hasSearchElement;
}

static bool
HnswShouldCopyTupleSlotByIndex(int slotIndex, int slotLimit, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(slotIndex < slotLimit);

	return slotIndex < slotLimit;
}

static bool
HnswShouldCapElementLevel(int level, int maxLevel, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_excess_dimensions_kernel(level, maxLevel);

	return level > maxLevel;
}

static bool
HnswShouldUseIndexOptions(bool hasOptions, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasOptions);

	return hasOptions;
}

static bool
HnswShouldHaveIndexOptionsFlag(bool hasOptions, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasOptions);

	return hasOptions;
}

static bool
HnswShouldHaveIndexOptions(HnswOptions *opts, bool useRust)
{
	return HnswShouldHaveIndexOptionsFlag(opts != NULL, useRust);
}

static bool
HnswShouldReturnMissingOptionalProc(bool hasProcOid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasProcOid);

	return !hasProcOid;
}

static bool
HnswShouldUseCustomAllocator(bool hasAllocator, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasAllocator);

	return hasAllocator;
}

static bool
HnswShouldHaveCustomAllocatorFlag(bool hasAllocator, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasAllocator);

	return hasAllocator;
}

static bool
HnswShouldHaveCustomAllocator(HnswAllocator *allocator, bool useRust)
{
	return HnswShouldHaveCustomAllocatorFlag(allocator != NULL, useRust);
}

static bool
HnswShouldLoadMetaM(bool hasMOutputPointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasMOutputPointer);

	return hasMOutputPointer;
}

static bool
HnswShouldLoadMetaEntrypoint(bool hasEntrypointOutputPointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasEntrypointOutputPointer);

	return hasEntrypointOutputPointer;
}

static bool
HnswShouldUseMetaEntryBlock(bool hasValidEntryBlock, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasValidEntryBlock);

	return hasValidEntryBlock;
}

static bool
HnswShouldUpdateMetaEntryInfo(int updateEntry, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(updateEntry != 0);

	return updateEntry != 0;
}

static bool
HnswShouldResetMetaEntrypoint(bool hasEntrypoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasEntrypoint);

	return !hasEntrypoint;
}

static bool
HnswShouldForceMetaEntryUpdate(int updateEntry, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(updateEntry == HNSW_UPDATE_ENTRY_ALWAYS);

	return updateEntry == HNSW_UPDATE_ENTRY_ALWAYS;
}

static bool
HnswShouldWriteMetaEntrypoint(bool hasEntrypoint, int entryLevel, int currentEntryLevel, int updateEntry, bool useRust)
{
	if (useRust)
	{
		if (HnswShouldForceMetaEntryUpdate(updateEntry, true))
			return true;

		return vector_rust_hnsw_should_update_entry_point_kernel(!hasEntrypoint, entryLevel, currentEntryLevel);
	}

	return !hasEntrypoint || entryLevel > currentEntryLevel || HnswShouldForceMetaEntryUpdate(updateEntry, false);
}

static bool
HnswShouldWriteMetaInsertPage(bool hasValidInsertPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasValidInsertPage);

	return hasValidInsertPage;
}

static bool
HnswShouldUseBuildBufferPath(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(building);

	return building;
}

static bool
HnswShouldCheckTypeValue(bool hasCheckValueFunction, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasCheckValueFunction);

	return hasCheckValueFunction;
}

static bool
HnswShouldHaveTypeCheckFunctionFlag(bool hasCheckValueFunction, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasCheckValueFunction);

	return hasCheckValueFunction;
}

static bool
HnswShouldHaveTypeCheckFunction(void (*checkValue) (Pointer v), bool useRust)
{
	return HnswShouldHaveTypeCheckFunctionFlag(checkValue != NULL, useRust);
}

static bool
HnswShouldNormalizeIndexValue(bool hasNormProcInfo, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasNormProcInfo);

	return hasNormProcInfo;
}

static bool
HnswShouldHaveNormProcInfoFlag(bool hasNormProcInfo, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasNormProcInfo);

	return hasNormProcInfo;
}

static bool
HnswShouldHaveNormProcInfo(FmgrInfo *normprocinfo, bool useRust)
{
	return HnswShouldHaveNormProcInfoFlag(normprocinfo != NULL, useRust);
}

static bool
HnswShouldRejectInvalidNorm(bool hasValidNorm, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasValidNorm);

	return !hasValidNorm;
}

static bool
HnswShouldPrioritizeLowerDistance(double leftDistance, double rightDistance, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_element_max_distance_kernel(true, true, leftDistance, rightDistance);

	return leftDistance < rightDistance;
}

static bool
HnswShouldPrioritizePointerTiebreak(bool leftPointerPrecedes, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(leftPointerPrecedes);

	return leftPointerPrecedes;
}

static bool
HnswShouldPrioritizeOffsetTiebreak(bool leftOffsetPrecedes, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(leftOffsetPrecedes);

	return leftOffsetPrecedes;
}

static bool
HnswShouldRejectInvalidMetaMagic(bool hasExpectedMagic, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasExpectedMagic);

	return !hasExpectedMagic;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_zero_distance_for_null_query_value);
Datum
vector_hnsw_should_zero_distance_for_null_query_value(PG_FUNCTION_ARGS)
{
	int32		hasQueryValue = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldZeroDistanceForNullQueryValue(hasQueryValue != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_zero_distance_for_null_query_value);
Datum
vector_rust_hnsw_should_zero_distance_for_null_query_value(PG_FUNCTION_ARGS)
{
	int32		hasQueryValue = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldZeroDistanceForNullQueryValue(hasQueryValue != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_calculate_element_distance);
Datum
vector_hnsw_should_calculate_element_distance(PG_FUNCTION_ARGS)
{
	int32		hasDistancePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCalculateElementDistance(hasDistancePointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_calculate_element_distance);
Datum
vector_rust_hnsw_should_calculate_element_distance(PG_FUNCTION_ARGS)
{
	int32		hasDistancePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCalculateElementDistance(hasDistancePointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_element_max_distance);
Datum
vector_hnsw_should_update_element_max_distance(PG_FUNCTION_ARGS)
{
	int32		hasDistancePointer = PG_GETARG_INT32(0);
	int32		hasMaxDistancePointer = PG_GETARG_INT32(1);
	float8		distanceValue = PG_GETARG_FLOAT8(2);
	float8		maxDistanceValue = PG_GETARG_FLOAT8(3);

	PG_RETURN_BOOL(HnswShouldUpdateElementMaxDistance(hasDistancePointer != 0, hasMaxDistancePointer != 0, distanceValue, maxDistanceValue, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_element_max_distance);
Datum
vector_rust_hnsw_should_update_element_max_distance(PG_FUNCTION_ARGS)
{
	int32		hasDistancePointer = PG_GETARG_INT32(0);
	int32		hasMaxDistancePointer = PG_GETARG_INT32(1);
	float8		distanceValue = PG_GETARG_FLOAT8(2);
	float8		maxDistanceValue = PG_GETARG_FLOAT8(3);

	PG_RETURN_BOOL(HnswShouldUpdateElementMaxDistance(hasDistancePointer != 0, hasMaxDistancePointer != 0, distanceValue, maxDistanceValue, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_default_distance_value);
Datum
vector_hnsw_should_use_default_distance_value(PG_FUNCTION_ARGS)
{
	int32		hasDistancePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultDistanceValue(hasDistancePointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_default_distance_value);
Datum
vector_rust_hnsw_should_use_default_distance_value(PG_FUNCTION_ARGS)
{
	int32		hasDistancePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultDistanceValue(hasDistancePointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_default_max_distance_value);
Datum
vector_hnsw_should_use_default_max_distance_value(PG_FUNCTION_ARGS)
{
	int32		hasMaxDistancePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultMaxDistanceValue(hasMaxDistancePointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_default_max_distance_value);
Datum
vector_rust_hnsw_should_use_default_max_distance_value(PG_FUNCTION_ARGS)
{
	int32		hasMaxDistancePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultMaxDistanceValue(hasMaxDistancePointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_initialize_loaded_element);
Datum
vector_hnsw_should_initialize_loaded_element(PG_FUNCTION_ARGS)
{
	int32		hasElement = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeLoadedElement(hasElement != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_initialize_loaded_element);
Datum
vector_rust_hnsw_should_initialize_loaded_element(PG_FUNCTION_ARGS)
{
	int32		hasElement = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeLoadedElement(hasElement != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_load_element_vector);
Datum
vector_hnsw_should_load_element_vector(PG_FUNCTION_ARGS)
{
	int32		shouldLoadVector = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLoadElementVector(shouldLoadVector != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_load_element_vector);
Datum
vector_rust_hnsw_should_load_element_vector(PG_FUNCTION_ARGS)
{
	int32		shouldLoadVector = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLoadElementVector(shouldLoadVector != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_load_element_heaptids);
Datum
vector_hnsw_should_load_element_heaptids(PG_FUNCTION_ARGS)
{
	int32		shouldLoadHeaptids = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLoadElementHeapTids(shouldLoadHeaptids != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_load_element_heaptids);
Datum
vector_rust_hnsw_should_load_element_heaptids(PG_FUNCTION_ARGS)
{
	int32		shouldLoadHeaptids = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLoadElementHeapTids(shouldLoadHeaptids != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_loading_element_heaptids);
Datum
vector_hnsw_should_stop_loading_element_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopLoadingElementHeapTids(heaptidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_loading_element_heaptids);
Datum
vector_rust_hnsw_should_stop_loading_element_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopLoadingElementHeapTids(heaptidValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_count_without_skip_element);
Datum
vector_hnsw_should_count_without_skip_element(PG_FUNCTION_ARGS)
{
	int32		hasSkipElement = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCountWithoutSkipElement(hasSkipElement != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_count_without_skip_element);
Datum
vector_rust_hnsw_should_count_without_skip_element(PG_FUNCTION_ARGS)
{
	int32		hasSkipElement = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCountWithoutSkipElement(hasSkipElement != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_append_unvisited_neighbor);
Datum
vector_hnsw_should_append_unvisited_neighbor(PG_FUNCTION_ARGS)
{
	int32		found = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAppendUnvisitedNeighbor(found != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_append_unvisited_neighbor);
Datum
vector_rust_hnsw_should_append_unvisited_neighbor(PG_FUNCTION_ARGS)
{
	int32		found = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAppendUnvisitedNeighbor(found != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_append_unvisited_disk_neighbor);
Datum
vector_hnsw_should_append_unvisited_disk_neighbor(PG_FUNCTION_ARGS)
{
	int32		found = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAppendUnvisitedDiskNeighbor(found != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_append_unvisited_disk_neighbor);
Datum
vector_rust_hnsw_should_append_unvisited_disk_neighbor(PG_FUNCTION_ARGS)
{
	int32		found = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAppendUnvisitedDiskNeighbor(found != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_loading_disk_neighbor);
Datum
vector_hnsw_should_stop_loading_disk_neighbor(PG_FUNCTION_ARGS)
{
	int32		isValidIndexTid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopLoadingDiskNeighbor(isValidIndexTid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_loading_disk_neighbor);
Datum
vector_rust_hnsw_should_stop_loading_disk_neighbor(PG_FUNCTION_ARGS)
{
	int32		isValidIndexTid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopLoadingDiskNeighbor(isValidIndexTid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_abort_unvisited_disk_load);
Datum
vector_hnsw_should_abort_unvisited_disk_load(PG_FUNCTION_ARGS)
{
	int32		neighborTidsLoaded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortUnvisitedDiskLoad(neighborTidsLoaded != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_abort_unvisited_disk_load);
Datum
vector_rust_hnsw_should_abort_unvisited_disk_load(PG_FUNCTION_ARGS)
{
	int32		neighborTidsLoaded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortUnvisitedDiskLoad(neighborTidsLoaded != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_stale_neighbor_tuple);
Datum
vector_hnsw_should_reject_stale_neighbor_tuple(PG_FUNCTION_ARGS)
{
	int32		tupleConsistent = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectStaleNeighborTuple(tupleConsistent != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_stale_neighbor_tuple);
Datum
vector_rust_hnsw_should_reject_stale_neighbor_tuple(PG_FUNCTION_ARGS)
{
	int32		tupleConsistent = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectStaleNeighborTuple(tupleConsistent != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_initialize_discarded_heap);
Datum
vector_hnsw_should_initialize_discarded_heap(PG_FUNCTION_ARGS)
{
	int32		hasDiscardedHeap = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeDiscardedHeap(hasDiscardedHeap != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_initialize_discarded_heap);
Datum
vector_rust_hnsw_should_initialize_discarded_heap(PG_FUNCTION_ARGS)
{
	int32		hasDiscardedHeap = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeDiscardedHeap(hasDiscardedHeap != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_track_tuple_counter);
Datum
vector_hnsw_should_track_tuple_counter(PG_FUNCTION_ARGS)
{
	int32		hasTupleCounter = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTrackTupleCounter(hasTupleCounter != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_track_tuple_counter);
Datum
vector_rust_hnsw_should_track_tuple_counter(PG_FUNCTION_ARGS)
{
	int32		hasTupleCounter = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTrackTupleCounter(hasTupleCounter != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_initialize_visited_hash);
Datum
vector_hnsw_should_initialize_visited_hash(PG_FUNCTION_ARGS)
{
	int32		hasVisitedHash = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeVisitedHash(hasVisitedHash != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_initialize_visited_hash);
Datum
vector_rust_hnsw_should_initialize_visited_hash(PG_FUNCTION_ARGS)
{
	int32		hasVisitedHash = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeVisitedHash(hasVisitedHash != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_initialize_visited_state);
Datum
vector_hnsw_should_initialize_visited_state(PG_FUNCTION_ARGS)
{
	int32		initVisited = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeVisitedState(initVisited != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_initialize_visited_state);
Datum
vector_rust_hnsw_should_initialize_visited_state(PG_FUNCTION_ARGS)
{
	int32		initVisited = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeVisitedState(initVisited != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_tid_visited_hash);
Datum
vector_hnsw_should_use_tid_visited_hash(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseTidVisitedHash(inMemory != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_tid_visited_hash);
Datum
vector_rust_hnsw_should_use_tid_visited_hash(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseTidVisitedHash(inMemory != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_offset_visited_hash);
Datum
vector_hnsw_should_use_offset_visited_hash(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseOffsetVisitedHash(hasBasePointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_offset_visited_hash);
Datum
vector_rust_hnsw_should_use_offset_visited_hash(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseOffsetVisitedHash(hasBasePointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_pointer_visited_hash);
Datum
vector_hnsw_should_use_pointer_visited_hash(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUsePointerVisitedHash(hasBasePointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_pointer_visited_hash);
Datum
vector_rust_hnsw_should_use_pointer_visited_hash(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUsePointerVisitedHash(hasBasePointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_memory_entry_distance);
Datum
vector_hnsw_should_use_memory_entry_distance(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseMemoryEntryDistance(inMemory != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_memory_entry_distance);
Datum
vector_rust_hnsw_should_use_memory_entry_distance(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseMemoryEntryDistance(inMemory != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_in_memory_search_path);
Datum
vector_hnsw_should_use_in_memory_search_path(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseInMemorySearchPath(inMemory != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_in_memory_search_path);
Datum
vector_rust_hnsw_should_use_in_memory_search_path(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseInMemorySearchPath(inMemory != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_without_entrypoint);
Datum
vector_hnsw_should_return_without_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnWithoutEntryPoint(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_without_entrypoint);
Datum
vector_rust_hnsw_should_return_without_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnWithoutEntryPoint(hasEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_precompute_hash_for_neighbors);
Datum
vector_hnsw_should_precompute_hash_for_neighbors(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldPrecomputeHashForNeighbors(inMemory != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_precompute_hash_for_neighbors);
Datum
vector_rust_hnsw_should_precompute_hash_for_neighbors(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldPrecomputeHashForNeighbors(inMemory != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_increment_ef_for_existing_element);
Datum
vector_hnsw_should_increment_ef_for_existing_element(PG_FUNCTION_ARGS)
{
	int32		existing = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldIncrementEfForExistingElement(existing != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_increment_ef_for_existing_element);
Datum
vector_rust_hnsw_should_increment_ef_for_existing_element(PG_FUNCTION_ARGS)
{
	int32		existing = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldIncrementEfForExistingElement(existing != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_remove_disk_only_elements_before_select);
Datum
vector_hnsw_should_remove_disk_only_elements_before_select(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRemoveDiskOnlyElementsBeforeSelect(inMemory != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_remove_disk_only_elements_before_select);
Datum
vector_rust_hnsw_should_remove_disk_only_elements_before_select(PG_FUNCTION_ARGS)
{
	int32		inMemory = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRemoveDiskOnlyElementsBeforeSelect(inMemory != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_clamp_neighbor_search_level);
Datum
vector_hnsw_should_clamp_neighbor_search_level(PG_FUNCTION_ARGS)
{
	int32		level = PG_GETARG_INT32(0);
	int32		entryLevel = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldClampNeighborSearchLevel(level, entryLevel, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_clamp_neighbor_search_level);
Datum
vector_rust_hnsw_should_clamp_neighbor_search_level(PG_FUNCTION_ARGS)
{
	int32		level = PG_GETARG_INT32(0);
	int32		entryLevel = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldClampNeighborSearchLevel(level, entryLevel, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_pointer_hash_for_base);
Datum
vector_hnsw_should_use_pointer_hash_for_base(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUsePointerHashForBase(hasBasePointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_pointer_hash_for_base);
Datum
vector_rust_hnsw_should_use_pointer_hash_for_base(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUsePointerHashForBase(hasBasePointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_keep_element_with_heaptids);
Datum
vector_hnsw_should_keep_element_with_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldKeepElementWithHeapTids(heaptidsLength, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_keep_element_with_heaptids);
Datum
vector_rust_hnsw_should_keep_element_with_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldKeepElementWithHeapTids(heaptidsLength, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_count_candidate_with_heaptids);
Datum
vector_hnsw_should_count_candidate_with_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCountCandidateWithHeapTids(heaptidsLength, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_count_candidate_with_heaptids);
Datum
vector_rust_hnsw_should_count_candidate_with_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCountCandidateWithHeapTids(heaptidsLength, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_self_for_vacuum_update);
Datum
vector_hnsw_should_skip_self_for_vacuum_update(PG_FUNCTION_ARGS)
{
	int32		hasSkipElement = PG_GETARG_INT32(0);
	int32		elementBlkno = PG_GETARG_INT32(1);
	int32		elementOffno = PG_GETARG_INT32(2);
	int32		skipBlkno = PG_GETARG_INT32(3);
	int32		skipOffno = PG_GETARG_INT32(4);

	PG_RETURN_BOOL(HnswShouldSkipSelfForVacuumUpdate(hasSkipElement != 0, elementBlkno, elementOffno, skipBlkno, skipOffno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_self_for_vacuum_update);
Datum
vector_rust_hnsw_should_skip_self_for_vacuum_update(PG_FUNCTION_ARGS)
{
	int32		hasSkipElement = PG_GETARG_INT32(0);
	int32		elementBlkno = PG_GETARG_INT32(1);
	int32		elementOffno = PG_GETARG_INT32(2);
	int32		skipBlkno = PG_GETARG_INT32(3);
	int32		skipOffno = PG_GETARG_INT32(4);

	PG_RETURN_BOOL(HnswShouldSkipSelfForVacuumUpdate(hasSkipElement != 0, elementBlkno, elementOffno, skipBlkno, skipOffno, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_skip_element_for_existing);
Datum
vector_hnsw_should_use_skip_element_for_existing(PG_FUNCTION_ARGS)
{
	int32		existing = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseSkipElementForExisting(existing != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_skip_element_for_existing);
Datum
vector_rust_hnsw_should_use_skip_element_for_existing(PG_FUNCTION_ARGS)
{
	int32		existing = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseSkipElementForExisting(existing != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_default_skip_element_tid);
Datum
vector_hnsw_should_use_default_skip_element_tid(PG_FUNCTION_ARGS)
{
	int32		hasSkipElement = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultSkipElementTid(hasSkipElement != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_default_skip_element_tid);
Datum
vector_rust_hnsw_should_use_default_skip_element_tid(PG_FUNCTION_ARGS)
{
	int32		hasSkipElement = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultSkipElementTid(hasSkipElement != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_default_type_info);
Datum
vector_hnsw_should_use_default_type_info(PG_FUNCTION_ARGS)
{
	int32		hasProcInfo = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultTypeInfo(hasProcInfo != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_default_type_info);
Datum
vector_rust_hnsw_should_use_default_type_info(PG_FUNCTION_ARGS)
{
	int32		hasProcInfo = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultTypeInfo(hasProcInfo != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_sparsevec_excess_nnz);
Datum
vector_hnsw_should_reject_sparsevec_excess_nnz(PG_FUNCTION_ARGS)
{
	int32		nnz = PG_GETARG_INT32(0);
	int32		maxNnz = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectSparsevecExcessNnz(nnz, maxNnz, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_sparsevec_excess_nnz);
Datum
vector_rust_hnsw_should_reject_sparsevec_excess_nnz(PG_FUNCTION_ARGS)
{
	int32		nnz = PG_GETARG_INT32(0);
	int32		maxNnz = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectSparsevecExcessNnz(nnz, maxNnz, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_sort_neighbor_candidates);
Datum
vector_hnsw_should_sort_neighbor_candidates(PG_FUNCTION_ARGS)
{
	int32		sortCandidates = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSortNeighborCandidates(sortCandidates != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_sort_neighbor_candidates);
Datum
vector_rust_hnsw_should_sort_neighbor_candidates(PG_FUNCTION_ARGS)
{
	int32		sortCandidates = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSortNeighborCandidates(sortCandidates != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_sort_pointer_candidates);
Datum
vector_hnsw_should_sort_pointer_candidates(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSortPointerCandidates(hasBasePointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_sort_pointer_candidates);
Datum
vector_rust_hnsw_should_sort_pointer_candidates(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSortPointerCandidates(hasBasePointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_calculate_neighbor_closer);
Datum
vector_hnsw_should_calculate_neighbor_closer(PG_FUNCTION_ARGS)
{
	int32		mustCalculate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCalculateNeighborCloser(mustCalculate != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_calculate_neighbor_closer);
Datum
vector_rust_hnsw_should_calculate_neighbor_closer(PG_FUNCTION_ARGS)
{
	int32		mustCalculate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCalculateNeighborCloser(mustCalculate != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reuse_added_candidates);
Datum
vector_hnsw_should_reuse_added_candidates(PG_FUNCTION_ARGS)
{
	int32		addedCount = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReuseAddedCandidates(addedCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reuse_added_candidates);
Datum
vector_rust_hnsw_should_reuse_added_candidates(PG_FUNCTION_ARGS)
{
	int32		addedCount = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReuseAddedCandidates(addedCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_define_closer_state_for_base);
Datum
vector_hnsw_should_define_closer_state_for_base(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldDefineCloserStateForBase(hasBasePointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_define_closer_state_for_base);
Datum
vector_rust_hnsw_should_define_closer_state_for_base(PG_FUNCTION_ARGS)
{
	int32		hasBasePointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldDefineCloserStateForBase(hasBasePointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_append_closer_candidate);
Datum
vector_hnsw_should_append_closer_candidate(PG_FUNCTION_ARGS)
{
	int32		isCloser = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAppendCloserCandidate(isCloser != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_append_closer_candidate);
Datum
vector_rust_hnsw_should_append_closer_candidate(PG_FUNCTION_ARGS)
{
	int32		isCloser = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAppendCloserCandidate(isCloser != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_recheck_candidate_after_removal);
Datum
vector_hnsw_should_recheck_candidate_after_removal(PG_FUNCTION_ARGS)
{
	int32		removedAny = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRecheckCandidateAfterRemoval(removedAny != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_recheck_candidate_after_removal);
Datum
vector_rust_hnsw_should_recheck_candidate_after_removal(PG_FUNCTION_ARGS)
{
	int32		removedAny = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRecheckCandidateAfterRemoval(removedAny != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_pruned_output);
Datum
vector_hnsw_should_return_pruned_output(PG_FUNCTION_ARGS)
{
	int32		hasPrunedOutput = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnPrunedOutput(hasPrunedOutput != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_pruned_output);
Datum
vector_rust_hnsw_should_return_pruned_output(PG_FUNCTION_ARGS)
{
	int32		hasPrunedOutput = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnPrunedOutput(hasPrunedOutput != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_process_new_candidate_branch);
Datum
vector_hnsw_should_process_new_candidate_branch(PG_FUNCTION_ARGS)
{
	int32		isNewCandidate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessNewCandidateBranch(isNewCandidate != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_process_new_candidate_branch);
Datum
vector_rust_hnsw_should_process_new_candidate_branch(PG_FUNCTION_ARGS)
{
	int32		isNewCandidate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessNewCandidateBranch(isNewCandidate != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_replace_pruned_neighbor);
Datum
vector_hnsw_should_replace_pruned_neighbor(PG_FUNCTION_ARGS)
{
	int32		matchesPrunedNeighbor = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReplacePrunedNeighbor(matchesPrunedNeighbor != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_replace_pruned_neighbor);
Datum
vector_rust_hnsw_should_replace_pruned_neighbor(PG_FUNCTION_ARGS)
{
	int32		matchesPrunedNeighbor = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReplacePrunedNeighbor(matchesPrunedNeighbor != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_abort_without_pruned_candidate);
Datum
vector_hnsw_should_abort_without_pruned_candidate(PG_FUNCTION_ARGS)
{
	int32		hasPrunedCandidate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortWithoutPrunedCandidate(hasPrunedCandidate != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_abort_without_pruned_candidate);
Datum
vector_rust_hnsw_should_abort_without_pruned_candidate(PG_FUNCTION_ARGS)
{
	int32		hasPrunedCandidate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortWithoutPrunedCandidate(hasPrunedCandidate != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_enqueue_counted_candidate);
Datum
vector_hnsw_should_enqueue_counted_candidate(PG_FUNCTION_ARGS)
{
	int32		countedCandidate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldEnqueueCountedCandidate(countedCandidate != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_enqueue_counted_candidate);
Datum
vector_rust_hnsw_should_enqueue_counted_candidate(PG_FUNCTION_ARGS)
{
	int32		countedCandidate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldEnqueueCountedCandidate(countedCandidate != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_missing_search_element);
Datum
vector_hnsw_should_skip_missing_search_element(PG_FUNCTION_ARGS)
{
	int32		hasSearchElement = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipMissingSearchElement(hasSearchElement != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_missing_search_element);
Datum
vector_rust_hnsw_should_skip_missing_search_element(PG_FUNCTION_ARGS)
{
	int32		hasSearchElement = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipMissingSearchElement(hasSearchElement != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_copy_tuple_slot_by_index);
Datum
vector_hnsw_should_copy_tuple_slot_by_index(PG_FUNCTION_ARGS)
{
	int32		slotIndex = PG_GETARG_INT32(0);
	int32		slotLimit = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldCopyTupleSlotByIndex(slotIndex, slotLimit, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_copy_tuple_slot_by_index);
Datum
vector_rust_hnsw_should_copy_tuple_slot_by_index(PG_FUNCTION_ARGS)
{
	int32		slotIndex = PG_GETARG_INT32(0);
	int32		slotLimit = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldCopyTupleSlotByIndex(slotIndex, slotLimit, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_cap_element_level);
Datum
vector_hnsw_should_cap_element_level(PG_FUNCTION_ARGS)
{
	int32		level = PG_GETARG_INT32(0);
	int32		maxLevel = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldCapElementLevel(level, maxLevel, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_cap_element_level);
Datum
vector_rust_hnsw_should_cap_element_level(PG_FUNCTION_ARGS)
{
	int32		level = PG_GETARG_INT32(0);
	int32		maxLevel = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldCapElementLevel(level, maxLevel, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_index_options);
Datum
vector_hnsw_should_use_index_options(PG_FUNCTION_ARGS)
{
	int32		hasOptions = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseIndexOptions(hasOptions != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_index_options);
Datum
vector_rust_hnsw_should_use_index_options(PG_FUNCTION_ARGS)
{
	int32		hasOptions = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseIndexOptions(hasOptions != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_index_options);
Datum
vector_hnsw_should_have_index_options(PG_FUNCTION_ARGS)
{
	int32		hasOptions = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveIndexOptionsFlag(hasOptions != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_index_options);
Datum
vector_rust_hnsw_should_have_index_options(PG_FUNCTION_ARGS)
{
	int32		hasOptions = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveIndexOptionsFlag(hasOptions != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_missing_optional_proc);
Datum
vector_hnsw_should_return_missing_optional_proc(PG_FUNCTION_ARGS)
{
	int32		hasProcOid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnMissingOptionalProc(hasProcOid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_missing_optional_proc);
Datum
vector_rust_hnsw_should_return_missing_optional_proc(PG_FUNCTION_ARGS)
{
	int32		hasProcOid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnMissingOptionalProc(hasProcOid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_custom_allocator);
Datum
vector_hnsw_should_use_custom_allocator(PG_FUNCTION_ARGS)
{
	int32		hasAllocator = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseCustomAllocator(hasAllocator != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_custom_allocator);
Datum
vector_rust_hnsw_should_use_custom_allocator(PG_FUNCTION_ARGS)
{
	int32		hasAllocator = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseCustomAllocator(hasAllocator != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_custom_allocator);
Datum
vector_hnsw_should_have_custom_allocator(PG_FUNCTION_ARGS)
{
	int32		hasAllocator = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveCustomAllocatorFlag(hasAllocator != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_custom_allocator);
Datum
vector_rust_hnsw_should_have_custom_allocator(PG_FUNCTION_ARGS)
{
	int32		hasAllocator = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveCustomAllocatorFlag(hasAllocator != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_load_meta_m);
Datum
vector_hnsw_should_load_meta_m(PG_FUNCTION_ARGS)
{
	int32		hasMOutputPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLoadMetaM(hasMOutputPointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_load_meta_m);
Datum
vector_rust_hnsw_should_load_meta_m(PG_FUNCTION_ARGS)
{
	int32		hasMOutputPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLoadMetaM(hasMOutputPointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_load_meta_entrypoint);
Datum
vector_hnsw_should_load_meta_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntrypointOutputPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLoadMetaEntrypoint(hasEntrypointOutputPointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_load_meta_entrypoint);
Datum
vector_rust_hnsw_should_load_meta_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntrypointOutputPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldLoadMetaEntrypoint(hasEntrypointOutputPointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_meta_entry_block);
Datum
vector_hnsw_should_use_meta_entry_block(PG_FUNCTION_ARGS)
{
	int32		hasValidEntryBlock = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseMetaEntryBlock(hasValidEntryBlock != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_meta_entry_block);
Datum
vector_rust_hnsw_should_use_meta_entry_block(PG_FUNCTION_ARGS)
{
	int32		hasValidEntryBlock = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseMetaEntryBlock(hasValidEntryBlock != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_meta_entry_info);
Datum
vector_hnsw_should_update_meta_entry_info(PG_FUNCTION_ARGS)
{
	int32		updateEntry = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdateMetaEntryInfo(updateEntry, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_meta_entry_info);
Datum
vector_rust_hnsw_should_update_meta_entry_info(PG_FUNCTION_ARGS)
{
	int32		updateEntry = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdateMetaEntryInfo(updateEntry, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reset_meta_entrypoint);
Datum
vector_hnsw_should_reset_meta_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntrypoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldResetMetaEntrypoint(hasEntrypoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reset_meta_entrypoint);
Datum
vector_rust_hnsw_should_reset_meta_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntrypoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldResetMetaEntrypoint(hasEntrypoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_write_meta_entrypoint);
Datum
vector_hnsw_should_write_meta_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntrypoint = PG_GETARG_INT32(0);
	int32		entryLevel = PG_GETARG_INT32(1);
	int32		currentEntryLevel = PG_GETARG_INT32(2);
	int32		updateEntry = PG_GETARG_INT32(3);

	PG_RETURN_BOOL(HnswShouldWriteMetaEntrypoint(hasEntrypoint != 0, entryLevel, currentEntryLevel, updateEntry, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_write_meta_entrypoint);
Datum
vector_rust_hnsw_should_write_meta_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntrypoint = PG_GETARG_INT32(0);
	int32		entryLevel = PG_GETARG_INT32(1);
	int32		currentEntryLevel = PG_GETARG_INT32(2);
	int32		updateEntry = PG_GETARG_INT32(3);

	PG_RETURN_BOOL(HnswShouldWriteMetaEntrypoint(hasEntrypoint != 0, entryLevel, currentEntryLevel, updateEntry, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_write_meta_insert_page);
Datum
vector_hnsw_should_write_meta_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasValidInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldWriteMetaInsertPage(hasValidInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_write_meta_insert_page);
Datum
vector_rust_hnsw_should_write_meta_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasValidInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldWriteMetaInsertPage(hasValidInsertPage != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_build_buffer_path);
Datum
vector_hnsw_should_use_build_buffer_path(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildBufferPath(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_build_buffer_path);
Datum
vector_rust_hnsw_should_use_build_buffer_path(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildBufferPath(building != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_check_type_value);
Datum
vector_hnsw_should_check_type_value(PG_FUNCTION_ARGS)
{
	int32		hasCheckValueFunction = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCheckTypeValue(hasCheckValueFunction != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_check_type_value);
Datum
vector_rust_hnsw_should_check_type_value(PG_FUNCTION_ARGS)
{
	int32		hasCheckValueFunction = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCheckTypeValue(hasCheckValueFunction != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_type_check_function);
Datum
vector_hnsw_should_have_type_check_function(PG_FUNCTION_ARGS)
{
	int32		hasCheckValueFunction = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveTypeCheckFunctionFlag(hasCheckValueFunction != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_type_check_function);
Datum
vector_rust_hnsw_should_have_type_check_function(PG_FUNCTION_ARGS)
{
	int32		hasCheckValueFunction = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveTypeCheckFunctionFlag(hasCheckValueFunction != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_normalize_index_value);
Datum
vector_hnsw_should_normalize_index_value(PG_FUNCTION_ARGS)
{
	int32		hasNormProcInfo = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldNormalizeIndexValue(hasNormProcInfo != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_normalize_index_value);
Datum
vector_rust_hnsw_should_normalize_index_value(PG_FUNCTION_ARGS)
{
	int32		hasNormProcInfo = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldNormalizeIndexValue(hasNormProcInfo != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_norm_procinfo);
Datum
vector_hnsw_should_have_norm_procinfo(PG_FUNCTION_ARGS)
{
	int32		hasNormProcInfo = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNormProcInfoFlag(hasNormProcInfo != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_norm_procinfo);
Datum
vector_rust_hnsw_should_have_norm_procinfo(PG_FUNCTION_ARGS)
{
	int32		hasNormProcInfo = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNormProcInfoFlag(hasNormProcInfo != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_invalid_norm);
Datum
vector_hnsw_should_reject_invalid_norm(PG_FUNCTION_ARGS)
{
	int32		hasValidNorm = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectInvalidNorm(hasValidNorm != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_invalid_norm);
Datum
vector_rust_hnsw_should_reject_invalid_norm(PG_FUNCTION_ARGS)
{
	int32		hasValidNorm = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectInvalidNorm(hasValidNorm != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_prioritize_lower_distance);
Datum
vector_hnsw_should_prioritize_lower_distance(PG_FUNCTION_ARGS)
{
	float8		leftDistance = PG_GETARG_FLOAT8(0);
	float8		rightDistance = PG_GETARG_FLOAT8(1);

	PG_RETURN_BOOL(HnswShouldPrioritizeLowerDistance(leftDistance, rightDistance, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_prioritize_lower_distance);
Datum
vector_rust_hnsw_should_prioritize_lower_distance(PG_FUNCTION_ARGS)
{
	float8		leftDistance = PG_GETARG_FLOAT8(0);
	float8		rightDistance = PG_GETARG_FLOAT8(1);

	PG_RETURN_BOOL(HnswShouldPrioritizeLowerDistance(leftDistance, rightDistance, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_prioritize_pointer_tiebreak);
Datum
vector_hnsw_should_prioritize_pointer_tiebreak(PG_FUNCTION_ARGS)
{
	int32		leftPointerPrecedes = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldPrioritizePointerTiebreak(leftPointerPrecedes != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_prioritize_pointer_tiebreak);
Datum
vector_rust_hnsw_should_prioritize_pointer_tiebreak(PG_FUNCTION_ARGS)
{
	int32		leftPointerPrecedes = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldPrioritizePointerTiebreak(leftPointerPrecedes != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_prioritize_offset_tiebreak);
Datum
vector_hnsw_should_prioritize_offset_tiebreak(PG_FUNCTION_ARGS)
{
	int32		leftOffsetPrecedes = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldPrioritizeOffsetTiebreak(leftOffsetPrecedes != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_prioritize_offset_tiebreak);
Datum
vector_rust_hnsw_should_prioritize_offset_tiebreak(PG_FUNCTION_ARGS)
{
	int32		leftOffsetPrecedes = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldPrioritizeOffsetTiebreak(leftOffsetPrecedes != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_invalid_meta_magic);
Datum
vector_hnsw_should_reject_invalid_meta_magic(PG_FUNCTION_ARGS)
{
	int32		hasExpectedMagic = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectInvalidMetaMagic(hasExpectedMagic != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_invalid_meta_magic);
Datum
vector_rust_hnsw_should_reject_invalid_meta_magic(PG_FUNCTION_ARGS)
{
	int32		hasExpectedMagic = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectInvalidMetaMagic(hasExpectedMagic != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_force_meta_entry_update);
Datum
vector_hnsw_should_force_meta_entry_update(PG_FUNCTION_ARGS)
{
	int32		updateEntry = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldForceMetaEntryUpdate(updateEntry, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_force_meta_entry_update);
Datum
vector_rust_hnsw_should_force_meta_entry_update(PG_FUNCTION_ARGS)
{
	int32		updateEntry = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldForceMetaEntryUpdate(updateEntry, true));
}

/*
 * Load an element and optionally get its distance from q
 */
static void
HnswLoadElementImpl(BlockNumber blkno, OffsetNumber offno, double *distance, HnswQuery * q, Relation index, HnswSupport * support, bool loadVec, double *maxDistance, HnswElement * element)
{
	Buffer		buf;
	Page		page;
	HnswElementTuple etup;
	double		distanceValueForCompare = 0;
	double		maxDistanceValueForCompare = 0;

	/* Read vector */
	buf = ReadBuffer(index, blkno);
	LockBuffer(buf, BUFFER_LOCK_SHARE);
	page = BufferGetPage(buf);

	etup = (HnswElementTuple) PageGetItem(page, PageGetItemId(page, offno));

	Assert(HnswIsElementTuple(etup));

	/* Calculate distance */
	if (HnswShouldCalculateElementDistance(distance != NULL, true))
	{
		if (HnswShouldZeroDistanceForNullQueryValue(DatumGetPointer(q->value) != NULL, true))
			*distance = 0;
		else
			*distance = HnswGetDistance(q->value, PointerGetDatum(&etup->data), support);
	}

	/* Load element */
	if (!HnswShouldUseDefaultDistanceValue(distance != NULL, true))
		distanceValueForCompare = *distance;

	if (!HnswShouldUseDefaultMaxDistanceValue(maxDistance != NULL, true))
		maxDistanceValueForCompare = *maxDistance;

	if (HnswShouldUpdateElementMaxDistance(distance != NULL, maxDistance != NULL,
										   distanceValueForCompare, maxDistanceValueForCompare, true))
	{
		if (HnswShouldInitializeLoadedElement(*element != NULL, true))
			*element = HnswInitElementFromBlock(blkno, offno);

		HnswLoadElementFromTuple(*element, etup, true, loadVec);
	}

	UnlockReleaseBuffer(buf);
}

/*
 * Load an element and optionally get its distance from q
 */
void
HnswLoadElement(HnswElement element, double *distance, HnswQuery * q, Relation index, HnswSupport * support, bool loadVec, double *maxDistance)
{
	HnswLoadElementImpl(element->blkno, element->offno, distance, q, index, support, loadVec, maxDistance, &element);
}

/*
 * Get the distance for an element
 */
static double
GetElementDistance(char *base, HnswElement element, HnswQuery * q, HnswSupport * support)
{
	Datum		value = HnswGetValue(base, element);

	return HnswGetDistance(q->value, value, support);
}

/*
 * Allocate a search candidate
 */
static HnswSearchCandidate *
HnswInitSearchCandidate(char *base, HnswElement element, double distance)
{
	HnswSearchCandidate *sc = palloc(sizeof(HnswSearchCandidate));

	HnswPtrStore(base, sc->element, element);
	sc->distance = distance;
	return sc;
}

/*
 * Create a candidate for the entry point
 */
HnswSearchCandidate *
HnswEntryCandidate(char *base, HnswElement entryPoint, HnswQuery * q, Relation index, HnswSupport * support, bool loadVec)
{
	bool		inMemory = index == NULL;
	double		distance;

	if (HnswShouldUseMemoryEntryDistance(inMemory, true))
		distance = GetElementDistance(base, entryPoint, q, support);
	else
		HnswLoadElement(entryPoint, &distance, q, index, support, loadVec, NULL);

	return HnswInitSearchCandidate(base, entryPoint, distance);
}

/*
 * Compare candidate distances
 */
static int
CompareNearestCandidates(const pairingheap_node *a, const pairingheap_node *b, void *arg)
{
	if (HnswShouldPrioritizeLowerDistance(HnswGetSearchCandidateConst(c_node, a)->distance,
										  HnswGetSearchCandidateConst(c_node, b)->distance, true))
		return 1;

	if (HnswShouldPrioritizeLowerDistance(HnswGetSearchCandidateConst(c_node, b)->distance,
										  HnswGetSearchCandidateConst(c_node, a)->distance, true))
		return -1;

	return 0;
}

/*
 * Compare discarded candidate distances
 */
static int
CompareNearestDiscardedCandidates(const pairingheap_node *a, const pairingheap_node *b, void *arg)
{
	if (HnswShouldPrioritizeLowerDistance(HnswGetSearchCandidateConst(w_node, a)->distance,
										  HnswGetSearchCandidateConst(w_node, b)->distance, true))
		return 1;

	if (HnswShouldPrioritizeLowerDistance(HnswGetSearchCandidateConst(w_node, b)->distance,
										  HnswGetSearchCandidateConst(w_node, a)->distance, true))
		return -1;

	return 0;
}

/*
 * Compare candidate distances
 */
static int
CompareFurthestCandidates(const pairingheap_node *a, const pairingheap_node *b, void *arg)
{
	if (HnswShouldPrioritizeLowerDistance(HnswGetSearchCandidateConst(w_node, a)->distance,
										  HnswGetSearchCandidateConst(w_node, b)->distance, true))
		return -1;

	if (HnswShouldPrioritizeLowerDistance(HnswGetSearchCandidateConst(w_node, b)->distance,
										  HnswGetSearchCandidateConst(w_node, a)->distance, true))
		return 1;

	return 0;
}

/*
 * Init visited
 */
static inline void
InitVisited(char *base, visited_hash * v, bool inMemory, int ef, int m)
{
	if (HnswShouldUseTidVisitedHash(inMemory, true))
		v->tids = tidhash_create(CurrentMemoryContext, ef * m * 2, NULL);
	else if (HnswShouldUseOffsetVisitedHash(base != NULL, true))
		v->offsets = offsethash_create(CurrentMemoryContext, ef * m * 2, NULL);
	else if (HnswShouldUsePointerVisitedHash(base != NULL, true))
		v->pointers = pointerhash_create(CurrentMemoryContext, ef * m * 2, NULL);
}

/*
 * Add to visited
 */
static inline void
AddToVisited(char *base, visited_hash * v, HnswElementPtr elementPtr, bool inMemory, bool *found)
{
	if (HnswShouldUseTidVisitedHash(inMemory, true))
	{
		HnswElement element = HnswPtrAccess(base, elementPtr);
		ItemPointerData indextid;

		ItemPointerSet(&indextid, element->blkno, element->offno);
		tidhash_insert(v->tids, indextid, found);
	}
	else if (HnswShouldUseOffsetVisitedHash(base != NULL, true))
	{
		HnswElement element = HnswPtrAccess(base, elementPtr);

		offsethash_insert_hash(v->offsets, HnswPtrOffset(elementPtr), element->hash, found);
	}
	else if (HnswShouldUsePointerVisitedHash(base != NULL, true))
	{
		HnswElement element = HnswPtrAccess(base, elementPtr);

		pointerhash_insert_hash(v->pointers, (uintptr_t) HnswPtrPointer(elementPtr), element->hash, found);
	}
}

/*
 * Count element towards ef
 */
static inline bool
CountElement(HnswElement skipElement, HnswElement e)
{
	if (HnswShouldCountWithoutSkipElement(skipElement != NULL, true))
		return true;

	/* Ensure does not access heaptidsLength during in-memory build */
	pg_memory_barrier();

	/* Keep scan-build happy on Mac x86-64 */
	Assert(e);

	return HnswShouldCountCandidateWithHeapTids(e->heaptidsLength, true);
}

/*
 * Load unvisited neighbors from memory
 */
static void
HnswLoadUnvisitedFromMemory(char *base, HnswElement element, HnswUnvisited * unvisited, int *unvisitedLength, visited_hash * v, int lc, HnswNeighborArray * localNeighborhood, Size neighborhoodSize)
{
	/* Get the neighborhood at layer lc */
	HnswNeighborArray *neighborhood = HnswGetNeighbors(base, element, lc);

	/* Copy neighborhood to local memory */
	LWLockAcquire(&element->lock, LW_SHARED);
	memcpy(localNeighborhood, neighborhood, neighborhoodSize);
	LWLockRelease(&element->lock);

	*unvisitedLength = 0;

	for (int i = 0; i < localNeighborhood->length; i++)
	{
		HnswCandidate *hc = &localNeighborhood->items[i];
		bool		found;

		AddToVisited(base, v, hc->element, true, &found);

		if (HnswShouldAppendUnvisitedNeighbor(found, true))
			unvisited[(*unvisitedLength)++].element = HnswPtrAccess(base, hc->element);
	}
}

/*
 * Load neighbor index TIDs
 */
bool
HnswLoadNeighborTids(HnswElement element, ItemPointerData *indextids, Relation index, int m, int lm, int lc)
{
	Buffer		buf;
	Page		page;
	HnswNeighborTuple ntup;
	int			start;

	buf = ReadBuffer(index, element->neighborPage);
	LockBuffer(buf, BUFFER_LOCK_SHARE);
	page = BufferGetPage(buf);

	ntup = (HnswNeighborTuple) PageGetItem(page, PageGetItemId(page, element->neighborOffno));

	/*
	 * Ensure the neighbor tuple has not been deleted or replaced between
	 * index scan iterations
	 */
	if (HnswShouldRejectStaleNeighborTuple(ntup->version == element->version && ntup->count == (element->level + 2) * m, true))
	{
		UnlockReleaseBuffer(buf);
		return false;
	}

	/* Copy to minimize lock time */
	start = (element->level - lc) * m;
	memcpy(indextids, ntup->indextids + start, lm * sizeof(ItemPointerData));

	UnlockReleaseBuffer(buf);
	return true;
}

/*
 * Load unvisited neighbors from disk
 */
static void
HnswLoadUnvisitedFromDisk(HnswElement element, HnswUnvisited * unvisited, int *unvisitedLength, visited_hash * v, Relation index, int m, int lm, int lc)
{
	ItemPointerData indextids[HNSW_MAX_M * 2];

	*unvisitedLength = 0;

	if (HnswShouldAbortUnvisitedDiskLoad(HnswLoadNeighborTids(element, indextids, index, m, lm, lc), true))
		return;

	for (int i = 0; i < lm; i++)
	{
		ItemPointer indextid = &indextids[i];
		bool		found;

		if (HnswShouldStopLoadingDiskNeighbor(ItemPointerIsValid(indextid), true))
			break;

		tidhash_insert(v->tids, *indextid, &found);

		if (HnswShouldAppendUnvisitedDiskNeighbor(found, true))
			unvisited[(*unvisitedLength)++].indextid = *indextid;
	}
}

/*
 * Algorithm 2 from paper
 */
List *
HnswSearchLayer(char *base, HnswQuery * q, List *ep, int ef, int lc, Relation index, HnswSupport * support, int m, bool inserting, HnswElement skipElement, visited_hash * v, pairingheap **discarded, bool initVisited, int64 *tuples)
{
	List	   *w = NIL;
	pairingheap *C = pairingheap_allocate(CompareNearestCandidates, NULL);
	pairingheap *W = pairingheap_allocate(CompareFurthestCandidates, NULL);
	int			wlen = 0;
	visited_hash vh;
	ListCell   *lc2;
	HnswNeighborArray *localNeighborhood = NULL;
	Size		neighborhoodSize = 0;
	int			lm = HnswGetLayerM(m, lc);
	HnswUnvisited *unvisited = palloc(lm * sizeof(HnswUnvisited));
	int			unvisitedLength;
	bool		inMemory = index == NULL;

	if (HnswShouldInitializeVisitedHash(v != NULL, true))
	{
		v = &vh;
		initVisited = true;
	}

	if (HnswShouldInitializeVisitedState(initVisited, true))
	{
		InitVisited(base, v, inMemory, ef, m);

		if (HnswShouldInitializeDiscardedHeap(discarded != NULL, true))
			*discarded = pairingheap_allocate(CompareNearestDiscardedCandidates, NULL);
	}

	/* Create local memory for neighborhood if needed */
	if (HnswShouldUseInMemorySearchPath(inMemory, true))
	{
		neighborhoodSize = HNSW_NEIGHBOR_ARRAY_SIZE(lm);
		localNeighborhood = palloc(neighborhoodSize);
	}

	/* Add entry points to v, C, and W */
	foreach(lc2, ep)
	{
		HnswSearchCandidate *sc = (HnswSearchCandidate *) lfirst(lc2);
		bool		found;

		if (HnswShouldInitializeVisitedState(initVisited, true))
		{
			AddToVisited(base, v, sc->element, inMemory, &found);

			/* OK to count elements instead of tuples */
			if (HnswShouldTrackTupleCounter(tuples != NULL, true))
				(*tuples)++;
		}

		pairingheap_add(C, &sc->c_node);
		pairingheap_add(W, &sc->w_node);

		/*
		 * Do not count elements being deleted towards ef when vacuuming. It
		 * would be ideal to do this for inserts as well, but this could
		 * affect insert performance.
		 */
		if (HnswShouldEnqueueCountedCandidate(CountElement(skipElement, HnswPtrAccess(base, sc->element)), true))
			wlen++;
	}

	while (!pairingheap_is_empty(C))
	{
		HnswSearchCandidate *c = HnswGetSearchCandidate(c_node, pairingheap_remove_first(C));
		HnswSearchCandidate *f = HnswGetSearchCandidate(w_node, pairingheap_first(W));
		HnswElement cElement;

		if (HnswShouldStopSearchLayer(c->distance, f->distance, true))
			break;

		cElement = HnswPtrAccess(base, c->element);

		if (HnswShouldUseInMemorySearchPath(inMemory, true))
			HnswLoadUnvisitedFromMemory(base, cElement, unvisited, &unvisitedLength, v, lc, localNeighborhood, neighborhoodSize);
		else
			HnswLoadUnvisitedFromDisk(cElement, unvisited, &unvisitedLength, v, index, m, lm, lc);

		/* OK to count elements instead of tuples */
		if (HnswShouldTrackTupleCounter(tuples != NULL, true))
			(*tuples) += unvisitedLength;

		for (int i = 0; i < unvisitedLength; i++)
		{
			HnswElement eElement;
			HnswSearchCandidate *e;
			double		eDistance;
			bool		alwaysAdd = HnswShouldAlwaysAddCandidate(wlen, ef, true);

			f = HnswGetSearchCandidate(w_node, pairingheap_first(W));

			if (HnswShouldUseInMemorySearchPath(inMemory, true))
			{
				eElement = unvisited[i].element;
				eDistance = GetElementDistance(base, eElement, q, support);
			}
			else
			{
				ItemPointer indextid = &unvisited[i].indextid;
				BlockNumber blkno = ItemPointerGetBlockNumber(indextid);
				OffsetNumber offno = ItemPointerGetOffsetNumber(indextid);
				bool		trackDiscarded;
				double	   *maxDistanceCap = NULL;

				/* Avoid any allocations if not adding */
				eElement = NULL;
				trackDiscarded = HnswShouldTrackDiscardedCandidates(discarded != NULL, true);
				if (HnswShouldLoadElementWithMaxDistanceCap(alwaysAdd, trackDiscarded, true))
					maxDistanceCap = &f->distance;
				HnswLoadElementImpl(blkno, offno, &eDistance, q, index, support, inserting, maxDistanceCap, &eElement);

				if (HnswShouldSkipMissingSearchElement(eElement != NULL, true))
					continue;
			}

			if (!HnswShouldAddSearchCandidate(eDistance, f->distance, alwaysAdd, true))
			{
				if (HnswShouldTrackDiscardedCandidates(discarded != NULL, true))
				{
					/* Create a new candidate */
					e = HnswInitSearchCandidate(base, eElement, eDistance);
					pairingheap_add(*discarded, &e->w_node);
				}

				continue;
			}

			/* Make robust to issues */
			if (HnswShouldSkipLowerLevelCandidate(eElement->level, lc, true))
				continue;

			/* Create a new candidate */
			e = HnswInitSearchCandidate(base, eElement, eDistance);
			pairingheap_add(C, &e->c_node);
			pairingheap_add(W, &e->w_node);

			/*
			 * Do not count elements being deleted towards ef when vacuuming.
			 * It would be ideal to do this for inserts as well, but this
			 * could affect insert performance.
			 */
			if (HnswShouldEnqueueCountedCandidate(CountElement(skipElement, eElement), true))
			{
				wlen++;

				/* No need to decrement wlen */
				if (HnswShouldTrimCandidateList(wlen, ef, true))
				{
					HnswSearchCandidate *d = HnswGetSearchCandidate(w_node, pairingheap_remove_first(W));

					if (HnswShouldTrackDiscardedCandidates(discarded != NULL, true))
						pairingheap_add(*discarded, &d->w_node);
				}
			}
		}
	}

	/* Add each element of W to w */
	while (!pairingheap_is_empty(W))
	{
		HnswSearchCandidate *sc = HnswGetSearchCandidate(w_node, pairingheap_remove_first(W));

		w = lappend(w, sc);
	}

	return w;
}

/*
 * Compare candidate distances with pointer tie-breaker
 */
static int
CompareCandidateDistances(const ListCell *a, const ListCell *b)
{
	HnswCandidate *hca = lfirst(a);
	HnswCandidate *hcb = lfirst(b);

	if (HnswShouldPrioritizeLowerDistance(hca->distance, hcb->distance, true))
		return 1;

	if (HnswShouldPrioritizeLowerDistance(hcb->distance, hca->distance, true))
		return -1;

	if (HnswShouldPrioritizePointerTiebreak(HnswPtrPointer(hca->element) < HnswPtrPointer(hcb->element), true))
		return 1;

	if (HnswShouldPrioritizePointerTiebreak(HnswPtrPointer(hcb->element) < HnswPtrPointer(hca->element), true))
		return -1;

	return 0;
}

/*
 * Compare candidate distances with offset tie-breaker
 */
static int
CompareCandidateDistancesOffset(const ListCell *a, const ListCell *b)
{
	HnswCandidate *hca = lfirst(a);
	HnswCandidate *hcb = lfirst(b);

	if (HnswShouldPrioritizeLowerDistance(hca->distance, hcb->distance, true))
		return 1;

	if (HnswShouldPrioritizeLowerDistance(hcb->distance, hca->distance, true))
		return -1;

	if (HnswShouldPrioritizeOffsetTiebreak(HnswPtrOffset(hca->element) < HnswPtrOffset(hcb->element), true))
		return 1;

	if (HnswShouldPrioritizeOffsetTiebreak(HnswPtrOffset(hcb->element) < HnswPtrOffset(hca->element), true))
		return -1;

	return 0;
}

static bool
HnswShouldRejectCloserNeighbor(float8 distance, float8 candidateDistance, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_closer_neighbor_kernel(distance, candidateDistance);

	return distance <= candidateDistance;
}

static bool
HnswShouldSelectNeighborsEarlyReturn(int candidateCount, int maxNeighbors, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_select_neighbors_early_return_kernel(candidateCount, maxNeighbors);

	return candidateCount <= maxNeighbors;
}

static bool
HnswShouldAddSearchCandidate(float8 candidateDistance, float8 frontierDistance, bool alwaysAdd, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_add_search_candidate_kernel(candidateDistance, frontierDistance, alwaysAdd);

	return candidateDistance < frontierDistance || alwaysAdd;
}

static bool
HnswShouldStopSearchLayer(float8 candidateDistance, float8 frontierDistance, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_stop_search_layer_kernel(candidateDistance, frontierDistance);

	return candidateDistance > frontierDistance;
}

static bool
HnswShouldAppendNeighborWithoutPrune(int neighborsLength, int maxNeighbors, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_append_neighbor_without_prune_kernel(neighborsLength, maxNeighbors);

	return neighborsLength < maxNeighbors;
}

static bool
HnswShouldSkipLowerLevelCandidate(int candidateLevel, int searchLevel, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_lower_level_candidate_kernel(candidateLevel, searchLevel);

	return candidateLevel < searchLevel;
}

static bool
HnswShouldKeepPrunedConnection(int wdoff, int wdlen, int resultLength, int maxNeighbors, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_keep_pruned_connection_kernel(wdoff, wdlen, resultLength, maxNeighbors);

	return wdoff < wdlen && resultLength < maxNeighbors;
}

static bool
HnswShouldSetPrunedFromArray(int wdoff, int wdlen, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_set_pruned_from_array_kernel(wdoff, wdlen);

	return wdoff < wdlen;
}

static bool
HnswShouldTrackDiscardedCandidates(bool hasDiscardedHeap, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_track_discarded_candidates_kernel(hasDiscardedHeap);

	return hasDiscardedHeap;
}

static bool
HnswShouldLoadElementWithMaxDistanceCap(bool alwaysAdd, bool trackDiscarded, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(alwaysAdd || trackDiscarded);

	return !alwaysAdd && !trackDiscarded;
}

static bool
HnswShouldTrackUpdateIndex(bool hasUpdateIndexPointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_track_update_index_kernel(hasUpdateIndexPointer);

	return hasUpdateIndexPointer;
}

static bool
HnswShouldProcessPrunedCandidate(bool hasPrunedCandidate, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_process_pruned_candidate_kernel(hasPrunedCandidate);

	return hasPrunedCandidate;
}

static bool
HnswShouldTrimCandidateList(int candidateCount, int ef, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_trim_candidate_list_kernel(candidateCount, ef);

	return candidateCount > ef;
}

static bool
HnswShouldAlwaysAddCandidate(int candidateCount, int ef, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_always_add_candidate_kernel(candidateCount, ef);

	return candidateCount < ef;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_closer_neighbor);
Datum
vector_hnsw_should_reject_closer_neighbor(PG_FUNCTION_ARGS)
{
	float8		distance = PG_GETARG_FLOAT8(0);
	float8		candidateDistance = PG_GETARG_FLOAT8(1);

	PG_RETURN_BOOL(HnswShouldRejectCloserNeighbor(distance, candidateDistance, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_closer_neighbor);
Datum
vector_rust_hnsw_should_reject_closer_neighbor(PG_FUNCTION_ARGS)
{
	float8		distance = PG_GETARG_FLOAT8(0);
	float8		candidateDistance = PG_GETARG_FLOAT8(1);

	PG_RETURN_BOOL(HnswShouldRejectCloserNeighbor(distance, candidateDistance, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_select_neighbors_early_return);
Datum
vector_hnsw_should_select_neighbors_early_return(PG_FUNCTION_ARGS)
{
	int32		candidateCount = PG_GETARG_INT32(0);
	int32		maxNeighbors = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSelectNeighborsEarlyReturn(candidateCount, maxNeighbors, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_select_neighbors_early_return);
Datum
vector_rust_hnsw_should_select_neighbors_early_return(PG_FUNCTION_ARGS)
{
	int32		candidateCount = PG_GETARG_INT32(0);
	int32		maxNeighbors = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSelectNeighborsEarlyReturn(candidateCount, maxNeighbors, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_add_search_candidate);
Datum
vector_hnsw_should_add_search_candidate(PG_FUNCTION_ARGS)
{
	float8		candidateDistance = PG_GETARG_FLOAT8(0);
	float8		frontierDistance = PG_GETARG_FLOAT8(1);
	int32		alwaysAdd = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldAddSearchCandidate(candidateDistance, frontierDistance, alwaysAdd != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_add_search_candidate);
Datum
vector_rust_hnsw_should_add_search_candidate(PG_FUNCTION_ARGS)
{
	float8		candidateDistance = PG_GETARG_FLOAT8(0);
	float8		frontierDistance = PG_GETARG_FLOAT8(1);
	int32		alwaysAdd = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldAddSearchCandidate(candidateDistance, frontierDistance, alwaysAdd != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_search_layer);
Datum
vector_hnsw_should_stop_search_layer(PG_FUNCTION_ARGS)
{
	float8		candidateDistance = PG_GETARG_FLOAT8(0);
	float8		frontierDistance = PG_GETARG_FLOAT8(1);

	PG_RETURN_BOOL(HnswShouldStopSearchLayer(candidateDistance, frontierDistance, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_search_layer);
Datum
vector_rust_hnsw_should_stop_search_layer(PG_FUNCTION_ARGS)
{
	float8		candidateDistance = PG_GETARG_FLOAT8(0);
	float8		frontierDistance = PG_GETARG_FLOAT8(1);

	PG_RETURN_BOOL(HnswShouldStopSearchLayer(candidateDistance, frontierDistance, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_append_neighbor_without_prune);
Datum
vector_hnsw_should_append_neighbor_without_prune(PG_FUNCTION_ARGS)
{
	int32		neighborsLength = PG_GETARG_INT32(0);
	int32		maxNeighbors = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldAppendNeighborWithoutPrune(neighborsLength, maxNeighbors, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_append_neighbor_without_prune);
Datum
vector_rust_hnsw_should_append_neighbor_without_prune(PG_FUNCTION_ARGS)
{
	int32		neighborsLength = PG_GETARG_INT32(0);
	int32		maxNeighbors = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldAppendNeighborWithoutPrune(neighborsLength, maxNeighbors, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_lower_level_candidate);
Datum
vector_hnsw_should_skip_lower_level_candidate(PG_FUNCTION_ARGS)
{
	int32		candidateLevel = PG_GETARG_INT32(0);
	int32		searchLevel = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSkipLowerLevelCandidate(candidateLevel, searchLevel, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_lower_level_candidate);
Datum
vector_rust_hnsw_should_skip_lower_level_candidate(PG_FUNCTION_ARGS)
{
	int32		candidateLevel = PG_GETARG_INT32(0);
	int32		searchLevel = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSkipLowerLevelCandidate(candidateLevel, searchLevel, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_keep_pruned_connection);
Datum
vector_hnsw_should_keep_pruned_connection(PG_FUNCTION_ARGS)
{
	int32		wdoff = PG_GETARG_INT32(0);
	int32		wdlen = PG_GETARG_INT32(1);
	int32		resultLength = PG_GETARG_INT32(2);
	int32		maxNeighbors = PG_GETARG_INT32(3);

	PG_RETURN_BOOL(HnswShouldKeepPrunedConnection(wdoff, wdlen, resultLength, maxNeighbors, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_keep_pruned_connection);
Datum
vector_rust_hnsw_should_keep_pruned_connection(PG_FUNCTION_ARGS)
{
	int32		wdoff = PG_GETARG_INT32(0);
	int32		wdlen = PG_GETARG_INT32(1);
	int32		resultLength = PG_GETARG_INT32(2);
	int32		maxNeighbors = PG_GETARG_INT32(3);

	PG_RETURN_BOOL(HnswShouldKeepPrunedConnection(wdoff, wdlen, resultLength, maxNeighbors, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_set_pruned_from_array);
Datum
vector_hnsw_should_set_pruned_from_array(PG_FUNCTION_ARGS)
{
	int32		wdoff = PG_GETARG_INT32(0);
	int32		wdlen = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSetPrunedFromArray(wdoff, wdlen, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_set_pruned_from_array);
Datum
vector_rust_hnsw_should_set_pruned_from_array(PG_FUNCTION_ARGS)
{
	int32		wdoff = PG_GETARG_INT32(0);
	int32		wdlen = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSetPrunedFromArray(wdoff, wdlen, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_track_discarded_candidates);
Datum
vector_hnsw_should_track_discarded_candidates(PG_FUNCTION_ARGS)
{
	int32		hasDiscardedHeap = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTrackDiscardedCandidates(hasDiscardedHeap != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_track_discarded_candidates);
Datum
vector_rust_hnsw_should_track_discarded_candidates(PG_FUNCTION_ARGS)
{
	int32		hasDiscardedHeap = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTrackDiscardedCandidates(hasDiscardedHeap != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_load_element_with_max_distance_cap);
Datum
vector_hnsw_should_load_element_with_max_distance_cap(PG_FUNCTION_ARGS)
{
	int32		alwaysAdd = PG_GETARG_INT32(0);
	int32		trackDiscarded = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldLoadElementWithMaxDistanceCap(alwaysAdd != 0, trackDiscarded != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_load_element_with_max_distance_cap);
Datum
vector_rust_hnsw_should_load_element_with_max_distance_cap(PG_FUNCTION_ARGS)
{
	int32		alwaysAdd = PG_GETARG_INT32(0);
	int32		trackDiscarded = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldLoadElementWithMaxDistanceCap(alwaysAdd != 0, trackDiscarded != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_track_update_index);
Datum
vector_hnsw_should_track_update_index(PG_FUNCTION_ARGS)
{
	int32		hasUpdateIndexPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTrackUpdateIndex(hasUpdateIndexPointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_track_update_index);
Datum
vector_rust_hnsw_should_track_update_index(PG_FUNCTION_ARGS)
{
	int32		hasUpdateIndexPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTrackUpdateIndex(hasUpdateIndexPointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_process_pruned_candidate);
Datum
vector_hnsw_should_process_pruned_candidate(PG_FUNCTION_ARGS)
{
	int32		hasPrunedCandidate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessPrunedCandidate(hasPrunedCandidate != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_process_pruned_candidate);
Datum
vector_rust_hnsw_should_process_pruned_candidate(PG_FUNCTION_ARGS)
{
	int32		hasPrunedCandidate = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessPrunedCandidate(hasPrunedCandidate != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_trim_candidate_list);
Datum
vector_hnsw_should_trim_candidate_list(PG_FUNCTION_ARGS)
{
	int32		candidateCount = PG_GETARG_INT32(0);
	int32		ef = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldTrimCandidateList(candidateCount, ef, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_trim_candidate_list);
Datum
vector_rust_hnsw_should_trim_candidate_list(PG_FUNCTION_ARGS)
{
	int32		candidateCount = PG_GETARG_INT32(0);
	int32		ef = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldTrimCandidateList(candidateCount, ef, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_always_add_candidate);
Datum
vector_hnsw_should_always_add_candidate(PG_FUNCTION_ARGS)
{
	int32		candidateCount = PG_GETARG_INT32(0);
	int32		ef = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldAlwaysAddCandidate(candidateCount, ef, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_always_add_candidate);
Datum
vector_rust_hnsw_should_always_add_candidate(PG_FUNCTION_ARGS)
{
	int32		candidateCount = PG_GETARG_INT32(0);
	int32		ef = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldAlwaysAddCandidate(candidateCount, ef, true));
}

/*
 * Check if an element is closer to q than any element from R
 */
static bool
CheckElementCloser(char *base, HnswCandidate * e, List *r, HnswSupport * support)
{
	HnswElement eElement = HnswPtrAccess(base, e->element);
	Datum		eValue = HnswGetValue(base, eElement);
	ListCell   *lc2;

	foreach(lc2, r)
	{
		HnswCandidate *ri = lfirst(lc2);
		HnswElement riElement = HnswPtrAccess(base, ri->element);
		Datum		riValue = HnswGetValue(base, riElement);
		float		distance = HnswGetDistance(eValue, riValue, support);

		if (HnswShouldRejectCloserNeighbor(distance, e->distance, true))
			return false;
	}

	return true;
}

/*
 * Algorithm 4 from paper
 */
static List *
SelectNeighbors(char *base, List *c, int lm, HnswSupport * support, bool *closerSet, HnswCandidate * newCandidate, HnswCandidate * *pruned, bool sortCandidates)
{
	List	   *r = NIL;
	List	   *w = list_copy(c);
	HnswCandidate **wd;
	int			wdlen = 0;
	int			wdoff = 0;
	bool		mustCalculate = !(*closerSet);
	List	   *added = NIL;
	bool		removedAny = false;

	if (HnswShouldSelectNeighborsEarlyReturn(list_length(w), lm, true))
		return w;

	wd = palloc(sizeof(HnswCandidate *) * list_length(w));

	/* Ensure order of candidates is deterministic for closer caching */
	if (HnswShouldSortNeighborCandidates(sortCandidates, true))
	{
		if (HnswShouldSortPointerCandidates(base != NULL, true))
			list_sort(w, CompareCandidateDistances);
		else
			list_sort(w, CompareCandidateDistancesOffset);
	}

	while (list_length(w) > 0 && list_length(r) < lm)
	{
		/* Assumes w is already ordered desc */
		HnswCandidate *e = llast(w);

		w = list_delete_last(w);

		/* Use previous state of r and wd to skip work when possible */
		if (HnswShouldCalculateNeighborCloser(mustCalculate, true))
			e->closer = CheckElementCloser(base, e, r, support);
		else if (HnswShouldReuseAddedCandidates(list_length(added), true))
		{
			/* Keep Valgrind happy for in-memory, parallel builds */
			if (HnswShouldDefineCloserStateForBase(base != NULL, true))
				VALGRIND_MAKE_MEM_DEFINED(&e->closer, 1);

			/*
			 * If the current candidate was closer, we only need to compare it
			 * with the other candidates that we have added.
			 */
			if (HnswShouldAppendCloserCandidate(e->closer, true))
			{
				e->closer = CheckElementCloser(base, e, added, support);

				if (!HnswShouldAppendCloserCandidate(e->closer, true))
					removedAny = true;
			}
			else
			{
				/*
				 * If we have removed any candidates from closer, a candidate
				 * that was not closer earlier might now be.
				 */
				if (HnswShouldRecheckCandidateAfterRemoval(removedAny, true))
				{
					e->closer = CheckElementCloser(base, e, r, support);
					if (HnswShouldAppendCloserCandidate(e->closer, true))
						added = lappend(added, e);
				}
			}
		}
		else if (HnswShouldProcessNewCandidateBranch(e == newCandidate, true))
		{
			e->closer = CheckElementCloser(base, e, r, support);
			if (HnswShouldAppendCloserCandidate(e->closer, true))
				added = lappend(added, e);
		}

		/* Keep Valgrind happy for in-memory, parallel builds */
		if (HnswShouldDefineCloserStateForBase(base != NULL, true))
			VALGRIND_MAKE_MEM_DEFINED(&e->closer, 1);

		if (HnswShouldAppendCloserCandidate(e->closer, true))
			r = lappend(r, e);
		else
			wd[wdlen++] = e;
	}

	/* Cached value can only be used in future if sorted deterministically */
	*closerSet = sortCandidates;

	/* Keep pruned connections */
	while (HnswShouldKeepPrunedConnection(wdoff, wdlen, list_length(r), lm, true))
		r = lappend(r, wd[wdoff++]);

	/* Return pruned for update connections */
	if (HnswShouldReturnPrunedOutput(pruned != NULL, true))
	{
		if (HnswShouldSetPrunedFromArray(wdoff, wdlen, true))
			*pruned = wd[wdoff];
		else
			*pruned = linitial(w);
	}

	return r;
}

/*
 * Add connections
 */
static void
AddConnections(char *base, HnswElement element, List *neighbors, int lc)
{
	ListCell   *lc2;
	HnswNeighborArray *a = HnswGetNeighbors(base, element, lc);

	foreach(lc2, neighbors)
		a->items[a->length++] = *((HnswCandidate *) lfirst(lc2));
}

/*
 * Update connections
 */
void
HnswUpdateConnection(char *base, HnswNeighborArray * neighbors, HnswElement newElement, float distance, int lm, int *updateIdx, Relation index, HnswSupport * support)
{
	HnswCandidate newHc;

	HnswPtrStore(base, newHc.element, newElement);
	newHc.distance = distance;

	if (HnswShouldAppendNeighborWithoutPrune(neighbors->length, lm, true))
	{
		neighbors->items[neighbors->length++] = newHc;

		/* Track update */
		if (HnswShouldTrackUpdateIndex(updateIdx != NULL, true))
			*updateIdx = -2;
	}
	else
	{
		/* Shrink connections */
		List	   *c = NIL;
		HnswCandidate *pruned = NULL;

		/* Add candidates */
		for (int i = 0; i < neighbors->length; i++)
			c = lappend(c, &neighbors->items[i]);
		c = lappend(c, &newHc);

		SelectNeighbors(base, c, lm, support, &neighbors->closerSet, &newHc, &pruned, true);

		/* Should not happen */
		if (HnswShouldAbortWithoutPrunedCandidate(pruned != NULL, true))
			return;

		/* Find and replace the pruned element */
		for (int i = 0; i < neighbors->length; i++)
		{
			if (HnswShouldReplacePrunedNeighbor(HnswPtrEqual(base, neighbors->items[i].element, pruned->element), true))
			{
				neighbors->items[i] = newHc;

				/* Track update */
				if (HnswShouldTrackUpdateIndex(updateIdx != NULL, true))
					*updateIdx = i;

				break;
			}
		}
	}
}

/*
 * Remove elements being deleted or skipped
 */
static List *
RemoveElements(char *base, List *w, HnswElement skipElement)
{
	ListCell   *lc2;
	List	   *w2 = NIL;

	/* Ensure does not access heaptidsLength during in-memory build */
	pg_memory_barrier();

	foreach(lc2, w)
	{
		HnswCandidate *hc = (HnswCandidate *) lfirst(lc2);
		HnswElement hce = HnswPtrAccess(base, hc->element);

		/* Skip self for vacuuming update */
		if (HnswShouldSkipSelfForVacuumUpdate(skipElement != NULL, hce->blkno, hce->offno,
											  HnswGetSkipElementBlknoForCompare(skipElement, true),
											  HnswGetSkipElementOffnoForCompare(skipElement, true), true))
			continue;

		if (HnswShouldKeepElementWithHeapTids(hce->heaptidsLength, true))
			w2 = lappend(w2, hc);
	}

	return w2;
}

/*
 * Precompute hash
 */
static void
PrecomputeHash(char *base, HnswElement element)
{
	HnswElementPtr ptr;

	HnswPtrStore(base, ptr, element);

	if (HnswShouldUsePointerHashForBase(base != NULL, true))
		element->hash = hash_pointer((uintptr_t) HnswPtrPointer(ptr));
	else
		element->hash = hash_offset(HnswPtrOffset(ptr));
}

/*
 * Algorithm 1 from paper
 */
void
HnswFindElementNeighbors(char *base, HnswElement element, HnswElement entryPoint, Relation index, HnswSupport * support, int m, int efConstruction, bool existing)
{
	List	   *ep;
	List	   *w;
	int			level = element->level;
	int			entryLevel;
	HnswQuery	q;
	HnswElement skipElement = NULL;
	bool		inMemory = index == NULL;

	if (HnswShouldUseSkipElementForExisting(existing, true))
		skipElement = element;

	q.value = HnswGetValue(base, element);

	/* Precompute hash */
	if (HnswShouldPrecomputeHashForNeighbors(inMemory, true))
		PrecomputeHash(base, element);

	/* No neighbors if no entry point */
	if (HnswShouldReturnWithoutEntryPoint(entryPoint != NULL, true))
		return;

	/* Get entry point and level */
	ep = list_make1(HnswEntryCandidate(base, entryPoint, &q, index, support, true));
	entryLevel = entryPoint->level;

	/* 1st phase: greedy search to insert level */
	for (int lc = entryLevel; lc >= level + 1; lc--)
	{
		w = HnswSearchLayer(base, &q, ep, 1, lc, index, support, m, true, skipElement, NULL, NULL, true, NULL);
		ep = w;
	}

	if (HnswShouldClampNeighborSearchLevel(level, entryLevel, true))
		level = entryLevel;

	/* Add one for existing element */
	if (HnswShouldIncrementEfForExistingElement(existing, true))
		efConstruction++;

	/* 2nd phase */
	for (int lc = level; lc >= 0; lc--)
	{
		int			lm = HnswGetLayerM(m, lc);
		List	   *neighbors;
		List	   *lw = NIL;
		ListCell   *lc2;

		w = HnswSearchLayer(base, &q, ep, efConstruction, lc, index, support, m, true, skipElement, NULL, NULL, true, NULL);

		/* Convert search candidates to candidates */
		foreach(lc2, w)
		{
			HnswSearchCandidate *sc = lfirst(lc2);
			HnswCandidate *hc = palloc(sizeof(HnswCandidate));

			hc->element = sc->element;
			hc->distance = sc->distance;

			lw = lappend(lw, hc);
		}

		/* Elements being deleted or skipped can help with search */
		/* but should be removed before selecting neighbors */
		if (HnswShouldRemoveDiskOnlyElementsBeforeSelect(inMemory, true))
			lw = RemoveElements(base, lw, skipElement);

		/*
		 * Candidates are sorted, but not deterministically. Could set
		 * sortCandidates to true for in-memory builds to enable closer
		 * caching, but there does not seem to be a difference in performance.
		 */
		neighbors = SelectNeighbors(base, lw, lm, support, &HnswGetNeighbors(base, element, lc)->closerSet, NULL, NULL, false);

		AddConnections(base, element, neighbors, lc);

		ep = w;
	}
}

PGDLLEXPORT Datum l2_normalize(PG_FUNCTION_ARGS);
PGDLLEXPORT Datum halfvec_l2_normalize(PG_FUNCTION_ARGS);
PGDLLEXPORT Datum sparsevec_l2_normalize(PG_FUNCTION_ARGS);

static void
SparsevecCheckValue(Pointer v)
{
	SparseVector *vec = (SparseVector *) v;

	if (HnswShouldRejectSparsevecExcessNnz(vec->nnz, HNSW_MAX_NNZ, true))
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("sparsevec cannot have more than %d non-zero elements for hnsw index", HNSW_MAX_NNZ)));
}

/*
 * Get type info
 */
const		HnswTypeInfo *
HnswGetTypeInfo(Relation index)
{
	FmgrInfo   *procinfo = HnswOptionalProcInfo(index, HNSW_TYPE_INFO_PROC);

	if (HnswShouldUseDefaultTypeInfo(procinfo != NULL, true))
	{
		static const HnswTypeInfo typeInfo = {
			.maxDimensions = HNSW_MAX_DIM,
			.normalize = l2_normalize,
			.checkValue = NULL
		};

		return (&typeInfo);
	}
	else
		return (const HnswTypeInfo *) DatumGetPointer(FunctionCall0Coll(procinfo, InvalidOid));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(hnsw_halfvec_support);
Datum
hnsw_halfvec_support(PG_FUNCTION_ARGS)
{
	static const HnswTypeInfo typeInfo = {
		.maxDimensions = HNSW_MAX_DIM * 2,
		.normalize = halfvec_l2_normalize,
		.checkValue = NULL
	};

	PG_RETURN_POINTER(&typeInfo);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(hnsw_bit_support);
Datum
hnsw_bit_support(PG_FUNCTION_ARGS)
{
	static const HnswTypeInfo typeInfo = {
		.maxDimensions = HNSW_MAX_DIM * 32,
		.normalize = NULL,
		.checkValue = NULL
	};

	PG_RETURN_POINTER(&typeInfo);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(hnsw_sparsevec_support);
Datum
hnsw_sparsevec_support(PG_FUNCTION_ARGS)
{
	static const HnswTypeInfo typeInfo = {
		.maxDimensions = SPARSEVEC_MAX_DIM,
		.normalize = sparsevec_l2_normalize,
		.checkValue = SparsevecCheckValue
	};

	PG_RETURN_POINTER(&typeInfo);
}
