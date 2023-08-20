; Declared in moves.asm 
extern get_moves
extern get_all_moves
extern play_move
extern moves
extern nMoves

section .data
	grid: times 32 db 0
	turn: db 0

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
	call	get_all_moves
	cmp	[nMoves], byte 0
	je	.game_over
; TODO: Get user input

; TODO: Check if input is valid

	; Example:
	mov	al, 9		; From square
	mov	bl, 14		; To square
	
	call play_move

	jmp	.game_loop

.game_over:
	; Exit the program
	mov	rax, 60             ; syscall number for sys_exit
	xor	rdi, rdi            ; exit code 0
	syscall
