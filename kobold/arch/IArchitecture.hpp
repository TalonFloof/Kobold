#pragma once
#include "../general/Common.hpp"

namespace Kobold {
    namespace Architecture {
        enum IntAction {
            DISABLE_INTERRUPTS,
            ENABLE_INTERRUPTS,
            YIELD_UNTIL_INTERRUPT,
        };

        void InterruptControl(IntAction action);
        void Log(const char* s, size_t l);
        void EarlyInitialize();
        void Initialize();

        int GetHartID();
        
    }
}