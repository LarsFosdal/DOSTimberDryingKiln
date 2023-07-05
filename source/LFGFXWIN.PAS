{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT LFgfxWin;

INTERFACE
USES Dos,Objects,LFsystem,LFwindow,LFextMsg,Graph;

CONST
  LFGfxWinMsg = ' LFGfxWin.1 910927 Lars Fosdal ';
TYPE
  PGfxCursor = ^GfxCursor;
  GfxCursor = OBJECT(GenericCursor)
    py1,py2 : Integer;
    CONSTRUCTOR Init(AtX,AtY:Integer; OwnerWS:PWorkSpace);
    PROCEDURE ChangeState(NewState:CursorSize); VIRTUAL;
    FUNCTION  AbsX:Integer;                VIRTUAL;
    FUNCTION  AbsY:Integer;                VIRTUAL;
    PROCEDURE MoveTo(NewX,NewY:Integer);   VIRTUAL;
    PROCEDURE Hide;                        VIRTUAL;
    PROCEDURE Show;                        VIRTUAL;
  END; {OBJ GfxCursor}

  PGfxWS = ^GfxWorkSpace;
  GfxWorkSpace = OBJECT(GenericWorkspace)
    TextLines : Integer; {Number of Actual Lines available in workspace }
    CC        : SingleColor; {Current Color}
    AutoClear : Boolean;     {True : Clear on Open}
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
  END; {OBJ GfxWorkspace}

  PWorldWS = ^WorldWorkSpace;
  WorldWorkSpace = OBJECT(GfxWorkspace)
    wxmin,wxmax,
    wymin,wymax : Float;
    dxmin,dxmax,
    dymin,dymax : Integer;
    Clip        : Boolean;
    xsf,ysf,
    dx,dy       : Float;
    xscleft,xScaleMargin,
    yscbottom,yScaleMargin : Integer;
    CONSTRUCTOR Init(x,y,w,h:Integer; scleft,scbottom:Integer);
    PROCEDURE Recalculate;                   VIRTUAL;
    PROCEDURE World(x1,y1,x2,y2:Float);
    FUNCTION  xWtoD(x:Float):Integer;        VIRTUAL;
    FUNCTION  yWtoD(y:Float):Integer;        VIRTUAL;
    PROCEDURE PutPixel(x,y: Float; color:word);
    PROCEDURE Line(x1,y1,x2,y2:Float);
    PROCEDURE PointTo(x,y:Float);
    PROCEDURE LineTo(x,y:Float);
    PROCEDURE Circle(x,y,radius:Float);
    PROCEDURE Rectangle(x1,y1,x2,y2:Float);
    PROCEDURE Bar(x1,y1,x2,y2:Float);
    PROCEDURE Bar3D(x1,y1,x2,y2:Float; Depth:Integer; _Top:Boolean);
    PROCEDURE PolywToD(NumPoints:Word;
                       VAR wPolyPoints; VAR dPolyPoints);
    PROCEDURE DrawPoly(NumPoints:Word; VAR wPolyPoints);
    PROCEDURE FillPoly(NumPoints:Word; VAR wPolyPoints);
    PROCEDURE Text(x,y:Float; theText:string);
    PROCEDURE xScale(Style:Word);                VIRTUAL;
    PROCEDURE xTimeScale(Style:Word; Hours:Word; Now:DateTime);  VIRTUAL;
    PROCEDURE yScale(Style:Word);                VIRTUAL;
    PROCEDURE Scales(vStyle,hStyle:Word);        VIRTUAL;
  END; {OBJ WorldWorkspace}

  PLogWS = ^LogWorkSpace;
  LogWorkSpace = OBJECT(WorldWorkspace)
    xLog,yLog   : Boolean;
    ldx,ldy     : Float;
    xDec,yDec,
    xBase,yBase : Integer;
    CONSTRUCTOR Init(x,y,w,h:Integer; scleft,scbottom:Integer);
    PROCEDURE Recalculate;                 VIRTUAL;
    PROCEDURE SetXLog(Dec,Base:Integer);
    PROCEDURE SetYLog(Dec,Base:Integer);
    FUNCTION  xWtoD(x:Float):Integer;      VIRTUAL;
    FUNCTION  yWtoD(y:Float):Integer;      VIRTUAL;
  END; {OBJ LogWorkspace}

  PGfxWin = ^GfxWin;
  GfxWin = OBJECT(GenericWindow)
    Buffer2   : Pointer; {For Graphic Windows > 64Kb }
    Buf2Size  : Word;    {Number of bytes allocated to buffer2}
    TextLines : Integer; {Number of Actual Lines available in window }
    CONSTRUCTOR Init(x,y,w,h:Integer; BackGrSave:Boolean);
    CONSTRUCTOR InitTxt(x,y,Columns,Lines:Integer; BackGrSave:Boolean);
    DESTRUCTOR  Done;                              VIRTUAL;
    PROCEDURE   TitlePtr(Head,Foot:PString);       VIRTUAL;
    PROCEDURE   MoveTo(x,y:Integer);               VIRTUAL;
    PROCEDURE   SizeSet(w,h:Integer);              VIRTUAL;
    PROCEDURE   TxtAdjSize(Columns,Lines:Integer); VIRTUAL;
    PROCEDURE   InternalInit;                      VIRTUAL;
    PROCEDURE   Open;                              VIRTUAL;
    PROCEDURE   Frame;                             VIRTUAL;
    PROCEDURE   Clear;                             VIRTUAL;
    PROCEDURE   CenterTitle(y:Integer; cf:SingleColor; Txt:String);    VIRTUAL;
    PROCEDURE   Leave;                             VIRTUAL;
    PROCEDURE   Close;                             VIRTUAL;
    FUNCTION    MemUsage:LongInt;                  VIRTUAL;
  END; {OBJ GfxWin}

CONST
  StdGfxWin : DefWinColor = { Standard Graphic Window Colors }
    (Pane:  (Norm: LightGray shl 4 + Yellow;
             High: LightGray shl 4 + White;
             Low : LightGray shl 4 + Black);
     Frame: (Norm: LightGray shl 4 + DarkGray;
             High: LightGray shl 4 + White;
             Low : LightGray shl 4 + DarkGray);
     Title: (Norm: Blue shl 4 + Yellow;
             High: Blue shl 4 + White;
             Low : Blue shl 4 + Black);
     SelBar:(Norm: Red shl 4 + Yellow;
             High: Red shl 4 + White;
             Low : Red shl 4 + Black));

  AltGfxWin : DefWinColor = { Alternate Graphic Window Colors }
    (Pane:  (Norm: Cyan shl 4 + Yellow;
             High: Cyan shl 4 + White;
             Low : Cyan shl 4 + Black);
     Frame: (Norm: Cyan shl 4 + DarkGray;
             High: Cyan shl 4 + LightCyan;
             Low : Cyan shl 4 + DarkGray);
     Title: (Norm: Blue shl 4 + Yellow;
             High: Blue shl 4 + White;
             Low : Blue shl 4 + Black);
     SelBar:(Norm: Red  shl 4 + Yellow;
             High: Red  shl 4 + White;
             Low : Red  shl 4 + Black));

PROCEDURE ShadowBox(x1,y1,x2,y2,Light,Dark:Integer; Down:Boolean);
PROCEDURE Relief(x,y,w,h,ful,flr,pane:Integer);
PROCEDURE BasRelief(x,y,w,h,ful,flr,pane:Integer);
PROCEDURE FrameRelief(x,y,w,h,ful,flr,pane:Integer);
PROCEDURE InvFrameRelief(x,y,w,h,ful,flr,pane:Integer);


IMPLEMENTATION
USES
  LFString,LFDos,LFgraph;


VAR
  GraphAreaLimit : anArea;


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ GfxCursor ÄÄÄ}

CONSTRUCTOR GfxCursor.Init(AtX,AtY:Integer; OwnerWS:PWorkSpace);
{ - }
BEGIN
  GenericCursor.Init(atX,atY,OwnerWS);
END; {CONS GfxCursor.Init}

PROCEDURE GfxCursor.ChangeState(NewState:CursorSize);
BEGIN
  GenericCursor.ChangeState(NewState);
  py2:=LineSpacing-2;
  CASE State OF
    SplitCsr,
    FullCsr   : py1:=0;
    HalfCsr   : py1:=(LineSpacing DIV 2)-1;
    NormalCsr : py1:=py2-1;
    HiddenCsr : py1:=py2;
  END;
END; {GfxCursor.ChangeState}

FUNCTION  GfxCursor.AbsX:Integer;
{ - Return cursor x-pos relative to screen origin}
BEGIN
  AbsX:=Owner^.Left+(x*CharSpacing);
END; {FUNC GfxCursor.AbsX}

FUNCTION  GfxCursor.AbsY:Integer;
{ - Return cursor y-pos relative to screen origin}
BEGIN
  AbsY:=Owner^.Top+(y*LineSpacing);
END; {FUNC GfxCursor.AbsY}

PROCEDURE GfxCursor.MoveTo(NewX,NewY:Integer);
{ - Move cursor within owner-window}
CONST
  ox : Integer = 0;
  oy : Integer = 0;
  c  : LongInt = 0;
VAR
  tick : LongInt Absolute $0040:$006C;
  Visible : Boolean;
BEGIN
  Visible:=not Hidden;
  IF (x<>NewX) or (y<>NewY)
  THEN BEGIN
    IF Visible THEN Hide;
    ox:=x;
    oy:=y;
    x:=NewX;
    y:=NewY;
    IF Visible THEN Show;
  END
  ELSE BEGIN
    IF Abs(Tick-c)>4
    THEN BEGIN
      Toggle;
      c:=Tick;
    END
  END;
END; {PROC GfxCursor.MoveTo}

PROCEDURE GfxCursor.Hide;
{ - Turn cursor off}
VAR
  px,py,m : Integer;
BEGIN
  IF (not Hidden) and (State<>HiddenCsr)
  THEN BEGIN
    m:=PutMode;
    PutMode:=Xorput;
    px:=AbsX; py:=AbsY;
    Block(px,py+py1,px+CharSpacing-1,py+py2,PGfxWS(Owner)^.CC.ExOR);
    GenericCursor.Hide;
    PutMode:=m;
  END;
END; {PROC GfxCursor.Hide}

PROCEDURE GfxCursor.Show;
{ - turn cursor on}
VAR
  px,py,m,c : Integer;
BEGIN
  IF Hidden and (State<>HiddenCsr)
  THEN BEGIN
    m:=PutMode;
    PutMode:=Xorput;
    px:=AbsX; py:=AbsY;
    Block(px,py+py1,px+CharSpacing-1,py+py2,PGfxWS(Owner)^.CC.ExOR);
    GenericCursor.Show;
    PutMode:=m;
  END;
END; {PROC GfxCursor.Show}

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ GfxWorkspace ÄÄÄ}

CONSTRUCTOR GfxWorkspace.Init(x,y,w,h:Integer);
{ - Define the location and size of the workspace}
BEGIN
  GenericWorkspace.Init(x,y,w,h);
  Pane.SetDefault(StdGfxWin.Pane);
  SelBar.SetDefault(StdGfxWin.SelBar);
  AutoClear:=True;
  CC:=Pane.Norm;
  Cursor:=New(PGfxCursor,Init(0,0,@Self));
END; {CONS GfxWorkspace.Init}

CONSTRUCTOR GfxWorkspace.InitTxt(x,y,Columns,Lines:Integer);
{ - Define the location and size of the workspace
    (size by number of columns/lines of text it can display) }
BEGIN
  GfxWorkspace.Init((x-1)*CharSpacing,(y-1)*CharSpacing,
                16+(Columns*CharSpacing),16+(Lines*LineSpacing));
END; {CONS GfxWorkspace.InitTxt}

DESTRUCTOR GfxWorkspace.Done;
{ - Close (if open), Deallocate used memory, i.e. Clean up after workspace}
BEGIN
  Dispose(PGfxCursor(Cursor),Done);
  Cursor:=nil;
  GenericWorkspace.Done;
END; {DEST GfxWorkspace.Done}

PROCEDURE GfxWorkspace.MoveTo(x,y:Integer);
{ - Move the workspace (upper lef corner) to (x,y)
    (Assume width and height within limits)}
VAR
  m : Integer;
  wasOpen : Boolean;
BEGIN
  wasOpen:=isOpen;
  IF wasOpen THEN Close;
  lx:=x;                          {Adjust in horisontal direction}
  m:=lx MOD 8;
  IF m<>0 THEN m:=1;
  lx:=(m+(lx DIV 8))*8;           {Adjust for VideoRAM-ByteAlignment}
  IF lx>639 THEN lx:=632;
  IF not GraphAreaLimit.InXrange(Left)     {Too far left}
   THEN lx:=GraphAreaLimit.Left;
  IF not GraphAreaLimit.InXrange(Right)    {Too far right}
   THEN lx:=GraphAreaLimit.Right-Width+1;
  uy:=y;                          {Adjust in vertical direction}
  IF not GraphAreaLimit.InYrange(Top)      {Too high}
   THEN uy:=GraphAreaLimit.Top;
  IF not GraphAreaLimit.InYrange(Bottom)   {Too low}
   THEN uy:=GraphAreaLimit.Bottom-Height+1;
  IF wasOpen THEN Open;
END; {PROC GfxWorkspace.MoveTo}

PROCEDURE GfxWorkspace.SizeSet(w,h:Integer);
{ - Set Size of workspace: width and height in pixels}
VAR
  m : Integer;
  wasOpen : Boolean;
BEGIN
  wasOpen:=isOpen;
  IF wasOpen THEN Close;
  IF w<MinimumWidth THEN w:=MinimumWidth; {Adjust horisontal size}
  m:=w MOD 8;
  IF m<>0 THEN m:=1;
  w:=(m+(w DIV 8))*8; {Adjust for VideoRAM-ByteAlignment}
  IF w<=GraphAreaLimit.Width
  THEN xw:=w
  ELSE xw:=GraphAreaLimit.Width;
  IF h<MinimumHeight THEN h:=MinimumHeight; {Adjust vertical size}
  IF h<=GraphAreaLimit.Height
  THEN yh:=h
  ELSE yh:=GraphAreaLimit.Height;
  MoveTo(Left,Top);            {Adjust position if necessary}
  if wasOpen THEN Open;
END; {PROC GfxWorkspace.SizeSet}

PROCEDURE GfxWorkspace.TxtAdjSize(Columns,Lines:Integer);
{ - Set Size of workspace: width and height in TextLines}
BEGIN
  GfxWorkspace.SizeSet(Columns*CharSpacing,Lines*LineSpacing);
END; {PROC GfxWorkspace.TxtAdjSize}

PROCEDURE GfxWorkspace.TxtBar(x,y,w:Integer; cf:SingleColor);
{ - Draw a Bar}
VAR
  opm : Word;
BEGIN
  opm:=PutMode;
  PutMode:=NormalPut;
  Block(Left+x*CharSpacing,Top+y*LineSpacing-1,
        Left+(x+w)*CharSpacing-1,Top+(y+1)*LineSpacing-1,cf.BG);
  PutMode:=opm;
END; {PROC GfxWorkspace.TxtBar}

PROCEDURE GfxWorkspace.Open;
{ - Open the workspace: Draw it/Select}
BEGIN
  IF not isOpen
  THEN BEGIN
    IF AutoClear THEN Clear;
    GenericWorkspace.Open;
  END;
END; {PROC GfxWorkspace.Open}

FUNCTION TrimmedString(MaxLen:Integer; Txt:String):String;
{ - Shorten a string to fit within a maximum width}
VAR
  n : Word;
BEGIN
  n:=Length(Txt);
  WHILE ((CharSpacing*n)>MaxLen) and (n>0) DO dec(n);
  TrimmedString:=Copy(Txt,1,n);
END; {FUNC TrimmedString}

FUNCTION TrimmedStringLength(MaxLen:Integer; Txt:String):Integer;
{ - Give length of a trimmed string }
VAR
  n : Word;
BEGIN
  n:=Length(Txt);
  WHILE ((CharSpacing*n)>MaxLen) and (n>0) DO dec(n);
  TrimmedStringLength:=CharSpacing*n;
END; {FUNC TrimmedStringLength}

PROCEDURE GfxWorkspace.Clear;
{ - Clear the pane of the workspace }
BEGIN
  SetFillStyle(SolidFill,Pane.Norm.BG);
  Graph.Bar(Left,Top,Right,Bottom);
END; {PROC GfxWorkspace.Clear}

PROCEDURE GfxWorkspace.ScrollUp(Lines:Integer);
{ - Roll the contents of the workspace "Lines" lines upwards}
VAR
  b : Pointer;
  w : Word;
BEGIN
{  IF MemUsage<65000
  THEN} BEGIN
    w:=ImageSize(Left,Top+lines,Right,Bottom);
    GetMem(b,w);
    GetBlock(Left,Top+lines,Right,Bottom,b^);
    PutBlock(Left,Top,b^,NormalPut);
    FreeMem(b,w);
  END;
END; {PROC GfxWorkspace.ScrollUp}

PROCEDURE GfxWorkspace.ScrollDown(Lines:Integer);
{ - Roll the contents of the workspace "Lines" lines downwards}
VAR
  b : Pointer;
  w : Word;
BEGIN
{  IF MemUsage<65000
  THEN} BEGIN
    w:=ImageSize(Left,Top,Right,Bottom-lines);
    GetMem(b,w);
    GetBlock(Left,Top,Right,Bottom-lines,b^);
    PutBlock(Left,Top+lines,b^,NormalPut);
    FreeMem(b,w);
  END;
END; {PROC GfxWorkspace.ScrollDown}

PROCEDURE GfxWorkspace.Wrt(x,y:Integer; cf:SingleColor; Txt:String);
{ - Display a text at (x,y) within the workspace relative to upper left corner}
BEGIN
  CC:=CF;
  IF x<0 THEN x:=0;
  gWrt(Left+x,Top+y,cf.FG,TrimmedString(Width,Txt));
END; {PROC GfxWorkspace.Wrt}

PROCEDURE GfxWorkspace.WrtTxt(x,y:Integer; cf:SingleColor; Txt:String);
{ - Display a text at (x,y) within the workspace relative to upper left corner}
VAR
  l,u : Integer;
  visible : Boolean;
BEGIN
  IF Txt='' THEN Exit;
  CC:=CF;
  visible:=not Cursor^.Hidden;
  IF Visible THEN Cursor^.Hide;
  IF x<0 THEN x:=0;
  l:=Left+(x*CharSpacing);
  u:=Top+(y*LineSpacing);
  SetFillStyle(SolidFill,cf.BG);
  Graph.Bar(l,u,l+TrimmedStringLength(Width,Txt)-1,u+LineSpacing-2);
  gWrt(l,u,cf.FG,TrimmedString(Width,Txt));
  IF Visible THEN Cursor^.Show;
END; {PROC GfxWorkspace.WrtTxt}

PROCEDURE GfxWorkspace.Center(y:Integer; cf:SingleColor; Txt:String);
{ - Display a Text Centered at row y within the workspace}
VAR
  l : Integer;
BEGIN
  CC:=CF;
  l:=(Width DIV 2)-(TrimmedStringLength(Width,Txt) DIV 2);
  gWrt(Left+l,Top+y,cf.FG,TrimmedString(Width,Txt));
END; {PROC GfxWorkspace.Center}

PROCEDURE GfxWorkspace.Ctr(y:Integer; cf:SingleColor; Txt:String);
{ - Display a Text Centered at row y within the workspace}
VAR
  l : Integer;
BEGIN
  CC:=CF;
  l:=(Width DIV 2)-(TrimmedStringLength(Width,Txt) DIV 2);
  Shadow(gWrt,Left+l,y,cf.FG,TrimmedString(Width,Txt));
END; {PROC GfxWorkspace.Ctr}

PROCEDURE GfxWorkspace.Leave;
{ - Exit the graphic workspace without closing it}
VAR n : Integer;
    s : String[80];
BEGIN
  s:=Rep(Width DIV CharSpacing,'°');
  FOR n:=0 TO (Height DIV LineSpacing)-1
  DO gWrt(Left,Top+n*LineSpacing,Pane.Norm.BG,s);
END; {PROC GfxWorkspace.Leave}

PROCEDURE GfxWorkspace.Close;
{ - Close the graphic workspace }
VAR
  h2 : Word;
BEGIN
  IF isOpen
  THEN BEGIN
    GenericWorkspace.Close;
  END;
END; {PROC GfxWorkspace.Close}

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ GfxWin ÄÄÄ}

CONSTRUCTOR GfxWin.Init(x,y,w,h:Integer; BackGrSave:Boolean);
{ - Define the location and size of the window,
    and if it should save it's background }
BEGIN
  GenericWindow.Init(x,y,w,h,BackGrSave);
  C.SetDefault(StdGfxWin);
  Buffer2:=nil;
  Buf2Size:=0;
END; {CONS GfxWin.Init}

CONSTRUCTOR GfxWin.InitTxt(x,y,Columns,Lines:Integer; BackGrSave:Boolean);
{ - Define the location and size of the window,
    (size by number of columns/lines of text it can display)
    and if it should save it's background }
BEGIN
  GfxWin.Init((x-1)*CharSpacing,(y-1)*CharSpacing,
                16+(Columns*CharSpacing),16+(Lines*LineSpacing),BackGrSave);
END; {CONS GfxWin.InitTxt}

DESTRUCTOR GfxWin.Done;
{ - Close (if open), Deallocate used memory, i.e. Clean up after window}
BEGIN
  GenericWindow.Done;
END; {DEST GfxWin.Done}

PROCEDURE GfxWin.TitlePtr(Head,Foot:PString);
{ - Attach/change title(s) to the window }
VAR
  hReDef,fReDef:Boolean;
BEGIN
  hReDef:=Header<>nil;                { Where there titles before ?}
  fReDef:=Footer<>nil;
  GenericWindow.TitlePtr(Head,Foot); { Assign new title(s)}
  IF (not hReDef) and (Header<>nil)
  THEN BEGIN
    iuy:=LineSpacing+12;
    GfxWin.SizeRel(0,LineSpacing+4);
  END
  ELSE IF (hReDef) and (Header=nil)
  THEN BEGIN
    iuy:=8;
    GfxWin.SizeRel(0,-(LineSpacing+4));
  END;
  IF (not fReDef) and (Footer<>nil)
  THEN BEGIN
    ily:=LineSpacing+12;
    GfxWin.SizeRel(0,LineSpacing+4);
  END
  ELSE IF (fReDef) and (Footer=nil)
  THEN BEGIN
    ily:=8;
    GfxWin.SizeRel(0,-(LineSpacing+4));
  END;
  IF (not hRedef) or (not fReDef)
  THEN WorkSpace^.MoveSize(iLeft,iTop,iWidth,iHeight);
END; {PROC GfxWin.TitlePtr}

PROCEDURE GfxWin.MoveTo(x,y:Integer);
{ - Move the window (upper left corner) to (x,y)
    (Assume width and height within limits)}
VAR
  m : Integer;
  wasOpen : Boolean;
BEGIN
  wasOpen:=isOpen;
  IF wasOpen THEN Close;
  lx:=x;                          {Adjust in horisontal direction}
  m:=lx MOD 8;
  IF m<>0 THEN m:=1;
  lx:=(m+(lx DIV 8))*8;           {Adjust for VideoRAM-ByteAlignment}
  IF lx>639 THEN lx:=632;
  IF not GraphAreaLimit.InXrange(Left)     {Too far left}
   THEN lx:=GraphAreaLimit.Left;
  IF not GraphAreaLimit.InXrange(Right)    {Too far right}
   THEN lx:=GraphAreaLimit.Right-Width+1;
  uy:=y;                          {Adjust in vertical direction}
  IF not GraphAreaLimit.InYrange(Top)      {Too high}
   THEN uy:=GraphAreaLimit.Top;
  IF not GraphAreaLimit.InYrange(Bottom)   {Too low}
   THEN uy:=GraphAreaLimit.Bottom-Height+1;
  WorkSpace^.MoveSize(iLeft,iTop,iWidth,iHeight);
  IF wasOpen THEN Open;
END; {PROC GfxWin.MoveTo}

PROCEDURE GfxWin.SizeSet(w,h:Integer);
{ - Set Size of window: width and height in pixels}
VAR
  m : Integer;
  wasOpen : Boolean;
BEGIN
  wasOpen:=isOpen;
  IF wasOpen THEN Close;
  IF w<MinimumWidth THEN w:=MinimumWidth; {Adjust horisontal size}
  m:=w MOD 8;
  IF m<>0 THEN m:=1;
  w:=(m+(w DIV 8))*8; {Adjust for VideoRAM-ByteAlignment}
  IF w<=GraphAreaLimit.Width
  THEN xw:=w
  ELSE xw:=GraphAreaLimit.Width;
  IF h<MinimumHeight THEN h:=MinimumHeight; {Adjust vertical size}
  IF h<=GraphAreaLimit.Height
  THEN yh:=h
  ELSE yh:=GraphAreaLimit.Height;
  MoveTo(Left,Top);            {Adjust position if necessary}
  WorkSpace^.MoveSize(iLeft,iTop,iWidth,iHeight);
  if wasOpen THEN Open;
END; {PROC GfxWin.SizeSet}

PROCEDURE GfxWin.TxtAdjSize(Columns,Lines:Integer);
{ - Set Size of window: width and height in TextLines}
BEGIN
  GfxWin.SizeSet(ilx+irx+Columns*CharSpacing,iuy+ily+Lines*LineSpacing);
END; {PROC GfxWin.TxtAdjSize}

PROCEDURE GfxWin.InternalInit;
BEGIN
  ilx:=8; irx:=8;
  iuy:=8; ily:=8;
  WorkSpace:=New(PGfxWS,Init(iLeft,iTop,iWidth,iHeight));
END; {PROC GfxWin.InternalInit}

PROCEDURE GfxWin.Open;
{ - Open the window: Save background/Draw it/Select}
VAR
  h2 : Word;
BEGIN
  IF not isOpen
  THEN BEGIN
    IF SaveBackground
    THEN BEGIN
      IF LongInt(Width)*Height < 120000
      THEN BEGIN { - One buffer sufficient }
        BufSize:=MemUsage;
        GetMem(Buffer,BufSize);
        GetBlock(Left,Top,Right,Bottom,Buffer^);
      END
      ELSE BEGIN { - Two buffers necessary }
        h2:=Height DIV 2;
        BufSize:=ImageSize(Left,Top,Right,Top+h2);
        GetMem(Buffer,BufSize);
        GetBlock(Left,Top,Right,Top+h2,Buffer^);
        Buf2Size:=ImageSize(Left,Top+h2+1,Right,Bottom);
        GetMem(Buffer2,Buf2Size);
        GetBlock(Left,Top+h2+1,Right,Bottom,Buffer2^);
      END;
    END;
    GenericWindow.Open;
  END;
END; {PROC GfxWin.Open}

PROCEDURE ShadowBox(x1,y1,x2,y2,Light,Dark:Integer; Down:Boolean);
BEGIN
  IF not Down THEN SetColor(Dark) ELSE SetColor(Light);
  Line(x1+1,y2,x2,y2); Line(x2,y1+1,x2,y2);
  IF not Down THEN SetColor(Light) ELSE SetColor(Dark);
  Line(x1,y1,x2-1,y1); Line(x1,y1,x1,y2-1);
END;{ShadowBox}

PROCEDURE Relief(x,y,w,h,ful,flr,pane:Integer);
BEGIN
  hLine(x,x+w-2,y,ful); hLine(x+1,x+w-3,y+1,ful); {O.Frame T.L.}
  vLine(x,y,y+h-2,ful); vLine(x+1,y+2,y+h-3,ful);
  hLine(x+1,x+w-1,y+h-2,flr); hLine(x,x+w-1,y+h-1,flr); {O.Frame B.R.}
  vLine(x+w-2,y+1,y+h-3,flr); vLine(x+w-1,y,y+h-2,flr);
END; {PROC Relief}

PROCEDURE BasRelief(x,y,w,h,ful,flr,pane:Integer);
BEGIN
  SetFillStyle(SolidFill,Pane);
  Bar(x+2,y+2,x+w-3,y+h-3);
  Relief(x,y,w,h,ful,flr,pane);
END; {PROC BasRelief}

PROCEDURE FrameRelief(x,y,w,h,ful,flr,pane:Integer);
BEGIN
  SetFillStyle(SolidFill,Pane);
  Bar(x+3,y+3,x+w-5,y+h-5);
  Relief(x,y,w,h,ful,flr,pane);
  ShadowBox(x+2,y+2,x+w-4,y+h-4,flr,ful,False);
END;

PROCEDURE InvFrameRelief(x,y,w,h,ful,flr,pane:Integer);
BEGIN
  SetFillStyle(SolidFill,Pane);
  Bar(x+3,y+3,x+w-5,y+h-5);
  Relief(x+1,y+1,w-2,h-2,flr,ful,pane);
  ShadowBox(x,y,x+w,y+h,ful,flr,False);
END;

PROCEDURE GfxWin.Frame;
{ - Draw a Frame around the window }
VAR
  tl,tx,txw : Integer;
BEGIN
  SetFillStyle(SolidFill,C.Frame.Norm.BG);

  Bar(Left+2,Bottom-2,iLeft-4,Top+2);
  Bar(Left+2,Top+2,Right-2,iTop-4);
  Bar(iRight+4,Top+2,Right-2,Bottom-2);
  Bar(Left+2,iBottom+4,Right-2,Bottom-2);

  Relief(Left,Top,Width,Height,C.Frame.High.FG,C.Frame.Low.FG,C.Frame.Norm.BG);
  ShadowBox(iLeft-3,iTop-3,iRight+3,iBottom+3,C.Frame.High.FG,C.Frame.Low.FG,True);
  IF Header<>nil
  THEN BEGIN
    tl:=(TrimmedStringLength(iWidth,Header^) DIV 2)+3;
    tx:=left+(Width DIV 2)-tl;
    txw:=2*tl;
    SetFillStyle(SolidFill,C.Title.Norm.BG);
    Bar(tx,Top+3,tx+txw+1,iTop-5);
    ShadowBox(tx,Top+3,tx+txw+1,iTop-5,C.Frame.High.FG,C.Frame.Low.FG,True);
    CenterTitle(Top+5,C.Title.Norm,Header^);
  END;
  IF Footer<>nil
  THEN BEGIN
    tl:=(TrimmedStringLength(iWidth,Footer^) DIV 2)+3;
    tx:=left+(Width DIV 2)-tl;
    txw:=2*tl;
    SetFillStyle(SolidFill,C.Title.Norm.BG);
    Bar(tx,iBottom+5,tx+txw+1,Bottom-3);
    ShadowBox(tx,iBottom+5,tx+txw+1,Bottom-3,C.Frame.High.FG,C.Frame.Low.FG,True);
    CenterTitle(iBottom+7,C.Title.Norm,Footer^);
  END;
END; {PROC GfxWin.Frame}

PROCEDURE GfxWin.Clear;
{ - Clear the pane of the window }
BEGIN
  SetFillStyle(SolidFill,C.Frame.Norm.BG);
  Bar(iLeft-2,iTop-2,iRight+2,iBottom+2);
  GenericWindow.Clear;
END; {PROC GfxWin.Clear}

PROCEDURE GfxWin.CenterTitle(y:Integer; cf:SingleColor; Txt:String);
{ - Display a Text Centered at row y within the window}
VAR
  l : Integer;
BEGIN
  l:=(iWidth DIV 2)-(TrimmedStringLength(iWidth,Txt) DIV 2);
  Shadow(gWrt,iLeft+l,y,cf.FG,TrimmedString(iWidth,Txt));
END; {PROC GfxWin.CenterTitle}

PROCEDURE GfxWin.Leave;
{ - Exit the graphic window without closing it}
BEGIN
  WorkSpace^.Leave;
END; {PROC GfxWin.Leave}

PROCEDURE GfxWin.Close;
{ - Close the graphic window and restore background (if necessary) }
VAR
  h2 : Word;
BEGIN
  IF isOpen
  THEN BEGIN
    IF SaveBackground
    THEN BEGIN
      IF Buffer2<>nil
      THEN BEGIN
        h2:=Height DIV 2;
        PutBlock(Left,Top,Buffer^,NormalPut);
        FreeMem(Buffer,BufSize);
        PutBlock(Left,Top+h2+1,Buffer2^,NormalPut);
        FreeMem(Buffer2,Buf2Size);
      END
      ELSE BEGIN
        PutBlock(Left,Top,Buffer^,NormalPut);
        FreeMem(Buffer,BufSize);
      END;
      Buffer:=nil; BufSize:=0;
      Buffer2:=nil; Buf2Size:=0;
    END
    ELSE GfxWin.Leave;
    GenericWindow.Close;
  END;
END; {PROC GfxWin.Close}

FUNCTION GfxWin.MemUsage:LongInt;
{ - Returns amount of Storage Space required by a graphic window (in bytes) }
BEGIN
  MemUsage:=ImageSize(Left,Top,Right,Bottom);
END; {FUNC GfxWin.MemUsage}

{---------------------------------------------------------- WorldWorkSpace ---
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
}

CONSTRUCTOR WorldWorkSpace.Init(x,y,w,h:Integer; scleft,scbottom:Integer);
BEGIN
  GfxWorkspace.Init(x,y,w,h);
  wxmin:=Left;  wxmax:=Right;
  wymin:=Top;   wymax:=Bottom;
  xscleft:=scleft;     xsf:=1.0;
  yscbottom:=scbottom; ysf:=1.0;
  xScaleMargin:=40;    yScaleMargin:=16;
  Recalculate;
END; {CONS WorldWorkSpace.Init}


PROCEDURE WorldWorkSpace.Recalculate;
BEGIN
  dxmin:=Left+5;  dxmax:=Right-5;
  dymin:=Top+5;   dymax:=Bottom-5;
  CASE xscleft OF
    -1 : dxmin:=dxmin+xScaleMargin;  {Scale on left side}
     1 : dxmax:=dxmax-xScaleMargin;  {Scale on right side}
  END;
  CASE yscbottom OF
    -1 : dymax:=dymax-yScaleMargin;  {Scale below graph}
     1 : dymin:=dymin+yScaleMargin;  {Scale above graph}
  END;
  dx:=(dxmax-dxmin)/(wxmax-wxmin);
  dy:=(dymax-dymin)/(wymax-wymin);
END; {PROC WorldWorkSpace.Recalculate}

PROCEDURE WorldWorkSpace.World(x1,y1,x2,y2:Float);
BEGIN
  wxmin:=x1;  wymin:=y1; wxmax:=x2; wymax:=y2;
  IF x1>x2 THEN Exchange(wxmin,wxmax,SizeOf(wxmin));
  IF y1>y2 THEN Exchange(wymin,wymax,SizeOf(wymin));
  Recalculate;
END; {PROC WorldWorkSpace.SetWorld}

FUNCTION WorldWorkSpace.xWtoD(x:Float):Integer;
BEGIN
 xWtoD:=dxmin+round((x-wxmin)*dx);
END; {FUNC WorldWorkSpace.xWtoD}

FUNCTION WorldWorkSpace.yWtoD(y:Float):Integer;
BEGIN
  yWtoD:=dymax-round((y-wymin)*dy);
END; {FUNC WorldWorkSpace.yWtoD}

PROCEDURE WorldWorkSpace.PutPixel(x,y: Float; color:word);
BEGIN
  Graph.PutPixel(xWtoD(x),yWtoD(y),Color);
END; {PROC WorldWorkSpace.PutPixel}

PROCEDURE WorldWorkSpace.Line(x1,y1,x2,y2:Float);
BEGIN
  Graph.Line(xWtoD(x1),yWtoD(y1),xWtoD(x2),yWtoD(y2));
END; {PROC WorldWorkSpace.Line}

PROCEDURE WorldWorkSpace.PointTo(x,y:Float);
BEGIN
  Graph.MoveTo(xWtoD(x),yWtoD(y));
END; {PROC WorldWorkSpace.PointTo}

PROCEDURE WorldWorkSpace.LineTo(x,y:Float);
BEGIN
  Graph.LineTo(xWtoD(x),yWtoD(y));
END; {PROC WorldWorkSpace.LineTo}

PROCEDURE WorldWorkSpace.Circle(x,y,radius:Float);
BEGIN
  Graph.Ellipse(xWtoD(x),yWtoD(y),0,360,
                Round(radius*dx),Round(radius*dy));
END; {PROC WorldWorkSpace.Circle}

PROCEDURE WorldWorkSpace.Bar(x1,y1,x2,y2:Float);
BEGIN
  Graph.Bar(xWtoD(x1),yWtoD(y1),xWtoD(x2),yWtoD(y2));
END; {PROC WorldWorkSpace.Bar}

PROCEDURE WorldWorkSpace.Rectangle(x1,y1,x2,y2:Float);
BEGIN
  Graph.Rectangle(xWtoD(x1),yWtoD(y1),xWtoD(x2),yWtoD(y2));
END; {PROC WorldWorkSpace.Rectangle}

PROCEDURE WorldWorkSpace.Bar3D(x1,y1,x2,y2:Float; Depth:Integer; _Top:Boolean);
BEGIN
  Graph.Bar3D(xWtoD(x1),yWtoD(y1),xWtoD(x2),yWtoD(y2),Depth,_Top);
END;{PROC wBar3D}

PROCEDURE WorldWorkSpace.PolywToD(NumPoints:Word;
                                  VAR wPolyPoints; VAR dPolyPoints);
CONST
  PolyMax = 1000;
TYPE
  wp = ARRAY[1..PolyMax]
       OF RECORD
            x,y : Float;
       END;
  dp = ARRAY[1..PolyMax]
       OF RECORD
         x,y : Integer;
       END;
VAR
  i : Integer;
BEGIN
  FOR i:=1 TO NumPoints
  DO BEGIN
    dp(dPolyPoints)[i].x:=xWtoD(wp(wPolyPoints)[i].x);
    dp(dPolyPoints)[i].y:=yWtoD(wp(wPolyPoints)[i].y);
  END;
END; {PROC WorldWorkSpace.PolywToD}

PROCEDURE WorldWorkSpace.DrawPoly(NumPoints:Word; VAR wPolyPoints);
VAR
  dPolyPoints : Pointer;
BEGIN
  GetMem(dPolyPoints,2*NumPoints);
  PolywToD(NumPoints,wPolyPoints,dPolyPoints^);
  Graph.DrawPoly(NumPoints,dPolyPoints^);
  FreeMem(dPolyPoints,2*NumPoints);
END; {PROC WorldWorkSpace.DrawPoly}

PROCEDURE WorldWorkSpace.FillPoly(NumPoints:Word; VAR wPolyPoints);
VAR
  dPolyPoints : Pointer;
BEGIN
  GetMem(dPolyPoints,2*NumPoints);
  PolywToD(NumPoints,wPolyPoints,dPolyPoints^);
  Graph.FillPoly(NumPoints,dPolyPoints^);
  FreeMem(dPolyPoints,2*NumPoints);
END; {PROC WorldWorkSpace.FillPoly}

PROCEDURE WorldWorkSpace.Text(x,y:Float; theText:string);
BEGIN
{  LFGraph.TextXY(xWtoD(x),yWtoD(y),theText);}
   Wrt(xWtoD(x)-Left,yWtoD(y)-Top,CC,theText);
END; {PROC WorldWorkSpace.Text}


CONST
  ScaleFactor : Array[1..12] OF Word =
  (1,2,5,10,20,25,50,100,200,250,500,1000);

PROCEDURE WorldWorkSpace.xScale(Style:Word);
{ - Draw the x-axis scale ... }
VAR
  n       : LongInt;
  i,nd    : Integer;
  minim,
  dlr,y,x : Float;
  xd      : Word;
BEGIN
  x:=wxmax-wxmin; i:=0;
  REPEAT
    inc(i); dlr:=ScaleFactor[i]; n:=Round(x/dlr);
  UNTIL n<15;
  minim:=trunc(wxmin/dlr)*dlr;
  IF Frac(dlr/xsf)=0 THEN nd:=0 ELSE nd:=1;
  SetTextJustify(CenterText,TopText); TextBlackOut:=True;
  SetLineStyle(Style,0,1);
  FOR i:=0 TO n DO
  BEGIN
    x:=minim+(dlr*i); xd:=xWtoD(x);
    IF (xd<=dxmax) and (xd>=dxmin) THEN
    BEGIN
     SetColor(Pane.Norm.FG);
     Graph.OutTextXY(xd,dymax+4,FloatStr(x/xsf,0,nd));
     SetColor(Pane.Low.FG);
     Graph.Line(xd,dymin,xd,dymax);
     Graph.PutPixel(xd,succ(dymax),Pane.Norm.FG);
    END;
  END;
  SetLineStyle(SolidLn,0,1);
  Graph.Line(dxmin,dymax,dxmax,dymax);
END; {PROC WorldWorkSpace.xScale}

PROCEDURE WorldWorkSpace.xTimeScale(Style:Word; Hours:Word; Now:DateTime);
{ - Draw an x-axis time scale
    WARNING: Will change the x-axis World coordinates !
}
VAR
  FirstDay : Boolean;
  days,h   : Word;
  id,ih    : Integer;
  x        : Float;
  xd       : Word;
BEGIN
  Days:=Hours DIV 24;
  h:=1;
  REPEAT
    xd:=xWtoD(h*3600)-xWtoD(0);
    CASE h OF
      1..3 : Inc(h);
      4,6  : Inc(h,2);
      8    : h:=12;
    END;
  UNTIL (xd>20) or (h=12);
  SetTextJustify(CenterText,CenterText); TextBlackOut:=True;
  SetLineStyle(Style,0,1);
  FOR id:=1 TO Days
  DO BEGIN
    FirstDay:=id=Days;
    x:=-id*24*3600.0;
    ih:=0;
    REPEAT
      IF ((ih=0) and FirstDay) or (ih<>0)
      THEN BEGIN
        xd:=xWToD(x+(ih*3600.0));
        SetColor(Pane.Low.FG);
        Graph.Line(xd,dymin,xd,dymax);
        IF (ih=0) or (ih=24)
        THEN BEGIN
          SetLineStyle(SolidLn,0,1);
          Graph.Line(xd,dymin,xd,dymax+18);
          Graph.Line(xd-2,dymax+18,xd+2,dymax+18);
          SetLineStyle(Style,0,1);
        END ELSE
        Graph.PutPixel(xd,succ(dymax),Pane.Norm.FG);
        SetColor(Pane.Norm.FG);
        Graph.OutTextXY(xd,dymax+5,IntStr(ih,0));
      END;
      Inc(ih,h);
    UNTIL ih>24;
    Graph.OutTextXY(xWToD(x+12*3600.0),dymax+5+11,LookDate(Now));
    DecDays(Now,1);
  END;
  SetColor(Pane.Low.FG);
  SetLineStyle(SolidLn,0,1);
  Graph.Line(dxmin,dymax,dxmax,dymax);
END; {PROC WorldWorkSpace.xTimeScale}


PROCEDURE WorldWorkSpace.yScale(Style:Word);
{ - Draw the y-axis scale }
VAR
  n       : LongInt;
  i,nd    : Integer;
  minim,
  dlr,y,x : Float;
  yd,sp,dp,lp : Word;
BEGIN
  y:=wymax-wymin; i:=0;
  REPEAT
    inc(i); dlr:=ScaleFactor[i]; n:=Round(y/dlr);
    yd:=yWtoD(dlr)-yWtoD(dlr+dlr);
  UNTIL (n<20) and (yd>10);
  minim:=trunc(wymin/dlr)*dlr;
  IF Frac(dlr/ysf)=0 THEN nd:=0 ELSE nd:=1;
  IF xscLeft=1
  THEN BEGIN
    SetTextJustify(LeftText,CenterText);
    sp:=dxmax+4; dp:=dxmax+1; lp:=dxmax;
  END
  ELSE BEGIN
    SetTextJustify(RightText,CenterText);
    sp:=dxmin-3; dp:=dxmin-1; lp:=dxmin;
  END;
  TextBlackOut:=False;
  SetLineStyle(Style,0,1);
  FOR i:=0 TO n DO
  BEGIN
    y:=minim+(dlr*i); yd:=yWtoD(y);
    IF (yd<=dymax) and (yd>=dymin) THEN
    BEGIN
      SetColor(Pane.Norm.FG);
      Graph.OutTextXY(sp,yd, FloatStr(y/ysf,0,nd));
      SetColor(Pane.Low.FG);
      Graph.Line(dxmin,yd,dxmax,yd);
      Graph.PutPixel(dp,yd,Pane.Norm.FG);
    END;
  END;
  SetLineStyle(SolidLn,0,1);
  Graph.Line(lp,dymin,lp,dymax);
END; {PROC WorldWorkSpace.yScale}

PROCEDURE WorldWorkSpace.Scales(vStyle,hStyle:Word);
BEGIN
  xScale(vStyle);
  yScale(hStyle);
END; {PROC WorldWorkSpace.Scales}

{----------------------------------------------------------- LogWorkSpace ---
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
}

CONSTRUCTOR LogWorkSpace.Init(x,y,w,h:Integer; scleft,scbottom:Integer);
BEGIN
  WorldWorkspace.Init(x,y,w,h,scleft,scbottom);
  xLog:=False; xBase:=1; xDec:=5;
  yLog:=False; yBase:=1; yDec:=5;
  Recalculate;
END; {CONS LogWorkSpace.Init}

PROCEDURE LogWorkSpace.Recalculate;
BEGIN
  WorldWorkSpace.Recalculate;
  ldx:=(wxmax-wxmin)/(xDec-xBase);
  ldy:=(wymax-wymin)/(yDec-yBase);
END; {PROC LogWorkSpace.Recalculate}

PROCEDURE LogWorkSpace.SetXLog(Dec,Base:Integer);
BEGIN
  xLog:=True; xDec:=Dec; xBase:=Base;
  Recalculate;
END; {PROC LogWorkSpace.SetXLog}

PROCEDURE LogWorkSpace.SetYLog(Dec,Base:Integer);
BEGIN
  yLog:=True; yDec:=Dec; yBase:=Base;
  Recalculate;
END; {PROC LogWorkSpace.SetYLog}

FUNCTION LogWorkSpace.xWtoD(x:Float):Integer;
VAR
  ix : Integer;
BEGIN
  IF xLog THEN ix:=Round(Ln(x)/2.302585093*ldx*dx)
   ELSE ix:=round((x-wxmin)*dx);
   xWtoD:=dxmin+ix;
END; {FUNC LogWorkSpace.xWtoD}

FUNCTION LogWorkSpace.yWtoD(y:Float):Integer;
VAR
  iy : Integer;
BEGIN
  IF yLog THEN iy:=Round(Ln(y)/2.302585093*ldy*dy)
   ELSE iy:=round((y-wymin)*dy);
  yWtoD:=dymax-iy;
END; {FUNC LogWorkSpace.yWtoD}


{-------------------------------------------------------------- Init parts ---

}


VAR
  PrevExitProc : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  GraphAreaLimit.Done;
  Units.Leave(LFGfxWinMsg,MemAvail);
END;

BEGIN
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  Units.Enter(LFGfxWinMsg,MemAvail,CSeg);
  MinimumWidth:=24;
  MinimumHeight:=32;
  GraphAreaLimit.Init(0,0,640,480);
END.
