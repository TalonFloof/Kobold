#![no_std]
#![no_main]
#![feature(naked_functions)]

pub mod hal;

use core::panic::PanicInfo;

fn main() {
    
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    loop {}
}