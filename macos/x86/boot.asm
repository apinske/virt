[org 0x7c00]                    ; adresses relative to actual adress BIOS loads this sector
    mov bp, 0x8000              ; setup stack
    mov sp, bp

    mov bx, greeting
    call print

    mov bx, 0x1000
    mov es, bx
    mov bx, 0x2000
    mov dh, 9
    ;mov dl, 0                  ; drive (0-based) - set by BIOS
    call disk_load              ; load to [es:bx]=0x12000

    cli                         ; switch to 32-bit protected mode
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp CODE_SEG:init_pm

disk_load:                      ; load DH sectors to ES:BX from drive DL
    push dx
    mov ah, 0x02                ; disk I/O
    mov al, dh                  ; sector count
    mov ch, 0                   ; 1st cylinder (0-based)
    mov dh, 0                   ; 1st head (0-based)
    mov cl, 2                   ; 2nd sector (1-based)
    int 0x13                    ; read into [es:bx]
    jc disk_error
    pop dx
    cmp al, dh                  ; check read sector count
    jne disk_error
    ret
disk_error:
    mov bx, DISK_ERROR_MSG
    call print
    mov bh, ah ; error http://stanislavs.org/helppc/int_13-1.html
    mov bl, dl ; drive
    call print_hex
    hlt

print:                          ; print char* in bx
    pusha
print_loop_start:
    mov ax, [bx]
    mov ah, 0
    cmp ax, 0
    je print_loop_end
    call print_ch
    inc bx
    jmp print_loop_start
print_loop_end:
    popa
    ret

print_hex:                      ; print hex-string in bx as 0x0000
    pusha
    mov ax, '0'
    call print_ch
    mov ax, 'x'
    call print_ch
    mov ax, bx
    rol ax, 4
    call print_hex_ch
    rol ax, 4
    call print_hex_ch
    rol ax, 4
    call print_hex_ch
    rol ax, 4
    call print_hex_ch
    popa
    ret

print_hex_ch:                   ; print hex-char in al & 0x0F
    pusha
    and ax, 0x000F
    add ax, 0x30
    cmp ax, 0x39
    jle print_hex_ch_next
    add ax, 7
print_hex_ch_next:
    call print_ch
    popa
    ret

print_ch:                       ; print char in al
    pusha
    mov ah, 0x0e
    int 0x10
    popa
    ret

greeting:
    db "Hello from real mode.", 0

DISK_ERROR_MSG:
    db "Disk read error. code=", 0

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
    hlt

begin_pm:
    mov ebx, greeting32
    call print32
    call 0x12000                 ; kernel
    ret

print32:
    ;0xb8000 + 2 * (row * 80 + col)
    pusha
    mov edx, 0xb8000
print32_loop_start:
    mov al, [ebx]
    mov ah, 0x0f
    cmp al, 0
    je print32_loop_end
    mov [edx+1440], ax
    add ebx, 1
    add edx, 2
    jmp print32_loop_start
print32_loop_end:
    popa
    ret

greeting32:
    db "Hello from protected mode.", 0

times 510-($-$$) db 0           ; Pad the boot sector out with zeros
dw 0xaa55                       ; Last two bytes form the magic number for boot sector

