#ifndef RUST_FFI_H
#define RUST_FFI_H

#include "postgres.h"

void		vector_rust_init(void);
const char *vector_rust_bridge_version_cstr(void);
uint64		vector_rust_bit_hamming_distance(uint32 bytes, unsigned char *ax, unsigned char *bx, uint64 distance);
double		vector_rust_bit_jaccard_distance(uint32 bytes, unsigned char *ax, unsigned char *bx, uint64 ab, uint64 aa, uint64 bb);
float		vector_rust_half_l2_squared_distance(int dim, const void *ax, const void *bx);
float		vector_rust_half_inner_product(int dim, const void *ax, const void *bx);
double		vector_rust_half_cosine_similarity(int dim, const void *ax, const void *bx);
float		vector_rust_half_l1_distance(int dim, const void *ax, const void *bx);
float		vector_rust_vector_l2_squared_distance(int dim, const float *ax, const float *bx);
float		vector_rust_vector_inner_product(int dim, const float *ax, const float *bx);
double		vector_rust_vector_cosine_similarity(int dim, const float *ax, const float *bx);
float		vector_rust_vector_l1_distance(int dim, const float *ax, const float *bx);
void		vector_rust_vector_add(int dim, const float *ax, const float *bx, float *rx);
void		vector_rust_vector_sub(int dim, const float *ax, const float *bx, float *rx);
void		vector_rust_vector_mul(int dim, const float *ax, const float *bx, float *rx);
void		vector_rust_vector_concat(int adim, const float *ax, int bdim, const float *bx, float *rx);
double		vector_rust_vector_norm(int dim, const float *ax);
void		vector_rust_vector_l2_normalize(int dim, const float *ax, float *rx);
void		vector_rust_vector_binary_quantize(int dim, const float *ax, unsigned char *rx);
void		vector_rust_vector_subvector(int dim, const float *ax, int start_index, float *rx);
int32		vector_rust_vector_cmp(int adim, const float *ax, int bdim, const float *bx);
void		vector_rust_vector_copy_f64(int dim, const double *src, double *dst);
void		vector_rust_vector_accum_init(int dim, const float *x, double *dst);
void		vector_rust_vector_accum_add(int dim, const double *state, const float *x, double *dst);
void		vector_rust_vector_combine_add(int dim, const double *a, const double *b, double *dst);
void		vector_rust_vector_avg(int dim, const double *state, double n, float *dst);
void		vector_rust_halfvec_to_vector(int dim, const void *ax, float *rx);
void		vector_rust_vector_to_halfvec_kernel(int dim, const float *ax, void *rx);
void		vector_rust_sparse_to_halfvec_kernel(int nnz, const int32 *indices, const float *values, void *rx);
void		vector_rust_sparse_to_dense(int nnz, const int32 *indices, const float *values, float *rx);
int32		vector_rust_vector_to_sparse_count_kernel(int dim, const float *ax);
int32		vector_rust_vector_to_sparse_fill_kernel(int dim, const float *ax, int32 *indices, float *values);
int32		vector_rust_halfvec_to_sparse_count_kernel(int dim, const void *ax);
int32		vector_rust_halfvec_to_sparse_fill_kernel(int dim, const void *ax, int32 *indices, float *values);
void		vector_rust_ivfflat_center_counts_kernel(int sample_count, const int32 *closest_centers, int center_count, int32 *counts);
void		vector_rust_ivfflat_zero_agg_kernel(int center_count, int dimensions, float *agg);
void		vector_rust_ivfflat_finalize_center_kernel(int dimensions, float *agg, int center_count);
bool		vector_rust_ivfflat_all_finite_kernel(int dimensions, const float *values);
void		vector_rust_ivfflat_vector_sum_center_kernel(int dimensions, const float *center, float *agg);
void		vector_rust_ivfflat_bit_sum_center_kernel(int dimensions, const unsigned char *bits, float *agg);
void		vector_rust_ivfflat_vector_update_center_kernel(int dimensions, const float *values, float *output);
void		vector_rust_ivfflat_bit_update_center_kernel(int dimensions, const float *values, unsigned char *output);
void		vector_rust_ivfflat_halfvec_update_center_kernel(int dimensions, const float *values, void *output);
void		vector_rust_ivfflat_halfvec_sum_center_kernel(int dimensions, const void *halfvec, float *agg);
void		vector_rust_ivfflat_adjust_lower_bounds_kernel(int sample_count, int center_count, float *lower_bounds, const float *center_distances);
void		vector_rust_ivfflat_adjust_upper_bounds_kernel(int sample_count, float *upper_bounds, const int32 *closest_centers, const float *center_distances);
void		vector_rust_ivfflat_init_bounds_kernel(int sample_count, int center_count, const float *lower_bounds, float *upper_bounds, int32 *closest_centers);
void		vector_rust_ivfflat_compute_s_kernel(int center_count, const float *halfcdist, float *s);
void		vector_rust_halfvec_add_kernel(int dim, const void *ax, const void *bx, float *rx);
void		vector_rust_halfvec_sub_kernel(int dim, const void *ax, const void *bx, float *rx);
void		vector_rust_halfvec_mul_kernel(int dim, const void *ax, const void *bx, float *rx);
void		vector_rust_halfvec_concat_kernel(int adim, const void *ax, int bdim, const void *bx, float *rx);
void		vector_rust_halfvec_binary_quantize_kernel(int dim, const void *ax, unsigned char *rx);
void		vector_rust_halfvec_subvector_kernel(int dim, const void *ax, int start_index, void *rx);
double		vector_rust_halfvec_l2_norm_kernel(int dim, const void *ax);
void		vector_rust_halfvec_l2_normalize_kernel(int dim, const void *ax, float *rx);
int32		vector_rust_halfvec_cmp_kernel(int adim, const void *ax, int bdim, const void *bx);
void		vector_rust_halfvec_accum_init_kernel(int dim, const void *ax, double *dst);
void		vector_rust_halfvec_accum_add_kernel(int dim, const double *state, const void *ax, double *dst);
float		vector_rust_sparsevec_l1_distance_kernel(int annz, const int32 *aindices, const float *ax, int bnnz, const int32 *bindices, const float *bx);
float		vector_rust_sparsevec_l2_squared_distance_kernel(int annz, const int32 *aindices, const float *ax, int bnnz, const int32 *bindices, const float *bx);
float		vector_rust_sparsevec_inner_product_kernel(int annz, const int32 *aindices, const float *ax, int bnnz, const int32 *bindices, const float *bx);
double		vector_rust_sparsevec_cosine_distance_kernel(int annz, const int32 *aindices, const float *ax, int bnnz, const int32 *bindices, const float *bx);
double		vector_rust_sparsevec_l2_norm_kernel(int nnz, const float *ax);
void		vector_rust_sparsevec_l2_normalize_values_kernel(int nnz, const float *ax, double norm, float *rx);
int32		vector_rust_sparsevec_cmp_kernel(int adim, int annz, const int32 *aindices, const float *ax, int bdim, int bnnz, const int32 *bindices, const float *bx);

#endif
