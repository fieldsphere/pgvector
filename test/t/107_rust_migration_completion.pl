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

done_testing();
