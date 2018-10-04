section .data
%define off_next_proceso 4
%define off_mov_2_word 16
%define div_4 2
    align 16
    maskF: times 8 DW 0xFFFF ;8 veces 0xFFFF
    mask4: DW 0, times 6 DW 0xFFFF, DW 0

section .text

global edgeSobel_asm
edgeSobel_asm:
	;void edgeSobel_c(
    ;rdi = unsigned char *src,
    ;rsi = unsigned char *dst,
    ;edx = int width,
    ;ecx = int height,
    ;r8d = int src_row_size,
    ;r9d = int dst_row_size)
    mov xmm12, [maskF]
	mov xmm11, [mask4]
	mov r13d, ecx; r13 cantidad de filas
	mov r14d, edx; r14 cantidad de columnas
	;cantidad de iteraciones sin contar la ultima fila
	;la ultima fila tiene el proceso un poco diferente por lectura invalida
	sub ecx, 3
	;se recorre n-3 filas con el loop 
	add rdi, r13 
	cicloFilasEdge:
	mov r12d, edx; r12 cantidad de columnas
	shrx r12, div_4
	cicloColumnasEdge:

	;cargando primer bloque de pixeles
	movdqu xmm1,[rdi+r14*0]
	movdqu xmm2,[rdi+r14*1]
	movdqu xmm3,[rdi+r14*2]
	;guardando(para empaquetar) parte baja del bloque a modificar
	punpckhbw xmm15, xmm2
	;extension de los bytes a trabajar
	punpcklbw xmm4, xmm1
	punpcklbw xmm5, xmm2
	punpcklbw xmm6, xmm3
	;Calculando Operador X
	;sumatoria en xmm4
	paddw xmm4, xmm5
	paddw xmm4, xmm5
	paddw xmm4, xmm6
	;sumatoria desde p2..p7,0,0(word)
	movdqu xmm5, xmm4
	psllw xmm4, off_mov_2_word
	;Operador X en xmm4
	psubw xmm4, xmm5
	;Calculando Operador Y
	;Solo usa la fila superior y la fila inferior
	;fila superior - fila inferior
	punpckhbw xmm7, xmm1
	punpckhbw xmm8, xmm3
	psubw xmm7, xmm8

	movdqu xmm8, xmm7
	movdqu xmm9, xmm7
	;2*(P_{i-fila} - P_{i+fila})
	paddw xmm8, xmm8
	pslldq xmm7, 1
	psrldq xmm9, 1
	paddw xmm8, xmm7
	paddw xmm8, xmm9
	pabsw xmm8, xmm8
	;Operador Y en xmm8
	pabsw xmm4, xmm4
	paddw xmm8, xmm8
	paddw xmm4, xmm8
	;mask4 filtra los 4 word
	;filtrando parte alta para empaquetado
	pand xmm5, xmm11
	pxor xmm11, xmm12
	pand xmm4, xmm11
	paddw xmm4, xmm5
	packuswb xmm4, xmm10
	movdqu [rsi], xmm4
	lea rdi, [rdi+off_next_proceso]
	lea rsi, [rsi+off_next_proceso]
	sub r12, 1
	cmp r12, 0
	jne columnas
	loop cicloFilasEdge

	;precesando ultima fila
	mov ecx, r14d;columnas
	shrx ecx, 2;columnas/4
	sub ecx, 1; elprimer proceso, es de 6 bytes, los otros de a 4
	sub rdi, 8

	cicloEdgeUltimaFila:
	;cargando primer bloque de pixeles
	movdqu xmm1,[rdi+r14*0]
	movdqu xmm2,[rdi+r14*1]
	movdqu xmm3,[rdi+r14*2]
	;guardando(para empaquetar) parte baja del bloque a modificar
	punpcklbw xmm15, xmm2
	;extension de los bytes a trabajar
	punpckhbw xmm4, xmm1
	punpckhbw xmm5, xmm2
	punpckhbw xmm6, xmm3
	;Calculando Operador X
	;sumatoria en xmm4
	paddw xmm4, xmm5
	paddw xmm4, xmm5
	paddw xmm4, xmm6
	movdqu xmm5, xmm4
	;sumatoria desde p2..p7,0,0(word)
	psllw xmm4, off_mov_2_word
	;Operador X en xmm4
	psubw xmm4, xmm5
	;Calculando Operador Y
	;Solo usa la fila superior y la fila inferior
	;fila superior - fila inferior
	punpckhbw xmm7, xmm1; fila inferior
	punpckhbw xmm8, xmm3; fila superior
	psubw xmm7, xmm8

	movdqu xmm8, xmm7
	movdqu xmm9, xmm7
	;2*(P_{i-fila} - P_{i+fila})
	paddw xmm8, xmm8
	pslldq xmm7, 1
	psrldq xmm9, 1
	paddw xmm8, xmm7
	paddw xmm8, xmm9
	pabsw xmm8, xmm8
	;Operador Y en xmm8
	pabsw xmm4, xmm4
	paddw xmm8, xmm8
	paddw xmm4, xmm8
	;mask4 filtra los 4 word
	;filtrando parte alta para empaquetado
	pand xmm5, xmm1
	pxor xmm1, xmm12
	pand xmm4, xmm1
	paddw xmm4, xmm5
	packuswb xmm4, xmm10
	movdqu [rsi], xmm4
	lea rdi, [rdi+off_next_proceso]
	lea rsi, [rsi+off_next_proceso]
	loop cicloEdgeUltimaFila
	ret