#[cfg(target_arch="x86_64")]
#[path = "x86_64/mod.rs"]
#[macro_use]
pub mod arch;

#[unsafe(no_mangle)]
extern "C" fn start_hal() {
    loop {}
}

pub trait HALArch {
    fn wait_for_int() {
        todo!("wait_for_int not implemented on this HAL Target!");
    }
    fn int_control(new_int: bool) -> bool {
        todo!("int_control not implemented on this HAL Target!");
    }
}