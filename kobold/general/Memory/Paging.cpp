#define _PAGING_IMPL
#include "Paging.hpp"
#include "../../arch/IArchitecture.hpp"
#include "PFN.hpp"
#include "../Memory.hpp"

#include "../Logging.hpp"

using namespace Kobold;
using namespace Kobold::Memory;

namespace Kobold::Memory {
    AddressSpace initialAddr = {0};

    AddressSpace CreateAddressSpace(usize vaddr) {
        if(!ChangeType((void*)vaddr,PFN_PAGEDIR)) {
            return {0};
        }
        AddressSpace as = {(usize*)vaddr};
        for(int i=256; i < 512; i++) {
            as.pointer[i] = initialAddr.pointer[i];
        }
        return as;
    }

    usize AddressSpace::MapPage(usize vaddr, PageTableEntry entry) {
        usize* entries = this->pointer;
        for(int i=0; i < 4; i++) {
            u64 index = (vaddr >> (39 - (i * 9))) & 0x1ff;
            PageTableEntry pte = Architecture::ArchPTEToPage(entries[index]);
            if (i + 1 >= 4) {
                entries[index] = Architecture::PageToArchPTE(entry);
                Architecture::InvalidatePage(vaddr);
                if(pte.valid == 0 && entry.valid != 0) {
                    ReferencePage((void*)((usize)entries - 0xffff800000000000));
                } else if(pte.valid == 1 && entry.valid == 0) {
                    DereferencePage((void*)((usize)entries - 0xffff800000000000));
                }
                return (usize)&entries[index];
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
                    entries[index] = Architecture::PageToArchPTE(pte);
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

    void derefPageLevel(usize* ptr, int level) {
        for(int i=0; i < 512; i++) {
            if(level == 0 && i >= 256) {
                break;
            } else if(level + 1 >= 4) {
                PageTableEntry pte = Architecture::ArchPTEToPage(ptr[i]);
                if(pte.valid != 0) {
                    // const addr = @as(usize, @intCast(pte.phys)) << 12;
                    usize addr = pte.pageFrame << 12;
                    DereferencePage((void*)addr);
                    ptr[i] = 0;
                    DereferencePage((void*)ptr);
                }
            } else {
                PageTableEntry pte = Architecture::ArchPTEToPage(ptr[i]);
                if(pte.valid != 0) {
                    derefPageLevel((usize*)(pte.pageFrame << 12), level + 1);
                }
            }
        }
    }

    void AddressSpace::Destroy() {
        derefPageLevel(this->pointer, 0);
        ForceFreePage(this->pointer);
    }
}