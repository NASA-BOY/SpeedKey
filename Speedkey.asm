; ========== SPEEDdigit by ~ITAY OLIEL~ ==========

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
line_pic	db 'line.bmp',0

; Game over variables
over_back	db 'over_bac.bmp', 0
over_txt	db 'over_txt.bmp', 0
txt_blank	db 'txt_blan.bmp', 0
txt_y		dw 90
txt_x		dw 40

; digits images
digits_pics	dw '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
pic 		db '_.bmp',0
digit_del		db 'delete.bmp',0

; digits coordinates
digits_x	dw 10 dup (0) ; The X coordinate of each digit
digits_y	dw 10 dup (0); The Y coordinate of each digit
prev_x		dw 0 ; The random x value will be saved here so the next digit wont be loaded on top the previous one 
y_jump		db 2 ; The Y pixel jump amount of every digit
y_fail		dw 170 ; The Y value that if a digit reaches the player fails
first_y		dw 15

fall_delay	dw 200 ; The delay between each fall

; Loaded digits index 
digits_on		dw 10 dup (0) ; If a digit is loaded the its value in index will be 1
digits_num 	db 0 ; Number of digits loaded

; Number of digits destroyed
score		dw 0

; General variables
counter		db 0
timer		db 0
fail		db 0 ; Turns to 1 if the player has failed and the game is over

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
	
	; digit animation and check any digit
	call home_key_ani
	
	
play_again:	
	
	; Game init
	call game_init
	
	call load_random_digit

	
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
	
	; Check if 5 * fall_delay has passed and if so load a random digit
	cmp [timer], 5
	jb no_load
	
	; Load a digit
	call load_random_digit
	mov [timer], 0
	
no_load:
	mov ax, [fall_delay]
	call MOR_SLEEP
	
	inc [timer]
	
	CALL digits_fall
	
	; Loop only if the player hasn't failed
	cmp [fail], 0
	je main
	
	call over_proc

	jmp play_again
	
exit:
	mov ax, 4c00h
	int 21h
	
; =================================== PROCEDURES ===================================


;====================================================================
;   PROC  –  home_key_ani - Creats the digit animation in the home screen
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
	; Check if a digit was pressed without waiting
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
	
	popa
	ret
endp game_init


;====================================================================
;   PROC  –  reset_vars - reset the changed variables for another run
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES : score, digits_num, fail, timer, fall_delay, y_jump, digits_on, digits_x, digits_y - all to their original value
; ====================================================================

proc reset_vars
	pusha
	
	mov [score], 0
	mov [digits_num], 0
	mov [fail], 0
	mov [timer], 0
	mov [fall_delay], 200
	mov [y_jump], 2
	
	; Reset the arrays using a loop
	mov bx, 0
arr_reset:
	mov [digits_on+bx], 0
	mov [digits_x+bx], 0
	mov [digits_y+bx], 0
	
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
;   PROC  –  load_random_digit - Load a random digit to the screen
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES: digits_num - inc by 1, prev_x, digits_on, digits_x, digits_y, pic - according to the number loaded
; ====================================================================

proc load_random_digit
	pusha
	
	; Check if all the digits are on
	mov al, 10
	cmp [digits_num], al
	je after_load
	
	; Get random x coordinate
	mov ax, 281
	call MOR_RANDOM
	add ax, 20
	
	; Check if the x value is too close to the last one and fix it if so
	call check_x_diff
	
	mov cx, ax
	mov dx, [first_y]
	
random:
	; Get a random digit number to load
	mov ax, 10
	call MOR_RANDOM
	
	; Check if the digit is already on screen and get random digit again if it is
	mov bx, ax
	add bx, bx
	cmp [digits_on + bx], 1
	je random
	
	mov bx, [digits_pics + bx]
	mov [pic], bl
	
	; Save the random digit coordinates
	mov bx, ax
	add bx, bx
	mov [digits_x + bx], cx
	mov [digits_y + bx], dx
	
	; Save the x value for next load
	mov [prev_x], cx
	
	; Change the digit index in the digits on array to 1
	mov [digits_on + bx], 1

	inc [digits_num]
	
	; Load the digit
	mov ax, offset pic
	call MOR_LOAD_BMP

after_load:

	popa
	ret
endp load_random_digit


;====================================================================
;   PROC  –  check_x_diff - Check if the substracte of the new digit and previous one is too small and if so return a fixed x value
;   IN: ax - the current digit x value
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
	
	; Check if add to x or to sub x is needed
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
;   PROC  –  digits_fall - make the digits fall
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES : fail - only if the player has failed, counter - by one each loop, digits_x, digits_y, pic - according to the number pressed
; ====================================================================

proc digits_fall
	pusha
	
	; Init
	mov [counter], 0
fall:
	mov bx, 0
	mov bl, [counter]
	add bx, bx
	; Move the digit index to bx
	cmp [digits_on + bx], 0
	je after_fall

	; Load a blank pic to delete the digit
	mov cx, [digits_x + bx]
	mov dx, [digits_y + bx]
	
	mov ax, offset digit_del
	call MOR_LOAD_BMP
	
	; Increase the digit y value for fall effect
	mov ax, 0
	mov al, [y_jump]
	add [digits_y + bx], ax
	
	; Load the digit back but with higher y (affter fall)
	mov dx, [digits_y + bx]
	
	mov ax,0
	mov ax, [digits_pics + bx]
	mov [pic], al
	
	mov ax, offset pic
	call MOR_LOAD_BMP
	
	; Checks if the digits y is in the fail range and if so call game over
	cmp dx, [y_fail]
	jae over
	jmp after_fall
	
over:
	mov [fail], 1
	
after_fall:
	
	inc [counter]
	
	; The loop will run for the amout of digits on screen
	mov al, 10
	cmp [counter], al
	jb fall
	

	popa
	ret
endp digits_fall


;====================================================================
;   PROC  –  check_press - check if the digit pressed is on screen and if so deletes it
;   IN: NONE
;   OUT: NONE
;	EFFECTED REGISTERS AND VARIABLES: score - inc if the clicked on the number on screen, digits_num - dec if the clicked on the number on screen, digits_on, digits_x, digits_y - according to the number pressed
; ====================================================================
	proc check_press
	pusha
	
	mov ax, 0
	call MOR_GET_KEY
	
	; Nothing is pressed
	cmp al, 0
	je not_on
	
	; A digit which is not a number was pressed
	cmp al, '0'
	jb not_on
	
	cmp al, '9'
	ja not_on
	
	; Convert the ascii code to the digits
	sub al, '0'
	mov ah,0
	
	; Check if the digit is on the screen
	mov bx, ax
	add bx, bx
	
	; If the digit pressed is not on the screen then GAME OVER
	cmp [digits_on + bx], 0
	je check_fail
	
	; Load a blank pic to delete the digit
	mov cx, [digits_x + bx]
	mov dx, [digits_y + bx]
	
	mov ax, offset digit_del
	call MOR_LOAD_BMP
	
	; Change the digit on status and details to 0
	mov [digits_on + bx], 0
	mov [digits_x + bx], 0
	mov [digits_y + bx], 0
	
	; Decrease the number of digit on screen
	dec [digits_num]	
	
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
	
	; Wait a bit before game over screen so the plyer can see what happend
	; this code is like this to fix the bug that if you press before the game over screen  it skips it
	mov [timer], 0
fail_wait:
	mov ax, 100
	call MOR_SLEEP
	
	call MOR_GET_KEY
	inc [timer]
	
	cmp [timer], 20
	jb fail_wait
	
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
	
	; GAME OVER animation
	mov ax, offset over_txt
	call MOR_LOAD_BMP
	
	mov ax, 500
	call MOR_SLEEP
	
	mov ax, offset txt_blank
	call MOR_LOAD_BMP
	
	mov ax, 500
	call MOR_SLEEP
	
	mov ax, 0
	; If Q or q is pressed exit the game
	call MOR_GET_KEY
	cmp al, 'q'
	je exit
	
	cmp al, 'Q'
	je exit
	
	; If any other digit is pressed play again
	cmp al, 0
	je game_over
	
	; Reset the variables and start again
	call reset_vars
	
	popa
	ret
endp over_proc

	
include "MOR_LIB.ASM"
END start
