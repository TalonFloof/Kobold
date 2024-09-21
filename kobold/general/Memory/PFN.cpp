#include "PFN.hpp"
#include "../Common.hpp"
#include "../Logging.hpp"
#include "../Lock.hpp"
#include "../Memory.hpp"

using namespace Kobold;

namespace Kobold::Memory {
    PFNEntry* PfnStart = NULL;
    PFNEntry* PfnFreeHead = NULL;
    PFNEntry* PfnFreeTail = NULL;
    Sync::Lock PfnLock = {0,false,false};

    void AddFreePage(usize page) {
        PfnLock.Acquire();
        usize index = page >> 12;
        PfnStart[index].next = NULL;
        PfnStart[index].prev = PfnFreeTail;
        if(PfnFreeHead == NULL) {
            PfnFreeHead = &PfnStart[index];
        }
        if(PfnFreeTail != NULL) {
            PfnFreeTail->next = &PfnStart[index];
        }
        PfnFreeTail = &PfnStart[index];
        PfnStart[index].type = PFN_FREE;
        PfnLock.Release();
    }

    void* AllocatePage(int type, usize pte) {
        PfnLock.Acquire();
        if(PfnFreeHead != NULL) {
            u64 index = (((usize)PfnFreeHead) - ((usize)PfnStart))/sizeof(PFNEntry);
            if(PfnFreeHead->next != NULL)
                PfnFreeHead->next->prev = NULL;
            PfnFreeHead = PfnFreeHead->next;
            PfnStart[index].pageEntry = pte & 0x7ffffffff000;
            PfnStart[index].type = type;
            PfnStart[index].references = 0;
            PfnLock.Release();
            memset((void*)((index << 12) + 0xffff800000000000),0,4096);
            return (void*)((index << 12) + 0xffff800000000000);
        }
        PfnLock.Release();
        return NULL;
    }

    void ReferencePage(void* page) {
        PfnLock.Acquire();
        usize index = (((usize)page) >> 12) & 0x7ffffffff;
        if(PfnStart[index].type >= PFN_ACTIVE) {
            PfnStart[index].references += 1;
        }
        PfnLock.Release();
    }

    void DereferencePage(void* page) {
        PfnLock.Acquire();
        usize index = (((usize)page) >> 12) & 0x7ffffffff;
        if(PfnStart[index].type >= PFN_ACTIVE) {
            PfnStart[index].references -= 1;
            if(PfnStart[index].references <= 0) {
                int oldState = PfnStart[index].type;
                PfnStart[index].type = PFN_FREE;
                PfnStart[index].prev = PfnFreeTail;
                if(PfnFreeHead == NULL)
                    PfnFreeHead = &PfnStart[index];
                if(PfnFreeTail != NULL) {
                    PfnFreeTail->next = &PfnStart[index];
                }
                PfnFreeTail = &PfnStart[index];
                if(PfnStart[index].pageEntry != 0 && oldState == PFN_PAGETABLE) {
                    usize entry = PfnStart[index].pageEntry;
                    usize pt = (entry & (~0xfff));
                    *((usize*)(entry + 0xffff800000000000)) = 0;
                    PfnLock.Release();
                    if(PfnStart[pt >> 12].type != PFN_PAGEDIR) {
                        DereferencePage((void*)pt);
                    }
                    return;
                }
            }
        }
        PfnLock.Release();
    }

    void ForceFreePage(void* page) {
        usize index = (((usize)page) >> 12) & 0x7ffffffff;
        PfnLock.Acquire();
        PfnStart[index].type = PFN_FREE;
        PfnStart[index].prev = PfnFreeTail;
        PfnStart[index].next = NULL;
        PfnStart[index].pageEntry = 0;
        if(PfnFreeTail != NULL)
            PfnFreeTail->next = &PfnStart[index];
        PfnFreeTail = &PfnStart[index];
        PfnLock.Release();
    }

    bool ChangeType(void* page, int type) {
        usize index = (((usize)page) >> 12) & 0x7ffffffff;
        PfnLock.Acquire();
        if(PfnStart[index].type >= PFN_ACTIVE && PfnStart[index].references <= 1) {
            PfnStart[index].type = type;
            PfnStart[index].references = 0;
        } else {
            PfnLock.Release();
            return false;
        }
        PfnLock.Release();
        return true;
    }

    void Initialize(dtb_pair* ranges, size_t len) {
        u64 highestAddr = 0;
        for(int i=0; i < len; i++) {
            if(ranges[i].b > highestAddr) {
                highestAddr = ranges[i].b;
            }
        }
        u64 entries = highestAddr / 4096;
        u64 neededSize = ALIGN_UP(entries*sizeof(PFNEntry),4096);
        u64 startAddr = 0;
        for(int i=0; i < len; i++) {
            if((ranges[i].b-ranges[i].a) > neededSize) {
                startAddr = ranges[i].a + 0xffff800000000000;
                ranges[i].a += neededSize;
                break;
            } else if((ranges[i].b-ranges[i].a) == neededSize) {
                startAddr = ranges[i].a + 0xffff800000000000;
                ranges[i].a = 0;
                ranges[i].b = 0;
                break;
            }
        }
        if(startAddr == 0)
            Panic("Couldn't allocate PFN Database! (Insufficient Memory Layout)");
        Logging::Log("PFN @ %X [%i entries, %i KiB]", startAddr, entries, neededSize/1024);
        PfnStart = (PFNEntry*)startAddr;
        memset(PfnStart,0,neededSize);
        u64 count = 0;
        for(int i=0; i < len; i++) {
            if(ranges[i].b != 0) {
                for(u64 p=ranges[i].a; p < ranges[i].b; p += 4096) {
                    AddFreePage(p);
                    count++;
                }
            }
        }
        Logging::Log("%i Pages Available", count);
    }
}