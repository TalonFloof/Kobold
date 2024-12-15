#[cfg(target_arch="x86_64")]
#[path = "x86_64/mod.rs"]
#[macro_use]
pub mod arch;

use core::ffi::c_void;

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
    {
        let mut logo = include_bytes!("../../logo.bmap");
        let fb = crate::framebuffer::GetFramebuffer();
        fb.Clear(0);
        let (iw, ih) = crate::framebuffer::Framebuffer::GetImageSize(logo.as_ptr() as *const c_void);
        let scale = 1.5;
        fb.DrawScaledImage(logo.as_ptr() as *const c_void, (fb.width/2)-(((iw as f64*scale) as usize)/2), (fb.height/2)-(((ih as f64*scale) as usize)/2),(iw as f64*scale) as usize,(ih as f64*scale) as usize,0xffffff);
    }
    INTERFACE.init();
    loop {}
}