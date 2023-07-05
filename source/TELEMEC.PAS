{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT Telemec{anique};

{ Unit
}

{ DEFINE debug} {Define to produce errors in protocol (Set ErrorType)}

INTERFACE
USES
  Crt,LFcomm;

CONST
{$IFDEF debug}
  ErrorType : Integer = 0;
{$ENDIF}
  FatalError = 3;
  NAKerror = 2;
  ChkSumError = 1;
  NoError = 0;
  TimeOut = -1;
  TeleMecErrorMsg : ARRAY[-1..3] OF String[30] =
   ('Timed Out','No Errors','Wrong Checksum','NAK error','Fatal Error');

PROCEDURE ConnectTeleMec(ComPort:ComPorts; Speed:ComSpeed);
PROCEDURE { 0 } GetStatus(VAR Master,Slaves:Word);
FUNCTION  { 1 } ReadCoil(Address:Word):Boolean;
PROCEDURE { 2 } SetCoil(Address:Word; State:Boolean);
FUNCTION  { 3 } ReadRegister(Address:Word):Integer;
PROCEDURE { 4 } SetRegister(Address:Word; Value:Integer);
FUNCTION  TeleMecError:Integer;
PROCEDURE DisconnectTeleMec;
{$IFDEF debug}
  FUNCTION Hex(Byt:Byte):String;
{$ENDIF}

IMPLEMENTATION

CONST
  TeleMecErr : Integer = NoError;
  cp : Byte = 1;
  MsgBytes = 14;
  Filler   = $8000;

TYPE
  MsgRec = RECORD
             Header,
             PLC,
             Func,
             Address,
             Value,
             Trailer,
             ChkSum : Word;
           END;
  Words = ARRAY[1..7] OF Word;

{---Primitives---------------------------------------------------------------}

FUNCTION LRC(Message:MsgRec):Word;
VAR
  i   : Integer;
  sum : Word;
BEGIN
  Sum:=0;
  FOR i:=1 TO 6 DO Sum:=Sum+Words(Message)[i];
  LRC:=Sum;
END;{LRC}

FUNCTION LRCok(Message:MsgRec):Boolean;
VAR
  chksum : Word;
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
            Message.value:=Random($FFFF);
            Message.Address:=Random($FFFF);
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
  BEGIN
    owmax:=WindMax;
    owmin:=WindMin;
    ox:=WhereX;
    oy:=WhereY;
    Window(38,3,79,24);
    GotoXY(LastX,LastY);
    Write(' ',What:5);
    IF What<>'ERR: '
    THEN BEGIN
      FOR i:=1 TO Byte(Msg[0])
      DO BEGIN
        Write(Hex(Byte(Msg[i])));
        IF not odd(i) THEN Write(' ');
      END;
    END ELSE Write(Msg);
    IF (What<>'') and (Msg[0]=#0) THEN Write('<No Msg>');
    Writeln;
    LastX:=WhereX; LastY:=WhereY;
    WindMin:=owmin;
    WindMax:=owmax;
    GotoXY(ox,oy);
  END;

{$ENDIF}

PROCEDURE xcv(PLC,Func:Word;VAR Address,Value:Word);
CONST
  StxDle = $1002;
  EtxDle = $1003;
VAR
  Trans,Timer,Bytes : Word;
  Message : MsgRec;
  MsgStr : String[MsgBytes];
BEGIN
  Trans:=0;
  REPEAT
    Inc(Trans);
    TeleMecErr:=NoError;
    Message.Header:=StxDle;
    Message.PLC:=PLC;
    Message.Func:=Func;
    Message.Address:=Address;
    Message.Value:=Value;
    Message.Trailer:=EtxDle;
    Message.ChkSum:=LRC(Message);
    {$IFDEF debug}
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
    UNTIL (Bytes=MsgBytes) or (Timer>1000);

    IF Timer>1000 THEN TelemecErr:=TimeOut;
    StrToMsg(MsgStr,Message);
    IF not LRCok(Message) THEN TelemecErr:=ChkSumError
     ELSE IF (Message.Func DIV $100)=$15{NAK} THEN TelemecErr:=NAKerror;
    {$IFDEF debug}
      ShowMsgs('PLS: ',MsgStr);
      ShowMsgs('ERR: ',TeleMecErrorMsg[TeleMecErr]);
    {$ENDIF}
    Delay(200); {3.3 No retransmission before 200ms since last received byte}
  UNTIL (TeleMecErr=NoError) or (Trans>4);
  IF not (Trans>4) and (TeleMecErr=NoError)
  THEN BEGIN
    Address:=Message.Address;
    Value:=Message.Value;
  END ELSE TeleMecErr:=FatalError;
  {$IFDEF debug}
    ShowMsgs('ERR: ',TeleMecErrorMsg[TeleMecErr]);
    ShowMsgs('','');
  {$ENDIF}
END;{xcv}

{---Globals------------------------------------------------------------------}

PROCEDURE ConnectTelemec(ComPort:Comports; Speed:ComSpeed);
BEGIN
  cp:=ComPort;
  cOpen(cp,32,Speed,8,pEven,1);
END;{ConnectTelemec}

PROCEDURE { 0 } GetStatus(VAR Master,Slaves:Word);
BEGIN
  Master:=Filler;
  Slaves:=Filler;
  xcv(Filler,0,Master,Slaves);
END;{GetStatus}

FUNCTION  { 1 } ReadCoil(Address:Word):Boolean;
VAR
  rAddr : Word;
  value : Word;
BEGIN
  Address:=Address MOD 10000;
  rAddr:=Address MOD 100;
  Value:=Filler;
  xcv(Address DIV 100,1,rAddr,Value);
  ReadCoil:=(Value=1)
END;{ReadCoil}

PROCEDURE { 2 } SetCoil(Address:Word; State:Boolean);
CONST
  Value : ARRAY[Boolean] OF Word = (0,1);
VAR
  rAddr : Word;
BEGIN
  Address:=Address MOD 10000;
  rAddr:=Address MOD 100;
  xcv(Address DIV 100,2,rAddr,Value[State]);
END;{SetCoil}

FUNCTION  { 3 } ReadRegister(Address:Word):Integer;
VAR
  rAddr : Word;
  value : Word;
BEGIN
  Address:=Address MOD 10000;
  rAddr:=Address MOD 100;
  Value:=Filler;
  xcv(Address DIV 100,3,rAddr,Value);
  ReadRegister:=Value;
END;{ReadRegister}

PROCEDURE { 4 } SetRegister(Address:Word; Value:Integer);
VAR
  rAddr  : Word;
  wValue : Word;
BEGIN
  Address:=Address MOD 10000;
  rAddr:=Address MOD 100;
  move(Value,wValue,SizeOF(wValue));
  xcv(Address DIV 100,4,rAddr,wValue);
END;{SetRegister}

FUNCTION TeleMecError:Integer;
BEGIN
  TeleMecError:=TeleMecErr;
  TeleMecErr:=NoError;
END;{TeleMecError}

PROCEDURE DisconnectTelemec;
BEGIN
  cClose(cp);
END;{DisconnectTelemec}

BEGIN { Init Unit Telemec }
END.
