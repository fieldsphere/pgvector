CREATE FUNCTION rust_halfvec_add(halfvec, halfvec) RETURNS halfvec
	AS '$libdir/vector', 'vector_rust_halfvec_add'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_sub(halfvec, halfvec) RETURNS halfvec
	AS '$libdir/vector', 'vector_rust_halfvec_sub'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_mul(halfvec, halfvec) RETURNS halfvec
	AS '$libdir/vector', 'vector_rust_halfvec_mul'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_concat(halfvec, halfvec) RETURNS halfvec
	AS '$libdir/vector', 'vector_rust_halfvec_concat'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_l2_norm(halfvec) RETURNS float8
	AS '$libdir/vector', 'vector_rust_halfvec_l2_norm'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_l2_normalize(halfvec) RETURNS halfvec
	AS '$libdir/vector', 'vector_rust_halfvec_l2_normalize'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_cmp(halfvec, halfvec) RETURNS int4
	AS '$libdir/vector', 'vector_rust_halfvec_cmp'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_accum(double precision[], halfvec) RETURNS double precision[]
	AS '$libdir/vector', 'vector_rust_halfvec_accum'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_avg(double precision[]) RETURNS halfvec
	AS '$libdir/vector', 'vector_rust_halfvec_avg'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE AGGREGATE rust_avg(halfvec) (
	SFUNC = rust_halfvec_accum,
	STYPE = double precision[],
	FINALFUNC = rust_halfvec_avg,
	INITCOND = '{0}',
	PARALLEL = SAFE
);

SELECT
	halfvec_add(h1, h2) = rust_halfvec_add(h1, h2),
	halfvec_sub(h1, h2) = rust_halfvec_sub(h1, h2),
	halfvec_mul(h1, h2) = rust_halfvec_mul(h1, h2)
FROM (VALUES
	('[1,2,3]'::halfvec(3), '[3,2,1]'::halfvec(3)),
	('[0.5,0.25,0.75]'::halfvec(3), '[0.1,0.2,0.3]'::halfvec(3))
) AS t(h1, h2);

SELECT
	halfvec_concat(h1, h2) = rust_halfvec_concat(h1, h2)
FROM (VALUES
	('[1,2]'::halfvec(2), '[3,4]'::halfvec(2)),
	('[-1,2]'::halfvec(2), '[0,5]'::halfvec(2))
) AS t(h1, h2);

SELECT
	l2_norm(h) = rust_halfvec_l2_norm(h),
	l2_normalize(h) = rust_halfvec_l2_normalize(h)
FROM (VALUES
	('[1,2,3]'::halfvec(3)),
	('[0,0,0]'::halfvec(3)),
	('[-1,2,-3,4]'::halfvec(4))
) AS t(h);

SELECT
	halfvec_cmp(h1, h2) = rust_halfvec_cmp(h1, h2)
FROM (VALUES
	('[1,2,3]'::halfvec(3), '[1,2,3]'::halfvec(3)),
	('[1,2,3]'::halfvec(3), '[1,2,4]'::halfvec(3)),
	('[1,2,3]'::halfvec(3), '[1,2]'::halfvec(2))
) AS t(h1, h2);

SELECT
	avg(h) = rust_avg(h)
FROM (VALUES
	('[1,2,3]'::halfvec(3)),
	('[4,5,6]'::halfvec(3)),
	('[7,8,9]'::halfvec(3))
) AS t(h);
