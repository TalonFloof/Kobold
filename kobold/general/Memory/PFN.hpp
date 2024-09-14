#pragma once
#include "../Common.hpp"

namespace Kobold::Memory {
    struct PFNEntry {
        PFNEntry* next;
        u32 references : 28;
        u32 type : 4;
    };
}