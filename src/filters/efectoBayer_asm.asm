global efectoBayer_asm

section .data

AZUL : db 0x0, 0xFF, 0xFF, 0xFF,		0x4, 0xFF, 0xFF, 0xFF, 		0x8, 0xFF, 0xFF, 0xFF, 		0xC, 0xFF, 0xFF, 0xFF
ROJO : db  0xFF, 0xFF, 0x2, 0xFF,		0xFF, 0xFF, 0x6, 0xFF, 		0xFF, 0xFF, 0xA, 0xFF, 		0xFF, 0xFF, 0xE, 0xFF
VERDE : db 0xFF, 0x1, 0xFF, 0xFF,		0xFF, 0x5, 0xFF, 0xFF, 		0xFF, 0x9, 0xFF, 0xFF, 		0xFF, 0xD, 0xFF, 0xFF


section .text
efectoBayer_asm:
	;i rdi = *src, img in
	;i rsi = *dst, img out
	;i edx = filas;
	;i ecx = columnas
	;i r8d = srr_row_size

	;stack frame
	push rbp ;a
	mov rbp, rsp
	;sub rsp, 8
	
	shr ecx, 2
	movdqu xmm10, [AZUL]
	movdqu xmm11, [ROJO]
	movdqu xmm12, [VERDE]

	;recorro todas las filas
	mov r10d, 0
	ciclo_filas_bayer:
		cmp r10d, edx; r10d = fila actual
		je termino_ciclo_filas_bayer
		
			mov r8, 0
			ciclo_4_veces:
			cmp r8, 4
			je termino_ciclo_4_veces
				;recorro esta fila
					mov r11d, 0
					ciclo_fila_actual:
					
					cmp r11d, ecx; r11d = columna actual
					je termino_ciclo_fila_actual
					movdqu xmm0, [rdi];
					
						;elijo mask rojo o verde
						mov r9d, r11d
						and r9d, 1; r8d = r8d%2
						cmp r9d, 0
						je rojo
						pshufb xmm0, xmm12;[VERDE]
						jmp termino_filtro2
						rojo:
						pshufb xmm0, xmm11;[ROJO]
						termino_filtro2:
						;termino de aplicar mask
					
					;se lo cargo a la img out
					movdqu [rsi], xmm0;;
					;sigo iterando
					add rsi, 16;;
					add rdi, 16;;
					inc r11d
					jmp ciclo_fila_actual
				termino_ciclo_fila_actual:

				;inc fila y veo si era la ultima
				inc r10d
				cmp r10d, edx
				je termino_ciclo_filas_bayer
				inc r8
				jmp ciclo_4_veces
		termino_ciclo_4_veces:
		
		mov r8, 0
		ciclo_4_veces_2:
		cmp r8, 4
		je termino_ciclo_4_veces_2
				;recorro la siguiente fila
					mov r11d, 0
					ciclo_fila_actual_2:
					cmp r11d, ecx; r11d = col actual
					je termino_ciclo_fila_actual_2
					
					movdqu xmm0, [rdi];
					
						;elijo mask verde o azul
						mov r9d, r11d
						and r9d, 1; r8d = r8d%2
						cmp r9d, 0
						je verde
						pshufb xmm0, xmm10;[AZUL]
						jmp termino_filtro
						verde:
						pshufb xmm0, xmm12;[VERDE]
						termino_filtro:
						;termino de aplicar mask
						
					;se lo cargo a la img out
					movdqu [rsi], xmm0;;
					;si sigo iterando
					add rsi, 16;;
					add rdi, 16;;
					inc r11d
					jmp ciclo_fila_actual_2
				termino_ciclo_fila_actual_2:
				
				;inc fila y veo si era la ultima
				inc r10d
				cmp r10d, edx
				je termino_ciclo_filas_bayer
				inc r8
				jmp ciclo_4_veces_2
		termino_ciclo_4_veces_2:

		;vuelvo a hacer ""dos"" filas
		jmp ciclo_filas_bayer
		
	termino_ciclo_filas_bayer:
		
		;fin
		pop rbp
		ret



