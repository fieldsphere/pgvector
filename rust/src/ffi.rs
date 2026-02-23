use std::ffi::c_char;

static RUST_BRIDGE_VERSION: &[u8] = b"rust-bridge-v1\0";

#[no_mangle]
pub extern "C" fn vector_rust_init() {}

#[no_mangle]
pub extern "C" fn vector_rust_bridge_version_cstr() -> *const c_char {
    RUST_BRIDGE_VERSION.as_ptr().cast()
}
