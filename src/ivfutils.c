#include "postgres.h"

#include "access/genam.h"
#include "access/generic_xlog.h"
#include "bitvec.h"
#include "catalog/pg_type.h"
#include "fmgr.h"
#include "halfutils.h"
#include "halfvec.h"
#include "ivfflat.h"
#include "rust_ffi.h"
#include "storage/bufmgr.h"
#include "utils/array.h"
#include "utils/relcache.h"
#include "utils/varbit.h"
#include "vector.h"

#if PG_VERSION_NUM >= 160000
#include "varatt.h"
#endif

/*
 * Allocate a vector array
 */
VectorArray
VectorArrayInit(int maxlen, int dimensions, Size itemsize)
{
	VectorArray res = palloc(sizeof(VectorArrayData));

	/* Ensure items are aligned to prevent UB */
	itemsize = MAXALIGN(itemsize);

	res->length = 0;
	res->maxlen = maxlen;
	res->dim = dimensions;
	res->itemsize = itemsize;
	res->items = palloc_extended(maxlen * itemsize, MCXT_ALLOC_ZERO | MCXT_ALLOC_HUGE);
	return res;
}

/*
 * Free a vector array
 */
void
VectorArrayFree(VectorArray arr)
{
	pfree(arr->items);
	pfree(arr);
}

/*
 * Get the number of lists in the index
 */
int
IvfflatGetLists(Relation index)
{
	IvfflatOptions *opts = (IvfflatOptions *) index->rd_options;

	if (opts)
		return opts->lists;

	return IVFFLAT_DEFAULT_LISTS;
}

/*
 * Get proc
 */
FmgrInfo *
IvfflatOptionalProcInfo(Relation index, uint16 procnum)
{
	if (!OidIsValid(index_getprocid(index, 1, procnum)))
		return NULL;

	return index_getprocinfo(index, 1, procnum);
}

/*
 * Normalize value
 */
Datum
IvfflatNormValue(const IvfflatTypeInfo * typeInfo, Oid collation, Datum value)
{
	return DirectFunctionCall1Coll(typeInfo->normalize, collation, value);
}

/*
 * Check if non-zero norm
 */
bool
IvfflatCheckNorm(FmgrInfo *procinfo, Oid collation, Datum value)
{
	return DatumGetFloat8(FunctionCall1Coll(procinfo, collation, value)) > 0;
}

/*
 * New buffer
 */
Buffer
IvfflatNewBuffer(Relation index, ForkNumber forkNum)
{
	Buffer		buf = ReadBufferExtended(index, forkNum, P_NEW, RBM_NORMAL, NULL);

	LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
	return buf;
}

/*
 * Init page
 */
void
IvfflatInitPage(Buffer buf, Page page)
{
	PageInit(page, BufferGetPageSize(buf), sizeof(IvfflatPageOpaqueData));
	IvfflatPageGetOpaque(page)->nextblkno = InvalidBlockNumber;
	IvfflatPageGetOpaque(page)->page_id = IVFFLAT_PAGE_ID;
}

/*
 * Init and register page
 */
void
IvfflatInitRegisterPage(Relation index, Buffer *buf, Page *page, GenericXLogState **state)
{
	*state = GenericXLogStart(index);
	*page = GenericXLogRegisterBuffer(*state, *buf, GENERIC_XLOG_FULL_IMAGE);
	IvfflatInitPage(*buf, *page);
}

/*
 * Commit buffer
 */
void
IvfflatCommitBuffer(Buffer buf, GenericXLogState *state)
{
	GenericXLogFinish(state);
	UnlockReleaseBuffer(buf);
}

/*
 * Add a new page
 *
 * The order is very important!!
 */
void
IvfflatAppendPage(Relation index, Buffer *buf, Page *page, GenericXLogState **state, ForkNumber forkNum)
{
	/* Get new buffer */
	Buffer		newbuf = IvfflatNewBuffer(index, forkNum);
	Page		newpage = GenericXLogRegisterBuffer(*state, newbuf, GENERIC_XLOG_FULL_IMAGE);

	/* Update the previous buffer */
	IvfflatPageGetOpaque(*page)->nextblkno = BufferGetBlockNumber(newbuf);

	/* Init new page */
	IvfflatInitPage(newbuf, newpage);

	/* Commit */
	GenericXLogFinish(*state);

	/* Unlock */
	UnlockReleaseBuffer(*buf);

	*state = GenericXLogStart(index);
	*page = GenericXLogRegisterBuffer(*state, newbuf, GENERIC_XLOG_FULL_IMAGE);
	*buf = newbuf;
}

/*
 * Get the metapage info
 */
void
IvfflatGetMetaPageInfo(Relation index, int *lists, int *dimensions)
{
	Buffer		buf;
	Page		page;
	IvfflatMetaPage metap;

	buf = ReadBuffer(index, IVFFLAT_METAPAGE_BLKNO);
	LockBuffer(buf, BUFFER_LOCK_SHARE);
	page = BufferGetPage(buf);
	metap = IvfflatPageGetMeta(page);

	if (unlikely(metap->magicNumber != IVFFLAT_MAGIC_NUMBER))
		elog(ERROR, "ivfflat index is not valid");

	if (lists != NULL)
		*lists = metap->lists;

	if (dimensions != NULL)
		*dimensions = metap->dimensions;

	UnlockReleaseBuffer(buf);
}

static bool
IvfflatShouldWriteListInsertPage(BlockNumber insertPage, BlockNumber currentInsertPage, bool useRust)
{
	if (useRust)
	{
		bool		isValid;

		isValid = vector_rust_ivfflat_should_follow_insert_page_link_kernel((int32) insertPage);
		return isValid &&
			vector_rust_ivfflat_should_update_insert_page_kernel((int32) insertPage, (int32) currentInsertPage);
	}

	return BlockNumberIsValid(insertPage) && insertPage != currentInsertPage;
}

static bool
IvfflatShouldAllowInsertPageAfterOriginal(BlockNumber insertPage, BlockNumber originalInsertPage, bool useRust)
{
	if (useRust)
		return vector_rust_ivfflat_should_allow_insert_page_after_original_kernel((int32) insertPage, (int32) originalInsertPage);

	return !BlockNumberIsValid(originalInsertPage) || insertPage >= originalInsertPage;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_should_write_list_insert_page);
Datum
vector_ivfflat_should_write_list_insert_page(PG_FUNCTION_ARGS)
{
	int32		insertPage = PG_GETARG_INT32(0);
	int32		currentInsertPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(IvfflatShouldWriteListInsertPage((BlockNumber) insertPage, (BlockNumber) currentInsertPage, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_should_write_list_insert_page);
Datum
vector_rust_ivfflat_should_write_list_insert_page(PG_FUNCTION_ARGS)
{
	int32		insertPage = PG_GETARG_INT32(0);
	int32		currentInsertPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(IvfflatShouldWriteListInsertPage((BlockNumber) insertPage, (BlockNumber) currentInsertPage, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_should_allow_insert_page_after_original);
Datum
vector_ivfflat_should_allow_insert_page_after_original(PG_FUNCTION_ARGS)
{
	int32		insertPage = PG_GETARG_INT32(0);
	int32		originalInsertPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(IvfflatShouldAllowInsertPageAfterOriginal((BlockNumber) insertPage, (BlockNumber) originalInsertPage, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_should_allow_insert_page_after_original);
Datum
vector_rust_ivfflat_should_allow_insert_page_after_original(PG_FUNCTION_ARGS)
{
	int32		insertPage = PG_GETARG_INT32(0);
	int32		originalInsertPage = PG_GETARG_INT32(1);

	PG_RETURN_BOOL(IvfflatShouldAllowInsertPageAfterOriginal((BlockNumber) insertPage, (BlockNumber) originalInsertPage, true));
}

/*
 * Update the start or insert page of a list
 */
void
IvfflatUpdateList(Relation index, ListInfo listInfo,
				  BlockNumber insertPage, BlockNumber originalInsertPage,
				  BlockNumber startPage, ForkNumber forkNum)
{
	Buffer		buf;
	Page		page;
	GenericXLogState *state;
	IvfflatList list;
	bool		changed = false;

	buf = ReadBufferExtended(index, forkNum, listInfo.blkno, RBM_NORMAL, NULL);
	LockBuffer(buf, BUFFER_LOCK_EXCLUSIVE);
	state = GenericXLogStart(index);
	page = GenericXLogRegisterBuffer(state, buf, 0);
	list = (IvfflatList) PageGetItem(page, PageGetItemId(page, listInfo.offno));

	if (IvfflatShouldWriteListInsertPage(insertPage, list->insertPage, true))
	{
		/* Skip update if insert page is lower than original insert page  */
		/* This is needed to prevent insert from overwriting vacuum */
		if (IvfflatShouldAllowInsertPageAfterOriginal(insertPage, originalInsertPage, true))
		{
			list->insertPage = insertPage;
			changed = true;
		}
	}

	if (BlockNumberIsValid(startPage) && startPage != list->startPage)
	{
		list->startPage = startPage;
		changed = true;
	}

	/* Only commit if changed */
	if (changed)
		IvfflatCommitBuffer(buf, state);
	else
	{
		GenericXLogAbort(state);
		UnlockReleaseBuffer(buf);
	}
}

static ArrayType *
IvfflatVectorSumCenter(ArrayType *leftArray, ArrayType *rightArray, bool useRust)
{
	Datum	   *leftDatums;
	Datum	   *rightDatums;
	int			leftLength;
	int			rightLength;
	float	   *agg;
	float	   *center;
	Datum	   *resultDatums;
	ArrayType  *result;

	if (ARR_NDIM(leftArray) > 1 || ARR_NDIM(rightArray) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("array must be 1-D")));

	if ((ARR_HASNULL(leftArray) && array_contains_nulls(leftArray)) ||
		(ARR_HASNULL(rightArray) && array_contains_nulls(rightArray)))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("array must not contain nulls")));

	if (ARR_ELEMTYPE(leftArray) != FLOAT4OID || ARR_ELEMTYPE(rightArray) != FLOAT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("array must be real[]")));

	deconstruct_array(leftArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &leftDatums, NULL, &leftLength);
	deconstruct_array(rightArray, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &rightDatums, NULL, &rightLength);

	if (leftLength != rightLength)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("array dimensions must match")));

	agg = palloc(sizeof(float) * leftLength);
	center = palloc(sizeof(float) * leftLength);
	for (int i = 0; i < leftLength; i++)
	{
		agg[i] = DatumGetFloat4(leftDatums[i]);
		center[i] = DatumGetFloat4(rightDatums[i]);
	}

	if (useRust)
		vector_rust_ivfflat_vector_sum_center_kernel(leftLength, center, agg);
	else
	{
		for (int i = 0; i < leftLength; i++)
			agg[i] += center[i];
	}

	resultDatums = palloc(sizeof(Datum) * leftLength);
	for (int i = 0; i < leftLength; i++)
		resultDatums[i] = Float4GetDatum(agg[i]);

	result = construct_array(resultDatums, leftLength, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(center);
	pfree(agg);
	pfree(rightDatums);
	pfree(leftDatums);

	return result;
}

static ArrayType *
IvfflatBitSumCenter(VarBit *vec, bool useRust)
{
	int			dimensions = VARBITLEN(vec);
	float	   *agg;
	Datum	   *resultDatums;
	ArrayType  *result;

	agg = palloc0(sizeof(float) * dimensions);

	if (useRust)
		vector_rust_ivfflat_bit_sum_center_kernel(dimensions, VARBITS(vec), agg);
	else
	{
		for (int i = 0; i < dimensions; i++)
			agg[i] += (float) (((VARBITS(vec)[i / 8]) >> (7 - (i % 8))) & 0x01);
	}

	resultDatums = palloc(sizeof(Datum) * dimensions);
	for (int i = 0; i < dimensions; i++)
		resultDatums[i] = Float4GetDatum(agg[i]);

	result = construct_array(resultDatums, dimensions, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(agg);

	return result;
}

static float *
IvfflatRealArrayToFloat(ArrayType *array, int *length)
{
	Datum	   *datums;
	float	   *values;

	if (ARR_NDIM(array) > 1)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("array must be 1-D")));

	if (ARR_HASNULL(array) && array_contains_nulls(array))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("array must not contain nulls")));

	if (ARR_ELEMTYPE(array) != FLOAT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("array must be real[]")));

	deconstruct_array(array, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT,
					  &datums, NULL, length);

	values = palloc(sizeof(float) * (*length));
	for (int i = 0; i < *length; i++)
		values[i] = DatumGetFloat4(datums[i]);

	pfree(datums);
	return values;
}

static ArrayType *
IvfflatVectorUpdateCenter(ArrayType *valuesArray, bool useRust)
{
	int			dimensions;
	float	   *values;
	Vector	   *vec;
	Datum	   *resultDatums;
	ArrayType  *result;

	values = IvfflatRealArrayToFloat(valuesArray, &dimensions);
	vec = InitVector(dimensions);

	if (useRust)
		vector_rust_ivfflat_vector_update_center_kernel(dimensions, values, vec->x);
	else
	{
		for (int i = 0; i < dimensions; i++)
			vec->x[i] = values[i];
	}

	resultDatums = palloc(sizeof(Datum) * dimensions);
	for (int i = 0; i < dimensions; i++)
		resultDatums[i] = Float4GetDatum(vec->x[i]);

	result = construct_array(resultDatums, dimensions, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(vec);
	pfree(values);

	return result;
}

static VarBit *
IvfflatBitUpdateCenter(ArrayType *valuesArray, bool useRust)
{
	int			dimensions;
	float	   *values;
	VarBit	   *vec;
	unsigned char *nx;

	values = IvfflatRealArrayToFloat(valuesArray, &dimensions);
	vec = InitBitVector(dimensions);
	nx = VARBITS(vec);

	if (useRust)
		vector_rust_ivfflat_bit_update_center_kernel(dimensions, values, nx);
	else
	{
		for (uint32 i = 0; i < VARBITBYTES(vec); i++)
			nx[i] = 0;

		for (int i = 0; i < dimensions; i++)
			nx[i / 8] |= (values[i] > 0.5 ? 1 : 0) << (7 - (i % 8));
	}

	pfree(values);
	return vec;
}

static ArrayType *
IvfflatHalfvecUpdateCenter(ArrayType *valuesArray, bool useRust)
{
	int			dimensions;
	float	   *values;
	HalfVector *vec;
	float	   *outputValues;
	Datum	   *resultDatums;
	ArrayType  *result;

	values = IvfflatRealArrayToFloat(valuesArray, &dimensions);
	vec = InitHalfVector(dimensions);

	if (useRust)
		vector_rust_ivfflat_halfvec_update_center_kernel(dimensions, values, vec->x);
	else
	{
		for (int i = 0; i < dimensions; i++)
			vec->x[i] = Float4ToHalfUnchecked(values[i]);
	}

	outputValues = palloc(sizeof(float) * dimensions);
	vector_rust_halfvec_to_vector(dimensions, vec->x, outputValues);

	resultDatums = palloc(sizeof(Datum) * dimensions);
	for (int i = 0; i < dimensions; i++)
		resultDatums[i] = Float4GetDatum(outputValues[i]);

	result = construct_array(resultDatums, dimensions, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(outputValues);
	pfree(vec);
	pfree(values);

	return result;
}

static ArrayType *
IvfflatHalfvecSumCenter(ArrayType *leftArray, ArrayType *rightArray, bool useRust)
{
	float	   *agg;
	float	   *centerValues;
	int			aggLength;
	int			centerLength;
	HalfVector *center;
	Datum	   *resultDatums;
	ArrayType  *result;

	agg = IvfflatRealArrayToFloat(leftArray, &aggLength);
	centerValues = IvfflatRealArrayToFloat(rightArray, &centerLength);

	if (aggLength != centerLength)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("array dimensions must match")));

	center = InitHalfVector(centerLength);
	if (useRust)
		vector_rust_ivfflat_halfvec_update_center_kernel(centerLength, centerValues, center->x);
	else
	{
		for (int i = 0; i < centerLength; i++)
			center->x[i] = Float4ToHalfUnchecked(centerValues[i]);
	}

	if (useRust)
		vector_rust_ivfflat_halfvec_sum_center_kernel(centerLength, center->x, agg);
	else
	{
		for (int i = 0; i < centerLength; i++)
			agg[i] += HalfToFloat4(center->x[i]);
	}

	resultDatums = palloc(sizeof(Datum) * aggLength);
	for (int i = 0; i < aggLength; i++)
		resultDatums[i] = Float4GetDatum(agg[i]);

	result = construct_array(resultDatums, aggLength, FLOAT4OID, sizeof(float4), true, TYPALIGN_INT);

	pfree(resultDatums);
	pfree(center);
	pfree(centerValues);
	pfree(agg);

	return result;
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_vector_sum_center);
Datum
vector_ivfflat_vector_sum_center(PG_FUNCTION_ARGS)
{
	ArrayType  *leftArray = PG_GETARG_ARRAYTYPE_P(0);
	ArrayType  *rightArray = PG_GETARG_ARRAYTYPE_P(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatVectorSumCenter(leftArray, rightArray, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_vector_sum_center);
Datum
vector_rust_ivfflat_vector_sum_center(PG_FUNCTION_ARGS)
{
	ArrayType  *leftArray = PG_GETARG_ARRAYTYPE_P(0);
	ArrayType  *rightArray = PG_GETARG_ARRAYTYPE_P(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatVectorSumCenter(leftArray, rightArray, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_bit_sum_center);
Datum
vector_ivfflat_bit_sum_center(PG_FUNCTION_ARGS)
{
	VarBit	   *vec = PG_GETARG_VARBIT_P(0);

	PG_RETURN_ARRAYTYPE_P(IvfflatBitSumCenter(vec, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_bit_sum_center);
Datum
vector_rust_ivfflat_bit_sum_center(PG_FUNCTION_ARGS)
{
	VarBit	   *vec = PG_GETARG_VARBIT_P(0);

	PG_RETURN_ARRAYTYPE_P(IvfflatBitSumCenter(vec, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_vector_update_center);
Datum
vector_ivfflat_vector_update_center(PG_FUNCTION_ARGS)
{
	ArrayType  *valuesArray = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_ARRAYTYPE_P(IvfflatVectorUpdateCenter(valuesArray, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_vector_update_center);
Datum
vector_rust_ivfflat_vector_update_center(PG_FUNCTION_ARGS)
{
	ArrayType  *valuesArray = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_ARRAYTYPE_P(IvfflatVectorUpdateCenter(valuesArray, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_bit_update_center);
Datum
vector_ivfflat_bit_update_center(PG_FUNCTION_ARGS)
{
	ArrayType  *valuesArray = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_VARBIT_P(IvfflatBitUpdateCenter(valuesArray, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_bit_update_center);
Datum
vector_rust_ivfflat_bit_update_center(PG_FUNCTION_ARGS)
{
	ArrayType  *valuesArray = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_VARBIT_P(IvfflatBitUpdateCenter(valuesArray, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_halfvec_update_center);
Datum
vector_ivfflat_halfvec_update_center(PG_FUNCTION_ARGS)
{
	ArrayType  *valuesArray = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_ARRAYTYPE_P(IvfflatHalfvecUpdateCenter(valuesArray, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_halfvec_update_center);
Datum
vector_rust_ivfflat_halfvec_update_center(PG_FUNCTION_ARGS)
{
	ArrayType  *valuesArray = PG_GETARG_ARRAYTYPE_P(0);

	PG_RETURN_ARRAYTYPE_P(IvfflatHalfvecUpdateCenter(valuesArray, true));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_ivfflat_halfvec_sum_center);
Datum
vector_ivfflat_halfvec_sum_center(PG_FUNCTION_ARGS)
{
	ArrayType  *leftArray = PG_GETARG_ARRAYTYPE_P(0);
	ArrayType  *rightArray = PG_GETARG_ARRAYTYPE_P(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatHalfvecSumCenter(leftArray, rightArray, false));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(vector_rust_ivfflat_halfvec_sum_center);
Datum
vector_rust_ivfflat_halfvec_sum_center(PG_FUNCTION_ARGS)
{
	ArrayType  *leftArray = PG_GETARG_ARRAYTYPE_P(0);
	ArrayType  *rightArray = PG_GETARG_ARRAYTYPE_P(1);

	PG_RETURN_ARRAYTYPE_P(IvfflatHalfvecSumCenter(leftArray, rightArray, true));
}

PGDLLEXPORT Datum l2_normalize(PG_FUNCTION_ARGS);
PGDLLEXPORT Datum halfvec_l2_normalize(PG_FUNCTION_ARGS);
PGDLLEXPORT Datum sparsevec_l2_normalize(PG_FUNCTION_ARGS);

static Size
VectorItemSize(int dimensions)
{
	return VECTOR_SIZE(dimensions);
}

static Size
HalfvecItemSize(int dimensions)
{
	return HALFVEC_SIZE(dimensions);
}

static Size
BitItemSize(int dimensions)
{
	return VARBITTOTALLEN(dimensions);
}

static void
VectorUpdateCenter(Pointer v, int dimensions, float *x)
{
	Vector	   *vec = (Vector *) v;

	SET_VARSIZE(vec, VECTOR_SIZE(dimensions));
	vec->dim = dimensions;
	vector_rust_ivfflat_vector_update_center_kernel(dimensions, x, vec->x);
}

static void
HalfvecUpdateCenter(Pointer v, int dimensions, float *x)
{
	HalfVector *vec = (HalfVector *) v;

	SET_VARSIZE(vec, HALFVEC_SIZE(dimensions));
	vec->dim = dimensions;
	vector_rust_ivfflat_halfvec_update_center_kernel(dimensions, x, vec->x);
}

static void
BitUpdateCenter(Pointer v, int dimensions, float *x)
{
	VarBit	   *vec = (VarBit *) v;
	unsigned char *nx = VARBITS(vec);

	SET_VARSIZE(vec, VARBITTOTALLEN(dimensions));
	VARBITLEN(vec) = dimensions;
	vector_rust_ivfflat_bit_update_center_kernel(dimensions, x, nx);
}

static void
VectorSumCenter(Pointer v, float *x)
{
	Vector	   *vec = (Vector *) v;

	vector_rust_ivfflat_vector_sum_center_kernel(vec->dim, vec->x, x);
}

static void
HalfvecSumCenter(Pointer v, float *x)
{
	HalfVector *vec = (HalfVector *) v;

	vector_rust_ivfflat_halfvec_sum_center_kernel(vec->dim, vec->x, x);
}

static void
BitSumCenter(Pointer v, float *x)
{
	VarBit	   *vec = (VarBit *) v;

	vector_rust_ivfflat_bit_sum_center_kernel(VARBITLEN(vec), VARBITS(vec), x);
}

/*
 * Get type info
 */
const		IvfflatTypeInfo *
IvfflatGetTypeInfo(Relation index)
{
	FmgrInfo   *procinfo = IvfflatOptionalProcInfo(index, IVFFLAT_TYPE_INFO_PROC);

	if (procinfo == NULL)
	{
		static const IvfflatTypeInfo typeInfo = {
			.maxDimensions = IVFFLAT_MAX_DIM,
			.normalize = l2_normalize,
			.itemSize = VectorItemSize,
			.updateCenter = VectorUpdateCenter,
			.sumCenter = VectorSumCenter
		};

		return (&typeInfo);
	}
	else
		return (const IvfflatTypeInfo *) DatumGetPointer(FunctionCall0Coll(procinfo, InvalidOid));
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(ivfflat_halfvec_support);
Datum
ivfflat_halfvec_support(PG_FUNCTION_ARGS)
{
	static const IvfflatTypeInfo typeInfo = {
		.maxDimensions = IVFFLAT_MAX_DIM * 2,
		.normalize = halfvec_l2_normalize,
		.itemSize = HalfvecItemSize,
		.updateCenter = HalfvecUpdateCenter,
		.sumCenter = HalfvecSumCenter
	};

	PG_RETURN_POINTER(&typeInfo);
}

FUNCTION_PREFIX PG_FUNCTION_INFO_V1(ivfflat_bit_support);
Datum
ivfflat_bit_support(PG_FUNCTION_ARGS)
{
	static const IvfflatTypeInfo typeInfo = {
		.maxDimensions = IVFFLAT_MAX_DIM * 32,
		.normalize = NULL,
		.itemSize = BitItemSize,
		.updateCenter = BitUpdateCenter,
		.sumCenter = BitSumCenter
	};

	PG_RETURN_POINTER(&typeInfo);
}
