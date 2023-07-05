{$I CODEDEFS.PAS} {Include code generation definitions}
{$O-,Q-}
UNIT LFGraph;

INTERFACE
USES
  Crt,LFsystem,Graph,BitFont1;
CONST
  LFgraphMsg = ' LFgraph.6 19890308 Lars Fosdal ';

TYPE
  ByteSet = Set of Byte;
  wCoord  = RECORD
              x,y : Float;
            END;
  dCoord  = RECORD
              x,y : Integer;
            END;
  wWindow = RECORD
              min : wCoord;
              max : wCoord;
            END;
  dWindow = RECORD
              min : dCoord;
              max : dCoord;
            END;
  gWindow = RECORD
              w           : wWindow;
              d           : dWindow;
              Clip,
              xLog,yLog   : Boolean;
              xsf,ysf,
              dx,dy,
              ldx,ldy     : Float;
              xDec,yDec,
              xBase,yBase : Integer;
              buffers,
              Buf2Start   : Word;
              FrameCol,
              PaneCol     : Byte;
              Buf1,Buf2   : Pointer;
            END;
  DeviceInfo = RECORD
                 Device,
                 LoMode,
                 Mode,
                 HiMode,
                 Xmax,
                 Ymax,
                 Cmax,
                 Error   : Integer;
               END;

CONST
  PageOriginOffset : Word = 0;          { Bufferoffset of Video Page 1}
  PutMode          : Word = NormalPut;  { hLine/vLine }
CONST
  IBM   = 1;
  Epson = 2;
  PrinterType : Word = IBM;

VAR
  GraphPossible : Boolean;
  Graphics      : DeviceInfo;
  NormalWin     : gWindow;
VAR
  TextBlackOut  : Boolean;    {Erase all pixels under text}

PROCEDURE RecalcWin (VAR Win:gWindow);
PROCEDURE InitWin   (VAR Win:gWindow);
PROCEDURE SetWindow (VAR Win:gWindow; x1,y1,x2,y2:Integer);
PROCEDURE SetWorld  (VAR Win:gWindow; x1,y1,x2,y2:Float);
PROCEDURE SetXLog   (VAR Win:gWindow; Dec,Base:Integer);
PROCEDURE SetYLog   (VAR Win:gWindow; Dec,Base:Integer);
FUNCTION  xWtoD     (VAR Win:gWindow; x:Float):Integer;
FUNCTION  yWtoD     (VAR Win:gWindow; y:Float):Integer;
PROCEDURE wPutPixel (VAR Win:gWindow; x,y: Float; color:word);
PROCEDURE wLine     (VAR Win:gWindow; x1,y1,x2,y2:Float);
PROCEDURE wMoveTo   (VAR Win:gWindow; x,y:Float);
PROCEDURE wLineTo   (VAR Win:gWindow; x,y:Float);
PROCEDURE wCircle   (VAR Win:gWindow; x,y,radius:Float);
PROCEDURE wBar      (VAR Win:gWindow; x1,y1,x2,y2:Float);
PROCEDURE wBar3D    (VAR Win:gWindow; x1,y1,x2,y2:Float; Depth:Integer; Top:Boolean);
PROCEDURE wDrawPoly (VAR Win:gWindow; NumPoints:Word; VAR wPolyPoints);
PROCEDURE wFillPoly (VAR Win:gWindow; NumPoints:Word; VAR wPolyPoints);
{PROCEDURE Vector    (x,y,Angle,Length:Integer);}
PROCEDURE TextXY    (x,y:Integer;txt:String);
PROCEDURE wText     (VAR Win:gWindow; x,y:Float; theText:string);
PROCEDURE xScale    (VAR Win:gWindow; LineStyle,ScaleColor:Word);
PROCEDURE yScale    (VAR Win:gWindow; LineStyle,ScaleColor:Word);
PROCEDURE gScrDump  (DumpColors : ByteSet);
PROCEDURE tScrDump  (uy,ly:Byte);
PROCEDURE GetGraphInfo (VAR Info:DeviceInfo);
FUNCTION  OpenGraph:boolean;
PROCEDURE SplitScreen (SplitLine:Integer);

PROCEDURE GetBlock  (lx,uy,rx,ly:Integer; VAR BitMap);
PROCEDURE PutBlock  (lx,uy:Integer; VAR BitMap; PMode:Word);
PROCEDURE GetPBlock (lx,uy,rx,ly:Integer; VAR BitMap);
PROCEDURE PutPBlock (lx,uy:Integer; VAR BitMap; PMode:Word);
PROCEDURE Block     (lx,uy,rx,ly, Col:Integer);
FUNCTION  PlaneSize (x,y,x2,y2:Integer):Word;
PROCEDURE GetPlane  (Plane:Byte; LX,UY,RX,LY:Integer; VAR BitMap);
PROCEDURE PutPlane  (Plane:Byte; lx,uy:Integer; VAR BitMap; PMode:Word);
PROCEDURE Paint     (lx,uy,Color:Integer; VAR BitMap; PMode:Word);

PROCEDURE hLine(LX,RX,Y,Col:Integer);
PROCEDURE vLine(X,UY,LY,Col:Integer);

TYPE
  PaletteMix = ARRAY[0..15]
               OF RECORD
                 r,g,b:Byte;
               END;
CONST
  Win3Pal : PaletteMix =
  ((r:$00; g:$00; b:$00),  {Black}
   (r:$02; g:$02; b:$25),  {D.Blue}
   (r:$02; g:$25; b:$02),  {D.Green}
   (r:$00; g:$25; b:$25),  {D.Cyan}
   (r:$25; g:$02; b:$02),  {D.Red}
   (r:$25; g:$00; b:$25),  {D.Magenta}
   (r:$25; g:$25; b:$00),  {D.Yellow}
   (r:$25; g:$25; b:$25),  {L.Gray}
   (r:$13; g:$13; b:$13),  {D.Gray}
   (r:$00; g:$00; b:$3c),  {L.Blue}
   (r:$00; g:$3c; b:$00),  {L.Green}
   (r:$00; g:$3c; b:$3c),  {L.Cyan}
   (r:$3c; g:$00; b:$00),  {L.Red}
   (r:$3c; g:$00; b:$3c),  {L.Magenta}
   (r:$3c; g:$3c; b:$00),  {L.Yellow}
   (r:$3e; g:$3e; b:$3e)); {White}

CONST
  StdVGApal : ARRAY[0..15] OF RECORD r,g,b:Byte; END =
  ((r:$00; g:$00; b:$00),  {Black}
   (r:$00; g:$00; b:$fc),  {D.Blue}
   (r:$24; g:$fc; b:$24),  {D.Green}
   (r:$00; g:$fc; b:$fc),  {D.Cyan}
   (r:$fc; g:$14; b:$14),  {D.Red}
   (r:$b0; g:$00; b:$fc),  {D.Magenta}
   (r:$70; g:$48; b:$00),  {D.Yellow}
   (r:$c4; g:$c4; b:$c4),  {L.Gray}
   (r:$34; g:$34; b:$34),  {D.Gray}
   (r:$00; g:$00; b:$70),  {L.Blue}
   (r:$00; g:$70; b:$00),  {L.Green}
   (r:$00; g:$70; b:$70),  {L.Cyan}
   (r:$70; g:$00; b:$00),  {L.Red}
   (r:$70; g:$00; b:$70),  {L.Magenta}
   (r:$fc; g:$fc; b:$24),  {L.Yellow}
   (r:$fc; g:$fc; b:$fc)); {White}

PROCEDURE MixPal(Mix:PaletteMix);
PROCEDURE BlendPal(Mix:PaletteMix; Factor:Integer);
PROCEDURE SetOverScan(Color:Integer);


(*
  Spacing table :  X    Y
  CourierFont      8    16
  ScriptFont       8    16
  BroadWayFont     9    16
  FutureFont       9    16
  CP865EGAFont     8    16
  LcdFont          8    16
  EGA8x8TNFont     7    9
*)
TYPE
  TextProc = PROCEDURE (xp,yp:Integer; Color:Byte; Txt:String);
CONST
  CharSpacing : Byte = 8;
  LineSpacing : Byte = 15;
CONST
  uLineOffset : ShortInt = 0;
  Underlining : Boolean = False;
VAR
  CurrFont  : FontSet;

PROCEDURE SetFont(Font:Pointer;ChSpc,LnSpc:Byte);
PROCEDURE gWrt(xp,yp:Integer; Color:Byte; txt:String);
PROCEDURE gTxt(xp,yp:Integer; Color:Byte; Txt:String);
PROCEDURE _gWrt(xp,yp:Integer; Color:Byte; txt:String);
PROCEDURE Wavetext(xp,yp:Integer; Color:Byte; txt:String);
PROCEDURE VDtext(xp,yp:Integer; Color:Byte; txt:String);
PROCEDURE VUtext(xp,yp:Integer; Color:Byte; txt:String);
PROCEDURE Shadow(WriteProc:TextProc;xp,yp:Integer;
                 Color:Byte; txt:string);
PROCEDURE ActivePage(Page:Word);

PROCEDURE DitherH(x1,y1,x2,y2,c1,c2:Integer);
PROCEDURE DitherV(x1,y1,x2,y2,c1,c2:Integer);


IMPLEMENTATION
USES
  Dos,LFcrt,LFdos,LFprint,LFmath,LFDPMI;

CONST
  ScaleFactor : Array[1..12] OF Word =
  (1,2,5,10,20,25,50,100,200,250,500,1000);
TYPE
  SplitProcType = PROCEDURE (SplitLine:Integer);
VAR
  SplitProc : SplitProcType;


PROCEDURE MixPal(Mix:PaletteMix);
CONST
  Pal : PaletteType =
  (Size:16; Colors:(0,1,2,3,4,5,20,7,56,57,58,59,60,61,62,63));
VAR
  i : Integer;
  c : Byte;
  PROCEDURE MixEntry(c,r,g,b:Byte); ASSEMBLER;
  ASM
    mov  dx,03c8h
    mov  al, c
    out  dx,al
    inc  dx
    mov  al,r
    out  dx,al
    mov  al,g
    out  dx,al
    mov  al,b
    out  dx,al
  END;
{
DATA/Programmering message #97 from TORSTEN AMUNDSEN to ERLING ELLINGSEN (read).
   Entered on 13th April, 1991 at 20:20, 29 lines.
   Reply to msg # 96. (There are no more replies.)
   There are replies to this message.

Subject: VGA palette & 3d koordinater..
=======================================

Etter at du har satt blÜfarge-styrken i registeret sÜ funker vga
kortet slik at du automatisk kan fortsette Ü sette DAC register dvs. 201
i dette tilfellet. du slipper altsÜ Ü utfõre de fire fõrste
instruksjonene for hver farge hvis det er flere et DAC register du
õnsker Ü sette. Du kan altsÜ enkelt ha en liten loop med lodsb og out
dx,al for en bunch av DAC registre.
Regner med at overnevnte er riktig da det er tatt pÜ husk da jeg ikke
har bõkene her.
GÜr utifra at du vet at en farge er satt sammen av Rõd-Grõnn-BlÜ og
hvor hver av disse er 6-bit. Dvs at du da kan velge mellom 2^18
forskjellige palletter - En del farger......

}
BEGIN
  FOR i:=0 TO 15
  DO MixEntry(Pal.Colors[i],Mix[i].r,Mix[i].g,Mix[i].b);
END;


PROCEDURE BlendPal(Mix:PaletteMix; Factor:Integer);
VAR
  i : Integer;
BEGIN
  IF Factor<1 THEN Factor:=1;
  FOR i:=0 TO 15
  DO BEGIN
    Mix[i].r:=Mix[i].r DIV Factor;
    Mix[i].g:=Mix[i].g DIV Factor;
    Mix[i].b:=Mix[i].b DIV Factor;
  END;
  MixPal(Mix);
END;

PROCEDURE SetOverScan(Color:Integer);
VAR
  Regs : Registers;
BEGIN
  Regs.ah:=$10;
  Regs.al:=1;
  Regs.bh:=Color and $FF;
  Intr($10,Regs);
END;{PROC SetOverScan}

PROCEDURE RecalcWin{(VAR Win:gWindow)};
BEGIN
  WITH Win DO
  BEGIN
    dx:=(succ(d.max.x)-d.min.x)/(w.max.x-w.min.x);
    dy:=(succ(d.max.y)-d.min.y)/(w.max.y-w.min.y);
    ldx:=(w.max.x-w.min.x)/(xDec-xBase);
    ldy:=(w.max.y-w.min.y)/(yDec-yBase);
  END;
END;{RecalcWin}

PROCEDURE InitWin{(VAR Win:gWindow)};
BEGIN
  WITH Win DO
  BEGIN
    d.min.x:=0;
    d.min.y:=0;
    d.max.x:=Graphics.xMax;
    d.max.y:=Graphics.yMax;
    w.min.x:=d.min.x;
    w.min.y:=d.min.y;
    w.max.x:=d.max.x;
    w.max.y:=d.max.y;
    xLog:=False; xBase:=1; xDec:=5;
    yLog:=False; yBase:=1; yDec:=5;
    Clip:=True;
    xsf:=1.0;
    ysf:=1.0;
    Buffers:=0;
    Buf2Start:=0;
    FrameCol:=LightGray;
    PaneCol:=Cyan;
  END;
  RecalcWin(Win);
END;{InitWin}

PROCEDURE SetWindow{(Win:gWindow; x1,y1,x2,y2:Word)};
BEGIN
  WITH Win DO
  BEGIN
    d.min.x:=x1; d.min.y:=y1; d.max.x:=x2; d.max.y:=y2;
    IF x1>x2 THEN Exchange(d.min.x,d.max.x,SizeOf(d.min.x));
    IF y1>y2 THEN Exchange(d.min.y,d.max.y,SizeOf(d.min.y));
  END;
  RecalcWin(Win);
END;{SetWindow}

PROCEDURE SetWorld{(Win:gWindow; x1,y1,x2,y2:Float)};
BEGIN
  WITH Win DO
  BEGIN
    w.min.x:=x1; w.min.y:=y1; w.max.x:=x2; w.max.y:=y2;
    IF x1>x2 THEN Exchange(w.min.x,w.max.x,SizeOf(w.min.x));
    IF y1>y2 THEN Exchange(w.min.y,w.max.y,SizeOf(w.min.y));
  END;
  RecalcWin(Win);
END;{SetWorld}

PROCEDURE SetXLog{(VAR Win:gWindow; Dec,Base:Integer)};
BEGIN
  Win.xLog:=True; Win.xDec:=Dec; Win.xBase:=Base;
  RecalcWin(Win);
END;{SetXLog}

PROCEDURE SetYLog{(VAR Win:gWindow; Dec,Base:Integer)};
BEGIN
  Win.yLog:=True; Win.yDec:=Dec; Win.yBase:=Base;
  RecalcWin(Win);
END;{SetYLog}

FUNCTION xWtoD(VAR Win:gWindow; x:Float):Integer;
VAR
  ix : Integer;
BEGIN
  IF Win.xLog THEN ix:=Round(Ln(x)/2.302585093*Win.ldx*Win.dx)
   ELSE ix:=round((x-Win.W.min.X)*Win.dx);
   xWtoD:=Win.d.min.x+ix;
END;{xWtoD}

FUNCTION yWtoD(VAR Win:gWindow; y:Float):Integer;
VAR
  iy : Integer;
BEGIN
  IF Win.yLog THEN iy:=Round(Ln(y)/2.302585093*Win.ldy*Win.dy)
   ELSE iy:=round((y-Win.W.min.Y)*Win.dy);
  yWtoD:=win.d.max.y-iy;
END;{yWtoD}

PROCEDURE wPutPixel(VAR Win:gWindow; x,y: Float; color:word);
BEGIN
  PutPixel(xWtoD(Win,x),yWtoD(Win,y),Color);
END;{wPutPixel}

PROCEDURE wLine(VAR Win:gWindow; x1,y1,x2,y2:Float);
BEGIN
  Line(xWtoD(Win,x1),yWtoD(Win,y1),xWtoD(Win,x2),yWtoD(Win,y2));
END;{wLine}

PROCEDURE wMoveTo(VAR Win:gWindow; x,y:Float);
BEGIN
  MoveTo(xWtoD(Win,x),yWtoD(Win,y));
END;{wMoveTo}

PROCEDURE wLineTo(VAR Win:gWindow; x,y:Float);
BEGIN
  LineTo(xWtoD(Win,x),yWtoD(Win,y));
END;{wLineTo}

PROCEDURE wCircle(VAR Win:gWindow; x,y,radius:Float);
BEGIN
  Ellipse(xWtoD(Win,x),yWtoD(Win,y),0,360,
  Round(radius*Win.dx),Round(radius*Win.dy));
END;{wLine}

PROCEDURE wBar(VAR Win:gWindow; x1,y1,x2,y2:Float);
BEGIN
  Bar(xWtoD(Win,x1),yWtoD(Win,y1),xWtoD(Win,x2),yWtoD(Win,y2));
END;{PROC wBar}

PROCEDURE wBar3D(VAR Win:gWindow; x1,y1,x2,y2:Float; Depth:Integer; Top:Boolean);
BEGIN
  Bar3D(xWtoD(Win,x1),yWtoD(Win,y1),xWtoD(Win,x2),yWtoD(Win,y2),Depth,Top);
END;{PROC wBar3D}


PROCEDURE PolywToD(VAR Win:gWindow; NumPoints:Word;
                   VAR wPolyPoints; VAR dPolyPoints);
CONST
  PolyMax = 1000;
TYPE
  wp = ARRAY[1..PolyMax] OF RECORD
                              x,y : Float;
                            END;
  dp = ARRAY[1..PolyMax] OF RECORD
                              x,y : Integer;
                            END;
VAR
  i : Integer;
BEGIN
  FOR i:=1 TO NumPoints
  DO BEGIN
    dp(dPolyPoints)[i].x:=xWtoD(Win,wp(wPolyPoints)[i].x);
    dp(dPolyPoints)[i].y:=yWtoD(Win,wp(wPolyPoints)[i].y);
  END;
END;{PolywToD}

PROCEDURE wDrawPoly(VAR Win:gWindow; NumPoints:Word; VAR wPolyPoints);
VAR
  dPolyPoints : Pointer;
BEGIN
  GetMem(dPolyPoints,2*NumPoints);
  PolywToD(Win,NumPoints,wPolyPoints,dPolyPoints^);
  DrawPoly(NumPoints,dPolyPoints^);
  FreeMem(dPolyPoints,2*NumPoints);
END;{wDrawPoly}

PROCEDURE wFillPoly(VAR Win:gWindow; NumPoints:Word; VAR wPolyPoints);
VAR
  dPolyPoints : Pointer;
BEGIN
  GetMem(dPolyPoints,2*NumPoints);
  PolywToD(Win,NumPoints,wPolyPoints,dPolyPoints^);
  FillPoly(NumPoints,dPolyPoints^);
  FreeMem(dPolyPoints,2*NumPoints);
END;{wFillPoly}

PROCEDURE DoTextBlackOut(x,y:Word; txt:String);
VAR
  w,h,c,bc : Word;
  txtSet   : TextSettingsType;
BEGIN
{  GetTextSettings(TxtSet);}
  w:=TextWidth(txt); h:=TextHeight(txt);
  CASE TxtSet.Horiz OF
    CenterText : x:=x-(w div 2);
    RightText  : x:=x-w;
  END;
  CASE TxtSet.Vert OF
    CenterText : y:=y-(h div 2);
    BottomText : y:=y-h;
  END;
  c:=GetColor;
  bc:=GetBkColor;
  SetColor(bc);
  SetFillStyle(SolidFill,bc);
  Bar(x,y,x+w,y+h);
  SetColor(c);
END;{DoTextBlackOut}

PROCEDURE TextXY{(x,y:Integer,txt:String)};
VAR
  over  : String;
  i,l   : Byte;
BEGIN
  over:=txt;
  l:=Byte(txt[0]);
  FOR i:=1 TO l DO
  CASE txt[i] OF
       'õ' : BEGIN
               txt[i]:='o'; over[i]:='/';
             END;
       'ù' : BEGIN
               txt[i]:='O'; over[i]:='/';
             END;
        ELSE over[i]:={#32} Txt[i];
  END;
  IF TextBlackOut THEN DoTextBlackOut(x,y,txt);
  OutTextXY(x,y,txt);
  OutTextXY(x,y,over);
END;{TextXY}

PROCEDURE wText{(VAR Win:gWindow; x,y:Float; theText:string)};
BEGIN
  TextXY(xWtoD(Win,x),yWtoD(Win,y),theText);
END;{wText}

PROCEDURE xScale{(VAR Win:gWindow; LineStyle,ScaleColor:Word)};
VAR
  n       : LongInt;
  i,nd    : Integer;
  minim,
  dlr,y,x : Real;
  xd      : Word;
  st      : string[8];
BEGIN{xScales}
  WITH Win DO
  BEGIN { Draw the x-axis scale ... }
    x:=w.max.x-w.min.x; i:=0;
    REPEAT
      inc(i); dlr:=ScaleFactor[i]; n:=Round(x/dlr);
    UNTIL n<15;
    minim:=trunc(w.min.x/dlr)*dlr;
    SetLineStyle(UserBitLn,LineStyle,1);
    SetTextJustify(CenterText,TopText); TextBlackOut:=True;
    FOR i:=0 TO n DO
    BEGIN
      x:=minim+(dlr*i); xd:=xWtoD(Win,x);
      IF (xd<=Win.d.max.x) and (xd>=Win.d.min.x) THEN
      BEGIN
       SetColor(Yellow);
       str(x/xsf:0:0,st); xd:=xWtoD(Win,x);
       OutTextXY(xd,d.max.y+2,st);
       SetColor(ScaleColor);
       Line(xd,d.min.y,xd,d.max.y);
       PutPixel(xd,succ(d.max.y),Yellow);
      END;
    END;
    SetLineStyle(SolidLn,0,1);
    Line(d.min.x,d.max.y,d.max.x,d.max.y);
  END;
END;{xScale}

PROCEDURE yScale{(VAR Win:gWindow; LineStyle,ScaleColor:Word)};
VAR
  n       : LongInt;
  i,nd    : Integer;
  minim,
  dlr,y,x : Real;
  yd      : Word;
  st      : string[8];
BEGIN
  WITH Win DO
  BEGIN { draw the y-axis scale ... }
    y:=w.max.y-w.min.y; i:=0;
    REPEAT
      inc(i); dlr:=ScaleFactor[i]; n:=Round(y/dlr);
      yd:=yWtoD(Win,dlr)-yWtoD(Win,2*dlr);
    UNTIL (n<20) and (yd>10);
    minim:=trunc(w.min.y/dlr)*dlr;
    IF Frac(dlr/ysf)=0 THEN nd:=0 ELSE nd:=1;
    SetLineStyle(UserBitLn,LineStyle,1);
    SetTextJustify(RightText,CenterText); TextBlackOut:=False;
    FOR i:=0 TO n DO
    BEGIN {$R-}
      y:=minim+(dlr*i); yd:=yWtoD(Win,y);
      IF (yd<=Win.d.max.y) and (yd>=Win.d.min.y) THEN
      BEGIN
        SetColor(Yellow);
        str(y/ysf:0:nd,st);
        TextXY(pred(Win.d.min.x),yd,st);
        SetColor(ScaleColor);
        Line(d.min.x,yd,d.max.x,yd);
        PutPixel(Pred(d.min.x),yd,Yellow);
      END;
    END;
    SetLineStyle(SolidLn,0,1);
    Line(d.min.x,d.min.y,d.min.x,d.max.y);
  END;
END;{yScale}

PROCEDURE gScrDump{(DumpColors:ByteSet)};
CONST
  exp2 : ARRAY[0..7] OF byte = (128,64,32,16,8,4,2,1);
VAR
  c    : byte;
  x,xx,
  yy,z : word;
  y    : ARRAY[0..7] OF Word;
  ddx,
  ddy  : Float;
BEGIN
  ddx:=succ(Graphics.Xmax)/960;   { 960 / (640/480) / (120/72) = 432 }
  ddy:=succ(Graphics.Ymax)/432;   {  X     max CRT      PRT       Y  }
  Print(#27#51#24);               { LineSpacing 24/216" = 8/72" }
  yy:=0;
  REPEAT
    Print(#27#89#192#03); { GraphMode 120*72 DPI = 960 dots pr.line}
    xx:=0;
    FOR z:=0 TO 7 DO y[z]:=Round((yy+z)*ddy);
    REPEAT
      c:=0; x:=round(xx*ddx);
      FOR z:=0 TO 7 DO
       IF GetPixel(x,y[z]) IN dumpColors THEN c:=c+exp2[z];
      Print(char(c));
      inc(xx);
    UNTIL (xx=960) or Boolean(PrintStat and PrtIOerror);
    CASE PrinterType OF
      IBM   : Print(^M^J);
      Epson : Print(^M);
      ELSE Print(^M^J);
    END;
    yy:=yy+8;
  UNTIL (yy>432) or Boolean(PrintStat and PrtIOerror);
  Print(#27#50);
END;{gScrDump}

PROCEDURE tScrDump{(uy,ly:Byte)};
{ - Dump textscreen, lines uy..ly, to printer}
Type
  scr = Array[1..25,1..80,1..2] OF Byte;
VAR
  x,y,i  : Byte;
  ScrPtr : Pointer;
  ch     : Byte;
BEGIN
  ScrPtr:=Ptr(ScreenSeg,0);
  FOR y:=uy to ly DO
  BEGIN
    x:=80;
    REPEAT
      dec(x);
      ch:=scr(ScrPtr^)[y,x,1];
    UNTIL (ch in [33..255]) or (x=0);
    IF x<>0 THEN
    BEGIN
      FOR i:=1 TO x DO
      BEGIN
        ch:=scr(ScrPtr^)[y,i,1]; IF ch=0 THEN ch:=32;
        print(char(ch));
      END;
    END;
    PrintLn('');
  END;
END;{tScrDump}

PROCEDURE SplitEGA(SplitLine:Integer); ASSEMBLER;
ASM
         MOV  AX,040h
         MOV  ES,AX
         MOV  DX,ES:[063h]
         MOV  AX,SplitLine
         MOV  BH,AH
         AND  BH,1
         SHL  BH,4
         MOV  AH,AL
         MOV  AL,18h
         OUT  DX,AX
         MOV  AH,1Fh { 1Fh=640 x 350, 11h = 320,640 x 200}
         AND  AH,11101111b
         OR   AH,BH
         MOV  AL,7
         OUT  DX,AX
END; {PROC SplitEGA}


PROCEDURE SplitVGA(SplitLine:Integer); ASSEMBLER;
ASM
         MOV  AX,040h
         MOV  ES,AX
         MOV  DX,ES:[063h]
         MOV  AX,SplitLine
         MOV  BH,AH
         AND  BL,BH
         AND  BX,0201
         SHL  BX,4
         SHL  BH,1
         MOV  AH,AL
         MOV  AL,18h
         OUT  DX,AX
         MOV  AL,7
         OUT  DX,AL
         INC  DX
         IN   AL,DX
         DEC  DX
         MOV  AH,AL
         AND  AH,11101111b
         OR   AH,BL
         MOV  AL,7
         OUT  DX,AX
         MOV  AL,9
         OUT  DX,AL
         INC  DX
         IN   AL,DX
         DEC  DX
         MOV  AH,AL
         AND  AH,11101111b
         OR   AH,BL
         MOV  AL,9
         OUT  DX,AX
END; {PROC SplitVGA}

PROCEDURE SplitScreen(SplitLine:Integer);
BEGIN
{  CASE Graphics.Mode OF
    EGAhi : SplitEGA(SplitLine);
    VGAhi : SplitVGA(SplitLine);
  END;}
  SplitProc(SplitLine);
END;{SplitScreen}



PROCEDURE GetGraphInfo{(VAR Info:DeviceInfo)};
BEGIN
  WITH Info DO
  BEGIN
    Device:=Detect;
    DetectGraph(Device,Mode);
    GetModeRange(Device,LoMode,HiMode); Mode:=HiMode;
    CASE Device OF
      CGA      : BEGIN Xmax:=639; Ymax:=199; Cmax:=1; END;
      MCGA     : BEGIN Xmax:=639; Ymax:=479; Cmax:=1; END;
      EGA,EGA64,
      EGAMono  : BEGIN Xmax:=639; Ymax:=349; Cmax:=15; END;
      HercMono : BEGIN Xmax:=719; Ymax:=347; Cmax:=1; END;
      ATT400   : BEGIN Xmax:=639; Ymax:=399; Cmax:=1; END;
      VGA      : BEGIN Xmax:=639; Ymax:=479; Cmax:=15; END;
      PC3270   : BEGIN Xmax:=719; Ymax:=349; Cmax:=15; END;
    END;
  END;
END;{GetGraphInfo}

FUNCTION OpenGraph:boolean;
BEGIN
  WITH Graphics DO
  BEGIN
    Device:=Detect;
    InitGraph(Device,Mode,LFSystem.Path);
    Error:=GraphResult;
    IF Error <> grOK THEN
    BEGIN
      writeln('Problem : ',GraphErrorMsg(Error));
      OpenGraph:=false;
    END
    ELSE WITH Graphics
    DO BEGIN
        SetFont(@CP865VGAfont,8,16);
        GraphPossible:=True;
        GetGraphInfo(Graphics);
        IF Graphics.Device=VGA
         THEN SplitProc:=SplitVGA
          ELSE SplitProc:=SplitEGA;
        InitWin(NormalWin);
        PageOriginOffset:=0;
        OpenGraph:=true;
        Xmax:=GetMaxX;
        Ymax:=GetMaxY;
        Cmax:=GetMaxColor;
        InitWin(NormalWin);
        MixPal(Win3Pal);
    END;
  END;
END;{OpenGraph}


{--- Bitmap block routines (Replacements for Get/PutImage ------------------}
CONST
  BytesPerRow  = 80;        { Bytes in one horizontal line }
  VideoBufSeg  : Word = $A000; { Gfx mode video buffer segment start adr.}
  ByteOfsShift = 3;         { Reflects # of pixels per byte }


PROCEDURE PixelAdr; NEAR; ASSEMBLER;
{ - Calculate adress of pixel in Video Buffer
  Expects:
    ax = Y
    bx = X
  Returns:
    es:bx = Byte offset in VideoBuf of (x,y)
    cl    = Shift
}
ASM
  mov  cl,bl                   { Copy msb of X to cl }
  mov  dx,BytesPerRow          { AX = Y (AX) * BytesPerRow (DX)}
  mul  dx
  shr  bx,3                    { X:=X DIV 8 }
  add  bx,ax                   { BX:=Y*BytesPerRow+(X DIV 8) }
{  add  bx,PageOriginOffset     { Add Page Origin offset (for video pages)}
  mov  ax,[VideoBufSeg]
  mov  es,ax                   { ES:=Video Buffer Segment }
  and  cl,7                    { CL:=CL MOD 8 }
  xor  cl,7                    { CL:=NOT CL }
END; {PROC ASM PixelAdr}

PROCEDURE GetPBlock(LX,UY,RX,LY:Integer; VAR BitMap); {FAR;}
VAR
  Rows,
  RowLen:Word;
BEGIN
  ASM
         push ds
         mov  ax,RX
         sub  ax,LX
         mov  cx,0FF07h
         and  cl,al
         xor  cl,7
         shl  ch,cl
         mov  cl,ch
         push cx
         shr  ax,ByteOfsShift
         inc  ax
         push ax

         mov  ax,LY
         sub  ax,UY
         inc  ax
         push ax

         mov  ax,UY
         mov  bx,LX
         call PixelAdr
         xor  cl,7
         push es
         pop  ds
         mov  si,bx
         les  di,BitMap

         pop  ax
         mov  Rows,ax
         stosw
         pop  ax
         mov  RowLen,ax
         stosw
         pop  ax
         mov  ch,al
         stosb

         mov  dx,03CEh
         mov  ax,0005
         out  dx,ax
         mov  ax,0304h

@@NxtPln:  out  dx,ax
           push ax
           push Rows
           push si
  @@NxtRow:  mov  bx,RowLen
             push si
    @@NxtByt:  lodsw
               dec  si
               rol  ax,cl
               stosb
               dec  bx
             jnz @@NxtByt
             and  es:[di-1],ch
             pop  si
             add  si,BytesPerRow
             dec  Rows
           jnz @@NxtRow
           pop si
           pop Rows
           pop ax
           dec ah
         jns @@NxtPln
         pop  ds
  END;
END; {PROC GetPBlock}

PROCEDURE PutPBlock(lx,uy:Integer; VAR BitMap; PMode:Word);
VAR
  Rows,
  RowLen,
  RowCount,
  StartMask,
  EndMaskR,
  EndMaskL:Word;
BEGIN
  ASM
         push ds

         mov  ax,UY
         mov  bx,LX
         call PixelAdr             { ES:BX -> Byte offset of (LX,UY) }
         inc  cl
         and  cl,7                 { CL := Number of bits to SHL }
         mov  di,bx                { ES:DI := ES:BX }
         lds  si,BitMap            { DS:SI := Start of buffer }

         lodsw                     { Fetch Stored Rows }
         mov  Rows,ax
         lodsw                     { Fetch Stored RowLen }
         mov  RowLen,ax
         lodsb                     { Fetch Bitmask for last byte in Row }
         mov  ch,al

         mov  dx,03CEh             { DX := Graphics Controller I/O port }
         mov  ax,PMode             { Load value for Data Rotate/Function }
         mov  ah,al
         and  al,1                 { Swap Xor and And... }
         jz   @@NoSwap             { To allow use of TP Graph Constants }
         xor  ah,2                 { AndPut or XorPut }
@@NoSwap:shl  ah,3                 { Move it to the correct position }
         and  ah,18h               { Allow only 00000b,01000b,10000b,11000b }
         mov  al,3                 { Select Register 3 (Data Rot./Fun.) }
         out  dx,ax                { Update it ! }

         mov  ax,0805h             { ah = R.mode 1 / W.mode 0, al = reg.5 }
         out  dx,ax                { Update R/W mode register }

         mov  ax,0007              { ah = Don't care for all maps }
         out  dx,ax                { CPU reads always return 0FFh }

         mov  ax,0FF08h            { Set up Bitmask reg (8) to 0FFh }
         out  dx,ax

         mov  dl,0C4h              { DX:=03C4h (Sequencer I/O port) }
         mov  ax,0802h             { ah=1000b=Map Mask, al=Map Mask Reg.}

         cmp  cx,0FF00h            { IF mask<>0FFh or bits to shift<>0 }
         jne  @@NoAlign            { jump if not byte-aligned }

{--- Routine for byte-aligned blocks ---------------------------------}

         mov  cx,RowLen
@@NxtAP:   out  dx,ax              { Enable one bitplane for write }
           push ax                 { Store Map Mask value }
           push di                 { and video buffer offset }
           mov  bx,Rows
@@NxtAR:     push di               { Preserve cx and di }
             push cx
@@NxtAB:       lodsb               { Fetch next byte of pixels }
               and es:[di],al      { update bitplane (and = Read, then Write) }
               inc di
             loop @@NxtAB          { Repeat for the whole row }
             pop  cx               { Restore cx and di }
             pop  di
             add  di,BytesPerRow   { move offset to next row }
             dec  bx               { One row less to go }
           jnz  @@NxtAR            { Repeat until all rows done }
           pop  di                 { Restore original offset }
           pop  ax                 { and mask value }
           shr  ah,1               { Shift to next bitplane }
         jnz  @@NxtAP              { Repeat until all four bitplanes are done}

         jmp  @@Exit

{--- Routines for non-aligned blocks --------------------------------}

@@NoAlign:
         push ax                   { Preserve Map Mask }
         mov  bx,0FFh              { BH:=Mask for first byte in row }
         mov  al,ch                { AL:=Mask for last byte in Row }
         cbw                       { Extend AL to AH (Byte to Word) }
         cmp  RowLen,1
         jne  @@More               { Jump if more than one pixel per row }

         mov  bl,ch
         mov  ah,ch                { AH:=Mask for last-1 byte }
         xor  al,al                { AL:=0 (mask for last byte) }

@@More:  shl  ax,cl                { Shift masks into position }
         shl  bx,cl
         mov  bl,al                { Save masks ... together with }
         mov  al,8                 { bitmask register no }
         mov  EndMaskL,ax
         mov  ah,bl
         mov  EndMaskR,ax
         mov  ah,bh
         mov  StartMask,ax

         mov  bx,RowLen
         pop  ax                   { Restore Map Mask reg values }

@@NxtNAP:  out  dx,ax              { Enable one bitplane for write }
           push ax
           push di
           mov  dl,0CEh            { DX:=03CEh (Graphics controller port) }
           mov  ax,Rows
           mov  RowCount,ax        { Initialize loop counter }
@@NxtRS:     push di               { Preserve offset of start of pixel row }
             push si               { Preserver offset of row in bitblock }
             push bx               { Preserve bytes per pixel row }
             mov  ax,StartMask
             out  dx,ax            { Set bitmask for first byte of row }

             lodsw                 { AH = 2nd byte of pixels, AL = 1st }
             dec  si               { SI:= 2nd byte of pixels }
             test cl,cl
             jnz  @@NLA            { Jump if not left-aligned }

             dec  bx               { BX:= Bytes Per Row - 1 }
             jnz  @@M2B            { Jump if at least two bytes per row }
             jmp  @@EoRow          { Jump if only one byte per row }

@@NLA:       rol  ax,cl            { AH:=Left part of 1st byte, Right part of 2nd byte }
             and  es:[di],ah
             inc  di
             dec  bx

@@M2B:       push ax
             mov  ax,0FF08h
             out  dx,ax
             pop  ax
             dec  bx
             jng  @@EoRow
@@MoRow:       and  es:[di],al
               inc  di
               lodsw
               dec  si
               rol  ax,cl
               dec  bx
             jnz  @@MoRow
@@EoRow:     mov  bx,ax
             mov  ax,EndMaskL
             out  dx,ax
             and  es:[di],bl
             mov  ax,EndMaskR
             out  dx,ax
             and  es:[di+1],bh
             pop  bx
             pop  si
             add  si,bx
             pop  di
             add  di,BytesPerRow
             dec  RowCount
           jnz  @@NxtRS
           pop  di
           pop  ax
           mov  dl,0C4h
           shr  ah,1
         jnz  @@NxtNAP

@@Exit:  mov  ax,0F02h
         out  dx,ax
         mov  dl,0CEh
         mov  ax,0003
         out  dx,ax
         mov  ax,0005
         out  dx,ax
         mov  ax,0F07h
         out  dx,ax
         mov  ax,0FF08h
         out  dx,ax

         pop  ds
  END;
END; {PROC PutPBlock}

PROCEDURE GetBlock(LX,UY,RX,LY:Integer; VAR BitMap); {FAR;}
{ - GetBlock2 stores the block into a buffer
    Storage: Ln0/Pln0,Ln0/Pln1,Ln0/Pln2,Ln0/Pln3,Ln1/Pln0,Ln1/Pln1, etc. }
VAR
  Rows   : Word;
  RowLen : Word;
BEGIN
  ASM
         push ds        { Save DS }
         mov  ax,RX     { Calculate width of block }
         sub  ax,LX
         mov  cx,0FF07h
         and  cl,al
         xor  cl,7
         shl  ch,cl
         mov  cl,ch
         push cx
         shr  ax,ByteOfsShift
         inc  ax
         push ax

         mov  ax,LY
         sub  ax,UY
         inc  ax
         push ax

         mov  ax,UY
         mov  bx,LX

         call PixelAdr
         xor  cl,7
         push es
         pop  ds
         mov  si,bx
         les  di,BitMap
         cld
         pop  ax
         mov  Rows,ax
         stosw
         pop  ax
         mov  RowLen,ax
         stosw
         pop  ax
         mov  ch,al
         stosb

         mov  dx,03CEh
         mov  ax,0005
         out  dx,ax

@@NxtRow:  push si
           mov  ax,0304h
  @@NxtPln:  out  dx,ax
             mov  bx,RowLen
             push ax
             push si
    @@NxtByt:  lodsw
               dec  si
               rol  ax,cl
               stosb
               dec  bx
             jnz @@NxtByt
             and  es:[di-1],ch
             pop  si
             pop  ax
             dec  ah
           jns @@NxtPln
           pop  si
           add  si,BytesPerRow
           dec  Rows
         jnz @@NxtRow
         pop  ds
  END;
END; {PROCEDURE GetBlock}


PROCEDURE PutBlock(lx,uy:Integer; VAR BitMap; PMode:Word);
VAR
  Rows,
  RowLen,
  StartMask,
  EndMaskR,
  EndMaskL : Word;
BEGIN
  ASM
         push ds             {    Save Initial value of DS}

         mov  ax,UY
         mov  bx,LX

         call PixelAdr             { ES:BX -> Byte offset of (LX,UY) }

         inc  cl
         and  cl,7                 { CL := Number of bits to SHL }
         mov  di,bx                { ES:DI := ES:BX }
         lds  si,BitMap            { DS:SI := Start of buffer }
         cld
         lodsw                     { Fetch Stored Rows }
         mov  Rows,ax
         lodsw                     { Fetch Stored RowLen }
         mov  RowLen,ax
         lodsb                     { Fetch Bitmask for last byte in Row }
         mov  ch,al

         mov  dx,03CEh             { DX := Graphics Controller I/O port }
         mov  ax,PMode             { Load value for Data Rotate/Function }
         mov  ah,al
         test al,1                 { Swap Xor and And... }
         jz   @@NoSwap             { to allow use of TP Graph Constants }
         xor  ah,2                 { AndPut or XorPut }
@@NoSwap:shl  ah,3                 { Move it to the correct position }
         and  ah,18h               { Allow only 00000b,01000b,10000b,11000b }
         mov  al,3                 { Select Register 3 (Data Rot./Fun.) }
         out  dx,ax                { Update it ! }

         mov  ax,0805h             { ah = R.mode 1 / W.mode 0, al = reg.5 }
         out  dx,ax                { Update R/W mode register }

         mov  ax,0007              { ah = Don't care for all maps }
         out  dx,ax                { CPU reads always return 0FFh }

         mov  ax,0FF08h            { Set up Bitmask reg (8) to 0FFh }
         out  dx,ax

         mov  dl,0C4h              { DX:=03C4h (Sequencer I/O port) }

         cmp  cx,0FF00h            { IF mask<>0FFh or bits to shift<>0 }
         jne  @@NoAlign            { jump if not byte-aligned }

{--- Routine for byte-aligned blocks ---------------------------------}

@@NxtAR:   mov  ax,0802h           { ah=1000b=Map Mask, al=Map Mask Reg. }
  @@NxtAP:   out  dx,ax            { Enable one bitplane for write }
             push ax               { Store Map Mask value }
             mov  bx,di            { and video buffer offset }
             mov  cx,RowLen
    @@NxtAB:   lodsb               { Fetch next byte of pixels }
               and es:[di],al      { update bitplane (and = Read, then Write) }
               inc di
             loop @@NxtAB          { Repeat for the whole row }
             mov  di,bx            { Restore last offset }
             pop  ax               { and mask value }
             shr  ah,1             { Shift to next bitplane }
           jnz  @@NxtAP            { Repeat until all four bitplanes are done }
           add  di,BytesPerRow     { move offset to next row }
           dec  Rows               { One row less to go }
         jnz  @@NxtAR              { Repeat until all rows done }
{-------------------------------------------------------------------- }
         jmp  @@Exit

{--- Routines for non-aligned blocks --------------------------------}

@@NoAlign:
         mov  bx,0FFh              { BH:=Mask for first byte in row }
         mov  al,ch                { AL:=Mask for last byte in Row }
         cbw                       { Extend AL to AH (Byte to Word) }
         cmp  RowLen,1
         jne  @@More               { Jump if more than one pixel per row }

         mov  bl,ch
         mov  ah,ch                { AH:=Mask for last-1 byte   }
         xor  al,al                { AL:=0 (mask for last byte) }

@@More:  shl  ax,cl                { Shift masks into position }
         shl  bx,cl
         mov  bl,al                { Save masks ... together with }
         mov  al,8                 { bitmask register no }
         mov  EndMaskL,ax
         mov  ah,bl
         mov  EndMaskR,ax
         mov  ah,bh
         mov  StartMask,ax

         mov  bx,RowLen
@@NxtRow:  push di
           mov  ax,0802h
  @@NxtPln:  out  dx,ax
             push ax
             push bx
             push di
             push si
             mov  ax,StartMask
             mov  dl,0CEh
             out  dx,ax
             lodsw
             dec si
             test cl,cl
             jnz  @@NLA
             dec  bx
             jnz  @@M2B
             jmp  @@EoRow
    @@NLA:   rol  ax,cl
             and  es:[di],ah
             inc  di
             dec  bx
    @@M2B:   push ax
             mov  ax,0FF08h
             out  dx,ax
             pop  ax
             dec  bx
             jng  @@EoRow
    @@MoRow:   and  es:[di],al
               inc  di
               lodsw
               dec  si
               rol  ax,cl
               dec  bx
             jnz  @@MoRow
    @@EoRow: mov  bx,ax
             mov  ax,EndMaskL
             out  dx,ax
             and  es:[di],bl
             mov  ax,EndMaskR
             out  dx,ax
             and  es:[di+1],bh
             mov  dl,0C4h
             pop  si
             pop  di
             pop  bx
             pop  ax
             add  si,bx
             shr  ah,1
           jnz @@NxtPln
           pop  di
           add  di,BytesPerRow
           dec  Rows
         jnz  @@NxtRow

@@Exit:  mov  ax,0F02h
         out  dx,ax
         mov  dl,0CEh
         mov  ax,0003
         out  dx,ax
         mov  ax,0005
         out  dx,ax
         mov  ax,0F07h
         out  dx,ax
         mov  ax,0FF08h
         out  dx,ax

         pop  ds
  END;
END;{PROC PutBlock}

{###########################################################################}
{--- Optimized solid bar routines ------------------------------------------}

PROCEDURE Block(LX,UY,RX,LY,Col:Integer);
VAR
  Rows,
  RowLen,
  StartMask,
  EndMaskR,
  EndMaskL : Word;
BEGIN
  ASM
         push ds        { Save DS }

         mov  ax,LY     { calculate height of block }
         sub  ax,UY
         inc  ax
         mov  Rows,ax

         mov  ax,RX     { Calculate width of block }
         sub  ax,LX
         mov  cx,0FF07h
         and  cl,al
         xor  cl,7
         shl  ch,cl
         mov  cl,ch
         push cx               {>}
         shr  ax,ByteOfsShift
         inc  ax
         mov  RowLen,ax

         mov  ax,UY
         mov  bx,LX

         call PixelAdr
         inc  cl
         and  cl,7                 { CL := Number of bits to SHL }
         mov  di,bx

         cld
         pop  ax        {<}
         mov  ch,al                {ch := bitmask of last byte in line}

         mov  dx,03CEh             { DX := Graphics Controller I/O port }

         mov  ax,PutMode           { Load value for Data Rotate/Function }
         mov  ah,al
         test al,1                 { Swap Xor and And... }
         jz   @@NoSwap             { to allow use of TP Graph Constants }
         xor  ah,2                 { AndPut or XorPut }
@@NoSwap:shl  ah,3                 { Move it to the correct position }
         and  ah,18h               { Allow only 00000b,01000b,10000b,11000b }
         mov  al,3                 { Select Register 3 (Data Rot./Fun.) }

         out  dx,ax                { Update it ! }

         mov  ax,0A05h             { Modes: R=1, W=2 - 5=Mode Register}
         out  dx,ax                { Set R/W modes}

         mov  ax,0007              { ah = Don't care for all maps }
         out  dx,ax                { CPU reads always return 0FFh }

         mov  ax,0FF08h            { Set up Bitmask reg (8) to 0FFh }
         out  dx,ax

         cld
         push es
         pop  ds
         mov  ax,Col               { al:=color}
         mov  ah,cl                { ah:=bits to shift}
         cmp  cx,0FF00h            { IF mask<>0FFh or bits to shift<>0 }
         jne  @@NoAlign            { jump if not byte-aligned }

{--- Routine for byte-aligned blocks ---------------------------------}
         mov bx,rows
         mov si,BytesPerRow
         sub si,RowLen
@@NxtAL: mov  cx,Rowlen
  @@NxtB: and [di],al
          inc di
          loop @@NxtB
         add di,si
         dec bx
         jnz @@NxtAL             { Repeat for each line }

{-------------------------------------------------------------------- }
         jmp  @@Exit

{--- Routines for non-aligned blocks --------------------------------}

@@NoAlign:
         push ax
         mov  bx,0FFh              { BH:=Mask for first byte in line }
         mov  al,ch                { AL:=Mask for last byte in line }
         cbw                       { Extend AL to AH (Byte to Word) }
         cmp  RowLen,1
         jne  @@More               { Jump if more than one pixel in line }

         mov  bl,ch
         mov  ah,ch                { AH:=Mask for last-1 byte   }
         xor  al,al                { AL:=0 (mask for last byte) }

@@More:  shl  ax,cl                { Shift masks into position }
         shl  bx,cl
         mov  bl,al                { Save masks ... together with }
         mov  al,8                 { bitmask register no }
         mov  EndMaskL,ax
         mov  ah,bl
         mov  EndMaskR,ax
         mov  ah,bh
         mov  startmask,ax
         pop  bx             { bh = Bits to shift, bl = color }
@@NxtRw: push di
         mov  ax,Startmask
         out  dx,ax
         mov  cx,RowLen
         test bh,bh
         jnz  @@NLA
         dec  cx
         jnz  @@M2B
         jmp  @@EoRow
@@NLA:   and  [di],bl    {*}
         inc  di
         dec  cx
@@M2B:   dec  cx
         jng  @@EoRow
         mov  ax,0FF08h
         out  dx,ax
  @@NxtM: and [di],bl    {*}
          inc di
          loop @@NxtM
@@EoRow: mov  ax,EndMaskL
         out  dx,ax
         and  [di],bl    {*}
         mov  ax,EndMaskR
         out  dx,ax
         and  [di+1],bl  {*}
         pop  di
         add  di,BytesPerRow
         dec  rows
         jnz @@NxtRw

@@Exit:  mov  ax,0003
         out  dx,ax
         mov  ax,0005
         out  dx,ax
         mov  ax,0F07h
         out  dx,ax
         mov  ax,0FF08h
         out  dx,ax

         pop  ds
  END;
END; {PROC Block}

{###########################################################################}
{--- Optimized bitplane routines -------------------------------------------}

FUNCTION PlaneSize(x,y,x2,y2:Integer):Word;
{ - Returns bitmap memory usage of a single bitplane w/dim.info.
    Used with PROCEDURE GetPlane. }
VAR
  w,h,BytesPerLine : Integer;
BEGIN
  IF x>x2                       { Swap inverted coords }
  THEN w:=x-x2+1
  ELSE w:=x2-x+1;
  IF y>y2
  THEN h:=y-y2+1
  ELSE h:=y2-y+1;
  BytesPerLine:=w div 8;        { Eight pixels per byte }
  IF w mod 8 <> 0               { Add a byte if there is excess bits }
  THEN inc(BytesPerLine);
  PlaneSize:=Word(5)+(BytesPerLine*h);  { Mem.requ. = 5 + bytes * lines }
END; {FUNC PlaneSize}

PROCEDURE GetPlane(Plane:Byte; LX,UY,RX,LY:Integer; VAR BitMap);
{ - Get a single plane <bitmap> from <Plane> at ((<lx>,<uy>),(<rx>,<ly>))
    (physical size of bitmap is stored in the bitmap, use PlaneSize to
    calculate <BitMap> memory requirements) }
VAR
  Rows,
  RowLen:Word;
BEGIN
  ASM
         push ds
         cld
         mov  ah,Plane
         and  ah,3
         mov  al,4
         push ax         { Store planemask }

         mov  ax,RX      { Calculate dimensions: Width ...}
         sub  ax,LX
         mov  cx,0FF07h  { determine mask }
         and  cl,al
         xor  cl,7
         shl  ch,cl
         mov  cl,ch
         push cx
         shr  ax,ByteOfsShift
         inc  ax
         push ax

         mov  ax,LY     { ... Height }
         sub  ax,UY
         inc  ax
         push ax

         mov  ax,UY      { calc address in video buffer}
         mov  bx,LX
         call PixelAdr
         xor  cl,7
         push es
         pop  ds
         mov  si,bx
         les  di,BitMap
         pop  ax         { Store dimensions and mask }
         mov  Rows,ax
         stosw
         pop  ax
         mov  RowLen,ax
         stosw
         pop  ax
         mov  ch,al
         stosb

         mov  dx,03CEh
         mov  ax,0005
         out  dx,ax

         pop  ax
         out  dx,ax

@@NxtRow:  mov  bx,RowLen
           push si
  @@NxtByt:  lodsw
             dec  si
             rol  ax,cl
             stosb
             dec  bx
           jnz @@NxtByt
           and  es:[di-1],ch
           pop  si
           add  si,BytesPerRow
           dec  Rows
         jnz @@NxtRow

       pop  ds
  END;
END; {PROC GetPlane}

PROCEDURE PutPlane(Plane:Byte; lx,uy:Integer; VAR BitMap; pmode:Word);
{ - Put a single plane <bitmap> into <Plane> at (<lx>,<uy>)
    (Size of bitmap is stored in the bitmap)}
VAR
  Rows,
  RowLen,
  RowCount,
  StartMask,
  EndMaskR,
  EndMaskL:Word;
BEGIN
  ASM
         push ds
         mov  cl,3
         and  plane,3
         sub  cl,plane
         mov  ah,8
         shr  ah,cl
         mov  al,2
         push ax                   { store plane mask }

         mov  ax,UY
         mov  bx,LX
         call PixelAdr             { ES:BX -> Byte offset of (LX,UY) }
         inc  cl
         and  cl,7                 { CL := Number of bits to SHL }
         mov  di,bx                { ES:DI := ES:BX }
         lds  si,BitMap            { DS:SI := Start of buffer }

         lodsw                     { Fetch Stored Rows }
         mov  Rows,ax
         lodsw                     { Fetch Stored RowLen }
         mov  RowLen,ax
         lodsb                     { Fetch Bitmask for last byte in Row }
         mov  ch,al

         mov  dx,03CEh             { DX := Graphics Controller I/O port }
         mov  ax,PMode             { Load value for Data Rotate/Function }
         mov  ah,al
         and  al,1                 { Swap Xor and And... }
         jz   @@NoSwap             { To allow use of TP Graph Constants }
         xor  ah,2                 { AndPut or XorPut }
@@NoSwap:shl  ah,3                 { Move it to the correct position }
         and  ah,18h               { Allow only 00000b,01000b,10000b,11000b }
         mov  al,3                 { Select Register 3 (Data Rot./Fun.) }
         out  dx,ax                { Update it ! }

         mov  ax,0805h             { ah = R.mode 1 / W.mode 0, al = reg.5 }
         out  dx,ax                { Update R/W mode register }

         mov  ax,0007              { ah = Don't care for all maps }
         out  dx,ax                { CPU reads always return 0FFh }

         mov  ax,0FF08h            { Set up Bitmask reg (8) to 0FFh }
         out  dx,ax

         mov  dl,0C4h              { DX:=03C4h (Sequencer I/O port) }
         pop  ax                   { ah=Map Mask, al=Map Mask Reg.}
         out  dx,ax

         cmp  cx,0FF00h            { IF mask<>0FFh or bits to shift<>0 }
         jne  @@NoAlign            { jump if not byte-aligned }

{--- Routine for byte-aligned blocks ---------------------------------}

         mov  cx,RowLen
         mov  bx,Rows
@@NxtAR:   push di               { Preserve cx and di }
           push cx
@@NxtAB:     lodsb               { Fetch next byte of pixels }
             and es:[di],al      { update bitplane (and = Read, then Write) }
             inc di
           loop @@NxtAB          { Repeat for the whole row }
           pop  cx               { Restore cx and di }
           pop  di
           add  di,BytesPerRow   { move offset to next row }
           dec  bx               { One row less to go }
         jnz  @@NxtAR            { Repeat until all rows done }
         jmp  @@Exit

{--- Routines for non-aligned blocks --------------------------------}

@@NoAlign:
         mov  bx,0FFh              { BH:=Mask for first byte in row }
         mov  al,ch                { AL:=Mask for last byte in Row }
         cbw                       { Extend AL to AH (Byte to Word) }
         cmp  RowLen,1
         jne  @@More               { Jump if more than one pixel per row }

         mov  bl,ch
         mov  ah,ch                { AH:=Mask for last-1 byte }
         xor  al,al                { AL:=0 (mask for last byte) }

@@More:  shl  ax,cl                { Shift masks into position }
         shl  bx,cl
         mov  bl,al                { Save masks ... together with }
         mov  al,8                 { bitmask register no }
         mov  EndMaskL,ax
         mov  ah,bl
         mov  EndMaskR,ax
         mov  ah,bh
         mov  StartMask,ax

         mov  bx,RowLen

         mov  dl,0CEh            { DX:=03CEh (Graphics controller port) }
         mov  ax,Rows
         mov  RowCount,ax        { Initialize loop counter }
@@NxtRS:   push di               { Preserve offset of start of pixel row }
           push si               { Preserver offset of row in bitblock }
           push bx               { Preserve bytes per pixel row }
           mov  ax,StartMask
           out  dx,ax            { Set bitmask for first byte of row }

           lodsw                 { AH = 2nd byte of pixels, AL = 1st }
           dec  si               { SI:= 2nd byte of pixels }
           test cl,cl
           jnz  @@NLA            { Jump if not left-aligned }

           dec  bx               { BX:= Bytes Per Row - 1 }
           jnz  @@M2B            { Jump if at least two bytes per row }
           jmp  @@EoRow          { Jump if only one byte per row }

@@NLA:     rol  ax,cl            { AH:=Left part of 1st byte, Right part of 2nd byte }
           and  es:[di],ah
           inc  di
           dec  bx

@@M2B:     push ax
           mov  ax,0FF08h
           out  dx,ax
           pop  ax
           dec  bx
           jng  @@EoRow
@@MoRow:     and  es:[di],al
             inc  di
             lodsw
             dec  si
             rol  ax,cl
             dec  bx
           jnz  @@MoRow
@@EoRow:   mov  bx,ax
           mov  ax,EndMaskL
           out  dx,ax
           and  es:[di],bl
           mov  ax,EndMaskR
           out  dx,ax
           and  es:[di+1],bh
           pop  bx
           pop  si
           add  si,bx
           pop  di
           add  di,BytesPerRow
           dec  RowCount
         jnz  @@NxtRS

@@Exit:  mov  dl,0C4h
         mov  ax,0F02h
         out  dx,ax
         mov  dl,0CEh
         mov  ax,0003
         out  dx,ax
         mov  ax,0005
         out  dx,ax
         mov  ax,0F07h
         out  dx,ax
         mov  ax,0FF08h
         out  dx,ax

         pop  ds
  END;
END; {PROC PutPlane}

PROCEDURE Paint(lx,uy,Color:Integer; VAR BitMap; PMode:Word);
{ - Uses a single plane bitmap to "paint" it's pattern using <Color> }
VAR
  Rows,
  Columns,
  RowLen : Word;
  StartMask,
  EndMaskR,
  EndMaskL:Byte;
BEGIN
  ASM
         push ds
         cld

         mov  bx,Color
         push bx
         mov  ax,UY
         mov  bx,LX
         call PixelAdr             { ES:BX -> Byte offset of (LX,UY) }
         inc  cl
         and  cl,7                 { CL := Number of bits to SHL }
         mov  di,bx                { ES:DI := ES:BX }
         lds  si,BitMap            { DS:SI := Start of buffer }

         lodsw                     { Fetch Stored Rows }
         mov  Rows,ax
         lodsw                     { Fetch Stored RowLen }
         mov  RowLen,ax
         lodsb                     { Fetch Bitmask for last byte in Row }
         mov  ch,al

         mov  dx,03CEh             { DX := Graphics Controller I/O port }
         mov  ax,PMode             { Load value for Data Rotate/Function }
         mov  ah,al
         and  al,1                 { Swap Xor and And... }
         jz   @@NoSwap             { To allow use of TP Graph Constants }
         xor  ah,2                 { AndPut or XorPut }
@@NoSwap:shl  ah,3                 { Move it to the correct position }
         and  ah,18h               { Allow only 00000b,01000b,10000b,11000b }
         mov  al,3                 { Select Register 3 (Data Rot./Fun.) }
         out  dx,ax                { Update it ! }

         mov  ax,0A05h             { ah = R.mode 1 / W.mode 2, al = reg.5 }
         out  dx,ax                { Update R/W mode register }

         mov  ax,0007              { ah = Don't care for all maps }
         out  dx,ax                { CPU reads always return 0FFh }

         mov  ax,0FF08h            { Set up Bitmask reg (8) to 0FFh }
         out  dx,ax

         cmp  cx,0FF00h            { Is mask=0FFh and bits to shift=0 }
         jne  @@NoAlign            { No: jump to not byte-aligned op.}

{--- Routine for byte-aligned blocks ---------------------------------}

         mov  cx,RowLen
         pop  bx
@@NxtAR:   push di               { Preserve cx and di }
           push cx
@@NxtAB:     mov ah,[si]            { Fetch next byte of pixels }
             inc si
             out dx,ax
             and es:[di],bl      { update bitplane (and = Read, then Write) }
             inc di
           loop @@NxtAB          { Repeat for the whole row }
           pop  cx               { Restore cx and di }
           pop  di
           add  di,BytesPerRow   { move offset to next row }
           dec  Rows               { One row less to go }
         jnz  @@NxtAR            { Repeat until all rows done }
         jmp  @@Exit

{--- Routines for non-aligned blocks --------------------------------}

@@NoAlign:
         mov  bx,0FFh              { BH:=Mask for first byte in row }
         mov  al,ch                { AL:=Mask for last byte in Row }
         cbw                       { Extend AL to AH (Byte to Word) }
         cmp  RowLen,1
         jne  @@More               { Jump if more than one pixel per row }

         mov  bl,ch
         mov  ah,ch                { AH:=Mask for last-1 byte }
         xor  al,al                { AL:=0 (mask for last byte) }

@@More:  shl  ax,cl                { Shift masks into position }
         shl  bx,cl
         mov  EndMaskL,ah
         mov  EndMaskR,al
         mov  StartMask,bh

         pop  bx
         mov  ch,bl              { ch := color }
         mov  bx,RowLen

         mov  dl,0CEh            { DX:=03CEh (Graphics controller port) }
@@NxtRS:   push di               { Preserve offset of start of pixel row }
           push si               { Preserver offset of row in bitblock }
           push bx               { Preserve bytes per pixel row }

           mov  columns,bx

           mov  al,08

           mov  bx,[si]          { BH = 2nd byte of pixels, BL = 1st }
           inc  si               { SI:= 2nd byte of pixels }
           test cl,cl
           jnz  @@NLA            { Jump if not left-aligned }

           dec  columns          { one less column }

           jnz  @@M2B            { Jump if at least two bytes per row }
           jmp  @@EoRow          { Jump if only one byte per row }

@@NLA:     rol  bx,cl            { AH:=Left part of 1st byte, Right part of 2nd byte }
           mov  ah,bh
           and  ah,StartMask
           out  dx,ax
           and  es:[di],ch
           inc  di
           dec  columns

@@M2B:     dec  columns
           jng  @@EoRow
@@MoRow:     cmp bl,0
             jz @@SkipBlank
             mov ah,bl
             out dx,ax
             and  es:[di],ch
@@SkipBlank: inc  di
             mov  bx,[si]
             inc  si
             rol  bx,cl
             dec  columns
           jnz  @@MoRow
@@EoRow:   and  bl,EndMaskL
           and  bh,EndMaskR
           mov  ah,bl
           out  dx,ax
           and  es:[di],ch
           mov  ah,bh
           out  dx,ax
           and  es:[di+1],ch
           pop  bx
           pop  si
           add  si,bx
           pop  di
           add  di,BytesPerRow
           dec  Rows
         jnz  @@NxtRS

@@Exit:  mov  ax,0003
         out  dx,ax
         mov  ax,0005
         out  dx,ax
         mov  ax,0F07h
         out  dx,ax
         mov  ax,0FF08h
         out  dx,ax

         pop  ds
  END;
END; {PROC Paint}


{###########################################################################}
{--- Optimized linedrawing routines ----------------------------------------}

PROCEDURE hLine(LX,RX,Y,Col:Integer);
VAR
  RowLen,
  EndMaskR,
  EndMaskL : Word;
BEGIN
  ASM
         push ds        { Save DS }
         mov  ax,RX     { Calculate length of line }
         sub  ax,LX
         mov  cx,0FF07h
         and  cl,al
         xor  cl,7
         shl  ch,cl
         mov  cl,ch
         push cx               {>}
         shr  ax,ByteOfsShift
         inc  ax
         mov  RowLen,ax

         mov  ax,Y
         mov  bx,LX

         call PixelAdr
         inc  cl
         and  cl,7                 { CL := Number of bits to SHL }
         mov  di,bx

         cld
         pop  ax        {<}
         mov  ch,al                {ch := bitmask of last byte in line}

         mov  dx,03CEh             { DX := Graphics Controller I/O port }

         mov  ax,PutMode           { Load value for Data Rotate/Function }
         mov  ah,al
         test al,1                 { Swap Xor and And... }
         jz   @@NoSwap             { to allow use of TP Graph Constants }
         xor  ah,2                 { AndPut or XorPut }
@@NoSwap:shl  ah,3                 { Move it to the correct position }
         and  ah,18h               { Allow only 00000b,01000b,10000b,11000b }
         mov  al,3                 { Select Register 3 (Data Rot./Fun.) }

         out  dx,ax                { Update it ! }

         mov  ax,0A05h             { Modes: R=1, W=2 - 5=Mode Register}
         out  dx,ax                { Set R/W modes}

         mov  ax,0007              { ah = Don't care for all maps }
         out  dx,ax                { CPU reads always return 0FFh }

         mov  ax,0FF08h            { Set up Bitmask reg (8) to 0FFh }
         out  dx,ax

         push es
         pop  ds
         mov  ax,Col
         cmp  cx,0FF00h            { IF mask<>0FFh or bits to shift<>0 }
         jne  @@NoAlign            { jump if not byte-aligned }

{--- Routine for byte-aligned lines ----------------------------------}

         mov  cx,RowLen
@@NxtB:  and [di],al
         inc di
         loop @@NxtB

{-------------------------------------------------------------------- }
         jmp  @@Exit

{--- Routines for non-aligned lines ---------------------------------}

@@NoAlign:
         push ax
         mov  bx,0FFh              { BH:=Mask for first byte in line }
         mov  al,ch                { AL:=Mask for last byte in line }
         cbw                       { Extend AL to AH (Byte to Word) }
         cmp  RowLen,1
         jne  @@More               { Jump if more than one pixel in line }

         mov  bl,ch
         mov  ah,ch                { AH:=Mask for last-1 byte   }
         xor  al,al                { AL:=0 (mask for last byte) }

@@More:  shl  ax,cl                { Shift masks into position }
         shl  bx,cl
         mov  bl,al                { Save masks ... together with }
         mov  al,8                 { bitmask register no }
         mov  EndMaskL,ax
         mov  ah,bl
         mov  EndMaskR,ax
         mov  ah,bh
         out  dx,ax
         pop  bx
         test cl,cl
         mov  cx,RowLen
         jnz  @@NLA
         dec  cx
         jnz  @@M2B
         jmp  @@EoRow
@@NLA:   and  [di],bl    {*}
         inc  di
         dec  cx
@@M2B:   dec  cx
         jng  @@EoRow
         mov  ax,0FF08h
         out  dx,ax
         mov  al,bl
@@NxtM:  and  [di],bl
         inc di
         loop @@NxtM
@@EoRow: mov  ax,EndMaskL
         out  dx,ax
         and  [di],bl    {*}
         mov  ax,EndMaskR
         out  dx,ax
         and  [di+1],bl  {*}

@@Exit:  mov  ax,0003
         out  dx,ax
         mov  ax,0005
         out  dx,ax
         mov  ax,0F07h
         out  dx,ax
         mov  ax,0FF08h
         out  dx,ax

         pop  ds
  END;
END; {PROC hLine}


PROCEDURE vLine(X,UY,LY,Col:Integer);
BEGIN
  ASM
         push ds        { Save DS }
         mov  ax,LY     { Calculate height of line }
         sub  ax,UY
         inc  ax
         push ax       {>}
         mov  ax,UY
         mov  bx,X
         call PixelAdr
         mov  di,bx

         mov  bx,Col
         mov  bh,1
         shl  bh,cl

         cld

         mov  dx,03CEh             { DX := Graphics Controller I/O port }

         mov  ax,PutMode           { Load value for Data Rotate/Function }
         mov  ah,al
         test al,1                 { Swap Xor and And... }
         jz   @@NoSwap             { to allow use of TP Graph Constants }
         xor  ah,2                 { AndPut or XorPut }
@@NoSwap:shl  ah,3                 { Move it to the correct position }
         and  ah,18h               { Allow only 00000b,01000b,10000b,11000b }
         mov  al,3                 { Select Register 3 (Data Rot./Fun.) }
         out  dx,ax                { Update it ! }

         mov  ax,0A05h             { Modes: R=1, W=2 - 5=Mode Register}
         out  dx,ax                { Set R/W modes}

         mov  ax,0007              { ah = Don't care for all maps }
         out  dx,ax                { CPU reads always return 0FFh }

         mov  ah,bh
         mov  al,08h               { Set up Bitmask reg (8) }
         out  dx,ax
         push es
         pop ds
         pop  cx  {<}
@@NxtLn:   and [di],bl      { update bitplanes (and = Read, then Write) }
           add di,BytesPerRow
         loop @@NxtLn          { Repeat for all lines }

@@Exit:  mov  ax,0003
         out  dx,ax
         mov  ax,0005
         out  dx,ax
         mov  ax,0F07h
         out  dx,ax
         mov  ax,0FF08h
         out  dx,ax

         pop  ds

  END;
END; {PROC vLine}



{---------------------------------------------------------------------------}


PROCEDURE ActivePage(Page:Word);
BEGIN
  PageOriginOffset:=Page*$8000; { For BitFonts / SoftBlit }
  Graph.SetActivePage(Page);
END; {PROC ActivePage}


PROCEDURE SetFont(Font:Pointer; ChSpc,LnSpc:Byte);
BEGIN
  Move(Font^,CurrFont,SizeOf(CurrFont));
  CharSpacing:=ChSpc;
  LineSpacing:=LnSpc;
END;

VAR
  uLineCount : Integer;
  uLineTable : ARRAY[1..40] OF Byte;

PROCEDURE Underline(xp,yp:Integer; Color:Byte;VAR txt:String);
VAR
  x,y,p : Integer;
BEGIN
  uLineCount:=0;
  p:=pos('_',txt);
  WHILE p<>0
  DO BEGIN
    delete(txt,p,1);
    Inc(uLineCount);
    uLineTable[uLineCount]:=p-1;
    p:=pos('_',txt);
  END;
  IF uLineCount>0
  THEN BEGIN
    IF odd(uLineCount)
    THEN BEGIN
     Inc(uLineCount);
     uLineTable[uLineCount]:=Byte(Txt[0]);
    END;
    y:=yp+LineSpacing-1+uLineOffset;
    p:=1;
    REPEAT
      IF uLinetable[p]<>uLinetable[p+1]
      THEN hLine(xp+(uLineTable[p]*CharSpacing),
                xp+(uLineTable[p+1]*CharSpacing),y,Color);
      Inc(p,2);
    UNTIL p>uLineCount;
  END;
END;{Underline}


{-----------------------------------------------------------------------}
{ PRIMITIVE fPutCh - Put Foreground of char (Background Non-Destructed)}
{ Call with ax=y, bx=x, cl=color, dx=Gfx Controller, es:di=Char.Def.}
{-----------------------------------------------------------------------}

(*
{$L LFGfxFnt}
PROCEDURE g_Wrt(xp,yp:Integer; Color:Byte; Txt:String); External;
*)

PROCEDURE gWrt(xp,yp:Integer; Color:Byte; Txt:String); ASSEMBLER;
VAR
  shifts : Byte;
  X      : Word;
  DSEG   : Word;
ASM
         push ds
         mov  dseg, ds
         mov  bl,CharSpacing       { bl:=distance to first pixel of next char}
         xor  bh,bh                { Zero bh}
         mov  ax,PutMode           { Load value for Data Rotate/Function  }
         mov  ah,al
         and  al,1                 { Swap Xor and And...  }
         jz   @@NoSwap             { To allow use of TP Graph Constants  }
         xor  ah,2                 { AndPut or XorPut  }
@@NoSwap:shl  ah,3                 { Move it to the correct position  }
         and  ah,18h               { Allow only 00000b,01000b,10000b,11000b  }
         mov  al,3                 { Select Register 3 (Data Rot./Fun.)  }
         push ax
         lea  di, Currfont         { es:di:=SEG:OFFSET to Font BitMap}
         push ds                   { es:=ds}
         pop  es
         lds  si,txt               { ds:si:=SEG:OFFSET to string}
         cld                       { Clear Direction flag (auto-inc. si/di)}
         lodsb                     { Get Length of string (1st byte)}
         cmp  al,0                 { Check if it is empty ?}
         je   @@Exit               { Yes, it was empty. Let's quit ! ...else}
         mov  cx,ax                { cl:=String length}
         xor  ch,ch
         mov  dx,03CEh             { dx:=Graphics Controller I/O Port}
         mov  ax,0A05h             { Modes: R=1, W=2 - 5=Mode Register}
         out  dx,ax                { Set R/W modes}
         pop  ax                   { Read-Modify-Write:= Copy Mode}
         out  dx,ax                { Set RMW mode}
         mov  ax,0007h             { Color Don't care = 0 - always return 0FFh}
         out  dx,ax                { after reads}
         mov  ax,XP
         mov  X,ax
@@NxtCh:   push cx                 { Store "chars-to-do" count}
           push di                 { Store base of BitMap}
           lodsb                   { Load next char}
           xor  ah,ah              { Zero ah}
           shl  ax,4               { ax:=ascii(char)*16 = offset in BitMap ...}
           add  di,ax              { es:di := Bitmap of char}
           mov  dx,YP              { ax:= Y}
           push bx                 { store charspacing}
           mov  bx,X               { bx:= X of char}

         { -------- }

         push es                   { Store es:di and ds:si ...}
         push ds
         push si
         push di
         push es
         mov  ax, DSEG
         mov  ds, ax
         mov  ax,dx
         call PixelAdr             { Calculate address of first pixel}
         mov  si,bx                { ds:si := SEG:OFFSET of pixel}
         push es
         pop  ds
         pop  es                   { es:di = SEG:OFFSET of Char.Def.}
         mov  bl,color             { bx := Color}
         inc  cx
         and  cl,7                 { cl := # of bits to shift left to mask}
         mov  ch,0FFh
         shl  ch,cl                { ch := bitmask for left side of char}
         mov  shifts,cl            { Store shift count}
         mov  cx,10h               { a Char.Def. contains 16 bytes}
         mov  dx,03CEh
         cmp  shifts,0             { Must we shift ?}
         jne  @@NoAlgn             { Yes, jump to non-aligned routine}
                                   { else ...}
{--- Byte aligned characters -------------------------------------------------}
         mov  al,8                 { al:=BitMask Register}
@@NxtRow:  mov  ah,es:[di]         { ah:=Next Char.Def. byte}
           out  dx,ax              { set mask equal to Char.Def. byte}
           and  [si],bl            { Update all masked bits to color in bl}
           inc  di                 { Point to Next Char.Def. byte}
           add  si,BytesPerRow     { Point to Next Screen Row}
         loop @@NxtRow             { Repeat for all Char.Def bytes}
         jmp @@ExitCh        { Jump to Exit when done ...}

{--- Non-aligned characters --------------------------------------------------}
@@NoAlgn:  push cx                 { Store Char.Def. byte counter}
           mov  cl,shifts          { Load shift count}
           mov  al,es:[di]         { Load Next Char.Def. byte}
           xor  ah,ah              { Zero ah}
           shl  ax,cl              { shift Char.Def. byte to the correct pos.}
           mov  bh,al              { Store the right side mask}
           mov  al,8               { al := Bitmask Register}
           out  dx,ax              { Set the left side mask}
           and  [si],bl            { Update the left side masked bits}
           mov  ah,bh              { Restore the right side mask}
           out  dx,ax              { and set it.}
           inc  si                 { Next byte of Video buffer}
           and  [si],bl            { Update the right side masked bits}
           inc  di                 { Point to Next Char.Def byte}
           dec  si                 { Point to Next Video buffer row}
           add  si,BytesPerRow
           pop  cx                 { Restore Char.Def byte counter}
         loop @@NoAlgn             { While there's more, process them}
                                   { else ... exit}
@@ExitCh:pop  di                   { Restore es:di and ds:si}
         pop  si
         pop  ds
         pop  es

         { -------- }

           pop  bx                 { Restore charspacing}
           add  X,bx               { x:=x+charspacing (1st pixel of next char)}
           pop  di                 { Restore Bitmap Base pointer}
           pop  cx                 { Restore "chars-to-do" counter}
           dec  cx
         jcxz @@NoMore             { Repeat for each char,}
         jmp  @@NxtCh              { else ... }
@@NoMore:
         mov  ax,0FF08h            { Restore default EGA/VGA modes...}
         out  dx,ax                { BitMask (All bits)}
         mov  ax,0005
         out  dx,ax                { Mode (R:0,W:0)}
         mov  ax,0003
         out  dx,ax                { RMW Mode (Copy Mode)}
         mov  ax,0F07h
         out  dx,ax                { Color Don't Care}

@@Exit:  pop  ds
END; {PROC gWrt}


PROCEDURE gTxt(xp,yp:Integer; Color:Byte; Txt:String); ASSEMBLER;
VAR
  vsegofs,FontBase : Word;
ASM
         push ds
         lea  di, CurrFont
         mov FontBase,di
         push ds
         pop  es
         lds  si,txt

         mov  bl,[si]              { Get Length of string (1st byte)}
         inc  si
         cmp  bl,0                 { Check if it is empty ?}
         je   @Exit                { Yes, it was empty. Let's quit ! ...else}

         mov  bh,Color

         mov  ax,YP
         mov  dx,ax
         shl  ax,6
         shl  dx,4
         add  ax,dx
         xor  dh,dh
         mov  dl, es:[LineSpacing]
         mul  dx
         add  ax,XP
         mov  vsegofs,ax

         mov  dx,03CEh             { dx:=Graphics Controller I/O Port}
         mov  ax,0A05h             { Modes: R=1, W=2 - 5=Mode Register}
         out  dx,ax                { Set R/W modes}
         mov  ax,3                 { Read-Modify-Write:= Copy Mode}
         out  dx,ax                { Set RMW mode}
         mov  ax,0007h             { Color Don't care = 0 - always return 0FFh}
         out  dx,ax                { after reads}

         cld
@NxtCh:  lodsb                   { load next char}
         xor  ah,ah              { Zero ah}
         shl  ax,4               { ax:=ascii(char)*16 = offset in BitMap ...}
         add  ax,FontBase
         mov  di,ax              { es:di := Bitmap of char}

         push ds
         push si

         mov  ax,VideoBufSeg
         mov  ds,ax
         mov  si,vsegofs

         mov  cx,16
         mov  al,8                 { al:=BitMask Register}

@NxtRow:  mov  ah,es:[di]          { ah:=Next Char.Def. byte}
           out  dx,ax              { set mask equal to Char.Def. byte}
           inc  di                 { Point to Next Char.Def. byte}
           and  [si],bh            { Update all masked bits to color in bh}
           add  si,BytesPerRow     { Point to Next Screen Row}
          loop @NxtRow             { Repeat for all Char.Def bytes}

         pop  si
         pop  ds
         inc  vsegofs
         dec bl
         jnz @NxtCh

@Done:   mov  ax,0FF08h            { Restore default EGA/VGA modes...}
         out  dx,ax                { BitMask (All bits)}
         mov  ax,0005
         out  dx,ax                { Mode (R:0,W:0)}
         mov  ax,0003
         out  dx,ax                { RMW Mode (Copy Mode)}
         mov  ax,0F07h
         out  dx,ax                { Color Don't Care}

@Exit:   pop  ds
END; {PROC gTxt}


PROCEDURE _gWrt(xp,yp:Integer; Color:Byte; txt:String);
BEGIN
  IF underlining THEN Underline(xp,yp,Color,txt);
  gWrt(xp,yp,Color,txt);
END;{PROC _gWrt}

PROCEDURE Wavetext(xp,yp:Integer; Color:Byte; txt:String);
VAR
  n,x,y : Integer;
BEGIN
  n:=1; x:=xp;
  WHILE n<=Byte(Txt[0]) DO
  BEGIN
    y:=yp+round(sin(n*0.5)*5);
    gWrt(x,y,Color,Txt[n]);
    x:=x+CharSpacing;
    inc(n);
  END;
END;{PROC Wavetext}

PROCEDURE VDtext(xp,yp:Integer; Color:Byte; txt:String);
VAR
  n,y : Integer;
BEGIN
  n:=1; y:=yp;
  WHILE n<=Byte(Txt[0]) DO
  BEGIN
    gWrt(xp,y,color,Txt[n]);
    y:=y+LineSpacing;
    inc(n);
  END;
END;{PROC VDtext}

PROCEDURE VUtext(xp,yp:Integer; Color:Byte; txt:String);
VAR
  n,y,xi,yi : Integer;
  chdef   : CharDef;
BEGIN
  n:=1; y:=yp;
  WHILE n<=Byte(Txt[0]) DO
  BEGIN
    gWrt(xp,y,color,Txt[n]);
    y:=y-LineSpacing;
    inc(n);
  END;
END;{VUtext}


PROCEDURE Shadow(WriteProc:TextProc;xp,yp:Integer;
                 Color:Byte; txt:string);
VAR
  i : Integer;
BEGIN
{  WriteProc(xp+1,yp+1,Black,txt);
  WriteProc(xp,yp,color,txt);}
  gWrt(xp+1,yp+1,Black,txt);
  gWrt(xp,yp,color,txt);
END;{Shadow}

{-------------------------------------------------------------- Dithering ---}
CONST
  Raster : ARRAY[0..16] OF Word
    =($0000, {    }   $8000, {ﬂ   }   $8020, {ﬂ   }   $A020, {ﬂ ﬂ }
      {  0%} {    }   {  6%} {    }   { 12%} {  ﬂ }   { 19%} {  ﬂ }

      $A0A0, {ﬂ ﬂ }   $A4A0, {ﬂ‹ﬂ }   $A4A1, {ﬂ‹ﬂ }   $A5A1, {ﬂ‹ﬂ‹}
      { 25%} {ﬂ ﬂ }   { 32%} {ﬂ ﬂ }   { 38%} {ﬂ ﬂ‹}   { 44%} {ﬂ ﬂ‹}

      $A5A5, {ﬂ‹ﬂ‹}   $E5A5, {ﬂ€ﬂ‹}   $E5B5, {ﬂ€ﬂ‹}   $F5B5, {ﬂ€ﬂ€}
      { 50%} {ﬂ‹ﬂ‹}   { 56%} {ﬂ‹ﬂ‹}   { 62%} {ﬂ‹ﬂ€}   { 68%} {ﬂ‹ﬂ€}

      $F5F5, {ﬂ€ﬂ€}   $FDF5, {€€ﬂ€}   $FDF7, {€€ﬂ€}   $FFF7, {€€€€}
      { 75%} {ﬂ€ﬂ€}   { 81%} {ﬂ€ﬂ€}   { 88%} {ﬂ€€€}   { 94%} {ﬂ€€€}

      $FFFF);{€€€€}
      {100%} {€€€€}

PROCEDURE MakeRasterPattern(def:Word; VAR rast);
BEGIN
  ASM
    push es
    mov  dx,def
    les  di,rast
    cld
    mov  cx,8
@@byt:   mov  bx,dx
         rol  bx,4
         mov  dx,bx
         and  bl,0Fh
         xor  ax,ax
         or   al,bl
         shl  al,4
         or   al,bl
         stosb
    loop @@byt
    pop es
  END;
END; {PROC SetRaster}

PROCEDURE DitherH(x1,y1,x2,y2,c1,c2:Integer);
CONST
  mx = 17;
VAR
  lxdi,
  rxdi,
  i     : Integer;
  blks  : Integer;
  RasterFill : FillPatternType;
BEGIN
  blks:=(x2-x1) DIV mx;
  lxdi:=((x2-x1) MOD mx);
  rxdi:=lxdi; lxdi:=lxdi DIV 2;
  rxdi:=rxdi-lxdi;
  SetFillStyle(SolidFill,c1);
  Bar(x1,y1,x1+(blks+2),y2);
  SetFillStyle(SolidFill,c2);
  Bar(x2-(blks+2),y1,x2,y2);
  FOR i:=0 TO mx-1
  DO BEGIN
    MakeRasterPattern(Raster[i],RasterFill);
    SetFillPattern(RasterFill,c1 xor c2);
    Bar(x1+lxdi+(i*blks),y1,x1+lxdi+(i*blks)+blks-1,y2);
  END;
  PutMode:=xOrPut;
  Block(x1+lxdi,y1,x2-rxdi-1,y2,c1);
  PutMode:=NormalPut;
END; {PROC DitherH}

PROCEDURE DitherV(x1,y1,x2,y2,c1,c2:Integer);
CONST
  mx = 17;
VAR
  uydi,
  lydi,
  i     : Integer;
  blks  : Integer;
  RasterFill : FillPatternType;
BEGIN
  blks:=(y2-y1) DIV mx;
  uydi:=((y2-y1) MOD mx);
  lydi:=uydi; uydi:=uydi DIV 2;
  lydi:=lydi-uydi;
  SetFillStyle(SolidFill,c1);
  Bar(x1,y1,x2,y1+(blks+2));
  SetFillStyle(SolidFill,c2);
  Bar(x1,y2-(blks+2),x2,y2);
  FOR i:=0 TO mx-1
  DO BEGIN
    MakeRasterPattern(Raster[i],RasterFill);
    SetFillPattern(RasterFill,c1 xor c2);
    Bar(x1,y1+uydi+(i*blks),x2,y1+uydi+(i*blks)+blks-1);
  END;
  PutMode:=xOrPut;
  Block(x1,y1+uydi,x2,x2-lydi-1,c1);
  PutMode:=NormalPut;
END; {PROC DitherV}



{------------------------------------------------------------ ExitHandler ---}

VAR
  PrevExitProc : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  Units.Leave(LFGraphMsg,MemAvail);
END;

BEGIN { Init Unit LFgraph5 }
  IF ProtectedMode
  THEN VideoBufSeg:=SegmentToSelector(VideoBufSeg);
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  Units.Enter(LFGraphMsg,MemAvail,CSeg);
END.
