[bits 32]
[org 0x12000]                   ; adresses relative to actual adress we load this sector

kernel:
    call kernel_sub
    mov al, 'X'
    mov ah, 0x0f
    mov[0xb8000+2240], ax
    mov ebx, kernel_helo
    call print32
    jmp $

print32:
    ;0xb8000 + 2 * (row * 80 + col)
    pusha
    mov edx, 0xb8000
print32_loop_start:
    mov al, [ebx]
    mov ah, 0x0f
    cmp al, 0
    je print32_loop_end
    mov [edx+2400], ax
    add ebx, 1
    add edx, 2
    jmp print32_loop_start
print32_loop_end:
    popa
    ret

greeting32:
    db "Hello from protected mode!", 0

dummy:
    nop
    nop

kernel_sub:
    mov al, 'X'
    mov ah, 0x0f
    mov[0xb8000+2242], ax
    ret

kernel_helo:
    db "Hello from the kernel!", 0

times 512-($-kernel) db 0 ; sector 2 = 512 bytes
times 256 dw 0xbeef ; sector 3 = 512 bytes

