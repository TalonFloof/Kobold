#[cfg(target_arch="x86_64")]
#[path = "x86_64/mod.rs"]
#[macro_use]
pub mod arch;

use arch::INTERFACE;

pub trait HALArch: Sync + 'static {
    fn early_init(&self) {

    }
    fn init(&self) {
        
    }
    fn wait_for_int(&self) {
        todo!("wait_for_int not implemented on this HAL Target!");
    }
    fn int_control(&self, new_int: bool) -> bool {
        todo!("int_control not implemented on this HAL Target!");
    }
}

#[unsafe(no_mangle)]
extern "C" fn start_hal() {
    INTERFACE.early_init();
    INTERFACE.init();
    loop {}
}