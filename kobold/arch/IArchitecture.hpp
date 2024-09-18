#pragma once
#include <stdint.h>
#include <stdarg.h>
#include <stddef.h>
#include "../general/Memory/Paging.hpp"

namespace Kobold {
    namespace Architecture {
        void WaitForInt();
        bool IntControl(bool enable);
        void Log(const char* s, size_t l);
        void EarlyInitialize();
        void Initialize(void* deviceTree);

        int GetHartID();
        struct Frame;
        void PrintFrame(Frame* f);
        Kobold::Memory::PageTableEntry ArchPTEToPage(usize value);
        usize PageToArchPTE(Kobold::Memory::PageTableEntry value);
    }
}