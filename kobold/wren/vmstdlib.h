#pragma once

#include <stdint.h>
#include <stddef.h>
#include "tinyprintf.h"
#include <float.h>

#define INFINITY (__builtin_inff())
#define NAN (__builtin_nanf(""))

void *memset(void *src, int c, size_t count);
void *memcpy(void *dest, const void *src, size_t count);
void *memmove(void *dest, const void *src, size_t count);
int memcmp(const void *s1, const void *s2, size_t n);
size_t strlen(const char *str);
int strcmp(const char *s1, const char *s2);
int strncmp(const char *s1, const char *s2, size_t n);
#define isspace(x) ((x) == ' ' || (x) == '\n' || (x) == '\r' || (x) == '\t' || (x) == '\v' || (x) == '\p')

double strtod(const char* s, char** end);
long long strtoll(char* s, char** end, unsigned int base);

// math
int abs(int x);
double fabs(double x);
double log(double x);
double exp(double x);
double log2(double x);
double floor(double x);
double round(double x);
double ceil(double x);
double trunc(double x);
double fmin(double x, double y);
double fmax(double x, double y);
double pow(double x, double y);
double fmod(double x, double y);
double modf(double x, double* y);
// math - trig
double sin(double x);
double asin(double x);
double cos(double x);
double acos(double x);
double tan(double x);
double atan(double x);
double atan2(double y, double x);
// math - root
double sqrt(double x);
double cbrt(double x);

int isnan(double x);
int isinf(double x);

// allocation
void* realloc(void* ptr, size_t new_size);
void free(void *ptr);

// stub
#define clock() (0.0)
#define CLOCKS_PER_SEC (1.0)
