#include "vmstdlib.h"

void *generic_memset(void *src, int c, size_t count) {
  uint8_t *xs = (uint8_t *)src;

  while (count--) *xs++ = c;

  return src;
}

void *generic_memcpy(void *dest, const void *src, size_t count) {
  const char *sp = (char *)src;
  char *dp = (char *)dest;
  size_t i;
  for (i = count; i >= sizeof(uint64_t); i = count) {
    *((uint64_t *)dp) = *((uint64_t *)sp);
    sp = sp + sizeof(uint64_t);
    dp = dp + sizeof(uint64_t);
    count -= sizeof(uint64_t);
  }

  for (i = count; i >= 4; i = count) {
    *((uint32_t *)dp) = *((uint32_t *)sp);
    sp = sp + 4;
    dp = dp + 4;
    count -= 4;
  }

  for (i = count; i > 0; i = count) {
    *(dp++) = *(sp++);
    count--;
  }

  return dest;
}

int generic_memcmp(const void *s1, const void *s2, size_t n) {
  const uint8_t *a = (uint8_t *)s1;
  const uint8_t *b = (uint8_t *)s2;
  size_t i;

  for (i = 0; i < n; i++) {
    if (a[i] < b[i]) {
      return -1;
    } else if (a[i] > b[i]) {
      return 1;
    }
  }

  return 0;
}

size_t generic_strlen(const char *str) {
  size_t i = 0;
  while (str[i]) i++;
  return i;
}

int generic_strcmp(const char *s1, const char *s2) {
  while (*s1 == *s2) {
    if (!*(s1++)) {
      return 0;
    }

    s2++;
  }
  return (*s1) - *(s2);
}

