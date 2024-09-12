#pragma once
#include "../general/Common.hpp"

namespace Kobold {
    namespace Architecture {
        typedef enum {
            DISABLE_INTERRUPTS,
            ENABLE_INTERRUPTS,
            YIELD_UNTIL_INTERRUPT,
        } IntAction;

        void InterruptControl(IntAction action);
        void Log(const char* s, size_t l);
        void Initialize();

        int GetHartID();
        
    }
}