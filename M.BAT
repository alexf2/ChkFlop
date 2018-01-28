tasm /ml /m3 /q /dPRODUCT=1  chkflop.asm + cpu2.asm + sound.asm + test_v.asm + scr.asm + umb.asm
tlink /C /c /m /s /n /t  chkflop.obj cpu2.obj sound.obj  test_v.obj  scr.obj umb.obj
