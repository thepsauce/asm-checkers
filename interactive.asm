; Declared in checkers.asm
extern grid
extern turn

; Declared in command.asm
extern command_quit
extern command_show_moves
extern command_swap_turn

section .data
	global buffer
	pretty:
		db "   --- --- --- --- --- --- --- --- ", 10
		db "1 |   |   |   |   |   |   |   |   |", 10
		db "  |--- --- --- --- --- --- --- ---|", 10
		db "2 |   |   |   |   |   |   |   |   |", 10
		db "  |--- --- --- --- --- --- --- ---|", 10
		db "3 |   |   |   |   |   |   |   |   |", 10
		db "  |--- --- --- --- --- --- --- ---|", 10
		db "4 |   |   |   |   |   |   |   |   |", 10
		db "  |--- --- --- --- --- --- --- ---|", 10
		db "5 |   |   |   |   |   |   |   |   |", 10
		db "  |--- --- --- --- --- --- --- ---|", 10
		db "6 |   |   |   |   |   |   |   |   |", 10
		db "  |--- --- --- --- --- --- --- ---|", 10
		db "7 |   |   |   |   |   |   |   |   |", 10
		db "  |--- --- --- --- --- --- --- ---|", 10
		db "8 |   |   |   |   |   |   |   |   |", 10
		db "   --- --- --- --- --- --- --- --- ", 10
		db "    H   G   F   E   D   C   B   A  ", 10
	nPretty: equ $ - pretty
	input: db 0
	buffer: times 100 db 0

section .rodata
	prettyOffsets:
		dw  44,  52,  60,  68,
		dw 112, 120, 128, 136,
		dw 188, 196, 204, 212,
		dw 256, 264, 272, 280,
		dw 336, 344, 352, 360,
		dw 400, 408, 416, 424,
		dw 476, 484, 492, 500,
		dw 544, 552, 560, 568

section .text
	global pretty_refresh
	global pretty_draw
	global read_move

; pretty_refresh() {{{
;
; Updates the pretty data using the grid data and
; outputs it to the terminal.
;
pretty_refresh:
	xor	rcx, rcx

.loop_grid:
	mov	al, [grid + rcx]
	cmp	al, 0
	je	.no_piece

	movzx	rbx, word [prettyOffsets + rcx * 2]

; Test for white piece bit
	test	al, 0x1
	jz	.black_piece

.white_piece:
	mov	byte [pretty + rbx], 'o'
	jmp	.no_piece

.black_piece:
	mov	byte [pretty + rbx], '*'

.no_piece:
	inc	rcx
	cmp	rcx, 32
	jne	.loop_grid

	mov	rax, 1
	mov	rdi, 1
	mov	rsi, pretty
	mov	rdx, nPretty
	syscall

	ret
; }}}

; read_move() {{{
;
; Output:
;	rax - First number
;	rbx - Second number
;
read_move:

;;;;;;;;;;;;;input;
; Read user input ;
;;;;;;;;;;;;;;;;;;;

; Skip until a new line
; r8 - buffer address
	mov	r8, buffer
.loop_newline:
	mov	rax, 0
	mov	rdi, 0
	mov	rsi, input
	mov	rdx, 1
	syscall

; End at a new line
; al - character
	mov	al, [input]
	cmp	al, 10
	je	.end_loop_newline

; Check for buffer overflow, excess characters are ignored
	cmp	r8, buffer + 99
	je	.loop_newline

; Write the character to the buffer
	mov	[r8], al
	inc	r8

	jmp	.loop_newline

.end_loop_newline:
	; Add null terminator
	mov	[r8], byte 0
;;;;;;;;;;;;;input;

;;;;;;;;;;;;;;;;;;;;;buffer;
; Parse the buffer content ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; rax - first number
; rbx - second number
; rcx - buffer count
; rdi - buffer pointer
;
; Valid formats are:
; [number]x[number]
; [number]-[number]

	xor	rax, rax
	xor	rbx, rbx
	xor	rdx, rdx
	mov	rcx, r8
	sub	rcx, buffer
	mov	rdi, buffer
.loop_blank:
; Go back all the way if the buffer is blank
	cmp	rcx, 0
	je	read_move

; Get the next character
	mov	dl, [rdi]
	inc	rdi
	dec	rcx

	cmp	dl, ' '
	je	.loop_blank
	cmp	dl, 0x9 ; \t
	je	.loop_blank

; Branch into special commands
	cmp	dl, 'q'
	je	command_quit
	cmp	dl, 'v'
	je	command_show_moves
	cmp	dl, 's'
	je	command_swap_turn

.loop_number1:
; Check for a delimiter
	cmp	dl, 'x'
	je	.end_number1
	cmp	dl, '-'
	je	.end_number1

; Check if the input is a digit
	sub	dl, '0'
	cmp	dl, 0
	jl	read_move
	cmp	dl, 9
	jg	read_move

; Multiply rax by 10
	shl	rax, 1
	mov	r8, rax
	shl	rax, 2
	add	rax, r8

; Add the digit to rax
	add	rax, rdx

	mov	dl, [rdi]
	inc	rdi
	dec	rcx

	jmp	.loop_number1

.end_number1:

.loop_number2:
	mov	dl, [rdi]
	inc	rdi
	dec	rcx

; Check if we are at the end
	cmp	dl, 0
	je	.end_number2

	cmp	dl, 0
	sub	dl, '0'
	cmp	dl, 0
	jl	read_move
	cmp	dl, 9
	jg	read_move

	shl	rbx, 1
	mov	r8, rbx
	shl	rbx, 2
	add	rbx, r8

	add	rbx, rdx

	jmp	.loop_number2

.end_number2:

;;;;;;;;;;;;;;;;;;;;;buffer;
	ret
; }}}
