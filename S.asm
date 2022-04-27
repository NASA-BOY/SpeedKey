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

; Keys images
; TODO: when doing the check which key is pressed check if the ascii of the pressed key is bigger or equals to 97 ('a' ascii)
; and if so substract less from the ascii value
keys_pics	db '0.bmp', '1.bmp', '2.bmp', '3.bmp', '4.bmp', '5.bmp', '6.bmp', '7.bmp', '8.bmp', '9.bmp', 'a.bmp', 'b.bmp', 'c.bmp', 'd.bmp', 'e.bmp', 'f.bmp', 'g.bmp', 'h.bmp', 'i.bmp', 'j.bmp', 'k.bmp', 'l.bmp', 'm.bmp', 'n.bmp', 'o.bmp', 'p.bmp', 'q.bmp', 'r.bmp', 's.bmp', 't.bmp', 'u.bmp', 'v.bmp', 'w.bmp', 'x.bmp', 'y.bmp', 'z.bmp'

; Keys coordinates
keys_x		db 35
keys_y		db 35

; Loaded Keys index 
keys_on		db 35
keys_num 	db 0  ; Number of keys loaded

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


;====================================================================
;   PROC  –  load_random_key - Load a random key to the screen
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS : NONE
; ====================================================================

proc load_random_key
	pusha
	
	; Get random x coordinate
	mov ax, 281
	call MOR_RANDOM
	add ax, 20
	
	mov cx, ax
	mov dx, 20
	
	; Get a random key number to load
	mov ax, 36
	call MOR_RANDOM
	
	; Save the random key coordinates
	mov [keys_x + ax], cx
	mov [keys_y + ax], dx
	
	; Save the key's index in the keys array
	mov bl, [keys_num]
	mov [keys_on + bl], ax
	inc [keys_num]
	
	; Load the key
	mov ax, offset [keys_pics + ax]
	call MOR_LOAD_BMP

	popa
	ret
endp load_random_key
	
	
include "MOR_LIB.ASM"
END start


