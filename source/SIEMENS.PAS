{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT Siemens;

{ Unit
}

{ $DEFINE debug} {Define to test protocol}

{$IFDEF debug}
  {$DEFINE LogToFile}   {Define if you want to log to file}
  { DEFINE LogToScreen} {Define if you want to log to screen}
{$ENDIF}

INTERFACE
USES
  Crt,LFcomm;

CONST
{$IFDEF debug}
  ErrorType : Integer = 0;
  LogFileName = 'SIEMENS.LOG';
{$ENDIF}
  FatalError = 3;
  NAKerror = 2;
  ChkSumError = 1;
  NoError = 0;
  TimeOut = -1;

PROCEDURE ConnectSiemens(ComPort:ComPorts; Speed:ComSpeed);
PROCEDURE { 0 } GetStatus(VAR Master,Slaves:Word);
FUNCTION  { 1 } ReadCoil(Address:Word):Boolean;
PROCEDURE { 2 } SetCoil(Address:Word; State:Boolean);
FUNCTION  { 3 } ReadRegister(Address:Word):Integer;
PROCEDURE { 4 } SetRegister(Address:Word; Value:Integer);
FUNCTION  SiemensError:Integer;
FUNCTION  SiemensErrorMsg(i:Integer):String;
PROCEDURE DisconnectSiemens;
{$IFDEF debug}
  FUNCTION Hex(Byt:Byte):String;
{$ENDIF}

IMPLEMENTATION

USES LFString, DOS;
{$IFDEF Debug}

VAR
  LogFile : Text;
{$ENDIF}

CONST
  SiemensErr : Integer = NoError;
  cp : Byte = 1;
  MsgBytes = 6;
  Filler   = $8000;

TYPE
  MsgRec = RECORD
             CASE Boolean OF
                False : (
                  Func    : Byte;
                  Address : Word;
                  Value   : Word;
                  ChkSum  : Byte);
                True : (Byt: ARRAY[1..6] OF Byte);
           END;

{---Primitives---------------------------------------------------------------}

FUNCTION LRC(Message:MsgRec):Byte;
VAR
  i   : Integer;
  sum : Byte;
BEGIN
  Sum:=0;
  FOR i:=1 TO 5 DO Sum:=(Sum+Message.Byt[i]) and $FF;
  LRC:=Sum;
END;{LRC}

FUNCTION LRCok(Message:MsgRec):Boolean;
VAR
  chksum : Byte;
BEGIN
  chksum:=LRC(Message);
  LRCok:=(ChkSum=Message.ChkSum);
END;{LRCok}

FUNCTION MsgToStr(Message:MsgRec):String;
VAR
  i : Integer;
  MsgStr : String[MsgBytes];
BEGIN
  MsgStr[0]:=Char(MsgBytes);
  Move(Message,MsgStr[1],MsgBytes);
  MsgToStr:=MsgStr;
END;{MsgToStr}

PROCEDURE StrToMsg(St:String;VAR Message:MsgRec);
VAR
  i : Integer;
BEGIN
  Move(St[1],Message,MsgBytes);
END;{StrToMsg}

{$IFDEF Debug}
  PROCEDURE MakeError(VAR Message:MsgRec);
  BEGIN
    Randomize;
    CASE ErrorType OF {Coding errors only}
      0 : {No Errors};
      3 : BEGIN {Unused variables in func 0 not initialized to $8000}
            Message.value:=Random($FFFE);
            Message.Address:=Random($FFFE);
          END;
     14 : BEGIN {Checksum Error}
            Message.Chksum:=not Message.ChkSum;
          END;
    ELSE {Other errors applied when calling public routines};
    END;
  END;{MakeError}

  FUNCTION Hex(Byt:Byte):String;
  CONST
    hx : String[16]='0123456789ABCDEF';
  BEGIN
    Hex:=hx[Succ(Byt DIV 16)]+hx[Succ(Byt MOD 16)];
  END;{Hex}

  PROCEDURE ShowMsgs(What:String;Msg:String);
  CONST
    LastX : Word = 1;
    LastY : Word = 1;
  VAR
    owmax,owmin,ox,oy,i : Word;
    PROCEDURE Put(s:String);
    BEGIN
      {$IFDEF LogToFile}
        Write(LogFile, s);
      {$ENDIF}
      {$IFDEF LogToScreen}
        Write(s);
      {$ENDIF}
    END;
  BEGIN
 {$IFDEF LogToScreen}
    owmax:=WindMax;
    owmin:=WindMin;
    ox:=WhereX;
    oy:=WhereY;
    Window(38,3,79,24);
    GotoXY(LastX,LastY);
{$ENDIF}
    Put(PadLeading(What,' ',5));
    IF Msg<>''
    THEN BEGIN
      FOR i:=1 TO Byte(Msg[0])
      DO BEGIN
        Put(Hex(Byte(Msg[i])));
        IF i in [1,3,5] THEN Put(' ');
      END;
    END;
    IF (What='PLS: ') and (Msg[0]=#0) THEN Put('<No Msg>');
    Put(^M^J);
{$IFDEF LogToScreen}
    LastX:=WhereX; LastY:=WhereY;
    WindMin:=owmin;
    WindMax:=owmax;
    GotoXY(ox,oy);
{$ENDIF}
  END;

{$ENDIF}

PROCEDURE xcv(Func:Byte;VAR Address,Value:Word);
CONST
  MaxTimer = 5000; {ms = 5 sek.}
  RetryCount = 4;
VAR
  Trans,Timer,Bytes : Word;
  Message : MsgRec;
  MsgStr : String[MsgBytes];
{$IFDEF Debug}
  Hour, Min, Sec, Hun : Word;
  tstr    : String[20];
{$ENDIF}
BEGIN
  Trans:=0;
  {$IFDEF debug}
    ShowMsgs('=== Start of function '+IntStr(Func,0)+' poll ===','');
  {$ENDIF}
  REPEAT
    Inc(Trans);
  {$IFDEF debug}
    GetTime(hour,min,sec,hun);
    tStr:=' at '+SwapAll(' ','0',IntStr(Hour,2)+'.'+IntStr(Min,2)+'.'+IntStr(Sec,2)+','+IntStr(Hun,2));
    ShowMsgs('--- Attempt #'+IntStr(Trans,0)+tStr,'');
  {$ENDIF}
    SiemensErr:=NoError;
    Message.Func:=Func;
    Message.Address:=Swap(Address);
    Message.Value:=Swap(Value);
    Message.ChkSum:=LRC(Message);

{$IFDEF MakeError}
    MakeError(Message);
{$ENDIF}

    MsgStr:=MsgToStr(Message);

{$IFDEF debug}
     ShowMsgs('PC: ',MsgStr);
{$ENDIF}

    ResetRB(cp);
    cWrite(cp,MsgStr);
    Bytes:=0; Timer:=0; MsgStr:='';
    REPEAT
      IF Received(cp)
      THEN BEGIN
        Inc(Bytes);
        MsgStr:=MsgStr+cRead(cp);
      END
      ELSE BEGIN
        Inc(Timer);
        Delay(1);
      END;
    UNTIL (Bytes=MsgBytes) or (Timer>MaxTimer);

    IF Timer>MaxTimer THEN SiemensErr:=TimeOut
    ELSE BEGIN
      StrToMsg(MsgStr,Message);
      IF not LRCok(Message) THEN SiemensErr:=ChkSumError
       ELSE IF (Message.Func=$15){NAK} THEN SiemensErr:=NAKerror;
    END;

{$IFDEF debug}
    ShowMsgs('PLS: ',MsgStr);
    ShowMsgs('ERR: '+SiemensErrorMsg(SiemensErr),'');
{$ENDIF}

    Delay(200); {3.3 No retransmission before 200ms since last received byte}
  UNTIL (SiemensErr=NoError) or (Trans>RetryCount);
  IF not (Trans>RetryCount+1) and (SiemensErr=NoError)
  THEN BEGIN
    Address:=Swap(Message.Address);
    Value:=Swap(Message.Value);
  END ELSE SiemensErr:=FatalError;
  {$IFDEF debug}
    ShowMsgs('ERR: '+SiemensErrorMsg(SiemensErr),'');
    ShowMsgs('=== End of function '+IntStr(Func,0)+' poll ======','');
    ShowMsgs('','');
  {$ENDIF}
END;{xcv}

{---Globals------------------------------------------------------------------}

PROCEDURE ConnectSiemens(ComPort:Comports; Speed:ComSpeed);
BEGIN
  cp:=ComPort;
  cOpen(cp,32,Speed,8,pEven,1);
END;{ConnectSiemens}

PROCEDURE { 0 } GetStatus(VAR Master,Slaves:Word);
BEGIN
  Master:=Filler;
  Slaves:=Filler;
  xcv(0, Master, Slaves);
END;{GetStatus}

FUNCTION  { 1 } ReadCoil(Address:Word):Boolean;
VAR
  value : Word;
BEGIN
  Value:=Filler;
  xcv(1 ,Address, Value);
  ReadCoil:=(Value=1)
END;{ReadCoil}

PROCEDURE { 2 } SetCoil(Address:Word; State:Boolean);
CONST
  Value : ARRAY[Boolean] OF Word = (0,1);
BEGIN
  xcv(2, Address, Value[State]);
END;{SetCoil}

FUNCTION  { 3 } ReadRegister(Address:Word):Integer;
VAR
  value : Word;
BEGIN
  Value:=Filler;
  xcv(3 ,Address, Value);
  ReadRegister:=Integer(Value);
END;{ReadRegister}

PROCEDURE { 4 } SetRegister(Address:Word; Value:Integer);
BEGIN
  xcv(4, Address, Word(Value));
END;{SetRegister}

FUNCTION SiemensError:Integer;
BEGIN
  SiemensError:=SiemensErr;
  SiemensErr:=NoError;
END;{SiemensError}

FUNCTION SiemensErrorMsg(i:Integer):String;
VAR
  s : String;
BEGIN
  s:=' ('+IntStr(i,2)+')';
  CASE i OF
    FatalError  : s:='Fatal Error'+s;
    NAKerror    : s:='NAK error'+s;
    ChkSumError : s:='Wrong Checksum'+s;
    NoError     : s:='No Errors'+s;
    TimeOut     : s:='Timed Out'+s;
           ELSE   s:='Unknown'+s;
  END;
  SiemensErrorMsg:=s;
END; {FUNC SiemensErrorMsg}


PROCEDURE DisconnectSiemens;
BEGIN
  cClose(cp);
END;{DisconnectSiemens}


{$IFDEF LogToFile}
  VAR
    PrevExitProc : Pointer;

  PROCEDURE NewExitProc; FAR;
  BEGIN
    ExitProc:=PrevExitProc;
    Close(LogFile);
  END;

  BEGIN { Init Unit Siemens }
    PrevExitProc:=ExitProc;
    ExitProc:=@NewExitProc;
    Assign(LogFile, LogFileName);
    Rewrite(LogFile);
{$ENDIF}

END.
