#include "ports.h"
unsigned char port_byte_in(unsigned short port) {
    unsigned char r;
    __asm__ volatile ("in %%dx,%%al":"=a"(r):"d"(port));
    return r;
}
void port_byte_out(unsigned short port, unsigned char data) {
    __asm__ volatile ("out %%al,%%dx"::"a"(data),"d"(port));
}
unsigned short port_word_in(unsigned short port) {
    unsigned short r;
    __asm__ volatile ("in %%dx,%%ax":"=a"(r):"d"(port));
    return r;
}
void port_word_out(unsigned short port, unsigned short data) {
    __asm__ volatile ("out %%ax,%%dx"::"a"(data),"d"(port));
}
