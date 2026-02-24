use std::ffi::{c_char, c_double, c_void};

static RUST_BRIDGE_VERSION: &[u8] = b"rust-bridge-v1\0";
static IVFFLAT_HANDLER_PROBE_VERSION: &[u8] = b"rust-ivfflat-handler-v1\0";
static HNSW_HANDLER_PROBE_VERSION: &[u8] = b"rust-hnsw-handler-v1\0";

unsafe extern "C" {
    fn vector_c_float4_to_half_bits(value: f32) -> u16;
}

#[no_mangle]
pub extern "C" fn vector_rust_init() {}

#[no_mangle]
pub extern "C" fn vector_rust_bridge_version_cstr() -> *const c_char {
    RUST_BRIDGE_VERSION.as_ptr().cast()
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_handler_probe_cstr() -> *const c_char {
    IVFFLAT_HANDLER_PROBE_VERSION.as_ptr().cast()
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_handler_probe_cstr() -> *const c_char {
    HNSW_HANDLER_PROBE_VERSION.as_ptr().cast()
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_reject_closer_neighbor_kernel(
    distance: c_double,
    candidate_distance: c_double,
) -> bool {
    distance <= candidate_distance
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_can_add_duplicate_heap_tid_kernel(
    heaptids_length: i32,
    max_heaptids: i32,
) -> bool {
    heaptids_length < max_heaptids
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_select_neighbors_early_return_kernel(
    candidate_count: i32,
    max_neighbors: i32,
) -> bool {
    candidate_count <= max_neighbors
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_repair_underfilled_layer0_kernel(
    last_item_valid: bool,
) -> bool {
    !last_item_valid
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_flush_graph_kernel(
    memory_used: i64,
    memory_total: i64,
) -> bool {
    memory_used >= memory_total
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_use_ondisk_phase_kernel(
    graph_flushed: bool,
) -> bool {
    graph_flushed
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_add_search_candidate_kernel(
    candidate_distance: c_double,
    frontier_distance: c_double,
    always_add: bool,
) -> bool {
    candidate_distance < frontier_distance || always_add
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_stop_search_layer_kernel(
    candidate_distance: c_double,
    frontier_distance: c_double,
) -> bool {
    candidate_distance > frontier_distance
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_append_neighbor_without_prune_kernel(
    neighbors_length: i32,
    max_neighbors: i32,
) -> bool {
    neighbors_length < max_neighbors
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_skip_lower_level_candidate_kernel(
    candidate_level: i32,
    search_level: i32,
) -> bool {
    candidate_level < search_level
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_keep_pruned_connection_kernel(
    wdoff: i32,
    wdlen: i32,
    result_length: i32,
    max_neighbors: i32,
) -> bool {
    wdoff < wdlen && result_length < max_neighbors
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_set_pruned_from_array_kernel(
    wdoff: i32,
    wdlen: i32,
) -> bool {
    wdoff < wdlen
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_track_discarded_candidates_kernel(
    has_discarded_heap: bool,
) -> bool {
    has_discarded_heap
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_track_update_index_kernel(
    has_update_index_pointer: bool,
) -> bool {
    has_update_index_pointer
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_process_pruned_candidate_kernel(
    has_pruned_candidate: bool,
) -> bool {
    has_pruned_candidate
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_trim_candidate_list_kernel(
    candidate_count: i32,
    ef: i32,
) -> bool {
    candidate_count > ef
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_always_add_candidate_kernel(
    candidate_count: i32,
    ef: i32,
) -> bool {
    candidate_count < ef
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_update_entry_point_kernel(
    entry_point_is_null: bool,
    element_level: i32,
    entry_level: i32,
) -> bool {
    entry_point_is_null || element_level > entry_level
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_flush_pages_in_build_kernel(
    graph_flushed: bool,
) -> bool {
    !graph_flushed
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_disable_without_order_kernel(
    orderby_count: i32,
) -> bool {
    orderby_count == 0
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_clamp_ratio_kernel(ratio: c_double) -> c_double {
    if ratio > 1.0 { 1.0 } else { ratio }
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_adjust_startup_cost_kernel(
    startup_pages: c_double,
    rel_pages: c_double,
    ratio: c_double,
) -> bool {
    startup_pages > rel_pages && ratio < 0.5
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_return_empty_without_entrypoint_kernel(
    entry_point_is_null: bool,
) -> bool {
    entry_point_is_null
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_resume_from_discarded_kernel(
    discarded_is_empty: bool,
) -> bool {
    !discarded_is_empty
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_return_remaining_discarded_kernel(
    discarded_is_empty: bool,
) -> bool {
    !discarded_is_empty
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_skip_strict_out_of_order_kernel(
    iterative_scan_mode: i32,
    distance: c_double,
    previous_distance: c_double,
) -> bool {
    iterative_scan_mode == 2 && distance < previous_distance
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_stop_without_discarded_kernel(
    discarded_is_null: bool,
) -> bool {
    discarded_is_null
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_stop_when_iterative_scan_off_kernel(
    iterative_scan_mode: i32,
) -> bool {
    iterative_scan_mode == 0
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_limit_scan_by_resources_kernel(
    tuple_count: i64,
    max_scan_tuples: i64,
    memory_used: i64,
    max_memory: i64,
) -> bool {
    tuple_count >= max_scan_tuples || memory_used > max_memory
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_release_iterative_scan_memory_kernel(
    iterative_scan_mode: i32,
) -> bool {
    iterative_scan_mode != 0
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_update_previous_distance_kernel(
    iterative_scan_mode: i32,
) -> bool {
    iterative_scan_mode == 2
}

#[no_mangle]
pub extern "C" fn vector_rust_hnsw_should_flush_graph_pages_at_end_kernel(
    graph_flushed: bool,
) -> bool {
    !graph_flushed
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_adjust_cost_kernel(
    index_total_cost: c_double,
    num_index_pages: c_double,
    random_page_cost: c_double,
    seq_page_cost: c_double,
    ratio: c_double,
    rel_pages: c_double,
    sequential_ratio: c_double,
    adjusted_total_cost: *mut c_double,
    adjusted_startup_cost: *mut c_double,
) {
    let total = index_total_cost - sequential_ratio * num_index_pages * (random_page_cost - seq_page_cost);
    let mut startup = total * ratio;
    let startup_pages = num_index_pages * ratio;

    if startup_pages > rel_pages && ratio < 0.5 {
        startup -= (1.0 - sequential_ratio) * startup_pages * (random_page_cost - seq_page_cost);
        startup -= (startup_pages - rel_pages) * seq_page_cost;
    }

    *adjusted_total_cost = total;
    *adjusted_startup_cost = startup;
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_probe_ratio_kernel(probes: i32, lists: i32) -> c_double {
    let mut ratio = probes as c_double / lists as c_double;

    if ratio > 1.0 {
        ratio = 1.0;
    }

    ratio
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_disable_without_order_kernel(
    orderby_count: i32,
) -> bool {
    orderby_count == 0
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_choose_insert_candidate_kernel(
    distance: c_double,
    min_distance: c_double,
    insert_page_is_valid: bool,
) -> bool {
    distance < min_distance || !insert_page_is_valid
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_choose_scan_list_candidate_kernel(
    distance: c_double,
    list_count: i32,
    max_probes: i32,
    max_distance: c_double,
) -> bool {
    list_count < max_probes || distance < max_distance
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_scan_next_list_kernel(
    list_index: i32,
    max_probes: i32,
    batch_probes: i32,
    probes: i32,
) -> bool {
    list_index < max_probes && (batch_probes + 1) <= probes
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_choose_build_center_candidate_kernel(
    distance: c_double,
    min_distance: c_double,
) -> bool {
    distance < min_distance
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_append_page_kernel(
    free_space: i32,
    item_size: i32,
) -> bool {
    free_space < item_size
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_follow_insert_page_link_kernel(
    insert_page: i32,
) -> bool {
    insert_page != -1
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_set_insert_page_kernel(
    ndeletable: i32,
    insert_page_is_valid: bool,
) -> bool {
    !insert_page_is_valid && ndeletable > 0
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_update_insert_page_kernel(
    insert_page: i32,
    original_insert_page: i32,
) -> bool {
    insert_page != original_insert_page
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_allow_insert_page_after_original_kernel(
    insert_page: i32,
    original_insert_page: i32,
) -> bool {
    original_insert_page == -1 || insert_page >= original_insert_page
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_reuse_scan_slot_kernel(
    list_count: i32,
    max_probes: i32,
) -> bool {
    list_count >= max_probes
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_scan_probe_limits_kernel(
    probes: i32,
    max_probes: i32,
    lists: i32,
    adjusted_probes: *mut i32,
    adjusted_max_probes: *mut i32,
) {
    let clamped_probes = if probes > lists { lists } else { probes };
    let clamped_max_probes = if max_probes > lists { lists } else { max_probes };

    *adjusted_probes = clamped_probes;
    *adjusted_max_probes = clamped_max_probes;
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_compute_scan_limits_kernel(
    probes: i32,
    max_probes: i32,
    lists: i32,
    iterative_scan_mode: i32,
    adjusted_probes: *mut i32,
    adjusted_max_probes: *mut i32,
) {
    let computed_max_probes = if iterative_scan_mode != 0 {
        if max_probes > probes {
            max_probes
        } else {
            probes
        }
    } else {
        probes
    };
    let clamped_probes = if probes > lists { lists } else { probes };
    let clamped_max_probes = if computed_max_probes > lists {
        lists
    } else {
        computed_max_probes
    };

    *adjusted_probes = clamped_probes;
    *adjusted_max_probes = clamped_max_probes;
}

#[no_mangle]
pub extern "C" fn vector_rust_ivfflat_should_load_more_scan_items_kernel(
    list_index: i32,
    max_probes: i32,
) -> bool {
    list_index < max_probes
}

#[inline]
unsafe fn read_half_bits(base: *const c_void, idx: usize) -> u16 {
    let ptr = (base as *const u8).add(idx * 2) as *const u16;
    std::ptr::read_unaligned(ptr)
}

#[inline]
unsafe fn write_half_bits(base: *mut c_void, idx: usize, bits: u16) {
    let ptr = (base as *mut u8).add(idx * 2) as *mut u16;
    std::ptr::write_unaligned(ptr, bits);
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

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_concat(
    adim: i32,
    ax: *const f32,
    bdim: i32,
    bx: *const f32,
    rx: *mut f32,
) {
    for i in 0..(adim as usize) {
        *rx.add(i) = *ax.add(i);
    }

    for i in 0..(bdim as usize) {
        *rx.add((adim as usize) + i) = *bx.add(i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_norm(dim: i32, ax: *const f32) -> f64 {
    let mut norm = 0.0f64;

    for i in 0..(dim as usize) {
        let a = *ax.add(i) as f64;
        norm += a * a;
    }

    norm.sqrt()
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_l2_normalize(dim: i32, ax: *const f32, rx: *mut f32) {
    let norm = vector_rust_vector_norm(dim, ax);

    if norm > 0.0 {
        for i in 0..(dim as usize) {
            *rx.add(i) = (*ax.add(i) as f64 / norm) as f32;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_binary_quantize(
    dim: i32,
    ax: *const f32,
    rx: *mut u8,
) {
    let mut i = 0usize;
    let dim = dim as usize;
    let count = (dim / 8) * 8;

    while i < count {
        let mut result_byte = 0u8;

        for j in 0..8 {
            result_byte |= ((*ax.add(i + j) > 0.0) as u8) << (7 - j);
        }

        *rx.add(i / 8) = result_byte;
        i += 8;
    }

    while i < dim {
        *rx.add(i / 8) |= ((*ax.add(i) > 0.0) as u8) << (7 - (i % 8));
        i += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_subvector(
    dim: i32,
    ax: *const f32,
    start_index: i32,
    rx: *mut f32,
) {
    let start = start_index as usize;

    for i in 0..(dim as usize) {
        *rx.add(i) = *ax.add(start + i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_cmp(
    adim: i32,
    ax: *const f32,
    bdim: i32,
    bx: *const f32,
) -> i32 {
    let dim = usize::min(adim as usize, bdim as usize);

    for i in 0..dim {
        let a = *ax.add(i);
        let b = *bx.add(i);

        if a < b {
            return -1;
        }

        if a > b {
            return 1;
        }
    }

    if adim < bdim {
        -1
    } else if adim > bdim {
        1
    } else {
        0
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_copy_f64(dim: i32, src: *const c_double, dst: *mut c_double) {
    for i in 0..(dim as usize) {
        *dst.add(i) = *src.add(i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_accum_init(dim: i32, x: *const f32, dst: *mut c_double) {
    for i in 0..(dim as usize) {
        *dst.add(i) = *x.add(i) as c_double;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_accum_add(
    dim: i32,
    state: *const c_double,
    x: *const f32,
    dst: *mut c_double,
) {
    for i in 0..(dim as usize) {
        *dst.add(i) = *state.add(i) + (*x.add(i) as c_double);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_combine_add(
    dim: i32,
    a: *const c_double,
    b: *const c_double,
    dst: *mut c_double,
) {
    for i in 0..(dim as usize) {
        *dst.add(i) = *a.add(i) + *b.add(i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_avg(
    dim: i32,
    state: *const c_double,
    n: c_double,
    dst: *mut f32,
) {
    for i in 0..(dim as usize) {
        *dst.add(i) = (*state.add(i) / n) as f32;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_to_vector(dim: i32, ax: *const c_void, rx: *mut f32) {
    for i in 0..(dim as usize) {
        *rx.add(i) = half_bits_to_f32(read_half_bits(ax, i));
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_to_halfvec_kernel(dim: i32, ax: *const f32, rx: *mut c_void) {
    for i in 0..(dim as usize) {
        write_half_bits(rx, i, vector_c_float4_to_half_bits(*ax.add(i)));
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparse_to_halfvec_kernel(
    nnz: i32,
    indices: *const i32,
    values: *const f32,
    rx: *mut c_void,
) {
    for i in 0..(nnz as usize) {
        let idx = *indices.add(i) as usize;
        write_half_bits(rx, idx, vector_c_float4_to_half_bits(*values.add(i)));
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparse_to_dense(
    nnz: i32,
    indices: *const i32,
    values: *const f32,
    rx: *mut f32,
) {
    for i in 0..(nnz as usize) {
        let idx = *indices.add(i) as usize;
        *rx.add(idx) = *values.add(i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_to_sparse_count_kernel(dim: i32, ax: *const f32) -> i32 {
    let mut nnz = 0i32;

    for i in 0..(dim as usize) {
        if *ax.add(i) != 0.0 {
            nnz += 1;
        }
    }

    nnz
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_vector_to_sparse_fill_kernel(
    dim: i32,
    ax: *const f32,
    indices: *mut i32,
    values: *mut f32,
) -> i32 {
    let mut j = 0i32;

    for i in 0..(dim as usize) {
        let value = *ax.add(i);

        if value != 0.0 {
            *indices.add(j as usize) = i as i32;
            *values.add(j as usize) = value;
            j += 1;
        }
    }

    j
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_to_sparse_count_kernel(dim: i32, ax: *const c_void) -> i32 {
    let mut nnz = 0i32;

    for i in 0..(dim as usize) {
        if (read_half_bits(ax, i) & 0x7fff) != 0 {
            nnz += 1;
        }
    }

    nnz
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_to_sparse_fill_kernel(
    dim: i32,
    ax: *const c_void,
    indices: *mut i32,
    values: *mut f32,
) -> i32 {
    let mut j = 0i32;

    for i in 0..(dim as usize) {
        let bits = read_half_bits(ax, i);

        if (bits & 0x7fff) != 0 {
            *indices.add(j as usize) = i as i32;
            *values.add(j as usize) = half_bits_to_f32(bits);
            j += 1;
        }
    }

    j
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_center_counts_kernel(
    sample_count: i32,
    closest_centers: *const i32,
    center_count: i32,
    counts: *mut i32,
) {
    for i in 0..(center_count as usize) {
        *counts.add(i) = 0;
    }

    for i in 0..(sample_count as usize) {
        let center = *closest_centers.add(i) as usize;
        *counts.add(center) += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_zero_agg_kernel(
    center_count: i32,
    dimensions: i32,
    agg: *mut f32,
) {
    for i in 0..((center_count as usize) * (dimensions as usize)) {
        *agg.add(i) = 0.0;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_finalize_center_kernel(
    dimensions: i32,
    agg: *mut f32,
    center_count: i32,
) {
    let center_count = center_count as f32;

    for i in 0..(dimensions as usize) {
        let mut value = *agg.add(i);

        if value.is_infinite() {
            value = if value > 0.0 { f32::MAX } else { -f32::MAX };
        }

        *agg.add(i) = value / center_count;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_all_finite_kernel(
    dimensions: i32,
    values: *const f32,
) -> bool {
    for i in 0..(dimensions as usize) {
        let value = *values.add(i);
        if value.is_nan() || value.is_infinite() {
            return false;
        }
    }

    true
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_vector_sum_center_kernel(
    dimensions: i32,
    center: *const f32,
    agg: *mut f32,
) {
    for i in 0..(dimensions as usize) {
        *agg.add(i) += *center.add(i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_bit_sum_center_kernel(
    dimensions: i32,
    bits: *const u8,
    agg: *mut f32,
) {
    for i in 0..(dimensions as usize) {
        let value = ((*bits.add(i / 8)) >> (7 - (i % 8))) & 0x01;
        *agg.add(i) += value as f32;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_vector_update_center_kernel(
    dimensions: i32,
    values: *const f32,
    output: *mut f32,
) {
    for i in 0..(dimensions as usize) {
        *output.add(i) = *values.add(i);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_bit_update_center_kernel(
    dimensions: i32,
    values: *const f32,
    output: *mut u8,
) {
    let dimensions = dimensions as usize;
    let byte_count = dimensions.div_ceil(8);

    for i in 0..byte_count {
        *output.add(i) = 0;
    }

    for i in 0..dimensions {
        if *values.add(i) > 0.5 {
            *output.add(i / 8) |= 1 << (7 - (i % 8));
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_halfvec_update_center_kernel(
    dimensions: i32,
    values: *const f32,
    output: *mut c_void,
) {
    for i in 0..(dimensions as usize) {
        write_half_bits(output, i, vector_c_float4_to_half_bits(*values.add(i)));
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_halfvec_sum_center_kernel(
    dimensions: i32,
    halfvec: *const c_void,
    agg: *mut f32,
) {
    for i in 0..(dimensions as usize) {
        *agg.add(i) += half_bits_to_f32(read_half_bits(halfvec, i));
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_adjust_lower_bounds_kernel(
    sample_count: i32,
    center_count: i32,
    lower_bounds: *mut f32,
    center_distances: *const f32,
) {
    let samples = sample_count as usize;
    let centers = center_count as usize;
    for sample in 0..samples {
        let row = lower_bounds.add(sample * centers);
        for center in 0..centers {
            let updated = *row.add(center) - *center_distances.add(center);
            *row.add(center) = if updated < 0.0 { 0.0 } else { updated };
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_adjust_upper_bounds_kernel(
    sample_count: i32,
    upper_bounds: *mut f32,
    closest_centers: *const i32,
    center_distances: *const f32,
) {
    for sample in 0..(sample_count as usize) {
        *upper_bounds.add(sample) += *center_distances.add(*closest_centers.add(sample) as usize);
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_init_bounds_kernel(
    sample_count: i32,
    center_count: i32,
    lower_bounds: *const f32,
    upper_bounds: *mut f32,
    closest_centers: *mut i32,
) {
    let samples = sample_count as usize;
    let centers = center_count as usize;
    for sample in 0..samples {
        let row = lower_bounds.add(sample * centers);
        let mut min_distance = f32::MAX;
        let mut closest_center = 0i32;
        for center in 0..centers {
            let distance = *row.add(center);
            if distance < min_distance {
                min_distance = distance;
                closest_center = center as i32;
            }
        }
        *upper_bounds.add(sample) = min_distance;
        *closest_centers.add(sample) = closest_center;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_ivfflat_compute_s_kernel(
    center_count: i32,
    halfcdist: *const f32,
    s: *mut f32,
) {
    let centers = center_count as usize;
    for center in 0..centers {
        let mut min_distance = f32::MAX;
        let row = halfcdist.add(center * centers);
        for other in 0..centers {
            if center == other {
                continue;
            }
            let distance = *row.add(other);
            if distance < min_distance {
                min_distance = distance;
            }
        }
        *s.add(center) = min_distance;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparsevec_l1_distance_kernel(
    annz: i32,
    aindices: *const i32,
    ax: *const f32,
    bnnz: i32,
    bindices: *const i32,
    bx: *const f32,
) -> f32 {
    let mut distance = 0.0f32;
    let mut bpos = 0usize;
    let annz = annz as usize;
    let bnnz = bnnz as usize;

    for i in 0..annz {
        let ai = *aindices.add(i);
        let mut bi = -1i32;

        for j in bpos..bnnz {
            bi = *bindices.add(j);

            if ai == bi {
                distance += (*ax.add(i) - *bx.add(j)).abs();
            } else if ai > bi {
                distance += (*bx.add(j)).abs();
            }

            if ai >= bi {
                bpos = j + 1;
            }

            if bi >= ai {
                break;
            }
        }

        if ai != bi {
            distance += (*ax.add(i)).abs();
        }
    }

    for j in bpos..bnnz {
        distance += (*bx.add(j)).abs();
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparsevec_l2_squared_distance_kernel(
    annz: i32,
    aindices: *const i32,
    ax: *const f32,
    bnnz: i32,
    bindices: *const i32,
    bx: *const f32,
) -> f32 {
    let mut distance = 0.0f32;
    let mut bpos = 0usize;
    let annz = annz as usize;
    let bnnz = bnnz as usize;

    for i in 0..annz {
        let ai = *aindices.add(i);
        let mut bi = -1i32;

        for j in bpos..bnnz {
            bi = *bindices.add(j);

            if ai == bi {
                let diff = *ax.add(i) - *bx.add(j);
                distance += diff * diff;
            } else if ai > bi {
                let b = *bx.add(j);
                distance += b * b;
            }

            if ai >= bi {
                bpos = j + 1;
            }

            if bi >= ai {
                break;
            }
        }

        if ai != bi {
            let a = *ax.add(i);
            distance += a * a;
        }
    }

    for j in bpos..bnnz {
        let b = *bx.add(j);
        distance += b * b;
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparsevec_inner_product_kernel(
    annz: i32,
    aindices: *const i32,
    ax: *const f32,
    bnnz: i32,
    bindices: *const i32,
    bx: *const f32,
) -> f32 {
    let mut distance = 0.0f32;
    let mut bpos = 0usize;
    let annz = annz as usize;
    let bnnz = bnnz as usize;

    for i in 0..annz {
        let ai = *aindices.add(i);

        for j in bpos..bnnz {
            let bi = *bindices.add(j);

            if ai == bi {
                distance += *ax.add(i) * *bx.add(j);
            }

            if ai >= bi {
                bpos = j + 1;
            }

            if bi >= ai {
                break;
            }
        }
    }

    distance
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparsevec_cosine_distance_kernel(
    annz: i32,
    aindices: *const i32,
    ax: *const f32,
    bnnz: i32,
    bindices: *const i32,
    bx: *const f32,
) -> f64 {
    let annz = annz as usize;
    let bnnz = bnnz as usize;
    let mut similarity = vector_rust_sparsevec_inner_product_kernel(
        annz as i32,
        aindices,
        ax,
        bnnz as i32,
        bindices,
        bx,
    ) as f64;
    let mut norma = 0.0f32;
    let mut normb = 0.0f32;

    for i in 0..annz {
        let a = *ax.add(i);
        norma += a * a;
    }

    for i in 0..bnnz {
        let b = *bx.add(i);
        normb += b * b;
    }

    similarity /= ((norma as f64) * (normb as f64)).sqrt();

    if similarity > 1.0 {
        similarity = 1.0;
    } else if similarity < -1.0 {
        similarity = -1.0;
    }

    1.0 - similarity
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparsevec_l2_norm_kernel(nnz: i32, ax: *const f32) -> f64 {
    let mut norm = 0.0f64;

    for i in 0..(nnz as usize) {
        let a = *ax.add(i) as f64;
        norm += a * a;
    }

    norm.sqrt()
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparsevec_l2_normalize_values_kernel(
    nnz: i32,
    ax: *const f32,
    norm: f64,
    rx: *mut f32,
) {
    if norm > 0.0 {
        for i in 0..(nnz as usize) {
            *rx.add(i) = (*ax.add(i) as f64 / norm) as f32;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_sparsevec_cmp_kernel(
    adim: i32,
    annz: i32,
    aindices: *const i32,
    ax: *const f32,
    bdim: i32,
    bnnz: i32,
    bindices: *const i32,
    bx: *const f32,
) -> i32 {
    let nnz = usize::min(annz as usize, bnnz as usize);

    for i in 0..nnz {
        let aidx = *aindices.add(i);
        let bidx = *bindices.add(i);
        let av = *ax.add(i);
        let bv = *bx.add(i);

        if aidx < bidx {
            return if av < 0.0 { -1 } else { 1 };
        }

        if aidx > bidx {
            return if bv < 0.0 { 1 } else { -1 };
        }

        if av < bv {
            return -1;
        }

        if av > bv {
            return 1;
        }
    }

    if annz < bnnz && *bindices.add(nnz) < adim {
        let bv = *bx.add(nnz);
        return if bv < 0.0 { 1 } else { -1 };
    }

    if annz > bnnz && *aindices.add(nnz) < bdim {
        let av = *ax.add(nnz);
        return if av < 0.0 { -1 } else { 1 };
    }

    if adim < bdim {
        -1
    } else if adim > bdim {
        1
    } else {
        0
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_add_kernel(
    dim: i32,
    ax: *const c_void,
    bx: *const c_void,
    rx: *mut f32,
) {
    for i in 0..(dim as usize) {
        let a = half_bits_to_f32(read_half_bits(ax, i));
        let b = half_bits_to_f32(read_half_bits(bx, i));
        *rx.add(i) = a + b;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_sub_kernel(
    dim: i32,
    ax: *const c_void,
    bx: *const c_void,
    rx: *mut f32,
) {
    for i in 0..(dim as usize) {
        let a = half_bits_to_f32(read_half_bits(ax, i));
        let b = half_bits_to_f32(read_half_bits(bx, i));
        *rx.add(i) = a - b;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_mul_kernel(
    dim: i32,
    ax: *const c_void,
    bx: *const c_void,
    rx: *mut f32,
) {
    for i in 0..(dim as usize) {
        let a = half_bits_to_f32(read_half_bits(ax, i));
        let b = half_bits_to_f32(read_half_bits(bx, i));
        *rx.add(i) = a * b;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_concat_kernel(
    adim: i32,
    ax: *const c_void,
    bdim: i32,
    bx: *const c_void,
    rx: *mut f32,
) {
    for i in 0..(adim as usize) {
        *rx.add(i) = half_bits_to_f32(read_half_bits(ax, i));
    }

    for i in 0..(bdim as usize) {
        *rx.add((adim as usize) + i) = half_bits_to_f32(read_half_bits(bx, i));
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_binary_quantize_kernel(
    dim: i32,
    ax: *const c_void,
    rx: *mut u8,
) {
    let dim = dim as usize;
    let byte_count = dim.div_ceil(8);

    for i in 0..byte_count {
        *rx.add(i) = 0;
    }

    for i in 0..dim {
        if half_bits_to_f32(read_half_bits(ax, i)) > 0.0 {
            *rx.add(i / 8) |= 1 << (7 - (i % 8));
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_subvector_kernel(
    dim: i32,
    ax: *const c_void,
    start_index: i32,
    rx: *mut c_void,
) {
    let start_index = start_index as usize;

    for i in 0..(dim as usize) {
        write_half_bits(rx, i, read_half_bits(ax, start_index + i));
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_l2_norm_kernel(dim: i32, ax: *const c_void) -> f64 {
    let mut norm = 0.0f64;

    for i in 0..(dim as usize) {
        let a = half_bits_to_f32(read_half_bits(ax, i)) as f64;
        norm += a * a;
    }

    norm.sqrt()
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_l2_normalize_kernel(
    dim: i32,
    ax: *const c_void,
    rx: *mut f32,
) {
    let norm = vector_rust_halfvec_l2_norm_kernel(dim, ax);

    if norm > 0.0 {
        for i in 0..(dim as usize) {
            *rx.add(i) = (half_bits_to_f32(read_half_bits(ax, i)) as f64 / norm) as f32;
        }
    } else {
        for i in 0..(dim as usize) {
            *rx.add(i) = 0.0;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_cmp_kernel(
    adim: i32,
    ax: *const c_void,
    bdim: i32,
    bx: *const c_void,
) -> i32 {
    let dim = usize::min(adim as usize, bdim as usize);

    for i in 0..dim {
        let a = half_bits_to_f32(read_half_bits(ax, i));
        let b = half_bits_to_f32(read_half_bits(bx, i));

        if a < b {
            return -1;
        }

        if a > b {
            return 1;
        }
    }

    if adim < bdim {
        -1
    } else if adim > bdim {
        1
    } else {
        0
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_accum_init_kernel(
    dim: i32,
    ax: *const c_void,
    dst: *mut c_double,
) {
    for i in 0..(dim as usize) {
        *dst.add(i) = half_bits_to_f32(read_half_bits(ax, i)) as c_double;
    }
}

#[no_mangle]
pub unsafe extern "C" fn vector_rust_halfvec_accum_add_kernel(
    dim: i32,
    state: *const c_double,
    ax: *const c_void,
    dst: *mut c_double,
) {
    for i in 0..(dim as usize) {
        *dst.add(i) = *state.add(i) + (half_bits_to_f32(read_half_bits(ax, i)) as c_double);
    }
}
