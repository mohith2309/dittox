# OurOS — Built From Scratch (HarmonyOS style)

A custom x86 OS built completely from zero, no Linux, no Android, no borrowed kernel. Inspired by how Huawei built HarmonyOS when they went fully independent.

## Architecture

```
BIOS
 └─ boot/boot.asm         512-byte MBR bootloader
      └─ boot/kernel_entry.asm  ASM -> C bridge
           └─ kernel/kernel.c    Kernel main
                ├─ cpu/idt.c          Interrupt Descriptor Table (256 entries)
                ├─ cpu/isr.c          32 CPU exceptions + 16 hardware IRQs
                ├─ cpu/interrupt.asm  Low-level stubs (NASM macros)
                ├─ cpu/timer.c        PIT at 50 Hz
                ├─ drivers/screen.c   VGA text 80x25 + scroll + cursor
                ├─ drivers/keyboard.c PS/2 keyboard via IRQ1
                └─ drivers/ports.c    x86 in/out port access
```

## Quick Start — macOS Apple Silicon M4

```bash
chmod +x setup.sh && ./setup.sh   # install nasm + qemu + i686-elf-gcc
make                               # build os-image
make run                           # launch in QEMU
make debug                         # attach GDB
```

## Boot Flow

```
BIOS loads sector 1 at 0x7c00
  -> INT 13h reads 31 sectors -> 0x1000
  -> GDT setup
  -> CR0 bit 0 = 1  (protected mode ON)
  -> far jump to 0x1000
  -> kernel_main()
       isr_install()   exception vectors
       irq_install()   PIC remap + STI
       init_timer(50)  IRQ0 @ 50Hz
       init_keyboard() IRQ1 echo
```

## Output

```
==============================================
        H A R M O N Y O S   (ours)
   Built from scratch. Zero dependencies.
==============================================

[ OK ] Kernel interrupts ready
[ OK ] Timer 50Hz
[ OK ] Keyboard ready

>
```

Type, backspace, enter — all work.

## Roadmap (Huawei's path)

- [x] Phase 1 — Bootloader + Protected Mode + VGA + Keyboard + Interrupts
- [ ] Phase 2 — Physical memory manager + paging
- [ ] Phase 3 — Shell with commands (echo, clear, help, meminfo)
- [ ] Phase 4 — FAT12 filesystem on floppy image
- [ ] Phase 5 — User-space processes + syscall interface
- [ ] Phase 6 — VBE/VESA graphical framebuffer
- [ ] Phase 7 — GUI window manager
