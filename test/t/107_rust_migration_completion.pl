use strict;
use warnings FATAL => 'all';
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Test::More;

my $repo_root = abs_path(dirname(__FILE__) . "/../..");
my $hnsw_path = "$repo_root/src/hnsw.c";
my $hnsw_scan_path = "$repo_root/src/hnswscan.c";
my $hnsw_build_path = "$repo_root/src/hnswbuild.c";
my $hnsw_insert_path = "$repo_root/src/hnswinsert.c";
my $hnsw_vacuum_path = "$repo_root/src/hnswvacuum.c";
my $hnsw_utils_path = "$repo_root/src/hnswutils.c";
my $ivf_vacuum_path = "$repo_root/src/ivfvacuum.c";

open(my $fh, '<', $hnsw_path) or die "could not open $hnsw_path: $!";
local $/ = undef;
my $hnsw_c = <$fh>;
close($fh);

open(my $scan_fh, '<', $hnsw_scan_path) or die "could not open $hnsw_scan_path: $!";
my $hnsw_scan_c = <$scan_fh>;
close($scan_fh);

open(my $build_fh, '<', $hnsw_build_path) or die "could not open $hnsw_build_path: $!";
my $hnsw_build_c = <$build_fh>;
close($build_fh);

open(my $insert_fh, '<', $hnsw_insert_path) or die "could not open $hnsw_insert_path: $!";
my $hnsw_insert_c = <$insert_fh>;
close($insert_fh);

open(my $vacuum_fh, '<', $hnsw_vacuum_path) or die "could not open $hnsw_vacuum_path: $!";
my $hnsw_vacuum_c = <$vacuum_fh>;
close($vacuum_fh);

open(my $utils_fh, '<', $hnsw_utils_path) or die "could not open $hnsw_utils_path: $!";
my $hnsw_utils_c = <$utils_fh>;
close($utils_fh);

open(my $ivf_vacuum_fh, '<', $ivf_vacuum_path) or die "could not open $ivf_vacuum_path: $!";
my $ivf_vacuum_c = <$ivf_vacuum_fh>;
close($ivf_vacuum_fh);

ok($hnsw_c =~ /vector_rust_hnsw_should_disable_without_order_kernel\(/,
	"hnsw.c uses rust disable-without-order kernel");
ok($hnsw_c =~ /vector_rust_hnsw_clamp_ratio_kernel\(/,
	"hnsw.c uses rust clamp-ratio kernel");
ok($hnsw_c =~ /vector_rust_hnsw_should_adjust_startup_cost_kernel\(/,
	"hnsw.c uses rust startup-cost kernel");
ok($hnsw_c =~ /vector_rust_hnsw_should_compute_scan_ratio_from_tuples_kernel\(/,
	"hnsw.c uses rust scan-ratio kernel");

unlike($hnsw_c, qr/return !preloadInProgress;/,
	"legacy C preload lock-tranche fallback removed");
unlike($hnsw_c, qr/return !found;/,
	"legacy C lock-tranche assignment fallback removed");
unlike($hnsw_c, qr/return orderbyCount == 0;/,
	"legacy C disable-without-order fallback removed");
unlike($hnsw_c, qr/return ratio > 1;/,
	"legacy C cap-ratio fallback removed");
unlike($hnsw_c, qr/return startupPages > relPages && ratio < 0.5;/,
	"legacy C startup-cost fallback removed");
unlike($hnsw_c, qr/return tupleCount > 0;/,
	"legacy C scan-ratio fallback removed");

ok($hnsw_scan_c =~ /vector_rust_hnsw_should_return_empty_without_entrypoint_kernel\(/,
	"hnswscan.c uses rust empty-entrypoint kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_resume_from_discarded_kernel\(/,
	"hnswscan.c uses rust resume-discarded kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_return_remaining_discarded_kernel\(/,
	"hnswscan.c uses rust remaining-discarded kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_advance_on_exhausted_heaptids_kernel\(/,
	"hnswscan.c uses rust exhausted-heaptids kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_reject_missing_orderby_kernel\(/,
	"hnswscan.c uses rust missing-orderby kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_reject_non_mvcc_snapshot_kernel\(/,
	"hnswscan.c uses rust non-mvcc kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_update_previous_distance_kernel\(/,
	"hnswscan.c uses rust update-previous-distance kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_stop_without_discarded_kernel\(/,
	"hnswscan.c uses rust stop-without-discarded kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_stop_when_iterative_scan_off_kernel\(/,
	"hnswscan.c uses rust stop-iterative-scan-off kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_release_iterative_scan_memory_kernel\(/,
	"hnswscan.c uses rust release-iterative-scan-memory kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_handle_empty_work_list_kernel\(/,
	"hnswscan.c uses rust empty-work-list kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_use_null_scan_value_kernel\(/,
	"hnswscan.c uses rust null-scan-value kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_normalize_scan_value_kernel\(/,
	"hnswscan.c uses rust normalize-scan-value kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_initialize_scan_state_kernel\(/,
	"hnswscan.c uses rust initialize-scan-state kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_increment_instrument_searches_kernel\(/,
	"hnswscan.c uses rust increment-instrument-searches kernel");

unlike($hnsw_scan_c, qr/return entryPointIsNull;/,
	"legacy C entrypoint-null fallback removed");
unlike($hnsw_scan_c, qr/return HnswShouldHaveNonEmptyResumeDiscardedFlag\(!discardedIsEmpty, false\);/,
	"legacy C resume-discarded fallback removed");
unlike($hnsw_scan_c, qr/return HnswShouldHaveNonEmptyRemainingDiscardedFlag\(!discardedIsEmpty, false\);/,
	"legacy C remaining-discarded fallback removed");
unlike($hnsw_scan_c, qr/return heaptidsLength == 0;/,
	"legacy C exhausted-heaptids fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveMissingOrderBy\(bool orderByIsNull, bool useRust\)\s*\{[^}]*return orderByIsNull;/s,
	"legacy C missing-orderby fallback removed");
unlike($hnsw_scan_c, qr/return !snapshotIsMVCC;/,
	"legacy C non-mvcc fallback removed");
unlike($hnsw_scan_c, qr/return hasPointer;/,
	"legacy C scan-pointer fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveDecreasingScanDistanceFlag\(bool isDecreasingDistance, bool useRust\)\s*\{[^}]*return isDecreasingDistance;/s,
	"legacy C decreasing-scan-distance-flag fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveStrictOutOfOrderScanMode\(int iterativeScanMode, bool useRust\)\s*\{[^}]*return iterativeScanMode == HNSW_ITERATIVE_SCAN_STRICT;/s,
	"legacy C strict-out-of-order-scan-mode fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldStopWithoutDiscarded\(bool discardedIsNull, bool useRust\)\s*\{[^}]*return discardedIsNull;/s,
	"legacy C stop-without-discarded fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveIterativeScanOffMode\(int iterativeScanMode, bool useRust\)\s*\{[^}]*return iterativeScanMode == HNSW_ITERATIVE_SCAN_OFF;/s,
	"legacy C iterative-scan-off-mode fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveActiveIterativeScanMode\(int iterativeScanMode, bool useRust\)\s*\{[^}]*return iterativeScanMode != HNSW_ITERATIVE_SCAN_OFF;/s,
	"legacy C active-iterative-scan-mode fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldReachScanTupleLimitFlag\(bool reachesTupleLimit, bool useRust\)\s*\{[^}]*return reachesTupleLimit;/s,
	"legacy C reach-scan-tuple-limit-flag fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldExceedScanMemoryLimitFlag\(bool exceedsMemoryLimit, bool useRust\)\s*\{[^}]*return exceedsMemoryLimit;/s,
	"legacy C exceed-scan-memory-limit-flag fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldLimitScanByResources\(int64 tupleCount, int64 maxScanTuples, int64 memoryUsed, int64 maxMemory, bool useRust\)\s*\{[^}]*return HnswShouldReachScanTupleLimit\(tupleCount, maxScanTuples, false\) \|\|[^}]*HnswShouldExceedScanMemoryLimit\(memoryUsed, maxMemory, false\);/s,
	"legacy C limit-scan-by-resources fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveEmptyWorkList\(int workListLength, bool useRust\)\s*\{[^}]*return workListLength == 0;/s,
	"legacy C empty-work-list fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHavePositiveRescanKeyCountFlag\(bool hasPositiveKeyCount, bool useRust\)\s*\{[^}]*return hasPositiveKeyCount;/s,
	"legacy C positive-rescan-key-count-flag fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveMissingDiscardedHeap\(bool hasDiscardedHeap, bool useRust\)\s*\{[^}]*return !hasDiscardedHeap;/s,
	"legacy C missing-discarded-heap fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveNullScanValue\(bool orderByIsNull, bool useRust\)\s*\{[^}]*return orderByIsNull;/s,
	"legacy C null-scan-value fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveNormalizedScanValue\(bool hasNormproc, bool useRust\)\s*\{[^}]*return hasNormproc;/s,
	"legacy C normalized-scan-value fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveInitialScanState\(bool isFirstScan, bool useRust\)\s*\{[^}]*return isFirstScan;/s,
	"legacy C initial-scan-state fallback removed");
unlike($hnsw_scan_c, qr/HnswShouldHaveInstrumentSearches\(bool hasInstrument, bool useRust\)\s*\{[^}]*return hasInstrument;/s,
	"legacy C instrument-searches fallback removed");

ok($hnsw_build_c =~ /vector_rust_hnsw_can_add_duplicate_heap_tid_kernel\(/,
	"hnswbuild.c uses rust duplicate-heaptid kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_stop_duplicate_search_on_value_mismatch_kernel\(/,
	"hnswbuild.c uses rust duplicate-search-stop kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_flush_graph_kernel\(/,
	"hnswbuild.c uses rust flush-graph kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_skip_invalid_index_value_kernel\(/,
	"hnswbuild.c uses rust invalid-index-value kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_update_entry_point_kernel\(/,
	"hnswbuild.c uses rust update-entrypoint kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_update_progress_after_insert_kernel\(/,
	"hnswbuild.c uses rust progress-update kernel");

unlike($hnsw_build_c, qr/return heaptidsLength < maxHeaptids;/,
	"legacy C duplicate-heaptid fallback removed");
unlike($hnsw_build_c, qr/return !valuesEqual;/,
	"legacy C duplicate-search-stop fallback removed");
unlike($hnsw_build_c, qr/return memoryUsed >= memoryTotal;/,
	"legacy C flush-graph fallback removed");
unlike($hnsw_build_c, qr/return !indexValueFormed;/,
	"legacy C invalid-index-value fallback removed");
unlike($hnsw_build_c, qr/return elementLevel > entryLevel;/,
	"legacy C higher-entrypoint-level fallback removed");
unlike($hnsw_build_c, qr/return !hasEntryPoint;/,
	"legacy C default-entrylevel fallback removed");
unlike($hnsw_build_c, qr/return hasPointer;/,
	"legacy C build-pointer fallback removed");

ok($hnsw_build_c =~ /vector_rust_hnsw_should_begin_parallel_build_kernel\(/,
	"hnswbuild.c uses rust begin-parallel-build kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_skip_parallel_workers_kernel\(/,
	"hnswbuild.c uses rust skip-parallel-workers kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_use_relation_parallel_workers_kernel\(/,
	"hnswbuild.c uses rust relation-parallel-workers kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_fallback_without_workers_kernel\(/,
	"hnswbuild.c uses rust fallback-without-workers kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_fallback_without_dsm_segment_kernel\(/,
	"hnswbuild.c uses rust fallback-without-dsm kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_use_non_concurrent_lock_modes_kernel\(/,
	"hnswbuild.c uses rust non-concurrent-lock-mode kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_use_non_concurrent_snapshot_kernel\(/,
	"hnswbuild.c uses rust non-concurrent-snapshot kernel");

unlike($hnsw_build_c, qr/return parallelWorkers > 0;/,
	"legacy C begin-parallel-build fallback removed");
unlike($hnsw_build_c, qr/return parallelWorkers == 0;/,
	"legacy C skip-parallel-workers fallback removed");
unlike($hnsw_build_c, qr/return parallelWorkers != -1;/,
	"legacy C relation-parallel-workers fallback removed");
unlike($hnsw_build_c, qr/return workersLaunched == 0;/,
	"legacy C fallback-without-workers branch removed");
unlike($hnsw_build_c, qr/return !hasDsmSegment;/,
	"legacy C fallback-without-dsm branch removed");
unlike($hnsw_build_c, qr/HnswShouldHaveNonConcurrentLockModes\(bool isConcurrent, bool useRust\)\s*\{[^}]*return !isConcurrent;/s,
	"legacy C non-concurrent-lock-mode fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveNonConcurrentSnapshot\(bool isConcurrent, bool useRust\)\s*\{[^}]*return !isConcurrent;/s,
	"legacy C non-concurrent-snapshot fallback removed");

ok($hnsw_build_c =~ /vector_rust_hnsw_should_return_after_duplicate_insert_kernel\(/,
	"hnswbuild.c uses rust duplicate-insert-return kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_skip_update_graph_for_duplicate_kernel\(/,
	"hnswbuild.c uses rust duplicate-update-skip kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_use_ondisk_phase_kernel\(/,
	"hnswbuild.c uses rust ondisk-phase kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_flush_pages_in_build_kernel\(/,
	"hnswbuild.c uses rust flush-pages-in-build kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_flush_graph_pages_at_end_kernel\(/,
	"hnswbuild.c uses rust flush-graph-pages-at-end kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_end_parallel_build_kernel\(/,
	"hnswbuild.c uses rust end-parallel-build kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_scan_heap_for_build_kernel\(/,
	"hnswbuild.c uses rust scan-heap-for-build kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_use_parallel_heap_scan_kernel\(/,
	"hnswbuild.c uses rust parallel-heap-scan kernel");

unlike($hnsw_build_c, qr/return duplicateInserted;/,
	"legacy C duplicate-insert-return fallback removed");
unlike($hnsw_build_c, qr/return duplicateFound;/,
	"legacy C duplicate-update-skip fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveOnDiskPhase\(bool graphFlushed, bool useRust\)\s*\{[^}]*return graphFlushed;/s,
	"legacy C ondisk-phase fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveFlushPagesInBuild\(bool graphFlushed, bool useRust\)\s*\{[^}]*return !graphFlushed;/s,
	"legacy C flush-pages-in-build fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveFlushGraphPagesAtEnd\(bool graphFlushed, bool useRust\)\s*\{[^}]*return !graphFlushed;/s,
	"legacy C flush-graph-pages-at-end fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveEndParallelBuild\(bool hasLeader, bool useRust\)\s*\{[^}]*return hasLeader;/s,
	"legacy C end-parallel-build fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveScanHeapForBuild\(bool hasHeap, bool useRust\)\s*\{[^}]*return hasHeap;/s,
	"legacy C scan-heap-for-build fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveParallelHeapScan\(bool hasLeader, bool useRust\)\s*\{[^}]*return hasLeader;/s,
	"legacy C parallel-heap-scan fallback removed");

ok($hnsw_build_c =~ /vector_rust_hnsw_should_leader_participate_kernel\(/,
	"hnswbuild.c uses rust leader-participate kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_use_debug_query_string_kernel\(/,
	"hnswbuild.c uses rust debug-query-string kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_finish_parallel_heap_scan_kernel\(/,
	"hnswbuild.c uses rust finish-parallel-heap-scan kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_unregister_mvcc_snapshot_kernel\(/,
	"hnswbuild.c uses rust unregister-mvcc kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_reserve_graph_memory_kernel\(/,
	"hnswbuild.c uses rust reserve-graph-memory kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_log_leader_progress_kernel\(/,
	"hnswbuild.c uses rust log-leader-progress kernel");

unlike($hnsw_build_c, qr/HnswShouldHaveLeaderParticipate\(bool leaderParticipates, bool useRust\)\s*\{[^}]*return leaderParticipates;/s,
	"legacy C leader-participate fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveDebugQueryStringFlag\(bool hasDebugQueryString, bool useRust\)\s*\{[^}]*return hasDebugQueryString;/s,
	"legacy C debug-query-string fallback removed");
unlike($hnsw_build_c, qr/return participantsDone == participantCount;/,
	"legacy C finish-parallel-heap-scan fallback removed");
unlike($hnsw_build_c, qr/return snapshotIsMVCC;/,
	"legacy C unregister-mvcc fallback removed");
unlike($hnsw_build_c, qr/return estHnswArea > estOther;/,
	"legacy C reserve-graph-memory fallback removed");
unlike($hnsw_build_c, qr/return progressIsLeader;/,
	"legacy C log-leader-progress fallback removed");

ok($hnsw_build_c =~ /vector_rust_hnsw_should_reject_varbit_type_kernel\(/,
	"hnswbuild.c uses rust reject-varbit kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_reject_missing_dimensions_kernel\(/,
	"hnswbuild.c uses rust reject-missing-dimensions kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_reject_excess_dimensions_kernel\(/,
	"hnswbuild.c uses rust reject-excess-dimensions kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_reject_low_ef_construction_kernel\(/,
	"hnswbuild.c uses rust reject-low-ef-construction kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_match_neighbor_connection_kernel\(/,
	"hnswbuild.c uses rust treat-fork-as-init kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_write_wal_page_kernel\(/,
	"hnswbuild.c uses rust write-wal-page kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_skip_null_build_tuple_kernel\(/,
	"hnswbuild.c uses rust skip-null-build-tuple kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_update_progress_after_insert_kernel\(/,
	"hnswbuild.c uses rust update-progress-after-insert kernel");

unlike($hnsw_build_c, qr/HnswShouldHaveRejectVarbitType\(Oid typeOid, bool useRust\)\s*\{[^}]*return typeOid == VARBITOID;/s,
	"legacy C reject-varbit fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveRejectMissingDimensions\(int32 dimensions, bool useRust\)\s*\{[^}]*return dimensions < 0;/s,
	"legacy C reject-missing-dimensions fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveRejectExcessDimensions\(int32 dimensions, int32 maxDimensions, bool useRust\)\s*\{[^}]*return dimensions > maxDimensions;/s,
	"legacy C reject-excess-dimensions fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveRejectLowEfConstruction\(int32 efConstruction, int32 m, bool useRust\)\s*\{[^}]*return efConstruction < 2 \* m;/s,
	"legacy C reject-low-ef-construction fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveTreatForkAsInit\(int32 forkNum, bool useRust\)\s*\{[^}]*return forkNum == INIT_FORKNUM;/s,
	"legacy C treat-fork-as-init fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveWriteWalPage\(bool needsWal, bool isInitFork, bool useRust\)\s*\{[^}]*return needsWal \|\| isInitFork;/s,
	"legacy C write-wal-page fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveSkipNullBuildTuple\(bool isNull, bool useRust\)\s*\{[^}]*return isNull;/s,
	"legacy C skip-null-build-tuple fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveUpdateProgressAfterInsert\(bool tupleInserted, bool useRust\)\s*\{[^}]*return tupleInserted;/s,
	"legacy C update-progress-after-insert fallback removed");

ok($hnsw_build_c =~ /vector_rust_hnsw_should_reject_oversized_element_tuple_kernel\(/,
	"hnswbuild.c uses rust reject-oversized-element-tuple kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_append_neighbor_page_kernel\(/,
	"hnswbuild.c uses rust append-neighbor-page kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_append_element_page_kernel\(/,
	"hnswbuild.c uses rust append-element-page kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_reject_unexpected_item_offset_kernel\(/,
	"hnswbuild.c uses rust reject-unexpected-item-offset kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_reject_neighbor_overwrite_kernel\(/,
	"hnswbuild.c uses rust reject-neighbor-overwrite kernel");
ok($hnsw_build_c =~ /vector_rust_hnsw_should_store_neighbors_on_same_page_kernel\(/,
	"hnswbuild.c uses rust store-neighbors-on-same-page kernel");

unlike($hnsw_build_c, qr/HnswShouldHaveUpdateEntryPoint\(bool entryPointIsNull, int elementLevel, int entryLevel, bool useRust\)\s*\{[^}]*return entryPointIsNull \|\| HnswShouldHaveHigherBuildEntrypointLevel\(elementLevel, entryLevel, false\);/s,
	"legacy C update-entrypoint fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveRejectInMemoryDuplicateHeapTid\(int32 heaptidsLength, int32 maxHeaptids, bool useRust\)\s*\{[^}]*return heaptidsLength >= maxHeaptids;/s,
	"legacy C reject-inmemory-duplicate-heaptid fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveRejectOversizedElementTuple\(int64 tupleSize, int64 allocSize, bool useRust\)\s*\{[^}]*return tupleSize > allocSize;/s,
	"legacy C reject-oversized-element-tuple fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveAppendNeighborPage\(int64 freeSpace, int64 neighborTupleSize, bool useRust\)\s*\{[^}]*return freeSpace < neighborTupleSize;/s,
	"legacy C append-neighbor-page fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveAppendElementPage\(int64 freeSpace, int64 elementTupleSize, int64 combinedSize, int64 maxSize, bool useRust\)\s*\{[^}]*return freeSpace < elementTupleSize \|\| \(combinedSize <= maxSize && freeSpace < combinedSize\);/s,
	"legacy C append-element-page fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveRejectUnexpectedItemOffset\(int32 insertedOffset, int32 expectedOffset, bool useRust\)\s*\{[^}]*return insertedOffset != expectedOffset;/s,
	"legacy C reject-unexpected-item-offset fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveRejectNeighborOverwrite\(bool overwriteSucceeded, bool useRust\)\s*\{[^}]*return !overwriteSucceeded;/s,
	"legacy C reject-neighbor-overwrite fallback removed");
unlike($hnsw_build_c, qr/HnswShouldHaveStoreNeighborsOnSamePage\(int64 combinedSize, int64 maxSize, bool useRust\)\s*\{[^}]*return combinedSize <= maxSize;/s,
	"legacy C store-neighbors-on-same-page fallback removed");

ok($hnsw_insert_c =~ /vector_rust_hnsw_should_update_entry_point_kernel\(/,
	"hnswinsert.c uses rust update-entrypoint kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_skip_invalid_index_value_kernel\(/,
	"hnswinsert.c uses rust skip-invalid-index-value kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_update_progress_after_insert_kernel\(/,
	"hnswinsert.c uses rust update-progress-after-insert kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_stop_duplicate_search_on_value_mismatch_kernel\(/,
	"hnswinsert.c uses rust duplicate-search-stop kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_return_after_duplicate_insert_kernel\(/,
	"hnswinsert.c uses rust duplicate-insert-return kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_skip_update_graph_for_duplicate_kernel\(/,
	"hnswinsert.c uses rust duplicate-update-skip kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_update_ondisk_insert_page_kernel\(/,
	"hnswinsert.c uses rust update-ondisk-insert-page kernel");

unlike($hnsw_insert_c, qr/HnswShouldHaveHigherOnDiskEntrypointLevel\(int32 elementLevel, int32 entryLevel, bool useRust\)\s*\{[^}]*return elementLevel > entryLevel;/s,
	"legacy C higher-ondisk-entrypoint-level fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldUpdateEntryPointOnDisk\(bool entryPointIsNull, int32 elementLevel, int32 entryLevel, bool useRust\)\s*\{[^}]*return entryPointIsNull \|\| HnswShouldHaveHigherOnDiskEntrypointLevel\(elementLevel, entryLevel, false\);/s,
	"legacy C update-entrypoint-ondisk fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveDefaultOnDiskEntryLevel\(bool hasEntryPoint, bool useRust\)\s*\{[^}]*return !hasEntryPoint;/s,
	"legacy C default-ondisk-entrylevel fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveOnDiskPointerFlag\(bool hasPointer, bool useRust\)\s*\{[^}]*return hasPointer;/s,
	"legacy C ondisk-pointer fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveValidInsertIndexValueFlag\(bool hasValidIndexValue, bool useRust\)\s*\{[^}]*return hasValidIndexValue;/s,
	"legacy C valid-insert-index-value fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveOnDiskValueMismatchFlag\(bool valuesMismatch, bool useRust\)\s*\{[^}]*return valuesMismatch;/s,
	"legacy C ondisk-value-mismatch-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveOnDiskValueMismatch\(bool valuesEqual, bool useRust\)\s*\{[^}]*return HnswShouldHaveOnDiskValueMismatchFlag\(!valuesEqual, false\);/s,
	"legacy C ondisk-value-mismatch fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldReturnAfterOnDiskDuplicateInsert\(bool duplicateInserted, bool useRust\)\s*\{[^}]*return duplicateInserted;/s,
	"legacy C return-after-ondisk-duplicate fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldSkipOnDiskGraphUpdateForDuplicate\(bool duplicateFound, bool useRust\)\s*\{[^}]*return duplicateFound;/s,
	"legacy C skip-ondisk-graph-update fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldUpdateOnDiskInsertPage\(bool hasNewInsertPage, bool useRust\)\s*\{[^}]*return hasNewInsertPage;/s,
	"legacy C update-ondisk-insert-page fallback removed");

ok($hnsw_insert_c =~ /vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel\(/,
	"hnswinsert.c uses rust commit-ondisk-duplicate-dirty kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_append_neighbor_page_kernel\(/,
	"hnswinsert.c uses rust append-neighbor-page kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_append_ondisk_element_page_kernel\(/,
	"hnswinsert.c uses rust append-ondisk-element-page kernel");

unlike($hnsw_insert_c, qr/HnswShouldHaveBoundaryDuplicateInsertSlotFlag\(bool hasBoundarySlot, bool useRust\)\s*\{[^}]*return hasBoundarySlot;/s,
	"legacy C boundary-duplicate-insert-slot fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveInvalidOnDiskHeapTidFlag\(bool heapTidValid, bool useRust\)\s*\{[^}]*return !heapTidValid;/s,
	"legacy C invalid-ondisk-heaptid fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldCommitOnDiskDuplicateWithBufferDirty\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C commit-ondisk-duplicate-with-dirty fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldCommitOnDiskNeighborUpdateWithBufferDirty\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C commit-ondisk-neighbor-update-with-dirty fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveNonBuildingOnDiskNeighborUpdate\(bool building, bool useRust\)\s*\{[^}]*return !building;/s,
	"legacy C nonbuilding-ondisk-neighbor-update fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveInsufficientOnDiskNeighborSpace\(int64 freeSpace, int64 tupleSize, bool useRust\)\s*\{[^}]*return freeSpace < tupleSize;/s,
	"legacy C insufficient-ondisk-neighbor-space fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldExceedOnDiskElementMaxSizeFlag\(bool exceedsMaxSize, bool useRust\)\s*\{[^}]*return exceedsMaxSize;/s,
	"legacy C exceed-ondisk-element-max-size fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveOnDiskElementWithoutNextPage\(bool hasNextPage, bool useRust\)\s*\{[^}]*return !hasNextPage;/s,
	"legacy C ondisk-element-without-next-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldAppendOnDiskElementPage\(int64 combinedSize, int64 maxSize, int64 freeSpace, int64 elementTupleSize, bool hasNextPage, bool useRust\)\s*\{[^}]*return HnswShouldExceedOnDiskElementMaxSize\(combinedSize, maxSize, false\) &&\s*HnswShouldHavePageSpaceForTuple\(freeSpace, elementTupleSize, false\) &&\s*HnswShouldHaveOnDiskElementWithoutNextPage\(hasNextPage, false\);/s,
	"legacy C append-ondisk-element-page fallback removed");

ok($hnsw_insert_c =~ /vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel\(/,
	"hnswinsert.c uses rust mark-ondisk-neighbor-buffer-dirty kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_update_ondisk_insert_page_kernel\(/,
	"hnswinsert.c uses rust update-ondisk-insert-page kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel\(/,
	"hnswinsert.c uses rust commit-ondisk-duplicate-dirty kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_update_progress_after_insert_kernel\(/,
	"hnswinsert.c uses rust update-progress-after-insert kernel");

unlike($hnsw_insert_c, qr/HnswShouldHaveNonBuildingOnDiskElementMoveNext\(bool building, bool useRust\)\s*\{[^}]*return !building;/s,
	"legacy C nonbuilding-ondisk-element-move-next fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldCommitOnDiskAddElementWithBufferDirty\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C commit-ondisk-add-element-dirty fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldMarkOnDiskNeighborBufferDirty\(bool sameBuffer, bool useRust\)\s*\{[^}]*return !sameBuffer;/s,
	"legacy C mark-ondisk-neighbor-buffer-dirty fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveChangedOnDiskInsertPageFlag\(bool pageChanged, bool useRust\)\s*\{[^}]*return pageChanged;/s,
	"legacy C changed-ondisk-insert-page-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldUpdateAddElementInsertPage\(bool hasNewInsertPage, bool pageChanged, bool useRust\)\s*\{[^}]*return shouldUpdate;/s,
	"legacy C update-add-element-insert-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveNeighborPageAsInsertPage\(bool hasNewInsertPage, bool useRust\)\s*\{[^}]*return !hasNewInsertPage;/s,
	"legacy C neighbor-page-as-insert-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveNextNeighborOffset\(bool sameBuffer, bool useRust\)\s*\{[^}]*return sameBuffer;/s,
	"legacy C next-neighbor-offset fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveFreeOnDiskOffsetFlag\(bool freeOffsetValid, bool useRust\)\s*\{[^}]*return freeOffsetValid;/s,
	"legacy C free-ondisk-offset-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveFreeOnDiskOffsets\(bool freeOffsetValid, bool useRust\)\s*\{[^}]*return freeOffsetValid;/s,
	"legacy C free-ondisk-offsets fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldProcessFreeOffsetResult\(bool freeOffsetResult, bool useRust\)\s*\{[^}]*return freeOffsetResult;/s,
	"legacy C process-free-offset-result fallback removed");

ok($hnsw_insert_c =~ /vector_rust_hnsw_should_append_neighbor_page_kernel\(/,
	"hnswinsert.c uses rust append-neighbor-page kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty_kernel\(/,
	"hnswinsert.c uses rust commit-ondisk-duplicate-dirty kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_update_progress_after_insert_kernel\(/,
	"hnswinsert.c uses rust update-progress-after-insert kernel");

unlike($hnsw_insert_c, qr/HnswShouldHaveOnDiskSpaceForCombinedTuple\(int64 freeSpace, int64 combinedSize, bool useRust\)\s*\{[^}]*return freeSpace >= combinedSize;/s,
	"legacy C ondisk-space-for-combined-tuple fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveBuildPathForOnDiskAddElement\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C build-path-for-ondisk-add-element fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldCommitOnDiskPageAppendWithBufferDirty\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C commit-ondisk-page-append-dirty fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveBuildPathForAppendedOnDiskBuffer\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C build-path-for-appended-buffer fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveBuildPathForReusedOnDiskBuffer\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C build-path-for-reused-buffer fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveBuildPathForOnDiskAppendPage\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C build-path-for-ondisk-append-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveBuildPathForOnDiskNeighborUpdate\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C build-path-for-ondisk-neighbor-update fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveBuildPathForOnDiskDuplicatePage\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C build-path-for-ondisk-duplicate-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveNonBuildingOnDiskDuplicateSlotReject\(bool building, bool useRust\)\s*\{[^}]*return !building;/s,
	"legacy C nonbuilding-ondisk-duplicate-slot-reject fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveOnDiskItemPointerFlag\(bool itemPointerValid, bool useRust\)\s*\{[^}]*return itemPointerValid;/s,
	"legacy C ondisk-itempointer fallback removed");

ok($hnsw_insert_c =~ /vector_rust_hnsw_should_skip_invalid_index_value_kernel\(/,
	"hnswinsert.c uses rust skip-invalid-index-value kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_update_progress_after_insert_kernel\(/,
	"hnswinsert.c uses rust update-progress-after-insert kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_update_ondisk_insert_page_kernel\(/,
	"hnswinsert.c uses rust update-ondisk-insert-page kernel");
ok($hnsw_insert_c =~ /vector_rust_hnsw_should_match_neighbor_connection_kernel\(/,
	"hnswinsert.c uses rust match-neighbor-connection kernel");

unlike($hnsw_insert_c, qr/HnswShouldHaveInvalidOnDiskNeighborSlotFlag\(bool slotTidValid, bool useRust\)\s*\{[^}]*return !slotTidValid;/s,
	"legacy C invalid-ondisk-neighbor-slot fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveInvalidOnDiskNeighborTidFlag\(bool neighborTidValid, bool useRust\)\s*\{[^}]*return !neighborTidValid;/s,
	"legacy C invalid-ondisk-neighbor-tid fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveMatchingNeighborBlockFlag\(bool hasMatchingBlock, bool useRust\)\s*\{[^}]*return hasMatchingBlock;/s,
	"legacy C matching-neighbor-block fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveMatchingNeighborOffsetFlag\(bool hasMatchingOffset, bool useRust\)\s*\{[^}]*return hasMatchingOffset;/s,
	"legacy C matching-neighbor-offset fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldSkipNonElementTuple\(bool isElementTuple, bool useRust\)\s*\{[^}]*return !isElementTuple;/s,
	"legacy C skip-non-element-tuple fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldReuseDeletedOnDiskTuple\(bool isDeleted, bool useRust\)\s*\{[^}]*return isDeleted;/s,
	"legacy C reuse-deleted-ondisk-tuple fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveOnDiskBlockFlag\(bool blockValid, bool useRust\)\s*\{[^}]*return blockValid;/s,
	"legacy C ondisk-block-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveMissingOnDiskInsertPage\(bool hasInsertPage, bool useRust\)\s*\{[^}]*return !hasInsertPage;/s,
	"legacy C missing-ondisk-insert-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldReuseElementBufferForNeighborPage\(bool samePage, bool useRust\)\s*\{[^}]*return samePage;/s,
	"legacy C reuse-element-buffer-for-neighbor-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveMatchingNeighborPageFlag\(bool hasMatchingPage, bool useRust\)\s*\{[^}]*return hasMatchingPage;/s,
	"legacy C matching-neighbor-page-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveMatchingNeighborPage\(int32 neighborPage, int32 elementPage, bool useRust\)\s*\{[^}]*return HnswShouldHaveMatchingNeighborPageFlag\(neighborPage == elementPage, false\);/s,
	"legacy C matching-neighbor-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveMatchingOnDiskBufferFlag\(bool hasMatchingBuffer, bool useRust\)\s*\{[^}]*return hasMatchingBuffer;/s,
	"legacy C matching-ondisk-buffer-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveMatchingOnDiskBuffer\(int32 leftBuffer, int32 rightBuffer, bool useRust\)\s*\{[^}]*return HnswShouldHaveMatchingOnDiskBufferFlag\(leftBuffer == rightBuffer, false\);/s,
	"legacy C matching-ondisk-buffer fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldReleaseReusedNeighborBuffer\(bool sameBuffer, bool useRust\)\s*\{[^}]*return !sameBuffer;/s,
	"legacy C release-reused-neighbor-buffer fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveDistinctNeighborPageSpace\(bool samePage, bool useRust\)\s*\{[^}]*return !samePage;/s,
	"legacy C distinct-neighbor-page-space fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHavePageSpaceForTuple\(int64 pageFree, int64 tupleSize, bool useRust\)\s*\{[^}]*return pageFree >= tupleSize;/s,
	"legacy C page-space-for-tuple fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldBorrowSamePageNeighborSpace\(int64 pageFree, int64 elementTupleSize, bool samePage, bool useRust\)\s*\{[^}]*return samePage && HnswShouldHavePageSpaceForTuple\(pageFree, elementTupleSize, false\);/s,
	"legacy C borrow-same-page-neighbor-space fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldRegisterReusedNeighborBuffer\(bool sameBuffer, bool useRust\)\s*\{[^}]*return !sameBuffer;/s,
	"legacy C register-reused-neighbor-buffer fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldReturnEmptyWithoutNeighborTids\(bool neighborTidsLoaded, bool useRust\)\s*\{[^}]*return !neighborTidsLoaded;/s,
	"legacy C return-empty-without-neighbor-tids fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveEmptyInsertHeapTidsFlag\(bool hasEmptyHeapTids, bool useRust\)\s*\{[^}]*return hasEmptyHeapTids;/s,
	"legacy C empty-insert-heaptids-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveEmptyInsertHeapTids\(int32 heaptidsLength, bool useRust\)\s*\{[^}]*return HnswShouldHaveEmptyInsertHeapTidsFlag\(heaptidsLength == 0, false\);/s,
	"legacy C empty-insert-heaptids fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveNeighborCountBeforeLayerM\(int32 neighborCount, int32 layerM, bool useRust\)\s*\{[^}]*return neighborCount < layerM;/s,
	"legacy C neighbor-count-before-layer-m fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveExistingNeighborCheckFlag\(bool shouldCheckExisting, bool useRust\)\s*\{[^}]*return shouldCheckExisting;/s,
	"legacy C existing-neighbor-check-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveExistingNeighborConnectionFlag\(bool hasConnection, bool useRust\)\s*\{[^}]*return hasConnection;/s,
	"legacy C existing-neighbor-connection-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldProbeUndecidedUpdateIndex\(int32 updateIndex, bool useRust\)\s*\{[^}]*return updateIndex == -2;/s,
	"legacy C probe-undecided-update-index fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveNonNegativeUpdateIndexFlag\(bool isNonNegative, bool useRust\)\s*\{[^}]*return isNonNegative;/s,
	"legacy C non-negative-update-index-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveUpdateIndexBeforeTupleCount\(int32 updateIndex, int32 tupleCount, bool useRust\)\s*\{[^}]*return updateIndex < tupleCount;/s,
	"legacy C update-index-before-tuple-count fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveCandidateUpdateIndexFlag\(bool hasCandidateIndex, bool useRust\)\s*\{[^}]*return hasCandidateIndex;/s,
	"legacy C candidate-update-index-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveCandidateUpdateIndex\(int32 updateIndex, bool useRust\)\s*\{[^}]*return HnswShouldHaveCandidateUpdateIndexFlag\(updateIndex == -1, false\);/s,
	"legacy C candidate-update-index fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldRejectOnDiskElementOverwrite\(bool overwriteSucceeded, bool useRust\)\s*\{[^}]*return !overwriteSucceeded;/s,
	"legacy C reject-ondisk-element-overwrite fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveExpectedOnDiskOffsetFlag\(bool hasExpectedOffset, bool useRust\)\s*\{[^}]*return hasExpectedOffset;/s,
	"legacy C expected-ondisk-offset-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldRejectOnDiskUnexpectedOffset\(bool hasExpectedOffset, bool useRust\)\s*\{[^}]*return !hasExpectedOffset;/s,
	"legacy C reject-ondisk-unexpected-offset fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldFollowOnDiskNextPage\(bool nextPageValid, bool useRust\)\s*\{[^}]*return nextPageValid;/s,
	"legacy C follow-ondisk-next-page fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveOnDiskInsertSpaceFlag\(bool hasSpace, bool useRust\)\s*\{[^}]*return hasSpace;/s,
	"legacy C ondisk-insert-space-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveDistinctOnDiskNeighborBufferFlag\(bool hasDistinctBuffer, bool useRust\)\s*\{[^}]*return hasDistinctBuffer;/s,
	"legacy C distinct-ondisk-neighbor-buffer-flag fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldHaveDistinctOnDiskNeighborBuffer\(bool sameBuffer, bool useRust\)\s*\{[^}]*return HnswShouldHaveDistinctOnDiskNeighborBufferFlag\(!sameBuffer, false\);/s,
	"legacy C distinct-ondisk-neighbor-buffer fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldSkipUnselectedOnDiskNeighbor\(int32 updateIndex, bool useRust\)\s*\{[^}]*return updateIndex == -1;/s,
	"legacy C skip-unselected-ondisk-neighbor fallback removed");
unlike($hnsw_insert_c, qr/HnswShouldSkipNullInsertTuple\(bool isNull, bool useRust\)\s*\{[^}]*return isNull;/s,
	"legacy C skip-null-insert-tuple fallback removed");

ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_repair_underfilled_layer0_kernel\(/,
	"hnswvacuum.c uses rust repair-underfilled-layer0 kernel");
ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_skip_invalid_index_value_kernel\(/,
	"hnswvacuum.c uses rust skip-invalid-index-value kernel");
ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_update_ondisk_insert_page_kernel\(/,
	"hnswvacuum.c uses rust update-ondisk-insert-page kernel");
ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_update_progress_after_insert_kernel\(/,
	"hnswvacuum.c uses rust update-progress-after-insert kernel");
ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_match_neighbor_connection_kernel\(/,
	"hnswvacuum.c uses rust match-neighbor-connection kernel");
ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_update_entry_point_kernel\(/,
	"hnswvacuum.c uses rust update-entry-point kernel");
ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty_kernel\(/,
	"hnswvacuum.c uses rust mark-ondisk-neighbor-buffer-dirty kernel");
ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_assign_new_lock_tranche_kernel\(/,
	"hnswvacuum.c uses rust assign-new-lock-tranche kernel");
ok($hnsw_vacuum_c =~ /vector_rust_hnsw_should_reject_neighbor_overwrite_kernel\(/,
	"hnswvacuum.c uses rust reject-neighbor-overwrite kernel");

unlike($hnsw_vacuum_c, qr/HnswShouldHaveDeletedTidPointerFlag\(bool hasDeletedTid, bool useRust\)\s*\{[^}]*return hasDeletedTid;/s,
	"legacy C deleted-tid-pointer-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveContinuableVacuumBlockScan\(bool hasValidBlock, bool useRust\)\s*\{[^}]*return hasValidBlock;/s,
	"legacy C continuable-vacuum-block-scan fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumBlockFlag\(bool blockValid, bool useRust\)\s*\{[^}]*return blockValid;/s,
	"legacy C vacuum-block-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveInvalidVacuumLastItemFlag\(bool lastItemValid, bool useRust\)\s*\{[^}]*return !lastItemValid;/s,
	"legacy C invalid-vacuum-last-item fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveNonElementVacuumTuple\(bool isElementTuple, bool useRust\)\s*\{[^}]*return !isElementTuple;/s,
	"legacy C non-element-vacuum-tuple fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveProcessableVacuumHeapTids\(bool firstHeaptidValid, bool useRust\)\s*\{[^}]*return firstHeaptidValid;/s,
	"legacy C processable-vacuum-heaptids fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumItemPointerFlag\(bool itemPointerValid, bool useRust\)\s*\{[^}]*return itemPointerValid;/s,
	"legacy C vacuum-itempointer-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveDeletedVacuumTuple\(bool firstHeaptidValid, bool useRust\)\s*\{[^}]*return !firstHeaptidValid;/s,
	"legacy C deleted-vacuum-tuple fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveInvalidVacuumHeapTid\(bool heapTidValid, bool useRust\)\s*\{[^}]*return !heapTidValid;/s,
	"legacy C invalid-vacuum-heaptid fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumHeapTidRemoval\(bool callbackRemove, bool useRust\)\s*\{[^}]*return callbackRemove;/s,
	"legacy C vacuum-heaptid-removal fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveCompactedVacuumHeapTids\(bool itemUpdated, bool useRust\)\s*\{[^}]*return itemUpdated;/s,
	"legacy C compacted-vacuum-heaptids fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveFinishedVacuumPageUpdate\(bool pageUpdated, bool useRust\)\s*\{[^}]*return pageUpdated;/s,
	"legacy C finished-vacuum-page-update fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveInvalidVacuumNeighborTid\(bool neighborTidValid, bool useRust\)\s*\{[^}]*return !neighborTidValid;/s,
	"legacy C invalid-vacuum-neighbor-tid fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveDeletedVacuumNeighbor\(bool isDeletedNeighbor, bool useRust\)\s*\{[^}]*return isDeletedNeighbor;/s,
	"legacy C deleted-vacuum-neighbor fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumUnderfilledLayer0\(bool needsUpdated, bool useRust\)\s*\{[^}]*return !needsUpdated;/s,
	"legacy C vacuum-underfilled-layer0 fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumSkipEntrypoint\(bool hasEntryPoint, bool useRust\)\s*\{[^}]*return hasEntryPoint;/s,
	"legacy C vacuum-skip-entrypoint fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMatchingVacuumEntrypointElement\(int32 elementBlkno, int32 elementOffno, int32 entryBlkno, int32 entryOffno, bool useRust\)\s*\{[^}]*return elementBlkno == entryBlkno && elementOffno == entryOffno;/s,
	"legacy C matching-vacuum-entrypoint-element fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumPointerFlag\(bool hasPointer, bool useRust\)\s*\{[^}]*return hasPointer;/s,
	"legacy C vacuum-pointer-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMissingVacuumEntrypointTid\(bool hasEntryPoint, bool useRust\)\s*\{[^}]*return !hasEntryPoint;/s,
	"legacy C missing-vacuum-entrypoint-tid fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumElementWithoutUpdatesFlag\(bool needsUpdated, bool useRust\)\s*\{[^}]*return !needsUpdated;/s,
	"legacy C vacuum-element-without-updates fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveHigherVacuumEntrypointLevel\(int32 elementLevel, int32 entryPointLevel, bool useRust\)\s*\{[^}]*return elementLevel > entryPointLevel;/s,
	"legacy C higher-vacuum-entrypoint-level fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumMissingEntrypoint\(bool entryPointIsNull, bool useRust\)\s*\{[^}]*return entryPointIsNull;/s,
	"legacy C vacuum-missing-entrypoint fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveDefaultVacuumEntryLevel\(bool hasEntryPoint, bool useRust\)\s*\{[^}]*return !hasEntryPoint;/s,
	"legacy C default-vacuum-entry-level fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldResetVacuumHighestPoint\(bool highestPointValid, bool useRust\)\s*\{[^}]*return !highestPointValid;/s,
	"legacy C reset-vacuum-highest-point fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumHighestPointBlockFlag\(bool highestPointValid, bool useRust\)\s*\{[^}]*return highestPointValid;/s,
	"legacy C vacuum-highest-point-block-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldRepairVacuumHighestPoint\(bool needsUpdated, bool useRust\)\s*\{[^}]*return needsUpdated;/s,
	"legacy C repair-vacuum-highest-point fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldRepairVacuumEntryPoint\(bool needsUpdated, bool useRust\)\s*\{[^}]*return needsUpdated;/s,
	"legacy C repair-vacuum-entrypoint fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldResetVacuumEntryPointNeighbors\(bool hasHighestPoint, bool useRust\)\s*\{[^}]*return hasHighestPoint;/s,
	"legacy C reset-vacuum-entrypoint-neighbors fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldReplaceDeletedVacuumEntryPoint\(bool isDeletedEntrypoint, bool useRust\)\s*\{[^}]*return isDeletedEntrypoint;/s,
	"legacy C replace-deleted-vacuum-entrypoint fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldRepairNonnullVacuumHighestPoint\(bool hasHighestPoint, bool useRust\)\s*\{[^}]*return hasHighestPoint;/s,
	"legacy C repair-nonnull-vacuum-highest-point fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldProcessNonnullVacuumEntrypoint\(bool hasEntryPoint, bool useRust\)\s*\{[^}]*return hasEntryPoint;/s,
	"legacy C process-nonnull-vacuum-entrypoint fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveNonElementMarkDeletedTuple\(bool isElementTuple, bool useRust\)\s*\{[^}]*return !isElementTuple;/s,
	"legacy C non-element-markdeleted-tuple fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveLiveMarkDeletedTuple\(bool isLiveTuple, bool useRust\)\s*\{[^}]*return isLiveTuple;/s,
	"legacy C live-markdeleted-tuple fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldSetVacuumInsertPageWhenMissing\(bool hasInsertPage, bool useRust\)\s*\{[^}]*return !hasInsertPage;/s,
	"legacy C set-vacuum-insert-page-when-missing fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMatchingMarkDeletedNeighborPageFlag\(bool pagesMatch, bool useRust\)\s*\{[^}]*return pagesMatch;/s,
	"legacy C matching-markdeleted-neighbor-page-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMatchingMarkDeletedNeighborPage\(int32 neighborPage, int32 elementPage, bool useRust\)\s*\{[^}]*return HnswShouldHaveMatchingMarkDeletedNeighborPageFlag\(neighborPage == elementPage, false\);/s,
	"legacy C matching-markdeleted-neighbor-page fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMatchingMarkDeletedBuffersFlag\(bool buffersMatch, bool useRust\)\s*\{[^}]*return buffersMatch;/s,
	"legacy C matching-markdeleted-buffers-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMatchingMarkDeletedBuffers\(int32 leftBuffer, int32 rightBuffer, bool useRust\)\s*\{[^}]*return HnswShouldHaveMatchingMarkDeletedBuffersFlag\(leftBuffer == rightBuffer, false\);/s,
	"legacy C matching-markdeleted-buffers fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldReuseMarkDeletedBufferForNeighborPage\(bool samePage, bool useRust\)\s*\{[^}]*return samePage;/s,
	"legacy C reuse-markdeleted-buffer-for-neighbor-page fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveDistinctMarkDeletedBuffersFlag\(bool buffersMatch, bool useRust\)\s*\{[^}]*return !buffersMatch;/s,
	"legacy C distinct-markdeleted-buffers-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMarkDeletedVersionBeyondMaxFlag\(bool versionWithinRange, bool useRust\)\s*\{[^}]*return !versionWithinRange;/s,
	"legacy C markdeleted-version-beyond-max-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveHigherVacuumElementLevelFlag\(bool isHigherLevel, bool useRust\)\s*\{[^}]*return isHigherLevel;/s,
	"legacy C higher-vacuum-element-level-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumNonEntrypointFlag\(bool isEntryPoint, bool useRust\)\s*\{[^}]*return !isEntryPoint;/s,
	"legacy C vacuum-non-entrypoint-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMatchingVacuumEntrypointTidFlag\(bool hasMatchingTid, bool useRust\)\s*\{[^}]*return hasMatchingTid;/s,
	"legacy C matching-vacuum-entrypoint-tid-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMatchingVacuumEntrypointTid\(int32 blkno, int32 offno, int32 entryBlkno, int32 entryOffno, bool useRust\)\s*\{[^}]*return HnswShouldHaveMatchingVacuumEntrypointTidFlag\(blkno == entryBlkno && offno == entryOffno, false\);/s,
	"legacy C matching-vacuum-entrypoint-tid fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldMatchVacuumEntrypointTuple\(bool hasEntryPoint, int32 blkno, int32 offno, int32 entryBlkno, int32 entryOffno, bool useRust\)\s*\{[^}]*return hasEntryPoint && HnswShouldHaveMatchingVacuumEntrypointTid\(blkno, offno, entryBlkno, entryOffno, false\);/s,
	"legacy C match-vacuum-entrypoint-tuple fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveFailedVacuumNeighborOverwriteFlag\(bool overwriteSucceeded, bool useRust\)\s*\{[^}]*return !overwriteSucceeded;/s,
	"legacy C failed-vacuum-neighbor-overwrite-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveMissingVacuumStatsFlag\(bool hasStats, bool useRust\)\s*\{[^}]*return !hasStats;/s,
	"legacy C missing-vacuum-stats-flag fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveVacuumCleanupAnalyzeOnly\(bool analyzeOnly, bool useRust\)\s*\{[^}]*return analyzeOnly;/s,
	"legacy C vacuum-cleanup-analyze-only fallback removed");
unlike($hnsw_vacuum_c, qr/HnswShouldHaveDeletedMarkDeletedTuple\(bool isDeletedTuple, bool useRust\)\s*\{[^}]*return isDeletedTuple;/s,
	"legacy C deleted-markdeleted-tuple fallback removed");

ok($hnsw_utils_c =~ /vector_rust_hnsw_should_update_progress_after_insert_kernel\(/,
	"hnswutils.c uses rust update-progress-after-insert kernel");
ok($hnsw_utils_c =~ /vector_rust_hnsw_should_skip_invalid_index_value_kernel\(/,
	"hnswutils.c uses rust skip-invalid-index-value kernel");
ok($hnsw_utils_c =~ /vector_rust_hnsw_should_update_ondisk_insert_page_kernel\(/,
	"hnswutils.c uses rust update-ondisk-insert-page kernel");
ok($hnsw_utils_c =~ /vector_rust_hnsw_should_update_element_max_distance_kernel\(/,
	"hnswutils.c uses rust update-element-max-distance kernel");
ok($hnsw_utils_c =~ /vector_rust_hnsw_should_update_entry_point_kernel\(/,
	"hnswutils.c uses rust update-entry-point kernel");
ok($hnsw_utils_c =~ /vector_rust_hnsw_should_match_neighbor_connection_kernel\(/,
	"hnswutils.c uses rust match-neighbor-connection kernel");
ok($hnsw_utils_c =~ /vector_rust_hnsw_should_reject_excess_dimensions_kernel\(/,
	"hnswutils.c uses rust reject-excess-dimensions kernel");

unlike($hnsw_utils_c, qr/HnswShouldHaveQueryValuePointerFlag\(bool hasQueryValue, bool useRust\)\s*\{[^}]*return hasQueryValue;/s,
	"legacy C query-value-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldZeroDistanceForNullQueryValue\(bool hasQueryValue, bool useRust\)\s*\{[^}]*return !hasQueryValue;/s,
	"legacy C zero-distance-for-null-query-value fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveElementDistancePointerFlag\(bool hasDistancePointer, bool useRust\)\s*\{[^}]*return hasDistancePointer;/s,
	"legacy C element-distance-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveElementMaxDistancePointerFlag\(bool hasMaxDistancePointer, bool useRust\)\s*\{[^}]*return hasMaxDistancePointer;/s,
	"legacy C element-max-distance-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldUpdateElementMaxDistance\(bool hasDistancePointer, bool hasMaxDistancePointer, double distanceValue, double maxDistanceValue, bool useRust\)\s*\{[^}]*return !hasDistancePointer \|\| !hasMaxDistancePointer \|\| distanceValue < maxDistanceValue;/s,
	"legacy C update-element-max-distance fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveDefaultDistanceValue\(bool hasDistancePointer, bool useRust\)\s*\{[^}]*return !hasDistancePointer;/s,
	"legacy C default-distance-value fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveDefaultMaxDistanceValue\(bool hasMaxDistancePointer, bool useRust\)\s*\{[^}]*return !hasMaxDistancePointer;/s,
	"legacy C default-max-distance-value fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveLoadedElementPointerFlag\(bool hasElement, bool useRust\)\s*\{[^}]*return hasElement;/s,
	"legacy C loaded-element-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldInitializeLoadedElement\(bool hasElement, bool useRust\)\s*\{[^}]*return !hasElement;/s,
	"legacy C initialize-loaded-element fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldLoadElementVector\(bool shouldLoadVector, bool useRust\)\s*\{[^}]*return shouldLoadVector;/s,
	"legacy C load-element-vector fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldLoadElementHeapTids\(bool shouldLoadHeaptids, bool useRust\)\s*\{[^}]*return shouldLoadHeaptids;/s,
	"legacy C load-element-heaptids fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveElementHeapTidItemPointerFlag\(bool heaptidValid, bool useRust\)\s*\{[^}]*return heaptidValid;/s,
	"legacy C element-heaptid-itempointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldStopLoadingElementHeapTids\(bool heaptidValid, bool useRust\)\s*\{[^}]*return !heaptidValid;/s,
	"legacy C stop-loading-element-heaptids fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldCountWithoutSkipElement\(bool hasSkipElement, bool useRust\)\s*\{[^}]*return !hasSkipElement;/s,
	"legacy C count-without-skip-element fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldAppendUnvisitedNeighbor\(bool found, bool useRust\)\s*\{[^}]*return !found;/s,
	"legacy C append-unvisited-neighbor fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldAppendUnvisitedDiskNeighbor\(bool found, bool useRust\)\s*\{[^}]*return !found;/s,
	"legacy C append-unvisited-disk-neighbor fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveDiskNeighborIndexTidFlag\(bool isValidIndexTid, bool useRust\)\s*\{[^}]*return isValidIndexTid;/s,
	"legacy C disk-neighbor-indextid-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldStopLoadingDiskNeighbor\(bool isValidIndexTid, bool useRust\)\s*\{[^}]*return !isValidIndexTid;/s,
	"legacy C stop-loading-disk-neighbor fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldAbortUnvisitedDiskLoad\(bool neighborTidsLoaded, bool useRust\)\s*\{[^}]*return !neighborTidsLoaded;/s,
	"legacy C abort-unvisited-disk-load fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveConsistentNeighborTupleFlag\(bool tupleConsistent, bool useRust\)\s*\{[^}]*return tupleConsistent;/s,
	"legacy C consistent-neighbor-tuple-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldRejectStaleNeighborTuple\(bool tupleConsistent, bool useRust\)\s*\{[^}]*return !tupleConsistent;/s,
	"legacy C reject-stale-neighbor-tuple fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveDiscardedHeapPointerFlag\(bool hasDiscardedHeap, bool useRust\)\s*\{[^}]*return hasDiscardedHeap;/s,
	"legacy C discarded-heap-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveTupleCounterPointerFlag\(bool hasTupleCounter, bool useRust\)\s*\{[^}]*return hasTupleCounter;/s,
	"legacy C tuple-counter-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveVisitedHashPointerFlag\(bool hasVisitedHash, bool useRust\)\s*\{[^}]*return hasVisitedHash;/s,
	"legacy C visited-hash-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldInitializeVisitedHash\(bool hasVisitedHash, bool useRust\)\s*\{[^}]*return !hasVisitedHash;/s,
	"legacy C initialize-visited-hash fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldInitializeVisitedState\(bool initVisited, bool useRust\)\s*\{[^}]*return initVisited;/s,
	"legacy C initialize-visited-state fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveTidVisitedHash\(bool inMemory, bool useRust\)\s*\{[^}]*return !inMemory;/s,
	"legacy C tid-visited-hash fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveVisitedBasePointerFlag\(bool hasBasePointer, bool useRust\)\s*\{[^}]*return hasBasePointer;/s,
	"legacy C visited-base-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHavePointerVisitedHash\(bool hasBasePointer, bool useRust\)\s*\{[^}]*return !hasBasePointer;/s,
	"legacy C pointer-visited-hash fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSearchIndexPointerFlag\(bool hasIndexPointer, bool useRust\)\s*\{[^}]*return hasIndexPointer;/s,
	"legacy C search-index-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveMemoryEntryDistance\(bool inMemory, bool useRust\)\s*\{[^}]*return inMemory;/s,
	"legacy C memory-entry-distance fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveInMemorySearchPath\(bool inMemory, bool useRust\)\s*\{[^}]*return inMemory;/s,
	"legacy C in-memory-search-path fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSearchEntrypointPointerFlag\(bool hasEntryPoint, bool useRust\)\s*\{[^}]*return hasEntryPoint;/s,
	"legacy C search-entrypoint-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldReturnWithoutEntryPoint\(bool hasEntryPoint, bool useRust\)\s*\{[^}]*return !hasEntryPoint;/s,
	"legacy C return-without-entrypoint fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldPrecomputeHashForNeighbors\(bool inMemory, bool useRust\)\s*\{[^}]*return inMemory;/s,
	"legacy C precompute-hash-for-neighbors fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldIncrementEfForExistingElement\(bool existing, bool useRust\)\s*\{[^}]*return existing;/s,
	"legacy C increment-ef-for-existing-element fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldRemoveDiskOnlyElementsBeforeSelect\(bool inMemory, bool useRust\)\s*\{[^}]*return !inMemory;/s,
	"legacy C remove-disk-only-elements-before-select fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldClampNeighborSearchLevel\(int level, int entryLevel, bool useRust\)\s*\{[^}]*return level > entryLevel;/s,
	"legacy C clamp-neighbor-search-level fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHavePointerHashForBase\(bool hasBasePointer, bool useRust\)\s*\{[^}]*return !hasBasePointer;/s,
	"legacy C pointer-hash-for-base fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldKeepElementWithHeapTids\(int heaptidsLength, bool useRust\)\s*\{[^}]*return heaptidsLength != 0;/s,
	"legacy C keep-element-with-heaptids fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldCountCandidateWithHeapTids\(int heaptidsLength, bool useRust\)\s*\{[^}]*return heaptidsLength != 0;/s,
	"legacy C count-candidate-with-heaptids fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSkipElementForExisting\(bool existing, bool useRust\)\s*\{[^}]*return existing;/s,
	"legacy C skip-element-for-existing fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSkipElementPointerFlag\(bool hasSkipElement, bool useRust\)\s*\{[^}]*return hasSkipElement;/s,
	"legacy C skip-element-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveDefaultSkipElementTid\(bool hasSkipElement, bool useRust\)\s*\{[^}]*return !hasSkipElement;/s,
	"legacy C default-skip-element-tid fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldSkipSelfForVacuumUpdate\(bool hasSkipElement, int elementBlkno, int elementOffno, int skipBlkno, int skipOffno, bool useRust\)\s*\{.*return hasSkipElement && elementBlkno == skipBlkno && elementOffno == skipOffno;\s*\}/s,
	"legacy C skip-self-for-vacuum-update fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveTypeInfoProcInfoFlag\(bool hasProcInfo, bool useRust\)\s*\{[^}]*return hasProcInfo;/s,
	"legacy C typeinfo-procinfo-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveDefaultTypeInfo\(bool hasProcInfo, bool useRust\)\s*\{[^}]*return !hasProcInfo;/s,
	"legacy C default-typeinfo fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldRejectSparsevecExcessNnz\(int nnz, int maxNnz, bool useRust\)\s*\{[^}]*return nnz > maxNnz;/s,
	"legacy C reject-sparsevec-excess-nnz fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldSortNeighborCandidates\(bool sortCandidates, bool useRust\)\s*\{[^}]*return sortCandidates;/s,
	"legacy C sort-neighbor-candidates fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSortBasePointerFlag\(bool hasBasePointer, bool useRust\)\s*\{[^}]*return hasBasePointer;/s,
	"legacy C sort-base-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldSortPointerCandidates\(bool hasBasePointer, bool useRust\)\s*\{[^}]*return !hasBasePointer;/s,
	"legacy C sort-pointer-candidates fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldCalculateNeighborCloser\(bool mustCalculate, bool useRust\)\s*\{[^}]*return mustCalculate;/s,
	"legacy C calculate-neighbor-closer fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldReuseAddedCandidates\(int addedCount, bool useRust\)\s*\{[^}]*return addedCount > 0;/s,
	"legacy C reuse-added-candidates fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldDefineCloserStateForBase\(bool hasBasePointer, bool useRust\)\s*\{[^}]*return hasBasePointer;/s,
	"legacy C define-closer-state-for-base fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldAppendCloserCandidate\(bool isCloser, bool useRust\)\s*\{[^}]*return isCloser;/s,
	"legacy C append-closer-candidate fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldRecheckCandidateAfterRemoval\(bool removedAny, bool useRust\)\s*\{[^}]*return removedAny;/s,
	"legacy C recheck-candidate-after-removal fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHavePrunedOutputPointerFlag\(bool hasPrunedOutput, bool useRust\)\s*\{[^}]*return hasPrunedOutput;/s,
	"legacy C pruned-output-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveNewCandidatePointerFlag\(bool hasNewCandidatePointer, bool useRust\)\s*\{[^}]*return hasNewCandidatePointer;/s,
	"legacy C new-candidate-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldProcessNewCandidateBranch\(bool isNewCandidate, bool useRust\)\s*\{[^}]*return isNewCandidate;/s,
	"legacy C process-new-candidate-branch fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldReplacePrunedNeighbor\(bool matchesPrunedNeighbor, bool useRust\)\s*\{[^}]*return matchesPrunedNeighbor;/s,
	"legacy C replace-pruned-neighbor fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldAbortWithoutPrunedCandidate\(bool hasPrunedCandidate, bool useRust\)\s*\{[^}]*return !hasPrunedCandidate;/s,
	"legacy C abort-without-pruned-candidate fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldEnqueueCountedCandidate\(bool countedCandidate, bool useRust\)\s*\{[^}]*return countedCandidate;/s,
	"legacy C enqueue-counted-candidate fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSearchElementPointerFlag\(bool hasSearchElement, bool useRust\)\s*\{[^}]*return hasSearchElement;/s,
	"legacy C search-element-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldSkipMissingSearchElement\(bool hasSearchElement, bool useRust\)\s*\{[^}]*return !hasSearchElement;/s,
	"legacy C skip-missing-search-element fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldCopyTupleSlotByIndex\(int slotIndex, int slotLimit, bool useRust\)\s*\{[^}]*return slotIndex < slotLimit;/s,
	"legacy C copy-tuple-slot-by-index fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldCapElementLevel\(int level, int maxLevel, bool useRust\)\s*\{[^}]*return level > maxLevel;/s,
	"legacy C cap-element-level fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldUseIndexOptions\(bool hasOptions, bool useRust\)\s*\{[^}]*return hasOptions;/s,
	"legacy C use-index-options fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveIndexOptionsFlag\(bool hasOptions, bool useRust\)\s*\{[^}]*return hasOptions;/s,
	"legacy C index-options-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldReturnMissingOptionalProc\(bool hasProcOid, bool useRust\)\s*\{[^}]*return !hasProcOid;/s,
	"legacy C return-missing-optional-proc fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldUseCustomAllocator\(bool hasAllocator, bool useRust\)\s*\{[^}]*return hasAllocator;/s,
	"legacy C use-custom-allocator fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveCustomAllocatorFlag\(bool hasAllocator, bool useRust\)\s*\{[^}]*return hasAllocator;/s,
	"legacy C custom-allocator-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldLoadMetaM\(bool hasMOutputPointer, bool useRust\)\s*\{[^}]*return hasMOutputPointer;/s,
	"legacy C load-meta-m fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveMetaOutputPointerFlag\(bool hasOutputPointer, bool useRust\)\s*\{[^}]*return hasOutputPointer;/s,
	"legacy C meta-output-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldLoadMetaEntrypoint\(bool hasEntrypointOutputPointer, bool useRust\)\s*\{[^}]*return hasEntrypointOutputPointer;/s,
	"legacy C load-meta-entrypoint fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveMetaBlockFlag\(bool hasValidBlock, bool useRust\)\s*\{[^}]*return hasValidBlock;/s,
	"legacy C meta-block-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldUpdateMetaEntryInfo\(int updateEntry, bool useRust\)\s*\{[^}]*return updateEntry != 0;/s,
	"legacy C update-meta-entry-info fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldResetMetaEntrypoint\(bool hasEntrypoint, bool useRust\)\s*\{[^}]*return !hasEntrypoint;/s,
	"legacy C reset-meta-entrypoint fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldForceMetaEntryUpdate\(int updateEntry, bool useRust\)\s*\{[^}]*return updateEntry == HNSW_UPDATE_ENTRY_ALWAYS;/s,
	"legacy C force-meta-entry-update fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldWriteMetaEntrypoint\(bool hasEntrypoint, int entryLevel, int currentEntryLevel, int updateEntry, bool useRust\)\s*\{.*return !hasEntrypoint \|\| entryLevel > currentEntryLevel \|\| HnswShouldForceMetaEntryUpdate\(updateEntry, false\);.*\}/s,
	"legacy C write-meta-entrypoint fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveBuildBufferPath\(bool building, bool useRust\)\s*\{[^}]*return building;/s,
	"legacy C build-buffer-path fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldCheckTypeValue\(bool hasCheckValueFunction, bool useRust\)\s*\{[^}]*return hasCheckValueFunction;/s,
	"legacy C check-type-value fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveTypeCheckFunctionFlag\(bool hasCheckValueFunction, bool useRust\)\s*\{[^}]*return hasCheckValueFunction;/s,
	"legacy C type-check-function-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldNormalizeIndexValue\(bool hasNormProcInfo, bool useRust\)\s*\{[^}]*return hasNormProcInfo;/s,
	"legacy C normalize-index-value fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveNormProcInfoFlag\(bool hasNormProcInfo, bool useRust\)\s*\{[^}]*return hasNormProcInfo;/s,
	"legacy C norm-procinfo-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldRejectInvalidNorm\(bool hasValidNorm, bool useRust\)\s*\{[^}]*return !hasValidNorm;/s,
	"legacy C reject-invalid-norm fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldPrioritizeLowerDistance\(double leftDistance, double rightDistance, bool useRust\)\s*\{[^}]*return leftDistance < rightDistance;/s,
	"legacy C prioritize-lower-distance fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldPrioritizePointerTiebreak\(bool leftPointerPrecedes, bool useRust\)\s*\{[^}]*return leftPointerPrecedes;/s,
	"legacy C prioritize-pointer-tiebreak fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldPrioritizeOffsetTiebreak\(bool leftOffsetPrecedes, bool useRust\)\s*\{[^}]*return leftOffsetPrecedes;/s,
	"legacy C prioritize-offset-tiebreak fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveExpectedMetaMagicFlag\(bool hasExpectedMagic, bool useRust\)\s*\{[^}]*return hasExpectedMagic;/s,
	"legacy C expected-meta-magic-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldRejectInvalidMetaMagic\(bool hasExpectedMagic, bool useRust\)\s*\{[^}]*return !hasExpectedMagic;/s,
	"legacy C reject-invalid-meta-magic fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveRejectCloserNeighbor\(float8 distance, float8 candidateDistance, bool useRust\)\s*\{[^}]*return distance <= candidateDistance;/s,
	"legacy C reject-closer-neighbor fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSelectNeighborsEarlyReturn\(int candidateCount, int maxNeighbors, bool useRust\)\s*\{[^}]*return candidateCount <= maxNeighbors;/s,
	"legacy C select-neighbors-early-return fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveAddSearchCandidate\(float8 candidateDistance, float8 frontierDistance, bool alwaysAdd, bool useRust\)\s*\{[^}]*return candidateDistance < frontierDistance \|\| alwaysAdd;/s,
	"legacy C add-search-candidate fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveStopSearchLayer\(float8 candidateDistance, float8 frontierDistance, bool useRust\)\s*\{[^}]*return candidateDistance > frontierDistance;/s,
	"legacy C stop-search-layer fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveAppendNeighborWithoutPrune\(int neighborsLength, int maxNeighbors, bool useRust\)\s*\{[^}]*return neighborsLength < maxNeighbors;/s,
	"legacy C append-neighbor-without-prune fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSkipLowerLevelCandidate\(int candidateLevel, int searchLevel, bool useRust\)\s*\{[^}]*return candidateLevel < searchLevel;/s,
	"legacy C skip-lower-level-candidate fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveKeepPrunedConnection\(int wdoff, int wdlen, int resultLength, int maxNeighbors, bool useRust\)\s*\{[^}]*return wdoff < wdlen && resultLength < maxNeighbors;/s,
	"legacy C keep-pruned-connection fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveSetPrunedFromArray\(int wdoff, int wdlen, bool useRust\)\s*\{[^}]*return wdoff < wdlen;/s,
	"legacy C set-pruned-from-array fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveTrackDiscardedCandidates\(bool hasDiscardedHeap, bool useRust\)\s*\{[^}]*return hasDiscardedHeap;/s,
	"legacy C track-discarded-candidates fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldLoadElementWithMaxDistanceCap\(bool alwaysAdd, bool trackDiscarded, bool useRust\)\s*\{[^}]*return !alwaysAdd && !trackDiscarded;/s,
	"legacy C load-element-with-max-distance-cap fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveUpdateIndexPointerFlag\(bool hasUpdateIndexPointer, bool useRust\)\s*\{[^}]*return hasUpdateIndexPointer;/s,
	"legacy C update-index-pointer-flag fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveTrackUpdateIndex\(bool hasUpdateIndexPointer, bool useRust\)\s*\{[^}]*return hasUpdateIndexPointer;/s,
	"legacy C track-update-index fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveProcessPrunedCandidate\(bool hasPrunedCandidate, bool useRust\)\s*\{[^}]*return hasPrunedCandidate;/s,
	"legacy C process-pruned-candidate fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveTrimCandidateList\(int candidateCount, int ef, bool useRust\)\s*\{[^}]*return candidateCount > ef;/s,
	"legacy C trim-candidate-list fallback removed");
unlike($hnsw_utils_c, qr/HnswShouldHaveAlwaysAddCandidate\(int candidateCount, int ef, bool useRust\)\s*\{[^}]*return candidateCount < ef;/s,
	"legacy C always-add-candidate fallback removed");

ok($ivf_vacuum_c =~ /vector_rust_ivfflat_should_follow_insert_page_link_kernel\(/,
	"ivfvacuum.c uses rust follow-insert-page-link kernel");
ok($ivf_vacuum_c =~ /vector_rust_ivfflat_should_set_insert_page_kernel\(/,
	"ivfvacuum.c uses rust set-insert-page kernel");

unlike($ivf_vacuum_c, qr/IvfflatVacuumPageIsValid\(BlockNumber page, bool useRust\)\s*\{[^}]*return BlockNumberIsValid\(page\);/s,
	"legacy C ivfvacuum-page-valid fallback removed");
unlike($ivf_vacuum_c, qr/IvfflatShouldSetInsertPage\(int ndeletable, BlockNumber insertPage, bool useRust\)\s*\{[^}]*return !IvfflatVacuumPageIsValid\(insertPage, false\) && ndeletable > 0;/s,
	"legacy C ivfvacuum-set-insert-page fallback removed");

done_testing();
