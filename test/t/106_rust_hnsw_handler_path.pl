use strict;
use warnings FATAL => 'all';
use PostgreSQL::Test::Cluster;
use PostgreSQL::Test::Utils;
use Test::More;

my $node = PostgreSQL::Test::Cluster->new('node');
$node->init;
$node->start;

$node->safe_psql("postgres", "CREATE EXTENSION vector;");
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_handler_probe() RETURNS text
	AS '$libdir/vector', 'vector_hnsw_handler_probe'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_handler_probe() RETURNS text
	AS '$libdir/vector', 'vector_rust_hnsw_handler_probe'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_disable_without_order(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_disable_without_order'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_disable_without_order(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_disable_without_order'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_clamp_ratio(double precision) RETURNS double precision
	AS '$libdir/vector', 'vector_hnsw_clamp_ratio'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_clamp_ratio(double precision) RETURNS double precision
	AS '$libdir/vector', 'vector_rust_hnsw_clamp_ratio'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_adjust_startup_cost(double precision, double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_adjust_startup_cost'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_adjust_startup_cost(double precision, double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_adjust_startup_cost'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_compute_scan_ratio_from_tuples(double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_compute_scan_ratio_from_tuples'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_compute_scan_ratio_from_tuples(double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_compute_scan_ratio_from_tuples'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_init_lock_tranche(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_init_lock_tranche'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_init_lock_tranche(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_init_lock_tranche'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_assign_new_lock_tranche(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_assign_new_lock_tranche'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_assign_new_lock_tranche(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_assign_new_lock_tranche'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_empty_without_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_empty_without_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_empty_without_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_empty_without_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_resume_from_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_resume_from_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_resume_from_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_resume_from_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_remaining_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_remaining_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_remaining_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_remaining_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_strict_out_of_order(integer, double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_strict_out_of_order'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_strict_out_of_order(integer, double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_strict_out_of_order'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_without_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_without_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_without_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_without_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_when_iterative_scan_off(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_when_iterative_scan_off'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_when_iterative_scan_off(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_when_iterative_scan_off'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_limit_scan_by_resources(bigint, bigint, bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_limit_scan_by_resources'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_limit_scan_by_resources(bigint, bigint, bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_limit_scan_by_resources'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_release_iterative_scan_memory(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_release_iterative_scan_memory'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_release_iterative_scan_memory(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_release_iterative_scan_memory'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_update_previous_distance(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_update_previous_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_update_previous_distance(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_update_previous_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_flush_graph_pages_at_end(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_flush_graph_pages_at_end'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_flush_graph_pages_at_end(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_flush_graph_pages_at_end'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_begin_parallel_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_begin_parallel_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_begin_parallel_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_begin_parallel_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_end_parallel_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_end_parallel_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_end_parallel_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_end_parallel_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_scan_heap_for_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_scan_heap_for_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_scan_heap_for_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_scan_heap_for_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_parallel_heap_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_parallel_heap_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_parallel_heap_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_parallel_heap_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_inmemory_duplicate_heaptid(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_inmemory_duplicate_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_inmemory_duplicate_heaptid(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_inmemory_duplicate_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_handle_empty_work_list(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_handle_empty_work_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_handle_empty_work_list(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_handle_empty_work_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_advance_on_exhausted_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_advance_on_exhausted_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_advance_on_exhausted_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_advance_on_exhausted_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_missing_orderby(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_missing_orderby'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_missing_orderby(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_missing_orderby'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_non_mvcc_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_non_mvcc_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_non_mvcc_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_non_mvcc_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_copy_rescan_keys(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_copy_rescan_keys'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_copy_rescan_keys(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_copy_rescan_keys'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_null_scan_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_null_scan_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_null_scan_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_null_scan_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_normalize_scan_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_normalize_scan_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_normalize_scan_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_normalize_scan_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_initialize_scan_state(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_initialize_scan_state'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_initialize_scan_state(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_initialize_scan_state'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_increment_instrument_searches(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_increment_instrument_searches'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_increment_instrument_searches(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_increment_instrument_searches'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_parallel_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_parallel_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_parallel_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_parallel_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_relation_parallel_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_relation_parallel_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_relation_parallel_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_relation_parallel_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_fallback_without_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_fallback_without_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_fallback_without_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_fallback_without_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_leader_participate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_leader_participate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_leader_participate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_leader_participate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_debug_query_string(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_debug_query_string'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_debug_query_string(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_debug_query_string'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_non_concurrent_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_non_concurrent_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_non_concurrent_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_non_concurrent_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_non_concurrent_lock_modes(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_non_concurrent_lock_modes'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_non_concurrent_lock_modes(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_non_concurrent_lock_modes'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_fallback_without_dsm_segment(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_fallback_without_dsm_segment'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_fallback_without_dsm_segment(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_fallback_without_dsm_segment'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reserve_graph_memory(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reserve_graph_memory'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reserve_graph_memory(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reserve_graph_memory'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_log_leader_progress(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_log_leader_progress'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_log_leader_progress(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_log_leader_progress'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_varbit_type(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_varbit_type'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_varbit_type(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_varbit_type'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_missing_dimensions(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_missing_dimensions'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_missing_dimensions(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_missing_dimensions'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_excess_dimensions(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_excess_dimensions'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_excess_dimensions(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_excess_dimensions'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_low_ef_construction(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_low_ef_construction'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_low_ef_construction(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_low_ef_construction'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_write_wal_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_write_wal_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_write_wal_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_write_wal_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_null_build_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_null_build_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_null_build_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_null_build_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_update_progress_after_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_update_progress_after_insert'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_update_progress_after_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_update_progress_after_insert'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_store_neighbors_on_same_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_store_neighbors_on_same_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_store_neighbors_on_same_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_store_neighbors_on_same_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_oversized_element_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_oversized_element_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_oversized_element_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_oversized_element_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_append_neighbor_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_append_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_append_neighbor_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_append_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_append_element_page(bigint, bigint, bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_append_element_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_append_element_page(bigint, bigint, bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_append_element_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_unexpected_item_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_unexpected_item_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_unexpected_item_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_unexpected_item_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_neighbor_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_neighbor_overwrite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_neighbor_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_neighbor_overwrite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_invalid_index_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_invalid_index_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_invalid_index_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_invalid_index_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_duplicate_search_on_value_mismatch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_duplicate_search_on_value_mismatch'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_duplicate_search_on_value_mismatch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_duplicate_search_on_value_mismatch'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_after_duplicate_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_after_duplicate_insert'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_after_duplicate_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_after_duplicate_insert'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_update_graph_for_duplicate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_update_graph_for_duplicate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_update_graph_for_duplicate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_update_graph_for_duplicate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_null_insert_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_null_insert_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_null_insert_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_null_insert_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_update_entrypoint_ondisk(integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_update_entrypoint_ondisk'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_update_entrypoint_ondisk(integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_update_entrypoint_ondisk'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_invalid_insert_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_invalid_insert_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_invalid_insert_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_invalid_insert_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_after_ondisk_duplicate_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_after_ondisk_duplicate_insert'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_after_ondisk_duplicate_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_after_ondisk_duplicate_insert'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_ondisk_graph_update_for_duplicate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_ondisk_graph_update_for_duplicate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_ondisk_graph_update_for_duplicate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_ondisk_graph_update_for_duplicate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_update_ondisk_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_update_ondisk_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_update_ondisk_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_update_ondisk_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_ondisk_duplicate_insert_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_ondisk_duplicate_insert_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_ondisk_duplicate_insert_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_ondisk_duplicate_insert_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_unselected_ondisk_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_unselected_ondisk_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_unselected_ondisk_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_unselected_ondisk_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_abort_ondisk_neighbor_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_abort_ondisk_neighbor_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_abort_ondisk_neighbor_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_abort_ondisk_neighbor_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_append_ondisk_neighbor_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_append_ondisk_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_append_ondisk_neighbor_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_append_ondisk_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_append_ondisk_element_page(bigint, bigint, bigint, bigint, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_append_ondisk_element_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_append_ondisk_element_page(bigint, bigint, bigint, bigint, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_append_ondisk_element_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_abort_ondisk_element_move_next(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_abort_ondisk_element_move_next'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_abort_ondisk_element_move_next(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_abort_ondisk_element_move_next'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_commit_ondisk_add_element_with_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_commit_ondisk_add_element_with_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_commit_ondisk_add_element_with_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_commit_ondisk_add_element_with_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_mark_ondisk_neighbor_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_mark_ondisk_neighbor_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_update_add_element_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_update_add_element_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_update_add_element_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_update_add_element_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_release_ondisk_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_release_ondisk_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_release_ondisk_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_release_ondisk_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_neighbor_page_as_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_neighbor_page_as_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_neighbor_page_as_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_neighbor_page_as_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_next_neighbor_offset(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_next_neighbor_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_next_neighbor_offset(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_next_neighbor_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_free_ondisk_offsets(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_free_ondisk_offsets'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_free_ondisk_offsets(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_free_ondisk_offsets'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_process_free_offset_result(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_process_free_offset_result'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_process_free_offset_result(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_process_free_offset_result'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_zero_distance_for_null_query_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_zero_distance_for_null_query_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_zero_distance_for_null_query_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_zero_distance_for_null_query_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_calculate_element_distance(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_calculate_element_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_calculate_element_distance(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_calculate_element_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_update_element_max_distance(integer, integer, double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_update_element_max_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_update_element_max_distance(integer, integer, double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_update_element_max_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_initialize_loaded_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_initialize_loaded_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_initialize_loaded_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_initialize_loaded_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_load_element_vector(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_load_element_vector'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_load_element_vector(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_load_element_vector'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_load_element_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_load_element_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_load_element_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_load_element_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_loading_element_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_loading_element_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_loading_element_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_loading_element_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_count_without_skip_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_count_without_skip_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_count_without_skip_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_count_without_skip_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_fit_ondisk_combined_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_fit_ondisk_combined_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_fit_ondisk_combined_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_fit_ondisk_combined_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_build_path_for_ondisk_add_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_build_path_for_ondisk_add_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_build_path_for_ondisk_add_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_build_path_for_ondisk_add_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_commit_ondisk_page_append_with_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_commit_ondisk_page_append_with_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_commit_ondisk_page_append_with_buffer_dirty(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_commit_ondisk_page_append_with_buffer_dirty'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_build_path_for_appended_ondisk_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_build_path_for_appended_ondisk_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_build_path_for_appended_ondisk_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_build_path_for_appended_ondisk_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_build_path_for_reused_ondisk_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_build_path_for_reused_ondisk_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_build_path_for_reused_ondisk_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_build_path_for_reused_ondisk_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_follow_ondisk_next_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_follow_ondisk_next_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_follow_ondisk_next_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_follow_ondisk_next_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_set_initial_ondisk_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_set_initial_ondisk_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_set_initial_ondisk_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_set_initial_ondisk_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_build_path_for_ondisk_append_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_build_path_for_ondisk_append_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_build_path_for_ondisk_append_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_build_path_for_ondisk_append_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_build_path_for_ondisk_neighbor_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_build_path_for_ondisk_neighbor_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_build_path_for_ondisk_neighbor_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_build_path_for_ondisk_neighbor_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_build_path_for_ondisk_duplicate_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_build_path_for_ondisk_duplicate_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_build_path_for_ondisk_duplicate_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_build_path_for_ondisk_duplicate_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_abort_ondisk_duplicate_slot_reject(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_abort_ondisk_duplicate_slot_reject'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_abort_ondisk_duplicate_slot_reject(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_abort_ondisk_duplicate_slot_reject'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_break_on_invalid_ondisk_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_break_on_invalid_ondisk_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_break_on_invalid_ondisk_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_break_on_invalid_ondisk_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_free_ondisk_neighbor_slot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_free_ondisk_neighbor_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_free_ondisk_neighbor_slot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_free_ondisk_neighbor_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_on_invalid_ondisk_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_on_invalid_ondisk_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_on_invalid_ondisk_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_on_invalid_ondisk_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_non_element_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_non_element_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_non_element_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_non_element_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_non_element_vacuum_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_non_element_vacuum_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_non_element_vacuum_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_non_element_vacuum_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_process_vacuum_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_process_vacuum_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_process_vacuum_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_process_vacuum_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_mark_vacuum_tuple_deleted(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_mark_vacuum_tuple_deleted'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_mark_vacuum_tuple_deleted(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_mark_vacuum_tuple_deleted'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_vacuum_heaptid_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_vacuum_heaptid_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_vacuum_heaptid_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_vacuum_heaptid_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_remove_vacuum_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_remove_vacuum_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_remove_vacuum_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_remove_vacuum_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_compact_vacuum_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_compact_vacuum_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_compact_vacuum_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_compact_vacuum_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_finish_vacuum_page_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_finish_vacuum_page_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_finish_vacuum_page_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_finish_vacuum_page_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_invalid_vacuum_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_invalid_vacuum_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_invalid_vacuum_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_invalid_vacuum_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_flag_deleted_vacuum_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_flag_deleted_vacuum_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_flag_deleted_vacuum_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_flag_deleted_vacuum_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_check_vacuum_underfilled_layer0(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_check_vacuum_underfilled_layer0'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_check_vacuum_underfilled_layer0(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_check_vacuum_underfilled_layer0'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_vacuum_entrypoint_element(integer, integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_vacuum_entrypoint_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_vacuum_entrypoint_element(integer, integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_vacuum_entrypoint_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_vacuum_element_without_updates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_vacuum_element_without_updates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_vacuum_element_without_updates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_vacuum_element_without_updates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_promote_vacuum_entrypoint(integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_promote_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_promote_vacuum_entrypoint(integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_promote_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reset_vacuum_highest_point(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reset_vacuum_highest_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reset_vacuum_highest_point(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reset_vacuum_highest_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_repair_vacuum_highest_point(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_repair_vacuum_highest_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_repair_vacuum_highest_point(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_repair_vacuum_highest_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_repair_vacuum_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_repair_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_repair_vacuum_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_repair_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reset_vacuum_entrypoint_neighbors(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reset_vacuum_entrypoint_neighbors'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reset_vacuum_entrypoint_neighbors(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reset_vacuum_entrypoint_neighbors'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_replace_deleted_vacuum_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_replace_deleted_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_replace_deleted_vacuum_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_replace_deleted_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_repair_nonnull_vacuum_highest_point(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_repair_nonnull_vacuum_highest_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_repair_nonnull_vacuum_highest_point(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_repair_nonnull_vacuum_highest_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_process_nonnull_vacuum_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_process_nonnull_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_process_nonnull_vacuum_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_process_nonnull_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_deleted_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_deleted_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_deleted_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_deleted_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_non_element_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_non_element_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_non_element_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_non_element_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_live_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_live_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_live_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_live_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_set_vacuum_insert_page_when_missing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_set_vacuum_insert_page_when_missing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_set_vacuum_insert_page_when_missing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_set_vacuum_insert_page_when_missing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_non_element_repairgraph_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_non_element_repairgraph_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_non_element_repairgraph_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_non_element_repairgraph_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_deleted_repairgraph_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_deleted_repairgraph_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_deleted_repairgraph_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_deleted_repairgraph_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_track_vacuum_highest_non_entrypoint(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_track_vacuum_highest_non_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_track_vacuum_highest_non_entrypoint(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_track_vacuum_highest_non_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_vacuum_neighbor_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_vacuum_neighbor_overwrite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_vacuum_neighbor_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_vacuum_neighbor_overwrite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_init_vacuum_stats_when_missing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_init_vacuum_stats_when_missing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_init_vacuum_stats_when_missing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_init_vacuum_stats_when_missing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_vacuum_cleanup_analyze_only(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_vacuum_cleanup_analyze_only'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_vacuum_cleanup_analyze_only(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_vacuum_cleanup_analyze_only'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_null_vacuum_cleanup_stats(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_null_vacuum_cleanup_stats'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_null_vacuum_cleanup_stats(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_null_vacuum_cleanup_stats'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_release_markdeleted_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_release_markdeleted_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_release_markdeleted_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_release_markdeleted_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reset_markdeleted_version(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reset_markdeleted_version'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reset_markdeleted_version(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reset_markdeleted_version'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reuse_deleted_ondisk_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reuse_deleted_ondisk_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reuse_deleted_ondisk_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reuse_deleted_ondisk_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_set_insert_page_when_missing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_set_insert_page_when_missing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_set_insert_page_when_missing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_set_insert_page_when_missing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reuse_element_buffer_for_neighbor_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reuse_element_buffer_for_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reuse_element_buffer_for_neighbor_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reuse_element_buffer_for_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_release_reused_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_release_reused_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_release_reused_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_release_reused_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_distinct_neighbor_page_space(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_distinct_neighbor_page_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_distinct_neighbor_page_space(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_distinct_neighbor_page_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reuse_deleted_tuple_space(bigint, bigint, bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reuse_deleted_tuple_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reuse_deleted_tuple_space(bigint, bigint, bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reuse_deleted_tuple_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_borrow_same_page_neighbor_space(bigint, bigint, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_borrow_same_page_neighbor_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_borrow_same_page_neighbor_space(bigint, bigint, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_borrow_same_page_neighbor_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_register_reused_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_register_reused_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_register_reused_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_register_reused_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_probe_for_free_neighbor_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_probe_for_free_neighbor_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_probe_for_free_neighbor_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_probe_for_free_neighbor_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_existing_neighbor_update(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_existing_neighbor_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_existing_neighbor_update(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_existing_neighbor_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_apply_neighbor_update_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_apply_neighbor_update_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_apply_neighbor_update_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_apply_neighbor_update_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_probe_undecided_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_probe_undecided_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_probe_undecided_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_probe_undecided_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_match_neighbor_connection(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_match_neighbor_connection'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_match_neighbor_connection(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_match_neighbor_connection'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_update_connection_from_candidate_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_update_connection_from_candidate_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_update_connection_from_candidate_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_update_connection_from_candidate_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_ondisk_element_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_ondisk_element_overwrite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_ondisk_element_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_ondisk_element_overwrite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_ondisk_unexpected_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_ondisk_unexpected_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_ondisk_unexpected_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_ondisk_unexpected_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_empty_without_neighbor_tids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_empty_without_neighbor_tids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_empty_without_neighbor_tids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_empty_without_neighbor_tids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_prune_deleted_insert_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_prune_deleted_insert_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_prune_deleted_insert_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_prune_deleted_insert_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_unregister_mvcc_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_unregister_mvcc_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_unregister_mvcc_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_unregister_mvcc_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_finish_parallel_heap_scan(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_finish_parallel_heap_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_finish_parallel_heap_scan(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_finish_parallel_heap_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});

my $parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_handler_probe() = rust_hnsw_handler_probe(),
		   rust_hnsw_handler_probe() LIKE 'rust-hnsw-handler-%';
});
is($parity, "t|t");

my $disable_without_order_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_disable_without_order(orderby_count) =
		   rust_hnsw_should_disable_without_order(orderby_count)
	FROM (VALUES
		(0),
		(1),
		(2),
		(5)
	) AS t(orderby_count);
});
is($disable_without_order_parity, "t\nt\nt\nt");

my $clamp_ratio_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_clamp_ratio(ratio) = rust_hnsw_clamp_ratio(ratio)
	FROM (VALUES
		(0.0::double precision),
		(0.2::double precision),
		(1.0::double precision),
		(1.5::double precision)
	) AS t(ratio);
});
is($clamp_ratio_parity, "t\nt\nt\nt");

my $adjust_startup_cost_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_adjust_startup_cost(startup_pages, rel_pages, ratio) =
		   rust_hnsw_should_adjust_startup_cost(startup_pages, rel_pages, ratio)
	FROM (VALUES
		(10.0::double precision, 9.0::double precision, 0.4::double precision),
		(10.0::double precision, 9.0::double precision, 0.5::double precision),
		(9.0::double precision, 9.0::double precision, 0.4::double precision),
		(8.0::double precision, 9.0::double precision, 0.1::double precision)
	) AS t(startup_pages, rel_pages, ratio);
});
is($adjust_startup_cost_parity, "t\nt\nt\nt");

my $compute_scan_ratio_from_tuples_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_compute_scan_ratio_from_tuples(tuple_count) =
		   rust_hnsw_should_compute_scan_ratio_from_tuples(tuple_count)
	FROM (VALUES
		(-1.0::double precision),
		(0.0::double precision),
		(0.01::double precision),
		(200.0::double precision)
	) AS t(tuple_count);
});
is($compute_scan_ratio_from_tuples_parity, "t\nt\nt\nt");

my $init_lock_tranche_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_init_lock_tranche(preload_in_progress) =
		   rust_hnsw_should_init_lock_tranche(preload_in_progress)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(preload_in_progress);
});
is($init_lock_tranche_parity, "t\nt\nt\nt");

my $assign_new_lock_tranche_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_assign_new_lock_tranche(found) =
		   rust_hnsw_should_assign_new_lock_tranche(found)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(found);
});
is($assign_new_lock_tranche_parity, "t\nt\nt\nt");

my $return_empty_without_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_empty_without_entrypoint(entry_point_is_null) =
		   rust_hnsw_should_return_empty_without_entrypoint(entry_point_is_null)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(entry_point_is_null);
});
is($return_empty_without_entrypoint_parity, "t\nt\nt\nt");

my $resume_from_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_resume_from_discarded(discarded_is_empty) =
		   rust_hnsw_should_resume_from_discarded(discarded_is_empty)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(discarded_is_empty);
});
is($resume_from_discarded_parity, "t\nt\nt\nt");

my $return_remaining_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_remaining_discarded(discarded_is_empty) =
		   rust_hnsw_should_return_remaining_discarded(discarded_is_empty)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(discarded_is_empty);
});
is($return_remaining_discarded_parity, "t\nt\nt\nt");

my $skip_strict_out_of_order_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_strict_out_of_order(iterative_scan_mode, distance, previous_distance) =
		   rust_hnsw_should_skip_strict_out_of_order(iterative_scan_mode, distance, previous_distance)
	FROM (VALUES
		(2, 0.1::double precision, 0.2::double precision),
		(2, 0.2::double precision, 0.2::double precision),
		(1, 0.1::double precision, 0.2::double precision),
		(0, 0.0::double precision, 1.0::double precision)
	) AS t(iterative_scan_mode, distance, previous_distance);
});
is($skip_strict_out_of_order_parity, "t\nt\nt\nt");

my $stop_without_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_without_discarded(discarded_is_null) =
		   rust_hnsw_should_stop_without_discarded(discarded_is_null)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(discarded_is_null);
});
is($stop_without_discarded_parity, "t\nt\nt\nt");

my $stop_when_iterative_scan_off_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_when_iterative_scan_off(iterative_scan_mode) =
		   rust_hnsw_should_stop_when_iterative_scan_off(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(0)
	) AS t(iterative_scan_mode);
});
is($stop_when_iterative_scan_off_parity, "t\nt\nt\nt");

my $limit_scan_by_resources_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_limit_scan_by_resources(tuple_count, max_scan_tuples, memory_used, max_memory) =
		   rust_hnsw_should_limit_scan_by_resources(tuple_count, max_scan_tuples, memory_used, max_memory)
	FROM (VALUES
		(10::bigint, 20::bigint, 100::bigint, 200::bigint),
		(20::bigint, 20::bigint, 100::bigint, 200::bigint),
		(10::bigint, 20::bigint, 201::bigint, 200::bigint),
		(30::bigint, 20::bigint, 50::bigint, 200::bigint)
	) AS t(tuple_count, max_scan_tuples, memory_used, max_memory);
});
is($limit_scan_by_resources_parity, "t\nt\nt\nt");

my $release_iterative_scan_memory_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_release_iterative_scan_memory(iterative_scan_mode) =
		   rust_hnsw_should_release_iterative_scan_memory(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(0)
	) AS t(iterative_scan_mode);
});
is($release_iterative_scan_memory_parity, "t\nt\nt\nt");

my $update_previous_distance_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_update_previous_distance(iterative_scan_mode) =
		   rust_hnsw_should_update_previous_distance(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(2)
	) AS t(iterative_scan_mode);
});
is($update_previous_distance_parity, "t\nt\nt\nt");

my $flush_graph_pages_at_end_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_flush_graph_pages_at_end(graph_flushed) =
		   rust_hnsw_should_flush_graph_pages_at_end(graph_flushed)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(graph_flushed);
});
is($flush_graph_pages_at_end_parity, "t\nt\nt\nt");

my $begin_parallel_build_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_begin_parallel_build(parallel_workers) =
		   rust_hnsw_should_begin_parallel_build(parallel_workers)
	FROM (VALUES
		(0),
		(1),
		(4),
		(-1)
	) AS t(parallel_workers);
});
is($begin_parallel_build_parity, "t\nt\nt\nt");

my $end_parallel_build_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_end_parallel_build(has_leader) =
		   rust_hnsw_should_end_parallel_build(has_leader)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_leader);
});
is($end_parallel_build_parity, "t\nt\nt\nt");

my $scan_heap_for_build_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_scan_heap_for_build(has_heap) =
		   rust_hnsw_should_scan_heap_for_build(has_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_heap);
});
is($scan_heap_for_build_parity, "t\nt\nt\nt");

my $use_parallel_heap_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_parallel_heap_scan(has_leader) =
		   rust_hnsw_should_use_parallel_heap_scan(has_leader)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_leader);
});
is($use_parallel_heap_scan_parity, "t\nt\nt\nt");

my $reject_inmemory_duplicate_heaptid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_inmemory_duplicate_heaptid(heaptids_length, max_heaptids) =
		   rust_hnsw_should_reject_inmemory_duplicate_heaptid(heaptids_length, max_heaptids)
	FROM (VALUES
		(0, 10),
		(9, 10),
		(10, 10),
		(11, 10)
	) AS t(heaptids_length, max_heaptids);
});
is($reject_inmemory_duplicate_heaptid_parity, "t\nt\nt\nt");

my $handle_empty_work_list_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_handle_empty_work_list(work_list_length) =
		   rust_hnsw_should_handle_empty_work_list(work_list_length)
	FROM (VALUES
		(0),
		(1),
		(3),
		(0)
	) AS t(work_list_length);
});
is($handle_empty_work_list_parity, "t\nt\nt\nt");

my $advance_on_exhausted_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_advance_on_exhausted_heaptids(heaptids_length) =
		   rust_hnsw_should_advance_on_exhausted_heaptids(heaptids_length)
	FROM (VALUES
		(0),
		(1),
		(5),
		(0)
	) AS t(heaptids_length);
});
is($advance_on_exhausted_heaptids_parity, "t\nt\nt\nt");

my $reject_missing_orderby_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_missing_orderby(orderby_is_null) =
		   rust_hnsw_should_reject_missing_orderby(orderby_is_null)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(orderby_is_null);
});
is($reject_missing_orderby_parity, "t\nt\nt\nt");

my $reject_non_mvcc_snapshot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_non_mvcc_snapshot(snapshot_is_mvcc) =
		   rust_hnsw_should_reject_non_mvcc_snapshot(snapshot_is_mvcc)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(snapshot_is_mvcc);
});
is($reject_non_mvcc_snapshot_parity, "t\nt\nt\nt");

my $copy_rescan_keys_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_copy_rescan_keys(has_keys, key_count) =
		   rust_hnsw_should_copy_rescan_keys(has_keys, key_count)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(0, 3),
		(1, 3)
	) AS t(has_keys, key_count);
});
is($copy_rescan_keys_parity, "t\nt\nt\nt");

my $use_null_scan_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_null_scan_value(orderby_is_null) =
		   rust_hnsw_should_use_null_scan_value(orderby_is_null)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(orderby_is_null);
});
is($use_null_scan_value_parity, "t\nt\nt\nt");

my $normalize_scan_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_normalize_scan_value(has_normproc) =
		   rust_hnsw_should_normalize_scan_value(has_normproc)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_normproc);
});
is($normalize_scan_value_parity, "t\nt\nt\nt");

my $initialize_scan_state_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_initialize_scan_state(is_first_scan) =
		   rust_hnsw_should_initialize_scan_state(is_first_scan)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_first_scan);
});
is($initialize_scan_state_parity, "t\nt\nt\nt");

my $increment_instrument_searches_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_increment_instrument_searches(has_instrument) =
		   rust_hnsw_should_increment_instrument_searches(has_instrument)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_instrument);
});
is($increment_instrument_searches_parity, "t\nt\nt\nt");

my $skip_parallel_workers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_parallel_workers(parallel_workers) =
		   rust_hnsw_should_skip_parallel_workers(parallel_workers)
	FROM (VALUES
		(0),
		(1),
		(-1),
		(8)
	) AS t(parallel_workers);
});
is($skip_parallel_workers_parity, "t\nt\nt\nt");

my $use_relation_parallel_workers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_relation_parallel_workers(parallel_workers) =
		   rust_hnsw_should_use_relation_parallel_workers(parallel_workers)
	FROM (VALUES
		(-1),
		(0),
		(4),
		(2)
	) AS t(parallel_workers);
});
is($use_relation_parallel_workers_parity, "t\nt\nt\nt");

my $fallback_without_workers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_fallback_without_workers(workers_launched) =
		   rust_hnsw_should_fallback_without_workers(workers_launched)
	FROM (VALUES
		(0),
		(1),
		(2),
		(0)
	) AS t(workers_launched);
});
is($fallback_without_workers_parity, "t\nt\nt\nt");

my $leader_participate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_leader_participate(leader_participates) =
		   rust_hnsw_should_leader_participate(leader_participates)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(leader_participates);
});
is($leader_participate_parity, "t\nt\nt\nt");

my $use_debug_query_string_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_debug_query_string(has_debug_query_string) =
		   rust_hnsw_should_use_debug_query_string(has_debug_query_string)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_debug_query_string);
});
is($use_debug_query_string_parity, "t\nt\nt\nt");

my $use_non_concurrent_snapshot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_non_concurrent_snapshot(is_concurrent) =
		   rust_hnsw_should_use_non_concurrent_snapshot(is_concurrent)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_concurrent);
});
is($use_non_concurrent_snapshot_parity, "t\nt\nt\nt");

my $use_non_concurrent_lock_modes_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_non_concurrent_lock_modes(is_concurrent) =
		   rust_hnsw_should_use_non_concurrent_lock_modes(is_concurrent)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_concurrent);
});
is($use_non_concurrent_lock_modes_parity, "t\nt\nt\nt");

my $fallback_without_dsm_segment_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_fallback_without_dsm_segment(has_dsm_segment) =
		   rust_hnsw_should_fallback_without_dsm_segment(has_dsm_segment)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_dsm_segment);
});
is($fallback_without_dsm_segment_parity, "t\nt\nt\nt");

my $reserve_graph_memory_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reserve_graph_memory(est_hnsw_area, est_other) =
		   rust_hnsw_should_reserve_graph_memory(est_hnsw_area, est_other)
	FROM (VALUES
		(64::bigint, 3::bigint),
		(3::bigint, 3::bigint),
		(2::bigint, 3::bigint),
		(100::bigint, 25::bigint)
	) AS t(est_hnsw_area, est_other);
});
is($reserve_graph_memory_parity, "t\nt\nt\nt");

my $log_leader_progress_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_log_leader_progress(progress_is_leader) =
		   rust_hnsw_should_log_leader_progress(progress_is_leader)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(progress_is_leader);
});
is($log_leader_progress_parity, "t\nt\nt\nt");

my $reject_varbit_type_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_varbit_type(type_oid) =
		   rust_hnsw_should_reject_varbit_type(type_oid)
	FROM (
		SELECT unnest(ARRAY[
			0::integer,
			'varbit'::regtype::oid::integer,
			42::integer,
			'varbit'::regtype::oid::integer
		]) AS type_oid
	) AS t;
});
is($reject_varbit_type_parity, "t\nt\nt\nt");

my $reject_missing_dimensions_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_missing_dimensions(dimensions) =
		   rust_hnsw_should_reject_missing_dimensions(dimensions)
	FROM (VALUES
		(-1),
		(0),
		(1024),
		(-42)
	) AS t(dimensions);
});
is($reject_missing_dimensions_parity, "t\nt\nt\nt");

my $reject_excess_dimensions_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_excess_dimensions(dimensions, max_dimensions) =
		   rust_hnsw_should_reject_excess_dimensions(dimensions, max_dimensions)
	FROM (VALUES
		(3, 3),
		(4, 3),
		(16, 1024),
		(2048, 1024)
	) AS t(dimensions, max_dimensions);
});
is($reject_excess_dimensions_parity, "t\nt\nt\nt");

my $reject_low_ef_construction_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_low_ef_construction(ef_construction, m) =
		   rust_hnsw_should_reject_low_ef_construction(ef_construction, m)
	FROM (VALUES
		(15, 8),
		(16, 8),
		(31, 16),
		(32, 16)
	) AS t(ef_construction, m);
});
is($reject_low_ef_construction_parity, "t\nt\nt\nt");

my $write_wal_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_write_wal_page(needs_wal, is_init_fork) =
		   rust_hnsw_should_write_wal_page(needs_wal, is_init_fork)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(0, 1),
		(1, 1)
	) AS t(needs_wal, is_init_fork);
});
is($write_wal_page_parity, "t\nt\nt\nt");

my $skip_null_build_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_null_build_tuple(is_null) =
		   rust_hnsw_should_skip_null_build_tuple(is_null)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_null);
});
is($skip_null_build_tuple_parity, "t\nt\nt\nt");

my $update_progress_after_insert_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_update_progress_after_insert(tuple_inserted) =
		   rust_hnsw_should_update_progress_after_insert(tuple_inserted)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(tuple_inserted);
});
is($update_progress_after_insert_parity, "t\nt\nt\nt");

my $store_neighbors_on_same_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_store_neighbors_on_same_page(combined_size, max_size) =
		   rust_hnsw_should_store_neighbors_on_same_page(combined_size, max_size)
	FROM (VALUES
		(10::bigint, 12::bigint),
		(12::bigint, 12::bigint),
		(13::bigint, 12::bigint),
		(1024::bigint, 2048::bigint)
	) AS t(combined_size, max_size);
});
is($store_neighbors_on_same_page_parity, "t\nt\nt\nt");

my $reject_oversized_element_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_oversized_element_tuple(tuple_size, alloc_size) =
		   rust_hnsw_should_reject_oversized_element_tuple(tuple_size, alloc_size)
	FROM (VALUES
		(32::bigint, 64::bigint),
		(64::bigint, 64::bigint),
		(65::bigint, 64::bigint),
		(2048::bigint, 1024::bigint)
	) AS t(tuple_size, alloc_size);
});
is($reject_oversized_element_tuple_parity, "t\nt\nt\nt");

my $append_neighbor_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_append_neighbor_page(free_space, neighbor_tuple_size) =
		   rust_hnsw_should_append_neighbor_page(free_space, neighbor_tuple_size)
	FROM (VALUES
		(8::bigint, 16::bigint),
		(16::bigint, 16::bigint),
		(32::bigint, 16::bigint),
		(0::bigint, 1::bigint)
	) AS t(free_space, neighbor_tuple_size);
});
is($append_neighbor_page_parity, "t\nt\nt\nt");

my $append_element_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_append_element_page(free_space, element_tuple_size, combined_size, max_size) =
		   rust_hnsw_should_append_element_page(free_space, element_tuple_size, combined_size, max_size)
	FROM (VALUES
		(4::bigint, 8::bigint, 16::bigint, 32::bigint),
		(12::bigint, 8::bigint, 16::bigint, 32::bigint),
		(20::bigint, 8::bigint, 16::bigint, 32::bigint),
		(20::bigint, 8::bigint, 48::bigint, 32::bigint)
	) AS t(free_space, element_tuple_size, combined_size, max_size);
});
is($append_element_page_parity, "t\nt\nt\nt");

my $reject_unexpected_item_offset_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_unexpected_item_offset(inserted_offset, expected_offset) =
		   rust_hnsw_should_reject_unexpected_item_offset(inserted_offset, expected_offset)
	FROM (VALUES
		(1, 1),
		(2, 1),
		(8, 8),
		(0, 1)
	) AS t(inserted_offset, expected_offset);
});
is($reject_unexpected_item_offset_parity, "t\nt\nt\nt");

my $reject_neighbor_overwrite_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_neighbor_overwrite(overwrite_succeeded) =
		   rust_hnsw_should_reject_neighbor_overwrite(overwrite_succeeded)
	FROM (VALUES
		(1),
		(0),
		(1),
		(0)
	) AS t(overwrite_succeeded);
});
is($reject_neighbor_overwrite_parity, "t\nt\nt\nt");

my $skip_invalid_index_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_invalid_index_value(index_value_formed) =
		   rust_hnsw_should_skip_invalid_index_value(index_value_formed)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(index_value_formed);
});
is($skip_invalid_index_value_parity, "t\nt\nt\nt");

my $stop_duplicate_search_on_value_mismatch_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_duplicate_search_on_value_mismatch(values_equal) =
		   rust_hnsw_should_stop_duplicate_search_on_value_mismatch(values_equal)
	FROM (VALUES
		(1),
		(0),
		(0),
		(1)
	) AS t(values_equal);
});
is($stop_duplicate_search_on_value_mismatch_parity, "t\nt\nt\nt");

my $return_after_duplicate_insert_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_after_duplicate_insert(duplicate_inserted) =
		   rust_hnsw_should_return_after_duplicate_insert(duplicate_inserted)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(duplicate_inserted);
});
is($return_after_duplicate_insert_parity, "t\nt\nt\nt");

my $skip_update_graph_for_duplicate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_update_graph_for_duplicate(duplicate_found) =
		   rust_hnsw_should_skip_update_graph_for_duplicate(duplicate_found)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(duplicate_found);
});
is($skip_update_graph_for_duplicate_parity, "t\nt\nt\nt");

my $skip_null_insert_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_null_insert_tuple(is_null) =
		   rust_hnsw_should_skip_null_insert_tuple(is_null)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_null);
});
is($skip_null_insert_tuple_parity, "t\nt\nt\nt");

my $update_entrypoint_ondisk_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_update_entrypoint_ondisk(entrypoint_is_null, element_level, entry_level) =
		   rust_hnsw_should_update_entrypoint_ondisk(entrypoint_is_null, element_level, entry_level)
	FROM (VALUES
		(1, 0, -1),
		(0, 2, 1),
		(0, 1, 1),
		(0, 0, 1)
	) AS t(entrypoint_is_null, element_level, entry_level);
});
is($update_entrypoint_ondisk_parity, "t\nt\nt\nt");

my $skip_invalid_insert_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_invalid_insert_value(index_value_formed) =
		   rust_hnsw_should_skip_invalid_insert_value(index_value_formed)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(index_value_formed);
});
is($skip_invalid_insert_value_parity, "t\nt\nt\nt");

my $stop_ondisk_duplicate_search_on_value_mismatch_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch(values_equal) =
		   rust_hnsw_should_stop_ondisk_duplicate_search_on_value_mismatch(values_equal)
	FROM (VALUES
		(1),
		(0),
		(0),
		(1)
	) AS t(values_equal);
});
is($stop_ondisk_duplicate_search_on_value_mismatch_parity, "t\nt\nt\nt");

my $return_after_ondisk_duplicate_insert_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_after_ondisk_duplicate_insert(duplicate_inserted) =
		   rust_hnsw_should_return_after_ondisk_duplicate_insert(duplicate_inserted)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(duplicate_inserted);
});
is($return_after_ondisk_duplicate_insert_parity, "t\nt\nt\nt");

my $skip_ondisk_graph_update_for_duplicate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_ondisk_graph_update_for_duplicate(duplicate_found) =
		   rust_hnsw_should_skip_ondisk_graph_update_for_duplicate(duplicate_found)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(duplicate_found);
});
is($skip_ondisk_graph_update_for_duplicate_parity, "t\nt\nt\nt");

my $update_ondisk_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_update_ondisk_insert_page(has_new_insert_page) =
		   rust_hnsw_should_update_ondisk_insert_page(has_new_insert_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_new_insert_page);
});
is($update_ondisk_insert_page_parity, "t\nt\nt\nt");

my $reject_ondisk_duplicate_insert_slot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_ondisk_duplicate_insert_slot(free_slot_index, max_heaptids) =
		   rust_hnsw_should_reject_ondisk_duplicate_insert_slot(free_slot_index, max_heaptids)
	FROM (VALUES
		(0, 10),
		(3, 10),
		(10, 10),
		(1, 2)
	) AS t(free_slot_index, max_heaptids);
});
is($reject_ondisk_duplicate_insert_slot_parity, "t\nt\nt\nt");

my $commit_ondisk_duplicate_with_buffer_dirty_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty(building) =
		   rust_hnsw_should_commit_ondisk_duplicate_with_buffer_dirty(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($commit_ondisk_duplicate_with_buffer_dirty_parity, "t\nt\nt\nt");

my $skip_unselected_ondisk_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_unselected_ondisk_neighbor(update_index) =
		   rust_hnsw_should_skip_unselected_ondisk_neighbor(update_index)
	FROM (VALUES
		(-1),
		(0),
		(3),
		(-1)
	) AS t(update_index);
});
is($skip_unselected_ondisk_neighbor_parity, "t\nt\nt\nt");

my $commit_ondisk_neighbor_update_with_buffer_dirty_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty(building) =
		   rust_hnsw_should_commit_ondisk_neighbor_update_with_buffer_dirty(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($commit_ondisk_neighbor_update_with_buffer_dirty_parity, "t\nt\nt\nt");

my $abort_ondisk_neighbor_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_abort_ondisk_neighbor_update(building) =
		   rust_hnsw_should_abort_ondisk_neighbor_update(building)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(building);
});
is($abort_ondisk_neighbor_update_parity, "t\nt\nt\nt");

my $append_ondisk_neighbor_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_append_ondisk_neighbor_page(free_space, tuple_size) =
		   rust_hnsw_should_append_ondisk_neighbor_page(free_space, tuple_size)
	FROM (VALUES
		(0, 1),
		(128, 128),
		(127, 128),
		(1024, 512)
	) AS t(free_space, tuple_size);
});
is($append_ondisk_neighbor_page_parity, "t\nt\nt\nt");

my $append_ondisk_element_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_append_ondisk_element_page(combined_size, max_size, free_space, element_tuple_size, has_next_page) =
		   rust_hnsw_should_append_ondisk_element_page(combined_size, max_size, free_space, element_tuple_size, has_next_page)
	FROM (VALUES
		(300, 256, 128, 64, 0),
		(300, 256, 32, 64, 0),
		(200, 256, 128, 64, 0),
		(300, 256, 128, 64, 1)
	) AS t(combined_size, max_size, free_space, element_tuple_size, has_next_page);
});
is($append_ondisk_element_page_parity, "t\nt\nt\nt");

my $abort_ondisk_element_move_next_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_abort_ondisk_element_move_next(building) =
		   rust_hnsw_should_abort_ondisk_element_move_next(building)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(building);
});
is($abort_ondisk_element_move_next_parity, "t\nt\nt\nt");

my $commit_ondisk_add_element_with_buffer_dirty_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_commit_ondisk_add_element_with_buffer_dirty(building) =
		   rust_hnsw_should_commit_ondisk_add_element_with_buffer_dirty(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($commit_ondisk_add_element_with_buffer_dirty_parity, "t\nt\nt\nt");

my $mark_ondisk_neighbor_buffer_dirty_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_mark_ondisk_neighbor_buffer_dirty(same_buffer) =
		   rust_hnsw_should_mark_ondisk_neighbor_buffer_dirty(same_buffer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_buffer);
});
is($mark_ondisk_neighbor_buffer_dirty_parity, "t\nt\nt\nt");

my $update_add_element_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_update_add_element_insert_page(has_new_insert_page, page_changed) =
		   rust_hnsw_should_update_add_element_insert_page(has_new_insert_page, page_changed)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(0, 1),
		(1, 1)
	) AS t(has_new_insert_page, page_changed);
});
is($update_add_element_insert_page_parity, "t\nt\nt\nt");

my $release_ondisk_neighbor_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_release_ondisk_neighbor_buffer(same_buffer) =
		   rust_hnsw_should_release_ondisk_neighbor_buffer(same_buffer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_buffer);
});
is($release_ondisk_neighbor_buffer_parity, "t\nt\nt\nt");

my $use_neighbor_page_as_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_neighbor_page_as_insert_page(has_new_insert_page) =
		   rust_hnsw_should_use_neighbor_page_as_insert_page(has_new_insert_page)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_new_insert_page);
});
is($use_neighbor_page_as_insert_page_parity, "t\nt\nt\nt");

my $use_next_neighbor_offset_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_next_neighbor_offset(same_buffer) =
		   rust_hnsw_should_use_next_neighbor_offset(same_buffer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_buffer);
});
is($use_next_neighbor_offset_parity, "t\nt\nt\nt");

my $use_free_ondisk_offsets_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_free_ondisk_offsets(free_offset_valid) =
		   rust_hnsw_should_use_free_ondisk_offsets(free_offset_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(free_offset_valid);
});
is($use_free_ondisk_offsets_parity, "t\nt\nt\nt");

my $process_free_offset_result_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_process_free_offset_result(free_offset_result) =
		   rust_hnsw_should_process_free_offset_result(free_offset_result)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(free_offset_result);
});
is($process_free_offset_result_parity, "t\nt\nt\nt");

my $zero_distance_for_null_query_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_zero_distance_for_null_query_value(has_query_value) =
		   rust_hnsw_should_zero_distance_for_null_query_value(has_query_value)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_query_value);
});
is($zero_distance_for_null_query_value_parity, "t\nt\nt\nt");

my $calculate_element_distance_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_calculate_element_distance(has_distance_pointer) =
		   rust_hnsw_should_calculate_element_distance(has_distance_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_distance_pointer);
});
is($calculate_element_distance_parity, "t\nt\nt\nt");

my $update_element_max_distance_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_update_element_max_distance(has_distance, has_max_distance, distance_value, max_distance_value) =
		   rust_hnsw_should_update_element_max_distance(has_distance, has_max_distance, distance_value, max_distance_value)
	FROM (VALUES
		(0, 1, 0.20::float8, 0.10::float8),
		(1, 0, 0.20::float8, 0.10::float8),
		(1, 1, 0.05::float8, 0.10::float8),
		(1, 1, 0.30::float8, 0.10::float8)
	) AS t(has_distance, has_max_distance, distance_value, max_distance_value);
});
is($update_element_max_distance_parity, "t\nt\nt\nt");

my $initialize_loaded_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_initialize_loaded_element(has_element) =
		   rust_hnsw_should_initialize_loaded_element(has_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_element);
});
is($initialize_loaded_element_parity, "t\nt\nt\nt");

my $load_element_vector_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_load_element_vector(load_vector) =
		   rust_hnsw_should_load_element_vector(load_vector)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(load_vector);
});
is($load_element_vector_parity, "t\nt\nt\nt");

my $load_element_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_load_element_heaptids(load_heaptids) =
		   rust_hnsw_should_load_element_heaptids(load_heaptids)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(load_heaptids);
});
is($load_element_heaptids_parity, "t\nt\nt\nt");

my $stop_loading_element_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_loading_element_heaptids(heaptid_valid) =
		   rust_hnsw_should_stop_loading_element_heaptids(heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(heaptid_valid);
});
is($stop_loading_element_heaptids_parity, "t\nt\nt\nt");

my $count_without_skip_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_count_without_skip_element(has_skip_element) =
		   rust_hnsw_should_count_without_skip_element(has_skip_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_skip_element);
});
is($count_without_skip_element_parity, "t\nt\nt\nt");

my $fit_ondisk_combined_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_fit_ondisk_combined_tuple(free_space, combined_size) =
		   rust_hnsw_should_fit_ondisk_combined_tuple(free_space, combined_size)
	FROM (VALUES
		(0, 1),
		(128, 128),
		(256, 128),
		(127, 128)
	) AS t(free_space, combined_size);
});
is($fit_ondisk_combined_tuple_parity, "t\nt\nt\nt");

my $use_build_path_for_ondisk_add_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_build_path_for_ondisk_add_element(building) =
		   rust_hnsw_should_use_build_path_for_ondisk_add_element(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($use_build_path_for_ondisk_add_element_parity, "t\nt\nt\nt");

my $commit_ondisk_page_append_with_buffer_dirty_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_commit_ondisk_page_append_with_buffer_dirty(building) =
		   rust_hnsw_should_commit_ondisk_page_append_with_buffer_dirty(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($commit_ondisk_page_append_with_buffer_dirty_parity, "t\nt\nt\nt");

my $use_build_path_for_appended_ondisk_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_build_path_for_appended_ondisk_buffer(building) =
		   rust_hnsw_should_use_build_path_for_appended_ondisk_buffer(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($use_build_path_for_appended_ondisk_buffer_parity, "t\nt\nt\nt");

my $use_build_path_for_reused_ondisk_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_build_path_for_reused_ondisk_buffer(building) =
		   rust_hnsw_should_use_build_path_for_reused_ondisk_buffer(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($use_build_path_for_reused_ondisk_buffer_parity, "t\nt\nt\nt");

my $follow_ondisk_next_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_follow_ondisk_next_page(next_page_valid) =
		   rust_hnsw_should_follow_ondisk_next_page(next_page_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(next_page_valid);
});
is($follow_ondisk_next_page_parity, "t\nt\nt\nt");

my $set_initial_ondisk_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_set_initial_ondisk_insert_page(has_insert_page, has_space) =
		   rust_hnsw_should_set_initial_ondisk_insert_page(has_insert_page, has_space)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(0, 0),
		(1, 0)
	) AS t(has_insert_page, has_space);
});
is($set_initial_ondisk_insert_page_parity, "t\nt\nt\nt");

my $use_build_path_for_ondisk_append_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_build_path_for_ondisk_append_page(building) =
		   rust_hnsw_should_use_build_path_for_ondisk_append_page(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($use_build_path_for_ondisk_append_page_parity, "t\nt\nt\nt");

my $use_build_path_for_ondisk_neighbor_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_build_path_for_ondisk_neighbor_update(building) =
		   rust_hnsw_should_use_build_path_for_ondisk_neighbor_update(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($use_build_path_for_ondisk_neighbor_update_parity, "t\nt\nt\nt");

my $use_build_path_for_ondisk_duplicate_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_build_path_for_ondisk_duplicate_page(building) =
		   rust_hnsw_should_use_build_path_for_ondisk_duplicate_page(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($use_build_path_for_ondisk_duplicate_page_parity, "t\nt\nt\nt");

my $abort_ondisk_duplicate_slot_reject_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_abort_ondisk_duplicate_slot_reject(building) =
		   rust_hnsw_should_abort_ondisk_duplicate_slot_reject(building)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(building);
});
is($abort_ondisk_duplicate_slot_reject_parity, "t\nt\nt\nt");

my $break_on_invalid_ondisk_heaptid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_break_on_invalid_ondisk_heaptid(heap_tid_valid) =
		   rust_hnsw_should_break_on_invalid_ondisk_heaptid(heap_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(heap_tid_valid);
});
is($break_on_invalid_ondisk_heaptid_parity, "t\nt\nt\nt");

my $use_free_ondisk_neighbor_slot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_free_ondisk_neighbor_slot(slot_tid_valid) =
		   rust_hnsw_should_use_free_ondisk_neighbor_slot(slot_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(slot_tid_valid);
});
is($use_free_ondisk_neighbor_slot_parity, "t\nt\nt\nt");

my $stop_on_invalid_ondisk_neighbor_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_on_invalid_ondisk_neighbor_tid(neighbor_tid_valid) =
		   rust_hnsw_should_stop_on_invalid_ondisk_neighbor_tid(neighbor_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(neighbor_tid_valid);
});
is($stop_on_invalid_ondisk_neighbor_tid_parity, "t\nt\nt\nt");

my $skip_non_element_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_non_element_tuple(is_element_tuple) =
		   rust_hnsw_should_skip_non_element_tuple(is_element_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_element_tuple);
});
is($skip_non_element_tuple_parity, "t\nt\nt\nt");

my $skip_non_element_vacuum_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_non_element_vacuum_tuple(is_element_tuple) =
		   rust_hnsw_should_skip_non_element_vacuum_tuple(is_element_tuple)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(is_element_tuple);
});
is($skip_non_element_vacuum_tuple_parity, "t\nt\nt\nt");

my $process_vacuum_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_process_vacuum_heaptids(first_heaptid_valid) =
		   rust_hnsw_should_process_vacuum_heaptids(first_heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(first_heaptid_valid);
});
is($process_vacuum_heaptids_parity, "t\nt\nt\nt");

my $mark_vacuum_tuple_deleted_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_mark_vacuum_tuple_deleted(first_heaptid_valid) =
		   rust_hnsw_should_mark_vacuum_tuple_deleted(first_heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(first_heaptid_valid);
});
is($mark_vacuum_tuple_deleted_parity, "t\nt\nt\nt");

my $stop_vacuum_heaptid_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_vacuum_heaptid_scan(heaptid_valid) =
		   rust_hnsw_should_stop_vacuum_heaptid_scan(heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(heaptid_valid);
});
is($stop_vacuum_heaptid_scan_parity, "t\nt\nt\nt");

my $remove_vacuum_heaptid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_remove_vacuum_heaptid(callback_remove) =
		   rust_hnsw_should_remove_vacuum_heaptid(callback_remove)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(callback_remove);
});
is($remove_vacuum_heaptid_parity, "t\nt\nt\nt");

my $compact_vacuum_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_compact_vacuum_heaptids(item_updated) =
		   rust_hnsw_should_compact_vacuum_heaptids(item_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(item_updated);
});
is($compact_vacuum_heaptids_parity, "t\nt\nt\nt");

my $finish_vacuum_page_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_finish_vacuum_page_update(page_updated) =
		   rust_hnsw_should_finish_vacuum_page_update(page_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(page_updated);
});
is($finish_vacuum_page_update_parity, "t\nt\nt\nt");

my $skip_invalid_vacuum_neighbor_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_invalid_vacuum_neighbor_tid(neighbor_tid_valid) =
		   rust_hnsw_should_skip_invalid_vacuum_neighbor_tid(neighbor_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(neighbor_tid_valid);
});
is($skip_invalid_vacuum_neighbor_tid_parity, "t\nt\nt\nt");

my $flag_deleted_vacuum_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_flag_deleted_vacuum_neighbor(is_deleted_neighbor) =
		   rust_hnsw_should_flag_deleted_vacuum_neighbor(is_deleted_neighbor)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(is_deleted_neighbor);
});
is($flag_deleted_vacuum_neighbor_parity, "t\nt\nt\nt");

my $check_vacuum_underfilled_layer0_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_check_vacuum_underfilled_layer0(needs_updated) =
		   rust_hnsw_should_check_vacuum_underfilled_layer0(needs_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(needs_updated);
});
is($check_vacuum_underfilled_layer0_parity, "t\nt\nt\nt");

my $skip_vacuum_entrypoint_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_vacuum_entrypoint_element(has_entry_point, element_blkno, element_offno, entry_blkno, entry_offno) =
		   rust_hnsw_should_skip_vacuum_entrypoint_element(has_entry_point, element_blkno, element_offno, entry_blkno, entry_offno)
	FROM (VALUES
		(0, 1, 1, 1, 1),
		(1, 1, 1, 1, 1),
		(1, 2, 1, 1, 1),
		(1, 3, 4, 3, 4)
	) AS t(has_entry_point, element_blkno, element_offno, entry_blkno, entry_offno);
});
is($skip_vacuum_entrypoint_element_parity, "t\nt\nt\nt");

my $skip_vacuum_element_without_updates_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_vacuum_element_without_updates(needs_updated) =
		   rust_hnsw_should_skip_vacuum_element_without_updates(needs_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(needs_updated);
});
is($skip_vacuum_element_without_updates_parity, "t\nt\nt\nt");

my $promote_vacuum_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_promote_vacuum_entrypoint(entry_point_is_null, element_level, entry_level) =
		   rust_hnsw_should_promote_vacuum_entrypoint(entry_point_is_null, element_level, entry_level)
	FROM (VALUES
		(0, 1, 2),
		(1, 0, 5),
		(0, 6, 5),
		(0, 2, 2)
	) AS t(entry_point_is_null, element_level, entry_level);
});
is($promote_vacuum_entrypoint_parity, "t\nt\nt\nt");

my $reset_vacuum_highest_point_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reset_vacuum_highest_point(highest_point_valid) =
		   rust_hnsw_should_reset_vacuum_highest_point(highest_point_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(highest_point_valid);
});
is($reset_vacuum_highest_point_parity, "t\nt\nt\nt");

my $repair_vacuum_highest_point_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_repair_vacuum_highest_point(needs_updated) =
		   rust_hnsw_should_repair_vacuum_highest_point(needs_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(needs_updated);
});
is($repair_vacuum_highest_point_parity, "t\nt\nt\nt");

my $repair_vacuum_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_repair_vacuum_entrypoint(needs_updated) =
		   rust_hnsw_should_repair_vacuum_entrypoint(needs_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(needs_updated);
});
is($repair_vacuum_entrypoint_parity, "t\nt\nt\nt");

my $reset_vacuum_entrypoint_neighbors_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reset_vacuum_entrypoint_neighbors(has_highest_point) =
		   rust_hnsw_should_reset_vacuum_entrypoint_neighbors(has_highest_point)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_highest_point);
});
is($reset_vacuum_entrypoint_neighbors_parity, "t\nt\nt\nt");

my $replace_deleted_vacuum_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_replace_deleted_vacuum_entrypoint(is_deleted_entrypoint) =
		   rust_hnsw_should_replace_deleted_vacuum_entrypoint(is_deleted_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(is_deleted_entrypoint);
});
is($replace_deleted_vacuum_entrypoint_parity, "t\nt\nt\nt");

my $repair_nonnull_vacuum_highest_point_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_repair_nonnull_vacuum_highest_point(has_highest_point) =
		   rust_hnsw_should_repair_nonnull_vacuum_highest_point(has_highest_point)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_highest_point);
});
is($repair_nonnull_vacuum_highest_point_parity, "t\nt\nt\nt");

my $process_nonnull_vacuum_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_process_nonnull_vacuum_entrypoint(has_entrypoint) =
		   rust_hnsw_should_process_nonnull_vacuum_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($process_nonnull_vacuum_entrypoint_parity, "t\nt\nt\nt");

my $skip_deleted_markdeleted_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_deleted_markdeleted_tuple(is_deleted_tuple) =
		   rust_hnsw_should_skip_deleted_markdeleted_tuple(is_deleted_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_deleted_tuple);
});
is($skip_deleted_markdeleted_tuple_parity, "t\nt\nt\nt");

my $skip_non_element_markdeleted_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_non_element_markdeleted_tuple(is_element_tuple) =
		   rust_hnsw_should_skip_non_element_markdeleted_tuple(is_element_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_element_tuple);
});
is($skip_non_element_markdeleted_tuple_parity, "t\nt\nt\nt");

my $skip_live_markdeleted_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_live_markdeleted_tuple(is_live_tuple) =
		   rust_hnsw_should_skip_live_markdeleted_tuple(is_live_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_live_tuple);
});
is($skip_live_markdeleted_tuple_parity, "t\nt\nt\nt");

my $set_vacuum_insert_page_when_missing_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_set_vacuum_insert_page_when_missing(has_insert_page) =
		   rust_hnsw_should_set_vacuum_insert_page_when_missing(has_insert_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_insert_page);
});
is($set_vacuum_insert_page_when_missing_parity, "t\nt\nt\nt");

my $skip_non_element_repairgraph_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_non_element_repairgraph_tuple(is_element_tuple) =
		   rust_hnsw_should_skip_non_element_repairgraph_tuple(is_element_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_element_tuple);
});
is($skip_non_element_repairgraph_tuple_parity, "t\nt\nt\nt");

my $skip_deleted_repairgraph_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_deleted_repairgraph_element(is_live_tuple) =
		   rust_hnsw_should_skip_deleted_repairgraph_element(is_live_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_live_tuple);
});
is($skip_deleted_repairgraph_element_parity, "t\nt\nt\nt");

my $track_vacuum_highest_non_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_track_vacuum_highest_non_entrypoint(is_higher_level, is_entrypoint) =
		   rust_hnsw_should_track_vacuum_highest_non_entrypoint(is_higher_level, is_entrypoint)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(1, 1),
		(0, 1)
	) AS t(is_higher_level, is_entrypoint);
});
is($track_vacuum_highest_non_entrypoint_parity, "t\nt\nt\nt");

my $reject_vacuum_neighbor_overwrite_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_vacuum_neighbor_overwrite(overwrite_succeeded) =
		   rust_hnsw_should_reject_vacuum_neighbor_overwrite(overwrite_succeeded)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(overwrite_succeeded);
});
is($reject_vacuum_neighbor_overwrite_parity, "t\nt\nt\nt");

my $init_vacuum_stats_when_missing_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_init_vacuum_stats_when_missing(has_stats) =
		   rust_hnsw_should_init_vacuum_stats_when_missing(has_stats)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_stats);
});
is($init_vacuum_stats_when_missing_parity, "t\nt\nt\nt");

my $skip_vacuum_cleanup_analyze_only_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_vacuum_cleanup_analyze_only(analyze_only) =
		   rust_hnsw_should_skip_vacuum_cleanup_analyze_only(analyze_only)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(analyze_only);
});
is($skip_vacuum_cleanup_analyze_only_parity, "t\nt\nt\nt");

my $return_null_vacuum_cleanup_stats_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_null_vacuum_cleanup_stats(has_stats) =
		   rust_hnsw_should_return_null_vacuum_cleanup_stats(has_stats)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_stats);
});
is($return_null_vacuum_cleanup_stats_parity, "t\nt\nt\nt");

my $reuse_markdeleted_buffer_for_neighbor_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page(same_page) =
		   rust_hnsw_should_reuse_markdeleted_buffer_for_neighbor_page(same_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_page);
});
is($reuse_markdeleted_buffer_for_neighbor_page_parity, "t\nt\nt\nt");

my $release_markdeleted_neighbor_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_release_markdeleted_neighbor_buffer(same_buffer) =
		   rust_hnsw_should_release_markdeleted_neighbor_buffer(same_buffer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_buffer);
});
is($release_markdeleted_neighbor_buffer_parity, "t\nt\nt\nt");

my $reset_markdeleted_version_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reset_markdeleted_version(version, max_version) =
		   rust_hnsw_should_reset_markdeleted_version(version, max_version)
	FROM (VALUES
		(1, 15),
		(15, 15),
		(16, 15),
		(22, 15)
	) AS t(version, max_version);
});
is($reset_markdeleted_version_parity, "t\nt\nt\nt");

my $reuse_deleted_ondisk_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reuse_deleted_ondisk_tuple(is_deleted) =
		   rust_hnsw_should_reuse_deleted_ondisk_tuple(is_deleted)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_deleted);
});
is($reuse_deleted_ondisk_tuple_parity, "t\nt\nt\nt");

my $set_insert_page_when_missing_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_set_insert_page_when_missing(has_insert_page) =
		   rust_hnsw_should_set_insert_page_when_missing(has_insert_page)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_insert_page);
});
is($set_insert_page_when_missing_parity, "t\nt\nt\nt");

my $reuse_element_buffer_for_neighbor_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reuse_element_buffer_for_neighbor_page(same_page) =
		   rust_hnsw_should_reuse_element_buffer_for_neighbor_page(same_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_page);
});
is($reuse_element_buffer_for_neighbor_page_parity, "t\nt\nt\nt");

my $release_reused_neighbor_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_release_reused_neighbor_buffer(same_buffer) =
		   rust_hnsw_should_release_reused_neighbor_buffer(same_buffer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_buffer);
});
is($release_reused_neighbor_buffer_parity, "t\nt\nt\nt");

my $use_distinct_neighbor_page_space_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_distinct_neighbor_page_space(same_page) =
		   rust_hnsw_should_use_distinct_neighbor_page_space(same_page)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(same_page);
});
is($use_distinct_neighbor_page_space_parity, "t\nt\nt\nt");

my $reuse_deleted_tuple_space_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reuse_deleted_tuple_space(page_free, npage_free, etup_size, ntup_size) =
		   rust_hnsw_should_reuse_deleted_tuple_space(page_free, npage_free, etup_size, ntup_size)
	FROM (VALUES
		(96::bigint, 64::bigint, 32::bigint, 16::bigint),
		(31::bigint, 64::bigint, 32::bigint, 16::bigint),
		(96::bigint, 15::bigint, 32::bigint, 16::bigint),
		(32::bigint, 16::bigint, 32::bigint, 16::bigint)
	) AS t(page_free, npage_free, etup_size, ntup_size);
});
is($reuse_deleted_tuple_space_parity, "t\nt\nt\nt");

my $borrow_same_page_neighbor_space_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_borrow_same_page_neighbor_space(page_free, etup_size, same_page) =
		   rust_hnsw_should_borrow_same_page_neighbor_space(page_free, etup_size, same_page)
	FROM (VALUES
		(96::bigint, 32::bigint, 1),
		(31::bigint, 32::bigint, 1),
		(96::bigint, 32::bigint, 0),
		(32::bigint, 32::bigint, 1)
	) AS t(page_free, etup_size, same_page);
});
is($borrow_same_page_neighbor_space_parity, "t\nt\nt\nt");

my $register_reused_neighbor_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_register_reused_neighbor_buffer(same_buffer) =
		   rust_hnsw_should_register_reused_neighbor_buffer(same_buffer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_buffer);
});
is($register_reused_neighbor_buffer_parity, "t\nt\nt\nt");

my $probe_for_free_neighbor_slot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_probe_for_free_neighbor_slot(neighbor_count, layer_m) =
		   rust_hnsw_should_probe_for_free_neighbor_slot(neighbor_count, layer_m)
	FROM (VALUES
		(0, 8),
		(8, 8),
		(7, 8),
		(12, 8)
	) AS t(neighbor_count, layer_m);
});
is($probe_for_free_neighbor_slot_parity, "t\nt\nt\nt");

my $skip_existing_neighbor_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_existing_neighbor_update(check_existing, connection_exists) =
		   rust_hnsw_should_skip_existing_neighbor_update(check_existing, connection_exists)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(1, 1),
		(0, 1)
	) AS t(check_existing, connection_exists);
});
is($skip_existing_neighbor_update_parity, "t\nt\nt\nt");

my $apply_neighbor_update_slot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_apply_neighbor_update_slot(update_idx, tuple_count) =
		   rust_hnsw_should_apply_neighbor_update_slot(update_idx, tuple_count)
	FROM (VALUES
		(0, 8),
		(7, 8),
		(8, 8),
		(-1, 8)
	) AS t(update_idx, tuple_count);
});
is($apply_neighbor_update_slot_parity, "t\nt\nt\nt");

my $probe_undecided_update_index_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_probe_undecided_update_index(update_idx) =
		   rust_hnsw_should_probe_undecided_update_index(update_idx)
	FROM (VALUES
		(-2),
		(-1),
		(0),
		(-2)
	) AS t(update_idx);
});
is($probe_undecided_update_index_parity, "t\nt\nt\nt");

my $match_neighbor_connection_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_match_neighbor_connection(indextid_blkno, indextid_offno, element_blkno, element_offno) =
		   rust_hnsw_should_match_neighbor_connection(indextid_blkno, indextid_offno, element_blkno, element_offno)
	FROM (VALUES
		(1, 1, 1, 1),
		(1, 2, 1, 1),
		(5, 8, 5, 8),
		(9, 1, 8, 1)
	) AS t(indextid_blkno, indextid_offno, element_blkno, element_offno);
});
is($match_neighbor_connection_parity, "t\nt\nt\nt");

my $update_connection_from_candidate_index_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_update_connection_from_candidate_index(update_idx) =
		   rust_hnsw_should_update_connection_from_candidate_index(update_idx)
	FROM (VALUES
		(-2),
		(-1),
		(0),
		(4)
	) AS t(update_idx);
});
is($update_connection_from_candidate_index_parity, "t\nt\nt\nt");

my $reject_ondisk_element_overwrite_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_ondisk_element_overwrite(overwrite_succeeded) =
		   rust_hnsw_should_reject_ondisk_element_overwrite(overwrite_succeeded)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(overwrite_succeeded);
});
is($reject_ondisk_element_overwrite_parity, "t\nt\nt\nt");

my $reject_ondisk_unexpected_offset_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_ondisk_unexpected_offset(inserted_offset, expected_offset) =
		   rust_hnsw_should_reject_ondisk_unexpected_offset(inserted_offset, expected_offset)
	FROM (VALUES
		(1, 1),
		(2, 1),
		(10, 10),
		(0, 1)
	) AS t(inserted_offset, expected_offset);
});
is($reject_ondisk_unexpected_offset_parity, "t\nt\nt\nt");

my $return_empty_without_neighbor_tids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_empty_without_neighbor_tids(neighbor_tids_loaded) =
		   rust_hnsw_should_return_empty_without_neighbor_tids(neighbor_tids_loaded)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(neighbor_tids_loaded);
});
is($return_empty_without_neighbor_tids_parity, "t\nt\nt\nt");

my $prune_deleted_insert_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_prune_deleted_insert_element(heaptids_length) =
		   rust_hnsw_should_prune_deleted_insert_element(heaptids_length)
	FROM (VALUES
		(0),
		(1),
		(2),
		(0)
	) AS t(heaptids_length);
});
is($prune_deleted_insert_element_parity, "t\nt\nt\nt");

my $unregister_mvcc_snapshot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_unregister_mvcc_snapshot(snapshot_is_mvcc) =
		   rust_hnsw_should_unregister_mvcc_snapshot(snapshot_is_mvcc)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(snapshot_is_mvcc);
});
is($unregister_mvcc_snapshot_parity, "t\nt\nt\nt");

my $finish_parallel_heap_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_finish_parallel_heap_scan(participants_done, participant_count) =
		   rust_hnsw_should_finish_parallel_heap_scan(participants_done, participant_count)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 3),
		(3, 3)
	) AS t(participants_done, participant_count);
});
is($finish_parallel_heap_scan_parity, "t\nt\nt\nt");

done_testing();
