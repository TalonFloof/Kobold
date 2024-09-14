#pragma once
#include <stdint.h>
#include <stdarg.h>
#include <stddef.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef uintptr_t usize;
typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;
typedef intptr_t isize;

#include "DeviceTree/smoldtb.hpp"
#ifdef _COMMON_INSTANCE
#include "../arch/IArchitecture.hpp"
#include "Logging.hpp"

using namespace Kobold::Architecture;

[[noreturn]] void Panic(const char* reason) {
    Kobold::Logging::Log("panic (hart %x) %s", 0, reason);
    InterruptControl(IntAction::DISABLE_INTERRUPTS);
    while(1)
        InterruptControl(IntAction::YIELD_UNTIL_INTERRUPT);
}

dtb_ops DeviceTreeOps;
#else
[[noreturn]] void Panic(const char* reason);
extern "C" dtb_ops DeviceTreeOps;
#endif