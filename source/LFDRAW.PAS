{$I CodeDefs.Pas}
{$X+}
UNIT LFdraw;

INTERFACE
USES Objects,LFsystem;

CONST
  LFDrawMsg = ' LFDraw.1 910927 Fosdal/AG ';
  Undef = -1;

TYPE

{--------------------------------------------------------------- Elements ---}

  PElement = ^Element;
  Element = OBJECT(TObject)
    CONSTRUCTOR Init;
    PROCEDURE Draw(OfsX,OfsY:Integer);    VIRTUAL;
    PROCEDURE Paint(OfsX,OfsY:Integer);   VIRTUAL;
  END;

  PStyleLine = ^StyleLine;
  StyleLine = OBJECT(Element)
    LineStyle : Word;
    Pattern   : Word;
    Thickness : Word;
    CONSTRUCTOR Init(_LineStyle: Word; _Pattern: Word; _Thickness: Word);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END;

  PStyleFill = ^StyleFill;
  StyleFill = OBJECT(Element)
    Pattern  : Word;
    Color    : Integer;
    CONSTRUCTOR Init(_Pattern: Word; _Color: Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END;

{-------------------------------------------------------- Static elements ---}

  PStaticElement = ^StaticElement;
  StaticElement = OBJECT(Element)
    Display : Boolean;
    x,y,fg  : Integer; { x,y location and forground color }
    CONSTRUCTOR Init(_x,_y,_Color:Integer);
    PROCEDURE Draw(OfsX,OfsY:Integer);   VIRTUAL;
    PROCEDURE Paint(OfsX,OfsY:Integer);   VIRTUAL;
    PROCEDURE MoveTo(_x,_y:Integer); VIRTUAL;
  END; {OBJ StaticElement}

  PStaticModule = ^StaticModule;
  StaticModule = OBJECT(StaticElement)
    Parts  : PCollection;
    Blocks : PCollection;
    CONSTRUCTOR Init(_x,_y,_Color:Integer);
    DESTRUCTOR Done;  VIRTUAL;
    PROCEDURE Draw(OfsX,OfsY:Integer);   VIRTUAL;
    PROCEDURE Paint(OfsX,OfsY:Integer);   VIRTUAL;
    FUNCTION  Add(NewPart:PElement):PElement;
    PROCEDURE Include(NewBlock:PElement);
  END; {OBJ StaticModule}

  PDrawing = ^Drawing;
  Drawing = OBJECT(TObject)
    x,y,b,c : Integer;
    Modules : PStaticModule;
    CONSTRUCTOR Init(_x,_y,_Color,_BackGr:Integer);
    DESTRUCTOR Done; VIRTUAL;
    FUNCTION Add(NewModule:PElement):PElement;
    PROCEDURE Include(NewBlock:PElement);
    PROCEDURE Draw;
    PROCEDURE Hide;
  END;

  PStaticCopy = ^StaticCopy;
  StaticCopy = OBJECT(StaticElement)
    Original : PStaticElement; { Pointer to copied element }
    CONSTRUCTOR Init(_x,_y,_Color:Integer; NewOrig:PStaticElement);
    PROCEDURE Draw(OfsX,OfsY:Integer);   VIRTUAL;
    PROCEDURE Paint(OfsX,OfsY:Integer);   VIRTUAL;
  END; {OBJ StaticCopy}

  PStaticArray = ^StaticArray;
  StaticArray = OBJECT(StaticCopy)
    xcount,             { Number of copies in _X direction }
    ycount,             { Number of copies in y direction }
    xdelta,             { element spacing in _X direction }
    ydelta  : Integer;  { element spacing in y direction }
    CONSTRUCTOR Init(_x,_y,_xd,_yd,_xc,_yc,_Color:Integer;
                     NewOrig:PStaticElement);
    PROCEDURE Draw(OfsX,OfsY:Integer);    VIRTUAL;
    PROCEDURE Paint(OfsX,OfsY:Integer);   VIRTUAL;
  END; {OBJ StaticArray}

  PStaticLine = ^StaticLine;
  StaticLine = OBJECT(StaticElement)
    dx,dy : Integer;
    CONSTRUCTOR Init(_x,_y,_x2,_y2,_Color:Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END; {OBJ StaticLine}

  PStaticCircle = ^StaticCircle;
  StaticCircle = OBJECT(StaticElement)
    r : Word;
    CONSTRUCTOR Init(_x,_y:Integer; NewR:Word; _Color:Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END; {OBJ StaticCircle}

  PArrowHead = ^ArrowHead;
  ArrowHead = OBJECT(StaticCircle)
    CONSTRUCTOR Init(_x,_y:Integer; NewA:Word; _Color:Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END; {OBJ ArrowHead}

  PStaticArc = ^StaticArc;
  StaticArc = OBJECT(StaticCircle)
    sa,ea : Word;
    CONSTRUCTOR Init(_x,_y:Integer; NewSa,NewEa,NewR:Word; _Color:Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END; {OBJ StaticArc}

  PArcArrow = ^ArcArrow;
  ArcArrow = OBJECT(StaticArc)
    ClockWise : Boolean;
    CONSTRUCTOR Init(_x,_y:Integer; NewSa,NewEa,NewR:Word;
                     CW:Boolean; _Color:Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END; {OBJ ArcArrow}

  PStaticRect = ^StaticRect;
  StaticRect = OBJECT(StaticLine)
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END; {OBJ StaticRect}

  PStaticBar = ^StaticBar;
  StaticBar = OBJECT(StaticLine)
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END; {OBJ StaticRect}

  PGradientH = ^GradientH;
  GradientH = OBJECT(StaticLine)
    fg2 : Integer;
    CONSTRUCTOR Init(_x,_y,_x2,_y2,_Color,_Color2:Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END; {OBJ StaticRect}

  PPolyDraw = ^PolyDraw;
  PolyDraw = OBJECT(StaticElement)
    NumPoints : Word;
    Points    : Pointer;
    work      : Pointer;
    CONSTRUCTOR Init(_x,_y:Integer; _NumPoints:Word; VAR PolyPoints;_Color:Integer);
    DESTRUCTOR Done;                     VIRTUAL;
    PROCEDURE PrePaint(OfsX,OfsY:Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
    PROCEDURE PostPaint;
  END;

  PPolyFill = ^PolyFill;
  PolyFill = OBJECT(PolyDraw)
    CONSTRUCTOR Init(_x,_y:Integer; _NumPoints:Word; VAR PolyPoints;_Color:Integer);
    PROCEDURE Paint(OfsX,OfsY:Integer);  VIRTUAL;
  END;


{------------------------------------------------------ Animated elements ---}

  PAnimatedElement = ^AnimatedElement;
  AnimatedElement = OBJECT(StaticElement)
    ElementID : LongInt; {Unique ID for element}
    Updated   : Pointer; {Pointer to updated parameter set}
    Current   : Pointer; {Pointer to current dataset}
    DataSize  : Word;    {Size of current dataset}
    Visible   : Boolean; {Is the element currently visible ?}
    CONSTRUCTOR Init(_x,_y,_Color:Integer; Params:Pointer; ParamSize:Word);
    DESTRUCTOR  Done;                      VIRTUAL;
    PROCEDURE   Connect(Params:Pointer);
    PROCEDURE   Update(OfsX,OfsY:Integer); VIRTUAL;
    FUNCTION    Changed:Boolean;           VIRTUAL;
  END; {OBJ AnimatedElement}

  PAnimation = ^Animation;
  Animation = OBJECT(Drawing)
    CONSTRUCTOR Init(_x,_y,_Color,_BackGr:Integer);
    PROCEDURE Connect(ElementID:LongInt; Params:Pointer);
    PROCEDURE Update;
  END;

  PDamperParam = ^DamperParamType;
  DamperParamType = RECORD
    Position  : Integer;
  END;

  PAnimatedDamper = ^AnimatedDamper;
  AnimatedDamper = OBJECT(AnimatedElement)
    bg,
    r,                { Radius }
    CalMin,           { CurPos when closed }
    CalMax : Integer; { CurPos when fully open }
    Percent : Integer; {Show percent open ?}
    CONSTRUCTOR Init(_x,_y,NewR,NewC,min,max,cur:Integer; Params:Pointer);
    FUNCTION PercentOpen:Integer;
    PROCEDURE Paint(OfsX,OfsY:Integer); VIRTUAL;
  PRIVATE
    rp : Float;
    PROCEDURE Vec(VAR dx,dy:Integer);
  END;

  PMotorParam = ^MotorParamType;
  MotorParamType = RECORD
    IsRunning : Boolean;
    Direction : Integer;
    MVError   : Boolean;
    Effect    : Integer;
  END;

  PAnimatedMotor = ^AnimatedMotor;
  AnimatedMotor = OBJECT(AnimatedElement)
    r,               { Radius }
    Angle : Integer; { Fandirection: 0=Right 90=Up 180=Left 270=Down }
    CONSTRUCTOR Init(_x,_y,NewR,NewA,NewC:Integer; Params:Pointer);
    PROCEDURE Paint(OfsX,OfsY:Integer); VIRTUAL;
  END;

  PFieldParam = ^FieldParamType;
  FieldParamType = RECORD
    Value : Float;
  END;

  PAnimatedField = ^AnimatedField;
  AnimatedField = OBJECT(AnimatedElement)
    Name : PString;
    CONSTRUCTOR Init(_x,_y,NewC:Integer; NewName:String; Params:Pointer);
    DESTRUCTOR Done;                   VIRTUAL;
    PROCEDURE Paint(OfsX,OfsY:Integer); VIRTUAL;
  END;

  PAnimatedInt = ^AnimatedInt;
  AnimatedInt = OBJECT(AnimatedElement)
    Name : PString;
    CONSTRUCTOR Init(_x,_y,NewC:Integer; NewName:String; Params:Pointer);
    DESTRUCTOR Done;                    VIRTUAL;
    PROCEDURE Paint(OfsX,OfsY:Integer); VIRTUAL;
  END;

  PBoolParamType = ^BoolParamType;
  BoolParamType  = RECORD
    IsOn : Boolean;
  END;

  PAnimatedBool = ^AnimatedBool;
  AnimatedBool = OBJECT(AnimatedElement)
    bg : Integer;
    CONSTRUCTOR Init(_x,_y,NewC:Integer; Params:Pointer);
  END;

  PBaseSymbol = ^BaseSymbol;
  BaseSymbol = OBJECT(AnimatedBool)
    PROCEDURE Paint(OfsX, oFsY:Integer); VIRTUAL;
  END;

IMPLEMENTATION
USES
  Graph,LFGraph,LFString;

{같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같� Elements 같�}

CONSTRUCTOR Element.Init;
BEGIN
  TObject.Init;
END; {CONS Element.Init}

PROCEDURE Element.Draw(OfsX,OfsY:Integer);
BEGIN
  Paint(OfsX,OfsY);
END; {PROC Element.Draw}

PROCEDURE Element.Paint(OfsX,OfsY:Integer);
BEGIN
  TrapAbstract;
END; {PROC Element.Paint}

{---------------------------------------------------------- StyleElements ---}

CONSTRUCTOR StyleLine.Init(_LineStyle: Word; _Pattern: Word; _Thickness: Word);
BEGIN
  Element.Init;
  LineStyle:=_LineStyle;
  Pattern:=_Pattern;
  Thickness:=_Thickness;
END; {CONS StyleLine.Init}

PROCEDURE StyleLine.Paint(OfsX,OfsY:Integer);
BEGIN
  Graph.SetLineStyle(LineStyle,Pattern,Thickness);
END; {PROC StyleLine.Paint}

CONSTRUCTOR StyleFill.Init(_Pattern: Word; _Color: Integer);
BEGIN
  Element.Init;
  Pattern:=_Pattern;
  Color:=_Color;
END; {CONS StyleFill.Init}

PROCEDURE StyleFill.Paint(OfsX,OfsY:Integer);
VAR
  c : Integer;
BEGIN
  IF Color=UnDef
  THEN c:=GetColor
  ELSE c:=Color;
  Graph.SetFillStyle(Pattern,c);
END; {PROC StyleFill.Paint}



{같같같같같같같같같같같같같같같같같같같같같같같같같같같같 Static Elements 같�}

{---------------------------------------------------------- StaticElement ---}

CONSTRUCTOR StaticElement.Init(_x,_y,_Color:Integer);
{ - Init Graphic Object }
BEGIN
  Element.Init;
  x:=_x;
  y:=_y;
  fg:=_Color;
  Display:=False;
END; {CONS StaticElement.Init}

PROCEDURE StaticElement.Paint(OfsX,OfsY:Integer);
{ - Hide Graphic Object }
BEGIN
  Graph.MoveTo(OfsX+x,OfsY+y);
  Graph.LineRel(0,0);
END; {PROC StaticElement.Paint}

PROCEDURE StaticElement.Draw(OfsX,OfsY:Integer);
{ - Draw Graphic point }
BEGIN
  IF fg<>UnDef THEN SetColor(fg);
  Display:=True;
  Paint(OfsX,OfsY);
  Display:=False;
END; {PROC StaticElement.Draw}

PROCEDURE StaticElement.MoveTo(_x,_y:Integer);
{ - Move Graphic Object Origin}
BEGIN
  x:=_x;
  y:=_y;
END; {PROC StaticElement.MoveTo}

{----------------------------------------------------------- StaticModule ---}

CONSTRUCTOR StaticModule.Init(_x,_y,_Color:Integer);
{ - }
BEGIN
  StaticElement.Init(_x,_y,_Color);
  New(Parts,Init(8,8));
  New(Blocks,Init(4,4));
END; {CONS StaticModule.Init}

DESTRUCTOR StaticModule.Done;
{ - Deallocate Graphic Module}
BEGIN
  Dispose(Blocks,Done);
  Dispose(Parts,Done);
  StaticElement.Done;
END; {DEST StaticModule.Done}

PROCEDURE StaticModule.Draw(OfsX,OfsY:Integer);
{ - Draw Graphic Module (i.e. symbol or drawing)}
  PROCEDURE DrawThem(Part : PStaticElement); FAR;
  { - Draw an Item in the collection }
  VAR
    c : Integer;
  BEGIN
    c := GetColor;
    IF fg<>Undef THEN SetColor(fg);
    Part^.Draw(OfsX+x,OfsY+y);
    SetColor(c);
  END;{LOCAL FAR PROC DrawThem}
BEGIN
  Parts^.ForEach(@DrawThem);
END; {PROC StaticModule.Draw}

PROCEDURE StaticModule.Paint(OfsX,OfsY:Integer);
{ - Hide Graphic Module (i.e. symbol or drawing)}
  PROCEDURE HideThem(Part : PStaticElement); FAR;
  { - Hide an Item in the collection }
  BEGIN
    Part^.Paint(OfsX+x,OfsY+y);
  END;{LOCAL FAR PROC DrawThem}
BEGIN
  Parts^.ForEach(@HideThem);
END; {PROC StaticModule.Paint}

FUNCTION StaticModule.Add(NewPart:PElement):PElement;
{ - Add an element to the symbol }
BEGIN
  Parts^.Insert(NewPart);
  Add:=NewPart;
END;

PROCEDURE StaticModule.Include(NewBlock:PElement);
{ - Add an reference element to the symbol }
BEGIN
  Blocks^.Insert(NewBlock);
END;

{---------------------------------------------------------------- Drawing ---}

CONSTRUCTOR Drawing.Init(_x,_y,_Color,_BackGr:Integer);
{ - }
BEGIN
  TObject.Init;
  x:=_x;
  y:=_y;
  c:=_Color;
  b:=_BackGr;
  New(Modules,Init(0,0,c));
END; {CONS StaticModule.Init}

DESTRUCTOR Drawing.Done;
{ - Deallocate drawing}
BEGIN
  Dispose(Modules,Done);
  TObject.Done;
END; {DEST Drawing.Done}

PROCEDURE Drawing.Draw;
BEGIN
  SetColor(c);
  Modules^.Draw(x,y);
END; {PROC Drawing.Draw}

PROCEDURE Drawing.Hide;
BEGIN
  SetColor(b);
  Modules^.Paint(x,y);
END; {PROC Drawing.Paint}

FUNCTION Drawing.Add(NewModule:PElement):PElement;
{ - Add an element to the symbol }
BEGIN
  Modules^.Add(NewModule);
  Add:=NewModule;
END;

PROCEDURE Drawing.Include(NewBlock:PElement);
{ - Add an reference element to the symbol }
BEGIN
  Modules^.Include(NewBlock);
END;

{------------------------------------------------------------- StaticCopy ---}

CONSTRUCTOR StaticCopy.Init(_x,_y,_Color:Integer; NewOrig:PStaticElement);
{ - }
BEGIN
  StaticElement.Init(_x,_y,_Color);
  Original:=NewOrig;
END; {CONS StaticCopy.Init}

PROCEDURE StaticCopy.Draw(OfsX,OfsY:Integer);
{ - Draw Graphic Copy (i.e. symbol or drawing)}
BEGIN
  IF fg<>Undef THEN SetColor(fg);
  Original^.Draw(OfsX+x,OfsY+y);
END; {PROC StaticCopy.Draw}

PROCEDURE StaticCopy.Paint(OfsX,OfsY:Integer);
{ - Draw Graphic Copy (i.e. symbol or drawing)}
BEGIN
  Original^.Paint(OfsX+x,OfsY+y);
END; {PROC StaticCopy.Draw}

{------------------------------------------------------------ StaticArray ---}

CONSTRUCTOR StaticArray.Init(_x,_y,_xd,_yd,
       _xc,_yc,_Color:Integer; NewOrig:PStaticElement);
{ - }
BEGIN
  StaticCopy.Init(_x,_y,_Color,NewOrig);
  xDelta:=_xd; yDelta:=_yd;
  xCount:=_xc; yCount:=_yc;
END; {CONS StaticArray.Init}

PROCEDURE StaticArray.Draw(OfsX,OfsY:Integer);
{ - Draw Graphic Array (i.e. symbol or drawing)}
VAR
  i,j : Integer;
BEGIN
  IF fg<>Undef THEN SetColor(fg);
  FOR i:=0 TO yCount-1
  DO FOR j:=0 TO xCount-1
    DO Original^.Draw(OfsX+x+j*xDelta,OfsY+y+i*yDelta);
END; {PROC StaticArray.Draw}

PROCEDURE StaticArray.Paint(OfsX,OfsY:Integer);
{ - Draw Graphic Array (i.e. symbol or drawing)}
VAR
  i,j : Integer;
BEGIN
  FOR i:=0 TO yCount-1
  DO FOR j:=0 TO xCount-1
    DO Original^.Paint(OfsX+x+j*xDelta,OfsY+y+i*yDelta);
END; {PROC StaticArray.Draw}


{------------------------------------------------------------- StaticLine ---}

CONSTRUCTOR StaticLine.Init(_x,_y,_x2,_y2,_Color:Integer);
{ - Init Graphic Object }
BEGIN
  StaticElement.Init(_x,_y,_Color);
  dx:=_x2-_x;
  dy:=_y2-_y;
END; {CONS StaticLine.Init}

PROCEDURE StaticLine.Paint(OfsX,OfsY:Integer);
{ - Hide Graphic Line }
BEGIN
  Graph.MoveTo(OfsX+x,OfsY+y);
  Graph.LineRel(dx,dy);
END; {PROC StaticLine.Paint}

{----------------------------------------------------------- StaticCircle ---}

CONSTRUCTOR StaticCircle.Init(_x,_y:Integer; NewR:Word; _Color:Integer);
{ - Init Graphic Object }
BEGIN
  StaticElement.Init(_x,_y,_Color);
  r:=NewR;
END; {CONS StaticCircle.Init}

PROCEDURE StaticCircle.Paint(OfsX,OfsY:Integer);
{ - Hide Graphic Circle }
BEGIN
  Graph.Circle(OfsX+x,OfsY+y,r);
END; {PROC StaticCircle.Draw}

CONST
  AHO = 25;
{----------------------------------------------------------- ArrowHead ---}

CONSTRUCTOR ArrowHead.Init(_x,_y:Integer; NewA:Word; _Color:Integer);
{ - Init Graphic Object }
BEGIN
  StaticCircle.Init(_x,_y,NewA,_Color);
END; {CONS ArrowHead.Init}

PROCEDURE corrArc(x,y,sa,ea,r:Integer);
VAR
  l : LineSettingsType;
BEGIN
  GetLineSettings(l);
  Graph.Arc(x,y,sa,ea,r);
  IF l.Thickness<>1
  THEN BEGIN
    SetLineStyle(l.LineStyle,l.Pattern,1);
    Graph.Arc(x,y,sa,ea,r);
    SetLineStyle(l.LineStyle,l.Pattern,l.Thickness);
  END;
END;

PROCEDURE ArrowHead.Paint(OfsX,OfsY:Integer);
{ - Hide Graphic Circle }
VAR
  a : ArcCoordsType;
BEGIN
  CorrArc(OfsX+x,OfsY+y,r-AHO,r+AHO,7);
  GetArcCoords(a);
  Graph.Line(a.x,a.y,a.xStart,a.yStart);
  Graph.Line(a.x,a.y,a.xEnd,a.yEnd);
END; {PROC ArrowHead.Draw}

{-------------------------------------------------------------- StaticArc ---}

CONSTRUCTOR StaticArc.Init(_x,_y:Integer; NewSa,NewEa,NewR:Word; _Color:Integer);
{ - Init Graphic Object }
BEGIN
  StaticCircle.Init(_x,_y,NewR,_Color);
  ea:=NewEa;
  sa:=NewSa;
END; {CONS StaticArc.Init}

PROCEDURE StaticArc.Paint(OfsX,OfsY:Integer);
{ - Hide Graphic Arc }
BEGIN
  Graph.Arc(OfsX+x,OfsY+y,sa,ea,r);
END; {PROC StaticArc.Draw}

{-------------------------------------------------------------- ArcArrow ---}

CONSTRUCTOR ArcArrow.Init(_x,_y:Integer; NewSa,NewEa,NewR:Word;
                          CW:Boolean; _Color:Integer);
{ - Init Graphic Object }
BEGIN
  StaticArc.Init(_x,_y,NewSa,NewEa,NewR,_Color);
  ClockWise:=CW;
END; {CONS ArcArrow.Init}


PROCEDURE ArcArrow.Paint(OfsX,OfsY:Integer);
{ - Hide Graphic Arc }
VAR
  a : ArcCoordsType;
BEGIN
  CorrArc(OfsX+x,OfsY+y,sa,ea,r);
  GetArcCoords(a);
  IF ClockWise
  THEN BEGIN
    CorrArc(a.xStart,a.yStart,(sa+90-AHO) MOD 360,(sa+90+AHO) MOD 360,r DIV 8);
  END
  ELSE BEGIN
    CorrArc(a.xEnd,a.yEnd,(ea-90-AHO) MOD 360,(ea-90+AHO) MOD 360,r DIV 8);
  END;
  GetArcCoords(a);
  Graph.Line(a.x,a.y,a.xStart,a.yStart);
  Graph.Line(a.x,a.y,a.xEnd,a.yEnd);
END; {PROC ArcArrow.Draw}

{------------------------------------------------------------- StaticRect ---}

PROCEDURE StaticRect.Paint(OfsX,OfsY:Integer);
BEGIN
  Graph.Rectangle(OfsX+x,OfsY+y,OfsX+x+dx,OfsY+y+dy);
END; {PROC StaticRect.Paint}

{-------------------------------------------------------------- StaticBar ---}

PROCEDURE StaticBar.Paint(OfsX,OfsY:Integer);
VAR
  s : FillSettingsType;
BEGIN
  GetFillSettings(s);
  SetFillStyle(s.Pattern,GetColor);
  SetColor(White);
  Graph.Bar(OfsX+x,OfsY+y,OfsX+x+dx,OfsY+y+dy);
END; {PROC StaticBar.Paint}

{-------------------------------------------------------------- GradientH ---}

CONSTRUCTOR GradientH.Init(_x,_y,_x2,_y2,_Color,_Color2:Integer);
BEGIN
  StaticLine.Init(_x,_y,_x2,_y2,_Color);
  fg2:=_Color2;
END;

PROCEDURE GradientH.Paint(OfsX,OfsY:Integer);
VAR
  s : FillSettingsType;
BEGIN
  GetFillSettings(s);
  LFGraph.DitherH(OfsX+x,OfsY+y,OfsX+x+dx,OfsY+y+dy,fg,fg2);
  SetFillStyle(s.Pattern,s.Color);
END; {PROC GradientH.Paint}

{--------------------------------------------------------------- PolyDraw ---}

PROCEDURE CopyData(VAR Src; VAR Target; Bytes:Word);
BEGIN
 ASM
  push ds
  lds  si,Src
  les  di,Target
  cld
  mov  cx,Bytes
  rep movsb
  pop ds
 END;
END; {PROC CopyData}

CONSTRUCTOR PolyDraw.Init(_x,_y:Integer; _NumPoints:Word; VAR PolyPoints;_Color:Integer);
BEGIN
  StaticElement.Init(_x,_y,_Color);
  NumPoints:=_NumPoints;
  GetMem(Points,NumPoints*SizeOf(PointType));
  CopyData(PolyPoints,Points^,NumPoints*SizeOf(PointType));
END; {CONS PolyDraw.Init}

DESTRUCTOR PolyDraw.Done;
BEGIN
  FreeMem(Points,NumPoints*SizeOf(PointType));
  StaticElement.Done;
END; {DEST PolyDraw.Done}

TYPE
  xyTable = ARRAY[1..1] OF PointType;

PROCEDURE PolyDraw.PrePaint(OfsX,OfsY:Integer);
VAR
  i : Integer;
BEGIN
  GetMem(Work,NumPoints*SizeOf(PointType));
  CopyData(Points^,Work^,NumPoints*SizeOf(PointType));
  FOR i:=1 TO NumPoints
  DO BEGIN
    {$IFOPT R+} {$DEFINE RPlus} {$R-} {$ENDIF}
    xyTable(Work^)[i].x:=xyTable(Work^)[i].x+OfsX+x;
    xyTable(Work^)[i].y:=xyTable(Work^)[i].y+OfsY+y;
    {$IFDEF RPlus} {$UNDEF RPlus} {$R+} {$ENDIF}
  END;
END; {PROC PolyDraw.PrePaint}

PROCEDURE PolyDraw.Paint(OfsX,OfsY:Integer);
BEGIN
  PrePaint(OfsX,OfsY);
  Graph.DrawPoly(NumPoints,Work^);
  PostPaint;
END; {PROC PolyDraw.Paint}

PROCEDURE PolyDraw.PostPaint;
BEGIN
  FreeMem(Work,NumPoints*SizeOf(PointType));
END; {PROC PolyDraw.PostPaint}

{--------------------------------------------------------------- PolyFill ---}

CONSTRUCTOR PolyFill.Init(_x,_y:Integer; _NumPoints:Word; VAR PolyPoints;_Color:Integer);
BEGIN
  PolyDraw.Init(_x,_y,_NumPoints,PolyPoints,_Color);
END; {CONS PolyFill.Init}

PROCEDURE PolyFill.Paint(OfsX,OfsY:Integer);
BEGIN
  PrePaint(OfsX,OfsY);
  Graph.FillPoly(NumPoints,Work^);
  Graph.DrawPoly(NumPoints,Work^);
  PostPaint;
END; {PROC PolyFill.Paint}


{같같같같같같같같같같같같같같같같같같같같같같같같같같같 Animated Elements 같�}

{-------------------------------------------------------- AnimatedElement ---}
(*
    ElementID : LongInt;
    data    : Pointer; {Pointer to parameter set}
    Visible : Boolean; {Is the element currently visible ?}
*)

CONSTRUCTOR AnimatedElement.Init(_x,_y,_Color:Integer; Params:Pointer; ParamSize:Word);
{ - Initalize the element and connect it to its parameters}
BEGIN
  StaticElement.Init(_x,_y,_Color);
  DataSize:=ParamSize;
  GetMem(Current,DataSize);
  Connect(Params);
END; {CONS AnimatedElement.Init}

DESTRUCTOR AnimatedElement.Done;
{ - Cleanup after element}
BEGIN
  FreeMem(Current,DataSize);
  StaticElement.Done;
END; {CONS AnimatedElement.Init}

PROCEDURE AnimatedElement.Connect(Params:Pointer);
{ - Give element a pointer to the right parameters and shuffle data}
BEGIN
  Updated:=Params;
  Move(Updated^,Current^,DataSize);
END; {PROC AnimatedElement.Connect}

PROCEDURE AnimatedElement.Update(OfsX,OfsY:Integer);
{ - Redraw element if it's parameters has changed }
VAR
  c:Integer;
BEGIN
  IF Changed
  THEN BEGIN
    c:=Getcolor;
    Paint(OfsX,OfsY);
    Connect(Updated);
    Draw(OfsX,OfsY);
    SetColor(c);
  END;
END; {PROC AnimatedElement.Update}

FUNCTION AnimatedElement.Changed:Boolean;
TYPE
  cast = ARRAY[1..4096] OF Byte;
VAR
  i    : Word;
  diff : Boolean;
BEGIN
  i:=1; diff:=false;
  REPEAT
    diff:=diff or (cast(Updated^)[i]<>cast(Current^)[i]);
    Inc(i);
  UNTIL Diff or (i=DataSize);
  Changed:=Diff;
END;

{-------------------------------------------------------------- Animation ---}

CONSTRUCTOR Animation.Init(_x,_y,_Color,_BackGr:Integer);
{ - Prepare collection of animated symbols}
BEGIN
  Drawing.Init(_x,_y,_Color,_BackGr);
END;

PROCEDURE Animation.Connect(ElementID:LongInt; Params:Pointer);
{ - Connect}
  FUNCTION Match_ID(This:PAnimatedElement):Boolean; FAR;
  BEGIN
    Match_ID:=This^.ElementID=ElementID;
  END;
VAR
  P : PAnimatedElement;
BEGIN
  P:=Modules^.Parts^.FirstThat(@Match_ID);
  IF P<>nil THEN P^.Connect(Params);
END;

PROCEDURE Animation.Update;
{ - Make every element access its parameter set to check for changes}
  PROCEDURE Do_Update(P:PAnimatedElement); FAR;
  BEGIN
    P^.Update(x,y);
  END;
BEGIN
  Setcolor(b);
  Modules^.Parts^.ForEach(@Do_Update);
END;

{--------------------------------------------------------- AnimatedDamper ---}

CONSTRUCTOR AnimatedDamper.Init(_x,_y,NewR,NewC,Min,Max,Cur:Integer; Params:Pointer);
BEGIN
  AnimatedElement.Init(_x,_y,NewC,Params,SizeOf(DamperParamType));
  r:=NewR;
  CalMin:=Min;
  CalMax:=Max;
  PDamperParam(Current)^.Position:=Cur;
  Percent:=0; { -1=Right  0=N/A  1=Left }
END; {CONS AnimatedDamper.Init}

PROCEDURE AnimatedDamper.Paint(OfsX,OfsY:Integer);
VAR
  dx,dy : Integer;
  lset  : LineSettingsType;
BEGIN
  rp:=(PDamperParam(Current)^.Position-CalMin)/(CalMax-CalMin);
  IF Percent<>0
  THEN BEGIN
    CASE Percent OF
     -1 : dx:=-48;
      1 : dx:=16;
    END;
    gWrt(OfsX+x+dx,OfsY+y-7,GetColor,IntStr(PercentOpen,3)+'%');
  END;
  IF Display
  THEN bg:=Graph.GetPixel(OfsX+x,OfsY+Y)
  ELSE SetColor(bg); {////////// KLUDGE }
  Vec(dx,dy);
  Circle(OfsX+x,OfsY+y,1);
  Circle(OfsX+x,OfsY+y,2);
  GetLineSettings(lset);
  SetLineStyle(SolidLn,0,3);
  Line(OfsX+x-dx,OfsY+y+dy,OfsX+x+dx,OfsY+y-dy);
  SetLineStyle(lset.LineStyle,lset.Pattern,lset.Thickness);
END;

FUNCTION AnimatedDamper.PercentOpen:Integer;
VAR
  p : Integer;
BEGIN
  p:=Round(rp*100);
  IF p<0 THEN p:=Abs(p);
  IF p>100 THEN p:=100 - (p MOD 100);
  PercentOpen:=p;
END;

PROCEDURE AnimatedDamper.Vec(VAR dx,dy:Integer);
VAR
  v : Float;
BEGIN
  v:=PI/2*rp;
  dx:=Round(cos(v)*r);
  dy:=Round(sin(v)*r);
END;


{---------------------------------------------------------- AnimatedMotor ---}


CONSTRUCTOR AnimatedMotor.Init(_x,_y,NewR,NewA,NewC:Integer; Params:Pointer);
BEGIN
  AnimatedElement.Init(_x,_y,NewC,Params,SizeOf(MotorParamType));
  r:=NewR;
  Angle:=NewA;
END;

PROCEDURE AnimatedMotor.Paint(OfsX,OfsY:Integer);
VAR
  p : ArcCoordsType;
  i,v : Word;
  c : Integer;
BEGIN
  v:=Angle+PMotorParam(Current)^.Direction;
  IF Display
  THEN BEGIN
    IF PMotorParam(Current)^.IsRunning
     THEN c:=LightGreen ELSE c:=fg;
    IF PMotorParam(Current)^.MVError
     THEN c:=LightRed;
  END ELSE c:=GetColor;
  SetColor(c);
  FOR i:=1 TO 3
  DO BEGIN
    Arc(OfsX+x,OfsY+y,v,v+120,r);
    GetArcCoords(p);
    Line(p.xStart,p.yStart,p.xEnd,p.yEnd);
    v:=v+120;
  END;
  IF (c<>White)
  THEN BEGIN
    IF (PMotorParam(Current)^.Effect>0)
    THEN gWrt(OfsX+x+r+13,OfsY+y-7,c,IntStr(PMotorParam(Current)^.Effect,3)+'%');
    SetFillStyle(SolidFill,c);
    FloodFill(OfsX+x,OfsY+y,c);
  END;
END;

{---------------------------------------------------------- AnimatedField ---}


CONSTRUCTOR AnimatedField.Init(_x,_y,NewC:Integer; NewName:String; Params:Pointer);
BEGIN
  AnimatedElement.Init(_x,_y,NewC,Params,SizeOf(FieldParamType));
  PSNew(Name,NewName);
END;

DESTRUCTOR AnimatedField.Done;
BEGIN
  PSDispose(Name);
  AnimatedElement.Done;
END;


PROCEDURE AnimatedField.Paint(OfsX,OfsY:Integer);
VAR
  c,c2 : Integer;
  s    : String[40];
BEGIN
  IF Display and (fg<>Undef)
  THEN BEGIN
    c:=fg;
    IF c>7
    THEN c2:=c-8
    ELSE c2:=Black;
  END
  ELSE BEGIN
    c:=GetColor;
    c2:=c;
  END;
  s:=Name^+': '+FloatStr(PFieldParam(Current)^.Value,4,1);
  gWrt(OfsX+x+1,OfsY+Y+1,c2,s);
  gWrt(OfsX+x,OfsY+Y,c,s);
END;

{---------------------------------------------------------- AnimatedInt ---}


CONSTRUCTOR AnimatedInt.Init(_x,_y,NewC:Integer; NewName:String; Params:Pointer);
BEGIN
  AnimatedElement.Init(_x,_y,NewC,Params,SizeOf(DamperParamType));
  PSNew(Name,NewName);
END;

DESTRUCTOR AnimatedInt.Done;
BEGIN
  PSDispose(Name);
  AnimatedElement.Done;
END;

PROCEDURE AnimatedInt.Paint(OfsX,OfsY:Integer);
VAR
  c,c2 : Integer;
  s    : String[40];
BEGIN
  IF Display and (fg<>Undef)
  THEN BEGIN
    c:=fg;
    IF c>7
    THEN c2:=c-8
    ELSE c2:=Black;
  END
  ELSE BEGIN
    c:=GetColor;
    c2:=c;
  END;
  s:=IntStr(PDamperParam(Current)^.Position,3)+'%';
  gWrt(OfsX+x+1,OfsY+Y+1,c2,s);
  gWrt(OfsX+x,OfsY+Y,c,s);
END;

{------------------------------------------------------------- AnimatedBool ---}
  
CONSTRUCTOR AnimatedBool.Init(_x,_y,NewC:Integer; Params:Pointer);
BEGIN
  AnimatedElement.Init(_x,_y,NewC, Params, SizeOf(BoolParamType));
END;


{--------------------------------------------------------------- BaseSymbol ---}

PROCEDURE BaseSymbol.Paint(OfsX, OfsY:Integer);
VAR
  c,cc,i : Integer;
BEGIN
  cc:=GetColor;
  IF Display
  THEN bg:=Graph.GetPixel(OfsX+x,OfsY+Y);
  IF PBoolParamType(Updated)^.IsOn
  THEN c:=cc
  ELSE c:=bg;
  SetColor(c);
  Circle(OfsX+x, OfsY+y, 2);
  FOR i:=0 TO 4
  DO BEGIN
    PutPixel(OfsX+x-(2+i), OfsY+y+3+(i*2), c);
    PutPixel(OfsX+x,       OfsY+y+4+(i*2), c);
    PutPixel(OfsX+x+(2+i), OfsY+y+3+(i*2), c);
  END;
  SetColor(cc);
END; {PROC BaseSymbol.Paint}

{-------------------------------------------------------------- ExitProc's ---
}

VAR
  PrevExitProc : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  Units.Leave(LFDrawMsg,MemAvail);
END;

BEGIN { - Init Unit LFDraw}
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  Units.Enter(LFDrawMsg,MemAvail,CSeg);
END.
