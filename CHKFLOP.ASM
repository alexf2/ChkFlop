Ideal

include 'dossys.ash'
include 'tsrid.inc'



P386
Model use16 tiny
SmallStack
Locals

            ASK_CODE    EQU   00FF07h   ;��� ����� ��� �஢�ન ������⢨� �ணࠬ�� � �����
            _u_         EQU       16h

            ERR_RATE    EQU      800   ;��ࠬ���� ��㪮���� ᨣ���� �訡��
            ERR_DEL     EQU      200   ;

            STK_SIZE    EQU      1024*2  ;bytes - ࠧ��� ᮡ�⢥����� ����᪮�� �⥪�
            MEM_SIZE    EQU      3520    ;para = 200kB 12800 - ࠧ��� १�ࢨ�㥬��� �� ���樠����樨 ����� ����� ��� ����᪠ ��⨢����
                                         ;300kB 19200
            STRPATH_AV1 EQU      'D:\AIDS\anti-dir.exe'

typedef PSP_PTR far ptr PSP ;㪠��⥫� �� ��䨪� �ணࠬ����� ᥣ����

STRUC ParsTyp          ;���� ������ ��� �㭪樨 DOS Exec

     parsSeg     DW ?
     cmdLinPtrO  DW ?
     cmdLinPtrS  DW ?
     FCB1O       DW ?
     FCB1S       DW ?
     FCB2O       DW ?
     FCB2S       DW ?
 ENDS

STRUC FCB

     f DB 0
       DB 11 Dup(?)
       DB 25 Dup(0)

  ENDS


Group  MyCode  Code0, Code1, Code2, Code3, Code4, StkSeg
; �ணࠬ�� ᤥ���� � ������ tiny � ���⮬� ��⮨� �ᥣ� �� ������ ᥣ����
; ����. �������� ����������� � ���� � ���浪� �� ���ᠭ�� � 䠩�� chkflop.asm.
; �⮡� ����� ������� ᥣ���� �ᯮ�짮���� ᬥ饭�� �� ��砫� ����稢襣���
; ������� ᥣ����, ��� ��ꥤ����� � ��㯯�. ��� ��ࢮ�� ᥣ���� ������ ᬥ饭��
; ��� ��砫� Org 100h - �� ��⠢���� ���� ��� PSP. ����� �ணࠬ�� �⠭������
; १����⭮�, � � ����� ������� ���� ���� �� ��砫� 䠩�� �� ��⪨ install
; - ᥣ����� Code0, Code2 � StkSeg. ��⠫�� ᥣ����� ᮤ�ঠ� ���樠�������騩
; ��� � ����뢠����, ⠪ ��� ���ᠭ� ��᫥ ��⪨ install.

        EXTRN  TestCPU        :PROC
        EXTRN  TestVirus      :PROC
        EXTRN  Beep           :PROC
        EXTRN  TimerInit      :PROC
        EXTRN  Play           :PROC
        EXTRN  KeepDisplay    :PROC
        EXTRN  RestoreDisplay :PROC
        EXTRN  AllocateUMB    :PROC
        EXTRN  FreeUMB        :PROC

        PUBLIC  File_length, File_CRC  ;����� � ����஫쭠� �㬬� 䠩��
        PUBLIC  start, end_start       ;��⪨ ��砫� � ���� ����

Segment  Code0  para public 'Code'
Assume   cs:MyCode, ds:MyCode

        Org 100h

start:
StartUpCode

        Jmp     install

enblStart       DB              0      ;ᥬ��� ��ࠡ��稪� Int9 - �ᯮ������ ��� �����஢�� �� ����୮�� �宦����� � ᮡ�⢥��� ��ࠡ��稪
enblGo          DB              0      ;䫠� �����襭�� ���樠����樨 १����� - ��⠭���������� � 1 ��᫥ �� �����襭�� � ࠧ�蠥� ࠡ��� ᮡ�⢥���� ��ࠡ��稪�� ���뢠���
NUMB_DRIVERS    EQU     26
drivers         DB NUMB_DRIVERS Dup(?) ;���ᨢ ⨯�� ���ன�� - �� ��.
ptrMemory       DW 0                   ;ᥣ���� ����� १�ࢨ�㥬�� �� ���樠����樨 ����� ��� ����᪠ ��⨢����
mountFlag       DB 0                   ;䫠� ������ ��᪠
avirActive      DB 0                   ;ᥬ��� ��������騩 ࠡ��� ᮡ�⢥���� ��ࠡ��稪�� ���뢠��� �� �६� ࠡ��� ��⨢����
dosActive       DD ?                   ;���� 䫠�� ��⨢���� DOS


PROC  New2Fh  far                ;��ࠡ��稪 ���⨯����୮�� ���뢠���
                                 ;�㦨� ��� �஢�ન ������ �⮩ �ணࠬ��
                                 ;� ����� � 楫�� �᪫�祭�� ����୮� ����㧪�.
        Pushf
        Cmp     ax, ASK_CODE     ;�� ���樠����樨 ��뢠���� Int2F � �᫮���
        Jnz     @@exit_          ;����� � AX, � �᫨ �ணࠬ�� 㦥 ���⠫�஢���,
                                 ;� � DS:SI �����頥��� ���� ���祢�� ��ப�.
        Mov     si, OFFSET cs:pass
        Mov     ax, cs
        Mov     ds, ax
        Popf
        Iret

@@exit_:
        Popf
        Jmp     [cs:Old2Fh]      ;���室 �� ���� ��ࠡ��稪 Int2F

STA00  =  $
pass      DB  "FlopVT 1.0"
LEN00  =  $-STA00
Old2Fh    DD  ?                  ;���� ��ண� ��ࠡ��稪�

ENDP New2Fh

PROC  New25h                      ;��אַ� �⥭�� ᥪ�� �ᯮ������ ��� ����᪠
                                  ;��⨢���� � ��砥 ���饭�� � �����񭭮�� ����.
        Cmp     [cs:enblGo], 0    ;��᫥ �맮�� ��ண� ��ࠡ��稪� ������������ 䫠� ������ ��᪠
        Jz      @@leave           ;��⠭��������� � ��ࠡ��稪� Int13h � �᫨ �� 1 � DOS �� ��⨢��, � ����᪠���� ��⨢����.
        Cmp     [cs:avirActive], 0
        Jz      @@enter
@@leave:
        Jmp     [cs:Old25h]       ;���室 �� ���� ��ࠡ��稪

@@enter:
        Call    [cs:Old25h]       ;�맮� ��ண� ��ࠡ��稪� (Pushf �� ���� - Int25h �� ��������� 䫠�� �� �⥪�).

        Pushf
        Cmp     [cs:mountFlag], 0 ;�஢�ઠ ᬥ�� ��᪠
        Jz      @@ex

        PushAll
        Lds     bx, [cs:dosActive] ;�஢�ઠ ��⨢���� DOS
        Cmp     [byte ptr bx], 0
        Jnz     @@dosAct

        Mov     [cs:avirActive], 1 ;�����஢�� ����୮�� �宦����� � ᮡ�⢥��� ��ࠡ��稪�
        Call    ExecAntivirus      ;����� ��⨢����
        Mov     [cs:mountFlag], 0
        Mov     [cs:avirActive], 0
@@dosAct:
        PopAll

@@ex:
        Popf
        Ret     2                  ;������ �� ���뢠��� ��� ��������� 䫠��� ��⠭�������� ���� ��ࠡ��稪��

Old25h    DD  ?

ENDP New25h


PROC  New9h far                      ;�஢���� ����⨥ Ctrl+Alt+U � �᫨ ��������� ����� ���㦠�� �ணࠬ��

        Cmp     [cs:avirActive], 0
        Jnz     @@leave
        Cmp     [cs:enblStart], 0
        Jz      @@leave

        Push    es ax
        Mov     [cs:enblStart], 0

        Xor     ax, ax
        Mov     es, ax
        Mov     al, [es:0417h]     ;�⥭�� ���� ���ﭨ� ���������� �� BIOS
        And     al, 00001111b      ; Ctrl+Alt
        Cmp     al, 00001100b
        Jnz     @@old_inter_pop

        In      al, 60h            ;�⥭�� ᪠�-���� ����⮩ ������
        Cmp     al, _u_
        Jz      @@unload


@@old_inter_pop:
        Pop     ax es

@@old_inter:
        Mov     [cs:enblStart], 1
@@leave:
        Jmp     [cs:Old9h]        ;���室 �� ᫥�. ��ࠡ��稪

@@return:
        Pop     ax es
        Mov     [cs:enblStart], 1
        Iret


@@unload:
        Call    near ptr @@inter_end ;�᫨ Ctrl+Alt+U, � �����⭮� ���뢠��� �� ���������� ��ࠡ��뢠���� ��� �맮�� ��ண� ��ࠡ��稪�, �� ������ �� ����⨥ ������ �������� ��� ��㣨� �ணࠬ�
        PushAll
        Call    Unload               ;���㧪� �ணࠬ��
        PopAll
        Jmp     SHORT @@return


@@inter_end:
        Push    ax
        Cli
        In      al, 61h       ;ࠧ�����஢�� ���������� � �����襭�� ��ࠡ�⪨ ���뢠��� � ����஫��� ���뢠���
        Mov     ah, al
        Or      al, 80h
        Out     61h, al
        Xchg    ah, al
        Out     61h, al
        Mov     al, 20h
        Out     20h, al
        Sti
        Pop     ax
        Retn

Old9h     DD  ?

ENDP  New9h

PROC  New21h far                    ;�ᯮ������ ��� ����᪠ ��⨢���� � ��砥 ������ ��᪠.
                                    ;���� ������ �஢������ ��᫥ �맮�� ��ண� ��ࠡ��稪� �
        Cmp     [cs:enblGo], 0      ;�᫨ ���� ����᪠���� ��⨢���� ⠪ ��� DOS ��室���� � ॥��ࠡ��쭮� ���ﭨ�.
        Jz      @@leave             ;
        Cmp     [cs:avirActive], 0  ;
        Jz      @@enter             ;
@@leave:
        Jmp     [cs:Old21h]

@@enter:
        Pushf
        Call    [cs:Old21h]        ;�맮� ��ண� ��ࠡ��稪� (Pushf �㦥� ��� �����樨 Int21h)

        Pushf
        Cmp     [cs:mountFlag], 0  ;�஢�ઠ ᬥ�� ��᪠
        Jz      @@ex

        PushAll
        Mov     [cs:avirActive], 1
        Call    ExecAntivirus      ;����� ��⨢����
        Mov     [cs:mountFlag], 0
        Mov     [cs:avirActive], 0
        PopAll

@@ex:
        Popf
        Ret     2                  ;������ �� ���뢠��� ��� ��������� 䫠���

Old21h        DD  ?

ENDP New21h


PROC  New13h  far                  ;�ᯮ������ ��� �஢�ન ᬥ�� ��᪠ - dl �ᥣ�� ᮤ�ন� ���� ���ன�⢠, ��� 0, 1.. - ᬥ���, � 80h, 81h.. - ��ᬥ���.

        Cmp     [cs:enblGo], 0
        Jz      @@leave
        Cmp     [cs:avirActive], 0
        Jz      @@enter
@@leave:
        Jmp     [cs:Old13h]

@@enter:
        Cmp     dl, 80h
        Jae     @@ex

        PushAll

        Mov     ah, 16h
        Pushf                            ;�㦭� ��� �����樨 Int13h
        Call    [dword ptr cs:Old13h]    ;�맮� ��ண� Int13h ��� �஢�ન ᬥ�� ��᪠ dl
        Cmp     ah, 6
        Jnz     @@noMount

        Add     dl, 'A'                  ;����塞 �㪢� ���ன�⢠
        Mov     [cs:mountFlag], dl


@@noMount:
        PopAll
@@ex:
        Jmp     [dword ptr cs:Old13h]

Old13h    DD  ?
;int13Led  DB  0

ENDP New13h

PROC ExecAntivirus near                ;�᢮������� ��१�ࢨ஢���� ���� �����, ��४��砥��� �⥪ �� ᢮�, � ����᪠�� ��⨢���� �㭪樥� Exec.

        Cmp     [cs:ptrMemory], 0      ;��� ��� ������ �᢮��������� ��। ����᪮� ��⨢���� � १�ࢨ����� ��᫥ ��� �����襭��, � �㦭� �஢�ઠ �� �ᯥ� �� �뤥�����.
        Jnz     @@Ok
        Ret

@@Ok:
        Mov     dl, [cs:mountFlag]
        Mov     [cs:@@cmdLine+2], dl   ;������ ���ன�⢠ � ��ப� ��ࠬ��஢.
        Mov     [cs:@@device], dl

        Mov     ax, 5900h                      ;��࠭���� ���ଠ樨 �� �訡��
        Xor     bx, bx
        Pushf
        Call    [cs:Old21h]
        Mov     [cs:@@oldExtErr], ax
        Mov     [cs:@@oldExtErr+2], bx
        Mov     [cs:@@oldExtErr+4], cx

        Mov     ax, 6200h                ;��࠭���� ⥪�饣� PSP
        Pushf
        Call    [cs:Old21h]
        Mov     [cs:@@oldPSP], bx
        Mov     ax, 5000h              ;��४��祭�� �� ᢮� PSP
        Mov     bx, cs
        Pushf
        Call    [cs:Old21h]

        Mov     [cs:@@OldSS], ss       ;��࠭���� �⥪�
        Mov     [cs:@@OldSP], sp
        Mov     ax, cs
        Cli
        Mov     ss, ax
        Mov     sp, OFFSET MyCode:myStk ;��४��祭�� �� ᢮� �⥪
        Add     sp, STK_SIZE-16
        Sti

        Mov     ax, [cs:ptrMemory]      ;�᢮�������� ��१�ࢨ஢����� ����� ��� ����᪠ ��⨢����
        Mov     es, ax
        ;Mov    ah, 49h
        ;Int    21h
        Call    FreeUMB

        Call    KeepDisplay             ;��࠭���� ��࠭�

        Push    cs
        Pop     ds
        Mov     ah, 9h
        Mov     dx, OFFSET cs:@@msgStartAV
        Pushf
        Call    [cs:Old21h]
        Mov     dx, OFFSET cs:@@strCom1
        Pushf
        Call    [cs:Old21h]
        Mov     dx, OFFSET cs:@@msgStartAVd
        Pushf
        Call    [cs:Old21h]

        Mov     ax, 5802h               ;��࠭���� ⥪�饩 �裡 UMB
        Pushf
        Call    [cs:Old21h]
        Mov     [cs:@@oldLink], al
        Mov     ax, 5803h               ;��⠭���� �裡 � UMB
        Mov     bx, 1
        Pushf
        Call    [cs:Old21h]

        Mov     ax, 4B00h               ;DOS Exec
        Push    cs cs
        Pop     ds es
        Mov     dx, OFFSET MyCode:@@strCom1
        Mov     bx, OFFSET MyCode:paramsBlc
        Pushf
        Call    [cs:Old21h]
        Lahf

        Mov     bx, cs                  ;����⠭������� �⥪� �� ᢮�
        Cli
        Mov     ss, bx
        Mov     sp, OFFSET MyCode:myStk
        Add     sp, STK_SIZE-16
        Sti

        Sahf
        Jnc     @@memRestore
        Push    cs
        Pop     ds
        Mov     ah, 9h
        Mov     dx, OFFSET cs:@@msgErrAVStart
        Pushf
        Call    [cs:Old21h]
        Mov     di, ERR_RATE
        Mov     bx, ERR_DEL
        Call    Beep

@@memRestore:
        Call    RestoreDisplay  ;����⠭������� ��࠭�

        Mov     ax, 5803h         ;����⠭������� ���ﭨ� �裡 � UMB
        Xor     bx, bx
        Mov     bl, [cs:@@oldLink]
        Pushf
        Call    [cs:Old21h]

        ;Mov    ah, 48h         ;१�ࢨ஢���� �᢮����񭭮� ��⨢���ᮬ �����
        Mov     bx, MEM_SIZE
        ;Int    21h
        Call    AllocateUMB
        Jc      @@noMem
        Mov     [cs:ptrMemory], ax
        Jmp     SHORT @@ent1
@@noMem:
        Mov     [cs:ptrMemory], 0

@@ent1:
        Cli                         ;����⠭������� �⥪�
        Mov     ss, [cs:@@OldSS]
        Mov     sp, [cs:@@OldSP]
        Sti

        Mov     ax, 5000h             ;����⠭������� ⥪�饣� PSP
        Mov     bx, [cs:@@oldPSP]
        Pushf
        Call    [cs:Old21h]

        Mov     ax, 5D0Ah
        Xor     bx, bx
        Push    cs
        Pop     ds
        Mov     dx, OFFSET MyCode:@@oldExtErr
        Pushf
        Call    [cs:Old21h]

        Ret

@@OldSS   DW ?
@@OldSP   DW ?
@@oldPSP  DW ?
@@oldLink DB ?

@@oldExtErr DW 3 Dup(?)

@@strCom1       DB STRPATH_AV1, 0, '$'
;@@cmdLine       DB 15, ' a:\ /q/f/g/s/n', 0Dh
@@cmdLine       DB 4,' a:\', 0Dh

@@msgStartAV    DB 10,13, '����� ��⨢����  $'
@@msgStartAVd   DB '  ��� ���ன�⢠ '
LABEL @@device BYTE
                DB 'A:', 10,13,10,'$'
@@msgErrAVStart DB 10,13,'�訡�� ����᪠ ��⨢����$'

@@fcb1    FCB <>
@@fcb2    FCB <>

paramsBlc    ParsTyp <, OFFSET MyCode:@@cmdLine,, OFFSET MyCode:@@fcb1,, OFFSET MyCode:@@fcb2,>


ENDP ExecAntivirus



PROC  Unload           ;����⠭�������� ����� ���뢠��� ��אַ� ������� � ⠡���� � �᢮������� ������ ��אַ� ����䨪�樥� MCB.

        Mov     al, 2Fh          ;� ��砫� ��� ������� ����� �஢�ઠ �� ��ॣ�㧪� ����� �������� �ணࠬ���� - �᫨ ���� ���� ����� ���墠祭, � ���㦠���� �����.
        Mov     dx, OFFSET New2Fh
        Call    Test_Vector
        Jnz     @@cant_unload

        Mov     al, 9h
        Mov     dx, OFFSET New9h
        Call    Test_Vector
        Jnz     @@cant_unload

        Mov     al, 13h
        Mov     dx, OFFSET New13h
        Call    Test_Vector
        Jnz     @@cant_unload

        Mov     al, 21h
        Mov     dx, OFFSET New21h
        Call    Test_Vector
        Jnz     @@cant_unload

        Mov     al, 25h
        Mov     dx, OFFSET New25h
        Call    Test_Vector
        Jnz     @@cant_unload

        Lds     dx, [cs:Old2Fh]    ;����⠭������� ����஢
        Mov     al, 2Fh
        Call    RestoreVector

        Lds     dx, [cs:Old9h]
        Mov     al, 9h
        Call    RestoreVector

        Lds     dx, [cs:Old13h]
        Mov     al, 13h
        Call    RestoreVector

        Lds     dx, [cs:Old21h]
        Mov     al, 21h
        Call    RestoreVector

        Lds     dx, [cs:Old25h]
        Mov     al, 25h
        Call    RestoreVector

        Mov     bx, cs
        Dec     bx
        Mov     ds, bx
        Xor     bx, bx
        Mov     [word ptr (MCB bx).ownerPSP], 0  ;�᢮�������� �����

        Mov     bx, [cs:2Ch] ;ᥣ���� Env
        Dec     bx
        Mov     ds, bx
        Xor     bx, bx
        Mov     [word ptr (MCB bx).ownerPSP], 0  ;�᢮�������� ����� ����� Enviroment

        Cmp     [cs:ptrMemory], 0
        Jz      @@NoMem

        Mov     bx, [cs:ptrMemory]
        Dec     bx
        Mov     ds, bx
        Xor     bx, bx
        Mov     [word ptr (MCB bx).ownerPSP], 0 ;�᢮�������� ��१�ࢨ஢����� �����

@@NoMem:
        Push    cs
        Pop     ds
        Mov     si, OFFSET unlSound
        Call    Play

        Ret

@@cant_unload:
        Mov     di, ERR_RATE
        Mov     bx, ERR_DEL
        Call    Beep

        Ret

unlSound  DW  100,100, 200,100, 500,50, 900,20, 0,0

ENDP  Unload

PROC  RestoreVector  near

        Xor     ah, ah
        Shl     ax, 2
        Mov     bx, ax
        Xor     ax, ax
        Mov     es, ax
        Cli
        Mov     [es:bx], dx
        Mov     dx, ds
        Mov     [es:bx+2], dx
        Sti

        Ret

ENDP  RestoreVector


PROC Test_Vector near   ; al - vector, dx - offset my proc

        Xor     ah, ah
        Shl     ax, 2
        Mov     bx, ax
        Xor     ax, ax
        Mov     es, ax
        Cli
        Cmp     dx, [es:bx]
        Jnz     @@bad_vector
        Mov     dx, cs
        Cmp     dx, [es:bx+2]
@@bad_vector:

        Sti
        Ret

ENDP Test_Vector


ENDS  Code0


Segment  StkSeg  para public 'Code'
        myStk      DB  STK_SIZE  Dup('Stack')
ENDS StkSeg

Segment  Code2  word public 'Code'

ENDS  Code2


Segment  Code1  word public 'Code'

install:

        Call    TestCPU             ;�஢�ઠ ⨯� ������
        Or      dx, dx
        Jnz     cpu_ok
        Mov     ah, 9h
        Mov     dx, OFFSET msgBadCPU
        Int     21h
        Int     20h

cpu_ok:

if PRODUCT GT 0
        Call    TestVirus       ;�஢�ઠ ����஫쭮� �㬬�
endif

        Push    cs cs           ;�஢�ઠ ��ࠬ��஢ ��������� ��ப�
        Pop     es ds
        Mov     ax, cs
        Mov     [word ptr myPSPPtr+2], ax

        Lds     bx, [cs:myPSPPtr]
        Cmp     [(PSP bx).pSize], 0
        Jz      enter00
        Cmp     [(PSP bx).pSize], 3
        Jz      get_param
bad_param:
        Mov     ah, 9h
        Mov     dx, OFFSET msgBadParam
        Int     21h
        Int     20h

get_param:
        Cmp     [(PSP bx+2).parm], '?'
        Jz      helpOut
        Cmp     [(PSP bx+2).parm], 'H'
        Jz      helpOut
        Cmp     [(PSP bx+2).parm], 'h'
        Jz      helpOut
        Jmp     SHORT bad_param
helpOut:
        Mov     ah, 9h
        Mov     dx, OFFSET titl
        Int     21h
        Int     20h


enter00:
        Mov     ax, ASK_CODE       ;�஢�ઠ ����୮� ����㧪�
        Int     2Fh
        Mov     di, OFFSET cs:pass
        Mov     cx, LEN00
        Cld
        REPZ Cmpsb
        Jz      already


        Cli                             ;��४��祭�� �⥪� �� ᢮�
        Mov     ax, cs
        Mov     ss, ax
        Mov     sp, OFFSET MyCode:myStk
        Add     sp, STK_SIZE-16
        Sti

        Call    initDrivers               ;���樠������ ������� ������
                            ;Free_Env
        Mov     ax, [cs:2Ch]
        Mov     [cs:paramsBlc.parsSeg], ax
        Mov     [cs:paramsBlc.cmdLinPtrS], cs
        Mov     [cs:paramsBlc.FCB1S], cs
        Mov     [cs:paramsBlc.FCB2S], cs

        ReDirectVector  2Fh              ;���墠� ����஢
        ReDirectVector  9h
        ReDirectVector  13h
        ReDirectVector  21h
        ReDirectVector  25h
        GetCritFlag     dosActive

        Call    TimerInit              ;���樠������ ��楤��� ���� ��모
        Push    cs
        Pop     ds
        Mov     ah, 9h
        Mov     dx, OFFSET titl
        Int     21h


        Mov     ah, 4Ah                     ;㬥��襭�� �ணࠬ����� ����� �����
        Mov     bx, OFFSET MyCode:end_start
        Shr     bx, 4
        Inc     bx
        Push    cs
        Pop     es
        Int     21h

        ;Mov    ah, 48h                  ;१�ࢨ஢���� ����� ��� ��⨢����
        Mov     bx, MEM_SIZE
        ;Int    21h
        Call    AllocateUMB
        Jc      noMemory
        Mov     [cs:ptrMemory], ax
        Jmp     SHORT ent1

noMemory:
        Mov     ah, 9h
        Mov     dx, OFFSET msgNoMem
        Int     21h
        Mov     di, ERR_RATE
        Mov     bx, ERR_DEL
        Call    Beep
        Int     20h

ent1:
        Push    cs                  ;�뢮� ���⠢�� � ࠧ�襭�� ࠡ��� ��ࠡ��稪�� ���뢠���
        Pop     es
        Mov     ah, 9h
        Mov     dx, OFFSET msgInst
        Int     21h

        Mov     [cs:enblStart], 1
        Mov     [cs:enblGo], 1
        Mov     dx, OFFSET install
        Int     27h


already:
        Push    cs cs
        Pop     ds es

        Mov     ah, 9h
        Mov     dx, OFFSET msgInst2
        Int     21h
        Mov     di, ERR_RATE
        Mov     bx, ERR_DEL
        Call    Beep

        Int     20h


initDrivers:
        Mov     cx, NUMB_DRIVERS
        Mov     si, OFFSET MyCode:drivers
        Mov     bl, 1

loopDrivers:
        Mov     ax, 4408h
        Int     21h
        Jc      driveAbsent
        Mov     [cs:si], al
        Jmp     SHORT loopCont

driveAbsent:
        Mov     [byte ptr cs:si], 2

loopCont:
        Inc     bl
        Inc     si
        Loop    loopDrivers

        Ret


myPSPPtr    PSP_PTR  0:?
msgBadParam DB 10,13,"�訡��� ��ࠬ����, �ᯮ���� /? ��� �ࠢ��",10,13,'$'
msgBadCPU   DB 10,13,"��� ࠡ��� �⮩ �ணࠬ�� ����室�� 286-�� ������ ��� ����",10,13,7,'$'


titl  DB  10,13
      DB     "���� (c)StasCorp. ������������������������ Flop virus test V[1.0 beta] �ͻ",10,13
      DB     "� All Rights Reserved                                    for free use    �",10,13
      DB     "�                                                                        �",10,13
      DB     "�               ��⮬���᪮� ���஢���� ������ ��᪮�                �",10,13
      DB     "�                    �� ������ ���⥫� � ��᪮����                     �",10,13
      DB     "�                                                                        �",10,13
      DB     "�                     (c) ����ᥩ ��஢ 1995-96 �.                     �",10,13
      DB     "�                                                                        �",10,13
      DB     "��� ����稥 ������ ����������������������������������������������������Ķ",10,13
      DB     "�  Ctrl + Alt � �� ��஭�  +:                                        �",10,13
      DB     "�                                                                        �",10,13
      DB     "�    U                  - ���㧪� �ணࠬ�� �� �����.                  �",10,13
      DB     "������������������������������������������������������������������������Ķ",10,13
      DB     "� ���. 146-7724, ���� ***-****, BBS ***-**** (**-** MSK), FIDO *:****/** �",10,13
      DB     "������������������������������������������������������������������������ͼ",10,13,'$'

msgInst      DB     "   �ணࠬ�� ���⠫�஢��� � �����...",10,13,'$'
msgInst2     DB     "   �ணࠬ�� 㦥 ���⠫�஢��� � �����...",10,13,'$'
msgNoMem     DB     "���� ����� ��� �ᯮ�짮����� ��⨢����",10,13,'$'

ENDS  Code1

Segment  Code3  word public 'Code'
ENDS  Code3

Segment  Code4  word public 'Code'

File_length     DD              23832
File_CRC        DD              8BC6ABACh
end_start:

ENDS  Code4

        END

