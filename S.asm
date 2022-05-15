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
; robot_pic	db 'robot.bmp',0
line_pic	db 'line.bmp',0

; Keys images
; TODO: when doing the check which key is pressed check if the ascii of the pressed key is bigger or equals to 97 ('a' ascii)
; and if so substract less from the ascii value
keys_pics	dw '0', '1', '2', '3', '4', '5', '6', '7', '8', '9';, 'a.bmp', 'b.bmp', 'c.bmp', 'd.bmp', 'e.bmp', 'f.bmp', 'g.bmp', 'h.bmp', 'i.bmp', 'j.bmp', 'k.bmp', 'l.bmp', 'm.bmp', 'n.bmp', 'o.bmp', 'p.bmp', 'q.bmp', 'r.bmp', 's.bmp', 't.bmp', 'u.bmp', 'v.bmp', 'w.bmp', 'x.bmp', 'y.bmp', 'z.bmp'
pic 		db '_.bmp',0
key_del		db 'delete.bmp',0

; Keys coordinates
keys_x		dw 10 dup (0)
keys_y		dw 10 dup (0)
y_jump		db 2 ; The Y pixel jump amount of every key
y_fail		dw 170 ;The Y value that if a key reaches the player fails

; Loaded Keys index 
keys_on		dw 10 dup (0) ;replace with 36 later
keys_num 	db 0  ; Number of keys loaded

; Number of keys killed
score		dw 0

; General variables
counter		db 0
timer		db 0

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
	
	call load_random_key

	
	; Main Game Loop
main:

	; Print the score
	mov dx, 0
	; set cursor position acording to dh dl
	MOV AH, 2       ; set cursor position
	MOV BH, 0       ; display page number
	INT 10H         ; video BIOS call
	
	mov ax, [score]
	call MOR_PRINT_NUM
	
	

	call check_press
	mov al, [timer]
	cmp al, 5
	jb no_load
	
	; Load a key
	call load_random_key
	call MOR_STOPPER_START
	mov [timer], 0
	
no_load:
	mov ax, 200
	call MOR_SLEEP
	
	inc [timer]
	
	CALL keys_fall
	
	; Loop
	jmp main
	
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
	
	; ; Robot
	; mov cx, [robot_x]
	; mov dx, [robot_y]
	
	; mov ax, offset robot_pic
	; call MOR_LOAD_BMP
	
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
	
	; Temp: check if all the keys are on
	mov al, 10
	cmp [keys_num], al
	je after_load
	
	; Get random x coordinate
	mov ax, 281
	call MOR_RANDOM
	add ax, 20
	
	mov cx, ax
	mov dx, 20
	
random:
	; Get a random key number to load
	mov ax, 10 ;replace with 36 later
	call MOR_RANDOM
	
	; Check if the key is already on screen and get random key again if it is
	mov bx, ax
	add bx, bx
	cmp [keys_on + bx], 70
	je random
	
	mov bx, [keys_pics + bx]
	mov [pic], bl
	
	; Save the random key coordinates
	mov bx, ax
	add bx, bx
	mov [keys_x + bx], cx
	mov [keys_y + bx], dx
	
	; Change the key index in the keys on array to 1
	mov [keys_on + bx], 70
	; mov ah,0
	; call MOR_PRINT_NUM
	inc [keys_num]
	
	; Load the key
	mov ax, offset pic
	call MOR_LOAD_BMP

after_load:

	popa
	ret
endp load_random_key



;====================================================================
;   PROC  –  keys_fall - make the keys fall
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS : NONE
; ====================================================================

proc keys_fall
	pusha
	
	; Init
	mov [counter], 0
fall:
	mov bx, 0
	mov bl, [counter]
	add bx, bx
	; Move the key index to bx
	cmp [keys_on + bx], 0
	je after_fall

	; Load a blank pic to delete the key
	mov cx, [keys_x + bx]
	mov dx, [keys_y + bx]
	
	mov ax, offset key_del
	call MOR_LOAD_BMP
	
	; Increase the key y value for fall effect
	mov ax, 0
	mov al, [y_jump]
	add [keys_y + bx], ax
	
	; Load the key back but with higher y (affter fall)
	mov dx, [keys_y + bx]
	
	mov ax,0
	mov ax, [keys_pics + bx]
	mov [pic], al
	
	mov ax, offset pic
	call MOR_LOAD_BMP
	
	; Checks if the keys y is in the fail range and if so call game over
	cmp dx, [y_fail]
	jae fail
	jmp after_fall
	
fail:
	call game_over
	
after_fall:
	
	inc [counter]
	
	; The loop will run for the amout of keys on screen
	mov al, 10 ;change to 36
	cmp [counter], al
	jb fall
	

	popa
	ret
endp keys_fall


;====================================================================
;   PROC  –  check_press - check if the key pressed is on screen and if so deletes it
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS : NONE
; ====================================================================
	proc check_press
	pusha
	mov ax, 0
	
	call MOR_GET_KEY
	
	cmp al, 0
	je not_on
	
	sub al, 48
	mov ah,0
	
	; Check if the key is on the screen
	mov bx, ax
	add bx, bx
	cmp [keys_on + bx], 0
	je not_on
	
	; Load a blank pic to delete the key
	mov cx, [keys_x + bx]
	mov dx, [keys_y + bx]
	
	mov ax, offset key_del
	call MOR_LOAD_BMP
	
	; Change the key on status and details to 0
	mov [keys_on + bx], 0
	mov [keys_x + bx], 0
	mov [keys_y + bx], 0
	
	; Decrease the number of key on screen
	dec [keys_num]	
	
	; Increase the score
	inc [score]
	
not_on:

	
	popa
	ret
endp check_press


;====================================================================
;   PROC  –  game_over - The game over screen
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS : NONE
; ====================================================================

proc game_over
	pusha
	
	mov ax, 2
	int 10h
	
	popa
	ret
endp game_over

	
include "MOR_LIB.ASM"
END start
