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

; Game over variables
over_back	db 'over_bac.bmp', 0
over_txt	db 'over_txt.bmp', 0
txt_blank	db 'txt_blan.bmp', 0
txt_y		dw 90
txt_x		dw 40

; Keys images
; TODO: when doing the check which key is pressed check if the ascii of the pressed key is bigger or equals to 97 ('a' ascii)
; and if so substract less from the ascii value
keys_pics	dw '0', '1', '2', '3', '4', '5', '6', '7', '8', '9';, 'a.bmp', 'b.bmp', 'c.bmp', 'd.bmp', 'e.bmp', 'f.bmp', 'g.bmp', 'h.bmp', 'i.bmp', 'j.bmp', 'k.bmp', 'l.bmp', 'm.bmp', 'n.bmp', 'o.bmp', 'p.bmp', 'q.bmp', 'r.bmp', 's.bmp', 't.bmp', 'u.bmp', 'v.bmp', 'w.bmp', 'x.bmp', 'y.bmp', 'z.bmp'
pic 		db '_.bmp',0
key_del		db 'delete.bmp',0

; Keys coordinates
keys_x		dw 10 dup (0)
keys_y		dw 10 dup (0)
prev_x		dw 0 ; The random x value will be saved here so the next key wont be loaded on the previous one 
y_jump		db 2 ; The Y pixel jump amount of every key
y_fail		dw 170 ; The Y value that if a key reaches the player fails
first_y		dw 15

fall_delay	dw 200 ; The delay between each fall

; Loaded Keys index 
keys_on		dw 10 dup (0) ;replace with 36 later
keys_num 	db 0  ; Number of keys loaded

; Number of keys killed
score		dw 0

; General variables
counter		db 0
timer		db 0
fail		db 0 ; Turns 1 if the player has failed and the game is over

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
	
	; Key animation and check any key
	call home_key_ani
	
	
play_again:	
	
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
	
	; Check if 5 * fall_delay has passed and if so load a random key
	cmp [timer], 5
	jb no_load
	
	; Load a key
	call load_random_key
	mov [timer], 0
	
no_load:
	mov ax, [fall_delay]
	call MOR_SLEEP
	
	inc [timer]
	
	CALL keys_fall
	
	; Loop only if the player hasn't failed
	cmp [fail], 0
	je main
	
	call over_proc

	jmp play_again
	
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
	
home_ani:

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
	
	mov al, 0
	; Check if a key was pressed without waiting
	call MOR_GET_KEY
	
	cmp al, 0
	je home_ani
	
	popa
	ret
endp home_key_ani
	

;====================================================================
;   PROC  –  game_init - Initiate the game for start
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES : NONE
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
;   PROC  –  reset_vars - reset the changed variables for another run
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES : score, keys_num, fail, timer, fall_delay, y_jump, keys_on, keys_x, keys_y - all to their original value
; ====================================================================

proc reset_vars
	pusha
	
	mov [score], 0
	mov [keys_num], 0
	mov [fail], 0
	mov [timer], 0
	mov [fall_delay], 200
	mov [y_jump], 2
	
	; Reset the arrays using a loop
	mov bx, 0
arr_reset:
	mov [keys_on+bx], 0
	mov [keys_x+bx], 0
	mov [keys_y+bx], 0
	
	add bx, 2
	
	cmp bx, 20
	jb arr_reset
	
	
	popa
	ret
endp reset_vars


;====================================================================
;   PROC  –  speed_calc - calculate the fall spee dbased on the score
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES : fall_delay - will decrease more the higher the score, y_jump - if the score hits 69 the y jump is set to 4
; ====================================================================

proc speed_calc
	pusha
	
	; If the score is 47 the delay will be 59 and 55 is the min delay so jmp to min delay to stop decreasing
	cmp [score], 47
	ja min_delay
	
	sub [fall_delay], 3
	
min_delay:
	; If the score hits 69 the y jump is set to 4
	cmp [score], 69
	je impossible
	jmp normal
	

impossible:
	mov [y_jump], 4
	
normal:

	
	popa
	ret
endp speed_calc


;====================================================================
;   PROC  –  load_random_key - Load a random key to the screen
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES: keys_num - inc by 1, prev_x, keys_on, keys_x, keys_y, pic - according to the number loaded
; ====================================================================

proc load_random_key
	pusha
	
	; Check if all the keys are on
	mov al, 10
	cmp [keys_num], al
	je after_load
	
	; Get random x coordinate
	mov ax, 281
	call MOR_RANDOM
	add ax, 20
	
	call check_x_diff
	
	mov cx, ax
	mov dx, [first_y]
	
random:
	; Get a random key number to load
	mov ax, 10 ;replace with 36 later
	call MOR_RANDOM
	
	; Check if the key is already on screen and get random key again if it is
	mov bx, ax
	add bx, bx
	cmp [keys_on + bx], 1
	je random
	
	mov bx, [keys_pics + bx]
	mov [pic], bl
	
	; Save the random key coordinates
	mov bx, ax
	add bx, bx
	mov [keys_x + bx], cx
	mov [keys_y + bx], dx
	
	; Save the x value for next load
	mov [prev_x], cx
	
	; Change the key index in the keys on array to 1
	mov [keys_on + bx], 1
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
;   PROC  –  check_x_diff - Check if the substracte of the new key and previous one is too small and if so return a fixed x value
;   IN: ax - the current key x value
;   OUT: ax - the fixed x value
;	EFFECTED REGISTERS AND VARIABLES : ax
; ====================================================================

proc check_x_diff
	push cx
	push bx
	push dx
	
	; If the prev is bigger than do prev - ax else do ax - prev
	cmp [prev_x], ax
	ja prev_bigger
	
	; ax is bigger
	mov bx, ax
	sub bx, [prev_x]
	cmp bx, 20
	jb add_x
	jmp after_fix
	
add_x:
	cmp ax, 280
	ja dec_x
	add ax, 20
	jmp after_fix
	
prev_bigger:
	mov bx, [prev_x]
	sub bx, ax
	cmp bx, 20
	jb dec_x
	jmp after_fix
	
	
dec_x:
	cmp ax, 40
	jb add_x
	sub ax, 20

after_fix:

	
	pop cx
	pop bx
	pop dx
	ret
endp check_x_diff


;====================================================================
;   PROC  –  keys_fall - make the keys fall
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES : fail - only if the player has failed, counter - by one each loop, keys_x, keys_y, pic - according to the number pressed
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
	jae over
	jmp after_fall
	
over:
	mov [fail], 1
	
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
;	EFFECTED REGISTERS AND VARIABLES: score - inc if the clicked on the number on screen, keys_num - dec if the clicked on the number on screen, keys_on, keys_x, keys_y - according to the number pressed
; ====================================================================
	proc check_press
	pusha
	mov ax, 0
	
	call MOR_GET_KEY
	
	cmp al, 0
	je not_on
	
	cmp al, '0'
	jb not_on
	
	cmp al, '9'
	ja not_on
	
	sub al, 48
	mov ah,0
	
	; Check if the key is on the screen
	mov bx, ax
	add bx, bx
	; if wrong click then fail
	cmp [keys_on + bx], 0
	je check_fail
	
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
	
	; Decrease the fall delay
	call speed_calc
	
	jmp not_on
	
check_fail:
	mov [fail], 1
		
not_on:
		
	popa
	ret
endp check_press


;====================================================================
;   PROC  –  over_proc - The game over screen
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES : timer - inc by 1 every loop
; ====================================================================

proc over_proc
	pusha
	
	; Wait a bit before game over screen
	; this code is like this to fix the bug that if you press before the game over screen  it skips it
	mov [timer], 0
fail_wait:
	mov ax, 100
	call MOR_SLEEP
	
	call MOR_GET_KEY
	inc [timer]
	
	cmp [timer], 20
	jb fail_wait

	; If the player fails and the game is over
	
	; Change the screen pic
	mov ax, offset over_back
	call MOR_SCREEN
	
	; Print the score
	mov dl, 19
	mov dh, 4
	; set cursor position acording to dh dl
	MOV AH, 2       ; set cursor position
	MOV BH, 0       ; display page number
	INT 10H         ; video BIOS call
	
	mov ax, [score]
	call MOR_PRINT_NUM
	
	mov cx, [txt_x]
	mov dx, [txt_y]
	
game_over:
	
	mov ax, offset over_txt
	call MOR_LOAD_BMP
	
	mov ax, 500
	call MOR_SLEEP
	
	mov ax, offset txt_blank
	call MOR_LOAD_BMP
	
	mov ax, 500
	call MOR_SLEEP
	
	; Check if a key was pressed without waiting
	mov ax, 0
	
	call MOR_GET_KEY
	cmp al, 'q'
	je exit
	
	cmp al, 'Q'
	je exit
	
	cmp al, 0
	je game_over
	
	; Reset the variables and start again
	call reset_vars
	
	popa
	ret
endp over_proc

	
include "MOR_LIB.ASM"
END start
