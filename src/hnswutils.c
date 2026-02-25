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
static bool HnswShouldUseTidVisitedHash(bool inMemory, bool useRust);
static bool HnswShouldUseOffsetVisitedHash(bool hasBasePointer, bool useRust);
static bool HnswShouldUsePointerVisitedHash(bool hasBasePointer, bool useRust);
static bool HnswShouldUseMemoryEntryDistance(bool inMemory, bool useRust);

/*
 * Get the max number of connections in an upper layer for each element in the index
 */
int
HnswGetM(Relation index)
{
	HnswOptions *opts = (HnswOptions *) index->rd_options;

	if (opts)
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

	if (opts)
		return opts->efConstruction;

	return HNSW_DEFAULT_EF_CONSTRUCTION;
}

/*
 * Get proc
 */
FmgrInfo *
HnswOptionalProcInfo(Relation index, uint16 procnum)
{
	if (!OidIsValid(index_getprocid(index, 1, procnum)))
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
	if (allocator)
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
	if (level > maxLevel)
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

	if (unlikely(metap->magicNumber != HNSW_MAGIC_NUMBER))
		elog(ERROR, "hnsw index is not valid");

	if (m != NULL)
		*m = metap->m;

	if (entryPoint != NULL)
	{
		if (BlockNumberIsValid(metap->entryBlkno))
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

	if (updateEntry)
	{
		if (entryPoint == NULL)
		{
			metap->entryBlkno = InvalidBlockNumber;
			metap->entryOffno = InvalidOffsetNumber;
			metap->entryLevel = -1;
		}
		else if (entryPoint->level > metap->entryLevel || updateEntry == HNSW_UPDATE_ENTRY_ALWAYS)
		{
			metap->entryBlkno = entryPoint->blkno;
			metap->entryOffno = entryPoint->offno;
			metap->entryLevel = entryPoint->level;
		}
	}

	if (BlockNumberIsValid(insertPage))
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
	if (building)
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

	if (building)
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
	if (typeInfo->checkValue != NULL)
		typeInfo->checkValue(DatumGetPointer(value));

	/* Normalize if needed */
	if (support->normprocinfo != NULL)
	{
		if (!HnswCheckNorm(support, value))
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
		if (i < element->heaptidsLength)
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

			if (i < neighbors->length)
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

/*
 * Load an element and optionally get its distance from q
 */
static void
HnswLoadElementImpl(BlockNumber blkno, OffsetNumber offno, double *distance, HnswQuery * q, Relation index, HnswSupport * support, bool loadVec, double *maxDistance, HnswElement * element)
{
	Buffer		buf;
	Page		page;
	HnswElementTuple etup;

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
	if (HnswShouldUpdateElementMaxDistance(distance != NULL, maxDistance != NULL,
										   distance != NULL ? *distance : 0,
										   maxDistance != NULL ? *maxDistance : 0,
										   true))
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
	if (HnswGetSearchCandidateConst(c_node, a)->distance < HnswGetSearchCandidateConst(c_node, b)->distance)
		return 1;

	if (HnswGetSearchCandidateConst(c_node, a)->distance > HnswGetSearchCandidateConst(c_node, b)->distance)
		return -1;

	return 0;
}

/*
 * Compare discarded candidate distances
 */
static int
CompareNearestDiscardedCandidates(const pairingheap_node *a, const pairingheap_node *b, void *arg)
{
	if (HnswGetSearchCandidateConst(w_node, a)->distance < HnswGetSearchCandidateConst(w_node, b)->distance)
		return 1;

	if (HnswGetSearchCandidateConst(w_node, a)->distance > HnswGetSearchCandidateConst(w_node, b)->distance)
		return -1;

	return 0;
}

/*
 * Compare candidate distances
 */
static int
CompareFurthestCandidates(const pairingheap_node *a, const pairingheap_node *b, void *arg)
{
	if (HnswGetSearchCandidateConst(w_node, a)->distance < HnswGetSearchCandidateConst(w_node, b)->distance)
		return -1;

	if (HnswGetSearchCandidateConst(w_node, a)->distance > HnswGetSearchCandidateConst(w_node, b)->distance)
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

	return e->heaptidsLength != 0;
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

	if (v == NULL)
	{
		v = &vh;
		initVisited = true;
	}

	if (initVisited)
	{
		InitVisited(base, v, inMemory, ef, m);

		if (discarded != NULL)
			*discarded = pairingheap_allocate(CompareNearestDiscardedCandidates, NULL);
	}

	/* Create local memory for neighborhood if needed */
	if (inMemory)
	{
		neighborhoodSize = HNSW_NEIGHBOR_ARRAY_SIZE(lm);
		localNeighborhood = palloc(neighborhoodSize);
	}

	/* Add entry points to v, C, and W */
	foreach(lc2, ep)
	{
		HnswSearchCandidate *sc = (HnswSearchCandidate *) lfirst(lc2);
		bool		found;

		if (initVisited)
		{
			AddToVisited(base, v, sc->element, inMemory, &found);

			/* OK to count elements instead of tuples */
			if (tuples != NULL)
				(*tuples)++;
		}

		pairingheap_add(C, &sc->c_node);
		pairingheap_add(W, &sc->w_node);

		/*
		 * Do not count elements being deleted towards ef when vacuuming. It
		 * would be ideal to do this for inserts as well, but this could
		 * affect insert performance.
		 */
		if (CountElement(skipElement, HnswPtrAccess(base, sc->element)))
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

		if (inMemory)
			HnswLoadUnvisitedFromMemory(base, cElement, unvisited, &unvisitedLength, v, lc, localNeighborhood, neighborhoodSize);
		else
			HnswLoadUnvisitedFromDisk(cElement, unvisited, &unvisitedLength, v, index, m, lm, lc);

		/* OK to count elements instead of tuples */
		if (tuples != NULL)
			(*tuples) += unvisitedLength;

		for (int i = 0; i < unvisitedLength; i++)
		{
			HnswElement eElement;
			HnswSearchCandidate *e;
			double		eDistance;
			bool		alwaysAdd = HnswShouldAlwaysAddCandidate(wlen, ef, true);

			f = HnswGetSearchCandidate(w_node, pairingheap_first(W));

			if (inMemory)
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

				/* Avoid any allocations if not adding */
				eElement = NULL;
				trackDiscarded = HnswShouldTrackDiscardedCandidates(discarded != NULL, true);
				HnswLoadElementImpl(blkno, offno, &eDistance, q, index, support, inserting, alwaysAdd || trackDiscarded ? NULL : &f->distance, &eElement);

				if (eElement == NULL)
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
			if (CountElement(skipElement, eElement))
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

	if (hca->distance < hcb->distance)
		return 1;

	if (hca->distance > hcb->distance)
		return -1;

	if (HnswPtrPointer(hca->element) < HnswPtrPointer(hcb->element))
		return 1;

	if (HnswPtrPointer(hca->element) > HnswPtrPointer(hcb->element))
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

	if (hca->distance < hcb->distance)
		return 1;

	if (hca->distance > hcb->distance)
		return -1;

	if (HnswPtrOffset(hca->element) < HnswPtrOffset(hcb->element))
		return 1;

	if (HnswPtrOffset(hca->element) > HnswPtrOffset(hcb->element))
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
	if (sortCandidates)
	{
		if (base == NULL)
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
		if (mustCalculate)
			e->closer = CheckElementCloser(base, e, r, support);
		else if (list_length(added) > 0)
		{
			/* Keep Valgrind happy for in-memory, parallel builds */
			if (base != NULL)
				VALGRIND_MAKE_MEM_DEFINED(&e->closer, 1);

			/*
			 * If the current candidate was closer, we only need to compare it
			 * with the other candidates that we have added.
			 */
			if (e->closer)
			{
				e->closer = CheckElementCloser(base, e, added, support);

				if (!e->closer)
					removedAny = true;
			}
			else
			{
				/*
				 * If we have removed any candidates from closer, a candidate
				 * that was not closer earlier might now be.
				 */
				if (removedAny)
				{
					e->closer = CheckElementCloser(base, e, r, support);
					if (e->closer)
						added = lappend(added, e);
				}
			}
		}
		else if (e == newCandidate)
		{
			e->closer = CheckElementCloser(base, e, r, support);
			if (e->closer)
				added = lappend(added, e);
		}

		/* Keep Valgrind happy for in-memory, parallel builds */
		if (base != NULL)
			VALGRIND_MAKE_MEM_DEFINED(&e->closer, 1);

		if (e->closer)
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
	if (pruned != NULL)
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
		if (!HnswShouldProcessPrunedCandidate(pruned != NULL, true))
			return;

		/* Find and replace the pruned element */
		for (int i = 0; i < neighbors->length; i++)
		{
			if (HnswPtrEqual(base, neighbors->items[i].element, pruned->element))
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
		if (skipElement != NULL && hce->blkno == skipElement->blkno && hce->offno == skipElement->offno)
			continue;

		if (hce->heaptidsLength != 0)
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

	if (base == NULL)
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
	HnswElement skipElement = existing ? element : NULL;
	bool		inMemory = index == NULL;

	q.value = HnswGetValue(base, element);

	/* Precompute hash */
	if (inMemory)
		PrecomputeHash(base, element);

	/* No neighbors if no entry point */
	if (entryPoint == NULL)
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

	if (level > entryLevel)
		level = entryLevel;

	/* Add one for existing element */
	if (existing)
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
		if (!inMemory)
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

	if (vec->nnz > HNSW_MAX_NNZ)
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

	if (procinfo == NULL)
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
