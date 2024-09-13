.section .text

.global _start
_start:
  la      sp, __rv64_init_stack_top

  la      t0, rv64_boot_page_table
  srli    t0, t0, 12
  li      t1, 9 << 60
  or      t0, t0, t1
  csrw    satp, t0
  sfence.vma

  call KernelInitialize

.section .bss
.align 12
__rv64_init_stack_bottom:
   .space 8192
__rv64_init_stack_top:
.section .data
.align 12 # Make sure the entries are aligned
rv64_boot_page_table:
  .quad (0x0 << 37) | 0xcf # VRWXAD
  .zero 8 * 255
  .quad (0x0 << 37) | 0xcf # VRWXAD
  .zero 8 * 255