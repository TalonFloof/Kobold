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
        void InvalidatePage(usize page);

        #ifdef _ARCH_RISCV64
        struct Frame {
            usize ra, gp, tp, t0, t1, t2, t3, t4, t5, t6, a0, a1, a2, a3, a4, a5, a6, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, sp, pc;
        };
        #else
        struct Frame;
        #endif
    }
}