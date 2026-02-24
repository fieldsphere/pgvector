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
