
Ideal

P286
Model tiny
Locals

Group  MyCode  Code2

         PUBLIC  Beep, Delay, TimerInit, Play, Sound, NoSound

Segment  Code2  word public 'Code'
Assume  cs:MyCode, ds:MyCode

PROC  Dummy  near

	Ret

ENDP  Dummy

PROC  ReadTimer near

	Pushf                    ;/* Save interrupt flag                       */
	Cli                      ;/* Disable interrupts                        */
	Xor  	al, al           ;    /* Latch timer 0                             */
	Out  	43h, al
        Call	Dummy            ;    /* Waste some time */
	In   	al, 40h          ;    /* Counter --> bx                            */
	Mov  	bl, al           ;    /* LSB in BL                                 */
        Call	Dummy            ; /* Waste some time */
	In   	al, 40h
	Mov  	bh, al           ;    /* MSB in BH                                 */
	Not  	bx               ;   /* Need ascending counter                    */
	Popf                     ;/* Restore interrupt flag                    */

        Ret

ENDP  ReadTimer


PROC  TimerInit near

	Push	ax bx cx

	Mov	cx, 100
@@read:
        Call   	ReadTimer
        Test	bx, 1h      
        Jne	@@next
        Mov	[word ptr cs:multiplier], 1193
	Mov	[word ptr cs:multiplier+2], 0	           
        Jmp	SHORT @@ret
@@next:
	Loop	@@read

@@ret:
	Pop	cx bx ax
	Ret

multiplier  DD  1193*2

ENDP  TimerInit

PROC  MulDDxDD  near ;ax:bx , dx:cx low:high; return - ax:dx

	Push	ds

	Push	cs
        Pop	ds
        Mov	[word ptr multcnd], bx
        Mov	[word ptr multcnd+2], ax
        Mov	[word ptr multplr], cx
        Mov	[word ptr multplr+2], dx

        Mov	ax, [word ptr multcnd+2]
        Mul	[word ptr multplr+2]
        Mov	[word ptr result+6], ax
        Mov	[word ptr result+4], dx
        Mov	ax, [word ptr multcnd+2]
        Mul     [word ptr multplr]
        Add	[word ptr result+4], ax
        Adc	[word ptr result+6], dx
        Adc	[word ptr result], 0
        Mov	ax, [word ptr multcnd]
        Mul	[word ptr multplr+2]
        Add	[word ptr result+4], ax
        Adc	[word ptr result+6], dx
        Adc	[word ptr result], 0
        Mov	ax, [word ptr multcnd]
        Mul	[word ptr multplr]
        Add	[word ptr result+2], ax
        Adc	[word ptr result], dx

        Mov     ax, [word ptr result+6]
        Mov	dx, [word ptr result+4]

	Pop	ds
        Ret

multcnd  DD  ?
multplr  DD  ?
result   DD  ?
	 DD  ?

ENDP  MulDDxDD

PROC  MulDDxDDb  near ;ax:dx , cx:bx low:high; return - ax:dx

	Push	si

        Xchg	si, ax
        Xchg	dx, ax
        Test	ax, ax
        Je	@@next00
        Mul	bx
@@next00:
        Jcxz	@@next01
        Xchg	cx, ax
        Mul	si
        Add	ax, cx
@@next01:
        Xchg	si, ax
        Mul	bx
        Add	dx, si

        Pop	si
        Ret

ENDP  MulDDxDDb

PROC Delay  near ; ax:dx - time low:high

	Push	cx dx ds
        Push	cs
        Pop	ds

	Mov	bx, [word ptr multiplier]
        Mov	cx, [word ptr multiplier+2]
        ;Call    MulDDxDD ; ax:dx
        Call    MulDDxDDb
        Push	ax
        Call	ReadTimer ; bx
        Pop	ax
        Mov	[prev], bx
        Add     ax, bx
        Adc	dx, 0
        Mov     [word ptr stop], ax
        Mov     [word ptr stop+2], dx

@@loop_wait:
	Call	ReadTimer ; bx
        Cmp	[word ptr stop+2], 0
        Jnz     @@next00
        Cmp	bx, [word ptr stop]
        Jae	@@end_wait

@@next00:
        Cmp	bx, [prev]
        Jae	@@next
        Cmp     [word ptr stop+2], 1
        Jb      @@end_wait   

@@sub:
        Sub	[word ptr stop+2], 1
@@next:
	Mov	[prev], bx
        Jmp	SHORT @@loop_wait

@@end_wait:
	Pop	ds dx cx
	Ret

stop	DD	?
prev    DW      ?

ENDP  Delay

PROC  Sound near ; di - rate

	Push	ax dx

	Mov 	al, 0B6h
	Out 	43h, al
	Mov 	dx, 12h    ;14h
	Mov 	ax, 34DDh  ;4F38h
	Div 	di
	Out 	42h, al
	Mov 	al, ah
	Out 	42h, al
	In 	al, 61h
	Or 	al, 3
	Out 	61h, al

        Pop	dx ax
        Ret

ENDP  Sound

PROC  NoSound  near

        Push	ax

	In 	al, 61h
        And	al, NOT 3
        Out	61h, al

        Pop	ax
        Ret

ENDP  NoSound

PROC  Beep  near  ; di - rate , bx - delay

	Push 	ax bx dx

	Call	TimerInit
        Call	Sound
     	Mov	ax, bx
        Xor	dx, dx
        Call	Delay
	Call	NoSound

	Pop  	dx bx ax
	Ret

ENDP  Beep

PROC  Play  near  ; ds:si - string word:word - rate, delay
                  ; if in rate bit15=1 then delay - jmp offset in DD:
	          ; if in offset bit15=0 - the jmp incr. else decr.		
		  ; if rate=delay=0 - then end
	Push	ax dx si di ds

	Call	TimerInit	
	Xor	dx, dx
@@play_loop:
	Cld
	Lodsw
	Mov	di, ax
	Lodsw
	Or	di, di
	Jnz	@@find_jmp
	Or	ax, ax
	Jz	@@end_play

@@find_jmp:
	Test	di, 1000000000000000b	
	Jnz	@@make_jmp	
	Call	Sound
	Call	Delay
	Jmp	SHORT @@play_loop

@@make_jmp:
	Test	ax, 1000000000000000b
	Jnz	@@decr
	Shl	ax, 2
	Add	si, ax
	Jmp	SHORT @@play_loop
@@decr:
	And	ax, 0111111111111111b
	Shl	ax, 2
	Sub	si, ax
	Jmp	SHORT @@play_loop

@@end_play:
	Call	NoSound
	Pop	ds di si dx ax
	Ret

ENDP  Play

ENDS  Code2

	END

