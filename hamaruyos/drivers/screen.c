#include "screen.h"
#include "ports.h"
#define CTRL 0x3d4
#define DATA 0x3d5
static int get_offset(int c,int r){return 2*(r*MAX_COLS+c);}
static int row_of(int o){return o/(2*MAX_COLS);}
static int col_of(int o){return(o-(row_of(o)*2*MAX_COLS))/2;}
static int get_cursor(){
    port_byte_out(CTRL,14);int o=port_byte_in(DATA)<<8;
    port_byte_out(CTRL,15);o+=port_byte_in(DATA);return o*2;
}
static void set_cursor(int o){
    o/=2;port_byte_out(CTRL,14);port_byte_out(DATA,(unsigned char)(o>>8));
    port_byte_out(CTRL,15);port_byte_out(DATA,(unsigned char)(o&0xff));
}
static void scroll(){
    unsigned char *v=(unsigned char*)VIDEO_ADDRESS;
    for(int i=1;i<MAX_ROWS;i++){
        unsigned char *dst=v+get_offset(0,i-1);
        unsigned char *src=v+get_offset(0,i);
        for(int j=0;j<MAX_COLS*2;j++) dst[j]=src[j];
    }
    unsigned char *last=v+get_offset(0,MAX_ROWS-1);
    for(int i=0;i<MAX_COLS*2;i++) last[i]=0;
}
static int print_char(char c,int col,int row,char attr){
    unsigned char *v=(unsigned char*)VIDEO_ADDRESS;
    if(!attr)attr=WHITE_ON_BLACK;
    int o=(col>=0&&row>=0)?get_offset(col,row):get_cursor();
    if(c=='\n'){row=row_of(o);o=get_offset(0,row+1);}
    else if(c=='\b'){o-=2;v[o]=' ';v[o+1]=(unsigned char)attr;}
    else{v[o]=(unsigned char)c;v[o+1]=(unsigned char)attr;o+=2;}
    if(o>=MAX_ROWS*MAX_COLS*2){scroll();o-=2*MAX_COLS;}
    set_cursor(o);return o;
}
void kprint_at(char *msg,int col,int row){
    int o=(col>=0&&row>=0)?get_offset(col,row):get_cursor();
    for(int i=0;msg[i];i++){row=row_of(o);col=col_of(o);o=print_char(msg[i],col,row,WHITE_ON_BLACK);}
}
void kprint(char *msg){kprint_at(msg,-1,-1);}
void kprint_backspace(){int o=get_cursor()-2;print_char('\b',col_of(o),row_of(o),WHITE_ON_BLACK);}
void clear_screen(){
    unsigned char *v=(unsigned char*)VIDEO_ADDRESS;
    for(int i=0;i<MAX_ROWS*MAX_COLS*2;i+=2){v[i]=' ';v[i+1]=WHITE_ON_BLACK;}
    set_cursor(get_offset(0,0));
}
