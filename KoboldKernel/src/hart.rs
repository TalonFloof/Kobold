use crate::hal::arch::ArchHartData;

pub struct Hart {
    tempReg1: usize,
    tempReg2: usize,
    activeContextStack: usize,
    activeSyscallStack: usize,
    trapStack: usize,
    archData: ArchHartData,
    hartID: usize
}