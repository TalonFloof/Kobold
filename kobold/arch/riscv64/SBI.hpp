#pragma once
#include "../../general/Common.hpp"

typedef enum {
    SBI_SUCCESS               =  0,
    SBI_ERR_FAILED            = -1,
    SBI_ERR_NOT_SUPPORTED     = -2,
    SBI_ERR_INVALID_PARAM     = -3,
    SBI_ERR_DENIED            = -4,
    SBI_ERR_INVALID_ADDRESS   = -5,
    SBI_ERR_ALREADY_AVAILABLE = -6
} SBIErrorCode;

struct SBIReturn {
  SBIErrorCode error;
  usize value;
};

static SBIReturn SBICall6(usize extID, usize funcID, usize arg1, usize arg2, usize arg3, usize arg4, usize arg5, usize arg6) {
  register usize a0 asm ("a0") = (usize)(arg1);
  register usize a1 asm ("a1") = (usize)(arg2);
  register usize a2 asm ("a2") = (usize)(arg3);
  register usize a3 asm ("a3") = (usize)(arg4);
  register usize a4 asm ("a4") = (usize)(arg5);
  register usize a5 asm ("a5") = (usize)(arg6);
  register usize a6 asm ("a6") = (usize)(funcID);
  register usize a7 asm ("a7") = (usize)(extID);
  asm volatile ("ecall" : "+r"(a0), "+r"(a1) : "r"(a2), "r"(a3), "r"(a4), "r"(a5), "r"(a6), "r"(a7) : "memory");
  return (SBIReturn){
    .error = (SBIErrorCode)a0,
    .value = a1,
  };
}

#define SBICall0(extID, funcID) SBICall6(extID, funcID, 0, 0, 0, 0, 0, 0)
#define SBICall1(extID, funcID, arg1) SBICall6(extID, funcID, arg1, 0, 0, 0, 0, 0)
#define SBICall2(extID, funcID, arg1, arg2) SBICall6(extID, funcID, arg1, arg2, 0, 0, 0, 0)
#define SBICall3(extID, funcID, arg1, arg2, arg3) SBICall6(extID, funcID, arg1, arg2, arg3, 0, 0, 0)
#define SBICall4(extID, funcID, arg1, arg2, arg3, arg4) SBICall6(extID, funcID, arg1, arg2, arg3, arg4, 0, 0)
#define SBICall5(extID, funcID, arg1, arg2, arg3, arg4, arg5) SBICall6(extID, funcID, arg1, arg2, arg3, arg4, arg5, 0)

static isize SBICallLegacy5(usize extID, usize arg1, usize arg2, usize arg3, usize arg4, usize arg5) {
  register usize a0 asm ("a0") = (usize)(arg1);
  register usize a1 asm ("a1") = (usize)(arg2);
  register usize a2 asm ("a2") = (usize)(arg3);
  register usize a3 asm ("a3") = (usize)(arg4);
  register usize a4 asm ("a4") = (usize)(arg5);
  register usize a7 asm ("a7") = (usize)(extID);
  asm volatile ("ecall" : "+r"(a0) : "r"(a1), "r"(a2), "r"(a3), "r"(a4), "r"(a7) : "memory");
  return (isize)a0;
}

#define SBICallLegacy0(extID) SBICallLegacy5(extID, 0, 0, 0, 0, 0)
#define SBICallLegacy1(extID, arg1) SBICallLegacy5(extID, arg1, 0, 0, 0, 0)
#define SBICallLegacy2(extID, arg1, arg2) SBICallLegacy5(extID, arg1, arg2, 0, 0, 0)
#define SBICallLegacy3(extID, arg1, arg2, arg3) SBICallLegacy5(extID, arg1, arg2, arg3, 0, 0)
#define SBICallLegacy4(extID, arg1, arg2, arg3, arg4) SBICallLegacy5(extID, arg1, arg2, arg3, arg4, 0)