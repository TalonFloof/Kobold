build_rv64:
	cd kobold; zig build -Dboard=qemu_riscv64; cd ..

run_rv64: build_rv64
	qemu-system-riscv64 -machine virt -m 128M -serial stdio -device ramfb -device virtio-keyboard-device -device virtio-mouse-device -kernel kobold/zig-out/bin/kernel