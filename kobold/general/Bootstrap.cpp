#define _COMMON_INSTANCE
#include "Common.hpp"
#include "../arch/IArchitecture.hpp"
#include "Logging.hpp"
#include "DeviceTree/smoldtb.hpp"

#include "Memory/Paging.hpp"
#include "Memory/PFN.hpp"
#include "Userspace/Thread.hpp"

using namespace Kobold;
using namespace Kobold::Architecture;

extern "C" [[noreturn]]
void KernelInitialize(int hartID, void* deviceTree) {
    DeviceTreeOps.on_error = Panic;
    EarlyInitialize();
    if(sizeof(Userspace::Thread) != 4096) {
        Logging::Log("TCB Size was expected to be 4096, got %i", sizeof(Userspace::Thread));
        Panic("Assertion failed");
    }
    Logging::Log("KoboldKernel");
    Logging::Log("Copyright (C) 2024 TalonFloof, Licensed under GNU LGPLv3");
    Initialize(deviceTree);

    Panic("Booted Successfully");
}