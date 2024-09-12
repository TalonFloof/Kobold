#pragma once
#include "../general/Common.hpp"

typedef enum {
    DISABLE_INTERRUPTS,
    ENABLE_INTERRUPTS,
    YIELD_UNTIL_INTERRUPT,
} IArch_IntAction;

class IKoboldArchitecture {
public:
    virtual void InterruptControl(IArch_IntAction action);
    virtual void Log(const char* s, size_t l);
};