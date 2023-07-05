{$I CODEDEFS.PAS} {Include code generation definitions}
{$X+} {Don't overlay this one }

UNIT LFtable; {.1 (c) 19910902 Lars Fosdal }

INTERFACE
USES
  Objects,Dos;
CONST
  LFTableMsg=' LFTable.1 19910902 Lars Fosdal ';

TYPE
  FlagGroup = OBJECT(TObject) { - Boolean flag table }
    OrigTable : LongInt; { Used to store Init-time flagtable }
    FlagTable : LongInt; { Table of Current Flags (max 32) }
    CONSTRUCTOR Init(Flags:LongInt);
    PROCEDURE Enable(Flags:LongInt);
    PROCEDURE Disable(Flags:LongInt);
    PROCEDURE Toggle(Flags:LongInt);
    PROCEDURE Assign(Flags:LongInt; NewState:Boolean);
    PROCEDURE Reset;
    PROCEDURE Clear(NewState:Boolean);
    FUNCTION  isEnabled(Flags:LongInt):Boolean;
    FUNCTION  isDisabled(Flags:LongInt):Boolean;
    FUNCTION  AnyEnabledOf(Flags:LongInt):Boolean;
    FUNCTION  AnyDisabledOf(Flags:LongInt):Boolean;
    FUNCTION  State(Flag:LongInt):Boolean;
    PROCEDURE Save(VAR Flags:LongInt);
    PROCEDURE Restore(Flags:LongInt);
  END; {OBJ FlagGroup}

  PGenSampler = ^GenericSampler;
  GenericSampler = OBJECT(TObject)
    ID         : Word;
    MaxSamples : Integer;          {Maximum number of samples}
    Current    : Integer;          {Current sample point}
    Table      : Pointer;          {Ptr to sampletable}
    CONSTRUCTOR Init(NewID:Word);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);                      VIRTUAL;
    DESTRUCTOR  Done;                                      VIRTUAL;
    FUNCTION    TableSize:Word;                            VIRTUAL;
    PROCEDURE   SetSize(Points:Integer);                   VIRTUAL;
    PROCEDURE   Discard;                                   VIRTUAL;
    PROCEDURE   Reset;                                     VIRTUAL;
    PROCEDURE   Skip(n:LongInt);                           VIRTUAL;
    PROCEDURE   CopyFrom(Sampler:PGenSampler);             VIRTUAL;
    PROCEDURE   Rol(Points:Integer);                       VIRTUAL;
    PROCEDURE   Ror(Points:Integer);                       VIRTUAL;
  END;

  IntSample = Integer;
  PIntSampler = ^IntSampler;
  IntSampler = OBJECT(GenericSampler)
    Min,
    max : IntSample;
    CONSTRUCTOR Init(NewID:Word);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);                      VIRTUAL;
    FUNCTION    TableSize:Word;                            VIRTUAL;
    PROCEDURE   Reset;                                     VIRTUAL;
    PROCEDURE   Rol(Points:Integer);                       VIRTUAL;
    PROCEDURE   Ror(Points:Integer);                       VIRTUAL;
    PROCEDURE   AtPut(Point:Integer; NewSample:IntSample); VIRTUAL;
    FUNCTION    At(Point:Integer):IntSample;               VIRTUAL;
    PROCEDURE   Update(NewSample:IntSample);               VIRTUAL;
    PROCEDURE   Skip(n:LongInt);                           VIRTUAL;
    PROCEDURE   CopyFrom(Sampler:PGenSampler);             VIRTUAL;
    PROCEDURE   AdjSize(NewSize:Integer);
    FUNCTION    Last:IntSample;                            VIRTUAL;
    FUNCTION    Average:IntSample;                         VIRTUAL;
  END; {OBJ IntSampler}

  PAvgIntSampler = ^AvgIntSampler;
  AvgIntSampler = OBJECT(IntSampler)
    MovAvg     : PIntSampler;
    TrigPoint  : Integer;
    Trigger    : Integer;
    QMin,QMax  : IntSample;
    CONSTRUCTOR Init(NewID:Word; NewTrigPoint:Integer (* ; _min,_max:IntSample *) );
    CONSTRUCTOR Load(VAR S:TStream);
    DESTRUCTOR  Done;                                      VIRTUAL;
    PROCEDURE   Store(VAR S:TStream);                      VIRTUAL;
(*    PROCEDURE   SetLimits(_min,_max:Integer);              VIRTUAL; *)
    PROCEDURE   SetSize(Points:Integer);                   VIRTUAL;
    PROCEDURE   Discard;                                   VIRTUAL;
    PROCEDURE   Reset;                                     VIRTUAL;
    PROCEDURE   Update(NewSample:IntSample);               VIRTUAL;
    FUNCTION    Last:IntSample;                            VIRTUAL;
    FUNCTION    Average:IntSample;                         VIRTUAL;
  END;

  PBoolSampler = ^BoolSampler;
  BoolSampler = OBJECT(GenericSampler)
    CONSTRUCTOR Init(NewID:Word);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);                      VIRTUAL;
    FUNCTION    TableSize:Word;                            VIRTUAL;
    PROCEDURE   Rol(Points:Integer);                       VIRTUAL;
    PROCEDURE   Ror(Points:Integer);                       VIRTUAL;
    PROCEDURE   AtPut(Point:Integer; NewSample:Boolean);   VIRTUAL;
    FUNCTION    At(Point:Integer):Boolean;                 VIRTUAL;
    PROCEDURE   Update(NewSample:Boolean);                 VIRTUAL;
    PROCEDURE   Skip(n:LongInt);                           VIRTUAL;
    FUNCTION    Last:Boolean;                              VIRTUAL;
    FUNCTION    Average:Boolean;                           VIRTUAL;
  END; {OBJ BoolSampler}

  PAvgBoolSampler = ^AvgBoolSampler;
  AvgBoolSampler = OBJECT(BoolSampler)
    MovAvg     : PBoolSampler;
    TrigPoint  : Integer;
    Trigger    : Integer;
    CONSTRUCTOR Init(NewID:Word; NewTrigPoint:Integer);
    CONSTRUCTOR Load(VAR S:TStream);
    DESTRUCTOR  Done;                                      VIRTUAL;
    PROCEDURE   Store(VAR S:TStream);                      VIRTUAL;
    PROCEDURE   SetSize(Points:Integer);                   VIRTUAL;
    PROCEDURE   Discard;                                   VIRTUAL;
    PROCEDURE   Reset;                                     VIRTUAL;
    PROCEDURE   Update(NewSample:Boolean);                 VIRTUAL;
    FUNCTION    Last:Boolean;                              VIRTUAL;
    FUNCTION    Average:Boolean;                           VIRTUAL;
  END; {OBJ AvgBoolSampler}


  PHookEntry = ^HookEntry;
  HookEntry = OBJECT(TObject)
    Hook : LongInt;
    CONSTRUCTOR Init(NewHook:LongInt);
  END;

PROCEDURE RegisterIntSamplers;
PROCEDURE RegisterBoolSamplers;

IMPLEMENTATION {#############################################################}
USES           {#############################################################}
  Crt,LFSystem;

CONST
  GenericRgd : Boolean = False;
CONST
  GenericSampler_OID = 9021;
  GenericSampler_OSR: TStreamRec = (
    ObjType: GenericSampler_OID;
    VmtLink: Ofs(TypeOf(GenericSampler)^);
    Load:    @GenericSampler.Load;
    Store:   @GenericSampler.Store
  );

CONST
  IntSampler_OID = 9022;
  IntSampler_OSR: TStreamRec = (
    ObjType: IntSampler_OID;
    VmtLink: Ofs(TypeOf(IntSampler)^);
    Load:    @IntSampler.Load;
    Store:   @IntSampler.Store
  );
CONST
  BoolSampler_OID = 9023;
  BoolSampler_OSR: TStreamRec = (
    ObjType: BoolSampler_OID;
    VmtLink: Ofs(TypeOf(BoolSampler)^);
    Load:    @BoolSampler.Load;
    Store:   @BoolSampler.Store
  );
CONST
  AvgIntSampler_OID = 9024;
  AvgIntSampler_OSR: TStreamRec = (
    ObjType: AvgIntSampler_OID;
    VmtLink: Ofs(TypeOf(AvgIntSampler)^);
    Load:    @AvgIntSampler.Load;
    Store:   @AvgIntSampler.Store
  );

CONST
  AvgBoolSampler_OID = 9025;
  AvgBoolSampler_OSR: TStreamRec = (
    ObjType: AvgBoolSampler_OID;
    VmtLink: Ofs(TypeOf(AvgBoolSampler)^);
    Load:    @AvgBoolSampler.Load;
    Store:   @AvgBoolSampler.Store
  );

PROCEDURE RegisterIntSamplers;
BEGIN
  IF Not GenericRgd
  THEN BEGIN
    RegisterType(GenericSampler_OSR);
    GenericRgd:=True;
  END;
  RegisterType(IntSampler_OSR);
  RegisterType(AvgIntSampler_OSR);
END; {PROC RegisterIntSamplers}

PROCEDURE RegisterBoolSamplers;
BEGIN
  IF Not GenericRgd
  THEN BEGIN
    RegisterType(GenericSampler_OSR);
    GenericRgd:=True;
  END;
  RegisterType(BoolSampler_OSR);
  RegisterType(AvgBoolSampler_OSR);
END; {PROC RegisterBoolSamplers}

{--------------------------------------------------------------- FlagGroup ---
  Description
    Object for collecting several boolean instances into one
}

FUNCTION FlagsSet(VAR FlagVar; Flags:LongInt):Boolean;
BEGIN
  FlagsSet:=(LongInt(FlagVar) and Flags)<>0;
END;{Flags}

CONSTRUCTOR FlagGroup.Init(Flags:LongInt);
{ - Initialize Flag-table}
BEGIN
  OrigTable:=Flags;
  Reset;
END; {CONS FlagGroup.}

PROCEDURE FlagGroup.Enable(Flags:LongInt);
{ - Enable all "flags"}
BEGIN
  FlagTable:=FlagTable or Flags;
END; {PROC FlagGroup.}

PROCEDURE FlagGroup.Disable(Flags:LongInt);
{ - Disable all "flags" }
BEGIN
  FlagTable:=FlagTable and not Flags;
END; {PROC FlagGroup.}

PROCEDURE FlagGroup.Toggle(Flags:LongInt);
{ - Invert state of all "flags"}
BEGIN
  FlagTable:=FlagTable xor Flags;
END; {PROC FlagGroup.}

PROCEDURE FlagGroup.Assign(Flags:LongInt; NewState:Boolean);
{ - Assign all "flags" the "NewState"}
BEGIN
  IF NewState
  THEN Enable(Flags)
  ELSE Disable(Flags);
END; {PROC FlagGroup.Assign}

PROCEDURE FlagGroup.Reset;
{ - Reset all flags to Init state}
BEGIN
  FlagTable:=OrigTable;
END; {PROC FlagGroup.Reset}

PROCEDURE FlagGroup.Clear(NewState:Boolean);
{ - Clear all flags to a given state}
BEGIN
  IF NewState
  THEN FlagTable:=$FFFFFFFF
  ELSE FlagTable:=$00000000;
END; {PROC FlagGroup.Clear}

FUNCTION FlagGroup.isEnabled(Flags:LongInt):Boolean;
{ - Return true if all "Flags" is set}
BEGIN
  isEnabled:=(FlagTable and Flags) = Flags;
END; {FUNC FlagGroup.isEnabled}

FUNCTION FlagGroup.isDisabled(Flags:LongInt):Boolean;
{ - Return true if all "Flags" is cleared}
BEGIN
  isDisabled:=((not FlagTable) and Flags) = Flags;
END; {FUNC FlagGroup.isDisabled}

FUNCTION FlagGroup.AnyEnabledOf(Flags:LongInt):Boolean;
{ - Return true if one or more of "Flags" is set}
BEGIN
  AnyEnabledOf:=(FlagTable and Flags) <> 0;
END; {FUNC FlagGroup.AnyEnabledOf}

FUNCTION FlagGroup.AnyDisabledOf(Flags:LongInt):Boolean;
{ - Return true if one or more of "Flags" is Cleared}
BEGIN
  AnyDisabledOf:=((not FlagTable) and Flags) <> 0;
END; {FUNC FlagGroup.AnyDisabledOf}

FUNCTION FlagGroup.State(Flag:LongInt):Boolean;
{ - Return state of flag}
BEGIN
  State:=(FlagTable and Flag)=Flag;
END; {FUNC FlagGroup.State}

PROCEDURE FlagGroup.Save(VAR Flags:LongInt);
{ - Store flags to an external variable}
BEGIN
  Flags:=FlagTable;
END; {PROC FlagGroup.Save}

PROCEDURE FlagGroup.Restore(Flags:LongInt);
{ - Load flags from an external variable}
BEGIN
  FlagTable:=Flags;
END; {PROC FlagGroup.Restore}



{---------------------------------------------------------- GenericSampler ---
  Description:
    Generic array object for maintaining sample tables
}

TYPE
  ByteArr = ARRAY[0..64000] OF Byte; {for type casts}

CONSTRUCTOR GenericSampler.Init(NewID:Word);
{ - Init sampler object }
BEGIN
  TObject.Init;
  ID:=NewID;
  Table:=nil;
  MaxSamples:=0;
  Discard;
  SetSize(0);
  Reset;
END; {CONS GenericSampler.Init}

CONSTRUCTOR GenericSampler.Load(VAR S:TStream);
{ - Load sampler object }
BEGIN
  S.Read(ID,SizeOf(ID));
  S.Read(MaxSamples,SizeOf(MaxSamples));
  S.Read(Current,SizeOf(Current));
  GetMem(Table,TableSize);
  S.Read(Table^,TableSize);
END; {CONS GenericSampler.Load}

PROCEDURE GenericSampler.Store(VAR S:TStream);
{ - Store sampler object }
BEGIN
  S.Write(ID,SizeOf(ID));
  S.Write(MaxSamples,SizeOf(MaxSamples));
  S.Write(Current,SizeOf(Current));
  S.Write(Table^,TableSize);
END; {PROC GenericSampler.Store}

FUNCTION GenericSampler.TableSize:Word;
BEGIN
  TableSize:=2;
END; {FUNC GenericSampler.TableSize}

PROCEDURE GenericSampler.SetSize(Points:Integer);
{ - Allocate and clear sample table space }
VAR
  n : Integer;
BEGIN
  GenericSampler.Discard;
  IF Points<0 THEN Points:=0;
  MaxSamples:=Points;
  GetMem(Table,TableSize);
  Reset;
END; {PROC GenericSampler.SetSize}

PROCEDURE GenericSampler.Discard;
{ - DeAllocate sample table space }
BEGIN
  IF Table<>nil  { Is there a table ?}
  THEN BEGIN
    FreeMem(Table,TableSize);
    Table:=nil;
  END;
  MaxSamples:=0; { No Samplespace }
END; {PROC GenericSampler.Discard}

PROCEDURE GenericSampler.Reset;
{ - clear sample table space }
VAR
  n : Integer;
BEGIN
  IF Table<>nil
  THEN FillChar(Table^,TableSize,0);
  Current:=0;
END; {PROC GenericSampler.Reset}

DESTRUCTOR GenericSampler.Done;
{ - Cleanup after sample table }
BEGIN
  Discard;
END; {DEST GenericSampler.Done}

PROCEDURE GenericSampler.Rol(Points:Integer);
{ - Rotate sample table <Points> places left }
BEGIN
  Abstract;
END; {DEST GenericSampler.Rol}

PROCEDURE GenericSampler.Ror(Points:Integer);
{ - Rotate sample table <Points> places right }
BEGIN
  Abstract;
END; {DEST GenericSampler.Ror}

PROCEDURE GenericSampler.Skip(n:LongInt);
{ - Skip (Copy last) <n> times }
BEGIN
  Abstract;
END; {DEST GenericSampler.Skip}

PROCEDURE GenericSampler.CopyFrom(Sampler:pGenSampler);
BEGIN
  Abstract;
END; {PROC GenericSampler.CopyFrom}

{-------------------------------------------------------------- IntSampler ---
  Description:
    Array object for maintaining integer samples
}

TYPE
  IntSamples = ARRAY[0..0] OF IntSample; {Typecast}

CONSTRUCTOR IntSampler.Init(NewID:Word);
BEGIN
  GenericSampler.Init(NewID);
END; {CONS IntSampler.Init}

CONSTRUCTOR IntSampler.Load(VAR S:TStream);
{ - Load IntSampler object }
BEGIN
  GenericSampler.Load(S);
  S.Read(Min,SizeOf(Min));
  S.Read(Max,SizeOf(Max));
END; {CONS IntSampler.Load}

PROCEDURE IntSampler.Store(VAR S:TStream);
{ - Store IntSampler object }
BEGIN
  GenericSampler.Store(S);
  S.Write(Min,SizeOf(Min));
  S.Write(Max,SizeOf(Max));
END; {PROC IntSampler.Store}

FUNCTION IntSampler.TableSize:Word;
BEGIN
  TableSize:=SizeOf(IntSample)*(MaxSamples+1)
END; {FUNC IntSampler.TableSize}

PROCEDURE IntSampler.Reset;
BEGIN
  GenericSampler.Reset;
  Min:=MaxInt;
  Max:=Not MaxInt;
END; {PROC IntSampler.Reset}

CONST
  IntSampleSize = SizeOf(IntSample);

PROCEDURE IntSampler.Rol(Points:Integer);
{ - Rotate Intsample table <Points> places left }
VAR
  i : Integer;
  Hold : Pointer;
BEGIN
  IF Table<>nil  { Is there a table ?}
  THEN BEGIN
    GetMem(Hold,IntSampleSize);
    FOR i:=1 TO Abs(Points)
    DO BEGIN
     {$IFOPT R+} {$R-} {$DEFINE RCheck} {$ENDIF}
      Move(Table^,Hold^,IntSampleSize);
      Move(ByteArr(Table^)[IntSampleSize],Table^,IntSampleSize*MaxSamples);
      Move(Hold^,ByteArr(Table^)[IntSampleSize*MaxSamples],IntSampleSize);
     {$IFDEF RCheck} {$R+} {$UNDEF RCheck} {$ENDIF}
    END;
    FreeMem(Hold,IntSampleSize);
  END;
END; {DEST IntSampler.Rol}

PROCEDURE IntSampler.Ror(Points:Integer);
{ - Rotate Intsample table <Points> places right }
VAR
  i : Integer;
  Hold : Pointer;
BEGIN
  IF Table<>nil  { Is there a table ?}
  THEN BEGIN
    GetMem(Hold,IntSampleSize);
    FOR i:=1 TO Abs(Points)
    DO BEGIN
     {$IFOPT R+} {$R-} {$DEFINE RCheck} {$ENDIF}
      Move(ByteArr(Table^)[IntSampleSize*MaxSamples],Hold^,IntSampleSize);
      Move(Table^,ByteArr(Table^)[IntSampleSize],IntSampleSize*MaxSamples);
      Move(Hold^,Table^,IntSampleSize);
     {$IFDEF RCheck} {$R+} {$UNDEF RCheck} {$ENDIF}
    END;
    FreeMem(Hold,IntSampleSize);
  END;
END; {DEST IntSampler.Ror}

PROCEDURE IntSampler.AtPut(Point:Integer; NewSample:IntSample);
BEGIN
  {$IFOPT R+} {$R-} {$DEFINE RCheck} {$ENDIF}
  IntSamples(Table^)[Point]:=NewSample;
  {$IFDEF RCheck} {$R+} {$UNDEF RCheck} {$ENDIF}
  IF NewSample>Max THEN Max:=NewSample;
  IF NewSample<Min THEN Min:=NewSample;
END; {PROC IntSampler.AtPut}

FUNCTION IntSampler.At(Point:Integer):IntSample;
BEGIN
  {$IFOPT R+} {$R-} {$DEFINE RCheck} {$ENDIF}
  At:=IntSamples(Table^)[Point];
  {$IFDEF RCheck} {$R+} {$UNDEF RCheck} {$ENDIF}
END; {FUNC IntSampler.At}

PROCEDURE IntSampler.Update(NewSample:IntSample);
{ - }
BEGIN
  IF Current<MaxSamples
  THEN Inc(Current)
  ELSE ROL(1);
  AtPut(Current,NewSample);
END; {PROC IntSampler.Update}

PROCEDURE IntSampler.Skip(n:LongInt);
{ - Skip (Copy last) <n> times }
VAR
  i : LongInt;
  v : IntSample;
BEGIN
  v:=Last;
  FOR i:=1 TO n DO Update(v);
END; {PROC IntSampler.Skip}

FUNCTION IntSampler.Last:IntSample;
BEGIN
  IF MaxSamples<2
  THEN Last:=At(0)
  ELSE Last:=At(Current);
END; {FUNC IntSampler.Last}

FUNCTION IntSampler.Average:IntSample;
VAR
  i  : Integer;
  av : IntSample;
  s  : Float;
BEGIN
  IF Current>0
  THEN BEGIN
    s:=0;
    FOR i:=1 TO Current
    DO s:=s+At(i);
    av:=Round(s/Current);
  END ELSE av:=Last;
  Average:=av;
END; {FUNC IntSampler.Average}

PROCEDURE IntSampler.CopyFrom(Sampler:pGenSampler);
VAR
  ip : PIntSampler Absolute Sampler;
BEGIN
  SetSize(ip^.MaxSamples);
  Move(ip^.Table^, Table^, TableSize);
  Min:=ip^.Min;
  Max:=ip^.Max;
END; {PROC IntSampler.CopyFrom}

PROCEDURE IntSampler.AdjSize(NewSize:Integer);
VAR
  Buf   : Pointer;
  csize : Word;
  nSize : Word;
BEGIN
  cSize:=TableSize;
  GetMem(Buf, cSize);
  Move(Table^, buf^, cSize);
  SetSize(NewSize);
  nSize:=TableSize;
  IF nSize>cSize
  THEN nSize:=cSize;
  Move(buf^, Table^, nSize);
  FreeMem(Buf, cSize);
END;

{-------------------------------------------------------------- AvgIntSampler ---
  Description:
    Array object for maintaining moving average integer samples
}

CONSTRUCTOR AvgIntSampler.Init(NewID:Word; NewTrigPoint:Integer (* ;
           _min,_max:IntSample *) );
BEGIN
  GenericSampler.Init(NewID);
  New(MovAvg,Init(0));
  TrigPoint:=NewTrigPoint;
  Trigger:=0;
(*  SetLimits(_min,_max); *)
  MovAvg^.SetSize(TrigPoint);
END; {CONS AvgIntSampler.Init}

CONSTRUCTOR AvgIntSampler.Load(VAR S:TStream);
{ - Load AvgIntSampler object }
BEGIN
  MovAvg:=nil;
  IntSampler.Load(S);
  New(MovAvg,Load(S));
(*  S.Read(QMin,SizeOf(Min));
  S.Read(QMax,SizeOf(Max));  *)
  S.Read(TrigPoint,SizeOf(TrigPoint));
  S.Read(Trigger,SizeOf(Trigger));
END; {CONS AvgIntSampler.Load}

PROCEDURE AvgIntSampler.Store(VAR S:TStream);
{ - Store AvgIntSampler object }
BEGIN
  IntSampler.Store(S);
  MovAvg^.Store(S);
(*  S.Write(QMin,SizeOf(Min));
  S.Write(QMax,SizeOf(Max)); *)
  S.Write(TrigPoint,SizeOf(TrigPoint));
  S.Write(Trigger,SizeOf(Trigger));
END; {PROC AvgIntSampler.Store}

DESTRUCTOR AvgIntSampler.Done;
{ - Cleanup after sample table }
BEGIN
  Dispose(MovAvg,Done);
  MovAvg:=nil;
  Discard;
END; {DEST AvgIntSampler.Done}

(*
PROCEDURE AvgIntSampler.SetLimits(_min,_max:IntSample);
{ - Set Filter }
BEGIN
  Qmin:=_min;
  Qmax:=_max;
END; {PROC AvgIntSampler.SetLimits}
*)

PROCEDURE AvgIntSampler.SetSize(Points:Integer);
{ - Allocate and clear sample table space }
VAR
  n : Integer;
BEGIN
  IntSampler.SetSize(Points);
  IF MovAvg<>nil
  THEN MovAvg^.SetSize(TrigPoint);
END; {PROC AvgIntSampler.SetSize}

PROCEDURE AvgIntSampler.Discard;
{ - DeAllocate sample table space }
BEGIN
  IntSampler.Discard;
  IF MovAvg<>nil
  THEN MovAvg^.Discard;
END; {PROC AvgSampler.Discard}

PROCEDURE AvgIntSampler.Reset;
BEGIN
  IntSampler.Reset;
  IF MovAvg<>nil
  THEN MovAvg^.Reset;
  Trigger:=0;
END; {DEST AvgIntSampler.Reset}

PROCEDURE AvgIntSampler.Update(NewSample:IntSample);
{ - }
BEGIN
  MovAvg^.UpDate(NewSample);
  IF Trigger<TrigPoint
  THEN BEGIN
    AtPut(Current,MovAvg^.Average);
    Inc(Trigger);
  END
  ELSE BEGIN
    IntSampler.Update(MovAvg^.Average);
    Trigger:=1;
  END;
END; {PROC AvgIntSampler.Update}

FUNCTION AvgIntSampler.Average:IntSample;
VAR
  i  : Integer;
  av : IntSample;
  s  : Float;
BEGIN
  IF Current>0
  THEN BEGIN
    s:=MovAvg^.Average;
    FOR i:=1 TO Current
    DO s:=s+At(i);
    av:=Round(s/(Current+1));
  END ELSE av:=Last;
  Average:=av;
END; {FUNC AvgIntSampler.Average}

FUNCTION AvgIntSampler.Last:IntSample;
VAR
  i : Integer;
BEGIN
  IF MaxSamples<2
  THEN Last:=At(0)
  ELSE Last:=MovAvg^.Last;
END; {FUNC IntSampler.Last}



{------------------------------------------------------------- BoolSampler ---
  Description:
    Array object for maintaining boolean samples (32 per sample)
}

TYPE
  BooleanSamples = ARRAY[0..0] OF Byte; {Typecast}

CONSTRUCTOR BoolSampler.Init(NewID:Word);
BEGIN
  GenericSampler.Init(NewID);
END; {CONS BoolSampler.Init}

CONSTRUCTOR BoolSampler.Load(VAR S:TStream);
{ - Load BoolSampler object }
BEGIN
  GenericSampler.Load(S);
END; {CONS BoolSampler.Load}

PROCEDURE BoolSampler.Store(VAR S:TStream);
{ - Store BoolSampler object }
BEGIN
  GenericSampler.Store(S);
END; {PROC BoolSampler.Store}

FUNCTION BoolSampler.TableSize:Word;
BEGIN
  TableSize:=((MaxSamples SHR 3)+1);
END; {FUNC BoolSampler.TableSize}


PROCEDURE BoolSampler.Rol(Points:Integer);
{ - Rotate Booleansample table <Points> places left }
VAR
  i,n   : Integer;
  carry : Byte;
  Hold  : Boolean;
BEGIN
  IF Table<>nil  { Is there a table ?}
  THEN BEGIN
    FOR i:=1 TO Abs(Points)
    DO BEGIN
      Hold:=At(1);
      FOR n:=0 TO (MaxSamples SHR 3)
      DO BEGIN
       {$IFOPT R+} {$R-} {$DEFINE RCheck} {$ENDIF}
        carry:=(BooleanSamples(Table^)[n+1] and $1) SHL $7;
        BooleanSamples(Table^)[n]:=(BooleanSamples(Table^)[n] SHR 1) or Carry;
       {$IFDEF RCheck} {$R+} {$UNDEF RCheck} {$ENDIF}
      END;
      AtPut(Current,Hold);
    END;
  END;
END; {DEST BoolSampler.Rol}

PROCEDURE BoolSampler.Ror(Points:Integer);
{ - Rotate Booleansample table <Points> places right }
VAR
  i,n   : Integer;
  carry : Word;
  Hold  : Boolean;
BEGIN
  IF Table<>nil  { Is there a table ?}
  THEN BEGIN
    FOR i:=1 TO Abs(Points)
    DO BEGIN
      Hold:=At(Current);
      FOR n:=(MaxSamples SHR 3) DOWNTO 0
      DO BEGIN
       {$IFOPT R+} {$R-} {$DEFINE RCheck} {$ENDIF}
        carry:=(BooleanSamples(Table^)[n-1] and $80) SHR $7;
        BooleanSamples(Table^)[n]:=(BooleanSamples(Table^)[n] SHL 1) or Carry;
       {$IFDEF RCheck} {$R+} {$UNDEF RCheck} {$ENDIF}
      END;
      AtPut(1,Hold);
    END;
  END;
END; {DEST BoolSampler.Ror}

PROCEDURE Position(Point:Integer; VAR Index:Word; VAR Mask:Byte); NEAR;
BEGIN
  Index:=Point SHR 3;
  Mask:=b2e[Point AND $07];
END; {PROC Position}

PROCEDURE BoolSampler.AtPut(Point:Integer; NewSample:Boolean);
VAR
  Temp  : Byte;
  Index : Word;
  Mask  : Byte;
BEGIN
  {$IFOPT R+} {$R-} {$DEFINE RCheck} {$ENDIF}
  Position(Point,Index,Mask);
  Temp:=BooleanSamples(Table^)[Index] and not Mask; {Clear bit}
  IF NewSample THEN Temp:=Temp or Mask;             {Set bit if needed}
  BooleanSamples(Table^)[Index]:=Temp;
  {$IFDEF RCheck} {$R+} {$UNDEF RCheck} {$ENDIF}
END; {PROC BoolSampler.AtPut}

FUNCTION BoolSampler.At(Point:Integer):Boolean;
VAR
  Index : Word;
  Mask  : Byte;
BEGIN
  {$IFOPT R+} {$R-} {$DEFINE RCheck} {$ENDIF}
  Position(Point,Index,Mask);
  At:=(BooleanSamples(Table^)[Index] and mask)=mask;
  {$IFDEF RCheck} {$R+} {$UNDEF RCheck} {$ENDIF}
END; {FUNC BoolSampler.At}

PROCEDURE BoolSampler.Update(NewSample:Boolean);
{ - }
BEGIN
  IF Current<MaxSamples
  THEN Inc(Current)
  ELSE ROL(1);
  AtPut(Current,NewSample);
END; {PROC BoolSampler.Update}

PROCEDURE BoolSampler.Skip(n:LongInt);
{ - Skip (Copy last) <n> times }
VAR
  i : LongInt;
  v : Boolean;
BEGIN
  v:=Last;
  FOR i:=1 TO n DO Update(v);
END; {PROC BoolSampler.Skip}

FUNCTION BoolSampler.Last:Boolean;
BEGIN
  IF MaxSamples<2
  THEN Last:=At(0)
  ELSE Last:=At(Current);
END; {FUNC BoolSampler.Last}

FUNCTION BoolSampler.Average:Boolean;
VAR
  i,s : Integer;
  av  : Boolean;
BEGIN
  IF Current>0
  THEN BEGIN
    s:=0;
    FOR i:=1 TO Current
    DO IF At(i) THEN Inc(s);
    av:=(s/Current)>=0.5;
  END ELSE av:=Last;
  Average:=av;
END; {FUNC BoolSampler.Average}


{--------------------------------------------------------- AvgBoolSampler ---
  Description:
    Array object for maintaining moving average boolean samples
}

CONSTRUCTOR AvgBoolSampler.Init(NewID:Word; NewTrigPoint:Integer);
BEGIN
  BoolSampler.Init(NewID);
  New(MovAvg,Init(0));
  TrigPoint:=NewTrigPoint;
  Trigger:=0;
  MovAvg^.SetSize(TrigPoint);
END; {CONS AvgBoolSampler.Init}

CONSTRUCTOR AvgBoolSampler.Load(VAR S:TStream);
{ - Load AvgBoolSampler object }
BEGIN
  MovAvg:=nil;
  BoolSampler.Load(S);
  New(MovAvg,Load(S));
  S.Read(TrigPoint,SizeOf(TrigPoint));
  S.Read(Trigger,SizeOf(Trigger));
END; {CONS AvgBoolSampler.Load}

PROCEDURE AvgBoolSampler.Store(VAR S:TStream);
{ - Store AvgBoolSampler object }
BEGIN
  BoolSampler.Store(S);
  MovAvg^.Store(S);
  S.Write(TrigPoint,SizeOf(TrigPoint));
  S.Write(Trigger,SizeOf(Trigger));
END; {PROC AvgBoolSampler.Store}

DESTRUCTOR AvgBoolSampler.Done;
{ - Cleanup after sample table }
BEGIN
  Dispose(MovAvg,Done);
  MovAvg:=nil;
  Discard;
END; {DEST AvgBoolSampler.Done}

PROCEDURE AvgBoolSampler.SetSize(Points:Integer);
{ - Allocate and clear sample table space }
VAR
  n : Integer;
BEGIN
  BoolSampler.SetSize(Points);
  IF MovAvg<>Nil
  THEN MovAvg^.SetSize(TrigPoint);
END; {PROC AvgBoolSampler.SetSize}

PROCEDURE AvgBoolSampler.Discard;
{ - DeAllocate sample table space }
BEGIN
  BoolSampler.Discard;
  IF MovAvg<>nil
  THEN MovAvg^.Discard;
END; {PROC AvgSampler.Discard}

PROCEDURE AvgBoolSampler.Reset;
BEGIN
  BoolSampler.Reset;
  IF MovAvg<>nil
  THEN MovAvg^.Reset;
  Trigger:=0;
END; {DEST AvgBoolSampler.Reset}

PROCEDURE AvgBoolSampler.Update(NewSample:Boolean);
{ - }
BEGIN
  MovAvg^.UpDate(NewSample);
  IF Trigger<TrigPoint
  THEN BEGIN
    AtPut(Current,MovAvg^.Average);
    Inc(Trigger);
  END
  ELSE BEGIN
    BoolSampler.Update(MovAvg^.Average);
    Trigger:=1;
  END;
END; {PROC AvgBoolSampler.Update}

FUNCTION AvgBoolSampler.Last:Boolean;
BEGIN
  IF MaxSamples<2
  THEN Last:=At(0)
  ELSE Last:=MovAvg^.Last;
END; {FUNC AvgBoolSampler.Last}

FUNCTION AvgBoolSampler.Average:Boolean;
VAR
  i,s : Integer;
  av  : Boolean;
BEGIN
  IF Current>0
  THEN BEGIN
    IF MovAvg^.Average THEN s:=1 ELSE s:=0;
    FOR i:=1 TO Current
    DO IF At(i) THEN Inc(s);
    av:=(s/(Current+1))>=0.5;
  END ELSE av:=Last;
  Average:=av;
END; {FUNC AvgBoolSampler.Average}


{-------------------------------------------------------------- HookEntry ---
}

CONSTRUCTOR HookEntry.Init(NewHook:LongInt);
BEGIN
  TObject.Init;
  Hook:=NewHook;
END; {CONS HookEntry.Init}

VAR
  PrevExitProc:Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  Units.Leave(LFTableMsg,MemAvail);
END;

BEGIN
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  Units.Enter(LFTableMsg,MemAvail,CSeg);
END.
