IDEAL
MODEL small
STACK 100h
DATASEG
;VARIABLES
pic_1	db '0.bmp',0

CODESEG
start:
	mov ax, @data
	mov ds, ax

	; CODE
	; Graphic mode
	mov ax, 13h
	int 10h
	
	mov cx, 100
	mov dx, 100
	
	mov ax, offset pic_1
	call MOR_LOAD_BMP
	
exit:
	mov ax, 4c00h
	int 21h
	
include "MOR_LIB.ASM"
END start


