{$I CODEDEFS.PAS} {Include code generation definitions}
{DEFINE Debug}{When enabled packets will be shown}

UNIT SattCon; {.1 (c) 19900207 Lars Fosdal}
{----------------------------------------------------------------------------}
{ Short System Description }
{----------------------------------------------------------------------------}
{
  Source : Turbo Pascal v.5.0
  Author : Lars Fosdal

  This unit contains an TP5 implementation of the
  SattCon COMLI 01 Protocol.
  (Documented in : PBS COMLI Systembeskrivning  COMLI.131.01.Sv)

}
INTERFACE

USES
  Crt,LFsystem,LFString,LFcomm;

CONST
  SattConMsg  = ' SattCon.1 19900207 Lars Fosdal ';

  NotAck      = -3;
  InvalidBCC  = -2;
  TimeOut     = -1;
  NoError     = 0;

  SattConErr : Integer = 0;

  SattConErrorMsg : ARRAY[-3..0] OF String[40]
  =(
  'SattCon: Packet Not Acknowledged',
  'SattCon: Invalid Packet BCC',
  'SattCon: Retransmission Timeout',
  'SattCon: No Errors'
  );

TYPE
  BusMode   = (Ascii,Binary);

PROCEDURE SetSattCon(_ComPort,
                     SlaveAddr : Byte;
                     _Mode     : BusMode);
PROCEDURE ConnectSattCon(speed    :ComSpeed;
                        parity   :Char;
                        stopbits :ComSbits);
PROCEDURE DisconnectSattCon;
FUNCTION  SattConResponding:Boolean;
FUNCTION  SattConError:Integer;
FUNCTION  GetIORAM(Addr:Word):Word;
PROCEDURE SetIORAM(Addr,Value:Word);
FUNCTION  GetIOBIT(Addr:Word):Boolean;
PROCEDURE SetIOBIT(Addr:Word;Switch:Boolean);

IMPLEMENTATION

CONST
  stx = #2;
  etx = #3;
  ack = #6;
  ComPort   : Byte = Com1;
  Mode      : BusMode = Binary;
  DataBits  : Byte = 8;
  DestAddr  : Byte = 1;        { PLC Address holder }
  StampValue: Byte = $30;      { $30 for 1st xmit, else $31,$32,$31,$32,$31...}
  Dummy     : Pointer = Nil;   { Dummy }

TYPE
  LongArr = Array[0..15] OF LongInt;
  WordArr = Array[0..31] OF Word;


  MsgData = ARRAY[0..63] OF Byte;

  MsgHeader = RECORD
    Destination : Word;
    Stamp       : Byte;
    Func        : Byte;
  END; {REC MsgHeader}

  MsgInfo = RECORD
    Addr        : LongInt;
    ByteCount   : Word;
  END;{REC MsgHeader}

  GetPack = RECORD
    Msg    : MsgHeader;
    Packet : MsgInfo;
  END;{REC GetPack}

  SetPack = RECORD
    Msg    : MsgHeader;
    Packet : MsgInfo;
    Data   : MsgData;
  END;{REC SetPack}


{----------------------------------------------------------------------------}
{ Connect/Disconnect procedures }
{----------------------------------------------------------------------------}

PROCEDURE SetSattCon(_ComPort,SlaveAddr:Byte; _Mode:BusMode);
BEGIN
  ComPort:=_ComPort;
  DestAddr:=SlaveAddr;
  Mode:=_Mode;
  CASE Mode OF
    Ascii  : DataBits:=7;
    Binary : DataBits:=8;
  END;
END;{SetSattCon}

PROCEDURE ConnectSattCon(speed:ComSpeed; parity:Char; stopbits:ComSbits);
VAR
  par : ComParity;
BEGIN
  CASE upcase(Parity) OF
    'E' : par:=pEven;
    'O' : par:=pOdd;
    'S' : par:=pSpace;
    'M' : par:=pMark;
     ELSE par:=pNone;
  END;
  cOpen(ComPort,640,speed,DataBits,par,stopbits);
  DTR(ComPort,True); ResetRB(ComPort);
END;{ConnectSattCon}

PROCEDURE DisconnectSattCon;
BEGIN
  DTR(ComPort,False);
  cClose(ComPort);
END;{DisconnectSattCon}

FUNCTION SattConError:Integer;
{ - Return current ErrorValue and Reset it to NoError}
BEGIN
  SattConError:=SattConErr;
  SattConErr:=NoError;
END;{FUNC SattConError}

{----------------------------------------------------------------------------}
{ Communication ASCII/Binary Interface}
{----------------------------------------------------------------------------}

FUNCTION bHex(b:Byte):Word;
{ - Convert Byte to 2-byte HexString }
VAR
  hs : String[2];
  w  : Word;
BEGIN
  hs:=HexB(b);
  move(hs[1],w,2);
  bHex:=w;
END;{FUNC bHex}

FUNCTION wHex(w:Word):LongInt;
{ - Convert Word to 4-byte HexString }
VAR
  hs  : String[4];
  l   : LongInt;
BEGIN
  hs:=HexW(w);
  Move(hs[1],l,4);
  wHex:=l;
END;{FUNC wHex}

FUNCTION bDes(st:str2):Byte;
{ - Convert 2-byte HexString to Byte }
VAR
  Err : Integer;
  v   : Byte;
BEGIN
  val('$'+st,v,err); bDes:=v;
END;{bDes}

FUNCTION wDes(st:str4):Word;
{ - Convert 4-byte HexString to Word}
VAR
  Err : Integer;
  v   : Word;
BEGIN
  val('$'+st,v,err); wDes:=v;
END;{wDes}

FUNCTION CalcBCC(st :String):Byte;
{ - Calculate Binary Block Checksum }
VAR
  i   : Byte;
  sum : Byte;
BEGIN
  sum:=Byte(St[1]);
  FOR i:=2 TO Byte(st[0]) DO Sum:=Sum XOR Byte(St[i]);
  CalcBCC:=Sum;
END;{FUNC CalcBCC}

PROCEDURE AddBCC(VAR st :String);
{ - Add BCC to packet st }
VAR
  Sum : Byte;
BEGIN
  Sum:=CalcBCC(st);
  inc(st[0]); st[Byte(St[0])]:=Char(Sum);
END;{AddBCC}

FUNCTION BCCok(st:String):Boolean;
{ - Do a BCC verification }
VAR
  Sum : Byte;
BEGIN
  Sum:=CalcBCC(Copy(st,2,Byte(st[0])-2));
  BCCok:=Boolean(Byte(st[Byte(st[0])])=Sum) and True;
END;{FUNC BCCok}

PROCEDURE Convert2ASCII(VAR data:MsgData; Items:Byte);
{ - Convert Binary data to ASCII data }
VAR
  Work : MsgData;
  i    : Word;
BEGIN
  i:=0;
  REPEAT
    LongArr(Work)[i]:=wHex(WordArr(data)[i*4]);
    Inc(i);
  UNTIL i=Items;
  data:=work;
END;{PROC Convert2ASCII}

PROCEDURE Convert2Binary(VAR data:MsgData; Bytes:Byte);
BEGIN
END;

FUNCTION TwistByte(b:Byte):Byte;
{ - Byte Rotator : 11001000 -> 00010011 }
VAR
  br,i : Byte;
BEGIN
  br:=0;
  FOR i:=0 TO 7
  DO BEGIN
    br:=br SHL 1;
    IF odd(b) THEN Inc(br);
    b:=b SHR 1;
  END;
  TwistByte:=br;
END;{FUNC TwistByte}

FUNCTION TwistWord(w:Word):Word;
{ - Convert SattCon's "twisted" Word to PC Word (Page 9.11)}
BEGIN
  TwistWord:=(TwistByte(Lo(w))*$100)+TwistByte(Hi(w));
END;{FUNC TwistWord}

FUNCTION Oct2Dec(Oct:Word):Word;
{ - Convert Octal number (Decimal form) to Decimal number}
CONST
  dBase : ARRAY[0..4] OF Word = (1,10,100,1000,10000);
  oBase : ARRAY[0..4] OF Word = (1,8,64,512,4096);
VAR
  Dec : Word;
  b,w : Word;
BEGIN
  Dec:=0;
  FOR b:=4 DownTo 0
  DO BEGIN
    w:=Oct DIV dBase[b];
    Oct:=Oct MOD dBase[b];
    Dec:=Dec+w*oBase[b];
  END;
  Oct2Dec:=Dec;
END;{Oct2Dec}

{$IFDEF Debug}
PROCEDURE DumpHex(Msg:String;Data:String);
{ - Debug mode, dump packet values on screen}
CONST
  Rev : Boolean = False;
VAR
  i : Word;
BEGIN
  IF Rev
  THEN BEGIN
    TextBackground(White);
    TextColor(Black);
  END;
  Rev:=Not Rev;
  ClrEol;
  Write(Msg,'(',Byte(Data[0]):2,'): ');
  IF Data[0]>#0
  THEN FOR i:=1 TO Byte(Data[0]) DO Write(Hex(Byte(Data[i])),' ')
  ELSE Write('<Packet is Empty>');
  TextColor(LightGray); TextBackGround(Black);
  Writeln;
END;{PROC DumpHex}
{$ENDIF}

PROCEDURE Command(VAR TheCmd; VAR ans:MsgData);
{ - Command parser, handles re-xmits, packing, control sums, etc.}
VAR
  reXmits   : Word;    {ReTransmission Counter}
  recvOK    : Boolean; {Receive Status}
  ReplyFunc : Char;    {Expected PLC Reply function}
  xBytes,              {Number of Bytes to transmit to PLC}
  dBytes,              {Number of Databytes (Included in rBytes)}
  rBytes,              {Number of Bytes to receive from PLC}
  bFactor,             {2=Binary, 4=ASCII}
  bCount    : Byte;    {Number of Registers Transmitted / Expected}
  xmtstr,              {Transmitted Packet Buffer}
  rcvstr    : String;  {Received Packet Buffer}
  Cmd       : SetPack; {Command Work Record}

  PROCEDURE Transmit;
  { - Build and Send Transmission Packet}
  BEGIN
    FillChar(xmtStr,SizeOf(xmtStr),0);
    CASE Char(Cmd.Msg.Func) OF
      '0' : BEGIN {Transfer of I/O-RAM status or register}
              xBytes:=10+bFactor*bCount;
              dBytes:=0;
              rBytes:=8;
              ReplyFunc:='1';
            END;
      '2' : BEGIN {Request of I/O-RAM status or register}
              xBytes:=10;
              dBytes:=bFactor*bCount;
              rBytes:=13+dBytes;
              ReplyFunc:='0';
            END;
      '4' : BEGIN {Request of I/O-BIT status}
              xBytes:=10;
              dBytes:=bCount;
              rBytes:=13+dBytes;
              ReplyFunc:='3';
            END;
      '3' : BEGIN {Transfer of I/O-BIT status}
              xBytes:=11;
              dBytes:=bCount;
              rBytes:=8;
              ReplyFunc:='1';
            END;
    END;
    Move(Cmd,xmtstr[1],xBytes); {Move Command Block into Xmt.Packet Buffer}
    xmtstr[0]:=Char(xBytes);
    xmtstr:=xmtstr+etx;         {Add ETX at end of Packet}
    AddBCC(xmtstr);             {Add BCC at end of Packet}
    xmtstr:=stx+xmtstr;         {Add STX at start of Packet}
    {$IFDEF Debug}
      DumpHex('Xmt',xmtstr);
    {$ENDIF}
    cWrite(ComPort,xmtstr);     {Send Packet}
  END;{PROC Transmit}

  PROCEDURE Receive(VAR ok:Boolean);
  VAR
    rCount : Byte;
    Timer  : Word;
  BEGIN
    rCount:=0;
    FillChar(RcvStr,SizeOf(RcvStr),0);
    Timer:=0;
    REPEAT
      IF Received(ComPort)
      THEN BEGIN
        RcvStr:=RcvStr+cRead(ComPort);
        Inc(rCount);
      END
      ELSE BEGIN
        Inc(Timer); Delay(1);
      END;
    UNTIL (rCount>=rBytes) or (Timer>1000);
    {$IFDEF Debug}
      Writeln('Rcv expects ',rBytes,' bytes (',dBytes,' data)');
      DumpHex('Rcv',RcvStr);
    {$ENDIF}

    IF Timer<=1000
    THEN BEGIN
      SattConErr:=NoError;
      ok:=BCCok(RcvStr);
      IF not ok THEN SattConErr:=invalidBCC;
      ok:=ok and ((RcvStr[6]=Ack) or (RcvStr[5]=ReplyFunc));
      IF not ok THEN SattConErr:=NotACK;
      IF ok and (Char(Cmd.Msg.Func) in ['2','4'])
      THEN BEGIN
        move(RcvStr[12],Ans,dBytes);
        IF Mode=ASCII
        THEN Convert2Binary(Ans,dBytes);
      END;
    END
    ELSE SattConErr:=TimeOut;
  END;{PROC Receive}

BEGIN {PROC Command}
  Cmd:=SetPack(TheCmd);
  bCount:=Cmd.Packet.ByteCount;
  WITH Cmd
  DO BEGIN  { - Convert Packet info to Hex format }
    Msg.Destination:=bHex(DestAddr);
    Msg.Stamp:=StampValue;
    Packet.Addr:=wHex(Packet.Addr);
    IF Mode=Binary
    THEN BEGIN
      bFactor:=2;
      Packet.ByteCount:=bFactor*Packet.ByteCount;
    END
    ELSE BEGIN {ASCII}
      bFactor:=4;
      Convert2ASCII(Data,Packet.ByteCount);
      Packet.ByteCount:=bFactor*Packet.ByteCount;
    END;
    CASE Char(Cmd.Msg.Func) OF
      '3': Packet.ByteCount:=1;
      '4': Packet.ByteCount:=0;
    END;
    Packet.ByteCount:=bHex(Packet.ByteCount);
  END;
  reXmits:=0;
  recvOK:=False;
  REPEAT
    Inc(reXmits);
    Transmit;
    Receive(recvOK);
  UNTIL recvOK or (reXmits>5);
  CASE StampValue OF
    $30 : StampValue:=$31;
    $31 : StampValue:=$32;
    $32 : StampValue:=$31;
  END;
END;{PROC Command}


{----------------------------------------------------------------------------}
{ SattCon Functions }
{----------------------------------------------------------------------------}

FUNCTION GetIORAM(Addr:Word):Word;
{ - MsgType 2 : Request of I/O-RAM status or register}
VAR
  Out : GetPack;
  Inn : MsgData;
  w   : Word;
BEGIN
  Out.Msg.Func:=Byte('2');
  Out.Packet.Addr:=$4000+(Addr*$10);
  Out.Packet.ByteCount:=1;
  Command(Out,Inn);
  IF SattConErr=0
  THEN BEGIN
    w:=WordArr(Inn)[0];
  END
  ELSE w:=0;
  GetIORAM:=TwistWord(w);
END; {FUNC GetIORAM}

PROCEDURE SetIORAM(Addr,Value:Word);
{ - MsgType 0 : Transfer of I/O-RAM status or register}
VAR
  Out : SetPack;
BEGIN
  Out.Msg.Func:=Byte('0');
  Out.Packet.Addr:=$4000+(Addr*$10);
  Out.Packet.ByteCount:=1;
  WordArr(Out.Data)[0]:=TwistWord(Value);
  Command(Out,MsgData(Dummy^));
END; {PROC SetIORAM}

FUNCTION GetIOBIT(Addr:Word):Boolean;
{ - MsgType 3 : Request of I/O-BIT status}
VAR
  Out : GetPack;
  Inn : MsgData;
BEGIN
  Out.Msg.Func:=Byte('4');
  Out.Packet.Addr:=Oct2Dec(Addr);
  Out.Packet.ByteCount:=1;
  Command(Out,Inn);
  IF SattConErr=0
  THEN BEGIN
    GetIObit:=(Char(Inn[0])='1');
  END
  ELSE GetIOBIT:=False;
END; {FUNC GetIOBIT}

PROCEDURE SetIOBIT(Addr:Word;Switch:Boolean);
{ - MsgType 4 : Transfer of I/O-BIT status}
CONST
  sw : ARRAY[Boolean] OF Char = ('0','1');
VAR
  Out : SetPack;
BEGIN
  Out.Msg.Func:=Byte('3');
  Out.Packet.Addr:=Oct2Dec(Addr);
  Out.Packet.ByteCount:=1;
  Char(Out.Data[0]):=sw[Switch];
  Command(Out,MsgData(Dummy^));
END; {PROC SetIOBIT}



FUNCTION SattConResponding:Boolean;
VAR
  Response : Boolean;
  Tries    : Integer;
  Answer   : Boolean;
BEGIN
  Tries:=0;
  REPEAT
    Inc(Tries);
    Answer:=GetIOBIT(0);
    Response:=SattConError=0;
  UNTIL Response or (Tries>5);
  SattConResponding:=Response;
END;{SattConResponding}

BEGIN {Init SattCon Unit}
  Units.Enter(SattConMsg,MemAvail,CSeg);
END.
