Ideal

include 'tsrid.inc'

P286
Model tiny
Locals

Group  MyCode  Code2


Segment  Code2  word public 'Code'
Assume  cs:MyCode, ds:MyCode

	PUBLIC  AllocateUMB, FreeUMB

oldLink       DB  0
oldStrategy   DW  0


PROC  UMBLink near

	Pushf
	Push	ax bx

	Mov	ax, 5802h
	Int	21h
	Mov	[cs:oldLink], al

	Mov	ax, 5800h
	Int	21h
	Mov	[cs:oldStrategy], ax

	Mov	ax, 5803h
	Mov	bx, 1
	Int	21h

	Mov	ax, 5801h
	Mov	bx, 80h
	Int	21h

	Pop	bx ax
	Popf
	Ret

ENDP UMBLink


PROC  UMBUnLink near

	Pushf
	Push	ax bx

	Mov	ax, 5803h
	Xor	bx, bx
	Mov	bl, [cs:oldLink]
	Int	21h

	Mov	ax, 5801h
	Mov	bx, [cs:oldStrategy]
	Int	21h
	
	Pop	bx ax
	Popf
	Ret

ENDP UMBUnLink


PROC  AllocateUMB near  ;INPUT:  bx - size in para
			;OUT:    ax - segment if carry=0

	Call	UMBLink
				
	Push	bx
	Mov 	ah, 48h
	Int	21h
	Jnc	@@ex
	
	Mov	ax, 5801h
	Xor	bx, bx
	Int	21h
	Pop	bx
	Mov 	ah, 48h
	Int	21h
		
	Call 	UMBUnLink	
	Ret

@@ex:			
	Call 	UMBUnLink
	Add	sp, 2
	Ret	

ENDP AllocateUMB


PROC  FreeUMB near   ;INPUT: es - segment

	Call	UMBLink
	Push	ax
	Mov	ah, 49h
	Int	21h

	Pop	ax
	Call	UMBUnLink
	Ret

ENDP FreeUMB

ENDS Code2

	END
