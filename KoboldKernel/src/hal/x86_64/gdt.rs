use x86_64::registers::segmentation::{Segment, CS, SS};
use x86_64::structures::gdt::SegmentSelector;
use x86_64::structures::DescriptorTablePointer;
use x86_64::addr::VirtAddr;
use x86_64::PrivilegeLevel;

pub static mut GDT_ENTRIES: [u64; 16] = [
    0x0000000000000000, // 0x00: NULL
    0x00009a000000ffff, // 0x08: LIMINE 16-BIT KCODE
    0x000092000000ffff, // 0x10: LIMINE 16-BIT KDATA
    0x00cf9a000000ffff, // 0x18: LIMINE 32-BIT KCODE
    0x00cf92000000ffff, // 0x20: LIMINE 32-BIT KDATA
    0x00209A0000000000, // 0x28: 64-BIT KCODE
    0x0000920000000000, // 0x30: 64-BIT KDATA
    0x0000F20000000000, // 0x3B: 64-BIT UDATA
    0x0020FA0000000000, // 0x43: 64-BIT UCODE
    0x0000E90000000067, // 0x48 TSS
    0,
    0,
    0,
    0,
    0,
    0,
];

#[allow(static_mut_refs, unsafe_op_in_unsafe_fn)]
pub unsafe fn init() {
    use x86_64::instructions::tables::lgdt;
    let ptr = DescriptorTablePointer {
        base: VirtAddr::new(GDT_ENTRIES.as_ptr() as u64),
        limit: (16 * size_of::<u64>() - 1) as u16,
    };
    lgdt(&ptr);
    CS::set_reg(SegmentSelector::new(5,PrivilegeLevel::Ring0));
    SS::set_reg(SegmentSelector::new(6,PrivilegeLevel::Ring0));
}