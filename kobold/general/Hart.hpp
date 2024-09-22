#pragma once
#include "Common.hpp"

namespace Kobold {
    struct Hart {
        usize tempReg1; // +0
        usize tempReg2; // +8
        usize activeUserStack; // +16
        usize activeSyscallStack; // +24
        usize trapStack; // +32
        void* activeThread;
        usize reserved1;
        usize reserved2;
    };
}