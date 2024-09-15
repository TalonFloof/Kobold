#pragma once
#include "../Common.hpp"

#define PFN_RESERVED 0
#define PFN_FREE 1
#define PFN_ZERO 2
#define PFN_ACTIVE 3
#define PFN_PAGEDIR 4
#define PFN_PAGETABLE 5
#define PFN_TCB 6
#define PFN_SERVICE_CATEGORY 7

namespace Kobold::Memory {
    struct PFNEntry {
        PFNEntry* next;
        u32 references;
        u32 type : 5;
        u32 reserved : 27;

    };
}