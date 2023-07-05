{$I CODEDEFS.PAS} {Include code generation definitions}
{DEFINE Debug} { If defined : Display actual bytes transferred }

UNIT MelsecF; {.1 (c) 19880929 Lars Fosdal }

(*
 *         Mitsubishi PLC MELSEC F-series communication primitives.
 *
 *                        Written by Lars Fosdal
 *
 *----------------------------------------------------------------------------
 *
 * Mitsubishi F-series PLC programming/monitoring comm. protocol definition
 *            (Courtesy of Mitsubishi Corp. / G&L Beijer Electronics)
 *
 * Definition follows document BZ-5140 ( Revision D ).
 *
 * Cmd.no. Decription:
 *    Implem.
 * 00h  Y  Read PLC type
 *
 * 01h  N  Read All Program    F2-2K             : 2000 steps
 *                             F2-1K & F1-series : 1000 steps
 *                             F-20              :  320 steps
 *                             F-40              :  890 steps
 *
 * 02h  N  Write Program Block 1 : Step   0 - 127
 * 03h  N  Write Program Block 2 : Step 128 - 255
 * 04h  N  Write Program Block 3 : Step 256 - 383
 * 05h  N  Write Program Block 4 : Step 384 - 511
 * 06h  N  Write Program Block 5 : Step 512 - 639
 * 07h  N  Write Program Block 6 : Step 640 - 767
 * 08h  N  Write Program Block 7 : Step 768 - 895
 *
 * 09h  Y  Read single program step
 * 0Ah  Y  Write single program step (K values only !)
 *
 * 0Bh  Y  Set Monitoring for Registers/Elements
 * 0Ch  Y  Read data/status from Monitored Registers/Elements
 *
 * 0Dh  Y  Set/Reset one Element
 *
 * 0Eh  -  Not Used
 *
 * 0Fh  Y  Read PLC status
 *
 * 10h  N  Program block write Termination
 *
 * 11h  N  Assign PLC type
 *
 * 12h  N  Start PLC self check (F2-20GF selfcheck)
 *
 * 13h  N  Write Program Block 7 : Step 896 - 1023
 *
 * 14h  Y  Write one Data Register
 * 15h  Y  Read one Data Register
 *
 * 16h  N  Write Program Block  9 : Step 1024 - 1151
 * 17h  N  Write Program Block 10 : Step 1152 - 1279
 * 18h  N  Write Program Block 11 : Step 1280 - 1407
 * 19h  N  Write Program Block 12 : Step 1408 - 1535
 * 1Ah  N  Write Program Block 13 : Step 1536 - 1663
 * 1Bh  N  Write Program Block 14 : Step 1664 - 1791
 * 1Ch  N  Write Program Block 15 : Step 1792 - 1919
 * 1Dh  N  Write Program Block 16 : Step 1920 - 2000
 *
 * 1Eh-7Dh Not Used
 *
 * 7Eh  -  External Request from PLC of Retransmission of Command
 *
 *----------------------------------------------------------------------------
 * Revision Log :
 *
 * 26/9-88 Communication problem. Must send extra chars to receive anything.
 *         Phoned G›ran Rundquist, Beijers, Malm›. (095 46 40 35 86 31)
 *         Inverse RTS/CTS Handshake !!! Problem solved by modifying LFcomm.
 *
 *)

INTERFACE
USES
  Crt,LFsystem,LFcrt,LFcomm;

CONST
  TimeCountMax = {$IFDEF SimReal} 1 {$ELSE} 50 {$ENDIF};
{-Error Numbers }
  MelsecNoError        = 0;
  MelsecMonitorNotSet  = 1;
  MelsecNotAssigned    = 2;
  MelsecTimedOut       = 3;
  MelsecNotConstant    = 4;
{-Error Messages corresponding to number }
  MelsecErrorMsg : ARRAY[0..4] OF String[40] =
  ('No errors detected',
   'Monitor-addresses not set',
   'No serial-port assigned',
   'Timed out. No response from PLC',
   'Programmable constant not found.');

{-Add these constants to address of monitored element to watch inputs }
{ instead of outputs/current value (Not valid for all addresses)}
  CounterINP = 1000;
  CounterRST = 2000;
  TimerINP   = 1000;
  PulseINP   = 1000;
  ShiftINP   = 4000;

TYPE
  CodeRec = RECORD { For use with ReadPLCprogStep }
              Code   : Word;      { Actual code }
              opCode : Byte;      { operation code }
              data   : Word;      { operation parameter }
              mne    : String[7]; { Mnemonic representation }
            END;

FUNCTION DataForm(deci:Word;dType:Byte):Str2;
FUNCTION MelsecError:Integer;
PROCEDURE ReadPLCtype(VAR PLCtype:Byte);
PROCEDURE SetPLCMonitorAddr(nEl:Byte; VAR ElAddr; nReg:Byte; VAR RegAddr);
PROCEDURE MonitorPLC(VAR ElData; VAR RegData);
PROCEDURE SwitchElement(Address:Word;Switch:Boolean);
PROCEDURE ReadPLCstatus(VAR StatusByte:Byte);
PROCEDURE WritePLCreg(Address,Value:Word);
PROCEDURE ReadPLCreg(Address:Word; VAR Value:Word);
PROCEDURE ReadPLCProgStep(Step:Word; VAR Prog:CodeRec);
PROCEDURE WritePLCConst(Step:Word;value:Str2);
PROCEDURE ConnectPLC(Com:ComPorts;Speed:ComSpeed);
PROCEDURE DisconnectPLC;

IMPLEMENTATION

CONST
  FseriesMsg = ' MelsecF.1 19880929 Lars Fosdal ';

TYPE { for Typecasting }
  The = RECORD
          Lo,Hi : Byte;
        END;
  wArr = Array[0..7] OF Word;
  bArr = Array[0..143] OF Boolean;

CONST
  ComPortNr : Byte = 0;
VAR
  ErrorHolder : Integer;
  MonElements,
  MonRegisters,
  Dummy       : Byte;

PROCEDURE AddChkSum(VAR Data:String);
{ - Appends LRC Check Sum to end of string }
VAR
 n   : Byte;
 Sum : Word;
BEGIN
 sum:=0;
 FOR n:=1 TO Byte(Data[0]) DO sum:=sum+Byte(Data[n]);
 Data:=Data+Char(sum and $FF);
END;{AddChkSum}

FUNCTION ChkSumOK(Data:String):Boolean;
VAR
 n   : Byte;
 Sum : Word;
BEGIN
 sum:=0;
 FOR n:=1 TO Byte(Data[0])-1 DO sum:=sum+Byte(Data[n]);
 ChkSumOK:=Data[Byte(Data[0])]=Char(sum and $FF);
END;{ChkSumOK}

FUNCTION WordStr(w:Word):Str2;
BEGIN
  WordStr:=Char(The(w).Lo)+Char(The(w).Hi);
END;{WordStr}

FUNCTION Octal(Oct:Word;oType:Byte):Str2;
VAR Value : Word;
BEGIN
  {$IFOPT R+} {$DEFINE Rplus} {$R-} {$ENDIF}
  The(Value).Lo:=(Oct MOD 10)*16+(oType and $0F);
  The(Value).Hi:=(Oct DIV 100);
  The(Value).Hi:=The(Value).Hi*16+((Oct-(The(Value).Hi*100)) DIV 10);
  {$IFDEF Rplus} {$R+} {$UNDEF RPlus} {$ENDIF}
  Octal:=WordStr(Value);
END;{Octal}

FUNCTION BCDValue(value:word):Word;
VAR
  n,err : word;
BEGIN
  val(hexW(value),n,err);
  BCDValue:=n;
END;{BCDValue}

FUNCTION DataValue(value:word):Word;
VAR
  n,err : word;
BEGIN
  the(value).lo:=the(value).lo shr 4;
  value:=swap(value);
  val(hexW(value),n,err);
  DataValue:=n;
END;{DataValue}

FUNCTION AddrValue(value:word):Word;
VAR
  n,err : word;
BEGIN
  value:=value shr 4;
  val(hexW(value),n,err);
  AddrValue:=n-200;
END;{AddrValue}

{$IFDEF Debug}
PROCEDURE HexStr(txt:String;st:String);
VAR
  n : Byte;
BEGIN
  Write(txt);
  IF st[0]>#0 THEN
   FOR n:=1 to Byte(st[0]) DO
   BEGIN
     IF odd(n) THEN TextAttr:=$07 ELSE TextAttr:=$70;
     write(hex(Byte(St[n])));
   END;
   TextAttr:=$07;
   writeln;
END;{HexStr}
{$ENDIF}

PROCEDURE xcv(CommandCode:Byte; Outgoing:String; VAR Incoming);
(*
 * Command Parser: Packs, transmits, receives and unpacks command-packets.
 *)
VAR
  WaitFor   : Char;  { Number of bytes to expect on packet from PLC }
  Trials,            { Times packet sendt to PLC }
  Counted   : Byte;  { Bytes received from PLC upto now }
  TimeCount : Word;  { Timeout counter allows variation in PLC response time }
  rStr      : String;{ Received Packet }
BEGIN
  IF ComPortNr<>0 THEN
  BEGIN
    CASE CommandCode OF
     $00,
     $0F : WaitFor:=#5;
     $0A,
     $0D,
     $14,
     $0B : WaitFor:=#4;
     $09,
     $15 : WaitFor:=#6;
     $0C : WaitFor:=char(4+((MonElements+7) DIV 8)+(2*MonRegisters));
      ELSE WaitFor:=#0; {Not Implemented}
    END;
    Outgoing:=#$AA+char(CommandCode)+Outgoing+#$55; AddChkSum(Outgoing);
    Trials:=0;
    {$IFDEF Debug} HexStr('Out>',OutGoing); {$ENDIF}
    REPEAT
      TimeCount:=0;
      ResetRB(ComPortNr); FillChar(rStr,256,0);
      cWrite(ComPortNr,Outgoing);
      inc(Trials);
      REPEAT
        IF Received(ComPortNr) THEN rStr:=rStr+cRead(ComPortNr)
         ELSE
        BEGIN
          inc(TimeCount); delay(3);
        END;
      UNTIL ((rStr[0]=WaitFor) and ChkSumOK(rStr)) or (TimeCount=TimeCountMax);
    UNTIL (Byte(rStr[2])=CommandCode) or (Trials>5);
    {$IFDEF Debug} Hexstr('<In ',rStr); {$ENDIF}
    IF Trials>5 THEN ErrorHolder:=MelsecTimedOut
     ELSE
    BEGIN { transfer packet data to calling procedure }
      ErrorHolder:=MelsecNoError;
      CASE CommandCode OF { data sizes }
       $00,
       $0F : move(rStr[3],Incoming,1); { byte }
       $09,
       $15 : move(rStr[3],Incoming,2); { word }
       $0C : move(rStr[3],Incoming,((MonElements+7) DIV 8)+(2*MonRegisters));
       ELSE {No data to transfer };
      END;
    END;
  END ELSE ErrorHolder:=MelsecNotAssigned;
END;{xcv}

FUNCTION DataForm(deci:Word;dType:Byte):Str2;
VAR Value : Word;
BEGIN
  The(Value).Lo:=(Deci DIV 100);
  The(Value).Hi:=((Deci-(The(Value).Lo*100)) DIV 10)*16 + (Deci MOD 10);
  The(Value).Lo:=The(Value).Lo*16+(dType and $0F);
  DataForm:=WordStr(Value);
END;{DataForm}

FUNCTION MelsecError;
BEGIN
  MelsecError:=ErrorHolder;
  ErrorHolder:=0;
END;{MelsecError}

PROCEDURE ReadPLCtype(VAR PLCtype:Byte);
BEGIN
  xcv($00,#$06,PLCtype);
END;{ReadPLCtype}

PROCEDURE SetPLCMonitorAddr(nEl:Byte; VAR ElAddr; nReg:Byte; VAR RegAddr);
VAR
  ea,ra : String;
  ad    : word;
  af,i  : Byte;
BEGIN
  IF nEl>120 THEN nEl:=120; { Real limit 144, but restricted by string-length }
  IF nReg>8 THEN nReg:=8;
  MonElements:=nEl; MonRegisters:=nReg; ea:=''; ra:='';
  IF nEl>0 THEN
  FOR i:=0 TO pred(monElements) DO
  BEGIN
    ad:=wArr(ElAddr)[i]; af:=ad div 1000; ad:=ad mod 1000;
    ea:=ea+Octal(ad,af);
  END;
  IF nReg>0 THEN
  FOR i:=0 TO pred(monRegisters) DO
  BEGIN
    ad:=wArr(RegAddr)[i]; af:=ad div 1000; ad:=ad mod 1000;
    ra:=ra+Octal(ad,af);
  END;
  xcv($0B,WordStr(2*nEl)+ea+char((2*nReg) and $FF)+ra,dummy);
END;{SetPLCMonitorAddr}

PROCEDURE MonitorPLC(VAR ElData; VAR RegData);
VAR
  data : ARRAY[0..35] OF Byte;
  bc,bb,bn,i : Byte;
  wrd : Word;
BEGIN
  IF (MonElements<>0) or (MonRegisters<>0) THEN
  BEGIN
    xcv($0C,'',data);
    bc:=(monElements+7) DIV 8;
    IF bc>0 THEN
    FOR i:=0 TO pred(monElements) DO
    BEGIN
      bb:=i div 8; bn:=i mod 8;
      bArr(Eldata)[i]:=Boolean(data[bb] and b2e[bn]) and true;
    END;
    IF monRegisters>0 THEN
    FOR i:=0 TO pred(monRegisters) DO
    BEGIN
      move(data[bc+(i*2)],wrd,2);
      wArr(RegData)[i]:=BCDvalue(wrd);
    END;
  END
   ELSE ErrorHolder:=MelsecMonitorNotSet;
END;{MonitorPLC}

PROCEDURE SwitchElement(Address:Word;Switch:Boolean);
CONST
  OnOff : ARRAY[Boolean] OF Char = (#00,#01);
VAR
  af : Byte;
BEGIN
  af:=address div 1000; address:=address mod 1000;
  xcv($0D,Octal(Address,af)+OnOff[Switch],dummy);
END;{SwitchElement}

PROCEDURE ReadPLCstatus;
BEGIN
  xcv($0F,'',StatusByte);
END;{ReadPLCstatus}

PROCEDURE WritePLCreg(Address,Value:Word);
{ - Write 3 digit decimal value to data register 700 - 777 }
BEGIN
  xcv($14,Octal(Address,1)+DataForm(Value,1),dummy);
END;{WritePLCreg}

PROCEDURE ReadPLCreg(Address:Word; VAR Value:Word);
{ - Read 3 digit decimal value from data register 700 - 777 }
BEGIN
  xcv($15,Octal(Address,0),Value);
  value:=DataValue(value);
END;{ReadPLCreg}

PROCEDURE DecodeProg(VAR Prog:CodeRec);
CONST
  opcodetxt : ARRAY[0..25] OF string[3] =
  ('NOP','RST','SFT','PLS','OUT','ANB','ORB','LDI',
   'ANI','ORI','LD ','AND','OR ','END','Kdp','K  ',
   'CJP','EJP','MC ','MCR','S  ','R  ','STL','RET',
   'F  ','???');
VAR
  i : Byte;
  wc : word;
BEGIN
  WITH Prog DO
  BEGIN
    opcode:=code and $F;
    CASE opCode OF
      $1..$C : BEGIN
                 data:=AddrValue(code);
                 IF (data<>0) and (opCode=$5) THEN OpCode:=$16;
                 IF (data-600 in [70..77]) and (opCode=$4) THEN Opcode:=$18;
               END;
      $0,$D  : BEGIN
                 data:=AddrValue(code);
                 CASE data OF
                    0      : {No changes};
                  100..177 : IF opCode=$0 THEN opCode:=$12 ELSE opcode:=$13;
                  200..377 : IF opCode=$0 THEN opCode:=$14 ELSE opcode:=$15;
                  575      : opcode:=$17; {RET}
                  700..777 : IF opCode=$0 THEN opCode:=$10 ELSE opcode:=$11;
                        ELSE opcode:=$18;
                 END;
               END;
      $E..$F : data:=dataValue(Code);
    END;
    CASE opCode OF
      $0,$5..$6,$D,$17 : mne:='   ';
      $E : str(data/10:3:1,mne);
      $F : str(data:3,mne);
      ELSE BEGIN
             str(data:3,mne);
             FOR i:=1 TO 3 DO IF mne[i]=#32 THEN mne[i]:='0';
           END;
    END;
    mne:=opcodetxt[opcode]+' '+mne;
  END;
END;{DecodeProg}

PROCEDURE ReadPLCProgStep(Step:Word; VAR Prog:CodeRec);
BEGIN
  xcv($09,wordstr(step),Prog.code);
  decodeProg(Prog);
END;{ReadPLCProgStep}

PROCEDURE WritePLCConst(Step:Word;value:Str2);
VAR
  opcode : Byte;
  Prog   : CodeRec;
BEGIN
  ReadPLCProgStep(Step,Prog);
  IF Prog.opCode in [$E,$F] THEN
   xcv($0A,WordStr(Step)+value,dummy)
  ELSE ErrorHolder:=MelsecNotConstant;
END;{WritePLCconst}

PROCEDURE ConnectPLC(Com:ComPorts;Speed:ComSpeed);
BEGIN
  ComPortNr:=Com;
  InverseRTS:=True;
  InverseDTR:=True;
  cOpen(ComPortNr,512,Speed,8,pEven,1);
  DTR(ComPortNr,True);
  ErrorHolder:=MelsecNoError;
END;{ConnectPLC}

PROCEDURE DisconnectPLC;
BEGIN
  InverseRTS:=False;
  InverseDTR:=False;
  DTR(ComPortNr,False);
  cClose(ComPortNr);
  ComPortNr:=0;
END;{DisConnectPLC}

BEGIN {Init Unit Fseries}
  Units.Enter(FseriesMsg,MemAvail,CSeg);
  ErrorHolder:=MelsecNoError; MonElements:=0; MonRegisters:=0;
END.

