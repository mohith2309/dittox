#include "keyboard.h"
#include "ports.h"
#include "../cpu/isr.h"
#include "../gui/desktop.h"

static char sc_ascii[128]={
    0,27,'1','2','3','4','5','6','7','8','9','0','-','=','\b',
    '\t','q','w','e','r','t','y','u','i','o','p','[',']','\n',
    0,'a','s','d','f','g','h','j','k','l',';','\'','`',
    0,'\\','z','x','c','v','b','n','m',',','.','/',0,
    '*',0,' ',0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};
static void kb_handler(registers_t *r){
    (void)r;
    unsigned char sc=port_byte_in(0x60);
    if(sc&0x80)return;
    char c=(sc<128)?sc_ascii[(int)sc]:0;
    if(c) desktop_handle_key(c);
}
void init_keyboard(){register_interrupt_handler(IRQ1,kb_handler);}
