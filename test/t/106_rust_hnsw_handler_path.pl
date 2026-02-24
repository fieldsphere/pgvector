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

done_testing();
