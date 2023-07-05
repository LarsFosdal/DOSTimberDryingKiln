{$I CODEDEFS.PAS} {Include code generation definitions}
{$O-} {Overlaying not allowed}

UNIT LFcomm; {.4 (c) 19880926 Lars Fosdal }

{ This TP4 Unit supports Com1 and Com2 with a few simple routines...
  ...the receive routine is interruptdriven and buffers input.

  Related info can be found in :

    "Product Handbook", Western Digital '81
      Section 1  : "WD8250 Asynchronous Communications Element"

    "Intel Microsystems Components Handbook", Intel '86
      Pages 2-95 ..2-132 : "8259A Programmable Interrupt Controller"
      Pages 2-144..2-181 : Application Note "Using the 8259A"

    "Advanced Techniques in Turbo Pascal", Charles C.Edwards, SYBEX '87
      Pages 220..233 : "Data Communications".

    BYTE magazine Vol.12/#12 : "Inside the IBM PC's"
      Pages 173..180 : "IBM PC Family BIOS Comparison" by Jon Shiell.

    "Advanced MSDOS", Ray Duncan, MicroSoft Press '86
      Reading the whole book is recommended !!!

    and in your TP4,TP5,TP55,TP60 Owner's handbooks.
}

INTERFACE USES Dos,Crt,LFsystem;

CONST
  Com1         = 1;
  Com2         = 2;
  Ready        = true;
  NotReady     = false;
  NoError      = 0;
  AlreadyOpen  = 1;
  AlreadyClosed= 2;
  NotOpen      = 3;

TYPE
  ComSpeed  = 110..38400;
  ComDbits  = 7..8;
  ComSbits  = 1..2;
  ComPorts  = 1..2;
  ComParity = (pNone,pOdd,pMark,pEven,pSpace);

VAR
  LFcommSpeed  : ARRAY[ComPorts] OF ComSpeed;
  LFcommDbits  : ARRAY[ComPorts] OF ComDbits;
  LFcommSbits  : ARRAY[ComPorts] OF ComSbits;
  LFcommParity : ARRAY[ComPorts] OF ComParity;
  InverseRTS,
  InverseDTR   : Boolean;

FUNCTION ComError:word;
FUNCTION Received(Com:ComPorts):boolean;
FUNCTION cRead(Com:ComPorts):char;
FUNCTION RBused(Com:ComPorts):Word;
PROCEDURE ResetRB(Com:ComPorts);
PROCEDURE cProtocol(Com : ComPorts;  speed : ComSpeed;
                    databits : ComDbits;  parity : ComParity;
                    stopbits:ComSbits);
PROCEDURE cOpen(Com : ComPorts;  RBsize : Word;
                speed : ComSpeed;  databits : ComDbits;
                parity : ComParity;  stopbits : ComSbits);
PROCEDURE DTR(Com:ComPorts; state:boolean);
PROCEDURE RTS(Com:ComPorts; state:boolean);
PROCEDURE cBreak(Com:ComPorts);
PROCEDURE cWrite(Com:ComPorts; msg:String);
PROCEDURE cClose(Com:ComPorts);


IMPLEMENTATION


CONST
  LFcommMsg = ' LFcomm.4 19880926 Lars Fosdal ';

  {--Interrupt consts-}
  imr8259       = $21;
  eoi8259       = $20;
  EOI           = $20;
  iComNo    : ARRAY[ComPorts] OF byte =($0C,$0B);
  irqCom    : ARRAY[ComPorts] OF byte =($EF,$F7);

  {---UART registers-}
  Data      : ARRAY[ComPorts] OF word = ($3F8,$2F8);
  iEnable   : ARRAY[ComPorts] OF word = ($3F9,$2F9);
  iIdentify : ARRAY[ComPorts] OF word = ($3FA,$2FA);
  LineCtrl  : ARRAY[ComPorts] OF word = ($3FB,$2FB);
  LineStat  : ARRAY[ComPorts] OF word = ($3FD,$2FD);
  ModemCtrl : ARRAY[ComPorts] OF word = ($3FC,$2FC);
  ModemStat : ARRAY[ComPorts] OF word = ($3FE,$2FE);
  Reserved  : ARRAY[ComPorts] OF word = ($3FF,$2FF);

  {--Interupt Enable-}
  InterruptsOff = $00;
  DataReceived  = $01;
  ReadyToSend   = $02;
  LineStatChng  = $04;
  ModemStatChng = $08;
  {Bits 4..7 not used}

  {---Line Status----}
  DataRecvReady = $01;
  OverRunError  = $02;
  ParityError   = $04;
  FramingError  = $08;
  BreakDetected = $10;
  XmitHoldEmpty = $20;
  XmitShftEmpty = $40;
  {bit 7 always zero }

  {---Line Control---}
  {Bits 0..1 : #DataBits : 0=5, 1=6, 2=7, 3=8 }
  {Bit 2     : #StopBits : 0=1, 1=2 }
  {Bit 3     : Enable Parity}
  {Bit 4     : 0=Odd/Space, 1=Even/Mark}
  {Bit 5     : Select Mark/Space Parity}
  GenerateBreak = $40;
  DivisorLatch  = $80;

  {---Modem Status---}
  deltaCTS      = $01;
  deltaDSR      = $02;
  TrailEdgeRI   = $04;
  deltaCD       = $08;
  _CTS_         = $10;
  _DSR_         = $20;
  _RI_          = $40;
  _CD_          = $80;

  {---Modem Control--}
  _DTR_         = $01;
  _RTS_         = $02;
  Out1          = $04;
  Out2          = $08;
  LoopBackTest  = $10;
  {bits 5..7 not used}

TYPE
  ComBuffer = ARRAY[1..65535] OF byte;
  ComStat   = (Closed,Open);
VAR
  rcvdBS,
  stRcvd,
  eoRcvd    : Array[ComPorts] OF word;
  Rcvd      : Array[ComPorts] OF ^ComBuffer;
  OldVec    : Array[ComPorts] OF Pointer;
  Status    : ARRAY[ComPorts] OF ComStat;
  cno       : Comports;
  ErrorCom  : Byte;

PROCEDURE iHandler1(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP : word);
 Interrupt;
BEGIN
{ sti;}
  Rcvd[Com1]^[eoRcvd[Com1]] := Port[Data[Com1]];
  IF eoRcvd[Com1]<RcvdBS[Com1]
  THEN inc(eoRcvd[Com1])
  ELSE eoRcvd[Com1] := 1;
{ cli;}
  Port[eoi8259] := EOI;
END; {PROC iHandler1}

PROCEDURE iHandler2(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP : word);
 Interrupt;
BEGIN
{ sti;}
  Rcvd[Com2]^[eoRcvd[Com2]] := Port[Data[Com2]];
  IF eoRcvd[Com2]<RcvdBS[Com2]
  THEN inc(eoRcvd[Com2])
  ELSE eoRcvd[Com2] := 1;
{ cli;}
  Port[eoi8259] := EOI;
END; {PROC iHandler2}

PROCEDURE DTR(Com:ComPorts; State:Boolean);
VAR
  onOff,pval : Byte;
BEGIN
  pval := Port[ModemCtrl[com]];
  CASE InverseDTR xor state OF
    False : pval := pval and not _DTR_;
    True  : pval := pval or _DTR_;
  END;
  Port[ModemCtrl[com]] := pval;
END; {PROC DTR}

PROCEDURE RTS(Com:ComPorts; State:Boolean);
VAR
 pval : Byte;
BEGIN
  pval := Port[ModemCtrl[com]];
  CASE InverseRTS xor state OF
    False : pval := pval and not _RTS_;
    True  : pval := pval or _RTS_;
  END;
  Port[ModemCtrl[com]] := pval;
END; {PROC RTS}

PROCEDURE cBreak(Com:ComPorts);
VAR
  asBefore : byte;
BEGIN
  IF Status[Com]=Open THEN
  BEGIN
    asbefore := port[LineCtrl[Com]]; delay(10);
    port[LineCtrl[Com]] := asBefore or GenerateBreak;
    delay(200);
    port[LineCtrl[Com]] := asBefore;
    ErrorCom := NoError;
  END
   ELSE ErrorCom := NotOpen;
END; {PROC cBreak}


PROCEDURE cProtocol(Com : ComPorts;  speed : ComSpeed;
                    databits : ComDbits;  parity : ComParity;
                    stopbits : ComSbits);
VAR
  rate : word;
  pval : byte;
BEGIN
  IF Status[Com]=Open THEN
  BEGIN
    cli;
    rate := 115200 div speed;
    pval := port[LineCtrl[Com]]; delay(10);
    port[LineCtrl[Com]] := pval or DivisorLatch; delay(10);
    port[Data[Com]]     := lo(rate); delay(10);
    port[iEnable[Com]]  := hi(rate); delay(10);
    pval := port[LineCtrl[Com]]; delay(10);
    port[LineCtrl[Com]] := pval xor DivisorLatch; delay(10);
    port[LineCtrl[Com]] := (databits-5)
                              +((stopBits-1) shl 2)
                              +(ord(parity) shl 3);
    sti;
    LFcommSpeed[com] := Speed;
    LFcommDbits[com] := Databits;
    LFcommSbits[com] := StopBits;
    LFcommParity[com] := Parity;
    ErrorCom := NoError;
  END
   ELSE ErrorCom := NotOpen;
END; {PROC cProtocol}

PROCEDURE cOpen(Com : ComPorts;  RBsize : Word;
                speed : ComSpeed;  databits : ComDbits;
                parity : ComParity;  stopbits : ComSbits);
VAR
  pval : byte;
BEGIN
  IF Status[Com]=Closed THEN
  BEGIN
    CASE Com OF
      Com1 : SetIntVec(iComNo[Com1],@iHandler1);
      Com2 : SetIntVec(iComNo[Com2],@iHandler2);
    END;
    RcvdBS[com] := RBSize; GetMem(rcvd[com],RcvdBS[com]);
    Status[Com] := Open;
    cProtocol(Com,speed,databits,parity,stopbits);
    cli;
    pval := port[imr8259]; delay(10);
    port[imr8259] := pval and IrqCom[Com]; delay(10);
    pval := port[LineCtrl[Com]]; delay(10);
    port[LineCtrl[Com]] := pval and $7F; delay(10);
    port[iEnable[Com]] := DataReceived; delay(10);
    pval := port[ModemCtrl[Com]]; delay(10);
    Port[ModemCtrl[Com]] := pval OR (Out2);
    pval := Port[LineStat[Com]];
    ResetRB(Com);
    sti;
    ErrorCom := NoError;
    DTR(Com,True);
  END
   ELSE
  BEGIN
    cProtocol(Com,speed,databits,parity,stopbits);
    ErrorCom := AlreadyOpen;
  END;
END; {PROC cOpen}

PROCEDURE cClose(Com:ComPorts);
BEGIN
  IF Status[Com]=Open THEN
  BEGIN
    cli;
    port[imr8259] := port[imr8259] or $18;
    port[LineCtrl[Com]] := port[LineCtrl[Com]] and $7F;
    port[iEnable[Com]] := InterruptsOff;
    port[ModemCtrl[Com]] := 0;
    sti;
    SetIntVec(iComNo[Com],OldVec[Com]);
    FreeMem(Rcvd[com],RcvdBS[com]); RcvdBS[com] := 1;
    Status[Com] := Closed;
    ErrorCom := NoError;
  END ELSE ErrorCom := AlreadyClosed;
END; {PROC cClose}

PROCEDURE ResetRB(Com:ComPorts);
BEGIN
  stRcvd[Com] := 1;
  eoRcvd[Com] := 1;
END; {PROC ResetRB}

FUNCTION Received(Com:ComPorts):Boolean;
BEGIN
  IF Status[Com]=Open THEN
  BEGIN
    Received := stRcvd[Com]<>eoRcvd[Com];
    ErrorCom := NoError;
  END
   ELSE
  BEGIN
    Received := False;
    ErrorCom := NotOpen;
  END;
END; {FUNC Received}

FUNCTION RBused(Com:ComPorts):Word;
BEGIN
  IF eoRcvd[Com]<stRcvd[Com] THEN
   RBused := RcvdBS[Com]-stRcvd[Com]+eoRcvd[Com]
    ELSE RBused := eoRcvd[Com]-stRcvd[Com];
END; {FUNC RBused}

FUNCTION cRead(Com:ComPorts):Char;
BEGIN
  IF Status[Com]=Open THEN
  BEGIN
    CLI;
    cRead := chr(Rcvd[Com]^[stRcvd[Com]]);
    IF stRcvd[Com]<RcvdBS[Com] THEN inc(stRcvd[Com])
     ELSE stRcvd[Com] := 1;
    STI;
    ErrorCom := NoError;
  END
   ELSE
  BEGIN
    cRead := #0;
    ErrorCom := NotOpen;
  END;
END; {FUNC cRead}

PROCEDURE cWrite(Com:ComPorts; msg:String);
VAR
  n : byte;
  HoldOK,DsrCtsOK : Boolean;
BEGIN
  IF Status[Com]=Open THEN
  BEGIN
    RTS(Com,True);
    FOR n := 1 to length(msg) DO
    BEGIN
      REPEAT
        HoldOK := Port[LineStat[Com]] and xmitHoldEmpty = xmitHoldEmpty;
        {DsrCtsOK := Port[ModemStat[Com]] and (_DSR_+_CTS_) = _DSR_+_CTS_;}
      UNTIL HoldOK { and DsrCtsOK};
      Port[Data[Com]] := byte(msg[n]);
    END;
    RTS(Com,False);
    ErrorCom := NoError;
  END
   ELSE ErrorCom := NotOpen;
END; {PROC cWrite}

FUNCTION ComError;
BEGIN
  ComError := ErrorCom;
  ErrorCom := 0;
END; {FUNC ComError}

BEGIN {Initialisation part of Unit LFcomm}
  Units.Enter(LFcommMsg,MemAvail,CSeg);
  InverseRTS := False;
  InverseDTR := False;
  FOR cno := Com1 to Com2 DO
  BEGIN
    GetIntVec(iComNo[cno],OldVec[cno]);
    Status[cno] := Closed;
    RcvdBS[cno] := 1;
  END;
  ErrorCom := 0;
END.
