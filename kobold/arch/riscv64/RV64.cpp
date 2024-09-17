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

    int UseLegacyTimer = 1;
    int UseLegacyConsole = 1;

    void EarlyInitialize() {
        // Check if the Debug Console SBI Extension is available, if its not, use the legacy console functions
        IntControl(false);
        SBIReturn hasDebugCon = SBICall1(0x10,3,0x4442434E);
        if(hasDebugCon.value) {
            UseLegacyConsole = 0;
        }
        hasDebugCon = SBICall1(0x10,3,0x54494D45);
        if(hasDebugCon.value) {
            UseLegacyTimer = 0;
        }
    }

    void Initialize(void* deviceTree) {
        WriteCSR(((usize)&_intHandler),stvec);
        Kobold::DeviceTree::ScanTree(deviceTree);
        // Setup the Timer
        if(UseLegacyTimer) {
            if(SBICallLegacy1(0,(Kobold::DeviceTree::CpuSpeed / 100)) != 0) {
                Panic("Failed to setup timer!");
            }
        } else {
            if(SBICall1(0x54494D45,0,(Kobold::DeviceTree::CpuSpeed / 100)).error != SBI_SUCCESS) {
                Panic("Failed to setup timer!");
            }
        }
        WriteCSR((1 << 5) | (1 << 9) | (1 << 1),sie);
    }

    void Log(const char* s, size_t l) {
        if(UseLegacyConsole) {
            size_t i;
            for(i = 0; i < l; i++) {
                SBICallLegacy1(1,s[i]);
            }
        } else {
            size_t i;
            for(i = 0; i < l; i++) {
                SBICall1(0x4442434E,2,s[i]);
            }
        }
    }

    void WaitForInt() {
        __asm__ __volatile__ ("wfi");
    }

    bool IntControl(bool enable) {
        if(enable) {
            __asm__ __volatile__("csrsi sstatus, 2");
        } else {
            __asm__ __volatile__("csrci sstatus, 2");
        }
        u64 v;
        ReadCSR(v,sstatus);
        return (v & 2) != 0;
    }

    struct Frame {
        usize ra, gp, tp, t0, t1, t2, t3, t4, t5, t6, a0, a1, a2, a3, a4, a5, a6, a7, s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, sp, pc;
    };

    void PrintFrame(Frame* f) {
        Logging::Log(" ra %X  gp %X  tp %X  t0 %X", f->ra, f->gp, f->tp, f->t0);
        Logging::Log(" t1 %X  t2 %X  t3 %X  t4 %X", f->t1, f->t2, f->t3, f->t4);
        Logging::Log(" t5 %X  t6 %X  a0 %X  a1 %X", f->t5, f->t6, f->a0, f->a1);
        Logging::Log(" a2 %X  a3 %X  a4 %X  a5 %X", f->a2, f->a3, f->a4, f->a5);
        Logging::Log(" a6 %X  a7 %X  s0 %X  s1 %X", f->a6, f->a7, f->s0, f->s1);
        Logging::Log(" s2 %X  s3 %X  s4 %X  s5 %X", f->s2, f->s3, f->s4, f->s5);
        Logging::Log(" s6 %X  s7 %X  s8 %X  s9 %X", f->s6, f->s7, f->s8, f->s9);
        Logging::Log("s10 %X s11 %X  sp %X  pc %X", f->s10, f->s11, f->sp, f->pc);
    }
}