global efectoBayer_asm

section .data
;mask_rvrv : db 0xFF, 0xFF, 0x2, 0xFF, 0xFF, 0xFF, 0xFF, 0X7, 0xFF, 0xFF, 0XA, 0xFF, 0xFF, 0xFF, 0xFF, 0XF
mask_rvrv : db 0x2, 0xFF, 0XFF, 0XFF, 0X5, 0xFF, 0XFF, 0XFF, 0x10, 0xFF, 0XFF, 0XFF, 0XD, 0xFF, 0XFF, 0XFF; ?
mask_vava : db 0xFF, 0x1, 0xFF, 0xFF, 0xFF, 0xFF, 0X6, 0xFF, 0xFF, 0X9, 0xFF, 0xFF, 0xFF, 0xFF, 0XE, 0xFF

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
	
	shl edx, 2
	movdqu xmm10, [mask_rvrv]
	movdqu xmm11, [mask_vava]

	;recorro todas las filas
	mov r10d, 0
	ciclo_filas_bayer:
		cmp r10d, edx; r10d = fila actual
		je termino_ciclo_filas_bayer
		;recorro esta fila
			mov r11d, 0
			ciclo_fila_actual:
			
			cmp r11d, ecx; r11d = columna actual
			je termino_ciclo_fila_actual

			movdqu xmm0, [rdi]; xmm0 = [rgba|rgba|rgba|rgba]
			pshufb xmm0, xmm10; xmm0 = [r000|0g00|r000|0g00]
			;se lo cargo a la img out
			movdqu [rsi], xmm0;;
			;sigo iterando
			add rsi, 16;;
			add rdi, 16;;
			add r11d, 16
			jmp ciclo_fila_actual
		termino_ciclo_fila_actual:

		;inc fila y veo si era la ultima
		inc r10d
		cmp r10d, edx
		je termino_ciclo_filas_bayer
		
			;;hago exactamente lo mismo para la proxima fila
				mov r11d, 0
			ciclo_fila_actual_repito:
				
				cmp r11d, ecx; r11d = columna actual
				je termino_ciclo_fila_actual_repito

				movdqu xmm0, [rdi]; xmm0 = [rgba|rgba|rgba|rgba]
				pshufb xmm0, xmm10; xmm0 = [r000|0g00|r000|0g00]
				;se lo cargo a la img out
				movdqu [rsi], xmm0;;
				;sigo iterando
				add rsi, 16;;
				add rdi, 16;;
				add r11d, 16
				jmp ciclo_fila_actual_repito
			termino_ciclo_fila_actual_repito:
			;inc fila y veo si era la ultima
			inc r10d
			cmp r10d, edx
			je termino_ciclo_filas_bayer
		
		;recorro la siguiente fila
			mov r11d, 0
			ciclo_fila_actual_2:
			cmp r11d, ecx; r11d = col actual
			je termino_ciclo_fila_actual_2
			
			movdqu xmm0, [rdi]; xmm0 = [rgba|rgba|rgba|rgba]
			pshufb xmm0, xmm11; xmm0 = [0g00|00b0|0g00|00b0]
			;se lo cargo a la img out
			movdqu [rsi], xmm0;;
			;si sigo iterando
			add rsi, 16;;
			add rdi, 16;;
			add r11d, 16
			jmp ciclo_fila_actual_2
		termino_ciclo_fila_actual_2:
		
			;inc fila y veo si era la ultima
			inc r10d
			cmp r10d, edx
			je termino_ciclo_filas_bayer
			;;hago exactamente lo mismo para la proxima fila
				mov r11d, 0
			ciclo_fila_actual_2repito:
				
				cmp r11d, ecx; r11d = columna actual
				je termino_ciclo_fila_actual_2repito

				movdqu xmm0, [rdi]; xmm0 = [rgba|rgba|rgba|rgba]
				pshufb xmm0, xmm11; xmm0 = [0g00|00b0|0g00|00b0]
				;se lo cargo a la img out
				movdqu [rsi], xmm0;;
				;sigo iterando
				add rsi, 16;;
				add rdi, 16;;
				add r11d, 16
				jmp ciclo_fila_actual_2repito
			termino_ciclo_fila_actual_2repito:
		
		;incremento fila
		inc r10d
		;vuelvo a hacer "dos*2" filas
		jmp ciclo_filas_bayer
		
	termino_ciclo_filas_bayer:
		
		;fin
		pop rbp
		ret






