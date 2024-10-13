build_rv64:
	rm -r -f kobold/zig-out/
	cd kobold; zig build -Dboard=qemu_riscv64; cd ..

build_pc64:
	rm -r -f kobold/zig-out/
	cd kobold; zig build -Dboard=pc_x86_64; cd ..

iso: build_pc64
	rm -r --force /tmp/limine
	rm -r --force /tmp/kobold_iso
	git clone --branch v8.x-binary --depth 1 https://github.com/limine-bootloader/limine /tmp/limine
	mkdir -p /tmp/kobold_iso/EFI/BOOT
	cp --force /tmp/limine/BOOTX64.EFI /tmp/limine/limine-uefi-cd.bin /tmp/limine/limine-bios-cd.bin /tmp/limine/limine-bios.sys boot/x86_64/* kobold/zig-out/bin/kernel /tmp/kobold_iso
	mv /tmp/kobold_iso/BOOTX64.EFI /tmp/kobold_iso/EFI/BOOT/BOOTX64.EFI
	xorriso -as mkisofs -b limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label /tmp/kobold_iso -o kobold.iso
	zig cc /tmp/limine/limine.c -o /tmp/limine/limine
	/tmp/limine/limine bios-install kobold.iso
	rm -r --force /tmp/limine
	rm -r --force /tmp/kobold_iso

run_pc64: iso
	qemu-system-x86_64 -m 512M -serial stdio -cdrom kobold.iso

run_rv64: build_rv64
	qemu-system-riscv64 -machine virt -m 128M -serial stdio -device ramfb -device virtio-keyboard-device -device virtio-mouse-device -kernel kobold/zig-out/bin/kernel