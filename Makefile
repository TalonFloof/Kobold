build:
	cd kobold; make build; cd ..

run:
	qemu-system-riscv64 -machine virt -device virtio-gpu-device -device virtio-keyboard-device -device virtio-mouse-device -smp 1 -m 512M -kernel kobold/Kobold -serial stdio -s

clean:
	cd kobold; make clean; cd ..