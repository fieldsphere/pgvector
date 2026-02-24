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
	CREATE FUNCTION c_hnsw_can_add_duplicate_heap_tid(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_can_add_duplicate_heap_tid'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_can_add_duplicate_heap_tid(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_can_add_duplicate_heap_tid'
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
	CREATE FUNCTION c_hnsw_should_repair_underfilled_layer0(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_repair_underfilled_layer0'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_repair_underfilled_layer0(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_repair_underfilled_layer0'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_flush_graph(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_flush_graph'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_flush_graph(bigint, bigint) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_flush_graph'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_hnsw_should_use_ondisk_phase(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_use_ondisk_phase'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_use_ondisk_phase(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_use_ondisk_phase'
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
	CREATE FUNCTION c_hnsw_should_stop_search_layer(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_hnsw_should_stop_search_layer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_hnsw_should_stop_search_layer(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_hnsw_should_stop_search_layer'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});

my $reject_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_reject_closer_neighbor(distance, candidate_distance) =
		   rust_hnsw_should_reject_closer_neighbor(distance, candidate_distance)
	FROM (VALUES
		(0.2::double precision, 0.3::double precision),
		(0.3::double precision, 0.3::double precision),
		(0.4::double precision, 0.3::double precision),
		(1.0::double precision, 0.5::double precision)
	) AS t(distance, candidate_distance);
});
is($reject_parity, "t\nt\nt\nt");

my $duplicate_capacity_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_can_add_duplicate_heap_tid(heaptids_length, max_heaptids) =
		   rust_hnsw_can_add_duplicate_heap_tid(heaptids_length, max_heaptids)
	FROM (VALUES
		(0, 10),
		(9, 10),
		(10, 10),
		(11, 10)
	) AS t(heaptids_length, max_heaptids);
});
is($duplicate_capacity_parity, "t\nt\nt\nt");

my $select_neighbors_early_return_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_select_neighbors_early_return(candidate_count, max_neighbors) =
		   rust_hnsw_should_select_neighbors_early_return(candidate_count, max_neighbors)
	FROM (VALUES
		(0, 10),
		(9, 10),
		(10, 10),
		(11, 10)
	) AS t(candidate_count, max_neighbors);
});
is($select_neighbors_early_return_parity, "t\nt\nt\nt");

my $repair_underfilled_layer0_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_repair_underfilled_layer0(last_item_valid) =
		   rust_hnsw_should_repair_underfilled_layer0(last_item_valid)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(last_item_valid);
});
is($repair_underfilled_layer0_parity, "t\nt\nt\nt");

my $flush_graph_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_flush_graph(memory_used, memory_total) =
		   rust_hnsw_should_flush_graph(memory_used, memory_total)
	FROM (VALUES
		(0::bigint, 10::bigint),
		(9::bigint, 10::bigint),
		(10::bigint, 10::bigint),
		(11::bigint, 10::bigint)
	) AS t(memory_used, memory_total);
});
is($flush_graph_parity, "t\nt\nt\nt");

my $ondisk_phase_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_use_ondisk_phase(flushed) =
		   rust_hnsw_should_use_ondisk_phase(flushed)
	FROM (VALUES
		(0),
		(1),
		(0),
		(1)
	) AS t(flushed);
});
is($ondisk_phase_parity, "t\nt\nt\nt");

my $add_search_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_add_search_candidate(candidate_distance, frontier_distance, always_add) =
		   rust_hnsw_should_add_search_candidate(candidate_distance, frontier_distance, always_add)
	FROM (VALUES
		(0.1::double precision, 0.2::double precision, 0),
		(0.3::double precision, 0.2::double precision, 0),
		(0.3::double precision, 0.2::double precision, 1),
		(0.2::double precision, 0.2::double precision, 0)
	) AS t(candidate_distance, frontier_distance, always_add);
});
is($add_search_candidate_parity, "t\nt\nt\nt");

my $stop_search_layer_parity = $node->safe_psql("postgres", q{
	SELECT c_hnsw_should_stop_search_layer(candidate_distance, frontier_distance) =
		   rust_hnsw_should_stop_search_layer(candidate_distance, frontier_distance)
	FROM (VALUES
		(0.1::double precision, 0.2::double precision),
		(0.2::double precision, 0.2::double precision),
		(0.3::double precision, 0.2::double precision),
		(1.0::double precision, 0.5::double precision)
	) AS t(candidate_distance, frontier_distance);
});
is($stop_search_layer_parity, "t\nt\nt\nt");

done_testing();
