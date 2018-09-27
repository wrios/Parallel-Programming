tres: dd 0x03000000, 0x03000000, 0x03000000, 0x03000000 ; Reversado re loco little endian friendly
cientoSetenta: dd 0xAA000000, 0xAA000000, 0xAA000000, 0xAA000000 
cientoCiencuentaYNueve: dd 0xA9000000, 0xA9000000, 0xA9000000, 0xA9000000 
ochentaYCinco: dd 0x55000000, 0x55000000, 0x55000000, 0x55000000
muchasF: dd 0xFFFF, 0xFFFFF, 0xFFFFF, 0xFFFFF

crema: dd 0x00D6E9EC , 0x00D6E9EC, 0x00D6E9EC, 0x00D6E9EC ; LITTLE ENDIAN
verde: dd 0x006E7000, 0x006E7000, 0x006E7000, 0x006E7000 ; LITTLE ENDIn
rojo: dd 0x004158F4, 0x004158F4, 0x004158F4, 0x004158F4 ; little endian

global tresColores_asm

;void tresColores_asm (unsigned char *src, unsigned char *dst, int width, int height,
;                      int src_row_size, int dst_row_size);

; rdi = *src
; rsi = *dst
; edx = width
; ecx = height
; r8d = src_row_size
; r9d = dst_row_size

tresColores_asm:
push rbp
mov rbp, rsp

; el mov anda ok porque setea parte alta en cero
mov eax, edx
mul ecx
add rax, rdi; en rax termina la imagen

    ; xmm0 = *src
    ciclo_tresColores:
    cmp rdi, rax
    jmp fin_tresColores
    movdqu xmm0, [rdi]; xmm0=|r|g|b|a|...

    movaps xmm1, xmm0
    pslld xmm1, 24; xmm1=|0|0|0|r|...
    movaps xmm2, xmm0
    psrld xmm2, 8; xmm2=|g|b|a|0|...
    pslld xmm2, 24; xmm2=|0|0|0|g|...
    movaps xmm3, xmm0
    psrld xmm3, 16; xmm2=|b|a|0|0|...
    pslld xmm3, 24; xmm2=|0|0|0|b|...
    ;guardo la suma en xmm1
    paddsw xmm1, xmm2; xmm1=|0|0|0|r+g|...
    paddsw xmm1, xmm3; xmm1=|0|0|0|r+g+b|...
    ;xmm1 paso los ints a floats
    movaps xmm7, xmm1
    cvtdq2ps xmm1, xmm7
    ;divido cada suma por 3 parte entera
    movdqu xmm15, [tres]
    divps xmm1, xmm15
    ;vuelvo a int
    cvtps2dq xmm1, xmm1
    ; xmm1 = [0 0 0 W_1 | 0 0 0 W_2 | 0 0 0 W_3 | 0 0 0 W_4] en int
    pcmpgtd xmm1, cientoCiencuentaYNueve ; cada W_i > 169 (>= 170)
    ; en xmm0 algo así [FFFF|0000|FFFF|FFFF] (ej.)
    pxor xmm0, muchasF
    ; en xmm0 tengo 0 donde elto falsos y -1 donde true
    mov xmm2, crema; guardo en otro registro para no perder los valores
    pand xmm2, xmm0 ; me quedo solo con los valores que me dieron true
    ; en xmm2 tengo los valores de "crema" en cada pixel que debería

    pcmpgtd xmm1, ochentaYCinco
    ; NOT = 1111 XOR xmmAlgo
    







    ;sigo iterando
    add rdi, 16; aumento 4 pixeles
    loop ciclo_tresColores

fin_tresColores:

pop rbp
ret