CREATE FUNCTION rust_l2_distance(vector, vector) RETURNS float8
	AS '$libdir/vector', 'vector_rust_l2_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_inner_product(vector, vector) RETURNS float8
	AS '$libdir/vector', 'vector_rust_inner_product'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_cosine_distance(vector, vector) RETURNS float8
	AS '$libdir/vector', 'vector_rust_cosine_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_l1_distance(vector, vector) RETURNS float8
	AS '$libdir/vector', 'vector_rust_l1_distance'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_vector_norm(vector) RETURNS float8
	AS '$libdir/vector', 'vector_rust_norm'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_l2_normalize(vector) RETURNS vector
	AS '$libdir/vector', 'vector_rust_l2_normalize'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_binary_quantize(vector) RETURNS bit
	AS '$libdir/vector', 'vector_rust_binary_quantize'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_subvector(vector, int, int) RETURNS vector
	AS '$libdir/vector', 'vector_rust_subvector'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_vector_cmp(vector, vector) RETURNS int4
	AS '$libdir/vector', 'vector_rust_cmp'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_halfvec_to_vector(halfvec) RETURNS vector
	AS '$libdir/vector', 'vector_rust_halfvec_to_vector_cast'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_sparsevec_to_vector(sparsevec) RETURNS vector
	AS '$libdir/vector', 'vector_rust_sparsevec_to_vector'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_vector_accum(double precision[], vector) RETURNS double precision[]
	AS '$libdir/vector', 'vector_rust_accum'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_vector_avg(double precision[]) RETURNS vector
	AS '$libdir/vector', 'vector_rust_avg'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_vector_combine(double precision[], double precision[]) RETURNS double precision[]
	AS '$libdir/vector', 'vector_rust_combine'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE AGGREGATE rust_avg(vector) (
	SFUNC = rust_vector_accum,
	STYPE = double precision[],
	FINALFUNC = rust_vector_avg,
	COMBINEFUNC = rust_vector_combine,
	INITCOND = '{0}',
	PARALLEL = SAFE
);

SELECT
	l2_distance(v1, v2) = rust_l2_distance(v1, v2),
	inner_product(v1, v2) = rust_inner_product(v1, v2),
	cosine_distance(v1, v2) = rust_cosine_distance(v1, v2),
	l1_distance(v1, v2) = rust_l1_distance(v1, v2)
FROM (VALUES
	('[1,2,3]'::vector(3), '[3,2,1]'::vector(3)),
	('[0.5,0.25,0.75]'::vector(3), '[0.1,0.2,0.3]'::vector(3)),
	('[1,1,1]'::vector(3), '[2,2,2]'::vector(3))
) AS t(v1, v2);

SELECT
	vector_norm(v) = rust_vector_norm(v),
	l2_normalize(v) = rust_l2_normalize(v),
	binary_quantize(v) = rust_binary_quantize(v)
FROM (VALUES
	('[1,2,3]'::vector(3)),
	('[0,0,0]'::vector(3)),
	('[-1,2,-3,4]'::vector(4))
) AS t(v);

SELECT
	subvector(v, start_idx, count) = rust_subvector(v, start_idx, count)
FROM (VALUES
	('[1,2,3,4,5]'::vector(5), 1, 3),
	('[1,2,3,4,5]'::vector(5), 2, 2),
	('[1,2,3,4,5]'::vector(5), 0, 3)
) AS t(v, start_idx, count);

SELECT
	vector_cmp(v1, v2) = rust_vector_cmp(v1, v2)
FROM (VALUES
	('[1,2,3]'::vector(3), '[1,2,3]'::vector(3)),
	('[1,2,3]'::vector(3), '[1,2,4]'::vector(3)),
	('[1,2,3]'::vector(3), '[1,2]'::vector(2))
) AS t(v1, v2);

SELECT
	hv::vector = rust_halfvec_to_vector(hv)
FROM (VALUES
	('[1,2,3]'::halfvec(3)),
	('[0,0,0]'::halfvec(3)),
	('[-1,2,-3,4]'::halfvec(4))
) AS t(hv);

SELECT
	sv::vector = rust_sparsevec_to_vector(sv)
FROM (VALUES
	('{1:1.5,3:3.5}/3'::sparsevec(3)),
	('{2:-2}/4'::sparsevec(4)),
	('{}/5'::sparsevec(5))
) AS t(sv);

SELECT
	avg(v) = rust_avg(v)
FROM (VALUES
	('[1,2,3]'::vector(3)),
	('[4,5,6]'::vector(3)),
	('[7,8,9]'::vector(3))
) AS t(v);
