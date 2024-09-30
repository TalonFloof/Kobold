#pragma once
#include "../Common.hpp"
#include "../../arch/IArchitecture.hpp"
#include "../Memory/Paging.hpp"

namespace Kobold::Userspace {
    enum ThreadStatus {
        NEW = 0,
        RUNNABLE,
        DEBUGGING,
        DYING,
    };

    struct Thread {
        Thread* prevQueue;
        Thread* nextQueue;
        Kobold::Memory::AddressSpace addrSpace;
        ThreadStatus status;
        __attribute__((aligned(256))) Kobold::Architecture::Frame frame;
       Kobold::Architecture::FloatFrame floatFrame;
        __attribute__((aligned(1024))) u8 kstack[1024*3];
    };

}