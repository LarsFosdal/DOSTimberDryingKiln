{$I CODEDEFS.PAS}

UNIT P4Kiln;

INTERFACE
USES
  Dos, Objects, P4Config, P4Model, P4U_Gen, P4U_Kiln, P4U_Mdl, P4U_Tunl;

TYPE
  RefInitProc = PROCEDURE;
  pUnitList = ^UnitList;
  UnitList = OBJECT(TCollection)
    Config : pInstallInfo; {Referenced !!}
    BackupFileName : String;
    CONSTRUCTOR Init(VAR Cfg:pInstallInfo; Name:String);
    PROCEDURE   Link(VAR Cfg:pInstallInfo; Name:String);
    PROCEDURE   ReLink(VAR Cfg:pInstallInfo);
    PROCEDURE   ResumeProcess;
    PROCEDURE   UpdateProcess;
    PROCEDURE   UpdateView;
    PROCEDURE   SetRedraw(NewProc:RefreshProc);
    PROCEDURE   Redraw;
  END;



VAR
  BackupInterval : Integer;
  BackupLoaded : Boolean;
  LastBackup   : DateTime;
  Kilns,
  ActiveUnit   : pUnitList;
  StartRedraw,
  StopRedraw   : RefInitProc;
  DoRedraw     : RefreshProc;

FUNCTION  LoadBackup(BackupFileName:String; VAR Config:pInstallInfo; VAR Units:pUnitList; Verbose:Boolean):Boolean;
PROCEDURE StoreBackup;
PROCEDURE SecondaryInit(Config:pInstallInfo);
PROCEDURE ViewMenu(TheActiveUnit:pUnitList);


IMPLEMENTATION
USES
  Crt,Graph,LFsystem,LFCrt,LFdos,LFGraph,
  LFString,LFExtMsg,LFWindow,ObjInput,LFGfxWin,
  AGTools,LFDraw, P4Limits,P4Remote;

CONST
  UnitList_OID = 10020;
  UnitList_OSR: TStreamRec = (
    ObjType: UnitList_OID;
    VmtLink: Ofs(TypeOf(UnitList)^);
    Load:    @UnitList.Load;
    Store:   @UnitList.Store
  );

VAR
  KilnCount,
  MdlCount,
  TunnelCount : Integer;

FUNCTION LoadBackup(BackupFileName:String; VAR Config:pInstallInfo; VAR Units:pUnitList; Verbose:Boolean):Boolean;
VAR
  BackupFile   : LFStream;
BEGIN
  IF Verbose
  THEN Write('Backup file ');
  IF FSearch(BackupFileName,'')='' {Can't find backup-file}
  THEN BEGIN
    IF Verbose
    THEN Writeln('created !');
    New(Units, Init(Config,BackupFileName));
    BackupLoaded:=True;
  END
  ELSE BEGIN
    IF Verbose
    THEN Writeln('OK');
    BackupFile.Init(BackupFileName,stOpenRead,StreamBufSize);
    IF BackupFile.Status<>StOK
    THEN BEGIN
      AddToLog('Backup Stream Error');
      Blip;
      BackupLoaded:=False;
    END
    ELSE BEGIN
      New(Units, Load(BackupFile));
      BackupLoaded:=True;
    END;
    BackupFile.Done;
    Units^.Link(Config, BackupFileName);
  END;
  LoadBackup:=BackupLoaded;
END;

PROCEDURE WriteBackup;
VAR
  BackupFile   : LFStream;
BEGIN
  BackupFile.Init(Kilns^.BackupFileName,stCreate,StreamBufSize);
  Kilns^.Store(BackupFile);
  BackupFile.Done;
  IF LANdir<>''
  THEN CopyFile(Kilns^.BackupFileName, LANdir+AfterLast('\',Kilns^.BackupFileName));
END;

PROCEDURE StoreBackup;
BEGIN
  RaiseBusySign(DiskIO);
  WriteBackup;
  DropBusySign;
  StartWatch(LastBackup);
END;

PROCEDURE ProcessWatcher(VAR Inp:Word); FAR;
BEGIN
  Kilns^.UpdateProcess;
END; {PROC ProcessWatcher}

PROCEDURE RemoteWatcher(VAR Inp:Word); FAR;
BEGIN
  ActiveUnit^.UpdateView;
END; {PROC RemoteWatcher}

PROCEDURE AutoBackup(VAR Inp:Word); FAR;
BEGIN
  IF SecondsSince(LastBackup)>BackupInterval*60
  THEN StoreBackup;
END; {PROC AutoBackup}

{$IFDEF FastDemo}
PROCEDURE SimTimeIncrement(VAR Inp:Word); FAR;
CONST
  Prev : LongInt = 0;
VAR
  tick : LongInt Absolute $0040:$006C;
BEGIN
  IF Abs(tick-Prev)>1
  THEN LFDos.IncrementSimTime(1);
END; {PROC SimTimeIncrement}
{$ENDIF}

PROCEDURE CountKilns(Units:pUnitList);
  PROCEDURE Count_Type(K:PGenericUnit); FAR;
  BEGIN
    IF TypeOf(K^)=TypeOf(KilnUnit)
    THEN Inc(KilnCount)
    ELSE IF TypeOf(K^)=TypeOf(TunnelUnit)
    THEN Inc(TunnelCount);
  END; {PROC Count_Type}
BEGIN
  KilnCount:=0;
  TunnelCount:=0;
  Units^.ForEach(@Count_Type);
  IF KilnCount>0
  THEN MdlCount:=1
  ELSE MdlCount:=0;
END; {PROC CountKilns}

PROCEDURE SecondaryInit(Config:pInstallInfo);
BEGIN
  DeskTopTitle(LookUp('STARTUP'));
  BackupInterval:=Config^.BackupInterval;
  IF Not Monitor
  THEN BEGIN
    Kilns^.ResumeProcess;
    Idle.Add(ProcessWatcher);
    Idle.Enable(ProcessWatcher);
    StartWatch(LastBackup);
    Idle.Add(AutoBackup);
    Idle.Enable(AutoBackup);
   {$IFDEF FastDemo}
    InstallSimTime;
    Idle.Add(SimTimeIncrement);
    Idle.Enable(SimTimeIncrement);
   {$ENDIF}
  END;
END; {PROC SecondaryInit}

{---------------------------------------------------------------- UnitList ---
  Description

}

CONSTRUCTOR UnitList.Init(VAR Cfg:pInstallInfo; Name:String);
{ - Prepare a list of kilns, expandable by 1 at a time
    Also, connect Config Info}
VAR
  i : Integer;
  c : PGenericCfg;

BEGIN
  TCollection.Init(Cfg^.Units,1);
  FOR i:=0 TO Cfg^.Units-1
  DO BEGIN
    c:=Cfg^.Kilns.At(i);
    IF TypeOf(c^)=TypeOf(KilnCfg)
    THEN Insert(New(PKilnUnit,Init(c)))
    ELSE IF TypeOf(c^)=TypeOf(TunnelCfg)
    THEN Insert(New(PTunnelUnit,Init(c)))
    ELSE IF TypeOf(c^)=TypeOf(MdlCfg)
    THEN Insert(New(PMdlUnit,Init(c)))
  END;
  Config:=Cfg;
  BackupFileName:=Name;
END; {CONS UnitList.Init}

PROCEDURE UnitList.Link(VAR Cfg:pInstallInfo; Name:String);
{ - Reestablish connection to Config Info}
VAR
  n : Integer;
  PROCEDURE Kiln_LinkCfg(K:PGenericUnit); FAR;
  BEGIN
    K^.Link(PGenericCfg(Cfg^.Kilns.At(n)));
    Inc(n);
  END;
BEGIN
  n:=0;
  ForEach(@Kiln_LinkCfg);
  Config:=Cfg;
  BackupFileName:=Name;
END; {PROC UnitList.Link}

PROCEDURE UnitList.ReLink(VAR Cfg:pInstallInfo);
{ - Reestablish connection to Config Info}
VAR
  n : Integer;
  PROCEDURE Kiln_ReLinkCfg(K:PGenericUnit); FAR;
  BEGIN
    IF TypeOf(K^)<>TypeOf(MdlUnit)
    THEN K^.ReLink(PGenericCfg(Cfg^.Kilns.At(n)));
    Inc(n);
  END;
BEGIN
  n:=0;
  ForEach(@Kiln_ReLinkCfg);
  Config:=Cfg;
END; {PROC UnitList.ReLink}

PROCEDURE UnitList.ResumeProcess;
{ - Walk through the UnitList and look for update requests}
  PROCEDURE Kiln_Resume(K:PGenericUnit); FAR;
  BEGIN
    WSWrtLn(Lookup('Resuming')+' '+K^.Cfg^.Name^);
    K^.ResumeProcess;
  END;
BEGIN
  WSClear;
  ForEach(@Kiln_Resume);
END; {PROC UnitList.ResumeProcess}

PROCEDURE UnitList.UpdateProcess;
{ - Walk through the UnitList and look for update requests}
CONST
  Current : Integer = 0;
VAR
  K : PGenericUnit;
BEGIN
  K:=PGenericUnit(At(Current));
  IF Not K^.Cfg^.PLC^.ReadUpdate
  THEN AddToLog('ReadFail: '+K^.Cfg^.PLC^.LastRead);
  IF K^.UpdateDue  THEN K^.UpdateProcess;
  IF K^.RefreshDue THEN K^.Redraw;
  Inc(Current);
  IF Current=Config^.Units
  THEN Current:=0;
END; {PROC UnitList.UpdateProcess}

PROCEDURE UnitList.UpdateView;
{ - Walk through the UnitList and look for update requests}
CONST
  Current : Integer = 0;
VAR
  K : PGenericUnit;
BEGIN
  K:=PGenericUnit(At(Current));
  IF K^.RefreshDue THEN K^.Redraw;
  Inc(Current);
  IF Current=Config^.Units
  THEN Current:=0;
END; {PROC UnitList.UpdateView}

PROCEDURE UnitList.SetRedraw(NewProc:RefreshProc);
  PROCEDURE Unit_Set(K:PGenericUnit); FAR;
  BEGIN
    K^.Refresh:=NewProc;
  END;
BEGIN
  ForEach(@Unit_Set);
END; {PROC UnitList.SetRedraw}

PROCEDURE UnitList.Redraw;
  PROCEDURE Unit_Set(K:PGenericUnit); FAR;
  BEGIN
    K^.Redraw;
  END;
BEGIN
  ForEach(@Unit_Set);
END; {PROC UnitList.Redraw}



{---------------------------------------------------------- Text Kiln List ---
}

VAR
  KlnYOfs : Integer;
  TnlYOfs : Integer;

PROCEDURE UnitListEntry(K:PGenericUnit); FAR;
VAR
  YOfs : Integer;
BEGIN
  IF TypeOf(K^)<>TypeOf(MdlUnit)
  THEN BEGIN
    IF TypeOf(K^)=TypeOf(KilnUnit)
    THEN YOfs:=KlnYOfs
    ELSE YOfs:=TnlYOfs;
    WSWrtXY(0,YOfs+K^.Cfg^.Number,PadTrailing(' '+K^.Describe,' ',77));
  END;
END; {PROC UnitListEntry}

PROCEDURE UnitListRedrawDone; FAR;
BEGIN
  ActiveUnit^.SetRedraw(NoRefresh);
END;

PROCEDURE UnitListRedraw; FAR;
{ - Kiln status list }
VAR
  tyoffs : Integer;
BEGIN
  DeskTopTitle(LookUp('TEXTLIST'));
  WSClear; WSColor(WS^.Pane.Low);
  IF KilnCount>0
  THEN BEGIN
    KlnYOfs:=2;
    WSWrtXY(1,1,LookUp('KLNLSTH1'));
    WSWrtXY(1,2,LookUp('KLNLSTH2'));
  END ELSE KlnYOfs:=0;
  IF TunnelCount>0
  THEN BEGIN
    TnlYOfs:=KlnYOfs+2; IF KlnYOfs<>0 THEN Inc(TnlYOfs);
    WSWrtXY(1,TnlYOfs+KilnCount-1,LookUp('TNLLSTH1'));
    WSWrtXY(1,TnlYOfs+KilnCount  ,LookUp('TNLLSTH2'));
  END;
  WSC.SetAll(LightPaleBlue,Yellow);
  DoRedraw:=UnitListEntry;
  StopRedraw:=UnitListRedrawDone;
  ActiveUnit^.SetRedraw(DoRedraw);
  ActiveUnit^.Redraw;
END; {FUNC UnitListRedraw}


{---------------------------------------------------- Temperature Bar List ---
}

{ $ DEFINE ShowSetValue}

CONST
  tmpofs = {$IFDEF ShowSetValue} 16 {$ELSE} 0 {$ENDIF};


VAR
  FirstView,
  ViewCount,
  ViewWidth : Integer;
  BarView   : WorldWorkSpace;
  ViewType  : Pointer;

PROCEDURE TempBarEntry(K:PGenericUnit); FAR;
VAR
  n : Integer;
  PROCEDURE DoBar(v0,n1,v1,n2,v2,c:Integer; n:Str4);
    PROCEDURE WrtNum(x,offset,c:Integer; s:String);
    BEGIN
      SetFillStyle(SolidFill, WSBG);
      Bar(x+8,BarView.Bottom+offset,x+Length(s)*8, BarView.Bottom+Offset+16);
      gWrt(x, BarView.Bottom+offset, c, s);
    END;
  VAR
    x,c2 : Integer;
  BEGIN
    x:=BarView.xWtoD(n1);
{$IFDEF ShowSetValue}
    IF v0<>-9999
    THEN WrtNum(x, 16, c, FloatStr(v0/10,5,1));
{$ENDIF}
    IF n1<>n2
    THEN BEGIN
      WrtNum(x, 16+tmpOfs, c, FloatStr(v1/10,5,1));
      SetFillStyle(SolidFill,c);
      IF v1<MinScale THEN v1:=MinScale
      ELSE IF v1>MaxScale THEN v1:=MaxScale;
      BarView.Bar(n1,MinScale,n1+1,v1);
    END
    ELSE x:=x-16;
    IF c=Violet
    THEN c2:=LightRed
    ELSE c2:=c+8;
    WrtNum(x, 32+tmpOfs, c2, FloatStr(v2/10,5,1));
    SetFillStyle(SolidFill,c2);
    IF v2<MinScale THEN v2:=MinScale
    ELSE IF v2>MaxScale THEN v2:=MaxScale;
    BarView.Bar(n2,MinScale,n2+1,v2);
    gWrt(x+8,BarView.Bottom,BarView.Pane.Low.FG,n);
  END;

  PROCEDURE HideBar(v0,n1,v1,n2,v2:Integer);
  BEGIN
    SetFillStyle(SolidFill,WSBG);
    IF n1<>n2
    THEN BEGIN
      IF v1<MinScale THEN v1:=MinScale
      ELSE IF v1>MaxScale THEN v1:=MaxScale;
      Bar(BarView.xWtoD(n1),BarView.yWtoD(MaxScale),
          BarView.xWtoD(n1+1),BarView.yWtoD(v1)-1);
    END;
    IF v2<MinScale THEN v2:=MinScale
    ELSE IF v2>MaxScale THEN v2:=MaxScale;
    Bar(BarView.xWtoD(n2),BarView.yWtoD(MaxScale),
        BarView.xWtoD(n2+1),BarView.yWtoD(v2)-1);
  END;

VAR
  MsgOffset : Word;
  msgc      : Integer;
BEGIN
  IF (ViewType<>TypeOf(K^)) THEN Exit;
  n:=ActiveUnit^.IndexOF(K);
  IF (n>=FirstView) and (n<FirstView+ViewCount)
  THEN BEGIN
    IF ViewType=TypeOF(KilnUnit)
    THEN MsgOffset:=32
    ELSE MsgOffset:=96;

    BarView.MoveTo(WS^.Left+((n-FirstView)*(ViewWidth+32)), WS^.Top+64);
    SetFillStyle(SolidFill,BarView.Pane.Norm.BG);
    BarView.Recalculate;
    IF ViewType=TypeOf(TunnelUnit)
    THEN BEGIN
      HideBar( K^.Register(tvSet)^.Last,
            1, K^.Register(tvRead)^.Last,
            2, K^.Register(tv1)^.Last);
      HideBar(   -9999,
            4, 0,
            4, K^.Register(tt1)^.Last);
      HideBar( K^.Register(ttSet)^.Last,
            6, K^.Register(ttRead)^.Last,
            7, K^.Register(tt3)^.Last);
      HideBar( K^.Register(ttSet)^.Last,
            9, K^.Register(ttRead)^.Last,
           10, K^.Register(tt4)^.Last);
    END
    ELSE BEGIN
      HideBar( K^.Register(tvSet)^.Last,
            1, K^.Register(tvRead)^.Last,
            2, K^.Register(tv1)^.Last);
      HideBar( K^.Register(ttSet)^.Last,
            4, K^.Register(ttRead)^.Last,
            5, K^.Register(tt1)^.Last);
    END;
    BarView.Open;
    SetTextStyle(TriplexFont, HorizDir,4);
    SetTextJustify(CenterText,BottomText); SetColor(BarView.Pane.High.FG);
    n:=BarView.Left+BarView.xScaleMargin+((BarView.Width-BarView.xScaleMargin) DIV 2);

    OutTextXY(n, BarView.Top-16, K^.Cfg^.Name^);
    SetTextStyle(SmallFont, HorizDir,5);
    Bar(BarView.Left, BarView.Top-15, BarView.Right, BarView.Top);
    gWrt(n-(Length(ModeName[K^.KilnMode]^)*4),BarView.Top-15,BarView.Pane.Norm.FG,ModeName[K^.KilnMode]^);

    BarView.yScale(DottedLn);
    gWrt(BarView.Left,BarView.Top,BarView.Pane.Low.FG,LookUp('CELSIUS'));
{$IFDEF ShowSetValue}
    gWrt(BarView.Left+28,BarView.Bottom+16,BarView.Pane.Norm.FG,Lookup('SETIDEAL'));
{$ENDIF}
    gWrt(BarView.Left+28,BarView.Bottom+16+tmpofs,BarView.Pane.Norm.FG,Lookup('SETPOINT'));
    gWrt(BarView.Left+28,BarView.Bottom+32+tmpofs,BarView.Pane.Norm.FG,Lookup('VALUE'));
    gWrt(BarView.Left+60,BarView.Bottom+48+tmpofs,BarView.Pane.Norm.FG,K^.Model^.Describe);

    IF K^.Coil(ProcessFault)^.Last THEN msgc:=LightRed ELSE msgc:=WSBG;
    gWrt(BarView.Left+MsgOffset,BarView.Bottom+80,msgc,LookUp('PROERROR'));

    IF K^.Coil(MotorFault)^.Last THEN msgc:=LightRed ELSE msgc:=WSBG;
    gWrt(BarView.Left+MsgOffset,BarView.Bottom+96,msgc,LookUp('MVERROR'));

    IF ViewType=TypeOf(TunnelUnit)
    THEN BEGIN
      DoBar(   K^.Register(tvSet)^.Last,
            1, K^.Register(tvRead)^.Last,
            2, K^.Register(tv1)^.Last, Blue,K^.Register(tv1)^.Name^);
      DoBar(   -9999,
            4, 0,
            4, K^.Register(tt1)^.Last,Violet,K^.Register(tt1)^.Name^);
      DoBar(   K^.Register(ttSet)^.Last,
            6, K^.Register(ttRead)^.Last,
            7, K^.Register(tt3)^.Last, Red,K^.Register(tt3)^.Name^);
      DoBar(   K^.Register(ttSet)^.Last,
            9, K^.Register(ttRead)^.Last,
           10, K^.Register(tt4)^.Last, Red,K^.Register(tt4)^.Name^);
    END
    ELSE BEGIN
      DoBar(   K^.Register(tvSet)^.Last,
            1, K^.Register(tvRead)^.Last,
            2, K^.Register(tv1)^.Last, Blue,K^.Register(tv1)^.Name^);
      DoBar(   K^.Register(ttSet)^.Last,
            4, K^.Register(ttRead)^.Last,
            5, K^.Register(tt1)^.Last, Red,K^.Register(tt1)^.Name^);
    END;
    BarView.Close;
  END;
END; {PROC TempBarEntry}

PROCEDURE TempBarRedrawDone; FAR;
BEGIN
  BarView.Done;
  ActiveUnit^.SetRedraw(NoRefresh);
END;

PROCEDURE TempBarAdjust;
VAR
  K     : PGenericUnit;
  Count : Integer;
BEGIN
  K:=PGenericUnit(ActiveUnit^.At(FirstView));
  ViewType:=TypeOf(K^);
  IF ViewType=TypeOf(KilnUnit)
  THEN BEGIN
    ViewCount:=3;
    Count:=KilnCount;
  END
  ELSE BEGIN
    ViewCount:=2;
    Count:=TunnelCount;
  END;
  ViewWidth:=(WS^.Width DIV ViewCount)-32;
  BarView.SizeSet(ViewWidth,WS^.Height-196);
  CASE ViewCount OF
    2 : BarView.World(0.5,MinScale,11.5,MaxScale);
    3 : BarView.World(0.5,MinScale,6.5,MaxScale);
  END;
  IF ViewCount>Count THEN ViewCount:=Count;
END; {PROC TempBarAdjust}

PROCEDURE TempBarRedraw; FAR;
{ - Kiln status list }
BEGIN
  BarView.Init(0,0,100,WS^.Height-196,-1,0);
  BarView.AutoClear:=False;
  BarView.ysf:=10;
  TempBarAdjust;
  DeskTopTitle(LookUp('BARLIST'));
  WSClear;
  DoRedraw:=TempBarEntry;
  StopRedraw:=TempBarRedrawDone;
  ActiveUnit^.SetRedraw(DoRedraw);
  ActiveUnit^.Redraw;
END; {FUNC RedrawTempBar}


{----------------------------------------------------------------------------}

FUNCTION SelectKiln(Config:pInstallInfo):PGenericUnit;
{ - Select Kiln by menu of kilns }
CONST
  Prev : Integer = 1;
VAR
  k   : PGenericUnit;
  win : PGfxWin;
  mnu : PMenuInput;
  kln : PMenuTxt;
BEGIN
  BuildKilnList(Config, kln);
  New(Win,InitTxt(35,20,30,10,True));
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  New(Mnu,Init(Win,10,kln));
{  IF Config^.Remote and (KilnCount>0)
  THEN mnu^.mnu^.LineDisable(KilnCount+TunnelCount); {Disable KammerModell}
  mnu^.Current:=Prev;
  mnu^.Select;
  Prev:=Mnu^.Current;
  IF mnu^.Choice<>0
  THEN K:=PGenericUnit(ActiveUnit^.At(mnu^.Choice-1))
  ELSE K:=nil;
  SelectKiln:=K;
  Dispose(mnu,Done);
  Dispose(Win,Done);
  Dispose(kln,Done);
END; {FUNC SelectKiln}


PROCEDURE ViewMenu(TheActiveUnit:pUnitList);
CONST
  View : RefInitProc = TempBarRedraw;
VAR
  k   : PGenericUnit;
  Key : PKeyStroke;
  Op  : Integer;
  MTxt: PString;
BEGIN
  ActiveUnit:=TheActiveUnit;
  IF ActiveUnit^.Config^.Remote
  THEN BEGIN
    Idle.Add(RemoteWatcher);
    Idle.Enable(RemoteWatcher);
  END;
  CountKilns(ActiveUnit);
  FirstView:=0;
  StartRedraw:=View;
  New(Key,Init(WorkSpace,1,1,[ESC,^R,^C,^M,^I,F9,'P'],True));
  Key^.Link(Msg,'BarHlp?','','');
  StartRedraw;
  REPEAT
    IF (@StartRedraw=@TempBarRedraw)
    THEN MTxt:=PLookUp('ChartCMD')
    ELSE MTxt:=PLookUp('ListCMD');
    PutMsg(MTxt^,LookUp('CMDPRESC'));
    ActiveUnit^.SetRedraw(DoRedraw);
    Key^.WaitForValid;
    ActiveUnit^.SetRedraw(NoRefresh);
    CASE Key^.LastChar OF
      ^M,F9 : BEGIN
                k:=SelectKiln(ActiveUnit^.Config);
                IF k<>nil
                THEN BEGIN
                  StopRedraw;
                  K^.Operation;
                  StartRedraw;
                END;
              END;
      ^I    : BEGIN
                StopRedraw;
                IF   @StartRedraw=@TempBarRedraw
                THEN StartRedraw:=UnitListRedraw
                ELSE StartRedraw:=TempBarRedraw;
                StartRedraw;
              END;
      ^R  : IF (@StartRedraw=@TempBarRedraw) and (FirstView>0)
            THEN BEGIN
              StopRedraw;
              IF FirstView>KilnCount
              THEN Dec(FirstView,2)
              ELSE Dec(FirstView,3);
              IF FirstView<0 THEN FirstView:=0;
              TempBarAdjust;
              WSClear;
              StartRedraw;
            END;
      ^C  : IF (@StartRedraw=@TempBarRedraw) and (FirstView<ActiveUnit^.Count-ViewCount-MdlCount)
            THEN BEGIN
              StopRedraw;
              IF FirstView<KilnCount
              THEN Inc(FirstView,ViewCount)
              ELSE Inc(FirstView,ViewCount);
              IF FirstView+ViewCount>KilnCount+TunnelCount
              THEN FirstView:=KilnCount+TunnelCount-ViewCount+1;
              TempBarAdjust;
              WSClear;
              StartRedraw;
            END;
      'P' : BEGIN
              IF PrintHeader
              THEN PrintWorkSpace([WSBG,LightPaleBlue]);
              PrintFooter;
            END;
    END;
  UNTIL Key^.LastChar=ESC;
  View:=StartRedraw;
  StopRedraw;
  IF ActiveUnit^.Config^.Remote
  THEN BEGIN
    Idle.Disable(RemoteWatcher);
    Idle.Remove(RemoteWatcher);
  END;
  Dispose(Key,Done);
END; {PROC ViewMenu}

VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}
CONST
  P4KilnMsg = ' P4Kiln ';

PROCEDURE P4KilnExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitHandler;
  IF BackupLoaded and not Monitor
  THEN BEGIN
    IF SecondsSince(LastBackup)>=30
    THEN WriteBackup;
    Dispose(Kilns, Done);
  END;
  Idle.Remove(ProcessWatcher);
  Idle.Remove(AutoBackup);
 {$IFDEF FastDemo}
  Idle.Remove(SimTimeIncrement);
 {$ENDIF}
  Units.Leave(P4KilnMsg,MemAvail);
END; {PROC P4KilnExitHandler}

BEGIN {Init part of P4Kiln}
  PrevExitHandler:=ExitProc;
  ExitProc:=@P4KilnExitHandler;
  Units.Enter(P4KilnMsg,MemAvail,Cseg);
  StartWatch(LastBackup);
  RegisterType(UnitList_OSR);
  BackupLoaded:=False;
END.


