#ifndef SCREEN_H
#define SCREEN_H
#define VIDEO_ADDRESS  0xb8000
#define MAX_ROWS       25
#define MAX_COLS       80
#define WHITE_ON_BLACK 0x0f
#define GREEN_ON_BLACK 0x0a
#define RED_ON_BLACK   0x0c
void clear_screen();
void kprint(char *msg);
void kprint_at(char *msg, int col, int row);
void kprint_backspace();
#endif
