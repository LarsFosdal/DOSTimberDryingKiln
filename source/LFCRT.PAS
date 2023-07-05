{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT LFcrt;

INTERFACE
USES Crt,LFsystem,LFWindow;
CONST
  LFCrtMsg = ' LFcrt.1 19890328 Lars Fosdal ';

TYPE
  str2    = String[2];
  str4    = String[4];
  str8    = String[8];
  str16   = String[16];
  str20   = String[20];
  Str80   = String[80];

  wConfig = (Fixed,Pull_Down,Pop_Up);
  aWindow = RECORD { the window definition }
              lx, uy, rx, ly, style, border, pane : byte;
              wType : wConfig;
              wSave : Boolean;
            END;

  PTxtCursor = ^TxtCursor;
  TxtCursor = OBJECT(GenericCursor)
    CONSTRUCTOR Init(AtX,AtY:Integer; OwnerWS:PWorkSpace);
    FUNCTION  AbsX:Integer;                VIRTUAL;
    FUNCTION  AbsY:Integer;                VIRTUAL;
    PROCEDURE MoveTo(NewX,NewY:Integer);   VIRTUAL;
    PROCEDURE ChangeState(NewState:CursorSize); VIRTUAL;
    PROCEDURE Hide;                        VIRTUAL;
    PROCEDURE Show;                        VIRTUAL;
  END; {OBJ TxtCursor}

  PTxtWS = ^TxtWorkSpace;
  TxtWorkSpace = OBJECT(GenericWorkspace)
    LastX,
    LastY     : Byte; {Last cursor position}
    TextLines : Integer; {Number of Actual Lines available in workspace }
    CC        : SingleColor; {Current Color}
    CONSTRUCTOR Init(x,y,w,h:Integer);
    CONSTRUCTOR InitTxt(x,y,Columns,Lines:Integer);
    DESTRUCTOR  Done;                              VIRTUAL;
    PROCEDURE   MoveTo(x,y:Integer);               VIRTUAL;
    PROCEDURE   SizeSet(w,h:Integer);              VIRTUAL;
    PROCEDURE   TxtAdjSize(Columns,Lines:Integer); VIRTUAL;
    PROCEDURE   TxtBar(x,y,w:Integer;cf:SingleColor); VIRTUAL;
    PROCEDURE   Open;                              VIRTUAL;
    PROCEDURE   Clear;                             VIRTUAL;
    PROCEDURE   ScrollUp(Lines:Integer);           VIRTUAL;
    PROCEDURE   ScrollDown(Lines:Integer);         VIRTUAL;
    PROCEDURE   Wrt(x,y:Integer; cf:SingleColor; Txt:String);      VIRTUAL;
    PROCEDURE   WrtTxt(x,y:Integer; cf:SingleColor; Txt:String);   VIRTUAL;
    PROCEDURE   Center(y:Integer; cf:SingleColor; Txt:String);     VIRTUAL;
    PROCEDURE   Ctr(y:Integer; cf:SingleColor; Txt:String);    VIRTUAL;
    PROCEDURE   Leave;                             VIRTUAL;
    PROCEDURE   Close;                             VIRTUAL;
  END; {OBJ TxtWorkspace}

  PTxtWin   = ^TxtWindow;
  TxtWindow = OBJECT(GenericWindow)
    WindowType,
    FrameType  : Byte;
    CONSTRUCTOR Init(x,y,w,h:Integer; BackGrSave:Boolean);
    CONSTRUCTOR InitTxt(x,y,Columns,Lines:Integer; BackGrSave:Boolean);
    DESTRUCTOR  Done;                              VIRTUAL;
    PROCEDURE   MoveTo(x,y:Integer);               VIRTUAL;
    PROCEDURE   SizeSet(w,h:Integer);              VIRTUAL;
    PROCEDURE   TxtAdjSize(Columns,Lines:Integer); VIRTUAL;
    PROCEDURE   InternalInit;                      VIRTUAL;
    PROCEDURE   Open;                              VIRTUAL;
    PROCEDURE   Frame;                             VIRTUAL;
    PROCEDURE   Clear;                             VIRTUAL;
    PROCEDURE   Leave;                             VIRTUAL;
    PROCEDURE   Close;                             VIRTUAL;
    FUNCTION    MemUsage:LongInt;                  VIRTUAL;
  END;{OBJ TxtWindow}

CONST
  NC       =-1;  {NC = No Change}
  PopUp    = 0;
  PullDown = 1;
  PullUp   = 2;
CONST
  StdTxtWin : DefWinColor = { Standard TextWin Colors }
    (Pane:  (Norm: LightGray shl 4 + White;
             High: LightGray shl 4 + Yellow;
             Low : LightGray shl 4 + Black);
     Frame: (Norm: LightGray shl 4 + DarkGray;
             High: LightGray shl 4 + White;
             Low : LightGray shl 4 + Black);
     Title: (Norm: Blue shl 4 + Yellow;
             High: Blue shl 4 + White;
             Low : Blue shl 4 + Black);
     SelBar:(Norm: Red shl 4 + Yellow;
             High: Red shl 4 + White;
             Low : Red shl 4 + Black));
CONST
  DefaultWindowType : Byte=PopUp;
  DefaultFrameType  : Byte=1;     {Single Frame}
CONST
  DefaultFrameColor : Byte=$07;   {LightGrey on Black}
  DefaultPaneColor  : Byte=$03;   {Cyan on Black}
  DefaultTitleColor : Byte=$4F;   {White on Red}
  DefaultBarColor   : Byte=$1E;   {Yellow on Blue}
CONST
  MinimumWidth    : Integer = 3;
  MinimumHeight   : Integer = 3;
CONST
  WindowAutoSave  = $0001;
  WindowAutoClear = $0002;
CONST
  ColorSeg = $B800;
  MonoSeg  = $B000;
CONST
  wDefaultType : wConfig = Fixed;
  wDefaultSave : Boolean = True;
CONST
  wMax = 10; { Open at the same time }
TYPE
  wScrNo  = 0..wMax;
CONST
  wCnt    : wScrNo = 0;
  w80x25 : aWindow =
  (lx:1; uy:1; rx:80; ly:25; Style:0; Border:0; Pane:7; wType:Fixed);
TYPE
  FrameChars = ARRAY[0..12] of Char;
CONST SingleFrame : FrameChars = { 1:ÚÄ}
  (#196,#192,#193,#217,#195,#197,#180,#218,#194,#191,#179,#196,#179);
CONST DoubleFrame : FrameChars = { 2:ÉÍ}
    (#205,#200,#202,#188,#204,#206,#185,#201,#203,#187,#186,#205,#186);
CONST DualSideFrame : FrameChars = { 3:ÖÄ}
    (#196,#211,#208,#189,#199,#215,#185,#214,#210,#183,#186,#196,#186);
CONST DualTopFrame : FrameChars = { 4:ÕÍ}
    (#205,#212,#207,#190,#198,#216,#181,#213,#209,#184,#179,#205,#179);
CONST HiFatFrame : FrameChars = { 5:Ûß}
    (#223,#223,#223,#223,#219,#219,#219,#219,#219,#219,#219,#223,#219);
CONST LoFatFrame : FrameChars = { 6:ÜÜ}
    (#220,#219,#219,#219,#219,#219,#219,#220,#220,#220,#219,#220,#219);
CONST DotFrame1 : FrameChars = { 7:°°}
    (#176,#176,#176,#176,#176,#176,#176,#176,#176,#176,#176,#176,#176);
CONST DotFrame2 : FrameChars = { 8:±±}
    (#177,#177,#177,#177,#177,#177,#177,#177,#177,#177,#177,#177,#177);
CONST DotFrame3 : FrameChars = { 9:²²}
    (#178,#178,#178,#178,#178,#178,#178,#178,#178,#178,#178,#178,#178);
CONST FatFrame : FrameChars = {10:ÛÛ}
    (#219,#219,#219,#219,#219,#219,#219,#219,#219,#219,#219,#219,#219);
CONST ShadowFrame : FrameChars = {11:Ú¼}
    (#196,#212,#107,#188,#195,#197,#185,#218,#194,#183,#179,#205,#186);

VAR
  CurrentCsr   : Word;
  ScreenMode   : byte;
  ScreenSeg    : Word;
  ScreenSegPtr : Pointer;
VAR
  FrameDef : FrameChars;

PROCEDURE UpSt(VAR St);
FUNCTION  Rep(Count:Byte; ch:Char):String;
FUNCTION  FillOut(L,p:Byte; fyll:Char):String;
FUNCTION  BeforeLast(Match:char; st:string):String;
FUNCTION  AfterLast(Match:char; st:string):String;
FUNCTION  StripAll(Ch:Char; st:String):String;
FUNCTION  SwapAll(Ch,ToCh:Char; st:String):String;
PROCEDURE DeleteLeading(Ch:Char; VAR st);
PROCEDURE DeleteTrailing(Ch:Char; VAR st);
FUNCTION  PadLeading(st:String; ch:Char; max:Byte):String;
FUNCTION  PadTrailing(st:String; ch:Char; max:Byte):String;
FUNCTION  IntStr(intNum:Longint; places:byte):str20;
FUNCTION  RealStr(RealNum:Real; places,decimals:ShortInt):str20;
FUNCTION  Bin(verdi:byte):Str8;
FUNCTION  Hex(verdi:byte):Str2;
FUNCTION  Hex16(h,l:byte):Str4;
FUNCTION  HexW(verdi:Word):Str4;
FUNCTION  HexM(verdi:LongInt):Str8;


FUNCTION  col(Paper,Ink:Byte):byte;
PROCEDURE color(Attr:byte);
PROCEDURE center(lx,rx,y,Attr:Byte; s:string);
PROCEDURE Wrt(x,y,Attr:Byte;s:string);
PROCEDURE CharFill(x1,y1,x2,y2,Attr:Byte;Cha:Char);
PROCEDURE ColorFill(x1,y1,x2,y2,Attr:Byte);
PROCEDURE Colorize(x1,x2,y,Attr:Byte);
PROCEDURE vScrollBar(x,y1,y2,Color,
                     Total,              {Total number of items}
                     InWindow,           {Displayable at once}
                     TopWindow:Integer); {Current Top of Window}

PROCEDURE UpdateScrMode;
FUNCTION  GetCsrSize:Word;
PROCEDURE SetCsrSize(cSize:Word);
PROCEDURE Cursor(Size:CursorSize);

PROCEDURE Blip;
PROCEDURE Beep(Typ:Byte);
PROCEDURE Dummy;

PROCEDURE ScrToBuf(x1,y1,x2,y2:Byte;VAR Buffer);
PROCEDURE BufToScr(x1,y1,x2,y2:Byte;VAR Buffer);
PROCEDURE wDef(VAR TheWindow:aWindow; lx,uy,rx,ly,style,border,pane:byte);
PROCEDURE wAdjust(VAR OrigWin,CorrWin:aWindow; VAR height,width:Word);
PROCEDURE Box(x1,y1,x2,y2,Style,Attr:Byte);
PROCEDURE wFrame(TheWindow:aWindow);
PROCEDURE wCenter(win:aWindow; Txt:Str80; atLine,c:Byte);
PROCEDURE wTitle(win:aWindow; TitleTxt:str80; c:byte);
PROCEDURE wFooter(win:aWindow; TitleTxt:str80; c:byte);
PROCEDURE wOpen(TheWindow:aWindow);
PROCEDURE wClose;

IMPLEMENTATION

USES Dos, LFDPMI;

TYPE
  wScreen = Array[1..25,1..80,1..2] of Byte;
  wStore  = RECORD
              Buffer : ^Byte;
              OldWin : aWindow;
              BufSize : Word;
              LastX,
              LastY,
              LastCol : Byte;
              LastCur : Word;
            END;
VAR
  wSave     : ARRAY [wScrNo] of wStore;
  wCurr     : aWindow;
CONST
  LFbinhex_hx : String[16] = '0123456789ABCDEF';
CONST
  LFbinhex_b : Array[0..15] of Str8=(
      '0000','0001','0010','0011',
      '0100','0101','0110','0111',
      '1000','1001','1010','1011',
      '1100','1101','1110','1111');

PROCEDURE UpSt(VAR st);
BEGIN
  INLINE($C4/$BE/St /$26/$8A/$0D/$FE/$C1/$FE/$C9/$74/$13/$47/$26/$80/
   $3D/$61/$72/$F5/$26/$80/$3D/$7A/$77/$EF/$26/$80/$2D/$20/$EB/$E9);
END;{UpSt}

FUNCTION Rep(Count:Byte; ch:Char):String;
{ - Create a string of length=Count composed by the character=ch }
VAR
  n : Byte;
  s : String;
BEGIN
  s:='';
  FOR n:=1 TO Count DO s:=s+ch;
  Rep:=s;
END; {FUNC Rep}

FUNCTION Fillout(L,p:Byte;fyll:Char):String;
BEGIN
  FillOut:=Rep(L-p,fyll);
END;{FillOut}

FUNCTION AfterLast(Match:char;st:string):String;
VAR
  index : Word;
BEGIN
  IF pos(Match,st)<>0 THEN
  BEGIN
    index:=Byte(st[0]);
    WHILE st[index]<>Match DO dec(index);
    AfterLast:=Copy(st,index+1,succ(Byte(st[0])-index));
  END
   ELSE AfterLast:='';
END;{AfterLast}

FUNCTION BeforeLast(Match:char;st:string):String;
VAR
  index : Word;
BEGIN
  IF pos(Match,st)<>0 THEN
  BEGIN
    index:=Byte(st[0]);
    WHILE st[index]<>Match DO dec(index);
    BeforeLast:=Copy(st,1,index-1);
  END
   ELSE BeforeLast:='';
END;{BeforeLast}

FUNCTION StripAll(Ch:Char; st:String):String;
VAR
  index : Word;
BEGIN
  Index:=pos(Ch,st);
  WHILE Index<>0
  DO BEGIN
    Delete(st,Index,1);
    Index:=pos(Ch,st);
  END;
  StripAll:=st;
END; {FUNC StripAll}

FUNCTION SwapAll(Ch,ToCh:Char; st:String):String;
VAR
  index : Word;
BEGIN
  Index:=pos(Ch,st);
  WHILE Index<>0
  DO BEGIN
    st[Index]:=ToCh;
    Index:=pos(Ch,st);
  END;
  SwapAll:=st;
END; {FUNC StripAll}


PROCEDURE DeleteLeading(Ch:Char; VAR st);
BEGIN
  WHILE (String(st)[1]=ch) and (Byte(st)>0) DO Delete(String(st),1,1);
END;{DeleteLeading}

PROCEDURE DeleteTrailing(Ch:Char; VAR st);
BEGIN
  WHILE (String(st)[Byte(st)]=ch) and (Byte(st)>0) DO Dec(Byte(st));
END;{DeleteTrailing}

FUNCTION PadLeading(st:String; ch:Char; max:Byte):String;
BEGIN
  PadLeading:=FillOut(max,Byte(st[0]),ch)+st;
END;{PadLeading}

FUNCTION PadTrailing(st:String; ch:Char; max:Byte):String;
BEGIN
  PadTrailing:=st+FillOut(max,Byte(st[0]),ch);
END;{PadTrailing}

FUNCTION IntStr(intNum:Longint; places:byte):str20;
CONST s : str20 ='';
BEGIN
  str(intNum:places,s);
  IntStr:=s;
END;{IntStr}

FUNCTION RealStr(RealNum:Real; places,decimals:ShortInt):str20;
VAR
  s : str20;
BEGIN
  IF (places<0) or (decimals<0) THEN str(realnum,s)
   ELSE str(realNum:places:decimals,s);
  RealStr:=s;
END;{RealStr}

FUNCTION bin(verdi:byte):Str8;
BEGIN
  bin:=LFbinhex_b[verdi DIV 16]+LFbinhex_b[verdi MOD 16];
END; {bin}

FUNCTION hex(verdi:byte):Str2;
BEGIN
  hex:=LFbinhex_hx[(verdi DIV 16)+1]+LFbinhex_hx[(verdi MOD 16)+1];
END; {hex}

FUNCTION hex16(h,l:byte):Str4;
BEGIN
  hex16:=LFbinhex_hx[(h DIV 16)+1]+LFbinhex_hx[(h MOD 16)+1]+
  LFbinhex_hx[(l DIV 16)+1]+LFbinhex_hx[(l MOD 16)+1];
END; {hex16}

FUNCTION HexW(verdi:Word):Str4;
VAR
  h,l : byte;
BEGIN
  h:=verdi div 256; l:=verdi mod 256;
  hexW:=LFbinhex_hx[(h DIV 16)+1]+LFbinhex_hx[(h MOD 16)+1]+
  LFbinhex_hx[(l DIV 16)+1]+LFbinhex_hx[(l MOD 16)+1];
END; {hexW}

FUNCTION HexM(verdi:LongInt):Str8;
VAR
  h,l : byte;
  v2  : word;
BEGIN
  v2:= verdi mod 65536;
  h:=v2 div 256; l:=v2 mod 256;
  hexM:=LFbinhex_hx[verdi div 4096]+
  LFbinhex_hx[(h DIV 16)+1]+LFbinhex_hx[(h MOD 16)+1]+
  LFbinhex_hx[(l DIV 16)+1]+LFbinhex_hx[(l MOD 16)+1];
END; {hexM}

FUNCTION col(Paper,Ink:Byte):Byte;
VAR
  blink : boolean;
  dCol  : byte;
BEGIN
  blink:=ink div 16 <>0;
  paper:=paper mod 8;
  ink:=ink mod 16;
  dCol:=((paper*16)+ink) mod 128;
  IF blink THEN dCol:=dCol+128;
  col:=dCol;
END; {col}

PROCEDURE color(Attr:Byte);
BEGIN
  TextAttr:=Attr;
END;{color}

PROCEDURE center(lx,rx,y,attr:Byte; s:String);
BEGIN
  lx:=lx+((rx-lx-length(s)+1) DIV 2);
  wrt(lx,y,Attr,s)
END;{center}

PROCEDURE Wrt(x,y,Attr:Byte;s:string); ASSEMBLER;
ASM
         PUSH  DS           { Preserve DS }
         MOV   DX,ScreenSeg { Point ES to start of Video segment }
         MOV   ES,DX
         LDS   SI,s         { Point DS:SI to start of string }
         LODSB              { Get the string length }
         CMP   AL,0         { Check if it is empty ? }
         JE    @@Finish     { Yes, it was empty. Let's quit ! ...else }
         XOR   CH,CH        { CH:=0 }
         MOV   CL,AL
         XOR   AH,AH
         MOV   AL,y         { Get y Position }
         DEC   AL           { Make it an offset }
         MOV   BX,50h       { and calculate offset from the }
         MUL   BX           { start of the video segment }
         MOV   BL,x         { Get x position }
         DEC   BL           { and make it an offset }
         ADD   AX,BX        { Add it to Segment offset }
         SHL   AX,1         { Multiply Seg.Offs by two (char and attr) }
         MOV   DI,AX        { and copy to our video segment index }
         MOV   AH,Attr      { Load our attribute }
         CLD
@@NextCh:LODSB              { Load next char }
         STOSW              { Store Attribute and char to screen }
         LOOP  @@NextCh     { Do loop while CX>0 }
@@Finish:                   { Restore ES and DS }
         POP DS
END;

PROCEDURE CharFill(x1,y1,x2,y2,Attr:Byte;cha:Char); ASSEMBLER;
ASM
         PUSH  DS
         MOV   DX,ScreenSeg { Point DS to Start of Video Segment }
         MOV   ES,DX
         XOR   AH,AH
         MOV   AL,y1        { Calculate Initial offset for first char }
         DEC   AL
         MOV   BX,50h
         MUL   BX
         MOV   BL,x1
         DEC   BL
         ADD   AX,BX
         SHL   AX,1
         MOV   DI,AX       { and store it in DI }
         MOV   AL,x2       { Calculate how wide an area to fill }
         SUB   AL,x1
         INC   AL
         CBW
         MOV   DX,AX       { and store result in DX }
         MOV   AL,y2       { Calculate how high the area to fill }
         SUB   AL,y1
         INC   AL
         CBW
         MOV   CX,AX       { and store this in CX }
         MOV   AX,050h
         SUB   AX,DX
         SHL   AX,1
         MOV   SI,AX
         MOV   AH,Attr     { Get attribute }
         MOV   AL,Cha       { and char }
         CLD
@@NextLn:PUSH  CX          { Preserve height counter }
           MOV   CX,DX     { Get width counter }
           REP STOSW       { Fill the Area }
           MOV  BX,SI    { Now we got to move on to the next line }
           ADD  BX,DI
           MOV  DI,BX
           POP  CX        { Restore height counter }
         LOOP  @@NextLn    { Do outer loop while height>0 }
         POP DS            { Afterwards, restore DS }
END; {PROC CharFill}

PROCEDURE ColorFill(x1,y1,x2,y2,Attr:Byte);        ASSEMBLER;
{ - Colorize a specific screen area with the wanted attribute}
ASM
         PUSH DS           { Preserve DS }
         MOV  DX,ScreenSeg { Point DS to Start of Video Segment }
         MOV  DS,DX
         XOR  AH,AH
         MOV  AL,y1        { Calculate Initial offset for first char }
         DEC  AL
         MOV  BX,50h
         MUL  BX
         MOV  BL,x1
         DEC  BL
         ADD  AX,BX
         SHL  AX,1
         MOV  DI,AX       { and store it in DI }
         MOV  AL,x2       { Calculate how wide an area to fill }
         SUB  AL,x1
         INC  AL
         CBW
         MOV  DX,AX       { and store result in DX }
         MOV  AL,y2       { Calculate how high the area to fill }
         SUB  AL,y1
         INC  AL
         CBW
         MOV  CX,AX       { and store this in CX }
         MOV  AX,050h
         SUB  AX,DX
         SHL  AX,1
         MOV  SI,AX
         MOV  BL,Attr      { Get attribute }
@@NextLn:PUSH CX           { Preserve height counter }
           MOV   CX,DX     { Get width counter }
  @@NextCh:INC   DI        { Skip Char }
             MOV  [DI],BL  { Put attribute into current Video }
             INC  DI       { location and point to the next one }
           LOOP  @@NextCh  { Do inner loop while width>0 }
           MOV  AX,SI
           ADD  AX,DI
           MOV  DI,AX
           POP  CX         { Restore height counter }
         LOOP  @@NextLn    { Do outer loop while height>0 }
         POP DS            { Afterwards, restore DS }
END; {PROC ColorFill}

PROCEDURE ScrToBuf(x1,y1,x2,y2:Byte; VAR Buffer);  ASSEMBLER;
{ - Save a screen window to a buffer }
ASM
         PUSH DS
         MOV  DX,ScreenSeg { Point DS to Start of Video Segment }
         MOV  DS,DX
         LES  DI,Buffer    { Point ES:DI to Start of Buffer }
         XOR  AH,AH
         MOV  AL,y1        { Calculate Initial offset for first char... }
         DEC  AL
         MOV  BX,50h
         MUL  BX
         MOV  BL,x1
         DEC  BL
         ADD  AX,BX
         SHL  AX,1
         MOV  SI,AX       { ...and store it in SI }
         MOV  AL,x2       { Calculate how wide an area to fill... }
         SUB  AL,x1
         INC  AL
         CBW
         MOV  DX,AX       { ...and store result in DX }
         MOV  AL,y2       { Calculate how high the area to fill... }
         SUB  AL,y1
         INC  AL
         CBW
         MOV  CX,AX       { ...and store this in CX }
         MOV  AX,050h     { Calculate offset to next line... }
         SUB  AX,DX
         SHL  AX,1
         MOV  BX,AX       { ...and store it in BX }
         CLD
@@NextLn:PUSH  CX         { Preserve height counter }
           MOV  CX,DX     { Get width counter }
           REP MOVSW      { Store the Line }
           MOV  AX,BX     { move on to the next line }
           ADD  AX,SI
           MOV  SI,AX
           POP  CX        { Restore height counter }
         LOOP @@NextLn    { Do outer loop while height>0 }
         POP  DS
END; {PROC ScrToBuf}

PROCEDURE BufToScr(x1,y1,x2,y2:Byte; VAR Buffer);  ASSEMBLER;
{ - Restore a previously saved buffer to a screen window}
ASM
         PUSH DS
         MOV  DX,ScreenSeg { Point DS to Start of Video Segment }
         MOV  ES,DX
         LDS  SI,Buffer
         XOR  AH,AH
         MOV  AL,y1        { Calculate Initial offset for first char }
         DEC  AL
         MOV  BX,50h
         MUL  BX
         MOV  BL,x1
         DEC  BL
         ADD  AX,BX
         SHL  AX,1
         MOV  DI,AX       { and store it in DI }
         MOV  AL,x2       { Calculate how wide an area to fill }
         SUB  AL,x1
         INC  AL
         CBW
         MOV  DX,AX       { and store result in DX }
         MOV  AL,y2       { Calculate how high the area to fill }
         SUB  AL,y1
         INC  AL
         CBW
         MOV  CX,AX       { and store this in CX }
         MOV  AX,050h
         SUB  AX,DX
         SHL  AX,1
         MOV  BX,AX
         CLD
@@NextLn:PUSH  CX         { Preserve height counter }
           MOV  CX,DX     { Get width counter }
           REP MOVSW      { Restore the Line }
           MOV  AX,BX     { move on to the next line }
           ADD  AX,DI
           MOV  DI,AX
           POP  CX        { Restore height counter }
         LOOP @@NextLn    { Do outer loop while height>0 }
         POP  DS
END; {PROC BufToScr}


PROCEDURE Colorize(x1,x2,y,Attr:Byte);
BEGIN
  ColorFill(x1,y,x2,y,Attr)
END;{Colorize}

PROCEDURE vScrollBar(x,y1,y2,Color:Integer;
                     {TotalChar,          {Bar "background"}
                     {InWindowChar : Char;{Displayed}
                     Total,              {Total number of items}
                     InWindow,           {Displayable at once}
                     TopWindow:Integer); {Current Top of Window}
VAR
  wdy,ty,dy : Integer;
  rdy : Real;
BEGIN
  wdy:=Succ(y2-y1)-2;
  IF wdy>0
  THEN BEGIN
    rdy:=wdy/Total;
    ty:=y1+Round(TopWindow*rdy);
    IF ty<=y1 THEN ty:=y1+1;
    dy:=Round(InWindow*rdy);
    IF dy>wdy THEN dy:=wdy;
    IF ty+dy>y2-1 THEN ty:=y2-dy-1;
    CharFill(x,y1,x,ty,Color,#176);
    CharFill(x,ty+dy,x,y2,Color,#176);
    CharFill(x,ty,x,ty+dy,Color,#219);
    wrt(x,y1,Color,#240);
    wrt(x,y2,Color,#240);
  END;
END;{PROC vScrollBar}

PROCEDURE UpdateScrMode;
VAR
  regs : registers;
BEGIN
  regs.ah:=$0F;
  intr($10,regs);
  ScreenMode:=regs.al;
  IF ScreenMode<>7 THEN ScreenSeg:=ColorSeg ELSE ScreenSeg:=MonoSeg;
  IF ProtectedMode
  THEN ScreenSeg:=SegmentToSelector(ScreenSeg);
  ScreenSegPtr:=Ptr(ScreenSeg,0);
END; {ScrMode}

FUNCTION GetCsrSize:Word;
BEGIN
  GetCsrSize:=CurrentCSR;
END;{GetCsrSize}

PROCEDURE SetCsrSize(cSize:Word);
VAR
  Reg : Registers;
BEGIN
  CurrentCSR:=cSize;
  Reg.AX:=$0100; {Set cursor size. ( A-47 HardWare Tech.Ref.Man.)}
  Reg.CX:=cSize;
  Intr($10,Reg);
END;{SetCsrSize}

PROCEDURE Cursor(Size:CursorSize);
  { Sets cursor to wanted size... requ.IBM-PC compatible BIOS ! }
CONST
  csize : ARRAY[boolean,CursorSize] of Integer =
  (($0D01,$000D,$070C,$0B0C,$2607),($0701,$0007,$0508,$0607,$2607));
BEGIN
  SetCsrSize(csize[ScreenMode<>7,size]);
END;{Cursor}

PROCEDURE Blip;
BEGIN
  Sound(3712); Delay(25); NoSound;
END;{Blip}

PROCEDURE Beep(Typ:Byte);
BEGIN
  CASE typ OF
    1 : BEGIN
          sound(300); delay(20); sound(600); delay(30);
        END;
    2 : BEGIN
          sound(600); delay(20); sound(300); delay(30);
        END;
    3 : BEGIN
          sound(1000); delay(100);
        END;
      ELSE Blip
  END;
  nosound;
END;{Beep}

PROCEDURE Dummy;
BEGIN
  Sound(1); Delay(1); NoSound;
END;

PROCEDURE wDef(VAR TheWindow:aWindow; lx,uy,rx,ly,style,border,pane:byte);
BEGIN
  TheWindow.lx:=lx;
  TheWindow.uy:=uy;
  TheWindow.rx:=rx;
  TheWindow.ly:=ly;
  TheWindow.Style:=Style;
  TheWindow.Border:=Border;
  TheWindow.Pane:=Pane;
  TheWindow.wType:=wDefaultType;
  TheWindow.wSave:=wDefaultSave;
END; {wDef}

PROCEDURE wConvert(OrigWin:aWindow; VAR CorrWin:aWindow);
{ - Adjust inner window size according to type }
BEGIN
  CorrWin:=OrigWin;
  With CorrWin DO
  BEGIN
    IF Style<>0 THEN
    BEGIN
      inc(lx); dec(rx);
      IF wType<>Pull_Down THEN inc(uy);
      IF wType<>Pop_Up THEN dec(ly);
    END;
  END;
END;{wConvert}

PROCEDURE wAdjust(VAR OrigWin,CorrWin:aWindow; VAR height,width:Word);
{ - Adjust window position and size to fit inside screen }
BEGIN
  WITH OrigWin DO
  BEGIN
    IF lx+Width>80 THEN lx:=80-Width;
    IF lx+Width>Rx THEN rx:=lx+Width;
    CASE wType OF
      Fixed     : IF Height<ly-uy-1 THEN ly:=uy+Height+1;
      Pull_Down : IF Height<ly-uy-1 THEN ly:=uy+Height;
      Pop_Up    : IF Height<ly-uy-1 THEN uy:=ly-Height;
    END;
  END;
  wConvert(OrigWin,CorrWin);
  Height:=CorrWin.ly-CorrWin.uy;
  Width :=1+CorrWin.rx-CorrWin.lx;
END;{wAdjust}

PROCEDURE Box(x1,y1,x2,y2,Style,Attr:Byte);
BEGIN
  CharFill(x1,y1,x2,y1,Attr,FrameDef[0]);
  CharFill(x1,y2,x2,y2,Attr,FrameDef[11]);
  CharFill(x1,y1,x1,y2,Attr,FrameDef[10]);
  CharFill(x2,y1,x2,y2,Attr,FrameDef[12]);
  Wrt(x1,y1,Attr,FrameDef[7]);
  Wrt(x2,y1,Attr,FrameDef[9]);
  Wrt(x1,y2,Attr,FrameDef[1]);
  Wrt(x2,y2,Attr,FrameDef[3]);
END;{Box}

PROCEDURE wFrame(TheWindow:aWindow);
{ - Draw a frame inside "TheWindow" }
VAR
  i : byte;
BEGIN
  WITH TheWindow DO
  IF Style<>0 THEN
  BEGIN
    CharFill(lx,uy,lx,ly,border,FrameDef[10]);
    CharFill(rx,uy,rx,ly,border,FrameDef[12]);
    IF wType<>Pull_Down THEN
    BEGIN
      CharFill(lx,uy,rx,uy,border,FrameDef[11]);
      Wrt(lx,uy,border,FrameDef[7]);
      Wrt(rx,uy,border,FrameDef[9]);
    END;
    IF wType<>Pop_Up THEN
    BEGIN
      CharFill(lx,ly,rx,ly,border,FrameDef[0]);
      Wrt(lx, ly,border,FrameDef[ 1]);
      Wrt(rx, ly,border,FrameDef[ 3]);
    END;
  END;
END;{Frame}

PROCEDURE wCenter(win:aWindow; Txt:Str80; atLine,c:Byte);
BEGIN
  center(win.lx,win.rx,atLine,c,Copy(Txt,1,win.rx-win.lx-1));
END;{wCenter}

PROCEDURE wTitle(win:aWindow; TitleTxt:str80; c:byte);
VAR
  y : Byte;
BEGIN
  IF win.wType=Pull_Down THEN y:=Win.ly ELSE y:=Win.uy;
  wCenter(win,Titletxt,y,c);
END;{wTitle}

PROCEDURE wFooter(win:aWindow; TitleTxt:str80; c:byte);
BEGIN
  wCenter(Win,Titletxt,Win.ly,c);
END;{wFooter}

FUNCTION CalcBufSize(Win:aWindow):Word;
BEGIN
  CalcBufSize:=Succ(Win.ly-Win.uy)*2*Succ(Win.rx-Win.lx);
END;{CalcBufSize}

PROCEDURE wOpen(TheWindow : aWindow);
BEGIN
  IF wCnt<wMax THEN
  BEGIN
    IF wCnt = 0 THEN wCurr:=w80x25;
    WITH wSave[wCnt] DO
    BEGIN
      OldWin:=wCurr;
      BufSize:=CalcBufSize(TheWindow);
      GetMem(Buffer,BufSize);
      ScrToBuf(TheWindow.lx,TheWindow.uy,TheWindow.rx,TheWindow.ly,Buffer^);
      LastX:=WhereX;
      LastY:=WhereY;
      LastCol:=TextAttr;
      LastCur:=GetCsrSize;
    END;
    wCurr:=TheWindow;
    wFrame(TheWindow);
    wConvert(wCurr,TheWindow);
    With TheWindow DO
    BEGIN
      Window(lx,uy,rx,ly);
      color(pane);
    END;
    inc(wCnt);
  END;
END; {wOpen}

PROCEDURE wClose;
VAR
  x,y   : Byte;
  wTemp : aWindow;
BEGIN
  IF wCnt>0 THEN
  BEGIN
    dec(wCnt);
    WITH wSave[wCnt] DO
    BEGIN
      BufToScr(wCurr.lx,wCurr.uy,wCurr.rx,wCurr.ly,Buffer^);
      wCurr:=OldWin;
      x:=LastX;
      y:=LastY;
      Color(LastCol);
      SetCsrSize(LastCur);

      FreeMem(Buffer,BufSize);
    END;
    wConvert(wCurr,wTemp);
    WITH wTemp DO Window(lx,uy,rx,ly);
    gotoxy(x,y);
  END;
END; {wClose}

{--- Methods for Object : TxtCursor -----------------------------------------}

VAR
  TxtAreaLimit : anArea;



CONSTRUCTOR TxtCursor.Init(AtX,AtY:Integer; OwnerWS:PWorkSpace);
{ - }
BEGIN
  GenericCursor.Init(atX,atY,OwnerWS);
  State:=NormalCsr;
END; {CONS TxtCursor.Init}

FUNCTION  TxtCursor.AbsX:Integer;
{ - Return cursor x-pos relative to screen origin}
BEGIN
  AbsX:=Owner^.Left+x;
END; {FUNC TxtCursor.AbsX}

FUNCTION  TxtCursor.AbsY:Integer;
{ - Return cursor y-pos relative to screen origin}
BEGIN
  AbsY:=Owner^.Top+y;
END; {FUNC TxtCursor.AbsY}

PROCEDURE TxtCursor.MoveTo(NewX,NewY:Integer);
{ - Move cursor within owner-window}
BEGIN
  x:=NewX;
  y:=NewY;
  GotoXY(AbsX,AbsY);
END; {PROC TxtCursor.MoveTo}

PROCEDURE TxtCursor.ChangeState(NewState:CursorSize);
BEGIN
  GenericCursor.ChangeState(NewState);
  IF NewState=HiddenCsr THEN Cursor(HiddenCsr);
END;

PROCEDURE TxtCursor.Hide;
{ - Turn cursor off}
BEGIN
  Cursor(HiddenCsr);
  GenericCursor.Hide;
END; {PROC TxtCursor.Hide}

PROCEDURE TxtCursor.Show;
{ - turn cursor on}
BEGIN
  Cursor(State);
  GenericCursor.Show;
END; {PROC TxtCursor.Show}

{------------------------------------------------------------ TxtWorkSpace ---

}

CONSTRUCTOR TxtWorkspace.Init(x,y,w,h:Integer);
{ - Define the location and size of the workspace}
BEGIN
  GenericWorkspace.Init(x,y,w,h);
  Pane.SetDefault(StdTxtWin.Pane);
  SelBar.SetDefault(StdTxtWin.SelBar);
  CC:=Pane.Norm;
  Cursor:=New(PTxtCursor,Init(0,0,@Self));
END; {CONS TxtWorkspace.Init}

CONSTRUCTOR TxtWorkspace.InitTxt(x,y,Columns,Lines:Integer);
{ - Define the location and size of the workspace
    (size by number of columns/lines of text it can display) }
BEGIN
  TxtWorkspace.Init(x,y,Columns,Lines);
END; {CONS TxtWorkspace.InitTxt}

DESTRUCTOR TxtWorkspace.Done;
{ - Close (if open), Deallocate used memory, i.e. Clean up after workspace}
BEGIN
  Dispose(PTxtCursor(Cursor),Done);
  Cursor:=nil;
  GenericWorkspace.Done;
END; {DEST TxtWorkspace.Done}

PROCEDURE TxtWorkspace.MoveTo(x,y:Integer);
{ - Move the workspace (upper lef corner) to (x,y)
    (Assume width and height within limits)}
VAR
  m : Integer;
  wasOpen : Boolean;
BEGIN
  wasOpen:=isOpen;
  IF wasOpen THEN Close;
  lx:=x;                          {Adjust in horisontal direction}
  IF not TxtAreaLimit.InXrange(Left)     {Too far left}
   THEN lx:=TxtAreaLimit.Left;
  IF not TxtAreaLimit.InXrange(Right)    {Too far right}
   THEN lx:=TxtAreaLimit.Right-Width+1;
  uy:=y;                          {Adjust in vertical direction}
  IF not TxtAreaLimit.InYrange(Top)      {Too high}
   THEN uy:=TxtAreaLimit.Top;
  IF not TxtAreaLimit.InYrange(Bottom)   {Too low}
   THEN uy:=TxtAreaLimit.Bottom-Height+1;
  IF wasOpen THEN Open;
END; {PROC TxtWorkspace.MoveTo}

PROCEDURE TxtWorkspace.SizeSet(w,h:Integer);
{ - Set Size of workspace: width and height in pixels}
VAR
  m : Integer;
  wasOpen : Boolean;
BEGIN
  wasOpen:=isOpen;
  IF wasOpen THEN Close;
  IF w<MinimumWidth THEN w:=MinimumWidth; {Adjust horisontal size}
  IF w<=TxtAreaLimit.Width
  THEN xw:=w
  ELSE xw:=TxtAreaLimit.Width;
  IF h<MinimumHeight THEN h:=MinimumHeight; {Adjust vertical size}
  IF h<=TxtAreaLimit.Height
  THEN yh:=h
  ELSE yh:=TxtAreaLimit.Height;
  MoveTo(Left,Top);            {Adjust position if necessary}
  if wasOpen THEN Open;
END; {PROC TxtWorkspace.SizeSet}

PROCEDURE TxtWorkspace.TxtAdjSize(Columns,Lines:Integer);
{ - Set Size of workspace: width and height in TextLines}
BEGIN
  TxtWorkspace.SizeSet(Columns,Lines);
END; {PROC TxtWorkspace.TxtAdjSize}

PROCEDURE TxtWorkspace.TxtBar(x,y,w:Integer; cf:SingleColor);
{ - Draw a Bar}
BEGIN
  Colorize(Left+x,Left+x+w,Top+y,cf.all);
END; {PROC TxtWorkspace.TxtBar}

PROCEDURE TxtWorkspace.Open;
{ - Open the workspace: Draw it/Select}
BEGIN
  IF not isOpen
  THEN BEGIN
    LastX:=WhereX;
    LastY:=WhereY;
    Clear;
    GenericWorkspace.Open;
  END;
END; {PROC TxtWorkspace.Open}

FUNCTION TrimmedString(MaxLen:Integer; Txt:String):String;
{ - Shorten a string to fit within a maximum width}
VAR
  n : Word;
BEGIN
  n:=Length(Txt);
  WHILE (n>MaxLen) and (n>0) DO dec(n);
  TrimmedString:=Copy(Txt,1,n);
END; {FUNC TrimmedString}

FUNCTION TrimmedStringLength(MaxLen:Integer; Txt:String):Integer;
{ - Give length of a trimmed string }
VAR
  n : Word;
BEGIN
  n:=Length(Txt);
  WHILE (n>MaxLen) and (n>0) DO dec(n);
  TrimmedStringLength:=n;
END; {FUNC TrimmedStringLength}

PROCEDURE TxtWorkspace.Clear;
{ - Clear the pane of the workspace }
BEGIN
  CharFill(Left,Top,Right,Bottom,Pane.Norm.All,' ');
END; {PROC TxtWorkspace.Clear}

PROCEDURE TxtWorkspace.ScrollUp(Lines:Integer);
{ - Roll the contents of the workspace "Lines" lines upwards}
VAR
  b : Pointer;
  w : Word;
BEGIN
{  IF MemUsage<65000
  THEN} BEGIN
    w:=(Height-1)*Width*2;
    GetMem(b,w);
    ScrToBuf(Left,Top+Lines,Right,Bottom,b^);
    BufToScr(Left,Top,Right,Bottom-Lines,b^);
    FreeMem(b,w);
  END;
END; {PROC TxtWorkspace.ScrollUp}

PROCEDURE TxtWorkspace.ScrollDown(Lines:Integer);
{ - Roll the contents of the workspace "Lines" lines downwards}
VAR
  b : Pointer;
  w : Word;
BEGIN
{  IF MemUsage<65000
  THEN} BEGIN
    w:=(Height-1)*Width*2;
    GetMem(b,w);
    ScrToBuf(Left,Top,Right,Bottom-lines,b^);
    BufToScr(Left,Top+lines,Right,Bottom,b^);
    FreeMem(b,w);
  END;
END; {PROC TxtWorkspace.ScrollDown}

PROCEDURE TxtWorkspace.Wrt(x,y:Integer; cf:SingleColor; Txt:String);
{ - Display a text at (x,y) within the workspace relative to upper left corner}
BEGIN
  CC:=CF;
  IF x<0 THEN x:=0;
  LFCrt.Wrt(Left+x,Top+y,cf.all,TrimmedString(Width,Txt));
END; {PROC TxtWorkspace.Wrt}

PROCEDURE TxtWorkspace.WrtTxt(x,y:Integer; cf:SingleColor; Txt:String);
{ - Display a text at (x,y) within the workspace relative to upper left corner}
VAR
  l,u : Integer;
  visible : Boolean;
BEGIN
  TxtWorkspace.Wrt(x,y,cf,Txt);
END; {PROC TxtWorkspace.WrtTxt}

PROCEDURE TxtWorkspace.Center(y:Integer; cf:SingleColor; Txt:String);
{ - Display a Text Centered at row y within the workspace}
VAR
  l : Integer;
BEGIN
  CC:=CF;
  l:=(Width DIV 2)-(TrimmedStringLength(Width,Txt) DIV 2);
  LFcrt.Wrt(Left+l,Top+y,cf.all,TrimmedString(Width,Txt));
END; {PROC TxtWorkspace.Center}

PROCEDURE TxtWorkspace.Ctr(y:Integer; cf:SingleColor; Txt:String);
{ - Display a Text Centered at row y within the workspace}
VAR
  l : Integer;
BEGIN
  CC:=CF;
  l:=(Width DIV 2)-(TrimmedStringLength(Width,Txt) DIV 2);
  LFCrt.Wrt(Left+l,y,cf.all,TrimmedString(Width,Txt));
END; {PROC TxtWorkspace.Ctr}

PROCEDURE TxtWorkspace.Leave;
{ - Exit the workspace without closing it}
BEGIN
END; {PROC TxtWorkspace.Leave}

PROCEDURE TxtWorkspace.Close;
{ - Close the workspace }
VAR
  h2 : Word;
BEGIN
  IF isOpen
  THEN BEGIN
    GenericWorkspace.Close;
    GotoXY(LastX,LastY);
  END;
END; {PROC TxtWorkspace.Close}



{--------------------------------------------------------------- TxtWindow ---

}

CONSTRUCTOR TxtWindow.Init(x,y,w,h:Integer; BackGrSave:Boolean);
BEGIN
  GenericWindow.Init(x,y,w,h,BackGrSave);
  C.SetDefault(StdTxtWin);
END;{CONS TxtWindow.Init}

CONSTRUCTOR TxtWindow.InitTxt(x,y,Columns,Lines:Integer; BackGrSave:Boolean);
BEGIN
  TxtWindow.Init(x,y,Columns,Lines+2,BackGrSave);
END;{CONS TxtWindow.InitTxt}

DESTRUCTOR TxtWindow.Done;
BEGIN
  GenericWindow.Done;
END;{DEST TxtWindow.Done}

PROCEDURE TxtWindow.MoveTo(x,y:Integer);
VAR
  wasOpen : Boolean;
BEGIN { - Place Window (Assume width and height within limits)}
  wasOpen:=isOpen;
  IF wasOpen THEN Close;
  lx:=x;                          {Adjust in horisontal direction}
  IF not TxtAreaLimit.InXrange(Left)     {Too far left}
   THEN lx:=TxtAreaLimit.Left;
  IF not TxtAreaLimit.InXrange(Right)    {Too far right}
   THEN lx:=TxtAreaLimit.Right-Width+1;
  uy:=y;                          {Adjust in vertical direction}
  IF not TxtAreaLimit.InYrange(Top)      {Too high}
   THEN uy:=TxtAreaLimit.Top;
  IF not TxtAreaLimit.InYrange(Bottom)   {Too low}
   THEN uy:=TxtAreaLimit.Bottom-Height+1;
  WorkSpace^.MoveTo(iLeft,iTop);
  WorkSpace^.SizeSet(iWidth,iHeight);
  IF wasOpen
  THEN Open;
END;{PROC TxtWindow.MoveTo}

PROCEDURE TxtWindow.SizeSet(w,h:Integer);
VAR
  wasOpen : Boolean;
BEGIN { - Dimension Window}
  wasOpen:=isOpen;
  IF wasOpen THEN Close;
  IF w<MinimumWidth THEN w:=MinimumWidth; {Adjust horisontal size}
  IF w<=TxtAreaLimit.Width
  THEN xw:=w
  ELSE xw:=TxtAreaLimit.Width;
  IF h<MinimumHeight THEN h:=MinimumHeight; {Adjust vertical size}
  IF h<=TxtAreaLimit.Height
  THEN yh:=h
  ELSE yh:=TxtAreaLimit.Height;
  MoveTo(Left,Top);            {Adjust position if necessary}
  IF wasOpen THEN Open;
END;{PROC TxtWindow.SizeSet}

PROCEDURE TxtWindow.TxtAdjSize(Columns,Lines:Integer);
BEGIN { - Dimension Window by text space}
  TxtWindow.SizeSet(Columns+2,Lines+2);
END;{PROC TxtWindow.TxtAdjSize}

PROCEDURE TxtWindow.InternalInit;
BEGIN
  WindowType:=DefaultWindowType;
  FrameType:=DefaultFrameType;
  ilx:=0;
  iuy:=0;
  irx:=0;
  ily:=0;
  IF FrameType<>0
  THEN BEGIN
    inc(ilx); Inc(irx); {Adjust width}
    CASE WindowType OF
      PopUp    : BEGIN
                   iuy:=1; ily:=1;
                 END;
      PullDown : ily:=1;
      PullUp   : iuy:=1;
    END;{case}
  END;
  WorkSpace:=New(PTxtWS,Init(iLeft,iTop,iWidth,iHeight));
END;{PROC TxtWindow.InternalInit}

PROCEDURE TxtWindow.Open;
BEGIN
  GetMem(Buffer,MemUsage);
  ScrToBuf(Left,Top,Right,Bottom,Buffer^);
  GenericWindow.Open;
END;{PROC TxtWindow.Open}

PROCEDURE TxtWindow.Frame;
VAR
  cc : Byte;
BEGIN { - Frame the window}
  cc:=C.Frame.Norm.All;
  IF FrameType<>0
  THEN BEGIN
    Wrt(Left,iTop,cc,FrameDef[10]);
    CharFill(Left,iTop,Left,iBottom,cc,FrameDef[10]);
    CharFill(Right,iTop,Right,iBottom,cc,FrameDef[12]);
    IF WindowType<>PullDown THEN
    BEGIN
      CharFill(Left,Top,Right,Top,cc,FrameDef[0]);
      LFcrt.Wrt(Left,Top,cc,FrameDef[7]);
      LFcrt.Wrt(Right,Top,cc,FrameDef[9]);
      IF Header<>Nil
      THEN LFcrt.Center(Left,Right,Top,C.Title.Norm.All,
                        Copy(Header^,1,iWidth));
    END;
    IF WindowType<>PullUp THEN
    BEGIN
      CharFill(Left,Bottom,Right,Bottom,cc,FrameDef[11]);
      LFcrt.Wrt(Left,Bottom,cc,FrameDef[ 1]);
      LFcrt.Wrt(Right,Bottom,cc,FrameDef[ 3]);
      IF Footer<>Nil
      THEN LFcrt.Center(Left,Right,Top+Height-1,C.Title.Norm.All,
                        Copy(Footer^,1,iWidth));
    END;
  END;
END;{PROC TxtWindow.Frame}

PROCEDURE TxtWindow.Clear;
BEGIN { - Clear pane of window}
  GenericWindow.Clear;
END;{PROC TxtWindow.Clear}

PROCEDURE TxtWindow.Leave;
BEGIN
END;{PROC TxtWindow.Leave}

PROCEDURE TxtWindow.Close;
BEGIN
  GenericWindow.Close;
  BufToScr(Left,Top,Right,Bottom,Buffer^);
  FreeMem(Buffer,MemUsage);
END;{PROC TxtWindow.Close}

FUNCTION TxtWindow.MemUsage:LongInt;
BEGIN
  MemUsage:=Width*Height*2;
END;{FUNC TxtWindow.MemUsage}

VAR
  PrevExitProc : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  TxtAreaLimit.Done;
  Units.Leave(LFCrtMsg,MemAvail);
END;

BEGIN
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  wCnt:=0;
  Units.Enter(LFCrtMsg,MemAvail,CSeg);
  UpdateScrMode;
  Cursor(NormalCsr);
  FrameDef:=SingleFrame;
  TxtAreaLimit.Init(1,1,80,25); {Define a default window area}
END.
