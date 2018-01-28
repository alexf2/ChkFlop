


; top of file "dossys.ash"


IDEAL

STRUC              tag$00               
firstSymb           DB      ?
ownerPSP            DW      ?
blockSize           DW      ?
reserved            DB      11 DUP ( ? )

ENDS              tag$00               

TYPEDEF              MCB                 tag$00

STRUC              tag$01               
mcbSeg              DW      ?
devCb               DD      FAR PTR ?
fileTab             DD      FAR PTR ?
clockDr             DD      FAR PTR ?
conDr               DD      FAR PTR ?
maxBtbl             DW      ?
diskBuf             DD      FAR PTR ?
drvInfo             DD      FAR PTR ?
fcbTabl             DD      FAR PTR ?
fcbSize             DW      ?
numBdev             DB      ?
lastDriv            DB      ?

ENDS              tag$01               

TYPEDEF              CVT                 tag$01

STRUC              tag$02               
int20h              DB      2 DUP ( ? )
memTop              DW      ?
reserv1             DB      ?
callDsp             DB      5 DUP ( ? )
termAdr             DD      FAR PTR ?
cbrkAdr             DD      FAR PTR ?
critErr             DD      FAR PTR ?
parnPSP             DW      ?
fileTab             DB      20 DUP ( ? )
envSeg              DW      ?
ss_sp               DD      FAR PTR ?
maxOpen             DW      ?
fileTba             DD      FAR PTR ?
reserv2             DB      24 DUP ( ? )
disp                DB      3 DUP ( ? )
reserv3             DB      9 DUP ( ? )
fCB1                DB      16 DUP ( ? )
fCB2                DB      20 DUP ( ? )
pSize               DB      ?
parm                DB      127 DUP ( ? )

ENDS              tag$02               

TYPEDEF              PSP                 tag$02

STRUC              tag$03               
signeture           DW      ?
partPag             DW      ?
fileSize            DW      ?
relItem             DW      ?
hdrSize             DW      ?
minMem              DW      ?
maxMem              DW      ?
ss_Reg              DW      ?
sp_Reg              DW      ?
chkSumm             DW      ?
ip_Reg              DW      ?
csReg               DW      ?
reltOff             DW      ?
overlay             DW      ?

ENDS              tag$03               

TYPEDEF              EXE_HDR             tag$03

STRUC              tag$04               
offset_              DW      ?
segment_             DW      ?

ENDS              tag$04               

TYPEDEF              RELOC_TAB           tag$04


; end of file "dossys.ash"

