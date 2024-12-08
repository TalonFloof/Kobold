TARGET := x86_64-pc

all: iso-pc64

build:
	rm -fr out
	cd KoboldKernel; cargo build -Z unstable-options --target=targets/$(TARGET).json --artifact-dir ../out/; cd ..

iso-pc64: build
	rm -rf /tmp/limine
	rm -rf /tmp/kobold_iso
	git clone --branch v8.x-binary --depth 1 https://github.com/limine-bootloader/limine /tmp/limine
	mkdir -p /tmp/kobold_iso/EFI/BOOT
	cp -f /tmp/limine/BOOTX64.EFI /tmp/limine/limine-uefi-cd.bin /tmp/limine/limine-bios-cd.bin /tmp/limine/limine-bios.sys boot/x86_64/* out/* /tmp/kobold_iso
	mv /tmp/kobold_iso/BOOTX64.EFI /tmp/kobold_iso/EFI/BOOT/BOOTX64.EFI
	xorriso -as mkisofs -b limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label /tmp/kobold_iso -o kobold.iso
	gcc /tmp/limine/limine.c -o /tmp/limine/limine
	/tmp/limine/limine bios-install kobold.iso
	rm -rf /tmp/limine
	rm -rf /tmp/kobold_iso

run-pc64: iso-pc64
	qemu-system-x86_64 -enable-kvm -cdrom kobold.iso -m 16M -smp 2