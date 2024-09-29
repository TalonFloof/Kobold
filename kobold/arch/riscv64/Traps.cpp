#include "Traps.hpp"
#include "../../general/Logging.hpp"
#include "CSR.hpp"
#include "../../general/DeviceTree/DevTree.hpp"
#include "SBI.hpp"

using namespace Kobold;

namespace Kobold::Architecture {
    extern int UseLegacyTimer;
}

extern "C" [[noreturn]] void KTrap(Architecture::Frame* frame) {
    usize reason = 0;
    ReadCSR(reason,scause);
    if(reason & (1ULL << 63ULL)) {
        usize intType = reason & ~(1ULL << 63ULL);
        if(intType == 0x5) {
            u64 base;
            ReadCSR(base,time);
            if(Architecture::UseLegacyTimer) {
                SBICallLegacy1(0,base+(DeviceTree::CpuSpeed / 100));
            } else {
                SBICall1(0x54494D45,0,base+(DeviceTree::CpuSpeed / 100));
            }
        }
    } else {
        Logging::Log("Supervisor Trap - Cause %x", reason);
        Architecture::PrintFrame(frame);
        Panic("RISC-V Supervisor Trap");
    }
    Architecture::EnterContext(frame);
}