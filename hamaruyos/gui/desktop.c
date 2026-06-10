#include "desktop.h"
#include "../drivers/vga.h"

#define C_DESK    VGA_ATTR(VGA_BLUE,  VGA_WHITE)
#define C_MENUBAR VGA_ATTR(VGA_LGRAY, VGA_BLACK)
#define C_TBAR    VGA_ATTR(VGA_DGRAY, VGA_LGRAY)
#define C_START   VGA_ATTR(VGA_GREEN, VGA_WHITE)
#define C_TRAY    VGA_ATTR(VGA_DGRAY, VGA_YELLOW)
#define C_WTITLE  VGA_ATTR(VGA_BLUE,  VGA_WHITE)
#define C_WBODY   VGA_ATTR(VGA_LGRAY, VGA_BLACK)
#define C_WBORD   VGA_ATTR(VGA_DGRAY, VGA_LGRAY)
#define C_WCLOSE  VGA_ATTR(VGA_RED,   VGA_WHITE)
#define C_ICON    VGA_ATTR(VGA_BLUE,  VGA_LCYAN)
#define C_ICONLBL VGA_ATTR(VGA_BLUE,  VGA_YELLOW)
#define C_SEP     VGA_ATTR(VGA_DGRAY, VGA_LGRAY)
#define C_INPUT   VGA_ATTR(VGA_WHITE, VGA_BLACK)
#define C_PROMPT  VGA_ATTR(VGA_LGRAY, VGA_LGREEN)

static char  ibuf[72];
static int   ilen = 0;

static void draw_window(int x, int y, int w, int h, const char *title) {
    vga_fill(x+1, y+1, w,   h,   ' ', VGA_ATTR(VGA_DGRAY, VGA_DGRAY));
    vga_fill(x,   y,   w,   1,   ' ', C_WTITLE);
    vga_str(x+2,  y,   title,     C_WTITLE);
    vga_str(x+w-9, y, " [-][\xFE][X]", C_WTITLE);
    vga_put(x+w-2, y, 'X', C_WCLOSE);
    vga_fill(x,   y+1, w,   h-2, ' ', C_WBODY);
    vga_vline(x,     y+1, h-2, '\xB3', C_WBORD);
    vga_vline(x+w-1, y+1, h-2, '\xB3', C_WBORD);
    vga_put(x,     y+h-1, '\xC0', C_WBORD);
    vga_hline(x+1, y+h-1, w-2,   '\xC4', C_WBORD);
    vga_put(x+w-1, y+h-1, '\xD9', C_WBORD);
}

static void draw_icon(int x, int y, const char *label) {
    vga_put(x,   y,   '\xDA', C_ICON);
    vga_put(x+1, y,   '\xC4', C_ICON);
    vga_put(x+2, y,   '\xBF', C_ICON);
    vga_put(x,   y+1, '\xDB', VGA_ATTR(VGA_BROWN, VGA_YELLOW));
    vga_put(x+1, y+1, ' ',    VGA_ATTR(VGA_BROWN, VGA_YELLOW));
    vga_put(x+2, y+1, '\xDB', VGA_ATTR(VGA_BROWN, VGA_YELLOW));
    vga_put(x,   y+2, '\xC0', C_ICON);
    vga_put(x+1, y+2, '\xC4', C_ICON);
    vga_put(x+2, y+2, '\xD9', C_ICON);
    vga_str(x,   y+3, label,  C_ICONLBL);
}

static void draw_welcome_content(int wx, int wy) {
    unsigned char a = C_WBODY;
    unsigned char g = VGA_ATTR(VGA_LGRAY, VGA_LGREEN);
    vga_str(wx+4, wy+1,  " ____  ____     ___  ____  ", g);
    vga_str(wx+4, wy+2,  "|  _ ||  _ |   / _ |/ ___| ", g);
    vga_str(wx+4, wy+3,  "| |_| | |_) | | | | |___ | ", g);
    vga_str(wx+4, wy+4,  "|  _ <|  _ <  | |_| |___) |", g);
    vga_str(wx+4, wy+5,  "|_| |_|_| |_|  |___|_____/ ", g);
    vga_hline(wx+2, wy+6,  52, '\xC4', VGA_ATTR(VGA_LGRAY, VGA_DGRAY));
    vga_str(wx+4, wy+7,  "  Built from scratch. Zero dependencies.", a);
    vga_str(wx+4, wy+8,  "  Inspired by how Huawei built HarmonyOS.", a);
    vga_hline(wx+2, wy+9,  52, '\xC4', VGA_ATTR(VGA_LGRAY, VGA_DGRAY));
    vga_str(wx+4, wy+10, "  CPU  : i686 32-bit Protected Mode", a);
    vga_str(wx+4, wy+11, "  BOOT : Custom BIOS MBR bootloader", a);
    vga_str(wx+4, wy+12, "  GFX  : VGA 80x25 Text (CP437)", a);
    vga_str(wx+4, wy+13, "  IRQs : PIC remapped, IDT 256 entries", a);
    vga_hline(wx+2, wy+14, 52, '\xC4', VGA_ATTR(VGA_LGRAY, VGA_DGRAY));
}

static void redraw_input(int wx, int wy) {
    int row = wy + 15;
    vga_fill(wx+2, row, 52, 1, ' ', C_INPUT);
    vga_put(wx+2, row, '\x10', C_PROMPT);
    vga_put(wx+3, row, ' ',    C_PROMPT);
    vga_str(wx+4, row, ibuf,   C_INPUT);
}

void desktop_draw() {
    vga_fill(0, 0, VGA_COLS, VGA_ROWS, ' ', C_DESK);

    vga_fill(0, 0, VGA_COLS, 1, ' ', C_MENUBAR);
    vga_str(2,  0, "AR OS",      VGA_ATTR(VGA_LGRAY, VGA_BLUE));
    vga_str(10, 0, "File",       C_MENUBAR);
    vga_str(16, 0, "View",       C_MENUBAR);
    vga_str(22, 0, "Settings",   C_MENUBAR);
    vga_str(32, 0, "Help",       C_MENUBAR);
    vga_str(68, 0, "12:00  Mon", VGA_ATTR(VGA_LGRAY, VGA_DGRAY));

    draw_icon(2,  2,  "My PC  ");
    draw_icon(2,  8,  "Docs   ");
    draw_icon(2,  14, "Trash  ");

    int wx = 10, wy = 1, ww = 58, wh = 19;
    draw_window(wx, wy, ww, wh, " Welcome to AR OS");
    draw_welcome_content(wx, wy);
    redraw_input(wx, wy);

    vga_hline(0, 22, VGA_COLS, '\xCD', C_SEP);

    vga_fill(0, 23, VGA_COLS, 1, ' ', C_TBAR);
    vga_str(0,  23, "\x10 Start ", C_START);
    vga_str(9,  23, "|", C_TBAR);
    vga_str(11, 23, "[ AR OS ]", VGA_ATTR(VGA_BLACK, VGA_LGRAY));
    vga_str(58, 23, "| EN | 12:00 |", C_TRAY);
    vga_str(72, 23, " \x0E\x0F ", VGA_ATTR(VGA_DGRAY, VGA_LCYAN));
}

void desktop_handle_key(char c) {
    if (c == '\b') {
        if (ilen > 0) ibuf[--ilen] = '\0';
    } else if (c == '\n') {
        ilen = 0;
        for (int i = 0; i < 72; i++) ibuf[i] = '\0';
    } else {
        if (ilen < 70) { ibuf[ilen++] = c; ibuf[ilen] = '\0'; }
    }
    redraw_input(10, 1);
}
