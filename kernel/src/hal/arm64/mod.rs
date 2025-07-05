#[naked]
#[no_mangle]
extern "C" fn _entry() {
    unsafe {
        asm!(
            "ldr x5, =_stack",
            "mov sp, x5",
            "ldr x5, =__bss_start",
            "ldr w6, =__bss_size",
            options(noreturn)
        )
    }
}