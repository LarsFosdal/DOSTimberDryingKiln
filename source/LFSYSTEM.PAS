{$I CODEDEFS.PAS} {Include code generation definitions}

{$DEFINE ParamProgName}

UNIT LFsystem; {.1 (c) 19890326 Lars Fosdal }

INTERFACE
USES
  Objects,Dos;
CONST
  LFsystemMsg=' LFsystem.1 890326 Lars Fosdal ';
CONST
  On  = True;
  Off = False;
CONST
  BootCold : Boolean = Off;
CONST
  b2e : ARRAY[0..7] OF Byte =  ($01,$02,$04,$08,$10,$20,$40,$80);
CONST
  w2e : ARRAY[0..15] OF Word = ($01,$02,$04,$08,$10,$20,$40,$80,
                $0100,$0200,$0400,$0800,$1000,$2000,$4000,$8000);

TYPE
  InfoIDType  = String[15];  { - External text types }
  CharSet = Set of Char;

CONST
  StreamBufSize : Word = 2048;

{ $ DEFINE LogStream} {Enable to log stream usage}

{$IFDEF LogStream}
CONST
  StrLogTxt : String[8] = '';
VAR
  StreamLog : Text;
{$ENDIF}

TYPE
  PLFStream = ^LFStream;
  LFStream = OBJECT(TBufStream)
    CONSTRUCTOR Init(FileName: FNameStr; Mode, Size: Word);
    FUNCTION    ReadStr:PString;            VIRTUAL;
  {$IFNDEF NoDebug}
    PROCEDURE   WriteStr(P:PString);        VIRTUAL;
    PROCEDURE   Write(VAR Buf; Count:Word); VIRTUAL;
    PROCEDURE   Read(VAR Buf; Count:Word);  VIRTUAL;
    PROCEDURE   Put(P: PObject);            VIRTUAL;
    FUNCTION    Get:PObject;                VIRTUAL;
  {$ENDIF}
  END;

  HelpProcType = PROCEDURE (Tag:InfoIDtype);
  BackgroundProcType = PROCEDURE (VAR Inp:Word);


  PIdleProc = ^IdleProc;
  IdleProc = OBJECT(TObject)
    Enabled : Boolean;
    Execute : BackgroundProcType;
    Key     : LongInt;
    CONSTRUCTOR Init(ExecProc:BackgroundProcType);
  END;

  IdleDispatcher = OBJECT(TSortedCollection)
    CONSTRUCTOR Init;
    FUNCTION Compare(Key1, Key2: Pointer):Integer; VIRTUAL;
    PROCEDURE Add(NewProc:BackgroundProcType);
    PROCEDURE Remove(OldProc:BackgroundProcType);
    PROCEDURE Enable(TheProc:BackgroundProcType);
    PROCEDURE Disable(TheProc:BackgroundProcType);
    PROCEDURE State(TheProc:BackgroundProcType; TrueIfEnable:Boolean);
    PROCEDURE Execute(VAR Inp:Word);
  END;

  PInteger    = ^Integer;
  Float       = {$IFOPT N+} Double; {$ELSE} Real; {$ENDIF}
  PFloat      = ^Float;

PROCEDURE Exchange(VAR A,B; Size:Integer);
FUNCTION  ByteComp(VAR var_A, var_B; SizeOfA,SizeOfB:Word):Integer;


CONST
  VisualHeap : Boolean = False;

TYPE
  PMemEntry = ^MemEntry;
  MemEntry = OBJECT(TObject)
    Name : String[31];
    CS   : Word;
    FreeOnEntry,
    FreeOnExit : LongInt;
    CONSTRUCTOR Enter(ID:String; OnEntry:LongInt; _CS:Word);
    PROCEDURE   Leave(OnExit:LongInt);
    FUNCTION    Report:String;
  END;

  SegOrder = OBJECT(TSortedCollection)
    DESTRUCTOR Done; VIRTUAL;
    FUNCTION Compare(A,B:Pointer):Integer; VIRTUAL;
    FUNCTION Containing(Adr:Pointer):PMemEntry;
  END;

  MemLog = OBJECT(TCollection)
    Segment : SegOrder;
    CONSTRUCTOR Init;
    DESTRUCTOR Done; VIRTUAL;
    PROCEDURE Enter(ID:String; OnEntry:LongInt; _CS:Word);
    PROCEDURE Leave(ID:String; OnExit:LongInt);
    PROCEDURE Report(VAR Out:Text);
  END;

VAR
  Units : MemLog;


PROCEDURE CLI;
InLine($FA); { - Disable Interrupts}

PROCEDURE STI;
InLine($FB); { - Enable Interrupts}

{ - Debugging tools }

PROCEDURE BreakPoint;
INLINE($CC); { - Generate Breakpoint (Single step Int)}

{$IFNDEF NoDebug}
CONST
  SysHaltOnError:Boolean = False;
  PROCEDURE GetMem(var p; size: Word);
  PROCEDURE FreeMem(var p; size: Word);
{$ENDIF}
  FUNCTION RTError(n:Integer):String;

PROCEDURE PSNew(VAR PS:PString; T:String);
PROCEDURE PSDispose(VAR PS:PString);
PROCEDURE PSReNew(VAR PS:PString; T:String);

PROCEDURE TrapAbstract;
PROCEDURE StdSysError(Msg:String; ECode1,ECode2:LongInt);


{ - Ctrl-Alt-Del handling }
PROCEDURE InstallCADIntercept;
PROCEDURE RemoveCADIntercept;
FUNCTION  DetectCAD:Boolean;
FUNCTION  DetectPause:Boolean;
PROCEDURE CancelCAD;
PROCEDURE CancelPause;
PROCEDURE WarmBoot;
PROCEDURE ColdBoot;

TYPE
  ErrorMsgProc = PROCEDURE(Msg:String; ECode1,ECode2:LongInt);

VAR
  SysError     : ErrorMsgProc;
VAR
  ExecuteCAD   : PROCEDURE; {Default = WarmBoot}
  CADHandler   : BackgroundProcType;
VAR
  Path       : PathStr;
  ExeName,
  SystemName : NameStr;

IMPLEMENTATION {#############################################################}
               {#############################################################}


{---------------------------------------------------------------- LFStream ---
  Description
    Exactly like TBufStream, except for nil string handling:
    If a PString in the stream is nil, it will be allocated
    with space only for the string length prefix.
    TBufStream ordinaryily returns nil.
}

{$IFNDEF NoDebug}
PROCEDURE DebugStream(S:TStream); FAR;
VAR
  i,df : Integer;
BEGIN
  FOR i:=1 TO 50
  DO BEGIN
    df:=i*10;
    IF Odd(i) THEN df:=-df;
  END;
  SysError('Stream',S.ErrorInfo,S.Status);
END; {PROC DebugStream}
{$ENDIF}

PROCEDURE StreamProblem(S:PLFStream; st,ei:Integer);
VAR
  m,e : String[60];
BEGIN
  CASE st OF
    stOk        : m:='No error';
    stError     : m:='Access error';
    stInitError : m:='Cannot initialize stream';
    stReadError : m:='Read beyond end of stream';
    stWriteError: m:='Cannot expand stream';
    stGetError  : m:='Get unreg''d object type';
    stPutError  : m:='Put unreg''d object type';
  END;
  Str(ei,e);
  m:='Stream: '+m;
  SysError(m,st,ei);
  BreakPoint;
END; {PROC StreamProblem}

CONSTRUCTOR LFStream.Init(FileName: FNameStr; Mode, Size: Word);
{ - No new initializing necesarry}
BEGIN
  TBufStream.Init(FileName,Mode,Size);
{$IFNDEF NoDebug}
  IF Status<>StOK
  THEN StreamProblem(@Self, Status,ErrorInfo);
{$ENDIF}
END; {CONS LFStream.Init}

FUNCTION LFStream.ReadStr:PString;
{ - If a PString in the stream is nil, it will be allocated
    with space only for the string length prefix.}
VAR
  n : Byte;
  p : PString;
BEGIN
{$IFDEF LogStream}
  Writeln(StreamLog,StrLogTxt,'ReadStr :', GetPos);
{$ENDIF}
  TBufStream.Read(n,SizeOf(n));
  GetMem(p,n+1);
  p^[0]:=Chr(n);
  IF n>0
  THEN TBufStream.Read(p^[1],n);
  ReadStr:=p;
{$IFNDEF NoDebug}
  IF Status<>StOK
  THEN StreamProblem(@Self, Status,ErrorInfo);
{$ENDIF}
END; {FUNC LFStream.ReadStr}

{$IFNDEF NoDebug}
PROCEDURE LFStream.WriteStr(P:PString);
BEGIN
{$IFDEF LogStream}
  Writeln(StreamLog,StrLogTxt,'WriteStr:', GetPos);
{$ENDIF}
  TBufStream.WriteStr(P);
  IF Status<>StOK
  THEN StreamProblem(@Self, Status,ErrorInfo);
END; {PROC LFStream.WriteStr}

PROCEDURE LFStream.Write(VAR Buf; Count:Word);
BEGIN
{$IFDEF LogStream}
  Writeln(StreamLog,StrLogTxt,'Write   :', GetPos);
{$ENDIF}
  TBufStream.Write(Buf,Count);
  IF Status<>StOK
  THEN StreamProblem(@Self, Status,ErrorInfo);
END; {PROC LFStream.Write}

PROCEDURE LFStream.Read(VAR Buf; Count:Word);
BEGIN
{$IFDEF LogStream}
  Writeln(StreamLog,StrLogTxt,'Read    :', GetPos);
{$ENDIF}
  TBufStream.Read(Buf,Count);
  IF Status<>StOK
  THEN StreamProblem(@Self, Status,ErrorInfo);
END; {PROC LFStream.Read}

PROCEDURE LFStream.Put(P: PObject);
BEGIN
{$IFDEF LogStream}
  Writeln(StreamLog,StrLogTxt,'Put     :', GetPos);
  IF GetPos=73
  THEN BreakPoint;
{$ENDIF}
  TBufStream.Put(P);
  IF Status<>StOK
  THEN StreamProblem(@Self, Status,ErrorInfo);
END; {PROC LFStream.}

FUNCTION LFStream.Get:PObject;
BEGIN
{$IFDEF LogStream}
  Writeln(StreamLog,StrLogTxt,'Get     :', GetPos);
{$ENDIF}
  Get:=TBufStream.Get;
  IF Status<>StOK
  THEN StreamProblem(@Self, Status,ErrorInfo);
END; {FUNC LFStream.Get}

{$ENDIF}


{---------------------------------------------------------- Debugging aids ---
  Description
    GetMem / FreeMem - for trapping memory allocation errors
    If NoDebug is defined, these will be removed.
}

CONSTRUCTOR MemEntry.Enter(ID:String; OnEntry:LongInt; _CS:Word);
BEGIN
  TObject.Init;
  Name:=ID;
  CS:=_CS;
  FreeOnEntry:=OnEntry;
  FreeOnExit:=FreeOnEntry;
END; {CONS MemEntry.Enter}

PROCEDURE MemEntry.Leave(OnExit:LongInt);
BEGIN
  FreeOnExit:=OnExit;
END; {PROC MemEntry.Leave}

FUNCTION hxw(w:Word):String;
CONST
  h : String[16] = '0123456789ABCDEF';
BEGIN
  hxw:=h[((w shr 12) and $000F)+1]+
       h[((w shr 8) and $000F)+1]+
       h[((w shr 4) and $000F)+1]+
       h[(w and $000F)+1];
END;

FUNCTION MemEntry.Report:String;
VAR
  s : String;
  n : String[8];
BEGIN
  Str(FreeOnEntry:6,s);
  Str(FreeOnExit:7,n);
  s:=s+n;
  Str(FreeOnEntry-FreeOnExit:7,n);
  Report:=s+n+'  '+hxw(CS)+'h :'+Name;
END; {FUNC MemEntry.Report}

DESTRUCTOR SegOrder.Done;
BEGIN
  DeleteAll;
  TSortedCollection.Done;
END;

FUNCTION SegOrder.Compare(A, B: Pointer):Integer;
VAR
  P1 : PMemEntry Absolute A;
  P2 : PMemEntry Absolute B;
BEGIN
  IF P1^.CS>P2^.CS THEN Compare:=1
  ELSE IF P1^.CS<P2^.CS THEN Compare:=-1
  ELSE Compare:=0;
END;{FUNC SegOrder.Compare}

FUNCTION SegOrder.Containing(Adr:Pointer):PMemEntry;
VAR
  ACS  : Word;
  CSIP : LongInt absolute Adr;
  FUNCTION IsAbove(P:PMemEntry):Boolean; FAR;
  BEGIN
    IsAbove:=ACS>=P^.CS;
  END;
BEGIN
  ACS:=Seg(Adr^);
  Containing:=FirstThat(@IsAbove);
END;

CONSTRUCTOR MemLog.Init;
BEGIN
  TCollection.Init(50,5);
  Segment.Init(50,5);
END;

DESTRUCTOR MemLog.Done;
BEGIN
  Segment.Done;
  TCollection.Done;
END;

PROCEDURE MemLog.Enter(ID:String; OnEntry:LongInt; _CS:Word);
BEGIN
  Insert(New(PMemEntry,Enter(ID,OnEntry,_CS)));
END; {PROC MemLog.Enter}


CONST
  RecMemUsage = ((SizeOf(MemEntry) DIV 8) + Ord(SizeOf(MemEntry) MOD 8>0))*8;

PROCEDURE MemLog.Leave(ID:String; OnExit:LongInt);
  FUNCTION Match_ID(RAM:PMemEntry):Boolean; FAR;
  BEGIN
    Match_ID:=ID=RAM^.Name;
  END;
VAR
  RAM : PMemEntry;
  n   : Integer;
BEGIN
  RAM:=FirstThat(@Match_ID);
  n:=IndexOf(RAM);
  IF n >= 0
  THEN RAM^.Leave(OnExit+((Count-n)*RecMemUsage));
END; {PROC MemLog.Leave}

PROCEDURE MemLog.Report(VAR Out:Text);
VAR
  RAM : PMemEntry;
  n   : Integer;
BEGIN
{  Writeln(Out,RecMemUsage); {////////DEBUG}
  Writeln(Out,'Entry  Exit    Diff.   CS     Unit (',Count,' logged units)');
  FOR n:=Count-1 DownTo 0
  DO BEGIN
    RAM:=At(n);
    Writeln(Out,RAM^.Report);
  END;
END;


{$IFNDEF NoDebug}

  PROCEDURE GetMem(var p; size: Word);
  VAR
    pp : Pointer Absolute p;
    m  : LongInt;
  BEGIN
    m:=MemAvail;
    IF Size>MemAvail
    THEN BreakPoint;
    System.GetMem(pp,size);
  END;

  PROCEDURE FreeMem(var p; size: Word);
  VAR
    pp : Pointer Absolute p;
    m  : LongInt;
  BEGIN
    System.FreeMem(pp,size);
    m:=MemAvail;
  END;

{$ENDIF}

PROCEDURE PSNew(VAR PS:PString; T:String);
{ - Allocate and copy message }
BEGIN
  GetMem(PS,Length(T)+1); {Allocate space for message}
  PS^:=T;                 {Copy the message text to allocated space}
END;{PROC PSNew}

PROCEDURE PSDispose(VAR PS:PString);
{ - DeAllocate Message }
BEGIN
  IF PS<>nil
  THEN BEGIN
    FreeMem(PS,Length(PS^)+1);
    PS:=nil;
  END;
END; {PROC PSDispose}

PROCEDURE PSReNew(VAR PS:PString; T:String);
{ - Change Message }
BEGIN
  PSDispose(PS);
  PSNew(PS,T);
END;

{--------------------------------------------------------- Misc. routines ---}

PROCEDURE Exchange(VAR A,B; Size:Integer);
{ - Exchange A and B
    ie. A:=1 and B:=2, Exchange(A,B,SizeOf(A)) gives A=2 and B=1 }
BEGIN
  INLINE(
  $1E/            {  PUSH DS           }
  $C5/$B6/A/      {  LDS SI,A          }
  $C5/$BE/B/      {  LES DI,B          }
  $8B/$8E/Size/   {  MOV CX,Size       }
  $FC/            {  CLD               }
  $26/$8A/$05/    {L:MOV AL,ES:[DI]    }
  $86/$04/        {  EXCH [SI],AL      }
  $46/            {  INC SI            }
  $AA/            {  STOSB             }
  $E2/$F7/        {  LOOP L            }
  $1F);           {  POP DS            }
END; {PROC Exchange}

FUNCTION ByteComp(VAR var_A, var_B; SizeOfA,SizeOfB:Word):Integer;
{ - Compare byte by byte - Returns: A=B:0  A<B:-1  A>B:+1 }
BEGIN
  ASM
       push ds               {save old ds}
       xor  ax,ax            {ax:=0}
       dec  ax               {ax:=-1}
       mov  bx,1             {bx:=1}
       mov  cx,SizeOfA       {cx:=byte count}
       cmp  cx,SizeOfB       {if A is longer than B, A may be greater}
       jg   @@Cmp
       pushf
       mov  cx,SizeOfB       {else they might be equal}
       dec  bx               {bx:=0}
       popf
       je   @@Cmp            {else A may be less than B}
       dec  bx               {bx:=-1}
@@Cmp: cld                   {set up for cmpsb (auto-incr. si/di) }
       lds  si,var_A
       les  di,var_B
@@Nxt: cmpsb
       jne  @@NE             {leave loop if byte difference is found}
       dec  cx               {is there more bytes ?}
       jnz  @@Nxt
       mov  ax,bx            {add check for difference in size}
       jmp  @@Exit
@@NE:  jl   @@Exit           {ax=-1, so exit if last cmps was a<b}
       inc  ax               {else it must be a>b, so add 2 to -1 and}
       inc  ax               {make ax=+1}
@@Exit:pop  ds               {restore old DS}
       mov  @result,ax       {return result (ax)}
  END;
END; {FUNC ByteComp}


{--------------------------------------------------------------- IdleProc ---}

CONSTRUCTOR IdleProc.Init(ExecProc:BackgroundProcType);
{ - Set Idle-proc. vector and disable it}
VAR
  E : BackgroundProcType;
  K : Longint Absolute E;
BEGIN
  TObject.Init;
  Enabled:=False;
  Execute:=ExecProc;
  E:=Execute;
  Key:=K;
END;{CONS IdleProc.Init}

{--------------------------------------------------------- IdleDispatcher ---}


CONSTRUCTOR IdleDispatcher.Init;
{ - Create a collection, start with 6 procs and increment by 2 at the time}
BEGIN
  TSortedCollection.Init(6,2);
END;{CONS IdleDispatcher.Init}

FUNCTION IdleDispatcher.Compare(Key1, Key2: Pointer):Integer;
VAR
  P1 : PIdleProc Absolute Key1;
  P2 : PIdleProc Absolute Key2;
BEGIN
  IF P1^.Key>P2^.Key THEN Compare:=1
  ELSE IF P1^.Key<P2^.Key THEN Compare:=-1
  ELSE Compare:=0;
END;{FUNC IdleDispatcher.Compare}

PROCEDURE IdleDispatcher.Add(NewProc:BackgroundProcType);
BEGIN
  Insert(New(PIdleProc,Init(NewProc)));
END;{PROC IdleDispatcher.Add}

PROCEDURE IdleDispatcher.Remove(OldProc:BackgroundProcType);
{ - Remove proc from idle list}
VAR
  i : Integer;
  k : PIdleProc;
BEGIN
  New(k,Init(OldProc));
  IF Search(k,i)
  THEN AtFree(i);
  Dispose(k,Done);
END;{PROC IdleDispatcher.Remove}

PROCEDURE IdleDispatcher.Enable(TheProc:BackgroundProcType);
{ - Enable idle proc}
BEGIN
  State(TheProc,True);
END;{PROC IdleDispatcher.Enable}

PROCEDURE IdleDispatcher.Disable(TheProc:BackgroundProcType);
{ - Disable idle proc}
BEGIN
  State(TheProc,False);
END;{PROC IdleDispatcher.Disable}

PROCEDURE IdleDispatcher.State(TheProc:BackgroundProcType; TrueIfEnable:Boolean);
{ - Set proc enabled state according to <TrueIfEnabled>}
VAR
  i : Integer;
  k : PIdleProc;
BEGIN
  New(k,Init(TheProc));
  IF Search(k,i)
  THEN PIdleProc(At(i))^.Enabled:=TrueIfEnable;
  Dispose(k,Done);
END;{PROC IdleDispatcher.State}

PROCEDURE IdleDispatcher.Execute(VAR Inp:Word);
  PROCEDURE ActiveProc_Execute(Proc:PIdleProc); FAR;
  BEGIN
    IF Proc^.Enabled
    THEN Proc^.Execute(Inp);
  END; {LOCAL PROC ActiveProc_Execute}
BEGIN
  ForEach(@ActiveProc_Execute);
END;{PROC IdleDispatcher.Execute}

{-------------------------------------------------------- CAD Ctrl-Alt-Del ---
  Description
    Ctrl-Alt-Del handling - Allows for trapping and disabling of
    this sequence.
}

VAR
  OldInt09     : Pointer;
  KeyStat      : ^Byte;
  CADPressed   : Boolean;
  PausePressed : Boolean;
  DOSCBreak    : Boolean;

PROCEDURE GoOldInt(OldIntVector: pointer);
{ - Allows Interrupt chaining }
INLINE (
   $5B/   {POP BX - Get Segment}
   $58/   {POP AX - Get Offset}
   $89/   {MOV SP,BP}
   $EC/
   $5D/   {POP BP}
   $07/   {POP ES}
   $1F/   {POP DS}
   $5F/   {POP DI}
   $5E/   {POP SI}
   $5A/   {POP DX}
   $59/   {POP CX}
   $87/   {XCHG SP,BP}
   $EC/
   $87/   {XCHG [BP],BX}
   $5E/
   $00/
   $87/   {XCHG [BP+2],AX}
   $46/
   $02/
   $87/   {XCHG SP,BP}
   $EC/
   $CB);  {RETF}

FUNCTION DetectCAD:boolean;
{ - True if C-A-D pressed since last call to CancelCAD}
BEGIN
  DetectCAD := CADPressed;
END; {FUNC DetectCAD}

PROCEDURE CancelCAD;
{- Clear C-A-D detected flag}
BEGIN
  CadPressed:=False;
END; {PROC CancelCAD}

FUNCTION DetectPause:boolean;
{ - True if Pause pressed since last call to CancelPause}
BEGIN
  DetectPause := PausePressed;
END; {FUNC DetectPause}

PROCEDURE CancelPause;
{- Clear Pause detected flag}
BEGIN
  PausePressed:=False;
END; {PROC CancelPause}

PROCEDURE WarmBoot; ASSEMBLER;
{ - Executes an immediate warm boot (al  Ctrl-Alt-Del)}
ASM
  xor  ax,ax
  mov  es,ax
  mov  es:word ptr [0472h],01234h
  mov  ax,0FFFFh
  push ax
  push es
  iret
END; {PROC WarmBoot}

PROCEDURE ColdBoot; ASSEMBLER;
{ - Executes an immediate cold boot (al  Reset w/POST (Pwr On Self Test)) }
ASM
  xor  ax,ax
  mov  es,ax
  mov  es:word ptr [0472h],0
  mov  ax,0FFFFh
  push ax
  push es
  iret
END; {PROC ColdBoot}


PROCEDURE CADIntercept(AX,BX,CX,DX,SI,DI,SD,ES,BP: Word);
{ - Interrupt hander for INT 09.  Intercepts CAD sequences }
INTERRUPT;
VAR
  I,J: integer;
  Chain : Boolean;
CONST
  ci : Word = 0;
  KsDelCode = $53;
BEGIN
  Chain:=True;
  I := Port[$60];   {Get Scan Code}

  IF (i=225) and (ci=0)
  THEN BEGIN
    PausePressed:=True;
    ci:=5;  {I=225 -> Pause pressed: Ignore this and the 4 next Int's}
  END;
  IF ci>0 THEN Dec(ci);
  Chain:=ci=0;

  IF ((I and $7F) = KsDelCode)   {DEL key?}
  and ((KeyStat^ and $0C) = $0C) {CTL + ALT ?}
  THEN BEGIN
    CADPressed:=True;
    Chain:=False;
  END;
  IF Chain                 { If we doesn't intercept this }
  THEN GoOldInt(OldInt09)  { - then jump to original intr.handler}
  ELSE BEGIN               { - else, clean up after intr.}
    J := Port[$61];	      {Save Kbd Status}
    Port[$61]:=J or $80;      {Reset Kbd Int}
    Port[$61]:=J and $7F;
    Port[$20]:=$20;           {send EOI to PIC}
  END;
END; {PROC INTR CADIntercept}

PROCEDURE InstallCADIntercept;
{ - Install INT 09 Intercept}
BEGIN
  SetIntVec($09, @CADIntercept);
  SetCBreak(FALSE);
  {CheckBreak := FALSE;}
  KeyStat := Ptr($40,$17);
  CancelCAD;
END; {PROC InstallCADIntercept}

PROCEDURE RemoveCADintercept;
{ - Remove INT 09 Intercept}
BEGIN
  SetIntVec($09,OldInt09);
  SetCBreak(DOSCBreak);
  {CheckBreak := DOSCBreak;}
  CancelCAD;
END; {PROC RemoveCADIntercept}

{-------------------------------------------------- ExitProc / Unit Init. ---}

VAR
  PrevExitProc : Pointer;
  Memory       : LongInt;


PROCEDURE TrapAbstract;
BEGIN
  BreakPoint;
  Abstract;
END;

FUNCTION RTError(n:Integer):String;
VAR
  s : String;
BEGIN
  CASE n OF
     1 : s:='Invalid function number';
     2 : s:='File not found';
     3 : s:='Path not found';
     4 : s:='Too many open files';
     5 : s:='File access denied';
     6 : s:='Invalid file handle';
    12 : s:='Invalid file access code';
    15 : s:='Invalid drive number';
    16 : s:='Cannot remove current directory';
    17 : s:='Cannot rename across drives';
   100 : s:='Disk read error';
   101 : s:='Disk write error';
   102 : s:='File not assigned';
   103 : s:='File not open';
   104 : s:='File not open for input';
   105 : s:='File not open for output';
   106 : s:='Invalid numeric format';
   150 : s:='Disk is write-protected';
   151 : s:='Bad drive request struct length';
   152 : s:='Drive not ready';
   154 : s:='CRC error in data';
   156 : s:='Disk seek error';
   157 : s:='Unknown media type';
   158 : s:='Sector Not Found';
   159 : s:='Printer out of paper';
   160 : s:='Device write fault';
   161 : s:='Device read fault';
   162 : s:='Hardware failure';
   200 : s:='Division by zero';
   201 : s:='Range check error';
   202 : s:='Stack overflow error';
   203 : s:='Heap overflow error';
   204 : s:='Invalid pointer operation';
   205 : s:='Floating point overflow';
   206 : s:='Floating point underflow';
   207 : s:='Invalid floating point operation';
   208 : s:='Overlay manager not installed';
   209 : s:='Overlay file read error';
   210 : s:='Object not initialized';
   211 : s:='Call to abstract method';
   212 : s:='Stream registration error';
   213 : s:='Collection index out of range';
   214 : s:='Collection overflow error';
   215 : s:='Arithmetic overflow';
   216 : s:='General protection fault';
   ELSE s:='Unknown error';
  END;
  RTError:=s;
END; {FUNC RTError}

PROCEDURE StdSysError(Msg:String; ECode1,ECode2:LongInt);
BEGIN
  Writeln('RT Fault, ',Msg,' (',ECode1:5,ECode2:5,')');
{$IFNDEF NoDebug}
  IF SysHaltOnError
  THEN BreakPoint;
{$ENDIF}
END;

PROCEDURE ExitHandler; FAR;
VAR
  Out : Text;
BEGIN
  ExitProc:=PrevExitProc;
{$IFDEF LogStream}
  Close(StreamLog);
{$ENDIF}
  RemoveCADIntercept;
  Units.Leave(LFsystemMsg,MemAvail);
  IF VisualHeap
  THEN BEGIN
    Assign(Out,Path+SystemName+'.RAM');
    Rewrite(Out);
    Units.Report(Out);
    Units.Done;
    Writeln(Out,Memory:6,MemAvail:7,(Memory-MemAvail):7,' : Total');
    Close(Out);
  END
  ELSE Units.Done;
END;

VAR
  Dummy : String[2];
  i : Integer;
BEGIN
  GetIntVec($09, OldInt09);
  GetCBreak(DOSCBreak);
  CancelCAD;
  CancelPause;
  ExecuteCAD:=WarmBoot;
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  Path:=ParamStr(0);
  FSplit(ParamStr(0),Path,ExeName,Dummy);
{$IFDEF ParamProgName}
  IF ParamCount>0
  THEN FSplit(ParamStr(1), Dummy, SystemName, Dummy)
  ELSE BEGIN
    Writeln('System name is missing ?');
    Writeln('Expects: ',ParamStr(0),' SystName');
    Writeln(' - Starting in monitor mode');
    SystemName:=ExeName;
  END;
  FOR i:=1 TO Length(SystemName)
  DO SystemName[i]:=Upcase(SystemName[i]);
{$ELSE}
  SystemName:=ExeName;
{$ENDIF}

{$IFDEF LogStream}
  Assign(StreamLog, Path+SystemName+'.STL');
  IF FSearch(SystemName+'.STL', Path)=''
  THEN Rewrite(StreamLog)
  ELSE Append(StreamLog);
  Writeln(StreamLog,'-------------------------------------------');
{$ENDIF}
  SysError:=StdSysError;
  Memory:=MemAvail;
  Units.Init;
  Units.Enter(LFSystemMsg,MemAvail,CSeg);
 {$IFNDEF NoDebug}
{  StreamError:=@DebugStream;}
 {$ENDIF}
END.
