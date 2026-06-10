#ifndef IDT_H
#define IDT_H
typedef struct{
    unsigned short base_lo,sel;
    unsigned char  always0,flags;
    unsigned short base_hi;
}__attribute__((packed)) idt_gate_t;
typedef struct{
    unsigned short limit;
    unsigned int   base;
}__attribute__((packed)) idt_register_t;
#define IDT_ENTRIES 256
extern idt_gate_t     idt[IDT_ENTRIES];
extern idt_register_t idt_reg;
void set_idt_gate(int n,unsigned int handler);
void set_idt();
#endif
