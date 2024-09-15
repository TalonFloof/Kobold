#include "Traps.hpp"
#include "../../general/Logging.hpp"
#include "CSR.hpp"

using namespace Kobold;

extern "C" void KernelTrap() {
    usize reason, epc = 0;
    ReadCSR(reason,scause);
    ReadCSR(epc,sepc);
    Logging::Log("Supervisor Trap - Cause %x | PC %x", reason, epc);
    Panic("RISC-V Supervisor Trap");
}