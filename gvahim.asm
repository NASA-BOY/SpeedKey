;--------------------------------------------------------------------------------------
; Here Be Dragons 
;--------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------
;
;                          G V A H I M     F U N C T I O N S 
;
;--------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------
; PRINT_NIBBLE 
;    Prints a single number to the screen
;    IN:  Number in lower nibble of DL (0-F)
;    OUT: None
;--------------------------------------------------------------------------------------
proc PRINT_NIBBLE
    PUSH_REGS <ax, dx>
    cmp  dl,9h
    jbe  @@DECIMAL

    add  dl,'A'-'0'-10

@@DECIMAL:
    add  dl,'0'

    mov  ah,02h
    int  21h
    POP_REGS <dx, ax>
    ret
endp PRINT_NIBBLE

;--------------------------------------------------------------------------------------
; NEW_LINE
;    Prints a new line to the screen  
;--------------------------------------------------------------------------------------
proc NEW_LINE
    PUTC 10
    PUTC 13
    ret
endp

;---------------------------------------------------
;  SCAN_NUM - 
;         Reads a number in base 10 or 16
;         If the number is in base 16, it must in with an 'h'
;
;        OUT: DX
;---------------------------------------------------
proc SCAN_NUM
    
    PUSH_REGS <ax, bx, cx, si>

    mov  si, 0
    
@@READ_CHAR:
    mov  [cs:scan_num_buffer + si], 0

    ; Wait for character
    mov  ax, 00h
    int  16h

    cmp  al, 10
    je   @@READ_CHAR
        
    cmp  al, 13
    JE_F @@HANDLE_ENTER

    cmp  al, 8
    JE_F @@HANDLE_BACKSPACE 

    cmp  si, [cs:scan_num_buffer_len]
    je   @@ILLEGAL

    ; Check for a digit/letter after 'h'
    cmp  [cs:scan_num_buffer + si - 1], 'h'
    je   @@ILLEGAL 

    cmp  al, '-'
    je   @@HANDLE_MINUS

    JBETWEEN al, '0', '9', @@HANDLE_DIGIT

    JBETWEEN al, 'A', 'F', @@HANDLE_UPPERCASE
    
    JBETWEEN al, 'a', 'f', @@HANDLE_LOWERCASE

    cmp  al, 'H'
    je   @@HANDLE_H

    cmp  al, 'h'
    je   @@HANDLE_H
    
@@ILLEGAL:
    PUTC 7    ; Beep

    jmp  @@READ_CHAR

@@HANDLE_MINUS:
    ; Allow minus only if at the first position
    cmp si, 0
    jne @@ILLEGAL

    PUTC '-'
    mov [cs:scan_num_buffer + si], '-'
    inc si
    jmp @@READ_CHAR 

@@HANDLE_H:
    PUTC 'h'
    mov  [cs:scan_num_buffer + si], 'h'
    inc  si
    jmp  @@READ_CHAR

@@HANDLE_DIGIT:
    PUTC al
    sub  al, '0'
    mov  [cs:scan_num_buffer + si], al
    inc  si
    jmp  @@READ_CHAR

@@HANDLE_LOWERCASE:
    sub  al, 'a' - 'A'
    
@@HANDLE_UPPERCASE:
    PUTC al

    sub  al, 'A' - 0Ah
    mov  [cs:scan_num_buffer + si], al
    inc  si
    jmp  @@READ_CHAR

@@HANDLE_BACKSPACE:
    cmp  si, 0
    JE_F @@READ_CHAR
    
    ; Erase char
    PUTC 8
    PUTC 20h

    ; Reposition cursor
    PUTC 8
    
    dec  si
    jmp  @@READ_CHAR

@@HANDLE_ENTER:
    cmp [cs:scan_num_buffer + si -1], 'h'
    JE  @@CONVERT_HEX

    ; Should be decimal, check for illegal hex chars
    mov bx, 0
@@HEX_CHECK:
    mov al, [cs:scan_num_buffer + bx]
    JBETWEEN al, 0Ah, 0Fh, @@ILLEGAL   
    inc bx
    cmp si, bx
    jne @@HEX_CHECK

    mov bx, 10
    JMP @@CONVERT_TO_NUM

@@CONVERT_HEX:
    mov bx, 16
    dec si

@@CONVERT_TO_NUM:
    mov  ax, 0
    mov  cx, si
    jcxz @@SCAN_DONE
    
    mov  si,0
    cmp  [cs:scan_num_buffer + si], '-'
    jne  @@DIGIT_LOOP

    ; skip over '-'
    dec  cx
    inc  si

@@DIGIT_LOOP:
    mul  bx
    add  al, [cs:scan_num_buffer + si]
    adc  ah, 0
    inc  si
    loop @@DIGIT_LOOP
    
    cmp  [cs:scan_num_buffer], '-'
    jne  @@SCAN_DONE

    neg  ax

@@SCAN_DONE:

    call NEW_LINE
    mov dx, ax

    POP_REGS <si, cx, bx, ax>

    ret

scan_num_sentinal1  db 0    ; This sentinal makes the expression [scan_num_buffer + si - 1] legal
scan_num_buffer     db 6 dup(?)
scan_num_sentinal2  db 1 dup(?) ; This sentinal makes the expression [scan_num_buffer + si] always legal
scan_num_buffer_len dw scan_num_sentinal2 - scan_num_buffer
	
endp 

;---------------------------------------------------
;  PRINT_NUM_BY_BASE - 
;         Prints a number in base 2-16 
;
;         IN: AX - Number
;             BX - Base
;
;        OUT: None
;---------------------------------------------------
proc PRINT_NUM_BY_BASE
    PUSH_REGS <ax, bx, cx, dx>
    
    mov  cx, 0

@@DIGIT_LOOP:
    mov  dx, 0
    div  bx  ; DX:AX / BX = AX and Remainder: DX
 
    push dx
    inc  cx

    cmp  ax, 0
    jne  @@DIGIT_LOOP

@@PRINT:
    pop  dx
    call PRINT_NIBBLE
    loop @@PRINT

    POP_REGS <dx, cx, bx, ax>
    ret

endp PRINT_NUM_BY_BASE
 
;--------------------------------------------------------------------------------------
; PRINT_NUM_BIN
;    Prints a 16 bit register to the screen in base 2
;    IN:  ax
;    OUT: None
;--------------------------------------------------------------------------------------
proc PRINT_NUM_BIN
   push bx
   mov  bx, 2
   call PRINT_NUM_BY_BASE
   PUTC 'b'
   pop  bx
   ret
endp

;--------------------------------------------------------------------------------------
; PRINT_NUM_DEC 
;    Prints a 16 bit register to the screen in base 10
;    IN:  ax
;    OUT: None
;--------------------------------------------------------------------------------------
proc PRINT_NUM_DEC
   push bx
   mov  bx, 10
   call PRINT_NUM_BY_BASE
   pop  bx
   ret
endp

;--------------------------------------------------------------------------------------
; PRINT_NUM_HEX
;    Prints a 16 bit register to the screen in base 16
;    IN:  ax
;    OUT: None
;--------------------------------------------------------------------------------------
proc PRINT_NUM_HEX
   push bx
   mov  bx, 16
   call PRINT_NUM_BY_BASE
   PUTC 'h'
   pop  bx
   ret
endp


;--------------------------------------------------------------------------------------
; PRINT_NUM_DEBUG
;    Prints a 16 bit register to the screen in base 10 and base 16 formatted for debug
;    IN:  ax
;    OUT: None
;--------------------------------------------------------------------------------------
proc PRINT_NUM_DEBUG
    push bx
    
    mov  bx, 16
    call PRINT_NUM_BY_BASE
    
    PUTC 'h'
    PUTC ' '
    PUTC '('

    mov  bx, 10
    call PRINT_NUM_BY_BASE

    PUTC ')'
    call NEW_LINE

    pop  bx
    ret 
endp 

;--------------------------------------------------------------------------------------
; PRINT_STR
;    Prints a string ending with ascii 0
;    IN:  si - address of string
;    OUT: None
;--------------------------------------------------------------------------------------
proc PRINT_STR
    push ax
    push si
    
@@CHAR_LOOP:
    lodsb
    or   al, al
    jz   @@EXIT
    PUTC al
    jmp  @@CHAR_LOOP

@@EXIT:
    pop  si
    pop  ax
    ret 
endp 

;--------------------------------------------------------------------------------------
; SCAN_STR
;    Reads a string from the user, and puts an ascii zero at the end
;    Please note that the user is limited 
;    IN:  si - address of string
;         cx - max string length (including the ascii zero) (0 is a special value - unlimited)
;
;    OUT: si - not changed, but points to the string entered by user
;         cx - Length of string entered by user (not including the ascii zero)
;        
;--------------------------------------------------------------------------------------
proc SCAN_STR
    PUSH_REGS <ax,bx>

    dec cx
    mov bx, 0

@@READ_CHAR:
    ; Read from keyboard
    mov  ah, 00h
    int  16h
    
    cmp  al, 13
    je   @@DONE

    cmp  al, 8 ; Backspace
    je   @@handle_backspace

    cmp  bx, cx
    je   @@READ_CHAR

    PUTC al
    mov  [si + bx], al
    inc  bx
    jmp  @@READ_CHAR
    

@@handle_backspace:
    cmp  bx, 0
    je   @@READ_CHAR
    
    dec  bx
    PUTC 8
    PUTC 20h
    PUTC 8
    jmp  @@READ_CHAR


@@DONE:
    mov  [BYTE si + bx], 0
    call NEW_LINE

    mov  cx, bx  
    POP_REGS  <bx,ax>

    ret 
endp 



