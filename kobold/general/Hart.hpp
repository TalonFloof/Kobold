#pragma once
#include "Common.hpp"

namespace Kobold {
    struct Hart {
        usize tempReg1;
        usize tempReg2;
        usize activeUserStack;
        usize activeSyscallStack;
        usize activeTrapStack;
        Thread* activeThread;
        void* kstackTop;
        usize reserved;
    };
}