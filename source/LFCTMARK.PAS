{$I CodeDefs.PAS}
{$X+}

UNIT LFCTMark; { Compile-Time Mark }

INTERFACE

PROCEDURE CheckCompileTime;
FUNCTION CompileTimeStr:String;
FUNCTION CompileTime:LongInt;
FUNCTION CTMismatch:Boolean;

IMPLEMENTATION
USES
  DOS, LFSystem, LFString;
TYPE
  table = ARRAY[1..9] OF Byte;
CONST
  StampMatch : Boolean = True;  {True if stamptime matches filetime}
  PackedStampTime : LongInt = 0;
  StampString : String[30] = '';
  tm : table = (18,19,0,12,15,0,0,0,0);
VAR
  ct : table;
  f  : File;
  ft : LongInt;

FUNCTION StampFound(VAR t:LongInt):Boolean;
{ - Check if .exe file has been timestamped }
VAR
  fs : LongInt;
BEGIN
  Writeln('*',IOResult,'*');
  Reset(f,1);
  Writeln('*',IOResult,'*');
  GetFtime(f,ft);
  fs:=FileSize(f);
  Seek(f,fs-9);
  BlockRead(f,ct,9);
  Close(f);
  IF ByteComp(ct,tm,5,5)=0
  THEN BEGIN
    StampFound:=True;
     move(ct[6],t,4);
  END
  ELSE BEGIN
    t:=ft;
    StampFound:=False;
  END;
END; {FUNC StampFound}

PROCEDURE PreStamp;
{ - Append Stamp signature to .exe-file }
VAR
  fs : LongInt;
  w  : Word;
BEGIN
  Reset(f,1);
  fs:=FileSize(f);
  Seek(f,fs+1);
  BlockWrite(f,tm,9);
  Close(f);
END; {PROC PreStamp}

PROCEDURE Stamp(t:LongInt);
{ - Update stamp time in .exe file}
VAR
  fs : LongInt;
BEGIN
  Reset(f,1);
  fs:=FileSize(f);
  Seek(f,fs-4);
  BlockWrite(f,t,4);
  Reset(f);
  SetFTime(f,t);
  Close(f);
END; {PROC Stamp}

PROCEDURE CheckCompileTime;
{ - Read/Stamp .exe file}
VAR
  t  : LongInt;
  ST : DateTime;
BEGIN
  Assign(f,ParamStr(0));
  IF Not StampFound(t)
  THEN BEGIN
    PreStamp;
    Stamp(t);
  END;
  StampMatch:=t=ft;
  PackedStampTime:=t;
  UnpackTime(PackedStampTime,ST);
  StampString:=SwapAll(' ','0',IntStr(ST.Year,2)
                              +IntStr(ST.Month,2)
                              +IntStr(ST.Day,2));
  StampString:=StampString+' '+SwapAll(' ','0',IntStr(ST.Hour,2)+'.'
                                               +IntStr(ST.Min,2));
END; {PROC CheckCompileTime}

FUNCTION CompileTimeStr:String;
{ - Returns Stamp time as YYMMDD HH.MM string }
BEGIN
  CompileTimeStr:=StampString;
END; {FUNC CompileTimeStr}

FUNCTION CompileTime:LongInt;
{ - Returns the StampTime in packed format}
BEGIN
  CompileTime:=PackedStampTime;
END; {FUNC CompileTime}

FUNCTION CTMismatch:Boolean;
{ - Returns true if stamptime and filetime doesn't match}
BEGIN
  CTMismatch:=Not StampMatch;
END; {FUNC CTMismatch}

END.
