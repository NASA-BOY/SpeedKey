; ==========SPEEDKEY by ITAY==========
IDEAL
MODEL small
jumps
STACK 100h
P186
DATASEG

; VARIABLES
; Home variables
home_pic	db 'Home.bmp',0
home_a_u	db 'HomeKeyU.bmp',0
home_a_d	db 'HomeKeyD.bmp',0

home_key_x		dw 220
home_key_y		dw 35

CODESEG
start:
	mov ax, @data
	mov ds, ax

	; CODE
	; Graphic mode
	mov ax, 13h
	int 10h
	
	; ==Home page==
	; Change the screen pic
	mov ax, offset home_pic
	call MOR_SCREEN
	
home_ani:
	; Key animation
	call home_key_ani
	
	; Check if a key was pressed without waiting
	mov ah,0bh
	int 21h
	
	cmp al, 0
	je home_ani
	
	; Back to text mode
	mov ah, 0
	mov al, 2
	int 10h
	
exit:
	mov ax, 4c00h
	int 21h
	
; ===================================PROCEDURES===================================


;====================================================================
;   PROC  –  home_key_ani - Creats the key animation in the home screen
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS : NONE
; ====================================================================

proc home_key_ani
	pusha
	
	mov cx, [home_key_x]
	mov dx, [home_key_y]
	
	mov ax, offset home_a_u
	call MOR_LOAD_BMP
	
	; wait
	mov ax,700
	call MOR_SLEEP
	
	mov ax, offset home_a_d
	call MOR_LOAD_BMP
	
	; wait
	mov ax,700
	call MOR_SLEEP
	
	popa
	ret
endp home_key_ani
	
	
	
	
include "MOR_LIB.ASM"
END start


