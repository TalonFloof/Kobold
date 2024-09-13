#pragma once
#include "../arch/IArchitecture.hpp"

namespace Kobold::Logging {
    void Write(const char* __restrict format, va_list args);
    static inline void Log(const char* __restrict fmt, ...) {
        va_list args;
        va_start(args, fmt);
        Write(fmt, args);
        va_end(args);
        Architecture::Log("\n", 1);
    }
}