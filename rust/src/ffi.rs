use std::ffi::{c_char, c_void};

static RUST_BRIDGE_VERSION: &[u8] = b"rust-bridge-v1\0";

#[no_mangle]
pub extern "C" fn vector_rust_init() {}

#[no_mangle]
pub extern "C" fn vector_rust_bridge_version_cstr() -> *const c_char {
    RUST_BRIDGE_VERSION.as_ptr().cast()
}

#[inline]
unsafe fn read_half_bits(base: *const c_void, idx: usize) -> u16 {
    let ptr = (base as *const u8).add(idx * 2) as *const u16;
    std::ptr::read_unaligned(ptr)
}

#[inline]
fn half_bits_to_f32(bits: u16) -> f32 {
    let sign = ((bits & 0x8000) as u32) << 16;
    let exponent = ((bits >> 10) & 0x1f) as u32;
    let mantissa = (bits & 0x03ff) as u32;

    let float_bits = if exponent == 0 {
        if mantissa == 0 {
            sign
        } else {
            let mut mant = mantissa;
            let mut exp = -14i32;

            while (mant & 0x0400) == 0 {
                mant <<= 1;
                exp -= 1;
            }

            mant &= 0x03ff;

            sign | (((exp + 127) as u32) << 23) | (mant << 13)
        }
    } else if exponent == 0x1f {
        sign | 0x7f80_0000 | (mantissa << 13)
    } else {
        sign | ((exponent + 112) << 23) | (mantissa << 13)
    };

    f32::from_bits(float_bits)
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_bit_hamming_distance(
    bytes: u32,
    ax: *mut u8,
    bx: *mut u8,
    distance: u64,
) -> u64 {
    let mut total = distance;

    for i in 0..(bytes as usize) {
        let a = *ax.add(i);
        let b = *bx.add(i);
        total += (a ^ b).count_ones() as u64;
    }

    total
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_bit_jaccard_distance(
    bytes: u32,
    ax: *mut u8,
    bx: *mut u8,
    ab: u64,
    aa: u64,
    bb: u64,
) -> f64 {
    let mut count_ab = ab;
    let mut count_aa = aa;
    let mut count_bb = bb;

    for i in 0..(bytes as usize) {
        let a = *ax.add(i);
        let b = *bx.add(i);

        count_ab += (a & b).count_ones() as u64;
        count_aa += a.count_ones() as u64;
        count_bb += b.count_ones() as u64;
    }

    if count_ab == 0 {
        1.0
    } else {
        1.0 - (count_ab as f64 / (count_aa + count_bb - count_ab) as f64)
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_half_l2_squared_distance(
    dim: i32,
    ax: *const c_void,
    bx: *const c_void,
) -> f32 {
    let mut distance = 0.0f32;

    for i in 0..(dim as usize) {
        let a = half_bits_to_f32(read_half_bits(ax, i));
        let b = half_bits_to_f32(read_half_bits(bx, i));
        let diff = a - b;
        distance += diff * diff;
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_half_inner_product(
    dim: i32,
    ax: *const c_void,
    bx: *const c_void,
) -> f32 {
    let mut distance = 0.0f32;

    for i in 0..(dim as usize) {
        let a = half_bits_to_f32(read_half_bits(ax, i));
        let b = half_bits_to_f32(read_half_bits(bx, i));
        distance += a * b;
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_half_cosine_similarity(
    dim: i32,
    ax: *const c_void,
    bx: *const c_void,
) -> f64 {
    let mut similarity = 0.0f32;
    let mut norm_a = 0.0f32;
    let mut norm_b = 0.0f32;

    for i in 0..(dim as usize) {
        let a = half_bits_to_f32(read_half_bits(ax, i));
        let b = half_bits_to_f32(read_half_bits(bx, i));

        similarity += a * b;
        norm_a += a * a;
        norm_b += b * b;
    }

    similarity as f64 / ((norm_a as f64) * (norm_b as f64)).sqrt()
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_half_l1_distance(
    dim: i32,
    ax: *const c_void,
    bx: *const c_void,
) -> f32 {
    let mut distance = 0.0f32;

    for i in 0..(dim as usize) {
        let a = half_bits_to_f32(read_half_bits(ax, i));
        let b = half_bits_to_f32(read_half_bits(bx, i));
        distance += (a - b).abs();
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_l2_squared_distance(
    dim: i32,
    ax: *const f32,
    bx: *const f32,
) -> f32 {
    let mut distance = 0.0f32;

    for i in 0..(dim as usize) {
        let a = *ax.add(i);
        let b = *bx.add(i);
        let diff = a - b;
        distance += diff * diff;
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_inner_product(
    dim: i32,
    ax: *const f32,
    bx: *const f32,
) -> f32 {
    let mut distance = 0.0f32;

    for i in 0..(dim as usize) {
        let a = *ax.add(i);
        let b = *bx.add(i);
        distance += a * b;
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_cosine_similarity(
    dim: i32,
    ax: *const f32,
    bx: *const f32,
) -> f64 {
    let mut similarity = 0.0f32;
    let mut norm_a = 0.0f32;
    let mut norm_b = 0.0f32;

    for i in 0..(dim as usize) {
        let a = *ax.add(i);
        let b = *bx.add(i);

        similarity += a * b;
        norm_a += a * a;
        norm_b += b * b;
    }

    similarity as f64 / ((norm_a as f64) * (norm_b as f64)).sqrt()
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_l1_distance(
    dim: i32,
    ax: *const f32,
    bx: *const f32,
) -> f32 {
    let mut distance = 0.0f32;

    for i in 0..(dim as usize) {
        let a = *ax.add(i);
        let b = *bx.add(i);
        distance += (a - b).abs();
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_add(
    dim: i32,
    ax: *const f32,
    bx: *const f32,
    rx: *mut f32,
) {
    for i in 0..(dim as usize) {
        *rx.add(i) = *ax.add(i) + *bx.add(i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_sub(
    dim: i32,
    ax: *const f32,
    bx: *const f32,
    rx: *mut f32,
) {
    for i in 0..(dim as usize) {
        *rx.add(i) = *ax.add(i) - *bx.add(i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_mul(
    dim: i32,
    ax: *const f32,
    bx: *const f32,
    rx: *mut f32,
) {
    for i in 0..(dim as usize) {
        *rx.add(i) = *ax.add(i) * *bx.add(i);
    }
}
