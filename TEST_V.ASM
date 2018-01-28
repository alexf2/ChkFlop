;Masm
Ideal

P286
Model tiny
Locals

;.286
;.Model tiny

	    ERR_RATE    EQU      800
            ERR_DEL     EQU      100

Group MyCode  Code3

	PUBLIC  TestVirus

        EXTRN   Beep        :PROC
        EXTRN   File_length :DWORD
        EXTRN   File_CRC    :DWORD  ;должна быть последней в готовом COM файле
	EXTRN   Play        :PROC
	EXTRN   start       :NEAR   ;метка начала программы
	EXTRN   end_start   :NEAR   ;метка конца программы

; С начала в переменную File_length заносится длина файла.
; Потом нужно пустить программу в отладчике и после ее завершения по ошибке
; контрольнй суммы надо узнать начение последних 4-х байт исполняемого файла -
; там находится переменная File_CRC. Правильное значение она получает только
; после завершения программы не по ошибке длины а по ошибке CRC !
; Далее надо инициализировать этими данными переменную File_CRC в исходнике
; программы переставив при этом старшое и младшее слова. 
; Например если из отладчика получен дамп  D3 00 DB 41 то в программе надо
; написать  File_CRC  DD  0DB41D300h.

Segment  Code3  word public 'Code'
Assume  cs:MyCode


PROC  TestVirus near

	Call 	Get_EXEName
	;Push 	es
	;Push 	ds
	Mov 	dx, di
	Mov 	ax, es
	Mov 	ds, ax
	Mov 	ax, 3D00h   ;open
	Int 	21h

        Push	cs cs
	Pop	es ds
	Jnc 	@@Get_Len
        Jmp	SHORT  @@IO_error_nc

@@IO_error:
	Mov 	ah, 3Eh     ;close
	Int 	21h
@@IO_error_nc:
	Push 	cs cs
	Pop 	es ds
	Mov 	bp, OFFSET IO_error_msg
	Mov 	bl, 12
	Call 	Teletype
	Jmp 	SHORT @@term

@@Err_CRC:
	Mov	ah, 3Eh
	Int	21h
	Push 	cs cs
	Pop 	es ds
	Mov 	bp, OFFSET CRC_error_msg
	Mov 	bl, 12
	Call 	Teletype

@@Loo:
	;Push	cs
     	;Pop	ds
	Mov	si, OFFSET soundErr
@@play:
	Call	Play
        Mov	ah, 1
        Int	16h
        Jnz	@@term_
        Jmp	SHORT @@play
@@term_:
	Xor	ax, ax
        Int	16h
        Mov	ax, 4C01h
        Int	21h


@@term:
	Mov	si, OFFSET soundErr
;	Mov	bx, OFFSET loop_sound
;	Mov	[word ptr cs:bx],   0
;	Mov	[word ptr cs:bx+2], 0
	Call	Play
	Mov	ax, 4C01h
	Int	21h

@@Get_Len:
	Mov 	bx, ax
	Xor 	dx, dx
	Mov 	cx, dx
	Mov 	ax, 4202h  ;seek end
	Int 	21h
	Jc 	@@IO_error

	Cmp 	ax, [WORD PTR File_length]
	Jne 	@@Err_CRC
	Cmp 	dx, [WORD PTR File_length+2]
	Jne 	@@Err_CRC

;******************  Test  CRC  ******************
	Xor	dx, dx
        Mov	ax, 4200h
        Int	21h
        Jc      @@IO_error

        Mov	ah, 3Fh
        Mov	cx, [word ptr File_length]
        Mov	dx, 100h
        Int	21h
        Jnc     @@next03
	Jmp	@@IO_error
@@next03:
        Cmp	ax, cx
        Je      @@next00
	Jmp	@@IO_error

@@next00:
        Mov	dx, [word ptr start]
        Mov	ax, [word ptr start+2]
        Mov	di, OFFSET start+4
        Mov	cx, OFFSET end_start
	Sub	cx, OFFSET start
	Sub	cx, 8

        Push	bx
@@next_byte:
        Mov	bl, [byte ptr di]
        Inc	di
        Mov	bh, 8

@@shift_CRC:
	Shl	bl, 1
        Rcl	ax, 1
        Rcl	dx, 1
        Jnc	@@test_EOB
        Xor	ax, 0FFFFh
        Xor	dx, 0FFFFh

@@test_EOB:
	Dec	bh
        Jnz     @@shift_CRC
        Loop    @@next_byte
        Pop	bx
				          
        Cmp	dx, [word ptr File_CRC]
        Jnz	@@err_jmp
        Cmp	ax, [word ptr File_CRC+2]
        Jnz	@@err_jmp

	Mov	ah, 3Eh
	Int	21h
	Ret

@@err_jmp:
        Mov	[byte ptr File_CRC], dh
        Mov	[byte ptr File_CRC+1], dl
        Mov	[byte ptr File_CRC+2], ah
        Mov	[byte ptr File_CRC+3], al
        Jmp     @@Err_CRC

ENDP  TestVirus



PROC  Get_EXEName near  ; ex: es:di - path name

	Push 	ds

	Mov 	es, [WORD PTR 2Ch]
	Xor 	ax, ax
	Mov 	di, ax
	Cld

@@Scan_env:
	Scasb
	Jnz 	@@Scan_env
	Cmp 	al, [BYTE PTR es:di]
	Jnz 	@@Scan_env
	Add 	di, 3

	Pop 	ds
	Ret

ENDP  Get_EXEName

PROC  Teletype near ; es:bp - str , bl - atr

	Push 	di
	Push 	es

	Les 	di, [DWORD PTR cs:@@BIOS_page]
	Mov 	bh, [BYTE PTR es:di]
	Pop 	es
	Mov 	ah, 3
	Int 	10h

	Mov 	di, bp
	Mov  	cx, 1024
	Mov 	al, '$'
	Cld
	REPNZ 	Scasb
	Sub 	di, bp
	Mov 	cx, di
	Dec 	cx

	Mov 	ax, 1301h
	Int 	10h

	Pop 	di
	Ret

@@BIOS_page    DW 62h
@@BIOS_page_s  DW 40h

ENDP  Teletype


IO_error_msg DB 10,13,"Невозможно проверить CRC файла - ошибка ввода/вывода",10,13,'$'
CRC_error_msg  DB  10,13
      DB     "╔═══════════════════════════ ПРЕДУПРЕЖДЕНИЕ ! ═══════════════════════════╗",10,13
      DB     "║                                                                        ║",10,13
      DB     "║             Обнаружены нарушения в структуре программы:                ║",10,13
      DB     "║                                                                        ║",10,13
      DB     "║      это результат сбоя аппаратуры или наличия активного ВИРУСА !      ║",10,13
      DB     "║                                                                        ║",10,13
      DB     "║ Рекомендация:  Вам надо проверить устройство ввода/вывода, либо логи-  ║",10,13
      DB     "║                ческую структуру диска и целостность программы, но      ║",10,13
      DB     "║                прежде всего проведите АНТИВИРУСНУЮ ДИАГНОСТИКУ.        ║",10,13
      DB     "║                                                                        ║",10,13
      DB     "╚════════════════════════════════════════════════════════════════════════╝",10,13,'$'


soundErr  DW   50,5,  70,5,  90,5, 110,5, 130,5, 150,5, 170,5
	  DW  190,10, 210,10, 230,10, 250,10, 270,10, 290,10, 310,10
          DW  330,10, 350,10, 370,10, 390,10, 410,10, 430,10, 450,10
          DW  470,10, 490,10, 510,10, 530,10, 550,10, 570,10, 590,10
          DW  610,20, 630,20, 650,20, 670,20, 690,20, 710,20, 730,20
          DW  750,20, 770,20, 790,20, 810,20, 830,20, 850,20, 870,200

          DW  850,20, 830,20, 810,20, 790,20, 770,20, 750,20
          DW  730,20, 710,20, 690,20, 670,20, 650,20, 630,20, 610,20
          DW  590,20, 570,20, 550,20, 530,20, 510,20, 490,20, 470,20
          DW  450,10, 430,10, 410,10, 390,10, 370,10, 350,10, 330,10
          DW  310,10, 290,10, 270,10, 250,10, 230,10, 210,10, 190,20
          DW  170,5, 150,5, 130,5, 110,5,  90,5,  70,5,  50,5, 0, 0
;LABEL loop_sound WORD
;          DW  8000h,(8000h OR 84), 0,0

ENDS Code3  

        END

