global efectoBayer_asm

mask_rvrv : db 0xFF, 0xFF, 0x2, 0xFF, 0xFF, 0xFF, 0xFF, 0X7, 0xFF, 0xFF, 0XA, 0xFF, 0xFF, 0xFF, 0xFF, 0XF
mask_vava : db 0xFF, 0x1, 0xFF, 0xFF, 0xFF, 0xFF, 0X6, 0xFF, 0xFF, 0X9, 0xFF, 0xFF, 0xFF, 0xFF, 0XE, 0xFF

efectoBayer_asm:
	;i rdi = *src, img in
	;i rsi = *dst, img out
	;i edx = filas
	;i ecx = columnas
	;i r8d = srr_row_size
	;rbx = *src

	;stack frame
	push rbp ;alin
	mov rbp, rsp
	push rbx ;desalin
	sub rsp, 8
	
	movdqu xmm10, [mask_rvrv]
	movdqu xmm11, [mask_vava]
	shr ecx, 3; ecx /= 8

	;recorro todas las filas
	mov r10d, 0
	ciclo_filas_bayer:
	cmp r10d, edx
	je termino_ciclo_filas_bayer
		;recorro esta fila
		mov r11d, 0
		ciclo_fila_actual:
		cmp r11d, ecx
		je termino_ciclo_fila_actual
		;calculo indice actual
		mov edi, r10d
		mov eax, ecx
		mul edi; edi = n*r10d
		shr edi, 3; *=8
		add edi, r11d; edi = n * fil pasadas + indice col
		movdqu xmm0, [rbx + rdi]; xmm0 = [rgba|rgba|rgba|rgba]
		pshufb xmm0, xmm10; xmm0 = [r000|0g00|r000|0g00]
		;se lo cargo a la img out
		movdqu [rsi + rdi], xmm0
		;sigo iterando
		inc r11d
		jmp ciclo_fila_actual
		termino_ciclo_fila_actual:

		inc r10d
		cmp r10d, edx
		je termino_ciclo_filas_bayer
		;recorro la siguiente fila
		mov r11d, 0
		ciclo_fila_actual_2:
		cmp r11d, ecx
		je termino_ciclo_fila_actual_2
		;calculo indice actual
		mov edi, r10d
		mov eax, ecx
		mul edi; edi = n*r10d
		shr edi, 3; *=8
		add edi, r11d; edi = n * fil pasadas + indice col
		movdqu xmm0, [rbx + rdi]; xmm0 = [rgba|rgba|rgba|rgba]
		pshufb xmm0, xmm11; xmm0 = [0g00|00b0|0g00|00b0]
		;se lo cargo a la img out
		movdqu [rsi + rdi], xmm0
		;sigo iterando
		inc r11d
		jmp ciclo_fila_actual_2
		termino_ciclo_fila_actual_2:
	termino_ciclo_filas_bayer:
		
		;fin
		pop rbx
		pop rbp
		ret



