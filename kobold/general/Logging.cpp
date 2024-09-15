#include "Logging.hpp"
#include "Memory.hpp"

void Kobold::Logging::Write(const char* __restrict format, va_list args) {
    char buf[64];
    while (*format != '\0') {
        if (format[0] != '%' || format[1] == '%') {
        if (format[0] == '%') format++;
        size_t amount = 1;
        while (format[amount] && format[amount] != '%') amount++;
        Kobold::Architecture::Log(format, amount);
        format += amount;
        continue;
        }
        const char* format_begun_at = format++;
        char hex = 1;
        char isHalf = 0;
        char isLong = 0;
    again:
        switch (*format) {
        case 'l':
            isLong = 1;
            format++;
            goto again;
        case 'h':
            if (!isLong) {
            isHalf = 1;
            }
            format++;
            goto again;
        case 'c': {
            format++;
            char arg = (char)va_arg(args, int);
            Kobold::Architecture::Log(&arg, 1);
            break;
        }
        case 'b': {
            format++;
            unsigned int arg = va_arg(args, unsigned int);
            const char* str = (arg ? "true" : "false");
            Kobold::Architecture::Log(str, strlen(str));
            break;
        }
        case 's': {
            format++;
            const char* arg = va_arg(args, const char*);
            size_t len = strlen(arg);
            Kobold::Architecture::Log(arg, len);
            break;
        }
        case 'd':
        case 'i': {
            format++;
            long arg = 0;

            if (isHalf) {
            arg = va_arg(args, int);
            } else {
            arg = va_arg(args, long);
            }

            if (arg < 0) {
            Kobold::Architecture::Log("-", 1);
            (void)itoa(-arg, (char*)&buf, 10);
            } else {
            (void)itoa(arg, (char*)&buf, 10);
            }
            Kobold::Architecture::Log((char*)&buf, strlen((char*)&buf));
            break;
        }
        case 'u': {
            hex = 0;
            //__attribute__((fallthrough));
        }
        case 'X': {
            //__attribute__((fallthrough));
        }
        case 'x': {
            int zeroPad = 0;
            if(*format == 'X') {
                zeroPad = 1;
            }
            format++;
            if (isHalf) {
            unsigned int arg = va_arg(args, unsigned int);
            (void)itoa(arg, (char*)&buf, hex ? 16 : 10);
            if (hex) {
                Kobold::Architecture::Log("0x", 2);
                if(zeroPad) {
                    for(int i=0; i < 8-strlen((char*)&buf); i++) {
                        Kobold::Architecture::Log("0",1);
                    }
                }
            }
            Kobold::Architecture::Log((char*)&buf, strlen((char*)&buf));
            } else {
            unsigned long long arg = va_arg(args, unsigned long long);
            (void)itoa(arg, (char*)&buf, hex ? 16 : 10);
            if (hex) {
                Kobold::Architecture::Log("0x", 2);
                if(zeroPad) {
                    for(int i=0; i < 16-strlen((char*)&buf); i++) {
                        Kobold::Architecture::Log("0",1);
                    }
                }
            }
            Kobold::Architecture::Log((char*)&buf, strlen((char*)&buf));
            }
            break;
        }
        default:
            format = format_begun_at;
            size_t len = strlen(format);
            Kobold::Architecture::Log(format, len);
            format += len;
        }
    }
}