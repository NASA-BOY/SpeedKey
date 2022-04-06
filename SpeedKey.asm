; ==========SpeedKey by ITAY==========
IDEAL
MODEL small
jumps
STACK 100h
P186
DATASEG

; Variables

CODESEG
start:
	mov ax, @data
	mov ds, ax

	;The Code
	
exit:
	mov ax, 4c00h
	int 21h
END start


