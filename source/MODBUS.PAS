{$I CODEDEFS.PAS} {Include code generation definitions}
{DEFINE Debug}

UNIT ModBus; {.3 (c) 19880812 Lars Fosdal}
{----------------------------------------------------------------------------}
{ Short System Description }
{----------------------------------------------------------------------------}
{
  Source : Turbo Pascal v.4.0
  Author : Lars Fosdal

  This unit contains an TP4/TP5 implementation of the
  Gould Modicon Modbus Protocol (Documented in PI-MBUS-300 Rev.A, Nov.'83)

  For use with an P484/P884 controller ONLY !
}
INTERFACE

USES
  Crt,LFsystem,LFcrt,LFcomm;

CONST
  TimeOut     = -1;
  IllegalFunc = 1;
  IllegalAddr = 2;
  IllegalData = 3;
  DeviceFail  = 4;
  BusyReject  = 6;
  ModBusError : Integer = 0;
TYPE
  BusMode   = (Ascii,RTU);
  StatusRec = RECORD
                ID      : Word;
                Running : Boolean;
                CurrPort,
                MemSize : Byte;
              END;

PROCEDURE SetModBus(_ComPort,
                    SlaveAddr : Byte;
                    _Mode     : BusMode);

PROCEDURE ConnectModBus(speed    :ComSpeed;
                        parity   :Char;
                        stopbits :ComSbits);

PROCEDURE DisconnectModBus;

PROCEDURE { 1} ReadCoilStatus(CoilAddr,Count:Word;VAR Data);      {Coil:0xxxx}

FUNCTION  { 1} ReadOneCoil(CoilAddr:Word):boolean;                {Coil:0xxxx}

PROCEDURE { 2} ReadInputStatus(InputAddr,Count:Word;VAR Data);    {Coil:1xxxx}

FUNCTION  { 2} ReadOneInput(InputAddr:Word):boolean;              {Coil:1xxxx}

PROCEDURE { 3} ReadHoldReg(HoldRegAddr,Count:Word;VAR Data);      {Reg:4xxxx}

FUNCTION  { 3} ReadOneHoldReg(HoldRegAddr:Word):Word;             {Reg:4xxxx}

PROCEDURE { 4} ReadInputReg(InputRegAddr,Count:Word;VAR Data);    {Reg:3xxxx}

FUNCTION  { 4} ReadOneInputReg(InputRegAddr:Word):Word;           {Reg:3xxxx}

PROCEDURE { 5} ForceSingleCoil(CoilAddr:Word;CoilSwitch:boolean); {Coil:0xxxx}

PROCEDURE { 6} PresetSingleReg(HoldRegAddr,RegData:Word);         {Reg:4xxxx}

FUNCTION  { 7} ReadExcepts:Byte;

PROCEDURE { 8} LoopBackTest(TestNo:Word;VAR Res:Word);

PROCEDURE {11} FetchEventCount(VAR Status,ErrCount:Word);

PROCEDURE {15} ForceCoils(CoilAddr,Count:Word; VAR Data);         {Coil:0xxxx}

PROCEDURE {16} PresetHoldRegs(HoldRegAddr,Count:Word; VAR Data);  {Reg:4xxxx}

PROCEDURE {17} ReportSlaveID(VAR Stat : StatusRec);

FUNCTION ModBusResponding:Boolean;

IMPLEMENTATION

CONST
  ModiconMsg =' Modicon.3 19880812 Lars Fosdal ';
  CrLf      = ^M^J;
  Switch    : Array[Boolean] OF Word = ($0000,$FF00);
  ModAddr   : Byte = 1;
  ComPort   : Byte = Com1;
  Mode      : BusMode = RTU;
  DataBits  : Byte = 8;

TYPE
  BoolArr = ARRAY[0..1999] OF Boolean;
  WordArr  = Array[1..125] OF Word;
  ByteArr  = Array[1..250] OF Byte;
  ShortCmd = RECORD
               Addr,
               Func : Byte;
             END;
  NormCmd  = RECORD
               Addr,
               Func : Byte;
               q1,
               q2 : Word;
             END;
  LongCmd  = RECORD
               Addr,
               Func : Byte;
               Start,
               Count : Word;
               Bytes : Byte;
               CASE Boolean OF
                 False : (byt : ByteArr);
                 True  : (wrd : WordArr);
             END;
  ShortAns = RECORD
               Addr,
               Func,
               Data : Byte;
             END;
  NormAns  = RECORD
               Addr,
               Func : Byte;
               a1,
               a2   : Word;
             END;
  LongAns  = RECORD
               Addr,
               Func,
               Bytes : Byte;
               CASE Boolean OF
                 False : (byt : ByteArr);
                 True  : (wrd : WordArr);

              END;


{----------------------------------------------------------------------------}
{ Connect/Disconnect procedures }
{----------------------------------------------------------------------------}

PROCEDURE SetModBus{(_ComPort,SlaveAddr:Byte; _Mode:BusMode)};
BEGIN
  ComPort:=_ComPort;
  ModAddr:=SlaveAddr;
  Mode:=_Mode;
  CASE Mode OF
    Ascii : DataBits:=7;
    RTU   : DataBits:=8;
  END;
END;{SetModBus}

PROCEDURE ConnectModBus{(speed:ComSpeed; parity:Char; stopbits:ComSbits)};
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
  DTR(ComPort,True); ResetRB(1);
END;{ConnectModBus}

PROCEDURE DisconnectModBus;
BEGIN
  DTR(ComPort,False);
  cClose(ComPort);
END;{DisconnectModBus}

{----------------------------------------------------------------------------}
{ Communication ASCII/RTU Interface}
{----------------------------------------------------------------------------}

FUNCTION des(st:str2):Char;
VAR
  Err : Integer;
  v   : Byte;
BEGIN
  val('$'+st,v,err); des:=char(v);
END;{des}

PROCEDURE AddLRC(VAR st :String);
VAR
  i   : Byte;
  sum : Byte;
BEGIN
  sum:=0;
  FOR i:=1 TO Byte(st[0]) DO Sum:=Sum+Byte(St[i]);
  inc(st[0]); st[Byte(St[0])]:=Char((Not Sum)+1);
END;{AddLRC}

PROCEDURE AddCRC(VAR st : String);
CONST
  polynom : word =$A001;
TYPE
  the = RECORD
          loByte,hiByte : byte;
        END;
VAR
  ShiftReg     : Word;
  Shifts,ByteN : Byte;
  Polyflag     : Boolean;
BEGIN
  ShiftReg:=$FFFF;
  FOR ByteN:=1 TO Byte(st[0]) DO
  BEGIN
    the(ShiftReg).loByte:=the(ShiftReg).loByte xor Byte(st[ByteN]);
    FOR Shifts:=1 TO 8 DO
    BEGIN
      Polyflag:=odd(ShiftReg);
      ShiftReg:=ShiftReg shr 1;
      IF Polyflag THEN ShiftReg:=ShiftReg xOr Polynom;
    END;
  END;
  St:=St+Char(Lo(ShiftReg))+Char(Hi(ShiftReg));
END;{AddCRC}

PROCEDURE Command(VAR cmd;VAR ans);
VAR
  sc,sa  : String;
  w      : Word;
  i,Func : Byte;
  Size,
  CharCount,
  Timer  : Word;
  Ch     : Char;
  hxs    : Str2;
BEGIN
  ModBusError:=0;
  NormCmd(Cmd).Addr:=ModAddr;
  Func:=NormCmd(Cmd).Func;
  IF Mode=RTU THEN
  CASE Func OF
         1,2 : BEGIN
                 Size:=5+(NormCmd(Cmd).q2 DIV 8);
                 IF (NormCmd(Cmd).q2 MOD 8) >0 THEN Inc(Size);
               END;
         3,4 : Size:=5+(2*NormCmd(Cmd).q2);
    5,6,8,11 : Size:=8;
           7 : Size:=5;
          12 : Size:=75;
       15,16 : Size:=8;
          17 : Size:=13;
  END;{Case}
  CASE Func OF
    1..6,
     8 : WITH NormCmd(Cmd) DO
         BEGIN
           q1:=Swap(q1); q2:=Swap(q2); sc[0]:=#6;
         END;
    7,11,12,
    17 : sc[0]:=#2;{ShortCmds}
    15 : WITH LongCmd(Cmd) DO
         BEGIN
           Start:=Swap(Start);
           Count:=Swap(Count);
           sc[0]:=Char(7+Bytes);
         END;
    16 : WITH LongCmd(Cmd) DO
         BEGIN
           FOR i:=1 TO Count DO Wrd[i]:=Swap(Wrd[i]);
           Start:=Swap(Start);
           Count:=Swap(Count);
           sc[0]:=Char(7+Bytes);
         END;
  END;{Case}
  Move(cmd,sc[1],Byte(sc[0]));
  CASE Mode OF
    Ascii : BEGIN
              AddLRC(sc);
              cWrite(ComPort,':');
              FOR i:=1 TO Byte(sc[0]) DO
              BEGIN
                cWrite(ComPort,Hex(Byte(Sc[i])));
              END;
              cWrite(ComPort,CrLF);
              ResetRB(ComPort);
              Timer:=0; sa:=''; Hxs:='';
              REPEAT
                IF Received(ComPort) THEN
                BEGIN
                  Ch:=cRead(ComPort);
                  IF not (ch in [':',^M,^J]) THEN
                  BEGIN
                    hxs:=hxs+ch;
                    IF length(hxs)=2 THEN
                    BEGIN
                      sa:=sa+des(Hxs);
                      hxs:='';
                    END;
                  END;
                END
                 ELSE
                BEGIN
                  Inc(Timer); Delay(1);
                END;
              UNTIL (Ch=^J) or (Timer>1000);
              move(sa[1],ans,Byte(sa[0])-1);
            END;
    RTU   : BEGIN
              AddCRC(sc);
              cWrite(ComPort,sc);
              Timer:=0; CharCount:=0; sa:='';
              REPEAT
                IF Received(ComPort) THEN
                BEGIN
                  sa:=sa+cRead(ComPort);
                  Inc(CharCount);
                END
                 ELSE
                BEGIN
                  Inc(Timer); Delay(1);
                END;
              UNTIL (CharCount>=Size) or (Timer>1000);
              Move(sa[1],ans,Size-2);
            END;
  END;{Case}
  IF Timer>1000 THEN ModBusError:=TimeOut;
{$IFDEF Debug}
  write('->:');
  FOR i:=1 TO Byte(sc[0]) DO
  BEGIN
    write(Hex(Byte(Sc[i])));
  END;
  writeln;
  write('<-'); IF Mode=RTU THEN write(':');
  FOR i:=1 TO Byte(sa[0]) DO
  BEGIN
    write(Hex(Byte(Sa[i])));
  END;
  writeln;
{$ENDIF}
  IF Boolean(ShortAns(ans).Func and $80) THEN ModBusError:=ShortAns(Ans).Data;
  CASE Func OF
    1,2 : {LongAns Byte};
    3,4 : BEGIN {LongAns Word}
            FOR i:=1 TO LongAns(Ans).Bytes DIV 2 DO
             LongAns(Ans).wrd[i]:=Swap(LongAns(Ans).wrd[i]);
          END;
    7   : {ShortAns};
    5,6,8,11,15,16
        : BEGIN {NormAns}
            NormAns(Ans).a1:=Swap(NormAns(Ans).a1);
            NormAns(Ans).a2:=Swap(NormAns(Ans).a2);
          END;
    12  : BEGIN {LongAns }
            FOR i:=1 TO 3 DO LongAns(Ans).Wrd[i]:=Swap(LongAns(Ans).wrd[i]);
          END;
  END;{Case}
END;{Command}

{----------------------------------------------------------------------------}
{ ModBus Functions }
{----------------------------------------------------------------------------}

PROCEDURE ReadCoilStatus{(CoilAddr,Count:Word;VAR Data)};
VAR
  Cmd : NormCmd;
  Ans : LongAns;
  i   : Word;
  byp : Word;
  bip : Byte;
BEGIN
  Cmd.Func:=1;
  Cmd.q1:=(CoilAddr-1) MOD 1000; Cmd.q2:=Count;
  Command(Cmd,Ans);
  i:=0;
  REPEAT
    Byp:=(i DIV 8)+1; Bip:=1 shl(i Mod 8);
    BoolArr(Data)[i]:=Ans.Byt[Byp] and Bip = bip;
    inc(i);
  UNTIL i=Count;
END;{ReadCoilStatus}

FUNCTION ReadOneCoil{(CoilAddr:Word):boolean};
VAR
  Cmd      : NormCmd;
  Ans      : LongAns;
  CoilStat : Boolean;
BEGIN
  ReadCoilStatus(CoilAddr,1,CoilStat);
  ReadOneCoil:=CoilStat;
END;{ReadOneCoil}

PROCEDURE ReadInputStatus{(InputAddr,Count:Word;VAR Data)};
VAR
  Cmd : NormCmd;
  Ans : LongAns;
  i   : Word;
  byp : Word;
  bip : Byte;
BEGIN
  Cmd.Func:=2;
  Cmd.q1:=(InputAddr-1) MOD 1000; Cmd.q2:=Count;
  Command(Cmd,Ans);
  i:=0;
  REPEAT
    Byp:=(i DIV 8)+1; Bip:=1 shl(i Mod 8);
    BoolArr(Data)[i]:=Ans.Byt[Byp] and Bip = bip;
    inc(i);
  UNTIL i=Count;
END;{ReadInputStatus}

FUNCTION ReadOneInput{(InputAddr:Word):Boolean};
VAR
  InputStat : Boolean;
BEGIN
  ReadInputStatus(InputAddr,1,InputStat);
  ReadOneInput:=InputStat;
END;{ReadOneInput}

PROCEDURE ReadHoldReg{(HoldRegAddr,Count:Word;VAR Data)};
VAR
  Cmd : NormCmd;
  Ans : LongAns;
  i   : Word;
BEGIN
  Cmd.Func:=3;
  Cmd.q1:=(HoldRegAddr-1) MOD 1000; Cmd.q2:=Count;
  Command(Cmd,Ans);
  i:=0;
  REPEAT
    WordArr(Data)[i+1]:=Ans.Wrd[i+1];
    inc(i);
  UNTIL i=Count;
END;{ReadHoldReg}

FUNCTION ReadOneHoldReg{(HoldRegAddr : Word):Word};
VAR
  Cmd : NormCmd;
  Ans : LongAns;
  wrd : Word;
BEGIN
  ReadHoldReg(HoldRegAddr,1,wrd);
  ReadOneHoldReg:=Wrd;
END;{ReadOneHoldReg}

PROCEDURE ReadInputReg{(InputRegAddr,Count:Word;VAR Data)};
VAR
  Cmd : NormCmd;
  Ans : LongAns;
  i   : Word;
BEGIN
  Cmd.Func:=4;
  Cmd.q1:=(InputRegAddr-1) MOD 1000; Cmd.q2:=Count;
  Command(Cmd,Ans);
  i:=0;
  REPEAT
    WordArr(Data)[i+1]:=Ans.Wrd[i+1];
    inc(i);
  UNTIL i=Count;
END;{ReadInputReg}

FUNCTION ReadOneInputReg{(InputRegAddr : Word):Word};
VAR
  Cmd : NormCmd;
  Ans : LongAns;
  wrd : Word;
BEGIN
  ReadInputReg(InputRegAddr,1,wrd);
  ReadOneInputReg:=Wrd;
END;{ReadOneInputReg}

PROCEDURE ForceSingleCoil{(CoilAddr:Word;CoilSwitch:boolean)};
VAR
  Cmd : NormCmd;
  Ans : NormAns;
BEGIN
  Cmd.Func:=5;
  Cmd.q1:=(CoilAddr-1) MOD 1000; Cmd.q2:=Switch[CoilSwitch];
  Command(Cmd,ans);
END;{ForceSingleCoil}

PROCEDURE PresetSingleReg{(HoldRegAddr,RegData:Word)};
VAR
  Cmd : NormCmd;
  Ans : NormAns;
BEGIN
  Cmd.Func:=6;
  Cmd.q1:=(HoldRegAddr-1) MOD 1000; Cmd.q2:=RegData;
  Command(Cmd,ans);
END;{PresetSingleReg}

FUNCTION ReadExcepts{:Byte};
VAR
  Cmd : ShortCmd;
  Ans : ShortAns;
BEGIN
  Cmd.Func:=7;
  Command(Cmd,Ans);
  ReadExcepts:=Ans.Data;
END;{ReadExcepts}

PROCEDURE LoopBackTest{(TestNo:Word;VAR Res:Word)};
VAR
  Cmd : NormCmd;
  Ans : NormAns;
BEGIN
  Cmd.Func:=8;
  Cmd.q1:=TestNo;
  Cmd.q2:=Res;
  Command(Cmd,Ans);
  Res:=Ans.a2;
END;{LoopBackTest}

PROCEDURE FetchEventCount{(VAR Status,ErrCount:Word)};
VAR
  Cmd : ShortCmd;
  Ans : NormAns;
BEGIN
  Cmd.Func:=11;
  Command(Cmd,Ans);
  Status:=Ans.a1;
  ErrCount:=Ans.a2;
END;{LoopBackTest}

PROCEDURE ForceCoils{(CoilAddr,Count:Word; VAR Data)};
VAR
  Cmd : LongCmd;
  Ans : NormAns;
  i   : Word;
  byp,
  bip : Byte;
BEGIN
  Cmd.Func:=15;
  Cmd.Start:=(CoilAddr-1) MOD 1000; Cmd.Count:=Count;
  Cmd.Bytes:=((Count-1) DIV 8)+1; FOR i:=1 TO Cmd.Bytes DO Cmd.Byt[i]:=0;
  FOR i:=0 TO Count-1 DO
  BEGIN
    Byp:=(i DIV 8)+1; Bip:=(1 shl(i Mod 8))*Byte(BoolArr(Data)[i]);
    Cmd.Byt[Byp]:=Cmd.Byt[Byp]+bip;
  END;
  Command(Cmd,Ans);
END;{PresetCoils}

PROCEDURE PresetHoldRegs{(HoldRegAddr,Count; VAR Data)};
VAR
  Cmd : LongCmd;
  Ans : NormAns;
  i   : Word;
BEGIN
  Cmd.Func:=16;
  Cmd.Start:=(HoldRegAddr-1) MOD 1000; Cmd.Count:=Count;
  Cmd.Bytes:=2*Count;
  FOR i:=1 TO Count DO Cmd.Wrd[i]:=WordArr(Data)[i];
  Command(Cmd,Ans);
END;{PresetHoldRegs}

PROCEDURE ReportSlaveID{(VAR Stat : StatusRec)};
CONST
  Model : Array[0..8] OF Word = (84,484,384,584,0,0,0,0,884);
VAR
  Cmd :ShortCmd;
  Ans :LongAns;
BEGIN
  Cmd.Func:=17;
  Command(Cmd,ans);
  WITH Stat DO
  BEGIN
    ID:=Model[Ans.Byt[1]];
    Running:=Ans.Byt[2]=$FF;
    CurrPort:=Ans.Byt[3];
    MemSize:=Ans.Byt[4];
  END;
END;{ReportSlaveID}

FUNCTION ModBusResponding{:Boolean};
VAR
  Response : Boolean;
  Tries    : Integer;
  Answer   : Byte;
BEGIN
  Tries:=0;
  REPEAT
    Inc(Tries);
    Answer:=ReadExcepts;
    Response:=ModBusError=0;
  UNTIL Response or (Tries>5);
  ModBusResponding:=Response;
END;{ModBusResponding}

BEGIN {Init Modicon Unit}
  Units.Enter(ModiconMsg,MemAvail,CSeg);
END.
