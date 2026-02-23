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
	CREATE FUNCTION rust_hamming_distance(bit, bit) RETURNS float8
	AS '$libdir/vector', 'vector_rust_hamming_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_jaccard_distance(bit, bit) RETURNS float8
	AS '$libdir/vector', 'vector_rust_jaccard_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});

my $hamming = $node->safe_psql("postgres", q{
	SELECT hamming_distance(v1, v2) = rust_hamming_distance(v1, v2)
	FROM (VALUES
		(B'111'::bit(3), B'110'::bit(3)),
		(B'10101010'::bit(8), B'01010101'::bit(8)),
		(B'10000001'::bit(8), B'00000001'::bit(8))
	) t(v1, v2);
});
is($hamming, "t\nt\nt");

my $jaccard = $node->safe_psql("postgres", q{
	SELECT jaccard_distance(v1, v2) = rust_jaccard_distance(v1, v2)
	FROM (VALUES
		(B'1111'::bit(4), B'1110'::bit(4)),
		(B'1100'::bit(4), B'1000'::bit(4)),
		(B'10101010'::bit(8), B'01010101'::bit(8))
	) t(v1, v2);
});
is($jaccard, "t\nt\nt");

done_testing();
