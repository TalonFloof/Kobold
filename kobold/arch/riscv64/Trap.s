.extern KTrap
.global _intHandler
.align 4
_intHandler:
    csrrw sp, sscratch, sp // SP -> Kernel Stack, SScratch -> User Stack
    addi sp, sp, -8 * 32
    sd ra,  8 * 0(sp)
    sd gp,  8 * 1(sp)
    sd tp,  8 * 2(sp)
    sd t0,  8 * 3(sp)
    sd t1,  8 * 4(sp)
    sd t2,  8 * 5(sp)
    sd t3,  8 * 6(sp)
    sd t4,  8 * 7(sp)
    sd t5,  8 * 8(sp)
    sd t6,  8 * 9(sp)
    sd a0,  8 * 10(sp)
    sd a1,  8 * 11(sp)
    sd a2,  8 * 12(sp)
    sd a3,  8 * 13(sp)
    sd a4,  8 * 14(sp)
    sd a5,  8 * 15(sp)
    sd a6,  8 * 16(sp)
    sd a7,  8 * 17(sp)
    sd s0,  8 * 18(sp)
    sd s1,  8 * 19(sp)
    sd s2,  8 * 20(sp)
    sd s3,  8 * 21(sp)
    sd s4,  8 * 22(sp)
    sd s5,  8 * 23(sp)
    sd s6,  8 * 24(sp)
    sd s7,  8 * 25(sp)
    sd s8,  8 * 26(sp)
    sd s9,  8 * 27(sp)
    sd s10, 8 * 28(sp)
    sd s11, 8 * 29(sp)

    csrr a0, sepc
    sd a0, 8 * 31(sp)

    csrr a0, sscratch // a0 -> User Stack
    sd a0, 8 * 30(sp)

    addi a0, sp, 8 * 32 // SScratch -> Kernel Stack
    csrw sscratch, a0

    mv a0, sp
    call KTrap
trap_exit:
    ld a1, 8 * 31(a0)
    csrw sepc, a1

    ld ra,  8 * 0(a0)
    ld gp,  8 * 1(a0)
    ld tp,  8 * 2(a0)
    ld t0,  8 * 3(a0)
    ld t1,  8 * 4(a0)
    ld t2,  8 * 5(a0)
    ld t3,  8 * 6(a0)
    ld t4,  8 * 7(a0)
    ld t5,  8 * 8(a0)
    ld t6,  8 * 9(a0)
    // a0 would go here
    ld a1,  8 * 11(a0)
    ld a2,  8 * 12(a0)
    ld a3,  8 * 13(a0)
    ld a4,  8 * 14(a0)
    ld a5,  8 * 15(a0)
    ld a6,  8 * 16(a0)
    ld a7,  8 * 17(a0)
    ld s0,  8 * 18(a0)
    ld s1,  8 * 19(a0)
    ld s2,  8 * 20(a0)
    ld s3,  8 * 21(a0)
    ld s4,  8 * 22(a0)
    ld s5,  8 * 23(a0)
    ld s6,  8 * 24(a0)
    ld s7,  8 * 25(a0)
    ld s8,  8 * 26(a0)
    ld s9,  8 * 27(a0)
    ld s10, 8 * 28(a0)
    ld s11, 8 * 29(a0)
    ld sp, 8 * 30(a0)
    fence

    ld a0,  8 * 10(a0)
    sret
    nop

    j . // Should never reach here, but leave this as a safety check
    nop