#include "postgres.h"

#include <float.h>
#include <limits.h>
#include <math.h>

#include "access/genam.h"
#include "catalog/pg_type.h"
#include "fmgr.h"
#include "ivfflat.h"
#include "miscadmin.h"
#include "rust_ffi.h"
#include "utils/array.h"
#include "utils/memutils.h"
#include "utils/relcache.h"

#if PG_VERSION_NUM >= 160000
#include "varatt.h"
#endif

static ArrayType *
IvfflatCenterCounts(ArrayType *assignmentsArray, int32 centerCount, bool useRust)
{
	Datum	   *assignmentDatums;
	int			assignmentLength;
	int32	   *assignments;
	int32	   *counts;
	Datum	   *countDatums;
	ArrayType  *result;

	if (centerCount < 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("center count must be at least 1")));

	if (ARR_NDIM(assignmentsArray) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("assignments array must be 1-D")));

	if (ARR_HASNULL(assignmentsArray) && array_contains_nulls(assignmentsArray))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("assignments array must not contain nulls")));

	if (ARR_ELEMTYPE(assignmentsArray) != INT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("assignments array must be integer[]")));

	deconstruct_array(assignmentsArray, INT4OID, sizeof(int32), true, TYPALIGN_INT,
					  &assignmentDatums, NULL, &assignmentLength);

	assignments = palloc(sizeof(int32) * assignmentLength);
	for (int i = 0; i < assignmentLength; i++)
	{
		int32		center = DatumGetInt32(assignmentDatums[i]);

		if (center < 0 || center >= centerCount)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("assignment index out of bounds")));

		assignments[i] = center;
	}

	counts = palloc0(sizeof(int32) * centerCount);

	if (useRust)
		vector_rust_ivfflat_center_counts_kernel(assignmentLength, assignments, centerCount, counts);
	else
	{
		for (int i = 0; i < assignmentLength; i++)
			counts[assignments[i]] += 1;
	}

	countDatums = palloc(sizeof(Datum) * centerCount);
	for (int i = 0; i < centerCount; i++)
		countDatums[i] = Int32GetDatum(counts[i]);

	result = construct_array(countDatums, centerCount, INT4OID, sizeof(int32), true, TYPALIGN_INT);

	pfree(countDatums);
	pfree(counts);
	pfree(assignments);
	pfree(assignmentDatums);

	return result;
}

static ArrayType *
IvfflatFinalizeCenter(ArrayType *aggArray, int32 centerCount, bool useRust)
{
	Datum	   *aggDatums;
	int			dimensions;
	float	   *agg;
	Datum	   *resultDatums;
	ArrayType  *result;

	if (centerCount < 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("center count must be at least 1")));

	if (ARR_NDIM(aggArray) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("aggregate array must be 1-D")));

	if (ARR_HASNULL(aggArray) && array_contains_nulls(aggArray))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("aggregate array must not contain nulls")));

	if (ARR_ELEMTYPE(aggArray) != FLOAT8OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("aggregate array must be double precision[]")));

	deconstruct_array(aggArray, FLOAT8OID, sizeof(float8), FLOAT8PASSBYVAL, TYPALIGN_DOUBLE,
					  &aggDatums, NULL, &dimensions);

	agg = palloc(sizeof(float) * dimensions);
	for (int i = 0; i < dimensions; i++)
		agg[i] = (float) DatumGetFloat8(aggDatums[i]);

	if (useRust)
		vector_rust_ivfflat_finalize_center_kernel(dimensions, agg, centerCount);
	else
	{
		for (int i = 0; i < dimensions; i++)
		{
			if (isinf(agg[i]))
				agg[i] = agg[i] > 0 ? FLT_MAX : -FLT_MAX;
			agg[i] /= centerCount;
		}
	}

	resultDatums = palloc(sizeof(Datum) * dimensions);
	for (int i = 0; i < dimensions; i++)
		resultDatums[i] = Float4GetDatum(agg[i]);

	result = construct_array(resultDatums, dimensions, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(agg);
	pfree(aggDatums);

	return result;
}

static ArrayType *
IvfflatZeroAgg(int32 centerCount, int32 dimensions, bool useRust)
{
	int64		totalLength = (int64) centerCount * dimensions;
	float	   *values;
	Datum	   *resultDatums;
	ArrayType  *result;

	if (centerCount < 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("center count must be at least 1")));

	if (dimensions < 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("dimensions must be at least 1")));

	values = palloc(sizeof(float) * totalLength);

	if (useRust)
		vector_rust_ivfflat_zero_agg_kernel(centerCount, dimensions, values);
	else
	{
		for (int64 i = 0; i < totalLength; i++)
			values[i] = 0.0;
	}

	resultDatums = palloc(sizeof(Datum) * totalLength);
	for (int64 i = 0; i < totalLength; i++)
		resultDatums[i] = Float4GetDatum(values[i]);

	result = construct_array(resultDatums, totalLength, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(values);

	return result;
}

static bool
IvfflatAllFinite(ArrayType *valuesArray, bool useRust)
{
	Datum	   *valueDatums;
	int			length;
	float	   *values;
	bool		allFinite = true;

	if (ARR_NDIM(valuesArray) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("values array must be 1-D")));

	if (ARR_HASNULL(valuesArray) && array_contains_nulls(valuesArray))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("values array must not contain nulls")));

	if (ARR_ELEMTYPE(valuesArray) != FLOAT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("values array must be real[]")));

	deconstruct_array(valuesArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &valueDatums, NULL, &length);

	values = palloc(sizeof(float) * length);
	for (int i = 0; i < length; i++)
		values[i] = DatumGetFloat4(valueDatums[i]);

	if (useRust)
		allFinite = vector_rust_ivfflat_all_finite_kernel(length, values);
	else
	{
		for (int i = 0; i < length; i++)
		{
			if (isnan(values[i]) || isinf(values[i]))
			{
				allFinite = false;
				break;
			}
		}
	}

	pfree(values);
	pfree(valueDatums);

	return allFinite;
}

static ArrayType *
IvfflatAdjustLowerBounds(ArrayType *lowerBoundsArray, int32 centerCount, ArrayType *centerDistancesArray, bool useRust)
{
	Datum	   *lowerDatums;
	Datum	   *distanceDatums;
	int			lowerLength;
	int			distanceLength;
	int			sampleCount;
	float	   *lowerBounds;
	float	   *centerDistances;
	Datum	   *resultDatums;
	ArrayType  *result;

	if (centerCount < 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("center count must be at least 1")));

	if (ARR_NDIM(lowerBoundsArray) > 1 || ARR_NDIM(centerDistancesArray) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("input arrays must be 1-D")));

	if ((ARR_HASNULL(lowerBoundsArray) && array_contains_nulls(lowerBoundsArray)) ||
		(ARR_HASNULL(centerDistancesArray) && array_contains_nulls(centerDistancesArray)))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("input arrays must not contain nulls")));

	if (ARR_ELEMTYPE(lowerBoundsArray) != FLOAT4OID || ARR_ELEMTYPE(centerDistancesArray) != FLOAT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("input arrays must be real[]")));

	deconstruct_array(lowerBoundsArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &lowerDatums, NULL, &lowerLength);
	deconstruct_array(centerDistancesArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &distanceDatums, NULL, &distanceLength);

	if (distanceLength != centerCount)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("center distance length must match center count")));

	if (lowerLength % centerCount != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("lower bounds length must be divisible by center count")));

	sampleCount = lowerLength / centerCount;
	lowerBounds = palloc(sizeof(float) * lowerLength);
	centerDistances = palloc(sizeof(float) * distanceLength);

	for (int i = 0; i < lowerLength; i++)
		lowerBounds[i] = DatumGetFloat4(lowerDatums[i]);
	for (int i = 0; i < distanceLength; i++)
		centerDistances[i] = DatumGetFloat4(distanceDatums[i]);

	if (useRust)
		vector_rust_ivfflat_adjust_lower_bounds_kernel(sampleCount, centerCount, lowerBounds, centerDistances);
	else
	{
		for (int sample = 0; sample < sampleCount; sample++)
		{
			float	   *row = lowerBounds + ((int64) sample * centerCount);

			for (int center = 0; center < centerCount; center++)
			{
				float		updated = row[center] - centerDistances[center];

				row[center] = updated < 0 ? 0 : updated;
			}
		}
	}

	resultDatums = palloc(sizeof(Datum) * lowerLength);
	for (int i = 0; i < lowerLength; i++)
		resultDatums[i] = Float4GetDatum(lowerBounds[i]);

	result = construct_array(resultDatums, lowerLength, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(centerDistances);
	pfree(lowerBounds);
	pfree(distanceDatums);
	pfree(lowerDatums);

	return result;
}

static ArrayType *
IvfflatAdjustUpperBounds(ArrayType *upperBoundsArray, ArrayType *closestCentersArray, ArrayType *centerDistancesArray, bool useRust)
{
	Datum	   *upperDatums;
	Datum	   *closestDatums;
	Datum	   *distanceDatums;
	int			upperLength;
	int			closestLength;
	int			distanceLength;
	float	   *upperBounds;
	int32	   *closestCenters;
	float	   *centerDistances;
	Datum	   *resultDatums;
	ArrayType  *result;

	if (ARR_NDIM(upperBoundsArray) > 1 || ARR_NDIM(closestCentersArray) > 1 || ARR_NDIM(centerDistancesArray) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("input arrays must be 1-D")));

	if ((ARR_HASNULL(upperBoundsArray) && array_contains_nulls(upperBoundsArray)) ||
		(ARR_HASNULL(closestCentersArray) && array_contains_nulls(closestCentersArray)) ||
		(ARR_HASNULL(centerDistancesArray) && array_contains_nulls(centerDistancesArray)))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("input arrays must not contain nulls")));

	if (ARR_ELEMTYPE(upperBoundsArray) != FLOAT4OID || ARR_ELEMTYPE(centerDistancesArray) != FLOAT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("upper bounds and center distances must be real[]")));
	if (ARR_ELEMTYPE(closestCentersArray) != INT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("closest centers must be integer[]")));

	deconstruct_array(upperBoundsArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &upperDatums, NULL, &upperLength);
	deconstruct_array(closestCentersArray, INT4OID, sizeof(int32), true, TYPALIGN_INT,
					  &closestDatums, NULL, &closestLength);
	deconstruct_array(centerDistancesArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &distanceDatums, NULL, &distanceLength);

	if (upperLength != closestLength)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("upper bounds and closest centers must have the same length")));
	if (distanceLength < 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("center distances must contain at least one element")));

	upperBounds = palloc(sizeof(float) * upperLength);
	closestCenters = palloc(sizeof(int32) * closestLength);
	centerDistances = palloc(sizeof(float) * distanceLength);

	for (int i = 0; i < upperLength; i++)
		upperBounds[i] = DatumGetFloat4(upperDatums[i]);
	for (int i = 0; i < closestLength; i++)
	{
		int32		center = DatumGetInt32(closestDatums[i]);

		if (center < 0 || center >= distanceLength)
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("closest center index out of bounds")));

		closestCenters[i] = center;
	}
	for (int i = 0; i < distanceLength; i++)
		centerDistances[i] = DatumGetFloat4(distanceDatums[i]);

	if (useRust)
		vector_rust_ivfflat_adjust_upper_bounds_kernel(upperLength, upperBounds, closestCenters, centerDistances);
	else
	{
		for (int i = 0; i < upperLength; i++)
			upperBounds[i] += centerDistances[closestCenters[i]];
	}

	resultDatums = palloc(sizeof(Datum) * upperLength);
	for (int i = 0; i < upperLength; i++)
		resultDatums[i] = Float4GetDatum(upperBounds[i]);

	result = construct_array(resultDatums, upperLength, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(centerDistances);
	pfree(closestCenters);
	pfree(upperBounds);
	pfree(distanceDatums);
	pfree(closestDatums);
	pfree(upperDatums);

	return result;
}

static void
IvfflatInitBoundsArrays(ArrayType *lowerBoundsArray, int32 centerCount, bool useRust, float **upperBoundsOut, int32 **closestCentersOut, int *sampleCountOut)
{
	Datum	   *lowerDatums;
	int			lowerLength;
	int			sampleCount;
	float	   *lowerBounds;
	float	   *upperBounds;
	int32	   *closestCenters;

	if (centerCount < 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("center count must be at least 1")));

	if (ARR_NDIM(lowerBoundsArray) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("lower bounds array must be 1-D")));

	if (ARR_HASNULL(lowerBoundsArray) && array_contains_nulls(lowerBoundsArray))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("lower bounds array must not contain nulls")));

	if (ARR_ELEMTYPE(lowerBoundsArray) != FLOAT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("lower bounds array must be real[]")));

	deconstruct_array(lowerBoundsArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &lowerDatums, NULL, &lowerLength);

	if (lowerLength % centerCount != 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("lower bounds length must be divisible by center count")));

	sampleCount = lowerLength / centerCount;
	lowerBounds = palloc(sizeof(float) * lowerLength);
	upperBounds = palloc(sizeof(float) * sampleCount);
	closestCenters = palloc(sizeof(int32) * sampleCount);

	for (int i = 0; i < lowerLength; i++)
		lowerBounds[i] = DatumGetFloat4(lowerDatums[i]);

	if (useRust)
		vector_rust_ivfflat_init_bounds_kernel(sampleCount, centerCount, lowerBounds, upperBounds, closestCenters);
	else
	{
		for (int sample = 0; sample < sampleCount; sample++)
		{
			float	   *row = lowerBounds + ((int64) sample * centerCount);
			float		minDistance = FLT_MAX;
			int32		closestCenter = 0;

			for (int center = 0; center < centerCount; center++)
			{
				if (row[center] < minDistance)
				{
					minDistance = row[center];
					closestCenter = center;
				}
			}

			upperBounds[sample] = minDistance;
			closestCenters[sample] = closestCenter;
		}
	}

	pfree(lowerBounds);
	pfree(lowerDatums);

	*upperBoundsOut = upperBounds;
	*closestCentersOut = closestCenters;
	*sampleCountOut = sampleCount;
}

static ArrayType *
IvfflatInitUpperBounds(ArrayType *lowerBoundsArray, int32 centerCount, bool useRust)
{
	float	   *upperBounds;
	int32	   *closestCenters;
	int			sampleCount;
	Datum	   *resultDatums;
	ArrayType  *result;

	IvfflatInitBoundsArrays(lowerBoundsArray, centerCount, useRust, &upperBounds, &closestCenters, &sampleCount);

	resultDatums = palloc(sizeof(Datum) * sampleCount);
	for (int i = 0; i < sampleCount; i++)
		resultDatums[i] = Float4GetDatum(upperBounds[i]);

	result = construct_array(resultDatums, sampleCount, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(closestCenters);
	pfree(upperBounds);

	return result;
}

static ArrayType *
IvfflatInitClosestCenters(ArrayType *lowerBoundsArray, int32 centerCount, bool useRust)
{
	float	   *upperBounds;
	int32	   *closestCenters;
	int			sampleCount;
	Datum	   *resultDatums;
	ArrayType  *result;

	IvfflatInitBoundsArrays(lowerBoundsArray, centerCount, useRust, &upperBounds, &closestCenters, &sampleCount);

	resultDatums = palloc(sizeof(Datum) * sampleCount);
	for (int i = 0; i < sampleCount; i++)
		resultDatums[i] = Int32GetDatum(closestCenters[i]);

	result = construct_array(resultDatums, sampleCount, INT4OID, sizeof(int32), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(closestCenters);
	pfree(upperBounds);

	return result;
}

static ArrayType *
IvfflatComputeS(ArrayType *halfcdistArray, int32 centerCount, bool useRust)
{
	Datum	   *halfcdistDatums;
	int			halfcdistLength;
	int64		expectedLength = (int64) centerCount * centerCount;
	float	   *halfcdist;
	float	   *s;
	Datum	   *resultDatums;
	ArrayType  *result;

	if (centerCount < 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("center count must be at least 1")));

	if (ARR_NDIM(halfcdistArray) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("halfcdist array must be 1-D")));

	if (ARR_HASNULL(halfcdistArray) && array_contains_nulls(halfcdistArray))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("halfcdist array must not contain nulls")));

	if (ARR_ELEMTYPE(halfcdistArray) != FLOAT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("halfcdist array must be real[]")));

	deconstruct_array(halfcdistArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &halfcdistDatums, NULL, &halfcdistLength);

	if (halfcdistLength != expectedLength)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("halfcdist length must equal center_count * center_count")));

	halfcdist = palloc(sizeof(float) * halfcdistLength);
	s = palloc(sizeof(float) * centerCount);

	for (int i = 0; i < halfcdistLength; i++)
		halfcdist[i] = DatumGetFloat4(halfcdistDatums[i]);

	if (useRust)
		vector_rust_ivfflat_compute_s_kernel(centerCount, halfcdist, s);
	else
	{
		for (int center = 0; center < centerCount; center++)
		{
			float		minDistance = FLT_MAX;
			float	   *row = halfcdist + ((int64) center * centerCount);

			for (int other = 0; other < centerCount; other++)
			{
				if (center == other)
					continue;
				if (row[other] < minDistance)
					minDistance = row[other];
			}

			s[center] = minDistance;
		}
	}

	resultDatums = palloc(sizeof(Datum) * centerCount);
	for (int i = 0; i < centerCount; i++)
		resultDatums[i] = Float4GetDatum(s[i]);

	result = construct_array(resultDatums, centerCount, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(s);
	pfree(halfcdist);
	pfree(halfcdistDatums);

	return result;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_center_counts);
Datum
vector_ivfflat_center_counts(PG_FUNCTION_ARGS)
{
	ArrayType  *assignmentsArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatCenterCounts(assignmentsArray, centerCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_center_counts);
Datum
vector_rust_ivfflat_center_counts(PG_FUNCTION_ARGS)
{
	ArrayType  *assignmentsArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatCenterCounts(assignmentsArray, centerCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_finalize_center);
Datum
vector_ivfflat_finalize_center(PG_FUNCTION_ARGS)
{
	ArrayType  *aggArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatFinalizeCenter(aggArray, centerCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_finalize_center);
Datum
vector_rust_ivfflat_finalize_center(PG_FUNCTION_ARGS)
{
	ArrayType  *aggArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatFinalizeCenter(aggArray, centerCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_zero_agg);
Datum
vector_ivfflat_zero_agg(PG_FUNCTION_ARGS)
{
	int32		centerCount = PG_GETARG_INT32(0);
	int32		dimensions = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatZeroAgg(centerCount, dimensions, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_zero_agg);
Datum
vector_rust_ivfflat_zero_agg(PG_FUNCTION_ARGS)
{
	int32		centerCount = PG_GETARG_INT32(0);
	int32		dimensions = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatZeroAgg(centerCount, dimensions, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_all_finite);
Datum
vector_ivfflat_all_finite(PG_FUNCTION_ARGS)
{
	ArrayType  *valuesArray = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_BOOL(IvfflatAllFinite(valuesArray, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_all_finite);
Datum
vector_rust_ivfflat_all_finite(PG_FUNCTION_ARGS)
{
	ArrayType  *valuesArray = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_BOOL(IvfflatAllFinite(valuesArray, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_adjust_lower_bounds);
Datum
vector_ivfflat_adjust_lower_bounds(PG_FUNCTION_ARGS)
{
	ArrayType  *lowerBoundsArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);
	ArrayType  *centerDistancesArray = PG_GETARG_ARRAYTYPE_P(2);

	PG_RETURN_ARRAYTYPE_P(IvfflatAdjustLowerBounds(lowerBoundsArray, centerCount, centerDistancesArray, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_adjust_lower_bounds);
Datum
vector_rust_ivfflat_adjust_lower_bounds(PG_FUNCTION_ARGS)
{
	ArrayType  *lowerBoundsArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);
	ArrayType  *centerDistancesArray = PG_GETARG_ARRAYTYPE_P(2);

	PG_RETURN_ARRAYTYPE_P(IvfflatAdjustLowerBounds(lowerBoundsArray, centerCount, centerDistancesArray, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_adjust_upper_bounds);
Datum
vector_ivfflat_adjust_upper_bounds(PG_FUNCTION_ARGS)
{
	ArrayType  *upperBoundsArray = PG_GETARG_ARRAYTYPE_P(0);
	ArrayType  *closestCentersArray = PG_GETARG_ARRAYTYPE_P(1);
	ArrayType  *centerDistancesArray = PG_GETARG_ARRAYTYPE_P(2);

	PG_RETURN_ARRAYTYPE_P(IvfflatAdjustUpperBounds(upperBoundsArray, closestCentersArray, centerDistancesArray, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_adjust_upper_bounds);
Datum
vector_rust_ivfflat_adjust_upper_bounds(PG_FUNCTION_ARGS)
{
	ArrayType  *upperBoundsArray = PG_GETARG_ARRAYTYPE_P(0);
	ArrayType  *closestCentersArray = PG_GETARG_ARRAYTYPE_P(1);
	ArrayType  *centerDistancesArray = PG_GETARG_ARRAYTYPE_P(2);

	PG_RETURN_ARRAYTYPE_P(IvfflatAdjustUpperBounds(upperBoundsArray, closestCentersArray, centerDistancesArray, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_init_upper_bounds);
Datum
vector_ivfflat_init_upper_bounds(PG_FUNCTION_ARGS)
{
	ArrayType  *lowerBoundsArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatInitUpperBounds(lowerBoundsArray, centerCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_init_upper_bounds);
Datum
vector_rust_ivfflat_init_upper_bounds(PG_FUNCTION_ARGS)
{
	ArrayType  *lowerBoundsArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatInitUpperBounds(lowerBoundsArray, centerCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_init_closest_centers);
Datum
vector_ivfflat_init_closest_centers(PG_FUNCTION_ARGS)
{
	ArrayType  *lowerBoundsArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatInitClosestCenters(lowerBoundsArray, centerCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_init_closest_centers);
Datum
vector_rust_ivfflat_init_closest_centers(PG_FUNCTION_ARGS)
{
	ArrayType  *lowerBoundsArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatInitClosestCenters(lowerBoundsArray, centerCount, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_compute_s);
Datum
vector_ivfflat_compute_s(PG_FUNCTION_ARGS)
{
	ArrayType  *halfcdistArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatComputeS(halfcdistArray, centerCount, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_compute_s);
Datum
vector_rust_ivfflat_compute_s(PG_FUNCTION_ARGS)
{
	ArrayType  *halfcdistArray = PG_GETARG_ARRAYTYPE_P(0);
	int32		centerCount = PG_GETARG_INT32(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatComputeS(halfcdistArray, centerCount, true));
}

/*
 * Initialize with kmeans++
 *
 * https://theory.stanford.edu/~sergei/papers/kMeansPP-soda.pdf
 */
static void
InitCenters(Relation index, VectorArray samples, VectorArray centers, float *lowerBound)
{
	FmgrInfo   *procinfo;
	Oid			collation;
	int64		j;
	float	   *weight = palloc(samples->length * sizeof(float));
	int			numCenters = centers->maxlen;
	int			numSamples = samples->length;

	procinfo = index_getprocinfo(index, 1, IVFFLAT_KMEANS_DISTANCE_PROC);
	collation = index->rd_indcollation[0];

	/* Choose an initial center uniformly at random */
	VectorArraySet(centers, 0, VectorArrayGet(samples, RandomInt() % samples->length));
	centers->length++;

	for (j = 0; j < numSamples; j++)
		weight[j] = FLT_MAX;

	for (int i = 0; i < numCenters; i++)
	{
		double		sum;
		double		choice;

		CHECK_FOR_INTERRUPTS();

		sum = 0.0;

		for (j = 0; j < numSamples; j++)
		{
			Datum		vec = PointerGetDatum(VectorArrayGet(samples, j));
			double		distance;

			/* Only need to compute distance for new center */
			/* TODO Use triangle inequality to reduce distance calculations */
			distance = DatumGetFloat8(FunctionCall2Coll(procinfo, collation, vec, PointerGetDatum(VectorArrayGet(centers, i))));

			/* Set lower bound */
			lowerBound[j * numCenters + i] = distance;

			/* Use distance squared for weighted probability distribution */
			distance *= distance;

			if (distance < weight[j])
				weight[j] = distance;

			sum += weight[j];
		}

		/* Only compute lower bound on last iteration */
		if (i + 1 == numCenters)
			break;

		/* Choose new center using weighted probability distribution. */
		choice = sum * RandomDouble();
		for (j = 0; j < numSamples - 1; j++)
		{
			choice -= weight[j];
			if (choice <= 0)
				break;
		}

		VectorArraySet(centers, i + 1, VectorArrayGet(samples, j));
		centers->length++;
	}

	pfree(weight);
}

/*
 * Norm centers
 */
static void
NormCenters(const IvfflatTypeInfo * typeInfo, Oid collation, VectorArray centers)
{
	MemoryContext normCtx = AllocSetContextCreate(CurrentMemoryContext,
												  "Ivfflat norm temporary context",
												  ALLOCSET_DEFAULT_SIZES);
	MemoryContext oldCtx = MemoryContextSwitchTo(normCtx);

	for (int j = 0; j < centers->length; j++)
	{
		Datum		center = PointerGetDatum(VectorArrayGet(centers, j));
		Datum		newCenter = IvfflatNormValue(typeInfo, collation, center);
		Size		size = VARSIZE_ANY(DatumGetPointer(newCenter));

		if (size > centers->itemsize)
			elog(ERROR, "safety check failed");

		memcpy(DatumGetPointer(center), DatumGetPointer(newCenter), size);
		MemoryContextReset(normCtx);
	}

	MemoryContextSwitchTo(oldCtx);
	MemoryContextDelete(normCtx);
}

/*
 * Quick approach if we have no data
 */
static void
RandomCenters(Relation index, VectorArray centers, const IvfflatTypeInfo * typeInfo)
{
	int			dimensions = centers->dim;
	FmgrInfo   *normprocinfo = IvfflatOptionalProcInfo(index, IVFFLAT_KMEANS_NORM_PROC);
	Oid			collation = index->rd_indcollation[0];
	float	   *x = (float *) palloc(sizeof(float) * dimensions);

	/* Fill with random data */
	while (centers->length < centers->maxlen)
	{
		Pointer		center = VectorArrayGet(centers, centers->length);

		for (int i = 0; i < dimensions; i++)
			x[i] = (float) RandomDouble();

		typeInfo->updateCenter(center, dimensions, x);

		centers->length++;
	}

	if (normprocinfo != NULL)
		NormCenters(typeInfo, collation, centers);
}

#ifdef IVFFLAT_MEMORY
/*
 * Show memory usage
 */
static void
ShowMemoryUsage(MemoryContext context, Size estimatedSize)
{
	elog(INFO, "total memory: %zu MB",
		 MemoryContextMemAllocated(context, true) / (1024 * 1024));
	elog(INFO, "estimated memory: %zu MB", estimatedSize / (1024 * 1024));
}
#endif

/*
 * Sum centers
 */
static void
SumCenters(VectorArray samples, float *agg, int *closestCenters, const IvfflatTypeInfo * typeInfo)
{
	for (int j = 0; j < samples->length; j++)
	{
		float	   *x = agg + ((int64) closestCenters[j] * samples->dim);

		typeInfo->sumCenter(VectorArrayGet(samples, j), x);
	}
}

/*
 * Update centers
 */
static void
UpdateCenters(float *agg, VectorArray centers, const IvfflatTypeInfo * typeInfo)
{
	for (int j = 0; j < centers->length; j++)
	{
		float	   *x = agg + ((int64) j * centers->dim);

		typeInfo->updateCenter(VectorArrayGet(centers, j), centers->dim, x);
	}
}

/*
 * Compute new centers
 */
static void
ComputeNewCenters(VectorArray samples, float *agg, VectorArray newCenters, int *centerCounts, int *closestCenters, FmgrInfo *normprocinfo, Oid collation, const IvfflatTypeInfo * typeInfo)
{
	int			dimensions = newCenters->dim;
	int			numCenters = newCenters->length;
	int			numSamples = samples->length;

	/* Reset sum and count */
	vector_rust_ivfflat_zero_agg_kernel(numCenters, dimensions, agg);

	/* Increment sum of closest center */
	SumCenters(samples, agg, closestCenters, typeInfo);

	/* Increment count of closest center */
	vector_rust_ivfflat_center_counts_kernel(numSamples, closestCenters, numCenters, centerCounts);

	/* Divide sum by count */
	for (int j = 0; j < numCenters; j++)
	{
		float	   *x = agg + ((int64) j * dimensions);

		if (centerCounts[j] > 0)
		{
			/* TODO Update bounds */
			vector_rust_ivfflat_finalize_center_kernel(dimensions, x, centerCounts[j]);
		}
		else
		{
			/* TODO Handle empty centers properly */
			for (int k = 0; k < dimensions; k++)
				x[k] = RandomDouble();
		}
	}

	/* Set new centers */
	UpdateCenters(agg, newCenters, typeInfo);

	/* Normalize if needed */
	if (normprocinfo != NULL)
		NormCenters(typeInfo, collation, newCenters);
}

/*
 * Use Elkan for performance. This requires distance function to satisfy triangle inequality.
 *
 * We use L2 distance for L2 (not L2 squared like index scan)
 * and angular distance for inner product and cosine distance
 *
 * https://www.aaai.org/Papers/ICML/2003/ICML03-022.pdf
 */
static void
ElkanKmeans(Relation index, VectorArray samples, VectorArray centers, const IvfflatTypeInfo * typeInfo)
{
	FmgrInfo   *procinfo;
	FmgrInfo   *normprocinfo;
	Oid			collation;
	int			dimensions = centers->dim;
	int			numCenters = centers->maxlen;
	int			numSamples = samples->length;
	VectorArray newCenters;
	float	   *agg;
	int		   *centerCounts;
	int		   *closestCenters;
	float	   *lowerBound;
	float	   *upperBound;
	float	   *s;
	float	   *halfcdist;
	float	   *newcdist;

	/* Calculate allocation sizes */
	Size		samplesSize = VECTOR_ARRAY_SIZE(samples->maxlen, samples->itemsize);
	Size		centersSize = VECTOR_ARRAY_SIZE(centers->maxlen, centers->itemsize);
	Size		newCentersSize = VECTOR_ARRAY_SIZE(numCenters, centers->itemsize);
	Size		aggSize = sizeof(float) * (int64) numCenters * dimensions;
	Size		centerCountsSize = sizeof(int) * numCenters;
	Size		closestCentersSize = sizeof(int) * numSamples;
	Size		lowerBoundSize = sizeof(float) * numSamples * numCenters;
	Size		upperBoundSize = sizeof(float) * numSamples;
	Size		sSize = sizeof(float) * numCenters;
	Size		halfcdistSize = sizeof(float) * numCenters * numCenters;
	Size		newcdistSize = sizeof(float) * numCenters;

	/* Calculate total size */
	Size		totalSize = samplesSize + centersSize + newCentersSize + aggSize + centerCountsSize + closestCentersSize + lowerBoundSize + upperBoundSize + sSize + halfcdistSize + newcdistSize;

	/* Check memory requirements */
	/* Add one to error message to ceil */
	if (totalSize > (Size) maintenance_work_mem * 1024L)
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("memory required is %zu MB, maintenance_work_mem is %d MB",
						totalSize / (1024 * 1024) + 1, maintenance_work_mem / 1024)));

	/* Ensure indexing does not overflow */
	if (numCenters * numCenters > INT_MAX)
		elog(ERROR, "Indexing overflow detected. Please report a bug.");

	/* Set support functions */
	procinfo = index_getprocinfo(index, 1, IVFFLAT_KMEANS_DISTANCE_PROC);
	normprocinfo = IvfflatOptionalProcInfo(index, IVFFLAT_KMEANS_NORM_PROC);
	collation = index->rd_indcollation[0];

	/* Allocate space */
	/* Use float instead of double to save memory */
	agg = palloc(aggSize);
	centerCounts = palloc(centerCountsSize);
	closestCenters = palloc(closestCentersSize);
	lowerBound = palloc_extended(lowerBoundSize, MCXT_ALLOC_HUGE);
	upperBound = palloc(upperBoundSize);
	s = palloc(sSize);
	halfcdist = palloc_extended(halfcdistSize, MCXT_ALLOC_HUGE);
	newcdist = palloc(newcdistSize);

	/* Initialize new centers */
	newCenters = VectorArrayInit(numCenters, dimensions, centers->itemsize);
	newCenters->length = numCenters;

#ifdef IVFFLAT_MEMORY
	ShowMemoryUsage(MemoryContextGetParent(CurrentMemoryContext), totalSize);
#endif

	/* Pick initial centers */
	InitCenters(index, samples, centers, lowerBound);

	/* Assign each x to its closest initial center c(x) = argmin d(x,c) */
	vector_rust_ivfflat_init_bounds_kernel(numSamples, numCenters, lowerBound, upperBound, closestCenters);

	/* Give 500 iterations to converge */
	for (int iteration = 0; iteration < 500; iteration++)
	{
		int			changes = 0;
		bool		rjreset;

		/* Can take a while, so ensure we can interrupt */
		CHECK_FOR_INTERRUPTS();

		/* Step 1: For all centers, compute distance */
		for (int64 j = 0; j < numCenters; j++)
		{
			Datum		vec = PointerGetDatum(VectorArrayGet(centers, j));

			for (int64 k = j + 1; k < numCenters; k++)
			{
				float		distance = 0.5 * DatumGetFloat8(FunctionCall2Coll(procinfo, collation, vec, PointerGetDatum(VectorArrayGet(centers, k))));

				halfcdist[j * numCenters + k] = distance;
				halfcdist[k * numCenters + j] = distance;
			}
		}

		/* For all centers c, compute s(c) */
		vector_rust_ivfflat_compute_s_kernel(numCenters, halfcdist, s);

		rjreset = iteration != 0;

		for (int64 j = 0; j < numSamples; j++)
		{
			bool		rj;

			/* Step 2: Identify all points x such that u(x) <= s(c(x)) */
			if (upperBound[j] <= s[closestCenters[j]])
				continue;

			rj = rjreset;

			for (int64 k = 0; k < numCenters; k++)
			{
				Datum		vec;
				float		dxcx;

				/* Step 3: For all remaining points x and centers c */
				if (k == closestCenters[j])
					continue;

				if (upperBound[j] <= lowerBound[j * numCenters + k])
					continue;

				if (upperBound[j] <= halfcdist[closestCenters[j] * numCenters + k])
					continue;

				vec = PointerGetDatum(VectorArrayGet(samples, j));

				/* Step 3a */
				if (rj)
				{
					dxcx = DatumGetFloat8(FunctionCall2Coll(procinfo, collation, vec, PointerGetDatum(VectorArrayGet(centers, closestCenters[j]))));

					/* d(x,c(x)) computed, which is a form of d(x,c) */
					lowerBound[j * numCenters + closestCenters[j]] = dxcx;
					upperBound[j] = dxcx;

					rj = false;
				}
				else
					dxcx = upperBound[j];

				/* Step 3b */
				if (dxcx > lowerBound[j * numCenters + k] || dxcx > halfcdist[closestCenters[j] * numCenters + k])
				{
					float		dxc = DatumGetFloat8(FunctionCall2Coll(procinfo, collation, vec, PointerGetDatum(VectorArrayGet(centers, k))));

					/* d(x,c) calculated */
					lowerBound[j * numCenters + k] = dxc;

					if (dxc < dxcx)
					{
						closestCenters[j] = k;

						/* c(x) changed */
						upperBound[j] = dxc;

						changes++;
					}
				}
			}
		}

		/* Step 4: For each center c, let m(c) be mean of all points assigned */
		ComputeNewCenters(samples, agg, newCenters, centerCounts, closestCenters, normprocinfo, collation, typeInfo);

		/* Step 5 */
		for (int j = 0; j < numCenters; j++)
			newcdist[j] = DatumGetFloat8(FunctionCall2Coll(procinfo, collation, PointerGetDatum(VectorArrayGet(centers, j)), PointerGetDatum(VectorArrayGet(newCenters, j))));

		vector_rust_ivfflat_adjust_lower_bounds_kernel(numSamples, numCenters, lowerBound, newcdist);

		/* Step 6 */
		/* We reset r(x) before Step 3 in the next iteration */
		vector_rust_ivfflat_adjust_upper_bounds_kernel(numSamples, upperBound, closestCenters, newcdist);

		/* Step 7 */
		for (int j = 0; j < numCenters; j++)
			VectorArraySet(centers, j, VectorArrayGet(newCenters, j));

		if (changes == 0 && iteration != 0)
			break;
	}
}

/*
 * Ensure no NaN or infinite values
 */
static void
CheckElements(VectorArray centers, const IvfflatTypeInfo * typeInfo)
{
	float	   *scratch = palloc(sizeof(float) * centers->dim);

	for (int i = 0; i < centers->length; i++)
	{
		vector_rust_ivfflat_zero_agg_kernel(1, centers->dim, scratch);

		/* /fp:fast may not propagate NaN with MSVC, but that's alright */
		typeInfo->sumCenter(VectorArrayGet(centers, i), scratch);
		if (!vector_rust_ivfflat_all_finite_kernel(centers->dim, scratch))
			elog(ERROR, "Non-finite value detected. Please report a bug.");
	}
}

/*
 * Ensure no zero vectors for cosine distance
 */
static void
CheckNorms(VectorArray centers, Relation index)
{
	/* Check NORM_PROC instead of KMEANS_NORM_PROC */
	FmgrInfo   *normprocinfo = IvfflatOptionalProcInfo(index, IVFFLAT_NORM_PROC);
	Oid			collation = index->rd_indcollation[0];

	if (normprocinfo == NULL)
		return;

	for (int i = 0; i < centers->length; i++)
	{
		double		norm = DatumGetFloat8(FunctionCall1Coll(normprocinfo, collation, PointerGetDatum(VectorArrayGet(centers, i))));

		if (norm == 0)
			elog(ERROR, "Zero norm detected. Please report a bug.");
	}
}

/*
 * Detect issues with centers
 */
static void
CheckCenters(Relation index, VectorArray centers, const IvfflatTypeInfo * typeInfo)
{
	if (centers->length != centers->maxlen)
		elog(ERROR, "Not enough centers. Please report a bug.");

	CheckElements(centers, typeInfo);
	CheckNorms(centers, index);
}

/*
 * Perform naive k-means centering
 * We use spherical k-means for inner product and cosine
 */
void
IvfflatKmeans(Relation index, VectorArray samples, VectorArray centers, const IvfflatTypeInfo * typeInfo)
{
	MemoryContext kmeansCtx = AllocSetContextCreate(CurrentMemoryContext,
													"Ivfflat kmeans temporary context",
													ALLOCSET_DEFAULT_SIZES);
	MemoryContext oldCtx = MemoryContextSwitchTo(kmeansCtx);

	if (samples->length == 0)
		RandomCenters(index, centers, typeInfo);
	else
		ElkanKmeans(index, samples, centers, typeInfo);

	CheckCenters(index, centers, typeInfo);

	MemoryContextSwitchTo(oldCtx);
	MemoryContextDelete(kmeansCtx);
}
