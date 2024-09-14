#pragma once
#include "../../general/Common.hpp"

#define ReadCSR(value, which)       \
    __asm__ __volatile__ (          \
        "csrr %[val], " #which ";"  \
        : [val] "=r" (value)        \
        :                           \
    )

#define WriteCSR(value, which)      \
    __asm__ __volatile__ (          \
        "csrw " #which ", %[val];"  \
        :                           \
        : [val] "r" (value)         \
    )