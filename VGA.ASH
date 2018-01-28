
IDEAL

ENUM              SVGAMODES           \
                    _640x400x256=256, \
                    _640x480x256, \
                    _800x600x16, \
                    _800x600x256, \
                    _1024x768x16, \
                    _1024x768x256, \
                    _1280x1024x16, \
                    _1280x1024x256, \
                    _80x60, \
                    _132x25, \
                    _132x43, \
                    _132x50, \
                    _132x60, \
                    DCLEAR=0, \
                    DONTCLEAR, \
                    pad$0=256


ENUM              VGAMODES            \
                    _40x25x16, \
                    _40x25x16_, \
                    _80x25x16, \
                    _80x25x16_, \
                    _320x200x4, \
                    _320x200x4_, \
                    _640x200x2, \
                    _80x25xmono, \
                    _EGA1=11, \
                    _EGA2, \
                    _320x200x16, \
                    _640x200x16, \
                    _640x350xmono, \
                    _640x350x16, \
                    _640x480xmono, \
                    _640x480x16, \
                    _320x200x256, \
                    pad$1=256


STRUC              tag$0               
width               DW      ?
height              DW      ?
cwidth              DB      ?
cheight             DB      ?
numb_mem_planes     DB      ?
numb_bits_per_pixel DB      ?
numb_banks          DB      ?
mem_model           DB      ?
size_bank_k         DB      ?

ENDS              tag$0               

TYPEDEF              OEMMODES            tag$0

STRUC              tag$1               
mode_attr           DW      ?
wA_attr             DB      ?
wB_attr             DB      ?
wgK                 DW      ?
wind_sizeK          DW      ?
segmA               DW      ?
segmB               DW      ?
pos_func            DD      ?
bytes_scan_lin      DW      ?
OEMmoes             tag$0   <>
reserv              DB      240 DUP ( ? )

ENDS              tag$1               

TYPEDEF              MODETBL             tag$1

STRUC              tag$3               
supportModes        DB      3 DUP ( ? )
reserv              DB      3 DUP ( ? )
rstrLine            DB      ?
numbCharTbl         DB      ?
maxUsesTbl          DB      ?
miscellaneous1      DB      ?
miscellaneous2      DB      ?
statusPtr           DB      ?

ENDS              tag$3               

TYPEDEF              FUNCTBL             tag$3

STRUC              tag$4               
funcTbl             DD      ?;FAR PTR
mode                DB      ?
width               DW      ?
videoPageLen        DW      ?
offsetCurPage       DW      ?
curs                DW      8 DUP ( ? )
cursUp              DB      ?
cursDown            DB      ?
actPage             DB      ?
portAdr             DW      ?
_3x8h               DB      ?
_3x9h               DB      ?
length              DB      ?
highChar            DW      ?
adapt1              DB      ?
adapt2              DB      ?
numbColors          DW      ?
numbPages           DB      ?
numbLineScan        DB      ?
nambCharTbl1        DB      ?
nambCharTbl2        DB      ?
miscellaneous       DB      ?
res                 DB      3 DUP ( ? )
videoMemLen         DB      ?
statusPtr           DB      ?
reserved            DB      13 DUP ( ? )

ENDS              tag$4               

TYPEDEF              VGAINFO             tag$4

STRUC              tag$5               
equipmentFl         DB      ?
reserv1             DB      56 DUP ( ? )
mode                DB      ?
width               DW      ?
lenPage             DW      ?
actPageAdr          DW      ?
cursCoords          DW      8 DUP ( ? )
cursSta             DB      ?
cursEnd             DB      ?
actPage             DB      ?
_3x4                DW      ?
_3x8                DB      ?
_3x9                DB      ?
reserv2             DB      29 DUP ( ? )
length              DB      ?
charHeight          DW      ?
egaInfo1            DB      ?
egaInfo2            DB      ?
reserv3             DB      31 DUP ( ? )
environPtr          DD       ?;FAR PTR

ENDS              tag$5

TYPEDEF              VIDEOBIOS           tag$5

