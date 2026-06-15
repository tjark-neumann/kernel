# Makefile for a minimal x86 kernel.
# Override CC with cross-compiler if you have one: make CC=i686-elf-gcc

CC      := gcc
LD      := ld
CFLAGS  := -m32 -std=gnu11 -ffreestanding -O2 -Wall -Wextra
ASFLAGS := -m32
LDFLAGS := -m elf_i386 -T linker.ld -nostdlib

OBJS := boot.o kernel.o
KERNEL := kernel.elf

.PHONY: all clean run iso

all: $(KERNEL)

boot.o: boot.s
	$(CC) $(ASFLAGS) -c $< -o $@

kernel.o: kernel.c
	$(CC) $(CFLAGS) -c $< -o $@

$(KERNEL): $(OBJS) linker.ld
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

# Boot the kernel directly in QEMU
run: $(KERNEL)
	qemu-system-i386 -kernel $(KERNEL)

# Build a bootable ISO with GRUB
iso: $(KERNEL)
	mkdir -p isodir/boot/grub
	cp $(KERNEL) isodir/boot/kernel.elf
	printf 'menuentry "mykernel" {\n  multiboot /boot/kernel.elf\n}\n' > isodir/boot/grub/grub.cfg
	grub-mkrescue -o kernel.iso isodir

clean:
	rm -rf $(OBJS) $(KERNEL) isodir kernel.iso
