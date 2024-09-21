#define _COMMON_INSTANCE
#include "Common.hpp"
#include "../arch/IArchitecture.hpp"
#include "Logging.hpp"
#include "DeviceTree/smoldtb.hpp"

#include "Memory/Paging.hpp"
#include "Memory/PFN.hpp"

using namespace Kobold;
using namespace Kobold::Architecture;

extern "C" [[noreturn]]
void KernelInitialize(int hartID, void* deviceTree) {
    DeviceTreeOps.on_error = Panic;
    EarlyInitialize();
    Logging::Log("KoboldKernel");
    Logging::Log("Copyright (C) 2024 TalonFloof, Licensed under GNU LGPLv3");
    Initialize(deviceTree);

    Panic("Booted Successfully");
}