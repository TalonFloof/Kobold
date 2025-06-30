#[naked]
#[no_mangle]
extern "C" fn _entry() {
    unsafe {
        asm!(
            "cli",
            "mov rdi, rsp",
            "add rdi, 8",
            "call arch_hal_init",
            "nop",
            "2:",
            "hlt",
            "jmp 2b",
            options(noreturn)
        )
    }
}