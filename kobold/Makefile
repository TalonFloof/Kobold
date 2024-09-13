CPPFILES := $(shell find . -type f -name '*.cpp')

OBJFILES := $(patsubst %.cpp,%.o,$(CPPFILES))

CPPFILES := $(CPPFILES) $(shell find . -type f -name '*.s')

CFLAGS := \
	-ffreestanding \
	-O0 \
	-Wall \
	-Wextra \
	-fno-exceptions \
	-fno-rtti

build: $(OBJFILES)

.PHONY: build clean

%.o: %.cpp
	zig c++ --target=riscv64-freestanding-none $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJFILES)