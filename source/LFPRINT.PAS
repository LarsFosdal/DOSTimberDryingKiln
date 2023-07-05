{$I CODEDEFS.PAS} {Include code generation definitions}
{$X+}
UNIT LFprint;

INTERFACE
USES
  Objects,LFString;

CONST
  LPTn : Byte = 1;
{  ÚÄÄÄÄÄÄÄÄ} PrtNotBusy = $80;
{  ³ÚÄÄÄÄÄÄÄ} PrtAck     = $40;
{  ³³ÚÄÄÄÄÄÄ} PrtNoPaper = $20;
{  ³³³ÚÄÄÄÄÄ} PrtSelect  = $10;
{  ³³³³ÚÄÄÄÄ} PrtIOerror = $08;
{  ³³³³³ÚÄÄÄ  Don't care}
{  ³³³³³³ÚÄÄ  Don't care}
{  ³³³³³³³ÚÄ} PrtTimeOut = $01;
{  10010000 = OK }

VAR
  PrintStat : Byte;

PROCEDURE Print(data:String);
PROCEDURE PrintLn(data:String);
FUNCTION  CurrentPrintStat:Byte;

TYPE
  PrintQueue = OBJECT(TObject)
    Queue      : Boolean;
    LastErr    : Integer;
    Port       : Str8;
    PortHandle : Word;
    PortWasRaw : Boolean;
    Spool      : Text;
    CONSTRUCTOR Init(NewPort:Str8; UseSpooler:Boolean);
    DESTRUCTOR Done; VIRTUAL;
    PROCEDURE Print(S:String);
    PROCEDURE PrintLn(S:String);
    PROCEDURE BlockPrint(VAR Buf; Count:Word);
    FUNCTION  Error:Boolean;
    FUNCTION  ErrorCode:Integer;

    PROCEDURE Start(FileName:String);
    PROCEDURE Stop;
    FUNCTION  SpoolerDetected:Boolean;
    PROCEDURE QueueSubmit;
    PROCEDURE QueueCancelAll;
    PROCEDURE QueueCancel(Filename:String);
    PROCEDURE QueueStop;
    PROCEDURE QueueRestart;
  END;

IMPLEMENTATION
USES
  Dos,LFdos;

FUNCTION PrtChar(Ch:Char; LPTx:Word):Byte;
INLINE($5A/      {  POP  DX    ; LPTx in DX}
       $58/      {  POP  AX    ; Ch in AL}
       $B4/$00/  {  MOV  AH,00 ; Func.0}
       $CD/$17/  {  INT  $17   ; Write Ch to LPTx}
       $86/$E0); {  XCHG AL,AH ; Put result in AL}

FUNCTION PrtStat(LPTx:Word):Byte;
INLINE($5A/      {  POP  DX    ; LPTx in DX}
       $B4/$02/  {  MOV  AH,02 ; Func.2}
       $CD/$17/  {  INT  $17   ; Get status of LPTx}
       $86/$E0); {  XCHG AL,AH ; Put result in AL}

PROCEDURE Sleep;
VAR
  i : Word;
BEGIN
  i:=0;
  WHILE i<10000 DO Inc(i);
END; {PROC Sleep}

PROCEDURE Print(data:String);
{ - Send a string to the printer}
VAR
  i : Byte;
BEGIN
  IF Data[0]<>#0 THEN
  BEGIN
   i:=0;
   REPEAT
     inc(i);
     WHILE not Boolean(PrtStat(Pred(LPTn)) and PrtNotBusy) DO Sleep;
     PrintStat:=PrtChar(Data[i],Pred(LPTn));
   UNTIL (i=Byte(Data[0])) or boolean(PrintStat and PrtIOerror);
  END ELSE PrintStat:=PrtStat(Pred(LPTn));
END; {PROC Print}

PROCEDURE PrintLn(data:String);
{ - Send a string to the printer, then advance one line}
BEGIN
  Print(data); Print(^M^J);
END; {PROC PrintLn}

FUNCTION CurrentPrintStat:Byte;
BEGIN
  PrintStat:=PrtStat(Pred(LPTn));
END; {FUNC CurrentPrintStat}


{----------------------------------------------------------------- Printer ---}

FUNCTION SetRawMode(Handle:Word; RawMode:Boolean):Boolean;
{ - Clears "cooked" bit to enable raw 8 bit output}
BEGIN
  ASM
    mov  ax, 4400h
    mov  bx, handle
    int 21h
    mov  ax,dx
    shr  ax,5
    and  ax,1
    mov  @Result,al
    and  dx,00DFh
    mov  al,Rawmode
    and  al,1
    shl  al,5
    or   dl,al
    mov  ax,4401h
    mov  bx,handle
    int 21h
  END;
END; {FUNC SetRawMode}

CONSTRUCTOR PrintQueue.Init(NewPort:Str8; UseSpooler:Boolean);
{}
BEGIN
  TObject.Init;
  Port:=NewPort;
  Queue:=UseSpooler and SpoolerDetected;
  Assign(Spool,Port);
{$IFOPT I+} {$I-} {$DEFINE Iplus} {$ENDIF}
  Rewrite(Spool);
  LastErr:=IOResult;
  IF LastErr=0
  THEN BEGIN
    PortHandle:=TextRec(Spool).Handle;
    PortWasRaw:=SetRawMode(PortHandle,True);
    LastErr:=IOResult;
  END;
{$IFDEF Iplus} {$I+} {$UNDEF Iplus} {$ENDIF}
END; {CONS PrintQueue.Init}

DESTRUCTOR PrintQueue.Done;
{}
VAR
  Err : Integer;
BEGIN
{$IFOPT I+} {$I-} {$DEFINE Iplus} {$ENDIF}
  IF not Queue THEN Write(Spool,^L);
  Err:=IOResult;
  SetRawMode(PortHandle,PortWasRaw);
  Err:=IOResult;
  Close(Spool);
  Err:=IOResult;
{$IFDEF Iplus} {$I+} {$UNDEF Iplus} {$ENDIF}
  TObject.Done;
END; {DEST PrintQueue.Done}

PROCEDURE PrintQueue.Print(S:String);
BEGIN
  {$IFOPT I+} {$I-} {$DEFINE Iplus} {$ENDIF}
  Write(Spool, S);
  LastErr:=IOResult;
  {$IFDEF IPlus} {$I+} {$UNDEF Iplus} {$ENDIF}
END; {PROC PrintQueue.Print}

PROCEDURE PrintQueue.PrintLn(S:String);
BEGIN
  {$IFOPT I+} {$I-} {$DEFINE Iplus} {$ENDIF}
  Writeln(Spool, S);
  LastErr:=IOResult;
  {$IFDEF IPlus} {$I+} {$UNDEF Iplus} {$ENDIF}
END; {PROC PrintQueue.PrintLn}

PROCEDURE PrintQueue.BlockPrint(VAR Buf; Count:Word);
TYPE
  CharArr = ARRAY[1..1] OF Char;
VAR
  ix : Word;
BEGIN
  {$IFOPT R+} {$R-} {$DEFINE Rplus} {$ENDIF}
  FOR ix:=1 TO Count
  DO PrintQueue.Print(CharArr(Buf)[ix]);
  {$IFDEF RPlus} {$R+} {$UNDEF Rplus} {$ENDIF}
END; {PROC PrintQueue.BlockPrint}

FUNCTION PrintQueue.Error:Boolean;
{}
BEGIN
  Error:=LastErr<>0;
END; {FUNC PrintQueue.Error}

FUNCTION PrintQueue.ErrorCode:Integer;
BEGIN
  ErrorCode:=LastErr;
END; {FUNC PrintQueue.ErrorCode}

FUNCTION PrintQueue.SpoolerDetected:Boolean;
{ Check if PRINT.COM is installed }
BEGIN
  ASM
    mov  ax,0100h
    int  2Fh
    mov  bl,1
    cmp  al,0FFh
    je   @@Inst
    mov  bl,0
@@Inst:
    mov  @Result,bl
  END;
END; {FUNC PrintQueue.SpoolerDetected}

PROCEDURE PrintQueue.Start(FileName:String);
{}
BEGIN

END; {PROC PrintQueue.Start}

PROCEDURE PrintQueue.Stop;
{}
BEGIN
END; {PROC PrintQueue.Stop}

PROCEDURE PrintQueue.QueueSubmit;
{}
BEGIN
END; {PROC PrintQueue.QueueSubmit}

PROCEDURE PrintQueue.QueueCancelAll;
{}
BEGIN
END; {PROC PrintQueue.QueueCancelAll}

PROCEDURE PrintQueue.QueueCancel(Filename:String);
{}
BEGIN
END; {PROC PrintQueue.QueueCancel}

PROCEDURE PrintQueue.QueueStop;
{}
BEGIN
END; {PROC PrintQueue.QueueStop}

PROCEDURE PrintQueue.QueueRestart;
{}
BEGIN
END; {PROC PrintQueue.QueueRestart}

BEGIN
END.
