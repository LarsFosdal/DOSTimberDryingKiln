{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT LFdos; {.1 (c) 19880719  Lars Fosdal }

INTERFACE
USES
  Dos;

CONST

  DaysInMonth : ARRAY[1..12] OF Byte = (31,28,31,30,31,30,31,31,30,31,30,31);
  DaysInYear  : Word = 365;

{ a Year     :    12             (12)   Months
                  52             (52)   Weeks
                 365            (366)   Days
                8760           (8784)   Hours
              525600         (527040)   Minutes
            31536000       (31622400)   Seconds

  a Day      :    24 Hours
                1440 Minutes
               86400 Seconds

}
TYPE
  TimerRec   = RECORD
                 RealDate : DateTime;
                 Hundreds : Word;
               END;
  CountryRec = RECORD
                 Code          : Word;
                 DateFormat    : Word;
                 DateSep       : Char;
                 TimeSep       : Char;
                 TimeFormat    : Byte;
                 MoneySymbol   : String[6];
                 MoneyFormat   : Byte;
                 ThousandSep   : Char;
                 DecimalPoint  : Char;
                 DecimalDigits : Byte;
                 DataListSep   : Char;
                 CaseMap       : Pointer;
               END;
  TimeProc = PROCEDURE(VAR HourYear,MinuteMonth,SecDay,HundredsDayofWeek:Word);
VAR
  Country   : CountryRec;
  DosVer    : Real;
VAR
  TimeNow   : Word;
VAR
  ExamineTime : TimeProc;
  ExamineDate : TimeProc;

FUNCTION  unASCIIZ(VAR asciiz):String;
PROCEDURE ZeroSpaces(VAR st:String);
FUNCTION  currentDir:String;
FUNCTION  FreeDiskSpace(Disk:Char):LongInt;
PROCEDURE DiskInfo(Disk:char);
FUNCTION  LastDrive:Char;
FUNCTION  FoundFile(FilePathAndName:string):Boolean;
PROCEDURE DeleteFile(FilePathAndName:string);
FUNCTION  SizeOfFile(FilePathAndName:string):LongInt;

PROCEDURE DirectTime(VAR Hour,Min,Sec,Hun:Word);
PROCEDURE CMosTime(VAR Hour,Min,Sec,dummy:Word);
PROCEDURE CMosDate(VAR Year,Month,Day,DayOfWeek:Word);
FUNCTION  TimeHasGoneBy:boolean;
FUNCTION  Time:String;
FUNCTION  Date:String;
PROCEDURE FixLeapYear(year:word);
FUNCTION  LookWatch(Started:DateTime):String;
FUNCTION  LookDate(Started:DateTime):String;
FUNCTION  FullWatch(Started:DateTime):String;
FUNCTION  MILWatch(Started:DateTime):String;
PROCEDURE StartWatch(VAR Started:DateTime);
FUNCTION  StopWatch(Started:DateTime):String;
FUNCTION  SecondsBetween(Started,Stopped:DateTime):LongInt;
FUNCTION  SecondsSince(Started:DateTime):LongInt;
FUNCTION  MinutesSince(Started:DateTime):LongInt;
FUNCTION  HoursSince(Started:DateTime):LongInt;
FUNCTION  TimeTo(Started:DateTime; Hours:Integer):String;
PROCEDURE DecDays(VAR When:DateTime; Days:Word);
PROCEDURE DecSeconds(VAR When:DateTime; Seconds:LongInt);
PROCEDURE IncDays(VAR When:DateTime; Days:Word);
PROCEDURE IncSeconds(VAR When:DateTime; Seconds:LongInt);
FUNCTION  SecToMidnight(When:DateTime):LongInt;
FUNCTION  SecSinceMidnight(When:DateTime):LongInt;

VAR
  SimDateTime : DateTime;
PROCEDURE InstallSimTime;
PROCEDURE RestoreNormTime;
PROCEDURE SimTime(VAR Hour,Min,Sec,zero:Word);
PROCEDURE SimDate(VAR Year,Month,Day,DayOfWeek:Word);
PROCEDURE IncrementSimTime(Secs:LongInt);

{////////////////////////////////////////////////////////////////////////////}
{////////////////////////////////////////////////////////////////////////////}
{////////////////////////////////////////////////////////////////////////////}

IMPLEMENTATION

USES LFsystem,LFString;

CONST
  LFdosMsg = ' LFdos.1 19890326 Lars Fosdal ';

FUNCTION unASCIIZ(VAR asciiz):String;
VAR
  Streng : String;
  lengde : byte;
BEGIN
  move(asciiz, Streng[1],80);
  Lengde:=0;
  While (Streng[Lengde+1]<>#0) and (lengde<79) DO Inc(lengde);
  Streng[0]:=chr(lengde);
  unASCIIZ:=Streng;
END;{unASCIIZ}

PROCEDURE ZeroSpaces(VAR st:String);
VAR
  i : Byte;
BEGIN
  FOR i:=1 TO length(st)
  DO IF st[i]=#32 THEN st[i]:='0';
END;{ZeroSpaces}

FUNCTION currentDir:String;
VAR
  regs : Registers;
  Buffer : ARRAY[1..65] OF byte;
  DiskDrive : integer;
BEGIN
  WITH regs DO
  BEGIN
    ax := $1900;
    MsDos(Regs);
    DiskDrive := ax mod 256;
    ax := $4700;
    dx := 0;
    ds := seg(buffer);
    si := ofs(buffer);
  END;
  MSDos(regs);
  CurrentDir:=chr(DiskDrive+65)+':\'+unASCIIZ(buffer);
END; {CurrentDir}

FUNCTION FreeDiskSpace(Disk:Char):LongInt;
VAR
  regs : Registers;
  DriveCode : byte;
  BytesSector, SectorsCluster, ClustersAvail : integer;
BEGIN
  IF disk = '*' THEN DriveCode:=0 ELSE DriveCode:=Ord(upcase(disk))-64;
  WITH regs DO
  BEGIN
    ax:=$3600;
    dx:=DriveCode;
    MsDos(regs);
    SectorsCluster:=ax;
    ClustersAvail:=bx;
    BytesSector:=cx;
  END;
  FreeDiskSpace:=BytesSector*SectorsCluster*ClustersAvail;
END; {FreeDiskSpace}

PROCEDURE DiskInfo(Disk:char);
VAR
  regs : Registers;
  DriveCode, FatID : byte;
  BytesSector, SectorsCluster, ClustersTot,
  SegFatID, OfsFatID : integer;
  DiskSize : real;
  DiskType : String;
BEGIN
  IF disk = '*' THEN DriveCode:=0 ELSE DriveCode:=Ord(upcase(disk))-64;
  WITH regs DO
  BEGIN
    ax:=$1C00;
    dx:=DriveCode;
    MsDos(regs);
    SectorsCluster:=ax MOD 256; DriveCode:= ax DIV 256;
    BytesSector:=cx;
    ClustersTot:=dx;
    SegFatID:=ds;
    OfsFatID:=bx;
  END;
  FatID:=Mem[SegFatID:OfsFatID];
  CASE FatID OF
      $F8 : DiskType:='Fixed Disk';
      $F9 : DiskType:='DS/HD Floppy 15sec';
      $FC : DiskType:='SS/DD Floppy 9sec';
      $FD : DiskType:='DS/DD Floppy 9sec';
      $FE : DiskType:='SS/SD Floppy 8sec';
      $FF : DiskType:='DS/SD Floppy 8sec';
       ELSE DiskType:='Unknown DiskType';
  END;
  DiskSize:=1.0*BytesSector*SectorsCluster*ClustersTot;
  Writeln(DiskType,' - Capacity : ',DiskSize:0:0,' bytes');
END; {DiskInfo}

FUNCTION LastDrive:Char;
VAR
  regs  : Registers;
  Drive : byte;
BEGIN
  WITH regs DO
  BEGIN
    ax:=$1900;
    MsDos(regs);
    Drive:= ax mod 256;
    ax:=$0E00;
    dx:=Drive;
    MsDos(regs);
    Drive := ax MOD 256;
  END;
  LastDrive:=chr(Drive+64);
END; {LastDrive}

FUNCTION DosVersion:Real;
VAR
  regs : Registers;
BEGIN
  regs.ax:=$3000;
  MsDos(regs);
  DosVersion:=Regs.AL+Regs.AH/100;
END; {DosVersion}

PROCEDURE CountryInfo(VAR Country:CountryRec);
VAR
  regs : Registers;
  Buffer : ARRAY[0..33] OF byte;
BEGIN
  regs.ax := $3800;
  regs.ds := seg(buffer);
  regs.dx := ofs(buffer);
  MSDos(regs);
  WITH Country DO
  BEGIN
    Code:=Regs.BX;
    DateFormat:=Word(Buffer[0]);
    DateSep:=Char(Buffer[11]);
    TimeSep:=Char(Buffer[13]);
    TimeFormat:=Buffer[17];
{    MoneySymbol:=UnASCIIZ(Buffer[2]);}
    MoneyFormat:=Buffer[15];
    ThousandSep:=Char(Buffer[7]);
    DecimalPoint:=Char(Buffer[9]);
    DecimalDigits:=Buffer[16];
    DataListSep:=Char(Buffer[22]);
    CaseMap:=Ptr(Word(Buffer[18]),Word(Buffer[20]));
  END;
END; {CountryInfo}

FUNCTION DiskControllerStat:Byte;
VAR
  regs:Registers;
BEGIN
  regs.ax :=$0100;
  Intr($13,regs);
  DiskControllerStat:=regs.ah;
END;

FUNCTION FoundFile(FilePathAndName:String):Boolean;
VAR
  chk : File;
  xst : Boolean;
BEGIN
{$IFNDEF NoDisk}
  {$I-}
  assign(chk,FilePathAndName);
  reset(chk);
  xst:=IOresult=0;
  IF xst THEN Close(chk);
  FoundFile:=xst;
{$ELSE}
  FoundFile:=False;
{$ENDIF}
END;{FoundFile}

PROCEDURE DeleteFile(FilePathAndName:String);
VAR
  chk : File;
BEGIN
{$IFNDEF NoDisk}
  {$I-}
  assign(chk,FilePathAndName);
  Erase(chk);
{$ENDIF}
END;{DeleteFile}

FUNCTION SizeOfFile(FilePathAndName:string):LongInt;
VAR
  FileInfo : SearchRec;
BEGIN
  FindFirst(FilePathAndName,AnyFile,FileInfo);
  IF DosError=0 THEN SizeOfFile:=FileInfo.Size ELSE SizeOfFile:=-1;
END;{SizeOfFile}

PROCEDURE CMOSwrite(Addr,Value:Byte);
BEGIN
  Port[$71]:=Addr;
  Addr:=Addr DIV 3; {delay}
  Port[$70]:=Value;
END;{PROC CMOSwrite}

PROCEDURE CMOSread(Addr:Byte;VAR Value:Byte);
BEGIN
  Port[$71]:=Addr;
  Value:=Value DIV 3; {delay}
  Value:=Port[$70];
END;{PROC CMOSread}

{$F+}
PROCEDURE DirectTime(VAR Hour,Min,Sec,Hun:Word);
VAR
  AbsClock : LongInt absolute $0:$046C;
  Clk : LongInt;
BEGIN
  Clk:=AbsClock;
  Hour:=Clk DIV $10007;
  Clk:=Clk MOD $10007;
  Min:=Clk DIV $444;
  Clk:=Clk MOD $444;
  Sec:=Round(Clk/18.21);
  Hun:=0;
END;{DirectTime}

PROCEDURE CMosTime(VAR Hour,Min,Sec,dummy:Word);
VAR
  b : Byte;
BEGIN
  dummy:=0;
  CMOSread(0,b); Sec:=((b SHR 4)*10)+b and $0F;
  CMOSread(2,b); Min:=((b SHR 4)*10)+b and $0F;
  CMOSread(4,b); Hour:=((b SHR 4)*10)+b and $0F;
END;{PROC CMosTime}

PROCEDURE CMosDate(VAR Year,Month,Day,DayOfWeek:Word);
VAR
  b : Byte;
BEGIN
  CMOSread(6,b); DayOfWeek:=(b and $0F)-1;
  CMOSread(7,b); Day:=((b SHR 4)*10)+b and $0F;
  CMOSread(8,b); Month:=((b SHR 4)*10)+b and $0F;
  CMOSread(9,b); Year:=((b SHR 4)*10)+b and $0F;
  IF Year<80 THEN Year:=Year+2000 ELSE Year:=Year+1900;
END;{PROC CMosDate}


FUNCTION TimeHasGoneBy:Boolean;
CONST
  LastTime:Word=0;
VAR
  regs : Registers;
  d,TimeNow : Word;
BEGIN
  ExamineTime(d,TimeNow,d,d);
  TimeHasGoneBy := (TimeNow<>LastTime);
  LastTime:=TimeNow;
END;{TimeHasGoneBy}

FUNCTION Time;
VAR
  st1,st2 : string[8];
  h,m,d   : Word;
BEGIN
  ExamineTime(h,m,d,d);
  str(h:2,st1);
  str(m:2,st2);
  st1:=st1+Country.TimeSep+st2;
  ZeroSpaces(st1);
  time:=st1;
END;{Time}

VAR
  st1,st2 : string[8];
  y,dm,m,d   : Word;

FUNCTION Date;
BEGIN
  ExamineDate(y,m,d,dm);
  str(d:2,st1);
  str(m:2,st2); st1:=st1+Country.DateSep+st2+Country.DateSep;
  str(y mod 100:2,st2); st1:=st1+st2;
  ZeroSpaces(st1);
  date:=st1;
END;{Date}

FUNCTION IsLeapYear(Year:Word):Boolean;
BEGIN
  IsLeapYear:=(Year MOD 4=0) and (Year MOD 4000<>0)
          and ((Year mod 100<>0) or (Year MOD 400=0));
END; {FUNC IsLeapYear}

PROCEDURE FixLeapYear(Year:Word);
BEGIN
  IF IsLeapYear(Year)
  THEN BEGIN
    DaysInMonth[2]:=29;
    DaysInYear:=366;
  END
  ELSE BEGIN
    DaysInMonth[2]:=28;
    DaysInYear:=365;
  END;
END;{FixLeapYear}

FUNCTION LookWatch(Started:DateTime):String;
{ dd/mm hh.mm}
VAR
  st1,st2 : String;
  n       : byte;
BEGIN
  WITH Started DO
  BEGIN
    str(day:2,st1);
    str(month:2,st2); st1:=st1+'/'+st2;
    str(hour:2,st2); st1:=st1+#0+st2;
    str(min:2,st2); st1:=st1+'.'+st2;
  END;
  LookWatch:=SwapAll(#0,#32,SwapAll(#32,'0',st1));
END;{LookWatch}

FUNCTION LookDate(Started:DateTime):String;
{ dd/mm }
VAR
  st1,st2 : String;
BEGIN
  WITH Started DO
  BEGIN
    str(day:2,st1);
    str(month:2,st2); st1:=st1+'/'+st2;
  END;
  ZeroSpaces(st1);
  LookDate:=st1;
END; {FUNC LookDate}

FUNCTION FullWatch(Started:DateTime):String;
{ yyyy/mm/dd hh.mm.ss }
VAR
  st1,st2 : String;
  n       : byte;
BEGIN
  WITH Started DO
  BEGIN
    str(year:4,st1);
    str(month:2,st2); st1:=st1+'/'+st2;
    str(day:2,st2); st1:=st1+'/'+st2;
    str(hour:2,st2); st1:=st1+#254+st2;
    str(min:2,st2); st1:=st1+'.'+st2;
    str(sec:2,st2); st1:=st1+'.'+st2;
  END;
  ZeroSpaces(st1);
  FullWatch:=st1;
END;{FullWatch}

FUNCTION MILWatch(Started:DateTime):String;
{ yymmdd hh.mm.ss }
VAR
  st1,st2 : String;
  n       : byte;
BEGIN
  WITH Started DO
  BEGIN
    str(year:4,st1);
    str(month:2,st2); st1:=Copy(st1,3,2)+st2;
    str(day:2,st2); st1:=st1+st2+#0;
    str(hour:2,st2); st1:=st1+st2;
    str(min:2,st2); st1:=st1+'.'+st2;
    str(sec:2,st2); st1:=st1+'.'+st2;
  END;
  ZeroSpaces(st1);
  st1:=SwapAll(#0,#32,st1);
  MILWatch:=st1;
END;{MILWatch}

PROCEDURE StartWatch;
VAR
  dummy : word;
BEGIN
  WITH Started DO
  BEGIN
    ExamineTime(Hour,Min,Sec,Dummy);
    ExamineDate(Year,Month,Day,Dummy);
  END;
END;{StartWatch}

FUNCTION StopWatch;
VAR
  Stopped : DateTime;
  st1     : String;
  st2     : String;
  days,hours,minutes,seconds : Word;
BEGIN
  StartWatch(Stopped);
  FixLeapYear(Stopped.Year);
  IF Stopped.day<started.day THEN
   days:=DaysInMonth[Started.month]-Started.Day+Stopped.Day
    ELSE days:=Stopped.Day-Started.Day;
  IF Stopped.Hour<Started.hour THEN
  BEGIN
    days:=days-1;
    hours:=24-Started.hour+Stopped.hour;
  END
   ELSE hours:=Stopped.hour-Started.hour;
  IF Stopped.min<Started.min THEN
  BEGIN
    hours:=hours-1;
    minutes:=60-Started.min+Stopped.min;
  END
   ELSE minutes:=Stopped.min-Started.min;
  IF Stopped.sec<Started.sec THEN
  BEGIN
    minutes:=minutes-1;
    seconds:=60-Started.sec+Stopped.sec;
  END
   ELSE Seconds:=Stopped.sec-Started.sec;
  IF not ((Days>1000) or (Hours>23) or (minutes>59) or (seconds>59)) THEN
  BEGIN
    str(Days:2,st1);
    str(hours:2,st2);   st1:=st1+'/'+st2;
    str(minutes:2,st2); st1:=st1+'.'+st2;
    str(seconds:2,st2); st1:=st1+'.'+st2;
    ZeroSpaces(st1);
  END ELSE st1:='00/00.00.00';
  StopWatch:=st1;
END;{StopWatch}


FUNCTION SecondsBetween(Started,Stopped:DateTime):LongInt;
VAR
  days : Integer;
  stp,sta : LongInt;
BEGIN
  FixLeapYear(Stopped.Year);
  IF Stopped.day<started.day THEN
   days:=DaysInMonth[Started.month]-Started.Day+Stopped.Day
    ELSE days:=Stopped.Day-Started.Day;
  stp:=LongInt(Stopped.Hour)*3600
      +LongInt(Stopped.min)*60
      +LongInt(Stopped.sec);
  sta:=LongInt(Started.Hour)*3600
      +LongInt(Started.min)*60
      +LongInt(Started.sec);
  IF stp<sta
  THEN Dec(days);
  SecondsBetween:=(Days*86400)+(((stp-sta)+86400) MOD 86400);
END;{SecondsBetween}

FUNCTION SecondsSince(Started:DateTime):LongInt;
VAR
  Stopped : DateTime;
BEGIN
  StartWatch(Stopped);
  SecondsSince:=SecondsBetween(Started,Stopped);
END; {FUNC SecondsSince}

FUNCTION MinutesSince(Started:DateTime):LongInt;
BEGIN
  MinutesSince:=SecondsSince(Started) DIV 60;
END; {FUNC MinutesSince}

FUNCTION HoursSince(Started:DateTime):LongInt;
BEGIN
  HoursSince:=SecondsSince(Started) DIV 3600;
END; {FUNC HoursSince}


PROCEDURE DecDays(VAR When:DateTime; Days:Word);
{ - Subtract <Days> days from <When>, giving a new date }
VAR
  maxd : Word;
BEGIN
  FixLeapYear(When.Year);
  WITH When DO
  REPEAT
    IF Days>=Day
    THEN BEGIN
      Dec(Days,Day);
      Dec(Month);
      IF Month=0
      THEN BEGIN
        Dec(Year);
        FixLeapYear(Year);
        Month:=12;
      END;
      Day:=DaysInMonth[Month];
    END
    ELSE BEGIN
      Dec(Day,Days);
      Days:=0;
    END;
  UNTIL Days=0;
END; {PROC DecDays}

PROCEDURE DecSeconds(VAR When:DateTime; Seconds:LongInt);
VAR
 d,h,m,s : LongInt;
BEGIN
  s:=Seconds MOD 60;
  Seconds := Seconds DIV 60;
  m:=Seconds MOD 60;
  Seconds:=Seconds DIV 60;
  h:=Seconds MOD 24;
  d:=Seconds DIV 24;
  WITH When DO
  BEGIN
    Dec(Sec,s); IF Sec>60
    THEN BEGIN
      Inc(Sec,60); Inc(m);
    END;
    Dec(Min,m); IF Min>60
    THEN BEGIN
      Inc(Min,60); Inc(h);
    END;
    Dec(Hour,h); IF Hour>23
    THEN BEGIN
      Inc(Hour,24); Inc(d);
    END;
  END;
  DecDays(When,d);
END; {PROC DecSeconds}

PROCEDURE IncDays(VAR When:DateTime; Days:Word);
{ - Add <Days> days to <When>, giving a new date }
VAR
  maxd,dd : Word;
BEGIN
  FixLeapYear(When.Year);
  WITH When DO
  REPEAT
    dd:=DaysInMonth[Month]-Day+1;
    IF Days>=dd
    THEN BEGIN
      Dec(Days,dd);
      Inc(Month);
      Day:=1;
      IF Month>12
      THEN BEGIN
        Inc(Year);
        FixLeapYear(Year);
        Month:=1;
      END;
    END
    ELSE BEGIN
      Inc(Day,Days);
      Days:=0;
    END;
  UNTIL Days=0;
END; {PROC IncDays}

PROCEDURE IncSeconds(VAR When:DateTime; Seconds:LongInt);
VAR
 d,h,m,s : LongInt;
BEGIN
  s:=Seconds MOD 60;
  Seconds := Seconds DIV 60;
  m:=Seconds MOD 60;
  Seconds:=Seconds DIV 60;
  h:=Seconds MOD 24;
  d:=Seconds DIV 24;
  WITH When DO
  BEGIN
    Inc(Sec,s); IF Sec>59
    THEN BEGIN
      Dec(Sec,60); Inc(m);
    END;
    Inc(Min,m); IF Min>59
    THEN BEGIN
      Dec(Min,60); Inc(h);
    END;
    Inc(Hour,h); IF Hour>23
    THEN BEGIN
      Dec(Hour,24); Inc(d);
    END;
  END;
  IncDays(When,d);
END; {PROC IncSeconds}

FUNCTION TimeTo(Started:DateTime; Hours:Integer):String;
VAR
  Ended : DateTime;
  Days  : Integer;
BEGIN
  Ended:=Started;
  IncSeconds(Ended,Hours*3600);
  TimeTo:=LookWatch(Ended);
END; {FUNC TimeTo}

FUNCTION SecToMidnight(When:DateTime):LongInt;
VAR
  MidNight:DateTime;
BEGIN
  MidNight:=When;
  IncDays(MidNight,1);
  WITH MidNight
  DO BEGIN
    Hour:=0; Min:=0; Sec:=0;
  END;
  SecToMidnight:=SecondsBetween(When,MidNight);
END; {FUNC SecToMidnight}

FUNCTION SecSinceMidnight(When:DateTime):LongInt;
VAR
  MidNight:DateTime;
BEGIN
  MidNight:=When;
  WITH MidNight
  DO BEGIN
    Hour:=0; Min:=0; Sec:=0;
  END;
  SecSinceMidnight:=SecondsBetween(MidNight,When);
END; {FUNC SecSinceMidnight}


PROCEDURE InstallSimTime;
{ - }
BEGIN
  StartWatch(SimDateTime);
  ExamineTime:=SimTime;
  ExamineDate:=SimDate;
END; {PROC InstallSimTime}

PROCEDURE RestoreNormTime;
{ - }
BEGIN
  ExamineTime:=GetTime;
  ExamineDate:=GetDate;
END; {PROC RestoreNormTime}

PROCEDURE SimTime(VAR Hour,Min,Sec,zero:Word);
{ - }
BEGIN
  Hour:=SimDateTime.Hour;
  Min:=SimDateTime.Min;
  Sec:=SimDateTime.Sec;
  zero:=0;
END; {PROC SimTime}

PROCEDURE SimDate(VAR Year,Month,Day,DayOfWeek:Word);
{ - }
BEGIN
  Year:=SimDateTime.Year;
  Month:=SimDateTime.Month;
  Day:=SimDateTime.Day;
END; {PROC SimDate}

PROCEDURE IncrementSimTime(Secs:LongInt);
{ - }
BEGIN
  IncSeconds(SimDateTime,Secs);
END; {PROC IncrementSimTime}

VAR
  PrevExitProc : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  Units.Leave(LFdosMsg,MemAvail);
END;

BEGIN {Init LFdos Unit}
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  Units.Enter(LFdosMsg,MemAvail,CSeg);
  RestoreNormTime;
  ExamineTime:=GetTime;
  ExamineDate:=GetDate;
  DosVer:=DosVersion;
  CountryInfo(Country);
END.




