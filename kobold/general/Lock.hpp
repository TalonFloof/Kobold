#pragma once
#include "Common.hpp"
#include "../arch/IArchitecture.hpp"

namespace Kobold::Sync {
    struct Lock {
        char atomic = 0;
        bool permitInterrupts = true;
        bool prevInt = false;

        void Acquire();
        void Release();
    };
}