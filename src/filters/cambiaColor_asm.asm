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
to_pixel : db 0x0, 0x4, 0x8, 0xC,    0xFF, 0xFF, 0xFF, 0xFF,    0xFF, 0xFF, 0xFF, 0xFF,    0xFF, 0xFF, 0xFF, 0xFF

section .text
global cambiaColor_asm
cambiaColor_asm:
	;i rdi = *src, img in	unsigned char *src,
	;i rsi = *dst, img out	unsigned char *dst,
	;i edx = filas
	;i ecx = columnas	
	;i r8d = src_row_size	
	;i r9d = dst_row_size	
	;i [rsp + 0] = Nr	
	;i [rsp + 8] = Ng	
	;i [rsp + 16] = Nb	
	;i [rsp + 24] = Cr	
	;i [rsp + 32] = Cg	
	;i [rsp + 40] = Cb	
	;i [rsp + 48] = int lim	

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
	
	;calculo xmm10 = [0 Cr Cg Cb|0 Cr Cg Cb]
	mov r8b, [rsp+24]; Cr
	movd xmm10, r8d; [0000|000r]
	pslldq xmm10, 2; [0000|00r0]
	movd xmm11, r8d
	paddw xmm10, xmm11
	pslldq xmm10, 2; [0000|0rr0]
	mov r8b, [rsp+32]; Cg
	movd xmm11, r8d
	paddw xmm10, xmm11; [0000|0rrg]
	mov r8b, [rsp+40]; Cb
	movd xmm11, r8d
	paddw xmm10, xmm11; [0000|rrgb]
	movdqu xmm11, xmm10
	pslldq xmm11, 8
	paddw xmm10, xmm11; [0 Cr Cg Cb|0 Cr Cg Cb]
	
	;calculo xmm4 = [0 Nr Ng Nb|0 Nr Ng Nb]
	mov r8b, [rsp+0]; Nr
	movd xmm4, r8d; [0000|000r]
	pslldq xmm4, 2; [0000|00r0]
	movd xmm11, r8d
	paddw xmm4, xmm11
	pslldq xmm4, 2; [0000|0rr0]
	mov r8b, [rsp+8]; Ng
	movd xmm11, r8d
	paddw xmm4, xmm11; [0000|0rrg]
	mov r8b, [rsp+16]; Nb
	movd xmm11, r8d
	paddw xmm4, xmm11; [0000|rrgb]
	movdqu xmm11, xmm10
	pslldq xmm11, 8
	paddw xmm4, xmm11; [0 Nr Ng Nb|0 Nr Ng Nb]
	
	;calculo xmm1 = [0lim|0lim]
	mov r8d, [rsp+56]
	movd xmm1, r8d; [00|0lim]
	pslldq xmm1, 8; [0lim|00]
	movd xmm11, r8d
	paddw xmm1, xmm11; [0lim|0lim]

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
					pshufb xmm0, xmm11; [rrgb|rrgb] (primeros)
					
					;calculo xmm7 = [r'111|r'111]
					movdqu xmm6, xmm0
					pshufb xmm6, xmm13; [r000|r000]
					movdqu xmm7, xmm10
					pshufb xmm7, xmm13; [r000|r000]
					paddw xmm7, xmm6; [r'000|r'000]
					movdqu xmm2, [_1000_1000]
					paddw xmm7, xmm2; [r'111|r'111]
					
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
					;xmm1 = [0lim|0lim] _int
					;calculo xmm2=[0c|0c]
					cvtdq2ps xmm1, xmm1; to_float
					mulps xmm1, xmm1; xmm1=[0lim2|0lim2]
					movdqu xmm9, xmm1
					psllq xmm9, 24; 4 bytes
					addps xmm9, xmm1; xmm9 = [lim2lim2|lim2lim2]
					movdqu xmm2, xmm8
					divps xmm2, xmm9; xmm2 = [0c|0c]
					
					;calculo xmm1 = [d>=lim|d>=lim]
					cvttps2dq xmm8, xmm8; to_int [0d2|0d2]
					cvttps2dq xmm1, xmm1; to_int [0lim2|0lim2]
					pcmpgtd xmm1, xmm8; xmm1 = [0 lim>d | 0 lim>d]
			
					;calculo xmm8 = [0, Nr-r, Ng-g, Nb-b]*(1-c)
						;precalculo xmm8 = [0(1-c)|(1-c)(1-c)] primeros
						;			xmm9 = [0(1-c)|(1-c)(1-c)] segundos
						por xmm8, xmm8
						divps xmm8, xmm8; xmm8 = [11|11]
						subps xmm8, xmm2; xmm8 = [1(1-c)|1(1-c)]
						psllq xmm8, 24; 4bytes
						psrlq xmm8, 24; xmm8 = [0(1-c)|0(1-c)]
						movdqu xmm9, xmm8
						pslldq xmm9, 8; [0(1-c)00]
						movdqu xmm3, xmm9
						psrldq xmm3, 4
						addps xmm9, xmm3; [0(1-c)|(1-c)0]
						psrldq xmm3, 4
						addps xmm9, xmm3; [0(1-c)|(1-c)(1-c)] (segundos)
						psrldq xmm8, 8; [00|0(1-c)]
						movdqu xmm3, xmm8
						pslldq xmm3, 4
						addps xmm8, xmm3; [00|(1-c)(1-c)]
						pslldq xmm3, 4
						addps xmm8, xmm3; [0(1-c)|(1-c)(1-c)] (primeros)
						;tenemos xmm4 = [0 Nr Ng Nb|0 Nr Ng Nb]
						;precalculo xmm0 = [0rgb|0rgb]
						;			xmm1 = [0, Nr-r, Ng-g, Nb-b]
						movdqu xmm0, [rdi]; [argb|argb|argb|argb]
						pshufb xmm0, xmm11; [rrgb|rrgb]
						psllq xmm0, 16; [rgb0|rgb0]
						psrlq xmm0, 16; [0rgb|0rgb]
						movdqu xmm2, xmm0
						psrldq xmm2, 8
						pshufb xmm2, xmm15; [0 r g b] 
						movdqu xmm1, xmm4; [0 Nr Ng Nb|0 Nr Ng Nb]
						subps xmm1, xmm2; [0, Nr-r, Ng-g, Nb-b] (primeros)
						;multiplico
						mulps xmm8, xmm1; [0, Nr-r, Ng-g, Nb-b]*(1-c)
						movdqu xmm2, xmm0
						pshufb xmm2, xmm15; [0 r g b]
						movdqu xmm1, xmm4
						subps xmm1, xmm2; [0, Nr-r, Ng-g, Nb-b] (segundos)
						;multiplico
						mulps xmm9, xmm1; [0, Nr-r, Ng-g, Nb-b]*(1-c)	
						cvttps2dq xmm8, xmm8
						cvttps2dq xmm9, xmm9; to_int
						movdqu xmm3, [to_pixel]
						pshufb xmm8, xmm3; [0000|0000|0000|0rgb]
						pslldq xmm8, 12; [0rgb|0000|0000|0000]
						pshufb xmm9, xmm3
						pslldq xmm9, 8; [0000|0rgb|0000|0000]
						paddb xmm8, xmm9; [0rgb|0rgb|0000|0000]
						;quiero ver si hace falta sumarle xmm8 a xmm0
						;xmm1 = [0 lim>d | 0 lim>d] 
						movdqu xmm2, xmm1
						pslldq xmm2, 8; [0 lim>d| 0 0] snd
						psrldq xmm1, 4
						pslldq xmm1, 8; [lim>d 0| 0 0] fst
						paddw xmm1, xmm2; [lim>d, lim>d, 0, 0]
						;paso clave
						pand xmm8, xmm1; [alfa si lim<d, 0 si no]
						;se lo sumo al [rdi] actual
						movdqu xmm0, [rdi]; [argb|argb|argb|argb] 
						psrldq xmm0, 8; [0000|0000|0rgb|0rgb]
						pslldq xmm0, 8; [0rgb|0rgb|0000|0000]	
						paddb xmm0, xmm8			
									
					;se lo cargo a la img out
						;paddb xmm0, xmm15; devuelvo A
					movdqu [rsi], xmm0;;
					
							;;vuelvo a hacer toda la iteracion con los otros dos pixeles
							movdqu xmm0, [rdi]; [argb|argb|argb|argb]
							pslldq xmm0, 8
							pshufb xmm0, xmm11; [rrgb|rrgb] (segundos)
							
							;calculo xmm7 = [r'111|r'111]
							movdqu xmm6, xmm0
							pshufb xmm6, xmm13; [r000|r000]
							movdqu xmm7, xmm10
							pshufb xmm7, xmm13; [r000|r000]
							paddw xmm7, xmm6; [r'000|r'000]
							movdqu xmm2, [_1000_1000]
							paddw xmm7, xmm2; [r'111|r'111]
							
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
							;xmm1 = [0lim|0lim] _int
							;calculo xmm2=[0c|0c]
							cvtdq2ps xmm1, xmm1; to_float
							mulps xmm1, xmm1; xmm1=[0lim2|0lim2]
							movdqu xmm9, xmm1
							psllq xmm9, 24; 4 bytes
							addps xmm9, xmm1; xmm9 = [lim2lim2|lim2lim2]
							movdqu xmm2, xmm8
							divps xmm2, xmm9; xmm2 = [0c|0c]
							
							;calculo xmm1 = [d>=lim|d>=lim]
							cvttps2dq xmm8, xmm8; to_int [0d2|0d2]
							cvttps2dq xmm1, xmm1; to_int [0lim2|0lim2]
							pcmpgtd xmm1, xmm8; xmm1 = [0 lim>d | 0 lim>d]
					
							;calculo xmm8 = [0, Nr-r, Ng-g, Nb-b]*(1-c)
								;precalculo xmm8 = [0(1-c)|(1-c)(1-c)] primeros
								;			xmm9 = [0(1-c)|(1-c)(1-c)] segundos
								por xmm8, xmm8
								divps xmm8, xmm8; xmm8 = [11|11]
								subps xmm8, xmm2; xmm8 = [1(1-c)|1(1-c)]
								psllq xmm8, 24; 4bytes
								psrlq xmm8, 24; xmm8 = [0(1-c)|0(1-c)]
								movdqu xmm9, xmm8
								pslldq xmm9, 8; [0(1-c)00]
								movdqu xmm3, xmm9
								psrldq xmm3, 4
								addps xmm9, xmm3; [0(1-c)|(1-c)0]
								psrldq xmm3, 4
								addps xmm9, xmm3; [0(1-c)|(1-c)(1-c)] (segundos)
								psrldq xmm8, 8; [00|0(1-c)]
								movdqu xmm3, xmm8
								pslldq xmm3, 4
								addps xmm8, xmm3; [00|(1-c)(1-c)]
								pslldq xmm3, 4
								addps xmm8, xmm3; [0(1-c)|(1-c)(1-c)] (primeros)
								;tenemos xmm4 = [0 Nr Ng Nb|0 Nr Ng Nb]
								;precalculo xmm0 = [0rgb|0rgb]
								;			xmm1 = [0, Nr-r, Ng-g, Nb-b]
								movdqu xmm0, [rdi]; [argb|argb|argb|argb]
								pslldq xmm0, 8
								pshufb xmm0, xmm11; [rrgb|rrgb] (segundos)
								psllq xmm0, 16; [rgb0|rgb0] 2bytes
								psrlq xmm0, 16; [0rgb|0rgb] 2bytes
								movdqu xmm2, xmm0
								psrldq xmm2, 8
								pshufb xmm2, xmm15; [0 r g b] 
								movdqu xmm1, xmm4; [0 Nr Ng Nb|0 Nr Ng Nb]
								subps xmm1, xmm2; [0, Nr-r, Ng-g, Nb-b] (primeros)
								;multiplico
								mulps xmm8, xmm1; [0, Nr-r, Ng-g, Nb-b]*(1-c)
								movdqu xmm2, xmm0
								pshufb xmm2, xmm15; [0 r g b]
								movdqu xmm1, xmm4
								subps xmm1, xmm2; [0, Nr-r, Ng-g, Nb-b] (segundos)
								;multiplico
								mulps xmm9, xmm1; [0, Nr-r, Ng-g, Nb-b]*(1-c)	
								cvttps2dq xmm8, xmm8
								cvttps2dq xmm9, xmm9; to_int
								movdqu xmm3, [to_pixel]
								pshufb xmm8, xmm3; [0000|0000|0000|0rgb]
								pslldq xmm8, 12; [0rgb|0000|0000|0000]
								pshufb xmm9, xmm3
								pslldq xmm9, 8; [0000|0rgb|0000|0000]
								paddb xmm8, xmm9; [0rgb|0rgb|0000|0000]
								;quiero ver si hace falta sumarle xmm8 a xmm0
								;xmm1 = [0 lim>d | 0 lim>d] 
								movdqu xmm2, xmm1
								pslldq xmm2, 8; [0 lim>d| 0 0] snd
								psrldq xmm1, 4
								pslldq xmm1, 8; [lim>d 0| 0 0] fst
								paddw xmm1, xmm2; [lim>d, lim>d, 0, 0]
								;paso clave
								pand xmm8, xmm1; [alfa si lim<d, 0 si no]
								;se lo sumo al [rdi] actual
								movdqu xmm0, [rdi]; [argb|argb|argb|argb] 
								psrldq xmm8, 8; [0000|0000|0rgb|0rgb]
								paddb xmm0, xmm8
								movdqu xmm1, [rsi]
								paddb xmm1, xmm0
								movdqu [rsi], xmm1		
											
							;se lo cargo a la img out
								;paddb xmm0, xmm15; devuelvo A
							movdqu [rsi], xmm1;;
					
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
