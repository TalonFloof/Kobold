build_rv64:
	rm -r -f kobold/zig-out/
	cd kobold; zig build -Dboard=qemu_riscv64; cd ..
	nm -B -S -n kobold/zig-out/bin/kernel | python3 scripts/generateDebugFile.py kobold/zig-out/bin/kernel.dbg
	objcopy -S kobold/zig-out/bin/kernel

build_pc64: limine-zig
	rm -r -f kobold/zig-out/
	nasm -f elf64 -O0 kobold/hal/x86_64/lowlevel.s -o lowlevel.o
	
	cd kobold; zig build -Dboard=pc_x86_64 -Doptimize=Debug; cd ..
	rm -r -f lowlevel.o
	nm -B -S -n kobold/zig-out/bin/* | python3 scripts/generateDebugFile.py kobold/zig-out/bin/kernel.dbg
	# objcopy -S kobold/zig-out/bin/kernel

iso: build_pc64
	rm -r --force /tmp/limine
	rm -r --force /tmp/kobold_iso
	git clone --branch v8.x-binary --depth 1 https://github.com/limine-bootloader/limine /tmp/limine
	mkdir -p /tmp/kobold_iso/EFI/BOOT
	cp --force /tmp/limine/BOOTX64.EFI /tmp/limine/limine-uefi-cd.bin /tmp/limine/limine-bios-cd.bin /tmp/limine/limine-bios.sys boot/x86_64/* kobold/zig-out/bin/* /tmp/kobold_iso
	mv /tmp/kobold_iso/BOOTX64.EFI /tmp/kobold_iso/EFI/BOOT/BOOTX64.EFI
	xorriso -as mkisofs -b limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label /tmp/kobold_iso -o kobold.iso
	zig cc /tmp/limine/limine.c -o /tmp/limine/limine
	/tmp/limine/limine bios-install kobold.iso
	rm -r --force /tmp/limine
	rm -r --force /tmp/kobold_iso

run_pc64: iso
	qemu-system-x86_64 -enable-kvm -cpu host,migratable=off -m 8M -serial stdio -device pcie-pci-bridge -cdrom kobold.iso

run_rv64: build_rv64
	qemu-system-riscv64 -machine virt -m 128M -serial stdio -device ramfb -device virtio-keyboard-device -device virtio-mouse-device -kernel kobold/zig-out/bin/kernel

limine-zig:
	git clone https://github.com/48cf/limine-zig --depth=1
	rm -f -r limine-zig/.git limine-zig/build.zig limine-zig/README.md