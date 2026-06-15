/* boot.s -- Multiboot header and the very first code the CPU runs.
 *
 * GRUB (and QEMU's -kernel) look for the Multiboot magic header below in the
 * first 8 KiB of the file. When found, the bootloader loads us into memory,
 * switches the CPU to 32-bit protected mode, and jumps to _start. There is no
 * OS underneath us at this point: no stack, no libc, nothing. We set up a
 * stack ourselves and then call into C.
 */

/* --- Multiboot header constants --- */
.set ALIGN,    1 << 0             /* align loaded modules on page boundaries */
.set MEMINFO,  1 << 1             /* ask the bootloader for a memory map      */
.set FLAGS,    ALIGN | MEMINFO    /* the Multiboot 'flags' field              */
.set MAGIC,    0x1BADB002         /* lets the bootloader find this header     */
.set CHECKSUM, -(MAGIC + FLAGS)   /* magic + flags + checksum must equal 0    */

/* The header itself, placed in its own section so the linker can put it
 * right at the start of the binary (see linker.ld). */
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/* Reserve a 16 KiB stack in .bss. The stack must be 16-byte aligned per the
 * System V ABI. It grows downward, so we point ESP at the TOP. */
.section .bss
.align 16
stack_bottom:
.skip 16384            /* 16 KiB */
stack_top:

/* The kernel entry point. */
.section .text
.global _start
.type _start, @function
_start:
	/* Set up the stack. */
	mov $stack_top, %esp

	/* Hand control to our C code. The CPU is already in 32-bit protected
	 * mode with interrupts off and paging disabled, exactly the
	 * environment the C is written for. */
	call kernel_main

	/* kernel_main should never return, but if it does: disable interrupts
	 * and halt forever. The jmp catches any spurious wakeups (NMIs). */
	cli
1:	hlt
	jmp 1b

/* Set the size of the _start symbol, useful for debuggers/profilers. */
.size _start, . - _start
