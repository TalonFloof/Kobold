#define _LOCK_IMPL
#include "Lock.hpp"

void Kobold::Sync::Lock::Acquire() {
    if(!permitInterrupts)
        this->prevInt = Kobold::Architecture::IntControl(false);
    for (int i = 0; i < 50000000; i++) {
        if (!__atomic_test_and_set(&(this->atomic), __ATOMIC_ACQUIRE)) {
            return;
        }
    }
    Panic("Deadlock");
}

void Kobold::Sync::Lock::Release() {
    __atomic_clear(&(this->atomic), __ATOMIC_RELEASE);
    if(!permitInterrupts)
        Kobold::Architecture::IntControl(this->prevInt);
}