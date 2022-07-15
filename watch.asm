; --------------------------------------------------------------
;
; Title:	Watch
; Author:	Oleksandr Babenko
;
; Before running the program:
;	- Set the speed of the processor to 64 kHz
;	- If you experience lags during the execution,
;	  you should hide the memory panel (View -> Memory)
;
; Description:
;	The program represents a simple watch. On the beginning of
;	the program, you are asked to enter your desired time in
;	the format like HH:MM:SS, meaning that you are expected to
;	enter digits in such order as described WITHOUT entering
;	the colon sign ( ":" ). After entering the desired number
;	(after entering the last 6th digit), the watch will
;	automatically begin working.
;
;	If you want to reset the time value, just press "*", and
;	the program will restart, meaning that you are expected to
;	enter new time value. After that, the watch will again
;	continue working.
;
;	And please, enter a correct time value, e.g. time 34:74:80
;	is NOT an appropriate value.
;
; Some good notes:
;	I have in my code some abbreviations like:
;
;		- HH - meaning the hours digits
;		- MM - meaning the minute digits
;		- SS - meaning the second digits
;
;		- H1 - meaning the first hour digit
;		- H2 - meaning the second hour digit
;		- M1 - meaning the first minute digit
;		- M2 - meaning the second minute digit
;		- S1 - meaning the first second digit
;		- S2 - meaning the second second digit
;
; --------------------------------------------------------------













; --------------------------------------------------------------
;
; Execution starts here
;
; --------------------------------------------------------------


JMP main ; first, we jump to the main code


; --------------------------------------------------------------
;
; We jump here when the timer value reaches 0
;
; So basically my code has one important, as I call it,
; "status" register D. I call it "status", because it allows me
; to constantly check at which point of the program I am.
; On the very beginning of the program, when we are reading the
; values that we wish to enter, after each read digit, the
; "status" register D increases, so that when we enter the last
; read digit (which is S2), the register D is 6, and after that
; we are jumping to the part of the code which is responsible
; for changing the values of the watch as time is running.
;
; --------------------------------------------------------------

isr:

CMP D, 0 ; if it is the beginning of reading values,
JE isr_read_h1 ; then read the first digit

CMP D, 1 ; if it is the second digit of HH
JE isr_read_h2 ; read second digit and enter ":" sign

CMP D, 2 ; if it is first digit of MM
JE isr_read_m1 ; read it

CMP D, 3 ; if it is the second digit of the MM
JE isr_read_m2 ; read the second digit and enter ":" sign

CMP D, 4 ; if it is the first digit of SS
JE isr_read_s1 ; read it

CMP D, 5 ; if it is the second digit of the SS
JE isr_read_s2 ; read it AND SAVE THE VALUES TO THE VARIABLES hh, mm and ss

CMP D, 6 ; if we read all the digits, 
JE isr_watch ; then begin with watch "mechanics"













isr_read_h1: ; read the first digit

CALL display_clear ;first of all, we clear the display so that the old string wipes out

CALL read_num ; read the first input number

IRET ; return from interrupt













isr_read_h2: ; read the second digit

CALL read_num ; read the second input number

MOVB [C], 58 ; it is the ASCII code for ":", we put this to the text display
INC C ; next text block adress

IRET ; return from interrupt













isr_read_m1: ; read the third digit

CALL read_num ; read the third input number

IRET ; return from interrupt














isr_read_m2: ; read the fourth digit

CALL read_num ; read the fourth input number

MOVB [C], 58 ; it is the ASCII code for ":", we put this to the text display
INC C ; next text block adress

IRET ; return from interrupt











isr_read_s1: ; read the fifth digit

CALL read_num ; read the fifth input number

IRET ; return from interrupt
















isr_read_s2: ; read the sixth input number

PUSH A ; store the reg A
IN 6 ; read the pressed key symbol

MOVB [C], AL ; write the symbol to text display
; no more this - INC C ; next text block adress
; no more this - INC D ; counter++

MOV A, 1 ; set the first bit to clear the interrupt
OUT 2 ; clear the interrupt (A -> IRQEOI)

; no more this - MOVB [C], 58 ; it is the ASCII code for ":"

POP A ; restore the reg A


; --------------------------------------------------------------
;
; THIS IS ORIGINAL - Aside from reading the sixth value of
; the input number, here we are enabling the timer
;
; --------------------------------------------------------------


PUSH A ; store the register

MOV A, 64000 ; 1 second = 64000 cycles ! ! !
OUT 3 ; put the value to the timer

MOV A, 3 ; prepare for timer AND KEYBOARD interrupts
OUT 0 ; enable timer interrupts

POP A ; restore the register
INC D ; next step for our program




; --------------------------------------------------------------
;
; At this point we are saving the read values to their variables
;
; --------------------------------------------------------------



MOV A, 0x0ee0 ; adress of the first digit of HH
MOV B, hh ; pointer to the HH var
MOV C, [A] ; store in C the read values of HH
MOV [B], C ; save the hh values to the hh variable

MOV A, 0x0ee3 ; adress of the first digit of MM
MOV B, mm ; pointer to the MM var
MOV C, [A] ; store in C the read values of MM
MOV [B], C ; save the mm values to the hh variable

MOV A, 0x0ee6 ; adress of the first digit of SS
MOV B, ss ; pointer to the SS var
MOV C, [A] ; store in C the read values of SS
MOV [B], C ; save the ss values to the ss variable

PUSH D ; store the register D
PUSH time
CALL display ; display the given time
POP D ; restore the register D

IRET ; return from interrupt

















; --------------------------------------------------------------
;
; Here is located the part of the code which is responsible for
; changing the values of HH:MM:SS, in other words, here we are
; increasing the values of numbers and at the same time
; checking if we are over 59 second, minute, etc...
;
; And here we are also cheking for the pressed button if it was
; pressed or not, which button was pressed, etc...
;
; --------------------------------------------------------------


isr_watch:

IN 1
CMP A, 2 ; if NO button was pressed (so it is timer interruption)
JE isr_watch_continue ; proceed with normal watch counting

; otherwise - if some button was pressed
; what we have above in the comment should be only AFTER we read a value from IO register 6, so that value from IO register 5 is reset to 0
;MOV A, 1 ; set the first bit to clear the interrupt
;OUT 2 ; clear the interrupt (A -> IRQEOI)

IN 6
CMP A, 42 ; if the pressed button wasn't "*"

MOV A, 1 ; set the first bit to clear the interrupt
OUT 2 ; clear the interrupt (A -> IRQEOI)

JNE iret ; then just proceed with timer counting

; otherwise - if the pressed button was exactly "*"
JMP main_restart ; restart the program



iret: ; exit keyboard interruption
IRET ; return from interrupt and proceed with timer counting














isr_watch_continue:
MOV A, 2 ; set the second bit to clear the interrupt
OUT 2 ; clear the interrupt (A -> IRQEOI)

; HERE WILL BE THE WATCH MECHANICS

MOV B, [ss] ; here we store the values of S1S2
CMPB BL, 57 ; if s2 is 9
JE next_s1 ; then increase s1 and reset s2 to 0

; otherwise - increase s2
INCB BL ; s2++
MOV [ss], B ; save the value to the ss directly

PUSH D ; store the reg D
PUSH time ; pass the time string in order to refresh the display
CALL display
POP D ; restore the reg D

IRET ; return from interrupt
















next_s1: ; label for increasing s1 and resetting s2 to 0

CMPB BH, 53 ; if s1 is 5 (so the whole SS looks like 59)
JE next_m2 ; SS becomes 00, and the minute value increases

; otherwise - if the SS is 09, 19, 29, 39 or 49
INCB BH ; s1++
MOVB BL, 48 ; set s2 to 0
MOV [ss], B ; save the value to the ss directly

PUSH D ; store the reg D
PUSH time ; pass the time string in order to refresh the display
CALL display
POP D ; restore the reg D

IRET ; return from interrupt














next_m2:
MOVB BH, 48 ; reset the whole S1 to 0
MOVB BL, 48 ; reset the whole S2 to 0
MOV [ss], B ; save the value to the ss directly

; next minute itself
MOV B, [mm] ; get the value of var MM to the reg B
CMPB BL, 57 ; if the m2 value is 9
JE next_m1 ; then reset M2 to 0 and increase the M1 value

; otherwise
INCB BL ; next minute
MOV [mm], B ; write the value directly to the MM variable

PUSH D ; store the reg D
PUSH time ; pass the time string in order to refresh the display
CALL display
POP D ; restore the reg D

IRET ; return from interrupt













next_m1:
CMPB BH, 53 ; if m1 is 5 (so the whole SS looks like 59)
JE next_h2

; otherwise
INCB BH ; M1++
MOVB BL, 48 ; reset the whole M2 to 0
MOV [mm], B ; save the value to the MM directly

PUSH D ; store the reg D
PUSH time ; pass the time string in order to refresh the display
CALL display
POP D ; restore the reg D

IRET ; return from interrupt













next_h2: ; if MM looks like 59
MOVB BH, 48 ; reset the whole M1 to 0
MOVB BL, 48 ; reset the whole M2 to 0
MOV [mm], B ; save the value to the MM directly

; next hour itself
MOV B, [hh] ; get the value of var HH to the reg B

CMP B, 0x3233 ; IF THE WHOLE HH VAR IS 23 (0x32 is ASCII code for 2, and 0x33 is for 3)
JE new_cycle ; begin the watch from 00:00:00

; otherwise
CMPB BL, 57 ; if the h2 value is 9
JE next_h1 ; then reset H2 to 0 and increase the H1 value

; otherwise
INCB BL ; next minute
MOV [hh], B ; write the value directly to the HH variable

PUSH D ; store the reg D
PUSH time ; pass the time string in order to refresh the display
CALL display
POP D ; restore the reg D

IRET ; return from interrupt
















next_h1:
INCB BH ; H1++
MOVB BL, 48 ; reset the whole H2 to 0
MOV [hh], B ; save the value to the HH directly

PUSH D ; store the reg D
PUSH time ; pass the time string in order to refresh the display
CALL display
POP D ; restore the reg D

IRET ; return from interrupt














; --------------------------------------------------------------
;
; When we reach 23:59:59, we reset the watch to 00:00:00
;
; --------------------------------------------------------------

new_cycle:
MOV B, 0x3030 ; put here 00 ; (0x30 is ASCII code for 0)
MOV [hh], B ; store the value in HH var

MOV B, 0x3030 ; put here 00 ; (0x30 is ASCII code for 0)
MOV [mm], B ; store the value in MM var

MOV B, 0x3030 ; put here 00 ; (0x30 is ASCII code for 0)
MOV [ss], B ; store the value in SS var

PUSH D ; store the reg D
PUSH time ; pass the time string in order to refresh the display
CALL display
POP D ; restore the reg D

IRET ; return from interrupt




















; --------------------------------------------------------------
;
; Here we have our strings
;
; --------------------------------------------------------------


intro: DB "Enter your time like HH:MM:SS"
DB 0


; --------------------------------------------------------------
;
; The interesting thing about the string "time" is that it
; includes also the variables "hh", "mm" and "ss", which are
; initially empty, and after they are filled with the values
; that we enter on the beginning of the program, they are not
; zero any more, and the "official" zero-terminating ending of
; this string is after the "ss" variable. I did it that way
; because I wanted to be the string "time" all the time be
; visible on the text display. So, when the value of the watch
; is updated, we display this string again with updated
; varialbes "hh", "mm" and "ss" on the text display.
;
; --------------------------------------------------------------

time: DB "Time is "
hh: DW 0
DB ":"
mm: DW 0
DB ":"
ss: DW 0
DB 0 ; the end of the string












; --------------------------------------------------------------
;
; Our functions are stored here
;
; --------------------------------------------------------------

display_clear:  ; clear the display so that old string wipes out from the display:
PUSH B ; store the reg B before the function execution
PUSH C ; store the reg C before the function execution
MOV B, display_start ; pointer to the first text pixel
MOV C, display_end ; pointer to the last pixel adress

display_clear_loop:
CMP B, C ; if we reached all the text pixels
JA display_clear_return ; then go back

; otherwise
MOVB [B], 0 ; clear the text block
INC B ; next text block adress
JMP display_clear_loop ; loop again

display_clear_return:
POP C ; restore the reg C before the function execution
POP B ; restore the reg B before the function execution
RET ; exit function







display: ; display the given string on the display
CALL display_clear ; first of all, we clear the display
POP D ; store the return adress
POP A ; store the pointer to the string
PUSH D ; restore the return adress

MOV B, display_start ; pointer to the first text pixel
MOV C, display_end ; pointer to the last pixel adress

display_loop:
MOVB DL, [A] ; store here the char at the adress which is in A
CMPB DL, 0 ; if the char is zero-terminating ( 0 )
JE display_return ; then exit function

; otherwise
CMP B, C ; if we used all the text blocks
JA display_return ; then exit function

;otherwise
MOVB [B], DL ; write the first char to the text block
INC A ; pointer to the next char
INC B ; next text block adress
JMP display_loop


display_return:
RET ; exit function











read_num: ; read an input number and display it
PUSH A ; store the reg A as it will be used by ISR
IN 6 ; read the pressed key symbol.

MOVB [C], AL ; write the symbol to the text display.
INC C ; next text block adress
INC D ; counter++ - next step - new "status" of the program

MOV A, 1 ; set the first bit to clear the interrupt.
OUT 2 ; clear the interrupt (A -> IRQEOI)

POP A ; restore register A to its original values.

RET ; exit function






















; --------------------------------------------------------------
;
; The label below is mentioned for the restarting the program.
; We first pop three values, or better to say, "delete" three
; values from the stack because we did not officially returned
; from the interruption with command IRET because we do not need
; to return back to HLT, but we want to restart the program. So
; basically here we just restore all the registers to their
; initial values as in the beginning of the program, immitating
; the new start. 
;
; --------------------------------------------------------------




main_restart:
POP A
POP A
POP A ; so here we basically do not IRET, we manually exit from interruptions and by this kinda restart the program

; after fixing the code it is always 0, so this command will make things only worse - even though it's 0, it WILL BECOME 3, although we are setting this to 0, so if it is 0, you can't just reset it again to 0, otherwise a problem will occur - MOV A, 3
; after fixing the code it is always 0, so this command will make things only worse - even though it's 0, it WILL BECOME 3, although we are setting this to 0, so if it is 0, you can't just reset it again to 0, otherwise a problem will occur - OUT 2 ; ending all the interrupts

MOV A, 0
OUT 3 ; reset the timer. If we will not do this, then new S2 will appear too fast as timer was not reseted

; ВАЖНО! CLI и OUT 0 НУЖНО ДЕЛАТЬ ТОЛЬКО ПОСЛЕ ТОГО, КАК БЫЛО OUT 2, OUT 3... ИНАЧЕ НЕ ЗАПИШЕТСЯ!
CLI ; disable interrupts globally (M = 0)

MOV A, 0
OUT 0 ; disabling all the interrupts

MOV A, 0
MOV B, 0
MOV C, 0
MOV D, 0 ; we reset each register to 0 as in the beginning of the program



; --------------------------------------------------------------
;
; and just proceed with main label below, like "restarting"
; the program.
;
; --------------------------------------------------------------



; --------------------------------------------------------------
;
; This is the basis for our code. It is the main part.
;
; --------------------------------------------------------------

main:
MOV SP, 0x0edf ; initializing stack pointer

PUSH intro ; intro string as an argument
CALL display ; display the given string

MOV A, 1 ; set the first bit to enable keyboard interrupts
OUT 0 ; enable keyboard interrupts (A -> IRQMASK)
STI ; enable interrupts globally (M = 1)


MOV C, display_start ; pointer to the first pixel of text block for entering digits of the watch
MOV D, 0 ; counter for reading HH, MM, SS and then for counting time; it is the "status" of our program
HLT ; halt and let interrupts do the rest





; --------------------------------------------------------------
;
; For more comfortable coding we add labels for the beginning
; block of the display and the last block of the display.
;
; --------------------------------------------------------------


org 0x0ee0
display_start:

org 0x0eff
display_end:


