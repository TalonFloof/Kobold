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

#define ALIGN_UP(s, a)      (((s) + ((a) - 1)) & ~((a) - 1))
#define ALIGN_DOWN(s, a)    ((s) & ~((a) - 1))
#define ALIGNED(s, a)       (!((s) & ((a) - 1)))

#include "DeviceTree/smoldtb.hpp"
#ifdef _COMMON_INSTANCE
#include "../arch/IArchitecture.hpp"
#include "Logging.hpp"

[[noreturn]] void Panic(const char* reason) {
    Kobold::Logging::Log("panic (hart %x) %s", 0, reason);
    Kobold::Architecture::IntControl(false);
    while(1)
        Kobold::Architecture::WaitForInt();
}

dtb_ops DeviceTreeOps;
#else
[[noreturn]] void Panic(const char* reason);
extern dtb_ops DeviceTreeOps;
#endif