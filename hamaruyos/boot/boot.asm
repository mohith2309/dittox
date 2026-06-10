[org 0x7c00]

KERNEL_OFFSET equ 0x1000

[bits 16]

start:
    mov [BOOT_DRIVE], dl
    mov bp, 0x9000
    mov sp, bp
    call load_kernel
    call switch_to_pm
    jmp $

print_rm:
    pusha
    mov ah, 0x0e
.loop:
    mov al, [bx]
    cmp al, 0
    je .done
    int 0x10
    add bx, 1
    jmp .loop
.done:
    popa
    ret

disk_load:
    push dx
    mov ah, 0x02
    mov al, dh
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02
    int 0x13
    jc .disk_error
    pop dx
    cmp dh, al
    jne .count_error
    ret
.disk_error:
    mov bx, DISK_ERR_MSG
    call print_rm
    jmp $
.count_error:
    mov bx, SECT_ERR_MSG
    call print_rm
    jmp $

load_kernel:
    mov bx, KERNEL_OFFSET
    mov dh, 31
    mov dl, [BOOT_DRIVE]
    call disk_load
    ret

gdt_start:
    dd 0x00000000
    dd 0x00000000
gdt_code:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00
gdt_data:
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

switch_to_pm:
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or  eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:init_pm

[bits 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ebp, 0x90000
    mov esp, ebp
    jmp KERNEL_OFFSET

BOOT_DRIVE   db 0
DISK_ERR_MSG db "Disk error!", 0
SECT_ERR_MSG db "Bad sector count", 0

times 510-($-$$) db 0
dw 0xaa55
