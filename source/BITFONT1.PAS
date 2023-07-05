{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT BitFont1;

INTERFACE

USES LFsystem;

CONST
  BitFont1Msg = ' LFbitFont1.1 (c) 890425 Lars Fosdal ';
  CharSetHeight : Byte = 16;
  DirectLoad : Boolean = True;
TYPE
(*

{--- New Format ? ---}
  CharDef = RECORD {Total 18 bytes}
              Width : Byte;
              { - msb:Proportional Width, lsb:Std.Width }
              Height: Byte;
              { - msb:First NonZero Byte, lsb:Last NonZero Byte}
              Bits  : ARRAY[1..16] OF Byte;
            END;
  FontDef = RECORD {Total 4632 bytes}
              Signature : Word;
              Name      : String[19];
              CRC       : Word;
              MaxWidth  : Word; {hmsb hlsb lmsb llsb}
              MaxHeight : Word; {hmsb hlsb lmsb llsb}
              Character : ARRAY[0..255] OF CharDef;
            END;

*)
  CharDef = ARRAY[1..16] OF Byte;
  FontSet = ARRAY[0..255] OF CharDef;
  BitFontProc = PROCEDURE;

PROCEDURE UploadFont(WhichSet:Word; FontPtr:Pointer);
PROCEDURE DownloadFont(WhichSet:Word; FontPtr:Pointer);
PROCEDURE UploadChar(WhichSet:Word; WhichChar:Char; CharPtr:Pointer);

PROCEDURE LoadRAMFont(FontBlock:Word; FontPtr:Pointer);
PROCEDURE LoadRAMFontMode(FontBlock:Byte; FontPtr:Pointer);
PROCEDURE LoadRAMChar(FontBlock:Word; ASCII:Char; aChar:CharDef);
PROCEDURE SetVisualFonts(NormalFontBlock,ExtendedFontBlock:Byte);

PROCEDURE FetchDiskFont(FontName:String; VAR Fnt:FontSet);
PROCEDURE StoreDiskFont(FontName:String; Fnt:Pointer);

PROCEDURE CP437EGAfont;
PROCEDURE CP437VGAfont;
PROCEDURE CP850EGAfont;
PROCEDURE CP850VGAfont;
PROCEDURE CP860EGAfont;
PROCEDURE CP860VGAfont;
PROCEDURE CP863EGAfont;
PROCEDURE CP863VGAfont;
PROCEDURE CP865EGAfont;
PROCEDURE CP865VGAfont;

IMPLEMENTATION

USES Dos;

CONST
  FontBase : ARRAY[0..7] OF Word =
    ($0000,$4000,$8000,$C000,$2000,$6000,$A000,$E000);

PROCEDURE UploadFont(WhichSet:Word; FontPtr:Pointer); ASSEMBLER;
{ - Upload a Font Into specified FontSet }
ASM
         push ds
         mov  bx,WhichSet
         mov  di,word ptr FontBase[bx+1]
         lds  si,FontPtr

         CLI
         MOV  DX,03C4h
         MOV  AX,0402h
         OUT  DX,AX
         MOV  AX,0704h
         OUT  DX,AX
         STI
         MOV  DL,0CEh
         MOV  AX,0204h
         OUT  DX,AX
         MOV  AX,0005h
         OUT  DX,AX
         MOV  AX,0006h
         OUT  DX,AX

         MOV  AX,0A000h
         MOV  ES,AX
         MOV  CX,0100h
@@NxtCh: PUSH CX
         MOV  CX,08h
@@NxtLn: MOVSW
         LOOP @@NxtLn
         ADD  DI,010h
         POP CX
         LOOP @@NxtCh

         CLI
         MOV  DX,03C4h
         MOV  AX,0302h
         OUT  DX,AX
         MOV  AX,0304h
         OUT  DX,AX
         STI
         MOV  DL,0CEh
         MOV  AX,0004h
         OUT  DX,AX
         MOV  AX,1005h
         OUT  DX,AX
         MOV  AX,0E06h
         OUT  DX,AX

         POP DS
END; {PROC UploadFont}

PROCEDURE DownloadFont(WhichSet:Word; FontPtr:Pointer); ASSEMBLER;
{ - Download a Font from specified FontSet }
ASM
         push ds
         mov  bx,WhichSet
         mov  si,word ptr FontBase[bx+1]
         les  di,FontPtr

         CLI
         MOV  DX,03C4h
         MOV  AX,0402h
         OUT  DX,AX
         MOV  AX,0704h
         OUT  DX,AX
         STI
         MOV  DL,0CEh
         MOV  AX,0204h
         OUT  DX,AX
         MOV  AX,0005h
         OUT  DX,AX
         MOV  AX,0006h
         OUT  DX,AX

         MOV  AX,0A000h
         MOV  DS,AX
         MOV  CX,0100h
@@NxtCh: PUSH CX
         MOV  CX,08h
@@NxtLn: MOVSW
         LOOP @@NxtLn
         ADD  SI,010h
         POP CX
         LOOP @@NxtCh

         CLI
         MOV  DX,03C4h
         MOV  AX,0302h
         OUT  DX,AX
         MOV  AX,0304h
         OUT  DX,AX
         STI
         MOV  DL,0CEh
         MOV  AX,0004h
         OUT  DX,AX
         MOV  AX,1005h
         OUT  DX,AX
         MOV  AX,0E06h
         OUT  DX,AX

         POP DS
END; {PROC DownloadFont}

PROCEDURE UploadChar(WhichSet:Word; WhichChar:Char; CharPtr:Pointer); ASSEMBLER;
{ - Load a char Into specified FontSet}
ASM
         PUSH DS
         MOV  BX,WhichSet
         MOV  DI,Word Ptr FontBase[bx+1]
         MOV  BL,WhichChar
         XOR  BH,BH
{$IFOPT G+}
         SHL  BX,5
{$ELSE}
         MOV  CL,5
         SHL  BX,CL
{$ENDIF}
         ADD  DI,BX
         LDS  SI,CharPtr
         CLI
         MOV  DX,03C4h
         MOV  AX,0402h
         OUT  DX,AX
         MOV  AX,0704h
         OUT  DX,AX
         STI
         MOV  DL,0CEh
         MOV  AX,0204h
         OUT  DX,AX
         MOV  AX,0005h
         OUT  DX,AX
         MOV  AX,0006h
         OUT  DX,AX

         MOV  AX,0A000h
         MOV  ES,AX
         MOV  CX,010h
         REP MOVSW

         CLI
         MOV  DX,03C4h
         MOV  AX,0302h
         OUT  DX,AX
         MOV  AX,0304h
         OUT  DX,AX
         STI
         MOV  DL,0CEh
         MOV  AX,0004h
         OUT  DX,AX
         MOV  AX,1005h
         OUT  DX,AX
         MOV  AX,0E06h
         OUT  DX,AX

         POP DS
END; {PROC LoadChar}

PROCEDURE LoadRAMFont(FontBlock:Word; FontPtr:Pointer);
VAR
  BIOS : Registers;
  Base : Word;
BEGIN
  IF DirectLoad THEN UploadFont(Base,FontPtr)
  ELSE WITH Bios
  DO BEGIN
    AX:=$1100;
    ES:=Seg(FontPtr^);
    BP:=Ofs(FontPtr^);
    CX:=256;
    DX:=0;
    BL:=FontBlock and $3;
    BH:=CharSetHeight;
    Intr($10,Bios);
  END;
END;{PROC LoadRAMFont}

PROCEDURE LoadRAMFontMode(FontBlock:Byte; FontPtr:Pointer);
VAR
  BIOS : Registers;
BEGIN
  WITH Bios DO BEGIN
    AX:=$1100;
    ES:=Seg(FontPtr^);
    BP:=Ofs(FontPtr^);
    CX:=256;
    DX:=0;
    BL:=FontBlock and $3;
    BH:=CharSetHeight;
    Intr($10,Bios);
  END;
END;{LoadRAMFontMode}

PROCEDURE LoadRAMChar(FontBlock:Word; ASCII:Char; aChar:CharDef);
VAR
  BIOS : Registers;
  Base : Word;
BEGIN
  IF DirectLoad
  THEN UploadChar(FontBlock,ASCII,@aChar)
  ELSE WITH Bios
  DO BEGIN
    AX:=$1100;
    ES:=Seg(aChar);
    BP:=Ofs(aChar);
    CX:=1;
    DX:=Byte(ASCII);
    BL:=FontBlock and $3;
    BH:=CharSetHeight;
    Intr($10,Bios);
  END;
END;{LoadRamChar}

PROCEDURE SetVisualFonts(NormalFontBlock,ExtendedFontBlock:Byte);
VAR
  Bios : Registers;
BEGIN
  Bios.AX:=$1103;
  Bios.BL:=((ExtendedFontBlock and $3) SHL 2)+(NormalFontBlock and $3);
  Intr($10,Bios);
END;{SetVisualFonts}

PROCEDURE FetchDiskFont(FontName:String; VAR Fnt:FontSet);
VAR
  f   : File of FontSet;
BEGIN
  Assign(f,FontName);
  Reset(f);
  Read(f,Fnt);
  Close(f);
END; {FetchDiskFont}

PROCEDURE StoreDiskFont(FontName:String; Fnt:Pointer);
VAR
  f : File of FontSet;
BEGIN
  Assign(f,FontName);
  Rewrite(f);
  Write(f,FontSet(Fnt^));
  Close(f);
END;

{$L CP437EGA} PROCEDURE CP437EGAfont; External;
{$L CP437VGA} PROCEDURE CP437VGAfont; External;
{$L CP850EGA} PROCEDURE CP850EGAfont; External;
{$L CP850VGA} PROCEDURE CP850VGAfont; External;
{$L CP860EGA} PROCEDURE CP860EGAfont; External;
{$L CP860VGA} PROCEDURE CP860VGAfont; External;
{$L CP863EGA} PROCEDURE CP863EGAfont; External;
{$L CP863VGA} PROCEDURE CP863VGAfont; External;
{$L CP865EGA} PROCEDURE CP865EGAfont; External;
{$L CP865VGA} PROCEDURE CP865VGAfont; External;

VAR
  PrevExitProc : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  Units.Leave(BitFont1Msg,MemAvail);
END;

BEGIN
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  Units.Enter(BitFont1Msg,MemAvail,CSeg);
END.
