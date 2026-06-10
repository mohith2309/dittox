#include "idt.h"
idt_gate_t     idt[IDT_ENTRIES];
idt_register_t idt_reg;
void set_idt_gate(int n,unsigned int h){
    idt[n].base_lo=h&0xffff;idt[n].sel=0x08;
    idt[n].always0=0;idt[n].flags=0x8e;
    idt[n].base_hi=(h>>16)&0xffff;
}
void set_idt(){
    idt_reg.base=(unsigned int)&idt;
    idt_reg.limit=IDT_ENTRIES*sizeof(idt_gate_t)-1;
    __asm__ volatile("lidt (%0)"::"r"(&idt_reg));
}
