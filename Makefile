build:
	cd kobold; make build; cd ..

run:
	qemu-system-riscv64 -machine virt -kernel kobold/Kobold -serial stdio

clean:
	cd kobold; make clean; cd ..