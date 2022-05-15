;  MOR_LIB  -  written by Oren Gross
;
; 15.5.20- stopper added : MOR_STOPPER_START + MOR_STOPPER_GET
; added 
; 27.2.2022 - additions draw-Pixel,Line,Rect + putMessage

Clock  	  equ es:6Ch ; BIOS 55 msec ticks counter


SCREEN_WIDTH = 320
SCREEN_HEIGHT = 200
SMALLEST_IMG_HEIGHT = 40
SMALLEST_IMG_WIDTH = 40

DATASEG 
msg_MOR_LIB db    ' MOR LIB '
MOR_lastrand    dw    0 ; needed for randomizing

; BMP File data
FileHandle	dw ?
Header 	    db 54 dup(0)
Palette 	db 400h dup (0)
Img_Width dw 14
Img_Highet dw 16
OneBmpLine 	db SCREEN_WIDTH dup (0)  ; One Color line read buffer
ScreenLineMax 	db SCREEN_WIDTH * 2 dup (0)  ; One Color line read buffer
bmp_x dw 1 ;BMP location - x
bmp_y dw 40 ; ;BMP location - y
bmp_failed db ?

const_225  dw 225
const_4096 dw 4096
ScrLine db 320 dup (0)
ErrorMsg1 db 'Error in opening file : $'
ErrorMsg2 db 13, 10,'1) Check if file exist', 13, 10,'2) Check if its name is correct.', 13, 10,'3) Check file is BMP-256 colors format.', 13, 10,'4) Check if filename is in 8.3 format .', 13, 10,'$'
stopper dw ?

CODESEG

;==============================================
;   drawPixel  – draw a pixel at  X,Y  
;   IN: CX=X  , DX =Y , AL = COLOR 
;   OUT:  NONE
;	AFFECTED REGISTERS AND VARIABLES: NONE
; ==============================================
proc drawPixel 
	PUSHA 
	mov bh,0
	mov ah,0ch
	int 10h
	POPA
	ret 
endp


;==============================================
;   drawLine  – draw a line starting at  X,Y  
;   IN: CX=X  , DX =Y , AL = COLOR , AH = WIDTH
;   OUT:  NONE
;	AFFECTED REGISTERS AND VARIABLES: NONE
; ==============================================
proc drawLine 
	PUSHA 
	mov bl,ah ; loop counter (cause ah is needed)
	mov bh,0
	mov ah,0ch
ONE_PIXEL	:
	int 10h
	inc cx
	dec bl
	jnz ONE_PIXEL
	POPA
	ret 
endp


;==============================================
;   drawRect  – draw a rectangle starting at  X,Y  
;   IN: CX=X  , DX =Y , AL = COLOR , AH = WIDTH , BL = HIGHT 
;   OUT:  NONE
;	AFFECTED REGISTERS AND VARIABLES: NONE
; ==============================================

proc drawRect 
	PUSHA 
ONE_LINE	:
    call drawLine  ; IN: CX=X  , DX =Y , AL = COLOR , AH = WIDTH 
	inc dx
	dec bl
	jnz ONE_LINE
	POPA
	ret 
endp

	




;==============================================
;   putMessage  - print message on screen
;   IN: DH= row number  , DL = column number  , cx = the message (offset)
;   OUT:  NONE
;	AFFECTED REGISTERS AND VARIABLES: NONE
; ==============================================

proc putMessage
	pusha

	; set cursor position acording to dh dl
	MOV AH, 2       ; set cursor position
	MOV BH, 0       ; display page number
	INT 10H         ; video BIOS call
	
	; print msg
	mov dx,cx
	mov ah,9
	int 21h

	popa
	ret
endp 



Proc MOR_SLEEP
;DO : sleep and return after AX mili second
;IN  : AX - unsigned - hold delay time in msec   ( accuracy is +- 55 msec )
;OUT : NONE

	; STORE
	push ax
    push cx
    push dx
	push es

;	mov ax,dx
;	mov dl,55
;	div dl   ;	DIV BYTE :  AL = AX / operand  , AH = remainder (modulus) 

	; calc dx:ax / 55 
	mov dx,0  ; AX - already holds the msec as a parameter
	mov cx , 55
	div cx   ;DIV  word: AX = (DX AX) / operand ,DX = remainder (modulus) 
	
	cmp ax,0
	je @@Finish ; no delay needed
	mov cx, ax  
	
	; the delay : based on gvahim asm book chap. 13
	; wait for first change in timer 
	mov  ax, 40h 
	mov  es, ax 
	mov  ax, [Clock] 
	FirstTick:  
	cmp  ax, [Clock] 
	je  FirstTick 
	

	; count CX ticks 
@@DelayLoop: 
	mov  ax, [Clock] 
	Tick: 
	cmp  ax, [Clock] 
	je  Tick 

	loop  @@DelayLoop 

@@Finish:	
	; RESTORE
	pop es 
	pop dx
	pop cx
	pop ax
	ret 
endp MOR_SLEEP	

Proc MOR_GET_KEY  
;DO :  get key from Type Ahead Buffer (TAB)
;IN  : NONE
;OUT :  ZF - FALSE (0) when key exist  AL - ASCII  AH - scan code

	; check if key pressed
	mov ah, 1   
	Int 16h   ; ret ZF=FALSE when key exi
	jnz  @@key_exist
    ret   ; with ZF = TRUE
	
@@key_exist:
	
	; pop the key from the buffer
	mov  ah, 0  
	int  16h  ; read key : ah := scan code  al = ascii

	ret 

endp MOR_GET_KEY


;
; random - pseudo generate random number
;
; Register Arguments:
;    None.
;
; Returns:
;    ax - random number.
;
codeseg
proc    MOR_RAND_BASIC
    push   dx
    push   bx
    mov    bx, [MOR_lastrand]
    mov    ax, bx
    mov    dx, 401  ; RANDPRIME
    mul    dx
    mov    dx, ax
    call   MOR_55_MSEC_TICKS
    xor    ax, dx
    xchg   dh, dl
    xor    ax, dx
    xchg   bh, bl
    xor    ax, bx
    mov    [MOR_lastrand], ax
    pop    bx
    pop    dx
    ret
endp MOR_RAND_BASIC

;
; rand_max - pseudo generate random number in a range
;
; Register Arguments:
;    ax - the range : 0 till ax-1
;
; Returns:
;    ax - the random number whtin the range 
;
proc    MOR_RANDOM
    push   dx
    push   bx

	mov bx,ax ; store max
	call MOR_RAND_BASIC ; -> ax
	xor dx,dx
	div bx
	mov ax,dx	; the reminder [0..max]
	
    pop    bx
    pop    dx
    ret
endp MOR_RANDOM



;
; timeticks - get time ticks from bios data segment.
;
; Register Arguments:
;    None.
;
; Returns:
;    ax - current ticks
;

proc    MOR_55_MSEC_TICKS
    push es
	mov  ax, 40h   ; clock is at 40:6c
	mov  es, ax 
	mov  ax, [Clock] 
    pop  es
    ret
endp  MOR_55_MSEC_TICKS



;---------------------------------------------------
;  MOR_PRINT_NUM - 
;         Prints a number in base 10 
;
;         IN: AX - Number
;             
;
;        OUT: None
;---------------------------------------------------
proc MOR_PRINT_NUM
	push   ax
	push   bx
    push   cx
    push   dx


    mov  cx, 0
	mov  bx,10 ; BASE

@@DIGIT_LOOP:
    mov  dx, 0
    div  bx  ; DX:AX / BX = AX and Remainder: DX
 
    push dx
    inc  cx

    cmp  ax, 0
    jne  @@DIGIT_LOOP

@@PRINT:
    pop  dx
	add dl,'0'
	mov ah,2
	int 21h

    loop @@PRINT


	pop   dx
	pop   cx
    pop   bx
    pop   ax
    ret

endp MOR_PRINT_NUM
 
; ======================  GRAPHIC ==========================
; DO : load a BMP at location (x,y)
; IN : ax - filename cx - x dx - y
; OUT : None
; effected registers : None

proc MOR_LOAD_BMP near
	push ax
	push bx
	push cx
	push dx
	push si
	push di

	; store location on screen
	mov [bmp_x],cx
	mov [bmp_y],dx
	mov dx,ax
	
	call OpenBmpFile
	cmp [bmp_failed],1
	je ret_bmp
    	
	call ReadBmpHeader	
	
	; from here assume bx is global param with file handle. 
	call ReadBmpPalette		
	call CopyBmpPalette		
	call ShowBMP			 
	call CloseBmpFile
ret_bmp:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp MOR_LOAD_BMP


; in - dx - file name 
proc OpenBmpFile	near	
	mov [bmp_failed] ,0
	mov ah, 3Dh
	xor al, al
	int 21h
	jc openerror
	mov [FileHandle], ax ; ??? was dx
ret
		
openerror:
	mov [bmp_failed] ,1

	push dx
	mov dx, offset ErrorMsg1
	mov ah, 9h
	int 21h

	; print max 50  chars
	mov cx,50 
	pop bx

char1:
    mov dl,[bx]
	cmp dl,'$'
	je filename_end
	mov ah,2
	int 21h
	inc bx
	loop char1

filename_end:

	mov dx, offset ErrorMsg2
	mov ah, 9h
	int 21h
	; Wait for key press
	mov ah,8
	int 21h
ret
		
endp OpenBmpFile
 
 
proc CloseBmpFile near
	mov ah, 3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile


; Read 54 bytes the Header
proc ReadBmpHeader	near
; in - [FileHandle]
; out - bx - hold ref to handle					
	push cx
	push dx
	
	mov ah, 3fh
	mov bx, [FileHandle]
	mov cx, 54
	mov dx, offset Header
	int 21h
	push bx
	mov bx , offset Header
	mov cx,[bx+18]
	mov [Img_Width],cx
	mov dx,[bx+22]
	mov [Img_Highet],dx
	pop bx
	pop dx
	pop cx
	ret
endp ReadBmpHeader


; Read BMP file color palette, 256 colors * 4 bytes (400h)
; 4 bytes for each color BGR + null)	
proc ReadBmpPalette near 		
	push cx
	push dx
	
	mov ah, 3fh
	mov cx, 400h
	mov dx, offset Palette
	int 21h
	
	pop dx
	pop cx	
	ret
endp ReadBmpPalette
	


; Will move out to screen memory the colors
; video ports are 3C8h for earlyTimer of first color
; and 3C9h for all rest
proc CopyBmpPalette		near					
										
	push cx
	push dx
	
	mov si, offset Palette
	mov cx, 256
	mov dx, 3C8h
	mov al, 0  ; black first							
	out dx, al ;3C8h
	inc dx	   ;3C9h
CopyNextColor:
	mov al, [si+2] 		; Red				
	shr al, 2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution).				
	out dx, al 						
	mov al, [si+1] 		; Green.				
	shr al, 2            
	out dx, al 							
	mov al, [si] 		; Blue.				
	shr al, 2            
	out dx, al 							
	add si, 4 			; Point to next color.  (4 bytes for each color BGR + null)												
	loop CopyNextColor
	
	pop dx
	pop cx	
	ret
endp CopyBmpPalette


; BMP graphics are saved upside-down.
; Read the graphic line by line (Img_Highet lines in VGA format),
; displaying the lines from bottom to top.
proc ShowBMP 
	push cx
	
	mov ax, 0A000h
	mov es, ax
	mov cx, [Img_Highet]
	
	; row size must dived by 4 so if it less we must 
	; calculate the extra padding bytes
	; set bp to hold  padding 
	mov ax, [Img_Width] 
	xor dx, dx
	mov si, 4
	div si
	mov bp, dx
	
	
@@NextLine:
	push cx
	
	;set di = current row + y
	mov di, cx  ; Current Row at the small bmp (each time -1)
	add di, [bmp_y] ; add the Y on entire screen
 
	; make di point to right screen-mem location
	; di = cx*320 + [bmp_x] , point to the correct screen line
	mov cx, di  ; 
	shl cx, 6
	shl di, 8
	add di, cx
	add di, [bmp_x]
	
	; Read one line
	mov ah, 3fh
	mov cx,[Img_Width]  
	add cx, bp  ; extra  bytes to each row must be divided by 4
	mov dx, offset ScreenLineMax
	int 21h

	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,[Img_Width] 
	mov si, offset ScreenLineMax
	rep movsb ; Copy line to the screen
;rep movsb is same as the following code:
;mov es:di, ds:si
;inc si
;inc di
;dec cx

	;loop until cx=0
	pop cx	
	loop @@NextLine
	
	pop cx
	ret
endp ShowBMP 

proc MOR_SCREEN
; DO : take a BMP and put it on screen ( starting from location 0,0)
; IN : ax filename
; OUT : None
; effected registers : None
	push cx
	push dx
  
	mov cx,0
	mov dx,0
    call MOR_LOAD_BMP 
	
	pop dx
	pop cx
	ret
endp MOR_SCREEN


proc  TimeMeasure_start
; in - none 
; out - none
; effected - none
	push es
	mov  ax, 40h 
	mov  es, ax 
	mov [word ptr Clock] ,0
	pop es

ret
endp

proc  TimeMeasure_reset
; in bx - offset to DW to hold start time
; out - none
; effected - none
	push es
	mov  ax, 40h 
	mov  es, ax 

	mov  ax, [Clock] 
	mov [bx],ax
	pop es

ret
endp

proc TimeMeasure_seconds_since
; in bx - offset to DW to hold start time
; out ax - seconds since starting
; effected - none 

	push es
	mov  ax, 40h 
	mov  es, ax 
	mov  ax, [Clock] 
	sub ax,[bx]
	mul [const_225]	; ax * 225 -> dx:ax
	div [const_4096] ; dx:ax  / 4096 -> ax 
	pop es
	ret
endp 



proc MOR_STOPPER_START
; in -none
; out - start the stopper
; effected - none 

	push bx
    call TimeMeasure_start
	mov bx,offset stopper
	call TimeMeasure_reset
	pop bx
	ret
endp 
	



proc MOR_STOPPER_GET
; in -none
; out - ax return seconds since start
; effected - none 

	push bx
	mov bx,offset stopper
	call TimeMeasure_seconds_since
	pop bx
	ret
endp

