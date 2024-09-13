#include "Common.hpp"
#include "../arch/IArchitecture.hpp"
#include "Logging.hpp"

using namespace Kobold;
using namespace Kobold::Architecture;

extern "C" [[noreturn]]
void KernelInitialize() {
    EarlyInitialize();
    Logging::Log("KoboldKernel");
    Logging::Log("Copyright (C) 2024 TalonFloof, Licensed under GNU LGPLv3");
    Initialize();
    InterruptControl(IntAction::DISABLE_INTERRUPTS);
    while(1)
        InterruptControl(IntAction::YIELD_UNTIL_INTERRUPT);
}