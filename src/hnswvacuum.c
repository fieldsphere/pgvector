#include "postgres.h"

#include "access/genam.h"
#include "access/generic_xlog.h"
#include "commands/vacuum.h"
#include "hnsw.h"
#include "nodes/pg_list.h"
#include "rust_ffi.h"
#include "storage/bufmgr.h"
#include "storage/lmgr.h"
#include "utils/memutils.h"
#include "utils/rel.h"

#if PG_VERSION_NUM >= 160000
#include "varatt.h"
#endif

#if PG_VERSION_NUM >= 180000
#define vacuum_delay_point() vacuum_delay_point(false)
#endif

/*
 * Check if deleted list contains an index TID
 */
static bool
HnswShouldContainDeletedTid(bool hasDeletedTid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasDeletedTid);

	return hasDeletedTid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_contain_deleted_tid);
Datum
vector_hnsw_should_contain_deleted_tid(PG_FUNCTION_ARGS)
{
	int32		hasDeletedTid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldContainDeletedTid(hasDeletedTid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_contain_deleted_tid);
Datum
vector_rust_hnsw_should_contain_deleted_tid(PG_FUNCTION_ARGS)
{
	int32		hasDeletedTid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldContainDeletedTid(hasDeletedTid != 0, true));
}

static bool
HnswShouldContinueVacuumBlockScan(bool hasValidBlock, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasValidBlock);

	return hasValidBlock;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_continue_vacuum_block_scan);
Datum
vector_hnsw_should_continue_vacuum_block_scan(PG_FUNCTION_ARGS)
{
	int32		hasValidBlock = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldContinueVacuumBlockScan(hasValidBlock != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_continue_vacuum_block_scan);
Datum
vector_rust_hnsw_should_continue_vacuum_block_scan(PG_FUNCTION_ARGS)
{
	int32		hasValidBlock = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldContinueVacuumBlockScan(hasValidBlock != 0, true));
}

static bool
DeletedContains(tidhash_hash * deleted, ItemPointer indextid)
{
	return HnswShouldContainDeletedTid(tidhash_lookup(deleted, *indextid) != NULL, true);
}

static bool
HnswShouldRepairUnderfilledLayer0(bool lastItemValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_repair_underfilled_layer0_kernel(lastItemValid);

	return !lastItemValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_repair_underfilled_layer0);
Datum
vector_hnsw_should_repair_underfilled_layer0(PG_FUNCTION_ARGS)
{
	int32		lastItemValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRepairUnderfilledLayer0(lastItemValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_repair_underfilled_layer0);
Datum
vector_rust_hnsw_should_repair_underfilled_layer0(PG_FUNCTION_ARGS)
{
	int32		lastItemValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRepairUnderfilledLayer0(lastItemValid != 0, true));
}

static bool
HnswShouldSkipNonElementVacuumTuple(bool isElementTuple, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(isElementTuple);

	return !isElementTuple;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_non_element_vacuum_tuple);
Datum
vector_hnsw_should_skip_non_element_vacuum_tuple(PG_FUNCTION_ARGS)
{
	int32		isElementTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNonElementVacuumTuple(isElementTuple != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_non_element_vacuum_tuple);
Datum
vector_rust_hnsw_should_skip_non_element_vacuum_tuple(PG_FUNCTION_ARGS)
{
	int32		isElementTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNonElementVacuumTuple(isElementTuple != 0, true));
}

static bool
HnswShouldProcessVacuumHeapTids(bool firstHeaptidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(firstHeaptidValid);

	return firstHeaptidValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_process_vacuum_heaptids);
Datum
vector_hnsw_should_process_vacuum_heaptids(PG_FUNCTION_ARGS)
{
	int32		firstHeaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessVacuumHeapTids(firstHeaptidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_process_vacuum_heaptids);
Datum
vector_rust_hnsw_should_process_vacuum_heaptids(PG_FUNCTION_ARGS)
{
	int32		firstHeaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessVacuumHeapTids(firstHeaptidValid != 0, true));
}

static bool
HnswShouldHaveVacuumTupleHeapTidFlag(bool firstHeaptidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(firstHeaptidValid);

	return firstHeaptidValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_vacuum_tuple_heaptid);
Datum
vector_hnsw_should_have_vacuum_tuple_heaptid(PG_FUNCTION_ARGS)
{
	int32		firstHeaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumTupleHeapTidFlag(firstHeaptidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_vacuum_tuple_heaptid);
Datum
vector_rust_hnsw_should_have_vacuum_tuple_heaptid(PG_FUNCTION_ARGS)
{
	int32		firstHeaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumTupleHeapTidFlag(firstHeaptidValid != 0, true));
}

static bool
HnswShouldMarkVacuumTupleDeleted(bool firstHeaptidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(firstHeaptidValid);

	return !firstHeaptidValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_mark_vacuum_tuple_deleted);
Datum
vector_hnsw_should_mark_vacuum_tuple_deleted(PG_FUNCTION_ARGS)
{
	int32		firstHeaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldMarkVacuumTupleDeleted(firstHeaptidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_mark_vacuum_tuple_deleted);
Datum
vector_rust_hnsw_should_mark_vacuum_tuple_deleted(PG_FUNCTION_ARGS)
{
	int32		firstHeaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldMarkVacuumTupleDeleted(firstHeaptidValid != 0, true));
}

static bool
HnswShouldStopVacuumHeapTidScan(bool heapTidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(heapTidValid);

	return !heapTidValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_vacuum_heaptid_scan);
Datum
vector_hnsw_should_stop_vacuum_heaptid_scan(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopVacuumHeapTidScan(heapTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_vacuum_heaptid_scan);
Datum
vector_rust_hnsw_should_stop_vacuum_heaptid_scan(PG_FUNCTION_ARGS)
{
	int32		heapTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopVacuumHeapTidScan(heapTidValid != 0, true));
}

static bool
HnswShouldRemoveVacuumHeapTid(bool callbackRemove, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(callbackRemove);

	return callbackRemove;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_remove_vacuum_heaptid);
Datum
vector_hnsw_should_remove_vacuum_heaptid(PG_FUNCTION_ARGS)
{
	int32		callbackRemove = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRemoveVacuumHeapTid(callbackRemove != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_remove_vacuum_heaptid);
Datum
vector_rust_hnsw_should_remove_vacuum_heaptid(PG_FUNCTION_ARGS)
{
	int32		callbackRemove = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRemoveVacuumHeapTid(callbackRemove != 0, true));
}

static bool
HnswShouldCompactVacuumHeapTids(bool itemUpdated, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(itemUpdated);

	return itemUpdated;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_compact_vacuum_heaptids);
Datum
vector_hnsw_should_compact_vacuum_heaptids(PG_FUNCTION_ARGS)
{
	int32		itemUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCompactVacuumHeapTids(itemUpdated != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_compact_vacuum_heaptids);
Datum
vector_rust_hnsw_should_compact_vacuum_heaptids(PG_FUNCTION_ARGS)
{
	int32		itemUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCompactVacuumHeapTids(itemUpdated != 0, true));
}

static bool
HnswShouldFinishVacuumPageUpdate(bool pageUpdated, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(pageUpdated);

	return pageUpdated;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_finish_vacuum_page_update);
Datum
vector_hnsw_should_finish_vacuum_page_update(PG_FUNCTION_ARGS)
{
	int32		pageUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFinishVacuumPageUpdate(pageUpdated != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_finish_vacuum_page_update);
Datum
vector_rust_hnsw_should_finish_vacuum_page_update(PG_FUNCTION_ARGS)
{
	int32		pageUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFinishVacuumPageUpdate(pageUpdated != 0, true));
}

static bool
HnswShouldSkipInvalidVacuumNeighborTid(bool neighborTidValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(neighborTidValid);

	return !neighborTidValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_invalid_vacuum_neighbor_tid);
Datum
vector_hnsw_should_skip_invalid_vacuum_neighbor_tid(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipInvalidVacuumNeighborTid(neighborTidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_invalid_vacuum_neighbor_tid);
Datum
vector_rust_hnsw_should_skip_invalid_vacuum_neighbor_tid(PG_FUNCTION_ARGS)
{
	int32		neighborTidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipInvalidVacuumNeighborTid(neighborTidValid != 0, true));
}

static bool
HnswShouldFlagDeletedVacuumNeighbor(bool isDeletedNeighbor, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isDeletedNeighbor);

	return isDeletedNeighbor;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_flag_deleted_vacuum_neighbor);
Datum
vector_hnsw_should_flag_deleted_vacuum_neighbor(PG_FUNCTION_ARGS)
{
	int32		isDeletedNeighbor = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFlagDeletedVacuumNeighbor(isDeletedNeighbor != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_flag_deleted_vacuum_neighbor);
Datum
vector_rust_hnsw_should_flag_deleted_vacuum_neighbor(PG_FUNCTION_ARGS)
{
	int32		isDeletedNeighbor = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldFlagDeletedVacuumNeighbor(isDeletedNeighbor != 0, true));
}

static bool
HnswShouldCheckVacuumUnderfilledLayer0(bool needsUpdated, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(needsUpdated);

	return !needsUpdated;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_check_vacuum_underfilled_layer0);
Datum
vector_hnsw_should_check_vacuum_underfilled_layer0(PG_FUNCTION_ARGS)
{
	int32		needsUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCheckVacuumUnderfilledLayer0(needsUpdated != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_check_vacuum_underfilled_layer0);
Datum
vector_rust_hnsw_should_check_vacuum_underfilled_layer0(PG_FUNCTION_ARGS)
{
	int32		needsUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldCheckVacuumUnderfilledLayer0(needsUpdated != 0, true));
}

static bool
HnswShouldSkipVacuumEntryPointElement(bool hasEntryPoint, int32 elementBlkno, int32 elementOffno, int32 entryBlkno, int32 entryOffno, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasEntryPoint) &&
			vector_rust_hnsw_should_match_neighbor_connection_kernel(elementBlkno, elementOffno, entryBlkno, entryOffno);

	return hasEntryPoint && elementBlkno == entryBlkno && elementOffno == entryOffno;
}

static bool
HnswShouldHaveVacuumEntrypointFlag(bool hasEntryPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasEntryPoint);

	return hasEntryPoint;
}

static bool
HnswShouldHaveVacuumEntrypoint(HnswElement entryPoint, bool useRust)
{
	return HnswShouldHaveVacuumEntrypointFlag(entryPoint != NULL, useRust);
}

static bool
HnswShouldUseDefaultVacuumEntrypointTid(bool hasEntryPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasEntryPoint);

	return !hasEntryPoint;
}

static int32
HnswGetVacuumEntrypointBlknoForCompare(HnswElement entryPoint, bool useRust)
{
	if (HnswShouldUseDefaultVacuumEntrypointTid(HnswShouldHaveVacuumEntrypoint(entryPoint, useRust), useRust))
		return -1;

	return (int32) entryPoint->blkno;
}

static int32
HnswGetVacuumEntrypointOffnoForCompare(HnswElement entryPoint, bool useRust)
{
	if (HnswShouldUseDefaultVacuumEntrypointTid(HnswShouldHaveVacuumEntrypoint(entryPoint, useRust), useRust))
		return -1;

	return (int32) entryPoint->offno;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_vacuum_entrypoint_element);
Datum
vector_hnsw_should_skip_vacuum_entrypoint_element(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);
	int32		elementBlkno = PG_GETARG_INT32(1);
	int32		elementOffno = PG_GETARG_INT32(2);
	int32		entryBlkno = PG_GETARG_INT32(3);
	int32		entryOffno = PG_GETARG_INT32(4);

	PG_RETURN_BOOL(HnswShouldSkipVacuumEntryPointElement(hasEntryPoint != 0, elementBlkno, elementOffno, entryBlkno, entryOffno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_vacuum_entrypoint_element);
Datum
vector_rust_hnsw_should_skip_vacuum_entrypoint_element(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);
	int32		elementBlkno = PG_GETARG_INT32(1);
	int32		elementOffno = PG_GETARG_INT32(2);
	int32		entryBlkno = PG_GETARG_INT32(3);
	int32		entryOffno = PG_GETARG_INT32(4);

	PG_RETURN_BOOL(HnswShouldSkipVacuumEntryPointElement(hasEntryPoint != 0, elementBlkno, elementOffno, entryBlkno, entryOffno, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_default_vacuum_entrypoint_tid);
Datum
vector_hnsw_should_use_default_vacuum_entrypoint_tid(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultVacuumEntrypointTid(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_default_vacuum_entrypoint_tid);
Datum
vector_rust_hnsw_should_use_default_vacuum_entrypoint_tid(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultVacuumEntrypointTid(hasEntryPoint != 0, true));
}

static bool
HnswShouldSkipVacuumElementWithoutUpdates(bool needsUpdated, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(needsUpdated);

	return !needsUpdated;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_vacuum_element_without_updates);
Datum
vector_hnsw_should_skip_vacuum_element_without_updates(PG_FUNCTION_ARGS)
{
	int32		needsUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipVacuumElementWithoutUpdates(needsUpdated != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_vacuum_element_without_updates);
Datum
vector_rust_hnsw_should_skip_vacuum_element_without_updates(PG_FUNCTION_ARGS)
{
	int32		needsUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipVacuumElementWithoutUpdates(needsUpdated != 0, true));
}

static bool
HnswShouldPromoteVacuumEntryPoint(bool entryPointIsNull, int32 elementLevel, int32 entryPointLevel, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_entry_point_kernel(entryPointIsNull, elementLevel, entryPointLevel);

	return entryPointIsNull || elementLevel > entryPointLevel;
}

static bool
HnswShouldUseDefaultVacuumEntryLevel(bool hasEntryPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasEntryPoint);

	return !hasEntryPoint;
}

static int32
HnswGetVacuumEntryLevelForPromotion(HnswElement entryPoint, bool useRust)
{
	if (HnswShouldUseDefaultVacuumEntryLevel(HnswShouldHaveVacuumEntrypoint(entryPoint, useRust), useRust))
		return 0;

	return entryPoint->level;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_promote_vacuum_entrypoint);
Datum
vector_hnsw_should_promote_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		entryPointIsNull = PG_GETARG_INT32(0);
	int32		elementLevel = PG_GETARG_INT32(1);
	int32		entryPointLevel = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldPromoteVacuumEntryPoint(entryPointIsNull != 0, elementLevel, entryPointLevel, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_promote_vacuum_entrypoint);
Datum
vector_rust_hnsw_should_promote_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		entryPointIsNull = PG_GETARG_INT32(0);
	int32		elementLevel = PG_GETARG_INT32(1);
	int32		entryPointLevel = PG_GETARG_INT32(2);

	PG_RETURN_BOOL(HnswShouldPromoteVacuumEntryPoint(entryPointIsNull != 0, elementLevel, entryPointLevel, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_default_vacuum_entry_level);
Datum
vector_hnsw_should_use_default_vacuum_entry_level(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultVacuumEntryLevel(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_default_vacuum_entry_level);
Datum
vector_rust_hnsw_should_use_default_vacuum_entry_level(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseDefaultVacuumEntryLevel(hasEntryPoint != 0, true));
}

static bool
HnswShouldResetVacuumHighestPoint(bool highestPointValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(highestPointValid);

	return !highestPointValid;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reset_vacuum_highest_point);
Datum
vector_hnsw_should_reset_vacuum_highest_point(PG_FUNCTION_ARGS)
{
	int32		highestPointValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldResetVacuumHighestPoint(highestPointValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reset_vacuum_highest_point);
Datum
vector_rust_hnsw_should_reset_vacuum_highest_point(PG_FUNCTION_ARGS)
{
	int32		highestPointValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldResetVacuumHighestPoint(highestPointValid != 0, true));
}

static bool
HnswShouldHaveVacuumHighestPointBlockFlag(bool highestPointValid, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(highestPointValid);

	return highestPointValid;
}

static bool
HnswShouldHaveVacuumHighestPointPointerFlag(bool hasHighestPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasHighestPoint);

	return hasHighestPoint;
}

static bool
HnswShouldHaveVacuumHighestPointPointer(HnswElement highestPoint, bool useRust)
{
	return HnswShouldHaveVacuumHighestPointPointerFlag(highestPoint != NULL, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_vacuum_highest_point_pointer);
Datum
vector_hnsw_should_have_vacuum_highest_point_pointer(PG_FUNCTION_ARGS)
{
	int32		hasHighestPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumHighestPointPointerFlag(hasHighestPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_vacuum_highest_point_pointer);
Datum
vector_rust_hnsw_should_have_vacuum_highest_point_pointer(PG_FUNCTION_ARGS)
{
	int32		hasHighestPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumHighestPointPointerFlag(hasHighestPoint != 0, true));
}

static bool
HnswShouldHaveVacuumHighestPointBlock(HnswElement highestPoint, bool useRust)
{
	bool		highestPointValid = false;

	if (HnswShouldHaveVacuumHighestPointPointer(highestPoint, useRust))
		highestPointValid = BlockNumberIsValid(highestPoint->blkno);

	return HnswShouldHaveVacuumHighestPointBlockFlag(highestPointValid, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_vacuum_highest_point_block);
Datum
vector_hnsw_should_have_vacuum_highest_point_block(PG_FUNCTION_ARGS)
{
	int32		highestPointValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumHighestPointBlockFlag(highestPointValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_vacuum_highest_point_block);
Datum
vector_rust_hnsw_should_have_vacuum_highest_point_block(PG_FUNCTION_ARGS)
{
	int32		highestPointValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumHighestPointBlockFlag(highestPointValid != 0, true));
}

static bool
HnswShouldRepairVacuumHighestPoint(bool needsUpdated, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(needsUpdated);

	return needsUpdated;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_repair_vacuum_highest_point);
Datum
vector_hnsw_should_repair_vacuum_highest_point(PG_FUNCTION_ARGS)
{
	int32		needsUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRepairVacuumHighestPoint(needsUpdated != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_repair_vacuum_highest_point);
Datum
vector_rust_hnsw_should_repair_vacuum_highest_point(PG_FUNCTION_ARGS)
{
	int32		needsUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRepairVacuumHighestPoint(needsUpdated != 0, true));
}

static bool
HnswShouldRepairVacuumEntryPoint(bool needsUpdated, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(needsUpdated);

	return needsUpdated;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_repair_vacuum_entrypoint);
Datum
vector_hnsw_should_repair_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		needsUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRepairVacuumEntryPoint(needsUpdated != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_repair_vacuum_entrypoint);
Datum
vector_rust_hnsw_should_repair_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		needsUpdated = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRepairVacuumEntryPoint(needsUpdated != 0, true));
}

static bool
HnswShouldResetVacuumEntryPointNeighbors(bool hasHighestPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasHighestPoint);

	return hasHighestPoint;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reset_vacuum_entrypoint_neighbors);
Datum
vector_hnsw_should_reset_vacuum_entrypoint_neighbors(PG_FUNCTION_ARGS)
{
	int32		hasHighestPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldResetVacuumEntryPointNeighbors(hasHighestPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reset_vacuum_entrypoint_neighbors);
Datum
vector_rust_hnsw_should_reset_vacuum_entrypoint_neighbors(PG_FUNCTION_ARGS)
{
	int32		hasHighestPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldResetVacuumEntryPointNeighbors(hasHighestPoint != 0, true));
}

static bool
HnswShouldReplaceDeletedVacuumEntryPoint(bool isDeletedEntrypoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isDeletedEntrypoint);

	return isDeletedEntrypoint;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_replace_deleted_vacuum_entrypoint);
Datum
vector_hnsw_should_replace_deleted_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		isDeletedEntrypoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReplaceDeletedVacuumEntryPoint(isDeletedEntrypoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_replace_deleted_vacuum_entrypoint);
Datum
vector_rust_hnsw_should_replace_deleted_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		isDeletedEntrypoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReplaceDeletedVacuumEntryPoint(isDeletedEntrypoint != 0, true));
}

static bool
HnswShouldRepairNonnullVacuumHighestPoint(bool hasHighestPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasHighestPoint);

	return hasHighestPoint;
}

static bool
HnswShouldHaveVacuumHighestPointFlag(bool hasHighestPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasHighestPoint);

	return hasHighestPoint;
}

static bool
HnswShouldHaveVacuumHighestPoint(HnswElement highestPoint, bool useRust)
{
	return HnswShouldHaveVacuumHighestPointFlag(highestPoint != NULL, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_repair_nonnull_vacuum_highest_point);
Datum
vector_hnsw_should_repair_nonnull_vacuum_highest_point(PG_FUNCTION_ARGS)
{
	int32		hasHighestPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRepairNonnullVacuumHighestPoint(hasHighestPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_repair_nonnull_vacuum_highest_point);
Datum
vector_rust_hnsw_should_repair_nonnull_vacuum_highest_point(PG_FUNCTION_ARGS)
{
	int32		hasHighestPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRepairNonnullVacuumHighestPoint(hasHighestPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_vacuum_highest_point);
Datum
vector_hnsw_should_have_vacuum_highest_point(PG_FUNCTION_ARGS)
{
	int32		hasHighestPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumHighestPointFlag(hasHighestPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_vacuum_highest_point);
Datum
vector_rust_hnsw_should_have_vacuum_highest_point(PG_FUNCTION_ARGS)
{
	int32		hasHighestPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumHighestPointFlag(hasHighestPoint != 0, true));
}

static bool
HnswShouldProcessNonnullVacuumEntrypoint(bool hasEntryPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(hasEntryPoint);

	return hasEntryPoint;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_process_nonnull_vacuum_entrypoint);
Datum
vector_hnsw_should_process_nonnull_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessNonnullVacuumEntrypoint(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_process_nonnull_vacuum_entrypoint);
Datum
vector_rust_hnsw_should_process_nonnull_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldProcessNonnullVacuumEntrypoint(hasEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_vacuum_entrypoint);
Datum
vector_hnsw_should_have_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumEntrypointFlag(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_vacuum_entrypoint);
Datum
vector_rust_hnsw_should_have_vacuum_entrypoint(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumEntrypointFlag(hasEntryPoint != 0, true));
}

static bool
HnswShouldSkipNonElementMarkDeletedTuple(bool isElementTuple, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(isElementTuple);

	return !isElementTuple;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_non_element_markdeleted_tuple);
Datum
vector_hnsw_should_skip_non_element_markdeleted_tuple(PG_FUNCTION_ARGS)
{
	int32		isElementTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNonElementMarkDeletedTuple(isElementTuple != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_non_element_markdeleted_tuple);
Datum
vector_rust_hnsw_should_skip_non_element_markdeleted_tuple(PG_FUNCTION_ARGS)
{
	int32		isElementTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNonElementMarkDeletedTuple(isElementTuple != 0, true));
}

static bool
HnswShouldSkipLiveMarkDeletedTuple(bool isLiveTuple, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isLiveTuple);

	return isLiveTuple;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_live_markdeleted_tuple);
Datum
vector_hnsw_should_skip_live_markdeleted_tuple(PG_FUNCTION_ARGS)
{
	int32		isLiveTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipLiveMarkDeletedTuple(isLiveTuple != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_live_markdeleted_tuple);
Datum
vector_rust_hnsw_should_skip_live_markdeleted_tuple(PG_FUNCTION_ARGS)
{
	int32		isLiveTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipLiveMarkDeletedTuple(isLiveTuple != 0, true));
}

static bool
HnswShouldSetVacuumInsertPageWhenMissing(bool hasInsertPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasInsertPage);

	return !hasInsertPage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_set_vacuum_insert_page_when_missing);
Datum
vector_hnsw_should_set_vacuum_insert_page_when_missing(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSetVacuumInsertPageWhenMissing(hasInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_set_vacuum_insert_page_when_missing);
Datum
vector_rust_hnsw_should_set_vacuum_insert_page_when_missing(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSetVacuumInsertPageWhenMissing(hasInsertPage != 0, true));
}

static bool
HnswShouldHaveVacuumInsertPageFlag(bool hasInsertPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasInsertPage);

	return hasInsertPage;
}

static bool
HnswShouldHaveVacuumInsertPage(BlockNumber insertPage, bool useRust)
{
	return HnswShouldHaveVacuumInsertPageFlag(BlockNumberIsValid(insertPage), useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_vacuum_insert_page);
Datum
vector_hnsw_should_have_vacuum_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumInsertPageFlag(hasInsertPage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_vacuum_insert_page);
Datum
vector_rust_hnsw_should_have_vacuum_insert_page(PG_FUNCTION_ARGS)
{
	int32		hasInsertPage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumInsertPageFlag(hasInsertPage != 0, true));
}

static bool
HnswShouldMatchMarkDeletedNeighborPage(int32 neighborPage, int32 elementPage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_match_neighbor_connection_kernel(neighborPage, 0, elementPage, 0);

	return neighborPage == elementPage;
}

static bool
HnswShouldMatchMarkDeletedBuffers(int32 leftBuffer, int32 rightBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_match_neighbor_connection_kernel(leftBuffer, 0, rightBuffer, 0);

	return leftBuffer == rightBuffer;
}

static bool
HnswShouldReuseMarkDeletedBufferForNeighborPage(bool samePage, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_ondisk_insert_page_kernel(samePage);

	return samePage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page);
Datum
vector_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page(PG_FUNCTION_ARGS)
{
	int32		samePage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReuseMarkDeletedBufferForNeighborPage(samePage != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page);
Datum
vector_rust_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page(PG_FUNCTION_ARGS)
{
	int32		samePage = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReuseMarkDeletedBufferForNeighborPage(samePage != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_match_markdeleted_neighbor_page);
Datum
vector_hnsw_should_match_markdeleted_neighbor_page(PG_FUNCTION_ARGS)
{
	int32		neighborPage = PG_GETARG_INT32(0);
	int32		elementPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldMatchMarkDeletedNeighborPage(neighborPage, elementPage, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_match_markdeleted_neighbor_page);
Datum
vector_rust_hnsw_should_match_markdeleted_neighbor_page(PG_FUNCTION_ARGS)
{
	int32		neighborPage = PG_GETARG_INT32(0);
	int32		elementPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldMatchMarkDeletedNeighborPage(neighborPage, elementPage, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_match_markdeleted_buffers);
Datum
vector_hnsw_should_match_markdeleted_buffers(PG_FUNCTION_ARGS)
{
	int32		leftBuffer = PG_GETARG_INT32(0);
	int32		rightBuffer = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldMatchMarkDeletedBuffers(leftBuffer, rightBuffer, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_match_markdeleted_buffers);
Datum
vector_rust_hnsw_should_match_markdeleted_buffers(PG_FUNCTION_ARGS)
{
	int32		leftBuffer = PG_GETARG_INT32(0);
	int32		rightBuffer = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldMatchMarkDeletedBuffers(leftBuffer, rightBuffer, true));
}

static bool
HnswShouldReleaseMarkDeletedNeighborBuffer(bool sameBuffer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel(sameBuffer);

	return !sameBuffer;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_release_markdeleted_neighbor_buffer);
Datum
vector_hnsw_should_release_markdeleted_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReleaseMarkDeletedNeighborBuffer(sameBuffer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_release_markdeleted_neighbor_buffer);
Datum
vector_rust_hnsw_should_release_markdeleted_neighbor_buffer(PG_FUNCTION_ARGS)
{
	int32		sameBuffer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReleaseMarkDeletedNeighborBuffer(sameBuffer != 0, true));
}

static bool
HnswShouldResetMarkDeletedVersion(int32 version, int32 maxVersion, bool useRust)
{
	bool		versionWithinRange = version <= maxVersion;

	if (useRust)
		return vector_rust_hnsw_should_assign_new_lock_tranche_kernel(versionWithinRange);

	return version > maxVersion;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reset_markdeleted_version);
Datum
vector_hnsw_should_reset_markdeleted_version(PG_FUNCTION_ARGS)
{
	int32		version = PG_GETARG_INT32(0);
	int32		maxVersion = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldResetMarkDeletedVersion(version, maxVersion, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reset_markdeleted_version);
Datum
vector_rust_hnsw_should_reset_markdeleted_version(PG_FUNCTION_ARGS)
{
	int32		version = PG_GETARG_INT32(0);
	int32		maxVersion = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldResetMarkDeletedVersion(version, maxVersion, true));
}

static bool
HnswShouldSkipNonElementRepairGraphTuple(bool isElementTuple, bool useRust)
{
	return HnswShouldSkipNonElementVacuumTuple(isElementTuple, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_non_element_repairgraph_tuple);
Datum
vector_hnsw_should_skip_non_element_repairgraph_tuple(PG_FUNCTION_ARGS)
{
	int32		isElementTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNonElementRepairGraphTuple(isElementTuple != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_non_element_repairgraph_tuple);
Datum
vector_rust_hnsw_should_skip_non_element_repairgraph_tuple(PG_FUNCTION_ARGS)
{
	int32		isElementTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipNonElementRepairGraphTuple(isElementTuple != 0, true));
}

static bool
HnswShouldSkipDeletedRepairGraphElement(bool firstHeaptidValid, bool useRust)
{
	return HnswShouldMarkVacuumTupleDeleted(firstHeaptidValid, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_deleted_repairgraph_element);
Datum
vector_hnsw_should_skip_deleted_repairgraph_element(PG_FUNCTION_ARGS)
{
	int32		firstHeaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipDeletedRepairGraphElement(firstHeaptidValid != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_deleted_repairgraph_element);
Datum
vector_rust_hnsw_should_skip_deleted_repairgraph_element(PG_FUNCTION_ARGS)
{
	int32		firstHeaptidValid = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipDeletedRepairGraphElement(firstHeaptidValid != 0, true));
}

static bool
HnswShouldTrackVacuumHighestNonEntrypoint(bool isHigherLevel, bool isEntryPoint, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isHigherLevel) &&
			vector_rust_hnsw_should_assign_new_lock_tranche_kernel(isEntryPoint);

	return isHigherLevel && !isEntryPoint;
}

static bool
HnswShouldMatchVacuumEntrypointTuple(bool hasEntryPoint, int32 blkno, int32 offno, int32 entryBlkno, int32 entryOffno, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasEntryPoint) &&
			vector_rust_hnsw_should_match_neighbor_connection_kernel(blkno, offno, entryBlkno, entryOffno);

	return hasEntryPoint && blkno == entryBlkno && offno == entryOffno;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_track_vacuum_highest_non_entrypoint);
Datum
vector_hnsw_should_track_vacuum_highest_non_entrypoint(PG_FUNCTION_ARGS)
{
	int32		isHigherLevel = PG_GETARG_INT32(0);
	int32		isEntryPoint = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldTrackVacuumHighestNonEntrypoint(isHigherLevel != 0, isEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_track_vacuum_highest_non_entrypoint);
Datum
vector_rust_hnsw_should_track_vacuum_highest_non_entrypoint(PG_FUNCTION_ARGS)
{
	int32		isHigherLevel = PG_GETARG_INT32(0);
	int32		isEntryPoint = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldTrackVacuumHighestNonEntrypoint(isHigherLevel != 0, isEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_match_vacuum_entrypoint_tuple);
Datum
vector_hnsw_should_match_vacuum_entrypoint_tuple(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);
	int32		blkno = PG_GETARG_INT32(1);
	int32		offno = PG_GETARG_INT32(2);
	int32		entryBlkno = PG_GETARG_INT32(3);
	int32		entryOffno = PG_GETARG_INT32(4);

	PG_RETURN_BOOL(HnswShouldMatchVacuumEntrypointTuple(hasEntryPoint != 0, blkno, offno, entryBlkno, entryOffno, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_match_vacuum_entrypoint_tuple);
Datum
vector_rust_hnsw_should_match_vacuum_entrypoint_tuple(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);
	int32		blkno = PG_GETARG_INT32(1);
	int32		offno = PG_GETARG_INT32(2);
	int32		entryBlkno = PG_GETARG_INT32(3);
	int32		entryOffno = PG_GETARG_INT32(4);

	PG_RETURN_BOOL(HnswShouldMatchVacuumEntrypointTuple(hasEntryPoint != 0, blkno, offno, entryBlkno, entryOffno, true));
}

static bool
HnswShouldRejectVacuumNeighborOverwrite(bool overwriteSucceeded, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_neighbor_overwrite_kernel(overwriteSucceeded);

	return !overwriteSucceeded;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_vacuum_neighbor_overwrite);
Datum
vector_hnsw_should_reject_vacuum_neighbor_overwrite(PG_FUNCTION_ARGS)
{
	int32		overwriteSucceeded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectVacuumNeighborOverwrite(overwriteSucceeded != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_vacuum_neighbor_overwrite);
Datum
vector_rust_hnsw_should_reject_vacuum_neighbor_overwrite(PG_FUNCTION_ARGS)
{
	int32		overwriteSucceeded = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectVacuumNeighborOverwrite(overwriteSucceeded != 0, true));
}

static bool
HnswShouldInitVacuumStatsWhenMissing(bool hasStats, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasStats);

	return !hasStats;
}

static bool
HnswShouldHaveVacuumStatsFlag(bool hasStats, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasStats);

	return hasStats;
}

static bool
HnswShouldHaveVacuumStats(IndexBulkDeleteResult *stats, bool useRust)
{
	return HnswShouldHaveVacuumStatsFlag(stats != NULL, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_init_vacuum_stats_when_missing);
Datum
vector_hnsw_should_init_vacuum_stats_when_missing(PG_FUNCTION_ARGS)
{
	int32		hasStats = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitVacuumStatsWhenMissing(hasStats != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_init_vacuum_stats_when_missing);
Datum
vector_rust_hnsw_should_init_vacuum_stats_when_missing(PG_FUNCTION_ARGS)
{
	int32		hasStats = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitVacuumStatsWhenMissing(hasStats != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_vacuum_stats);
Datum
vector_hnsw_should_have_vacuum_stats(PG_FUNCTION_ARGS)
{
	int32		hasStats = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumStatsFlag(hasStats != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_vacuum_stats);
Datum
vector_rust_hnsw_should_have_vacuum_stats(PG_FUNCTION_ARGS)
{
	int32		hasStats = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveVacuumStatsFlag(hasStats != 0, true));
}

static bool
HnswShouldSkipVacuumCleanupAnalyzeOnly(bool analyzeOnly, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(analyzeOnly);

	return analyzeOnly;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_vacuum_cleanup_analyze_only);
Datum
vector_hnsw_should_skip_vacuum_cleanup_analyze_only(PG_FUNCTION_ARGS)
{
	int32		analyzeOnly = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipVacuumCleanupAnalyzeOnly(analyzeOnly != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_vacuum_cleanup_analyze_only);
Datum
vector_rust_hnsw_should_skip_vacuum_cleanup_analyze_only(PG_FUNCTION_ARGS)
{
	int32		analyzeOnly = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipVacuumCleanupAnalyzeOnly(analyzeOnly != 0, true));
}

static bool
HnswShouldReturnNullVacuumCleanupStats(bool hasStats, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasStats);

	return !hasStats;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_null_vacuum_cleanup_stats);
Datum
vector_hnsw_should_return_null_vacuum_cleanup_stats(PG_FUNCTION_ARGS)
{
	int32		hasStats = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnNullVacuumCleanupStats(hasStats != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_null_vacuum_cleanup_stats);
Datum
vector_rust_hnsw_should_return_null_vacuum_cleanup_stats(PG_FUNCTION_ARGS)
{
	int32		hasStats = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnNullVacuumCleanupStats(hasStats != 0, true));
}

static bool
HnswShouldSkipDeletedMarkDeletedTuple(bool isDeletedTuple, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isDeletedTuple);

	return isDeletedTuple;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_deleted_markdeleted_tuple);
Datum
vector_hnsw_should_skip_deleted_markdeleted_tuple(PG_FUNCTION_ARGS)
{
	int32		isDeletedTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipDeletedMarkDeletedTuple(isDeletedTuple != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_deleted_markdeleted_tuple);
Datum
vector_rust_hnsw_should_skip_deleted_markdeleted_tuple(PG_FUNCTION_ARGS)
{
	int32		isDeletedTuple = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldSkipDeletedMarkDeletedTuple(isDeletedTuple != 0, true));
}

/*
 * Remove deleted heap TIDs
 *
 * OK to remove for entry point, since always considered for searches and inserts
 */
static void
RemoveHeapTids(HnswVacuumState * vacuumstate)
{
	BlockNumber blkno = HNSW_HEAD_BLKNO;
	HnswElement highestPoint = &vacuumstate->highestPoint;
	Relation	index = vacuumstate->index;
	BufferAccessStrategy bas = vacuumstate->bas;
	HnswElement entryPoint = HnswGetEntryPoint(vacuumstate->index);
	IndexBulkDeleteResult *stats = vacuumstate->stats;

	/* Store separately since highestPoint.level is uint8 */
	int			highestLevel = -1;

	/* Initialize highest point */
	highestPoint->blkno = InvalidBlockNumber;
	highestPoint->offno = InvalidOffsetNumber;

	while (HnswShouldContinueVacuumBlockScan(BlockNumberIsValid(blkno), true))
	{
		Buffer		buf;
		Page		page;
		GenericXLogState *state;
		OffsetNumber offno;
		OffsetNumber maxoffno;
		bool		updated = false;

		vacuum_delay_point();

		buf = ReadBufferExtended(index, MAIN_FORKNUM, blkno, RBM_NORMAL, bas);
		LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
		state = GenericXLogStart(index);
		page = GenericXLogRegisterBuffer(state, buf, 0);
		maxoffno = PageGetMaxOffsetNumber(page);

		/* Iterate over nodes */
		for (offno = FirstOffsetNumber; offno <= maxoffno; offno = OffsetNumberNext(offno))
		{
			HnswElementTuple etup = (HnswElementTuple) PageGetItem(page, PageGetItemId(page, offno));
			int			idx = 0;
			bool		itemUpdated = false;
			bool		isEntryPoint = HnswShouldMatchVacuumEntrypointTuple(HnswShouldHaveVacuumEntrypoint(entryPoint, true),
																		(int32) blkno,
																		(int32) offno,
																		HnswGetVacuumEntrypointBlknoForCompare(entryPoint, true),
																		HnswGetVacuumEntrypointOffnoForCompare(entryPoint, true),
																		true);

			/* Skip neighbor tuples */
			if (HnswShouldSkipNonElementVacuumTuple(HnswIsElementTuple(etup), true))
				continue;

			if (HnswShouldProcessVacuumHeapTids(HnswShouldHaveVacuumTupleHeapTidFlag(ItemPointerIsValid(&etup->heaptids[0]), true), true))
			{
				for (int i = 0; i < HNSW_HEAPTIDS; i++)
				{
					/* Stop at first unused */
					if (HnswShouldStopVacuumHeapTidScan(ItemPointerIsValid(&etup->heaptids[i]), true))
						break;

					if (HnswShouldRemoveVacuumHeapTid(vacuumstate->callback(&etup->heaptids[i], vacuumstate->callback_state), true))
					{
						itemUpdated = true;
						stats->tuples_removed++;
					}
					else
					{
						/* Move to front of list */
						etup->heaptids[idx++] = etup->heaptids[i];
						stats->num_index_tuples++;
					}
				}

				if (HnswShouldCompactVacuumHeapTids(itemUpdated, true))
				{
					/* Mark rest as invalid */
					for (int i = idx; i < HNSW_HEAPTIDS; i++)
						ItemPointerSetInvalid(&etup->heaptids[i]);

					updated = true;
				}
			}

			if (HnswShouldMarkVacuumTupleDeleted(HnswShouldHaveVacuumTupleHeapTidFlag(ItemPointerIsValid(&etup->heaptids[0]), true), true))
			{
				ItemPointerData ip;
				bool		found;

				/* Add to deleted list */
				ItemPointerSet(&ip, blkno, offno);

				tidhash_insert(vacuumstate->deleted, ip, &found);
				Assert(!found);
			}
			else if (HnswShouldTrackVacuumHighestNonEntrypoint(etup->level > highestLevel, isEntryPoint, true))
			{
				/* Keep track of highest non-entry point */
				highestPoint->blkno = blkno;
				highestPoint->offno = offno;
				highestPoint->level = etup->level;
				highestLevel = etup->level;
			}
		}

		blkno = HnswPageGetOpaque(page)->nextblkno;

		if (HnswShouldFinishVacuumPageUpdate(updated, true))
			GenericXLogFinish(state);
		else
			GenericXLogAbort(state);

		UnlockReleaseBuffer(buf);
	}
}

/*
 * Check for deleted neighbors
 */
static bool
NeedsUpdated(HnswVacuumState * vacuumstate, HnswElement element)
{
	Relation	index = vacuumstate->index;
	BufferAccessStrategy bas = vacuumstate->bas;
	Buffer		buf;
	Page		page;
	HnswNeighborTuple ntup;
	bool		needsUpdated = false;

	buf = ReadBufferExtended(index, MAIN_FORKNUM, element->neighborPage, RBM_NORMAL, bas);
	LockBuffer(buf, BUFFER_LOCK_SHARE);
	page = BufferGetPage(buf);
	ntup = (HnswNeighborTuple) PageGetItem(page, PageGetItemId(page, element->neighborOffno));

	Assert(HnswIsNeighborTuple(ntup));

	/* Check neighbors */
	for (int i = 0; i < ntup->count; i++)
	{
		ItemPointer indextid = &ntup->indextids[i];

		if (HnswShouldSkipInvalidVacuumNeighborTid(ItemPointerIsValid(indextid), true))
			continue;

		/* Check if in deleted list */
		if (HnswShouldFlagDeletedVacuumNeighbor(DeletedContains(vacuumstate->deleted, indextid), true))
		{
			needsUpdated = true;
			break;
		}
	}

	/* Also update if layer 0 is not full */
	/* This could indicate too many candidates being deleted during insert */
	if (HnswShouldCheckVacuumUnderfilledLayer0(needsUpdated, true))
	{
		bool		lastItemValid;

		/* Keep clang-tidy happy */
		Assert(ntup->count > 0);
		lastItemValid = ItemPointerIsValid(&ntup->indextids[ntup->count - 1]);
		needsUpdated = HnswShouldRepairUnderfilledLayer0(lastItemValid, true);
	}

	UnlockReleaseBuffer(buf);

	return needsUpdated;
}

/*
 * Repair graph for a single element
 */
static void
RepairGraphElement(HnswVacuumState * vacuumstate, HnswElement element, HnswElement entryPoint)
{
	Relation	index = vacuumstate->index;
	HnswSupport *support = &vacuumstate->support;
	Buffer		buf;
	Page		page;
	GenericXLogState *state;
	int			m = vacuumstate->m;
	int			efConstruction = vacuumstate->efConstruction;
	BufferAccessStrategy bas = vacuumstate->bas;
	HnswNeighborTuple ntup = vacuumstate->ntup;
	Size		ntupSize = HNSW_NEIGHBOR_TUPLE_SIZE(element->level, m);
	char	   *base = NULL;

	/* Skip if element is entry point */
	if (HnswShouldSkipVacuumEntryPointElement(HnswShouldHaveVacuumEntrypoint(entryPoint, true), (int32) element->blkno, (int32) element->offno,
											  HnswGetVacuumEntrypointBlknoForCompare(entryPoint, true),
											  HnswGetVacuumEntrypointOffnoForCompare(entryPoint, true), true))
		return;

	/* Init fields */
	HnswInitNeighbors(base, element, m, NULL);
	element->heaptidsLength = 0;

	/* Find neighbors for element, skipping itself */
	HnswFindElementNeighbors(base, element, entryPoint, index, support, m, efConstruction, true);

	/* Zero memory for each element */
	MemSet(ntup, 0, HNSW_TUPLE_ALLOC_SIZE);

	/* Update neighbor tuple */
	/* Do this before getting page to minimize locking */
	HnswSetNeighborTuple(base, ntup, element, m);

	/* Get neighbor page */
	buf = ReadBufferExtended(index, MAIN_FORKNUM, element->neighborPage, RBM_NORMAL, bas);
	LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
	state = GenericXLogStart(index);
	page = GenericXLogRegisterBuffer(state, buf, 0);

	/* Overwrite tuple */
	if (HnswShouldRejectVacuumNeighborOverwrite(PageIndexTupleOverwrite(page, element->neighborOffno, (Item) ntup, ntupSize), true))
		elog(ERROR, "failed to add index item to \"%s\"", RelationGetRelationName(index));

	/* Commit */
	GenericXLogFinish(state);
	UnlockReleaseBuffer(buf);

	/* Update neighbors */
	HnswUpdateNeighborsOnDisk(index, support, element, m, true, false);
}

/*
 * Repair graph entry point
 */
static void
RepairGraphEntryPoint(HnswVacuumState * vacuumstate)
{
	Relation	index = vacuumstate->index;
	HnswSupport *support = &vacuumstate->support;
	HnswElement highestPoint = &vacuumstate->highestPoint;
	HnswElement entryPoint;
	MemoryContext oldCtx = MemoryContextSwitchTo(vacuumstate->tmpCtx);

	if (HnswShouldResetVacuumHighestPoint(HnswShouldHaveVacuumHighestPointBlock(highestPoint, true), true))
		highestPoint = NULL;

	/*
	 * Repair graph for highest non-entry point. Highest point may be outdated
	 * due to inserts that happen during and after RemoveHeapTids.
	 */
	if (HnswShouldRepairNonnullVacuumHighestPoint(HnswShouldHaveVacuumHighestPoint(highestPoint, true), true))
	{
		/* Get a shared lock */
		LockPage(index, HNSW_UPDATE_LOCK, ShareLock);

		/* Load element */
		HnswLoadElement(highestPoint, NULL, NULL, index, support, true, NULL);

		/* Repair if needed */
		if (HnswShouldRepairVacuumHighestPoint(NeedsUpdated(vacuumstate, highestPoint), true))
			RepairGraphElement(vacuumstate, highestPoint, HnswGetEntryPoint(index));

		/* Release lock */
		UnlockPage(index, HNSW_UPDATE_LOCK, ShareLock);
	}

	/* Prevent concurrent inserts when possibly updating entry point */
	LockPage(index, HNSW_UPDATE_LOCK, ExclusiveLock);

	/* Get latest entry point */
	entryPoint = HnswGetEntryPoint(index);

	if (HnswShouldProcessNonnullVacuumEntrypoint(HnswShouldHaveVacuumEntrypoint(entryPoint, true), true))
	{
		ItemPointerData epData;

		ItemPointerSet(&epData, entryPoint->blkno, entryPoint->offno);

		if (HnswShouldReplaceDeletedVacuumEntryPoint(DeletedContains(vacuumstate->deleted, &epData), true))
		{
			/*
			 * Replace the entry point with the highest point. If highest
			 * point is outdated and empty, the entry point will be empty
			 * until an element is repaired.
			 */
			HnswUpdateMetaPage(index, HNSW_UPDATE_ENTRY_ALWAYS, highestPoint, InvalidBlockNumber, MAIN_FORKNUM, false);
		}
		else
		{
			/*
			 * Repair the entry point with the highest point. If highest point
			 * is outdated, this can remove connections at higher levels in
			 * the graph until they are repaired, but this should be fine.
			 */
			HnswLoadElement(entryPoint, NULL, NULL, index, support, true, NULL);

			if (HnswShouldRepairVacuumEntryPoint(NeedsUpdated(vacuumstate, entryPoint), true))
			{
				/* Reset neighbors from previous update */
				if (HnswShouldResetVacuumEntryPointNeighbors(HnswShouldHaveVacuumHighestPoint(highestPoint, true), true))
					HnswPtrStore((char *) NULL, highestPoint->neighbors, (HnswNeighborArrayPtr *) NULL);

				RepairGraphElement(vacuumstate, entryPoint, highestPoint);
			}
		}
	}

	/* Release lock */
	UnlockPage(index, HNSW_UPDATE_LOCK, ExclusiveLock);

	/* Reset memory context */
	MemoryContextSwitchTo(oldCtx);
	MemoryContextReset(vacuumstate->tmpCtx);
}

/*
 * Repair graph for all elements
 */
static void
RepairGraph(HnswVacuumState * vacuumstate)
{
	Relation	index = vacuumstate->index;
	BufferAccessStrategy bas = vacuumstate->bas;
	BlockNumber blkno = HNSW_HEAD_BLKNO;

	/*
	 * Wait for inserts to complete. Inserts before this point may have
	 * neighbors about to be deleted. Inserts after this point will not.
	 */
	LockPage(index, HNSW_UPDATE_LOCK, ExclusiveLock);
	UnlockPage(index, HNSW_UPDATE_LOCK, ExclusiveLock);

	/* Repair entry point first */
	RepairGraphEntryPoint(vacuumstate);

	while (HnswShouldContinueVacuumBlockScan(BlockNumberIsValid(blkno), true))
	{
		Buffer		buf;
		Page		page;
		OffsetNumber offno;
		OffsetNumber maxoffno;
		List	   *elements = NIL;
		ListCell   *lc2;
		MemoryContext oldCtx;

		vacuum_delay_point();

		oldCtx = MemoryContextSwitchTo(vacuumstate->tmpCtx);

		buf = ReadBufferExtended(index, MAIN_FORKNUM, blkno, RBM_NORMAL, bas);
		LockBuffer(buf, BUFFER_LOCK_SHARE);
		page = BufferGetPage(buf);
		maxoffno = PageGetMaxOffsetNumber(page);

		/* Load items into memory to minimize locking */
		for (offno = FirstOffsetNumber; offno <= maxoffno; offno = OffsetNumberNext(offno))
		{
			HnswElementTuple etup = (HnswElementTuple) PageGetItem(page, PageGetItemId(page, offno));
			HnswElement element;

			/* Skip neighbor tuples */
			if (HnswShouldSkipNonElementRepairGraphTuple(HnswIsElementTuple(etup), true))
				continue;

			/* Skip updating neighbors if being deleted */
			if (HnswShouldSkipDeletedRepairGraphElement(HnswShouldHaveVacuumTupleHeapTidFlag(ItemPointerIsValid(&etup->heaptids[0]), true), true))
				continue;

			/* Create an element */
			element = HnswInitElementFromBlock(blkno, offno);
			HnswLoadElementFromTuple(element, etup, false, true);

			elements = lappend(elements, element);
		}

		blkno = HnswPageGetOpaque(page)->nextblkno;

		UnlockReleaseBuffer(buf);

		/* Update neighbor pages */
		foreach(lc2, elements)
		{
			HnswElement element = (HnswElement) lfirst(lc2);
			HnswElement entryPoint;
			LOCKMODE	lockmode = ShareLock;

			/* Check if any neighbors point to deleted values */
			if (HnswShouldSkipVacuumElementWithoutUpdates(NeedsUpdated(vacuumstate, element), true))
				continue;

			/* Get a shared lock */
			LockPage(index, HNSW_UPDATE_LOCK, lockmode);

			/* Refresh entry point for each element */
			entryPoint = HnswGetEntryPoint(index);

			/* Prevent concurrent inserts when likely updating entry point */
			if (HnswShouldPromoteVacuumEntryPoint(!HnswShouldHaveVacuumEntrypoint(entryPoint, true), element->level, HnswGetVacuumEntryLevelForPromotion(entryPoint, true), true))
			{
				/* Release shared lock */
				UnlockPage(index, HNSW_UPDATE_LOCK, lockmode);

				/* Get exclusive lock */
				lockmode = ExclusiveLock;
				LockPage(index, HNSW_UPDATE_LOCK, lockmode);

				/* Get latest entry point after lock is acquired */
				entryPoint = HnswGetEntryPoint(index);
			}

			/* Repair connections */
			RepairGraphElement(vacuumstate, element, entryPoint);

			/*
			 * Update metapage if needed. Should only happen if entry point
			 * was replaced and highest point was outdated.
			 */
			if (HnswShouldPromoteVacuumEntryPoint(!HnswShouldHaveVacuumEntrypoint(entryPoint, true), element->level, HnswGetVacuumEntryLevelForPromotion(entryPoint, true), true))
				HnswUpdateMetaPage(index, HNSW_UPDATE_ENTRY_GREATER, element, InvalidBlockNumber, MAIN_FORKNUM, false);

			/* Release lock */
			UnlockPage(index, HNSW_UPDATE_LOCK, lockmode);
		}

		/* Reset memory context */
		MemoryContextSwitchTo(oldCtx);
		MemoryContextReset(vacuumstate->tmpCtx);
	}
}

/*
 * Mark items as deleted
 */
static void
MarkDeleted(HnswVacuumState * vacuumstate)
{
	BlockNumber blkno = HNSW_HEAD_BLKNO;
	BlockNumber insertPage = InvalidBlockNumber;
	Relation	index = vacuumstate->index;
	BufferAccessStrategy bas = vacuumstate->bas;

	/*
	 * Wait for index scans to complete. Scans before this point may contain
	 * tuples about to be deleted. Scans after this point will not, since the
	 * graph has been repaired.
	 */
	LockPage(index, HNSW_SCAN_LOCK, ExclusiveLock);
	UnlockPage(index, HNSW_SCAN_LOCK, ExclusiveLock);

	while (HnswShouldContinueVacuumBlockScan(BlockNumberIsValid(blkno), true))
	{
		Buffer		buf;
		Page		page;
		GenericXLogState *state;
		OffsetNumber offno;
		OffsetNumber maxoffno;

		vacuum_delay_point();

		buf = ReadBufferExtended(index, MAIN_FORKNUM, blkno, RBM_NORMAL, bas);

		/*
		 * ambulkdelete cannot delete entries from pages that are pinned by
		 * other backends
		 *
		 * https://www.postgresql.org/docs/current/index-locking.html
		 */
		LockBufferForCleanup(buf);

		state = GenericXLogStart(index);
		page = GenericXLogRegisterBuffer(state, buf, 0);
		maxoffno = PageGetMaxOffsetNumber(page);

		/* Update element and neighbors together */
		for (offno = FirstOffsetNumber; offno <= maxoffno; offno = OffsetNumberNext(offno))
		{
			HnswElementTuple etup = (HnswElementTuple) PageGetItem(page, PageGetItemId(page, offno));
			HnswNeighborTuple ntup;
			Buffer		nbuf;
			Page		npage;
			BlockNumber neighborPage;
			OffsetNumber neighborOffno;
			bool		samePage;
			bool		sameBuffer;

			/* Skip neighbor tuples */
			if (HnswShouldSkipNonElementMarkDeletedTuple(HnswIsElementTuple(etup), true))
				continue;

			/* Skip deleted tuples */
			if (HnswShouldSkipDeletedMarkDeletedTuple(etup->deleted, true))
			{
				/* Set to first free page */
				if (HnswShouldSetVacuumInsertPageWhenMissing(HnswShouldHaveVacuumInsertPage(insertPage, true), true))
					insertPage = blkno;

				continue;
			}

			/* Skip live tuples */
			if (HnswShouldSkipLiveMarkDeletedTuple(HnswShouldHaveVacuumTupleHeapTidFlag(ItemPointerIsValid(&etup->heaptids[0]), true), true))
				continue;

			/* Get neighbor page */
			neighborPage = ItemPointerGetBlockNumber(&etup->neighbortid);
			neighborOffno = ItemPointerGetOffsetNumber(&etup->neighbortid);
			samePage = HnswShouldMatchMarkDeletedNeighborPage((int32) neighborPage, (int32) blkno, true);

			if (HnswShouldReuseMarkDeletedBufferForNeighborPage(samePage, true))
			{
				nbuf = buf;
				npage = page;
			}
			else
			{
				nbuf = ReadBufferExtended(index, MAIN_FORKNUM, neighborPage, RBM_NORMAL, bas);
				LockBuffer(nbuf, BUFFER_LOCK_EXCLUSIVE);
				npage = GenericXLogRegisterBuffer(state, nbuf, 0);
			}

			ntup = (HnswNeighborTuple) PageGetItem(npage, PageGetItemId(npage, neighborOffno));

			/* Overwrite element */
			/* Use memset instead of MemSet to keep clang-tidy happy */
			etup->deleted = 1;
			memset(&etup->data, 0, VARSIZE_ANY(&etup->data));

			/* Overwrite neighbors */
			for (int i = 0; i < ntup->count; i++)
				ItemPointerSetInvalid(&ntup->indextids[i]);

			/* Increment version */
			/* This is used to avoid incorrect reads for iterative scans */
			/* Reserve some bits for future use */
			etup->version++;
			if (HnswShouldResetMarkDeletedVersion(etup->version, 15, true))
				etup->version = 1;
			ntup->version = etup->version;

			/*
			 * We modified the tuples in place, no need to call
			 * PageIndexTupleOverwrite
			 */

			/* Commit */
			GenericXLogFinish(state);
			sameBuffer = HnswShouldMatchMarkDeletedBuffers((int32) nbuf, (int32) buf, true);
			if (HnswShouldReleaseMarkDeletedNeighborBuffer(sameBuffer, true))
				UnlockReleaseBuffer(nbuf);

			/* Set to first free page */
			if (HnswShouldSetVacuumInsertPageWhenMissing(HnswShouldHaveVacuumInsertPage(insertPage, true), true))
				insertPage = blkno;

			/* Prepare new xlog */
			state = GenericXLogStart(index);
			page = GenericXLogRegisterBuffer(state, buf, 0);
		}

		blkno = HnswPageGetOpaque(page)->nextblkno;

		GenericXLogAbort(state);
		UnlockReleaseBuffer(buf);
	}

	/* Update insert page last, after everything has been marked as deleted */
	HnswUpdateMetaPage(index, 0, NULL, insertPage, MAIN_FORKNUM, false);
}

/*
 * Initialize the vacuum state
 */
static void
InitVacuumState(HnswVacuumState * vacuumstate, IndexVacuumInfo *info, IndexBulkDeleteResult *stats, IndexBulkDeleteCallback callback, void *callback_state)
{
	Relation	index = info->index;

	if (HnswShouldInitVacuumStatsWhenMissing(HnswShouldHaveVacuumStats(stats, true), true))
		stats = (IndexBulkDeleteResult *) palloc0(sizeof(IndexBulkDeleteResult));

	vacuumstate->index = index;
	vacuumstate->stats = stats;
	vacuumstate->callback = callback;
	vacuumstate->callback_state = callback_state;
	vacuumstate->efConstruction = HnswGetEfConstruction(index);
	vacuumstate->bas = GetAccessStrategy(BAS_BULKREAD);
	vacuumstate->ntup = palloc0(HNSW_TUPLE_ALLOC_SIZE);
	vacuumstate->tmpCtx = AllocSetContextCreate(CurrentMemoryContext,
												"Hnsw vacuum temporary context",
												ALLOCSET_DEFAULT_SIZES);

	HnswInitSupport(&vacuumstate->support, index);

	/* Get m from metapage */
	HnswGetMetaPageInfo(index, &vacuumstate->m, NULL);

	/* Create hash table */
	vacuumstate->deleted = tidhash_create(CurrentMemoryContext, 256, NULL);
}

/*
 * Free resources
 */
static void
FreeVacuumState(HnswVacuumState * vacuumstate)
{
	tidhash_destroy(vacuumstate->deleted);
	FreeAccessStrategy(vacuumstate->bas);
	pfree(vacuumstate->ntup);
	MemoryContextDelete(vacuumstate->tmpCtx);
}

/*
 * Bulk delete tuples from the index
 */
IndexBulkDeleteResult *
hnswbulkdelete(IndexVacuumInfo *info, IndexBulkDeleteResult *stats,
			   IndexBulkDeleteCallback callback, void *callback_state)
{
	HnswVacuumState vacuumstate;

	InitVacuumState(&vacuumstate, info, stats, callback, callback_state);

	/* Pass 1: Remove heap TIDs */
	RemoveHeapTids(&vacuumstate);

	/* Pass 2: Repair graph */
	RepairGraph(&vacuumstate);

	/* Pass 3: Mark as deleted */
	MarkDeleted(&vacuumstate);

	FreeVacuumState(&vacuumstate);

	return vacuumstate.stats;
}

/*
 * Clean up after a VACUUM operation
 */
IndexBulkDeleteResult *
hnswvacuumcleanup(IndexVacuumInfo *info, IndexBulkDeleteResult *stats)
{
	Relation	rel = info->index;

	if (HnswShouldSkipVacuumCleanupAnalyzeOnly(info->analyze_only, true))
		return stats;

	/* stats is NULL if ambulkdelete not called */
	/* OK to return NULL if index not changed */
	if (HnswShouldReturnNullVacuumCleanupStats(HnswShouldHaveVacuumStats(stats, true), true))
		return NULL;

	stats->num_pages = RelationGetNumberOfBlocks(rel);

	return stats;
}
