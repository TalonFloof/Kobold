#![no_std] // don't link the Rust standard library
#![no_main] // disable all Rust-level entry points

// extern crate alloc;

pub mod hal;

use core::panic::PanicInfo;

/// This function is called on panic.
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}