; Declared in moves.asm 
extern get_moves
extern get_all_moves
extern play_move
extern moves
extern nMoves

section .data
	global grid
	global turn
	grid: times 32 db 0
	turn: db 0
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
	nPretty equ $-pretty
    codes: dw 44, 52, 60, 68, 112, 120, 128, 136, 188, 196, 204, 212, 256, 264, 272, 280, 336, 344, 352, 360, 400, 408, 416, 424, 476, 484, 492, 500, 544, 552, 560, 568
    input: db "12"
    dummy: db 0

section .text
	global	_start

_start:
; ===== Setup =====
	; White begins
	mov	[turn], byte 1
	; Setup white pieces
	mov	[grid +  0], byte 1
	mov	[grid +  1], byte 1
	mov	[grid +  2], byte 1
	mov	[grid +  3], byte 1
	mov	[grid +  4], byte 1
	mov	[grid +  5], byte 1
	mov	[grid +  6], byte 1
	mov	[grid +  7], byte 1
	mov	[grid +  8], byte 1
	mov	[grid +  9], byte 1
	mov	[grid + 10], byte 1
	mov	[grid + 11], byte 1
	; Setup black pieces
	mov	[grid + 20], byte 2
	mov	[grid + 21], byte 2
	mov	[grid + 22], byte 2
	mov	[grid + 23], byte 2
	mov	[grid + 24], byte 2
	mov	[grid + 25], byte 2
	mov	[grid + 26], byte 2
	mov	[grid + 27], byte 2
	mov	[grid + 28], byte 2
	mov	[grid + 29], byte 2
	mov	[grid + 30], byte 2
	mov	[grid + 31], byte 2
; =================

.game_loop:
; TODO: Print grid
    call populate
    call draw

	mov	rsi, 8
	mov	rdi, moves
	call	get_all_moves
	cmp	[nMoves], byte 0
	je	.game_over
; TODO: Get user input
    call get_input
    mov r9, r8
    call get_input

; TODO: Check if input is valid

	; Example:
	; mov	al, 9		; From square
	; mov	bl, 14		; To square
    mov rax, r9
    mov rbx, r8
	
	call play_move

	jmp	.game_loop

.game_over:
	; Exit the program
	mov	rax, 60             ; syscall number for sys_exit
	xor	rdi, rdi            ; exit code 0
	syscall

populate:
    mov rsi, grid
    mov rdi, codes
    xor rcx, rcx
.loop_grid:
    mov r8b, [rsi+rcx]
    cmp r8b, 0
    je .no_piece
    mov rax, 2
    mul rcx
    mov bx, [rdi+rax]
    cmp r8b, 1
    jne .black_piece
    mov byte [pretty+rbx], 'o'
    jmp .no_piece
.black_piece:
    mov byte [pretty+rbx], '*'
.no_piece:
    inc rcx
    cmp rcx, 32
    jne .loop_grid
    ret

draw:
    mov rax, 1
    mov rdi, 1
    mov rsi, pretty
    mov edx, nPretty
    syscall
    ret

get_input:
    ; takes a two byte input
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 2
    syscall
    ; for Return character
	mov rax, 0
	mov rdi, 0
	mov rsi, dummy
	mov rdx, 1
    syscall

    mov rax, [input]
    mov bl, ah
    mov r8b, bl
    sub r8b, 48
    mov bl, al
    sub rbx, 48
    mov rax, 10
    mul bl
    add r8, rax
    ret

