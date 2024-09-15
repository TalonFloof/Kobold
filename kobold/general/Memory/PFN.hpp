#pragma once
#include "../Common.hpp"
#include "../DeviceTree/smoldtb.hpp"

#define PFN_RESERVED 0
#define PFN_FREE 1
#define PFN_ZERO 2
#define PFN_ACTIVE 3
#define PFN_PAGEDIR 4
#define PFN_PAGETABLE 5
#define PFN_TCB 6
#define PFN_SERVICE_CATEGORY 7
#define PFN_KERNEL 512
#define PFN_PFN 513
#define PFN_DEVTREE 514

namespace Kobold::Memory {
    struct PFNEntry {
        PFNEntry* next;
        PFNEntry* prev; // Prev is reused as the reference count if not free
        u64 type : 12;
        u64 pageFrame : 52;

        inline usize GetReferences() {
            return (usize)(this->prev);
        }

        inline void SetReferences(usize r) {
            this->prev = (PFNEntry*)r;
        }
    };
    void Initialize(dtb_pair* ranges, size_t len);
}