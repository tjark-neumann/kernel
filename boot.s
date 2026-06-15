/* boot.s multiboot header */

/* multiboot header constants */
.set ALIGN,    1 << 0             /* align loaded modules on page boundaries */
.set MEMINFO,  1 << 1             /* ask the bootloader for a memory map      */
.set FLAGS,    ALIGN | MEMINFO    /* the multiboot flags field              */
.set MAGIC,    0x1BADB002         /* lets the bootloader find this header     */
.set CHECKSUM, -(MAGIC + FLAGS)   /* magic + flags + checksum must equal 0    */

/* the header itself, placed in its own section so the linker can put it
 * right at the start of the binary (see linker.ld). */
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/* reserve a 16 KiB stack in .bss. the stack must be 16-byte aligned per the
 * System V ABI. it grows downward, so we point ESP at the TOP. */
.section .bss
.align 16
stack_bottom:
.skip 16384            /* 16 KiB */
stack_top:

/* kernel entry point. */
.section .text
.global _start
.type _start, @function
_start:
	/* set up the stack. */
	mov $stack_top, %esp

	/* hand control to C code. CPU is already in 32-bit protected
	 * mode with interrupts off and paging disabled. */
	call kernel_main

	/* kernel_main should never return, but if it does: disable interrupts
	 * and halt forever. the jmp catches any wakeups. */
	cli
1:	hlt
	jmp 1b

/* set size of the _start symbol */
.size _start, . - _start
