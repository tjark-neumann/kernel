/* linker.ld tells the linker how to lay the kernel out in memory.
 * bootloader loads us at the 1 MiB mark (addresses below 1 MiB are full
 * of legacy BIOS/hardware regions)
 */

ENTRY(_start)

SECTIONS
{
	/* start placing sections at 1 MiB */
	. = 1M;

	/* code. .multiboot goes first so the bootloader can find the header */
	.text BLOCK(4K) : ALIGN(4K)
	{
		*(.multiboot)
		*(.text)
	}

	/* read-only data */
	.rodata BLOCK(4K) : ALIGN(4K)
	{
		*(.rodata)
	}

	/* initialised read-write data */
	.data BLOCK(4K) : ALIGN(4K)
	{
		*(.data)
	}

	/* zero-initialised data and the stack reservation from boot.s */
	.bss BLOCK(4K) : ALIGN(4K)
	{
		*(COMMON)
		*(.bss)
	}
}
