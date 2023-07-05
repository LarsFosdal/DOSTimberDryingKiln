{$I CodeDefs.pas}
{ $O-}

UNIT Icons;
INTERFACE

TYPE
  ExtPicture = PROCEDURE;

PROCEDURE ECPutBlock(x,y:Integer; Picture:ExtPicture; m:Integer);

PROCEDURE HD3Icon;
PROCEDURE FD3Icon;
PROCEDURE Tlf1Icon;
PROCEDURE AlfOgGunAS;
PROCEDURE AGlogo1;
PROCEDURE ABB_Logo;

IMPLEMENTATION
USES
  LFGraph,LFImplod;

TYPE
  FixupRec = RECORD
    JmpIns : Byte; { $CD:Overlay not loaded  $EA:Overlay is loaded }
    JmpLoc : Pointer;
  END; {REC FixupRec}

PROCEDURE ECPutBlock(x,y:Integer; Picture:ExtPicture; m:Integer);
{ - Shell around PutBlock for External Compressed .OBJ pictures}
VAR
  Fixup           : ^FixupRec;
  p,s    : Pointer;
  ps,ss,n  : Word;
BEGIN
  n:=0;
  REPEAT
    Picture;
    FixUp:=@Picture;
    p:=Fixup^.JmpLoc;
    Inc(n);
  UNTIL (Fixup^.JmpIns=$EA) or (n>10);
  IF n>10 THEN p:=@Picture;
  Explode(p^,s,ss);
  IF ss<>0
  THEN BEGIN
    PutBlock(x,y,s^,m);
    FreeMem(s,ss);
  END;
END;{PROC ECPutBlock}

{$L HD3Icon}
PROCEDURE HD3Icon; External;

{$L FD3Icon}
PROCEDURE FD3Icon; External;

{$L A&G-AS}
PROCEDURE AlfOgGunAS; External;

{$L AGLOGO1}
PROCEDURE AGlogo1; External;

{$L TLF1ICON}
PROCEDURE Tlf1Icon; External;

{$L ABB_LOGO}
PROCEDURE ABB_Logo; External;

END.