OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)

ENTRY(_start)

PHDRS
{
    null    PT_NULL    FLAGS(0) ;
    text    PT_LOAD    FLAGS((1 << 0) | (1 << 2)) ;
    rodata  PT_LOAD    FLAGS(1 << 2) ;
    data    PT_LOAD    FLAGS((1 << 1) | (1 << 2)) ;
}

SECTIONS
{
    . = 0xffffffff80000000;

    _TEXT_START_ = .;
    .text : {
        *(.text .text.* .ltext .ltext.*)
    } : text

    . += CONSTANT(MAXPAGESIZE);
    _TEXT_END_ = .;

    _RODATA_START_ = .;
    .rodata : {
        *(.rodata .rodata.* .lrodata .lrodata.*)
    } : rodata

    . += CONSTANT(MAXPAGESIZE);
    _RODATA_END_ = .;

    _DATA_START_ = .;
    .data : {
        *(.data .data.* .ldata .ldata.*)
    } : data
    _DATA_END_ = .;

    _BSS_START_ = .;
    .bss : {
        *(COMMON)
        *(.bss .bss.* .lbss .lbss.*)
    } : data
    _BSS_END_ = .;
}