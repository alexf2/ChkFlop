Ideal

include 'dossys.ash'
include 'tsrid.inc'



P386
Model use16 tiny
SmallStack
Locals

            ASK_CODE    EQU   00FF07h   ;код запроса для проверки присутствия программы в памяти
            _u_         EQU       16h

            ERR_RATE    EQU      800   ;параметры звукового сигнала ошибки
            ERR_DEL     EQU      200   ;

            STK_SIZE    EQU      1024*2  ;bytes - размер собственного статического стека
            MEM_SIZE    EQU      3520    ;para = 200kB 12800 - размер резервируемого при инициализации блока памяти для запуска антивируса
                                         ;300kB 19200
            STRPATH_AV1 EQU      'D:\AIDS\anti-dir.exe'

typedef PSP_PTR far ptr PSP ;указатель на префикс программного сегмента

STRUC ParsTyp          ;блок данных для функции DOS Exec

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
; Программа сделана в модели tiny и поэтому состоит всего из одного сегмента
; кода. Сегменты компануются в один в порядке их описания в файле chkflop.asm.
; Чтобы внутри каждого сегмента использовать смещения от начала получившегося
; единого сегмента, они объединены в группу. Для первого сегмента задано смещение
; его начала Org 100h - это оставлено место для PSP. Когда программа становится
; резидентной, то в памяти остётся часть кода от начала файла до метки install
; - сегменты Code0, Code2 и StkSeg. Остальные сегменты содержат инициализирующий
; код и отбрасываются, так как описаны после метки install.

        EXTRN  TestCPU        :PROC
        EXTRN  TestVirus      :PROC
        EXTRN  Beep           :PROC
        EXTRN  TimerInit      :PROC
        EXTRN  Play           :PROC
        EXTRN  KeepDisplay    :PROC
        EXTRN  RestoreDisplay :PROC
        EXTRN  AllocateUMB    :PROC
        EXTRN  FreeUMB        :PROC

        PUBLIC  File_length, File_CRC  ;длина и контрольная сумма файла
        PUBLIC  start, end_start       ;метки начала и конца кода

Segment  Code0  para public 'Code'
Assume   cs:MyCode, ds:MyCode

        Org 100h

start:
StartUpCode

        Jmp     install

enblStart       DB              0      ;семафор обработчика Int9 - используется для блокировки от повторного вхождения в собственный обработчик
enblGo          DB              0      ;флаг завершения инициализации резидента - устанавливается в 1 после её завершения и разрешает работу собственных обработчиков прерываний
NUMB_DRIVERS    EQU     26
drivers         DB NUMB_DRIVERS Dup(?) ;массив типов устройств - не исп.
ptrMemory       DW 0                   ;сегмент блока резервируемой при инициализации памяти для запуска антивируса
mountFlag       DB 0                   ;флаг замены диска
avirActive      DB 0                   ;семафор блокирующий работу собственных обработчиков прерывания во время работы антивируса
dosActive       DD ?                   ;адрес флага активности DOS


PROC  New2Fh  far                ;Обработчик мультиплексорного прерывания
                                 ;служит для проверки наличия этой программы
                                 ;в памяти с целью исключения повторной загрузки.
        Pushf
        Cmp     ax, ASK_CODE     ;При инициализации вызывается Int2F с условным
        Jnz     @@exit_          ;кодом в AX, и если программа уже инсталирована,
                                 ;то в DS:SI возвращается адрес ключевой строки.
        Mov     si, OFFSET cs:pass
        Mov     ax, cs
        Mov     ds, ax
        Popf
        Iret

@@exit_:
        Popf
        Jmp     [cs:Old2Fh]      ;переход на старый обработчик Int2F

STA00  =  $
pass      DB  "FlopVT 1.0"
LEN00  =  $-STA00
Old2Fh    DD  ?                  ;адрес старого обработчика

ENDP New2Fh

PROC  New25h                      ;Прямое чтение сектора используется для запуска
                                  ;антивируса в случае обращения к заменённому диску.
        Cmp     [cs:enblGo], 0    ;После вызова старого обработчика анализируется флаг замены диска
        Jz      @@leave           ;устанавливаемый в обработчике Int13h и если он 1 и DOS не активна, то запускается антивирус.
        Cmp     [cs:avirActive], 0
        Jz      @@enter
@@leave:
        Jmp     [cs:Old25h]       ;переход на старый обработчик

@@enter:
        Call    [cs:Old25h]       ;вызов старого обработчика (Pushf не надо - Int25h не извлекает флаги из стека).

        Pushf
        Cmp     [cs:mountFlag], 0 ;проверка смены диска
        Jz      @@ex

        PushAll
        Lds     bx, [cs:dosActive] ;проверка активности DOS
        Cmp     [byte ptr bx], 0
        Jnz     @@dosAct

        Mov     [cs:avirActive], 1 ;блокировка повторного вхождения в собственные обработчики
        Call    ExecAntivirus      ;запуск антивируса
        Mov     [cs:mountFlag], 0
        Mov     [cs:avirActive], 0
@@dosAct:
        PopAll

@@ex:
        Popf
        Ret     2                  ;возврат из прерывания без изменения флагов установленных старым обработчиком

Old25h    DD  ?

ENDP New25h


PROC  New9h far                      ;Проверяет нажатие Ctrl+Alt+U и если комбинация нажата выгружает программу

        Cmp     [cs:avirActive], 0
        Jnz     @@leave
        Cmp     [cs:enblStart], 0
        Jz      @@leave

        Push    es ax
        Mov     [cs:enblStart], 0

        Xor     ax, ax
        Mov     es, ax
        Mov     al, [es:0417h]     ;Чтение байта состояния клавиатуры из BIOS
        And     al, 00001111b      ; Ctrl+Alt
        Cmp     al, 00001100b
        Jnz     @@old_inter_pop

        In      al, 60h            ;чтение скан-кода нажатой клавиши
        Cmp     al, _u_
        Jz      @@unload


@@old_inter_pop:
        Pop     ax es

@@old_inter:
        Mov     [cs:enblStart], 1
@@leave:
        Jmp     [cs:Old9h]        ;переход на след. обработчик

@@return:
        Pop     ax es
        Mov     [cs:enblStart], 1
        Iret


@@unload:
        Call    near ptr @@inter_end ;если Ctrl+Alt+U, то аппаратное прерывание от клавиатуры обрабатывается без вызова старого обработчика, что делает это нажатие клавиши незаметным для других программ
        PushAll
        Call    Unload               ;выгрузка программы
        PopAll
        Jmp     SHORT @@return


@@inter_end:
        Push    ax
        Cli
        In      al, 61h       ;разблакировка клавиатуры и завершение обработки прерывания в контроллере прерываний
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

PROC  New21h far                    ;Используется для запуска антивируса в случае замены дмска.
                                    ;Флаг замены проверяется после вызова старого обработчика и
        Cmp     [cs:enblGo], 0      ;если надо запускается антивирус так как DOS находится в реентерабельном состоянии.
        Jz      @@leave             ;
        Cmp     [cs:avirActive], 0  ;
        Jz      @@enter             ;
@@leave:
        Jmp     [cs:Old21h]

@@enter:
        Pushf
        Call    [cs:Old21h]        ;вызов старого обработчика (Pushf нужен для эммуляции Int21h)

        Pushf
        Cmp     [cs:mountFlag], 0  ;проверка смены диска
        Jz      @@ex

        PushAll
        Mov     [cs:avirActive], 1
        Call    ExecAntivirus      ;запуск антивируса
        Mov     [cs:mountFlag], 0
        Mov     [cs:avirActive], 0
        PopAll

@@ex:
        Popf
        Ret     2                  ;возврат из прерывания без изменения флагов

Old21h        DD  ?

ENDP New21h


PROC  New13h  far                  ;Используется для проверки смены диска - dl всегда содержит адрес устройства, где 0, 1.. - сменные, а 80h, 81h.. - несменные.

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
        Pushf                            ;нужно для эммуляции Int13h
        Call    [dword ptr cs:Old13h]    ;вызов старого Int13h для проверки смены диска dl
        Cmp     ah, 6
        Jnz     @@noMount

        Add     dl, 'A'                  ;вычисляем букву устройства
        Mov     [cs:mountFlag], dl


@@noMount:
        PopAll
@@ex:
        Jmp     [dword ptr cs:Old13h]

Old13h    DD  ?
;int13Led  DB  0

ENDP New13h

PROC ExecAntivirus near                ;Освобождает зарезервированный блок памяти, переключается стек на свой, и запускает антивирус функцией Exec.

        Cmp     [cs:ptrMemory], 0      ;Так как память освобождается перед запуском антивируса и резервируется после его завершения, то нужна проверка на успех её выделения.
        Jnz     @@Ok
        Ret

@@Ok:
        Mov     dl, [cs:mountFlag]
        Mov     [cs:@@cmdLine+2], dl   ;Запись устройства в строку параметров.
        Mov     [cs:@@device], dl

        Mov     ax, 5900h                      ;сохранение информации об ошибке
        Xor     bx, bx
        Pushf
        Call    [cs:Old21h]
        Mov     [cs:@@oldExtErr], ax
        Mov     [cs:@@oldExtErr+2], bx
        Mov     [cs:@@oldExtErr+4], cx

        Mov     ax, 6200h                ;сохранение текущего PSP
        Pushf
        Call    [cs:Old21h]
        Mov     [cs:@@oldPSP], bx
        Mov     ax, 5000h              ;переключение на свой PSP
        Mov     bx, cs
        Pushf
        Call    [cs:Old21h]

        Mov     [cs:@@OldSS], ss       ;сохранение стека
        Mov     [cs:@@OldSP], sp
        Mov     ax, cs
        Cli
        Mov     ss, ax
        Mov     sp, OFFSET MyCode:myStk ;переключение на свой стек
        Add     sp, STK_SIZE-16
        Sti

        Mov     ax, [cs:ptrMemory]      ;освобождение зарезервированной памяти для запуска антивируса
        Mov     es, ax
        ;Mov    ah, 49h
        ;Int    21h
        Call    FreeUMB

        Call    KeepDisplay             ;сохранение экрана

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

        Mov     ax, 5802h               ;сохранение текущей связи UMB
        Pushf
        Call    [cs:Old21h]
        Mov     [cs:@@oldLink], al
        Mov     ax, 5803h               ;установка связи с UMB
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

        Mov     bx, cs                  ;восстановление стека на свой
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
        Call    RestoreDisplay  ;восстановление экрана

        Mov     ax, 5803h         ;восстановление состояния связи с UMB
        Xor     bx, bx
        Mov     bl, [cs:@@oldLink]
        Pushf
        Call    [cs:Old21h]

        ;Mov    ah, 48h         ;резервирование освобождённой антивирусом памяти
        Mov     bx, MEM_SIZE
        ;Int    21h
        Call    AllocateUMB
        Jc      @@noMem
        Mov     [cs:ptrMemory], ax
        Jmp     SHORT @@ent1
@@noMem:
        Mov     [cs:ptrMemory], 0

@@ent1:
        Cli                         ;восстановление стека
        Mov     ss, [cs:@@OldSS]
        Mov     sp, [cs:@@OldSP]
        Sti

        Mov     ax, 5000h             ;восстановление текущего PSP
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

@@msgStartAV    DB 10,13, 'Запуск антивируса  $'
@@msgStartAVd   DB '  для устройства '
LABEL @@device BYTE
                DB 'A:', 10,13,10,'$'
@@msgErrAVStart DB 10,13,'Ошибка запуска антивируса$'

@@fcb1    FCB <>
@@fcb2    FCB <>

paramsBlc    ParsTyp <, OFFSET MyCode:@@cmdLine,, OFFSET MyCode:@@fcb1,, OFFSET MyCode:@@fcb2,>


ENDP ExecAntivirus



PROC  Unload           ;Восстанавливает вектора прерываний прямой записью в таблицу и освобождает память прямой модификацией MCB.

        Mov     al, 2Fh          ;В начале для каждого вектора проверка на перегрузку более поздними программами - если хотябы один вектор перехвачен, то выгружаться нельзя.
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

        Lds     dx, [cs:Old2Fh]    ;восстановление векторов
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
        Mov     [word ptr (MCB bx).ownerPSP], 0  ;освобождение памяти

        Mov     bx, [cs:2Ch] ;сегмент Env
        Dec     bx
        Mov     ds, bx
        Xor     bx, bx
        Mov     [word ptr (MCB bx).ownerPSP], 0  ;освобождение памяти блока Enviroment

        Cmp     [cs:ptrMemory], 0
        Jz      @@NoMem

        Mov     bx, [cs:ptrMemory]
        Dec     bx
        Mov     ds, bx
        Xor     bx, bx
        Mov     [word ptr (MCB bx).ownerPSP], 0 ;освобождение зарезервированной памяти

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

        Call    TestCPU             ;проверка типа процессора
        Or      dx, dx
        Jnz     cpu_ok
        Mov     ah, 9h
        Mov     dx, OFFSET msgBadCPU
        Int     21h
        Int     20h

cpu_ok:

if PRODUCT GT 0
        Call    TestVirus       ;проверка контрольной суммы
endif

        Push    cs cs           ;проверка параметров командной строки
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
        Mov     ax, ASK_CODE       ;проверка повторной загрузки
        Int     2Fh
        Mov     di, OFFSET cs:pass
        Mov     cx, LEN00
        Cld
        REPZ Cmpsb
        Jz      already


        Cli                             ;переключение стека на свой
        Mov     ax, cs
        Mov     ss, ax
        Mov     sp, OFFSET MyCode:myStk
        Add     sp, STK_SIZE-16
        Sti

        Call    initDrivers               ;инициализация структур данных
                            ;Free_Env
        Mov     ax, [cs:2Ch]
        Mov     [cs:paramsBlc.parsSeg], ax
        Mov     [cs:paramsBlc.cmdLinPtrS], cs
        Mov     [cs:paramsBlc.FCB1S], cs
        Mov     [cs:paramsBlc.FCB2S], cs

        ReDirectVector  2Fh              ;перехват векторов
        ReDirectVector  9h
        ReDirectVector  13h
        ReDirectVector  21h
        ReDirectVector  25h
        GetCritFlag     dosActive

        Call    TimerInit              ;инициализация процедуры игры музыки
        Push    cs
        Pop     ds
        Mov     ah, 9h
        Mov     dx, OFFSET titl
        Int     21h


        Mov     ah, 4Ah                     ;уменьшение программного блока памяти
        Mov     bx, OFFSET MyCode:end_start
        Shr     bx, 4
        Inc     bx
        Push    cs
        Pop     es
        Int     21h

        ;Mov    ah, 48h                  ;резервирование памяти для антивируса
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
        Push    cs                  ;вывод заставки и разрешение работы обработчиков прерывания
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
msgBadParam DB 10,13,"Ошибочные параметры, используйте /? для справки",10,13,'$'
msgBadCPU   DB 10,13,"Для работы зтой программы необходим 286-ой процессор или старше",10,13,7,'$'


titl  DB  10,13
      DB     "╔═══ (c)StasCorp. ════════════════════════ Flop virus test V[1.0 beta] ══╗",10,13
      DB     "║ All Rights Reserved                                    for free use    ║",10,13
      DB     "║                                                                        ║",10,13
      DB     "║               Автоматическое тестирование гибких дисков                ║",10,13
      DB     "║                    при замене носителя в дисководе                     ║",10,13
      DB     "║                                                                        ║",10,13
      DB     "║                     (c) Алексей Фёдоров 1995-96 г.                     ║",10,13
      DB     "║                                                                        ║",10,13
      DB     "╟── Горячие клавиши ─────────────────────────────────────────────────────╢",10,13
      DB     "║  Ctrl + Alt с любой стороны  +:                                        ║",10,13
      DB     "║                                                                        ║",10,13
      DB     "║    U                  - выгрузка программы из памяти.                  ║",10,13
      DB     "╟────────────────────────────────────────────────────────────────────────╢",10,13
      DB     "║ Тел. 146-7724, Факс ***-****, BBS ***-**** (**-** MSK), FIDO *:****/** ║",10,13
      DB     "╚════════════════════════════════════════════════════════════════════════╝",10,13,'$'

msgInst      DB     "   Программа инсталирована в памяти...",10,13,'$'
msgInst2     DB     "   Программа уже инсталирована в памяти...",10,13,'$'
msgNoMem     DB     "Мало памяти для использования антивируса",10,13,'$'

ENDS  Code1

Segment  Code3  word public 'Code'
ENDS  Code3

Segment  Code4  word public 'Code'

File_length     DD              23832
File_CRC        DD              8BC6ABACh
end_start:

ENDS  Code4

        END

