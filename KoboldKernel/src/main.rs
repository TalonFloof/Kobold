#![no_std]
#![no_main]
#![feature(naked_functions)]

extern crate alloc;

pub mod hal;
pub mod scheme;
pub mod framebuffer;

use core::panic::PanicInfo;

fn main() {
    
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    loop {}
}