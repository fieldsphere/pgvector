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
	CREATE FUNCTION rust_halfvec_l2_distance(halfvec, halfvec) RETURNS float8
	AS '$libdir/vector', 'vector_rust_halfvec_l2_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_halfvec_inner_product(halfvec, halfvec) RETURNS float8
	AS '$libdir/vector', 'vector_rust_halfvec_inner_product'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_halfvec_cosine_distance(halfvec, halfvec) RETURNS float8
	AS '$libdir/vector', 'vector_rust_halfvec_cosine_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_halfvec_l1_distance(halfvec, halfvec) RETURNS float8
	AS '$libdir/vector', 'vector_rust_halfvec_l1_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});

my $query = q{
	SELECT
		l2_distance(v1, v2) = rust_halfvec_l2_distance(v1, v2),
		inner_product(v1, v2) = rust_halfvec_inner_product(v1, v2),
		cosine_distance(v1, v2) = rust_halfvec_cosine_distance(v1, v2),
		l1_distance(v1, v2) = rust_halfvec_l1_distance(v1, v2)
	FROM (VALUES
		('[1,2,3]'::halfvec(3), '[3,2,1]'::halfvec(3)),
		('[0.5,0.25,0.75]'::halfvec(3), '[0.1,0.2,0.3]'::halfvec(3)),
		('[1,1,1]'::halfvec(3), '[2,2,2]'::halfvec(3))
	) t(v1, v2);
};
my $res = $node->safe_psql("postgres", $query);
is($res, "t|t|t|t\nt|t|t|t\nt|t|t|t");

done_testing();
