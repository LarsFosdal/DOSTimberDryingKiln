{ DEFINE NoDebug}
{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT OBJINPUT; {.1 891029}

INTERFACE
USES
  Dos,Objects,LFsystem,LFTable,LFExtMsg,LFwindow;
CONST
  ObjInputMsg = ' ObjInput.1 910927 Lars Fosdal ';
CONST
  CharMaxX = 80;
  CharMaxY = 43;
CONST
  MouseMaxX = (CharMaxX*8)-1;
  MouseMaxY = (CharMaxY*8)-1;

{
  AutoRecall =$0001; Numeric  =$0002; NotEmpty =$0004; ShowLimits =$0008;
  Uppercase  =$0010; InsertOn =$0020; AutoCR   =$0040; AutoNew    =$0080;
  ExitClear  =$0100;
}
TYPE
  CharSet = Set Of Char;
  PGenInput = ^GenInput;
  GenInput = OBJECT(TObject)
    Owner : PWorkSpace;
    x, y : Integer; {Where is it ?}
    LastInput  : Word;         {Last key}
    LegalChars : CharSet;      {Legal chars for Edit}
    Valid      : Boolean;      {Edit value valid on exit ?}
    Funk       : Boolean;      {Function key was pressed ?}
    Entered    : Boolean;      {Are we entering now ?}
    HelpTag    : InfoIDType;   {Help Lookup tag}
    CONSTRUCTOR Init(OwnerWS:PWorkSpace; WhatX,WhatY:Integer;
                     InputSet:CharSet);
    PROCEDURE SetCharSet(InputSet:CharSet);                     VIRTUAL;
    FUNCTION  isValid:Boolean;                                  VIRTUAL;
    FUNCTION  isFunction:Boolean;                               VIRTUAL;
    FUNCTION  LastChar:Char;                                    VIRTUAL;
    FUNCTION  LastKey:Word;                                     VIRTUAL;
    PROCEDURE MoveTo(toX,toY:Integer);
    PROCEDURE MoveRel(addX,addY:Integer);
    PROCEDURE UpdateLocation;                                   VIRTUAL;
    FUNCTION atX:Integer;
    FUNCTION atY:Integer;
  END;

  PGenEdit = ^GenEdit;
  GenEdit = OBJECT(GenInput)
    color      : SingleColor;  {Value color}
    xp         : Integer;      {Current position}
    Attrib     : FlagGroup;    {Edit Attributes}
    DoUpCase   : Boolean;      {Convert to Upper-case ?}
    MarkAll    : Boolean;      {Is the field marked ?}
    maxLength  : Integer;      {Max length of Edit field}
    LeadText   : PString;      {Prompt text}
    TrailText  : PString;      {description text '¯C' ): Prompt [45] ¯C }
    CONSTRUCTOR Init(OwnerWS:PWorkSpace; WhatX,WhatY,WhatLength:Integer;
                     InputSet:CharSet; TrueIfUpcase:Boolean);
    DESTRUCTOR Done;                                            VIRTUAL;
    PROCEDURE Link(Index:PMsgIndex;WhatHelp,Lead,Trail:String); VIRTUAL;
    PROCEDURE SetLength(WhatLength:Integer);                    VIRTUAL;
    PROCEDURE SetUpCase(TrueIfUpcase:Boolean);                  VIRTUAL;
    PROCEDURE Edit;                                             VIRTUAL;
    FUNCTION  asText:String;                                    VIRTUAL;
    PROCEDURE Display;                                          VIRTUAL;
    PROCEDURE Refresh(From,UpTo:Byte);                          VIRTUAL;
  END;

  PKeystroke = ^Keystroke;
  Keystroke = OBJECT(GenEdit)
    CONSTRUCTOR Init(Win:PWorkSpace; whatX,whatY:Integer;
                   WhatChars:CharSet;
                   TrueIfUpcase:Boolean);
    DESTRUCTOR Done;                                            VIRTUAL;
    PROCEDURE Edit;                                             VIRTUAL;
    FUNCTION WaitForValid:Char;
    PROCEDURE Clear;
    FUNCTION  asText:String;                                    VIRTUAL;
  END;

  PStrDisplay = ^StrDisplay;
  StrDisplay = OBJECT(GenEdit)
    StringValue : PString;     { Value of String Object }
    CONSTRUCTOR Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength:Integer;
                   Default:String);
    DESTRUCTOR Done;                                            VIRTUAL;
    PROCEDURE Assign(NewDefault:String);                        VIRTUAL;
    PROCEDURE Edit;                                             VIRTUAL;
    FUNCTION asText:String;                                     VIRTUAL;
    FUNCTION Value:String;                                      VIRTUAL;
  END;

  PStrInput = ^StrInput;
  StrInput = Object(StrDisplay)
    CONSTRUCTOR Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength:Integer;
                   Default:String;
                   WhatChars:CharSet;
                   TrueIfUpcase:Boolean);
    PROCEDURE Edit;                                             VIRTUAL;
  END;

  PStrPInput = ^StrPInput;
  StrPInput = Object(StrInput)
    CONSTRUCTOR Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength:Integer;
                   Default:PString;
                   WhatChars:CharSet;
                   TrueIfUpcase:Boolean);
    FUNCTION PValue:PString;                VIRTUAL;
  END;

  PIntDisplay = ^IntDisplay;
  IntDisplay = Object(GenEdit)
    IntValue : LongInt; {Value of Integer Object}
    CONSTRUCTOR Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength:Integer;
                   def : LongInt);
    PROCEDURE Edit;                                             VIRTUAL;
    PROCEDURE Assign(NewDefault:LongInt);                       VIRTUAL;
    FUNCTION  asText:String;                                    VIRTUAL;
    FUNCTION Value:LongInt;                                     VIRTUAL;
  END;

  PIntInput = ^IntInput;
  IntInput = Object(IntDisplay)
    MinValue : LongInt; {Minimum value of Integer Object}
    MaxValue : LongInt; {Maximum value of Integer Object}
    CONSTRUCTOR Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength:Integer;
                   min,def,max : LongInt);
    PROCEDURE SetLimits(min,max:LongInt);                       VIRTUAL;
    PROCEDURE Edit;                                             VIRTUAL;
  END;

  PFloatInput = ^FloatInput;
  FloatInput = Object(GenEdit)
    MinValue   : Float;   {Minimum value of Float Object}
    MaxValue   : Float;   {Maximum value of Float Object}
    FloatValue : Float;   {Value of Float Object}
    Decimals   : Integer; {Number of desimals}
    CONSTRUCTOR Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength,Decim:Integer;
                   min,def,max : Float);
    DESTRUCTOR Done;                                            VIRTUAL;
    PROCEDURE SetLimits(min,max:Float);                         VIRTUAL;
    PROCEDURE Assign(NewDefault:Float);                         VIRTUAL;
    PROCEDURE Edit;                                             VIRTUAL;
    FUNCTION  asText:String;                                    VIRTUAL;
    FUNCTION Value:Float;                                       VIRTUAL;
  END;

  PSelectInput = ^SelectInput;      { - Base type: DO NOT USE !}
  SelectInput = OBJECT(GenEdit)
    Option  : PTextTxt; {Ext.msg. ref.}
    Current : Integer;
    CONSTRUCTOR Init(Win:PWorkspace; WhatX,WhatY,
                     MaxLen:Integer; TxtRef:PTextTxt);
  END; {OBJ SelectInput}

  PChoiceInput = ^ChoiceInput;
  ChoiceInput = OBJECT(SelectInput)
    CONSTRUCTOR Init(Win:PWorkspace; WhatX,WhatY,
                     MaxLen,Curr:Integer; TxtRef:PTextTxt);
    PROCEDURE Edit;                       VIRTUAL;
    FUNCTION  asText:String;              VIRTUAL;
    PROCEDURE Assign(NewDefault:Integer); VIRTUAL;
    FUNCTION Value:Integer;               VIRTUAL;
  END; {OBJ ChoiceInput}

  PBooleanInput = ^BooleanInput;
  BooleanInput = OBJECT(SelectInput)
    CONSTRUCTOR Init(Win:PWorkspace; WhatX,WhatY,
                     MaxLen:Integer; Def:Boolean; TxtRef:PTextTxt);
    PROCEDURE Edit;                       VIRTUAL;
    FUNCTION  asText:String;              VIRTUAL;
    PROCEDURE Assign(NewDefault:Boolean); VIRTUAL;
    FUNCTION Value:Boolean;               VIRTUAL;
  END; {OBJ ChoiceInput}

  PMenuInput = ^MenuInput;
  MenuInput = OBJECT(GenInput)
    Mnu     : PMenuTxt;
    Current : Integer;
    vColumns,
    vLines  : Integer;
    CONSTRUCTOR Init(OwnerWin:PWindow; VisualLines:Integer; MnuRef:PMenuTxt);
    PROCEDURE Select;
    FUNCTION Choice:Integer;
  END;

  PHyperText = ^HyperText;
  HyperText = OBJECT(GenInput)
    Index   : PMsgIndex;
    vColumns,
    vLines  : Integer;
    CONSTRUCTOR Init(OwnerWin:PWindow; TextIndex:PMsgIndex; BaseRef:String);
    PROCEDURE LookUp(Tag:String);
  END;

  PInputField = ^InputField;
  InputField = OBJECT(TObject)
    Field     : PGenEdit;
    PosKey    : LongInt;
    Reference : LongInt;
    CONSTRUCTOR Init(VAR NewRef; NewField:PGenEdit);
    DESTRUCTOR Done; Virtual;
  END; {OBJ InputField}

  PFieldList = ^FieldList;
  FieldList = OBJECT(TSortedCollection)
    ExitSet   : CharSet;
    LastInput : Word;
    CONSTRUCTOR Init;
    DESTRUCTOR Done;                                 VIRTUAL;
    PROCEDURE Add(VAR NewRef; NewField:PGenEdit);
    FUNCTION  Compare(A,B:Pointer):Integer;          VIRTUAL;
    PROCEDURE Display;
    PROCEDURE Refresh;
    PROCEDURE Edit;
    FUNCTION  Using(VAR Ref):PGenEdit;
    PROCEDURE Fetch(VAR FieldValue);
    FUNCTION  LastChar: Char;                        VIRTUAL;
    FUNCTION  LastKey:Word;                          VIRTUAL;
  END; {OBJ FieldList}

CONST
  nul =^@; soh =^A; stx =^B; etx =^C; eot =^D; enq =^E; ack =^F; bel =^G;
  bs  =^H; ht  =^I; lf  =^J; vt  =^K; ff  =^L; cr  =^M; so  =^N; si  =^O;
  dle =^P; dc1 =^Q; dc2 =^R; dc3 =^S; dc4 =^T; nak =^U; syn =^V; etb =^W;
  can =^X; em  =^Y; sub =^Z; esc =^[; fs  =^\; gs  =^]; rs  =^^; us  =^_;
CONST
  F1 =#219;  sF1 =#231;  cF1 =#243;  aF1 =#164;
  F2 =#220;  sF2 =#232;  cF2 =#244;  aF2 =#165;
  F3 =#221;  sF3 =#233;  cF3 =#245;  aF3 =#166;
  F4 =#222;  sF4 =#234;  cF4 =#246;  aF4 =#167;
  F5 =#223;  sF5 =#235;  cF5 =#247;  aF5 =#168;
  F6 =#224;  sF6 =#236;  cF6 =#248;  aF6 =#169;
  F7 =#225;  sF7 =#237;  cF7 =#249;  aF7 =#170;
  F8 =#226;  sF8 =#238;  cF8 =#250;  aF8 =#171;
  F9 =#227;  sF9 =#239;  cF9 =#251;  aF9 =#172;
  F10=#228;  sF10=#240;  cF10=#252;  aF10=#173;
  F11=#229;  sF11=#241;  cF11=#253;  aF11=#174;
  F12=#230;  sF12=#242;  cF12=#254;  aF12=#175;
CONST
  AutoRecall =$0001; Numeric  =$0002; NotEmpty =$0004; ShowLimits =$0008;
  Uppercase  =$0010; InsertOn =$0020; AutoCR   =$0040; AutoNew    =$0080;
  ExitClear  =$0100;
CONST
  HelpKey : Char = F1;
  DefaultAttrib : Word = AutoRecall+AutoNew;
CONST
  intgset : charset = ['0'..'9','-'];
CONST
  realset : charset = ['0'..'9','.',',','-','E'];
CONST
  fnamset : charset = [' ','"','/','[',']','|','<','>','+','=',';',','];
CONST
  naviset : charset = [^A,^C,^D,^E,^F,^G,^H,^I,^J,^M,^R,^S,^U,^V,^W,^X,^Y,^Z,
                       ^^,^_,esc,F1..F10];
CONST
  NorskSet: charSet = ['ë','õ','Ü','í','ù','è'];
  EdExitSet : CharSet = [Esc, F9];
CONST
  SelectExitText : String ='  Oops';
VAR
  TimeSinceKeyPressed : DateTime;
  CallHelp            : HelpProcType;
  Idle                : IdleDispatcher;


IMPLEMENTATION
USES
  Crt,LFdos,LFcrt;

CONST
  xlateKey : ARRAY[#15..#140] of Char =
  (  ^J,#209,#215,#197,#210,#212,#217,#213,#201,#207,#208, NUL, NUL, NUL, NUL,
   #193,#211,#196,#198,#199,#200,#202,#203,#204, NUL, NUL, NUL, NUL, NUL,
   #218,#216,#195,#214,#194,#206,#205, NUL, NUL, NUL, NUL, NUL, NUL, NUL, NUL,
     F1,  F2,  F3,  F4,  F5,  F6,  F7,  F8,  F9, F10, NUL, NUL,
     ^W,  ^E,  ^R, NUL,  ^S, NUL,  ^D, NUL,  ^Z,  ^X,  ^C,  ^V,  ^G,
    sF1, sF2, sF3, sF4, sF5, sF6, sF7, sF8, sF9,sF10,
    cF1, cF2, cF3, cF4, cF5, cF6, cF7, cF8, cF9,cF10,
    aF1, aF2, aF3, aF4, aF5, aF6, aF7, aF8, aF9,aF10,
   #255,  ^A,  ^F,  ^_,  ^N,  ^^,
   #176,#177,#178,#179,#180,#181,#182,#183,#184,#185, NUL, NUL,
     ^P, F11, F12,sF11,sF12,cF11,cF12,aF11,aF12);
CONST
   AttrCh : ARRAY[1..4,Boolean] OF char =
           (('.','r'),('.','a'),('.','s'),('.','h'));


PROCEDURE NoHelp(HelpTag:InfoIDType); FAR;
{ - Empty help handler }
BEGIN
  {Nothing to do}
END; {PROC NoHelp}

{--- Methods for Object : GenInput ------------------------------------------}

CONSTRUCTOR GenInput.Init(OwnerWS:PWorkSpace; WhatX,WhatY:Integer;
                          InputSet:CharSet);
BEGIN
  TObject.Init;
  Owner:=OwnerWS;
{  MoveTo(WhatX,WhatY);}
  x:=WhatX MOD succ(CharMaxX);
  y:=WhatY MOD succ(CharMaxY);
  IF x=0 THEN x:=1;
  IF y=0 THEN y:=1;
  SetCharSet(InputSet);
END;

PROCEDURE GenInput.SetCharSet(InputSet:CharSet);
{ - Define legal Edit characters }
BEGIN
  LegalChars:=InputSet;
END;{PROC GenInput.SetCharSet}

FUNCTION GenInput.isValid:Boolean;
{ - Return True if last entered value was valid}
BEGIN
  isValid:=Valid;
END;{FUNC GenInput.isValid}

FUNCTION GenInput.isFunction:Boolean;
{ - Return true if last entered value was a two-byte sequence}
BEGIN
  isFunction:=Funk;
END;{FUNC GenInput.isFunction}

FUNCTION GenInput.LastChar:Char;
{ - Return last Edit as character}
BEGIN
  LastChar:=Char(Lo(LastInput));
END;{FUNC GenInput.LastChar}

FUNCTION GenInput.LastKey:Word;
{ - Return last Edit as key}
BEGIN
  LastKey:=LastInput;
END;{FUNC GenInput.LastKey}

PROCEDURE GenInput.MoveTo(toX,toY:Integer);
BEGIN
  x:=toX MOD succ(CharMaxX);
  y:=toY MOD succ(CharMaxY);
  IF x=0 THEN x:=1;
  IF y=0 THEN y:=1;
  Owner^.Cursor^.MoveTo(x,y)
END;{GenInput.MoveTo}

PROCEDURE GenInput.MoveRel(addX,addY:Integer);
BEGIN
  MoveTo(x+addx,y+addy);
END;{GenInput.MoveRel}

PROCEDURE GenInput.UpdateLocation;
{ - Update position }
BEGIN
  MoveTo(x,y);
END;{PROC GenInput.UpdateLocation}

FUNCTION GenInput.AtX:Integer;
{ - Where is X located}
BEGIN
  AtX:=X;
END;{FUNC GenInput.AtX}

FUNCTION GenInput.AtY:Integer;
{ - Where is Y located}
BEGIN
  AtY:=Y;
END;{FUNC GenInput.AtY}


{--- Methods for Object : GenEdit -------------------------------------------}

CONSTRUCTOR GenEdit.Init(OwnerWS:PWorkSpace;
                       WhatX,WhatY,WhatLength:Integer;
                       InputSet:CharSet;
                       TrueIfUpcase:Boolean);
{ - Initialize an Edit abstract}
BEGIN
  GenInput.Init(OwnerWS,WhatX,WhatY,InputSet);
  SetUpcase(TrueIfUpcase);
  SetLength(WhatLength);
  Attrib.Init(DefaultAttrib);
  MarkAll:=False;
  Entered:=False;
  Valid:=False;
  LastInput:=0;
  HelpTag:=NoID;
  LeadText:=Nil;
  TrailText:=Nil;
  xp:=1;
  color:=Owner^.Pane.High;
END;{CONS GenEdit.Init}

DESTRUCTOR GenEdit.Done;
BEGIN
  IF HelpTag=NoID
  THEN BEGIN
    PSDispose(LeadText);
    PSDispose(TrailText);
  END;
  GenInput.Done;
END; {DEST GenEdit.Done}

PROCEDURE GenEdit.Link(Index:PMsgIndex;WhatHelp,Lead,Trail:String);
{ - Define links to helptexts/messages}
VAR
  m : PMsgTxt;
BEGIN
  HelpTag:=WhatHelp;
  IF Index<>nil
  THEN BEGIN
    m:=Index^.FindMsg(Lead);
    IF m<>nil THEN LeadText:=m^.MesText;
    m:=Index^.FindMsg(Trail);
    IF m<>nil THEN TrailText:=m^.MesText;
  END
  ELSE BEGIN
    HelpTag:=NoID;
    PSNew(LeadText,Lead);
    PSNew(TrailText,Trail);
  END;
END;{PROC GenEdit.Link}

PROCEDURE GenEdit.SetLength(WhatLength:Integer);
{ - Define max length of Edit field}
BEGIN
  maxLength:=WhatLength;
END;{PROC GenEdit.SetLength}

PROCEDURE GenEdit.SetUpCase(TrueIfUpcase:Boolean);
{ - Set upper-case switch ): a..z -> A..Z}
BEGIN
  DoUpcase:=TrueIfUpcase;
END;{PROC GenEdit.SetUpcase}

PROCEDURE GenEdit.Edit;
{ - Abstract }
BEGIN
  Abstract; { Should never be called }
END;{PROC GenEdit.Edit}

FUNCTION GenEdit.asText:String;
{ - Return value of Edit field as a string}
BEGIN
  Abstract; { Should never be called }
END;{FUNC GenEdit.asText}

PROCEDURE GenEdit.Display;
{ - Display Edit with text(s) and value }
VAR
  x2 : Integer;
BEGIN
  IF LeadText<>nil
  THEN BEGIN
    x2:=x-Length(LeadText^)-1;
    Owner^.WrtTxt(x2,y,Owner^.Pane.Norm,LeadText^);
  END;
  IF TrailText<>nil
  THEN BEGIN
    x2:=x+MaxLength+1;
    Owner^.WrtTxt(x2,y,Owner^.Pane.Norm,TrailText^);
  END;
  Refresh(0,0);
END;{PROC GenEdit.Display}

PROCEDURE GenEdit.Refresh(From,UpTo:Byte);
{ - Refresh field contents}
VAR
  c:SingleColor;
BEGIN
  IF From=0 THEN From:=1;
  IF UpTo=0 THEN UpTo:=MaxLength;
  IF MarkAll
  THEN c:=Owner^.SelBar.Norm
  ELSE c:=color;
  Owner^.WrtTxt(x+From-1,y,c,Copy(asText,From,UpTo));
END; {PROC GenEdit.Refresh}

{--- Methods for Object : Keystroke ----------------------------------------------}

CONSTRUCTOR Keystroke.Init(Win:PWorkSpace;
                         whatX,whatY:Integer;
                         WhatChars:CharSet;
                         TrueIfUpcase:Boolean);
{ - Initialize an single char Edit field}
BEGIN
  GenEdit.Init(Win,WhatX,WhatY,1,WhatChars,TrueIfUpcase);
END;{CONS Keystroke.Init}

DESTRUCTOR Keystroke.Done;
{ - Clean up after Object key}
BEGIN
  GenEdit.Done;
END;{DEST Keystroke.Done}

PROCEDURE Keystroke.Edit;
{ - Enter the key}
TYPE
  The = RECORD
          Ch   : Char;
          Scan : Char;
        END;
VAR
  Key : Char;
BEGIN
  Valid:=False;
  UpdateLocation;
  IF KeyPressed
  THEN BEGIN
    StartWatch(TimeSinceKeyPressed);
    The(LastInput).Scan:=ReadKey;
    Funk:=(The(LastInput).Scan=#0) and KeyPressed;
    IF Funk
    THEN BEGIN
      Key:=ReadKey;
      CASE Key of
        #15..#140 : key:=xLateKey[key];
               ELSE Key:=nul;
      END;
      The(LastInput).Ch:=Key;
    END
    ELSE BEGIN
      The(LastInput).Ch:=The(LastInput).Scan;
      IF DoUpcase
      THEN The(LastInput).Ch:=upcase{Map[}(The(LastInput).Ch{]});
      IF Attrib.isEnabled(Numeric)
      THEN CASE The(LastInput).Ch OF
         ',' : The(LastInput).Ch:='.';
      END;
    END;
    valid:=The(LastInput).Ch in LegalChars;
    IF The(LastInput).Ch=HelpKey
    THEN CallHelp(HelpTag)
    ELSE IF not valid
    THEN Blip;
  END
  ELSE Idle.Execute(LastInput);
END;{PROC Keystroke.Edit}

PROCEDURE Keystroke.Clear;
BEGIN
  LastInput:=0;
END; {PROC Keystroke.Clear}

FUNCTION Keystroke.WaitForValid:Char;
BEGIN
  REPEAT
    Edit;
  UNTIL Valid;
  WaitForValid:=LastChar;
END; {FUNC Keystroke.WaitForValid}

FUNCTION Keystroke.asText:String;
{ - Return value of Edit field as a string}
BEGIN
  asText:=LastChar;
END;{FUNC Keystroke.asText}


{--- Methods for Object : StrDisplay -------------------------------------------}

CONSTRUCTOR StrDisplay.Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength:Integer;
                   Default:String);
BEGIN
  GenEdit.Init(Win,WhatX,WhatY,WhatLength,[],False);
  GetMem(StringValue,MaxLength+1);
  Assign(Default);
  xp:=1;
  Attrib.Enable(InsertOn);
  IF TypeOf(Self)=TypeOf(StrDisplay)
  THEN color:=Owner^.Pane.Norm;
END;{StrDisplay.Init}

DESTRUCTOR StrDisplay.Done;
BEGIN
  FreeMem(StringValue,MaxLength+1);
  GenEdit.Done;
END;{StrDisplay.Done}

PROCEDURE StrDisplay.Assign(NewDefault:String);
{ - Assign new default value}
BEGIN
  StringValue^:=Copy(NewDefault,1,maxLength);
  IF xp>Length(StringValue^) THEN xp:=Length(StringValue^)+1;
END; {PROC StrDisplay.Assign}

PROCEDURE StrDisplay.Edit;
{ - Edit value of String Object}
BEGIN
  {Do Nothing}
END;{PROC StrDisplay.Edit}

FUNCTION StrDisplay.Value:String;
{ - Returns value of string object}
BEGIN
  Value:=StringValue^;
END;{FUNC StrDisplay.Value}

FUNCTION StrDisplay.asText:String;
{ - Return value of Edit field as a string
    (ho hum... not much conversion here :-) ) }
BEGIN
  IF Entered
  THEN asText:=Copy(Value+Rep(MaxLength,#250),1,MaxLength)
  ELSE asText:=Copy(Value+Rep(MaxLength,' '),1,MaxLength);
END;{FUNC StrDisplay.asText}


{--- Methods for Object : StrInput -------------------------------------------}

CONSTRUCTOR StrInput.Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength:Integer;
                   Default:String;
                   WhatChars:CharSet;
                   TrueIfUpcase:Boolean);
BEGIN
  StrDisplay.Init(Win, whatX,whatY, WhatLength, Default);
  SetCharSet(WhatChars);
  SetUpcase(TrueIfUpcase);
END;{StrInput.Init}

CONST
  SkipSet : CharSet = [#32..#47,#58..#63,#91..#94,#96,#123..#127];
  { Defines characters to be skipped in WordFW/BW search}

PROCEDURE WordBW(st:String; VAR xp:Integer);
{ - Search Backwards in string for start of word}
BEGIN
  IF xp>2
  THEN BEGIN
    dec(xp);
    WHILE (xp>2) and (st[xp] in SkipSet)
    DO dec(xp);
    REPEAT
      dec(xp);
    UNTIL  (st[xp] in SkipSet) or (xp=1);
    IF xp<>1
    THEN inc(xp);
  END
  ELSE xp:=1;
END;{PROC WordBW}

PROCEDURE WordFW(st:String; VAR xp:Integer);
{ - Search Forwards in string for end of word}
VAR
  L : Integer;
BEGIN
  L:=Byte(St[0]);
  IF xp<L
  THEN BEGIN
    WHILE (xp<=L) and not (st[xp] in SkipSet)
     DO inc(xp);
    WHILE (st[xp] in SkipSet) and (xp<=L)
     DO inc(xp);
  END
  ELSE xp:=L+1;
END;{PROC WordFW}

PROCEDURE UpdateCsr(Csr:PCursor; InsOn:Boolean);
BEGIN
  CASE InsOn OF
    True : Csr^.Mode(NormalCsr);
   False : Csr^.Mode(FullCsr);
  END;
END;{PROC UpdateCsr}

PROCEDURE StrInput.Edit;
{ - Edit value of String Object}
VAR
  Key : PKeystroke;
  l   : Integer;
  nxp : Integer;
  DoRef : Boolean;
  Comp : ^String;
  PrevState : CursorSize;
BEGIN
  GetMem(Comp,MaxLength+1);
  Entered:=True;
  Valid:=False;
  xp:=1;
  New(Key,Init(Owner,x+xp,y,
      LegalChars+[^A,^E,^X,^V,^S,^D,^F,^M,^G,^H,^T,^W,^Z,^I]+EdExitSet,
      DoUpCase));
  Key^.HelpTag:=HelpTag;
  Key^.Clear;
  Key^.Attrib:=Attrib;
  PrevState:=Owner^.Cursor^.State;
  Owner^.Cursor^.MoveTo(x+xp-1,y);
  UpdateCsr(Owner^.Cursor,Attrib.IsEnabled(InsertOn));
  Owner^.Cursor^.Show;
  MarkAll:=Attrib.IsEnabled(AutoNew);
  Refresh(0,0);
  DoRef:=False;
  REPEAT
    IF DoRef
    THEN BEGIN
      Refresh(0,0);
      DoRef:=False;
      Comp^:=StringValue^;
    END;
    Key^.MoveTo(x+xp-1,y);
    Key^.Edit;
    LastInput:=Key^.LastInput;
    IF Key^.Valid
    THEN BEGIN
      l:=Length(StringValue^);
      CASE Key^.LastChar OF
        ^A : BEGIN {Word Left}
               nxp:=xp;
               WordBW(StringValue^,xp);
               IF xp=nxp THEN Valid:=True;
             END;
        ^D : IF xp<l+1 THEN inc(xp) ELSE Valid:=True; {Char Right}
        ^F : BEGIN {Word Right}
               nxp:=xp;
               WordFW(StringValue^,xp);
               IF xp=nxp THEN Valid:=True;
             END;
        ^G : IF l>0 THEN {Delete char under cursor}
             BEGIN
               IF xp>l THEN dec(xp);
               Delete(StringValue^,xp,1);
             END;
        ^H : IF (l>0) and (xp>1) {Backspace}
             THEN BEGIN
               Dec(xp);
               Delete(StringValue^,xp,1);
             END;
        ^S : IF xp>1 THEN Dec(xp) ELSE Valid:=True; {Char Left}
        ^T : BEGIN {Delete from cursor to next word}
               nxp:=xp;
               WordFW(StringValue^,nxp);
               Delete(StringValue^,xp,nxp-xp);
             END;
        ^V : BEGIN {Toggle Insert/Overwrite mode}
               Attrib.Toggle(InsertOn);
               UpdateCsr(Owner^.Cursor,Attrib.IsEnabled(InsertOn));
             END;
        ^W : xp:=1; {Home}
        ^Z : xp:=l+1; {End}
        ELSE BEGIN
          IF Key^.LastChar In [^M,^E,^X,^I]+EdExitSet
          THEN Valid:=True
          ELSE IF (xp<=l+1) and (l<maxLength)
              or Attrib.isDisabled(InsertOn)
              or MarkAll
          THEN BEGIN
            IF MarkAll THEN StringValue^:='';
            IF Attrib.isDisabled(InsertOn) THEN Delete(StringValue^,xp,1);
            Insert(Key^.LastChar,StringValue^,xp);
            Inc(xp);
          END;
        END;
      END;
      IF MarkAll
      THEN BEGIN
        MarkAll:=False;
        Refresh(0,0);
      END;
    END;
    DoRef:=Comp^<>StringValue^;
  UNTIL Valid;
  LastInput:=Key^.LastInput;
  Dispose(Key,Done);
  FreeMem(Comp,MaxLength+1);
  Entered:=False;
  Owner^.Cursor^.Mode(PrevState);
  Refresh(0,0);
END;{PROC StrInput.Edit}


{--------------------------------------------------------------- StrPInput ---

}


CONSTRUCTOR StrPInput.Init(Win:PWorkSpace;
                   whatX,whatY,
                   WhatLength:Integer;
                   Default:PString;
                   WhatChars:CharSet;
                   TrueIfUpcase:Boolean);
VAR
  s : String;
BEGIN
  IF Default<>nil THEN s:=Default^ ELSE s:='';
  StrInput.Init(Win,WhatX,WhatY,WhatLength,s,WhatChars,TrueIfUpcase);
END;{StrPInput.Init}

FUNCTION StrPInput.PValue:PString;
{ - Returns value of string object}
VAR
  p : PString;
BEGIN
  PSNew(p,Value);
  PValue:=p;
END;{FUNC StrPInput.PValue}


{------------------------------------------------------------- IntDisplay ---

}

CONSTRUCTOR IntDisplay.Init(Win:PWorkSpace;
                       whatX,whatY,
                       WhatLength:Integer;
                       Def : LongInt);
{ - Initialize the Integer object }
BEGIN
  GenEdit.Init(Win,WhatX,WhatY,WhatLength,['0'..'9','-','+'],True);
  Assign(Def);
  IF TypeOf(Self)=TypeOf(IntDisplay)
  THEN color:=Owner^.Pane.Low;
END;{CONS IntDisplay.Init}

PROCEDURE IntDisplay.Assign(NewDefault:LongInt);
{ - Assign new default value}
BEGIN
  IntValue:=NewDefault;
END; {PROC IntDisplay.Assign}

PROCEDURE IntDisplay.Edit;
BEGIN
  {Do nothing}
END;{PROC IntDisplay.Edit}

FUNCTION IntDisplay.Value:LongInt;
BEGIN
  Value:=IntValue;
END;{IntDisplay.Value}

FUNCTION IntDisplay.asText:String;
{ - Return value of Edit field as a string}
BEGIN
  asText:=IntStr(Value,MaxLength);
END;{FUNC IntDisplay.asText}


{--- Methods for Object : IntInput -----------------------------------------}

PROCEDURE IntInput.SetLimits(min,max:LongInt);
{ - Set extremal values for Float Objects}
BEGIN
  minValue:=min;
  maxValue:=max;
END;{PROC IntInput.SetLimits}

CONSTRUCTOR IntInput.Init(Win:PWorkSpace;
                       whatX,whatY,
                       WhatLength:Integer;
                       Min,Def,Max : LongInt);
{ - Initialize the Integer object }
BEGIN
  IntDisplay.Init(Win,WhatX,WhatY,WhatLength,Def);
  SetLimits(Min,Max);
END;{CONS IntInput.Init}

PROCEDURE IntInput.Edit;
{ - Edit the Integer value}
VAR
  St : PStrInput;
  e  : Integer;
  v  : LongInt;
BEGIN
  New(st,Init(Owner,x,y,MaxLength,IntStr(Value,0),LegalChars,DoUpCase));
  st^.HelpTag:=HelpTag;
  REPEAT
    st^.Edit;
    VAL(st^.Value,v,e);
    Valid:=e=0;
    Valid:=Valid and ((v>=MinValue) and (v<=MaxValue));
    IF Valid THEN IntValue:=v;
  UNTIL Valid or (st^.lastChar=Esc);
  LastInput:=St^.LastInput;
  Dispose(St,Done);
  Refresh(0,0);
END;{PROC IntInput.Edit}

{--- Methods for Object : FloatInput --------------------------------------------}

PROCEDURE FloatInput.SetLimits(min,max:Float);
{ - Set extremal value for Float Object}
BEGIN
  minValue:=min;
  maxValue:=max;
END;{PROC FloatInput.SetLimits}

CONSTRUCTOR FloatInput.Init(Win:PWorkSpace;
                       whatX,whatY,
                       WhatLength,Decim:Integer;
                       Min,Def,Max : Float);
{ - Initialize a Float Object}
BEGIN
  GenEdit.Init(Win,WhatX,WhatY,WhatLength,['0'..'9','-','+','.',',','E'],True);
  Attrib.Enable(Numeric);
  SetLimits(Min,Max);
  FloatValue:=Def;
  Decimals:=2;
END;{CONS FloatInput.Init}

DESTRUCTOR FloatInput.Done;
{ - Clean up after Float Object}
BEGIN
  GenEdit.Done;
END;{DEST FloatInput.Done}

PROCEDURE FloatInput.Assign(NewDefault:Float);
{ - Assign new default value}
BEGIN
  FloatValue:=NewDefault;
END; {PROC IntDisplay.Assign}

PROCEDURE FloatInput.Edit;
{ - Edit value of Float Object}
VAR
  St : PStrInput;
  e  : Integer;
  f  : Float;
BEGIN
  New(st,Init(Owner,x,y,MaxLength,RealStr(Value,0,Decimals),
      LegalChars,DoUpCase));
  st^.HelpTag:=HelpTag;
  st^.Attrib:=Attrib;
  REPEAT
    st^.Edit;
    VAL(st^.Value,f,e);
    Valid:=e=0;
    Valid:=Valid and ((f>=MinValue) and (f<=MaxValue));
    IF Valid THEN FloatValue:=f;
  UNTIL Valid or (St^.LastChar=Esc);
  LastInput:=St^.LastInput;
  Dispose(St,Done);
  Refresh(0,0);
END;{PROC FloatInput.Edit}

FUNCTION FloatInput.Value:Float;
{ - Return value of Float Object}
BEGIN
  Value:=FloatValue;
END;{FUNC FloatInput.Value}

FUNCTION FloatInput.asText:String;
{ - Return value of Edit field as a string}
BEGIN
  asText:=RealStr(Value,MaxLength,Decimals);
END;{FUNC FloatInput.asText}


{--- Methods for Object : SelectInput ---------------------------------------------}

CONSTRUCTOR SelectInput.Init(Win:PWorkspace; Whatx,Whaty,
                             MaxLen:Integer;
                             TxtRef:PTextTxt);
{ - Init multiple Select object}
BEGIN
  GenEdit.Init(Win,WhatX,WhatY,MaxLen,LegalChars,True);
  Option:=TxtRef;
END;{CONS SelectInput.Init}


{--- Methods for Object : ChoiceInput ---------------------------------------------}

CONSTRUCTOR ChoiceInput.Init(Win:PWorkspace; Whatx,Whaty,
                             MaxLen,Curr:Integer;
                             TxtRef:PTextTxt);
{ - Init multiple choice object}
BEGIN
  GenEdit.Init(Win,WhatX,WhatY,MaxLen,LegalChars,True);
  Option:=TxtRef;
  Assign(Curr);
END;{CONS ChoiceInput.Init}

PROCEDURE ChoiceInput.Assign(NewDefault:Integer);
{ - Assign new default value}
BEGIN
  IF NewDefault<1 THEN NewDefault:=1
  ELSE IF NewDefault>Option^.Lines
  THEN NewDefault:=Option^.Lines;
  Current:=NewDefault;
END; {PROC ChoiceInput.Assign}


FUNCTION ChoiceInput.asText:String;
{ - Return value of Edit field as a string
    (ho hum... not much conversion here :-) ) }
BEGIN
  asText:=Copy(Option^.TextAtLine(Current-1)+Rep(MaxLength,' '),1,MaxLength);
                                    { ^ -1 because of TCollection index}
END;{FUNC ChoiceInput.asText}

PROCEDURE ChoiceInput.Edit;
{ - user select }
CONST
  nk : char = nul;
VAR
  Key : PKeystroke;
  sKey : Str2;
  Search : Integer;
  PrevState : CursorSize;
BEGIN
  Entered:=True;
  Valid:=False;
  xp:=1;
  New(Key,Init(Owner,x+xp,y,
      [^A,^E,^X,^S,^D,^F,^M,^H,#32..#127]+EdExitSet,
      DoUpCase));
  Key^.HelpTag:=HelpTag;
  Key^.Clear;
  PrevState:=Owner^.Cursor^.State;
  MarkAll:=True;
  Refresh(0,0);
  REPEAT
    Key^.Edit;
    IF Key^.Valid
    THEN BEGIN
      CASE Key^.LastChar OF
        ^R     : IF Current>1 THEN Dec(Current) ELSE Current:=Option^.Lines;
        ^C,#32 : IF Current<Option^.Lines THEN Inc(Current) ELSE Current:=1;
        ELSE IF Key^.LastChar In [^A,^E,^X,^S,^D,^F,^M]+EdExitSet
         THEN Valid:=True
          ELSE IF (key^.LastChar in [^H,#33..#127]) THEN
             BEGIN
               Search:=Current;
               REPEAT
                 inc(search);
                 IF search > Option^.Lines THEN search:=1;
                 sKey:=Copy(Option^.TextAtLine(Search-1),1,1);
                 UpSt(sKey);
                 IF sKey[1] IN [#0..#31] THEN sKey[1]:=^H;
               UNTIL (sKey[1]=key^.LastChar) or (Search=Current);
               Current:=Search;
             END;
      END;
      Refresh(0,0);
    END;
  UNTIL Valid;
  LastInput:=Key^.LastInput;
  Dispose(Key,Done);
  Owner^.Cursor^.Mode(PrevState);
  Entered:=False;
  MarkAll:=False;
  Refresh(0,0);
END; {PROC ChoiceInput.Edit}

FUNCTION ChoiceInput.Value:Integer;
{ - Return index of selected multiple choice Object}
BEGIN
  IF LastChar=ESC
  THEN Value:=0
  ELSE Value:=Current;
END;{FUNC ChoiceInput.Value}

{--- Methods for Object : BooleanInput ---------------------------------------------}

CONSTRUCTOR BooleanInput.Init(Win:PWorkspace; Whatx,Whaty,
                             MaxLen:Integer;  Def:Boolean;
                             TxtRef:PTextTxt);
{ - Init multiple Boolean object}
BEGIN
  SelectInput.Init(Win,WhatX,WhatY,MaxLen,TxtRef);
  Assign(Def);
END;{CONS BooleanInput.Init}

PROCEDURE BooleanInput.Assign(NewDefault:Boolean);
{ - Assign new default value}
BEGIN
  IF NewDefault
  THEN Current:=1
  ELSE Current:=2;
END; {PROC BooleanInput.Assign}


FUNCTION BooleanInput.asText:String;
{ - Return value of Edit field as a string
    (ho hum... not much conversion here :-) ) }
BEGIN
  asText:=Copy(Option^.TextAtLine(Current-1)+Rep(MaxLength,' '),1,MaxLength);
                                    { ^ -1 because of TCollection index}
END;{FUNC BooleanInput.asText}

PROCEDURE BooleanInput.Edit;
{ - user select }
CONST
  nk : char = nul;
VAR
  Key : PKeystroke;
  sKey : Str2;
  Search : Integer;
  PrevState : CursorSize;
BEGIN
  Entered:=True;
  Valid:=False;
  xp:=1;
  New(Key,Init(Owner,x+xp,y,
      [^A,^E,^X,^S,^D,^F,^M,^H,#32..#127]+EdExitSet,
      DoUpCase));
  Key^.HelpTag:=HelpTag;
  Key^.Clear;
  PrevState:=Owner^.Cursor^.State;
  MarkAll:=True;
  Refresh(0,0);
  REPEAT
    Key^.Edit;
    IF Key^.Valid
    THEN BEGIN
      CASE Key^.LastChar OF
        #32 : IF Current<2 THEN Inc(Current) ELSE Current:=1;
        ELSE IF Key^.LastChar IN [^A,^E,^X,^S,^D,^F,^M]+EdExitSet
         THEN Valid:=True
          ELSE IF (key^.LastChar in [^H,#33..#127]) THEN
             BEGIN
               Search:=Current;
               REPEAT
                 inc(search);
                 IF search > 2 THEN search:=1;
                 sKey:=Copy(Option^.TextAtLine(Search-1),1,1);
                 UpSt(sKey);
                 IF sKey[1] IN [#0..#31] THEN sKey[1]:=^H;
               UNTIL (sKey[1]=key^.LastChar) or (Search=Current);
               Current:=Search;
             END;
      END;
      Refresh(0,0);
    END;
  UNTIL Valid;
  LastInput:=Key^.LastInput;
  Dispose(Key,Done);
  Owner^.Cursor^.Mode(PrevState);
  Entered:=False;
  MarkAll:=False;
  Refresh(0,0);
END; {PROC BooleanInput.Edit}

FUNCTION BooleanInput.Value:Boolean;
{ - Return state of selected Boolean Object}
BEGIN
  Value:=Boolean((Current=1) and True);
END;{FUNC BooleanInput.Value}




{-------------------------------------------------------------- MenuInput ---
}

CONSTRUCTOR MenuInput.Init(OwnerWin:PWindow; VisualLines:Integer; MnuRef:PMenuTxt);
{ - Init menu object}
VAR
  i,w : Integer;
BEGIN
  PWindow(Owner):=OwnerWin;
  Mnu:=MnuRef;
  IF Mnu^.Title=nil THEN PSNew(Mnu^.Title,'');            {//////// DIRTY}
  vColumns:=Length(Mnu^.Title^); { Find longest string in menu }
  FOR i:=0 TO Mnu^.Lines-1
  DO BEGIN
    w:=Length(Mnu^.TextAtLine(i));
    IF w>vColumns THEN vColumns:=w;
  END;
  IF Mnu^.Title^<>''
  THEN PWindow(Owner)^.TitlePtr(Mnu^.Title,nil);
  IF PWindow(Owner)^.Header<>nil
  THEN BEGIN
    w:=Length(pWindow(Owner)^.Header^);
    IF w>vColumns THEN vColumns:=w;
  END;
  IF PWindow(Owner)^.Footer<>nil
  THEN BEGIN
    w:=Length(pWindow(Owner)^.Footer^);
    IF w>vColumns THEN vColumns:=w;
  END;
  IF Mnu^.Lines<VisualLines
  THEN vLines:=Mnu^.Lines
  ELSE vLines:=VisualLines;
  PWindow(Owner)^.TxtAdjSize(vColumns+2,vLines);
  Current:=1;
END;{CONS MenuInput.Init}

PROCEDURE MenuInput.Select;
{ - Opens owning window and lets user select }
VAR
  CurrBase,            {Number of lines *before* current first visible line}
  PrevBase,            {Number of lines *before* previous first visible line}
  CurrOfs,             {Offset from Current Base}
  PrevOfs      : Integer;{Offset from Previous Base}
  Key          : PKeystroke;  {Keyboard input}
  ForcedRedraw : Boolean; {Used to force list redraw/select bar
                           to redraw/select}

  PROCEDURE MoveBar(nLine:Integer);
  { - Recalc ScrollBar and Redisplay if necesarry }
  VAR
    dl,i : Integer;
    cc   : SingleColor;
  BEGIN
    IF nLine<0 THEN nLine:=1;
    dl:=nLine-(CurrBase+CurrOfs);
    IF (nLine>CurrBase) and (nLine<=CurrBase+vLines)
    THEN CurrOfs:=nLine-CurrBase
    ELSE CASE dl OF
      -1 : IF CurrOfs>1
           THEN dec(CurrOfs)
           ELSE dec(CurrBase);       {Scroll up}
       1 : IF CurrOfs<vLines
           THEN inc(CurrOfs)
           ELSE inc(CurrBase);       {Scroll down}
       ELSE BEGIN                    {Page up/down}
         CurrBase:=CurrBase+dl;
         IF CurrBase<0 THEN CurrBase:=0;
         IF CurrBase+vLines>Mnu^.Lines
         THEN CurrBase:=Mnu^.Lines-vLines;
         CurrOfs:=nLine-CurrBase;
       END;
    END;
    WITH PWindow(Owner)^ DO
    BEGIN
      IF not ForcedRedraw
      THEN BEGIN
        WorkSpace^.TxtBar(0,PrevOfs-1,vColumns+2,WorkSpace^.Pane.Norm);
        IF Mnu^.LineIsActive(PrevBase+PrevOfs-1)
        THEN cc:=WorkSpace^.Pane.Norm
        ELSE cc:=WorkSpace^.Pane.Low;
        WorkSpace^.WrtTxt(1,PrevOfs-1,cc,Mnu^.TextAtLine(PrevBase+PrevOfs-1));
      END;
      IF (CurrBase<>PrevBase) or ForcedRedraw
      THEN BEGIN
        WorkSpace^.Clear;
        FOR i:=0 TO vLines-1
        DO BEGIN
          IF Mnu^.LineIsActive(CurrBase+i)
          THEN cc:=WorkSpace^.Pane.Norm
          ELSE cc:=WorkSpace^.Pane.Low;
          WorkSpace^.WrtTxt(1,i,cc, Mnu^.TextAtLine(CurrBase+i))
        END;
        PrevBase:=CurrBase;
      END;
      WorkSpace^.TxtBar(0,CurrOfs-1,vColumns+2,WorkSpace^.SelBar.Norm);
      IF Mnu^.LineIsActive(CurrBase+CurrOfs-1)
      THEN cc:=WorkSpace^.SelBar.Norm
      ELSE cc:=WorkSpace^.SelBar.Low;
      WorkSpace^.WrtTxt(1,CurrOfs-1,cc,Mnu^.TextAtLine(CurrBase+CurrOfs-1));
      PrevOfs:=CurrOfs;
    END;
  END; {PROC MenuInput.Select LOCAL PROC MoveBar}

VAR
  Search : Integer;
  sKey   : String[1];
CONST
  CtrlSet : CharSet = [^E,^X,^R,^C,^W,^Z,^^,^_,^I];
BEGIN
  New(Key,Init(PWindow(Owner)^.WorkSpace,
      1,1,[^M,ESC,^H,#32..#127]+CtrlSet,True));
  Valid:=False;
  PWindow(Owner)^.Open;
  PWindow(Owner)^.WorkSpace^.Cursor^.Mode(HiddenCsr);
  CurrBase:=0; CurrOfs:=1;
  PrevBase:=CurrBase; PrevOfs:=CurrOfs;
  ForcedRedraw:=True; MoveBar(Current); ForcedRedraw:=False;
  REPEAT
    IF (PrevBase+PrevOfs<>Current) or ForcedRedraw
    THEN MoveBar(Current);
    ForcedRedraw:=False;
    Key^.Edit;
    IF Key^.Valid
    THEN BEGIN
      CASE Key^.LastChar OF
        ^E : IF Current>1 THEN Dec(Current);
        ^X : IF Current<Mnu^.Lines THEN Inc(Current);
        ^M : IF Mnu^.LineIsActive(Current-1)
             THEN Valid:=True
             ELSE BEGIN
               Blip;
               Key^.LastInput:=$FFFF
             END;
        ^R : IF Current>vLines
             THEN Current:=Current-vLines
             ELSE Current:=1;
        ^W : Current:=CurrBase+1;
        ^^ : Current:=1;
        ^C : IF Current+vLines<Mnu^.Lines
             THEN Current:=Current+vLines
             ELSE Current:=Mnu^.Lines;
        ^Z : Current:=CurrBase+vLines;
        ^_ : Current:=Mnu^.Lines;
        ELSE IF (key^.LastChar in [^H,#32..#127]) THEN
             BEGIN
               Search:=Current;
               REPEAT
                 inc(search);
                 IF search > Mnu^.Lines THEN search:=1;
                 sKey:=Copy(Mnu^.TextAtLine(Search-1),1,1);
                 UpSt(sKey);
                 CASE sKey[1] OF
                      #0 : sKey[1]:=#32;
                 #1..#31 : sKey[1]:=^H;
                 END;
               UNTIL (sKey[1]=key^.LastChar) or (Search=Current);
               Current:=Search;
             END;
      END;
    END;
  UNTIL Valid or (Key^.LastChar in EdExitSet);
  LastInput:=Key^.LastInput;
  Dispose(Key,Done);
  PWindow(Owner)^.Close;
END; {PROC MenuInput.Select}

FUNCTION MenuInput.Choice:Integer;
BEGIN
  IF LastChar=ESC
  THEN Choice:=0
  ELSE Choice:=Current;
END; {FUNC MenuInput.Choice}

{-------------------------------------------------------------- HyperText ---
}

TYPE
  Ref_P = ^Ref;
  Ref = OBJECT(TObject)
    pos : Integer;
    txt : PString;
    Tag : PString;
    CONSTRUCTOR Init(NewPos:Integer; NewTxt:String; NewTag:String);
    DESTRUCTOR Done; VIRTUAL;
  END; {OBJ Ref}

  LineR_P = ^LineRefs;
  LineRefs = OBJECT(TCollection)
    Refs : Integer;
    CONSTRUCTOR Init;
    DESTRUCTOR Done; VIRTUAL;
    PROCEDURE Add(NewPos:Integer; NewTxt:String; NewTag:String);
  END; {OBJ LineRefs}

  Lines = OBJECT(TCollection)
    Owner  : PWindow;
    RefCnt : Integer;
    PrevRow,PrevCol,
    Row,Col: Integer;
    FirstPass : Boolean;
    CONSTRUCTOR Init(OwnerWin:PWindow);
    DESTRUCTOR Done; VIRTUAL;
    PROCEDURE Add(NewPos:Integer; NewTxt:String; NewTag:String);
    PROCEDURE NewLine;
    PROCEDURE GoUp;
    PROCEDURE GoDown;
    PROCEDURE GoPrev;
    PROCEDURE GoNext;
    PROCEDURE GoHome;
    PROCEDURE GoEnd;
    PROCEDURE UpDate;
    FUNCTION  CurrTag:String;
  END; {OBJ Lines}

CONSTRUCTOR Ref.Init(NewPos:Integer; NewTxt:String; NewTag:String);
BEGIN
  TObject.Init;
  PSNew(Txt,NewTxt);
  Pos:=NewPos;
  PSNew(Tag,NewTag);
END; {CONS Ref.Init}

DESTRUCTOR Ref.Done;
BEGIN
  PSDispose(Tag);
  PSDispose(Txt);
  TObject.Done;
END; {DEST Ref.Done}

CONSTRUCTOR LineRefs.Init;
BEGIN
  TCollection.Init(2,1);
END; {CONS LineRefs.Init}

DESTRUCTOR LineRefs.Done;
BEGIN
  TCollection.Done;
END; {DEST LineRefs.Done}

PROCEDURE LineRefs.Add(NewPos:Integer; NewTxt:String; NewTag:String);
BEGIN
  TCollection.Insert(New(Ref_P,Init(NewPos,NewTxt,NewTag)));
END; {PROC LineRefs.Add}

CONSTRUCTOR Lines.Init(OwnerWin:PWindow);
BEGIN
  TCollection.Init(4,2);
  Owner:=OwnerWin;
  RefCnt:=0;
  Row:=0;
  Col:=0;
END; {CONS Lines.Init}

DESTRUCTOR Lines.Done;
BEGIN
  TCollection.Done;
END; {DEST Lines.Done}

PROCEDURE Lines.Add(NewPos:Integer; NewTxt:String; NewTag:String);
VAR
  LR : LineR_P;
BEGIN
  Inc(RefCnt);
  LR:=LineR_P(At(Count-1));
  LR^.Add(NewPos,NewTxt,NewTag);
  IF RefCnt=1
  THEN BEGIN
    Row:=Count;
    Col:=1;
    FirstPass:=True;
    PrevRow:=Not Row;
    PrevCol:=Not Col;
  END;
END; {PROC Lines.Add}

PROCEDURE Lines.NewLine;
BEGIN
  TCollection.Insert(New(LineR_P,Init));
END; {PROC Lines.NewLine}

PROCEDURE Lines.GoUp;
BEGIN
  IF RefCnt>1
  THEN BEGIN
    IF Row>1 THEN Dec(Row);
    WHILE (Row>1) and (LineR_P(At(Row-1))^.Count=0) DO Dec(Row);
    IF (LineR_P(At(Row-1))^.Count=0)
    THEN Row:=PrevRow
    ELSE BEGIN
      IF Col>LineR_P(At(Row-1))^.Count THEN Col:=LineR_P(At(Row-1))^.Count;
    END;
  END;
END; {PROC Lines.GoUp}

PROCEDURE Lines.GoDown;
BEGIN
  IF RefCnt>1
  THEN BEGIN
    IF Row<Count THEN Inc(Row);
    WHILE (Row<Count) and (LineR_P(At(Row-1))^.Count=0) DO Inc(Row);
    IF (LineR_P(At(Row-1))^.Count=0)
    THEN Row:=PrevRow
    ELSE BEGIN
      IF Col>LineR_P(At(Row-1))^.Count THEN Col:=LineR_P(At(Row-1))^.Count;
    END;
  END;
END; {PROC Lines.GoDown}

PROCEDURE Lines.GoPrev;
BEGIN
  IF RefCnt>1
  THEN BEGIN
    IF Col>1
    THEN Dec(Col)
    ELSE BEGIN
      Col:=1000;
      GoUp;
      IF Row=PrevRow THEN Col:=PrevCol;
    END;
  END;
END; {PROC Lines.GoPrev}

PROCEDURE Lines.GoNext;
BEGIN
  IF RefCnt>1
  THEN BEGIN
    IF Col<LineR_P(At(Row-1))^.Count
    THEN Inc(Col)
    ELSE BEGIN
      Col:=1;
      GoDown;
      IF Row=PrevRow THEN Col:=PrevCol;
    END;
  END;
END; {PROC Lines.GoNext}

PROCEDURE Lines.GoHome;
VAR
  p : Integer;
BEGIN
  IF RefCnt>1
  THEN BEGIN
    p:=1; Col:=1;
    WHILE (p<Count) and (LineR_P(At(p-1))^.Count=0) DO Inc(p);
    Row:=p;
  END;
END; {PROC Lines.GoHome}

PROCEDURE Lines.GoEnd;
VAR
  p : Integer;
BEGIN
  IF RefCnt>1
  THEN BEGIN
    p:=Count;
    WHILE (p>1) and (LineR_P(At(p-1))^.Count=0) DO Dec(p);
    Row:=p;
    Col:=LineR_P(At(Row-1))^.Count;
  END;
END; {PROC Lines.GoEnd}

PROCEDURE Lines.UpDate;
VAR
  P : Ref_P;
BEGIN
  WITH Owner^ DO
  IF (RefCnt>0) and ((PrevRow<>Row) or (PrevCol<>Col))
  THEN BEGIN
    IF Not FirstPass
    THEN BEGIN
      P:=Ref_P(LineR_P(At(PrevRow-1))^.At(PrevCol-1));
      WorkSpace^.WrtTxt(P^.pos,PrevRow-1,WorkSpace^.Pane.High,P^.Txt^);
    END
    ELSE FirstPass:=False;
    P:=Ref_P(LineR_P(At(Row-1))^.At(Col-1));
    WorkSpace^.WrtTxt(P^.pos,Row-1,WorkSpace^.SelBar.Norm,P^.Txt^);
    PrevRow:=Row;
    PrevCol:=Col;
  END;
END; {PROC Lines.UpDate}

FUNCTION Lines.CurrTag:String;
BEGIN
  IF RefCnt>0
  THEN CurrTag:=Ref_P(LineR_P(At(Row-1))^.At(Col-1))^.Tag^;
END; {FUNC Lines.CurrTag}

CONSTRUCTOR HyperText.Init(OwnerWin:PWindow; TextIndex:PMsgIndex; BaseRef:String);
{ - Prepare Hypertext object}
VAR
  Item,
  GetvLines,
  GetvColumns : Integer;
  i , l : Integer;
  H : PHelpTxt;
BEGIN
  PWindow(Owner):=OwnerWin;
  Index:=TextIndex;
  HelpTag:=BaseRef;
  GetvLines:=2;
  GetvColumns:=10;
  FOR Item:=0 TO Index^.Count-1
  DO BEGIN
    H:=Index^.At(Item);
    IF TypeOf(H^)=TypeOf(HelpTxt)
    THEN BEGIN
      l:=H^.Lines;
      IF l>GetvLines THEN GetvLines:=l;
      FOR i:=0 TO H^.Lines-1
      DO BEGIN
        l:=Length(H^.TextAtLine(i));
        IF l>GetvColumns THEN GetvColumns:=l;
      END;
    END;
  END;
  vLines:=GetvLines+1;
  vColumns:=GetvColumns+2;
  PWindow(Owner)^.TxtAdjSize(vColumns,vLines);
{  Owner^.CenterAround(40,12);}
END; {CONS HyperText.Init}

PROCEDURE HyperText.LookUp(Tag:String);
{ - Search in HyperBase after Tag }
VAR
  PrevHelpProc : HelpProcType;
  CurrHelp,PrevHelp : PHelpTxt;
  TagRef      : Lines;
  s : String;
  Key : PKeystroke;

  PROCEDURE Redraw;
  VAR
    i,n : Integer;
    rLine : RefEntryPtr;
    tRef : RefLstPtr;
    st   : String[50];
  BEGIN
    WITH PWindow(Owner)^
    DO BEGIN
      Frame;
      Clear;
      FOR i:=0 TO CurrHelp^.Lines-1
      DO BEGIN
        TagRef.NewLine;
        rLine:=RefEntryPtr(CurrHelp^.atLine(i));
        IF rLine^.Txt<>nil
        THEN BEGIN
          WorkSpace^.WrtTxt(1,i,WorkSpace^.Pane.Norm,rLine^.Txt^);
          FOR n:=0 TO rLine^.Ref^.Count-1
          DO BEGIN
            tRef:=rLine^.Ref^.At(n);
            St:=Copy(rLine^.Txt^,tRef^.Starts-1,tRef^.length+1);
            TagRef.Add(tRef^.Starts-1,st,tRef^.ID^);
            WorkSpace^.WrtTxt(tRef^.Starts-1,i,WorkSpace^.Pane.High,st);
          END;
        END;
      END;
      TagRef.Update;
    END;
  END;{PROC HyperText.LookUp LOCAL PROC Redraw}
BEGIN
  PrevHelpProc:=CallHelp;
  CallHelp:=NoHelp;
  PWindow(Owner)^.Title(' ? ','');
  PWindow(Owner)^.WorkSpace^.Cursor^.Mode(HiddenCsr);
  PWindow(Owner)^.Open;
  New(Key,Init(PWindow(Owner)^.WorkSpace,
      0,0,[^M,^E,^X,^S,^D,^W,^Z,^O,Esc,^I,HelpKey],True));
  CurrHelp:=nil;
  REPEAT
    TagRef.Init(PWindow(Owner));
    IF Tag='' THEN Tag:=HelpTag;
    PrevHelp:=CurrHelp;
    CurrHelp:=Index^.FindHelp(Tag);
    IF CurrHelp=nil                         {No subject, lookup main tag}
    THEN CurrHelp:=Index^.FindHelp(HelpTag);
    IF CurrHelp<>nil
    THEN BEGIN
      IF CurrHelp<>PrevHelp
      THEN BEGIN
        PWindow(Owner)^.TitlePtr(CurrHelp^.Title,nil);
        Redraw;
      END;
      REPEAT
        Key^.Edit;
        IF Key^.Valid
        THEN BEGIN
          CASE Key^.LastChar OF
            ^W :TagRef.GoHome;
            ^Z :TagRef.GoEnd;
            ^E :TagRef.GoUp;
            ^X :TagRef.GoDown;
            ^S,^O :TagRef.GoPrev;
            ^D,^I :TagRef.GoNext;
            ^M :IF (TagRef.RefCnt=0) and (PrevHelp<>nil)
                THEN Tag:=PrevHelp^.ID^ {Return to previous}
                ELSE Tag:=TagRef.CurrTag; {Jump to ref.tag}
            ELSE IF (Key^.LastChar=HelpKey) { More help }
            THEN BEGIN
              IF CurrHelp^.GroupRef=nil
              THEN Tag:=HelpTag
              ELSE Tag:=CurrHelp^.GroupRef^;
            END;
          END;
          Key^.Valid:=(Key^.LastChar in [^M,Esc,HelpKey]);
          IF Not Key^.Valid
          THEN TagRef.Update;
        END;
      UNTIL Key^.Valid;
    END;
    TagRef.Done;
  UNTIL (Key^.LastChar=Esc) or (CurrHelp=nil);
  Dispose(Key,Done);
  PWindow(Owner)^.Close;
  CallHelp:=PrevHelpProc;
END; {PROC HyperText.LookUp}

{--- Methods for Object : InputField --------------------------------------------}

CONSTRUCTOR InputField.Init(VAR NewRef; NewField:PGenEdit);
{ - Initialize a new field }
BEGIN
  TObject.Init;
  Field:=NewField;
  Reference:=LongInt(Addr(NewRef));
  PosKey:=(Field^.y*1024)+Field^.x;
  { Calculates a Position Key based on a maximum
    resolution of 1024 horisontal screen positions.
    (Vertical resolution is restricted by MaxLongInt DIV 1024) }
END; {CONS InputField.Init}

DESTRUCTOR InputField.Done;
{ - Clean up after a field }
BEGIN
  Dispose(Field,Done); { DeAllocate field (Virtual Done) }
  Field:=nil;
  TObject.Done;
END; {DEST InputField.Done}


{--- Methods for Object : FieldList ----------------------------------------}

FUNCTION FieldList.Compare(A,B:Pointer):Integer;
{*
 * Compare two Field positions, Return  -1: A<B,  0: A=B,  1: A>B
 * Used for sorted insertion and tree searching.
 *}
VAR
  c : Integer;
BEGIN
  IF PInputField(A)^.PosKey<PInputField(B)^.PosKey
  THEN c:=-1                                  { Entry ID A<B }
  ELSE IF PInputField(A)^.PosKey>PInputField(B)^.PosKey
  THEN c:=1                                   { Entry ID A>B }
  ELSE c:=0;                                  { Entry ID A=B }
  Compare:=c;
END; {FUNC FieldList.Compare}

CONSTRUCTOR FieldList.Init;
{ - Initialize a new Field collection }
BEGIN
  TSortedCollection.Init(10,5);
END; {CONS FieldList.Init}

DESTRUCTOR FieldList.Done;
{ - Clean up; i.e. DeAllocate space used by list }
BEGIN
  TSortedCollection.Done; {Delete tree contents}
END; {DEST FieldList.Done}

PROCEDURE FieldList.Add(VAR NewRef; NewField:PGenEdit);
{ - Add a new Field to the FieldList according to Position Key }
BEGIN
  Insert(New(PInputField,Init(NewRef,NewField))); {Allocate the new field}
END; {PROC FieldList.Add}

PROCEDURE FieldList.Display;
{ - Show Fields}
  PROCEDURE Field_Display(F:PInputField); FAR;
  BEGIN
    F^.Field^.Display;
  END; {PROC Field_Display}
BEGIN
  ForEach(@Field_Display);
END; {PROC FieldList.Display}

PROCEDURE FieldList.Refresh;
{ - Refresh Fields}
  PROCEDURE Field_Refresh(F:PInputField); FAR;
  BEGIN
    F^.Field^.Refresh(0,0);
  END; {PROC Field_Refresh}
BEGIN
  ForEach(@Field_Refresh);
END; {PROC FieldList.Display}

PROCEDURE FieldList.Edit;
{ - Accept Edit from Fields}
VAR
  p : PinputField;
  FieldIndex : integer;
BEGIN
  FieldIndex:=0;
  Lastinput:=Byte(^F); {Field Forward}
  REPEAT
    p:=PinputField(At(FieldIndex));
    WITH p^
    DO BEGIN
      Field^.Lastinput:=Lastinput;
      Field^.Edit;
      Lastinput:=Field^.LastKey;
      CASE LastChar OF
        ^M,^F,^X,^D,^I : IF FieldIndex<Count-1
                      THEN inc(FieldIndex) ELSE FieldIndex:=0;
        ^A,^E,^S    : IF FieldIndex>0
                      THEN Dec(FieldIndex)
                      ELSE FieldIndex:=Count-1;
      END;
    END;
  UNTIL (LastChar in EdExitSet);  {////////////OiOiOi !!!}
END; {PROC FieldList.Edit}

FUNCTION FieldList.Using(VAR Ref):PGenEdit;
{ - Find field by referred variable }
  FUNCTION Match_Ref(F:PInputField):Boolean; FAR;
  BEGIN
    Match_Ref:=f^.Reference=LongInt(Addr(Ref));
  END;
BEGIN
  Using:=PInputField(FirstThat(@Match_Ref))^.Field;
END; {FUNC FieldList.Using}

PROCEDURE FieldList.Fetch(VAR FieldValue);
VAR
  f : PGenEdit;
  ftype : Pointer;
BEGIN
  f:=FieldList.Using(FieldValue);
  IF f<>nil
  THEN BEGIN
 {$IFOPT R+} {$DEFINE Rplus} {$R-} {$ENDIF}
    ftype:=TypeOf(f^);
    IF ftype=TypeOf(StrInput)
    THEN String(FieldValue):=PStrInput(f)^.Value
    ELSE IF ftype=TypeOf(StrPInput)
    THEN PSReNew(PString(FieldValue),PStrPInput(f)^.Value)
    ELSE IF ftype=TypeOf(IntInput)
    THEN Integer(FieldValue):=PIntInput(f)^.Value
    ELSE IF ftype=TypeOf(FloatInput)
    THEN Float(FieldValue):=PFloatInput(f)^.Value
    ELSE IF ftype=TypeOf(ChoiceInput)
    THEN Integer(FieldValue):=PChoiceInput(f)^.Value
    ELSE IF ftype=TypeOf(BooleanInput)
    THEN Boolean(FieldValue):=PBooleanInput(f)^.Value
 {$IFDEF Rplus} {$UNDEF Rplus} {$R+} {$ENDIF}
  END;
END; {FUNC FieldList.Fetch}

FUNCTION FieldList.LastChar:Char;
{ - Return last Edit as character}
BEGIN
  LastChar:=Char(Lo(LastInput));
END; {FUNC FieldList.LastChar}

FUNCTION FieldList.LastKey:Word;
{ - Return last Edit as key}
BEGIN
  LastKey:=LastInput;
END; {FUNC FieldList.LastKey}



{----------------------------------------------------- Entry & Exit Proc's ---
}

VAR
  PrevExitProc : Pointer;

PROCEDURE ObjInputExitProc; FAR;
{ - Unit deinitialization }
BEGIN
  ExitProc:=PrevExitProc;
  Idle.Done;
  Units.Leave(ObjInputMsg,MemAvail);
END;{PROC ObjInputExitProc}


BEGIN {Init Unit OBJInput}
  PrevExitProc:=ExitProc;
  ExitProc:=@ObjInputExitProc;
  Units.Enter(ObjInputMsg,MemAvail,CSeg);
  StartWatch(TimeSinceKeypressed);
  CallHelp:=NoHelp;
  Idle.Init;
END.
