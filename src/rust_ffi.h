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

#endif
