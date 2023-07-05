{$I CODEDEFS.PAS} {Include code generation definitions}
{$X+}
UNIT P4U_Tunl;

INTERFACE
USES
  Dos,Objects,
  LFsystem, LFExtMsg, LFDraw, PLCDrive, LFWindow, LFGfxWin,
  P4Config, P4Model, P4U_Gen, P4MatLst;

TYPE
  PTunnelUnit = ^TunnelUnit;
  TunnelUnit = OBJECT(GenericUnit)
    Ranks      : pRankList; {Stored}
    PrevDeltaT : Integer;   {Volatile}
    PrevWarmUp : Integer;   {Volatile}

    CONSTRUCTOR Init(NewCfg:PGenericCfg);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);     VIRTUAL;
    PROCEDURE   Link(NewCfg:PGenericCfg); VIRTUAL;
    FUNCTION    ParamEdit(WS:PWorkSpace):Char;  VIRTUAL;
    PROCEDURE   ParamView(WS:PWorkSpace); VIRTUAL;
    FUNCTION    MakeOpMenu:PMenuTxt;      VIRTUAL;
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
  END; {OBJ TunnelUnit}


CONST
  TunnelUnit_OID = 10023;
  TunnelUnit_OSR: TStreamRec = (
    ObjType: TunnelUnit_OID;
    VmtLink: Ofs(TypeOf(TunnelUnit)^);
    Load:    @TunnelUnit.Load;
    Store:   @TunnelUnit.Store
  );



IMPLEMENTATION
USES
  Crt,Graph,LFtable,LFString,LFDos,
  ObjInput,AGTools,P4Limits;

{-------------------------------------------------------------- TunnelUnit ---
  Description

}


CONSTRUCTOR TunnelUnit.Init(NewCfg:PGenericCfg);
{ - Initialize kiln with connected Config info }
VAR
  tCfg : pTunnelCfg;
BEGIN
  GenericUnit.Init(NewCfg);
  Model:=New(PTunnelModel,Init);
  Log^.SetSize(Cfg^.PLC, TotalSamples);
  tCfg:=pTunnelCfg(Cfg);
  New(Ranks, Init(tCfg));
  PrevDeltaT:=-999;
  PrevWarmUp:=-999;
END; {CONS TunnelUnit.Init}

CONSTRUCTOR TunnelUnit.Load(VAR S:TStream);
VAR
  VerID : Integer;
  tCfg : pTunnelCfg;
BEGIN
  GenericUnit.Load(S);
  tCfg:=pTunnelCfg(Cfg);
  IF IsVersion<BackupVersion    {If updating an old version of the bku file}
  THEN BEGIN
    FOR VerID:=IsVersion TO BackupVersion
    DO BEGIN
      CASE VerID OF
        0 : {Do nothing};
        1 :  New(Ranks, Init(tCfg));
      END;
    END;
  END
  ELSE BEGIN
    New(Ranks, Load(S));
  END;
END; {CONS TunnelUnit.Load}

PROCEDURE TunnelUnit.Store(VAR S:TStream);
BEGIN
  GenericUnit.Store(S);
  Ranks^.Store(S);
END; {PROC TunnelUnit.Store}

PROCEDURE TunnelUnit.Link(NewCfg:PGenericCfg);
{ - Reestablish link to configuration }
BEGIN
  GenericUnit.Link(NewCfg);
  Ranks^.SetZoneCount(pTunnelCfg(Cfg));
END; {PROC TunnelUnit.Link}


FUNCTION TunnelUnit.ParamEdit(WS:PWorkSpace):Char;
{ - }
VAR
  Win : PGfxWin;
BEGIN
  New(Win,InitTxt(20,10,40,9,True));
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  Win^.Title(LookUp('PARAMTITLE')+Cfg^.Name^,LookUp('ESC=EXIT'));
  Win^.Open;
  ParamEdit:=GenericUnit.ParamEdit(Win^.WorkSpace);
  Dispose(Win,Done);
END; {PROC TunnelList.ParamEdit}

PROCEDURE TunnelUnit.ParamView(WS:PWorkSpace);
{ - }
VAR
  Win : PGfxWin;
BEGIN
  New(Win,InitTxt(20,10,40,9,True));
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  Win^.Title(LookUp('PARAMTITLE')+Cfg^.Name^,'');
  Win^.Open;
  GenericUnit.ParamView(Win^.WorkSpace);
  Dispose(Win,Done);
END; {PROC TunnelList.ParamView}

FUNCTION TunnelUnit.MakeOpMenu:PMenuTxt;
VAR
  opm : pMenuTxt;
BEGIN
  IF KilnMode=Stopped
  THEN BEGIN
    opm:=Msg^.FindMenu('TNLSTPMNU');
    IF Cfg^.Remote
    THEN opm^.LineDisable(1)
    ELSE opm^.LineEnable(1);
  END
  ELSE BEGIN
    IF pTunnelCfg(Cfg)^.UseRankList
    THEN BEGIN
      opm:=Msg^.FindMenu('TNLRUNMNU2');
      IF Cfg^.Remote
      THEN opm^.LineDisable(5)
      ELSE opm^.LineEnable(5);
    END
    ELSE BEGIN
      opm:=Msg^.FindMenu('TNLRUNMNU');
      IF Cfg^.Remote
      THEN opm^.LineDisable(4)
      ELSE opm^.LineEnable(4);
    END;
  END;
  MakeOpMenu:=opm;
END; {FUNC TunnelUnit.MakeOpMenu}

PROCEDURE TunnelUnit.Operation;
VAR
  SelOp : Integer;
BEGIN
  SelOp:=SelectOp;
  CASE SelOp OF
    2 : IF ParamEdit(nil)=F9
        THEN StartProcess;
   12 : IF ParamEdit(nil)=F9
        THEN UpdateProcess;
   13 : Chart;
   14 : ProcessDiagram;
   15,16
      : IF (SelOp=15) and (pTunnelCfg(Cfg)^.UseRankList)
        THEN BEGIN
          DeskTopTitle(LookUp('RANKLIST')+', '+Cfg^.Name^);
          Ranks^.Edit;
        END
        ELSE IF YesNo(LookUp('STOP!')+Cfg^.Name^,LookUp('StopNow'))
        THEN StopProcess;
  END;
END; {PROC TunnelUnit.Operation}


PROCEDURE RedrawTnlChart(K:PGenericUnit); FAR;
  PROCEDURE Plot(ID:Word; Color:Integer);
  VAR
    n,v : Integer;
    t   : Float;
    Temperature : PAvgIntSampler;
  BEGIN
    IF K^.Interrupted THEN Exit;
    SetColor(Color);
    Temperature:=K^.Log^.Register(ID);
    t:=-SecToMidnight(K^.LastUpdate);
    v:=Temperature^.Last;
      IF v<MinScale THEN v:=MinScale
      ELSE IF v>MaxScale THEN v:=MaxScale;
    Graf.PointTo(t,v);
    n:=Temperature^.Current;
    WSC.SetAll(Color,PaleYellow);
    WSWrt('Ý '+K^.Cfg^.PLC^.Register(ID)^.name^+' ');
    WHILE (n>=0) and (t>=Graf.wxmin)
    DO BEGIN
      v:=Temperature^.At(n);
      IF v<MinScale THEN v:=MinScale
      ELSE IF v>MaxScale THEN v:=MaxScale;
      Graf.LineTo(t,v);
      t:=t-SampleInterval;
      Dec(n);
    END;
    K^.Interrupted:=KeyPressed;
  END;
BEGIN
  K^.Interrupted:=KeyPressed;
  IF K^.Interrupted THEN Exit;
  WSClear;
  WSWrtXY(1,23,'');
  SetTextStyle(SmallFont, HorizDir,5);
  Graf.World(-MaxHours*3600,MinScale,0,MaxScale);
  Graf.xTimeScale(DottedLn,MaxHours,K^.LastUpdate);
  Graf.yScale(DottedLn);
  SetLineStyle(SolidLn,0,3);
  Plot(tvRead,Blue);
  Plot(ttRead,Red);
  SetLineStyle(SolidLn,0,LnWidth);
  CASE GrafPart OF
    1 : BEGIN
          Plot(tv1,LightBlue);
          Plot(tt1,Violet);
          Plot(tt3,LightRed);
        END;
    2 : BEGIN
          Plot(tv2,LightBlue);
          Plot(tt2,Violet);
          Plot(tt4,LightRed);
        END;
  END;
  SetLineStyle(SolidLn,0,1);
  IF K^.Interrupted THEN Exit;
  WSC.SetBG(WSBG);
  WSWrt('Ý');
END; {PROC RedrawTnlChart}

PROCEDURE TunnelUnit.Chart;
VAR
  Key  : PKeyStroke;
BEGIN
  New(Key,Init(WorkSpace,0,0,['P','-','+',^R,^C,'0'..'9',ESC,F9,^M,' '],True));
  Key^.Link(Msg,'CHARTHLP?','','');
  GenericUnit.Chart;
  PutMsg(LookUp('CHART1'),LookUp('ESCPRINT'));
  Graf.Init(WS^.Left+10,WS^.Top+1,WS^.Width-20,WS^.Height-20,1,-1);
  Graf.ysf:=10;
  Graf.World(-MaxHours*3600,MinScale,0,MaxScale);
  Refresh:=RedrawTnlChart;
  RefreshDue:=True;
  REPEAT
    RefreshDue:=RefreshDue Or Interrupted;
    Key^.WaitForValid;
    CASE Key^.LastChar OF
      ^R,^C : BEGIN
              IF GrafPart<2 THEN Inc(GrafPart) ELSE GrafPart:=1;
              RefreshDue:=True;
            END;
      '0'..'9'
          : BEGIN
              MaxHours:=24*(Byte(Key^.LastChar)-Byte('0'));
              IF MaxHours=0 THEN MaxHours:=TotalHours;
              RefreshDue:=True;
            END;
      '+' : IF MaxHours<TotalHours
            THEN BEGIN
              MaxHours:=MaxHours+24;
              RefreshDue:=True;
            END;
      '-' : IF MaxHours>=48
            THEN BEGIN
              MaxHours:=MaxHours-24;
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
END; {TunnelUnit.Chart}

PROCEDURE TunnelRefreshDiagram(K:PGenericUnit); FAR;
VAR
  f : Boolean;
BEGIN
  IF K^.Coil(ProcessFault)^.Last
  THEN WSC.SetAll(LightRed,PaleYellow)
  ELSE WSC.SetAll(WSBG,WSBG);
  WSWrtXY(60,3,LookUp('PROERROR'));
  IF K^.Coil(MotorFault)^.Last
  THEN WSC.SetAll(LightRed,PaleYellow)
  ELSE WSC.SetAll(WSBG,WSBG);
  WSWrtXY(60,5,LookUp('MVERROR'));

  IF K^.Register(Damper1Pos)^.Installed
  THEN D1.Position:=K^.Register(Damper1Pos)^.Last
  ELSE D1.Position:=50;

  IF K^.Register(Damper2Pos)^.Installed
  THEN D2.Position:=K^.Register(Damper2Pos)^.Last
  ELSE D2.Position:=50;

  IF K^.Register(Valve1Pos)^.Installed
  THEN V1.Position:=K^.Register(Valve1Pos)^.Last
  ELSE V1.Position:=50;

  IF K^.Register(Valve2Pos)^.Installed
  THEN V2.Position:=K^.Register(Valve2Pos)^.Last
  ELSE V2.Position:=50;

  VF1.IsRunning:=K^.Coil(VentFan1Run)^.Last;
  P1.IsRunning:= K^.Coil(Pump1Run)^.Last;
  P2.IsRunning:= K^.Coil(Pump2Run)^.Last;

  MF1.IsRunning:=K^.Coil(MF1Run)^.Last;
  MF2.IsRunning:=K^.Coil(MF2Run)^.Last;
  MF3.IsRunning:=K^.Coil(MF3Run)^.Last;
  MF4.IsRunning:=K^.Coil(MF4Run)^.Last;
  MF5.IsRunning:=K^.Coil(MF5Run)^.Last;
  MF6.IsRunning:=K^.Coil(MF6Run)^.Last;

  MF1.MVError:=K^.Coil(MF1Fault)^.Last;
  MF2.MVError:=K^.Coil(MF2Fault)^.Last;
  MF3.MVError:=K^.Coil(MF3Fault)^.Last;
  MF4.MVError:=K^.Coil(MF4Fault)^.Last;
  MF5.MVError:=K^.Coil(MF5Fault)^.Last;
  MF6.MVError:=K^.Coil(MF6Fault)^.Last;

  T1T.Value:=K^.Register(tt1)^.Last/10;
  T1V.Value:=K^.Register(tv1)^.Last/10;
  T2T.Value:=K^.Register(tt2)^.Last/10;
  T2V.Value:=K^.Register(tv2)^.Last/10;
  T3T.Value:=K^.Register(tt3)^.Last/10;
  T4T.Value:=K^.Register(tt4)^.Last/10;

{$IFDEF NoSerial}{vv/////////////////////////////////////////////////////vv}
  IF K^.Register(Damper1Pos)^.Installed
   THEN D1.Position:=22
    ELSE D1.Position:=50;
  IF K^.Register(Damper2Pos)^.Installed
   THEN D2.Position:=31
    ELSE D2.Position:=50;
  IF K^.Register(Valve1Pos)^.Installed
   THEN V1.Position:=52
    ELSE V1.Position:=50;
  IF K^.Register(Valve2Pos)^.Installed
   THEN V2.Position:=35
    ELSE V2.Position:=50;

  VF1.IsRunning:=True;
  P1.IsRunning:= True;
  P2.IsRunning:= False;

  MF1.IsRunning:=True;
  MF2.IsRunning:=MF1.IsRunning;
  MF3.IsRunning:=MF1.IsRunning;
  MF4.IsRunning:=MF1.IsRunning;
  MF5.IsRunning:=MF1.IsRunning;
  MF6.IsRunning:=MF1.IsRunning;

  MF1.MVError:=False;
  MF2.MVError:=False;
  MF3.MVError:=False;
  MF4.MVError:=False;
  MF5.MVError:=False;
  MF6.MVError:=False;

  T1T.Value:=59.3;
  T1V.Value:=55.1;
  T2T.Value:=57.4;
  T2V.Value:=55.2;
  T3T.Value:=60.8;
  T4T.Value:=60.7;
{$ENDIF}{^^///////////////////////////////////////////////^^}
  K^.Dynamics^.Update;
END; {PROC TunnelRefreshDiagram}


PROCEDURE TunnelUnit.MakeDiagram;
CONST
  vpHot_c = 9;
  vpHot : ARRAY[1..2*vpHot_c] OF Integer
  = (50,108,
     50,50,
     120,50,
     120,20,
     135,20,
     135,65,
     65,65,
     65,108,
     50,108);

  vpCold_c = 9;
  vpCold : ARRAY[1..2*vpCold_c] OF Integer
  = (50,20,
     65,20,
     65,50,
     50,65,
     50,108,
     65,108,
     65,65,
     50,50,
     50,20);

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
  New(Statics ,Init(8,TitleH+8,DWGFG,WSBG));
  New(Dynamics,Init(8,TitleH+8,DWGFG,WSBG));

  New(Concrete,Init(16,100,DarkGray));
  Concrete^.Add(New(PStaticBar,Init(0,0,588,8,UnDef)));    { Ceiling }
  Concrete^.Add(New(PStaticBar,Init(0,8,8,89,UnDef)));     { Left wall }
  Concrete^.Add(New(PStaticBar,Init(580,8,588,89,UnDef))); { Right wall }
  Concrete^.Add(New(PStaticBar,Init(0,248,588,256,UnDef)));{ Floor }
  Concrete^.Add(New(PStaticRect,Init(0,0,588,256,DWGFG))); { Outside surface }
  Concrete^.Add(New(PStaticRect,Init(8,8,580,248,DWGFG))); { Inside surface }

  It:=New(PStaticLine,Init(-1,89,9,89,DWGFG));          { Gate }
  Concrete^.Include(It);
  Concrete^.Add(New(PStaticArray,Init(0,0,580,159,2,2,Undef,It)));
  It:=New(PStaticBar, Init(-4,85,0,252,UnDef));
  Concrete^.Add(it);
  Concrete^.Add(New(PStaticCopy, Init(592,0,UnDef,It)));
  It:=New(PStaticRect, Init(-4,85,0,252,Blue));
  Concrete^.Add(it);
  Concrete^.Add(New(PStaticCopy, Init(592,0,UnDef,It)));

  Concrete^.Add(New(PStaticBar, Init(60,81,246,89,UnDef))); { False ceiling }
  Concrete^.Add(New(PStaticRect,Init(60,81,246,89,DWGFG)));
  Concrete^.Add(New(PStaticBar, Init(334,81,520,89,UnDef))); { False ceiling }
  Concrete^.Add(New(PStaticRect,Init(334,81,520,89,DWGFG)));

  New(VentPipe,Init(28,0,DWGFG));                      { Vent. duct }

  VentPipe^.Add(New(PStyleFill,Init(InterLeaveFill,LightGray)));
  VentPipe^.Add(New(PStaticBar,Init(75,45,110,70,White)));
  VentPipe^.Add(New(PStyleFill,Init(SolidFill,Red)));
  VentPipe^.Add(New(PPolyFill,Init(0,0,vpHot_c,vpHot,Red)));
  VentPipe^.Add(New(PStaticRect,Init(50,100,65,108,DWGFG)));
  VentPipe^.Add(New(PStyleFill,Init(SolidFill,Blue)));
  VentPipe^.Add(New(PPolyFill,Init(35,0,vpCold_c,vpCold,Blue)));
  VentPipe^.Add(New(PStaticRect,Init(85,100,100,108,DWGFG)));
  VentPipe^.Add(New(PStaticRect,Init(75,45,110,70,White)));
  VentPipe^.Add(New(PStaticLine,Init(75,45,110,70,White)));
  VentPipe^.Add(New(PStaticLine,Init(75,70,110,45,White)));
  VentPipe^.Add(New(PStyleFill,Init(SolidFill,UnDef)));


  New(HeatElem,Init(0,0,UnDef));                           { Heating element }
  HeatElem^.Add(New(PStaticLine,Init(0,0,10,0,Red)));
  HeatElem^.Add(New(PStaticLine,Init(4,-1,6,-1,Red)));
  HeatElem^.Add(New(PStaticLine,Init(0,2,10,2,Red)));
  New(Heater,Init(220,110,UnDef));
  Heater^.Include(HeatElem);
  Heater^.Add(New(PStaticArray,Init(0,0,0,4,1,18,UnDef,HeatElem)));

  New(Plank,Init(0,0,UnDef));                              { Timber }
  Plank^.Add(New(PStaticBar,Init(0,0,7,3,Yellow)));
  New(Pack,Init(0,0,UnDef));
  Pack^.Include(Plank);
  Pack^.Add(New(PStaticArray,Init(0,0,11,7,4,5,UnDef,Plank)));
  New(Timber,Init(77,196,Yellow));
  Timber^.Include(Pack);
  Timber^.Add(New(PStaticArray,Init(0,0,48,38,4,4,UnDef,Pack)));
  Timber^.Add(New(PStaticArray,Init(274,0,48,38,4,4,UnDef,Pack)));

  { - Arrows ...}
  Statics^.Add(New(PArrowHead,Init(86,112,270,Red)));
  Statics^.Add(New(PArrowHead,Init(121,120,90,Blue)));
  Statics^.Add(New(PArrowHead,Init(156,8,270,Red)));
  Statics^.Add(New(PArrowHead,Init(121,15,90,Blue)));
  Statics^.Add(New(PStyleLine,Init(SolidLn,0,3)));
  Statics^.Add(New(PArcArrow,Init(100,240,120,210,60,True,LightPaleBlue)));
  Statics^.Add(New(PArcArrow,Init(240,240,331,60,60,True,LightPaleBlue)));
  Statics^.Add(New(PArcArrow,Init(374,240,120,209,60,False,LightPaleBlue)));
  Statics^.Add(New(PArcArrow,Init(514,240,331,60,60,False,LightPaleBlue)));

  { - Water, left side ...}
  Statics^.Add(New(PStaticLine,Init(200,175,220,175, Red)));
  Statics^.Add(New(PStaticLine,Init(200,25,200,175, Red)));
  Statics^.Add(New(PStaticLine,Init(230,120,240,120, Red)));
  Statics^.Add(New(PStaticLine,Init(240,25,240,120, Red)));
  Statics^.Add(New(PStaticLine,Init(200,70,240,70, Red)));
  Statics^.Add(New(PArrowHead,Init(200,25,90, Red)));
  Statics^.Add(New(PArrowHead,Init(240,17,270, Red)));

  Statics^.Add(New(PStyleLine,Init(SolidLn,0,1)));
  Statics^.Add(New(PStyleFill,Init(SolidFill,Black)));
  Statics^.Add(New(PPolyFill,Init(210,70,LTri_c,LTri,White)));
  Statics^.Add(New(PStyleFill,Init(SolidFill,WSBG)));
  Statics^.Add(New(PPolyFill,Init(220,70,RTri_c,RTri,White)));
  Statics^.Add(New(PPolyFill,Init(240,40,Valve_c,Valve,White)));
  Statics^.Add(New(PStaticLine,Init(240,40,250,40, White)));
  Statics^.Add(New(PStaticRect,Init(250,34,262,46, White)));


  { - Water, Right side ...}
  Statics^.Add(New(PStyleLine,Init(SolidLn,0,3)));
  Statics^.Add(New(PStaticLine,Init(390,175,410,175, Red)));
  Statics^.Add(New(PStaticLine,Init(410,25,410,175, Red)));
  Statics^.Add(New(PStaticLine,Init(370,120,380,120, Red)));
  Statics^.Add(New(PStaticLine,Init(370,25,370,120, Red)));
  Statics^.Add(New(PStaticLine,Init(370,70,410,70, Red)));
  Statics^.Add(New(PArrowHead,Init(370,17,270, Red)));
  Statics^.Add(New(PArrowHead,Init(410,25,90, Red)));

  Statics^.Add(New(PStyleLine,Init(SolidLn,0,1)));
  Statics^.Add(New(PStyleFill,Init(SolidFill,WSBG)));
  Statics^.Add(New(PPolyFill,Init(370,40,Valve_c,Valve,White)));
  Statics^.Add(New(PPolyFill,Init(380,70,LTri_c,LTri,White)));
  Statics^.Add(New(PStyleFill,Init(SolidFill,Black)));
  Statics^.Add(New(PPolyFill,Init(390,70,RTri_c,RTri,White)));
  Statics^.Add(New(PStaticLine,Init(360,40,370,40, White)));
  Statics^.Add(New(PStaticRect,Init(348,34,360,46, White)));


  { - Put the pieces together }

  Statics^.Add(Concrete);
  Statics^.Add(VentPipe);
  Statics^.Add(Heater);
  Statics^.Add(New(PStaticCopy,Init(160,0,Undef,Heater)));
  Statics^.Add(Timber);
  d:=New(PAnimatedDamper,Init(85,85,7,White,0,100,90,@D1));
  IF Register(Damper1Pos)^.Installed
  THEN d^.percent:= -1 ELSE d^.percent:= 0;
  Dynamics^.Add(d);

  d:=New(PAnimatedDamper,Init(120,85,7,White,0,100,90,@D2));
  IF Register(Damper1Pos)^.Installed
  THEN d^.percent:= 1 ELSE d^.percent:= 0;
  Dynamics^.Add(d);

  Dynamics^.Add(New(PAnimatedMotor,Init(155,35,7,90,White,@VF1)));
  Dynamics^.Add(New(PAnimatedMotor,Init(200,85,7,270,White,@P1)));
  Dynamics^.Add(New(PAnimatedMotor,Init(410,85,7,270,White,@P2)));

  IF Register(Valve1Pos)^.Installed
  THEN Dynamics^.Add(New(PAnimatedInt,Init(250,16,White,'VM1',@V1)));

  IF Register(Valve2Pos)^.Installed
  THEN Dynamics^.Add(New(PAnimatedInt,Init(332,50,White,'VM2',@V2)));

  Dynamics^.Add(New(PAnimatedMotor,Init(180,120,10,0,White,@MF1)));
  Dynamics^.Add(New(PAnimatedMotor,Init(180,144,10,0,White,@MF2)));
  Dynamics^.Add(New(PAnimatedMotor,Init(180,168,10,0,White,@MF3)));
  Dynamics^.Add(New(PAnimatedMotor,Init(430,120,10,180,White,@MF4)));
  Dynamics^.Add(New(PAnimatedMotor,Init(430,144,10,180,White,@MF5)));
  Dynamics^.Add(New(PAnimatedMotor,Init(430,168,10,180,White,@MF6)));

  Dynamics^.Add( New(PAnimatedField,Init(40,160,Violet,
                 PadLeading( Register(tt1)^.Name^,' ',3), @T1T)));
  Dynamics^.Add( New(PAnimatedField,Init(40,140,LightBlue,
                 PadLeading( Register(tv1)^.Name^,' ',3), @T1V)));
  Dynamics^.Add( New(PAnimatedField,Init(500,160,Violet,
                 PadLeading( Register(tt2)^.Name^,' ',3), @T2T)));
  Dynamics^.Add( New(PAnimatedField,Init(500,140,LightBlue,
                 PadLeading( Register(tv2)^.Name^,' ',3), @T2V)));
  Dynamics^.Add( New(PAnimatedField,Init(250,160,LightRed,
                 PadLeading( Register(tt3)^.Name^,' ',3), @T3T)));
  Dynamics^.Add( New(PAnimatedField,Init(300,124,LightRed,
                 PadLeading( Register(tt4)^.Name^,' ',3), @T4T)));

  Refresh:=TunnelRefreshDiagram;
END; {PROC TunnelUnit.MakeDiagram}


PROCEDURE TunnelUnit.PLCWrite;
BEGIN
  IF KilnMode<>Stopped
  THEN BEGIN
    IF Register(tvSet)^.Value<>PrevTv
    THEN BEGIN
      Register(tvSet)^.Write;
      PrevTt:= Register(tvSet)^.Value;
    END;
    IF Register(ttSet)^.Value<>PrevTt
    THEN BEGIN
      Register(ttSet)^.Write;
      PrevTt:= Register(ttSet)^.Value;
    END;
    IF Register(delta_t)^.Installed
    THEN BEGIN
      IF Register(delta_t)^.Value<>PrevDeltaT
      THEN BEGIN
        Register(delta_t)^.Write;
        PrevTt:= Register(delta_t)^.Value;
      END;
    END;
    IF Register(WarmUpTime)^.Installed
    THEN BEGIN
      IF Register(WarmUpTime)^.Value<>PrevWarmUp
      THEN BEGIN
        Register(WarmUpTime)^.Write;
        PrevWarmUp:= Register(WarmUpTime)^.Value;
      END;
    END;
  END;
END; {PROC TunnelUnit.PLCWrite}

PROCEDURE TunnelUnit.PLCRead;
VAR
  c : Word;
BEGIN
  Coil(SkipRead)^.Read;
  IF Coil(SkipRead)^.Last
  THEN BEGIN
    Register(tvRead)^.UpdateLog;
    Register(ttRead)^.UpdateLog;
    Register(tv1)^.UpdateLog;
    Register(tt1)^.UpdateLog;
    Register(tv2)^.UpdateLog;
    Register(tt2)^.UpdateLog;
    Register(tt3)^.UpdateLog;
    Register(tt4)^.UpdateLog;
  END
  ELSE BEGIN
    Register(tvRead)^.UpdateLog;
    Register(ttRead)^.UpdateLog;
    Register(tv1)^.UpdateLog;
    Register(tt1)^.UpdateLog;
    Register(tv2)^.UpdateLog;
    Register(tt2)^.UpdateLog;
    Register(tt3)^.UpdateLog;
    Register(tt4)^.UpdateLog;
  END;

  Register(Valve1Pos)^.UpdateLog;
  Register(Valve2Pos)^.UpdateLog;
  Register(Damper1Pos)^.UpdateLog;
  Register(Damper2Pos)^.UpdateLog;
  Coil(ProcessFault)^.UpdateLog;
  Coil(DryingPhaseFlag)^.UpdateLog;
  Coil(Started)^.UpdateLog;
  Coil(MF1Run)^.UpdateLog;
  Coil(MF2Run)^.UpdateLog;
  Coil(MF3Run)^.UpdateLog;
  Coil(MF4Run)^.UpdateLog;
  Coil(MF5Run)^.UpdateLog;
  Coil(MF6Run)^.UpdateLog;
  Coil(VentFan1Run)^.UpdateLog;
  Coil(Pump1Run)^.UpdateLog;
  Coil(Pump2Run)^.UpdateLog;
  Coil(MotorFault)^.UpdateLog;
  Coil(MF1Fault)^.UpdateLog;
  Coil(MF2Fault)^.UpdateLog;
  Coil(MF3Fault)^.UpdateLog;
  Coil(MF4Fault)^.UpdateLog;
  Coil(MF5Fault)^.UpdateLog;
  Coil(MF6Fault)^.UpdateLog;
  Coil(VentFan1Fault)^.UpdateLog;
  Coil(Pump1Fault)^.UpdateLog;
  Coil(Pump2Fault)^.UpdateLog;
END; {PROC TunnelUnit.PLCRead}


PROCEDURE TunnelUnit.ResumeProcess;
{ - Examine PLC to check for NON-PC controlled changes in kiln control}
VAR
  Running : Boolean;
BEGIN
  GenericUnit.ResumeProcess;
  WITH Coil(Started)^
  DO Running:=(State=True) and isValid;
  IF (KilnMode=Stopped) and Running
  THEN KilnMode:=PLCcontrolled;
END; {PROC TunnelUnit.ResumeProcess}

PROCEDURE TunnelUnit.StartProcess;
{ - Execute kiln startup sequence}
VAR
  n  : Integer;
  Ok : Boolean;
BEGIN
  Register(tvSet)^.Value:=PTunnelModel(Model)^.sptv;
  Register(ttSet)^.Value:=PTunnelModel(Model)^.sptt;
  Register(delta_t)^.Value:=PTunnelModel(Model)^.delta_t;
  Register(WarmUpTime)^.Value:=PTunnelModel(Model)^.HeatTime;
  {$IFDEF NoSerial}
    Register(tt1)^.Value:=PTunnelModel(Model)^.sptt-1;
    Register(tt2)^.Value:=PTunnelModel(Model)^.sptt-2;
    Register(tv1)^.Value:=PTunnelModel(Model)^.sptv-1;
    Register(tv2)^.Value:=PTunnelModel(Model)^.sptv+1;
    Register(tt3)^.Value:=PTunnelModel(Model)^.sptt-5;
    Register(tt4)^.Value:=PTunnelModel(Model)^.sptt-3;
  {$ENDIF}
  GenericUnit.StartProcess;
  IF Coil(DryingPhaseFlag)^.Installed
  THEN KilnMode:=WarmingUp
  ELSE KilnMode:=Drying;
END; {PROC TunnelUnit.StartProcess}

PROCEDURE TunnelUnit.UpdateProcess;
{ - Walk through kiln registers/coils and look for comm.requests
    Use as Last call from inheritors}
VAR
  v1,v2:Integer;
BEGIN
  Register(tvSet)^.Value:=PTunnelModel(Model)^.sptv;
  Register(ttSet)^.Value:=PTunnelModel(Model)^.sptt;
  Register(delta_t)^.Value:=PTunnelModel(Model)^.delta_t;
  Register(WarmUpTime)^.Value:=PTunnelModel(Model)^.HeatTime;

{$IFDEF NoSerial}
{vv------------------------------------------------------vv}
  v1:=PTunnelModel(Model)^.sptv;
  v2:=PTunnelModel(Model)^.sptt;
  Register(tv1)^.Value:=v1+5-Random(10);
  Register(tt1)^.Value:=v2+5-Random(10);
  Register(tvRead)^.Value:=v1;
  Register(ttRead)^.Value:=v2;
  Register(tv2)^.Value:=v1-Random(10);
  Register(tt2)^.Value:=v2-Random(10);
  Register(tt3)^.Value:=v2+5+Random(3);
  Register(tt4)^.Value:=v2+5+Random(3);
{^^------------------------------------------------------^^}
{$ENDIF}

  GenericUnit.UpdateProcess;
  IF KilnMode<>Stopped
  THEN BEGIN
    IF Coil(DryingPhaseFlag)^.Installed
    THEN BEGIN
      IF Coil(DryingPhaseFlag)^.Last
      THEN KilnMode:=Drying
      ELSE KilnMode:=WarmingUp;
    END ELSE KilnMode:=Drying;
  END;
END; {PROC TunnelUnit.UpdateProcess}

PROCEDURE TunnelUnit.StopProcess;
BEGIN
  Register(tvSet)^.Value:=160;  {16.0 øC}
  Register(ttSet)^.Value:=200;  {20.0 øC}
  Register(delta_t)^.Value:=PTunnelModel(Model)^.delta_t;
  Register(WarmUpTime)^.Value:=PTunnelModel(Model)^.HeatTime;
  GenericUnit.StopProcess;
  KilnMode:=Stopped;
END; {PROC TunnelUnit.StopProcess}


FUNCTION TunnelUnit.UpdateDue:Boolean;
BEGIN
  UpdateDue:=SecondsSince(LastUpdate)>=UpdateInterval;
END; {FUNC TunnelUnit.UpdateDue}

FUNCTION TunnelUnit.Describe:String;
{ - Return a description string }
VAR
  s : String[79];
BEGIN
  s:=GenericUnit.Describe;
  s:=s+Model^.Describe
   +FloatStr(Register(tvSet)^.Last/10,6,1)
   +FloatStr(Register(tv1)^.Last/10,6,1)
   +FloatStr(Register(ttSet)^.Last/10,8,1)
   +FloatStr(Register(tt3)^.Last/10,6,1);  {Changed from tt1 to tt3: 920928 LF}
   IF Coil(ProcessFault)^.Last or Coil(MotorFault)^.Last
   THEN s:=s+'  '+Lookup('FAULT');
  Describe:=s;
END; {FUNC TunnelUnit.Describe}

FUNCTION TunnelUnit.TotalTime:Integer;
{ - Return total time usage }
BEGIN
  TotalTime:=Model^.TotalTime;
END; {FUNC TunnelUnit.TotalTime}



{------------------------------------------------------------- Unit init's ---
}

PROCEDURE RegisterKilnTypes;
BEGIN
  RegisterType(TunnelUnit_OSR);
END; {PROC RegisterKilnTypes}

VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}
CONST
  P4UnitMsg = ' P4U_Tunl ';

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

