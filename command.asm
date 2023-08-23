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

; Load the first move into r9d
	mov	r9d, [r8]
	add	r8, 4

;;;;;;;;;;;;;;;;;;;;;num1;
; Print the first number ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov	rdi, buffer + 99
	movzx	rax, r9b
	inc	rax

.print_num1:
	xor	rdx, rdx
	mov	rbx, 10
	div	rbx

	add	rdx, '0'
	mov	[rdi], dl
	dec	rdi

	cmp	rax, 0
	jne	.print_num1

	inc	 rdi		; compensate for previous dec

	; push rcx because syscall modifies it
	push	rcx
	mov	rdx, buffer + 100
	sub	rdx, rdi
	mov	rsi, rdi
	mov	rax, 1
	mov	rdi, 1
	syscall
	pop	rcx
;;;;;;;;;;;;;;;;;;;;;num1;

;;;;;;;;;;;;;;;;;;;;;;num2;
; Print the second number ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	shr	r9d, 8
	mov	rdi, buffer + 99
	mov	[rdi], byte 10
	dec	rdi
	movzx	rax, r9b
	inc	rax

.print_num2:
	xor	rdx, rdx
	mov	rbx, 10
	div	rbx

	add	rdx, '0'
	mov	[rdi], dl
	dec	rdi

	cmp	rax, 0
	jne	.print_num2

	test	r9d, 0x00010000
	jnz	.is_x

	mov	[rdi], byte '-'
	jmp	.after_is_x

.is_x:
	mov	[rdi], byte 'x'

.after_is_x:
	push	rcx
	mov	rdx, buffer + 100
	sub	rdx, rdi
	mov	rsi, rdi
	mov	rax, 1
	mov	rdi, 1
	syscall
	pop	rcx
;;;;;;;;;;;;;;;;;;;;;;num2;
	jmp .loop
	
.end:
	mov	rax, rbx
	ret
; }}}

; command_swap_turn() {{{
; 
; Simply swaps the turn by using xor on the turn variable.
;
command_swap_turn:
	mov	al, [turn]
	xor	al, 0x3
	mov	[turn], al

	mov	rax, rbx
	ret
; }}}
