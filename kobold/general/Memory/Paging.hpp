#pragma once
#include "../Common.hpp"

namespace Kobold::Memory {
    struct PageTableEntry {
        usize valid : 1;
        usize read : 1;
        usize write : 1;
        usize execute : 1;
        usize user : 1;
        usize noCache : 1;
        usize writeThru : 1;
        usize writeCombine : 1;
        usize reserved : 4;
        usize pageFrame : (64-12);
    };

    struct AddressSpace {
        usize* pointer;

        usize MapPage(usize vaddr, PageTableEntry entry);
        PageTableEntry GetPage(usize vaddr);
        void Destroy();
    };
    AddressSpace CreateAddressSpace(usize paddr);

    #ifndef _PAGING_IMPL
    extern AddressSpace initialAddr;
    #endif
}