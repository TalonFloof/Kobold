#include "../IArchitecture.hpp"
#include "../../general/Logging.hpp"
#include "SBI.hpp"
#include "../../general/DeviceTree/DevTree.hpp"
#include "CSR.hpp"
#include "Traps.hpp"

using namespace Kobold;

namespace Kobold::Architecture {
    struct StatusRegister {
        union {
            u64 value;

            struct {
                u64 uie   : 1;
                u64 sie   : 1;
                u64 rsv1  : 1;
                u64 mie   : 1;
                u64 upie  : 1;
                u64 spie  : 1;
                u64 rsv2  : 1;
                u64 mpie  : 1;
                u64 spp   : 1;
                u64 rsv3  : 2;
                u64 mpp   : 2;
                u64 fs    : 2;
                u64 xs    : 2;
                u64 mprv  : 1;
                u64 sum   : 1;
                u64 mxr   : 1;
                u64 tvm   : 1;
                u64 tw    : 1;
                u64 tsr   : 1;
                u64 rsv4  : 9;
                u64 uxl   : 2;
                u64 sxl   : 2;
                u64 rsv5  : 27;
                u64 sd    : 1;
            };
        };
    };

    int UseLegacyConsole = 1;

    void EarlyInitialize() {
        // Check if the Debug Console SBI Extension is available, if its not, use the legacy console functions
        InterruptControl(DISABLE_INTERRUPTS);
        SBIReturn hasDebugCon = SBICall1(0x10,3,0x4442434E);
        if(hasDebugCon.value) {
            UseLegacyConsole = 0;
        }
    }

    void Initialize(void* deviceTree) {
        WriteCSR(((usize)&kernelvec),stvec);
        Kobold::DeviceTree::ScanTree(deviceTree);
    }

    void Log(const char* s, size_t l) {
        if(UseLegacyConsole) {
            size_t i;
            for(i = 0; i < l; i++) {
                SBICallLegacy1(1,s[i]);
            }
        } else {
            SBICall3(0x4442434E,0,l,((usize)s) & 0xFFFFFFFF,((usize)s) >> 32);
        }
    }

    void InterruptControl(IntAction action) {
        if(action == YIELD_UNTIL_INTERRUPT) {
            __asm__ __volatile__ ("wfi");
        } else if(action == DISABLE_INTERRUPTS) {
            StatusRegister sr;
            ReadCSR(sr,sstatus);
            sr.sie = 0;
            WriteCSR(sr,sstatus);
        } else if(action == ENABLE_INTERRUPTS) {
            StatusRegister sr;
            ReadCSR(sr,sstatus);
            sr.sie = 1;
            WriteCSR(sr,sstatus);
        }
    }
}