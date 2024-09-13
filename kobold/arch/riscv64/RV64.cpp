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

    }

    void Interrupt() {
        asm volatile("wfi");
    }
}