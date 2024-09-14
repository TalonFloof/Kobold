#include "Traps.hpp"
#include "../../general/Logging.hpp"
#include "CSR.hpp"

using namespace Kobold;

extern "C" void KernelTrap() {
    int reason;
    ReadCSR(reason,scause);
    Logging::Log("Cause %x", reason);
    Panic("RISC-V Supervisor Trap");
}