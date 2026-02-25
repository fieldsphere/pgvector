#include "postgres.h"

#include "access/genam.h"
#include "access/generic_xlog.h"
#include "hnsw.h"
#include "rust_ffi.h"
#include "nodes/execnodes.h"
#include "storage/bufmgr.h"
#include "storage/lmgr.h"
#include "utils/datum.h"
#include "utils/memutils.h"
#include "utils/rel.h"

#if PG_VERSION_NUM >= 160000
#include "varatt.h"
#endif

static bool HnswShouldUpdateEntryPointOnDisk(bool entryPointIsNull, int32 elementLevel, int32 entryLevel, bool useRust);
static bool HnswShouldSkipInvalidInsertValue(bool indexValueFormed, bool useRust);
static bool HnswShouldStopOnDiskDuplicateSearchOnValueMismatch(bool valuesEqual, bool useRust);
static bool HnswShouldReturnAfterOnDiskDuplicateInsert(bool duplicateInserted, bool useRust);
static bool HnswShouldSkipOnDiskGraphUpdateForDuplicate(bool duplicateFound, bool useRust);
static bool HnswShouldUpdateOnDiskInsertPage(bool hasNewInsertPage, bool useRust);
static bool HnswShouldRejectOnDiskDuplicateInsertSlot(int32 freeSlotIndex, int32 maxHeaptids, bool useRust);
static bool HnswShouldBreakOnInvalidOnDiskHeapTid(bool heapTidValid, bool useRust);
static bool HnswShouldCommitOnDiskDuplicateWithBufferDirty(bool building, bool useRust);
static bool HnswShouldSkipUnselectedOnDiskNeighbor(int32 updateIndex, bool useRust);
static bool HnswShouldCommitOnDiskNeighborUpdateWithBufferDirty(bool building, bool useRust);
static bool HnswShouldAbortOnDiskNeighborUpdate(bool building, bool useRust);
static bool HnswShouldAppendOnDiskNeighborPage(int64 freeSpace, int64 tupleSize, bool useRust);
static bool HnswShouldAppendOnDiskElementPage(int64 combinedSize, int64 maxSize, int64 freeSpace, int64 elementTupleSize, bool hasNextPage, bool useRust);
static bool HnswShouldAbortOnDiskElementMoveNext(bool building, bool useRust);
static bool HnswShouldCommitOnDiskAddElementWithBufferDirty(bool building, bool useRust);
static bool HnswShouldMarkOnDiskNeighborBufferDirty(bool sameBuffer, bool useRust);
static bool HnswShouldUpdateAddElementInsertPage(bool hasNewInsertPage, bool pageChanged, bool useRust);
static bool HnswShouldReleaseOnDiskNeighborBuffer(bool sameBuffer, bool useRust);
static bool HnswShouldUseNeighborPageAsInsertPage(bool hasNewInsertPage, bool useRust);
static bool HnswShouldUseNextNeighborOffset(bool sameBuffer, bool useRust);
static bool HnswShouldUseFreeOnDiskOffsets(bool freeOffsetValid, bool useRust);
static bool HnswShouldFitOnDiskCombinedTuple(int64 freeSpace, int64 combinedSize, bool useRust);
static bool HnswShouldUseBuildPathForOnDiskAddElement(bool building, bool useRust);
static bool HnswShouldCommitOnDiskPageAppendWithBufferDirty(bool building, bool useRust);
static bool HnswShouldUseBuildPathForAppendedOnDiskBuffer(bool building, bool useRust);
static bool HnswShouldUseBuildPathForReusedOnDiskBuffer(bool building, bool useRust);
static bool HnswShouldFollowOnDiskNextPage(bool nextPageValid, bool useRust);
static bool HnswShouldSetInitialOnDiskInsertPage(bool hasInsertPage, bool hasSpace, bool useRust);
static bool HnswShouldUseBuildPathForOnDiskAppendPage(bool building, bool useRust);
static bool HnswShouldUseBuildPathForOnDiskNeighborUpdate(bool building, bool useRust);
static bool HnswShouldUseBuildPathForOnDiskDuplicatePage(bool building, bool useRust);
static bool HnswShouldAbortOnDiskDuplicateSlotReject(bool building, bool useRust);
static bool HnswShouldUseFreeOnDiskNeighborSlot(bool slotTidValid, bool useRust);
static bool HnswShouldStopOnInvalidOnDiskNeighborTid(bool neighborTidValid, bool useRust);
static bool HnswShouldSkipNonElementTuple(bool isElementTuple, bool useRust);
static bool HnswShouldReuseDeletedOnDiskTuple(bool isDeleted, bool useRust);
static bool HnswShouldSetInsertPageWhenMissing(bool hasInsertPage, bool useRust);
static bool HnswShouldReuseElementBufferForNeighborPage(bool samePage, bool useRust);
static bool HnswShouldReleaseReusedNeighborBuffer(bool sameBuffer, bool useRust);
static bool HnswShouldUseDistinctNeighborPageSpace(bool samePage, bool useRust);
static bool HnswShouldReuseDeletedTupleSpace(int64 pageFree, int64 neighborPageFree, int64 elementTupleSize, int64 neighborTupleSize, bool useRust);
static bool HnswShouldBorrowSamePageNeighborSpace(int64 pageFree, int64 elementTupleSize, bool samePage, bool useRust);
static bool HnswShouldRegisterReusedNeighborBuffer(bool sameBuffer, bool useRust);

/*
 * Get the insert page
 */
static BlockNumber
GetInsertPage(Relation index)
{
	Buffer		buf;
	Page		page;
	HnswMetaPage metap;
	BlockNumber insertPage;

	buf = ReadBuffer(index, HNSW_METAPAGE_BLKNO);
	LockBuffer(buf, BUFFER_LOCK_SHARE);
	page = BufferGetPage(buf);
	metap = HnswPageGetMeta(page);

	insertPage = metap->insertPage;

	UnlockReleaseBuffer(buf);

	return insertPage;
}

/*
 * Check for a free offset
 */
static bool
HnswFreeOffset(Relation index, Buffer buf, Page page, HnswElement element, Size etupSize, Size ntupSize, Buffer *nbuf, Page *npage, OffsetNumber *freeOffno, OffsetNumber *freeNeighborOffno, BlockNumber *newInsertPage, uint8 *tupleVersion)
{
	OffsetNumber offno;
	OffsetNumber maxoffno = PageGetMaxOffsetNumber(page);

	for (offno = FirstOffsetNumber; offno <= maxoffno; offno = OffsetNumberNext(offno))
	{
		ItemId		eitemid = PageGetItemId(page, offno);
		HnswElementTuple etup = (HnswElementTuple) PageGetItem(page, eitemid);

		/* Skip neighbor tuples */
		if (HnswShouldSkipNonElementTuple(HnswIsElementTuple(etup), true))
			continue;

		if (HnswShouldReuseDeletedOnDiskTuple(etup->deleted, true))
		{
			BlockNumber elementPage = BufferGetBlockNumber(buf);
			BlockNumber neighborPage = ItemPointerGetBlockNumber(&etup->neighbortid);
			OffsetNumber neighborOffno = ItemPointerGetOffsetNumber(&etup->neighbortid);
			ItemId		nitemid;
			Size		pageFree;
			Size		npageFree;

			if (HnswShouldSetInsertPageWhenMissing(BlockNumberIsValid(*newInsertPage), true))
				*newInsertPage = elementPage;

			if (HnswShouldReuseElementBufferForNeighborPage(neighborPage == elementPage, true))
			{
				*nbuf = buf;
				*npage = page;
			}
			else
			{
				*nbuf = ReadBuffer(index, neighborPage);
				LockBuffer(*nbuf, BUFFER_LOCK_EXCLUSIVE);

				/* Skip WAL for now */
				*npage = BufferGetPage(*nbuf);
			}

			nitemid = PageGetItemId(*npage, neighborOffno);

			/* Ensure aligned for space check */
			Assert(etupSize == MAXALIGN(etupSize));
			Assert(ntupSize == MAXALIGN(ntupSize));

			/*
			 * Calculate free space individually since tuples are overwritten
			 * individually (in separate calls to PageIndexTupleOverwrite)
			 */
			pageFree = ItemIdGetLength(eitemid) + PageGetExactFreeSpace(page);
			npageFree = ItemIdGetLength(nitemid);
			if (HnswShouldUseDistinctNeighborPageSpace(neighborPage == elementPage, true))
				npageFree += PageGetExactFreeSpace(*npage);
			else if (HnswShouldBorrowSamePageNeighborSpace((int64) pageFree,
											   (int64) etupSize,
											   neighborPage == elementPage,
											   true))
				npageFree += pageFree - etupSize;

			/* Check for space */
			if (HnswShouldReuseDeletedTupleSpace((int64) pageFree,
											 (int64) npageFree,
											 (int64) etupSize,
											 (int64) ntupSize,
											 true))
			{
				*freeOffno = offno;
				*freeNeighborOffno = neighborOffno;
				*tupleVersion = etup->version;
				return true;
			}
			else if (HnswShouldReleaseReusedNeighborBuffer(*nbuf == buf, true))
				UnlockReleaseBuffer(*nbuf);
		}
	}

	return false;
}

/*
 * Add a new page
 */
static void
HnswInsertAppendPage(Relation index, Buffer *nbuf, Page *npage, GenericXLogState *state, Page page, bool building)
{
	/* Add a new page */
	LockRelationForExtension(index, ExclusiveLock);
	*nbuf = HnswNewBuffer(index, MAIN_FORKNUM);
	UnlockRelationForExtension(index, ExclusiveLock);

	/* Init new page */
	if (HnswShouldUseBuildPathForOnDiskAppendPage(building, true))
		*npage = BufferGetPage(*nbuf);
	else
		*npage = GenericXLogRegisterBuffer(state, *nbuf, GENERIC_XLOG_FULL_IMAGE);

	HnswInitPage(*nbuf, *npage);

	/* Update previous buffer */
	HnswPageGetOpaque(page)->nextblkno = BufferGetBlockNumber(*nbuf);
}

/*
 * Add to element and neighbor pages
 */
static void
AddElementOnDisk(Relation index, HnswElement e, int m, BlockNumber insertPage, BlockNumber *updatedInsertPage, bool building)
{
	Buffer		buf;
	Page		page;
	GenericXLogState *state;
	Size		etupSize;
	Size		ntupSize;
	Size		combinedSize;
	Size		maxSize;
	Size		minCombinedSize;
	HnswElementTuple etup;
	BlockNumber currentPage = insertPage;
	HnswNeighborTuple ntup;
	Buffer		nbuf;
	Page		npage;
	OffsetNumber freeOffno = InvalidOffsetNumber;
	OffsetNumber freeNeighborOffno = InvalidOffsetNumber;
	BlockNumber newInsertPage = InvalidBlockNumber;
	uint8		tupleVersion;
	char	   *base = NULL;

	/* Calculate sizes */
	etupSize = HNSW_ELEMENT_TUPLE_SIZE(VARSIZE_ANY(HnswPtrAccess(base, e->value)));
	ntupSize = HNSW_NEIGHBOR_TUPLE_SIZE(e->level, m);
	combinedSize = etupSize + ntupSize + sizeof(ItemIdData);
	maxSize = HNSW_MAX_SIZE;
	minCombinedSize = etupSize + HNSW_NEIGHBOR_TUPLE_SIZE(0, m) + sizeof(ItemIdData);

	/* Prepare element tuple */
	etup = palloc0(etupSize);
	HnswSetElementTuple(base, etup, e);

	/* Prepare neighbor tuple */
	ntup = palloc0(ntupSize);
	HnswSetNeighborTuple(base, ntup, e, m);

	/* Find a page (or two if needed) to insert the tuples */
	for (;;)
	{
		buf = ReadBuffer(index, currentPage);
		LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);

		if (HnswShouldUseBuildPathForOnDiskAddElement(building, true))
		{
			state = NULL;
			page = BufferGetPage(buf);
		}
		else
		{
			state = GenericXLogStart(index);
			page = GenericXLogRegisterBuffer(state, buf, 0);
		}

		/* Keep track of first page where element at level 0 can fit */
		if (HnswShouldSetInitialOnDiskInsertPage(BlockNumberIsValid(newInsertPage),
												 PageGetFreeSpace(page) >= minCombinedSize,
												 true))
			newInsertPage = currentPage;

		/* First, try the fastest path */
		/* Space for both tuples on the current page */
		/* This can split existing tuples in rare cases */
		if (HnswShouldFitOnDiskCombinedTuple((int64) PageGetFreeSpace(page), (int64) combinedSize, true))
		{
			nbuf = buf;
			npage = page;
			break;
		}

		/* Next, try space from a deleted element */
		if (HnswFreeOffset(index, buf, page, e, etupSize, ntupSize, &nbuf, &npage, &freeOffno, &freeNeighborOffno, &newInsertPage, &tupleVersion))
		{
			if (HnswShouldRegisterReusedNeighborBuffer(nbuf == buf, true))
			{
				if (HnswShouldUseBuildPathForReusedOnDiskBuffer(building, true))
					npage = BufferGetPage(nbuf);
				else
					npage = GenericXLogRegisterBuffer(state, nbuf, 0);
			}

			/* Set tuple version */
			etup->version = tupleVersion;
			ntup->version = tupleVersion;

			break;
		}

		/* Finally, try space for element only if last page */
		/* Skip if both tuples can fit on the same page */
		if (HnswShouldAppendOnDiskElementPage((int64) combinedSize,
											  (int64) maxSize,
											  (int64) PageGetFreeSpace(page),
											  (int64) etupSize,
											  BlockNumberIsValid(HnswPageGetOpaque(page)->nextblkno),
											  true))
		{
			HnswInsertAppendPage(index, &nbuf, &npage, state, page, building);
			break;
		}

		currentPage = HnswPageGetOpaque(page)->nextblkno;

		if (HnswShouldFollowOnDiskNextPage(BlockNumberIsValid(currentPage), true))
		{
			/* Move to next page */
			if (HnswShouldAbortOnDiskElementMoveNext(building, true))
				GenericXLogAbort(state);
			UnlockReleaseBuffer(buf);
		}
		else
		{
			Buffer		newbuf;
			Page		newpage;

			HnswInsertAppendPage(index, &newbuf, &newpage, state, page, building);

			/* Commit */
			if (HnswShouldCommitOnDiskPageAppendWithBufferDirty(building, true))
				MarkBufferDirty(buf);
			else
				GenericXLogFinish(state);

			/* Unlock previous buffer */
			UnlockReleaseBuffer(buf);

			/* Prepare new buffer */
			buf = newbuf;
			if (HnswShouldUseBuildPathForAppendedOnDiskBuffer(building, true))
			{
				state = NULL;
				page = BufferGetPage(buf);
			}
			else
			{
				state = GenericXLogStart(index);
				page = GenericXLogRegisterBuffer(state, buf, 0);
			}

			/* Create new page for neighbors if needed */
			if (HnswShouldAppendOnDiskNeighborPage((int64) PageGetFreeSpace(page), (int64) combinedSize, true))
				HnswInsertAppendPage(index, &nbuf, &npage, state, page, building);
			else
			{
				nbuf = buf;
				npage = page;
			}

			break;
		}
	}

	e->blkno = BufferGetBlockNumber(buf);
	e->neighborPage = BufferGetBlockNumber(nbuf);

	/* Added tuple to new page if newInsertPage is not set */
	/* So can set to neighbor page instead of element page */
	if (HnswShouldUseNeighborPageAsInsertPage(BlockNumberIsValid(newInsertPage), true))
		newInsertPage = e->neighborPage;

	if (HnswShouldUseFreeOnDiskOffsets(OffsetNumberIsValid(freeOffno), true))
	{
		e->offno = freeOffno;
		e->neighborOffno = freeNeighborOffno;
	}
	else
	{
		e->offno = OffsetNumberNext(PageGetMaxOffsetNumber(page));
		if (HnswShouldUseNextNeighborOffset(nbuf == buf, true))
			e->neighborOffno = OffsetNumberNext(e->offno);
		else
			e->neighborOffno = FirstOffsetNumber;
	}

	ItemPointerSet(&etup->neighbortid, e->neighborPage, e->neighborOffno);

	/* Add element and neighbors */
	if (HnswShouldUseFreeOnDiskOffsets(OffsetNumberIsValid(freeOffno), true))
	{
		if (!PageIndexTupleOverwrite(page, e->offno, (Item) etup, etupSize))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));

		if (!PageIndexTupleOverwrite(npage, e->neighborOffno, (Item) ntup, ntupSize))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));
	}
	else
	{
		if (PageAddItem(page, (Item) etup, etupSize, InvalidOffsetNumber, false, false) != e->offno)
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));

		if (PageAddItem(npage, (Item) ntup, ntupSize, InvalidOffsetNumber, false, false) != e->neighborOffno)
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));
	}

	/* Commit */
	if (HnswShouldCommitOnDiskAddElementWithBufferDirty(building, true))
	{
		MarkBufferDirty(buf);
		if (HnswShouldMarkOnDiskNeighborBufferDirty(nbuf == buf, true))
			MarkBufferDirty(nbuf);
	}
	else
		GenericXLogFinish(state);
	UnlockReleaseBuffer(buf);
	if (HnswShouldReleaseOnDiskNeighborBuffer(nbuf == buf, true))
		UnlockReleaseBuffer(nbuf);

	/* Update the insert page */
	if (HnswShouldUpdateAddElementInsertPage(BlockNumberIsValid(newInsertPage),
											 newInsertPage != insertPage,
											 true))
		*updatedInsertPage = newInsertPage;
}

/*
 * Load neighbors
 */
static HnswNeighborArray *
HnswLoadNeighbors(HnswElement element, Relation index, int m, int lm, int lc)
{
	char	   *base = NULL;
	HnswNeighborArray *neighbors = HnswInitNeighborArray(lm, NULL);
	ItemPointerData indextids[HNSW_MAX_M * 2];

	if (!HnswLoadNeighborTids(element, indextids, index, m, lm, lc))
		return neighbors;

	for (int i = 0; i < lm; i++)
	{
		ItemPointer indextid = &indextids[i];
		HnswElement e;
		HnswCandidate *hc;

		if (HnswShouldStopOnInvalidOnDiskNeighborTid(ItemPointerIsValid(indextid), true))
			break;

		e = HnswInitElementFromBlock(ItemPointerGetBlockNumber(indextid), ItemPointerGetOffsetNumber(indextid));
		hc = &neighbors->items[neighbors->length++];
		HnswPtrStore(base, hc->element, e);
	}

	return neighbors;
}

/*
 * Load elements for insert
 */
static void
LoadElementsForInsert(HnswNeighborArray * neighbors, HnswQuery * q, int *idx, Relation index, HnswSupport * support)
{
	char	   *base = NULL;

	for (int i = 0; i < neighbors->length; i++)
	{
		HnswCandidate *hc = &neighbors->items[i];
		HnswElement element = HnswPtrAccess(base, hc->element);
		double		distance;

		HnswLoadElement(element, &distance, q, index, support, true, NULL);
		hc->distance = distance;

		/* Prune element if being deleted */
		if (element->heaptidsLength == 0)
		{
			*idx = i;
			break;
		}
	}
}

/*
 * Get update index
 */
static int
GetUpdateIndex(HnswElement element, HnswElement newElement, float distance, int m, int lm, int lc, Relation index, HnswSupport * support, MemoryContext updateCtx)
{
	char	   *base = NULL;
	int			idx = -1;
	HnswNeighborArray *neighbors;
	MemoryContext oldCtx = MemoryContextSwitchTo(updateCtx);

	/*
	 * Get latest neighbors since they may have changed. Do not lock yet since
	 * selecting neighbors can take time. Could use optimistic locking to
	 * retry if another update occurs before getting exclusive lock.
	 */
	neighbors = HnswLoadNeighbors(element, index, m, lm, lc);

	/*
	 * Could improve performance for vacuuming by checking neighbors against
	 * list of elements being deleted to find index. It's important to exclude
	 * already deleted elements for this since they can be replaced at any
	 * time.
	 */

	if (neighbors->length < lm)
		idx = -2;
	else
	{
		HnswQuery	q;

		q.value = HnswGetValue(base, element);

		LoadElementsForInsert(neighbors, &q, &idx, index, support);

		if (idx == -1)
			HnswUpdateConnection(base, neighbors, newElement, distance, lm, &idx, index, support);
	}

	MemoryContextSwitchTo(oldCtx);
	MemoryContextReset(updateCtx);

	return idx;
}

/*
 * Check if connection already exists
 */
static bool
ConnectionExists(HnswElement e, HnswNeighborTuple ntup, int startIdx, int lm)
{
	for (int i = 0; i < lm; i++)
	{
		ItemPointer indextid = &ntup->indextids[startIdx + i];

		if (HnswShouldStopOnInvalidOnDiskNeighborTid(ItemPointerIsValid(indextid), true))
			break;

		if (ItemPointerGetBlockNumber(indextid) == e->blkno && ItemPointerGetOffsetNumber(indextid) == e->offno)
			return true;
	}

	return false;
}

/*
 * Update neighbor
 */
static void
UpdateNeighborOnDisk(HnswElement element, HnswElement newElement, int idx, int m, int lm, int lc, Relation index, bool checkExisting, bool building)
{
	Buffer		buf;
	Page		page;
	GenericXLogState *state;
	HnswNeighborTuple ntup;
	int			startIdx;
	OffsetNumber offno = element->neighborOffno;

	/* Register page */
	buf = ReadBuffer(index, element->neighborPage);
	LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
	if (HnswShouldUseBuildPathForOnDiskNeighborUpdate(building, true))
	{
		state = NULL;
		page = BufferGetPage(buf);
	}
	else
	{
		state = GenericXLogStart(index);
		page = GenericXLogRegisterBuffer(state, buf, 0);
	}

	/* Get tuple */
	ntup = (HnswNeighborTuple) PageGetItem(page, PageGetItemId(page, offno));

	/* Calculate index for update */
	startIdx = (element->level - lc) * m;

	/* Check for existing connection */
	if (checkExisting && ConnectionExists(newElement, ntup, startIdx, lm))
		idx = -1;
	else if (idx == -2)
	{
		/* Find free offset if still exists */
		/* TODO Retry updating connections if not */
		for (int j = 0; j < lm; j++)
		{
			if (HnswShouldUseFreeOnDiskNeighborSlot(ItemPointerIsValid(&ntup->indextids[startIdx + j]), true))
			{
				idx = startIdx + j;
				break;
			}
		}
	}
	else
		idx += startIdx;

	/* Make robust to issues */
	if (idx >= 0 && idx < ntup->count)
	{
		ItemPointer indextid = &ntup->indextids[idx];

		/* Update neighbor on the buffer */
		ItemPointerSet(indextid, newElement->blkno, newElement->offno);

		/* Commit */
		if (HnswShouldCommitOnDiskNeighborUpdateWithBufferDirty(building, true))
			MarkBufferDirty(buf);
		else
			GenericXLogFinish(state);
	}
	else if (HnswShouldAbortOnDiskNeighborUpdate(building, true))
		GenericXLogAbort(state);

	UnlockReleaseBuffer(buf);
}

/*
 * Update neighbors
 */
void
HnswUpdateNeighborsOnDisk(Relation index, HnswSupport * support, HnswElement e, int m, bool checkExisting, bool building)
{
	char	   *base = NULL;

	/* Use separate memory context to improve performance for larger vectors */
	MemoryContext updateCtx = GenerationContextCreate(CurrentMemoryContext,
													  "Hnsw insert update context",
#if PG_VERSION_NUM >= 150000
													  128 * 1024, 128 * 1024,
#endif
													  128 * 1024);

	for (int lc = e->level; lc >= 0; lc--)
	{
		int			lm = HnswGetLayerM(m, lc);
		HnswNeighborArray *neighbors = HnswGetNeighbors(base, e, lc);

		for (int i = 0; i < neighbors->length; i++)
		{
			HnswCandidate *hc = &neighbors->items[i];
			HnswElement neighborElement = HnswPtrAccess(base, hc->element);
			int			idx;

			idx = GetUpdateIndex(neighborElement, e, hc->distance, m, lm, lc, index, support, updateCtx);

			/* New element was not selected as a neighbor */
			if (HnswShouldSkipUnselectedOnDiskNeighbor(idx, true))
				continue;

			UpdateNeighborOnDisk(neighborElement, e, idx, m, lm, lc, index, checkExisting, building);
		}
	}

	MemoryContextDelete(updateCtx);
}

/*
 * Add a heap TID to an existing element
 */
static bool
AddDuplicateOnDisk(Relation index, HnswElement element, HnswElement dup, bool building)
{
	Buffer		buf;
	Page		page;
	GenericXLogState *state;
	HnswElementTuple etup;
	int			i;

	/* Read page */
	buf = ReadBuffer(index, dup->blkno);
	LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
	if (HnswShouldUseBuildPathForOnDiskDuplicatePage(building, true))
	{
		state = NULL;
		page = BufferGetPage(buf);
	}
	else
	{
		state = GenericXLogStart(index);
		page = GenericXLogRegisterBuffer(state, buf, 0);
	}

	/* Find space */
	etup = (HnswElementTuple) PageGetItem(page, PageGetItemId(page, dup->offno));
	for (i = 0; i < HNSW_HEAPTIDS; i++)
	{
		if (HnswShouldBreakOnInvalidOnDiskHeapTid(ItemPointerIsValid(&etup->heaptids[i]), true))
			break;
	}

	/* Either being deleted or we lost our chance to another backend */
	if (HnswShouldRejectOnDiskDuplicateInsertSlot(i, HNSW_HEAPTIDS, true))
	{
		if (HnswShouldAbortOnDiskDuplicateSlotReject(building, true))
			GenericXLogAbort(state);
		UnlockReleaseBuffer(buf);
		return false;
	}

	/* Add heap TID, modifying the tuple on the page directly */
	etup->heaptids[i] = element->heaptids[0];

	/* Commit */
	if (HnswShouldCommitOnDiskDuplicateWithBufferDirty(building, true))
		MarkBufferDirty(buf);
	else
		GenericXLogFinish(state);
	UnlockReleaseBuffer(buf);

	return true;
}

/*
 * Find duplicate element
 */
static bool
FindDuplicateOnDisk(Relation index, HnswElement element, bool building)
{
	char	   *base = NULL;
	HnswNeighborArray *neighbors = HnswGetNeighbors(base, element, 0);
	Datum		value = HnswGetValue(base, element);

	for (int i = 0; i < neighbors->length; i++)
	{
		HnswCandidate *neighbor = &neighbors->items[i];
		HnswElement neighborElement = HnswPtrAccess(base, neighbor->element);
		Datum		neighborValue = HnswGetValue(base, neighborElement);

		/* Exit early since ordered by distance */
		if (HnswShouldStopOnDiskDuplicateSearchOnValueMismatch(datumIsEqual(value, neighborValue, false, -1), true))
			return false;

		if (HnswShouldReturnAfterOnDiskDuplicateInsert(AddDuplicateOnDisk(index, element, neighborElement, building), true))
			return true;
	}

	return false;
}

/*
 * Update graph on disk
 */
static void
UpdateGraphOnDisk(Relation index, HnswSupport * support, HnswElement element, int m, HnswElement entryPoint, bool building)
{
	BlockNumber newInsertPage = InvalidBlockNumber;

	/* Look for duplicate */
	if (HnswShouldSkipOnDiskGraphUpdateForDuplicate(FindDuplicateOnDisk(index, element, building), true))
		return;

	/* Add element */
	AddElementOnDisk(index, element, m, GetInsertPage(index), &newInsertPage, building);

	/* Update insert page if needed */
	if (HnswShouldUpdateOnDiskInsertPage(BlockNumberIsValid(newInsertPage), true))
		HnswUpdateMetaPage(index, 0, NULL, newInsertPage, MAIN_FORKNUM, building);

	/* Update neighbors */
	HnswUpdateNeighborsOnDisk(index, support, element, m, false, building);

	/* Update entry point if needed */
	if (HnswShouldUpdateEntryPointOnDisk(entryPoint == NULL, element->level, entryPoint != NULL ? entryPoint->level : -1, true))
		HnswUpdateMetaPage(index, HNSW_UPDATE_ENTRY_GREATER, element, InvalidBlockNumber, MAIN_FORKNUM, building);
}

/*
 * Insert a tuple into the index
 */
bool
HnswInsertTupleOnDisk(Relation index, HnswSupport * support, Datum value, ItemPointer heaptid, bool building)
{
	HnswElement entryPoint;
	HnswElement element;
	int			m;
	int			efConstruction = HnswGetEfConstruction(index);
	LOCKMODE	lockmode = ShareLock;
	char	   *base = NULL;

	/*
	 * Get a shared lock. This allows vacuum to ensure no in-flight inserts
	 * before repairing graph. Use a page lock so it does not interfere with
	 * buffer lock (or reads when vacuuming).
	 */
	LockPage(index, HNSW_UPDATE_LOCK, lockmode);

	/* Get m and entry point */
	HnswGetMetaPageInfo(index, &m, &entryPoint);

	/* Create an element */
	element = HnswInitElement(base, heaptid, m, HnswGetMl(m), HnswGetMaxLevel(m), NULL);
	HnswPtrStore(base, element->value, (char *) DatumGetPointer(value));

	/* Prevent concurrent inserts when likely updating entry point */
	if (HnswShouldUpdateEntryPointOnDisk(entryPoint == NULL, element->level, entryPoint != NULL ? entryPoint->level : -1, true))
	{
		/* Release shared lock */
		UnlockPage(index, HNSW_UPDATE_LOCK, lockmode);

		/* Get exclusive lock */
		lockmode = ExclusiveLock;
		LockPage(index, HNSW_UPDATE_LOCK, lockmode);

		/* Get latest entry point after lock is acquired */
		entryPoint = HnswGetEntryPoint(index);
	}

	/* Find neighbors for element */
	HnswFindElementNeighbors(base, element, entryPoint, index, support, m, efConstruction, false);

	/* Update graph on disk */
	UpdateGraphOnDisk(index, support, element, m, entryPoint, building);

	/* Release lock */
	UnlockPage(index, HNSW_UPDATE_LOCK, lockmode);

	return true;
}

/*
 * Insert a tuple into the index
 */
static void
HnswInsertTuple(Relation index, Datum *values, bool *isnull, ItemPointer heaptid)
{
	Datum		value;
	const		HnswTypeInfo *typeInfo = HnswGetTypeInfo(index);
	HnswSupport support;

	HnswInitSupport(&support, index);

	/* Form index value */
	if (HnswShouldSkipInvalidInsertValue(HnswFormIndexValue(&value, values, isnull, typeInfo, &support), true))
		return;

	HnswInsertTupleOnDisk(index, &support, value, heaptid, false);
}

static bool
HnswShouldUpdateEntryPointOnDisk(bool entryPointIsNull, int32 elementLevel, int32 entryLevel, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_entry_point_kernel(entryPointIsNull, elementLevel, entryLevel);

	return entryPointIsNull || elementLevel > entryLevel;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_entrypoint_ondisk);
Datum
vector_hnsw_should_update_entrypoint_ondisk(PG_FUNCTION_ARGS)
{
	int32		entryPointIsNull = PG_GETARG_INT32(0);
	int32		elementLevel = PG_GETARG_INT32(1);
	int32		entryLevel = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldUpdateEntryPointOnDisk(entryPointIsNull != 0, elementLevel, entryLevel, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_entrypoint_ondisk);
Datum
vector_rust_hnsw_should_update_entrypoint_ondisk(PG_FUNCTION_ARGS)
{
	int32		entryPointIsNull = PG_GETARG_INT32(0);
	int32		elementLevel = PG_GETARG_INT32(1);
	int32		entryLevel = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldUpdateEntryPointOnDisk(entryPointIsNull != 0, elementLevel, entryLevel, true));
}

static bool
HnswShouldSkipInvalidInsertValue(bool indexValueFormed, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(indexValueFormed);

	return !indexValueFormed;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_invalid_insert_value);
Datum
vector_hnsw_should_skip_invalid_insert_value(PG_FUNCTION_ARGS)
{
	int32		indexValueFormed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipInvalidInsertValue(indexValueFormed != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_invalid_insert_value);
Datum
vector_rust_hnsw_should_skip_invalid_insert_value(PG_FUNCTION_ARGS)
{
	int32		indexValueFormed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipInvalidInsertValue(indexValueFormed != 0, true));
}

static bool
HnswShouldStopOnDiskDuplicateSearchOnValueMismatch(bool valuesEqual, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_stop_duplicate_search_on_value_mismatch_kernel(valuesEqual);

	return !valuesEqual;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch);
Datum
vector_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch(PG_FUNCTION_ARGS)
{
	int32		valuesEqual = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopOnDiskDuplicateSearchOnValueMismatch(valuesEqual != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch);
Datum
vector_rust_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch(PG_FUNCTION_ARGS)
{
	int32		valuesEqual = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopOnDiskDuplicateSearchOnValueMismatch(valuesEqual != 0, true));
}

static bool
HnswShouldReturnAfterOnDiskDuplicateInsert(bool duplicateInserted, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_return_after_duplicate_insert_kernel(duplicateInserted);

	return duplicateInserted;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_after_ondisk_duplicate_insert);
Datum
vector_hnsw_should_return_after_ondisk_duplicate_insert(PG_FUNCTION_ARGS)
{
	int32		duplicateInserted = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnAfterOnDiskDuplicateInsert(duplicateInserted != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_after_ondisk_duplicate_insert);
Datum
vector_rust_hnsw_should_return_after_ondisk_duplicate_insert(PG_FUNCTION_ARGS)
{
	int32		duplicateInserted = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnAfterOnDiskDuplicateInsert(duplicateInserted != 0, true));
}

static bool
HnswShouldSkipOnDiskGraphUpdateForDuplicate(bool duplicateFound, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_update_graph_for_duplicate_kernel(duplicateFound);

	return duplicateFound;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_ondisk_graph_update_for_duplicate);
Datum
vector_hnsw_should_skip_ondisk_graph_update_for_duplicate(PG_FUNCTION_ARGS)
{
	int32		duplicateFound = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipOnDiskGraphUpdateForDuplicate(duplicateFound != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_ondisk_graph_update_for_duplicate);
Datum
vector_rust_hnsw_should_skip_ondisk_graph_update_for_duplicate(PG_FUNCTION_ARGS)
{
	int32		duplicateFound = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipOnDiskGraphUpdateForDuplicate(duplicateFound != 0, true));
}

static bool
HnswShouldUpdateOnDiskInsertPage(bool hasNewInsertPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasNewInsertPage);

	return hasNewInsertPage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_ondisk_insert_page);
Datum
vector_hnsw_should_update_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasNewInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdateOnDiskInsertPage(hasNewInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_ondisk_insert_page);
Datum
vector_rust_hnsw_should_update_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasNewInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdateOnDiskInsertPage(hasNewInsertPage != 0, true));
}

static bool
HnswShouldRejectOnDiskDuplicateInsertSlot(int32 freeSlotIndex, int32 maxHeaptids, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_ondisk_duplicate_insert_slot_kernel(freeSlotIndex, maxHeaptids);

	return freeSlotIndex == 0 || freeSlotIndex == maxHeaptids;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_ondisk_duplicate_insert_slot);
Datum
vector_hnsw_should_reject_ondisk_duplicate_insert_slot(PG_FUNCTION_ARGS)
{
	int32		freeSlotIndex = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectOnDiskDuplicateInsertSlot(freeSlotIndex, maxHeaptids, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_ondisk_duplicate_insert_slot);
Datum
vector_rust_hnsw_should_reject_ondisk_duplicate_insert_slot(PG_FUNCTION_ARGS)
{
	int32		freeSlotIndex = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectOnDiskDuplicateInsertSlot(freeSlotIndex, maxHeaptids, true));
}

static bool
HnswShouldBreakOnInvalidOnDiskHeapTid(bool heapTidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(heapTidValid);

	return !heapTidValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_break_on_invalid_ondisk_heaptid);
Datum
vector_hnsw_should_break_on_invalid_ondisk_heaptid(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldBreakOnInvalidOnDiskHeapTid(heapTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_break_on_invalid_ondisk_heaptid);
Datum
vector_rust_hnsw_should_break_on_invalid_ondisk_heaptid(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldBreakOnInvalidOnDiskHeapTid(heapTidValid != 0, true));
}

static bool
HnswShouldCommitOnDiskDuplicateWithBufferDirty(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty);
Datum
vector_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCommitOnDiskDuplicateWithBufferDirty(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty);
Datum
vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCommitOnDiskDuplicateWithBufferDirty(building != 0, true));
}

static bool
HnswShouldCommitOnDiskNeighborUpdateWithBufferDirty(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty);
Datum
vector_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCommitOnDiskNeighborUpdateWithBufferDirty(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty);
Datum
vector_rust_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCommitOnDiskNeighborUpdateWithBufferDirty(building != 0, true));
}

static bool
HnswShouldAbortOnDiskNeighborUpdate(bool building, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return !building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_abort_ondisk_neighbor_update);
Datum
vector_hnsw_should_abort_ondisk_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortOnDiskNeighborUpdate(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_abort_ondisk_neighbor_update);
Datum
vector_rust_hnsw_should_abort_ondisk_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortOnDiskNeighborUpdate(building != 0, true));
}

static bool
HnswShouldAppendOnDiskNeighborPage(int64 freeSpace, int64 tupleSize, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_append_neighbor_page_kernel(freeSpace, tupleSize);

	return freeSpace < tupleSize;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_append_ondisk_neighbor_page);
Datum
vector_hnsw_should_append_ondisk_neighbor_page(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		tupleSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldAppendOnDiskNeighborPage(freeSpace, tupleSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_append_ondisk_neighbor_page);
Datum
vector_rust_hnsw_should_append_ondisk_neighbor_page(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		tupleSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldAppendOnDiskNeighborPage(freeSpace, tupleSize, true));
}

static bool
HnswShouldAppendOnDiskElementPage(int64 combinedSize, int64 maxSize, int64 freeSpace, int64 elementTupleSize, bool hasNextPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_append_ondisk_element_page_kernel(combinedSize,
																		 maxSize,
																		 freeSpace,
																		 elementTupleSize,
																		 hasNextPage);

	return combinedSize > maxSize && freeSpace >= elementTupleSize && !hasNextPage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_append_ondisk_element_page);
Datum
vector_hnsw_should_append_ondisk_element_page(PG_FUNCTION_ARGS)
{
	int64		combinedSize = PG_GETARG_INT64(0);
	int64		maxSize = PG_GETARG_INT64(1);
	int64		freeSpace = PG_GETARG_INT64(2);
	int64		elementTupleSize = PG_GETARG_INT64(3);
	int32		hasNextPage = PG_GETARG_INT32(4);

	PG_RETURN_BOOL(HnswShouldAppendOnDiskElementPage(combinedSize,
													 maxSize,
													 freeSpace,
													 elementTupleSize,
													 hasNextPage != 0,
													 false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_append_ondisk_element_page);
Datum
vector_rust_hnsw_should_append_ondisk_element_page(PG_FUNCTION_ARGS)
{
	int64		combinedSize = PG_GETARG_INT64(0);
	int64		maxSize = PG_GETARG_INT64(1);
	int64		freeSpace = PG_GETARG_INT64(2);
	int64		elementTupleSize = PG_GETARG_INT64(3);
	int32		hasNextPage = PG_GETARG_INT32(4);

	PG_RETURN_BOOL(HnswShouldAppendOnDiskElementPage(combinedSize,
													 maxSize,
													 freeSpace,
													 elementTupleSize,
													 hasNextPage != 0,
													 true));
}

static bool
HnswShouldAbortOnDiskElementMoveNext(bool building, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return !building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_abort_ondisk_element_move_next);
Datum
vector_hnsw_should_abort_ondisk_element_move_next(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortOnDiskElementMoveNext(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_abort_ondisk_element_move_next);
Datum
vector_rust_hnsw_should_abort_ondisk_element_move_next(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortOnDiskElementMoveNext(building != 0, true));
}

static bool
HnswShouldCommitOnDiskAddElementWithBufferDirty(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_commit_ondisk_add_element_with_buffer_dirty);
Datum
vector_hnsw_should_commit_ondisk_add_element_with_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCommitOnDiskAddElementWithBufferDirty(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_commit_ondisk_add_element_with_buffer_dirty);
Datum
vector_rust_hnsw_should_commit_ondisk_add_element_with_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCommitOnDiskAddElementWithBufferDirty(building != 0, true));
}

static bool
HnswShouldMarkOnDiskNeighborBufferDirty(bool sameBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel(sameBuffer);

	return !sameBuffer;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_mark_ondisk_neighbor_buffer_dirty);
Datum
vector_hnsw_should_mark_ondisk_neighbor_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldMarkOnDiskNeighborBufferDirty(sameBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty);
Datum
vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldMarkOnDiskNeighborBufferDirty(sameBuffer != 0, true));
}

static bool
HnswShouldUpdateAddElementInsertPage(bool hasNewInsertPage, bool pageChanged, bool useRust)
{
	bool		shouldUpdate = hasNewInsertPage && pageChanged;

	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(shouldUpdate);

	return shouldUpdate;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_add_element_insert_page);
Datum
vector_hnsw_should_update_add_element_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasNewInsertPage = PG_GETARG_INT32(0);
	int32		pageChanged = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldUpdateAddElementInsertPage(hasNewInsertPage != 0, pageChanged != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_add_element_insert_page);
Datum
vector_rust_hnsw_should_update_add_element_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasNewInsertPage = PG_GETARG_INT32(0);
	int32		pageChanged = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldUpdateAddElementInsertPage(hasNewInsertPage != 0, pageChanged != 0, true));
}

static bool
HnswShouldUseNeighborPageAsInsertPage(bool hasNewInsertPage, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasNewInsertPage);

	return !hasNewInsertPage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_neighbor_page_as_insert_page);
Datum
vector_hnsw_should_use_neighbor_page_as_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasNewInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNeighborPageAsInsertPage(hasNewInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_neighbor_page_as_insert_page);
Datum
vector_rust_hnsw_should_use_neighbor_page_as_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasNewInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNeighborPageAsInsertPage(hasNewInsertPage != 0, true));
}

static bool
HnswShouldUseNextNeighborOffset(bool sameBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(sameBuffer);

	return sameBuffer;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_next_neighbor_offset);
Datum
vector_hnsw_should_use_next_neighbor_offset(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNextNeighborOffset(sameBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_next_neighbor_offset);
Datum
vector_rust_hnsw_should_use_next_neighbor_offset(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNextNeighborOffset(sameBuffer != 0, true));
}

static bool
HnswShouldUseFreeOnDiskOffsets(bool freeOffsetValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(freeOffsetValid);

	return freeOffsetValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_free_ondisk_offsets);
Datum
vector_hnsw_should_use_free_ondisk_offsets(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseFreeOnDiskOffsets(freeOffsetValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_free_ondisk_offsets);
Datum
vector_rust_hnsw_should_use_free_ondisk_offsets(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseFreeOnDiskOffsets(freeOffsetValid != 0, true));
}

static bool
HnswShouldFitOnDiskCombinedTuple(int64 freeSpace, int64 combinedSize, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_append_neighbor_page_kernel(freeSpace, combinedSize);

	return freeSpace >= combinedSize;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_fit_ondisk_combined_tuple);
Datum
vector_hnsw_should_fit_ondisk_combined_tuple(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		combinedSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldFitOnDiskCombinedTuple(freeSpace, combinedSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_fit_ondisk_combined_tuple);
Datum
vector_rust_hnsw_should_fit_ondisk_combined_tuple(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		combinedSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldFitOnDiskCombinedTuple(freeSpace, combinedSize, true));
}

static bool
HnswShouldUseBuildPathForOnDiskAddElement(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_build_path_for_ondisk_add_element);
Datum
vector_hnsw_should_use_build_path_for_ondisk_add_element(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForOnDiskAddElement(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_build_path_for_ondisk_add_element);
Datum
vector_rust_hnsw_should_use_build_path_for_ondisk_add_element(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForOnDiskAddElement(building != 0, true));
}

static bool
HnswShouldCommitOnDiskPageAppendWithBufferDirty(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_commit_ondisk_page_append_with_buffer_dirty);
Datum
vector_hnsw_should_commit_ondisk_page_append_with_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCommitOnDiskPageAppendWithBufferDirty(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_commit_ondisk_page_append_with_buffer_dirty);
Datum
vector_rust_hnsw_should_commit_ondisk_page_append_with_buffer_dirty(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCommitOnDiskPageAppendWithBufferDirty(building != 0, true));
}

static bool
HnswShouldUseBuildPathForAppendedOnDiskBuffer(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_build_path_for_appended_ondisk_buffer);
Datum
vector_hnsw_should_use_build_path_for_appended_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForAppendedOnDiskBuffer(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_build_path_for_appended_ondisk_buffer);
Datum
vector_rust_hnsw_should_use_build_path_for_appended_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForAppendedOnDiskBuffer(building != 0, true));
}

static bool
HnswShouldUseBuildPathForReusedOnDiskBuffer(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_build_path_for_reused_ondisk_buffer);
Datum
vector_hnsw_should_use_build_path_for_reused_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForReusedOnDiskBuffer(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_build_path_for_reused_ondisk_buffer);
Datum
vector_rust_hnsw_should_use_build_path_for_reused_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForReusedOnDiskBuffer(building != 0, true));
}

static bool
HnswShouldUseBuildPathForOnDiskAppendPage(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_build_path_for_ondisk_append_page);
Datum
vector_hnsw_should_use_build_path_for_ondisk_append_page(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForOnDiskAppendPage(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_build_path_for_ondisk_append_page);
Datum
vector_rust_hnsw_should_use_build_path_for_ondisk_append_page(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForOnDiskAppendPage(building != 0, true));
}

static bool
HnswShouldUseBuildPathForOnDiskNeighborUpdate(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_build_path_for_ondisk_neighbor_update);
Datum
vector_hnsw_should_use_build_path_for_ondisk_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForOnDiskNeighborUpdate(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_build_path_for_ondisk_neighbor_update);
Datum
vector_rust_hnsw_should_use_build_path_for_ondisk_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForOnDiskNeighborUpdate(building != 0, true));
}

static bool
HnswShouldUseBuildPathForOnDiskDuplicatePage(bool building, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_build_path_for_ondisk_duplicate_page);
Datum
vector_hnsw_should_use_build_path_for_ondisk_duplicate_page(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForOnDiskDuplicatePage(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_build_path_for_ondisk_duplicate_page);
Datum
vector_rust_hnsw_should_use_build_path_for_ondisk_duplicate_page(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseBuildPathForOnDiskDuplicatePage(building != 0, true));
}

static bool
HnswShouldAbortOnDiskDuplicateSlotReject(bool building, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);

	return !building;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_abort_ondisk_duplicate_slot_reject);
Datum
vector_hnsw_should_abort_ondisk_duplicate_slot_reject(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortOnDiskDuplicateSlotReject(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_abort_ondisk_duplicate_slot_reject);
Datum
vector_rust_hnsw_should_abort_ondisk_duplicate_slot_reject(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAbortOnDiskDuplicateSlotReject(building != 0, true));
}

static bool
HnswShouldUseFreeOnDiskNeighborSlot(bool slotTidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(slotTidValid);

	return !slotTidValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_free_ondisk_neighbor_slot);
Datum
vector_hnsw_should_use_free_ondisk_neighbor_slot(PG_FUNCTION_ARGS)
{
	int32		slotTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseFreeOnDiskNeighborSlot(slotTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_free_ondisk_neighbor_slot);
Datum
vector_rust_hnsw_should_use_free_ondisk_neighbor_slot(PG_FUNCTION_ARGS)
{
	int32		slotTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseFreeOnDiskNeighborSlot(slotTidValid != 0, true));
}

static bool
HnswShouldStopOnInvalidOnDiskNeighborTid(bool neighborTidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(neighborTidValid);

	return !neighborTidValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_on_invalid_ondisk_neighbor_tid);
Datum
vector_hnsw_should_stop_on_invalid_ondisk_neighbor_tid(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopOnInvalidOnDiskNeighborTid(neighborTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_on_invalid_ondisk_neighbor_tid);
Datum
vector_rust_hnsw_should_stop_on_invalid_ondisk_neighbor_tid(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopOnInvalidOnDiskNeighborTid(neighborTidValid != 0, true));
}

static bool
HnswShouldSkipNonElementTuple(bool isElementTuple, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(isElementTuple);

	return !isElementTuple;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_non_element_tuple);
Datum
vector_hnsw_should_skip_non_element_tuple(PG_FUNCTION_ARGS)
{
	int32		isElementTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNonElementTuple(isElementTuple != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_non_element_tuple);
Datum
vector_rust_hnsw_should_skip_non_element_tuple(PG_FUNCTION_ARGS)
{
	int32		isElementTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNonElementTuple(isElementTuple != 0, true));
}

static bool
HnswShouldReuseDeletedOnDiskTuple(bool isDeleted, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(isDeleted);

	return isDeleted;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reuse_deleted_ondisk_tuple);
Datum
vector_hnsw_should_reuse_deleted_ondisk_tuple(PG_FUNCTION_ARGS)
{
	int32		isDeleted = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReuseDeletedOnDiskTuple(isDeleted != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reuse_deleted_ondisk_tuple);
Datum
vector_rust_hnsw_should_reuse_deleted_ondisk_tuple(PG_FUNCTION_ARGS)
{
	int32		isDeleted = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReuseDeletedOnDiskTuple(isDeleted != 0, true));
}

static bool
HnswShouldSetInsertPageWhenMissing(bool hasInsertPage, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasInsertPage);

	return !hasInsertPage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_set_insert_page_when_missing);
Datum
vector_hnsw_should_set_insert_page_when_missing(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSetInsertPageWhenMissing(hasInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_set_insert_page_when_missing);
Datum
vector_rust_hnsw_should_set_insert_page_when_missing(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSetInsertPageWhenMissing(hasInsertPage != 0, true));
}

static bool
HnswShouldReuseElementBufferForNeighborPage(bool samePage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(samePage);

	return samePage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reuse_element_buffer_for_neighbor_page);
Datum
vector_hnsw_should_reuse_element_buffer_for_neighbor_page(PG_FUNCTION_ARGS)
{
	int32		samePage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReuseElementBufferForNeighborPage(samePage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reuse_element_buffer_for_neighbor_page);
Datum
vector_rust_hnsw_should_reuse_element_buffer_for_neighbor_page(PG_FUNCTION_ARGS)
{
	int32		samePage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReuseElementBufferForNeighborPage(samePage != 0, true));
}

static bool
HnswShouldReleaseReusedNeighborBuffer(bool sameBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel(sameBuffer);

	return !sameBuffer;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_release_reused_neighbor_buffer);
Datum
vector_hnsw_should_release_reused_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReleaseReusedNeighborBuffer(sameBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_release_reused_neighbor_buffer);
Datum
vector_rust_hnsw_should_release_reused_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReleaseReusedNeighborBuffer(sameBuffer != 0, true));
}

static bool
HnswShouldUseDistinctNeighborPageSpace(bool samePage, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_update_ondisk_insert_page_kernel(samePage);

	return !samePage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_distinct_neighbor_page_space);
Datum
vector_hnsw_should_use_distinct_neighbor_page_space(PG_FUNCTION_ARGS)
{
	int32		samePage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDistinctNeighborPageSpace(samePage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_distinct_neighbor_page_space);
Datum
vector_rust_hnsw_should_use_distinct_neighbor_page_space(PG_FUNCTION_ARGS)
{
	int32		samePage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDistinctNeighborPageSpace(samePage != 0, true));
}

static bool
HnswShouldReuseDeletedTupleSpace(int64 pageFree, int64 neighborPageFree, int64 elementTupleSize, int64 neighborTupleSize, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_append_neighbor_page_kernel(pageFree, elementTupleSize) &&
			!vector_rust_hnsw_should_append_neighbor_page_kernel(neighborPageFree, neighborTupleSize);

	return pageFree >= elementTupleSize && neighborPageFree >= neighborTupleSize;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reuse_deleted_tuple_space);
Datum
vector_hnsw_should_reuse_deleted_tuple_space(PG_FUNCTION_ARGS)
{
	int64		pageFree = PG_GETARG_INT64(0);
	int64		neighborPageFree = PG_GETARG_INT64(1);
	int64		elementTupleSize = PG_GETARG_INT64(2);
	int64		neighborTupleSize = PG_GETARG_INT64(3);

	PG_RETURN_BOOL(HnswShouldReuseDeletedTupleSpace(pageFree, neighborPageFree, elementTupleSize, neighborTupleSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reuse_deleted_tuple_space);
Datum
vector_rust_hnsw_should_reuse_deleted_tuple_space(PG_FUNCTION_ARGS)
{
	int64		pageFree = PG_GETARG_INT64(0);
	int64		neighborPageFree = PG_GETARG_INT64(1);
	int64		elementTupleSize = PG_GETARG_INT64(2);
	int64		neighborTupleSize = PG_GETARG_INT64(3);

	PG_RETURN_BOOL(HnswShouldReuseDeletedTupleSpace(pageFree, neighborPageFree, elementTupleSize, neighborTupleSize, true));
}

static bool
HnswShouldBorrowSamePageNeighborSpace(int64 pageFree, int64 elementTupleSize, bool samePage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(samePage) &&
			!vector_rust_hnsw_should_append_neighbor_page_kernel(pageFree, elementTupleSize);

	return samePage && pageFree >= elementTupleSize;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_borrow_same_page_neighbor_space);
Datum
vector_hnsw_should_borrow_same_page_neighbor_space(PG_FUNCTION_ARGS)
{
	int64		pageFree = PG_GETARG_INT64(0);
	int64		elementTupleSize = PG_GETARG_INT64(1);
	int32		samePage = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldBorrowSamePageNeighborSpace(pageFree, elementTupleSize, samePage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_borrow_same_page_neighbor_space);
Datum
vector_rust_hnsw_should_borrow_same_page_neighbor_space(PG_FUNCTION_ARGS)
{
	int64		pageFree = PG_GETARG_INT64(0);
	int64		elementTupleSize = PG_GETARG_INT64(1);
	int32		samePage = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldBorrowSamePageNeighborSpace(pageFree, elementTupleSize, samePage != 0, true));
}

static bool
HnswShouldRegisterReusedNeighborBuffer(bool sameBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel(sameBuffer);

	return !sameBuffer;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_register_reused_neighbor_buffer);
Datum
vector_hnsw_should_register_reused_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRegisterReusedNeighborBuffer(sameBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_register_reused_neighbor_buffer);
Datum
vector_rust_hnsw_should_register_reused_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRegisterReusedNeighborBuffer(sameBuffer != 0, true));
}

static bool
HnswShouldFollowOnDiskNextPage(bool nextPageValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(nextPageValid);

	return nextPageValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_follow_ondisk_next_page);
Datum
vector_hnsw_should_follow_ondisk_next_page(PG_FUNCTION_ARGS)
{
	int32		nextPageValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFollowOnDiskNextPage(nextPageValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_follow_ondisk_next_page);
Datum
vector_rust_hnsw_should_follow_ondisk_next_page(PG_FUNCTION_ARGS)
{
	int32		nextPageValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFollowOnDiskNextPage(nextPageValid != 0, true));
}

static bool
HnswShouldSetInitialOnDiskInsertPage(bool hasInsertPage, bool hasSpace, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasInsertPage) &&
			vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasSpace);

	return !hasInsertPage && hasSpace;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_set_initial_ondisk_insert_page);
Datum
vector_hnsw_should_set_initial_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);
	int32		hasSpace = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSetInitialOnDiskInsertPage(hasInsertPage != 0, hasSpace != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_set_initial_ondisk_insert_page);
Datum
vector_rust_hnsw_should_set_initial_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);
	int32		hasSpace = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSetInitialOnDiskInsertPage(hasInsertPage != 0, hasSpace != 0, true));
}

static bool
HnswShouldReleaseOnDiskNeighborBuffer(bool sameBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel(sameBuffer);

	return !sameBuffer;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_release_ondisk_neighbor_buffer);
Datum
vector_hnsw_should_release_ondisk_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReleaseOnDiskNeighborBuffer(sameBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_release_ondisk_neighbor_buffer);
Datum
vector_rust_hnsw_should_release_ondisk_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReleaseOnDiskNeighborBuffer(sameBuffer != 0, true));
}

static bool
HnswShouldSkipUnselectedOnDiskNeighbor(int32 updateIndex, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_unselected_ondisk_neighbor_kernel(updateIndex);

	return updateIndex == -1;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_unselected_ondisk_neighbor);
Datum
vector_hnsw_should_skip_unselected_ondisk_neighbor(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipUnselectedOnDiskNeighbor(updateIndex, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_unselected_ondisk_neighbor);
Datum
vector_rust_hnsw_should_skip_unselected_ondisk_neighbor(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipUnselectedOnDiskNeighbor(updateIndex, true));
}

static bool
HnswShouldSkipNullInsertTuple(bool isNull, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_null_insert_tuple_kernel(isNull);

	return isNull;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_null_insert_tuple);
Datum
vector_hnsw_should_skip_null_insert_tuple(PG_FUNCTION_ARGS)
{
	int32		isNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNullInsertTuple(isNull != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_null_insert_tuple);
Datum
vector_rust_hnsw_should_skip_null_insert_tuple(PG_FUNCTION_ARGS)
{
	int32		isNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNullInsertTuple(isNull != 0, true));
}

/*
 * Insert a tuple into the index
 */
bool
hnswinsert(Relation index, Datum *values, bool *isnull, ItemPointer heap_tid,
		   Relation heap, IndexUniqueCheck checkUnique
#if PG_VERSION_NUM >= 140000
		   ,bool indexUnchanged
#endif
		   ,IndexInfo *indexInfo
)
{
	MemoryContext oldCtx;
	MemoryContext insertCtx;

	/* Skip nulls */
	if (HnswShouldSkipNullInsertTuple(isnull[0], true))
		return false;

	/* Create memory context */
	insertCtx = AllocSetContextCreate(CurrentMemoryContext,
									  "Hnsw insert temporary context",
									  ALLOCSET_DEFAULT_SIZES);
	oldCtx = MemoryContextSwitchTo(insertCtx);

	/* Insert tuple */
	HnswInsertTuple(index, values, isnull, heap_tid);

	/* Delete memory context */
	MemoryContextSwitchTo(oldCtx);
	MemoryContextDelete(insertCtx);

	return false;
}
