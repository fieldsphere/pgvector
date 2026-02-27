#include "postgres.h"

#include "access/genam.h"
#include "access/relscan.h"
#include "fmgr.h"
#include "hnsw.h"
#include "lib/pairingheap.h"
#include "miscadmin.h"
#include "nodes/pg_list.h"
#include "pgstat.h"
#include "rust_ffi.h"
#include "storage/lmgr.h"
#include "utils/float.h"
#include "utils/memutils.h"
#include "utils/relcache.h"
#include "utils/snapmgr.h"

#if PG_VERSION_NUM >= 160000
#include "varatt.h"
#endif

static bool
HnswShouldReturnEmptyWithoutEntryPoint(bool entryPointIsNull, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_return_empty_without_entrypoint_kernel(entryPointIsNull);

	return entryPointIsNull;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_empty_without_entrypoint);
Datum
vector_hnsw_should_return_empty_without_entrypoint(PG_FUNCTION_ARGS)
{
	int32		entryPointIsNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnEmptyWithoutEntryPoint(entryPointIsNull != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_empty_without_entrypoint);
Datum
vector_rust_hnsw_should_return_empty_without_entrypoint(PG_FUNCTION_ARGS)
{
	int32		entryPointIsNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnEmptyWithoutEntryPoint(entryPointIsNull != 0, true));
}

static bool
HnswShouldResumeFromDiscarded(bool discardedIsEmpty, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_resume_from_discarded_kernel(discardedIsEmpty);

	return !discardedIsEmpty;
}

static bool
HnswShouldStopResumeFromDiscarded(bool discardedIsEmpty, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(discardedIsEmpty);

	return discardedIsEmpty;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_resume_from_discarded);
Datum
vector_hnsw_should_resume_from_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldResumeFromDiscarded(discardedIsEmpty != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_resume_from_discarded);
Datum
vector_rust_hnsw_should_resume_from_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldResumeFromDiscarded(discardedIsEmpty != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_resume_from_discarded);
Datum
vector_hnsw_should_stop_resume_from_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopResumeFromDiscarded(discardedIsEmpty != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_resume_from_discarded);
Datum
vector_rust_hnsw_should_stop_resume_from_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopResumeFromDiscarded(discardedIsEmpty != 0, true));
}

static bool
HnswShouldHaveNonEmptyRemainingDiscardedFlag(bool hasNonEmptyDiscarded, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasNonEmptyDiscarded);

	return hasNonEmptyDiscarded;
}

static bool
HnswShouldHaveNonEmptyRemainingDiscarded(bool discardedIsEmpty, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_return_remaining_discarded_kernel(discardedIsEmpty);

	return HnswShouldHaveNonEmptyRemainingDiscardedFlag(!discardedIsEmpty, false);
}

static bool
HnswShouldReturnRemainingDiscarded(bool discardedIsEmpty, bool useRust)
{
	return HnswShouldHaveNonEmptyRemainingDiscarded(discardedIsEmpty, useRust);
}

static bool
HnswShouldStopReturningRemainingDiscarded(bool discardedIsEmpty, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(discardedIsEmpty);

	return discardedIsEmpty;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_return_remaining_discarded);
Datum
vector_hnsw_should_return_remaining_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnRemainingDiscarded(discardedIsEmpty != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_return_remaining_discarded);
Datum
vector_rust_hnsw_should_return_remaining_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReturnRemainingDiscarded(discardedIsEmpty != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_nonempty_remaining_discarded);
Datum
vector_hnsw_should_have_nonempty_remaining_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonEmptyRemainingDiscarded(discardedIsEmpty != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_nonempty_remaining_discarded);
Datum
vector_rust_hnsw_should_have_nonempty_remaining_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveNonEmptyRemainingDiscarded(discardedIsEmpty != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_returning_remaining_discarded);
Datum
vector_hnsw_should_stop_returning_remaining_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopReturningRemainingDiscarded(discardedIsEmpty != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_returning_remaining_discarded);
Datum
vector_rust_hnsw_should_stop_returning_remaining_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsEmpty = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopReturningRemainingDiscarded(discardedIsEmpty != 0, true));
}

static bool
HnswShouldHaveDecreasingScanDistanceFlag(bool isDecreasingDistance, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(isDecreasingDistance);

	return isDecreasingDistance;
}

static bool
HnswShouldHaveDecreasingScanDistance(double distance, double previousDistance, bool useRust)
{
	return HnswShouldHaveDecreasingScanDistanceFlag(distance < previousDistance, useRust);
}

static bool
HnswShouldHaveStrictOutOfOrderScanMode(int iterativeScanMode, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_previous_distance_kernel(iterativeScanMode);

	return iterativeScanMode == HNSW_ITERATIVE_SCAN_STRICT;
}

static bool
HnswShouldSkipStrictOutOfOrder(int iterativeScanMode, double distance, double previousDistance, bool useRust)
{
	return HnswShouldHaveStrictOutOfOrderScanMode(iterativeScanMode, useRust) &&
		HnswShouldHaveDecreasingScanDistance(distance, previousDistance, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_skip_strict_out_of_order);
Datum
vector_hnsw_should_skip_strict_out_of_order(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);
	float8		distance = PG_GETARG_FLOAT8(1);
	float8		previousDistance = PG_GETARG_FLOAT8(2);

	PG_RETURN_BOOL(HnswShouldSkipStrictOutOfOrder(iterativeScanMode, distance, previousDistance, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_skip_strict_out_of_order);
Datum
vector_rust_hnsw_should_skip_strict_out_of_order(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);
	float8		distance = PG_GETARG_FLOAT8(1);
	float8		previousDistance = PG_GETARG_FLOAT8(2);

	PG_RETURN_BOOL(HnswShouldSkipStrictOutOfOrder(iterativeScanMode, distance, previousDistance, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_strict_out_of_order_scan_mode);
Datum
vector_hnsw_should_have_strict_out_of_order_scan_mode(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveStrictOutOfOrderScanMode(iterativeScanMode, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_strict_out_of_order_scan_mode);
Datum
vector_rust_hnsw_should_have_strict_out_of_order_scan_mode(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveStrictOutOfOrderScanMode(iterativeScanMode, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_decreasing_scan_distance);
Datum
vector_hnsw_should_have_decreasing_scan_distance(PG_FUNCTION_ARGS)
{
	float8		distance = PG_GETARG_FLOAT8(0);
	float8		previousDistance = PG_GETARG_FLOAT8(1);

	PG_RETURN_BOOL(HnswShouldHaveDecreasingScanDistance(distance, previousDistance, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_decreasing_scan_distance);
Datum
vector_rust_hnsw_should_have_decreasing_scan_distance(PG_FUNCTION_ARGS)
{
	float8		distance = PG_GETARG_FLOAT8(0);
	float8		previousDistance = PG_GETARG_FLOAT8(1);

	PG_RETURN_BOOL(HnswShouldHaveDecreasingScanDistance(distance, previousDistance, true));
}

static bool
HnswShouldStopWithoutDiscarded(bool discardedIsNull, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_stop_without_discarded_kernel(discardedIsNull);

	return discardedIsNull;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_without_discarded);
Datum
vector_hnsw_should_stop_without_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopWithoutDiscarded(discardedIsNull != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_without_discarded);
Datum
vector_rust_hnsw_should_stop_without_discarded(PG_FUNCTION_ARGS)
{
	int32		discardedIsNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopWithoutDiscarded(discardedIsNull != 0, true));
}

static bool
HnswShouldHaveIterativeScanOffMode(int iterativeScanMode, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_stop_when_iterative_scan_off_kernel(iterativeScanMode);

	return iterativeScanMode == HNSW_ITERATIVE_SCAN_OFF;
}

static bool
HnswShouldStopWhenIterativeScanOff(int iterativeScanMode, bool useRust)
{
	return HnswShouldHaveIterativeScanOffMode(iterativeScanMode, useRust);
}

static bool
HnswShouldHaveActiveIterativeScanMode(int iterativeScanMode, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_release_iterative_scan_memory_kernel(iterativeScanMode);

	return iterativeScanMode != HNSW_ITERATIVE_SCAN_OFF;
}

static bool
HnswShouldTrackScanDiscarded(int iterativeScanMode, bool useRust)
{
	return HnswShouldHaveActiveIterativeScanMode(iterativeScanMode, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_stop_when_iterative_scan_off);
Datum
vector_hnsw_should_stop_when_iterative_scan_off(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopWhenIterativeScanOff(iterativeScanMode, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_stop_when_iterative_scan_off);
Datum
vector_rust_hnsw_should_stop_when_iterative_scan_off(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldStopWhenIterativeScanOff(iterativeScanMode, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_iterative_scan_off_mode);
Datum
vector_hnsw_should_have_iterative_scan_off_mode(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveIterativeScanOffMode(iterativeScanMode, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_iterative_scan_off_mode);
Datum
vector_rust_hnsw_should_have_iterative_scan_off_mode(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveIterativeScanOffMode(iterativeScanMode, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_track_scan_discarded);
Datum
vector_hnsw_should_track_scan_discarded(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTrackScanDiscarded(iterativeScanMode, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_track_scan_discarded);
Datum
vector_rust_hnsw_should_track_scan_discarded(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldTrackScanDiscarded(iterativeScanMode, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_active_iterative_scan_mode);
Datum
vector_hnsw_should_have_active_iterative_scan_mode(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveActiveIterativeScanMode(iterativeScanMode, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_active_iterative_scan_mode);
Datum
vector_rust_hnsw_should_have_active_iterative_scan_mode(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveActiveIterativeScanMode(iterativeScanMode, true));
}

static bool
HnswShouldReachScanTupleLimitFlag(bool reachesTupleLimit, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(reachesTupleLimit);

	return reachesTupleLimit;
}

static bool
HnswShouldReachScanTupleLimit(int64 tupleCount, int64 maxScanTuples, bool useRust)
{
	return HnswShouldReachScanTupleLimitFlag(tupleCount >= maxScanTuples, useRust);
}

static bool
HnswShouldExceedScanMemoryLimitFlag(bool exceedsMemoryLimit, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(exceedsMemoryLimit);

	return exceedsMemoryLimit;
}

static bool
HnswShouldExceedScanMemoryLimit(int64 memoryUsed, int64 maxMemory, bool useRust)
{
	return HnswShouldExceedScanMemoryLimitFlag(memoryUsed > maxMemory, useRust);
}

static bool
HnswShouldLimitScanByResources(int64 tupleCount, int64 maxScanTuples, int64 memoryUsed, int64 maxMemory, bool useRust)
{
	if (useRust)
		return HnswShouldReachScanTupleLimit(tupleCount, maxScanTuples, true) ||
			HnswShouldExceedScanMemoryLimit(memoryUsed, maxMemory, true);

	return HnswShouldReachScanTupleLimit(tupleCount, maxScanTuples, false) ||
		HnswShouldExceedScanMemoryLimit(memoryUsed, maxMemory, false);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_limit_scan_by_resources);
Datum
vector_hnsw_should_limit_scan_by_resources(PG_FUNCTION_ARGS)
{
	int64		tupleCount = PG_GETARG_INT64(0);
	int64		maxScanTuples = PG_GETARG_INT64(1);
	int64		memoryUsed = PG_GETARG_INT64(2);
	int64		maxMemory = PG_GETARG_INT64(3);

	PG_RETURN_BOOL(HnswShouldLimitScanByResources(tupleCount, maxScanTuples, memoryUsed, maxMemory, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_limit_scan_by_resources);
Datum
vector_rust_hnsw_should_limit_scan_by_resources(PG_FUNCTION_ARGS)
{
	int64		tupleCount = PG_GETARG_INT64(0);
	int64		maxScanTuples = PG_GETARG_INT64(1);
	int64		memoryUsed = PG_GETARG_INT64(2);
	int64		maxMemory = PG_GETARG_INT64(3);

	PG_RETURN_BOOL(HnswShouldLimitScanByResources(tupleCount, maxScanTuples, memoryUsed, maxMemory, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reach_scan_tuple_limit);
Datum
vector_hnsw_should_reach_scan_tuple_limit(PG_FUNCTION_ARGS)
{
	int64		tupleCount = PG_GETARG_INT64(0);
	int64		maxScanTuples = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldReachScanTupleLimit(tupleCount, maxScanTuples, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reach_scan_tuple_limit);
Datum
vector_rust_hnsw_should_reach_scan_tuple_limit(PG_FUNCTION_ARGS)
{
	int64		tupleCount = PG_GETARG_INT64(0);
	int64		maxScanTuples = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldReachScanTupleLimit(tupleCount, maxScanTuples, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_exceed_scan_memory_limit);
Datum
vector_hnsw_should_exceed_scan_memory_limit(PG_FUNCTION_ARGS)
{
	int64		memoryUsed = PG_GETARG_INT64(0);
	int64		maxMemory = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldExceedScanMemoryLimit(memoryUsed, maxMemory, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_exceed_scan_memory_limit);
Datum
vector_rust_hnsw_should_exceed_scan_memory_limit(PG_FUNCTION_ARGS)
{
	int64		memoryUsed = PG_GETARG_INT64(0);
	int64		maxMemory = PG_GETARG_INT64(1);

	PG_RETURN_BOOL(HnswShouldExceedScanMemoryLimit(memoryUsed, maxMemory, true));
}

static bool
HnswShouldReleaseIterativeScanMemory(int iterativeScanMode, bool useRust)
{
	return HnswShouldHaveActiveIterativeScanMode(iterativeScanMode, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_release_iterative_scan_memory);
Datum
vector_hnsw_should_release_iterative_scan_memory(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReleaseIterativeScanMemory(iterativeScanMode, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_release_iterative_scan_memory);
Datum
vector_rust_hnsw_should_release_iterative_scan_memory(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldReleaseIterativeScanMemory(iterativeScanMode, true));
}

static bool
HnswShouldUseStrictScanMode(int iterativeScanMode, bool useRust)
{
	return HnswShouldHaveStrictOutOfOrderScanMode(iterativeScanMode, useRust);
}

static bool
HnswShouldUpdatePreviousDistance(int iterativeScanMode, bool useRust)
{
	return HnswShouldUseStrictScanMode(iterativeScanMode, useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_update_previous_distance);
Datum
vector_hnsw_should_update_previous_distance(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdatePreviousDistance(iterativeScanMode, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_update_previous_distance);
Datum
vector_rust_hnsw_should_update_previous_distance(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUpdatePreviousDistance(iterativeScanMode, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_strict_scan_mode);
Datum
vector_hnsw_should_use_strict_scan_mode(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseStrictScanMode(iterativeScanMode, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_strict_scan_mode);
Datum
vector_rust_hnsw_should_use_strict_scan_mode(PG_FUNCTION_ARGS)
{
	int32		iterativeScanMode = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseStrictScanMode(iterativeScanMode, true));
}

static bool
HnswShouldHandleEmptyWorkList(int workListLength, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_handle_empty_work_list_kernel(workListLength);

	return workListLength == 0;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_handle_empty_work_list);
Datum
vector_hnsw_should_handle_empty_work_list(PG_FUNCTION_ARGS)
{
	int32		workListLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHandleEmptyWorkList(workListLength, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_handle_empty_work_list);
Datum
vector_rust_hnsw_should_handle_empty_work_list(PG_FUNCTION_ARGS)
{
	int32		workListLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHandleEmptyWorkList(workListLength, true));
}

static bool
HnswShouldAdvanceOnExhaustedHeapTids(int heaptidsLength, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_advance_on_exhausted_heaptids_kernel(heaptidsLength);

	return heaptidsLength == 0;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_advance_on_exhausted_heaptids);
Datum
vector_hnsw_should_advance_on_exhausted_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAdvanceOnExhaustedHeapTids(heaptidsLength, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_advance_on_exhausted_heaptids);
Datum
vector_rust_hnsw_should_advance_on_exhausted_heaptids(PG_FUNCTION_ARGS)
{
	int32		heaptidsLength = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldAdvanceOnExhaustedHeapTids(heaptidsLength, true));
}

static bool
HnswShouldRejectMissingOrderBy(bool orderByIsNull, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_missing_orderby_kernel(orderByIsNull);

	return orderByIsNull;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_missing_orderby);
Datum
vector_hnsw_should_reject_missing_orderby(PG_FUNCTION_ARGS)
{
	int32		orderByIsNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectMissingOrderBy(orderByIsNull != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_missing_orderby);
Datum
vector_rust_hnsw_should_reject_missing_orderby(PG_FUNCTION_ARGS)
{
	int32		orderByIsNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectMissingOrderBy(orderByIsNull != 0, true));
}

static bool
HnswShouldRejectNonMVCCSnapshot(bool snapshotIsMVCC, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_reject_non_mvcc_snapshot_kernel(snapshotIsMVCC);

	return !snapshotIsMVCC;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_reject_non_mvcc_snapshot);
Datum
vector_hnsw_should_reject_non_mvcc_snapshot(PG_FUNCTION_ARGS)
{
	int32		snapshotIsMVCC = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectNonMVCCSnapshot(snapshotIsMVCC != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_reject_non_mvcc_snapshot);
Datum
vector_rust_hnsw_should_reject_non_mvcc_snapshot(PG_FUNCTION_ARGS)
{
	int32		snapshotIsMVCC = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldRejectNonMVCCSnapshot(snapshotIsMVCC != 0, true));
}

static bool
HnswShouldHaveScanPointerFlag(bool hasPointer, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasPointer);

	return hasPointer;
}

static bool
HnswShouldHaveScanPointer(const void *pointer, bool useRust)
{
	return HnswShouldHaveScanPointerFlag(pointer != NULL, useRust);
}

static bool
HnswShouldHaveRescanKeysFlag(bool hasKeys, bool useRust)
{
	return HnswShouldHaveScanPointerFlag(hasKeys, useRust);
}

static bool
HnswShouldHavePositiveRescanKeyCountFlag(bool hasPositiveKeyCount, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_update_progress_after_insert_kernel(hasPositiveKeyCount);

	return hasPositiveKeyCount;
}

static bool
HnswShouldHavePositiveRescanKeyCount(int keyCount, bool useRust)
{
	return HnswShouldHavePositiveRescanKeyCountFlag(keyCount > 0, useRust);
}

static bool
HnswShouldCopyRescanKeys(bool hasKeys, int keyCount, bool useRust)
{
	return HnswShouldHaveRescanKeysFlag(hasKeys, useRust) &&
		HnswShouldHavePositiveRescanKeyCount(keyCount, useRust);
}

static bool
HnswShouldUseProvidedRescanKeyArrayFlag(bool hasKeyArray, bool useRust)
{
	return HnswShouldHaveScanPointerFlag(hasKeyArray, useRust);
}

static bool
HnswShouldUseProvidedRescanKeyArray(ScanKey keys, bool useRust)
{
	return HnswShouldHaveScanPointer((const void *) keys, useRust);
}

static bool
HnswShouldUseProvidedOrderByDataFlag(bool hasOrderByData, bool useRust)
{
	return HnswShouldHaveScanPointerFlag(hasOrderByData, useRust);
}

static bool
HnswShouldUseProvidedOrderByData(ScanKey orderByData, bool useRust)
{
	return HnswShouldHaveScanPointer((const void *) orderByData, useRust);
}

static bool
HnswShouldUseScanNormprocFlag(bool hasNormproc, bool useRust)
{
	return HnswShouldHaveScanPointerFlag(hasNormproc, useRust);
}

static bool
HnswShouldUseScanNormproc(void *normprocinfo, bool useRust)
{
	return HnswShouldHaveScanPointer((const void *) normprocinfo, useRust);
}

static bool
HnswShouldUseEntrypointForScanFlag(bool hasEntryPoint, bool useRust)
{
	return HnswShouldHaveScanPointerFlag(hasEntryPoint, useRust);
}

static bool
HnswShouldUseEntrypointForScan(HnswElement entryPoint, bool useRust)
{
	return HnswShouldHaveScanPointer((const void *) entryPoint, useRust);
}

static bool
HnswShouldUseScanInstrumentFlag(bool hasInstrument, bool useRust)
{
	return HnswShouldHaveScanPointerFlag(hasInstrument, useRust);
}

#if PG_VERSION_NUM >= 180000
static bool
HnswShouldUseScanInstrument(void *instrument, bool useRust)
{
	return HnswShouldHaveScanPointer((const void *) instrument, useRust);
}
#endif

static bool
HnswShouldDiscardedHeapMissingFlag(bool hasDiscardedHeap, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_skip_invalid_index_value_kernel(hasDiscardedHeap);

	return !hasDiscardedHeap;
}

static bool
HnswShouldDiscardedHeapMissing(pairingheap * discarded, bool useRust)
{
	return HnswShouldDiscardedHeapMissingFlag(HnswShouldHaveScanPointer((const void *) discarded, useRust), useRust);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_copy_rescan_keys);
Datum
vector_hnsw_should_copy_rescan_keys(PG_FUNCTION_ARGS)
{
	int32		hasKeys = PG_GETARG_INT32(0);
	int32		keyCount = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldCopyRescanKeys(hasKeys != 0, keyCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_copy_rescan_keys);
Datum
vector_rust_hnsw_should_copy_rescan_keys(PG_FUNCTION_ARGS)
{
	int32		hasKeys = PG_GETARG_INT32(0);
	int32		keyCount = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(HnswShouldCopyRescanKeys(hasKeys != 0, keyCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_rescan_keys);
Datum
vector_hnsw_should_have_rescan_keys(PG_FUNCTION_ARGS)
{
	int32		hasKeys = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveRescanKeysFlag(hasKeys != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_rescan_keys);
Datum
vector_rust_hnsw_should_have_rescan_keys(PG_FUNCTION_ARGS)
{
	int32		hasKeys = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveRescanKeysFlag(hasKeys != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_positive_rescan_key_count);
Datum
vector_hnsw_should_have_positive_rescan_key_count(PG_FUNCTION_ARGS)
{
	int32		keyCount = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHavePositiveRescanKeyCount(keyCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_positive_rescan_key_count);
Datum
vector_rust_hnsw_should_have_positive_rescan_key_count(PG_FUNCTION_ARGS)
{
	int32		keyCount = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHavePositiveRescanKeyCount(keyCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_provided_rescan_key_array);
Datum
vector_hnsw_should_use_provided_rescan_key_array(PG_FUNCTION_ARGS)
{
	int32		hasKeyArray = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseProvidedRescanKeyArrayFlag(hasKeyArray != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_provided_rescan_key_array);
Datum
vector_rust_hnsw_should_use_provided_rescan_key_array(PG_FUNCTION_ARGS)
{
	int32		hasKeyArray = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseProvidedRescanKeyArrayFlag(hasKeyArray != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_have_scan_pointer);
Datum
vector_hnsw_should_have_scan_pointer(PG_FUNCTION_ARGS)
{
	int32		hasPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveScanPointerFlag(hasPointer != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_have_scan_pointer);
Datum
vector_rust_hnsw_should_have_scan_pointer(PG_FUNCTION_ARGS)
{
	int32		hasPointer = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldHaveScanPointerFlag(hasPointer != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_provided_orderby_data);
Datum
vector_hnsw_should_use_provided_orderby_data(PG_FUNCTION_ARGS)
{
	int32		hasOrderByData = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseProvidedOrderByDataFlag(hasOrderByData != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_provided_orderby_data);
Datum
vector_rust_hnsw_should_use_provided_orderby_data(PG_FUNCTION_ARGS)
{
	int32		hasOrderByData = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseProvidedOrderByDataFlag(hasOrderByData != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_entrypoint_for_scan);
Datum
vector_hnsw_should_use_entrypoint_for_scan(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseEntrypointForScanFlag(hasEntryPoint != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_entrypoint_for_scan);
Datum
vector_rust_hnsw_should_use_entrypoint_for_scan(PG_FUNCTION_ARGS)
{
	int32		hasEntryPoint = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseEntrypointForScanFlag(hasEntryPoint != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_discarded_heap_missing);
Datum
vector_hnsw_should_discarded_heap_missing(PG_FUNCTION_ARGS)
{
	int32		hasDiscardedHeap = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldDiscardedHeapMissingFlag(hasDiscardedHeap != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_discarded_heap_missing);
Datum
vector_rust_hnsw_should_discarded_heap_missing(PG_FUNCTION_ARGS)
{
	int32		hasDiscardedHeap = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldDiscardedHeapMissingFlag(hasDiscardedHeap != 0, true));
}

static bool
HnswShouldUseNullScanValue(bool orderByIsNull, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_use_null_scan_value_kernel(orderByIsNull);

	return orderByIsNull;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_null_scan_value);
Datum
vector_hnsw_should_use_null_scan_value(PG_FUNCTION_ARGS)
{
	int32		orderByIsNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNullScanValue(orderByIsNull != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_null_scan_value);
Datum
vector_rust_hnsw_should_use_null_scan_value(PG_FUNCTION_ARGS)
{
	int32		orderByIsNull = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseNullScanValue(orderByIsNull != 0, true));
}

static bool
HnswShouldNormalizeScanValue(bool hasNormproc, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_normalize_scan_value_kernel(hasNormproc);

	return hasNormproc;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_normalize_scan_value);
Datum
vector_hnsw_should_normalize_scan_value(PG_FUNCTION_ARGS)
{
	int32		hasNormproc = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldNormalizeScanValue(hasNormproc != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_normalize_scan_value);
Datum
vector_rust_hnsw_should_normalize_scan_value(PG_FUNCTION_ARGS)
{
	int32		hasNormproc = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldNormalizeScanValue(hasNormproc != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_scan_normproc);
Datum
vector_hnsw_should_use_scan_normproc(PG_FUNCTION_ARGS)
{
	int32		hasNormproc = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseScanNormprocFlag(hasNormproc != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_scan_normproc);
Datum
vector_rust_hnsw_should_use_scan_normproc(PG_FUNCTION_ARGS)
{
	int32		hasNormproc = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseScanNormprocFlag(hasNormproc != 0, true));
}

static bool
HnswShouldInitializeScanState(bool isFirstScan, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_initialize_scan_state_kernel(isFirstScan);

	return isFirstScan;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_initialize_scan_state);
Datum
vector_hnsw_should_initialize_scan_state(PG_FUNCTION_ARGS)
{
	int32		isFirstScan = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeScanState(isFirstScan != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_initialize_scan_state);
Datum
vector_rust_hnsw_should_initialize_scan_state(PG_FUNCTION_ARGS)
{
	int32		isFirstScan = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldInitializeScanState(isFirstScan != 0, true));
}

static bool
HnswShouldIncrementInstrumentSearches(bool hasInstrument, bool useRust)
{
	if (useRust)
		return vector_rust_hnsw_should_increment_instrument_searches_kernel(hasInstrument);

	return hasInstrument;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_increment_instrument_searches);
Datum
vector_hnsw_should_increment_instrument_searches(PG_FUNCTION_ARGS)
{
	int32		hasInstrument = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldIncrementInstrumentSearches(hasInstrument != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_increment_instrument_searches);
Datum
vector_rust_hnsw_should_increment_instrument_searches(PG_FUNCTION_ARGS)
{
	int32		hasInstrument = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldIncrementInstrumentSearches(hasInstrument != 0, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_hnsw_should_use_scan_instrument);
Datum
vector_hnsw_should_use_scan_instrument(PG_FUNCTION_ARGS)
{
	int32		hasInstrument = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseScanInstrumentFlag(hasInstrument != 0, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_hnsw_should_use_scan_instrument);
Datum
vector_rust_hnsw_should_use_scan_instrument(PG_FUNCTION_ARGS)
{
	int32		hasInstrument = PG_GETARG_INT32(0);

	PG_RETURN_BOOL(HnswShouldUseScanInstrumentFlag(hasInstrument != 0, true));
}

/*
 * Algorithm 5 from paper
 */
static List *
GetScanItems(IndexScanDesc scan, Datum value)
{
	HnswScanOpaque so = (HnswScanOpaque) scan->opaque;
	Relation	index = scan->indexRelation;
	HnswSupport *support = &so->support;
	List	   *ep;
	List	   *w;
	int			m;
	HnswElement entryPoint;
	char	   *base = NULL;
	HnswQuery  *q = &so->q;
	pairingheap **discarded = NULL;

	/* Get m and entry point */
	HnswGetMetaPageInfo(index, &m, &entryPoint);

	q->value = value;
	so->m = m;

	if (HnswShouldReturnEmptyWithoutEntryPoint(!HnswShouldUseEntrypointForScan(entryPoint, true), true))
		return NIL;

	ep = list_make1(HnswEntryCandidate(base, entryPoint, q, index, support, false));

	for (int lc = entryPoint->level; lc >= 1; lc--)
	{
		w = HnswSearchLayer(base, q, ep, 1, lc, index, support, m, false, NULL, NULL, NULL, true, NULL);
		ep = w;
	}

	if (HnswShouldTrackScanDiscarded(hnsw_iterative_scan, true))
		discarded = &so->discarded;

	return HnswSearchLayer(base, q, ep, hnsw_ef_search, 0, index, support, m, false, NULL, &so->v, discarded, true, &so->tuples);
}

/*
 * Resume scan at ground level with discarded candidates
 */
static List *
ResumeScanItems(IndexScanDesc scan)
{
	HnswScanOpaque so = (HnswScanOpaque) scan->opaque;
	Relation	index = scan->indexRelation;
	List	   *ep = NIL;
	char	   *base = NULL;
	int			batch_size = hnsw_ef_search;

	if (HnswShouldStopResumeFromDiscarded(pairingheap_is_empty(so->discarded), true))
		return NIL;

	/* Get next batch of candidates */
	for (int i = 0; i < batch_size; i++)
	{
		HnswSearchCandidate *sc;

		if (HnswShouldStopResumeFromDiscarded(pairingheap_is_empty(so->discarded), true))
			break;

		sc = HnswGetSearchCandidate(w_node, pairingheap_remove_first(so->discarded));

		ep = lappend(ep, sc);
	}

	return HnswSearchLayer(base, &so->q, ep, batch_size, 0, index, &so->support, so->m, false, NULL, &so->v, &so->discarded, false, &so->tuples);
}

/*
 * Get scan value
 */
static Datum
GetScanValue(IndexScanDesc scan)
{
	HnswScanOpaque so = (HnswScanOpaque) scan->opaque;
	Datum		value;

	if (HnswShouldUseNullScanValue((scan->orderByData->sk_flags & SK_ISNULL) != 0, true))
		value = PointerGetDatum(NULL);
	else
	{
		value = scan->orderByData->sk_argument;

		/* Value should not be compressed or toasted */
		Assert(!VARATT_IS_COMPRESSED(DatumGetPointer(value)));
		Assert(!VARATT_IS_EXTENDED(DatumGetPointer(value)));

		/* Normalize if needed */
		if (HnswShouldNormalizeScanValue(HnswShouldUseScanNormproc(so->support.normprocinfo, true), true))
			value = HnswNormValue(so->typeInfo, so->support.collation, value);
	}

	return value;
}

#if defined(HNSW_MEMORY)
/*
 * Show memory usage
 */
static void
ShowMemoryUsage(HnswScanOpaque so)
{
	elog(INFO, "memory: %zu KB, tuples: " INT64_FORMAT, MemoryContextMemAllocated(so->tmpCtx, false) / 1024, so->tuples);
}
#endif

/*
 * Prepare for an index scan
 */
IndexScanDesc
hnswbeginscan(Relation index, int nkeys, int norderbys)
{
	IndexScanDesc scan;
	HnswScanOpaque so;
	double		maxMemory;

	scan = RelationGetIndexScan(index, nkeys, norderbys);

	so = (HnswScanOpaque) palloc(sizeof(HnswScanOpaqueData));
	so->typeInfo = HnswGetTypeInfo(index);

	/* Set support functions */
	HnswInitSupport(&so->support, index);

	/*
	 * Use a lower max allocation size than default to allow scanning more
	 * tuples for iterative search before exceeding work_mem
	 */
	so->tmpCtx = AllocSetContextCreate(CurrentMemoryContext,
									   "Hnsw scan temporary context",
									   0, 8 * 1024, 256 * 1024);

	/* Calculate max memory */
	/* Add 256 extra bytes to fill last block when close */
	maxMemory = (double) work_mem * hnsw_scan_mem_multiplier * 1024.0 + 256;
	so->maxMemory = Min(maxMemory, (double) SIZE_MAX);

	scan->opaque = so;

	return scan;
}

/*
 * Start or restart an index scan
 */
void
hnswrescan(IndexScanDesc scan, ScanKey keys, int nkeys, ScanKey orderbys, int norderbys)
{
	HnswScanOpaque so = (HnswScanOpaque) scan->opaque;
	bool		hasKeys;
	bool		hasOrderBys;

	so->first = true;
	/* v and discarded are allocated in tmpCtx */
	so->v.tids = NULL;
	so->discarded = NULL;
	so->tuples = 0;
	so->previousDistance = -get_float8_infinity();
	MemoryContextReset(so->tmpCtx);
	hasKeys = HnswShouldUseProvidedRescanKeyArray(keys, true);
	hasOrderBys = HnswShouldUseProvidedOrderByData(orderbys, true);

	if (HnswShouldCopyRescanKeys(hasKeys, scan->numberOfKeys, true))
		memmove(scan->keyData, keys, scan->numberOfKeys * sizeof(ScanKeyData));

	if (HnswShouldCopyRescanKeys(hasOrderBys, scan->numberOfOrderBys, true))
		memmove(scan->orderByData, orderbys, scan->numberOfOrderBys * sizeof(ScanKeyData));
}

/*
 * Fetch the next tuple in the given scan
 */
bool
hnswgettuple(IndexScanDesc scan, ScanDirection dir)
{
	HnswScanOpaque so = (HnswScanOpaque) scan->opaque;
	MemoryContext oldCtx = MemoryContextSwitchTo(so->tmpCtx);

	/*
	 * Index can be used to scan backward, but Postgres doesn't support
	 * backward scan on operators
	 */
	Assert(ScanDirectionIsForward(dir));

	if (HnswShouldInitializeScanState(so->first, true))
	{
		Datum		value;
		bool		hasOrderByData;

		/* Count index scan for stats */
		pgstat_count_index_scan(scan->indexRelation);
#if PG_VERSION_NUM >= 180000
		bool		hasInstrument = HnswShouldUseScanInstrument(scan->instrument, true);

		if (HnswShouldIncrementInstrumentSearches(hasInstrument, true))
			scan->instrument->nsearches++;
#endif

		/* Safety check */
		hasOrderByData = HnswShouldUseProvidedOrderByData(scan->orderByData, true);
		if (HnswShouldRejectMissingOrderBy(!hasOrderByData, true))
			elog(ERROR, "cannot scan hnsw index without order");

		/* Requires MVCC-compliant snapshot as not able to maintain a pin */
		/* https://www.postgresql.org/docs/current/index-locking.html */
		if (HnswShouldRejectNonMVCCSnapshot(IsMVCCSnapshot(scan->xs_snapshot), true))
			elog(ERROR, "non-MVCC snapshots are not supported with hnsw");

		/* Get scan value */
		value = GetScanValue(scan);

		/*
		 * Get a shared lock. This allows vacuum to ensure no in-flight scans
		 * before marking tuples as deleted.
		 */
		LockPage(scan->indexRelation, HNSW_SCAN_LOCK, ShareLock);

		so->w = GetScanItems(scan, value);

		/* Release shared lock */
		UnlockPage(scan->indexRelation, HNSW_SCAN_LOCK, ShareLock);

		so->first = false;

#if defined(HNSW_MEMORY)
		ShowMemoryUsage(so);
#endif
	}

	for (;;)
	{
		char	   *base = NULL;
		HnswSearchCandidate *sc;
		HnswElement element;
		ItemPointer heaptid;

		if (HnswShouldHandleEmptyWorkList(list_length(so->w), true))
		{
			if (HnswShouldStopWhenIterativeScanOff(hnsw_iterative_scan, true))
				break;

			/* Empty index */
			if (HnswShouldStopWithoutDiscarded(HnswShouldDiscardedHeapMissing(so->discarded, true), true))
				break;

			/* Reached max number of tuples or memory limit */
			if (HnswShouldLimitScanByResources(so->tuples, (int64) hnsw_max_scan_tuples, (int64) MemoryContextMemAllocated(so->tmpCtx, false), (int64) so->maxMemory, true))
			{
				if (HnswShouldStopReturningRemainingDiscarded(pairingheap_is_empty(so->discarded), true))
					break;

				/* Return remaining tuples */
				so->w = lappend(so->w, HnswGetSearchCandidate(w_node, pairingheap_remove_first(so->discarded)));
			}
			else
			{
				/*
				 * Locking ensures when neighbors are read, the elements they
				 * reference will not be deleted (and replaced) during the
				 * iteration.
				 *
				 * Elements loaded into memory on previous iterations may have
				 * been deleted (and replaced), so when reading neighbors, the
				 * element version must be checked.
				 */
				LockPage(scan->indexRelation, HNSW_SCAN_LOCK, ShareLock);

				so->w = ResumeScanItems(scan);

				UnlockPage(scan->indexRelation, HNSW_SCAN_LOCK, ShareLock);

#if defined(HNSW_MEMORY)
				ShowMemoryUsage(so);
#endif
			}

			if (HnswShouldHandleEmptyWorkList(list_length(so->w), true))
				break;
		}

		sc = llast(so->w);
		element = HnswPtrAccess(base, sc->element);

		/* Move to next element if no valid heap TIDs */
		if (HnswShouldAdvanceOnExhaustedHeapTids(element->heaptidsLength, true))
		{
			so->w = list_delete_last(so->w);

			/* Mark memory as free for next iteration */
			if (HnswShouldReleaseIterativeScanMemory(hnsw_iterative_scan, true))
			{
				pfree(element);
				pfree(sc);
			}

			continue;
		}

		heaptid = &element->heaptids[--element->heaptidsLength];

		if (HnswShouldSkipStrictOutOfOrder(hnsw_iterative_scan, sc->distance, so->previousDistance, true))
			continue;

		if (HnswShouldUpdatePreviousDistance(hnsw_iterative_scan, true))
		{
			so->previousDistance = sc->distance;
		}

		MemoryContextSwitchTo(oldCtx);

		scan->xs_heaptid = *heaptid;
		scan->xs_recheck = false;
		scan->xs_recheckorderby = false;
		return true;
	}

	MemoryContextSwitchTo(oldCtx);
	return false;
}

/*
 * End a scan and release resources
 */
void
hnswendscan(IndexScanDesc scan)
{
	HnswScanOpaque so = (HnswScanOpaque) scan->opaque;

	MemoryContextDelete(so->tmpCtx);

	pfree(so);
	scan->opaque = NULL;
}
