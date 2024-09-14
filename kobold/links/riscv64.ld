OUTPUT_ARCH( "riscv" )
OUTPUT_FORMAT( "elf64-littleriscv" )
ENTRY( _start )

PHDRS
{
    null    PT_NULL    FLAGS(0) ;
    boot    PT_LOAD    FLAGS((1 << 0) | (1 << 1) | (1 << 2)) ;
    text    PT_LOAD    FLAGS((1 << 0) | (1 << 2)) ;
    rodata  PT_LOAD    FLAGS(1 << 2) ;
    data    PT_LOAD    FLAGS((1 << 1) | (1 << 2)) ;
}


SECTIONS
{
    KERNEL_VMA = 0xFFFF800000000000;

    .text.boot (0x80200000) : AT(0x80200000) {
       KEEP(*(.text.boot))
    } : boot

    . = 0x80200000 + SIZEOF(.text.boot);
    . = ALIGN(4096);

    . += KERNEL_VMA;

    .text : AT(ADDR(.text) - KERNEL_VMA) {
        *(.text .text.*)
        __TEXT_END__ = .;
    } : text

    . = ALIGN(4096);

    .rodata : AT(ADDR(.rodata) - KERNEL_VMA) {
        *(.rodata .rodata.*)
        __RODATA_END__ = .;
    } : rodata

   . = ALIGN(4096);

    .data : AT(ADDR(.data) - KERNEL_VMA) {
        *(.data .data.*)
        __DATA_END__ = .;
    } : data

    .bss : AT(ADDR(.bss) - KERNEL_VMA) {
        *(COMMON)
        *(.bss .bss.*)
        __BSS_END__ = .;
    } : data

    . = ALIGN(4096);
}