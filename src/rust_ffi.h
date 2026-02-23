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

#endif
