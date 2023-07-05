{$DEFINE NoDebug}
{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT LFWindow;

INTERFACE
USES LFsystem,Objects;
CONST
  LFwindowMsg = ' LFwindow.1 19900831 Lars Fosdal ';

TYPE
  DefColorSet = RECORD
    Norm,
    High,
    Low  : Byte;
  END; {REC DefColorSet}

  DefWinColor = RECORD {of default colors for a window}
    Pane   : DefColorSet; { Window Pane }
    Frame  : DefColorSet; { Frame }
    Title  : DefColorSet; { Title }
    SelBar : DefColorSet; { Select Bar }
  END; {REC DefWinColor}

  SingleColor = OBJECT
    CBF : Byte;
    PROCEDURE SetAll(NewBG,NewFG:Byte);
    PROCEDURE SetBG(NewBG:Byte);
    PROCEDURE SetFG(NewFG:Byte);
    FUNCTION  BG:Byte;
    FUNCTION  FG:Byte;
    FUNCTION  All:Byte;
    FUNCTION  ExOR:Byte;
  END;

  ColorSet = OBJECT
    Norm,
    High,
    Low  : SingleColor;
    PROCEDURE SetAllBG(NewBG:Byte);
    PROCEDURE SetDefault(NewDef:DefColorSet);
  END;

  WinColor = OBJECT {of colors for a window}
    Frame  : ColorSet; { Frame }
    Title  : ColorSet; { Title }
    PROCEDURE SetDefault(NewDef:DefWinColor);
  END; {OBJ WinColor}

  anAreaPtr = ^anArea;
  anArea = OBJECT(TObject)
    lx,uy,xw,yh : Integer;
    CONSTRUCTOR Init(x,y,w,h:Integer);
    DESTRUCTOR  Done;                              VIRTUAL;
    PROCEDURE   MoveTo(x,y:Integer);               VIRTUAL;
    PROCEDURE   MoveRel(dx,dy:Integer);            VIRTUAL;
    PROCEDURE   SizeSet(w,h:Integer);              VIRTUAL;
    PROCEDURE   SizeRel(dw,dh:Integer);            VIRTUAL;
    PROCEDURE   InternalInit;                      VIRTUAL;
    FUNCTION    InXRange(x:Integer):Boolean;
    FUNCTION    InYRange(y:Integer):Boolean;
    FUNCTION    InRange(x,y:Integer):Boolean;
    FUNCTION    Left:Integer;
    FUNCTION    Right:Integer;
    FUNCTION    Top:Integer;
    FUNCTION    Bottom:Integer;
    FUNCTION    Width:Integer;
    FUNCTION    Height:Integer;
  END;{OBJ anArea}

  CursorSize = (SplitCsr,FullCsr,HalfCsr,NormalCsr,HiddenCsr);
  PWorkSpace = ^GenericWorkSpace;
  PWindow    = ^GenericWindow;
  PCursor    = ^GenericCursor;
  GenericCursor = OBJECT(TObject)
    Owner  : PWorkSpace;
    Hidden : Boolean;
    State  : CursorSize;
    x,y    : Integer;
    CONSTRUCTOR Init(AtX,AtY:Integer; OwnerArea:PWorkSpace);
    DESTRUCTOR Done;                            VIRTUAL;
    PROCEDURE ChangeState(NewState:CursorSize); VIRTUAL;
    PROCEDURE Mode(NewState:CursorSize);
    FUNCTION  AbsX:Integer;                VIRTUAL;
    FUNCTION  AbsY:Integer;                VIRTUAL;
    PROCEDURE MoveTo(NewX,NewY:Integer);   VIRTUAL;
    PROCEDURE Hide;                        VIRTUAL;
    PROCEDURE Show;                        VIRTUAL;
    PROCEDURE Toggle;                      VIRTUAL;
  END; {OBJ GenericCursor}

  WorkSpaceLayout = PROCEDURE (WS:PWorkSpace);

  GenericWorkSpace = OBJECT(AnArea)
    Cursor  : PCursor;
    Layout  : WorkSpaceLayout;
    OpenNow : Boolean;
    Pane,
    SelBar  : ColorSet;
    CONSTRUCTOR Init(x,y,w,h:Integer);
    CONSTRUCTOR InitTxt(x,y,Columns,Lines:Integer);
    DESTRUCTOR  Done;                              VIRTUAL;
    PROCEDURE   MoveTo(x,y:Integer);               VIRTUAL;
    PROCEDURE   MoveRel(dx,dy:Integer);            VIRTUAL;
    PROCEDURE   SizeSet(w,h:Integer);              VIRTUAL;
    PROCEDURE   SizeRel(dw,dh:Integer);            VIRTUAL;
    PROCEDURE   MoveSize(x,y,w,h:Integer);         VIRTUAL;
    PROCEDURE   TxtAdjSize(Columns,Lines:Integer); VIRTUAL;
    PROCEDURE   TxtBar(x,y,w:Integer; cf:SingleColor); VIRTUAL;
    PROCEDURE   SetLayout(NewLayout:WorkSpaceLayout);      VIRTUAL;
    PROCEDURE   Open;                              VIRTUAL;
    PROCEDURE   Select;                            VIRTUAL;
    PROCEDURE   Frame;                             VIRTUAL;
    PROCEDURE   Clear;                             VIRTUAL;
    PROCEDURE   ScrollUp(Lines:Integer);           VIRTUAL;
    PROCEDURE   ScrollDown(Lines:Integer);         VIRTUAL;
    PROCEDURE   Wrt(x,y:Integer; cf:SingleColor; Txt:String);      VIRTUAL;
    PROCEDURE   WrtTxt(x,y:Integer; cf:SingleColor; Txt:String);   VIRTUAL;
    PROCEDURE   Center(y:Integer; cf:SingleColor; Txt:String);     VIRTUAL;
    PROCEDURE   Leave;                             VIRTUAL;
    PROCEDURE   Close;                             VIRTUAL;
    FUNCTION    isOpen:Boolean;
  END; {OBJ GenericWorkSpace}

  GenericWindow = OBJECT(anArea)
    Buffer     : Pointer;
    BufSize    : Word;
    WorkSpace  : PWorkSpace;
    ilx,iuy,
    irx,ily    : Integer; { Border widths }
    SaveBackground,
    OpenNow    : Boolean;
    C          : WinColor;
    Header,
    Footer     : PString;
    CONSTRUCTOR Init(x,y,w,h:Integer; BackGrSave:Boolean);
    CONSTRUCTOR InitTxt(x,y,Columns,Lines:Integer; BackGrSave:Boolean);
    DESTRUCTOR  Done;                              VIRTUAL;
    PROCEDURE   Title(Head,Foot:String);           VIRTUAL;
    PROCEDURE   TitlePtr(Head,Foot:PString);       VIRTUAL;
    PROCEDURE   MoveTo(x,y:Integer);               VIRTUAL;
    PROCEDURE   MoveRel(dx,dy:Integer);            VIRTUAL;
    PROCEDURE   SizeSet(w,h:Integer);              VIRTUAL;
    PROCEDURE   SizeRel(dw,dh:Integer);            VIRTUAL;
    PROCEDURE   TxtAdjSize(Columns,Lines:Integer); VIRTUAL;
    PROCEDURE   Open;                              VIRTUAL;
    PROCEDURE   Select;                            VIRTUAL;
    PROCEDURE   InternalInit;                      VIRTUAL;
    PROCEDURE   Frame;                             VIRTUAL;
    PROCEDURE   Clear;                             VIRTUAL;
    PROCEDURE   Leave;                             VIRTUAL;
    PROCEDURE   Close;                             VIRTUAL;
    FUNCTION    Save:Boolean;
    FUNCTION    isOpen:Boolean;
    FUNCTION    MemUsage:LongInt;                  VIRTUAL;
    FUNCTION    iInXRange(x:Integer):Boolean;
    FUNCTION    iInYRange(y:Integer):Boolean;
    FUNCTION    iInRange(x,y:Integer):Boolean;
    FUNCTION    iLeft:Integer;
    FUNCTION    iRight:Integer;
    FUNCTION    iTop:Integer;
    FUNCTION    iBottom:Integer;
    FUNCTION    iWidth:Integer;
    FUNCTION    iHeight:Integer;
  END;{OBJ GenericWindow}

  PROCEDURE EmptyWorkSpace(WS:PWorkSpace);

CONST
  NC       =-1;  {NC = No Change}
  PopUp    = 0;
  PullDown = 1;
  PullUp   = 2;
  DefaultWindowType : Byte=PopUp;
  DefaultFrameType  : Byte=1;     {Single Frame}
CONST
  MinimumWidth    : Integer = 3;
  MinimumHeight   : Integer = 3;
CONST
  WindowAutoSave  = $0001;
  WindowAutoClear = $0002;

CONST
  b2e : ARRAY[0..7] OF Byte =  ($01,$02,$04,$08,$10,$20,$40,$80);
CONST
  w2e : ARRAY[0..15] OF Word = ($01,$02,$04,$08,$10,$20,$40,$80,
                $0100,$0200,$0400,$0800,$1000,$2000,$4000,$8000);

IMPLEMENTATION

USES Crt,Dos;

{--- Methods for Object : SingleColor ---------------------------------------}

PROCEDURE SingleColor.SetAll(NewBG,NewFG:Byte);
{ - Set both FG and BG colors}
BEGIN
  CBF:=(NewFG and $0F)+((NewBG and $0F) shl 4);
END; {PROC SingleColor.SetAll}

PROCEDURE SingleColor.SetBG(NewBG:Byte);
{ - Set Background nibble of color}
BEGIN
  CBF:=(CBF and $0F)+((NewBG and $0F) shl 4);
END; {PROC SingleColor.SetBG}

PROCEDURE SingleColor.SetFG(NewFG:Byte);
{ - Set Foreground nibble of color}
BEGIN
  CBF:=(CBF and $F0)+(NewFG and $0F);
END; {PROC SingleColor.SetFG}

FUNCTION SingleColor.BG:Byte;
{ - Return Background of Color}
BEGIN
  BG:=CBF shr 4;
END; {FUNC SingleColor.BG}

FUNCTION SingleColor.FG:Byte;
{ - Return Foreground of Color}
BEGIN
  FG:=CBF and $0F;
END; {FUNC SingleColor.FG}

FUNCTION SingleColor.All:Byte;
{ - Return both BG and FG Color}
BEGIN
  All:=CBF;
END; {FUNC SingleColor.All}

FUNCTION SingleColor.ExOR:Byte;
{ - Return BG Xor FG = Which color to Xor onto BG to give FG}
BEGIN
  ExOR:=BG XOR FG;
END; {FUNC SingleColor.All}

{--- Methods for Object : ColorSet ------------------------------------------}

PROCEDURE ColorSet.SetAllBG(NewBG:Byte);
{ - Set same BG for all colors in group}
BEGIN
  Norm.SetBG(NewBG);
  High.SetBG(NewBG);
  Low.SetBG(NewBG);
END; {PROC ColorSet.SetAllBG}

PROCEDURE ColorSet.SetDefault(NewDef:DefColorSet);
{ - Set all colors in set to Default Rec.}
BEGIN
  Norm.CBF:=NewDef.Norm;
  High.CBF:=NewDef.High;
  Low.CBF:=NewDef.Low;
END; {PROC ColorSet.SetDefault}

{--- Methods for Object : WinColor ------------------------------------------}

PROCEDURE WinColor.SetDefault(NewDef:DefWinColor);
{ - Set all colors in WinColor to Default Rec.}
BEGIN
  Frame.SetDefault(NewDef.Frame);
  Title.SetDefault(NewDef.Title);
END; {PROC WinColor.SetDefault}


{--- Methods for Object : anArea --------------------------------------------}

CONSTRUCTOR anArea.Init(x,y,w,h:Integer);
BEGIN { - Initialize object}
  TObject.Init;
  lx:=x; xw:=w;
  uy:=y; yh:=h;
  InternalInit;
  SizeSet(w,h);
END;{CONS anArea.Init}

DESTRUCTOR anArea.Done;
BEGIN { - Clean up after object}
  {Nothing to do}
END;{DEST anArea.Done}

PROCEDURE anArea.MoveTo(x,y:Integer);
BEGIN { - Place Area (Assume width and height within limits)}
  {Abstract}
END;{PROC anArea.MoveTo}

PROCEDURE anArea.MoveRel(dx,dy:Integer);
BEGIN { - Drag Area Left/up(-) Right/Down(+)}
  MoveTo(Left+dx,Top+dy);
END;{PROC anArea.MoveRel}

PROCEDURE anArea.SizeSet(w,h:Integer);
BEGIN { - Dimension Area}
  {Abstract}
END;{PROC anArea.SizeSet}

PROCEDURE anArea.SizeRel(dw,dh:Integer);
BEGIN { - Expand(+)/Contract(-) Area}
  SizeSet(Width+dw,Height+dh);
END;{anArea.SizeRel}

PROCEDURE AnArea.InternalInit;
BEGIN
  { Pseudo Abstract }
END; {PROC AnArea.InternalInit}

FUNCTION anArea.InXRange(x:Integer):Boolean;
BEGIN { - Is value x within x-range of area ?}
  InXRange:=(x>=Left) and (x<=Right);
END;{FUNC anArea.InXRange}

FUNCTION anArea.InYRange(y:Integer):Boolean;
BEGIN { - Is value y within y-range of area ?}
  InYRange:=(y>=Top) and (y<=Bottom);
END;{FUNC anArea.InRange}

FUNCTION anArea.InRange(x,y:Integer):Boolean;
BEGIN { - Is  point(x,y) within area ?}
  InRange:=InXRange(X) and InYRange(Y);
END;{FUNC anArea.InRange}

FUNCTION anArea.Left:Integer;
BEGIN { - Return left edge of area}
  Left:=lx;
END;{FUNC anArea.Left}

FUNCTION anArea.Right:Integer;
BEGIN { - Return right edge of area}
  Right:=lx+xw-1;
END;{FUNC anArea.Right}

FUNCTION anArea.Top:Integer;
BEGIN { - Return top edge of area}
  Top:=uy;
END;{FUNC anArea.Top}

FUNCTION anArea.Bottom:Integer;
BEGIN { - Return bottom edge of area}
  Bottom:=uy+yh-1;
END;{FUNC anArea.Bottom}

FUNCTION anArea.Width:Integer;
BEGIN { - Return width of area}
  Width:=xw;
END;{FUNC anArea.Width}

FUNCTION anArea.Height:Integer;
BEGIN { - Return height of area}
  Height:=yh;
END;{FUNC anArea.Height}


{--- Methods for Object : GenericCursor -------------------------------------}

CONSTRUCTOR GenericCursor.Init(AtX,AtY:Integer; OwnerArea:PWorkSpace);
{ - Initialize new cursor}
BEGIN
  TObject.Init;
  Owner:=OwnerArea;
  Hidden:=True;
  MoveTo(atX,atY);
  Mode(HiddenCsr);
END; {CONS GenericCursor.Init}

DESTRUCTOR GenericCursor.Done;
{ - Cleanup after cursor}
BEGIN
  Hide;
END; {CONS GenericCursor.Done}

PROCEDURE GenericCursor.ChangeState(NewState:CursorSize);
{ - Used by GC.Mode to adjust cursor variables }
BEGIN
  State:=NewState;
END; {GenericCursor.ChangeState}

PROCEDURE GenericCursor.Mode(NewState:CursorSize);
{ - Change cursor mode}
VAR
  Visible : Boolean;
BEGIN
  IF NewState<>State
  THEN BEGIN
    Visible:=not Hidden;
    IF Visible THEN Hide;
    ChangeState(NewState);
    IF Visible THEN Show;
  END;
END; {PROC GenericCursor.Mode}

FUNCTION  GenericCursor.AbsX:Integer;
{ - Return cursor x-pos relative to screen origin}
BEGIN
  TrapAbstract;
END; {FUNC GenericCursor.AbsX}

FUNCTION  GenericCursor.AbsY:Integer;
{ - Return cursor y-pos relative to screen origin}
BEGIN
  TrapAbstract;
END; {FUNC GenericCursor.AbsY}

PROCEDURE GenericCursor.MoveTo(NewX,NewY:Integer);
{ - Move cursor within owner-window}
BEGIN
  TrapAbstract;
END; {PROC GenericCursor.MoveTo}

PROCEDURE GenericCursor.Hide;
{ - Turn cursor off}
BEGIN
  Hidden:=True;
END; {PROC GenericCursor.Hide}

PROCEDURE GenericCursor.Show;
{ - turn cursor on}
BEGIN
  Hidden:=False;
END; {PROC GenericCursor.Show}

PROCEDURE GenericCursor.Toggle;
{ - Toggle cursor on/off or off/on}
BEGIN
  IF Hidden
  THEN Show
  ELSE Hide;
END; {PROC GenericCursor.Toggle}

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴� GenericWorkSpace 컴�}

PROCEDURE EmptyWorkSpace(WS:PWorkSpace);
BEGIN
END;{EmptyWorkSpace}

CONSTRUCTOR GenericWorkSpace.Init(x,y,w,h:Integer);
BEGIN
  anArea.Init(x,y,w,h);
  OpenNow:=False;
  SizeSet(w,h);
  MoveTo(x,y);
  SetLayOut(EmptyWorkSpace);
END;{CONS GenericWorkSpace.Define}

CONSTRUCTOR GenericWorkSpace.InitTxt(x,y,Columns,Lines:Integer);
BEGIN
  anArea.Init(x,y,Columns,Lines);
  OpenNow:=False;
  SizeSet(Columns,Lines);
  MoveTo(x,y);
  SetLayOut(EmptyWorkSpace);
END;{CONS GenericWorkSpace.Define}

DESTRUCTOR GenericWorkSpace.Done;
BEGIN
  IF isOpen THEN Close;
END;{DEST GenericWorkSpace.Done}

PROCEDURE GenericWorkSpace.MoveTo(x,y:Integer);
{ - Place Window (Assume width and height within limits)}
BEGIN
  TrapAbstract;
END;{PROC GenericWorkSpace.MoveTo}

PROCEDURE GenericWorkSpace.MoveRel(dx,dy:Integer);
BEGIN { - Drag Window Left/up(-) Right/Down(+)}
  MoveTo(Left+dx,Top+dy);
END;{PROC GenericWorkSpace.MoveRel}

PROCEDURE GenericWorkSpace.SizeSet(w,h:Integer);
{ - Dimension Window }
BEGIN
  TrapAbstract;
END;{PROC GenericWorkSpace.SizeSet}

PROCEDURE GenericWorkSpace.SizeRel(dw,dh:Integer);
{ - Expand(+)/Contract(-) Window}
BEGIN 
  SizeSet(Width+dw,Height+dh);
END;{GenericWorkSpace.SizeRel}

PROCEDURE GenericWorkSpace.MoveSize(x,y,w,h:Integer);
{ - ReDimension Window }
BEGIN
  MoveTo(x,y);
  SizeSet(w,h);
END;{PROC GenericWorkSpace.MoveSize}


PROCEDURE GenericWorkSpace.TxtAdjSize(Columns,Lines:Integer);
{ - Adjust size of window to contain Columns*Lines chars }
BEGIN
  TrapAbstract;
END;{PROC GenericWorkSpace.TxtAdjSize}

PROCEDURE GenericWorkSpace.TxtBar(x,y,w:Integer; cf:SingleColor);
{ - Draw a Bar }
BEGIN
  TrapAbstract;
END;{PROC GenericWorkSpace.TxtBar}

PROCEDURE GenericWorkSpace.SetLayout(NewLayout:WorkSpaceLayout);
BEGIN
  Layout:=NewLayout;
END;{PROC GenericWorkSpace.LayOut}

PROCEDURE GenericWorkSpace.Open;
BEGIN
  OpenNow:=True;
  LayOut(@Self);
END;{PROC GenericWorkSpace.Open}

PROCEDURE GenericWorkSpace.Select;
BEGIN
  IF Not OpenNow THEN Open;
END;{PROC GenericWorkSpace.Select}

PROCEDURE GenericWorkSpace.Frame;
BEGIN { - Frame the window}
  { * Abstract}
END;{PROC GenericWorkSpace.Frame}

PROCEDURE GenericWorkSpace.Clear;
BEGIN { - Clear pane of window}
  { * Abstract}
END;{PROC GenericWorkSpace.Clear}

PROCEDURE GenericWorkSpace.ScrollUp(Lines:Integer);
BEGIN
  { * Abstract}
END;{PROC GenericWorkSpace.ScrollUp}

PROCEDURE GenericWorkSpace.ScrollDown(Lines:Integer);
BEGIN
  { * Abstract}
END;{PROC GenericWorkSpace.ScrollDown}

PROCEDURE GenericWorkSpace.Wrt(x,y:Integer; cf:SingleColor; Txt:String);
BEGIN { - Wrt relative to window}
  { * Abstract}
END;{PROC GenericWorkSpace.Wrt}

PROCEDURE GenericWorkSpace.WrtTxt(x,y:Integer; cf:SingleColor; Txt:String);
BEGIN { - Wrt text relative to window}
  { * Abstract}
END;{PROC GenericWorkSpace.WrtTxt}

PROCEDURE GenericWorkSpace.Center(y:Integer; cf:SingleColor;  Txt:String);
BEGIN { - Center inside window}
  { * Abstract}
END;{PROC GenericWorkSpace.Center}

PROCEDURE GenericWorkSpace.Leave;
BEGIN
  { * Abstract}
END;{PROC GenericWorkSpace.Leave}

PROCEDURE GenericWorkSpace.Close;
BEGIN
  OpenNow:=False;
END;{PROC GenericWorkSpace.Close}

FUNCTION GenericWorkSpace.isOpen:Boolean;
BEGIN
  isOpen:=OpenNow;
END;{FUNC GenericWorkSpace.isOpen}

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 GenericWindow 컴�}

CONSTRUCTOR GenericWindow.Init(x,y,w,h:Integer; BackGrSave:Boolean);
BEGIN
  anArea.Init(x,y,w,h);
  SaveBackground:=BackGrSave;
  OpenNow:=False;
  SizeSet(w,h);
  MoveTo(x,y);
  Header:=nil;
  Footer:=nil;
  Buffer:=nil;
  BufSize:=0;
END;{CONS GenericWindow.Define}

CONSTRUCTOR GenericWindow.InitTxt(x,y,Columns,Lines:Integer; BackGrSave:Boolean);
BEGIN
  anArea.Init(x,y,Columns,Lines);
  SaveBackground:=BackGrSave;
  OpenNow:=False;
  SizeSet(Columns,Lines);
  MoveTo(x,y);
  Header:=nil;
  Footer:=nil;
  Buffer:=nil;
  BufSize:=0;
END;{CONS GenericWindow.Define}

DESTRUCTOR GenericWindow.Done;
BEGIN
  IF isOpen THEN Close;
  IF Header<>nil THEN FreeMem(Header,Length(Header^)+1);
  IF Footer<>nil THEN FreeMem(Footer,Length(Footer^)+1);
  Dispose(WorkSpace,Done);
END;{DEST GenericWindow.Done}

PROCEDURE GenericWindow.Title(Head,Foot:String);
{ - Get Title text(s) and allocate space fo them}
VAR
  h,f:PString;
BEGIN
  IF Head<>''
  THEN BEGIN
    h:=Addr(Head);
  END ELSE h:=nil;
  IF Foot<>''
  THEN BEGIN
    f:=Addr(Foot);
  END ELSE f:=nil;
  TitlePtr(h,f);
END;{PROC GenericWindow.Title}

PROCEDURE GenericWindow.TitlePtr(Head,Foot:PString);
{ - Connect Title(s) to Window}
VAR
  l : Word;
BEGIN
  IF Head<>nil
  THEN BEGIN
    IF Header<>nil THEN PSDispose(Header);
    PSNew(Header,' '+Head^+' ');
  END;
  IF Foot<>nil
  THEN BEGIN
    IF Footer<>nil THEN PSDispose(Footer);
    PSNew(Footer,' '+Foot^+' ');
  END;
END;{PROC GenericWindow.TitlePtr}

PROCEDURE GenericWindow.MoveTo(x,y:Integer);
{ - Place Window (Assume width and height within limits)}
BEGIN
  TrapAbstract;
END;{PROC GenericWindow.MoveTo}

PROCEDURE GenericWindow.MoveRel(dx,dy:Integer);
BEGIN { - Drag Window Left/up(-) Right/Down(+)}
  MoveTo(Left+dx,Top+dy);
END;{PROC GenericWindow.MoveRel}

PROCEDURE GenericWindow.SizeSet(w,h:Integer);
{ - Dimension Window }
BEGIN
  TrapAbstract;
END;{PROC GenericWindow.SizeSet}

PROCEDURE GenericWindow.SizeRel(dw,dh:Integer);
{ - Expand(+)/Contract(-) Window}
BEGIN 
  SizeSet(Width+dw,Height+dh);
END;{GenericWindow.SizeRel}

PROCEDURE GenericWindow.TxtAdjSize(Columns,Lines:Integer);
{ - Adjust size of window to contain Columns*Lines chars }
BEGIN
  TrapAbstract;
END;{PROC GenericWindow.TxtAdjSize}

PROCEDURE GenericWindow.InternalInit;
{ - Determine the InternalInit }
BEGIN
  TrapAbstract;
END;{PROC GenericWindow.InternalInit}

PROCEDURE GenericWindow.Open;
BEGIN
  OpenNow:=True;
  Frame;
  WorkSpace^.Open;
  Clear;
END;{PROC GenericWindow.Open}

PROCEDURE GenericWindow.Select;
BEGIN
  IF Not OpenNow THEN Open;
END;{PROC GenericWindow.Select}

PROCEDURE GenericWindow.Frame;
BEGIN { - Frame the window}
  { * Abstract}
END;{PROC GenericWindow.Frame}

PROCEDURE GenericWindow.Clear;
BEGIN { - Clear pane of window}
  WorkSpace^.Clear;
END;{PROC GenericWindow.Clear}

PROCEDURE GenericWindow.Leave;
BEGIN
  { * Abstract}
  WorkSpace^.Leave;
END;{PROC GenericWindow.Leave}

PROCEDURE GenericWindow.Close;
BEGIN
  OpenNow:=False;
  WorkSpace^.Close;
END;{PROC GenericWindow.Close}

FUNCTION GenericWindow.Save:Boolean;
BEGIN
  Save:=SaveBackground;
END;{FUNC GenericWindow.Save}

FUNCTION GenericWindow.isOpen:Boolean;
BEGIN
  isOpen:=OpenNow;
END;{FUNC GenericWindow.isOpen}

FUNCTION GenericWindow.MemUsage:LongInt;
BEGIN
  { * Abstract}
END;{FUNC GenericWindow.MemUsage}

FUNCTION GenericWindow.iInXRange(x:Integer):Boolean;
BEGIN { - Is value x within x-range of area ?}
  iInXRange:=(x>=iLeft) and (x<=iRight);
END;{FUNC GenericWindow.iInXRange}

FUNCTION GenericWindow.iInYRange(y:Integer):Boolean;
BEGIN { - Is value y within y-range of area ?}
  iInYRange:=(y>=iTop) and (y<=iBottom);
END;{FUNC GenericWindow.iInYRange}

FUNCTION GenericWindow.iInRange(x,y:Integer):Boolean;
BEGIN { - Is  point(x,y) within area ?}
  iInRange:=iInXRange(X) and iInYRange(Y);
END;{FUNC GenericWindow.iInRange}

FUNCTION GenericWindow.iLeft:Integer;
BEGIN { - Returns inner left margin of window}
  iLeft:=Left+ilx;
END;{FUNC GenericWindow.iLeft}

FUNCTION GenericWindow.iRight:Integer;
BEGIN { - Returns inner right margin of window}
  iRight:=Right-irx;
END;{FUNC GenericWindow.Right}

FUNCTION GenericWindow.iTop:Integer;
BEGIN { - Returns inner top margin of window}
  iTop:=Top+iuy;
END;{FUNC GenericWindow.iTop}

FUNCTION GenericWindow.iBottom:Integer;
BEGIN { - Returns inner bottom margin of window}
  iBottom:=Bottom-ily;
END;{FUNC GenericWindow.iBottom}

FUNCTION GenericWindow.iWidth:Integer;
BEGIN { - Returns inner width of window}
  iWidth:=iRight-iLeft+1;
END;{FUNC GenericWindow.iWidth}

FUNCTION GenericWindow.iHeight:Integer;
BEGIN { - Returns inner height of window}
  iHeight:=iBottom-iTop+1;
END;{FUNC GenericWindow.iHeight}

{--- Methods for Object : GenericWindow -------------------------------------}

VAR
  PrevExitProc : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  Units.Leave(LFWindowMsg,MemAvail);
END;

BEGIN
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  Units.Enter(LFWindowMsg,MemAvail,CSeg);
END.
