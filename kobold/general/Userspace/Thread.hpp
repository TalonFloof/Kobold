#pragma once
#include "../Common.hpp"
#include "../../arch/IArchitecture.hpp"
#include "../Memory/Paging.hpp"

namespace Kobold::Userspace {
    struct Thread {
        Thread* prevQueue;
        Thread* nextQueue;
        Kobold::Memory::AddressSpace addrSpace;
        __attribute__((aligned(512))) Kobold::Architecture::Frame frame;
        __attribute__((aligned(1024))) u8 kstack[1024*3];
    };

}