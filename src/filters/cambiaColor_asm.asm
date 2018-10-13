section .data

AZUL : db 0x0, 0xFF, 0xFF, 0xFF,		0x4, 0xFF, 0xFF, 0xFF, 		0x8, 0xFF, 0xFF, 0xFF, 		0xC, 0xFF, 0xFF, 0xFF
ROJO : db  0xFF, 0xFF, 0x2, 0xFF,		0xFF, 0xFF, 0x6, 0xFF, 		0xFF, 0xFF, 0xA, 0xFF, 		0xFF, 0xFF, 0xE, 0xFF
VERDE : db 0xFF, 0x1, 0xFF, 0xFF,		0xFF, 0x5, 0xFF, 0xFF, 		0xFF, 0x9, 0xFF, 0xFF, 		0xFF, 0xD, 0xFF, 0xFF
AAAA : db 0xFF, 0xFF, 0xFF, 0x3,		0xFF, 0xFF, 0xFF, 0x7, 		0xFF, 0xFF, 0xFF, 0xB, 		0xFF, 0xFF, 0xFF, 0xF

pixel_1_2 : db 0x8, 0xFF, 0x9, 0xFF,    0xA, 0xFF, 0xA, 0xFF,    0xC, 0xFF, 0xD, 0xFF,    0xE, 0xFF, 0xE, 0xFF
azul_adelante : db 0xFF, 0xFF, 0xFF, 0xFF,    0xFF, 0xFF, 0x0, 0x1,    0xFF, 0xFF, 0xFF, 0xFF,    0xFF, 0xFF, 0x8, 0x9
rojo_adelante : db 0xFF, 0xFF, 0xFF, 0xFF,    0xFF, 0xFF, 0x4, 0x5,    0xFF, 0xFF, 0xFF, 0xFF,    0xFF, 0xFF, 0xC, 0xD
constantes : dw 3.0, 4.0, 2.0, 0.001953125
segundos_params : dw 0x0, 0xFF,  0x1, 0xFF,  0x2, 0xFF,  0x3, 0xFF
_1000_1000 : dw 0xFF, 0xFF, 0xFF, 0x1,    0xFF, 0xFF, 0xFF, 0x1

section .text
global cambiaColor_asm
cambiaColor_asm:
	;i rdi = *src, img in
	;i rsi = *dst, img out
	;i edx = filas;
	;i ecx = columnas
	;i r8d = src_row_size
	;i r9d = dst_row_size
	;i [rsp + 0] = Nr
	;i [rsp + 8] = Nr
	;i [rsp + 16] = Ng
	;i [rsp + 24] = Nb
	;i [rsp + 32] = Cr
	;i [rsp + 40] = Cg
	;i [rsp + 48] = Cb
	;i [rsp + 56] = int lim

	;stack frame
	push rbp ;a
	mov rbp, rsp
	;sub rsp, 8
	
	shr ecx, 2; leo de a 4
	movdqu xmm11, [pixel_1_2]
	movdqu xmm12, [azul_adelante]
	movdqu xmm13, [rojo_adelante]
	movdqu xmm14, [constantes]
	movdqu xmm15, [segundos_params]
	movdqu xmm4, [_1000_1000]
	
	;calculo xmm10 = [0 Cr Cg Cb|0 Cr Cg Cb]
	mov r8b, [rsp+32]; Cr
	movd xmm10, r8d; [0000|000r]
	pslldq xmm10, 2; [0000|00r0]
	movd xmm11, r8d
	paddw xmm10, xmm11
	pslldq xmm10, 2; [0000|0rr0]
	mov r8b, [rsp+40]; Cg
	movd xmm11, r8d
	paddw xmm10, xmm11; [0000|0rrg]
	mov r8b, [rsp+48]; Cb
	movd xmm1, r8d
	paddw xmm10, xmm11; [0000|rrgb]
	movdqu xmm11, xmm10
	pslldq xmm11, 8
	paddw xmm10, xmm11; [0 Cr Cg Cb|0 Cr Cg Cb]
	
	;calculo xmm1 = [lim2|lim2]
	mov r8d, [rsp+56]
	movd xmm1, r8d; [00|0lim]
	pslldq xmm1, 8; [0lim|00]
	movd xmm11, r8d
	paddw xmm1, xmm11; [0lim|0lim]
	pmulld xmm1, xmm1; [0lim2|0lim2]

	;recorro todas las filas
	mov r10d, 0
	ciclo_filas:
		cmp r10d, edx; r10d = fila actual
		je termino_ciclo_filas
		
				;recorro esta fila
					mov r11d, 0
					ciclo_fila_actual:
					cmp r11d, ecx; r11d = columna actual
					je termino_ciclo_fila_actual
					
					movdqu xmm0, [rdi]; [argb|argb|argb|argb]
					pshufb xmm0, xmm11; [rrgb|rrgb]
					
					;calculo xmm7 = [r'111|r'111]
					movdqu xmm6, xmm0
					pshufb xmm6, xmm13; [r000|r000]
					movdqu xmm7, xmm10
					pshufb xmm7, xmm13; [r000|r000]
					paddw xmm7, xmm6; [r'000|r'000]
					paddw xmm7, xmm4; [r'111|r'111]
					
					;calculo xmmo = [d2|d2]
					;precalculo xmm0 = [Δr2-b2,Δr2,Δg2,Δb2|Δr2-b2,Δr2,Δg2,Δb2]
					psubw xmm0, xmm10; [ΔrΔrΔgΔb|ΔrΔrΔgΔb]
					pmullw xmm0, xmm0; [Δr2Δr2Δg2Δb2|Δr2Δr2Δg2Δb2]
						;calculo xmm5 = [Δb2000|Δb2000]
						movdqu xmm5, xmm0
						pshufb xmm5, xmm12; [Δb2000|Δb2000]
					psubw xmm0, xmm5; xmm0=[Δr2-b2,Δr2,Δg2,Δb2|Δr2-b2,Δr2,Δg2,Δb2]
					
					;calculo xmm8 = [0d2|0d2]
					movdqu xmm2, xmm7
					psrldq xmm2, 4
					pshufb xmm2, xmm15; [r'111] primeros
					cvtdq2ps xmm2, xmm2
					movdqu xmm3, xmm7
					pshufb xmm3, xmm15; [r'111] segundos
					cvtdq2ps xmm3, xmm3			
					movdqu xmm9, xmm0
					pshufb xmm9, xmm15; [Δr2-b2,Δr2,Δg2,Δb2] segundos
					psrldq xmm0, 4
					movdqu xmm8, xmm9
					pshufb xmm8, xmm15; [Δr2-b2,Δr2,Δg2,Δb2] primeros
					;to_float
					;mutiplico por las constantes
					cvtdq2ps xmm8, xmm8
					mulps xmm8, xmm14
					cvtdq2ps xmm9, xmm9
					mulps xmm9, xmm14
					;mutiplico por el r'
					mulps xmm8, xmm2
					mulps xmm9, xmm3
					;sumo
					movdqu xmm2, xmm8
					psrldq xmm2, 8
					addps xmm8, xmm2
					movdqu xmm2, xmm8
					psrldq xmm2, 4
					addps xmm8, xmm2; [***d2]
					pslldq xmm8, 12
					psrldq xmm8, 4; [0d'00]
					movdqu xmm3, xmm9
					psrldq xmm3, 8
					addps xmm9, xmm3
					movdqu xmm3, xmm9
					psrldq xmm3, 4
					addps xmm9, xmm3; [***d2]
					pslldq xmm9, 12
					psrldq xmm9, 12; [000d']
					addps xmm8, xmm9
					
					;xmm8 = [0d2|0d2] _float
					;xmm1 = [lim2|lim2] _int8bytes
					movdqu xmm9, xmm1
					movdqu xmm2, xmm9
					psllq xmm2, 24
					addps xmm8, xmm9
					
					cvtpd2dq xmm8, xmm8; esta bien ?
					pcmpgtq xmm8, xmm1; q?
					
					;...
					;...
					
				
				
								
										
					;se lo cargo a la img out
						;paddb xmm0, xmm15; devuelvo A
					movdqu [rsi], xmm0;;
					;sigo iterando
					add rsi, 16;;
					add rdi, 16;;
					inc r11d
					jmp ciclo_fila_actual
				termino_ciclo_fila_actual:

		;inc fila y sigo
		;iterando o termino
		inc r10d
		cmp r10d, edx
		je termino_ciclo_filas
		jmp ciclo_filas
		
	termino_ciclo_filas:
		
		;fin
		pop rbp
ret
