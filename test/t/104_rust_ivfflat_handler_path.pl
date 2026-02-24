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
	CREATE FUNCTION c_ivfflat_handler_probe() RETURNS text
	AS '$libdir/vector', 'vector_ivfflat_handler_probe'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_handler_probe() RETURNS text
	AS '$libdir/vector', 'vector_rust_ivfflat_handler_probe'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});

my $parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_handler_probe() = rust_ivfflat_handler_probe(),
		   rust_ivfflat_handler_probe() LIKE 'rust-ivfflat-handler-%';
});
is($parity, "t|t");

done_testing();
