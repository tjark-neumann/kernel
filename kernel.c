/* kernel.c -- The C portion of the kernel.
 *
 * We are freestanding: there is no standard library, no malloc, no printf,
 * no operating system. The only thing we can rely on is the C language itself
 * and the hardware. To put text on the screen we write directly into the VGA
 * text-mode buffer, a fixed block of memory the video hardware continuously
 * scans out to the monitor.
 */

#include <stdint.h>
#include <stddef.h>

#if !defined(__i386__)
#error "This kernel must be compiled with a 32-bit (ix86) target."
#endif

/* --- VGA text mode ---------------------------------------------------------
 * The text buffer lives at physical address 0xB8000. It is an 80x25 grid of
 * 16-bit cells. Each cell is: low byte = ASCII character, high byte = color
 * (low nibble foreground, high nibble background).
 */
static const size_t VGA_WIDTH  = 80;
static const size_t VGA_HEIGHT = 25;
static uint16_t* const VGA_MEMORY = (uint16_t*)0xB8000;

enum vga_color {
	VGA_COLOR_BLACK         = 0,
	VGA_COLOR_BLUE          = 1,
	VGA_COLOR_GREEN         = 2,
	VGA_COLOR_CYAN          = 3,
	VGA_COLOR_RED           = 4,
	VGA_COLOR_MAGENTA       = 5,
	VGA_COLOR_BROWN         = 6,
	VGA_COLOR_LIGHT_GREY    = 7,
	VGA_COLOR_DARK_GREY     = 8,
	VGA_COLOR_LIGHT_BLUE    = 9,
	VGA_COLOR_LIGHT_GREEN   = 10,
	VGA_COLOR_LIGHT_CYAN    = 11,
	VGA_COLOR_LIGHT_RED     = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN   = 14,
	VGA_COLOR_WHITE         = 15,
};

/* Pack a foreground/background pair into the color byte. */
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
	return fg | (bg << 4);
}

/* Pack a character and color into a full 16-bit cell. */
static inline uint16_t vga_entry(unsigned char c, uint8_t color) {
	return (uint16_t)c | ((uint16_t)color << 8);
}

/* A tiny strlen, since there is no libc. */
static size_t kstrlen(const char* s) {
	size_t len = 0;
	while (s[len])
		len++;
	return len;
}

/* --- Terminal state -------------------------------------------------------- */
static size_t   term_row;
static size_t   term_col;
static uint8_t  term_color;
static uint16_t* term_buffer;

static void term_init(void) {
	term_row = 0;
	term_col = 0;
	term_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
	term_buffer = VGA_MEMORY;
	for (size_t y = 0; y < VGA_HEIGHT; y++) {
		for (size_t x = 0; x < VGA_WIDTH; x++) {
			term_buffer[y * VGA_WIDTH + x] = vga_entry(' ', term_color);
		}
	}
}

static void term_set_color(uint8_t color) {
	term_color = color;
}

static void term_put_at(char c, uint8_t color, size_t x, size_t y) {
	term_buffer[y * VGA_WIDTH + x] = vga_entry(c, color);
}

/* Scroll the whole screen up by one line when we run off the bottom. */
static void term_scroll(void) {
	for (size_t y = 1; y < VGA_HEIGHT; y++)
		for (size_t x = 0; x < VGA_WIDTH; x++)
			term_buffer[(y - 1) * VGA_WIDTH + x] = term_buffer[y * VGA_WIDTH + x];

	for (size_t x = 0; x < VGA_WIDTH; x++)
		term_buffer[(VGA_HEIGHT - 1) * VGA_WIDTH + x] = vga_entry(' ', term_color);
}

static void term_putchar(char c) {
	if (c == '\n') {
		term_col = 0;
		if (++term_row == VGA_HEIGHT) {
			term_scroll();
			term_row = VGA_HEIGHT - 1;
		}
		return;
	}

	term_put_at(c, term_color, term_col, term_row);
	if (++term_col == VGA_WIDTH) {
		term_col = 0;
		if (++term_row == VGA_HEIGHT) {
			term_scroll();
			term_row = VGA_HEIGHT - 1;
		}
	}
}

static void term_write(const char* data, size_t size) {
	for (size_t i = 0; i < size; i++)
		term_putchar(data[i]);
}

static void term_print(const char* s) {
	term_write(s, kstrlen(s));
}

/* --- Kernel entry point ----------------------------------------------------
 * Called from boot.s. Must NOT be named main() and must not return into a
 * runtime that does not exist. We loop forever at the end.
 */
void kernel_main(void) {
	term_init();

	term_set_color(vga_entry_color(VGA_COLOR_LIGHT_CYAN, VGA_COLOR_BLACK));
	term_print("Hello from a kernel that runs on bare metal.\n");

	term_set_color(vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK));
	term_print("\n");
	term_print("There is no operating system here -- this code IS the OS.\n");
	term_print("It was loaded by a Multiboot bootloader, set up its own\n");
	term_print("stack, and is now writing characters straight into video\n");
	term_print("memory at 0xB8000.\n\n");

	term_set_color(vga_entry_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK));
	term_print("kernel_main reached. Halting CPU.\n");

	/* Nothing left to do. Returning would go back to boot.s, which halts
	 * the CPU. We could also start scheduling, handle interrupts, talk to
	 * devices... but that is the rest of an OS. */
}
