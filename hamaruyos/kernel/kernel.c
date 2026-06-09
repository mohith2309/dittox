#include "../drivers/screen.h"
#include "../drivers/keyboard.h"
#include "../cpu/isr.h"
#include "../cpu/timer.h"

void kernel_main() {
    clear_screen();
    kprint("==============================================\n");
    kprint("        H A R M O N Y O S   (ours)           \n");
    kprint("   Built from scratch. Zero dependencies.    \n");
    kprint("==============================================\n");
    kprint("\n");
    isr_install();
    irq_install();
    init_timer(50);
    init_keyboard();
    kprint("[ OK ] Kernel interrupts ready\n");
    kprint("[ OK ] Timer 50Hz\n");
    kprint("[ OK ] Keyboard ready\n");
    kprint("\n> ");
}
