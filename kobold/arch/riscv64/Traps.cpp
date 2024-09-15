#include "Traps.hpp"
#include "../../general/Logging.hpp"
#include "CSR.hpp"

using namespace Kobold;

extern "C" void KTrap(Architecture::Frame* frame) {
    usize reason = 0;
    ReadCSR(reason,scause);
    Logging::Log("Supervisor Trap - Cause %x", reason);
    Architecture::PrintFrame(frame);
    Panic("RISC-V Supervisor Trap");
}