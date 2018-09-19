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
div 4

; rax = height*width/4 (puede pasarse)

; xmm0 = *src
ciclo_tresColores:
movdqu xmm0, [rdi]


add rdi, 16
loop ciclo_tresColores




pop rbp
ret