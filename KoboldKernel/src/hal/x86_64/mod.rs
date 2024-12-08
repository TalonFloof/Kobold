use core::arch::naked_asm;

use crate::hal::HALArch;

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

}

const PRIVATE_INTERFACE: HALArchImpl = HALArchImpl {};
pub const INTERFACE: &dyn HALArch = &PRIVATE_INTERFACE;