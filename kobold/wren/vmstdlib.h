#pragma once

#include <stdint.h>

#ifdef __has_builtin
    #if __has_builtin(__builtin_memcpy)
        #define memcpy(dest, src, n) __builtin_memcpy(dest, src, n)
    #else
        #define memcpy(dest, src, n) generic_memcpy(dest, src, n)
    #endif
#endif