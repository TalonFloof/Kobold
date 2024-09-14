.section .text.boot
.global _start

.option push
_start:
  # a0 = Hart ID
  # a1 = Device Tree Address
  li t2, 0xffff800000000000
  la sp, __rv64_init_stack_top-0xffff800000000000
  add sp, sp, t2

  la t0, rv64_boot_page_table-0xffff800000000000
  srli    t0, t0, 12
  li      t1, 9 << 60
  or      t0, t0, t1
  csrw    satp, t0
  sfence.vma

  la t0, KernelInitialize-0xffff800000000000
  add t0, t0, t2
  or ra, zero, zero
  add a1, a1, t2
  jr t0
.option pop

.align 12
__rv64_init_stack_bottom:
   .zero 4096
__rv64_init_stack_top:
.align 12 # Make sure the entries are aligned
rv64_boot_page_table:
  .quad (0x0 << 37) | 0xcf # VRWXAD
  .zero 8 * 255
  .quad (0x0 << 37) | 0xcf # VRWXAD
  .zero 8 * 255