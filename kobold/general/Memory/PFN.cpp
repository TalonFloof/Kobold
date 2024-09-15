#include "PFN.hpp"
#include "../Common.hpp"
#include "../Logging.hpp"

using namespace Kobold;

namespace Kobold::Memory {
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
    }
}