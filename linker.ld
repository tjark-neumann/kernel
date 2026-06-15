/* linker.ld -- Tells the linker how to lay the kernel out in memory.
 *
 * The bootloader loads us at the 1 MiB mark (addresses below 1 MiB are full
 * of legacy BIOS/hardware regions). Crucially, the .multiboot section must
 * appear within the first 8 KiB of the file, so we place it first.
 */

ENTRY(_start)

SECTIONS
{
	/* Start placing sections at 1 MiB. */
	. = 1M;

	/* Code. .multiboot goes first so the bootloader can find the header. */
	.text BLOCK(4K) : ALIGN(4K)
	{
		*(.multiboot)
		*(.text)
	}

	/* Read-only data. */
	.rodata BLOCK(4K) : ALIGN(4K)
	{
		*(.rodata)
	}

	/* Initialized read-write data. */
	.data BLOCK(4K) : ALIGN(4K)
	{
		*(.data)
	}

	/* Zero-initialized data and the stack reservation from boot.s. */
	.bss BLOCK(4K) : ALIGN(4K)
	{
		*(COMMON)
		*(.bss)
	}
}
