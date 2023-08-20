; Declared in checkers.asm
extern moves
extern nMoves

section .data
	grid: times 100 db 0
	turn: db 0
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

;
; Gets all moves of a single piece
;
; Input:
;	rsi - Index of the piece
;	rdi - Index where to store the piece
;
; Output:
;	rdi - Current move index
;
get_moves:
	; r8 (row) = (rsi (current index) * 2) / 8
	mov	r8, rsi
	shl	r8, 1
	shr	r8, 3
	; r9 (column) = (rsi (current index) * 2) % 8
	mov	r9, rsi
	shl	r9, 1
	and	r9, 0x7
	; al (piece) = grid[rsi]
	mov	al, [grid + rsi]
	; Check if it's the piece's turn
	test	al, [turn]
	jz	.continue
	; Get the right range of offsets
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
	jl	.invalid_move
	cmp	bh, 32
	jge	.invalid_move
	; Check if the source and destination are diagonal to each other
	shl	bl, 1
	shl	bh, 1
	mov	cl, bl
	mov	ch, bl
	mov	dl, bh
	mov	dh, bh
	shr	bl, 1
	shr	bh, 1
	and	cl, 0x7
	shr	ch, 3
	and	dl, 0x7
	shr	ch, 3
	sub	cl, dl
	jnl	.not_negate_cl
	neg	cl
.not_negate_cl:
	sub	ch, dh
	jnl	.not_negate_ch
	neg	ch
.not_negate_ch:
	sub	cl, ch
	jnz	.invalid_move

	mov	[rdi], bh
	inc	rdi
	mov	[rdi], bl
	inc	rdi
	mov	[rdi], byte 0
	inc	rdi
	mov	[rdi], byte 0
	inc	rdi
	
.invalid_move:
	inc	r10
	dec	r11
	jnz	.loop_offsets

.continue:
	inc	rsi
	ret

;
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
	mov	rdi, 0		; current move index
.loop:
	call get_moves

	cmp	rsi, 32
	jne	.loop

	mov	rbx, rdi
	shl	rbx, 14
	mov	[nMoves], bx
	
	ret

;
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
	mov	rsi, 0
	mov	rax, 0
	mov	ax, [nMoves]
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
.continue:
	cmp	rsi, rax
	jne .loop
	
	ret
