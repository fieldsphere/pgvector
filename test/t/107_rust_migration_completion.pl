use strict;
use warnings FATAL => 'all';
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Test::More;

my $repo_root = abs_path(dirname(__FILE__) . "/../..");
my $hnsw_path = "$repo_root/src/hnsw.c";
my $hnsw_scan_path = "$repo_root/src/hnswscan.c";
my $hnsw_build_path = "$repo_root/src/hnswbuild.c";

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

done_testing();
