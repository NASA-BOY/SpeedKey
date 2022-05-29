IDEAL
MODEL small
STACK 100h
p186
DATASEG
; --------------------------
; Your variables here
; --------------------------
CODESEG
start:
	mov ax, @data
	mov ds, ax
	
	mov ax, 0
loopy:
	call MOR_GET_KEY

	cmp ax, 0CBh
	je lefty

	cmp al, 0
	je loopy
	
lefty:
	mov ax, 69
	call MOR_PRINT_NUM
	
	
exit:
	mov ax, 4c00h
	int 21h
	
include "MOR_LIB.asm"
END start


