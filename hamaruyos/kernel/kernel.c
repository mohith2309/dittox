#include "../drivers/vga.h"
#include "../drivers/keyboard.h"
#include "../cpu/isr.h"
#include "../cpu/timer.h"
#include "../gui/desktop.h"

void kernel_main() {
    vga_clear(VGA_ATTR(VGA_BLACK, VGA_LCYAN));
    vga_str(27, 11, "AR OS is starting...", VGA_ATTR(VGA_BLACK, VGA_WHITE));

    isr_install();
    irq_install();
    init_timer(50);
    init_keyboard();

    vga_disable_cursor();
    desktop_draw();
}
