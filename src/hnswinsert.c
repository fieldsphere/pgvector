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
static bool HnswShouldHaveDefaultOnDiskEntryLevel(bool hasEntryPoint, bool useRust);
static bool HnswShouldUseDefaultOnDiskEntryLevel(bool hasEntryPoint, bool useRust);
static bool HnswShouldHaveOnDiskPointerFlag(bool hasPointer, bool useRust);
static bool HnswShouldHaveOnDiskPointer(const void *pointer, bool useRust);
static bool HnswShouldHaveOnDiskEntrypointPointerFlag(bool hasEntryPoint, bool useRust);
static bool HnswShouldHaveOnDiskEntrypointPointer(HnswElement entryPoint, bool useRust);
static bool HnswShouldHaveOnDiskEntrypointFlag(bool hasEntryPoint, bool useRust);
static bool HnswShouldHaveOnDiskEntrypoint(HnswElement entryPoint, bool useRust);
static int HnswGetOnDiskEntryLevelForUpdate(HnswElement entryPoint, bool useRust);
static bool HnswShouldSkipInvalidInsertValue(bool indexValueFormed, bool useRust);
static bool HnswShouldHaveValidInsertIndexValueFlag(bool hasValidIndexValue, bool useRust);
static bool HnswShouldHaveValidInsertIndexValue(bool indexValueFormed, bool useRust);
static bool HnswShouldHaveOnDiskValueMismatchFlag(bool valuesMismatch, bool useRust);
static bool HnswShouldHaveOnDiskValueMismatch(bool valuesEqual, bool useRust);
static bool HnswShouldStopOnDiskDuplicateSearchOnValueMismatch(bool valuesEqual, bool useRust);
static bool HnswShouldReturnAfterOnDiskDuplicateInsert(bool duplicateInserted, bool useRust);
static bool HnswShouldSkipOnDiskGraphUpdateForDuplicate(bool duplicateFound, bool useRust);
static bool HnswShouldUpdateOnDiskInsertPage(bool hasNewInsertPage, bool useRust);
static bool HnswShouldHaveBoundaryDuplicateInsertSlotFlag(bool hasBoundarySlot, bool useRust);
static bool HnswShouldHaveBoundaryDuplicateInsertSlot(int32 freeSlotIndex, int32 maxHeaptids, bool useRust);
static bool HnswShouldRejectOnDiskDuplicateInsertSlot(bool hasBoundarySlot, bool useRust);
static bool HnswShouldHaveInvalidOnDiskHeapTidFlag(bool heapTidValid, bool useRust);
static bool HnswShouldBreakOnInvalidOnDiskHeapTid(bool heapTidValid, bool useRust);
static bool HnswShouldCommitOnDiskDuplicateWithBufferDirty(bool building, bool useRust);
static bool HnswShouldSkipUnselectedOnDiskNeighbor(int32 updateIndex, bool useRust);
static bool HnswShouldCommitOnDiskNeighborUpdateWithBufferDirty(bool building, bool useRust);
static bool HnswShouldHaveNonBuildingOnDiskNeighborUpdate(bool building, bool useRust);
static bool HnswShouldAbortOnDiskNeighborUpdate(bool building, bool useRust);
static bool HnswShouldHaveInsufficientOnDiskNeighborSpace(int64 freeSpace, int64 tupleSize, bool useRust);
static bool HnswShouldAppendOnDiskNeighborPage(int64 freeSpace, int64 tupleSize, bool useRust);
static bool HnswShouldExceedOnDiskElementMaxSizeFlag(bool exceedsMaxSize, bool useRust);
static bool HnswShouldExceedOnDiskElementMaxSize(int64 combinedSize, int64 maxSize, bool useRust);
static bool HnswShouldHaveOnDiskElementWithoutNextPage(bool hasNextPage, bool useRust);
static bool HnswShouldAppendOnDiskElementPage(int64 combinedSize, int64 maxSize, int64 freeSpace, int64 elementTupleSize, bool hasNextPage, bool useRust);
static bool HnswShouldHaveNonBuildingOnDiskElementMoveNext(bool building, bool useRust);
static bool HnswShouldAbortOnDiskElementMoveNext(bool building, bool useRust);
static bool HnswShouldCommitOnDiskAddElementWithBufferDirty(bool building, bool useRust);
static bool HnswShouldMarkOnDiskNeighborBufferDirty(bool sameBuffer, bool useRust);
static bool HnswShouldHaveChangedOnDiskInsertPageFlag(bool pageChanged, bool useRust);
static bool HnswShouldHaveChangedOnDiskInsertPage(BlockNumber newInsertPage, BlockNumber insertPage, bool useRust);
static bool HnswShouldUpdateAddElementInsertPage(bool hasNewInsertPage, bool pageChanged, bool useRust);
static bool HnswShouldHaveDistinctOnDiskNeighborBufferFlag(bool hasDistinctBuffer, bool useRust);
static bool HnswShouldHaveDistinctOnDiskNeighborBuffer(bool sameBuffer, bool useRust);
static bool HnswShouldReleaseOnDiskNeighborBuffer(bool sameBuffer, bool useRust);
static bool HnswShouldHaveNeighborPageAsInsertPage(bool hasNewInsertPage, bool useRust);
static bool HnswShouldUseNeighborPageAsInsertPage(bool hasNewInsertPage, bool useRust);
static bool HnswShouldHaveNextNeighborOffset(bool sameBuffer, bool useRust);
static bool HnswShouldUseNextNeighborOffset(bool sameBuffer, bool useRust);
static bool HnswShouldHaveFreeOnDiskOffsetFlag(bool freeOffsetValid, bool useRust);
static bool HnswShouldHaveValidOnDiskOffsetNumberFlag(bool offsetNumberValid, bool useRust);
static bool HnswShouldHaveValidOnDiskOffsetNumber(OffsetNumber freeOffno, bool useRust);
static bool HnswShouldHaveFreeOnDiskOffset(OffsetNumber freeOffno, bool useRust);
static bool HnswShouldHaveFreeOnDiskOffsets(bool freeOffsetValid, bool useRust);
static bool HnswShouldUseFreeOnDiskOffsets(bool freeOffsetValid, bool useRust);
static bool HnswShouldProcessFreeOffsetResult(bool freeOffsetResult, bool useRust);
static bool HnswShouldHaveOnDiskSpaceForCombinedTuple(int64 freeSpace, int64 combinedSize, bool useRust);
static bool HnswShouldFitOnDiskCombinedTuple(int64 freeSpace, int64 combinedSize, bool useRust);
static bool HnswShouldUseBuildPathForOnDiskAddElement(bool building, bool useRust);
static bool HnswShouldCommitOnDiskPageAppendWithBufferDirty(bool building, bool useRust);
static bool HnswShouldUseBuildPathForAppendedOnDiskBuffer(bool building, bool useRust);
static bool HnswShouldUseBuildPathForReusedOnDiskBuffer(bool building, bool useRust);
static bool HnswShouldFollowOnDiskNextPage(bool nextPageValid, bool useRust);
static bool HnswShouldHaveOnDiskNextPageFlag(bool nextPageValid, bool useRust);
static bool HnswShouldHaveOnDiskNextPage(BlockNumber nextPage, bool useRust);
static bool HnswShouldSetInitialOnDiskInsertPage(bool hasInsertPage, bool hasSpace, bool useRust);
static bool HnswShouldUseBuildPathForOnDiskAppendPage(bool building, bool useRust);
static bool HnswShouldUseBuildPathForOnDiskNeighborUpdate(bool building, bool useRust);
static bool HnswShouldUseBuildPathForOnDiskDuplicatePage(bool building, bool useRust);
static bool HnswShouldHaveNonBuildingOnDiskDuplicateSlotReject(bool building, bool useRust);
static bool HnswShouldAbortOnDiskDuplicateSlotReject(bool building, bool useRust);
static bool HnswShouldHaveOnDiskInsertSpaceFlag(bool hasSpace, bool useRust);
static bool HnswShouldHaveOnDiskItemPointerFlag(bool itemPointerValid, bool useRust);
static bool HnswShouldHaveOnDiskItemPointer(ItemPointer itemPointer, bool useRust);
static bool HnswShouldHaveOnDiskHeapTidFlag(bool heapTidValid, bool useRust);
static bool HnswShouldHaveOnDiskHeapTid(ItemPointer heaptid, bool useRust);
static bool HnswShouldHaveOnDiskNeighborTidFlag(bool neighborTidValid, bool useRust);
static bool HnswShouldHaveOnDiskNeighborTid(ItemPointer indextid, bool useRust);
static bool HnswShouldHaveInvalidOnDiskNeighborSlotFlag(bool slotTidValid, bool useRust);
static bool HnswShouldHaveFreeOnDiskNeighborSlot(bool slotTidValid, bool useRust);
static bool HnswShouldUseFreeOnDiskNeighborSlot(bool slotTidValid, bool useRust);
static bool HnswShouldHaveInvalidOnDiskNeighborTidFlag(bool neighborTidValid, bool useRust);
static bool HnswShouldStopOnInvalidOnDiskNeighborTid(bool neighborTidValid, bool useRust);
static bool HnswShouldHaveMatchingNeighborBlockFlag(bool hasMatchingBlock, bool useRust);
static bool HnswShouldHaveMatchingNeighborBlock(int32 indextidBlkno, int32 elementBlkno, bool useRust);
static bool HnswShouldHaveMatchingNeighborOffsetFlag(bool hasMatchingOffset, bool useRust);
static bool HnswShouldHaveMatchingNeighborOffset(int32 indextidOffno, int32 elementOffno, bool useRust);
static bool HnswShouldMatchNeighborConnection(int32 indextidBlkno, int32 indextidOffno, int32 elementBlkno, int32 elementOffno, bool useRust);
static bool HnswShouldSkipNonElementTuple(bool isElementTuple, bool useRust);
static bool HnswShouldReuseDeletedOnDiskTuple(bool isDeleted, bool useRust);
static bool HnswShouldSetInsertPageWhenMissing(bool hasInsertPage, bool useRust);
static bool HnswShouldHaveMissingOnDiskInsertPage(bool hasInsertPage, bool useRust);
static bool HnswShouldHaveOnDiskBlockFlag(bool blockValid, bool useRust);
static bool HnswShouldHaveValidOnDiskBlockNumberFlag(bool blockNumberValid, bool useRust);
static bool HnswShouldHaveValidOnDiskBlockNumber(BlockNumber blkno, bool useRust);
static bool HnswShouldHaveOnDiskBlockNumber(BlockNumber blkno, bool useRust);
static bool HnswShouldHaveOnDiskInsertPageFlag(bool hasInsertPage, bool useRust);
static bool HnswShouldHaveOnDiskInsertPage(BlockNumber insertPage, bool useRust);
static bool HnswShouldReuseElementBufferForNeighborPage(bool samePage, bool useRust);
static bool HnswShouldHaveMatchingNeighborPageFlag(bool hasMatchingPage, bool useRust);
static bool HnswShouldHaveMatchingNeighborPage(int32 neighborPage, int32 elementPage, bool useRust);
static bool HnswShouldMatchNeighborPages(int32 neighborPage, int32 elementPage, bool useRust);
static bool HnswShouldHaveMatchingOnDiskBufferFlag(bool hasMatchingBuffer, bool useRust);
static bool HnswShouldHaveMatchingOnDiskBuffer(int32 leftBuffer, int32 rightBuffer, bool useRust);
static bool HnswShouldMatchOnDiskBuffers(int32 leftBuffer, int32 rightBuffer, bool useRust);
static bool HnswShouldReleaseReusedNeighborBuffer(bool sameBuffer, bool useRust);
static bool HnswShouldHaveDistinctNeighborPageSpace(bool samePage, bool useRust);
static bool HnswShouldUseDistinctNeighborPageSpace(bool samePage, bool useRust);
static bool HnswShouldHavePageSpaceForTuple(int64 pageFree, int64 tupleSize, bool useRust);
static bool HnswShouldReuseDeletedTupleSpace(int64 pageFree, int64 neighborPageFree, int64 elementTupleSize, int64 neighborTupleSize, bool useRust);
static bool HnswShouldBorrowSamePageNeighborSpace(int64 pageFree, int64 elementTupleSize, bool samePage, bool useRust);
static bool HnswShouldRegisterReusedNeighborBuffer(bool sameBuffer, bool useRust);
static bool HnswShouldReturnEmptyWithoutNeighborTids(bool neighborTidsLoaded, bool useRust);
static bool HnswShouldHaveEmptyInsertHeapTidsFlag(bool hasEmptyHeapTids, bool useRust);
static bool HnswShouldHaveEmptyInsertHeapTids(int32 heaptidsLength, bool useRust);
static bool HnswShouldPruneDeletedInsertElement(int32 heaptidsLength, bool useRust);
static bool HnswShouldHaveNeighborCountBeforeLayerM(int32 neighborCount, int32 layerM, bool useRust);
static bool HnswShouldProbeForFreeNeighborSlot(int32 neighborCount, int32 layerM, bool useRust);
static bool HnswShouldHaveExistingNeighborCheckFlag(bool shouldCheckExisting, bool useRust);
static bool HnswShouldHaveExistingNeighborCheck(bool checkExisting, bool useRust);
static bool HnswShouldHaveExistingNeighborConnectionFlag(bool hasConnection, bool useRust);
static bool HnswShouldHaveExistingNeighborConnection(bool connectionExists, bool useRust);
static bool HnswShouldSkipExistingNeighborUpdate(bool checkExisting, bool connectionExists, bool useRust);
static bool HnswShouldProbeUndecidedUpdateIndex(int32 updateIndex, bool useRust);
static bool HnswShouldHaveNonNegativeUpdateIndexFlag(bool isNonNegative, bool useRust);
static bool HnswShouldHaveNonNegativeUpdateIndex(int32 updateIndex, bool useRust);
static bool HnswShouldHaveUpdateIndexBeforeTupleCount(int32 updateIndex, int32 tupleCount, bool useRust);
static bool HnswShouldApplyNeighborUpdateSlot(int32 updateIndex, int32 tupleCount, bool useRust);
static bool HnswShouldHaveCandidateUpdateIndexFlag(bool hasCandidateIndex, bool useRust);
static bool HnswShouldHaveCandidateUpdateIndex(int32 updateIndex, bool useRust);
static bool HnswShouldUpdateConnectionFromCandidateIndex(int32 updateIndex, bool useRust);
static bool HnswShouldRejectOnDiskElementOverwrite(bool overwriteSucceeded, bool useRust);
static bool HnswShouldHaveExpectedOnDiskOffsetFlag(bool hasExpectedOffset, bool useRust);
static bool HnswShouldHaveExpectedOnDiskOffset(int32 insertedOffset, int32 expectedOffset, bool useRust);
static bool HnswShouldRejectOnDiskUnexpectedOffset(bool hasExpectedOffset, bool useRust);

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
			bool		samePage;
			bool		sameBuffer;

			samePage = HnswShouldMatchNeighborPages((int32) neighborPage, (int32) elementPage, true);

			if (HnswShouldSetInsertPageWhenMissing(HnswShouldHaveOnDiskInsertPage(*newInsertPage, true), true))
				*newInsertPage = elementPage;

			if (HnswShouldReuseElementBufferForNeighborPage(samePage, true))
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
			if (HnswShouldUseDistinctNeighborPageSpace(samePage, true))
				npageFree += PageGetExactFreeSpace(*npage);
			else if (HnswShouldBorrowSamePageNeighborSpace((int64) pageFree,
											   (int64) etupSize,
											   samePage,
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
			sameBuffer = HnswShouldMatchOnDiskBuffers((int32) *nbuf, (int32) buf, true);
			if (HnswShouldReleaseReusedNeighborBuffer(sameBuffer, true))
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
	bool		sameBuffer;
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
		if (HnswShouldSetInitialOnDiskInsertPage(HnswShouldHaveOnDiskInsertPage(newInsertPage, true),
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
		if (HnswShouldProcessFreeOffsetResult(HnswFreeOffset(index, buf, page, e, etupSize, ntupSize, &nbuf, &npage, &freeOffno, &freeNeighborOffno, &newInsertPage, &tupleVersion), true))
		{
			sameBuffer = HnswShouldMatchOnDiskBuffers((int32) nbuf, (int32) buf, true);
			if (HnswShouldRegisterReusedNeighborBuffer(sameBuffer, true))
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
											  HnswShouldHaveOnDiskNextPage(HnswPageGetOpaque(page)->nextblkno, true),
											  true))
		{
			HnswInsertAppendPage(index, &nbuf, &npage, state, page, building);
			break;
		}

		currentPage = HnswPageGetOpaque(page)->nextblkno;

		if (HnswShouldFollowOnDiskNextPage(HnswShouldHaveOnDiskNextPage(currentPage, true), true))
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
	if (HnswShouldUseNeighborPageAsInsertPage(HnswShouldHaveOnDiskInsertPage(newInsertPage, true), true))
		newInsertPage = e->neighborPage;

	if (HnswShouldUseFreeOnDiskOffsets(HnswShouldHaveFreeOnDiskOffset(freeOffno, true), true))
	{
		e->offno = freeOffno;
		e->neighborOffno = freeNeighborOffno;
	}
	else
	{
		e->offno = OffsetNumberNext(PageGetMaxOffsetNumber(page));
		sameBuffer = HnswShouldMatchOnDiskBuffers((int32) nbuf, (int32) buf, true);
		if (HnswShouldUseNextNeighborOffset(sameBuffer, true))
			e->neighborOffno = OffsetNumberNext(e->offno);
		else
			e->neighborOffno = FirstOffsetNumber;
	}

	ItemPointerSet(&etup->neighbortid, e->neighborPage, e->neighborOffno);

	/* Add element and neighbors */
	if (HnswShouldUseFreeOnDiskOffsets(HnswShouldHaveFreeOnDiskOffset(freeOffno, true), true))
	{
		if (HnswShouldRejectOnDiskElementOverwrite(PageIndexTupleOverwrite(page, e->offno, (Item) etup, etupSize), true))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));

		if (HnswShouldRejectOnDiskElementOverwrite(PageIndexTupleOverwrite(npage, e->neighborOffno, (Item) ntup, ntupSize), true))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));
	}
	else
	{
		if (HnswShouldRejectOnDiskUnexpectedOffset(HnswShouldHaveExpectedOnDiskOffset((int32) PageAddItem(page, (Item) etup, etupSize, InvalidOffsetNumber, false, false),
												   (int32) e->offno,
												   true),
												   true))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));

		if (HnswShouldRejectOnDiskUnexpectedOffset(HnswShouldHaveExpectedOnDiskOffset((int32) PageAddItem(npage, (Item) ntup, ntupSize, InvalidOffsetNumber, false, false),
												   (int32) e->neighborOffno,
												   true),
												   true))
			elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));
	}

	/* Commit */
	sameBuffer = HnswShouldMatchOnDiskBuffers((int32) nbuf, (int32) buf, true);
	if (HnswShouldCommitOnDiskAddElementWithBufferDirty(building, true))
	{
		MarkBufferDirty(buf);
		if (HnswShouldMarkOnDiskNeighborBufferDirty(sameBuffer, true))
			MarkBufferDirty(nbuf);
	}
	else
		GenericXLogFinish(state);
	UnlockReleaseBuffer(buf);
	if (HnswShouldReleaseOnDiskNeighborBuffer(sameBuffer, true))
		UnlockReleaseBuffer(nbuf);

	/* Update the insert page */
	if (HnswShouldUpdateAddElementInsertPage(HnswShouldHaveOnDiskInsertPage(newInsertPage, true),
											 HnswShouldHaveChangedOnDiskInsertPage(newInsertPage, insertPage, true),
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

	if (HnswShouldReturnEmptyWithoutNeighborTids(HnswLoadNeighborTids(element, indextids, index, m, lm, lc), true))
		return neighbors;

	for (int i = 0; i < lm; i++)
	{
		ItemPointer indextid = &indextids[i];
		HnswElement e;
		HnswCandidate *hc;

		if (HnswShouldStopOnInvalidOnDiskNeighborTid(HnswShouldHaveOnDiskNeighborTid(indextid, true), true))
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
		if (HnswShouldPruneDeletedInsertElement(element->heaptidsLength, true))
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

	if (HnswShouldProbeForFreeNeighborSlot(neighbors->length, lm, true))
		idx = -2;
	else
	{
		HnswQuery	q;

		q.value = HnswGetValue(base, element);

		LoadElementsForInsert(neighbors, &q, &idx, index, support);

		if (HnswShouldUpdateConnectionFromCandidateIndex(idx, true))
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

		if (HnswShouldStopOnInvalidOnDiskNeighborTid(HnswShouldHaveOnDiskNeighborTid(indextid, true), true))
			break;

		if (HnswShouldMatchNeighborConnection((int32) ItemPointerGetBlockNumber(indextid), (int32) ItemPointerGetOffsetNumber(indextid), (int32) e->blkno, (int32) e->offno, true))
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
	if (HnswShouldSkipExistingNeighborUpdate(checkExisting,
											 ConnectionExists(newElement, ntup, startIdx, lm),
											 true))
		idx = -1;
	else if (HnswShouldProbeUndecidedUpdateIndex(idx, true))
	{
		/* Find free offset if still exists */
		/* TODO Retry updating connections if not */
		for (int j = 0; j < lm; j++)
		{
			if (HnswShouldUseFreeOnDiskNeighborSlot(HnswShouldHaveOnDiskNeighborTid(&ntup->indextids[startIdx + j], true), true))
			{
				idx = startIdx + j;
				break;
			}
		}
	}
	else
		idx += startIdx;

	/* Make robust to issues */
	if (HnswShouldApplyNeighborUpdateSlot(idx, ntup->count, true))
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
		if (HnswShouldBreakOnInvalidOnDiskHeapTid(HnswShouldHaveOnDiskHeapTid(&etup->heaptids[i], true), true))
			break;
	}

	/* Either being deleted or we lost our chance to another backend */
	if (HnswShouldRejectOnDiskDuplicateInsertSlot(HnswShouldHaveBoundaryDuplicateInsertSlot(i, HNSW_HEAPTIDS, true), true))
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
	if (HnswShouldUpdateOnDiskInsertPage(HnswShouldHaveOnDiskInsertPage(newInsertPage, true), true))
		HnswUpdateMetaPage(index, 0, NULL, newInsertPage, MAIN_FORKNUM, building);

	/* Update neighbors */
	HnswUpdateNeighborsOnDisk(index, support, element, m, false, building);

	/* Update entry point if needed */
	if (HnswShouldUpdateEntryPointOnDisk(!HnswShouldHaveOnDiskEntrypoint(entryPoint, true), element->level, HnswGetOnDiskEntryLevelForUpdate(entryPoint, true), true))
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
	if (HnswShouldUpdateEntryPointOnDisk(!HnswShouldHaveOnDiskEntrypoint(entryPoint, true), element->level, HnswGetOnDiskEntryLevelForUpdate(entryPoint, true), true))
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
HnswShouldHaveHigherOnDiskEntrypointLevel(int32 elementLevel, int32 entryLevel, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_entry_point_kernel(false, elementLevel, entryLevel);
}

static bool
HnswShouldUpdateEntryPointOnDisk(bool entryPointIsNull, int32 elementLevel, int32 entryLevel, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(entryPointIsNull) ||
		HnswShouldHaveHigherOnDiskEntrypointLevel(elementLevel, entryLevel, true);
}

static bool
HnswShouldHaveDefaultOnDiskEntryLevel(bool hasEntryPoint, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasEntryPoint);
}

static bool
HnswShouldUseDefaultOnDiskEntryLevel(bool hasEntryPoint, bool useRust)
{
	return HnswShouldHaveDefaultOnDiskEntryLevel(hasEntryPoint, useRust);
}

static bool
HnswShouldHaveOnDiskPointerFlag(bool hasPointer, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasPointer);
}

static bool
HnswShouldHaveOnDiskPointer(const void *pointer, bool useRust)
{
	return HnswShouldHaveOnDiskPointerFlag(pointer != NULL, useRust);
}

static bool
HnswShouldHaveOnDiskEntrypointPointerFlag(bool hasEntryPoint, bool useRust)
{
	return HnswShouldHaveOnDiskPointerFlag(hasEntryPoint, useRust);
}

static bool
HnswShouldHaveOnDiskEntrypointPointer(HnswElement entryPoint, bool useRust)
{
	return HnswShouldHaveOnDiskPointer((const void *) entryPoint, useRust);
}

static bool
HnswShouldHaveOnDiskEntrypointFlag(bool hasEntryPoint, bool useRust)
{
	return HnswShouldHaveOnDiskEntrypointPointerFlag(hasEntryPoint, useRust);
}

static bool
HnswShouldHaveOnDiskEntrypoint(HnswElement entryPoint, bool useRust)
{
	return HnswShouldHaveOnDiskEntrypointPointer(entryPoint, useRust);
}

static int
HnswGetOnDiskEntryLevelForUpdate(HnswElement entryPoint, bool useRust)
{
	if (HnswShouldUseDefaultOnDiskEntryLevel(HnswShouldHaveOnDiskEntrypoint(entryPoint, useRust), useRust))
		return -1;

	return entryPoint->level;
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_higher_ondisk_entrypoint_level);
Datum
vector_hnsw_should_have_higher_ondisk_entrypoint_level(PG_FUNCTION_ARGS)
{
	int32		elementLevel = PG_GETARG_INT32(0);
	int32		entryLevel = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveHigherOnDiskEntrypointLevel(elementLevel, entryLevel, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_higher_ondisk_entrypoint_level);
Datum
vector_rust_hnsw_should_have_higher_ondisk_entrypoint_level(PG_FUNCTION_ARGS)
{
	int32		elementLevel = PG_GETARG_INT32(0);
	int32		entryLevel = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveHigherOnDiskEntrypointLevel(elementLevel, entryLevel, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_entrypoint);
Datum
vector_hnsw_should_have_ondisk_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointFlag(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_entrypoint);
Datum
vector_rust_hnsw_should_have_ondisk_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointFlag(hasEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_entrypoint_flag);
Datum
vector_hnsw_should_have_ondisk_entrypoint_flag(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointFlag(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_entrypoint_flag);
Datum
vector_rust_hnsw_should_have_ondisk_entrypoint_flag(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointFlag(hasEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_entrypoint_value);
Datum
vector_hnsw_should_have_ondisk_entrypoint_value(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);
	const char *mockEntryPoint = "entrypoint";
	HnswElement	entryPoint = hasEntryPoint != 0 ? (HnswElement) mockEntryPoint : NULL;

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypoint(entryPoint, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_entrypoint_value);
Datum
vector_rust_hnsw_should_have_ondisk_entrypoint_value(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);
	const char *mockEntryPoint = "entrypoint";
	HnswElement	entryPoint = hasEntryPoint != 0 ? (HnswElement) mockEntryPoint : NULL;

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypoint(entryPoint, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_entrypoint_pointer);
Datum
vector_hnsw_should_have_ondisk_entrypoint_pointer(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointPointerFlag(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_entrypoint_pointer);
Datum
vector_rust_hnsw_should_have_ondisk_entrypoint_pointer(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointPointerFlag(hasEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_entrypoint_pointer_flag);
Datum
vector_hnsw_should_have_ondisk_entrypoint_pointer_flag(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointPointerFlag(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_entrypoint_pointer_flag);
Datum
vector_rust_hnsw_should_have_ondisk_entrypoint_pointer_flag(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointPointerFlag(hasEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_entrypoint_pointer_value);
Datum
vector_hnsw_should_have_ondisk_entrypoint_pointer_value(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);
	const char *mockEntryPoint = "entrypoint";
	HnswElement	entryPoint = hasEntryPoint != 0 ? (HnswElement) mockEntryPoint : NULL;

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointPointer(entryPoint, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_entrypoint_pointer_value);
Datum
vector_rust_hnsw_should_have_ondisk_entrypoint_pointer_value(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);
	const char *mockEntryPoint = "entrypoint";
	HnswElement	entryPoint = hasEntryPoint != 0 ? (HnswElement) mockEntryPoint : NULL;

	PG_RETURN_BOOL(HnswShouldHaveOnDiskEntrypointPointer(entryPoint, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_pointer);
Datum
vector_hnsw_should_have_ondisk_pointer(PG_FUNCTION_ARGS)
{
	int32		hasPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskPointerFlag(hasPointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_pointer);
Datum
vector_rust_hnsw_should_have_ondisk_pointer(PG_FUNCTION_ARGS)
{
	int32		hasPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskPointerFlag(hasPointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_pointer_flag);
Datum
vector_hnsw_should_have_ondisk_pointer_flag(PG_FUNCTION_ARGS)
{
	int32		hasPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskPointerFlag(hasPointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_pointer_flag);
Datum
vector_rust_hnsw_should_have_ondisk_pointer_flag(PG_FUNCTION_ARGS)
{
	int32		hasPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskPointerFlag(hasPointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_pointer_value);
Datum
vector_hnsw_should_have_ondisk_pointer_value(PG_FUNCTION_ARGS)
{
	int32		hasPointer = PG_GETARG_INT32(0);
	const char *mockPointer = "pointer";
	const void *pointer = hasPointer != 0 ? (const void *) mockPointer : NULL;

	PG_RETURN_BOOL(HnswShouldHaveOnDiskPointer(pointer, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_pointer_value);
Datum
vector_rust_hnsw_should_have_ondisk_pointer_value(PG_FUNCTION_ARGS)
{
	int32		hasPointer = PG_GETARG_INT32(0);
	const char *mockPointer = "pointer";
	const void *pointer = hasPointer != 0 ? (const void *) mockPointer : NULL;

	PG_RETURN_BOOL(HnswShouldHaveOnDiskPointer(pointer, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_default_ondisk_entry_level);
Datum
vector_hnsw_should_use_default_ondisk_entry_level(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultOnDiskEntryLevel(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_default_ondisk_entry_level);
Datum
vector_rust_hnsw_should_use_default_ondisk_entry_level(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultOnDiskEntryLevel(hasEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_default_ondisk_entry_level);
Datum
vector_hnsw_should_have_default_ondisk_entry_level(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveDefaultOnDiskEntryLevel(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_default_ondisk_entry_level);
Datum
vector_rust_hnsw_should_have_default_ondisk_entry_level(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveDefaultOnDiskEntryLevel(hasEntryPoint != 0, true));
}

static bool
HnswShouldHaveValidInsertIndexValueFlag(bool hasValidIndexValue, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasValidIndexValue);
}

static bool
HnswShouldHaveValidInsertIndexValue(bool indexValueFormed, bool useRust)
{
	return HnswShouldHaveValidInsertIndexValueFlag(indexValueFormed, useRust);
}

static bool
HnswShouldSkipInvalidInsertValue(bool indexValueFormed, bool useRust)
{
	return !HnswShouldHaveValidInsertIndexValue(indexValueFormed, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_valid_insert_index_value);
Datum
vector_hnsw_should_have_valid_insert_index_value(PG_FUNCTION_ARGS)
{
	int32		indexValueFormed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidInsertIndexValue(indexValueFormed != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_valid_insert_index_value);
Datum
vector_rust_hnsw_should_have_valid_insert_index_value(PG_FUNCTION_ARGS)
{
	int32		indexValueFormed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidInsertIndexValue(indexValueFormed != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_valid_insert_index_value_flag);
Datum
vector_hnsw_should_have_valid_insert_index_value_flag(PG_FUNCTION_ARGS)
{
	int32		indexValueFormed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidInsertIndexValueFlag(indexValueFormed != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_valid_insert_index_value_flag);
Datum
vector_rust_hnsw_should_have_valid_insert_index_value_flag(PG_FUNCTION_ARGS)
{
	int32		indexValueFormed = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidInsertIndexValueFlag(indexValueFormed != 0, true));
}

static bool
HnswShouldHaveOnDiskValueMismatchFlag(bool valuesMismatch, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(valuesMismatch);
}

static bool
HnswShouldHaveOnDiskValueMismatch(bool valuesEqual, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_stop_duplicate_search_on_value_mismatch_kernel(valuesEqual);
}

static bool
HnswShouldStopOnDiskDuplicateSearchOnValueMismatch(bool valuesEqual, bool useRust)
{
	return HnswShouldHaveOnDiskValueMismatch(valuesEqual, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_value_mismatch);
Datum
vector_hnsw_should_have_ondisk_value_mismatch(PG_FUNCTION_ARGS)
{
	int32		valuesEqual = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskValueMismatch(valuesEqual != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_value_mismatch);
Datum
vector_rust_hnsw_should_have_ondisk_value_mismatch(PG_FUNCTION_ARGS)
{
	int32		valuesEqual = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskValueMismatch(valuesEqual != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_value_mismatch_flag);
Datum
vector_hnsw_should_have_ondisk_value_mismatch_flag(PG_FUNCTION_ARGS)
{
	int32		valuesMismatch = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskValueMismatchFlag(valuesMismatch != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_value_mismatch_flag);
Datum
vector_rust_hnsw_should_have_ondisk_value_mismatch_flag(PG_FUNCTION_ARGS)
{
	int32		valuesMismatch = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskValueMismatchFlag(valuesMismatch != 0, true));
}

static bool
HnswShouldReturnAfterOnDiskDuplicateInsert(bool duplicateInserted, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_return_after_duplicate_insert_kernel(duplicateInserted);
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
	(void) useRust;
	return vector_rust_hnsw_should_skip_update_graph_for_duplicate_kernel(duplicateFound);
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
	(void) useRust;
	return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasNewInsertPage);
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
HnswShouldHaveBoundaryDuplicateInsertSlotFlag(bool hasBoundarySlot, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasBoundarySlot);
}

static bool
HnswShouldHaveBoundaryDuplicateInsertSlot(int32 freeSlotIndex, int32 maxHeaptids, bool useRust)
{
	return HnswShouldHaveBoundaryDuplicateInsertSlotFlag(freeSlotIndex == 0 || freeSlotIndex == maxHeaptids, useRust);
}

static bool
HnswShouldRejectOnDiskDuplicateInsertSlot(bool hasBoundarySlot, bool useRust)
{
	return HnswShouldHaveBoundaryDuplicateInsertSlotFlag(hasBoundarySlot, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_ondisk_duplicate_insert_slot);
Datum
vector_hnsw_should_reject_ondisk_duplicate_insert_slot(PG_FUNCTION_ARGS)
{
	int32		freeSlotIndex = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectOnDiskDuplicateInsertSlot(HnswShouldHaveBoundaryDuplicateInsertSlot(freeSlotIndex, maxHeaptids, false), false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_ondisk_duplicate_insert_slot);
Datum
vector_rust_hnsw_should_reject_ondisk_duplicate_insert_slot(PG_FUNCTION_ARGS)
{
	int32		freeSlotIndex = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectOnDiskDuplicateInsertSlot(HnswShouldHaveBoundaryDuplicateInsertSlot(freeSlotIndex, maxHeaptids, true), true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_boundary_duplicate_insert_slot);
Datum
vector_hnsw_should_have_boundary_duplicate_insert_slot(PG_FUNCTION_ARGS)
{
	int32		freeSlotIndex = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveBoundaryDuplicateInsertSlot(freeSlotIndex, maxHeaptids, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_boundary_duplicate_insert_slot);
Datum
vector_rust_hnsw_should_have_boundary_duplicate_insert_slot(PG_FUNCTION_ARGS)
{
	int32		freeSlotIndex = PG_GETARG_INT32(0);
	int32		maxHeaptids = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveBoundaryDuplicateInsertSlot(freeSlotIndex, maxHeaptids, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_boundary_duplicate_insert_slot_flag);
Datum
vector_hnsw_should_have_boundary_duplicate_insert_slot_flag(PG_FUNCTION_ARGS)
{
	int32		hasBoundarySlot = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBoundaryDuplicateInsertSlotFlag(hasBoundarySlot != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_boundary_duplicate_insert_slot_flag);
Datum
vector_rust_hnsw_should_have_boundary_duplicate_insert_slot_flag(PG_FUNCTION_ARGS)
{
	int32		hasBoundarySlot = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBoundaryDuplicateInsertSlotFlag(hasBoundarySlot != 0, true));
}

static bool
HnswShouldHaveInvalidOnDiskHeapTidFlag(bool heapTidValid, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_skip_invalid_index_value_kernel(heapTidValid);
}

static bool
HnswShouldBreakOnInvalidOnDiskHeapTid(bool heapTidValid, bool useRust)
{
	return HnswShouldHaveInvalidOnDiskHeapTidFlag(heapTidValid, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_invalid_ondisk_heaptid);
Datum
vector_hnsw_should_have_invalid_ondisk_heaptid(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskHeapTidFlag(heapTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_invalid_ondisk_heaptid);
Datum
vector_rust_hnsw_should_have_invalid_ondisk_heaptid(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskHeapTidFlag(heapTidValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_invalid_ondisk_heaptid_flag);
Datum
vector_hnsw_should_have_invalid_ondisk_heaptid_flag(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskHeapTidFlag(heapTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_invalid_ondisk_heaptid_flag);
Datum
vector_rust_hnsw_should_have_invalid_ondisk_heaptid_flag(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskHeapTidFlag(heapTidValid != 0, true));
}

static bool
HnswShouldCommitOnDiskDuplicateWithBufferDirty(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
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
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
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
HnswShouldHaveNonBuildingOnDiskNeighborUpdate(bool building, bool useRust)
{
	(void) useRust;
	return !vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldAbortOnDiskNeighborUpdate(bool building, bool useRust)
{
	return HnswShouldHaveNonBuildingOnDiskNeighborUpdate(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_nonbuilding_ondisk_neighbor_update);
Datum
vector_hnsw_should_have_nonbuilding_ondisk_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonBuildingOnDiskNeighborUpdate(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_nonbuilding_ondisk_neighbor_update);
Datum
vector_rust_hnsw_should_have_nonbuilding_ondisk_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonBuildingOnDiskNeighborUpdate(building != 0, true));
}

static bool
HnswShouldHaveInsufficientOnDiskNeighborSpace(int64 freeSpace, int64 tupleSize, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_append_neighbor_page_kernel(freeSpace, tupleSize);
}

static bool
HnswShouldAppendOnDiskNeighborPage(int64 freeSpace, int64 tupleSize, bool useRust)
{
	return HnswShouldHaveInsufficientOnDiskNeighborSpace(freeSpace, tupleSize, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_insufficient_ondisk_neighbor_space);
Datum
vector_hnsw_should_have_insufficient_ondisk_neighbor_space(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		tupleSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldHaveInsufficientOnDiskNeighborSpace(freeSpace, tupleSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_insufficient_ondisk_neighbor_space);
Datum
vector_rust_hnsw_should_have_insufficient_ondisk_neighbor_space(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		tupleSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldHaveInsufficientOnDiskNeighborSpace(freeSpace, tupleSize, true));
}

static bool
HnswShouldExceedOnDiskElementMaxSizeFlag(bool exceedsMaxSize, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(exceedsMaxSize);
}

static bool
HnswShouldExceedOnDiskElementMaxSize(int64 combinedSize, int64 maxSize, bool useRust)
{
	return HnswShouldExceedOnDiskElementMaxSizeFlag(combinedSize > maxSize, useRust);
}

static bool
HnswShouldHaveOnDiskElementWithoutNextPage(bool hasNextPage, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasNextPage);
}

static bool
HnswShouldAppendOnDiskElementPage(int64 combinedSize, int64 maxSize, int64 freeSpace, int64 elementTupleSize, bool hasNextPage, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_append_ondisk_element_page_kernel(combinedSize,
																	 maxSize,
																	 freeSpace,
																	 elementTupleSize,
																	 hasNextPage);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_exceed_ondisk_element_max_size);
Datum
vector_hnsw_should_exceed_ondisk_element_max_size(PG_FUNCTION_ARGS)
{
	int64		combinedSize = PG_GETARG_INT64(0);
	int64		maxSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldExceedOnDiskElementMaxSize(combinedSize, maxSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_exceed_ondisk_element_max_size);
Datum
vector_rust_hnsw_should_exceed_ondisk_element_max_size(PG_FUNCTION_ARGS)
{
	int64		combinedSize = PG_GETARG_INT64(0);
	int64		maxSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldExceedOnDiskElementMaxSize(combinedSize, maxSize, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_exceed_ondisk_element_max_size_flag);
Datum
vector_hnsw_should_exceed_ondisk_element_max_size_flag(PG_FUNCTION_ARGS)
{
	int32		exceedsMaxSize = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldExceedOnDiskElementMaxSizeFlag(exceedsMaxSize != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_exceed_ondisk_element_max_size_flag);
Datum
vector_rust_hnsw_should_exceed_ondisk_element_max_size_flag(PG_FUNCTION_ARGS)
{
	int32		exceedsMaxSize = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldExceedOnDiskElementMaxSizeFlag(exceedsMaxSize != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_element_without_next_page);
Datum
vector_hnsw_should_have_ondisk_element_without_next_page(PG_FUNCTION_ARGS)
{
	int32		hasNextPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskElementWithoutNextPage(hasNextPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_element_without_next_page);
Datum
vector_rust_hnsw_should_have_ondisk_element_without_next_page(PG_FUNCTION_ARGS)
{
	int32		hasNextPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskElementWithoutNextPage(hasNextPage != 0, true));
}

static bool
HnswShouldHaveNonBuildingOnDiskElementMoveNext(bool building, bool useRust)
{
	(void) useRust;
	return !vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldAbortOnDiskElementMoveNext(bool building, bool useRust)
{
	return HnswShouldHaveNonBuildingOnDiskElementMoveNext(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_nonbuilding_ondisk_element_move_next);
Datum
vector_hnsw_should_have_nonbuilding_ondisk_element_move_next(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonBuildingOnDiskElementMoveNext(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_nonbuilding_ondisk_element_move_next);
Datum
vector_rust_hnsw_should_have_nonbuilding_ondisk_element_move_next(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonBuildingOnDiskElementMoveNext(building != 0, true));
}

static bool
HnswShouldCommitOnDiskAddElementWithBufferDirty(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
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
	(void) useRust;
	return vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel(sameBuffer);
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
HnswShouldHaveChangedOnDiskInsertPageFlag(bool pageChanged, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(pageChanged);
}

static bool
HnswShouldHaveChangedOnDiskInsertPage(BlockNumber newInsertPage, BlockNumber insertPage, bool useRust)
{
	return HnswShouldHaveChangedOnDiskInsertPageFlag(newInsertPage != insertPage, useRust);
}

static bool
HnswShouldUpdateAddElementInsertPage(bool hasNewInsertPage, bool pageChanged, bool useRust)
{
	bool		shouldUpdate = hasNewInsertPage && pageChanged;

	(void) useRust;
	return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(shouldUpdate);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_changed_ondisk_insert_page);
Datum
vector_hnsw_should_have_changed_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		newInsertPage = PG_GETARG_INT32(0);
	int32		insertPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveChangedOnDiskInsertPage((BlockNumber) newInsertPage, (BlockNumber) insertPage, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_changed_ondisk_insert_page);
Datum
vector_rust_hnsw_should_have_changed_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		newInsertPage = PG_GETARG_INT32(0);
	int32		insertPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveChangedOnDiskInsertPage((BlockNumber) newInsertPage, (BlockNumber) insertPage, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_changed_ondisk_insert_page_flag);
Datum
vector_hnsw_should_have_changed_ondisk_insert_page_flag(PG_FUNCTION_ARGS)
{
	int32		pageChanged = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveChangedOnDiskInsertPageFlag(pageChanged != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_changed_ondisk_insert_page_flag);
Datum
vector_rust_hnsw_should_have_changed_ondisk_insert_page_flag(PG_FUNCTION_ARGS)
{
	int32		pageChanged = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveChangedOnDiskInsertPageFlag(pageChanged != 0, true));
}

static bool
HnswShouldHaveNeighborPageAsInsertPage(bool hasNewInsertPage, bool useRust)
{
	(void) useRust;
	return !vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasNewInsertPage);
}

static bool
HnswShouldUseNeighborPageAsInsertPage(bool hasNewInsertPage, bool useRust)
{
	return HnswShouldHaveNeighborPageAsInsertPage(hasNewInsertPage, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_neighbor_page_as_insert_page);
Datum
vector_hnsw_should_have_neighbor_page_as_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasNewInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNeighborPageAsInsertPage(hasNewInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_neighbor_page_as_insert_page);
Datum
vector_rust_hnsw_should_have_neighbor_page_as_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasNewInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNeighborPageAsInsertPage(hasNewInsertPage != 0, true));
}

static bool
HnswShouldHaveNextNeighborOffset(bool sameBuffer, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(sameBuffer);
}

static bool
HnswShouldUseNextNeighborOffset(bool sameBuffer, bool useRust)
{
	return HnswShouldHaveNextNeighborOffset(sameBuffer, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_next_neighbor_offset);
Datum
vector_hnsw_should_have_next_neighbor_offset(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNextNeighborOffset(sameBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_next_neighbor_offset);
Datum
vector_rust_hnsw_should_have_next_neighbor_offset(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNextNeighborOffset(sameBuffer != 0, true));
}

static bool
HnswShouldHaveFreeOnDiskOffsetFlag(bool freeOffsetValid, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(freeOffsetValid);
}

static bool
HnswShouldHaveValidOnDiskOffsetNumberFlag(bool offsetNumberValid, bool useRust)
{
	return HnswShouldHaveFreeOnDiskOffsetFlag(offsetNumberValid, useRust);
}

static bool
HnswShouldHaveValidOnDiskOffsetNumber(OffsetNumber freeOffno, bool useRust)
{
	return HnswShouldHaveValidOnDiskOffsetNumberFlag(OffsetNumberIsValid(freeOffno), useRust);
}

static bool
HnswShouldHaveFreeOnDiskOffset(OffsetNumber freeOffno, bool useRust)
{
	return HnswShouldHaveValidOnDiskOffsetNumber(freeOffno, useRust);
}

static bool
HnswShouldHaveFreeOnDiskOffsets(bool freeOffsetValid, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(freeOffsetValid);
}

static bool
HnswShouldUseFreeOnDiskOffsets(bool freeOffsetValid, bool useRust)
{
	return HnswShouldHaveFreeOnDiskOffsets(freeOffsetValid, useRust);
}

static bool
HnswShouldProcessFreeOffsetResult(bool freeOffsetResult, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(freeOffsetResult);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_free_ondisk_offsets);
Datum
vector_hnsw_should_use_free_ondisk_offsets(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseFreeOnDiskOffsets(freeOffsetValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_free_ondisk_offsets);
Datum
vector_hnsw_should_have_free_ondisk_offsets(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveFreeOnDiskOffsets(freeOffsetValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_free_ondisk_offsets);
Datum
vector_rust_hnsw_should_have_free_ondisk_offsets(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveFreeOnDiskOffsets(freeOffsetValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_free_ondisk_offset);
Datum
vector_hnsw_should_have_free_ondisk_offset(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveFreeOnDiskOffsetFlag(freeOffsetValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_free_ondisk_offset);
Datum
vector_rust_hnsw_should_have_free_ondisk_offset(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveFreeOnDiskOffsetFlag(freeOffsetValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_free_ondisk_offset_flag);
Datum
vector_hnsw_should_have_free_ondisk_offset_flag(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveFreeOnDiskOffsetFlag(freeOffsetValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_free_ondisk_offset_flag);
Datum
vector_rust_hnsw_should_have_free_ondisk_offset_flag(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveFreeOnDiskOffsetFlag(freeOffsetValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_valid_ondisk_offset_number);
Datum
vector_hnsw_should_have_valid_ondisk_offset_number(PG_FUNCTION_ARGS)
{
	int32		freeOffno = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidOnDiskOffsetNumber((OffsetNumber) freeOffno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_valid_ondisk_offset_number);
Datum
vector_rust_hnsw_should_have_valid_ondisk_offset_number(PG_FUNCTION_ARGS)
{
	int32		freeOffno = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidOnDiskOffsetNumber((OffsetNumber) freeOffno, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_valid_ondisk_offset_number_flag);
Datum
vector_hnsw_should_have_valid_ondisk_offset_number_flag(PG_FUNCTION_ARGS)
{
	int32		offsetNumberValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidOnDiskOffsetNumberFlag(offsetNumberValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_valid_ondisk_offset_number_flag);
Datum
vector_rust_hnsw_should_have_valid_ondisk_offset_number_flag(PG_FUNCTION_ARGS)
{
	int32		offsetNumberValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidOnDiskOffsetNumberFlag(offsetNumberValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_free_ondisk_offsets);
Datum
vector_rust_hnsw_should_use_free_ondisk_offsets(PG_FUNCTION_ARGS)
{
	int32		freeOffsetValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseFreeOnDiskOffsets(freeOffsetValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_process_free_offset_result);
Datum
vector_hnsw_should_process_free_offset_result(PG_FUNCTION_ARGS)
{
	int32		freeOffsetResult = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessFreeOffsetResult(freeOffsetResult != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_process_free_offset_result);
Datum
vector_rust_hnsw_should_process_free_offset_result(PG_FUNCTION_ARGS)
{
	int32		freeOffsetResult = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessFreeOffsetResult(freeOffsetResult != 0, true));
}

static bool
HnswShouldHaveOnDiskSpaceForCombinedTuple(int64 freeSpace, int64 combinedSize, bool useRust)
{
	(void) useRust;
	return !vector_rust_hnsw_should_append_neighbor_page_kernel(freeSpace, combinedSize);
}

static bool
HnswShouldFitOnDiskCombinedTuple(int64 freeSpace, int64 combinedSize, bool useRust)
{
	return HnswShouldHaveOnDiskSpaceForCombinedTuple(freeSpace, combinedSize, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_space_for_combined_tuple);
Datum
vector_hnsw_should_have_ondisk_space_for_combined_tuple(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		combinedSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskSpaceForCombinedTuple(freeSpace, combinedSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_space_for_combined_tuple);
Datum
vector_rust_hnsw_should_have_ondisk_space_for_combined_tuple(PG_FUNCTION_ARGS)
{
	int64		freeSpace = PG_GETARG_INT64(0);
	int64		combinedSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskSpaceForCombinedTuple(freeSpace, combinedSize, true));
}

static bool
HnswShouldHaveBuildPathForOnDiskAddElement(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldUseBuildPathForOnDiskAddElement(bool building, bool useRust)
{
	return HnswShouldHaveBuildPathForOnDiskAddElement(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_build_path_for_ondisk_add_element);
Datum
vector_hnsw_should_have_build_path_for_ondisk_add_element(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForOnDiskAddElement(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_build_path_for_ondisk_add_element);
Datum
vector_rust_hnsw_should_have_build_path_for_ondisk_add_element(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForOnDiskAddElement(building != 0, true));
}

static bool
HnswShouldCommitOnDiskPageAppendWithBufferDirty(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
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
HnswShouldHaveBuildPathForAppendedOnDiskBuffer(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldUseBuildPathForAppendedOnDiskBuffer(bool building, bool useRust)
{
	return HnswShouldHaveBuildPathForAppendedOnDiskBuffer(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_build_path_for_appended_ondisk_buffer);
Datum
vector_hnsw_should_have_build_path_for_appended_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForAppendedOnDiskBuffer(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_build_path_for_appended_ondisk_buffer);
Datum
vector_rust_hnsw_should_have_build_path_for_appended_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForAppendedOnDiskBuffer(building != 0, true));
}

static bool
HnswShouldHaveBuildPathForReusedOnDiskBuffer(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldUseBuildPathForReusedOnDiskBuffer(bool building, bool useRust)
{
	return HnswShouldHaveBuildPathForReusedOnDiskBuffer(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_build_path_for_reused_ondisk_buffer);
Datum
vector_hnsw_should_have_build_path_for_reused_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForReusedOnDiskBuffer(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_build_path_for_reused_ondisk_buffer);
Datum
vector_rust_hnsw_should_have_build_path_for_reused_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForReusedOnDiskBuffer(building != 0, true));
}

static bool
HnswShouldHaveBuildPathForOnDiskAppendPage(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldUseBuildPathForOnDiskAppendPage(bool building, bool useRust)
{
	return HnswShouldHaveBuildPathForOnDiskAppendPage(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_build_path_for_ondisk_append_page);
Datum
vector_hnsw_should_have_build_path_for_ondisk_append_page(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForOnDiskAppendPage(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_build_path_for_ondisk_append_page);
Datum
vector_rust_hnsw_should_have_build_path_for_ondisk_append_page(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForOnDiskAppendPage(building != 0, true));
}

static bool
HnswShouldHaveBuildPathForOnDiskNeighborUpdate(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldUseBuildPathForOnDiskNeighborUpdate(bool building, bool useRust)
{
	return HnswShouldHaveBuildPathForOnDiskNeighborUpdate(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_build_path_for_ondisk_neighbor_update);
Datum
vector_hnsw_should_have_build_path_for_ondisk_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForOnDiskNeighborUpdate(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_build_path_for_ondisk_neighbor_update);
Datum
vector_rust_hnsw_should_have_build_path_for_ondisk_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForOnDiskNeighborUpdate(building != 0, true));
}

static bool
HnswShouldHaveBuildPathForOnDiskDuplicatePage(bool building, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldUseBuildPathForOnDiskDuplicatePage(bool building, bool useRust)
{
	return HnswShouldHaveBuildPathForOnDiskDuplicatePage(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_build_path_for_ondisk_duplicate_page);
Datum
vector_hnsw_should_have_build_path_for_ondisk_duplicate_page(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForOnDiskDuplicatePage(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_build_path_for_ondisk_duplicate_page);
Datum
vector_rust_hnsw_should_have_build_path_for_ondisk_duplicate_page(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveBuildPathForOnDiskDuplicatePage(building != 0, true));
}

static bool
HnswShouldHaveNonBuildingOnDiskDuplicateSlotReject(bool building, bool useRust)
{
	(void) useRust;
	return !vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel(building);
}

static bool
HnswShouldAbortOnDiskDuplicateSlotReject(bool building, bool useRust)
{
	return HnswShouldHaveNonBuildingOnDiskDuplicateSlotReject(building, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject);
Datum
vector_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonBuildingOnDiskDuplicateSlotReject(building != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject);
Datum
vector_rust_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject(PG_FUNCTION_ARGS)
{
	int32		building = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonBuildingOnDiskDuplicateSlotReject(building != 0, true));
}

static bool
HnswShouldHaveOnDiskItemPointerFlag(bool itemPointerValid, bool useRust)
{
	(void) useRust;
	return vector_rust_hnsw_should_update_progress_after_insert_kernel(itemPointerValid);
}

static bool
HnswShouldHaveOnDiskItemPointer(ItemPointer itemPointer, bool useRust)
{
	return HnswShouldHaveOnDiskItemPointerFlag(ItemPointerIsValid(itemPointer), useRust);
}

static bool
HnswShouldHaveOnDiskHeapTidFlag(bool heapTidValid, bool useRust)
{
	return HnswShouldHaveOnDiskItemPointerFlag(heapTidValid, useRust);
}

static bool
HnswShouldHaveOnDiskHeapTid(ItemPointer heaptid, bool useRust)
{
	return HnswShouldHaveOnDiskItemPointer(heaptid, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_heaptid);
Datum
vector_hnsw_should_have_ondisk_heaptid(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskHeapTidFlag(heapTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_heaptid);
Datum
vector_rust_hnsw_should_have_ondisk_heaptid(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskHeapTidFlag(heapTidValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_heaptid_flag);
Datum
vector_hnsw_should_have_ondisk_heaptid_flag(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskHeapTidFlag(heapTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_heaptid_flag);
Datum
vector_rust_hnsw_should_have_ondisk_heaptid_flag(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskHeapTidFlag(heapTidValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_itempointer);
Datum
vector_hnsw_should_have_ondisk_itempointer(PG_FUNCTION_ARGS)
{
	int32		itemPointerValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskItemPointerFlag(itemPointerValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_itempointer);
Datum
vector_rust_hnsw_should_have_ondisk_itempointer(PG_FUNCTION_ARGS)
{
	int32		itemPointerValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskItemPointerFlag(itemPointerValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_itempointer_flag);
Datum
vector_hnsw_should_have_ondisk_itempointer_flag(PG_FUNCTION_ARGS)
{
	int32		itemPointerValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskItemPointerFlag(itemPointerValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_itempointer_flag);
Datum
vector_rust_hnsw_should_have_ondisk_itempointer_flag(PG_FUNCTION_ARGS)
{
	int32		itemPointerValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskItemPointerFlag(itemPointerValid != 0, true));
}

static bool
HnswShouldHaveOnDiskNeighborTidFlag(bool neighborTidValid, bool useRust)
{
	return HnswShouldHaveOnDiskItemPointerFlag(neighborTidValid, useRust);
}

static bool
HnswShouldHaveOnDiskNeighborTid(ItemPointer indextid, bool useRust)
{
	return HnswShouldHaveOnDiskItemPointer(indextid, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_neighbor_tid);
Datum
vector_hnsw_should_have_ondisk_neighbor_tid(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskNeighborTidFlag(neighborTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_neighbor_tid);
Datum
vector_rust_hnsw_should_have_ondisk_neighbor_tid(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskNeighborTidFlag(neighborTidValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_neighbor_tid_flag);
Datum
vector_hnsw_should_have_ondisk_neighbor_tid_flag(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskNeighborTidFlag(neighborTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_neighbor_tid_flag);
Datum
vector_rust_hnsw_should_have_ondisk_neighbor_tid_flag(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskNeighborTidFlag(neighborTidValid != 0, true));
}

static bool
HnswShouldHaveInvalidOnDiskNeighborSlotFlag(bool slotTidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(slotTidValid);

	return !slotTidValid;
}

static bool
HnswShouldHaveFreeOnDiskNeighborSlot(bool slotTidValid, bool useRust)
{
	return HnswShouldHaveInvalidOnDiskNeighborSlotFlag(slotTidValid, useRust);
}

static bool
HnswShouldUseFreeOnDiskNeighborSlot(bool slotTidValid, bool useRust)
{
	return HnswShouldHaveFreeOnDiskNeighborSlot(slotTidValid, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_free_ondisk_neighbor_slot);
Datum
vector_hnsw_should_have_free_ondisk_neighbor_slot(PG_FUNCTION_ARGS)
{
	int32		slotTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveFreeOnDiskNeighborSlot(slotTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_free_ondisk_neighbor_slot);
Datum
vector_rust_hnsw_should_have_free_ondisk_neighbor_slot(PG_FUNCTION_ARGS)
{
	int32		slotTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveFreeOnDiskNeighborSlot(slotTidValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_invalid_ondisk_neighbor_slot);
Datum
vector_hnsw_should_have_invalid_ondisk_neighbor_slot(PG_FUNCTION_ARGS)
{
	int32		slotTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskNeighborSlotFlag(slotTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_invalid_ondisk_neighbor_slot);
Datum
vector_rust_hnsw_should_have_invalid_ondisk_neighbor_slot(PG_FUNCTION_ARGS)
{
	int32		slotTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskNeighborSlotFlag(slotTidValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_invalid_ondisk_neighbor_slot_flag);
Datum
vector_hnsw_should_have_invalid_ondisk_neighbor_slot_flag(PG_FUNCTION_ARGS)
{
	int32		slotTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskNeighborSlotFlag(slotTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_invalid_ondisk_neighbor_slot_flag);
Datum
vector_rust_hnsw_should_have_invalid_ondisk_neighbor_slot_flag(PG_FUNCTION_ARGS)
{
	int32		slotTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskNeighborSlotFlag(slotTidValid != 0, true));
}

static bool
HnswShouldHaveInvalidOnDiskNeighborTidFlag(bool neighborTidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(neighborTidValid);

	return !neighborTidValid;
}

static bool
HnswShouldStopOnInvalidOnDiskNeighborTid(bool neighborTidValid, bool useRust)
{
	return HnswShouldHaveInvalidOnDiskNeighborTidFlag(neighborTidValid, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_invalid_ondisk_neighbor_tid);
Datum
vector_hnsw_should_have_invalid_ondisk_neighbor_tid(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskNeighborTidFlag(neighborTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_invalid_ondisk_neighbor_tid);
Datum
vector_rust_hnsw_should_have_invalid_ondisk_neighbor_tid(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskNeighborTidFlag(neighborTidValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_invalid_ondisk_neighbor_tid_flag);
Datum
vector_hnsw_should_have_invalid_ondisk_neighbor_tid_flag(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskNeighborTidFlag(neighborTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_invalid_ondisk_neighbor_tid_flag);
Datum
vector_rust_hnsw_should_have_invalid_ondisk_neighbor_tid_flag(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveInvalidOnDiskNeighborTidFlag(neighborTidValid != 0, true));
}

static bool
HnswShouldHaveMatchingNeighborBlockFlag(bool hasMatchingBlock, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasMatchingBlock);

	return hasMatchingBlock;
}

static bool
HnswShouldHaveMatchingNeighborBlock(int32 indextidBlkno, int32 elementBlkno, bool useRust)
{
	return HnswShouldHaveMatchingNeighborBlockFlag(indextidBlkno == elementBlkno, useRust);
}

static bool
HnswShouldHaveMatchingNeighborOffsetFlag(bool hasMatchingOffset, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasMatchingOffset);

	return hasMatchingOffset;
}

static bool
HnswShouldHaveMatchingNeighborOffset(int32 indextidOffno, int32 elementOffno, bool useRust)
{
	return HnswShouldHaveMatchingNeighborOffsetFlag(indextidOffno == elementOffno, useRust);
}

static bool
HnswShouldMatchNeighborConnection(int32 indextidBlkno, int32 indextidOffno, int32 elementBlkno, int32 elementOffno, bool useRust)
{
	return HnswShouldHaveMatchingNeighborBlock(indextidBlkno, elementBlkno, useRust) &&
		HnswShouldHaveMatchingNeighborOffset(indextidOffno, elementOffno, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_match_neighbor_connection);
Datum
vector_hnsw_should_match_neighbor_connection(PG_FUNCTION_ARGS)
{
	int32		indextidBlkno = PG_GETARG_INT32(0);
	int32		indextidOffno = PG_GETARG_INT32(1);
	int32		elementBlkno = PG_GETARG_INT32(2);
	int32		elementOffno = PG_GETARG_INT32(3);

	PG_RETURN_BOOL(HnswShouldMatchNeighborConnection(indextidBlkno, indextidOffno, elementBlkno, elementOffno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_match_neighbor_connection);
Datum
vector_rust_hnsw_should_match_neighbor_connection(PG_FUNCTION_ARGS)
{
	int32		indextidBlkno = PG_GETARG_INT32(0);
	int32		indextidOffno = PG_GETARG_INT32(1);
	int32		elementBlkno = PG_GETARG_INT32(2);
	int32		elementOffno = PG_GETARG_INT32(3);

	PG_RETURN_BOOL(HnswShouldMatchNeighborConnection(indextidBlkno, indextidOffno, elementBlkno, elementOffno, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_matching_neighbor_block);
Datum
vector_hnsw_should_have_matching_neighbor_block(PG_FUNCTION_ARGS)
{
	int32		indextidBlkno = PG_GETARG_INT32(0);
	int32		elementBlkno = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborBlock(indextidBlkno, elementBlkno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_matching_neighbor_block);
Datum
vector_rust_hnsw_should_have_matching_neighbor_block(PG_FUNCTION_ARGS)
{
	int32		indextidBlkno = PG_GETARG_INT32(0);
	int32		elementBlkno = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborBlock(indextidBlkno, elementBlkno, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_matching_neighbor_block_flag);
Datum
vector_hnsw_should_have_matching_neighbor_block_flag(PG_FUNCTION_ARGS)
{
	int32		hasMatchingBlock = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborBlockFlag(hasMatchingBlock != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_matching_neighbor_block_flag);
Datum
vector_rust_hnsw_should_have_matching_neighbor_block_flag(PG_FUNCTION_ARGS)
{
	int32		hasMatchingBlock = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborBlockFlag(hasMatchingBlock != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_matching_neighbor_offset);
Datum
vector_hnsw_should_have_matching_neighbor_offset(PG_FUNCTION_ARGS)
{
	int32		indextidOffno = PG_GETARG_INT32(0);
	int32		elementOffno = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborOffset(indextidOffno, elementOffno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_matching_neighbor_offset);
Datum
vector_rust_hnsw_should_have_matching_neighbor_offset(PG_FUNCTION_ARGS)
{
	int32		indextidOffno = PG_GETARG_INT32(0);
	int32		elementOffno = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborOffset(indextidOffno, elementOffno, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_matching_neighbor_offset_flag);
Datum
vector_hnsw_should_have_matching_neighbor_offset_flag(PG_FUNCTION_ARGS)
{
	int32		hasMatchingOffset = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborOffsetFlag(hasMatchingOffset != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_matching_neighbor_offset_flag);
Datum
vector_rust_hnsw_should_have_matching_neighbor_offset_flag(PG_FUNCTION_ARGS)
{
	int32		hasMatchingOffset = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborOffsetFlag(hasMatchingOffset != 0, true));
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
HnswShouldHaveOnDiskBlockFlag(bool blockValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(blockValid);

	return blockValid;
}

static bool
HnswShouldHaveValidOnDiskBlockNumberFlag(bool blockNumberValid, bool useRust)
{
	return HnswShouldHaveOnDiskBlockFlag(blockNumberValid, useRust);
}

static bool
HnswShouldHaveValidOnDiskBlockNumber(BlockNumber blkno, bool useRust)
{
	return HnswShouldHaveValidOnDiskBlockNumberFlag(BlockNumberIsValid(blkno), useRust);
}

static bool
HnswShouldHaveOnDiskBlockNumber(BlockNumber blkno, bool useRust)
{
	return HnswShouldHaveValidOnDiskBlockNumber(blkno, useRust);
}

static bool
HnswShouldHaveOnDiskInsertPageFlag(bool hasInsertPage, bool useRust)
{
	return HnswShouldHaveOnDiskBlockFlag(hasInsertPage, useRust);
}

static bool
HnswShouldHaveOnDiskInsertPage(BlockNumber insertPage, bool useRust)
{
	return HnswShouldHaveOnDiskBlockNumber(insertPage, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_insert_page);
Datum
vector_hnsw_should_have_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskInsertPageFlag(hasInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_insert_page);
Datum
vector_rust_hnsw_should_have_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskInsertPageFlag(hasInsertPage != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_insert_page_flag);
Datum
vector_hnsw_should_have_ondisk_insert_page_flag(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskInsertPageFlag(hasInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_insert_page_flag);
Datum
vector_rust_hnsw_should_have_ondisk_insert_page_flag(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskInsertPageFlag(hasInsertPage != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_block_number);
Datum
vector_hnsw_should_have_ondisk_block_number(PG_FUNCTION_ARGS)
{
	int32		blkno = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskBlockNumber((BlockNumber) blkno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_block_number);
Datum
vector_rust_hnsw_should_have_ondisk_block_number(PG_FUNCTION_ARGS)
{
	int32		blkno = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskBlockNumber((BlockNumber) blkno, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_valid_ondisk_block_number);
Datum
vector_hnsw_should_have_valid_ondisk_block_number(PG_FUNCTION_ARGS)
{
	int32		blkno = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidOnDiskBlockNumber((BlockNumber) blkno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_valid_ondisk_block_number);
Datum
vector_rust_hnsw_should_have_valid_ondisk_block_number(PG_FUNCTION_ARGS)
{
	int32		blkno = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidOnDiskBlockNumber((BlockNumber) blkno, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_valid_ondisk_block_number_flag);
Datum
vector_hnsw_should_have_valid_ondisk_block_number_flag(PG_FUNCTION_ARGS)
{
	int32		blockNumberValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidOnDiskBlockNumberFlag(blockNumberValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_valid_ondisk_block_number_flag);
Datum
vector_rust_hnsw_should_have_valid_ondisk_block_number_flag(PG_FUNCTION_ARGS)
{
	int32		blockNumberValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveValidOnDiskBlockNumberFlag(blockNumberValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_block_flag);
Datum
vector_hnsw_should_have_ondisk_block_flag(PG_FUNCTION_ARGS)
{
	int32		blockValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskBlockFlag(blockValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_block_flag);
Datum
vector_rust_hnsw_should_have_ondisk_block_flag(PG_FUNCTION_ARGS)
{
	int32		blockValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskBlockFlag(blockValid != 0, true));
}

static bool
HnswShouldSetInsertPageWhenMissing(bool hasInsertPage, bool useRust)
{
	return HnswShouldHaveMissingOnDiskInsertPage(hasInsertPage, useRust);
}

static bool
HnswShouldHaveMissingOnDiskInsertPage(bool hasInsertPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasInsertPage);

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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_missing_ondisk_insert_page);
Datum
vector_hnsw_should_have_missing_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMissingOnDiskInsertPage(hasInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_missing_ondisk_insert_page);
Datum
vector_rust_hnsw_should_have_missing_ondisk_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMissingOnDiskInsertPage(hasInsertPage != 0, true));
}

static bool
HnswShouldReuseElementBufferForNeighborPage(bool samePage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(samePage);

	return samePage;
}

static bool
HnswShouldHaveMatchingNeighborPageFlag(bool hasMatchingPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasMatchingPage);

	return hasMatchingPage;
}

static bool
HnswShouldHaveMatchingNeighborPage(int32 neighborPage, int32 elementPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_match_neighbor_connection_kernel(neighborPage, 0, elementPage, 0);

	return HnswShouldHaveMatchingNeighborPageFlag(neighborPage == elementPage, false);
}

static bool
HnswShouldMatchNeighborPages(int32 neighborPage, int32 elementPage, bool useRust)
{
	return HnswShouldHaveMatchingNeighborPage(neighborPage, elementPage, useRust);
}

static bool
HnswShouldHaveMatchingOnDiskBufferFlag(bool hasMatchingBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasMatchingBuffer);

	return hasMatchingBuffer;
}

static bool
HnswShouldHaveMatchingOnDiskBuffer(int32 leftBuffer, int32 rightBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_match_neighbor_connection_kernel(leftBuffer, 0, rightBuffer, 0);

	return HnswShouldHaveMatchingOnDiskBufferFlag(leftBuffer == rightBuffer, false);
}

static bool
HnswShouldMatchOnDiskBuffers(int32 leftBuffer, int32 rightBuffer, bool useRust)
{
	return HnswShouldHaveMatchingOnDiskBuffer(leftBuffer, rightBuffer, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_match_neighbor_pages);
Datum
vector_hnsw_should_match_neighbor_pages(PG_FUNCTION_ARGS)
{
	int32		neighborPage = PG_GETARG_INT32(0);
	int32		elementPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldMatchNeighborPages(neighborPage, elementPage, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_match_neighbor_pages);
Datum
vector_rust_hnsw_should_match_neighbor_pages(PG_FUNCTION_ARGS)
{
	int32		neighborPage = PG_GETARG_INT32(0);
	int32		elementPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldMatchNeighborPages(neighborPage, elementPage, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_matching_neighbor_page);
Datum
vector_hnsw_should_have_matching_neighbor_page(PG_FUNCTION_ARGS)
{
	int32		neighborPage = PG_GETARG_INT32(0);
	int32		elementPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborPage(neighborPage, elementPage, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_matching_neighbor_page);
Datum
vector_rust_hnsw_should_have_matching_neighbor_page(PG_FUNCTION_ARGS)
{
	int32		neighborPage = PG_GETARG_INT32(0);
	int32		elementPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborPage(neighborPage, elementPage, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_matching_neighbor_page_flag);
Datum
vector_hnsw_should_have_matching_neighbor_page_flag(PG_FUNCTION_ARGS)
{
	int32		hasMatchingPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborPageFlag(hasMatchingPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_matching_neighbor_page_flag);
Datum
vector_rust_hnsw_should_have_matching_neighbor_page_flag(PG_FUNCTION_ARGS)
{
	int32		hasMatchingPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMatchingNeighborPageFlag(hasMatchingPage != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_match_ondisk_buffers);
Datum
vector_hnsw_should_match_ondisk_buffers(PG_FUNCTION_ARGS)
{
	int32		leftBuffer = PG_GETARG_INT32(0);
	int32		rightBuffer = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldMatchOnDiskBuffers(leftBuffer, rightBuffer, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_match_ondisk_buffers);
Datum
vector_rust_hnsw_should_match_ondisk_buffers(PG_FUNCTION_ARGS)
{
	int32		leftBuffer = PG_GETARG_INT32(0);
	int32		rightBuffer = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldMatchOnDiskBuffers(leftBuffer, rightBuffer, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_matching_ondisk_buffer);
Datum
vector_hnsw_should_have_matching_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		leftBuffer = PG_GETARG_INT32(0);
	int32		rightBuffer = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveMatchingOnDiskBuffer(leftBuffer, rightBuffer, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_matching_ondisk_buffer);
Datum
vector_rust_hnsw_should_have_matching_ondisk_buffer(PG_FUNCTION_ARGS)
{
	int32		leftBuffer = PG_GETARG_INT32(0);
	int32		rightBuffer = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveMatchingOnDiskBuffer(leftBuffer, rightBuffer, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_matching_ondisk_buffer_flag);
Datum
vector_hnsw_should_have_matching_ondisk_buffer_flag(PG_FUNCTION_ARGS)
{
	int32		hasMatchingBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMatchingOnDiskBufferFlag(hasMatchingBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_matching_ondisk_buffer_flag);
Datum
vector_rust_hnsw_should_have_matching_ondisk_buffer_flag(PG_FUNCTION_ARGS)
{
	int32		hasMatchingBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveMatchingOnDiskBufferFlag(hasMatchingBuffer != 0, true));
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
HnswShouldHaveDistinctNeighborPageSpace(bool samePage, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_update_ondisk_insert_page_kernel(samePage);

	return !samePage;
}

static bool
HnswShouldUseDistinctNeighborPageSpace(bool samePage, bool useRust)
{
	return HnswShouldHaveDistinctNeighborPageSpace(samePage, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_distinct_neighbor_page_space);
Datum
vector_hnsw_should_have_distinct_neighbor_page_space(PG_FUNCTION_ARGS)
{
	int32		samePage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveDistinctNeighborPageSpace(samePage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_distinct_neighbor_page_space);
Datum
vector_rust_hnsw_should_have_distinct_neighbor_page_space(PG_FUNCTION_ARGS)
{
	int32		samePage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveDistinctNeighborPageSpace(samePage != 0, true));
}

static bool
HnswShouldHavePageSpaceForTuple(int64 pageFree, int64 tupleSize, bool useRust)
{
	if (useRust)
		return !vector_rust_hnsw_should_append_neighbor_page_kernel(pageFree, tupleSize);

	return pageFree >= tupleSize;
}

static bool
HnswShouldReuseDeletedTupleSpace(int64 pageFree, int64 neighborPageFree, int64 elementTupleSize, int64 neighborTupleSize, bool useRust)
{
	return HnswShouldHavePageSpaceForTuple(pageFree, elementTupleSize, useRust) &&
		HnswShouldHavePageSpaceForTuple(neighborPageFree, neighborTupleSize, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_page_space_for_tuple);
Datum
vector_hnsw_should_have_page_space_for_tuple(PG_FUNCTION_ARGS)
{
	int64		pageFree = PG_GETARG_INT64(0);
	int64		tupleSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldHavePageSpaceForTuple(pageFree, tupleSize, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_page_space_for_tuple);
Datum
vector_rust_hnsw_should_have_page_space_for_tuple(PG_FUNCTION_ARGS)
{
	int64		pageFree = PG_GETARG_INT64(0);
	int64		tupleSize = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldHavePageSpaceForTuple(pageFree, tupleSize, true));
}

static bool
HnswShouldBorrowSamePageNeighborSpace(int64 pageFree, int64 elementTupleSize, bool samePage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(samePage) &&
			HnswShouldHavePageSpaceForTuple(pageFree, elementTupleSize, true);

	return samePage && HnswShouldHavePageSpaceForTuple(pageFree, elementTupleSize, false);
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
HnswShouldReturnEmptyWithoutNeighborTids(bool neighborTidsLoaded, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(neighborTidsLoaded);

	return !neighborTidsLoaded;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_empty_without_neighbor_tids);
Datum
vector_hnsw_should_return_empty_without_neighbor_tids(PG_FUNCTION_ARGS)
{
	int32		neighborTidsLoaded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnEmptyWithoutNeighborTids(neighborTidsLoaded != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_empty_without_neighbor_tids);
Datum
vector_rust_hnsw_should_return_empty_without_neighbor_tids(PG_FUNCTION_ARGS)
{
	int32		neighborTidsLoaded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnEmptyWithoutNeighborTids(neighborTidsLoaded != 0, true));
}

static bool
HnswShouldHaveEmptyInsertHeapTidsFlag(bool hasEmptyHeapTids, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasEmptyHeapTids);

	return hasEmptyHeapTids;
}

static bool
HnswShouldHaveEmptyInsertHeapTids(int32 heaptidsLength, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_advance_on_exhausted_heaptids_kernel(heaptidsLength);

	return HnswShouldHaveEmptyInsertHeapTidsFlag(heaptidsLength == 0, false);
}

static bool
HnswShouldPruneDeletedInsertElement(int32 heaptidsLength, bool useRust)
{
	return HnswShouldHaveEmptyInsertHeapTids(heaptidsLength, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_prune_deleted_insert_element);
Datum
vector_hnsw_should_prune_deleted_insert_element(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldPruneDeletedInsertElement(heaptidsLength, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_prune_deleted_insert_element);
Datum
vector_rust_hnsw_should_prune_deleted_insert_element(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldPruneDeletedInsertElement(heaptidsLength, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_empty_insert_heaptids);
Datum
vector_hnsw_should_have_empty_insert_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveEmptyInsertHeapTids(heaptidsLength, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_empty_insert_heaptids);
Datum
vector_rust_hnsw_should_have_empty_insert_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveEmptyInsertHeapTids(heaptidsLength, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_empty_insert_heaptids_flag);
Datum
vector_hnsw_should_have_empty_insert_heaptids_flag(PG_FUNCTION_ARGS)
{
	int32		hasEmptyHeapTids = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveEmptyInsertHeapTidsFlag(hasEmptyHeapTids != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_empty_insert_heaptids_flag);
Datum
vector_rust_hnsw_should_have_empty_insert_heaptids_flag(PG_FUNCTION_ARGS)
{
	int32		hasEmptyHeapTids = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveEmptyInsertHeapTidsFlag(hasEmptyHeapTids != 0, true));
}

static bool
HnswShouldHaveNeighborCountBeforeLayerM(int32 neighborCount, int32 layerM, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_append_neighbor_page_kernel((int64) neighborCount, (int64) layerM);

	return neighborCount < layerM;
}

static bool
HnswShouldProbeForFreeNeighborSlot(int32 neighborCount, int32 layerM, bool useRust)
{
	return HnswShouldHaveNeighborCountBeforeLayerM(neighborCount, layerM, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_probe_for_free_neighbor_slot);
Datum
vector_hnsw_should_probe_for_free_neighbor_slot(PG_FUNCTION_ARGS)
{
	int32		neighborCount = PG_GETARG_INT32(0);
	int32		layerM = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldProbeForFreeNeighborSlot(neighborCount, layerM, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_probe_for_free_neighbor_slot);
Datum
vector_rust_hnsw_should_probe_for_free_neighbor_slot(PG_FUNCTION_ARGS)
{
	int32		neighborCount = PG_GETARG_INT32(0);
	int32		layerM = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldProbeForFreeNeighborSlot(neighborCount, layerM, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_neighbor_count_before_layer_m);
Datum
vector_hnsw_should_have_neighbor_count_before_layer_m(PG_FUNCTION_ARGS)
{
	int32		neighborCount = PG_GETARG_INT32(0);
	int32		layerM = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveNeighborCountBeforeLayerM(neighborCount, layerM, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_neighbor_count_before_layer_m);
Datum
vector_rust_hnsw_should_have_neighbor_count_before_layer_m(PG_FUNCTION_ARGS)
{
	int32		neighborCount = PG_GETARG_INT32(0);
	int32		layerM = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveNeighborCountBeforeLayerM(neighborCount, layerM, true));
}

static bool
HnswShouldHaveExistingNeighborCheckFlag(bool shouldCheckExisting, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(shouldCheckExisting);

	return shouldCheckExisting;
}

static bool
HnswShouldHaveExistingNeighborCheck(bool checkExisting, bool useRust)
{
	return HnswShouldHaveExistingNeighborCheckFlag(checkExisting, useRust);
}

static bool
HnswShouldHaveExistingNeighborConnectionFlag(bool hasConnection, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_update_graph_for_duplicate_kernel(hasConnection);

	return hasConnection;
}

static bool
HnswShouldHaveExistingNeighborConnection(bool connectionExists, bool useRust)
{
	return HnswShouldHaveExistingNeighborConnectionFlag(connectionExists, useRust);
}

static bool
HnswShouldSkipExistingNeighborUpdate(bool checkExisting, bool connectionExists, bool useRust)
{
	return HnswShouldHaveExistingNeighborCheck(checkExisting, useRust) &&
		HnswShouldHaveExistingNeighborConnection(connectionExists, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_existing_neighbor_update);
Datum
vector_hnsw_should_skip_existing_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		checkExisting = PG_GETARG_INT32(0);
	int32		connectionExists = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSkipExistingNeighborUpdate(checkExisting != 0, connectionExists != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_existing_neighbor_update);
Datum
vector_rust_hnsw_should_skip_existing_neighbor_update(PG_FUNCTION_ARGS)
{
	int32		checkExisting = PG_GETARG_INT32(0);
	int32		connectionExists = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldSkipExistingNeighborUpdate(checkExisting != 0, connectionExists != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_existing_neighbor_check);
Datum
vector_hnsw_should_have_existing_neighbor_check(PG_FUNCTION_ARGS)
{
	int32		checkExisting = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExistingNeighborCheck(checkExisting != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_existing_neighbor_check);
Datum
vector_rust_hnsw_should_have_existing_neighbor_check(PG_FUNCTION_ARGS)
{
	int32		checkExisting = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExistingNeighborCheck(checkExisting != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_existing_neighbor_check_flag);
Datum
vector_hnsw_should_have_existing_neighbor_check_flag(PG_FUNCTION_ARGS)
{
	int32		checkExisting = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExistingNeighborCheckFlag(checkExisting != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_existing_neighbor_check_flag);
Datum
vector_rust_hnsw_should_have_existing_neighbor_check_flag(PG_FUNCTION_ARGS)
{
	int32		checkExisting = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExistingNeighborCheckFlag(checkExisting != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_existing_neighbor_connection);
Datum
vector_hnsw_should_have_existing_neighbor_connection(PG_FUNCTION_ARGS)
{
	int32		connectionExists = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExistingNeighborConnection(connectionExists != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_existing_neighbor_connection);
Datum
vector_rust_hnsw_should_have_existing_neighbor_connection(PG_FUNCTION_ARGS)
{
	int32		connectionExists = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExistingNeighborConnection(connectionExists != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_existing_neighbor_connection_flag);
Datum
vector_hnsw_should_have_existing_neighbor_connection_flag(PG_FUNCTION_ARGS)
{
	int32		connectionExists = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExistingNeighborConnectionFlag(connectionExists != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_existing_neighbor_connection_flag);
Datum
vector_rust_hnsw_should_have_existing_neighbor_connection_flag(PG_FUNCTION_ARGS)
{
	int32		connectionExists = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExistingNeighborConnectionFlag(connectionExists != 0, true));
}

static bool
HnswShouldProbeUndecidedUpdateIndex(int32 updateIndex, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_probe_undecided_update_index_kernel(updateIndex);

	return updateIndex == -2;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_probe_undecided_update_index);
Datum
vector_hnsw_should_probe_undecided_update_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProbeUndecidedUpdateIndex(updateIndex, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_probe_undecided_update_index);
Datum
vector_rust_hnsw_should_probe_undecided_update_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProbeUndecidedUpdateIndex(updateIndex, true));
}

static bool
HnswShouldHaveNonNegativeUpdateIndexFlag(bool isNonNegative, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isNonNegative);

	return isNonNegative;
}

static bool
HnswShouldHaveNonNegativeUpdateIndex(int32 updateIndex, bool useRust)
{
	return HnswShouldHaveNonNegativeUpdateIndexFlag(updateIndex >= 0, useRust);
}

static bool
HnswShouldHaveUpdateIndexBeforeTupleCount(int32 updateIndex, int32 tupleCount, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_append_neighbor_page_kernel((int64) updateIndex, (int64) tupleCount);

	return updateIndex < tupleCount;
}

static bool
HnswShouldApplyNeighborUpdateSlot(int32 updateIndex, int32 tupleCount, bool useRust)
{
	return HnswShouldHaveNonNegativeUpdateIndex(updateIndex, useRust) &&
		HnswShouldHaveUpdateIndexBeforeTupleCount(updateIndex, tupleCount, useRust);
}

static bool
HnswShouldHaveCandidateUpdateIndexFlag(bool hasCandidateIndex, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasCandidateIndex);

	return hasCandidateIndex;
}

static bool
HnswShouldHaveCandidateUpdateIndex(int32 updateIndex, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_unselected_ondisk_neighbor_kernel(updateIndex);

	return HnswShouldHaveCandidateUpdateIndexFlag(updateIndex == -1, false);
}

static bool
HnswShouldUpdateConnectionFromCandidateIndex(int32 updateIndex, bool useRust)
{
	return HnswShouldHaveCandidateUpdateIndex(updateIndex, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_apply_neighbor_update_slot);
Datum
vector_hnsw_should_apply_neighbor_update_slot(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);
	int32		tupleCount = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldApplyNeighborUpdateSlot(updateIndex, tupleCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_apply_neighbor_update_slot);
Datum
vector_rust_hnsw_should_apply_neighbor_update_slot(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);
	int32		tupleCount = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldApplyNeighborUpdateSlot(updateIndex, tupleCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_update_index_before_tuple_count);
Datum
vector_hnsw_should_have_update_index_before_tuple_count(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);
	int32		tupleCount = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveUpdateIndexBeforeTupleCount(updateIndex, tupleCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_update_index_before_tuple_count);
Datum
vector_rust_hnsw_should_have_update_index_before_tuple_count(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);
	int32		tupleCount = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveUpdateIndexBeforeTupleCount(updateIndex, tupleCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_nonnegative_update_index);
Datum
vector_hnsw_should_have_nonnegative_update_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonNegativeUpdateIndex(updateIndex, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_non_negative_update_index);
Datum
vector_hnsw_should_have_non_negative_update_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonNegativeUpdateIndex(updateIndex, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_nonnegative_update_index);
Datum
vector_rust_hnsw_should_have_nonnegative_update_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonNegativeUpdateIndex(updateIndex, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_non_negative_update_index);
Datum
vector_rust_hnsw_should_have_non_negative_update_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonNegativeUpdateIndex(updateIndex, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_non_negative_update_index_flag);
Datum
vector_hnsw_should_have_non_negative_update_index_flag(PG_FUNCTION_ARGS)
{
	int32		isNonNegative = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonNegativeUpdateIndexFlag(isNonNegative != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_non_negative_update_index_flag);
Datum
vector_rust_hnsw_should_have_non_negative_update_index_flag(PG_FUNCTION_ARGS)
{
	int32		isNonNegative = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonNegativeUpdateIndexFlag(isNonNegative != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_connection_from_candidate_index);
Datum
vector_hnsw_should_update_connection_from_candidate_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdateConnectionFromCandidateIndex(updateIndex, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_connection_from_candidate_index);
Datum
vector_rust_hnsw_should_update_connection_from_candidate_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdateConnectionFromCandidateIndex(updateIndex, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_candidate_update_index);
Datum
vector_hnsw_should_have_candidate_update_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveCandidateUpdateIndex(updateIndex, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_candidate_update_index);
Datum
vector_rust_hnsw_should_have_candidate_update_index(PG_FUNCTION_ARGS)
{
	int32		updateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveCandidateUpdateIndex(updateIndex, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_candidate_update_index_flag);
Datum
vector_hnsw_should_have_candidate_update_index_flag(PG_FUNCTION_ARGS)
{
	int32		hasCandidateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveCandidateUpdateIndexFlag(hasCandidateIndex != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_candidate_update_index_flag);
Datum
vector_rust_hnsw_should_have_candidate_update_index_flag(PG_FUNCTION_ARGS)
{
	int32		hasCandidateIndex = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveCandidateUpdateIndexFlag(hasCandidateIndex != 0, true));
}

static bool
HnswShouldRejectOnDiskElementOverwrite(bool overwriteSucceeded, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_neighbor_overwrite_kernel(overwriteSucceeded);

	return !overwriteSucceeded;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_ondisk_element_overwrite);
Datum
vector_hnsw_should_reject_ondisk_element_overwrite(PG_FUNCTION_ARGS)
{
	int32		overwriteSucceeded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectOnDiskElementOverwrite(overwriteSucceeded != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_ondisk_element_overwrite);
Datum
vector_rust_hnsw_should_reject_ondisk_element_overwrite(PG_FUNCTION_ARGS)
{
	int32		overwriteSucceeded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectOnDiskElementOverwrite(overwriteSucceeded != 0, true));
}

static bool
HnswShouldHaveExpectedOnDiskOffsetFlag(bool hasExpectedOffset, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasExpectedOffset);

	return hasExpectedOffset;
}

static bool
HnswShouldHaveExpectedOnDiskOffset(int32 insertedOffset, int32 expectedOffset, bool useRust)
{
	return HnswShouldHaveExpectedOnDiskOffsetFlag(insertedOffset == expectedOffset, useRust);
}

static bool
HnswShouldRejectOnDiskUnexpectedOffset(bool hasExpectedOffset, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasExpectedOffset);

	return !hasExpectedOffset;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_ondisk_unexpected_offset);
Datum
vector_hnsw_should_reject_ondisk_unexpected_offset(PG_FUNCTION_ARGS)
{
	int32		insertedOffset = PG_GETARG_INT32(0);
	int32		expectedOffset = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectOnDiskUnexpectedOffset(HnswShouldHaveExpectedOnDiskOffset(insertedOffset, expectedOffset, false), false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_ondisk_unexpected_offset);
Datum
vector_rust_hnsw_should_reject_ondisk_unexpected_offset(PG_FUNCTION_ARGS)
{
	int32		insertedOffset = PG_GETARG_INT32(0);
	int32		expectedOffset = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldRejectOnDiskUnexpectedOffset(HnswShouldHaveExpectedOnDiskOffset(insertedOffset, expectedOffset, true), true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_expected_ondisk_offset);
Datum
vector_hnsw_should_have_expected_ondisk_offset(PG_FUNCTION_ARGS)
{
	int32		insertedOffset = PG_GETARG_INT32(0);
	int32		expectedOffset = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveExpectedOnDiskOffset(insertedOffset, expectedOffset, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_expected_ondisk_offset);
Datum
vector_rust_hnsw_should_have_expected_ondisk_offset(PG_FUNCTION_ARGS)
{
	int32		insertedOffset = PG_GETARG_INT32(0);
	int32		expectedOffset = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldHaveExpectedOnDiskOffset(insertedOffset, expectedOffset, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_expected_ondisk_offset_flag);
Datum
vector_hnsw_should_have_expected_ondisk_offset_flag(PG_FUNCTION_ARGS)
{
	int32		hasExpectedOffset = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExpectedOnDiskOffsetFlag(hasExpectedOffset != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_expected_ondisk_offset_flag);
Datum
vector_rust_hnsw_should_have_expected_ondisk_offset_flag(PG_FUNCTION_ARGS)
{
	int32		hasExpectedOffset = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveExpectedOnDiskOffsetFlag(hasExpectedOffset != 0, true));
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
HnswShouldHaveOnDiskNextPageFlag(bool nextPageValid, bool useRust)
{
	return HnswShouldHaveOnDiskBlockFlag(nextPageValid, useRust);
}

static bool
HnswShouldHaveOnDiskNextPage(BlockNumber nextPage, bool useRust)
{
	return HnswShouldHaveOnDiskBlockNumber(nextPage, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_next_page);
Datum
vector_hnsw_should_have_ondisk_next_page(PG_FUNCTION_ARGS)
{
	int32		nextPageValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskNextPageFlag(nextPageValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_next_page);
Datum
vector_rust_hnsw_should_have_ondisk_next_page(PG_FUNCTION_ARGS)
{
	int32		nextPageValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskNextPageFlag(nextPageValid != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_next_page_flag);
Datum
vector_hnsw_should_have_ondisk_next_page_flag(PG_FUNCTION_ARGS)
{
	int32		nextPageValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskNextPageFlag(nextPageValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_next_page_flag);
Datum
vector_rust_hnsw_should_have_ondisk_next_page_flag(PG_FUNCTION_ARGS)
{
	int32		nextPageValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskNextPageFlag(nextPageValid != 0, true));
}

static bool
HnswShouldHaveOnDiskInsertSpaceFlag(bool hasSpace, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasSpace);

	return hasSpace;
}

static bool
HnswShouldSetInitialOnDiskInsertPage(bool hasInsertPage, bool hasSpace, bool useRust)
{
	return HnswShouldSetInsertPageWhenMissing(hasInsertPage, useRust) &&
		HnswShouldHaveOnDiskInsertSpaceFlag(hasSpace, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_insert_space);
Datum
vector_hnsw_should_have_ondisk_insert_space(PG_FUNCTION_ARGS)
{
	int32		hasSpace = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskInsertSpaceFlag(hasSpace != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_insert_space);
Datum
vector_rust_hnsw_should_have_ondisk_insert_space(PG_FUNCTION_ARGS)
{
	int32		hasSpace = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskInsertSpaceFlag(hasSpace != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_ondisk_insert_space_flag);
Datum
vector_hnsw_should_have_ondisk_insert_space_flag(PG_FUNCTION_ARGS)
{
	int32		hasSpace = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskInsertSpaceFlag(hasSpace != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_ondisk_insert_space_flag);
Datum
vector_rust_hnsw_should_have_ondisk_insert_space_flag(PG_FUNCTION_ARGS)
{
	int32		hasSpace = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveOnDiskInsertSpaceFlag(hasSpace != 0, true));
}

static bool
HnswShouldHaveDistinctOnDiskNeighborBufferFlag(bool hasDistinctBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasDistinctBuffer);

	return hasDistinctBuffer;
}

static bool
HnswShouldHaveDistinctOnDiskNeighborBuffer(bool sameBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel(sameBuffer);

	return HnswShouldHaveDistinctOnDiskNeighborBufferFlag(!sameBuffer, false);
}

static bool
HnswShouldReleaseOnDiskNeighborBuffer(bool sameBuffer, bool useRust)
{
	return HnswShouldHaveDistinctOnDiskNeighborBuffer(sameBuffer, useRust);
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

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_distinct_ondisk_neighbor_buffer);
Datum
vector_hnsw_should_have_distinct_ondisk_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveDistinctOnDiskNeighborBuffer(sameBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_distinct_ondisk_neighbor_buffer);
Datum
vector_rust_hnsw_should_have_distinct_ondisk_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveDistinctOnDiskNeighborBuffer(sameBuffer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_distinct_ondisk_neighbor_buffer_flag);
Datum
vector_hnsw_should_have_distinct_ondisk_neighbor_buffer_flag(PG_FUNCTION_ARGS)
{
	int32		hasDistinctBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveDistinctOnDiskNeighborBufferFlag(hasDistinctBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_distinct_ondisk_neighbor_buffer_flag);
Datum
vector_rust_hnsw_should_have_distinct_ondisk_neighbor_buffer_flag(PG_FUNCTION_ARGS)
{
	int32		hasDistinctBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveDistinctOnDiskNeighborBufferFlag(hasDistinctBuffer != 0, true));
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
