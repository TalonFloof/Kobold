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
#define PFN_PFN 128

namespace Kobold::Memory {
    struct PFNEntry {
        PFNEntry* next;
        union {
            PFNEntry* prev;
            usize references;
        };
        usize pageEntry : 48; // Used on PFN_PAGETABLE to point to the entry on the page table
        usize reserved : 8;
        usize type : 8;
    };
    void Initialize(dtb_pair* ranges, size_t len);
    void* AllocatePage(int type, usize pte);
    void ReferencePage(void* page);
    void DereferencePage(void* page);
    void ForceFreePage(void* page);
}