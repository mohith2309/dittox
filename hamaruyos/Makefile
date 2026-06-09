CC      = i686-elf-gcc
LD      = i686-elf-ld
ASM     = nasm
CFLAGS  = -m32 -ffreestanding -fno-stack-protector -nostdlib -Wall -Wextra -std=c11
LDFLAGS = -m elf_i386

C_SOURCES := $(wildcard kernel/*.c drivers/*.c cpu/*.c)
C_OBJS    := $(C_SOURCES:.c=.o)
ASM_OBJS  := boot/kernel_entry.o cpu/interrupt.o

all: os-image

os-image: boot/boot.bin kernel.bin
	cat $^ > $@

kernel.bin: $(ASM_OBJS) $(C_OBJS)
	$(LD) $(LDFLAGS) -o $@ -Ttext 0x1000 $^ --oformat binary

kernel.elf: $(ASM_OBJS) $(C_OBJS)
	$(LD) $(LDFLAGS) -o $@ -Ttext 0x1000 $^

boot/boot.bin: boot/boot.asm
	$(ASM) -f bin -o $@ $<

boot/kernel_entry.o: boot/kernel_entry.asm
	$(ASM) -f elf -o $@ $<

cpu/interrupt.o: cpu/interrupt.asm
	$(ASM) -f elf -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

run: os-image
	qemu-system-i386 -fda os-image

debug: os-image kernel.elf
	qemu-system-i386 -s -S -fda os-image &
	i686-elf-gdb kernel.elf -ex "target remote :1234" -ex "break kernel_main" -ex "continue"

clean:
	rm -f os-image kernel.bin kernel.elf
	rm -f boot/*.bin boot/*.o kernel/*.o drivers/*.o cpu/*.o

.PHONY: all run debug clean
