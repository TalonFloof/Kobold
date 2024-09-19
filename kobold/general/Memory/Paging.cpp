#include "Paging.hpp"
#include "../arch/IArchitecture.hpp"

using namespace Kobold;
using namespace Kobold::Memory;

namespace Kobold::Memory {
    usize AddressSpace::MapPage(usize vaddr, PageTableEntry entry) {
        usize* entries = this->pointer;
        for(int i=0; i < 4; i++) {
            //const index: u64 = (vaddr >> (39 - @as(u6, @intCast(i * 9)))) & 0x1ff;
            u64 index = (vaddr >> (39 - (i * 9))) & 0x1ff;
            PageTableEntry pte = Architecture::ArchPTEToPage(entries[index]);
            if (i + 1 >= 4) {
                entries[index] = Architecture::PageToArchPTE(entry);
            } else {
                if(entries[index].valid == 0) {

                } else {
                    entries = (usize*)((pte.pageFrame << 12) + 0xffff800000000000);
                }
            }
        }
    }

    PageTableEntry AddressSpace::GetPage(usize vaddr) {
        
    }
}