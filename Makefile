build:
	cd kobold; make build; cd ..

run:
	qemu-system-riscv64 -machine virt -device virtio-gpu -device virtio-keyboard -device virtio-mouse -smp 2 -m 4G -kernel kobold/Kobold -serial stdio

clean:
	cd kobold; make clean; cd ..