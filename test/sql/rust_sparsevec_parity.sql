CREATE FUNCTION rust_sparsevec_l2_norm(sparsevec) RETURNS float8
	AS '$libdir/vector', 'vector_rust_sparsevec_l2_norm'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION rust_sparsevec_l2_normalize(sparsevec) RETURNS sparsevec
	AS '$libdir/vector', 'vector_rust_sparsevec_l2_normalize'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

SELECT
	l2_norm(sv) = rust_sparsevec_l2_norm(sv)
FROM (VALUES
	('{1:1.5,3:3.5}/3'::sparsevec(3)),
	('{2:-2}/4'::sparsevec(4)),
	('{}/5'::sparsevec(5))
) AS t(sv);

SELECT
	l2_normalize(sv) = rust_sparsevec_l2_normalize(sv)
FROM (VALUES
	('{1:1.5,3:3.5}/3'::sparsevec(3)),
	('{2:-2}/4'::sparsevec(4)),
	('{}/5'::sparsevec(5))
) AS t(sv);
