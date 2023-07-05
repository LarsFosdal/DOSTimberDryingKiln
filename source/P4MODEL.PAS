{$I CODEDEFS.PAS} {Include code generation definitions}

UNIT P4Model; {Calculation models for timber drying kilns}

INTERFACE
USES Objects,LFSystem,LFtable,LFWindow,ObjInput,P4Config;

PROCEDURE SecondaryInit;

TYPE
  PModelType = ^ModelType;
  ModelType = OBJECT(TObject)
    Comment   : PString;
    tv        : IntSampler;
    tt        : IntSampler;
    CONSTRUCTOR Init;
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE   Store(VAR S:LFStream);               VIRTUAL;
    DESTRUCTOR  Done;                                VIRTUAL;
    PROCEDURE   AdjustSize;                          VIRTUAL;
    PROCEDURE   Calculate(Cfg:pGenericCfg);          VIRTUAL;
    PROCEDURE   CreateFields(WS:PWorkSpace; VAR Fields:PFieldList); VIRTUAL;
    PROCEDURE   SetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   GetFields(VAR Fields:PFieldList);    VIRTUAL;
    FUNCTION    Describe:String;                     VIRTUAL;
    FUNCTION    TotalTime:Integer;                   VIRTUAL;
    FUNCTION    ModelTime:Integer;                   VIRTUAL;
    PROCEDURE   PrintInfo;                           VIRTUAL;
  END; {OBJ ModelType}

  PKilnModel = ^KilnModel;
  KilnModel = OBJECT(ModelType)
    Material    : Word;
    DoubleLayed : Boolean;
    DimY,
    DimX,
    HeatTime,
    EquTime,
    CondTime,
    DryTime,
    CoolTime,
    CondTDiff    : Integer;
    CONSTRUCTOR Init(_CoolTime:Integer);
    CONSTRUCTOR Load(VAR S:LFStream);
    CONSTRUCTOR InitCopy(P:PKilnModel);
    PROCEDURE   Store(VAR S:LFStream);                VIRTUAL;
    DESTRUCTOR  Done;                                VIRTUAL;
    PROCEDURE   CreateFields(WS:PWorkSpace; VAR Fields:PFieldList); VIRTUAL;
    PROCEDURE   SetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   GetFields(VAR Fields:PFieldList);    VIRTUAL;
    FUNCTION    Describe:String;                     VIRTUAL;
    FUNCTION    TotalTime:Integer;                   VIRTUAL;
    FUNCTION    ModelTime:Integer;                   VIRTUAL;
  END; {OBJ KilnModel}

  POwnModel = ^OwnModel;
  OwnModel = OBJECT(KilnModel)
    DataInterval,
    CurveType    : Integer;
    CONSTRUCTOR Init(_CoolTime:Integer);
    CONSTRUCTOR InitCopy(P:PKilnModel);
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE   Store(VAR S:LFStream);               VIRTUAL;
    PROCEDURE   AdjustSize;                          VIRTUAL;
    PROCEDURE   Calculate(Cfg:pGenericCfg);          VIRTUAL;
    PROCEDURE   CreateFields(WS:PWorkSpace; VAR Fields:PFieldList); VIRTUAL;
    PROCEDURE   SetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   GetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   PrintInfo;                           VIRTUAL;
  END; {OBJ OwnModel}

  PModel3 = ^Model3;
  Model3 = OBJECT(KilnModel)
    MoistNow,
    MoistWanted,
    Density,
    tWet,
    StartTDiff   : Integer;
    Intensity,
    CharDryTime  : Float;
    CONSTRUCTOR Init(_CoolTime:Integer);
    CONSTRUCTOR InitCopy(P:PKilnModel);
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE   Store(VAR S:LFStream);                VIRTUAL;
    PROCEDURE   Calculate(Cfg:pGenericCfg);          VIRTUAL;
    FUNCTION    ApproxMoist(t:Integer):Float;        VIRTUAL;
    PROCEDURE   CreateFields(WS:PWorkSpace; VAR Fields:PFieldList); VIRTUAL;
    PROCEDURE   SetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   GetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   PrintInfo;                           VIRTUAL;
  END; {OBJ Model3}

  PModelM1 = ^ModelM1;
  ModelM1 = OBJECT(Model3)
              {Calculation models for timber drying kilns}
              {Based on Malmquist's model M1, january -92, HK}
    Kernal      : Float;
    CONSTRUCTOR Init(_CoolTime:Integer);
    CONSTRUCTOR InitCopy(P:PKilnModel);
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE   Store(VAR S:LFStream);                VIRTUAL;
    PROCEDURE   Calculate(Cfg:pGenericCfg);          VIRTUAL;
    FUNCTION    ApproxMoist(t:Integer):Float;        VIRTUAL;
    PROCEDURE   CreateFields(WS:PWorkSpace; VAR Fields:PFieldList); VIRTUAL;
    PROCEDURE   SetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   GetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   PrintInfo;                           VIRTUAL;
  END; {OBJ ModelM1}

{ DEFINE UseDeltaT}

  PTunnelModel = ^TunnelModel;
  TunnelModel = OBJECT(ModelType)
    sptv,sptt,
    delta_t  : Word;
    HeatTime : Word;
    Comment2, Comment3:PString;
    CONSTRUCTOR Init;
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE   Store(VAR S:LFStream);                VIRTUAL;
    DESTRUCTOR  Done;                                VIRTUAL;
    PROCEDURE   Calculate(Cfg:pGenericCfg);          VIRTUAL;
    FUNCTION    TotalTime:Integer;                   VIRTUAL;
    PROCEDURE   CreateFields(WS:PWorkSpace; VAR Fields:PFieldList); VIRTUAL;
    PROCEDURE   SetFields(VAR Fields:PFieldList);    VIRTUAL;
    PROCEDURE   GetFields(VAR Fields:PFieldList);    VIRTUAL;
    FUNCTION    Describe:String;                     VIRTUAL;
    PROCEDURE   PrintInfo;                           VIRTUAL;
  END; {OBJ TunnelModel}


CONST
  ModelType_OID = 10025;
  ModelType_OSR: TStreamRec = (
    ObjType: ModelType_OID;
    VmtLink: Ofs(TypeOf(ModelType)^);
    Load:    @ModelType.Load;
    Store:   @ModelType.Store
  );

  KilnModel_OID = 10026;
  KilnModel_OSR: TStreamRec = (
    ObjType: KilnModel_OID;
    VmtLink: Ofs(TypeOf(KilnModel)^);
    Load:    @KilnModel.Load;
    Store:   @KilnModel.Store
  );

  OwnModel_OID = 10027;
  OwnModel_OSR: TStreamRec = (
    ObjType: OwnModel_OID;
    VmtLink: Ofs(TypeOf(OwnModel)^);
    Load:    @OwnModel.Load;
    Store:   @OwnModel.Store
  );

  Model3_OID = 10028;
  Model3_OSR: TStreamRec = (
    ObjType: Model3_OID;
    VmtLink: Ofs(TypeOf(Model3)^);
    Load:    @Model3.Load;
    Store:   @Model3.Store
  );

  TunnelModel_OID = 10029;
  TunnelModel_OSR: TStreamRec = (
    ObjType: TunnelModel_OID;
    VmtLink: Ofs(TypeOf(TunnelModel)^);
    Load:    @TunnelModel.Load;
    Store:   @TunnelModel.Store
  );

  ModelM1_OID = 10030;
  ModelM1_OSR: TStreamRec = (
    ObjType: ModelM1_OID;
    VmtLink: Ofs(TypeOf(ModelM1)^);
    Load:    @ModelM1.Load;
    Store:   @ModelM1.Store
  );


IMPLEMENTATION
USES
  LFCrt,LFExtMsg,AGTools,P4Limits, LFString;

VAR
  WoodSortName : ARRAY[1..2] OF PString;

PROCEDURE SecondaryInit;
CONST
  wt_tag = 'WOODTYPES';
VAR
  i : Integer;
  t : PTextTxt;
BEGIN
  t:=Msg^.FindText(wt_tag);
  IF t<>nil
  THEN FOR i:=0 TO 1
  DO WoodSortName[i+1]:=t^.PTextAtLine(i);
END; {PROC SecondaryInit}


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Common Malmquist model routines ÄÄÄ}

FUNCTION Raise(x,y:Float):Float; NEAR;
{ - Ex.: Raise(3,4) = 3^4 = 3*3*3*3 = 81
    Limitation : Doesn't handle x<0 (infinite or complex) !!}
VAR result : Float;
BEGIN
  IF x>0   THEN Raise:=EXP(y*LN(x))
  ELSE IF x=0
  THEN BEGIN
    IF y=0 THEN Raise:=1       { 0^0 = 1  per def.}
           ELSE Raise:=0;      { 0^y }
       END ELSE RunError(207); { (x<0)^y -> may be complex or infinite }
END; {FUNC Raise}

FUNCTION gauss(arg:Float):Float;  NEAR;
{ - Approximation of the cumulative standard Normal distribution function

            1   ôx  -t^2/2
    F(x) = ÄÄÄ  ³  e       dt
           û2ã  õ
               -ì
}
VAR a,b,c,d,f : Float;
BEGIN
  IF abs(arg)<3.6 THEN
  BEGIN
    f:=1/sqrt(2*PI*EXP(sqr(arg)));
    a:=1.0/(abs(arg)*0.2316419+1);
    d:=0.31938153 * a - 0.356563782 * sqr(a) + 1.781477937 * Raise(a,3.0);
    b:=d - 1.821255978 * Raise(a,4.0) + 1.330274429 * Raise(a,5.0);
    c:=f*b;
  END ELSE c:=0;
  IF arg>=0 THEN c:=1-c;
  gauss:=c;
END; {FUNC Gauss}

FUNCTION varmeo_tall(DimY:integer):Float; NEAR;
{ - Heat transfer factor }
VAR u : Float;
BEGIN
  u := - 0.00013867 * Raise(DimY,2.0) + 0.0364 * DimY + 1.67667;
  varmeo_tall := 8 * Raise(u,0.67);
END;{FUNC varmeo_tall}


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Generic Model ÄÄÄ}
{ Description:
³   Generic model object meant as base for kiln and tunnel models
}

CONSTRUCTOR ModelType.Init;
{ - Initialize model object}
BEGIN
  TObject.Init;
  PSNew(Comment,'');
  tv.init(0);
  tt.init(0);
END; {CONS ModelType.Init}

CONSTRUCTOR ModelType.Load(VAR S:LFStream);
{ - Initialize model object}
BEGIN
  Comment:=S.ReadStr;
  tv.Load(S);
  tt.Load(S);
END; {CONS ModelType.Load}

PROCEDURE ModelType.Store(VAR S:LFStream);
{ - Store model object}
BEGIN
  S.WriteStr(Comment);
  tv.Store(S);
  tt.Store(S);
END; {PROC ModelType.Store}

DESTRUCTOR ModelType.Done;
{ - cleanup after model object}
BEGIN
  PSDispose(Comment);
  tt.Done;
  tv.Done;
  TObject.Done;
END; {DEST ModelType.Done}

PROCEDURE ModelType.AdjustSize;
BEGIN
END; {PROC ModelType.AdjustSize}
                          
PROCEDURE ModelType.Calculate(Cfg:pGenericCfg);
{ - Calculate model data from parameters }
BEGIN
END; {PROC ModelType.Calculate}

PROCEDURE ModelType.CreateFields(WS:PWorkSpace; VAR Fields:PFieldList);
{ - Create fields and initialize them }
BEGIN
  Abstract;
END; {PROC ModelType.CreateFields}

PROCEDURE ModelType.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
BEGIN
  Abstract;
END; {PROC ModelType.SetFields}

PROCEDURE ModelType.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
BEGIN
  Abstract;
END; {PROC ModelType.GetFields}

FUNCTION ModelType.Describe:String;
BEGIN
  Abstract;
END; {FUNC ModelType.Describe}

FUNCTION ModelType.TotalTime;
{ - Return accumulated total time for model }
BEGIN
  TotalTime:=0;
END; {PROC ModelType.TotalTime}

FUNCTION ModelType.ModelTime;
{ - Return accumulated total time for model }
BEGIN
  ModelTime:=0;
END; {PROC ModelType.ModelTime}

PROCEDURE ModelType.PrintInfo;
BEGIN
  Abstract;
END; {PROC ModelType.PrintInfo}

{--------------------------------------------------------------- KilnModel ---
  Description:
    Generic kiln model with basic model information
}

CONSTRUCTOR KilnModel.Init(_CoolTime:Integer);
{ - Initialize basis kiln model}
BEGIN
  ModelType.Init;

  {Override _Cooltime=Cfg^.CoolLimit -> 5 hours  921012 LF}
  _CoolTime := 5;

  Material    := 1;      { "Gran" }
  DoubleLayed := False;  { Timber is not double stacked }
  DimX        := 100;    { 100 mm }
  DimY        :=  50;    { by 50 mm }
  HeatTime    :=   6;    { Approx. heating time}
  EquTime     :=   0;    { No thawing period }
  DryTime     :=   1;    { No initial drying time }
  CondTime    :=  24;    { 24 hours of conditioning }
  CoolTime    := _CoolTime; { 5 hours of cooling }
  CondTDiff   :=  30;    { Initial temp.diff., 3.0øC (30 x 1/10øC) }
END; {CONS KilnModel.Init}

CONSTRUCTOR KilnModel.InitCopy(P:PKilnModel);
BEGIN
  KilnModel.Init(P^.CoolTime);
  PSReNew(Comment, P^.Comment^);
  tt.CopyFrom(pGenSampler(@P^.tt));
  tv.CopyFrom(pGenSampler(@P^.tv));
  Material    := P^.Material;
  DoubleLayed := P^.DoubleLayed;
  DimX        := P^.DimX;
  DimY        := P^.DimY;
  HeatTime    := P^.HeatTime;
  EquTime     := P^.EquTime;
  DryTime     := P^.DryTime;
  CondTime    := P^.CondTime;
  CondTDiff   := P^.CondTDiff;
  CoolTime    := P^.CoolTime;
END; {CONS KilnModel.InitCopy}

CONSTRUCTOR KilnModel.Load(VAR S:LFStream);
{ - Initialize model object}
BEGIN
  ModelType.Load(S);
  S.Read(Material,SizeOf(Material));
  IF Material<1 THEN Material:=1;
  S.Read(DoubleLayed,SizeOf(DoubleLayed));
  S.Read(DimX,SizeOf(DimX));
  S.Read(DimY,SizeOf(DimY));
  S.Read(HeatTime,SizeOf(HeatTime));
  S.Read(EquTime,SizeOf(EquTime));
  S.Read(DryTime,SizeOf(DryTime));
  S.Read(CondTime,SizeOf(CondTime));
  S.Read(CoolTime,SizeOf(CoolTime));
  S.Read(CondTDiff,SizeOf(CondTDiff));
END; {CONS KilnModel.Load}

PROCEDURE KilnModel.Store(VAR S:LFStream);
{ - Store Kilnmodel object}
BEGIN
  ModelType.Store(S);
  S.Write(Material,SizeOf(Material));
  S.Write(DoubleLayed,SizeOf(DoubleLayed));
  S.Write(DimX,SizeOf(DimX));
  S.Write(DimY,SizeOf(DimY));
  S.Write(HeatTime,SizeOf(HeatTime));
  S.Write(EquTime,SizeOf(EquTime));
  S.Write(DryTime,SizeOf(DryTime));
  S.Write(CondTime,SizeOf(CondTime));
  S.Write(CoolTime,SizeOf(CoolTime));
  S.Write(CondTDiff,SizeOf(CondTDiff));
END; {PROC KilnModel.Store}

DESTRUCTOR  KilnModel.Done;
{ - }
BEGIN
  ModelType.Done;
END; {DEST KilnModel.Done}

PROCEDURE KilnModel.CreateFields(WS:PWorkSpace; VAR Fields:PFieldList);
{ - Create fields and initialize them }
VAR
  f : PGenEdit;
BEGIN
  f:=new(PChoiceInput,Init(WS,22, 1 ,6,Material,Msg^.FindText('WOODTYPES')));
  f^.Link(Msg,'WOODSRT?','WOODSORT','');
  Fields^.Add(Material,f);

  f:=new(PIntInput,Init(WS,22, 2 ,4,           12,DimY,150));
  f^.Link(Msg,'THICK?','THICKNESS','MILLIMET');
  Fields^.Add(DimY,f);

  f:=new(PIntInput,Init(WS,22, 3 ,4,           50,DimX,300));
  f^.Link(Msg,'WIDTH?','WIDTH','MILLIMET');
  Fields^.Add(DimX,f);

  f:=new(PFloatInput,Init(WS,22, 7 ,4,1,       1, CondTDiff/10, 20));
  f^.Link(Msg,'TDC?','TDC','CELSIUS');
  Fields^.Add(CondTDiff,f);

  f:=new(PIntInput,Init(WS,22,12,4,           0,EquTime,24));
  f^.Link(Msg,'EQUTIME?','EQUTIME','HOURS');
  Fields^.Add(EquTime,f);

  f:=new(PIntInput,Init(WS,22,13,4,           0, CondTime, 72));
  f^.Link(Msg,'CONDTIME?','CONDTIME','HOURS');
  Fields^.Add(CondTime,f);

  f:=new(PIntInput,Init(WS,22,14,4,           0, CoolTime, 72));
  f^.Link(Msg,'COOLTIME?','COOLTIME','HOURS');
  Fields^.Add(CoolTime,f);
END; {PROC KilnModel.CreateFields}


PROCEDURE KilnModel.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
VAR
  f : PGenEdit;
BEGIN
  f:=Fields^.Using(Material);   PChoiceInput(f)^.Assign(Material);
  f:=Fields^.Using(DimY);       PIntInput(f)^.Assign(DimY);
  f:=Fields^.Using(DimX);       PIntInput(f)^.Assign(DimX);
  f:=Fields^.Using(EquTime);    PIntInput(f)^.Assign(EquTime);
  f:=Fields^.Using(CondTime);   PIntInput(f)^.Assign(CondTime);
  f:=Fields^.Using(CoolTime);   PIntInput(f)^.Assign(CoolTime);
  f:=Fields^.Using(CondTDiff);  PFloatInput(f)^.Assign(CondTDiff/10);
END; {PROC KilnModel.SetFields}

PROCEDURE KilnModel.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
VAR
  f : PGenEdit;
BEGIN
  Fields^.Fetch(Material);
  Fields^.Fetch(DimY);
  Fields^.Fetch(DimX);
  Fields^.Fetch(EquTime);
  Fields^.Fetch(CondTime);
  Fields^.Fetch(CoolTime);
  f:=Fields^.Using(CondTDiff);  CondTDiff:=Trunc(PFloatInput(f)^.Value*10);
END; {PROC KilnModel.GetFields}

FUNCTION KilnModel.Describe:String;
BEGIN
  Describe:=PadTrailing(WoodSortName[Material]^,' ',5)
           +IntStr(DimX,3)+'x'+IntStr(DimY,3);
END; {FUNC KilnModel.Describe}

FUNCTION KilnModel.ModelTime:Integer;
BEGIN
  ModelTime:=EquTime+DryTime+CondTime;
END; {FUNC KilnModel.ModelTime}

FUNCTION KilnModel.TotalTime:Integer;
BEGIN
  TotalTime:=HeatTime+ModelTime+CoolTime;
END; {FUNC KilnModel.TotalTime}


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ OwnModel ÄÄÄ}
{ Description:
³   Model allowing user to describe kiln drying characteristics
}

CONSTRUCTOR OwnModel.Init(_CoolTime:Integer);
{ - Initialize user def. kiln model}
BEGIN
  KilnModel.Init(_CoolTime);
  DataInterval := 12; {12 hours between each setpoint}
  CurveType    :=  0; {Smoothing}
END; {CONS OwnModel.Init}

CONSTRUCTOR OwnModel.InitCopy(P:PKilnModel);
BEGIN
  KilnModel.InitCopy(P);
  IF TypeOf(P^)=TypeOf(OwnModel)
  THEN BEGIN
    DataInterval:=pOwnModel(P)^.DataInterval;
    CurveType:=pOwnModel(P)^.CurveType
  END
  ELSE BEGIN
    DataInterval:=12;
    CurveType:=0;
  END;
END; {CONS OwnModel.InitCopy}

CONSTRUCTOR OwnModel.Load(VAR S:LFStream);
{ - Initialize model object}
BEGIN
  KilnModel.Load(S);
  S.Read(DataInterval,SizeOf(DataInterval));
  S.Read(CurveType,SizeOf(CurveType));
END; {CONS OwnModel.Load}

PROCEDURE OwnModel.Store(VAR S:LFStream);
{ - Store Ownmodel object}
BEGIN
  KilnModel.Store(S);
  S.Write(DataInterval,SizeOf(DataInterval));
  S.Write(CurveType,SizeOf(CurveType));
END; {PROC OwnModel.Store}

PROCEDURE OwnModel.AdjustSize;
BEGIN
  tt.AdjSize(EquTime+DryTime+CondTime+1); {Init setpoint tables}
  tv.AdjSize(EquTime+DryTime+CondTime+1);
END; {PROC OwnModel.AdjustSize}

PROCEDURE OwnModel.Calculate(Cfg:pGenericCfg);
{ - Calculate model data from parameters }
VAR
  TimeIndex,i,j,s : Integer;
  Stig1, Stig2  : Float;
BEGIN
  AdjustSize;

  FOR TimeIndex:=0 TO EquTime-1 DO
  BEGIN
    tt.AtPut(TimeIndex, tt.At(EquTime + 1));
    tv.AtPut(TimeIndex, tv.At(EquTime + 1));
  END;

  FOR TimeIndex:=1 TO DryTime DO
  BEGIN
    IF tt.At(EquTime+TimeIndex)=0
    THEN tt.AtPut(EquTime+TimeIndex, tt.At(EquTime+TimeIndex-1));
    IF tv.At(EquTime+TimeIndex)=0
    THEN tv.AtPut(EquTime+TimeIndex, tv.At(EquTime+TimeIndex-1));
  END;

  IF DataInterval>1
  THEN BEGIN
    CASE CurveType OF
      1 : BEGIN {Interpolation}
            i:=0;
            REPEAT
              s:=DataInterval; IF i+s>DryTime THEN s:=DryTime-i;
              stig1:=(tt.At(EquTime+i+s)-tt.At(EquTime+i))/s;
              stig2:=(tv.At(EquTime+i+s)-tv.At(EquTime+i))/s;
              FOR j:=1 TO s-1 DO
              BEGIN
                tt.AtPut(EquTime+i+j, trunc((j*stig1)+tt.At(EquTime+i)));
                tv.AtPut(EquTime+i+j, trunc((j*stig2)+tv.At(EquTime+i)));
              END;
              i:=i+DataInterval;
            UNTIL i>=DryTime;
          END;
      2 : BEGIN  {Step}
            i:=0;
            REPEAT
              s:=DataInterval;
              IF i+s>DryTime THEN s:=DryTime-i;
              FOR j:=1 TO s-1 DO
              BEGIN
                tt.AtPut(EquTime+i+j,tt.At(EquTime+i));
                tv.AtPut(EquTime+i+j,tv.At(EquTime+i));
              END;
              i:=i+DataInterval;
            UNTIL i>=DryTime;
          END;
    END;
  END;
  FOR TimeIndex:=1 TO CondTime DO
  BEGIN
    Tt.AtPut(EquTime+DryTime+TimeIndex, Tt.At(DryTime));
    Tv.AtPut(EquTime+DryTime+TimeIndex, Tt.At(DryTime)-CondTDiff);
  END;

  tt.Current:=tt.MaxSamples;
  tv.Current:=tv.MaxSamples;
END; {PROC OwnModel.Calculate}

PROCEDURE OwnModel.CreateFields(WS:PWorkSpace; VAR Fields:PFieldList);
{ - Create fields and initialize them }
VAR
  f : PGenEdit;
BEGIN
  KilnModel.CreateFields(WS, Fields);

  f:=new(PIntInput,Init(WS,22,8,4,           1, DryTime ,600));
  f^.Link(Msg,'DRYTIME?','DRYTIME','HOURS');
  Fields^.Add(DryTime,f);

  f:=new(PIntInput,Init(WS,22,9,4,           1, DataInterval ,150));
  f^.Link(Msg,'DATAINT?','DATAINT','HOURS');
  Fields^.Add(DataInterval,f);

  f:=new(PChoiceInput,Init(WS,22,10,8,CurveType,Msg^.FindText('SMOOTHING')));
  f^.Link(Msg,'DISTRIB?','DISTRIB','');
  Fields^.Add(CurveType,f);

END; {PROC OwnModel.CreateFields}

PROCEDURE OwnModel.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
VAR
  f : PGenEdit;
BEGIN
  KilnModel.SetFields(Fields);
  f:=Fields^.Using(DataInterval);  PIntInput(f)^.Assign(DataInterval);
  f:=Fields^.Using(CurveType);     PIntInput(f)^.Assign(CurveType);
  f:=Fields^.Using(DryTime);       PIntInput(f)^.Assign(DryTime);
END; {PROC OwnModel.SetFields}

PROCEDURE OwnModel.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
BEGIN
  KilnModel.GetFields(Fields);
  Fields^.Fetch(DataInterval);
  Fields^.Fetch(CurveType);
  Fields^.Fetch(DryTime);
END; {PROC OwnModel.GetFields}

PROCEDURE OwnModel.PrintInfo;
BEGIN
  PrintLine(PadLeading('Egen modell :',' ',30)+WoodSortName[Material]^+', '+IntStr(DimY,0)+'x'+IntStr(DimX,0)+'mm');
  PrintLine(PadLeading(LookUp('TDC'),' ',30)+FloatStr(CondTDiff/10,4,1)+' '+LookUp('CELSIUS'));
  PrintLine(PadLeading(LookUp('HEATTIME'),' ',30)+IntStr(HeatTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('EQUTIME'),' ',30)+IntStr(EquTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('DRYTIME'),' ',30)+IntStr(DryTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('CONDTIME'),' ',30)+IntStr(CondTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('COOLTIME'),' ',30)+IntStr(CoolTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('TOTTIME'),' ',30)+IntStr(TotalTime,4)+' '+LookUp('HOURS'));
  PrintLine('');
END; {PROC OwnModel.PrintInfo}


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Model3 ÄÄÄ}
{ Description:
³   Specific Malmquist model 3 for kilns
}

CONSTRUCTOR Model3.Init;
{ - Initialize Malmquist model 3 object}
BEGIN
  KilnModel.Init(_CoolTime);
  MoistNow    := 100;
  MoistWanted := 17;
  Density     := 400;
  tWet        := 450;
  StartTDiff  := 10;
  Intensity   := 1.25;
  CharDryTime := 0;
END; {CONS Model3.Init}

CONSTRUCTOR Model3.Load(VAR S:LFStream);
{ - Initialize model3 object}
BEGIN
  KilnModel.Load(S);
  S.Read(MoistNow,SizeOf(MoistNow));
  S.Read(MoistWanted,SizeOf(MoistWanted));
  S.Read(Density,SizeOf(Density));
  S.Read(tWet,SizeOf(tWet));
  S.Read(StartTDiff,SizeOf(StartTDiff));
  S.Read(Intensity,SizeOf(Intensity));
  S.Read(CharDryTime,SizeOf(CharDryTime));
END; {CONS Model3.Load}

CONSTRUCTOR Model3.InitCopy(P:PKilnModel);
BEGIN
  KilnModel.InitCopy(P);
  IF (TypeOf(P^)=TypeOf(Model3)) or (TypeOf(P^)=TypeOf(ModelM1))
  THEN BEGIN
    MoistNow    := pModel3(P)^.MoistNow;
    MoistWanted := pModel3(P)^.MoistWanted;
    Density     := pModel3(P)^.Density;
    tWet        := pModel3(P)^.tWet;
    StartTDiff  := pModel3(P)^.StartTDiff;
    Intensity   := pModel3(P)^.Intensity;
    CharDryTime := pModel3(P)^.CharDryTime;
  END
  ELSE BEGIN
    MoistNow    := 100;
    MoistWanted := 17;
    Density     := 400;
    tWet        := 450;
    StartTDiff  := 10;
    Intensity   := 1.25;
    CharDryTime := 0;
  END;
END;

PROCEDURE Model3.Store(VAR S:LFStream);
{ - Store model3 object}
BEGIN
  KilnModel.Store(S);
  S.Write(MoistNow,SizeOf(MoistNow));
  S.Write(MoistWanted,SizeOf(MoistWanted));
  S.Write(Density,SizeOf(Density));
  S.Write(tWet,SizeOf(tWet));
  S.Write(StartTDiff,SizeOf(StartTDiff));
  S.Write(Intensity,SizeOf(Intensity));
  S.Write(CharDryTime,SizeOf(CharDryTime));
END; {PROC Model3.Store}


FUNCTION Model3.ApproxMoist(t:Integer):Float;
BEGIN
  ApproxMoist:=MoistNow/EXP(t/CharDryTime);
END;{FUNC Model3.ApproxMoist}


PROCEDURE Model3.Calculate(Cfg:pGenericCfg);
VAR
  TimeIndex : Integer; { Table time index }
  um1,         { ? Midlere fuktkvote (Startfukt kvote) ?}
  tom,         { ? }
  dif_tet,     { Diffusivitet eller diffusjonstetthet}
  kr_pshy_dif, { Kritisk psykrometer differanse}
  pshy_dif,    { Psykrometer differanse}
  my,          { ? }
  a1,          { ? }
  a2,          { ? }
  j,           { ? }
  exp_my_j,    { = EXP(-my*j) (Mellomregning)}
  fukt_dif,    { ? }
  overfl_fukt, { ? }
  midl_fukt,   { ? }
  DryT, WetT  : Float;  { ? }
BEGIN
    um1 := 25*sin(Intensity)/cos(Intensity)/(Intensity);

    tom := tWet/10 + 5*(((um1/18)-1)/(ln(um1/18))-1);

    dif_tet := 0.26E-10*exp(8.5*sqr(1-Density/1000)+2*ln(Density/450)
               +tom/33.4-1+Intensity*gauss((70-tom)/21)
               *gauss(DimY/40-40/DimY));

    CharDryTime := 1/dif_tet*sqr(DimY/2000/Intensity)/(1+DimY/DimX)/3600;

    DryTime := Round(charDryTime*ln(MoistNow/MoistWanted));

    kr_pshy_dif := 0.25*dif_tet*Density*2.4E6*Intensity*sin(Intensity)/
                   (varmeo_tall(DimY)*cos(Intensity)*DimY/2000);

    my := (2*gauss(7.8-8.42*Intensity)+5.06*Raise(1-2*Intensity/pi,1.118))*
          Intensity*sin(Intensity)/cos(Intensity);

    a1 := (0.411*gauss(6*(Intensity-1.425))-2.28*(Intensity -1.425))*
          Intensity*sin(Intensity)/cos(Intensity);

    a2 := -(0.143+0.165*Raise(Intensity,3))*ln(1-2*Intensity/PI);

    IF DryTime>500 THEN
    BEGIN

{      ActionMsg('Problem');
      center(1,80,21,Hi2,
        'T›rketiden overskrider '+IntStr(MaxData-120,0)+' timer !');
      center(1,80,23,Hi2,'Modellen kan ikke brukes. (Trykk en tast)');
      WaitForAnyKey;
      color(Hi1); gotoxy(1,23); clreol; gotoxy(1,21); clreol;
      MD3mnu.Entry:=1; }

      DryTime:=1;
    END
     ELSE
    BEGIN
      tt.SetSize(EquTime+DryTime+CondTime+1); {Init setpoint tables}
      tv.SetSize(EquTime+DryTime+CondTime+1); {Init setpoint tables}

      FOR TimeIndex:=0 TO EquTime             {Initial/Equ. setpoints}
      DO BEGIN
        tt.AtPut(TimeIndex,tWet+StartTDiff);
        tv.AtPut(TimeIndex,tWet);
      END;

      FOR TimeIndex:=1 TO DryTime { Drying Reference values }
      DO BEGIN
        j:=TimeIndex / charDryTime;

        exp_my_j    := EXP(-my*j);
        fukt_dif    := (1-exp_my_j)*(j+a1*sqrt(j)*exp_my_j+a2*(1-exp_my_j));
        overfl_fukt := MoistNow/EXP(fukt_dif);
        pshy_dif    := kr_pshy_dif*(1-EXP(-5/sqr(Intensity)*j))*overfl_fukt/25;

        IF overfl_fukt<=25
        THEN pshy_dif:=pshy_dif+5*((25/overfl_fukt)-1);

        DryT := tWet+(10*pshy_dif);
        WetT := tWet;

        IF DryT>700
        THEN BEGIN
          DryT:=700.0;
          WetT:=trunc(700-(10*pshy_dif));
        END;

        tt.AtPut(EquTime + TimeIndex, Trunc(DryT + StartTDiff));
        tv.AtPut(EquTime + TimeIndex, Trunc(WetT));
      END;

      { - Conditioning Reference values }
      DryT:=tt.At(EquTime+DryTime);
      FOR TimeIndex:=1 TO CondTime DO
      BEGIN
        tt.AtPut(EquTime+DryTime+TimeIndex,Trunc(DryT));
        tv.AtPut(EquTime+DryTime+TimeIndex,Trunc(DryT-CondTDiff));
      END;

      tt.Current:=tt.MaxSamples;
      tv.Current:=tv.MaxSamples;
    END;
END;{PROC Model3.Calculate}

PROCEDURE Model3.CreateFields(WS:PWorkSpace; VAR Fields:PFieldList);
{ - Create fields and initialize them }
VAR
  f : PGenEdit;
BEGIN
  KilnModel.CreateFields(WS,Fields);
  f:=new(PIntInput,Init(WS,22,4,4,           300,Density,600));
  f^.Link(Msg,'DENSITY?','DENSITY','DENSMEAS');
  Fields^.Add(Density,f);

  f:=new(PFloatInput,Init(WS,22,5,4,1,       30,tWet/10,KilnMaxTWet/10));
  f^.Link(Msg,'TWET?','WET-TEMP','CELSIUS');
  Fields^.Add(tWet,f);

  f:=new(PFloatInput,Init(WS,22,6,4,1,       0,StartTDiff/10,2.5));
  f^.Link(Msg,'TDS?','TDS','CELSIUS');
  Fields^.Add(StartTDiff,f);

  f:=new(PIntInput,Init(WS,22,8,4,          15,MoistNow,130));
  f^.Link(Msg,'SMOIST?','MOISTBEGIN','PERCENT');
  Fields^.Add(MoistNow,f);

  f:=new(PIntInput,Init(WS,22,9,4,          6,MoistWanted,25));
  f^.Link(Msg,'EMOIST?','MOISTEND','PERCENT');
  Fields^.Add(MoistWanted,f);

  f:=new(PFloatInput,Init(WS,22,10,4,2,      1.15,Intensity,1.45));
  f^.Link(Msg,'INTENS?','INTENSITY','');
  Fields^.Add(Intensity,f);
END; {PROC Model3.CreateFields}

PROCEDURE Model3.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
VAR
  f : PGenEdit;
BEGIN
  KilnModel.SetFields(Fields);
  f:=Fields^.Using(Density);       PIntInput(f)^.Assign(Density);
  f:=Fields^.Using(StartTDiff);    PFloatInput(f)^.Assign(StartTDiff/10);
  f:=Fields^.Using(tWet);          PFloatInput(f)^.Assign(tWet/10);
  f:=Fields^.Using(MoistNow);      PIntInput(f)^.Assign(MoistNow);
  f:=Fields^.Using(MoistWanted);   PIntInput(f)^.Assign(MoistWanted);
  f:=Fields^.Using(Intensity);     PFloatInput(f)^.Assign(Intensity);
END; {PROC Model3.SetFields}

PROCEDURE Model3.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
VAR
  f : PGenEdit;
BEGIN
  KilnModel.GetFields(Fields);
  Fields^.Fetch(Density);
  f:=Fields^.Using(StartTDiff);  StartTDiff:=Round(PFloatInput(f)^.Value*10);
  f:=Fields^.Using(tWet);        tWet:=Round(PFloatInput(f)^.Value*10);
  Fields^.Fetch(MoistNow);
  Fields^.Fetch(MoistWanted);
  Fields^.Fetch(Intensity);
END; {PROC Model3.GetFields}

PROCEDURE Model3.PrintInfo;
BEGIN
  Print(PadLeading('Modell 3 :',' ',30)+WoodSortName[Material]^+', '+IntStr(DimX,0)+'x'+IntStr(DimY,0)+'mm');
  PrintLine(', '+IntStr(Density,0)+' '+LookUp('DENSMEAS'));

  PrintLine(PadLeading(LookUp('WET-TEMP'),' ',30)+FloatStr(tWet/10,4,1)+' '+LookUp('CELSIUS'));
  PrintLine(PadLeading(LookUp('TDS'),' ',30)+FloatStr(StartTDiff/10,4,1)+' '+LookUp('CELSIUS'));
  PrintLine(PadLeading(LookUp('TDC'),' ',30)+FloatStr(CondTDiff/10,4,1)+' '+LookUp('CELSIUS'));

  PrintLine(PadLeading(LookUp('MOISTBEGIN'),' ',30)+IntStr(MoistNow,4)+' '+LookUp('PERCENT'));
  PrintLine(PadLeading(LookUp('MOISTEND'),' ',30)+IntStr(MoistWanted,4)+' '+LookUp('PERCENT'));
  PrintLine(PadLeading(LookUp('INTENSITY'),' ',30)+FloatStr(Intensity,4,2));

  PrintLine(PadLeading(LookUp('HEATTIME'),' ',30)+IntStr(HeatTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('EQUTIME'),' ',30)+IntStr(EquTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('DRYTIME'),' ',30)+IntStr(DryTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('CONDTIME'),' ',30)+IntStr(CondTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('COOLTIME'),' ',30)+IntStr(CoolTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('TOTTIME'),' ',30)+IntStr(TotalTime,4)+' '+LookUp('HOURS'));
  PrintLine('');
END; {PROC Model3.PrintInfo}

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ModelM1 ÄÄÄ}
{ Description:
³   Specific Malmquist ModelM1 for kilns
}

CONSTRUCTOR ModelM1.Init(_CoolTime:Integer);
{ - Initialize Malmquist ModelM1 object}
BEGIN
  Model3.Init(_CoolTime);
  Kernal:=40;
END; {CONS ModelM1.Init}

CONSTRUCTOR ModelM1.Load(VAR S:LFStream);
{ - Initialize ModelM1 object}
BEGIN
  Model3.Load(S);
  S.Read(Kernal,SizeOf(Kernal));
END; {CONS ModelM1.Load}

CONSTRUCTOR ModelM1.InitCopy(P:PKilnModel);
BEGIN
  Model3.InitCopy(P);
  IF TypeOf(P^)=TypeOf(ModelM1)
  THEN BEGIN
    Kernal  := pModelM1(P)^.Kernal;
  END
  ELSE BEGIN
    Kernal:=40;
  END;
END;

PROCEDURE ModelM1.Store(VAR S:LFStream);
{ - Store ModelM1 object}
BEGIN
  Model3.Store(S);
  S.Write(Kernal,SizeOf(Kernal));
END; {PROC ModelM1.Store}


FUNCTION ModelM1.ApproxMoist(t:Integer):Float;
BEGIN
  ApproxMoist:=MoistNow/EXP(t/CharDryTime);
END;{FUNC ModelM1.ApproxMoist}


PROCEDURE ModelM1.Calculate(Cfg:pGenericCfg);
VAR
  TimeIndex,
           {Variables specific for M1}
  max_DryT,    { maximum dry temperature }
  max_pshy_dif : Integer; { maximum pshykrometer difference}
  Hast,        { Lufthastighet }
  Dybde,       { Bl†sedybde }
  FuktGrad,    { Fuktgradient i overflaten }
  T1,          { Tid for fibermetning }
  T2,          { Tid for spenningsskifting }
  T3,          { T›rketid, Real }
  Lambda,      { Hjelpevariabel }
  C1,
  C2,
  C3,
  tWood,       { Tretemperatur }
  w_overfl,    { Overflate-fuktkvote }
  kr_pshy_dif1,{ Kritisk psykrometer-differanse ved styring av Ttmiddel }
  um1,         { ? Midlere fuktkvote (Startfukt kvote) ?}
  tom,         { ? }
  dif_tet,     { Diffusivitet eller diffusjonstetthet}
  kr_pshy_dif, { Kritisk psykrometer differanse}
  pshy_dif,    { Psykrometer differanse}
  my,          { ? }
  a1,          { ? }
  a2,          { ? }
  j,           { ? }
  exp_my_j,    { = EXP(-my*j) (Mellomregning)}
  fukt_dif,    { ? }
  overfl_fukt, { ? }
  midl_fukt,   { ? }
  DryT, WetT,
  a,           { Kladdeparametre M1 }
  b,
  c,
  d,
  e,
  f,
  g,
  h           : Float;

  Function Diff(x:integer):Float;
  VAR
  ns,nk      : Integer;
  a,          { Hjelpevariabel}
  myk,        { Kjerneved-andel (0-1)}
  Fw,
  Fmyk,
  Fd,
  Ft         : Float;

  BEGIN

    ns  := 6;
    nk  := 4;
    myk := Kernal/100; {0.7 - LF}
    max_pshy_dif := 280;

    IF x=0       { F›r spenningsomvandling (T < T2)}
    THEN
      BEGIN
        Fw := 1;
        Ft := Gauss((706-tWet)/216);
        Fd := Gauss(2.4*(1-(2*15/DimY)));
        Fmyk := exp(ns*0.26);
        a := Intensity*Ft*Fd+tWet/334;
      END;
    IF x = 1
    THEN
      BEGIN
        IF tWet + 280 > Max_DryT
        THEN  Dryt := Max_DryT;

        IF tWet + 280 <= Max_DryT
        THEN  DryT := tWet + max_pshy_dif;

        tWood := DryT - 280*(0.6 -(1/(1+max_pshy_dif/50)));
        Fw := 1-(1-0.6)*(1-0.6);
        Fmyk := myk*exp(0.26*nk)+(1-myk)*exp(0.26*ns);
        a := tWood/334;
      END;
    Diff := 140/Density*Fw*Fmyk/1E10*exp(a);

  END; {Function Diff}

  BEGIN
    max_DryT := Cfg^.MaxTDry;  {750 LF}

    Hast := pKilnCfg(Cfg)^.AirSpeed; { 3.0 LF}

    Dybde := pKilnCfg(Cfg)^.BlowDepth; {0.15 LF}

  { Grunnlagsdata for modell 3 }

  { um1 := 25*sin(Intensity)/cos(Intensity)/(Intensity);

    tom := tWet/10 + 5*(((um1/18)-1)/(ln(um1/18))-1);

    dif_tet := (140/Density*Fw*Fmyk)E-10*exp(a);

    CharDryTime := 1/dif_tet*sqr(DimY/2000/Intensity)/(1+DimY/DimX)/3600;

    DryTime := Round(charDryTime*ln(MoistNow/MoistWanted));

    kr_pshy_dif := 0.25*dif_tet*Density*2.4E6*Intensity*sin(Intensity)/
                   (varmeo_tall(DimY)*cos(Intensity)*DimY/2000);

    my := (2*gauss(7.8-8.42*Intensity)+5.06*Raise(1-2*Intensity/pi,1.118))*
          Intensity*sin(Intensity)/cos(Intensity);

    a1 := (0.411*gauss(6*(Intensity-1.425))-2.28*(Intensity -1.425))*
          Intensity*sin(Intensity)/cos(Intensity);

    a2 := -(0.143+0.165*Raise(Intensity,3))*ln(1-2*Intensity/PI);}

    { Grunnlagsdata for modell M1 }

    a := sin(Intensity);
    b := cos(Intensity);

    C3 := 3/4*(2+b-Intensity/a*(1+2*b))/(1-b)/a/a;
    C2 := -(1+4*C3*b*(1+b))/(1+2*b);
    C1 := 1-C2-C3;

    c := Diff(0);

    CharDryTime := 1/c*sqr(DimY/2000/Intensity)*DimX/(DimY+DimX)/3600;

    b := 8*exp(0.67*ln(Hast));

    kr_pshy_dif := 0.25*c*Density*2.4E6/b/(DimY/2000);

    { Iterering for † bestemme T1, fibermetning i overflaten}

    T1:=0;                {Endring: Satt inn for † tillate }
    IF MoistNow >= 25     {Endring: startfukt < 25% }
    THEN BEGIN            {Endring: }
      a := 0;
      b := 2*CharDryTime;
      c := 1;
        REPEAT
          T1 := (a+b)/2;
          e := C1*cos(Intensity)*exp(-T1/CharDryTime);
          f := C2*cos(2*Intensity)*exp(-4*T1/CharDryTime);
          g := C3*cos(3*Intensity)*exp(-9*T1/CharDryTime);
          d := MoistNow/25*(e+f+g);
          IF d>c THEN a:=T1 ELSE b:=T1;
        UNTIL abs(d-c) < 0.01;
     END;
      { Iterering for † bestemme T2, spenningsskifting i overflaten}

    a := 0;
    b := 5*CharDryTime;
    c := 0.6;
      REPEAT
        T2 := (a+b)/2;
        e := C1*sin(Intensity)/Intensity*exp(-T2/CharDryTime);
        f := C2*sin(2*Intensity)/(2*Intensity)*exp(-4*T2/CharDryTime);
        g := C3*sin(3*Intensity)/(3*Intensity)*exp(-9*T2/CharDryTime);
        d := MoistNow/25*(e+f+g);
        IF d>c THEN a:=T2 ELSE b:=T2;
      UNTIL abs(d-c) < 0.0001;

      { Iterering for † bestemme T›rketiden }

    IF MoistWanted >= 15
    THEN
      BEGIN
        a := 0;
        b := 5*CharDryTime;
        c := MoistWanted/25;
        REPEAT
          T3 := (a+b)/2;
          e := C1*sin(Intensity)/Intensity*exp(-T3/CharDryTime);
          f := C2*sin(2*Intensity)/(2*Intensity)*exp(-4*T3/CharDryTime);
          g := C3*sin(3*Intensity)/(3*Intensity)*exp(-9*T3/CharDryTime);
          d := MoistNow/25*(e+f+g);
          IF d>c THEN a:=T3 ELSE b:=T3;
        UNTIL abs(d-c) < 0.0001;
      END;

      IF MoistWanted < 15
      THEN
        BEGIN
          c := Diff(1);
          a := 1/c*sqr(DimY/2000/Intensity)*DimX/(DimY+DimX)/3600;
          b := 1/(1+max_pshy_dif/50);

          T3 := (T2+a*ln((0.6-b)/(MoistWanted/25-b)));
          DryTime := round(T3);
        END;

      DryTime := trunc(T3);

    IF DryTime>500 THEN
    BEGIN

{      ActionMsg('Problem');
      center(1,80,21,Hi2,
        'T›rketiden overskrider '+IntStr(MaxData-120,0)+' timer !');
      center(1,80,23,Hi2,'Modellen kan ikke brukes. (Trykk en tast)');
      WaitForAnyKey;
      color(Hi1); gotoxy(1,23); clreol; gotoxy(1,21); clreol;
      MD3mnu.Entry:=1; }

      DryTime:=1;
    END
     ELSE
    BEGIN
      tt.SetSize(EquTime+DryTime+CondTime+1); {Init setpoint tables}
      tv.SetSize(EquTime+DryTime+CondTime+1); {Init setpoint tables}

      FOR TimeIndex:= 0 TO EquTime             {Initial/Equ. setpoints}
      DO BEGIN
        tt.AtPut(TimeIndex,tWet+StartTDiff);
        tv.AtPut(TimeIndex,tWet);
      END;

      FOR TimeIndex:= 1 TO DryTime { Drying Reference values }
      DO BEGIN
        j:=TimeIndex / charDryTime;

      { exp_my_j    := EXP(-my*j);
        fukt_dif    := (1-exp_my_j)*(j+a1*sqrt(j)*exp_my_j+a2*(1-exp_my_j));
        overfl_fukt := MoistNow/EXP(fukt_dif);
        pshy_dif    := kr_pshy_dif*(1-EXP(-5/sqr(Intensity)*j))*overfl_fukt/25;

        IF overfl_fukt<=25
        THEN pshy_dif:=pshy_dif+5*((25/overfl_fukt)-1);
        }


        e := C1*sin(Intensity)*Intensity*exp(-j);
        f := C2*sin(2*Intensity)*(2*Intensity)*exp(-4*j);
        g := C3*sin(3*Intensity)*(3*Intensity)*exp(-9*j);
        FuktGrad := MoistNow/25*(e+f+g);

        IF TimeIndex < T2 THEN
          BEGIN
            IF TimeIndex <= T1  THEN b := 0;
            IF TimeIndex > T1 THEN
              BEGIN
                e := C1*cos(Intensity)*exp(-j);
                f := C2*cos(2*Intensity)*exp(-4*j);
                g := C3*cos(3*Intensity)*exp(-9*j);

                w_overfl := MoistNow/25*(e+f+g);

                b := 5*(1/w_overfl-1);
              END;
            Lambda := 16/25*exp(-0.33*ln(Hast));
            h := 1-exp(-Lambda*Dybde);
            kr_pshy_dif1 := kr_pshy_dif*Lambda*Dybde/2*(2-h)/h;

            pshy_dif := kr_pshy_dif1*FuktGrad+b;
          END;

        IF TimeIndex >= T2 THEN
          BEGIN
            pshy_dif := 28;
            DryT := tWet+280;
            WetT := tWet;
          END;

        DryT := tWet+(10*pshy_dif);
        WetT := tWet;

        IF DryT>Max_DryT
        THEN BEGIN
          DryT:=Max_DryT;
          WetT:=trunc(Max_DryT-(10*pshy_dif));
        END;

        tt.AtPut(EquTime + TimeIndex, Trunc(DryT + StartTDiff));
        tv.AtPut(EquTime + TimeIndex, Trunc(WetT));
      END;

      { - Conditioning Reference values }
      DryT:=tt.At(EquTime+DryTime);
      FOR TimeIndex:=1 TO CondTime DO
      BEGIN
        tt.AtPut(EquTime+DryTime+TimeIndex,Trunc(DryT));
        tv.AtPut(EquTime+DryTime+TimeIndex,Trunc(DryT-CondTDiff));
      END;

      tt.Current:=tt.MaxSamples;
      tv.Current:=tv.MaxSamples;
    END;
END;{PROC ModelM1.Calculate}

PROCEDURE ModelM1.CreateFields(WS:PWorkSpace; VAR Fields:PFieldList);
{ - Create fields and initialize them }
VAR
  f : PGenEdit;
BEGIN
  Model3.CreateFields(WS,Fields);
  f:=new(PFloatInput,Init(WS,22,11,4,1,       0,Kernal,100));
  f^.Link(Msg,'KERNAL?','KERNAL','PERCENT');
  Fields^.Add(Kernal,f);
END; {PROC ModelM1.CreateFields}

PROCEDURE ModelM1.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
VAR
  f : PGenEdit;
BEGIN
  Model3.SetFields(Fields);
  f:=Fields^.Using(Kernal);     PFloatInput(f)^.Assign(Kernal);
END; {PROC ModelM1.SetFields}

PROCEDURE ModelM1.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
VAR
  f : PGenEdit;
BEGIN
  Model3.GetFields(Fields);
  Fields^.Fetch(Kernal);
END; {PROC ModelM1.GetFields}

PROCEDURE ModelM1.PrintInfo;
BEGIN
  Print(PadLeading('Modell M1 :',' ',30)+WoodSortName[Material]^+', '+IntStr(DimX,0)+'x'+IntStr(DimY,0)+'mm');
  PrintLine(', '+IntStr(Density,0)+' '+LookUp('DENSMEAS'));

  PrintLine(PadLeading(LookUp('WET-TEMP'),' ',30)+FloatStr(tWet/10,4,1)+' '+LookUp('CELSIUS'));
  PrintLine(PadLeading(LookUp('TDS'),' ',30)+FloatStr(StartTDiff/10,4,1)+' '+LookUp('CELSIUS'));
  PrintLine(PadLeading(LookUp('TDC'),' ',30)+FloatStr(CondTDiff/10,4,1)+' '+LookUp('CELSIUS'));

  PrintLine(PadLeading(LookUp('MOISTBEGIN'),' ',30)+IntStr(MoistNow,4)+' '+LookUp('PERCENT'));
  PrintLine(PadLeading(LookUp('MOISTEND'),' ',30)+IntStr(MoistWanted,4)+' '+LookUp('PERCENT'));
  PrintLine(PadLeading(LookUp('INTENSITY'),' ',30)+FloatStr(Intensity,4,2));
  PrintLine(PadLeading(LookUp('KERNAL'),' ',30)+FloatStr(Kernal,4,1));

  PrintLine(PadLeading(LookUp('HEATTIME'),' ',30)+IntStr(HeatTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('EQUTIME'),' ',30)+IntStr(EquTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('DRYTIME'),' ',30)+IntStr(DryTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('CONDTIME'),' ',30)+IntStr(CondTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('COOLTIME'),' ',30)+IntStr(CoolTime,4)+' '+LookUp('HOURS'));
  PrintLine(PadLeading(LookUp('TOTTIME'),' ',30)+IntStr(TotalTime,4)+' '+LookUp('HOURS'));
  PrintLine('');
END; {PROC ModelM1.PrintInfo}


{------------------------------------------------------------- TunnelModel ---
  Description:
    Generic tunnel model information
}

CONSTRUCTOR TunnelModel.Init;
{ - Initialize basis kiln model}
BEGIN
  ModelType.Init;
  sptv:=550;
  sptt:=600;
  delta_t:=20; { 2.0 øC }
  HeatTime:=2*60; { 2 hours }
  PSNew(Comment2,'');
  PSNew(Comment3,'');
END; {CONS TunnelModel.Init}

CONSTRUCTOR TunnelModel.Load(VAR S:LFStream);
{ - Initialize model object}
BEGIN
  ModelType.Load(S);
  S.Read(delta_t,SizeOf(Delta_T));
  S.Read(HeatTime,SizeOf(HeatTime));
  S.Read(sptv,SizeOf(sptv));
  S.Read(sptt,SizeOf(sptt));
  Comment2:=S.ReadStr;
  Comment3:=S.ReadStr;
END; {CONS TunnelModel.Load}

PROCEDURE TunnelModel.Store(VAR S:LFStream);
{ - Store TunnelModel object}
BEGIN
  ModelType.Store(S);
  S.Write(delta_t,SizeOf(Delta_T));
  S.Write(HeatTime,SizeOf(HeatTime));
  S.Write(sptv,SizeOf(sptv));
  S.Write(sptt,SizeOf(sptt));
  S.WriteStr(Comment2);
  S.WriteStr(Comment3);
END; {PROC TunnelModel.Store}

DESTRUCTOR  TunnelModel.Done;
{ - }
BEGIN
  PSDispose(Comment3);
  PSDispose(Comment2);
  ModelType.Done;
END; {DEST TunnelModel.Done}

PROCEDURE TunnelModel.Calculate(Cfg:pGenericCfg);
{ - Calculate model data from parameters }
BEGIN
  tt.AtPut(0,sptt);
  tv.AtPut(0,sptv);
END; {PROC TunnelModel.Calculate}

FUNCTION TunnelModel.TotalTime;
{ - Return accumulated total time for model }
BEGIN
  TotalTime:=TotalHours;
END; {PROC TunnelModel.TotalTime}

PROCEDURE TunnelModel.CreateFields(WS:PWorkSpace; VAR Fields:PFieldList);
{ - Create fields and initialize them }
VAR
  f : PGenEdit;
BEGIN
  f:=new(PFloatInput,Init(WS,22,1,4,1,       30,sptv/10,TunnelMaxTWet/10));
  f^.Link(Msg,'WET-TEMP?','WET-TEMP','CELSIUS');
  Fields^.Add(sptv,f);

  f:=new(PFloatInput,Init(WS,22,2,4,1,       30, sptt/10, TunnelMaxTDry/10));
  f^.Link(Msg,'DRY-TEMP?','DRY-TEMP','CELSIUS');
  Fields^.Add(sptt,f);

  f:=new(PStrPInput,Init(WS,22,3,15,         Comment,[#32..#127]+NorskSet,False));
  f^.Link(Msg,'MDLCMNT?','MDLCMNT','');
  Fields^.Add(Comment,f);

{$IFDEF UseDeltaT}
  f:=new(PFloatInput,Init(WS,22,4,4,2,       0,delta_t/10,3));
  f^.Link(Msg,'DELTAHEAT?','DELTAHEAT','CELSIUS');
  Fields^.Add(delta_t,f);

  f:=new(PIntInput,Init(WS,22,5,4,           0, HeatTime, 4*60));
  f^.Link(Msg,'HEATTIME?','HEATTIME','MINUTES');
  Fields^.Add(HeatTime,f);
{$ENDIF}

END; {PROC TunnelModel.CreateFields}


PROCEDURE TunnelModel.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
VAR
  f : PGenEdit;
BEGIN
  f:=Fields^.Using(sptv);       PFloatInput(f)^.Assign(sptv/10);
  f:=Fields^.Using(sptt);       PFloatInput(f)^.Assign(sptt/10);
  f:=Fields^.Using(Comment);    PStrPInput(f)^.Assign(comment^);
{$IFDEF UseDeltaT}
  f:=Fields^.Using(delta_t);    PFloatInput(f)^.Assign(delta_t/10);
  f:=Fields^.Using(heattime);   PIntInput(f)^.Assign(heattime);
{$ENDIF}
END; {PROC TunnelModel.SetFields}

PROCEDURE TunnelModel.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
VAR
  f : PGenEdit;
BEGIN
  f:=Fields^.Using(sptv);     sptv:=Round(PFloatInput(f)^.Value*10);
  f:=Fields^.Using(sptt);     sptt:=Round(PFloatInput(f)^.Value*10);
  PSDispose(Comment);  Fields^.Fetch(Comment);
{$IFDEF UseDeltaT}
  f:=Fields^.Using(delta_t);  delta_t:=Round(PFloatInput(f)^.Value*10);
  Fields^.Fetch(heattime);
{$ENDIF}
END; {PROC TunnelModel.GetFields}

FUNCTION TunnelModel.Describe:String;
BEGIN
  Describe:=PadTrailing(Copy(Comment^,1,15),' ',15);
END; {FUNC TunnelModel.Describe}

PROCEDURE TunnelModel.PrintInfo;
BEGIN
  PrintLine(PadLeading(LookUp('WET-TEMP'),' ',30)+FloatStr(sptv/10,4,1)+' '+LookUp('CELSIUS'));
  PrintLine(PadLeading(LookUp('DRY-TEMP'),' ',30)+FloatStr(sptt/10,4,1)+' '+LookUp('CELSIUS'));
  IF Comment^<>''
  THEN PrintLine(PadLeading(LookUp('MDLCMNT'),' ',30)+Comment^);
{$IFDEF UseDeltaT}
  IF Delta_t<>0
  THEN PrintLine(PadLeading(LookUp('DELTAHEAT'),' ',30)+FloatStr(delta_t/10,4,1)+' '+LookUp('CELSIUS'));
  IF HeatTime<>0
  THEN PrintLine(PadLeading(LookUp('HEATTIME'),' ',30)+IntStr(HeatTime,4)+' '+LookUp('HOURS'));
{$ENDIF}
  PrintLine('');
END; {PROC TunnelModel.PrintInfo}


{------------------------------------------------------------------ Init's ---
}

PROCEDURE RegisterKilnModels;
{ - Object stream registration for kiln models}
BEGIN
  RegisterType(ModelType_OSR);
  RegisterType(KilnModel_OSR);
  RegisterType(OwnModel_OSR);
  RegisterType(Model3_OSR);
  RegisterType(TunnelModel_OSR);
  RegisterType(ModelM1_OSR);
END; {PROC RegisterKilnModels}

VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}
CONST
  P4ModelMsg = ' P4Model ';

PROCEDURE P4ModelExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitHandler;
  Units.Leave(P4ModelMsg,MemAvail);
END; {PROC P4ModelExitHandler}

BEGIN {Init part of P4Models}
  PrevExitHandler:=ExitProc;
  ExitProc:=@P4ModelExitHandler;
  Units.Enter(P4ModelMsg,MemAvail,CSeg);
  RegisterKilnModels;
END.

