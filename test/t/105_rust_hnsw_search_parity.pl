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

done_testing();
