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
	CREATE FUNCTION c_ivfflat_center_counts(integer[], integer) RETURNS integer[]
	AS '$libdir/vector', 'vector_ivfflat_center_counts'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_center_counts(integer[], integer) RETURNS integer[]
	AS '$libdir/vector', 'vector_rust_ivfflat_center_counts'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_finalize_center(double precision[], integer) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_finalize_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_finalize_center(double precision[], integer) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_finalize_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_zero_agg(integer, integer) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_zero_agg'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_zero_agg(integer, integer) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_zero_agg'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_all_finite(real[]) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_all_finite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_all_finite(real[]) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_all_finite'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_vector_sum_center(real[], real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_vector_sum_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_vector_sum_center(real[], real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_vector_sum_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_bit_sum_center(bit) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_bit_sum_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_bit_sum_center(bit) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_bit_sum_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_vector_update_center(real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_vector_update_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_vector_update_center(real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_vector_update_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_bit_update_center(real[]) RETURNS bit
	AS '$libdir/vector', 'vector_ivfflat_bit_update_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_bit_update_center(real[]) RETURNS bit
	AS '$libdir/vector', 'vector_rust_ivfflat_bit_update_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_halfvec_update_center(real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_halfvec_update_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_halfvec_update_center(real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_halfvec_update_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_halfvec_sum_center(real[], real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_halfvec_sum_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_halfvec_sum_center(real[], real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_halfvec_sum_center'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_adjust_lower_bounds(real[], integer, real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_adjust_lower_bounds'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_adjust_lower_bounds(real[], integer, real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_adjust_lower_bounds'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_adjust_upper_bounds(real[], integer[], real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_adjust_upper_bounds'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_adjust_upper_bounds(real[], integer[], real[]) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_adjust_upper_bounds'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_init_upper_bounds(real[], integer) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_init_upper_bounds'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_init_upper_bounds(real[], integer) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_init_upper_bounds'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_init_closest_centers(real[], integer) RETURNS integer[]
	AS '$libdir/vector', 'vector_ivfflat_init_closest_centers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_init_closest_centers(real[], integer) RETURNS integer[]
	AS '$libdir/vector', 'vector_rust_ivfflat_init_closest_centers'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_compute_s(real[], integer) RETURNS real[]
	AS '$libdir/vector', 'vector_ivfflat_compute_s'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_compute_s(real[], integer) RETURNS real[]
	AS '$libdir/vector', 'vector_rust_ivfflat_compute_s'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});

my $parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_center_counts(assignments, centers) = rust_ivfflat_center_counts(assignments, centers)
	FROM (VALUES
		(ARRAY[0, 1, 1, 2, 3, 3, 3]::integer[], 4),
		(ARRAY[2, 2, 2, 2, 0, 1]::integer[], 3),
		(ARRAY[0, 0, 0, 0]::integer[], 1)
	) AS t(assignments, centers);
});
is($parity, "t\nt\nt");

my $finalize_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_finalize_center(values, n) = rust_ivfflat_finalize_center(values, n)
	FROM (VALUES
		(ARRAY[2.0, 4.0, 6.0]::double precision[], 2),
		(ARRAY['Infinity'::float8, '-Infinity'::float8, 4.0]::double precision[], 2),
		(ARRAY[0.0, 0.0, 0.0]::double precision[], 3)
	) AS t(values, n);
});
is($finalize_parity, "t\nt\nt");

my $zero_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_zero_agg(centers, dims) = rust_ivfflat_zero_agg(centers, dims)
	FROM (VALUES
		(1, 3),
		(2, 2),
		(3, 4)
	) AS t(centers, dims);
});
is($zero_parity, "t\nt\nt");

my $finite_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_all_finite(v) = rust_ivfflat_all_finite(v)
	FROM (VALUES
		(ARRAY[1.0, 2.0, 3.0]::real[]),
		(ARRAY['Infinity'::real, 1.0]::real[]),
		(ARRAY['NaN'::real, 0.0]::real[])
	) AS t(v);
});
is($finite_parity, "t\nt\nt");

my $vector_sum_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_vector_sum_center(a, b) = rust_ivfflat_vector_sum_center(a, b)
	FROM (VALUES
		(ARRAY[1.0, 2.0, 3.0]::real[], ARRAY[0.5, 1.5, 2.5]::real[]),
		(ARRAY[0.0, 0.0, 0.0]::real[], ARRAY[1.0, 1.0, 1.0]::real[]),
		(ARRAY[-1.0, 1.0, -1.0]::real[], ARRAY[2.0, -2.0, 2.0]::real[])
	) AS t(a, b);
});
is($vector_sum_parity, "t\nt\nt");

my $bit_sum_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_bit_sum_center(bv) = rust_ivfflat_bit_sum_center(bv)
	FROM (VALUES
		(B'1010'::bit(4)),
		(B'11110000'::bit(8)),
		(B'00000000'::bit(8))
	) AS t(bv);
});
is($bit_sum_parity, "t\nt\nt");

my $vector_update_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_vector_update_center(v) = rust_ivfflat_vector_update_center(v)
	FROM (VALUES
		(ARRAY[1.0, 2.0, 3.0]::real[]),
		(ARRAY[0.0, 0.0, 0.0]::real[]),
		(ARRAY[-1.5, 2.5, -3.5]::real[])
	) AS t(v);
});
is($vector_update_parity, "t\nt\nt");

my $bit_update_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_bit_update_center(v) = rust_ivfflat_bit_update_center(v)
	FROM (VALUES
		(ARRAY[0.0, 0.6, 0.4, 0.8]::real[]),
		(ARRAY[0.51, 0.49, 0.9, 0.1, 0.5, 0.7, 0.2, 0.99]::real[]),
		(ARRAY[0.0, 0.0, 0.0, 0.0]::real[])
	) AS t(v);
});
is($bit_update_parity, "t\nt\nt");

my $halfvec_update_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_halfvec_update_center(v) = rust_ivfflat_halfvec_update_center(v)
	FROM (VALUES
		(ARRAY[1.0, 2.0, 3.0]::real[]),
		(ARRAY[0.0, 0.0, 0.0]::real[]),
		(ARRAY[-1.25, 2.5, -3.75]::real[])
	) AS t(v);
});
is($halfvec_update_parity, "t\nt\nt");

my $halfvec_sum_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_halfvec_sum_center(a, b) = rust_ivfflat_halfvec_sum_center(a, b)
	FROM (VALUES
		(ARRAY[1.0, 2.0, 3.0]::real[], ARRAY[0.5, 1.5, 2.5]::real[]),
		(ARRAY[0.0, 0.0, 0.0]::real[], ARRAY[1.0, 1.0, 1.0]::real[]),
		(ARRAY[-1.0, 1.0, -1.0]::real[], ARRAY[2.0, -2.0, 2.0]::real[])
	) AS t(a, b);
});
is($halfvec_sum_parity, "t\nt\nt");

my $lower_bounds_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_adjust_lower_bounds(lower_vals, center_count, deltas) =
		   rust_ivfflat_adjust_lower_bounds(lower_vals, center_count, deltas)
	FROM (VALUES
		(ARRAY[2.0, 4.0, 6.0, 8.0, 10.0, 12.0]::real[], 3, ARRAY[1.0, 3.5, 20.0]::real[]),
		(ARRAY[0.0, 0.1, 0.2, 0.3]::real[], 2, ARRAY[0.5, 0.25]::real[]),
		(ARRAY[5.0, 1.0, 7.0, 2.0, 9.0, 3.0]::real[], 3, ARRAY[1.5, 0.5, 2.5]::real[])
	) AS t(lower_vals, center_count, deltas);
});
is($lower_bounds_parity, "t\nt\nt");

my $upper_bounds_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_adjust_upper_bounds(upper_vals, closest, deltas) =
		   rust_ivfflat_adjust_upper_bounds(upper_vals, closest, deltas)
	FROM (VALUES
		(ARRAY[1.0, 2.0, 3.0, 4.0]::real[], ARRAY[0, 1, 2, 1]::integer[], ARRAY[0.5, 1.5, 2.5]::real[]),
		(ARRAY[0.0, 10.0, 20.0]::real[], ARRAY[2, 0, 1]::integer[], ARRAY[3.0, 4.0, 5.0]::real[]),
		(ARRAY[7.5, 8.5]::real[], ARRAY[1, 1]::integer[], ARRAY[0.25, 0.75]::real[])
	) AS t(upper_vals, closest, deltas);
});
is($upper_bounds_parity, "t\nt\nt");

my $init_upper_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_init_upper_bounds(lower_vals, center_count) =
		   rust_ivfflat_init_upper_bounds(lower_vals, center_count)
	FROM (VALUES
		(ARRAY[2.0, 4.0, 1.0, 5.0, 3.0, 6.0]::real[], 3),
		(ARRAY[9.0, 8.0, 7.0, 6.0]::real[], 2),
		(ARRAY[0.5, 0.25, 0.125, 1.0, 2.0, 3.0]::real[], 3)
	) AS t(lower_vals, center_count);
});
is($init_upper_parity, "t\nt\nt");

my $init_closest_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_init_closest_centers(lower_vals, center_count) =
		   rust_ivfflat_init_closest_centers(lower_vals, center_count)
	FROM (VALUES
		(ARRAY[2.0, 4.0, 1.0, 5.0, 3.0, 6.0]::real[], 3),
		(ARRAY[9.0, 8.0, 7.0, 6.0]::real[], 2),
		(ARRAY[0.5, 0.25, 0.125, 1.0, 2.0, 3.0]::real[], 3)
	) AS t(lower_vals, center_count);
});
is($init_closest_parity, "t\nt\nt");

my $compute_s_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_compute_s(halfcdist, center_count) =
		   rust_ivfflat_compute_s(halfcdist, center_count)
	FROM (VALUES
		(ARRAY[0.0, 1.5, 2.5, 1.5, 0.0, 0.75, 2.5, 0.75, 0.0]::real[], 3),
		(ARRAY[0.0, 4.0, 4.0, 0.0]::real[], 2),
		(ARRAY[0.0, 9.0, 5.0, 9.0, 0.0, 2.0, 5.0, 2.0, 0.0]::real[], 3)
	) AS t(halfcdist, center_count);
});
is($compute_s_parity, "t\nt\nt");

done_testing();
