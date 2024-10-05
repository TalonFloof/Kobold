#include <stddef.h>

int strcmp(const char *s1, const char *s2) {
  while (*s1 == *s2) {
    if (!*(s1++)) {
      return 0;
    }

    s2++;
  }
  return (*s1) - *(s2);
}

int strncmp(const char *s1, const char *s2, size_t n) {
  size_t i;
  for (i = 0; i < n; i++) {
    if (s1[i] != s2[i]) {
      return s1[i] < s2[i] ? -1 : 1;
    } else if (s1[i] == '\0') {
      return 0;
    }
  }

  return 0;
}