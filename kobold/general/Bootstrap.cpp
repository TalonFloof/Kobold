#define _COMMON_INSTANCE
#include "Common.hpp"
#include "../arch/IArchitecture.hpp"
#include "Logging.hpp"
#include "DeviceTree/smoldtb.hpp"

using namespace Kobold;
using namespace Kobold::Architecture;

extern "C" [[noreturn]]
void KernelInitialize(int hartID, void* deviceTree) {
    DeviceTreeOps.on_error = Panic;
    EarlyInitialize();
    Logging::Log("KoboldKernel");
    Logging::Log("Copyright (C) 2024 TalonFloof, Licensed under GNU LGPLv3");
    Initialize(deviceTree);
    *((u32*)0x0) = 0;
    Panic("Booted Successfully");
}