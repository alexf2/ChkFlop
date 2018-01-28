Ideal

include 'vga.ash'
include 'tsrid.inc'
include 'dossys.ash'

P286
Model tiny
Locals

typedef  VIDEOBIOS_PTR  far ptr VIDEOBIOS

MACRO  GetVioSegm  reg  ; ds:bx - Lds	bx, [cs:bios]
       Local @@mono, @@next00

	Cmp	[(VIDEOBIOS bx)._3x4], 03D4h
	Jnz	@@mono
	Push	0B800h
	Jmp	SHORT @@next00
@@mono:
	Push    0B000h
@@next00:
	Pop	reg
endm


Group  MyCode  Code2


Segment  Code2  word public 'Code'
Assume  cs:MyCode, ds:MyCode

	PUBLIC  ClrScr, KeepDisplay, RestoreDisplay

bios         	VIDEOBIOS_PTR	0:410h
vga	     	VGAINFO 	<>
pageClr		DB 0
keepScrBuf	DB 1024*8 Dup(?)


PROC  GetVGAParam near

	Mov 	ah, 1Bh
	Xor	bx, bx
	Push	cs
	Pop	es
	Mov	di, OFFSET cs:vga
	Int	10h

	Ret

ENDP GetVGAParam


PROC  ClrScr  near

	Call	GetVGAParam

	Lds	bx, [cs:bios]
	GetVioSegm	ds

	Push	cs
	Pop	es
	Mov	bx, OFFSET cs:vga
	Mov	ax, [es:(VGAINFO bx).videoPageLen]
	Les	bx, [cs:bios]
	Xor	dh, dh
	;Mov	dl, [es:(VIDEOBIOS bx).actPage]
	Mov	dl, [cs:pageClr]
	Mul	dx
	Push	ax

	Mov	al, [es:(VIDEOBIOS bx).length]
	Inc	al
	Xor	ah, ah
	Mul     [word ptr es:(VIDEOBIOS bx).width]
	Mov	cx, ax

	Mov	ax, ds
	Mov     es, ax
	Xor	ax, ax
	Pop	di
	Cld
	REP 	Stosw

	Ret

ENDP  ClrScr


PROC  KeepDisplay near

	PushAll

	Call	GetVGAParam

		int 3h

	Lds	bx, [cs:bios]
	GetVioSegm	ds
	Xor	si, si
	Mov	di, OFFSET MyCode:keepScrBuf

	Push	cs
	Pop	es
	Mov	bx, OFFSET cs:vga
	Mov	cx, [es:(VGAINFO bx).videoPageLen]	
	Shr	cx, 1

	Push	cs
	Pop	es
	Cld
	REP 	Movsw

	Mov	[cs:pageClr], 0
	Call	ClrScr

	PopAll
	Ret

ENDP  KeepDisplay


PROC  RestoreDisplay  near

	PushAll

	Call	GetVGAParam

	Lds	bx, [cs:bios]
	GetVioSegm	ax
	Xor	di, di
	Mov	si, OFFSET MyCode:keepScrBuf

	Push	cs
	Pop	es
	Mov	bx, OFFSET cs:vga
	Mov	cx, [es:(VGAINFO bx).videoPageLen]	
	Shr	cx, 1

	Mov	es, ax
	Push	cs
	Pop	ds
	Cld
	REP 	Movsw

	;Mov	[cs:pageClr], 1
	;Call	ClrScr

	PopAll
	Ret


ENDP  RestoreDisplay


ENDS  Code2

	END
