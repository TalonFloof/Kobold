use core::arch::naked_asm;

use limine::request::FramebufferRequest;
use crate::hal::HALArch;

static FRAMEBUFFER: FramebufferRequest = FramebufferRequest::new();

#[naked]
#[unsafe(no_mangle)]
extern "C" fn _entry() {
	unsafe {
		naked_asm!(
			"cli",
			"mov rdi, rsp",
			"push rax",
			"mov rax, cr0",
			"and al, 0xfb",
			"or al, 0x22",
			"mov cr0, rax",
			"mov rax, cr4",
			"or rax, 0x600",
			"mov cr4, rax",
			"fninit",
			"pop rax",
			"add rdi, 8",
			"call start_hal",
			"nop",
			"cli",
			"hlt",
		);
	}
}

struct HALArchImpl {}

impl HALArch for HALArchImpl {
	fn early_init(&self) {
		if let Some(fb) = FRAMEBUFFER.get_response() {
			let f = fb.framebuffers().next().unwrap();
			let fbf = crate::framebuffer::GetFramebuffer();
			fbf.ptr = f.addr() as *mut u32;
			fbf.width = f.width() as usize;
			fbf.height = f.height() as usize;
			fbf.stride = f.pitch() as usize;
			fbf.bpp = f.bpp() as usize;
		}
	}
	fn init(&self) {

	}
}

static PRIVATE_INTERFACE: HALArchImpl = HALArchImpl {};
pub const INTERFACE: &dyn HALArch = &PRIVATE_INTERFACE;