OUTPUT_ARCH( "riscv" )
OUTPUT_FORMAT( "elf64-littleriscv" )
ENTRY( _start )

PHDRS
{
    null    PT_NULL    FLAGS(0) ;
    text    PT_LOAD    FLAGS((1 << 0) | (1 << 2)) ;
    rodata  PT_LOAD    FLAGS(1 << 2) ;
    data    PT_LOAD    FLAGS((1 << 1) | (1 << 2)) ;
}


SECTIONS
{
    . = 0x80200000;

    __KERNEL_BEGIN__ = .;

    .text : {
        KEEP(*(.text.boot))
        *(.text .text.*)
        __TEXT_END__ = .;
    } : text

    . = ALIGN(4096);

    .rodata : {
        *(.rodata .rodata.*)
        __RODATA_END__ = .;
    } : rodata

   . = ALIGN(4096);

    .data : {
        *(.data .data.*)
        __DATA_END__ = .;
    } : data

    .bss : {
        *(COMMON)
        *(.bss .bss.*)
        __BSS_END__ = .;
    } : data

    . = ALIGN(4096);

    __KERNEL_END__ = .;
}