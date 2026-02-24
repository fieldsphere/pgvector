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

done_testing();
