; Declared in checkers.asm

extern grid
extern turn

; Declared in moves.asm
extern moves
extern nMoves

; Declated in interactive.asm
extern buffer

section .text
	global command_quit
	global command_show_moves
	global command_swap_turn

; command_quit() {{{
;
; Exits the program.
;
command_quit:
	mov	rax, 60		; syscall number for sys_exit
	xor	rdi, rdi	; exit code 0
	syscall
; }}}

; command_show_moves() {{{
;
; Shows all moves possible.
;
command_show_moves:
	mov	r8, moves
	mov	cx, [nMoves]
.loop:
	cmp	cx, 0
	je	.end
	dec	cx

	mov	rdi, buffer

	mov	r9d, [r8]
	add	r8, 4

; TODO: print r9d formatted
	
.end:
	ret
; }}}

; TODO:
command_swap_turn:
	ret
