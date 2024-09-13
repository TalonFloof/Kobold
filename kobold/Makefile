CPPFILES := $(shell find . -type f -name '*.cpp')
ASMFILES := $(shell find . -type f -name '*.s')

OBJFILES := $(patsubst %.cpp,%.o,$(CPPFILES)) $(patsubst %.s,%.o,$(ASMFILES))

CPPFILES := $(CPPFILES) $(ASMFILES)

CFLAGS := \
	-ffreestanding \
	-O0 \
	-Wall \
	-Wextra \
	-fno-omit-frame-pointer       \
	-fno-stack-protector          \
	-fno-stack-check              \
	-fno-pic                      \
	-fno-pie                      \
	-mno-red-zone                 \
	-nostdlib \
	-fno-exceptions \
	-mabi=lp64 \
	-mcmodel=medany \
	-fno-rtti

build: $(OBJFILES)
	zig c++ --target=riscv64-freestanding-none $(OBJFILES) -O3 -r -o Kobold.o
	zig c++ --target=riscv64-freestanding-none Kobold.o -Tlinks/riscv64.ld -g -Wl,-z,max-page-size=0x1000 -static -o Kobold
	rm -f Kobold.o
	rm -f $(OBJFILES)
	rm -f $(shell find . -type f -name '*.tmp*')

.PHONY: build clean

%.o: %.cpp
	zig c++ --target=riscv64-freestanding-none $(CFLAGS) -c $< -o $@

%.o: %.s
	zig c++ --target=riscv64-freestanding-none $(CFLAGS) -c $< -o $@

clean:
	rm -f Kobold.o Kobold
	rm -f $(OBJFILES)
	rm -f $(shell find . -type f -name '*.tmp*')