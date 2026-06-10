#include "vga.h"
#include "ports.h"

void vga_put(int x, int y, char c, unsigned char attr) {
    if ((unsigned)x >= VGA_COLS || (unsigned)y >= VGA_ROWS) return;
    unsigned char *v = (unsigned char *)VGA_ADDR;
    int off = 2*(y*VGA_COLS+x);
    v[off] = (unsigned char)c; v[off+1] = attr;
}
void vga_str(int x, int y, const char *s, unsigned char attr) {
    for (int i = 0; s[i] && x+i < VGA_COLS; i++) vga_put(x+i, y, s[i], attr);
}
void vga_fill(int x, int y, int w, int h, char c, unsigned char attr) {
    for (int j = y; j < y+h; j++)
        for (int i = x; i < x+w; i++) vga_put(i, j, c, attr);
}
void vga_hline(int x, int y, int w, char c, unsigned char attr) {
    for (int i = 0; i < w; i++) vga_put(x+i, y, c, attr);
}
void vga_vline(int x, int y, int h, char c, unsigned char attr) {
    for (int i = 0; i < h; i++) vga_put(x, y+i, c, attr);
}
void vga_box(int x, int y, int w, int h, unsigned char ba, unsigned char fa) {
    vga_fill(x+1, y+1, w-2, h-2, ' ', fa);
    vga_put(x,     y,     '\xDA', ba);
    vga_put(x+w-1, y,     '\xBF', ba);
    vga_put(x,     y+h-1, '\xC0', ba);
    vga_put(x+w-1, y+h-1, '\xD9', ba);
    vga_hline(x+1, y,     w-2, '\xC4', ba);
    vga_hline(x+1, y+h-1, w-2, '\xC4', ba);
    vga_vline(x,     y+1, h-2, '\xB3', ba);
    vga_vline(x+w-1, y+1, h-2, '\xB3', ba);
}
void vga_clear(unsigned char attr) { vga_fill(0,0,VGA_COLS,VGA_ROWS,' ',attr); }
void vga_disable_cursor() {
    port_byte_out(0x3D4, 0x0A);
    port_byte_out(0x3D5, 0x20);
}
