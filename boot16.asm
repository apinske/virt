[org 0x7c00]                    ; adresses relative to actual adress BIOS loads this sector

    mov bp, 0x8000              ; setup stack
    mov sp, bp

    mov bx, greeting
    call print
    mov bx, crlf
    call print

    mov bx, 0x1234
    call print_hex
    mov bx, crlf
    call print

    mov bx, 0xDADA
    call print_hex
    mov bx, crlf
    call print

    mov bx, 0x1000
    mov es, bx
    mov bx, 0x2000
    mov dh, 2
    ;mov dl, 0                  ; drive (0-based) - set by BIOS
    call disk_load

    mov bx, [es:0x2000]
    call print_hex
    mov bx, crlf
    call print

    mov bx, [es:0x2000+512]
    call print_hex
    mov bx, crlf
    call print

    jmp $

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
    jmp $

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
    db "Hello, world!", 0

crlf:
    db 13, 10, 0

DISK_ERROR_MSG:
    db "Disk read error! code=", 0

times 510-($-$$) db 0           ; Pad the boot sector out with zeros
dw 0xaa55                       ; Last two bytes form the magic number for boot sector

times 256 dw 0xdead ; sector 2 = 512 bytes
times 256 dw 0xbeef ; sector 3 = 512 bytes

