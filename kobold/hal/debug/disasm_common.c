/*
 * This code is modified from:
 * https://gitlab.com/bztsrc/minidbg
 *
 * Copyright (C) 2021 bzt (bztsrc@github)
 *           (C) 2024 TalonFloof
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * @brief: mini debugger architecture independent code
 */

/* add includes here if you want */

#ifndef _STDINT_H
typedef unsigned long   uint64_t;
typedef unsigned int    uint32_t;
typedef unsigned short  uint16_t;
typedef unsigned char   uint8_t;
typedef long            int64_t;
typedef int             int32_t;
typedef short           int16_t;
typedef char            int8_t;
#endif
#ifndef NULL
#define NULL ((void*)0)
#endif
#ifndef true
#define true 1
#define false 0
#endif


/**
 * minimal sprintf implementation
 */
unsigned int dbg_vsprintf(char *dst, char* fmt, __builtin_va_list args)
{
    long int arg;
    int len, sign, i;
    char *p, *orig=dst, tmpstr[19], pad=' ';

    if(dst==(void*)0 || fmt==(void*)0)
        return 0;

    arg = 0;
    while(*fmt) {
        if(*fmt=='%') {
            fmt++;
            if(*fmt=='%') goto put;
            len=0;
            if(*fmt=='0') pad='0';
            while(*fmt>='0' && *fmt<='9') {
                len *= 10;
                len += *fmt-'0';
                fmt++;
            }
            if(*fmt=='l') fmt++;
            if(*fmt=='c') {
                arg = __builtin_va_arg(args, int);
                *dst++ = (char)arg;
                fmt++;
                continue;
            } else
            if(*fmt=='d') {
                arg = __builtin_va_arg(args, int);
                sign=0;
                if((int)arg<0) {
                    arg*=-1;
                    sign++;
                }
                if(arg>99999999999999999L) {
                    arg=99999999999999999L;
                }
                i=18;
                tmpstr[i]=0;
                do {
                    tmpstr[--i]='0'+(arg%10);
                    arg/=10;
                } while(arg!=0 && i>0);
                if(sign) {
                    tmpstr[--i]='-';
                }
                if(len>0 && len<18) {
                    while(i>18-len) {
                        tmpstr[--i]=pad;
                    }
                }
                p=&tmpstr[i];
                goto copystring;
            } else
            if(*fmt=='x') {
                arg = __builtin_va_arg(args, long int);
                i=16;
                tmpstr[i]=0;
                do {
                    char n=arg & 0xf;
                    /* 0-9 => '0'-'9', 10-15 => 'A'-'F' */
                    tmpstr[--i]=n+(n>9?0x37:0x30);
                    arg>>=4;
                } while(arg!=0 && i>0);
                /* padding, only leading zeros */
                if(len>0 && len<=16) {
                    while(i>16-len) {
                        tmpstr[--i]='0';
                    }
                }
                p=&tmpstr[i];
                goto copystring;
            } else
            if(*fmt=='s') {
                p = __builtin_va_arg(args, char*);
copystring:     if(p==(void*)0) {
                    p="(null)";
                }
                while(*p) {
                    *dst++ = *p++;
                }
            }
        } else {
put:        *dst++ = *fmt;
        }
        fmt++;
    }
    *dst=0;
    return dst-orig;
}

/**
 * Variable length arguments
 */
unsigned int dbg_sprintf(char *dst, char* fmt, ...)
{
    __builtin_va_list args;
    __builtin_va_start(args, fmt);
    return dbg_vsprintf(dst,fmt,args);
}
