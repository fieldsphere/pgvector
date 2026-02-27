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
	CREATE FUNCTION c_hnsw_should_cap_ratio_at_one(double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_cap_ratio_at_one'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_cap_ratio_at_one(double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_cap_ratio_at_one'
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
	CREATE FUNCTION c_hnsw_should_use_entrypoint_for_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_entrypoint_for_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_entrypoint_for_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_entrypoint_for_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_entrypoint_for_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_entrypoint_for_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_entrypoint_for_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_entrypoint_for_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_entrypoint_for_scan_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_entrypoint_for_scan_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_entrypoint_for_scan_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_entrypoint_for_scan_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_scan_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_entrypoint'
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
	CREATE FUNCTION c_hnsw_should_have_nonempty_resume_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_nonempty_resume_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_nonempty_resume_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_nonempty_resume_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_resume_from_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_resume_from_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_resume_from_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_resume_from_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_empty_resume_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_empty_resume_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_empty_resume_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_empty_resume_discarded'
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
	CREATE FUNCTION c_hnsw_should_have_nonempty_remaining_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_nonempty_remaining_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_nonempty_remaining_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_nonempty_remaining_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_returning_remaining_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_returning_remaining_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_returning_remaining_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_returning_remaining_discarded'
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
	CREATE FUNCTION c_hnsw_should_have_strict_out_of_order_scan_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_strict_out_of_order_scan_mode'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_strict_out_of_order_scan_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_strict_out_of_order_scan_mode'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_decreasing_scan_distance(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_decreasing_scan_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_decreasing_scan_distance(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_decreasing_scan_distance'
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
	CREATE FUNCTION c_hnsw_should_discarded_heap_missing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_discarded_heap_missing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_discarded_heap_missing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_discarded_heap_missing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_missing_discarded_heap(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_missing_discarded_heap'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_missing_discarded_heap(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_missing_discarded_heap'
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
	CREATE FUNCTION c_hnsw_should_have_iterative_scan_off_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_iterative_scan_off_mode'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_iterative_scan_off_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_iterative_scan_off_mode'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_track_scan_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_track_scan_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_track_scan_discarded(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_track_scan_discarded'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_active_iterative_scan_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_active_iterative_scan_mode'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_active_iterative_scan_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_active_iterative_scan_mode'
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
	CREATE FUNCTION c_hnsw_should_reach_scan_tuple_limit(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reach_scan_tuple_limit'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reach_scan_tuple_limit(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reach_scan_tuple_limit'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_exceed_scan_memory_limit(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_exceed_scan_memory_limit'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_exceed_scan_memory_limit(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_exceed_scan_memory_limit'
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
	CREATE FUNCTION c_hnsw_should_use_strict_scan_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_strict_scan_mode'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_strict_scan_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_strict_scan_mode'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_strict_scan_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_strict_scan_mode'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_strict_scan_mode(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_strict_scan_mode'
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
	CREATE FUNCTION c_hnsw_should_have_flush_graph_pages_at_end(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_flush_graph_pages_at_end'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_flush_graph_pages_at_end(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_flush_graph_pages_at_end'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_flush_pages_in_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_flush_pages_in_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_flush_pages_in_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_flush_pages_in_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_flush_graph(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_flush_graph'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_flush_graph(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_flush_graph'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_phase(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_phase'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_phase(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_phase'
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
	CREATE FUNCTION c_hnsw_should_have_begin_parallel_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_begin_parallel_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_begin_parallel_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_begin_parallel_build'
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
	CREATE FUNCTION c_hnsw_should_have_end_parallel_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_end_parallel_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_end_parallel_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_end_parallel_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_build_leader(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_leader'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_leader(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_leader'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_build_leader_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_leader_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_leader_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_leader_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_scan_heap_for_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_heap_for_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_heap_for_build(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_heap_for_build'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_build_heap(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_heap'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_heap(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_heap'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_build_heap_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_heap_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_heap_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_heap_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_parallel_heap_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_parallel_heap_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_parallel_heap_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_parallel_heap_scan'
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
	CREATE FUNCTION c_hnsw_should_have_reject_inmemory_duplicate_heaptid(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_inmemory_duplicate_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_inmemory_duplicate_heaptid(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_inmemory_duplicate_heaptid'
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
	CREATE FUNCTION c_hnsw_should_have_empty_work_list(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_empty_work_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_empty_work_list(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_empty_work_list'
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
	CREATE FUNCTION c_hnsw_should_have_empty_scan_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_empty_scan_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_empty_scan_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_empty_scan_heaptids'
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
	CREATE FUNCTION c_hnsw_should_have_missing_orderby(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_missing_orderby'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_missing_orderby(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_missing_orderby'
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
	CREATE FUNCTION c_hnsw_should_have_non_mvcc_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_non_mvcc_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_non_mvcc_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_non_mvcc_snapshot'
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
	CREATE FUNCTION c_hnsw_should_have_copyable_rescan_keys(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_copyable_rescan_keys'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_copyable_rescan_keys(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_copyable_rescan_keys'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_rescan_keys(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_rescan_keys'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_rescan_keys(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_rescan_keys'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_positive_rescan_key_count(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_positive_rescan_key_count'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_positive_rescan_key_count(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_positive_rescan_key_count'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_provided_rescan_key_array(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_provided_rescan_key_array'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_provided_rescan_key_array(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_provided_rescan_key_array'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_provided_rescan_key_array(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_provided_rescan_key_array'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_provided_rescan_key_array(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_provided_rescan_key_array'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_provided_rescan_key_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_provided_rescan_key_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_provided_rescan_key_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_provided_rescan_key_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_scan_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_scan_pointer_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_pointer_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_pointer_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_pointer_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_scan_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_provided_orderby_data(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_provided_orderby_data'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_provided_orderby_data(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_provided_orderby_data'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_provided_orderby_data(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_provided_orderby_data'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_provided_orderby_data(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_provided_orderby_data'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_provided_orderby_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_provided_orderby_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_provided_orderby_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_provided_orderby_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_null_scan_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_null_scan_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_null_scan_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_null_scan_value'
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
	CREATE FUNCTION c_hnsw_should_have_normalized_scan_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_normalized_scan_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_normalized_scan_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_normalized_scan_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_scan_normproc(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_scan_normproc'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_scan_normproc(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_scan_normproc'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_scan_normproc(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_normproc'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_normproc(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_normproc'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_scan_normproc_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_normproc_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_normproc_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_normproc_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_initial_scan_state(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_initial_scan_state'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_initial_scan_state(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_initial_scan_state'
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
	CREATE FUNCTION c_hnsw_should_have_instrument_searches(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_instrument_searches'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_instrument_searches(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_instrument_searches'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_scan_instrument(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_scan_instrument'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_scan_instrument(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_scan_instrument'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_scan_instrument(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_instrument'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_instrument(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_instrument'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_scan_instrument_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_scan_instrument_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_scan_instrument_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_scan_instrument_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_skip_parallel_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_skip_parallel_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_skip_parallel_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_skip_parallel_workers'
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
	CREATE FUNCTION c_hnsw_should_have_relation_parallel_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_relation_parallel_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_relation_parallel_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_relation_parallel_workers'
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
	CREATE FUNCTION c_hnsw_should_have_fallback_without_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_fallback_without_workers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_fallback_without_workers(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_fallback_without_workers'
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
	CREATE FUNCTION c_hnsw_should_have_leader_participate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_leader_participate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_leader_participate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_leader_participate'
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
	CREATE FUNCTION c_hnsw_should_have_debug_query_string(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_debug_query_string'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_debug_query_string(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_debug_query_string'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_debug_query_string_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_debug_query_string_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_debug_query_string_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_debug_query_string_flag'
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
	CREATE FUNCTION c_hnsw_should_have_non_concurrent_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_non_concurrent_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_non_concurrent_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_non_concurrent_snapshot'
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
	CREATE FUNCTION c_hnsw_should_have_non_concurrent_lock_modes(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_non_concurrent_lock_modes'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_non_concurrent_lock_modes(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_non_concurrent_lock_modes'
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
	CREATE FUNCTION c_hnsw_should_have_fallback_without_dsm_segment(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_fallback_without_dsm_segment'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_fallback_without_dsm_segment(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_fallback_without_dsm_segment'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_parallel_dsm_segment(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_parallel_dsm_segment'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_parallel_dsm_segment(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_parallel_dsm_segment'
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
	CREATE FUNCTION c_hnsw_should_have_log_leader_progress(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_log_leader_progress'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_log_leader_progress(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_log_leader_progress'
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
	CREATE FUNCTION c_hnsw_should_have_reject_varbit_type(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_varbit_type'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_varbit_type(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_varbit_type'
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
	CREATE FUNCTION c_hnsw_should_have_reject_missing_dimensions(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_missing_dimensions'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_missing_dimensions(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_missing_dimensions'
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
	CREATE FUNCTION c_hnsw_should_have_reject_excess_dimensions(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_excess_dimensions'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_excess_dimensions(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_excess_dimensions'
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
	CREATE FUNCTION c_hnsw_should_have_reject_low_ef_construction(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_low_ef_construction'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_low_ef_construction(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_low_ef_construction'
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
	CREATE FUNCTION c_hnsw_should_have_write_wal_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_write_wal_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_write_wal_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_write_wal_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_treat_fork_as_init(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_treat_fork_as_init'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_treat_fork_as_init(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_treat_fork_as_init'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_treat_fork_as_init(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_treat_fork_as_init'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_treat_fork_as_init(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_treat_fork_as_init'
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
	CREATE FUNCTION c_hnsw_should_have_skip_null_build_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_skip_null_build_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_skip_null_build_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_skip_null_build_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_update_progress_after_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_update_progress_after_insert'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_update_progress_after_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_update_progress_after_insert'
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
	CREATE FUNCTION c_hnsw_should_have_store_neighbors_on_same_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_store_neighbors_on_same_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_store_neighbors_on_same_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_store_neighbors_on_same_page'
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
	CREATE FUNCTION c_hnsw_should_have_reject_oversized_element_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_oversized_element_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_oversized_element_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_oversized_element_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_append_neighbor_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_append_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_append_neighbor_page(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_append_neighbor_page'
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
	CREATE FUNCTION c_hnsw_should_have_append_element_page(bigint, bigint, bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_append_element_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_append_element_page(bigint, bigint, bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_append_element_page'
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
	CREATE FUNCTION c_hnsw_should_have_reject_unexpected_item_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_unexpected_item_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_unexpected_item_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_unexpected_item_offset'
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
	CREATE FUNCTION c_hnsw_should_have_reject_neighbor_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_neighbor_overwrite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_neighbor_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_neighbor_overwrite'
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
	CREATE FUNCTION c_hnsw_should_have_skip_invalid_index_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_skip_invalid_index_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_skip_invalid_index_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_skip_invalid_index_value'
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
	CREATE FUNCTION c_hnsw_should_have_stop_duplicate_search_on_value_mismatch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_stop_duplicate_search_on_value_mismatch'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_stop_duplicate_search_on_value_mismatch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_stop_duplicate_search_on_value_mismatch'
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
	CREATE FUNCTION c_hnsw_should_have_return_after_duplicate_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_return_after_duplicate_insert'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_return_after_duplicate_insert(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_return_after_duplicate_insert'
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
	CREATE FUNCTION c_hnsw_should_use_default_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_default_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_default_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_default_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_update_entry_point(integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_update_entry_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_update_entry_point(integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_update_entry_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_default_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_default_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_default_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_default_entry_level'
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
	CREATE FUNCTION c_hnsw_should_have_higher_ondisk_entrypoint_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_higher_ondisk_entrypoint_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_higher_ondisk_entrypoint_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_higher_ondisk_entrypoint_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_entrypoint_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_entrypoint_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_entrypoint_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_entrypoint_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_entrypoint_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_entrypoint_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_entrypoint_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_entrypoint_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_entrypoint_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_entrypoint_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_entrypoint_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_entrypoint_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_build_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_build_entrypoint_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_entrypoint_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_entrypoint_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_entrypoint_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_higher_build_entrypoint_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_higher_build_entrypoint_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_higher_build_entrypoint_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_higher_build_entrypoint_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_build_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_default_ondisk_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_default_ondisk_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_default_ondisk_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_default_ondisk_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_default_ondisk_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_default_ondisk_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_default_ondisk_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_default_ondisk_entry_level'
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
	CREATE FUNCTION c_hnsw_should_have_valid_insert_index_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_valid_insert_index_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_valid_insert_index_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_valid_insert_index_value'
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
	CREATE FUNCTION c_hnsw_should_have_ondisk_value_mismatch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_value_mismatch'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_value_mismatch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_value_mismatch'
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
	CREATE FUNCTION c_hnsw_should_have_boundary_duplicate_insert_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_boundary_duplicate_insert_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_boundary_duplicate_insert_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_boundary_duplicate_insert_slot'
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
	CREATE FUNCTION c_hnsw_should_have_nonbuilding_ondisk_neighbor_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_nonbuilding_ondisk_neighbor_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_nonbuilding_ondisk_neighbor_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_nonbuilding_ondisk_neighbor_update'
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
	CREATE FUNCTION c_hnsw_should_have_insufficient_ondisk_neighbor_space(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_insufficient_ondisk_neighbor_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_insufficient_ondisk_neighbor_space(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_insufficient_ondisk_neighbor_space'
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
	CREATE FUNCTION c_hnsw_should_exceed_ondisk_element_max_size(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_exceed_ondisk_element_max_size'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_exceed_ondisk_element_max_size(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_exceed_ondisk_element_max_size'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_element_without_next_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_element_without_next_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_element_without_next_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_element_without_next_page'
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
	CREATE FUNCTION c_hnsw_should_have_nonbuilding_ondisk_element_move_next(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_nonbuilding_ondisk_element_move_next'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_nonbuilding_ondisk_element_move_next(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_nonbuilding_ondisk_element_move_next'
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
	CREATE FUNCTION c_hnsw_should_have_changed_ondisk_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_changed_ondisk_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_changed_ondisk_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_changed_ondisk_insert_page'
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
	CREATE FUNCTION c_hnsw_should_have_distinct_ondisk_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_distinct_ondisk_neighbor_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_distinct_ondisk_neighbor_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_distinct_ondisk_neighbor_buffer'
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
	CREATE FUNCTION c_hnsw_should_have_neighbor_page_as_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_neighbor_page_as_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_neighbor_page_as_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_neighbor_page_as_insert_page'
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
	CREATE FUNCTION c_hnsw_should_have_next_neighbor_offset(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_next_neighbor_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_next_neighbor_offset(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_next_neighbor_offset'
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
	CREATE FUNCTION c_hnsw_should_have_free_ondisk_offsets(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_free_ondisk_offsets'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_free_ondisk_offsets(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_free_ondisk_offsets'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_free_ondisk_offset(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_free_ondisk_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_free_ondisk_offset(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_free_ondisk_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_valid_ondisk_offset_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_valid_ondisk_offset_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_valid_ondisk_offset_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_valid_ondisk_offset_number'
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
	CREATE FUNCTION c_hnsw_should_have_query_value_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_query_value_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_query_value_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_query_value_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_element_distance_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_element_distance_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_element_distance_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_element_distance_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_element_max_distance_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_element_max_distance_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_element_max_distance_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_element_max_distance_pointer'
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
	CREATE FUNCTION c_hnsw_should_use_default_distance_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_default_distance_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_default_distance_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_default_distance_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_default_distance_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_default_distance_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_default_distance_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_default_distance_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_default_max_distance_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_default_max_distance_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_default_max_distance_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_default_max_distance_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_default_max_distance_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_default_max_distance_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_default_max_distance_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_default_max_distance_value'
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
	CREATE FUNCTION c_hnsw_should_have_loaded_element_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_loaded_element_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_loaded_element_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_loaded_element_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_element_heaptid_itempointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_element_heaptid_itempointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_element_heaptid_itempointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_element_heaptid_itempointer'
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
	CREATE FUNCTION c_hnsw_should_append_unvisited_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_append_unvisited_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_append_unvisited_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_append_unvisited_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_append_unvisited_disk_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_append_unvisited_disk_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_append_unvisited_disk_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_append_unvisited_disk_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_loading_disk_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_loading_disk_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_loading_disk_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_loading_disk_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_disk_neighbor_indextid_itempointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_disk_neighbor_indextid_itempointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_disk_neighbor_indextid_itempointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_disk_neighbor_indextid_itempointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_abort_unvisited_disk_load(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_abort_unvisited_disk_load'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_abort_unvisited_disk_load(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_abort_unvisited_disk_load'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_stale_neighbor_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_stale_neighbor_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_stale_neighbor_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_stale_neighbor_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_consistent_neighbor_tuple(integer, integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_consistent_neighbor_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_consistent_neighbor_tuple(integer, integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_consistent_neighbor_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_initialize_discarded_heap(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_initialize_discarded_heap'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_initialize_discarded_heap(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_initialize_discarded_heap'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_discarded_heap_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_discarded_heap_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_discarded_heap_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_discarded_heap_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_load_element_with_max_distance_cap(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_load_element_with_max_distance_cap'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_load_element_with_max_distance_cap(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_load_element_with_max_distance_cap'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_track_tuple_counter(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_track_tuple_counter'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_track_tuple_counter(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_track_tuple_counter'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_tuple_counter_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_tuple_counter_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_tuple_counter_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_tuple_counter_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_initialize_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_initialize_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_initialize_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_initialize_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_visited_hash_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_visited_hash_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_visited_hash_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_visited_hash_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_initialize_visited_state(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_initialize_visited_state'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_initialize_visited_state(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_initialize_visited_state'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_tid_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_tid_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_tid_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_tid_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_tid_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_tid_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_tid_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_tid_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_offset_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_offset_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_offset_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_offset_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_offset_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_offset_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_offset_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_offset_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_pointer_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_pointer_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_pointer_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_pointer_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_pointer_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_pointer_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_pointer_visited_hash(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_pointer_visited_hash'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_visited_base_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_visited_base_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_visited_base_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_visited_base_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_memory_entry_distance(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_memory_entry_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_memory_entry_distance(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_memory_entry_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_memory_entry_distance(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_memory_entry_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_memory_entry_distance(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_memory_entry_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_in_memory_search_path(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_in_memory_search_path'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_in_memory_search_path(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_in_memory_search_path'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_in_memory_search_path(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_in_memory_search_path'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_in_memory_search_path(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_in_memory_search_path'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_search_index_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_search_index_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_search_index_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_search_index_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_without_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_without_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_without_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_without_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_search_entrypoint_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_search_entrypoint_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_search_entrypoint_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_search_entrypoint_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_precompute_hash_for_neighbors(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_precompute_hash_for_neighbors'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_precompute_hash_for_neighbors(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_precompute_hash_for_neighbors'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_increment_ef_for_existing_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_increment_ef_for_existing_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_increment_ef_for_existing_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_increment_ef_for_existing_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_remove_disk_only_elements_before_select(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_remove_disk_only_elements_before_select'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_remove_disk_only_elements_before_select(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_remove_disk_only_elements_before_select'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_clamp_neighbor_search_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_clamp_neighbor_search_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_clamp_neighbor_search_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_clamp_neighbor_search_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_pointer_hash_for_base(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_pointer_hash_for_base'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_pointer_hash_for_base(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_pointer_hash_for_base'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_pointer_hash_for_base(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_pointer_hash_for_base'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_pointer_hash_for_base(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_pointer_hash_for_base'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_keep_element_with_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_keep_element_with_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_keep_element_with_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_keep_element_with_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_count_candidate_with_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_count_candidate_with_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_count_candidate_with_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_count_candidate_with_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_self_for_vacuum_update(integer, integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_self_for_vacuum_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_self_for_vacuum_update(integer, integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_self_for_vacuum_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_skip_element_for_existing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_skip_element_for_existing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_skip_element_for_existing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_skip_element_for_existing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_skip_element_for_existing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_skip_element_for_existing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_skip_element_for_existing(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_skip_element_for_existing'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_default_skip_element_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_default_skip_element_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_default_skip_element_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_default_skip_element_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_default_skip_element_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_default_skip_element_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_default_skip_element_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_default_skip_element_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_skip_element_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_skip_element_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_skip_element_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_skip_element_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_default_type_info(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_default_type_info'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_default_type_info(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_default_type_info'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_default_type_info(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_default_type_info'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_default_type_info(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_default_type_info'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_typeinfo_procinfo_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_typeinfo_procinfo_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_typeinfo_procinfo_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_typeinfo_procinfo_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_sparsevec_excess_nnz(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_sparsevec_excess_nnz'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_sparsevec_excess_nnz(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_sparsevec_excess_nnz'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_sort_neighbor_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_sort_neighbor_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_sort_neighbor_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_sort_neighbor_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_sort_pointer_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_sort_pointer_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_sort_pointer_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_sort_pointer_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_sort_base_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_sort_base_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_sort_base_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_sort_base_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_calculate_neighbor_closer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_calculate_neighbor_closer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_calculate_neighbor_closer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_calculate_neighbor_closer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reuse_added_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reuse_added_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reuse_added_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reuse_added_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_define_closer_state_for_base(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_define_closer_state_for_base'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_define_closer_state_for_base(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_define_closer_state_for_base'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_closer_neighbor(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_closer_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_closer_neighbor(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_closer_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_reject_closer_neighbor(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_reject_closer_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_reject_closer_neighbor(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_reject_closer_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_select_neighbors_early_return(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_select_neighbors_early_return'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_select_neighbors_early_return(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_select_neighbors_early_return'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_select_neighbors_early_return(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_select_neighbors_early_return'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_select_neighbors_early_return(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_select_neighbors_early_return'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_add_search_candidate(double precision, double precision, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_add_search_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_add_search_candidate(double precision, double precision, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_add_search_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_add_search_candidate(double precision, double precision, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_add_search_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_add_search_candidate(double precision, double precision, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_add_search_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_stop_search_layer(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_search_layer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_search_layer(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_search_layer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_stop_search_layer(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_stop_search_layer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_stop_search_layer(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_stop_search_layer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_append_neighbor_without_prune(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_append_neighbor_without_prune'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_append_neighbor_without_prune(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_append_neighbor_without_prune'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_append_neighbor_without_prune(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_append_neighbor_without_prune'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_append_neighbor_without_prune(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_append_neighbor_without_prune'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_lower_level_candidate(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_lower_level_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_lower_level_candidate(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_lower_level_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_skip_lower_level_candidate(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_skip_lower_level_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_skip_lower_level_candidate(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_skip_lower_level_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_keep_pruned_connection(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_keep_pruned_connection'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_keep_pruned_connection(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_keep_pruned_connection'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_keep_pruned_connection(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_keep_pruned_connection'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_keep_pruned_connection(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_keep_pruned_connection'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_set_pruned_from_array(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_set_pruned_from_array'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_set_pruned_from_array(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_set_pruned_from_array'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_set_pruned_from_array(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_set_pruned_from_array'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_set_pruned_from_array(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_set_pruned_from_array'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_track_discarded_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_track_discarded_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_track_discarded_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_track_discarded_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_track_discarded_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_track_discarded_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_track_discarded_candidates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_track_discarded_candidates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_track_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_track_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_track_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_track_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_track_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_track_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_track_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_track_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_process_pruned_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_process_pruned_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_process_pruned_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_process_pruned_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_process_pruned_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_process_pruned_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_process_pruned_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_process_pruned_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_trim_candidate_list(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_trim_candidate_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_trim_candidate_list(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_trim_candidate_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_trim_candidate_list(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_trim_candidate_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_trim_candidate_list(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_trim_candidate_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_always_add_candidate(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_always_add_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_always_add_candidate(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_always_add_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_always_add_candidate(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_always_add_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_always_add_candidate(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_always_add_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_append_closer_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_append_closer_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_append_closer_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_append_closer_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_recheck_candidate_after_removal(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_recheck_candidate_after_removal'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_recheck_candidate_after_removal(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_recheck_candidate_after_removal'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_pruned_output(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_pruned_output'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_pruned_output(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_pruned_output'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_pruned_output_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_pruned_output_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_pruned_output_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_pruned_output_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_process_new_candidate_branch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_process_new_candidate_branch'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_process_new_candidate_branch(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_process_new_candidate_branch'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_new_candidate_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_new_candidate_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_new_candidate_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_new_candidate_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_replace_pruned_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_replace_pruned_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_replace_pruned_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_replace_pruned_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_abort_without_pruned_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_abort_without_pruned_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_abort_without_pruned_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_abort_without_pruned_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_enqueue_counted_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_enqueue_counted_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_enqueue_counted_candidate(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_enqueue_counted_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_skip_missing_search_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_skip_missing_search_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_skip_missing_search_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_skip_missing_search_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_search_element_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_search_element_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_search_element_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_search_element_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_copy_tuple_slot_by_index(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_copy_tuple_slot_by_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_copy_tuple_slot_by_index(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_copy_tuple_slot_by_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_cap_element_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_cap_element_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_cap_element_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_cap_element_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_index_options(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_index_options'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_index_options(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_index_options'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_index_options(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_index_options'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_index_options(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_index_options'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_return_missing_optional_proc(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_return_missing_optional_proc'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_return_missing_optional_proc(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_return_missing_optional_proc'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_custom_allocator(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_custom_allocator'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_custom_allocator(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_custom_allocator'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_custom_allocator(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_custom_allocator'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_custom_allocator(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_custom_allocator'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_load_meta_m(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_load_meta_m'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_load_meta_m(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_load_meta_m'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_meta_m_output_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_meta_m_output_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_meta_m_output_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_meta_m_output_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_load_meta_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_load_meta_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_load_meta_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_load_meta_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_meta_entrypoint_output_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_meta_entrypoint_output_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_meta_entrypoint_output_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_meta_entrypoint_output_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_meta_output_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_meta_output_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_meta_output_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_meta_output_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_meta_entry_block(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_meta_entry_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_meta_entry_block(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_meta_entry_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_meta_entry_block(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_meta_entry_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_meta_entry_block(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_meta_entry_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_meta_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_meta_block_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_meta_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_meta_block_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_update_meta_entry_info(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_update_meta_entry_info'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_update_meta_entry_info(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_update_meta_entry_info'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reset_meta_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reset_meta_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reset_meta_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reset_meta_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_meta_update_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_meta_update_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_meta_update_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_meta_update_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_write_meta_entrypoint(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_write_meta_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_write_meta_entrypoint(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_write_meta_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_write_meta_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_write_meta_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_write_meta_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_write_meta_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_build_buffer_path(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_build_buffer_path'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_build_buffer_path(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_build_buffer_path'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_build_buffer_path(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_buffer_path'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_buffer_path(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_buffer_path'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_check_type_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_check_type_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_check_type_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_check_type_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_type_check_function(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_type_check_function'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_type_check_function(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_type_check_function'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_normalize_index_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_normalize_index_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_normalize_index_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_normalize_index_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_norm_procinfo(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_norm_procinfo'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_norm_procinfo(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_norm_procinfo'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_invalid_norm(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_invalid_norm'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_invalid_norm(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_invalid_norm'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_prioritize_lower_distance(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_prioritize_lower_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_prioritize_lower_distance(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_prioritize_lower_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_prioritize_pointer_tiebreak(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_prioritize_pointer_tiebreak'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_prioritize_pointer_tiebreak(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_prioritize_pointer_tiebreak'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_prioritize_offset_tiebreak(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_prioritize_offset_tiebreak'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_prioritize_offset_tiebreak(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_prioritize_offset_tiebreak'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_reject_invalid_meta_magic(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_reject_invalid_meta_magic'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_reject_invalid_meta_magic(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_reject_invalid_meta_magic'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_expected_meta_magic(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_expected_meta_magic'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_expected_meta_magic(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_expected_meta_magic'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_force_meta_entry_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_force_meta_entry_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_force_meta_entry_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_force_meta_entry_update'
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
	CREATE FUNCTION c_hnsw_should_have_ondisk_space_for_combined_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_space_for_combined_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_space_for_combined_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_space_for_combined_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_build_path_for_ondisk_add_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_path_for_ondisk_add_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_path_for_ondisk_add_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_path_for_ondisk_add_element'
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
	CREATE FUNCTION c_hnsw_should_have_build_path_for_appended_ondisk_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_path_for_appended_ondisk_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_path_for_appended_ondisk_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_path_for_appended_ondisk_buffer'
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
	CREATE FUNCTION c_hnsw_should_have_build_path_for_reused_ondisk_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_path_for_reused_ondisk_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_path_for_reused_ondisk_buffer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_path_for_reused_ondisk_buffer'
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
	CREATE FUNCTION c_hnsw_should_have_ondisk_next_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_next_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_next_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_next_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_block_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_block_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_valid_ondisk_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_valid_ondisk_block_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_valid_ondisk_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_valid_ondisk_block_number'
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
	CREATE FUNCTION c_hnsw_should_have_ondisk_insert_space(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_insert_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_insert_space(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_insert_space'
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
	CREATE FUNCTION c_hnsw_should_have_build_path_for_ondisk_append_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_path_for_ondisk_append_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_path_for_ondisk_append_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_path_for_ondisk_append_page'
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
	CREATE FUNCTION c_hnsw_should_have_build_path_for_ondisk_neighbor_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_path_for_ondisk_neighbor_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_path_for_ondisk_neighbor_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_path_for_ondisk_neighbor_update'
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
	CREATE FUNCTION c_hnsw_should_have_build_path_for_ondisk_duplicate_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_build_path_for_ondisk_duplicate_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_build_path_for_ondisk_duplicate_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_build_path_for_ondisk_duplicate_page'
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
	CREATE FUNCTION c_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject'
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
	CREATE FUNCTION c_hnsw_should_have_invalid_ondisk_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_invalid_ondisk_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_invalid_ondisk_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_invalid_ondisk_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_itempointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_itempointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_itempointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_itempointer'
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
	CREATE FUNCTION c_hnsw_should_have_free_ondisk_neighbor_slot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_free_ondisk_neighbor_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_free_ondisk_neighbor_slot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_free_ondisk_neighbor_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_invalid_ondisk_neighbor_slot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_invalid_ondisk_neighbor_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_invalid_ondisk_neighbor_slot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_invalid_ondisk_neighbor_slot'
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
	CREATE FUNCTION c_hnsw_should_have_invalid_ondisk_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_invalid_ondisk_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_invalid_ondisk_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_invalid_ondisk_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_neighbor_tid'
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
	CREATE FUNCTION c_hnsw_should_have_non_element_vacuum_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_non_element_vacuum_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_non_element_vacuum_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_non_element_vacuum_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_invalid_vacuum_last_item(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_invalid_vacuum_last_item'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_invalid_vacuum_last_item(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_invalid_vacuum_last_item'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_contain_deleted_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_contain_deleted_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_contain_deleted_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_contain_deleted_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_deleted_tid_containment(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_deleted_tid_containment'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_deleted_tid_containment(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_deleted_tid_containment'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_contain_deleted_tid_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_contain_deleted_tid_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_contain_deleted_tid_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_contain_deleted_tid_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_deleted_tid_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_deleted_tid_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_deleted_tid_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_deleted_tid_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_continue_vacuum_block_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_continue_vacuum_block_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_continue_vacuum_block_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_continue_vacuum_block_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_continuable_vacuum_block_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_continuable_vacuum_block_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_continuable_vacuum_block_scan(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_continuable_vacuum_block_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_scan_block(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_scan_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_scan_block(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_scan_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_block_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_block_number'
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
	CREATE FUNCTION c_hnsw_should_have_processable_vacuum_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_processable_vacuum_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_processable_vacuum_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_processable_vacuum_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_tuple_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_tuple_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_tuple_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_tuple_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_itempointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_itempointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_itempointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_itempointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_tuple_heaptid_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_tuple_heaptid_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_tuple_heaptid_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_tuple_heaptid_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_deleted_vacuum_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_deleted_vacuum_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_deleted_vacuum_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_deleted_vacuum_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_invalid_vacuum_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_invalid_vacuum_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_invalid_vacuum_heaptid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_invalid_vacuum_heaptid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_heaptid_scan_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_heaptid_scan_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_heaptid_scan_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_heaptid_scan_tid'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_heaptid_removal(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_heaptid_removal'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_heaptid_removal(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_heaptid_removal'
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
	CREATE FUNCTION c_hnsw_should_have_compacted_vacuum_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_compacted_vacuum_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_compacted_vacuum_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_compacted_vacuum_heaptids'
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
	CREATE FUNCTION c_hnsw_should_have_finished_vacuum_page_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_finished_vacuum_page_update'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_finished_vacuum_page_update(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_finished_vacuum_page_update'
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
	CREATE FUNCTION c_hnsw_should_have_invalid_vacuum_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_invalid_vacuum_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_invalid_vacuum_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_invalid_vacuum_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_neighbor_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_neighbor_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_neighbor_tid'
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
	CREATE FUNCTION c_hnsw_should_have_deleted_vacuum_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_deleted_vacuum_neighbor'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_deleted_vacuum_neighbor(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_deleted_vacuum_neighbor'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_underfilled_layer0(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_underfilled_layer0'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_underfilled_layer0(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_underfilled_layer0'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_repair_underfilled_layer0(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_repair_underfilled_layer0'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_repair_underfilled_layer0(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_repair_underfilled_layer0'
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
	CREATE FUNCTION c_hnsw_should_have_matching_vacuum_entrypoint_element(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_matching_vacuum_entrypoint_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_matching_vacuum_entrypoint_element(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_matching_vacuum_entrypoint_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_skip_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_skip_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_skip_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_skip_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_default_vacuum_entrypoint_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_default_vacuum_entrypoint_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_default_vacuum_entrypoint_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_default_vacuum_entrypoint_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_default_vacuum_entrypoint_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_default_vacuum_entrypoint_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_default_vacuum_entrypoint_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_default_vacuum_entrypoint_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_missing_vacuum_entrypoint_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_missing_vacuum_entrypoint_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_missing_vacuum_entrypoint_tid(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_missing_vacuum_entrypoint_tid'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_element_without_updates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_element_without_updates'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_element_without_updates(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_element_without_updates'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_missing_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_missing_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_missing_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_missing_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_higher_vacuum_entrypoint_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_higher_vacuum_entrypoint_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_higher_vacuum_entrypoint_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_higher_vacuum_entrypoint_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_default_vacuum_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_default_vacuum_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_default_vacuum_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_default_vacuum_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_default_vacuum_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_default_vacuum_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_default_vacuum_entry_level(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_default_vacuum_entry_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_need_vacuum_entrypoint_replacement(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_need_vacuum_entrypoint_replacement'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_need_vacuum_entrypoint_replacement(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_need_vacuum_entrypoint_replacement'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_highest_point_block(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_highest_point_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_highest_point_block(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_highest_point_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_highest_point_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_highest_point_block_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_highest_point_block_number(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_highest_point_block_number'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_highest_point_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_highest_point_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_highest_point_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_highest_point_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_highest_point_pointer_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_highest_point_pointer_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_highest_point_pointer_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_highest_point_pointer_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_highest_point_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_highest_point_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_highest_point_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_highest_point_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_pointer_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_pointer_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_pointer_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_pointer_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_pointer_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_pointer_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_pointer_value'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_highest_point(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_highest_point'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_highest_point(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_highest_point'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_entrypoint_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_entrypoint_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_entrypoint_flag(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_entrypoint_flag'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_entrypoint_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_entrypoint_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_entrypoint_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_entrypoint_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_deleted_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_deleted_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_deleted_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_deleted_markdeleted_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_non_element_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_non_element_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_non_element_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_non_element_markdeleted_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_live_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_live_markdeleted_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_live_markdeleted_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_live_markdeleted_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_missing_vacuum_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_missing_vacuum_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_missing_vacuum_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_missing_vacuum_insert_page'
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
	CREATE FUNCTION c_hnsw_should_have_non_element_repairgraph_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_non_element_repairgraph_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_non_element_repairgraph_tuple(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_non_element_repairgraph_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_deleted_repairgraph_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_deleted_repairgraph_element'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_deleted_repairgraph_element(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_deleted_repairgraph_element'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_non_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_non_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_non_entrypoint(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_non_entrypoint'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_higher_vacuum_element_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_higher_vacuum_element_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_higher_vacuum_element_level(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_higher_vacuum_element_level'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_match_vacuum_entrypoint_tuple(integer, integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_match_vacuum_entrypoint_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_match_vacuum_entrypoint_tuple(integer, integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_match_vacuum_entrypoint_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_matching_vacuum_entrypoint_tid(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_matching_vacuum_entrypoint_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_matching_vacuum_entrypoint_tid(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_matching_vacuum_entrypoint_tid'
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
	CREATE FUNCTION c_hnsw_should_have_failed_vacuum_neighbor_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_failed_vacuum_neighbor_overwrite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_failed_vacuum_neighbor_overwrite(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_failed_vacuum_neighbor_overwrite'
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
	CREATE FUNCTION c_hnsw_should_have_missing_vacuum_stats(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_missing_vacuum_stats'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_missing_vacuum_stats(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_missing_vacuum_stats'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_missing_vacuum_stats_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_missing_vacuum_stats_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_missing_vacuum_stats_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_missing_vacuum_stats_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_stats(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_stats'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_stats(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_stats'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_vacuum_stats_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_stats_value'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_stats_value(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_stats_value'
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
	CREATE FUNCTION c_hnsw_should_have_vacuum_cleanup_analyze_only(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_vacuum_cleanup_analyze_only'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_vacuum_cleanup_analyze_only(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_vacuum_cleanup_analyze_only'
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
	CREATE FUNCTION c_hnsw_should_have_null_vacuum_cleanup_stats(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_null_vacuum_cleanup_stats'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_null_vacuum_cleanup_stats(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_null_vacuum_cleanup_stats'
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
	CREATE FUNCTION c_hnsw_should_match_markdeleted_neighbor_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_match_markdeleted_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_match_markdeleted_neighbor_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_match_markdeleted_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_matching_markdeleted_neighbor_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_matching_markdeleted_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_matching_markdeleted_neighbor_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_matching_markdeleted_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_match_markdeleted_buffers(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_match_markdeleted_buffers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_match_markdeleted_buffers(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_match_markdeleted_buffers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_matching_markdeleted_buffers(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_matching_markdeleted_buffers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_matching_markdeleted_buffers(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_matching_markdeleted_buffers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_distinct_markdeleted_buffers(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_distinct_markdeleted_buffers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_distinct_markdeleted_buffers(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_distinct_markdeleted_buffers'
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
	CREATE FUNCTION c_hnsw_should_have_markdeleted_version_beyond_max(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_markdeleted_version_beyond_max'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_markdeleted_version_beyond_max(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_markdeleted_version_beyond_max'
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
	CREATE FUNCTION c_hnsw_should_have_missing_ondisk_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_missing_ondisk_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_missing_ondisk_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_missing_ondisk_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_ondisk_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_ondisk_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_ondisk_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_ondisk_insert_page'
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
	CREATE FUNCTION c_hnsw_should_match_neighbor_pages(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_match_neighbor_pages'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_match_neighbor_pages(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_match_neighbor_pages'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_matching_neighbor_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_matching_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_matching_neighbor_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_matching_neighbor_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_match_ondisk_buffers(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_match_ondisk_buffers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_match_ondisk_buffers(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_match_ondisk_buffers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_matching_ondisk_buffer(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_matching_ondisk_buffer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_matching_ondisk_buffer(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_matching_ondisk_buffer'
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
	CREATE FUNCTION c_hnsw_should_have_distinct_neighbor_page_space(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_distinct_neighbor_page_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_distinct_neighbor_page_space(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_distinct_neighbor_page_space'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_page_space_for_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_page_space_for_tuple'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_page_space_for_tuple(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_page_space_for_tuple'
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
	CREATE FUNCTION c_hnsw_should_have_neighbor_count_before_layer_m(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_neighbor_count_before_layer_m'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_neighbor_count_before_layer_m(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_neighbor_count_before_layer_m'
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
	CREATE FUNCTION c_hnsw_should_have_existing_neighbor_check(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_existing_neighbor_check'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_existing_neighbor_check(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_existing_neighbor_check'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_existing_neighbor_connection(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_existing_neighbor_connection'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_existing_neighbor_connection(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_existing_neighbor_connection'
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
	CREATE FUNCTION c_hnsw_should_have_update_index_before_tuple_count(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_update_index_before_tuple_count'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_update_index_before_tuple_count(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_update_index_before_tuple_count'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_nonnegative_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_nonnegative_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_nonnegative_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_nonnegative_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_update_index_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_update_index_pointer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_update_index_pointer(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_update_index_pointer'
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
	CREATE FUNCTION c_hnsw_should_have_matching_neighbor_block(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_matching_neighbor_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_matching_neighbor_block(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_matching_neighbor_block'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_matching_neighbor_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_matching_neighbor_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_matching_neighbor_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_matching_neighbor_offset'
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
	CREATE FUNCTION c_hnsw_should_have_candidate_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_candidate_update_index'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_candidate_update_index(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_candidate_update_index'
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
	CREATE FUNCTION c_hnsw_should_have_expected_ondisk_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_expected_ondisk_offset'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_expected_ondisk_offset(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_expected_ondisk_offset'
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
	CREATE FUNCTION c_hnsw_should_have_empty_insert_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_empty_insert_heaptids'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_empty_insert_heaptids(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_empty_insert_heaptids'
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
	CREATE FUNCTION c_hnsw_should_have_unregister_mvcc_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_unregister_mvcc_snapshot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_unregister_mvcc_snapshot(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_unregister_mvcc_snapshot'
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
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_have_finish_parallel_heap_scan(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_have_finish_parallel_heap_scan'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_have_finish_parallel_heap_scan(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_have_finish_parallel_heap_scan'
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

my $cap_ratio_at_one_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_cap_ratio_at_one(ratio) =
		   rust_hnsw_should_cap_ratio_at_one(ratio)
	FROM (VALUES
		(0.0::double precision),
		(0.2::double precision),
		(1.0::double precision),
		(1.5::double precision)
	) AS t(ratio);
});
is($cap_ratio_at_one_parity, "t\nt\nt\nt");

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

my $use_entrypoint_for_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_entrypoint_for_scan(has_entrypoint) =
		   rust_hnsw_should_use_entrypoint_for_scan(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($use_entrypoint_for_scan_parity, "t\nt\nt\nt");

my $have_entrypoint_for_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_entrypoint_for_scan(has_entrypoint) =
		   rust_hnsw_should_have_entrypoint_for_scan(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_entrypoint_for_scan_parity, "t\nt\nt\nt");

my $have_entrypoint_for_scan_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_entrypoint_for_scan_pointer(has_entrypoint) =
		   rust_hnsw_should_have_entrypoint_for_scan_pointer(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_entrypoint_for_scan_pointer_parity, "t\nt\nt\nt");

my $have_scan_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_entrypoint(has_entrypoint) =
		   rust_hnsw_should_have_scan_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_scan_entrypoint_parity, "t\nt\nt\nt");

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

my $have_nonempty_resume_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_nonempty_resume_discarded(discarded_is_empty) =
		   rust_hnsw_should_have_nonempty_resume_discarded(discarded_is_empty)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(discarded_is_empty);
});
is($have_nonempty_resume_discarded_parity, "t\nt\nt\nt");

my $stop_resume_from_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_resume_from_discarded(discarded_is_empty) =
		   rust_hnsw_should_stop_resume_from_discarded(discarded_is_empty)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(discarded_is_empty);
});
is($stop_resume_from_discarded_parity, "t\nt\nt\nt");

my $have_empty_resume_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_empty_resume_discarded(discarded_is_empty) =
		   rust_hnsw_should_have_empty_resume_discarded(discarded_is_empty)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(discarded_is_empty);
});
is($have_empty_resume_discarded_parity, "t\nt\nt\nt");

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

my $have_nonempty_remaining_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_nonempty_remaining_discarded(discarded_is_empty) =
		   rust_hnsw_should_have_nonempty_remaining_discarded(discarded_is_empty)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(discarded_is_empty);
});
is($have_nonempty_remaining_discarded_parity, "t\nt\nt\nt");

my $stop_returning_remaining_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_returning_remaining_discarded(discarded_is_empty) =
		   rust_hnsw_should_stop_returning_remaining_discarded(discarded_is_empty)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(discarded_is_empty);
});
is($stop_returning_remaining_discarded_parity, "t\nt\nt\nt");

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

my $have_strict_out_of_order_scan_mode_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_strict_out_of_order_scan_mode(iterative_scan_mode) =
		   rust_hnsw_should_have_strict_out_of_order_scan_mode(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(1)
	) AS t(iterative_scan_mode);
});
is($have_strict_out_of_order_scan_mode_parity, "t\nt\nt\nt");

my $have_decreasing_scan_distance_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_decreasing_scan_distance(distance, previous_distance) =
		   rust_hnsw_should_have_decreasing_scan_distance(distance, previous_distance)
	FROM (VALUES
		(0.1::double precision, 0.2::double precision),
		(0.2::double precision, 0.2::double precision),
		(0.3::double precision, 0.2::double precision),
		(-1.0::double precision, 0.0::double precision)
	) AS t(distance, previous_distance);
});
is($have_decreasing_scan_distance_parity, "t\nt\nt\nt");

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

my $discarded_heap_missing_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_discarded_heap_missing(has_discarded_heap) =
		   rust_hnsw_should_discarded_heap_missing(has_discarded_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_discarded_heap);
});
is($discarded_heap_missing_parity, "t\nt\nt\nt");

my $have_missing_discarded_heap_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_missing_discarded_heap(has_discarded_heap) =
		   rust_hnsw_should_have_missing_discarded_heap(has_discarded_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_discarded_heap);
});
is($have_missing_discarded_heap_parity, "t\nt\nt\nt");

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

my $have_iterative_scan_off_mode_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_iterative_scan_off_mode(iterative_scan_mode) =
		   rust_hnsw_should_have_iterative_scan_off_mode(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(0)
	) AS t(iterative_scan_mode);
});
is($have_iterative_scan_off_mode_parity, "t\nt\nt\nt");

my $track_scan_discarded_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_track_scan_discarded(iterative_scan_mode) =
		   rust_hnsw_should_track_scan_discarded(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(1)
	) AS t(iterative_scan_mode);
});
is($track_scan_discarded_parity, "t\nt\nt\nt");

my $have_active_iterative_scan_mode_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_active_iterative_scan_mode(iterative_scan_mode) =
		   rust_hnsw_should_have_active_iterative_scan_mode(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(1)
	) AS t(iterative_scan_mode);
});
is($have_active_iterative_scan_mode_parity, "t\nt\nt\nt");

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

my $reach_scan_tuple_limit_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reach_scan_tuple_limit(tuple_count, max_scan_tuples) =
		   rust_hnsw_should_reach_scan_tuple_limit(tuple_count, max_scan_tuples)
	FROM (VALUES
		(10::bigint, 20::bigint),
		(20::bigint, 20::bigint),
		(21::bigint, 20::bigint),
		(0::bigint, 1::bigint)
	) AS t(tuple_count, max_scan_tuples);
});
is($reach_scan_tuple_limit_parity, "t\nt\nt\nt");

my $exceed_scan_memory_limit_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_exceed_scan_memory_limit(memory_used, max_memory) =
		   rust_hnsw_should_exceed_scan_memory_limit(memory_used, max_memory)
	FROM (VALUES
		(100::bigint, 200::bigint),
		(200::bigint, 200::bigint),
		(201::bigint, 200::bigint),
		(300::bigint, 150::bigint)
	) AS t(memory_used, max_memory);
});
is($exceed_scan_memory_limit_parity, "t\nt\nt\nt");

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

my $use_strict_scan_mode_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_strict_scan_mode(iterative_scan_mode) =
		   rust_hnsw_should_use_strict_scan_mode(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(2)
	) AS t(iterative_scan_mode);
});
is($use_strict_scan_mode_parity, "t\nt\nt\nt");

my $have_strict_scan_mode_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_strict_scan_mode(iterative_scan_mode) =
		   rust_hnsw_should_have_strict_scan_mode(iterative_scan_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(2)
	) AS t(iterative_scan_mode);
});
is($have_strict_scan_mode_parity, "t\nt\nt\nt");

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

my $have_flush_graph_pages_at_end_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_flush_graph_pages_at_end(graph_flushed) =
		   rust_hnsw_should_have_flush_graph_pages_at_end(graph_flushed)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(graph_flushed);
});
is($have_flush_graph_pages_at_end_parity, "t\nt\nt\nt");

my $have_flush_pages_in_build_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_flush_pages_in_build(graph_flushed) =
		   rust_hnsw_should_have_flush_pages_in_build(graph_flushed)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(graph_flushed);
});
is($have_flush_pages_in_build_parity, "t\nt\nt\nt");

my $have_flush_graph_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_flush_graph(memory_used, memory_total) =
		   rust_hnsw_should_have_flush_graph(memory_used, memory_total)
	FROM (VALUES
		(0::bigint, 1::bigint),
		(1::bigint, 1::bigint),
		(2::bigint, 1::bigint),
		(5::bigint, 9::bigint)
	) AS t(memory_used, memory_total);
});
is($have_flush_graph_parity, "t\nt\nt\nt");

my $have_ondisk_phase_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_phase(graph_flushed) =
		   rust_hnsw_should_have_ondisk_phase(graph_flushed)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(graph_flushed);
});
is($have_ondisk_phase_parity, "t\nt\nt\nt");

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

my $have_begin_parallel_build_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_begin_parallel_build(parallel_workers) =
		   rust_hnsw_should_have_begin_parallel_build(parallel_workers)
	FROM (VALUES
		(0),
		(1),
		(4),
		(-1)
	) AS t(parallel_workers);
});
is($have_begin_parallel_build_parity, "t\nt\nt\nt");

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

my $have_end_parallel_build_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_end_parallel_build(has_leader) =
		   rust_hnsw_should_have_end_parallel_build(has_leader)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_leader);
});
is($have_end_parallel_build_parity, "t\nt\nt\nt");

my $have_build_leader_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_leader(has_leader) =
		   rust_hnsw_should_have_build_leader(has_leader)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_leader);
});
is($have_build_leader_parity, "t\nt\nt\nt");

my $have_build_leader_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_leader_pointer(has_leader) =
		   rust_hnsw_should_have_build_leader_pointer(has_leader)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_leader);
});
is($have_build_leader_pointer_parity, "t\nt\nt\nt");

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

my $have_scan_heap_for_build_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_heap_for_build(has_heap) =
		   rust_hnsw_should_have_scan_heap_for_build(has_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_heap);
});
is($have_scan_heap_for_build_parity, "t\nt\nt\nt");

my $have_build_heap_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_heap(has_heap) =
		   rust_hnsw_should_have_build_heap(has_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_heap);
});
is($have_build_heap_parity, "t\nt\nt\nt");

my $have_build_heap_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_heap_pointer(has_heap) =
		   rust_hnsw_should_have_build_heap_pointer(has_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_heap);
});
is($have_build_heap_pointer_parity, "t\nt\nt\nt");

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

my $have_parallel_heap_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_parallel_heap_scan(has_leader) =
		   rust_hnsw_should_have_parallel_heap_scan(has_leader)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_leader);
});
is($have_parallel_heap_scan_parity, "t\nt\nt\nt");

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

my $have_reject_inmemory_duplicate_heaptid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_inmemory_duplicate_heaptid(heaptids_length, max_heaptids) =
		   rust_hnsw_should_have_reject_inmemory_duplicate_heaptid(heaptids_length, max_heaptids)
	FROM (VALUES
		(0, 10),
		(9, 10),
		(10, 10),
		(11, 10)
	) AS t(heaptids_length, max_heaptids);
});
is($have_reject_inmemory_duplicate_heaptid_parity, "t\nt\nt\nt");

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

my $have_empty_work_list_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_empty_work_list(work_list_length) =
		   rust_hnsw_should_have_empty_work_list(work_list_length)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(work_list_length);
});
is($have_empty_work_list_parity, "t\nt\nt\nt");

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

my $have_empty_scan_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_empty_scan_heaptids(heaptids_length) =
		   rust_hnsw_should_have_empty_scan_heaptids(heaptids_length)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(heaptids_length);
});
is($have_empty_scan_heaptids_parity, "t\nt\nt\nt");

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

my $have_missing_orderby_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_missing_orderby(orderby_is_null) =
		   rust_hnsw_should_have_missing_orderby(orderby_is_null)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(orderby_is_null);
});
is($have_missing_orderby_parity, "t\nt\nt\nt");

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

my $have_non_mvcc_snapshot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_non_mvcc_snapshot(snapshot_is_mvcc) =
		   rust_hnsw_should_have_non_mvcc_snapshot(snapshot_is_mvcc)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(snapshot_is_mvcc);
});
is($have_non_mvcc_snapshot_parity, "t\nt\nt\nt");

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

my $have_copyable_rescan_keys_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_copyable_rescan_keys(has_keys, key_count) =
		   rust_hnsw_should_have_copyable_rescan_keys(has_keys, key_count)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(0, 3),
		(1, 3)
	) AS t(has_keys, key_count);
});
is($have_copyable_rescan_keys_parity, "t\nt\nt\nt");

my $have_rescan_keys_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_rescan_keys(has_keys) =
		   rust_hnsw_should_have_rescan_keys(has_keys)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_keys);
});
is($have_rescan_keys_parity, "t\nt\nt\nt");

my $have_positive_rescan_key_count_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_positive_rescan_key_count(key_count) =
		   rust_hnsw_should_have_positive_rescan_key_count(key_count)
	FROM (VALUES
		(0),
		(1),
		(-1),
		(2)
	) AS t(key_count);
});
is($have_positive_rescan_key_count_parity, "t\nt\nt\nt");

my $use_provided_rescan_key_array_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_provided_rescan_key_array(has_key_array) =
		   rust_hnsw_should_use_provided_rescan_key_array(has_key_array)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_key_array);
});
is($use_provided_rescan_key_array_parity, "t\nt\nt\nt");

my $have_provided_rescan_key_array_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_provided_rescan_key_array(has_key_array) =
		   rust_hnsw_should_have_provided_rescan_key_array(has_key_array)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_key_array);
});
is($have_provided_rescan_key_array_parity, "t\nt\nt\nt");

my $have_provided_rescan_key_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_provided_rescan_key_pointer(has_key_array) =
		   rust_hnsw_should_have_provided_rescan_key_pointer(has_key_array)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_key_array);
});
is($have_provided_rescan_key_pointer_parity, "t\nt\nt\nt");

my $have_scan_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_pointer(has_pointer) =
		   rust_hnsw_should_have_scan_pointer(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_scan_pointer_parity, "t\nt\nt\nt");

my $have_scan_pointer_flag_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_pointer_flag(has_pointer) =
		   rust_hnsw_should_have_scan_pointer_flag(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_scan_pointer_flag_parity, "t\nt\nt\nt");

my $have_scan_pointer_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_pointer_value(has_pointer) =
		   rust_hnsw_should_have_scan_pointer_value(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_scan_pointer_value_parity, "t\nt\nt\nt");

my $use_provided_orderby_data_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_provided_orderby_data(has_orderby_data) =
		   rust_hnsw_should_use_provided_orderby_data(has_orderby_data)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_orderby_data);
});
is($use_provided_orderby_data_parity, "t\nt\nt\nt");

my $have_provided_orderby_data_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_provided_orderby_data(has_orderby_data) =
		   rust_hnsw_should_have_provided_orderby_data(has_orderby_data)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_orderby_data);
});
is($have_provided_orderby_data_parity, "t\nt\nt\nt");

my $have_provided_orderby_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_provided_orderby_pointer(has_orderby_data) =
		   rust_hnsw_should_have_provided_orderby_pointer(has_orderby_data)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_orderby_data);
});
is($have_provided_orderby_pointer_parity, "t\nt\nt\nt");

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

my $have_null_scan_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_null_scan_value(orderby_is_null) =
		   rust_hnsw_should_have_null_scan_value(orderby_is_null)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(orderby_is_null);
});
is($have_null_scan_value_parity, "t\nt\nt\nt");

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

my $have_normalized_scan_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_normalized_scan_value(has_normproc) =
		   rust_hnsw_should_have_normalized_scan_value(has_normproc)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_normproc);
});
is($have_normalized_scan_value_parity, "t\nt\nt\nt");

my $use_scan_normproc_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_scan_normproc(has_normproc) =
		   rust_hnsw_should_use_scan_normproc(has_normproc)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_normproc);
});
is($use_scan_normproc_parity, "t\nt\nt\nt");

my $have_scan_normproc_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_normproc(has_normproc) =
		   rust_hnsw_should_have_scan_normproc(has_normproc)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_normproc);
});
is($have_scan_normproc_parity, "t\nt\nt\nt");

my $have_scan_normproc_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_normproc_pointer(has_normproc) =
		   rust_hnsw_should_have_scan_normproc_pointer(has_normproc)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_normproc);
});
is($have_scan_normproc_pointer_parity, "t\nt\nt\nt");

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

my $have_initial_scan_state_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_initial_scan_state(is_first_scan) =
		   rust_hnsw_should_have_initial_scan_state(is_first_scan)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_first_scan);
});
is($have_initial_scan_state_parity, "t\nt\nt\nt");

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

my $have_instrument_searches_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_instrument_searches(has_instrument) =
		   rust_hnsw_should_have_instrument_searches(has_instrument)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_instrument);
});
is($have_instrument_searches_parity, "t\nt\nt\nt");

my $use_scan_instrument_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_scan_instrument(has_instrument) =
		   rust_hnsw_should_use_scan_instrument(has_instrument)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_instrument);
});
is($use_scan_instrument_parity, "t\nt\nt\nt");

my $have_scan_instrument_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_instrument(has_instrument) =
		   rust_hnsw_should_have_scan_instrument(has_instrument)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_instrument);
});
is($have_scan_instrument_parity, "t\nt\nt\nt");

my $have_scan_instrument_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_scan_instrument_pointer(has_instrument) =
		   rust_hnsw_should_have_scan_instrument_pointer(has_instrument)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_instrument);
});
is($have_scan_instrument_pointer_parity, "t\nt\nt\nt");

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

my $have_skip_parallel_workers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_skip_parallel_workers(parallel_workers) =
		   rust_hnsw_should_have_skip_parallel_workers(parallel_workers)
	FROM (VALUES
		(0),
		(1),
		(-1),
		(8)
	) AS t(parallel_workers);
});
is($have_skip_parallel_workers_parity, "t\nt\nt\nt");

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

my $have_relation_parallel_workers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_relation_parallel_workers(parallel_workers) =
		   rust_hnsw_should_have_relation_parallel_workers(parallel_workers)
	FROM (VALUES
		(-1),
		(0),
		(4),
		(2)
	) AS t(parallel_workers);
});
is($have_relation_parallel_workers_parity, "t\nt\nt\nt");

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

my $have_fallback_without_workers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_fallback_without_workers(workers_launched) =
		   rust_hnsw_should_have_fallback_without_workers(workers_launched)
	FROM (VALUES
		(0),
		(1),
		(2),
		(0)
	) AS t(workers_launched);
});
is($have_fallback_without_workers_parity, "t\nt\nt\nt");

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

my $have_leader_participate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_leader_participate(leader_participates) =
		   rust_hnsw_should_have_leader_participate(leader_participates)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(leader_participates);
});
is($have_leader_participate_parity, "t\nt\nt\nt");

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

my $have_debug_query_string_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_debug_query_string(has_debug_query_string) =
		   rust_hnsw_should_have_debug_query_string(has_debug_query_string)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_debug_query_string);
});
is($have_debug_query_string_parity, "t\nt\nt\nt");

my $have_debug_query_string_flag_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_debug_query_string_flag(has_debug_query_string) =
		   rust_hnsw_should_have_debug_query_string_flag(has_debug_query_string)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_debug_query_string);
});
is($have_debug_query_string_flag_parity, "t\nt\nt\nt");

my $have_build_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_pointer(has_pointer) =
		   rust_hnsw_should_have_build_pointer(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_build_pointer_parity, "t\nt\nt\nt");

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

my $have_non_concurrent_snapshot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_non_concurrent_snapshot(is_concurrent) =
		   rust_hnsw_should_have_non_concurrent_snapshot(is_concurrent)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_concurrent);
});
is($have_non_concurrent_snapshot_parity, "t\nt\nt\nt");

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

my $have_non_concurrent_lock_modes_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_non_concurrent_lock_modes(is_concurrent) =
		   rust_hnsw_should_have_non_concurrent_lock_modes(is_concurrent)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_concurrent);
});
is($have_non_concurrent_lock_modes_parity, "t\nt\nt\nt");

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

my $have_fallback_without_dsm_segment_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_fallback_without_dsm_segment(has_dsm_segment) =
		   rust_hnsw_should_have_fallback_without_dsm_segment(has_dsm_segment)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_dsm_segment);
});
is($have_fallback_without_dsm_segment_parity, "t\nt\nt\nt");

my $have_parallel_dsm_segment_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_parallel_dsm_segment(has_dsm_segment) =
		   rust_hnsw_should_have_parallel_dsm_segment(has_dsm_segment)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_dsm_segment);
});
is($have_parallel_dsm_segment_parity, "t\nt\nt\nt");

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

my $have_log_leader_progress_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_log_leader_progress(progress_is_leader) =
		   rust_hnsw_should_have_log_leader_progress(progress_is_leader)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(progress_is_leader);
});
is($have_log_leader_progress_parity, "t\nt\nt\nt");

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

my $have_reject_varbit_type_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_varbit_type(type_oid) =
		   rust_hnsw_should_have_reject_varbit_type(type_oid)
	FROM (
		SELECT unnest(ARRAY[
			0::integer,
			'varbit'::regtype::oid::integer,
			42::integer,
			'varbit'::regtype::oid::integer
		]) AS type_oid
	) AS t;
});
is($have_reject_varbit_type_parity, "t\nt\nt\nt");

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

my $have_reject_missing_dimensions_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_missing_dimensions(dimensions) =
		   rust_hnsw_should_have_reject_missing_dimensions(dimensions)
	FROM (VALUES
		(-1),
		(0),
		(1024),
		(-42)
	) AS t(dimensions);
});
is($have_reject_missing_dimensions_parity, "t\nt\nt\nt");

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

my $have_reject_excess_dimensions_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_excess_dimensions(dimensions, max_dimensions) =
		   rust_hnsw_should_have_reject_excess_dimensions(dimensions, max_dimensions)
	FROM (VALUES
		(3, 3),
		(4, 3),
		(16, 1024),
		(2048, 1024)
	) AS t(dimensions, max_dimensions);
});
is($have_reject_excess_dimensions_parity, "t\nt\nt\nt");

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

my $have_reject_low_ef_construction_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_low_ef_construction(ef_construction, m) =
		   rust_hnsw_should_have_reject_low_ef_construction(ef_construction, m)
	FROM (VALUES
		(15, 8),
		(16, 8),
		(31, 16),
		(32, 16)
	) AS t(ef_construction, m);
});
is($have_reject_low_ef_construction_parity, "t\nt\nt\nt");

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

my $have_write_wal_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_write_wal_page(needs_wal, is_init_fork) =
		   rust_hnsw_should_have_write_wal_page(needs_wal, is_init_fork)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(0, 1),
		(1, 1)
	) AS t(needs_wal, is_init_fork);
});
is($have_write_wal_page_parity, "t\nt\nt\nt");

my $treat_fork_as_init_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_treat_fork_as_init(fork_num) =
		   rust_hnsw_should_treat_fork_as_init(fork_num)
	FROM (VALUES
		(0),
		(1),
		(2),
		(3)
	) AS t(fork_num);
});
is($treat_fork_as_init_parity, "t\nt\nt\nt");

my $have_treat_fork_as_init_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_treat_fork_as_init(fork_num) =
		   rust_hnsw_should_have_treat_fork_as_init(fork_num)
	FROM (VALUES
		(0),
		(1),
		(2),
		(3)
	) AS t(fork_num);
});
is($have_treat_fork_as_init_parity, "t\nt\nt\nt");

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

my $have_skip_null_build_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_skip_null_build_tuple(is_null) =
		   rust_hnsw_should_have_skip_null_build_tuple(is_null)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_null);
});
is($have_skip_null_build_tuple_parity, "t\nt\nt\nt");

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

my $have_update_progress_after_insert_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_update_progress_after_insert(tuple_inserted) =
		   rust_hnsw_should_have_update_progress_after_insert(tuple_inserted)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(tuple_inserted);
});
is($have_update_progress_after_insert_parity, "t\nt\nt\nt");

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

my $have_store_neighbors_on_same_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_store_neighbors_on_same_page(combined_size, max_size) =
		   rust_hnsw_should_have_store_neighbors_on_same_page(combined_size, max_size)
	FROM (VALUES
		(10::bigint, 12::bigint),
		(12::bigint, 12::bigint),
		(13::bigint, 12::bigint),
		(1024::bigint, 2048::bigint)
	) AS t(combined_size, max_size);
});
is($have_store_neighbors_on_same_page_parity, "t\nt\nt\nt");

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

my $have_reject_oversized_element_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_oversized_element_tuple(tuple_size, alloc_size) =
		   rust_hnsw_should_have_reject_oversized_element_tuple(tuple_size, alloc_size)
	FROM (VALUES
		(32::bigint, 64::bigint),
		(64::bigint, 64::bigint),
		(65::bigint, 64::bigint),
		(2048::bigint, 1024::bigint)
	) AS t(tuple_size, alloc_size);
});
is($have_reject_oversized_element_tuple_parity, "t\nt\nt\nt");

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

my $have_append_neighbor_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_append_neighbor_page(free_space, neighbor_tuple_size) =
		   rust_hnsw_should_have_append_neighbor_page(free_space, neighbor_tuple_size)
	FROM (VALUES
		(8::bigint, 16::bigint),
		(16::bigint, 16::bigint),
		(32::bigint, 16::bigint),
		(0::bigint, 1::bigint)
	) AS t(free_space, neighbor_tuple_size);
});
is($have_append_neighbor_page_parity, "t\nt\nt\nt");

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

my $have_append_element_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_append_element_page(free_space, element_tuple_size, combined_size, max_size) =
		   rust_hnsw_should_have_append_element_page(free_space, element_tuple_size, combined_size, max_size)
	FROM (VALUES
		(4::bigint, 8::bigint, 16::bigint, 32::bigint),
		(12::bigint, 8::bigint, 16::bigint, 32::bigint),
		(20::bigint, 8::bigint, 16::bigint, 32::bigint),
		(20::bigint, 8::bigint, 48::bigint, 32::bigint)
	) AS t(free_space, element_tuple_size, combined_size, max_size);
});
is($have_append_element_page_parity, "t\nt\nt\nt");

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

my $have_reject_unexpected_item_offset_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_unexpected_item_offset(inserted_offset, expected_offset) =
		   rust_hnsw_should_have_reject_unexpected_item_offset(inserted_offset, expected_offset)
	FROM (VALUES
		(1, 1),
		(2, 1),
		(8, 8),
		(0, 1)
	) AS t(inserted_offset, expected_offset);
});
is($have_reject_unexpected_item_offset_parity, "t\nt\nt\nt");

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

my $have_reject_neighbor_overwrite_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_neighbor_overwrite(overwrite_succeeded) =
		   rust_hnsw_should_have_reject_neighbor_overwrite(overwrite_succeeded)
	FROM (VALUES
		(1),
		(0),
		(1),
		(0)
	) AS t(overwrite_succeeded);
});
is($have_reject_neighbor_overwrite_parity, "t\nt\nt\nt");

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

my $have_skip_invalid_index_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_skip_invalid_index_value(index_value_formed) =
		   rust_hnsw_should_have_skip_invalid_index_value(index_value_formed)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(index_value_formed);
});
is($have_skip_invalid_index_value_parity, "t\nt\nt\nt");

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

my $have_stop_duplicate_search_on_value_mismatch_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_stop_duplicate_search_on_value_mismatch(values_equal) =
		   rust_hnsw_should_have_stop_duplicate_search_on_value_mismatch(values_equal)
	FROM (VALUES
		(1),
		(0),
		(0),
		(1)
	) AS t(values_equal);
});
is($have_stop_duplicate_search_on_value_mismatch_parity, "t\nt\nt\nt");

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

my $have_return_after_duplicate_insert_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_return_after_duplicate_insert(duplicate_inserted) =
		   rust_hnsw_should_have_return_after_duplicate_insert(duplicate_inserted)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(duplicate_inserted);
});
is($have_return_after_duplicate_insert_parity, "t\nt\nt\nt");

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

my $use_default_entry_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_default_entry_level(has_entrypoint) =
		   rust_hnsw_should_use_default_entry_level(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($use_default_entry_level_parity, "t\nt\nt\nt");

my $have_update_entry_point_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_update_entry_point(entrypoint_is_null, element_level, entry_level) =
		   rust_hnsw_should_have_update_entry_point(entrypoint_is_null, element_level, entry_level)
	FROM (VALUES
		(1, 0, -1),
		(0, 2, 1),
		(0, 1, 1),
		(0, 0, 1)
	) AS t(entrypoint_is_null, element_level, entry_level);
});
is($have_update_entry_point_parity, "t\nt\nt\nt");

my $have_default_entry_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_default_entry_level(has_entrypoint) =
		   rust_hnsw_should_have_default_entry_level(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_default_entry_level_parity, "t\nt\nt\nt");

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

my $have_higher_ondisk_entrypoint_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_higher_ondisk_entrypoint_level(element_level, entry_level) =
		   rust_hnsw_should_have_higher_ondisk_entrypoint_level(element_level, entry_level)
	FROM (VALUES
		(0, -1),
		(2, 1),
		(1, 1),
		(0, 1)
	) AS t(element_level, entry_level);
});
is($have_higher_ondisk_entrypoint_level_parity, "t\nt\nt\nt");

my $have_ondisk_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_entrypoint(has_entrypoint) =
		   rust_hnsw_should_have_ondisk_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_ondisk_entrypoint_parity, "t\nt\nt\nt");

my $have_ondisk_entrypoint_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_entrypoint_value(has_entrypoint) =
		   rust_hnsw_should_have_ondisk_entrypoint_value(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_ondisk_entrypoint_value_parity, "t\nt\nt\nt");

my $have_ondisk_entrypoint_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_entrypoint_pointer(has_entrypoint) =
		   rust_hnsw_should_have_ondisk_entrypoint_pointer(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_ondisk_entrypoint_pointer_parity, "t\nt\nt\nt");

my $have_ondisk_entrypoint_pointer_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_entrypoint_pointer_value(has_entrypoint) =
		   rust_hnsw_should_have_ondisk_entrypoint_pointer_value(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_ondisk_entrypoint_pointer_value_parity, "t\nt\nt\nt");

my $have_ondisk_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_pointer(has_pointer) =
		   rust_hnsw_should_have_ondisk_pointer(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_ondisk_pointer_parity, "t\nt\nt\nt");

my $have_ondisk_pointer_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_pointer_value(has_pointer) =
		   rust_hnsw_should_have_ondisk_pointer_value(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_ondisk_pointer_value_parity, "t\nt\nt\nt");

my $have_build_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_entrypoint(has_entrypoint) =
		   rust_hnsw_should_have_build_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_build_entrypoint_parity, "t\nt\nt\nt");

my $have_build_entrypoint_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_entrypoint_pointer(has_entrypoint) =
		   rust_hnsw_should_have_build_entrypoint_pointer(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_build_entrypoint_pointer_parity, "t\nt\nt\nt");

my $have_higher_build_entrypoint_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_higher_build_entrypoint_level(element_level, entry_level) =
		   rust_hnsw_should_have_higher_build_entrypoint_level(element_level, entry_level)
	FROM (VALUES
		(0, -1),
		(2, 1),
		(1, 1),
		(0, 1)
	) AS t(element_level, entry_level);
});
is($have_higher_build_entrypoint_level_parity, "t\nt\nt\nt");

my $use_default_ondisk_entry_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_default_ondisk_entry_level(has_entrypoint) =
		   rust_hnsw_should_use_default_ondisk_entry_level(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($use_default_ondisk_entry_level_parity, "t\nt\nt\nt");

my $have_default_ondisk_entry_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_default_ondisk_entry_level(has_entrypoint) =
		   rust_hnsw_should_have_default_ondisk_entry_level(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_default_ondisk_entry_level_parity, "t\nt\nt\nt");

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

my $have_valid_insert_index_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_valid_insert_index_value(index_value_formed) =
		   rust_hnsw_should_have_valid_insert_index_value(index_value_formed)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(index_value_formed);
});
is($have_valid_insert_index_value_parity, "t\nt\nt\nt");

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

my $have_ondisk_value_mismatch_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_value_mismatch(values_equal) =
		   rust_hnsw_should_have_ondisk_value_mismatch(values_equal)
	FROM (VALUES
		(1),
		(0),
		(0),
		(1)
	) AS t(values_equal);
});
is($have_ondisk_value_mismatch_parity, "t\nt\nt\nt");

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

my $have_boundary_duplicate_insert_slot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_boundary_duplicate_insert_slot(free_slot_index, max_heaptids) =
		   rust_hnsw_should_have_boundary_duplicate_insert_slot(free_slot_index, max_heaptids)
	FROM (VALUES
		(0, 10),
		(3, 10),
		(10, 10),
		(1, 2)
	) AS t(free_slot_index, max_heaptids);
});
is($have_boundary_duplicate_insert_slot_parity, "t\nt\nt\nt");

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

my $have_nonbuilding_ondisk_neighbor_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_nonbuilding_ondisk_neighbor_update(building) =
		   rust_hnsw_should_have_nonbuilding_ondisk_neighbor_update(building)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(building);
});
is($have_nonbuilding_ondisk_neighbor_update_parity, "t\nt\nt\nt");

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

my $have_insufficient_ondisk_neighbor_space_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_insufficient_ondisk_neighbor_space(free_space, tuple_size) =
		   rust_hnsw_should_have_insufficient_ondisk_neighbor_space(free_space, tuple_size)
	FROM (VALUES
		(0, 1),
		(128, 128),
		(127, 128),
		(1024, 512)
	) AS t(free_space, tuple_size);
});
is($have_insufficient_ondisk_neighbor_space_parity, "t\nt\nt\nt");

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

my $exceed_ondisk_element_max_size_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_exceed_ondisk_element_max_size(combined_size, max_size) =
		   rust_hnsw_should_exceed_ondisk_element_max_size(combined_size, max_size)
	FROM (VALUES
		(128::bigint, 256::bigint),
		(256::bigint, 256::bigint),
		(257::bigint, 256::bigint),
		(512::bigint, 128::bigint)
	) AS t(combined_size, max_size);
});
is($exceed_ondisk_element_max_size_parity, "t\nt\nt\nt");

my $have_ondisk_element_without_next_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_element_without_next_page(has_next_page) =
		   rust_hnsw_should_have_ondisk_element_without_next_page(has_next_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_next_page);
});
is($have_ondisk_element_without_next_page_parity, "t\nt\nt\nt");

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

my $have_nonbuilding_ondisk_element_move_next_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_nonbuilding_ondisk_element_move_next(building) =
		   rust_hnsw_should_have_nonbuilding_ondisk_element_move_next(building)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(building);
});
is($have_nonbuilding_ondisk_element_move_next_parity, "t\nt\nt\nt");

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

my $have_changed_ondisk_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_changed_ondisk_insert_page(new_insert_page, insert_page) =
		   rust_hnsw_should_have_changed_ondisk_insert_page(new_insert_page, insert_page)
	FROM (VALUES
		(1, 1),
		(1, 2),
		(9, 4),
		(8, 8)
	) AS t(new_insert_page, insert_page);
});
is($have_changed_ondisk_insert_page_parity, "t\nt\nt\nt");

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

my $have_distinct_ondisk_neighbor_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_distinct_ondisk_neighbor_buffer(same_buffer) =
		   rust_hnsw_should_have_distinct_ondisk_neighbor_buffer(same_buffer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_buffer);
});
is($have_distinct_ondisk_neighbor_buffer_parity, "t\nt\nt\nt");

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

my $have_neighbor_page_as_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_neighbor_page_as_insert_page(has_new_insert_page) =
		   rust_hnsw_should_have_neighbor_page_as_insert_page(has_new_insert_page)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_new_insert_page);
});
is($have_neighbor_page_as_insert_page_parity, "t\nt\nt\nt");

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

my $have_next_neighbor_offset_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_next_neighbor_offset(same_buffer) =
		   rust_hnsw_should_have_next_neighbor_offset(same_buffer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(same_buffer);
});
is($have_next_neighbor_offset_parity, "t\nt\nt\nt");

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

my $have_free_ondisk_offsets_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_free_ondisk_offsets(free_offset_valid) =
		   rust_hnsw_should_have_free_ondisk_offsets(free_offset_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(free_offset_valid);
});
is($have_free_ondisk_offsets_parity, "t\nt\nt\nt");

my $have_free_ondisk_offset_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_free_ondisk_offset(free_offset_valid) =
		   rust_hnsw_should_have_free_ondisk_offset(free_offset_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(free_offset_valid);
});
is($have_free_ondisk_offset_parity, "t\nt\nt\nt");

my $have_valid_ondisk_offset_number_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_valid_ondisk_offset_number(free_offno) =
		   rust_hnsw_should_have_valid_ondisk_offset_number(free_offno)
	FROM (VALUES
		(0),
		(1),
		(7),
		(-1)
	) AS t(free_offno);
});
is($have_valid_ondisk_offset_number_parity, "t\nt\nt\nt");

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

my $have_query_value_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_query_value_pointer(has_query_value) =
		   rust_hnsw_should_have_query_value_pointer(has_query_value)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_query_value);
});
is($have_query_value_pointer_parity, "t\nt\nt\nt");

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

my $have_element_distance_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_element_distance_pointer(has_distance_pointer) =
		   rust_hnsw_should_have_element_distance_pointer(has_distance_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_distance_pointer);
});
is($have_element_distance_pointer_parity, "t\nt\nt\nt");

my $have_element_max_distance_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_element_max_distance_pointer(has_max_distance_pointer) =
		   rust_hnsw_should_have_element_max_distance_pointer(has_max_distance_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_max_distance_pointer);
});
is($have_element_max_distance_pointer_parity, "t\nt\nt\nt");

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

my $use_default_distance_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_default_distance_value(has_distance_pointer) =
		   rust_hnsw_should_use_default_distance_value(has_distance_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_distance_pointer);
});
is($use_default_distance_value_parity, "t\nt\nt\nt");

my $have_default_distance_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_default_distance_value(has_distance_pointer) =
		   rust_hnsw_should_have_default_distance_value(has_distance_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_distance_pointer);
});
is($have_default_distance_value_parity, "t\nt\nt\nt");

my $use_default_max_distance_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_default_max_distance_value(has_max_distance_pointer) =
		   rust_hnsw_should_use_default_max_distance_value(has_max_distance_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_max_distance_pointer);
});
is($use_default_max_distance_value_parity, "t\nt\nt\nt");

my $have_default_max_distance_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_default_max_distance_value(has_max_distance_pointer) =
		   rust_hnsw_should_have_default_max_distance_value(has_max_distance_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_max_distance_pointer);
});
is($have_default_max_distance_value_parity, "t\nt\nt\nt");

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

my $have_loaded_element_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_loaded_element_pointer(has_element) =
		   rust_hnsw_should_have_loaded_element_pointer(has_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_element);
});
is($have_loaded_element_pointer_parity, "t\nt\nt\nt");

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

my $have_element_heaptid_itempointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_element_heaptid_itempointer(heaptid_valid) =
		   rust_hnsw_should_have_element_heaptid_itempointer(heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(heaptid_valid);
});
is($have_element_heaptid_itempointer_parity, "t\nt\nt\nt");

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

my $append_unvisited_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_append_unvisited_neighbor(found) =
		   rust_hnsw_should_append_unvisited_neighbor(found)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(found);
});
is($append_unvisited_neighbor_parity, "t\nt\nt\nt");

my $append_unvisited_disk_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_append_unvisited_disk_neighbor(found) =
		   rust_hnsw_should_append_unvisited_disk_neighbor(found)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(found);
});
is($append_unvisited_disk_neighbor_parity, "t\nt\nt\nt");

my $stop_loading_disk_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_loading_disk_neighbor(is_valid_indextid) =
		   rust_hnsw_should_stop_loading_disk_neighbor(is_valid_indextid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_valid_indextid);
});
is($stop_loading_disk_neighbor_parity, "t\nt\nt\nt");

my $have_disk_neighbor_indextid_itempointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_disk_neighbor_indextid_itempointer(is_valid_indextid) =
		   rust_hnsw_should_have_disk_neighbor_indextid_itempointer(is_valid_indextid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_valid_indextid);
});
is($have_disk_neighbor_indextid_itempointer_parity, "t\nt\nt\nt");

my $abort_unvisited_disk_load_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_abort_unvisited_disk_load(neighbor_tids_loaded) =
		   rust_hnsw_should_abort_unvisited_disk_load(neighbor_tids_loaded)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(neighbor_tids_loaded);
});
is($abort_unvisited_disk_load_parity, "t\nt\nt\nt");

my $reject_stale_neighbor_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_stale_neighbor_tuple(tuple_consistent) =
		   rust_hnsw_should_reject_stale_neighbor_tuple(tuple_consistent)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(tuple_consistent);
});
is($reject_stale_neighbor_tuple_parity, "t\nt\nt\nt");

my $have_consistent_neighbor_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_consistent_neighbor_tuple(tuple_version, element_version, tuple_count, element_level, m) =
		   rust_hnsw_should_have_consistent_neighbor_tuple(tuple_version, element_version, tuple_count, element_level, m)
	FROM (VALUES
		(2, 2, 16, 6, 2),
		(3, 4, 10, 4, 2),
		(7, 7, 18, 8, 2),
		(1, 1, 8, 3, 1)
	) AS t(tuple_version, element_version, tuple_count, element_level, m);
});
is($have_consistent_neighbor_tuple_parity, "t\nt\nt\nt");

my $initialize_discarded_heap_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_initialize_discarded_heap(has_discarded_heap) =
		   rust_hnsw_should_initialize_discarded_heap(has_discarded_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_discarded_heap);
});
is($initialize_discarded_heap_parity, "t\nt\nt\nt");

my $have_discarded_heap_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_discarded_heap_pointer(has_discarded_heap) =
		   rust_hnsw_should_have_discarded_heap_pointer(has_discarded_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_discarded_heap);
});
is($have_discarded_heap_pointer_parity, "t\nt\nt\nt");

my $load_element_with_max_distance_cap_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_load_element_with_max_distance_cap(always_add, track_discarded) =
		   rust_hnsw_should_load_element_with_max_distance_cap(always_add, track_discarded)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(0, 1),
		(1, 1)
	) AS t(always_add, track_discarded);
});
is($load_element_with_max_distance_cap_parity, "t\nt\nt\nt");

my $track_tuple_counter_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_track_tuple_counter(has_tuple_counter) =
		   rust_hnsw_should_track_tuple_counter(has_tuple_counter)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_tuple_counter);
});
is($track_tuple_counter_parity, "t\nt\nt\nt");

my $have_tuple_counter_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_tuple_counter_pointer(has_tuple_counter) =
		   rust_hnsw_should_have_tuple_counter_pointer(has_tuple_counter)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_tuple_counter);
});
is($have_tuple_counter_pointer_parity, "t\nt\nt\nt");

my $initialize_visited_hash_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_initialize_visited_hash(has_visited_hash) =
		   rust_hnsw_should_initialize_visited_hash(has_visited_hash)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_visited_hash);
});
is($initialize_visited_hash_parity, "t\nt\nt\nt");

my $have_visited_hash_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_visited_hash_pointer(has_visited_hash) =
		   rust_hnsw_should_have_visited_hash_pointer(has_visited_hash)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_visited_hash);
});
is($have_visited_hash_pointer_parity, "t\nt\nt\nt");

my $initialize_visited_state_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_initialize_visited_state(init_visited) =
		   rust_hnsw_should_initialize_visited_state(init_visited)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(init_visited);
});
is($initialize_visited_state_parity, "t\nt\nt\nt");

my $use_tid_visited_hash_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_tid_visited_hash(in_memory) =
		   rust_hnsw_should_use_tid_visited_hash(in_memory)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(in_memory);
});
is($use_tid_visited_hash_parity, "t\nt\nt\nt");

my $have_tid_visited_hash_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_tid_visited_hash(in_memory) =
		   rust_hnsw_should_have_tid_visited_hash(in_memory)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(in_memory);
});
is($have_tid_visited_hash_parity, "t\nt\nt\nt");

my $use_offset_visited_hash_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_offset_visited_hash(has_base_pointer) =
		   rust_hnsw_should_use_offset_visited_hash(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_base_pointer);
});
is($use_offset_visited_hash_parity, "t\nt\nt\nt");

my $have_offset_visited_hash_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_offset_visited_hash(has_base_pointer) =
		   rust_hnsw_should_have_offset_visited_hash(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_base_pointer);
});
is($have_offset_visited_hash_parity, "t\nt\nt\nt");

my $use_pointer_visited_hash_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_pointer_visited_hash(has_base_pointer) =
		   rust_hnsw_should_use_pointer_visited_hash(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_base_pointer);
});
is($use_pointer_visited_hash_parity, "t\nt\nt\nt");

my $have_pointer_visited_hash_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_pointer_visited_hash(has_base_pointer) =
		   rust_hnsw_should_have_pointer_visited_hash(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_base_pointer);
});
is($have_pointer_visited_hash_parity, "t\nt\nt\nt");

my $have_visited_base_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_visited_base_pointer(has_base_pointer) =
		   rust_hnsw_should_have_visited_base_pointer(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_base_pointer);
});
is($have_visited_base_pointer_parity, "t\nt\nt\nt");

my $use_memory_entry_distance_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_memory_entry_distance(in_memory) =
		   rust_hnsw_should_use_memory_entry_distance(in_memory)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(in_memory);
});
is($use_memory_entry_distance_parity, "t\nt\nt\nt");

my $have_memory_entry_distance_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_memory_entry_distance(in_memory) =
		   rust_hnsw_should_have_memory_entry_distance(in_memory)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(in_memory);
});
is($have_memory_entry_distance_parity, "t\nt\nt\nt");

my $use_in_memory_search_path_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_in_memory_search_path(in_memory) =
		   rust_hnsw_should_use_in_memory_search_path(in_memory)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(in_memory);
});
is($use_in_memory_search_path_parity, "t\nt\nt\nt");

my $have_in_memory_search_path_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_in_memory_search_path(in_memory) =
		   rust_hnsw_should_have_in_memory_search_path(in_memory)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(in_memory);
});
is($have_in_memory_search_path_parity, "t\nt\nt\nt");

my $have_search_index_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_search_index_pointer(has_index_pointer) =
		   rust_hnsw_should_have_search_index_pointer(has_index_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_index_pointer);
});
is($have_search_index_pointer_parity, "t\nt\nt\nt");

my $return_without_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_without_entrypoint(has_entrypoint) =
		   rust_hnsw_should_return_without_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($return_without_entrypoint_parity, "t\nt\nt\nt");

my $have_search_entrypoint_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_search_entrypoint_pointer(has_entrypoint) =
		   rust_hnsw_should_have_search_entrypoint_pointer(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_search_entrypoint_pointer_parity, "t\nt\nt\nt");

my $precompute_hash_for_neighbors_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_precompute_hash_for_neighbors(in_memory) =
		   rust_hnsw_should_precompute_hash_for_neighbors(in_memory)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(in_memory);
});
is($precompute_hash_for_neighbors_parity, "t\nt\nt\nt");

my $increment_ef_for_existing_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_increment_ef_for_existing_element(existing_element) =
		   rust_hnsw_should_increment_ef_for_existing_element(existing_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(existing_element);
});
is($increment_ef_for_existing_element_parity, "t\nt\nt\nt");

my $remove_disk_only_elements_before_select_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_remove_disk_only_elements_before_select(in_memory) =
		   rust_hnsw_should_remove_disk_only_elements_before_select(in_memory)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(in_memory);
});
is($remove_disk_only_elements_before_select_parity, "t\nt\nt\nt");

my $clamp_neighbor_search_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_clamp_neighbor_search_level(level, entry_level) =
		   rust_hnsw_should_clamp_neighbor_search_level(level, entry_level)
	FROM (VALUES
		(1, 2),
		(3, 2),
		(4, 4),
		(6, 5)
	) AS t(level, entry_level);
});
is($clamp_neighbor_search_level_parity, "t\nt\nt\nt");

my $use_pointer_hash_for_base_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_pointer_hash_for_base(has_base_pointer) =
		   rust_hnsw_should_use_pointer_hash_for_base(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_base_pointer);
});
is($use_pointer_hash_for_base_parity, "t\nt\nt\nt");

my $have_pointer_hash_for_base_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_pointer_hash_for_base(has_base_pointer) =
		   rust_hnsw_should_have_pointer_hash_for_base(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_base_pointer);
});
is($have_pointer_hash_for_base_parity, "t\nt\nt\nt");

my $keep_element_with_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_keep_element_with_heaptids(heaptids_length) =
		   rust_hnsw_should_keep_element_with_heaptids(heaptids_length)
	FROM (VALUES
		(0),
		(1),
		(2),
		(-1)
	) AS t(heaptids_length);
});
is($keep_element_with_heaptids_parity, "t\nt\nt\nt");

my $count_candidate_with_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_count_candidate_with_heaptids(heaptids_length) =
		   rust_hnsw_should_count_candidate_with_heaptids(heaptids_length)
	FROM (VALUES
		(0),
		(1),
		(2),
		(-1)
	) AS t(heaptids_length);
});
is($count_candidate_with_heaptids_parity, "t\nt\nt\nt");

my $skip_self_for_vacuum_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_self_for_vacuum_update(has_skip_element, element_blkno, element_offno, skip_blkno, skip_offno) =
		   rust_hnsw_should_skip_self_for_vacuum_update(has_skip_element, element_blkno, element_offno, skip_blkno, skip_offno)
	FROM (VALUES
		(0, 10, 2, 10, 2),
		(1, 10, 2, 10, 2),
		(1, 10, 2, 10, 3),
		(1, 11, 2, 10, 2)
	) AS t(has_skip_element, element_blkno, element_offno, skip_blkno, skip_offno);
});
is($skip_self_for_vacuum_update_parity, "t\nt\nt\nt");

my $use_skip_element_for_existing_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_skip_element_for_existing(existing) =
		   rust_hnsw_should_use_skip_element_for_existing(existing)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(existing);
});
is($use_skip_element_for_existing_parity, "t\nt\nt\nt");

my $have_skip_element_for_existing_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_skip_element_for_existing(existing) =
		   rust_hnsw_should_have_skip_element_for_existing(existing)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(existing);
});
is($have_skip_element_for_existing_parity, "t\nt\nt\nt");

my $use_default_skip_element_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_default_skip_element_tid(has_skip_element) =
		   rust_hnsw_should_use_default_skip_element_tid(has_skip_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_skip_element);
});
is($use_default_skip_element_tid_parity, "t\nt\nt\nt");

my $have_default_skip_element_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_default_skip_element_tid(has_skip_element) =
		   rust_hnsw_should_have_default_skip_element_tid(has_skip_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_skip_element);
});
is($have_default_skip_element_tid_parity, "t\nt\nt\nt");

my $have_skip_element_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_skip_element_pointer(has_skip_element) =
		   rust_hnsw_should_have_skip_element_pointer(has_skip_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_skip_element);
});
is($have_skip_element_pointer_parity, "t\nt\nt\nt");

my $use_default_type_info_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_default_type_info(has_procinfo) =
		   rust_hnsw_should_use_default_type_info(has_procinfo)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_procinfo);
});
is($use_default_type_info_parity, "t\nt\nt\nt");

my $have_default_type_info_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_default_type_info(has_procinfo) =
		   rust_hnsw_should_have_default_type_info(has_procinfo)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_procinfo);
});
is($have_default_type_info_parity, "t\nt\nt\nt");

my $have_typeinfo_procinfo_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_typeinfo_procinfo_pointer(has_procinfo) =
		   rust_hnsw_should_have_typeinfo_procinfo_pointer(has_procinfo)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_procinfo);
});
is($have_typeinfo_procinfo_pointer_parity, "t\nt\nt\nt");

my $reject_sparsevec_excess_nnz_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_sparsevec_excess_nnz(nnz, max_nnz) =
		   rust_hnsw_should_reject_sparsevec_excess_nnz(nnz, max_nnz)
	FROM (VALUES
		(0, 100),
		(100, 100),
		(101, 100),
		(200, 199)
	) AS t(nnz, max_nnz);
});
is($reject_sparsevec_excess_nnz_parity, "t\nt\nt\nt");

my $sort_neighbor_candidates_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_sort_neighbor_candidates(sort_candidates) =
		   rust_hnsw_should_sort_neighbor_candidates(sort_candidates)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(sort_candidates);
});
is($sort_neighbor_candidates_parity, "t\nt\nt\nt");

my $sort_pointer_candidates_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_sort_pointer_candidates(has_base_pointer) =
		   rust_hnsw_should_sort_pointer_candidates(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_base_pointer);
});
is($sort_pointer_candidates_parity, "t\nt\nt\nt");

my $have_sort_base_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_sort_base_pointer(has_base_pointer) =
		   rust_hnsw_should_have_sort_base_pointer(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_base_pointer);
});
is($have_sort_base_pointer_parity, "t\nt\nt\nt");

my $calculate_neighbor_closer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_calculate_neighbor_closer(must_calculate) =
		   rust_hnsw_should_calculate_neighbor_closer(must_calculate)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(must_calculate);
});
is($calculate_neighbor_closer_parity, "t\nt\nt\nt");

my $reuse_added_candidates_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reuse_added_candidates(added_count) =
		   rust_hnsw_should_reuse_added_candidates(added_count)
	FROM (VALUES
		(0),
		(1),
		(2),
		(0)
	) AS t(added_count);
});
is($reuse_added_candidates_parity, "t\nt\nt\nt");

my $define_closer_state_for_base_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_define_closer_state_for_base(has_base_pointer) =
		   rust_hnsw_should_define_closer_state_for_base(has_base_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_base_pointer);
});
is($define_closer_state_for_base_parity, "t\nt\nt\nt");

my $reject_closer_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_closer_neighbor(distance_value, candidate_distance) =
		   rust_hnsw_should_reject_closer_neighbor(distance_value, candidate_distance)
	FROM (VALUES
		(0.10::float8, 0.20::float8),
		(0.20::float8, 0.20::float8),
		(0.30::float8, 0.20::float8),
		(0.05::float8, 0.10::float8)
	) AS t(distance_value, candidate_distance);
});
is($reject_closer_neighbor_parity, "t\nt\nt\nt");

my $have_reject_closer_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_reject_closer_neighbor(distance_value, candidate_distance) =
		   rust_hnsw_should_have_reject_closer_neighbor(distance_value, candidate_distance)
	FROM (VALUES
		(0.10::float8, 0.20::float8),
		(0.20::float8, 0.20::float8),
		(0.30::float8, 0.20::float8),
		(0.05::float8, 0.10::float8)
	) AS t(distance_value, candidate_distance);
});
is($have_reject_closer_neighbor_parity, "t\nt\nt\nt");

my $select_neighbors_early_return_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_select_neighbors_early_return(candidate_count, max_neighbors) =
		   rust_hnsw_should_select_neighbors_early_return(candidate_count, max_neighbors)
	FROM (VALUES
		(0, 0),
		(4, 5),
		(5, 5),
		(6, 5)
	) AS t(candidate_count, max_neighbors);
});
is($select_neighbors_early_return_parity, "t\nt\nt\nt");

my $have_select_neighbors_early_return_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_select_neighbors_early_return(candidate_count, max_neighbors) =
		   rust_hnsw_should_have_select_neighbors_early_return(candidate_count, max_neighbors)
	FROM (VALUES
		(0, 0),
		(4, 5),
		(5, 5),
		(6, 5)
	) AS t(candidate_count, max_neighbors);
});
is($have_select_neighbors_early_return_parity, "t\nt\nt\nt");

my $add_search_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_add_search_candidate(candidate_distance, frontier_distance, always_add) =
		   rust_hnsw_should_add_search_candidate(candidate_distance, frontier_distance, always_add)
	FROM (VALUES
		(0.10::float8, 0.20::float8, 0),
		(0.30::float8, 0.20::float8, 0),
		(0.30::float8, 0.20::float8, 1),
		(0.20::float8, 0.20::float8, 0)
	) AS t(candidate_distance, frontier_distance, always_add);
});
is($add_search_candidate_parity, "t\nt\nt\nt");

my $have_add_search_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_add_search_candidate(candidate_distance, frontier_distance, always_add) =
		   rust_hnsw_should_have_add_search_candidate(candidate_distance, frontier_distance, always_add)
	FROM (VALUES
		(0.10::float8, 0.20::float8, 0),
		(0.30::float8, 0.20::float8, 0),
		(0.30::float8, 0.20::float8, 1),
		(0.20::float8, 0.20::float8, 0)
	) AS t(candidate_distance, frontier_distance, always_add);
});
is($have_add_search_candidate_parity, "t\nt\nt\nt");

my $stop_search_layer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_search_layer(candidate_distance, frontier_distance) =
		   rust_hnsw_should_stop_search_layer(candidate_distance, frontier_distance)
	FROM (VALUES
		(0.10::float8, 0.20::float8),
		(0.20::float8, 0.20::float8),
		(0.30::float8, 0.20::float8),
		(0.50::float8, 0.10::float8)
	) AS t(candidate_distance, frontier_distance);
});
is($stop_search_layer_parity, "t\nt\nt\nt");

my $have_stop_search_layer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_stop_search_layer(candidate_distance, frontier_distance) =
		   rust_hnsw_should_have_stop_search_layer(candidate_distance, frontier_distance)
	FROM (VALUES
		(0.10::float8, 0.20::float8),
		(0.20::float8, 0.20::float8),
		(0.30::float8, 0.20::float8),
		(0.50::float8, 0.10::float8)
	) AS t(candidate_distance, frontier_distance);
});
is($have_stop_search_layer_parity, "t\nt\nt\nt");

my $append_neighbor_without_prune_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_append_neighbor_without_prune(neighbors_length, max_neighbors) =
		   rust_hnsw_should_append_neighbor_without_prune(neighbors_length, max_neighbors)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(3, 5)
	) AS t(neighbors_length, max_neighbors);
});
is($append_neighbor_without_prune_parity, "t\nt\nt\nt");

my $have_append_neighbor_without_prune_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_append_neighbor_without_prune(neighbors_length, max_neighbors) =
		   rust_hnsw_should_have_append_neighbor_without_prune(neighbors_length, max_neighbors)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(3, 5)
	) AS t(neighbors_length, max_neighbors);
});
is($have_append_neighbor_without_prune_parity, "t\nt\nt\nt");

my $skip_lower_level_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_lower_level_candidate(candidate_level, search_level) =
		   rust_hnsw_should_skip_lower_level_candidate(candidate_level, search_level)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(3, 5)
	) AS t(candidate_level, search_level);
});
is($skip_lower_level_candidate_parity, "t\nt\nt\nt");

my $have_skip_lower_level_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_skip_lower_level_candidate(candidate_level, search_level) =
		   rust_hnsw_should_have_skip_lower_level_candidate(candidate_level, search_level)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(3, 5)
	) AS t(candidate_level, search_level);
});
is($have_skip_lower_level_candidate_parity, "t\nt\nt\nt");

my $keep_pruned_connection_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_keep_pruned_connection(wdoff, wdlen, result_length, max_neighbors) =
		   rust_hnsw_should_keep_pruned_connection(wdoff, wdlen, result_length, max_neighbors)
	FROM (VALUES
		(0, 1, 0, 1),
		(1, 1, 0, 1),
		(0, 2, 1, 1),
		(1, 3, 0, 2)
	) AS t(wdoff, wdlen, result_length, max_neighbors);
});
is($keep_pruned_connection_parity, "t\nt\nt\nt");

my $have_keep_pruned_connection_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_keep_pruned_connection(wdoff, wdlen, result_length, max_neighbors) =
		   rust_hnsw_should_have_keep_pruned_connection(wdoff, wdlen, result_length, max_neighbors)
	FROM (VALUES
		(0, 1, 0, 1),
		(1, 1, 0, 1),
		(0, 2, 1, 1),
		(1, 3, 0, 2)
	) AS t(wdoff, wdlen, result_length, max_neighbors);
});
is($have_keep_pruned_connection_parity, "t\nt\nt\nt");

my $set_pruned_from_array_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_set_pruned_from_array(wdoff, wdlen) =
		   rust_hnsw_should_set_pruned_from_array(wdoff, wdlen)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(1, 3)
	) AS t(wdoff, wdlen);
});
is($set_pruned_from_array_parity, "t\nt\nt\nt");

my $have_set_pruned_from_array_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_set_pruned_from_array(wdoff, wdlen) =
		   rust_hnsw_should_have_set_pruned_from_array(wdoff, wdlen)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(1, 3)
	) AS t(wdoff, wdlen);
});
is($have_set_pruned_from_array_parity, "t\nt\nt\nt");

my $track_discarded_candidates_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_track_discarded_candidates(has_discarded_heap) =
		   rust_hnsw_should_track_discarded_candidates(has_discarded_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_discarded_heap);
});
is($track_discarded_candidates_parity, "t\nt\nt\nt");

my $have_track_discarded_candidates_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_track_discarded_candidates(has_discarded_heap) =
		   rust_hnsw_should_have_track_discarded_candidates(has_discarded_heap)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_discarded_heap);
});
is($have_track_discarded_candidates_parity, "t\nt\nt\nt");

my $track_update_index_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_track_update_index(has_update_index_pointer) =
		   rust_hnsw_should_track_update_index(has_update_index_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_update_index_pointer);
});
is($track_update_index_parity, "t\nt\nt\nt");

my $have_track_update_index_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_track_update_index(has_update_index_pointer) =
		   rust_hnsw_should_have_track_update_index(has_update_index_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_update_index_pointer);
});
is($have_track_update_index_parity, "t\nt\nt\nt");

my $process_pruned_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_process_pruned_candidate(has_pruned_candidate) =
		   rust_hnsw_should_process_pruned_candidate(has_pruned_candidate)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pruned_candidate);
});
is($process_pruned_candidate_parity, "t\nt\nt\nt");

my $have_process_pruned_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_process_pruned_candidate(has_pruned_candidate) =
		   rust_hnsw_should_have_process_pruned_candidate(has_pruned_candidate)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pruned_candidate);
});
is($have_process_pruned_candidate_parity, "t\nt\nt\nt");

my $trim_candidate_list_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_trim_candidate_list(candidate_count, ef_value) =
		   rust_hnsw_should_trim_candidate_list(candidate_count, ef_value)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(5, 3)
	) AS t(candidate_count, ef_value);
});
is($trim_candidate_list_parity, "t\nt\nt\nt");

my $have_trim_candidate_list_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_trim_candidate_list(candidate_count, ef_value) =
		   rust_hnsw_should_have_trim_candidate_list(candidate_count, ef_value)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(5, 3)
	) AS t(candidate_count, ef_value);
});
is($have_trim_candidate_list_parity, "t\nt\nt\nt");

my $always_add_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_always_add_candidate(candidate_count, ef_value) =
		   rust_hnsw_should_always_add_candidate(candidate_count, ef_value)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(5, 3)
	) AS t(candidate_count, ef_value);
});
is($always_add_candidate_parity, "t\nt\nt\nt");

my $have_always_add_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_always_add_candidate(candidate_count, ef_value) =
		   rust_hnsw_should_have_always_add_candidate(candidate_count, ef_value)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(5, 3)
	) AS t(candidate_count, ef_value);
});
is($have_always_add_candidate_parity, "t\nt\nt\nt");

my $append_closer_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_append_closer_candidate(is_closer) =
		   rust_hnsw_should_append_closer_candidate(is_closer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_closer);
});
is($append_closer_candidate_parity, "t\nt\nt\nt");

my $recheck_candidate_after_removal_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_recheck_candidate_after_removal(removed_any) =
		   rust_hnsw_should_recheck_candidate_after_removal(removed_any)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(removed_any);
});
is($recheck_candidate_after_removal_parity, "t\nt\nt\nt");

my $return_pruned_output_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_pruned_output(has_pruned_output) =
		   rust_hnsw_should_return_pruned_output(has_pruned_output)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pruned_output);
});
is($return_pruned_output_parity, "t\nt\nt\nt");

my $have_pruned_output_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_pruned_output_pointer(has_pruned_output) =
		   rust_hnsw_should_have_pruned_output_pointer(has_pruned_output)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pruned_output);
});
is($have_pruned_output_pointer_parity, "t\nt\nt\nt");

my $process_new_candidate_branch_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_process_new_candidate_branch(is_new_candidate) =
		   rust_hnsw_should_process_new_candidate_branch(is_new_candidate)
	FROM (VALUES
		(1),
		(0),
		(1),
		(0)
	) AS t(is_new_candidate);
});
is($process_new_candidate_branch_parity, "t\nt\nt\nt");

my $have_new_candidate_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_new_candidate_pointer(has_new_candidate_pointer) =
		   rust_hnsw_should_have_new_candidate_pointer(has_new_candidate_pointer)
	FROM (VALUES
		(1),
		(0),
		(1),
		(0)
	) AS t(has_new_candidate_pointer);
});
is($have_new_candidate_pointer_parity, "t\nt\nt\nt");

my $replace_pruned_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_replace_pruned_neighbor(matches_pruned) =
		   rust_hnsw_should_replace_pruned_neighbor(matches_pruned)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(matches_pruned);
});
is($replace_pruned_neighbor_parity, "t\nt\nt\nt");

my $abort_without_pruned_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_abort_without_pruned_candidate(has_pruned_candidate) =
		   rust_hnsw_should_abort_without_pruned_candidate(has_pruned_candidate)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pruned_candidate);
});
is($abort_without_pruned_candidate_parity, "t\nt\nt\nt");

my $enqueue_counted_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_enqueue_counted_candidate(counted_candidate) =
		   rust_hnsw_should_enqueue_counted_candidate(counted_candidate)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(counted_candidate);
});
is($enqueue_counted_candidate_parity, "t\nt\nt\nt");

my $skip_missing_search_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_skip_missing_search_element(has_element) =
		   rust_hnsw_should_skip_missing_search_element(has_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_element);
});
is($skip_missing_search_element_parity, "t\nt\nt\nt");

my $have_search_element_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_search_element_pointer(has_element) =
		   rust_hnsw_should_have_search_element_pointer(has_element)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_element);
});
is($have_search_element_pointer_parity, "t\nt\nt\nt");

my $copy_tuple_slot_by_index_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_copy_tuple_slot_by_index(slot_index, slot_limit) =
		   rust_hnsw_should_copy_tuple_slot_by_index(slot_index, slot_limit)
	FROM (VALUES
		(0, 0),
		(0, 1),
		(1, 1),
		(2, 1),
		(3, 4),
		(4, 4)
	) AS t(slot_index, slot_limit);
});
is($copy_tuple_slot_by_index_parity, "t\nt\nt\nt\nt\nt");

my $cap_element_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_cap_element_level(level_value, max_level) =
		   rust_hnsw_should_cap_element_level(level_value, max_level)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(2, 2),
		(3, 2),
		(-1, 0),
		(5, 7)
	) AS t(level_value, max_level);
});
is($cap_element_level_parity, "t\nt\nt\nt\nt\nt");

my $use_index_options_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_index_options(has_options) =
		   rust_hnsw_should_use_index_options(has_options)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_options);
});
is($use_index_options_parity, "t\nt\nt\nt");

my $have_index_options_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_index_options(has_options) =
		   rust_hnsw_should_have_index_options(has_options)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_options);
});
is($have_index_options_parity, "t\nt\nt\nt");

my $return_missing_optional_proc_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_return_missing_optional_proc(has_proc_oid) =
		   rust_hnsw_should_return_missing_optional_proc(has_proc_oid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_proc_oid);
});
is($return_missing_optional_proc_parity, "t\nt\nt\nt");

my $use_custom_allocator_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_custom_allocator(has_allocator) =
		   rust_hnsw_should_use_custom_allocator(has_allocator)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_allocator);
});
is($use_custom_allocator_parity, "t\nt\nt\nt");

my $have_custom_allocator_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_custom_allocator(has_allocator) =
		   rust_hnsw_should_have_custom_allocator(has_allocator)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_allocator);
});
is($have_custom_allocator_parity, "t\nt\nt\nt");

my $load_meta_m_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_load_meta_m(has_m_pointer) =
		   rust_hnsw_should_load_meta_m(has_m_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_m_pointer);
});
is($load_meta_m_parity, "t\nt\nt\nt");

my $have_meta_m_output_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_meta_m_output_pointer(has_m_pointer) =
		   rust_hnsw_should_have_meta_m_output_pointer(has_m_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_m_pointer);
});
is($have_meta_m_output_pointer_parity, "t\nt\nt\nt");

my $load_meta_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_load_meta_entrypoint(has_entrypoint_pointer) =
		   rust_hnsw_should_load_meta_entrypoint(has_entrypoint_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint_pointer);
});
is($load_meta_entrypoint_parity, "t\nt\nt\nt");

my $have_meta_entrypoint_output_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_meta_entrypoint_output_pointer(has_entrypoint_pointer) =
		   rust_hnsw_should_have_meta_entrypoint_output_pointer(has_entrypoint_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint_pointer);
});
is($have_meta_entrypoint_output_pointer_parity, "t\nt\nt\nt");

my $have_meta_output_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_meta_output_pointer(has_output_pointer) =
		   rust_hnsw_should_have_meta_output_pointer(has_output_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_output_pointer);
});
is($have_meta_output_pointer_parity, "t\nt\nt\nt");

my $use_meta_entry_block_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_meta_entry_block(has_valid_entry_block) =
		   rust_hnsw_should_use_meta_entry_block(has_valid_entry_block)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_valid_entry_block);
});
is($use_meta_entry_block_parity, "t\nt\nt\nt");

my $have_meta_entry_block_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_meta_entry_block(has_valid_entry_block) =
		   rust_hnsw_should_have_meta_entry_block(has_valid_entry_block)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_valid_entry_block);
});
is($have_meta_entry_block_parity, "t\nt\nt\nt");

my $have_meta_block_number_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_meta_block_number(block_number) =
		   rust_hnsw_should_have_meta_block_number(block_number)
	FROM (VALUES
		(-1),
		(0),
		(1),
		(42)
	) AS t(block_number);
});
is($have_meta_block_number_parity, "t\nt\nt\nt");

my $update_meta_entry_info_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_update_meta_entry_info(update_entry_mode) =
		   rust_hnsw_should_update_meta_entry_info(update_entry_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(1)
	) AS t(update_entry_mode);
});
is($update_meta_entry_info_parity, "t\nt\nt\nt");

my $reset_meta_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reset_meta_entrypoint(has_entrypoint) =
		   rust_hnsw_should_reset_meta_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($reset_meta_entrypoint_parity, "t\nt\nt\nt");

my $have_meta_update_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_meta_update_entrypoint(has_entrypoint) =
		   rust_hnsw_should_have_meta_update_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_meta_update_entrypoint_parity, "t\nt\nt\nt");

my $write_meta_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_write_meta_entrypoint(has_entrypoint, entry_level, current_entry_level, update_entry_mode) =
		   rust_hnsw_should_write_meta_entrypoint(has_entrypoint, entry_level, current_entry_level, update_entry_mode)
	FROM (VALUES
		(0, 0, -1, 0),
		(1, 2, 1, 0),
		(1, 1, 2, 2),
		(1, 3, 3, 1),
		(1, 2, 3, 1),
		(0, 5, 4, 2)
	) AS t(has_entrypoint, entry_level, current_entry_level, update_entry_mode);
});
is($write_meta_entrypoint_parity, "t\nt\nt\nt\nt\nt");

my $write_meta_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_write_meta_insert_page(has_valid_insert_page) =
		   rust_hnsw_should_write_meta_insert_page(has_valid_insert_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_valid_insert_page);
});
is($write_meta_insert_page_parity, "t\nt\nt\nt");

my $use_build_buffer_path_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_build_buffer_path(building) =
		   rust_hnsw_should_use_build_buffer_path(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($use_build_buffer_path_parity, "t\nt\nt\nt");

my $have_build_buffer_path_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_buffer_path(building) =
		   rust_hnsw_should_have_build_buffer_path(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($have_build_buffer_path_parity, "t\nt\nt\nt");

my $check_type_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_check_type_value(has_check_value_fn) =
		   rust_hnsw_should_check_type_value(has_check_value_fn)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_check_value_fn);
});
is($check_type_value_parity, "t\nt\nt\nt");

my $have_type_check_function_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_type_check_function(has_check_value_fn) =
		   rust_hnsw_should_have_type_check_function(has_check_value_fn)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_check_value_fn);
});
is($have_type_check_function_parity, "t\nt\nt\nt");

my $normalize_index_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_normalize_index_value(has_norm_procinfo) =
		   rust_hnsw_should_normalize_index_value(has_norm_procinfo)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_norm_procinfo);
});
is($normalize_index_value_parity, "t\nt\nt\nt");

my $have_norm_procinfo_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_norm_procinfo(has_norm_procinfo) =
		   rust_hnsw_should_have_norm_procinfo(has_norm_procinfo)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_norm_procinfo);
});
is($have_norm_procinfo_parity, "t\nt\nt\nt");

my $reject_invalid_norm_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_invalid_norm(has_valid_norm) =
		   rust_hnsw_should_reject_invalid_norm(has_valid_norm)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_valid_norm);
});
is($reject_invalid_norm_parity, "t\nt\nt\nt");

my $prioritize_lower_distance_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_prioritize_lower_distance(left_distance, right_distance) =
		   rust_hnsw_should_prioritize_lower_distance(left_distance, right_distance)
	FROM (VALUES
		(0.00::float8, 0.00::float8),
		(0.10::float8, 0.20::float8),
		(0.20::float8, 0.10::float8),
		(-1.00::float8, 0.00::float8),
		(4.00::float8, 4.00::float8)
	) AS t(left_distance, right_distance);
});
is($prioritize_lower_distance_parity, "t\nt\nt\nt\nt");

my $prioritize_pointer_tiebreak_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_prioritize_pointer_tiebreak(left_pointer_precedes) =
		   rust_hnsw_should_prioritize_pointer_tiebreak(left_pointer_precedes)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(left_pointer_precedes);
});
is($prioritize_pointer_tiebreak_parity, "t\nt\nt\nt");

my $prioritize_offset_tiebreak_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_prioritize_offset_tiebreak(left_offset_precedes) =
		   rust_hnsw_should_prioritize_offset_tiebreak(left_offset_precedes)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(left_offset_precedes);
});
is($prioritize_offset_tiebreak_parity, "t\nt\nt\nt");

my $reject_invalid_meta_magic_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_invalid_meta_magic(has_expected_magic) =
		   rust_hnsw_should_reject_invalid_meta_magic(has_expected_magic)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_expected_magic);
});
is($reject_invalid_meta_magic_parity, "t\nt\nt\nt");

my $have_expected_meta_magic_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_expected_meta_magic(magic_number) =
		   rust_hnsw_should_have_expected_meta_magic(magic_number)
	FROM (VALUES
		(0),
		(305419896),
		(-1),
		(1)
	) AS t(magic_number);
});
is($have_expected_meta_magic_parity, "t\nt\nt\nt");

my $force_meta_entry_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_force_meta_entry_update(update_entry_mode) =
		   rust_hnsw_should_force_meta_entry_update(update_entry_mode)
	FROM (VALUES
		(0),
		(1),
		(2),
		(3)
	) AS t(update_entry_mode);
});
is($force_meta_entry_update_parity, "t\nt\nt\nt");

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

my $have_ondisk_space_for_combined_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_space_for_combined_tuple(free_space, combined_size) =
		   rust_hnsw_should_have_ondisk_space_for_combined_tuple(free_space, combined_size)
	FROM (VALUES
		(0, 1),
		(128, 128),
		(256, 128),
		(127, 128)
	) AS t(free_space, combined_size);
});
is($have_ondisk_space_for_combined_tuple_parity, "t\nt\nt\nt");

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

my $have_build_path_for_ondisk_add_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_path_for_ondisk_add_element(building) =
		   rust_hnsw_should_have_build_path_for_ondisk_add_element(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($have_build_path_for_ondisk_add_element_parity, "t\nt\nt\nt");

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

my $have_build_path_for_appended_ondisk_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_path_for_appended_ondisk_buffer(building) =
		   rust_hnsw_should_have_build_path_for_appended_ondisk_buffer(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($have_build_path_for_appended_ondisk_buffer_parity, "t\nt\nt\nt");

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

my $have_build_path_for_reused_ondisk_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_path_for_reused_ondisk_buffer(building) =
		   rust_hnsw_should_have_build_path_for_reused_ondisk_buffer(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($have_build_path_for_reused_ondisk_buffer_parity, "t\nt\nt\nt");

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

my $have_ondisk_next_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_next_page(next_page_valid) =
		   rust_hnsw_should_have_ondisk_next_page(next_page_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(next_page_valid);
});
is($have_ondisk_next_page_parity, "t\nt\nt\nt");

my $have_ondisk_block_number_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_block_number(block_number) =
		   rust_hnsw_should_have_ondisk_block_number(block_number)
	FROM (VALUES
		(-1),
		(0),
		(1),
		(42)
	) AS t(block_number);
});
is($have_ondisk_block_number_parity, "t\nt\nt\nt");

my $have_valid_ondisk_block_number_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_valid_ondisk_block_number(block_number) =
		   rust_hnsw_should_have_valid_ondisk_block_number(block_number)
	FROM (VALUES
		(-1),
		(0),
		(1),
		(42)
	) AS t(block_number);
});
is($have_valid_ondisk_block_number_parity, "t\nt\nt\nt");

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

my $have_ondisk_insert_space_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_insert_space(has_space) =
		   rust_hnsw_should_have_ondisk_insert_space(has_space)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_space);
});
is($have_ondisk_insert_space_parity, "t\nt\nt\nt");

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

my $have_build_path_for_ondisk_append_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_path_for_ondisk_append_page(building) =
		   rust_hnsw_should_have_build_path_for_ondisk_append_page(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($have_build_path_for_ondisk_append_page_parity, "t\nt\nt\nt");

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

my $have_build_path_for_ondisk_neighbor_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_path_for_ondisk_neighbor_update(building) =
		   rust_hnsw_should_have_build_path_for_ondisk_neighbor_update(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($have_build_path_for_ondisk_neighbor_update_parity, "t\nt\nt\nt");

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

my $have_build_path_for_ondisk_duplicate_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_build_path_for_ondisk_duplicate_page(building) =
		   rust_hnsw_should_have_build_path_for_ondisk_duplicate_page(building)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(building);
});
is($have_build_path_for_ondisk_duplicate_page_parity, "t\nt\nt\nt");

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

my $have_nonbuilding_ondisk_duplicate_slot_reject_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject(building) =
		   rust_hnsw_should_have_nonbuilding_ondisk_duplicate_slot_reject(building)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(building);
});
is($have_nonbuilding_ondisk_duplicate_slot_reject_parity, "t\nt\nt\nt");

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

my $have_invalid_ondisk_heaptid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_invalid_ondisk_heaptid(heap_tid_valid) =
		   rust_hnsw_should_have_invalid_ondisk_heaptid(heap_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(heap_tid_valid);
});
is($have_invalid_ondisk_heaptid_parity, "t\nt\nt\nt");

my $have_ondisk_heaptid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_heaptid(heap_tid_valid) =
		   rust_hnsw_should_have_ondisk_heaptid(heap_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(heap_tid_valid);
});
is($have_ondisk_heaptid_parity, "t\nt\nt\nt");

my $have_ondisk_itempointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_itempointer(item_pointer_valid) =
		   rust_hnsw_should_have_ondisk_itempointer(item_pointer_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(item_pointer_valid);
});
is($have_ondisk_itempointer_parity, "t\nt\nt\nt");

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

my $have_free_ondisk_neighbor_slot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_free_ondisk_neighbor_slot(slot_tid_valid) =
		   rust_hnsw_should_have_free_ondisk_neighbor_slot(slot_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(slot_tid_valid);
});
is($have_free_ondisk_neighbor_slot_parity, "t\nt\nt\nt");

my $have_invalid_ondisk_neighbor_slot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_invalid_ondisk_neighbor_slot(slot_tid_valid) =
		   rust_hnsw_should_have_invalid_ondisk_neighbor_slot(slot_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(slot_tid_valid);
});
is($have_invalid_ondisk_neighbor_slot_parity, "t\nt\nt\nt");

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

my $have_invalid_ondisk_neighbor_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_invalid_ondisk_neighbor_tid(neighbor_tid_valid) =
		   rust_hnsw_should_have_invalid_ondisk_neighbor_tid(neighbor_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(neighbor_tid_valid);
});
is($have_invalid_ondisk_neighbor_tid_parity, "t\nt\nt\nt");

my $have_ondisk_neighbor_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_neighbor_tid(neighbor_tid_valid) =
		   rust_hnsw_should_have_ondisk_neighbor_tid(neighbor_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(neighbor_tid_valid);
});
is($have_ondisk_neighbor_tid_parity, "t\nt\nt\nt");

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

my $have_non_element_vacuum_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_non_element_vacuum_tuple(is_element_tuple) =
		   rust_hnsw_should_have_non_element_vacuum_tuple(is_element_tuple)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(is_element_tuple);
});
is($have_non_element_vacuum_tuple_parity, "t\nt\nt\nt");

my $have_invalid_vacuum_last_item_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_invalid_vacuum_last_item(last_item_valid) =
		   rust_hnsw_should_have_invalid_vacuum_last_item(last_item_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(last_item_valid);
});
is($have_invalid_vacuum_last_item_parity, "t\nt\nt\nt");

my $contain_deleted_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_contain_deleted_tid(has_deleted_tid) =
		   rust_hnsw_should_contain_deleted_tid(has_deleted_tid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_deleted_tid);
});
is($contain_deleted_tid_parity, "t\nt\nt\nt");

my $have_deleted_tid_containment_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_deleted_tid_containment(has_deleted_tid) =
		   rust_hnsw_should_have_deleted_tid_containment(has_deleted_tid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_deleted_tid);
});
is($have_deleted_tid_containment_parity, "t\nt\nt\nt");

my $contain_deleted_tid_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_contain_deleted_tid_pointer(has_deleted_tid) =
		   rust_hnsw_should_contain_deleted_tid_pointer(has_deleted_tid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_deleted_tid);
});
is($contain_deleted_tid_pointer_parity, "t\nt\nt\nt");

my $have_deleted_tid_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_deleted_tid_pointer(has_deleted_tid) =
		   rust_hnsw_should_have_deleted_tid_pointer(has_deleted_tid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_deleted_tid);
});
is($have_deleted_tid_pointer_parity, "t\nt\nt\nt");

my $continue_vacuum_block_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_continue_vacuum_block_scan(has_valid_block) =
		   rust_hnsw_should_continue_vacuum_block_scan(has_valid_block)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_valid_block);
});
is($continue_vacuum_block_scan_parity, "t\nt\nt\nt");

my $have_continuable_vacuum_block_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_continuable_vacuum_block_scan(has_valid_block) =
		   rust_hnsw_should_have_continuable_vacuum_block_scan(has_valid_block)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_valid_block);
});
is($have_continuable_vacuum_block_scan_parity, "t\nt\nt\nt");

my $have_vacuum_scan_block_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_scan_block(has_valid_block) =
		   rust_hnsw_should_have_vacuum_scan_block(has_valid_block)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_valid_block);
});
is($have_vacuum_scan_block_parity, "t\nt\nt\nt");

my $have_vacuum_block_number_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_block_number(block_number) =
		   rust_hnsw_should_have_vacuum_block_number(block_number)
	FROM (VALUES
		(-1),
		(0),
		(1),
		(42)
	) AS t(block_number);
});
is($have_vacuum_block_number_parity, "t\nt\nt\nt");

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

my $have_processable_vacuum_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_processable_vacuum_heaptids(first_heaptid_valid) =
		   rust_hnsw_should_have_processable_vacuum_heaptids(first_heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(first_heaptid_valid);
});
is($have_processable_vacuum_heaptids_parity, "t\nt\nt\nt");

my $have_vacuum_tuple_heaptid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_tuple_heaptid(first_heaptid_valid) =
		   rust_hnsw_should_have_vacuum_tuple_heaptid(first_heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(first_heaptid_valid);
});
is($have_vacuum_tuple_heaptid_parity, "t\nt\nt\nt");

my $have_vacuum_itempointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_itempointer(itempointer_valid) =
		   rust_hnsw_should_have_vacuum_itempointer(itempointer_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(itempointer_valid);
});
is($have_vacuum_itempointer_parity, "t\nt\nt\nt");

my $have_vacuum_tuple_heaptid_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_tuple_heaptid_pointer(first_heaptid_valid) =
		   rust_hnsw_should_have_vacuum_tuple_heaptid_pointer(first_heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(first_heaptid_valid);
});
is($have_vacuum_tuple_heaptid_pointer_parity, "t\nt\nt\nt");

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

my $have_deleted_vacuum_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_deleted_vacuum_tuple(first_heaptid_valid) =
		   rust_hnsw_should_have_deleted_vacuum_tuple(first_heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(first_heaptid_valid);
});
is($have_deleted_vacuum_tuple_parity, "t\nt\nt\nt");

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

my $have_invalid_vacuum_heaptid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_invalid_vacuum_heaptid(heaptid_valid) =
		   rust_hnsw_should_have_invalid_vacuum_heaptid(heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(heaptid_valid);
});
is($have_invalid_vacuum_heaptid_parity, "t\nt\nt\nt");

my $have_vacuum_heaptid_scan_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_heaptid_scan_tid(heaptid_valid) =
		   rust_hnsw_should_have_vacuum_heaptid_scan_tid(heaptid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(heaptid_valid);
});
is($have_vacuum_heaptid_scan_tid_parity, "t\nt\nt\nt");

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

my $have_vacuum_heaptid_removal_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_heaptid_removal(callback_remove) =
		   rust_hnsw_should_have_vacuum_heaptid_removal(callback_remove)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(callback_remove);
});
is($have_vacuum_heaptid_removal_parity, "t\nt\nt\nt");

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

my $have_compacted_vacuum_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_compacted_vacuum_heaptids(item_updated) =
		   rust_hnsw_should_have_compacted_vacuum_heaptids(item_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(item_updated);
});
is($have_compacted_vacuum_heaptids_parity, "t\nt\nt\nt");

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

my $have_finished_vacuum_page_update_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_finished_vacuum_page_update(page_updated) =
		   rust_hnsw_should_have_finished_vacuum_page_update(page_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(page_updated);
});
is($have_finished_vacuum_page_update_parity, "t\nt\nt\nt");

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

my $have_invalid_vacuum_neighbor_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_invalid_vacuum_neighbor_tid(neighbor_tid_valid) =
		   rust_hnsw_should_have_invalid_vacuum_neighbor_tid(neighbor_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(neighbor_tid_valid);
});
is($have_invalid_vacuum_neighbor_tid_parity, "t\nt\nt\nt");

my $have_vacuum_neighbor_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_neighbor_tid(neighbor_tid_valid) =
		   rust_hnsw_should_have_vacuum_neighbor_tid(neighbor_tid_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(neighbor_tid_valid);
});
is($have_vacuum_neighbor_tid_parity, "t\nt\nt\nt");

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

my $have_deleted_vacuum_neighbor_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_deleted_vacuum_neighbor(is_deleted_neighbor) =
		   rust_hnsw_should_have_deleted_vacuum_neighbor(is_deleted_neighbor)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(is_deleted_neighbor);
});
is($have_deleted_vacuum_neighbor_parity, "t\nt\nt\nt");

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

my $have_vacuum_underfilled_layer0_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_underfilled_layer0(needs_updated) =
		   rust_hnsw_should_have_vacuum_underfilled_layer0(needs_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(needs_updated);
});
is($have_vacuum_underfilled_layer0_parity, "t\nt\nt\nt");

my $have_repair_underfilled_layer0_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_repair_underfilled_layer0(last_item_valid) =
		   rust_hnsw_should_have_repair_underfilled_layer0(last_item_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(last_item_valid);
});
is($have_repair_underfilled_layer0_parity, "t\nt\nt\nt");

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

my $have_matching_vacuum_entrypoint_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_matching_vacuum_entrypoint_element(element_blkno, element_offno, entry_blkno, entry_offno) =
		   rust_hnsw_should_have_matching_vacuum_entrypoint_element(element_blkno, element_offno, entry_blkno, entry_offno)
	FROM (VALUES
		(1, 1, 1, 1),
		(2, 1, 1, 1),
		(3, 4, 3, 4),
		(5, 6, 7, 8)
	) AS t(element_blkno, element_offno, entry_blkno, entry_offno);
});
is($have_matching_vacuum_entrypoint_element_parity, "t\nt\nt\nt");

my $have_vacuum_skip_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_skip_entrypoint(has_entrypoint) =
		   rust_hnsw_should_have_vacuum_skip_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_vacuum_skip_entrypoint_parity, "t\nt\nt\nt");

my $use_default_vacuum_entrypoint_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_default_vacuum_entrypoint_tid(has_entrypoint) =
		   rust_hnsw_should_use_default_vacuum_entrypoint_tid(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($use_default_vacuum_entrypoint_tid_parity, "t\nt\nt\nt");

my $have_default_vacuum_entrypoint_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_default_vacuum_entrypoint_tid(has_entrypoint) =
		   rust_hnsw_should_have_default_vacuum_entrypoint_tid(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_default_vacuum_entrypoint_tid_parity, "t\nt\nt\nt");

my $have_missing_vacuum_entrypoint_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_missing_vacuum_entrypoint_tid(has_entrypoint) =
		   rust_hnsw_should_have_missing_vacuum_entrypoint_tid(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_missing_vacuum_entrypoint_tid_parity, "t\nt\nt\nt");

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

my $have_vacuum_element_without_updates_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_element_without_updates(needs_updated) =
		   rust_hnsw_should_have_vacuum_element_without_updates(needs_updated)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(needs_updated);
});
is($have_vacuum_element_without_updates_parity, "t\nt\nt\nt");

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

my $have_vacuum_missing_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_missing_entrypoint(entry_point_is_null) =
		   rust_hnsw_should_have_vacuum_missing_entrypoint(entry_point_is_null)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(entry_point_is_null);
});
is($have_vacuum_missing_entrypoint_parity, "t\nt\nt\nt");

my $have_higher_vacuum_entrypoint_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_higher_vacuum_entrypoint_level(element_level, entry_level) =
		   rust_hnsw_should_have_higher_vacuum_entrypoint_level(element_level, entry_level)
	FROM (VALUES
		(0, 1),
		(6, 5),
		(2, 2),
		(7, 3)
	) AS t(element_level, entry_level);
});
is($have_higher_vacuum_entrypoint_level_parity, "t\nt\nt\nt");

my $use_default_vacuum_entry_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_default_vacuum_entry_level(has_entrypoint) =
		   rust_hnsw_should_use_default_vacuum_entry_level(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($use_default_vacuum_entry_level_parity, "t\nt\nt\nt");

my $have_default_vacuum_entry_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_default_vacuum_entry_level(has_entrypoint) =
		   rust_hnsw_should_have_default_vacuum_entry_level(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_entrypoint);
});
is($have_default_vacuum_entry_level_parity, "t\nt\nt\nt");

my $need_vacuum_entrypoint_replacement_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_need_vacuum_entrypoint_replacement(has_entrypoint) =
		   rust_hnsw_should_need_vacuum_entrypoint_replacement(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($need_vacuum_entrypoint_replacement_parity, "t\nt\nt\nt");

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

my $have_vacuum_highest_point_block_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_highest_point_block(highest_point_valid) =
		   rust_hnsw_should_have_vacuum_highest_point_block(highest_point_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(highest_point_valid);
});
is($have_vacuum_highest_point_block_parity, "t\nt\nt\nt");

my $have_vacuum_highest_point_block_number_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_highest_point_block_number(block_number) =
		   rust_hnsw_should_have_vacuum_highest_point_block_number(block_number)
	FROM (VALUES
		(-1),
		(0),
		(1),
		(42)
	) AS t(block_number);
});
is($have_vacuum_highest_point_block_number_parity, "t\nt\nt\nt");

my $have_vacuum_highest_point_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_highest_point_pointer(has_highest_point) =
		   rust_hnsw_should_have_vacuum_highest_point_pointer(has_highest_point)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_highest_point);
});
is($have_vacuum_highest_point_pointer_parity, "t\nt\nt\nt");

my $have_vacuum_highest_point_pointer_flag_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_highest_point_pointer_flag(has_highest_point) =
		   rust_hnsw_should_have_vacuum_highest_point_pointer_flag(has_highest_point)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_highest_point);
});
is($have_vacuum_highest_point_pointer_flag_parity, "t\nt\nt\nt");

my $have_vacuum_highest_point_pointer_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_highest_point_pointer_value(has_highest_point) =
		   rust_hnsw_should_have_vacuum_highest_point_pointer_value(has_highest_point)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_highest_point);
});
is($have_vacuum_highest_point_pointer_value_parity, "t\nt\nt\nt");

my $have_vacuum_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_pointer(has_pointer) =
		   rust_hnsw_should_have_vacuum_pointer(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_vacuum_pointer_parity, "t\nt\nt\nt");

my $have_vacuum_pointer_flag_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_pointer_flag(has_pointer) =
		   rust_hnsw_should_have_vacuum_pointer_flag(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_vacuum_pointer_flag_parity, "t\nt\nt\nt");

my $have_vacuum_pointer_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_pointer_value(has_pointer) =
		   rust_hnsw_should_have_vacuum_pointer_value(has_pointer)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_pointer);
});
is($have_vacuum_pointer_value_parity, "t\nt\nt\nt");

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

my $have_vacuum_highest_point_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_highest_point(has_highest_point) =
		   rust_hnsw_should_have_vacuum_highest_point(has_highest_point)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_highest_point);
});
is($have_vacuum_highest_point_parity, "t\nt\nt\nt");

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

my $have_vacuum_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_entrypoint(has_entrypoint) =
		   rust_hnsw_should_have_vacuum_entrypoint(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_vacuum_entrypoint_parity, "t\nt\nt\nt");

my $have_vacuum_entrypoint_flag_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_entrypoint_flag(has_entrypoint) =
		   rust_hnsw_should_have_vacuum_entrypoint_flag(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_vacuum_entrypoint_flag_parity, "t\nt\nt\nt");

my $have_vacuum_entrypoint_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_entrypoint_pointer(has_entrypoint) =
		   rust_hnsw_should_have_vacuum_entrypoint_pointer(has_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_entrypoint);
});
is($have_vacuum_entrypoint_pointer_parity, "t\nt\nt\nt");

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

my $have_deleted_markdeleted_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_deleted_markdeleted_tuple(is_deleted_tuple) =
		   rust_hnsw_should_have_deleted_markdeleted_tuple(is_deleted_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_deleted_tuple);
});
is($have_deleted_markdeleted_tuple_parity, "t\nt\nt\nt");

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

my $have_non_element_markdeleted_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_non_element_markdeleted_tuple(is_element_tuple) =
		   rust_hnsw_should_have_non_element_markdeleted_tuple(is_element_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_element_tuple);
});
is($have_non_element_markdeleted_tuple_parity, "t\nt\nt\nt");

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

my $have_live_markdeleted_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_live_markdeleted_tuple(is_live_tuple) =
		   rust_hnsw_should_have_live_markdeleted_tuple(is_live_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_live_tuple);
});
is($have_live_markdeleted_tuple_parity, "t\nt\nt\nt");

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

my $have_vacuum_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_insert_page(has_insert_page) =
		   rust_hnsw_should_have_vacuum_insert_page(has_insert_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_insert_page);
});
is($have_vacuum_insert_page_parity, "t\nt\nt\nt");

my $have_missing_vacuum_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_missing_vacuum_insert_page(has_insert_page) =
		   rust_hnsw_should_have_missing_vacuum_insert_page(has_insert_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_insert_page);
});
is($have_missing_vacuum_insert_page_parity, "t\nt\nt\nt");

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

my $have_non_element_repairgraph_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_non_element_repairgraph_tuple(is_element_tuple) =
		   rust_hnsw_should_have_non_element_repairgraph_tuple(is_element_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_element_tuple);
});
is($have_non_element_repairgraph_tuple_parity, "t\nt\nt\nt");

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

my $have_deleted_repairgraph_element_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_deleted_repairgraph_element(is_live_tuple) =
		   rust_hnsw_should_have_deleted_repairgraph_element(is_live_tuple)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_live_tuple);
});
is($have_deleted_repairgraph_element_parity, "t\nt\nt\nt");

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

my $have_vacuum_non_entrypoint_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_non_entrypoint(is_entrypoint) =
		   rust_hnsw_should_have_vacuum_non_entrypoint(is_entrypoint)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(is_entrypoint);
});
is($have_vacuum_non_entrypoint_parity, "t\nt\nt\nt");

my $have_higher_vacuum_element_level_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_higher_vacuum_element_level(element_level, highest_level) =
		   rust_hnsw_should_have_higher_vacuum_element_level(element_level, highest_level)
	FROM (VALUES
		(0, 0),
		(1, 0),
		(1, 1),
		(2, 4)
	) AS t(element_level, highest_level);
});
is($have_higher_vacuum_element_level_parity, "t\nt\nt\nt");

my $match_vacuum_entrypoint_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_match_vacuum_entrypoint_tuple(has_entrypoint, blkno, offno, entry_blkno, entry_offno) =
		   rust_hnsw_should_match_vacuum_entrypoint_tuple(has_entrypoint, blkno, offno, entry_blkno, entry_offno)
	FROM (VALUES
		(0, 5, 3, 5, 3),
		(1, 5, 3, 5, 3),
		(1, 5, 3, 5, 4),
		(1, 9, 2, 8, 2)
	) AS t(has_entrypoint, blkno, offno, entry_blkno, entry_offno);
});
is($match_vacuum_entrypoint_tuple_parity, "t\nt\nt\nt");

my $have_matching_vacuum_entrypoint_tid_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_matching_vacuum_entrypoint_tid(blkno, offno, entry_blkno, entry_offno) =
		   rust_hnsw_should_have_matching_vacuum_entrypoint_tid(blkno, offno, entry_blkno, entry_offno)
	FROM (VALUES
		(5, 3, 5, 3),
		(5, 3, 5, 4),
		(9, 2, 8, 2),
		(7, 7, 7, 7)
	) AS t(blkno, offno, entry_blkno, entry_offno);
});
is($have_matching_vacuum_entrypoint_tid_parity, "t\nt\nt\nt");

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

my $have_failed_vacuum_neighbor_overwrite_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_failed_vacuum_neighbor_overwrite(overwrite_succeeded) =
		   rust_hnsw_should_have_failed_vacuum_neighbor_overwrite(overwrite_succeeded)
	FROM (VALUES
		(1),
		(0),
		(1),
		(0)
	) AS t(overwrite_succeeded);
});
is($have_failed_vacuum_neighbor_overwrite_parity, "t\nt\nt\nt");

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

my $have_missing_vacuum_stats_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_missing_vacuum_stats(has_stats) =
		   rust_hnsw_should_have_missing_vacuum_stats(has_stats)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_stats);
});
is($have_missing_vacuum_stats_parity, "t\nt\nt\nt");

my $have_missing_vacuum_stats_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_missing_vacuum_stats_value(has_stats) =
		   rust_hnsw_should_have_missing_vacuum_stats_value(has_stats)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_stats);
});
is($have_missing_vacuum_stats_value_parity, "t\nt\nt\nt");

my $have_vacuum_stats_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_stats(has_stats) =
		   rust_hnsw_should_have_vacuum_stats(has_stats)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_stats);
});
is($have_vacuum_stats_parity, "t\nt\nt\nt");

my $have_vacuum_stats_value_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_stats_value(has_stats) =
		   rust_hnsw_should_have_vacuum_stats_value(has_stats)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_stats);
});
is($have_vacuum_stats_value_parity, "t\nt\nt\nt");

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

my $have_vacuum_cleanup_analyze_only_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_vacuum_cleanup_analyze_only(analyze_only) =
		   rust_hnsw_should_have_vacuum_cleanup_analyze_only(analyze_only)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(analyze_only);
});
is($have_vacuum_cleanup_analyze_only_parity, "t\nt\nt\nt");

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

my $have_null_vacuum_cleanup_stats_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_null_vacuum_cleanup_stats(has_stats) =
		   rust_hnsw_should_have_null_vacuum_cleanup_stats(has_stats)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_stats);
});
is($have_null_vacuum_cleanup_stats_parity, "t\nt\nt\nt");

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

my $match_markdeleted_neighbor_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_match_markdeleted_neighbor_page(neighbor_page, element_page) =
		   rust_hnsw_should_match_markdeleted_neighbor_page(neighbor_page, element_page)
	FROM (VALUES
		(3, 3),
		(2, 3),
		(0, 0),
		(11, 10)
	) AS t(neighbor_page, element_page);
});
is($match_markdeleted_neighbor_page_parity, "t\nt\nt\nt");

my $have_matching_markdeleted_neighbor_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_matching_markdeleted_neighbor_page(neighbor_page, element_page) =
		   rust_hnsw_should_have_matching_markdeleted_neighbor_page(neighbor_page, element_page)
	FROM (VALUES
		(1, 1),
		(1, 2),
		(9, 9),
		(4, 8)
	) AS t(neighbor_page, element_page);
});
is($have_matching_markdeleted_neighbor_page_parity, "t\nt\nt\nt");

my $match_markdeleted_buffers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_match_markdeleted_buffers(left_buffer, right_buffer) =
		   rust_hnsw_should_match_markdeleted_buffers(left_buffer, right_buffer)
	FROM (VALUES
		(1, 1),
		(4, 6),
		(0, 0),
		(9, 8)
	) AS t(left_buffer, right_buffer);
});
is($match_markdeleted_buffers_parity, "t\nt\nt\nt");

my $have_matching_markdeleted_buffers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_matching_markdeleted_buffers(left_buffer, right_buffer) =
		   rust_hnsw_should_have_matching_markdeleted_buffers(left_buffer, right_buffer)
	FROM (VALUES
		(1, 1),
		(1, 2),
		(13, 13),
		(5, 6)
	) AS t(left_buffer, right_buffer);
});
is($have_matching_markdeleted_buffers_parity, "t\nt\nt\nt");

my $have_distinct_markdeleted_buffers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_distinct_markdeleted_buffers(left_buffer, right_buffer) =
		   rust_hnsw_should_have_distinct_markdeleted_buffers(left_buffer, right_buffer)
	FROM (VALUES
		(1, 1),
		(1, 2),
		(13, 13),
		(5, 6)
	) AS t(left_buffer, right_buffer);
});
is($have_distinct_markdeleted_buffers_parity, "t\nt\nt\nt");

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

my $have_markdeleted_version_beyond_max_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_markdeleted_version_beyond_max(version, max_version) =
		   rust_hnsw_should_have_markdeleted_version_beyond_max(version, max_version)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 1),
		(5, 3)
	) AS t(version, max_version);
});
is($have_markdeleted_version_beyond_max_parity, "t\nt\nt\nt");

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

my $have_missing_ondisk_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_missing_ondisk_insert_page(has_insert_page) =
		   rust_hnsw_should_have_missing_ondisk_insert_page(has_insert_page)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(has_insert_page);
});
is($have_missing_ondisk_insert_page_parity, "t\nt\nt\nt");

my $have_ondisk_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_ondisk_insert_page(has_insert_page) =
		   rust_hnsw_should_have_ondisk_insert_page(has_insert_page)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_insert_page);
});
is($have_ondisk_insert_page_parity, "t\nt\nt\nt");

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

my $match_neighbor_pages_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_match_neighbor_pages(neighbor_page, element_page) =
		   rust_hnsw_should_match_neighbor_pages(neighbor_page, element_page)
	FROM (VALUES
		(1, 1),
		(10, 11),
		(0, 0),
		(100, 99)
	) AS t(neighbor_page, element_page);
});
is($match_neighbor_pages_parity, "t\nt\nt\nt");

my $have_matching_neighbor_page_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_matching_neighbor_page(neighbor_page, element_page) =
		   rust_hnsw_should_have_matching_neighbor_page(neighbor_page, element_page)
	FROM (VALUES
		(1, 1),
		(10, 11),
		(0, 0),
		(100, 99)
	) AS t(neighbor_page, element_page);
});
is($have_matching_neighbor_page_parity, "t\nt\nt\nt");

my $match_ondisk_buffers_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_match_ondisk_buffers(left_buffer, right_buffer) =
		   rust_hnsw_should_match_ondisk_buffers(left_buffer, right_buffer)
	FROM (VALUES
		(1, 1),
		(7, 9),
		(0, 0),
		(20, 15)
	) AS t(left_buffer, right_buffer);
});
is($match_ondisk_buffers_parity, "t\nt\nt\nt");

my $have_matching_ondisk_buffer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_matching_ondisk_buffer(left_buffer, right_buffer) =
		   rust_hnsw_should_have_matching_ondisk_buffer(left_buffer, right_buffer)
	FROM (VALUES
		(1, 1),
		(7, 9),
		(0, 0),
		(20, 15)
	) AS t(left_buffer, right_buffer);
});
is($have_matching_ondisk_buffer_parity, "t\nt\nt\nt");

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

my $have_distinct_neighbor_page_space_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_distinct_neighbor_page_space(same_page) =
		   rust_hnsw_should_have_distinct_neighbor_page_space(same_page)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(same_page);
});
is($have_distinct_neighbor_page_space_parity, "t\nt\nt\nt");

my $have_page_space_for_tuple_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_page_space_for_tuple(page_free, tuple_size) =
		   rust_hnsw_should_have_page_space_for_tuple(page_free, tuple_size)
	FROM (VALUES
		(64::bigint, 32::bigint),
		(32::bigint, 32::bigint),
		(31::bigint, 32::bigint),
		(0::bigint, 1::bigint)
	) AS t(page_free, tuple_size);
});
is($have_page_space_for_tuple_parity, "t\nt\nt\nt");

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

my $have_neighbor_count_before_layer_m_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_neighbor_count_before_layer_m(neighbor_count, layer_m) =
		   rust_hnsw_should_have_neighbor_count_before_layer_m(neighbor_count, layer_m)
	FROM (VALUES
		(0, 8),
		(8, 8),
		(7, 8),
		(12, 8)
	) AS t(neighbor_count, layer_m);
});
is($have_neighbor_count_before_layer_m_parity, "t\nt\nt\nt");

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

my $have_existing_neighbor_check_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_existing_neighbor_check(check_existing) =
		   rust_hnsw_should_have_existing_neighbor_check(check_existing)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(check_existing);
});
is($have_existing_neighbor_check_parity, "t\nt\nt\nt");

my $have_existing_neighbor_connection_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_existing_neighbor_connection(connection_exists) =
		   rust_hnsw_should_have_existing_neighbor_connection(connection_exists)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(connection_exists);
});
is($have_existing_neighbor_connection_parity, "t\nt\nt\nt");

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

my $have_nonnegative_update_index_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_nonnegative_update_index(update_idx) =
		   rust_hnsw_should_have_nonnegative_update_index(update_idx)
	FROM (VALUES
		(-1),
		(0),
		(2),
		(-2)
	) AS t(update_idx);
});
is($have_nonnegative_update_index_parity, "t\nt\nt\nt");

my $have_update_index_before_tuple_count_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_update_index_before_tuple_count(update_idx, tuple_count) =
		   rust_hnsw_should_have_update_index_before_tuple_count(update_idx, tuple_count)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 4),
		(3, 2)
	) AS t(update_idx, tuple_count);
});
is($have_update_index_before_tuple_count_parity, "t\nt\nt\nt");

my $have_update_index_pointer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_update_index_pointer(has_update_idx) =
		   rust_hnsw_should_have_update_index_pointer(has_update_idx)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(has_update_idx);
});
is($have_update_index_pointer_parity, "t\nt\nt\nt");

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

my $have_matching_neighbor_block_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_matching_neighbor_block(indextid_blkno, element_blkno) =
		   rust_hnsw_should_have_matching_neighbor_block(indextid_blkno, element_blkno)
	FROM (VALUES
		(1, 1),
		(1, 2),
		(5, 5),
		(9, 8)
	) AS t(indextid_blkno, element_blkno);
});
is($have_matching_neighbor_block_parity, "t\nt\nt\nt");

my $have_matching_neighbor_offset_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_matching_neighbor_offset(indextid_offno, element_offno) =
		   rust_hnsw_should_have_matching_neighbor_offset(indextid_offno, element_offno)
	FROM (VALUES
		(1, 1),
		(1, 2),
		(8, 8),
		(9, 1)
	) AS t(indextid_offno, element_offno);
});
is($have_matching_neighbor_offset_parity, "t\nt\nt\nt");

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

my $have_candidate_update_index_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_candidate_update_index(update_idx) =
		   rust_hnsw_should_have_candidate_update_index(update_idx)
	FROM (VALUES
		(-2),
		(-1),
		(0),
		(2)
	) AS t(update_idx);
});
is($have_candidate_update_index_parity, "t\nt\nt\nt");

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

my $have_expected_ondisk_offset_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_expected_ondisk_offset(inserted_offset, expected_offset) =
		   rust_hnsw_should_have_expected_ondisk_offset(inserted_offset, expected_offset)
	FROM (VALUES
		(1, 1),
		(2, 1),
		(10, 10),
		(0, 1)
	) AS t(inserted_offset, expected_offset);
});
is($have_expected_ondisk_offset_parity, "t\nt\nt\nt");

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

my $have_empty_insert_heaptids_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_empty_insert_heaptids(heaptids_length) =
		   rust_hnsw_should_have_empty_insert_heaptids(heaptids_length)
	FROM (VALUES
		(0),
		(1),
		(2),
		(-1)
	) AS t(heaptids_length);
});
is($have_empty_insert_heaptids_parity, "t\nt\nt\nt");

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

my $have_unregister_mvcc_snapshot_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_unregister_mvcc_snapshot(snapshot_is_mvcc) =
		   rust_hnsw_should_have_unregister_mvcc_snapshot(snapshot_is_mvcc)
	FROM (VALUES
		(0),
		(1),
		(1),
		(0)
	) AS t(snapshot_is_mvcc);
});
is($have_unregister_mvcc_snapshot_parity, "t\nt\nt\nt");

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

my $have_finish_parallel_heap_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_have_finish_parallel_heap_scan(participants_done, participant_count) =
		   rust_hnsw_should_have_finish_parallel_heap_scan(participants_done, participant_count)
	FROM (VALUES
		(0, 1),
		(1, 1),
		(2, 3),
		(3, 3)
	) AS t(participants_done, participant_count);
});
is($have_finish_parallel_heap_scan_parity, "t\nt\nt\nt");

done_testing();
