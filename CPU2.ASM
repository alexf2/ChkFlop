
Ideal

P386
Model use16 tiny

Group  MyCode  Code3

          PUBLIC TestCPU

Segment  Code3  word public 'Code'
Assume  cs:MyCode


PROC  TestCPU

        Xor dx,dx   ; 86
	Pushf
	Pop bx
	And bh,0Fh
	Push bx
	Popf
	Pushf
	Pop ax
	And ah,0F0h
	Cmp ah,0F0h
	Je @@cpu_end

	Mov dx,1    ; 286
	Or bh,0F0h
	Push bx
	Popf
	Pushf
	Pop ax
	Test ah,0F0h
	Jz @@cpu_end

	Mov edx,esp
	And esp,NOT 3
	Pushfd
	Pop eax
	Mov ecx,eax
	Xor eax,40000h
	Push eax
	Popfd
	Pushfd
	Pop eax
	Xor eax,ecx
	Shr eax,18
	And eax,1
	Push cx
	Popfd
	Mov esp,edx
	Mov dx,2    ; 386
	Test ax,ax
	Jz @@cpu_end
	Mov dx,3    ; 486

@@cpu_end:
	Mov ax,dx
	Ret

ENDP  TestCPU

ENDS  Code3
	
	END

