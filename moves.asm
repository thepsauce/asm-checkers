; Declared in checkers.asm
extern grid
extern turn

section .data
	global moves
	global extraMoves
	global nMoves
	; 0 - source
	; 1 - destination
	; 2 - flags
	; 3 - additional
	moves: times 48 dq 0
	extraMoves: times 12 dq 0
	nMoves: dw 0
	
section .rodata
	offsets:
		db -9, -7, -4, -3, 4, 5, 7, 9
		db -9, -7, -5, -4, 3, 4, 7, 9

section .text
	global get_moves
	global get_all_moves
	global play_move

; get_moves(index, destination) {{{
; Gets all moves of a single piece
;
; Input:
;	rsi - Index of the piece
;	rdi - Index where to store the piece
;
; Output:
;	rsi - Incremented by one
;	rdi - Current move index
;
get_moves:

; r8 (row) = (rsi (current index) * 2) / 8
	mov	r8, rsi
	shl	r8, 1
	shr	r8, 3

; al (piece) = grid[rsi]
	mov	al, [grid + rsi]

; Check if it's the piece's turn
	test	al, [turn]
	jz	.end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;range;
; Get the right range of offsets ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; r10 - Address of offsets
; r11 - Number of offsets
	mov	r10, offsets
	mov	r11, 4
	add	r10, 4

; If we have an odd row, we use the second offset list
	mov	r12, r8
	and	r12, 0x1
	shl	r12, 3
	add	r10, r12

; If the piece is a queen, we use 8 offsets
	movzx	r12, al
	and	r12, 0x4
	setnz	bl
	add	r11, r12

; If the piece is black or a queen, we use negative offsets
	mov	ah, al
	and	ah, 0x2
	shl	ah, 1
	and	bl, ah
	movzx	r12, bl
	shl	r12, 2
	sub	r10, r12
;;;;;;;;;;;;;;;;;;;;;;;;;;;;range;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;offset;
; Check all offsets for a valid move ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.loop_offsets:

; ah (difference) = [r10] (offset)
	mov	dl, [r10]
	mov	ah, dl

; rbx (bl, source) = rsi (current index)
	mov	rbx, rsi

; bh (destination) = bl (source) + ah (difference)
	mov	bh, bl
	add	bh, ah

; Check if the destination is out of bounds
	cmp	bh, 0
	jl	.next_offset
	cmp	bh, 32
	jge	.next_offset

; Check if the destination is already occupied
	mov	cl, bh
	movzx	r12, cl
	cmp	[grid + r12], byte 0
	jnz	.next_offset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;diagonal;
; Check if the source and destination are diagonal to each other ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; cl - source column
; ch - source row
; dl - destination column
; dh - destination row
	; Rotate rbx back and forth to store and restore the original values
	rol	rbx, 16
	shl	bl, 1
	shl	bh, 1
	mov	cl, bl
	mov	dl, bh
	mov	ch, bl
	mov	dh, bh
	shr	ch, 3
	test	ch, 1
	setz	bl
	shr	dh, 3
	test	dh, 1
	setz	bh
	and	cl, 0x7
	add	cl, bl
	and	dl, 0x7
	add	dl, bh

; Move (cl, ch) into the higher word of rcx
	mov	bl, cl
	mov	bh, ch
	shl	rcx, 16
	mov	cl, bl
	mov	ch, bh

; Move (dl, dh) into the higher word of rdx
	mov	bl, dl
	mov	bh, dh
	shl	rdx, 16
	mov	dl, bl
	mov	dh, bh
	ror	rbx, 16

	sub	cl, dl
	jnl	.not_negate_cl
	neg	cl

.not_negate_cl:
	sub	ch, dh
	jnl	.not_negate_ch
	neg	ch

.not_negate_ch:
	; If row and column difference are not equal, then they are
	; not diagonal to each other.
	cmp	cl, ch
	jnz	.next_offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;diagonal;

	mov	[rdi], bl
	inc	rdi
	mov	[rdi], bh
	inc	rdi

	; Check for a double move
	cmp	ah, -5
	jl	.double_move
	cmp	ah, 5
	jg	.double_move

	mov	[rdi], byte 0
	inc	rdi
	mov	[rdi], byte 0
	inc	rdi

	jmp	.next_offset

.double_move:
;;;;;;;;;;;;;;middle;
; Get middle square ;
;;;;;;;;;;;;;;;;;;;;;

; Restore the lower c and d registers
	shr	rcx, 16
	shr	rdx, 16

; cl = ((cl + dl) / 2 + (ch + dh) / 2 * 8) / 2
	add	cl, dl
	add	ch, dh
	shr	cl, 1
	shr	ch, 1
	shl	ch, 3
	add	cl, ch
	shr	cl, 1

	movzx	r12, cl
	mov	bl, [grid + r12]
	or	bl, al
	and	bl, 0x3
	xor	bl, 0x3
	jz	.is_middle_valid

	sub	rdi, 2
	jmp	.next_offset

.is_middle_valid:
	mov	[rdi], byte 1
	inc	rdi
	mov	[rdi], cl
	inc	rdi
;;;;;;;;;;;;;;middle;

.next_offset:
	inc	r10
	dec	r11
	jnz	.loop_offsets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;offset;

.end:
	inc	rsi
	ret
; }}}

; get_all_moves() {{{
; Gets all possible moves of all pieces on the board whose turn it is.
;
; No input.
;
; Output:
;	moves - all moves
;	nMoves - number of moves
;
get_all_moves:
	mov	rsi, 0		; current index
	mov	rdi, moves	; move destination pointer
.loop:
	call get_moves

	cmp	rsi, 32
	jne	.loop

	mov	rbx, rdi
	sub	rbx, moves
	shr	rbx, 2
	mov	[nMoves], bx

	ret
; }}}

; play_move(source, dest) {{{
; Plays the given move on the board if it exists inside the moves array.
;
; Input:
;	al - Source of the piece
;	bl - Destination of the piece
;
; Output:
;	rax - 0 if the piece was moved, 1 otherwise
;
play_move:
	mov	rsi, grid
	mov	r8w, [nMoves]

.loop:
; ah = source
	mov	ah, [rsi]
	inc	rsi

; bh = destination
	mov	bh, [rsi]
	inc	rsi

; ch = flags
	mov	ch, [rsi]
	inc	rsi

; dh = extra
	mov	dh, [rsi]
	inc	rsi

; Check if the given move is contained
	cmp	ah, al
	sete	cl
	cmp	bh, bl
	sete	ch
	and	cl, ch
	jz	.continue

; Move the piece
	movzx	r8, al
	movzx	r9, bl
	add	r8, grid
	mov	dl, [r8]
	mov	[grid + r9], dl
	mov	[r8], byte 0

; Check for double move
	test	cl, 1
	jz	.continue

; Clear middle piece
	mov	dl, ch
	movzx	r8, dl
	mov	[grid + r8], byte 0

	mov	rax, 0
	ret

.continue:
	dec	r8w
	jne	.loop

	mov	rax, 1
	ret
; }}}
