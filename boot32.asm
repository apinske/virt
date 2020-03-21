[org 0x7c00]                    ; adresses relative to actual adress BIOS loads this sector

    mov bp, 0x8000              ; setup stack
    mov sp, bp

    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:init_pm

    jmp $

gdt_start: ; don't remove the labels, they're needed to compute sizes and jumps
    ; the GDT starts with a null 8-byte
    dd 0x0 ; 4 byte
    dd 0x0 ; 4 byte

; GDT for code segment. base = 0x00000000, length = 0xfffff
; for flags, refer to os-dev.pdf document, page 36
gdt_code:
    dw 0xffff    ; segment length, bits 0-15
    dw 0x0       ; segment base, bits 0-15
    db 0x0       ; segment base, bits 16-23
    db 10011010b ; flags (8 bits)
    db 11001111b ; flags (4 bits) + segment length, bits 16-19
    db 0x0       ; segment base, bits 24-31

; GDT for data segment. base and length identical to code segment
; some flags changed, again, refer to os-dev.pdf
gdt_data:
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0

gdt_end:

; GDT descriptor
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; size (16 bit), always one less of its true size
    dd gdt_start ; address (32 bit)

; define some constants for later use
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

[bits 32]
init_pm: ; we are now using 32-bit instructions
    mov ax, DATA_SEG ; 5. update the segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000 ; 6. update the stack right at the top of the free space
    mov esp, ebp

    call begin_pm
    jmp $

begin_pm:
   mov ebx, MSG
   call print32
   jmp $

print32:
    pusha
    ;0xb8000 + 2 * (row * 80 + col)
    mov edx, 0xb8000
print32_loop_start:
    mov al, [ebx]
    mov ah, 0x0f
    cmp al, 0
    je print32_loop_end
    mov [edx], ax
    add ebx, 1
    add edx, 2
    jmp print32_loop_start
print32_loop_end:
    popa
    ret

MSG:
    db "Hello!", 0

times 510-($-$$) db 0           ; Pad the boot sector out with zeros
dw 0xaa55                       ; Last two bytes form the magic number for boot sector

