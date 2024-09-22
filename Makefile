build:
	cd kobold; make build; cd ..

run: build
	qemu-system-riscv64 -machine virt -device virtio-gpu-device -device virtio-keyboard-device -device virtio-mouse-device -device virtio-sound-device -smp 1 -m 32M -kernel kobold/Kobold -serial stdio -s

clean:
	cd kobold; make clean; cd ..