{$I CODEDEFS.PAS} {Include code generation definitions}
{$X+}
UNIT P4U_Kiln;

INTERFACE
USES
  Dos,Objects, LFCrt,
  LFsystem, LFExtMsg, LFDraw, PLCDrive, LFWindow, LFGfxWin,
  P4Config, P4Model, P4U_Gen;

TYPE
  PKilnUnit = ^KilnUnit;
  KilnUnit = OBJECT(GenericUnit)
    EquStart   : DateTime;   {Stored}
    PhaseStart : DateTime;   {Stored}
    CONSTRUCTOR Init(NewCfg:PGenericCfg);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);     VIRTUAL;
    FUNCTION    ParamEdit(WS:PWorkSpace):Char; VIRTUAL;
    PROCEDURE   ParamView(WS:PWorkSpace); VIRTUAL;
    PROCEDURE   PrintInfo;                VIRTUAL;
    PROCEDURE   TimeView(Win:PGfxWin);    VIRTUAL;
    FUNCTION    MakeOpMenu:PMenuTxt;      VIRTUAL;
    FUNCTION    StartOK:Boolean;          VIRTUAL;
    PROCEDURE   Operation;                VIRTUAL;
    PROCEDURE   Chart;                    VIRTUAL;
    PROCEDURE   MakeDiagram;              VIRTUAL;
    PROCEDURE   PLCWrite;                 VIRTUAL;
    PROCEDURE   PLCRead;                  VIRTUAL;
    PROCEDURE   ResumeProcess;            VIRTUAL;
    PROCEDURE   StartProcess;             VIRTUAL;
    PROCEDURE   UpdateProcess;            VIRTUAL;
    PROCEDURE   StopProcess;              VIRTUAL;
    FUNCTION    UpdateDue:Boolean;        VIRTUAL;
    FUNCTION    Describe:String;          VIRTUAL;
    FUNCTION    TotalTime:Integer;        VIRTUAL;
  END; {OBJ KilnUnit}

CONST
  KilnUnit_OID = 10022;
  KilnUnit_OSR: TStreamRec = (
    ObjType: KilnUnit_OID;
    VmtLink: Ofs(TypeOf(KilnUnit)^);
    Load:    @KilnUnit.Load;
    Store:   @KilnUnit.Store
  );

IMPLEMENTATION
USES
  Crt,Graph,LFGraph, LFtable,LFString,LFDos,
  ObjInput,AGTools,P4Limits;

{------------------------------------------------------------- KilnUnit ---
  Description

}

CONSTRUCTOR KilnUnit.Init(NewCfg:PGenericCfg);
{ - Initialize kiln with connected Config info }
BEGIN
  GenericUnit.Init(NewCfg);
  Model:=New(PModel3,Init(PKilnCfg(NewCfg)^.CoolLimit));
END; {CONS KilnUnit.Init}

CONSTRUCTOR KilnUnit.Load(VAR S:TStream);
{ - Load stored kiln and re-connect Config info}
VAR
  VerID : Integer;
BEGIN
  GenericUnit.Load(S);
  S.Read(EquStart,SizeOf(EquStart));
  S.Read(PhaseStart,SizeOf(PhaseStart));

  IF IsVersion<BackupVersion    {If updating an old version of the bku file}
  THEN BEGIN
    FOR VerID:=IsVersion TO BackupVersion
    DO BEGIN
      CASE VerID OF
        0 : {Do nothing};
      END;
    END;
  END;

END; {CONS KilnUnit.Load}

PROCEDURE KilnUnit.Store(VAR S:TStream);
{ - Store kiln _without_ Config info}
BEGIN
  GenericUnit.Store(S);
  S.Write(EquStart,SizeOf(EquStart));
  S.Write(PhaseStart,SizeOf(PhaseStart));
END; {PROC KilnUnit.Store}

PROCEDURE RedrawKlnChart(K:PGenericUnit); FAR;
  PROCEDURE PlotModel;
  VAR
    n,v : Integer;
    t   : Float;
    M   : PKilnModel;
  BEGIN
    IF K^.Interrupted THEN Exit;  {Exit if key pressed}
    M:=PKilnModel(K^.Model);      {This is our model}

    SetColor(Red);
    WSC.SetAll(Red,PaleYellow);
    IF TypeOf(K^.Cfg^)<>TypeOf(MdlCfg)
    THEN WSWrt('Ý '+K^.Register(ttSet)^.name^+' ')
    ELSE WSWrt('Ý t-t›rr ');
    IF K^.KilnMode<>Stopped
    THEN t:=M^.HeatTime
    ELSE t:=0;
    Graf.PointTo(t,M^.tt.At(0));
    FOR n:=1 TO M^.ModelTime
    DO BEGIN
      t:=t+1;
      Graf.LineTo(t,M^.tt.At(n));
    END;

    SetColor(Blue);
    WSC.SetAll(Blue,PaleYellow);
    IF TypeOf(K^.Cfg^)<>TypeOf(MdlCfg)
    THEN WSWrt('Ý '+K^.Register(tvSet)^.name^+' ')
    ELSE WSWrt('Ý t-v†t ');
    IF K^.KilnMode<>Stopped
    THEN t:=M^.HeatTime
    ELSE t:=0;
    Graf.PointTo(t,M^.tv.At(0));
    FOR n:=1 TO M^.ModelTime
    DO BEGIN
      t:=t+1;
      Graf.LineTo(t,M^.tv.At(n));
    END;
    K^.Interrupted:=KeyPressed;
  END;

  PROCEDURE Plot(ID:Word; Color:Integer);
  VAR
    n,v  : Integer;
    t,dt : Float;
    Temperature : PAvgIntSampler;
  BEGIN
    IF K^.Interrupted THEN Exit;
    SetColor(Color);
    Temperature:=K^.Log^.Register(ID);
    t:=0; dt:=1/SamplesPerHour;
    v:=Temperature^.At(0);
    IF v<MinScale THEN v:=MinScale
    ELSE IF v>MaxScale THEN v:=MaxScale;
    Graf.PointTo(t,v);
    WSC.SetAll(Color,PaleYellow);
    WSWrt('Ý '+K^.Register(ID)^.name^+' ');
    FOR n:=1 TO Temperature^.Current
    DO BEGIN
      t:=t+dt;
      v:=Temperature^.At(n);
      IF v<MinScale THEN v:=MinScale
      ELSE IF v>MaxScale THEN v:=MaxScale;
      Graf.LineTo(t,v);
    END;
    v:=Temperature^.Last;
    IF v<MinScale THEN v:=MinScale
    ELSE IF v>MaxScale THEN v:=MaxScale;
    Graf.LineTo(t,v);
    K^.Interrupted:=KeyPressed;
  END;
BEGIN
  K^.Interrupted:=KeyPressed;
  IF K^.Interrupted THEN Exit;
  WSClear;
  SetTextStyle(SmallFont, HorizDir,5);
  WSWrtXY(1,23,'');
  IF K^.KilnMode<>Stopped
  THEN Graf.World(-1,MinScale,K^.Model^.TotalTime+1,MaxScale)
  ELSE Graf.World(-1,MinScale,K^.Model^.ModelTime+1,MaxScale);
  Graf.xScale(DottedLn);
  Graf.yScale(DottedLn);
  SetLineStyle(SolidLn,0,3);
  PlotModel;
  SetLineStyle(SolidLn,0,LnWidth);
  IF K^.KilnMode<>Stopped
  THEN CASE GrafPart OF
    1 : BEGIN
          Plot(tv1,LightBlue);
          Plot(tt1,LightRed);
        END;
    2 : BEGIN
          Plot(tt2,LightRed);
          Plot(tt3,LightBlue);
        END;
  END;
  SetLineStyle(SolidLn,0,1);
  IF K^.Interrupted THEN Exit;
  WSC.SetBG(WSBG);
  WSWrt('Ý');
END; {PROC RedrawKlnChart}

FUNCTION KilnUnit.ParamEdit(WS:PWorkSpace):Char;
{ - }
VAR
  Win : PGfxWin;
  Key : PKeyStroke;
  OK,Quit  : Boolean;
  ch : Char;
  tt : String;
BEGIN
  New(Win,InitTxt(20,10,40,16,True));
  Win^.Title(LookUp('PARAMTITLE')+Cfg^.Name^,LookUp('ESC=EXIT'));
  Win^.TxtAdjSize(40,16);
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  New(Key,Init(WorkSpace,0,0,[F9,ESC,^M],True));
  Key^.LastInput:=$001B; {Esc}
  REPEAT
    Quit:=False;
    Win^.Open;
    ch:=GenericUnit.ParamEdit(Win^.WorkSpace);
    OK:=ch<>Esc;
    Win^.Close;
    IF OK
    THEN BEGIN
      Graf.Init(WorkSpace^.Left,WorkSpace^.Top+1,
                WorkSpace^.Width-20,WorkSpace^.Height-20,-1,-1);
      Graf.ysf:=10;
      Refresh:=RedrawKlnChart;
      Redraw;
      Refresh:=NoRefresh;
      Graf.Done;
      Win^.TxtAdjSize(40,10);
      Win^.MoveRel(0,170);
      IF TypeOf(Cfg^)=TypeOf(MdlCfg)
      THEN tt:=LookUp('ESC=LOGIN')
      ELSE BEGIN
        tt:=LookUp('F9/ESC');
        Win^.C.Title.SetAllBG(Red);
      END;
      Win^.Title(LookUp('TIMEUSAGE'), tt);
      Win^.Open;
      TimeView(Win);
      Key^.WaitForValid;
      Quit:=Key^.LastChar in [ESC,F9];
      Win^.Close;
      Win^.C.Title.SetAllBG(Blue);
      Win^.MoveRel(0,-170);
      Win^.Title(LookUp('PARAMTITLE')+Cfg^.Name^,LookUp('ESC=EXIT'));
      Win^.TxtAdjSize(40,16);
    END
    ELSE Quit:=True;
  UNTIL Quit;
  ParamEdit:=(Key^.LastChar);
  Dispose(Key,Done);
  Dispose(Win,Done);
END; {PROC KilnUnit.ParamEdit}

PROCEDURE KilnUnit.ParamView(WS:PWorkSpace);
{ - }
VAR
  Win : PGfxWin;
BEGIN
  New(Win,InitTxt(20,10,40,16,True));
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  Win^.Title(LookUp('PARAMTITLE')+Cfg^.Name^,LookUp(''));
  Win^.Open;
  GenericUnit.ParamView(Win^.WorkSpace);
  Win^.Clear;
  TimeView(Win);
  WaitForAnyKey('PARAMVIEW');
  Dispose(Win,Done);
END; {PROC KilnUnit.ParamView}

PROCEDURE KilnUnit.TimeView(Win:PGfxWin);
VAR
  WS     : PWorkSpace;
  Fields : PFieldList;
  f      : PGenEdit;
  M      : PKilnModel;
  tot    : Integer;
  When   : DateTime;
BEGIN
  WS:=Win^.WorkSpace;
  New(Fields,Init);
  M:=PKilnModel(Model);

  f:=new(PIntInput,Init(WS,22,1,4,           0,M^.HeatTime,24));
  f^.Link(Msg,'','HEATTIME','HOURS');
  Fields^.Add(M^.HeatTime,f);

  f:=new(PIntInput,Init(WS,22,2,4,           0,M^.EquTime,24));
  f^.Link(Msg,'','EQUTIME','HOURS');
  Fields^.Add(M^.EquTime,f);

  f:=new(PIntInput,Init(WS,22,3,4,           0, M^.DryTime, 500));
  f^.Link(Msg,'','DRYTIME','HOURS');
  Fields^.Add(M^.DryTime,f);

  f:=new(PIntInput,Init(WS,22,4,4,           0, M^.CondTime, 72));
  f^.Link(Msg,'','CONDTIME','HOURS');
  Fields^.Add(M^.CondTime,f);

  f:=new(PIntInput,Init(WS,22,5,4,           0, M^.CoolTime, 72));
  f^.Link(Msg,'','COOLTIME','HOURS');
  Fields^.Add(M^.CoolTime,f);

  tot:=M^.TotalTime;
  f:=new(PIntInput,Init(WS,22,7,4,           0, tot, 500));
  f^.Link(Msg,'','TOTTIME','HOURS');
  Fields^.Add(M^.CoolTime,f);

  IF KilnMode=Stopped
  THEN StartWatch(When)  { Time from now (when not running)}
  ELSE When:=StartTime;  { or time from started}

  IncSeconds(When,LongInt(tot)*3600);
  f:=new(PStrInput,Init(WS,22,8,11,  Lookwatch(When),[],False));
  f^.Link(Msg,'','DONETIME','');
  Fields^.Add(When,f);

  Fields^.Display;
  Dispose(Fields,Done);
END; {PROC KilnUnit.TimeView}

PROCEDURE KilnUnit.PrintInfo;
VAR
  When : DateTime;
BEGIN
  GenericUnit.PrintInfo;
  IF KilnMode=Stopped
  THEN StartWatch(When)  { Time from now (when not running)}
  ELSE When:=StartTime;  { or time from started}
  IncSeconds(When,LongInt(pKilnModel(Model)^.TotalTime)*3600);
  PrintLine(PadLeading('Antatt ferdig :',' ',30)+LookWatch(When));
END; {PROC KilnUnit.PrintInfo}

FUNCTION KilnUnit.MakeOpMenu:PMenuTxt;
VAR
  Mnu : pMenuTxt;
BEGIN
  IF KilnMode=Stopped
  THEN BEGIN
    Mnu:=Msg^.FindMenu('KLNSTPMNU');
    IF Cfg^.Remote
    THEN Mnu^.LineDisable(1)
    ELSE Mnu^.LineEnable(1);
  END
  ELSE BEGIN
    Mnu:=Msg^.FindMenu('KLNRUNMNU');
    IF Cfg^.Remote
    THEN Mnu^.LineDisable(4)
    ELSE Mnu^.LineEnable(4);
  END;
  MakeOpMenu:=Mnu;
END; {FUNC KilnUnit.MakeOpMenu}

FUNCTION KilnUnit.StartOK:Boolean;
CONST
  Prev : Integer = 1;
VAR
  k   : PGenericUnit;
  win : PGfxWin;
  mnu : PMenuInput;
  ok  : Boolean;
  OldModel : PKilnModel;
BEGIN
  New(Win,InitTxt(30,20,30,10,True));
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  Win^.Title(LookUp(''), Cfg^.Name^);
  New(Mnu, Init(Win, 10, Msg^.FindMenu('MDLSLCT')));
  mnu^.Current:=1;
  mnu^.Select;
  ok:=True;
  OldModel:=pKilnModel(Model);
  CASE mnu^.Choice OF
    1 : Model:=New(pModelM1, InitCopy(OldModel));
    2 : Model:=New(pModel3, InitCopy(OldModel));
    3 : Model:=New(pOwnModel, InitCopy(OldModel));
    ELSE ok:=False;
  END;
  Dispose(mnu,Done);
  Dispose(Win,Done);
  IF ok
  THEN BEGIN
    Dispose(OldModel, Done);
    StartOK:=(ParamEdit(nil)=F9)
  END
  ELSE StartOK:=False;
END; {FUNC KilnUnit.StartOK}

PROCEDURE KilnUnit.Operation;
BEGIN
  CASE SelectOp OF
    2 : IF StartOK
        THEN StartProcess;
   12 : ParamView(nil);
   13 : Chart;
   14 : ProcessDiagram;
   15 : IF YesNo(LookUp('STOP!')+Cfg^.Name^,LookUp('StopNow'))
        THEN BEGIN
          AddToLog('Operator issues stop command');
          StopProcess;
        END;
  END;
END; {PROC KilnUnit.Operation}


PROCEDURE KilnUnit.Chart;
VAR
  Key  : PKeyStroke;
BEGIN
  New(Key,Init(WorkSpace,0,0,['P',^R,^C,ESC,F9,^M,' '],True));
  Key^.Link(Msg,'CHARTHLP?','','');
  GenericUnit.Chart;
  PutMsg(LookUp('CHART2'),LookUp('ESCPRINT'));
  Graf.Init(WS^.Left,WS^.Top+1,WS^.Width-20,WS^.Height-20,-1,-1);
  Graf.ysf:=10;
  Refresh:=RedrawKlnChart;
  RefreshDue:=True;
  REPEAT
    RefreshDue:=RefreshDue Or Interrupted;
    Key^.WaitForValid;
    CASE Key^.LastChar OF
      ^R,^C : BEGIN
              IF GrafPart<2 THEN Inc(GrafPart) ELSE GrafPart:=1;
              RefreshDue:=True;
            END;
      ' ' : RefreshDue:=True;
      'P' : BEGIN
              LnWidth:=1;
              RefreshDue:=True;
              Refresh(@Self);
              IF PrintHeader
              THEN BEGIN
                PrintInfo;
                PrintWorkSpace([WSBG,PaleYellow]);
              END;
              PrintFooter;
              LnWidth:=1; {Set to 3 for thick lines in graph}
              RefreshDue:=True;
            END;
    END;
  UNTIL Key^.LastChar in [ESC,F9,^M];
  Refresh:=NoRefresh;
  Graf.Done;
  Dispose(Key,Done);
END; {KilnUnit.Chart}

PROCEDURE UpdateXferRec(K:PGenericUnit); FAR;
VAR
  f : Boolean;
  dir : Integer;
BEGIN
  IF K^.Register(Damper1Pos)^.Installed
  THEN D1.Position:=
  {$IFDEF NoSerial} 20 + Round(Sin(random)*20)
            {$ELSE} K^.Register(Damper1Pos)^.Last
  {$ENDIF}
  ELSE D1.Position:=50;

  IF K^.Register(Damper2Pos)^.Installed
  THEN D2.Position:=
  {$IFDEF NoSerial} 80 + Round(Sin(random)*20)
            {$ELSE} K^.Register(Damper2Pos)^.Last
  {$ENDIF}
  ELSE D2.Position:=50;

  IF K^.Register(Valve1Pos)^.Installed
  THEN V1.Position:=
  {$IFDEF NoSerial} 35 + Round(Sin(random)*20)
            {$ELSE} K^.Register(Valve1Pos)^.Last
  {$ENDIF}
  ELSE V1.Position:=100;

  VF1.IsRunning:=K^.Coil(VentFan1Run)^.Last;
  VF2.IsRunning:=K^.Coil(VentFan2Run)^.Last;
  P1.IsRunning:= K^.Coil(Pump1Run)^.Last;

  IF K^.Coil(Pump1Fault)^.Installed
  THEN P1.MVError:= K^.Coil(Pump1Fault)^.Last
  ELSE P1.MVError:= False;

  IF K^.Coil(MainFanDir)^.Last
  THEN dir:=180 ELSE dir:=0;

  MF1.Direction:=dir;
  MF2.Direction:=dir;
  MF3.Direction:=dir;

  MF1.IsRunning:=K^.Coil(MF1Run)^.Last;
  MF2.IsRunning:=K^.Coil(MF2Run)^.Last;
  MF3.IsRunning:=K^.Coil(MF3Run)^.Last;

  IF K^.Coil(MF1Fault)^.Installed
  THEN BEGIN
    MF1.MVError:=K^.Coil(MF1Fault)^.Last;
    MF2.MVError:=K^.Coil(MF2Fault)^.Last;
    MF3.MVError:=K^.Coil(MF3Fault)^.Last;
  END
  ELSE BEGIN
    MF1.MVError:=False;
    MF2.MVError:=False;
    MF3.MVError:=False;
  END;

  IF K^.Coil(Basing)^.Installed
  THEN BAS.IsOn:=K^.Coil(Basing)^.Last
  ELSE BAS.IsOn:=False;

  IF K^.Register(MainFanEff)^.Installed
  THEN MF1.Effect:=K^.Register(MainFanEff)^.Last
  ELSE MF1.Effect:=0;
  MF2.Effect:=MF1.Effect;
  MF3.Effect:=MF1.Effect;

  T1T.Value:=K^.Register(tt2)^.Last/10;
  T1V.Value:=K^.Register(tv1)^.Last/10;
  T2T.Value:=K^.Register(tt3)^.Last/10;

{$IFDEF NoSerial}
{vv///////////////////////////////////////////////vv}

  IF K^.Log^.Coil(MainFanDir)^.Last or (Random>0.9)
  THEN dir:=180 ELSE dir:=0;

  BAS.IsOn:=Random>0.1;
  VF1.IsRunning:=False;
  VF2.IsRunning:=Not VF1.IsRunning;
  P1.IsRunning:=True;
  P1.MVError:=False;

  MF1.Direction:=dir;
  MF1.IsRunning:=True;
  MF1.MVError:=False;
  MF2:=MF1;
  MF3:=MF1;

  T1T.Value:=(K^.Register(ttset)^.Last+Random(10)-5)/10;
  T1V.Value:=(K^.Register(tvset)^.Last+Random(12)-6)/10;
  T2T.Value:=(K^.Register(ttset)^.Last+Random(16)-8)/10;
{^^///////////////////////////////////////////////^^}
{$ENDIF}

END; {PROC UpdateXferRec}

PROCEDURE KilnRefreshDiagram(K:PGenericUnit); FAR;
VAR
  dir : Integer;
BEGIN
  dir:=MF1.Direction;
  UpdateXferRec(K);
  IF K^.Coil(ProcessFault)^.Installed
  THEN BEGIN
    IF K^.Coil(ProcessFault)^.Last
    THEN WSC.SetAll(LightRed,PaleYellow)
    ELSE WSC.SetAll(WSBG,WSBG);
    WSWrtXY(60,3,LookUp('PROERROR'));
  END;

  IF K^.Coil(MotorFault)^.Installed
  THEN BEGIN
    IF K^.Coil(MotorFault)^.Last
    THEN WSC.SetAll(LightRed,PaleYellow)
    ELSE WSC.SetAll(WSBG,WSBG);
    WSWrtXY(60,5,LookUp('MVERROR'));
  END;

  IF MF1.Direction<>dir
  THEN BEGIN
    K^.DestroyDiagram;
    K^.MakeDiagram;
    K^.RepaintDiagram;
  END;
  K^.Dynamics^.Update;
END; {PROC KilnRefreshDiagram}

PROCEDURE KilnUnit.MakeDiagram;
VAR
  HeatElem,
  Heater,
  Plank,
  Pack,
  Timber,
  VentPipe,
  Concrete : PStaticModule;
  d        : PAnimatedDamper;
  i,x,y : Integer;
  It : PStaticElement;
BEGIN
  GenericUnit.MakeDiagram;
  New(Statics ,Init(86,TitleH+8,DWGFG,WSBG));
  New(Dynamics,Init(86,TitleH+8,DWGFG,WSBG));

  New(Concrete,Init(16,100,DarkGray));
  Concrete^.Add(New(PStaticBar,Init(0,0,430,8,UnDef)));    { Ceiling }
  Concrete^.Add(New(PStaticBar,Init(0,8,8,247,UnDef)));     { Left wall }
  Concrete^.Add(New(PStaticBar,Init(422,8,430,89,UnDef))); { Right wall }
  Concrete^.Add(New(PStaticBar,Init(0,248,430,256,UnDef)));{ Floor }
  Concrete^.Add(New(PStaticRect,Init(0,0,430,256,DWGFG))); { Outside surface }
  Concrete^.Add(New(PStaticRect,Init(8,8,422,248,DWGFG))); { Inside surface }

  Concrete^.Add(New(PStaticLine,Init(421,89,431,89,DWGFG)));       { Gate }
  Concrete^.Add(New(PStaticLine,Init(421,488,431,488,DWGFG)));
  Concrete^.Add(New(PStaticBar, Init(430,85,435,252,UnDef)));
  Concrete^.Add(New(PStaticRect, Init(430,85,435,252,Blue)));

  Concrete^.Add(New(PStaticBar, Init(90,81,330,89,UnDef))); { False ceiling }
  Concrete^.Add(New(PStaticRect,Init(90,81,330,89,DWGFG)));

  New(VentPipe,Init(28,0,DWGFG));                          { Vent. duct }

  VentPipe^.Add(New(PStaticBar ,Init(120,30,143,108,WSBG)));
  VentPipe^.Add(New(PStaticRect,Init(120,30,143,108,DWGFG)));
  VentPipe^.Add(New(PStaticLine,Init(120,100,143,100,DWGFG)));


  New(HeatElem,Init(0,0,UnDef));                           { Heating element }
  HeatElem^.Add(New(PStaticLine,Init(0,0,10,0,Red)));
  HeatElem^.Add(New(PStaticLine,Init(4,-1,6,-1,Red)));
  HeatElem^.Add(New(PStaticLine,Init(0,2,10,2,Red)));
  New(Heater,Init(110,110,UnDef));
  Heater^.Include(HeatElem);
  Heater^.Add(New(PStaticArray,Init(0,0,0,4,1,18,UnDef,HeatElem)));

  New(Plank,Init(0,0,UnDef));                              { Timber }
  Plank^.Add(New(PStaticBar,Init(0,0,7,3,Yellow)));
  New(Pack,Init(0,0,UnDef));
  Pack^.Include(Plank);
  Pack^.Add(New(PStaticArray,Init(0,0,11,7,5,5,UnDef,Plank)));
  New(Timber,Init(113,196,Yellow));
  Timber^.Include(Pack);
  Timber^.Add(New(PStaticArray,Init(0,0,58,38,4,4,UnDef,Pack)));


  { - Arrows ...}
  Statics^.Add(New(PStyleLine,Init(SolidLn,0,3)));
  IF MF1.Direction=0
  THEN BEGIN
{  Statics^.Add(New(PGradientH,Init(16+8,108,16+430,348,PaleBlue,Violet)));
}
    Statics^.Add(New(PArcArrow,Init(100,240,120,210,60,True,LightPaleBlue)));
    Statics^.Add(New(PArcArrow,Init(360,240,331,60,60,True,LightPaleBlue)));
  END
  ELSE BEGIN
  {  Statics^.Add(New(PGradientH,Init(16+8,108,16+430,348,Violet,PaleBlue)));
  }
    Statics^.Add(New(PArcArrow,Init(100,240,120,209,60,False,LightPaleBlue)));
    Statics^.Add(New(PArcArrow,Init(360,240,331,60,60,False,LightPaleBlue)));
  END;

  { - Water, left side ...}
  Statics^.Add(New(PStaticLine,Init(60,25,60,175, Red)));
  Statics^.Add(New(PStaticLine,Init(60,175,338,175, Red)));
  Statics^.Add(New(PStaticLine,Init(100,115,338,115, Red)));
  Statics^.Add(New(PStaticLine,Init(100,25,100,115, Red)));
  Statics^.Add(New(PStaticLine,Init(60,70,100,70, Red)));

  Statics^.Add(New(PArrowHead,Init(60,25,90, Red)));
  Statics^.Add(New(PArrowHead,Init(100,17,270, Red)));

  Statics^.Add(New(PStyleLine,Init(SolidLn,0,1)));
  Statics^.Add(New(PStyleFill,Init(SolidFill,Black)));
  Statics^.Add(New(PPolyFill,Init(70,70,LTri_c,LTri,White)));
  Statics^.Add(New(PStyleFill,Init(SolidFill,WSBG)));
  Statics^.Add(New(PPolyFill,Init(80,70,RTri_c,RTri,White)));

  Statics^.Add(New(PPolyFill,Init(100,40,Valve_c,Valve,White)));
  Statics^.Add(New(PStaticLine,Init(100,40,110,40, White)));
  Statics^.Add(New(PStaticRect,Init(110,34,122,46, White)));


  { - Put the pieces together }

  Statics^.Add(Concrete);
  Statics^.Add(VentPipe);
  Statics^.Add(New(PStaticCopy,Init(125,0,Undef,VentPipe)));
  Statics^.Add(Heater);
  Statics^.Add(New(PStaticCopy,Init(222,0,Undef,Heater)));
  Statics^.Add(Timber);

  { - Dynamics -------------- }

  d:=New(PAnimatedDamper,Init(160,85,10,White,0,100,90,@D1));
  IF Register(Damper1Pos)^.Installed
  THEN d^.percent:= 1 ELSE d^.percent:= 0;
  Dynamics^.Add(d);

  d:=New(PAnimatedDamper,Init(285,85,10,White,0,100,90,@D2));
  IF Register(Damper2Pos)^.Installed
  THEN d^.percent:= 1 ELSE d^.percent:= 0;
  Dynamics^.Add(d);

  Dynamics^.Add(New(PAnimatedMotor,Init(160,45,10,90,White,@VF1)));
  Dynamics^.Add(New(PAnimatedMotor,Init(285,45,10,90,White,@VF2)));
  Dynamics^.Add(New(PAnimatedMotor,Init(60,85,7,270,White,@P1)));

  IF Register(Valve1Pos)^.Installed
  THEN Dynamics^.Add(New(PAnimatedInt,Init(106,16,White,'VM1',@V1)));

  IF Coil(Basing)^.Installed
  THEN BEGIN
    IF MF1.Direction=0
    THEN Dynamics^.Add(New(PBaseSymbol, Init(315, 124, LightBlue, @BAS)))
    ELSE Dynamics^.Add(New(PBaseSymbol, Init(135, 124, LightBlue, @BAS)));
  END;


  Dynamics^.Add(New(PAnimatedMotor,Init(225,120,10,0,White,@MF1)));
  Dynamics^.Add(New(PAnimatedMotor,Init(225,144,10,0,White,@MF2)));
  Dynamics^.Add(New(PAnimatedMotor,Init(225,168,10,0,White,@MF3)));

  Dynamics^.Add(New(PAnimatedField,Init(32,300,LightRed,
            PadLeading(Register(tt2)^.Name^,' ',3),@T1T)));
  Dynamics^.Add(New(PAnimatedField,Init(32,280,LightBlue,
            PadLeading(Register(tv1)^.Name^,' ',3),@T1V)));
  Dynamics^.Add(New(PAnimatedField,Init(360,120,LightRed,
            PadLeading(Register(tt3)^.Name^,' ',3),@T2T)));

  Refresh:=KilnRefreshDiagram;
END; {PROC KilnUnit.MakeDiagram}

PROCEDURE KilnUnit.PLCWrite;
BEGIN
  CASE KilnMode OF
    Stopped,
    Finished,
    PLCControlled : {Do nothing};
    WarmingUp,
    Equalizing,
    Drying        : BEGIN {Send setpoints}
                      IF Register(tvSet)^.Value<>PrevTv
                      THEN BEGIN
                        Register(tvSet)^.Write;
                        PrevTv:= Register(tvSet)^.Value;
                      END;
                      IF Register(ttSet)^.Value<>PrevTt
                      THEN BEGIN
                        Register(ttSet)^.Write;
                        PrevTt:= Register(ttSet)^.Value;
                      END;
                    END;
    Conditioning,
    CoolingDown   : {No setpoints necessary} ;
  END;
END; {PROC KilnUnit.PLCWrite}

PROCEDURE KilnUnit.PLCRead;
BEGIN

  Coil(SkipRead)^.Read;
  IF Coil(SkipRead)^.Last
  THEN BEGIN
    Register(tvRead)^.UpdateLog;
    Register(ttRead)^.UpdateLog;
    Register(tv1)^.UpdateLog;
    Register(tt1)^.UpdateLog;
    Register(tt2)^.UpdateLog;
    Register(tt3)^.UpdateLog;
  END;

  Register(tvRead)^.UpdateLog;
  Register(ttRead)^.UpdateLog;
  Register(tv1)^.UpdateLog;
  Register(tt1)^.UpdateLog;
  Register(tt2)^.UpdateLog;
  Register(tt3)^.UpdateLog;

  Register(Valve1Pos)^.UpdateLog;
  Register(Damper1Pos)^.UpdateLog;
  Register(Damper2Pos)^.UpdateLog;
  Coil(ProcessFault)^.UpdateLog;
  Coil(DryingPhaseFlag)^.UpdateLog;
  Coil(Started)^.UpdateLog;
  Coil(MainFanDir)^.UpdateLog;
  Coil(Basing)^.UpdateLog;
  Coil(MF1Run)^.UpdateLog;
  Coil(MF2Run)^.UpdateLog;
  Coil(MF3Run)^.UpdateLog;
  Coil(VentFan1Run)^.UpdateLog;
  Coil(VentFan2Run)^.UpdateLog;
  Coil(Pump1Run)^.UpdateLog;
  Coil(MotorFault)^.UpdateLog;
  Coil(MF1Fault)^.UpdateLog;
  Coil(MF2Fault)^.UpdateLog;
  Coil(MF3Fault)^.UpdateLog;
  Coil(VentFan1Fault)^.UpdateLog;
  Coil(VentFan1Fault)^.UpdateLog;
  Coil(Pump1Fault)^.UpdateLog;
END; {PROC KilnUnit.PLCRead}

PROCEDURE KilnUnit.ResumeProcess;
{ - Examine PLC to check for NON-PC controlled changes in kiln control}
BEGIN
  GenericUnit.ResumeProcess;
END; {PROC KilnUnit.ResumeProcess}

PROCEDURE KilnUnit.StartProcess;
{ - Execute kiln startup sequence}
VAR
  n  : Integer;
  Ok : Boolean;
BEGIN
  Log^.SetSize(Cfg^.PLC,(PKilnModel(Model)^.TotalTime+96)*SamplesPerHour);

  Register(ProgramNumber)^.Value:=0;
  Register(CondTime)^.Value:=PKilnModel(Model)^.CondTime;
  Register(DryingTime)^.Value:=PKilnModel(Model)^.EquTime
                              +PKilnModel(Model)^.DryTime;
  Register(CoolTime)^.Value:= PKilnModel(Model)^.CoolTime;
  Register(TempDiffCond)^.Value:=PKilnModel(Model)^.CondTDiff;

  Register(ProgramNumber)^.Write;
  Register(CondTime)^.Write;
  Register(DryingTime)^.Write;
  Register(CoolTime)^.Write;
  Register(TempDiffCond)^.Write;
  GenericUnit.StartProcess;
  EquStart:=LastUpdate;
  PhaseStart:=LastUpdate;
END; {PROC KilnUnit.StartProcess}

PROCEDURE KilnUnit.UpdateProcess;
{ - Walk through kiln registers/coils and look for comm.requests
    Use as Last call from inheritors}
VAR
  NextMode : Integer; {Next mode/phase if phase completed}
  ModeTime : Integer; {Expected time to use in current mode/phase}
  FixTime  : Integer;
  ModeChg  : Boolean; {Yes, we have completed the current phase}
  spidx    : Integer; {SetPoint InDeX}
{$IFDEF NoSerial}
  v,t      : Integer; {Temporary storage for simulation}
{$ENDIF}
BEGIN
  ModeTime:=0;
  FixTime:=0;
  ModeChg:=False;
  CASE KilnMode OF
    Stopped,
    Finished : BEGIN
      spidx:=0;
      NextMode:=KilnMode; {Next mode := current mode, i.e. No Changes}
    END;
    WarmingUp: BEGIN
      spidx:=0;
      IF PKilnModel(Model)^.EquTime>0
      THEN NextMode:=Equalizing
      ELSE NextMode:=Drying;
      EquStart:=LastUpdate;
      PKilnModel(Model)^.HeatTime:=HoursSince(PhaseStart);
    END;
    Equalizing: BEGIN
      FixTime:=1;
      spidx:=HoursSince(EquStart)+1;
      ModeTime:=PKilnModel(Model)^.EquTime;
      NextMode:=Drying;
    END;
    Drying: BEGIN
      FixTime:=PKilnModel(Model)^.EquTime+1;
      spidx:=HoursSince(EquStart)+1;
      ModeTime:=PKilnModel(Model)^.DryTime;
      NextMode:=Conditioning;
    END;
    Conditioning: BEGIN
      FixTime:=PKilnModel(Model)^.EquTime+pKilnModel(Model)^.DryTime+1;
      spidx:=HoursSince(EquStart)+1;
      ModeTime:=PKilnModel(Model)^.CondTime;
      NextMode:=CoolingDown;
    END;
    CoolingDown: BEGIN
      spidx:=0;
      ModeTime:=PKilnModel(Model)^.CoolTime;
      NextMode:=Finished;
    END
    ELSE BEGIN
      spidx:=0;
    END;
  END;

  IF spidx>Model^.tt.MaxSamples-1
  THEN spidx:=FixTime;


  IF not (KilnMode IN [Conditioning, CoolingDown,Finished,Stopped])
  THEN BEGIN
    Register(ttSet)^.Value:=Model^.tt.At(spidx);
    Register(tvSet)^.Value:=Model^.tv.At(spidx);
  END;

{$IFDEF NoSerial}
{vv------------------------------------------------------vv}
  v:=Model^.tv.At(spidx);
  t:=Model^.tt.At(spidx);
  Register(tv1)^.Value:=v+5-Random(10);
  Register(tt1)^.Value:=t+5-Random(10);
  Register(tvRead)^.Value:=v;
  Register(ttRead)^.Value:=t;
  Register(tt2)^.Value:=t-Random(10);
  Register(tt3)^.Value:=v+5+Random(3);
{^^------------------------------------------------------^^}
{$ENDIF}

  GenericUnit.UpdateProcess;

  CASE KilnMode OF
    WarmingUp    : ModeChg:=Coil(DryingPhaseFlag)^.Enabled;
    Equalizing   : ModeChg:=HoursSince(PhaseStart)>=ModeTime;
    Drying       : BEGIN
                     ModeChg:=HoursSince(PhaseStart)>=ModeTime;
                     IF ModeChg
                     THEN BEGIN
                       Coil(CondPhaseFlag)^.Enable;
                       Coil(CondPhaseFlag)^.Write;
                     END;
                   END;
    Conditioning : ModeChg:=HoursSince(PhaseStart)>=ModeTime;
    CoolingDown  : BEGIN
                     ModeChg:=HoursSince(PhaseStart)>=ModeTime;
                     IF ModeChg
                     THEN StopProcess;
                   END;
  END;
  IF ModeChg
  THEN BEGIN
    KilnMode:=NextMode;
    PhaseStart:=LastUpdate;
  END;
END; {PROC KilnUnit.UpdateProcess}

PROCEDURE KilnUnit.StopProcess;
{ - Execute kiln stop sequence}
BEGIN
  Register(tvSet)^.Value:=160;  {16.0 øC}
  Register(ttSet)^.Value:=200;  {20.0 øC}
  GenericUnit.StopProcess;
  KilnMode:=Stopped;
END; {PROC KilnUnit.StopProcess}

FUNCTION KilnUnit.UpdateDue:Boolean;
BEGIN
  UpdateDue:=SecondsSince(LastUpdate)>UpdateInterval;
END; {FUNC KilnUnit.UpdateDue}

FUNCTION KilnUnit.Describe:String;
{ - Return a description string }
VAR
  s : String[79];
  t : DateTime;
BEGIN
  s:=GenericUnit.Describe+Model^.Describe;
  IF KilnMode<>Stopped
  THEN BEGIN
    t:=StartTime;
    WITH PKilnModel(Model)^
    DO BEGIN
      IncSeconds(t,3600*LongInt(TotalTime));
      s:=s+'  '+LookWatch(StartTime)+IntStr(DryTime,5)
        +IntStr(CondTime,5)+'  '+LookWatch(t);
    END;
  END;
  Describe:=s;
END; {FUNC KilnUnit.Describe}


FUNCTION KilnUnit.TotalTime:Integer;
{ - Return total time usage }
BEGIN
  TotalTime:=Model^.TotalTime;
END; {FUNC KilnUnit.TotalTime}


{------------------------------------------------------------- Unit init's ---
}

PROCEDURE RegisterKilnTypes;
BEGIN
  RegisterType(KilnUnit_OSR);
END; {PROC RegisterKilnTypes}

VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}
CONST
  P4UnitMsg = ' P4U_Kiln ';

PROCEDURE P4UnitExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitHandler;
  Units.Leave(P4UnitMsg,MemAvail);
END; {PROC P4UnitExitHandler}

BEGIN
  PrevExitHandler:=ExitProc;
  ExitProc:=@P4UnitExitHandler;
  Units.Enter(P4UnitMsg,MemAvail,CSeg);
  RegisterKilnTypes;
END.

