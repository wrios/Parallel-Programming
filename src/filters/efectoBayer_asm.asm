global efectoBayer_asm

section .data
mask_rvrv : db 0xFF, 0xFF, 0x2, 0xFF, 0xFF, 0xFF, 0xFF, 0X7, 0xFF, 0xFF, 0XA, 0xFF, 0xFF, 0xFF, 0xFF, 0XF
mask_vava : db 0xFF, 0x1, 0xFF, 0xFF, 0xFF, 0xFF, 0X6, 0xFF, 0xFF, 0X9, 0xFF, 0xFF, 0xFF, 0xFF, 0XE, 0xFF

section .text
efectoBayer_asm:
	;i rdi = *src, img in
	;i rsi = *dst, img out
	;i edx = filas;
	;i ecx = columnas
	;i r8d = srr_row_size
	;rbx = *src
	;r12d = edx = filas (mul pisa edx)

	;stack frame
	push rbp ;a
	mov rbp, rsp
	push rbx ;d
	push r12
	;sub rsp, 8
	
	mov rbx, rdi
	mov r12d, edx
	movdqu xmm10, [mask_rvrv]
	movdqu xmm11, [mask_vava]

	;recorro todas las filas
	mov r10d, 0
	ciclo_filas_bayer:
	cmp r10d, r12d; r10d = fila actual
	je termino_ciclo_filas_bayer
		;recorro esta fila
		mov r11d, 0
		ciclo_fila_actual:
		
		cmp r11d, ecx; r11d = columna actual
		je termino_ciclo_fila_actual
		;calculo indice actual
		mov edi, r10d
		mov eax, ecx
		mul edi; edi = n*r10d
		add edi, r11d; edi = n * fil actual + indice col
		mov edi, edi
		movdqu xmm0, [rbx + rdi]; xmm0 = [rgba|rgba|rgba|rgba]
		pshufb xmm0, xmm10; xmm0 = [r000|0g00|r000|0g00]
		;se lo cargo a la img out
		movdqu [rsi + rdi], xmm0
		;sigo iterando
		add r11d, 16
		jmp ciclo_fila_actual
		termino_ciclo_fila_actual:

		;si era la ultima fila
		inc r10d
		cmp r10d, r12d
		je termino_ciclo_filas_bayer
		
		;recorro la siguiente fila
		mov r11d, 0
		ciclo_fila_actual_2:
		cmp r11d, ecx; r11d = col actual
		je termino_ciclo_fila_actual_2
		;calculo indice actual
		mov edi, r10d
		mov eax, ecx
		mul edi; edi = n*r10d
		add edi, r11d; edi = n * fil pasadas + indice col
		movdqu xmm0, [rbx + rdi]; xmm0 = [rgba|rgba|rgba|rgba]
		pshufb xmm0, xmm11; xmm0 = [0g00|00b0|0g00|00b0]
		;se lo cargo a la img out
		movdqu [rsi + rdi], xmm0
		;si sigo iterando
		add r11d, 16
		jmp ciclo_fila_actual_2
		termino_ciclo_fila_actual_2:
		
		;si era la ultima fila
		inc r10d
		cmp r10d, r12d
		je termino_ciclo_filas_bayer
		
		;vuelvo a hacer "dos" filas
		mov r11d, 0
		jmp ciclo_fila_actual
		
	termino_ciclo_filas_bayer:
		
		;fin
		pop r12
		pop rbx
		pop rbp
		ret


