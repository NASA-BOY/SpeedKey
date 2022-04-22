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

; Init variables
back_pic	db 'back_pic.bmp',0
robot_pic	db 'robot.bmp',0
line_pic	db 'line.bmp',0



; CONSTANTS
; Home
home_key_x	dw 220
home_key_y	dw 35

; Init
robot_x		dw 80
robot_y		dw 126

line_x		dw 0
line_y		dw 185



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
	call MOR_GET_KEY
	
	cmp al, 0
	je home_ani
	
	; Game init
	call game_init
	
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
	

;====================================================================
;   PROC  –  game_init - Initiate the game for start
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS : NONE
; ====================================================================

proc game_init
	pusha
	
	; Change the screen pic
	mov ax, offset back_pic
	call MOR_SCREEN
	
	; Line
	mov cx, [line_x]
	mov dx, [line_y]
	
	mov ax, offset line_pic
	call MOR_LOAD_BMP
	
	; Robot
	mov cx, [robot_x]
	mov dx, [robot_y]
	
	mov ax, offset robot_pic
	call MOR_LOAD_BMP
	
	popa
	ret
endp game_init	
	
	
include "MOR_LIB.ASM"
END start


