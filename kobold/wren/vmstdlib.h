#pragma once

#include <stdint.h>

void *generic_memset(void *src, int c, size_t count);
void *generic_memcpy(void *dest, const void *src, size_t count);
int generic_memcmp(const void *s1, const void *s2, size_t n);
size_t generic_strlen(const char *str);
int generic_strcmp(const char *s1, const char *s2);

#ifdef __has_builtin
    #if __has_builtin(__builtin_memcpy)
        #define memcpy(dest, src, n) __builtin_memcpy(dest, src, n)
    #else
        #define memcpy(dest, src, n) generic_memcpy(dest, src, n)
    #endif
    #if __has_builtin(__builtin_memmove)
        #define memmove(dest, src, n) __builtin_memmove(dest, src, n)
    #else
        #define memmove(dest, src, n) generic_memcpy(dest, src, n)
    #endif
    #if __has_builtin(__builtin_memset)
        #define memset(src, c, count) __builtin_memset(src, c, count)
    #else
        #define memset(src, c, count) generic_memset(src, c, count)
    #endif
    #if __has_builtin(__builtin_memcmp)
        #define memcmp(s1, s2, n) __builtin_memcmp(s1, s2, n)
    #else
        #define memcmp(s1, s2, n) generic_memcmp(s1, s2, n)
    #endif
    #if __has_builtin(__builtin_strlen)
        #define strlen(s) __builtin_strlen(s)
    #else
        #define strlen(s) generic_strlen(s)
    #endif
    #if __has_builtin(__butltin_strcmp)
        #define strcmp(s1, s2) __builtin_strcmp(s1,s2)
    #else
        #define strcmp(s1, s2) generic_strcmp(s1, s2)
    #endif
#else
    #define memcpy(dest, src, n) generic_memcpy(dest, src, n)
    #define memset(src, c, count) generic_memset(src, c, count)
    #define memcmp(s1, s2, n) generic_memcmp(s1, s2, n)
    #define strlen(s) generic_strlen(s)
    #define strcmp(s1, s2) generic_strcmp(s1, s2)
#endif