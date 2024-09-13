#include "../IArchitecture.hpp"
#include "SBI.hpp"

namespace Kobold::Architecture {
    int UseLegacyConsole = 1;

    void EarlyInitialize() {
        // Check if the Debug Console SBI Extension is available, if its not, use the legacy console functions
        SBIReturn hasDebugCon = SBICall1(0x10,3,0x4442434E);
        if(hasDebugCon.value) {
            UseLegacyConsole = 0;
        }
    }

    void Initialize() {
        
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
            asm volatile("wfi");
        }
    }
}