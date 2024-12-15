#![no_std]
#![no_main]
#![feature(naked_functions)]

extern crate alloc;

pub mod hal;
pub mod allocator;
pub mod scheme;
pub mod framebuffer;
pub mod hart;

use core::panic::PanicInfo;

fn main() {
    
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    framebuffer::GetFramebuffer().Clear(0x0000ff);
    loop {}
}