#include "Paging.hpp"
#include "../../arch/IArchitecture.hpp"
#include "PFN.hpp"

using namespace Kobold;
using namespace Kobold::Memory;

namespace Kobold::Memory {
    usize AddressSpace::MapPage(usize vaddr, PageTableEntry entry) {
        usize* entries = this->pointer;
        for(int i=0; i < 4; i++) {
            u64 index = (vaddr >> (39 - (i * 9))) & 0x1ff;
            PageTableEntry pte = Architecture::ArchPTEToPage(entries[index]);
            if (i + 1 >= 4) {
                entries[index] = Architecture::PageToArchPTE(entry);
                Architecture::InvalidatePage(((usize)entries - 0xffff800000000000));
                if(pte.valid == 0 && entry.valid != 0) {
                    DereferencePage((void*)((usize)entries - 0xffff800000000000));
                } else if(pte.valid == 1 && entry.valid == 0) {
                    ReferencePage((void*)((usize)entries - 0xffff800000000000));
                }
            } else {
                if(pte.valid == 0) {
                    if(entry.valid == 0) {
                        return 0;
                    }
                    void* page = AllocatePage(PFN_PAGETABLE,((usize)&entries[index]) - 0xffff800000000000);
                    pte.valid = 1;
                    pte.read = 0;
                    pte.write = 0;
                    pte.execute = 0;
                    pte.user = 1;
                    pte.noCache = 0;
                    pte.writeCombine = 0;
                    pte.writeThru = 0;
                    pte.pageFrame = ((((usize)page) - 0xffff800000000000) >> 12);
                    entries[index] = Architecture::PageToArchPTE(entry);
                    if(i > 0) {
                        ReferencePage((void*)((usize)entries - 0xffff800000000000));
                    }
                }
                entries = (usize*)((pte.pageFrame << 12) + 0xffff800000000000);
            }
        }
    }

    PageTableEntry AddressSpace::GetPage(usize vaddr) {
        usize* entries = this->pointer;
        for(int i=0; i < 4; i++) {
            u64 index = (vaddr >> (39 - (i * 9))) & 0x1ff;
            PageTableEntry pte = Architecture::ArchPTEToPage(entries[index]);
            if (i + 1 >= 4) {
                return pte;
            } else {
                if(pte.valid == 0) {
                    return {0,0,0,0,0,0,0,0,0,0};
                } else {
                    entries = (usize*)((pte.pageFrame << 12) + 0xffff800000000000);
                }
            }
        }
        __builtin_unreachable();
    }
}