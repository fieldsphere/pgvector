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
