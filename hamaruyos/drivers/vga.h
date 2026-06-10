#ifndef VGA_H
#define VGA_H
#define VGA_ADDR 0xB8000
#define VGA_COLS 80
#define VGA_ROWS 25
#define VGA_ATTR(bg,fg) ((unsigned char)(((bg)<<4)|((fg)&0x0F)))
#define VGA_BLACK   0
#define VGA_BLUE    1
#define VGA_GREEN   2
#define VGA_CYAN    3
#define VGA_RED     4
#define VGA_LGRAY   7
#define VGA_DGRAY   8
#define VGA_LBLUE   9
#define VGA_LGREEN 10
#define VGA_LCYAN  11
#define VGA_YELLOW 14
#define VGA_WHITE  15
#define VGA_BROWN   6
void vga_put(int x, int y, char c, unsigned char attr);
void vga_str(int x, int y, const char *s, unsigned char attr);
void vga_fill(int x, int y, int w, int h, char c, unsigned char attr);
void vga_hline(int x, int y, int w, char c, unsigned char attr);
void vga_vline(int x, int y, int h, char c, unsigned char attr);
void vga_box(int x, int y, int w, int h, unsigned char ba, unsigned char fa);
void vga_clear(unsigned char attr);
void vga_disable_cursor();
#endif
