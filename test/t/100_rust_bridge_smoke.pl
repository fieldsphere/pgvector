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
	CREATE FUNCTION vector_rust_bridge_version() RETURNS cstring
	AS '$libdir/vector', 'vector_rust_bridge_version'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});

my $version = $node->safe_psql("postgres", "SELECT vector_rust_bridge_version();");
is($version, "rust-bridge-v1");

done_testing();
