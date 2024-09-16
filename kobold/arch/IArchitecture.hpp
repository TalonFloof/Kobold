#pragma once
#include "../general/Common.hpp"

namespace Kobold {
    namespace Architecture {
        inline void WaitForInt();
        bool IntControl(bool enable);
        void Log(const char* s, size_t l);
        void EarlyInitialize();
        void Initialize(void* deviceTree);

        int GetHartID();
        struct Frame;
        void PrintFrame(Frame* f);
    }
}