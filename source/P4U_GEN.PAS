{$I CODEDEFS.PAS} {Include code generation definitions}
{$X+}
UNIT P4U_Gen;

INTERFACE
USES
  Dos,Objects,
  LFsystem, LFExtMsg, LFDraw, PLCDrive, LFWindow, LFGfxWin,
  P4Limits, P4Config, P4Model;

CONST
  Stopped       = 0;
  WarmingUp     = 1;
  Equalizing    = 2;
  Drying        = 3;
  Conditioning  = 4;
  CoolingDown   = 5;
  Finished      = 6;
  Running       = 7;
  PLCcontrolled = 8;

    { PRO2   StatusTyp= (Stop,Warm,Equ,Dry,Cond,Cool,Fini,Modi,Loop);}

CONST
  BackupVersion = 1;  {MUST be change if adding parameters to Backup}
TYPE

  PGenericUnit = ^GenericUnit;
  RefreshProc  = PROCEDURE (Kiln:PGenericUnit);

  GenericUnit = OBJECT(TObject)
    Version     : VersionRec;
    IsVersion   : Integer;
    Model       : PModelType;   {Stored}
    Cfg         : PGenericCfg;  {Linked}
    Log         : PLogList;     {Stored}
    LastUpdate,                 {Stored}
    StartTime   : DateTime;     {Stored}
    KilnMode    : Integer;      {Stored}
    Statics     : PDrawing;     {Volatile}
    Dynamics    : PAnimation;   {Volatile}
    Refresh     : RefreshProc;  {Volatile}
    RefreshDue  : Boolean;      {Volatile}
    Interrupted : Boolean;      {Volatile}
    PrevTt      : Integer;      {Volatile}
    PrevTv      : Integer;      {Volatile}

    CONSTRUCTOR Init(NewCfg:PGenericCfg);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);     VIRTUAL;
    DESTRUCTOR  Done;                     VIRTUAL;
    PROCEDURE   Link(NewCfg:PGenericCfg); VIRTUAL;
    PROCEDURE   ReLink(NewCfg:PGenericCfg); VIRTUAL;
    FUNCTION    ParamEdit(WS:PWorkSpace):Char; VIRTUAL;
    PROCEDURE   ParamView(WS:PWorkSpace); VIRTUAL;
    PROCEDURE   TimeView(Win:PGfxWin);    VIRTUAL;
    FUNCTION    MakeOpMenu:PMenuTxt;      VIRTUAL;
    FUNCTION    SelectOp:Integer;
    PROCEDURE   Operation;                VIRTUAL;
    PROCEDURE   Chart;                    VIRTUAL;
    PROCEDURE   PrintInfo;                VIRTUAL;
    PROCEDURE   DestroyDiagram;
    PROCEDURE   RepaintDiagram;
    PROCEDURE   MakeDiagram;              VIRTUAL;
    PROCEDURE   ProcessDiagram;
    PROCEDURE   PreLog;
    PROCEDURE   ProLog;
    PROCEDURE   PLCWrite;                 VIRTUAL;
    PROCEDURE   PLCRead;                  VIRTUAL;
    PROCEDURE   ResumeProcess;            VIRTUAL;
    PROCEDURE   StartProcess;             VIRTUAL;
    PROCEDURE   UpdateProcess;            VIRTUAL;
    PROCEDURE   StopProcess;              VIRTUAL;
    PROCEDURE   Redraw;
    FUNCTION    UpdateDue:Boolean;        VIRTUAL;
    FUNCTION    Describe:String;          VIRTUAL;
    FUNCTION    TotalTime:Integer;        VIRTUAL;
    FUNCTION    Coil(ID:Word):PCoil;
    FUNCTION    Register(ID:Word):PRegister;
  END; {OBJ GenericUnit}

VAR
  ModeName : ARRAY[Stopped..PLCcontrolled] OF PString;

PROCEDURE SecondaryInit;
PROCEDURE NoRefresh(Kiln:PGenericUnit);

CONST
  GenericUnit_OID = 10021;
  GenericUnit_OSR: TStreamRec = (
    ObjType: GenericUnit_OID;
    VmtLink: Ofs(TypeOf(GenericUnit)^);
    Load:    @GenericUnit.Load;
    Store:   @GenericUnit.Store
  );

CONST
  MaxHours : Word = TotalHours;
  lnWidth  : Integer = 1;  {Set to 3 for thick lines in graph}
  GrafPart : Integer = 1;
VAR
  Graf     : WorldWorkSpace;

CONST
  LTri_c = 5;
  LTri : ARRAY[1..2*LTri_c] OF Integer
  = (0,0,   0,-6,   10,0,   0,6,   0,0);

  RTri_c = 5;
  RTri : ARRAY[1..2*RTri_c] OF Integer
  = (10,0,   10,-6,   0,0,   10,6,   10,0);

  Valve_c =5;
  Valve : ARRAY[1..2*Valve_c] OF Integer
  = (-6,-10,    6,-10,    -6,10,    6,10,   -6,-10);

VAR
  D1,D2                      : DamperParamType;
  V1,V2                      : DamperParamType;
  MF1,MF2,MF3,MF4,MF5,MF6,
  VF1,VF2,P1,P2              : MotorParamType;
  T1T,T1V,T2T,T2V,T3T,T4T    : FieldParamType;
  BAS                        : BoolParamType;

IMPLEMENTATION
USES
  Crt,Graph,LFtable,LFString,LFDos, LFCrt,
  ObjInput,AGTools;

PROCEDURE SecondaryInit;
CONST
  sn_tag = 'STATENAMES';
VAR
  i : Integer;
  t : PTextTxt;
BEGIN
  t:=Msg^.FindText(sn_tag);
  IF t<>nil
  THEN FOR i:=Stopped TO PLCControlled
  DO ModeName[i]:=t^.PTextAtLine(i);
END; {PROC SecondaryInit}


PROCEDURE NoRefresh(Kiln:PGenericUnit);
BEGIN
END; {PROC NoRefresh}

{------------------------------------------------------------- GenericUnit ---
  Description

}

CONSTRUCTOR GenericUnit.Init(NewCfg:PGenericCfg);
{ - Initialize kiln with connected Config info }
BEGIN
  TObject.Init;
  Version:=VersionID;
  Version.Version:=BackupVersion;
  Cfg:=NewCfg;
  New(Log,Init(Cfg^.PLC,LoggingsPerSample));
  StartWatch(StartTime);
  LastUpdate:=StartTime;
  KilnMode:=Stopped;
  RefreshDue:=False;
  Interrupted:=False;
  Refresh:=NoRefresh;
  PrevTt:=-999;
  PrevTv:=-999;
  Statics:=nil;
  Dynamics:=nil;
END; {CONS GenericUnit.Init}

CONSTRUCTOR GenericUnit.Load(VAR S:TStream);
{ - Load stored kiln and re-connect Config info}
VAR
  VerID : Integer;
BEGIN
  TObject.Init;

  S.Read(Version, SizeOf(Version));
  IF Version.Signature<>VersionID.Signature
  THEN BEGIN
    Version:=VersionID;
    Version.Version:=BackupVersion;
    IsVersion:=0;
    S.Seek(0);
  END
  ELSE IsVersion:=Version.Version;

  Log:=PLogList(S.Get);
  Model:=PModelType(S.Get);
  S.Read(StartTime,SizeOf(StartTime));
  S.Read(LastUpdate,SizeOf(LastUpdate));
  S.Read(KilnMode,SizeOf(KilnMode));
  RefreshDue:=True;
  Interrupted:=False;
  Refresh:=NoRefresh;
  Statics:=nil;
  Dynamics:=nil;

  IF IsVersion<BackupVersion    {If updating an old version of the bku file}
  THEN BEGIN
    FOR VerID:=IsVersion TO BackupVersion
    DO BEGIN
      CASE VerID OF
        0 : {Do nothing};
      END;
    END;
  END;

END; {CONS GenericUnit.Load}

PROCEDURE GenericUnit.Store(VAR S:TStream);
{ - Store kiln _without_ Config info}
BEGIN
  S.Write(Version, SizeOf(Version));
  S.Put(Log);
  S.Put(Model);
  S.Write(StartTime,SizeOf(StartTime));
  S.Write(LastUpdate,SizeOf(LastUpdate));
  S.Write(KilnMode,SizeOf(KilnMode));
END; {PROC GenericUnit.Store}

DESTRUCTOR GenericUnit.Done;
{ - Cleanup after kiln }
BEGIN
  Log^.UnLink(Cfg^.PLC);
  Dispose(Log,Done);
  Dispose(Model,Done);
END; {DEST GenericUnit.Done}

PROCEDURE GenericUnit.Link(NewCfg:PGenericCfg);
{ - Reestablish link to configuration }
BEGIN
  Cfg:=NewCfg;
  Log^.Link(Cfg^.PLC);
END; {PROC GenericUnit.Link}

PROCEDURE GenericUnit.ReLink(NewCfg:pGenericCfg);
BEGIN
  Log^.UnLink(Cfg^.PLC);
  Link(NewCfg);
END;

CONST
  NewFile = ' <Ny fil>';
  NoFile  = ' <Angre>';
  MdlFN   = '*.MDL';

FUNCTION SelFileName(NewF:Boolean):String;
CONST
  mTitle : ARRAY[Boolean] OF String[30] = ('Hent Modell', 'Lagre Modell');
VAR
  Win : PGfxWin;
  Mnu : PMenuInput;
  MnuTxt : pMenuTxt;
  FI  : SearchRec;
  FS,FN  : String;
  fc  : Integer;
  Fields : pFieldList;
  f      : pStrInput;
  PrevExit : CharSet;
BEGIN
  FN:='';
  FS:=Path+MdlFN;
  New(MnuTxt, Init(NoFile, mTitle[NewF]));
  MnuTxt^.AddLine(NoFile);
  IF NewF
  THEN MnuTxt^.AddLine(NewFile);
  fc:=0;
  FindFirst(FS, ReadOnly or Archive, FI);
  WHILE DosError=0
  DO BEGIN
    Inc(fc);
    MnuTxt^.AddLine(BeforeLast('.',FI.Name));
    FindNext(FI);
  END;
  IF (fc=0) and Not NewF
  THEN BEGIN
    Blip;
  END
  ELSE BEGIN
    New(Win, InitTxt(33,14,30,12,True));
    New(Mnu, Init(Win,MnuTxt^.Lines, MnuTxt));
    Mnu^.Select;
    IF (Mnu^.LastChar<>Esc)
    THEN BEGIN
      FN:=MnuTxt^.TextAtLine(Mnu^.Choice-1);
      IF FN=NoFile
      THEN FN:=''
      ELSE BEGIN
        IF FN=NewFile
        THEN BEGIN
          Dispose(Win, Done);
          New(Win, InitTxt(28, 14, 25, 3, True));
          New(Fields,Init);
          New(f, Init(Win^.WorkSpace, 16, 1, 8, 'NYFIL', ([#33..#127]-FnamSet)-['\','.',':'], True));
          f^.Link(Msg,'','FILENAME','');
          Fields^.Add(FN, f);
          Win^.Open;
          Fields^.Display;
          PrevExit:=EdExitSet;
          EdExitSet:=[Esc, F9, ^M];
          Fields^.Edit;
          EdExitSet:=PrevExit;
          Win^.Close;
          CASE Fields^.LastChar OF
            Esc : FN:='';
            ELSE BEGIN
              Fields^.Fetch(FN);
              FN:=Path+FN+'.MDL'
            END;
          END;
          Dispose(Fields, Done);
        END
        ELSE FN:=Path+FN+'.MDL';
      END;
    END;
    Dispose(Win, Done);
    Dispose(Mnu, Done);
  END;
  Dispose(MnuTxt, Done);
{$IFDEF Aux}
  Writeln(Aux,'Filename: "',FN,'"');
{$ENDIF}
  SelFileName:=FN;
END; {FUNC SelFileName}

FUNCTION LoadModel:pModelType;
VAR
  FName     : String;
  ModelFile : LFStream;
  mdl       : pModelType;
BEGIN
  mdl:=nil;
  FName:=SelFileName(False);
  IF FName<>''
  THEN BEGIN
{$IFDEF Aux}
  Writeln(Aux,'Load Filename: "',FName,'"');
{$ENDIF}
    ModelFile.Init(FName, stOpen, StreamBufSize);
    mdl:=pModelType(ModelFile.Get);
    IF ModelFile.Status<>stOK
    THEN BEGIN
      AddToLog('Invalid model file "'+FName+'" ?');
      mdl:=nil;
      Blip;
    END;
    ModelFile.Done;
  END;
  LoadModel:=mdl;
END; {FUNC LoadModel}

PROCEDURE SaveModel(mdl:pModelType);
VAR
  FName : String;
  ModelFile : LFStream;
BEGIN
  FName:=SelFileName(True);
  IF FName<>''
  THEN BEGIN
{$IFDEF Aux}
  Writeln(Aux,'Save Filename: "',FName,'"');
{$ENDIF}
    ModelFile.Init(FName, stCreate, StreamBufSize);
    ModelFile.Put(mdl);
    ModelFile.Done;
  END;
END; {PROC SaveModel}

PROCEDURE EditModelData(mdl:pOwnModel);
VAR
  Win,Win2 : PGfxWin;
  Mnu : PMenuInput;
  MnuTxt : pMenuTxt;
  Fields : pFieldList;
  i,err,pri : Integer;
  f      : pFloatInput;
  t,v    : Float;
  EdLn   : String;
  PrevExit : CharSet;
  Ch : Char;
BEGIN
  pri:=1;
  New(Win, InitTxt(27,14,30,12,True));
  Win^.Title(LookUp('ENTERCHG'), LookUp('F10RETURN'));

  REPEAT
    New(MnuTxt, Init('',''));
    i:=0;

    REPEAT
      MnuTxt^.AddLine(IntStr(i,3)+': '
               +FloatStr(mdl^.tt.At(Mdl^.EquTime+i)/10,4,1)+'  '
               +FloatStr(mdl^.tv.At(Mdl^.EquTime+i)/10,4,1));
      i:=i+mdl^.DataInterval;
    UNTIL i > mdl^.DryTime;
    IF (i-mdl^.DataInterval) < mdl^.DryTime
    THEN MnuTxt^.AddLine(IntStr(Mdl^.DryTime,3)+': '
               +FloatStr(mdl^.tt.At(Mdl^.EquTime+Mdl^.DryTime)/10,4,1)+'  '
               +FloatStr(mdl^.tv.At(Mdl^.EquTime+Mdl^.DryTime)/10,4,1));


    PrevExit:=EdExitSet;
    EdExitSet:=[ESC, F9, F10];
    New(Mnu, Init(Win,10, MnuTxt));

    IF pri<=MnuTxt^.Lines
    THEN Mnu^.Current:=pri;
    Mnu^.Select;
    EdExitSet:=PrevExit;
    Ch:=Mnu^.LastChar;

    IF Not (Ch in [Esc, F10])
    THEN BEGIN
      Pri:=Mnu^.Current;
      EdLn:=BeforeLast(':',MnuTxt^.TextAtLine(Mnu^.Choice-1));
      VAL(EdLn,i,Err);
      v:=Mdl^.tv.At(Mdl^.EquTime+i)/10;
      t:=Mdl^.tt.At(Mdl^.EquTime+i)/10;
      New(Win2, InitTxt(20, 14, 37, 4, True));
      Win2^.Title(LookUp('ATTIME')+EdLn,LookUp('ENTERESC'));
      New(Fields,Init);
      New(f, Init(Win2^.WorkSpace, 20, 1, 4,1, 0.0, t, KilnMaxTDry));
      f^.Link(Msg,'DRY-TEMP?','DRY-TEMP','CELSIUS');
      Fields^.Add(t, f);
      New(f, Init(Win2^.WorkSpace, 20, 2, 4,1, 0.0, v, KilnMaxTWet));
      f^.Link(Msg,'WET-TEMP?','WET-TEMP','CELSIUS');
      Fields^.Add(v, f);

      Win2^.Open;
      Fields^.Display;
      PrevExit:=EdExitSet;
      EdExitSet:=[Esc, F9, ^M];
      Fields^.Edit;
      EdExitSet:=PrevExit;
      Win2^.Close;

      CASE Fields^.LastChar OF
        Esc : ;
        ELSE BEGIN
          Fields^.Fetch(t);
          Fields^.Fetch(v);
          Mdl^.tv.AtPut(Mdl^.EquTime+i,Trunc(v*10));
          Mdl^.tt.AtPut(Mdl^.EquTime+i,Trunc(t*10));
        END;
      END;
      Dispose(Fields, Done);
      Dispose(Win2, Done);
    END
    ELSE Pri:=1;
    Dispose(Mnu, Done);
    Dispose(MnuTxt, Done);
  UNTIL Ch In [Esc, F10];
  Dispose(Win, Done);
END; {PROC EditModelData}

FUNCTION GenericUnit.ParamEdit(WS:PWorkSpace):Char;
{ - }
VAR
  Fields  : PFieldList;
  NewMdl  : pModelType;
  OwnMdl  : Boolean;
  ch      : Char;
BEGIN
  REPEAT
    New(Fields,Init);
    OwnMdl:=TypeOf(Model^)=TypeOf(OwnModel);
    IF OwnMdl
    THEN EdExitSet:=[Esc, F9, F2, F3, F10];
    Model^.CreateFields(WS,Fields);
    WS^.Clear;
    Fields^.Display;
    IF OwnMdl
    THEN BEGIN
      WS^.WrtTxt(10,5,WS^.Pane.Low,LookUp('F2/F3'));
      WS^.WrtTxt(10,6,WS^.Pane.Low,LookUp('F10TABLE'));
    END;
    Fields^.Edit;
    CASE Fields^.LastChar OF
      F2 : BEGIN
             WS^.Leave;
             SaveModel(Model);
           END;
      F3 : BEGIN
             WS^.Leave;
             NewMdl:=LoadModel;
             IF NewMdl<>nil
             THEN BEGIN
               Dispose(Model, Done);
               Model:=NewMdl;
             END;
           END;
      F9 : BEGIN
             Model^.GetFields(Fields);
             RaiseBusySign(Calculus);
             Model^.Calculate(Cfg);
             DropBusySign;
             Model^.SetFields(Fields);
             Fields^.Refresh;
           END;
     F10 : BEGIN
             Model^.GetFields(Fields);
             Model^.AdjustSize;
             EditModelData(pOwnModel(Model));
           END;
    END;
    Ch:=Fields^.LastChar;
    Dispose(Fields,Done);
  UNTIL Ch in [Esc, F9];
  EdExitSet:=[Esc, F9];
  ParamEdit:=Ch;
END; {PROC GenericUnit.ParamEdit}

PROCEDURE GenericUnit.ParamView(WS:PWorkSpace);
{ - }
VAR
  Fields  : PFieldList;
BEGIN
  New(Fields,Init);
  Model^.CreateFields(WS,Fields);
  WS^.Clear;
  Fields^.Display;
  WaitForAnyKey('PARAMVIEW');
  Dispose(Fields,Done);
END; {PROC GenericUnit.ParamView}

PROCEDURE GenericUnit.TimeView;
BEGIN
END; {PROC GenericUnit.TimeView}

FUNCTION GenericUnit.SelectOp:Integer;
VAR
  Op  : Integer;
  Alt : PMenuTxt;
  win : PGfxWin;
  mnu : PMenuInput;
BEGIN
  IF KilnMode=Stopped
  THEN Op:=0
  ELSE Op:=10;
  Alt:=MakeOpMenu;
  IF Alt=nil THEN RunError(204);
  New(Win,InitTxt(33,20,30,10,True));
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  Win^.Title('',Cfg^.Name^);
  New(Mnu,Init(Win,Alt^.Lines,Alt));
  mnu^.Select;
  Op:=Op+Mnu^.Choice;
  Dispose(Mnu,Done);
  Dispose(Win,Done);
  SelectOp:=Op;
END; {FUNC GenericUnit.SelectOp}

FUNCTION GenericUnit.MakeOpMenu:PMenuTxt;
BEGIN
  TrapAbstract;
END; {FUNC GenericUnit.MakeOpMenu}

PROCEDURE GenericUnit.Operation;
BEGIN
  TrapAbstract;
END; {PROC GenericUnit.Operation}

PROCEDURE GenericUnit.Chart;
BEGIN
  DeskTopTitle(LookUp('TMPCHART')+Cfg^.Name^);
  WSClear;
END; {PROC GenericUnit.Chart}

PROCEDURE GenericUnit.PrintInfo;
BEGIN
  PrintLine('');
  PrintLine('T›rkeparametre for '+Cfg^.Name^+'  ('+ModeName[KilnMode]^+')');
  PrintLine(PadLeading('Startet :',' ',30)+ LookWatch(StartTime));
  Model^.PrintInfo;
END; {PROC GenericUnit.Print}

PROCEDURE GenericUnit.DestroyDiagram;
BEGIN
  IF Statics<>nil
  THEN Dispose(Statics, Done);
  Statics:=nil;
  IF Dynamics<>nil
  THEN Dispose(Dynamics, Done);
  Dynamics:=nil;
END; {PROC GenericUnit.DestroyDiagram}

PROCEDURE GenericUnit.MakeDiagram;
BEGIN
END; {PROC GenericUnit.MakeDiagram}

PROCEDURE GenericUnit.RepaintDiagram;
BEGIN
  DeskTopTitle(LookUp('PRODIAG')+Cfg^.Name^);
  WSClear;
  Statics^.Draw;
  Dynamics^.Draw;
  RefreshDue:=True;
END; {PROC GenericUnit.RepaintDiagram}

PROCEDURE GenericUnit.ProcessDiagram;
VAR
  Key : PKeyStroke;
BEGIN
  FillChar(D1,SizeOf(D1),0);     FillChar(D2,SizeOf(D2),0);
  FillChar(V1,SizeOf(V1),0);     FillChar(V2,SizeOf(V2),0);
  FillChar(MF1,SizeOf(MF1),0);   FillChar(T1T,SizeOf(T1T),0);
  FillChar(MF2,SizeOf(MF2),0);   FillChar(T1V,SizeOf(T1V),0);
  FillChar(MF3,SizeOf(MF3),0);   FillChar(T2T,SizeOf(T2T),0);
  FillChar(MF4,SizeOf(MF4),0);   FillChar(T2V,SizeOf(T2V),0);
  FillChar(MF5,SizeOf(MF5),0);   FillChar(T3T,SizeOf(T3T),0);
  FillChar(MF6,SizeOf(MF6),0);   FillChar(T4T,SizeOf(T4T),0);
  FillChar(VF1,SizeOf(VF1),0);   FillChar(VF2,SizeOf(VF2),0);
  FillChar(P1,SizeOf(P1),0);     FillChar(P2,SizeOf(P2),0);
  FillChar(BAS, SizeOf(BAS), 0);
  PutMsg(LookUp('PRODIAG1'), LookUp('ESCPRINT'));
  DestroyDiagram;
  MakeDiagram;
  RepaintDiagram;
  New(Key,Init(Workspace,0,0,[' ','P',Esc,^M],True));
  Key^.Link(Msg,'PRODIAGHLP?','','');
  REPEAT
    Key^.WaitForValid;
    CASE Key^.LastChar OF
     ' ' : BEGIN
             WSClear;
             Statics^.Draw;
             Dynamics^.Draw;
           END;
     'P' : BEGIN
             IF PrintHeader
             THEN BEGIN
               PrintInfo;
               PrintWorkSpace([WSBG,PaleYellow]);
             END;
             PrintFooter;
           END;
    END;
  UNTIL Key^.LastChar in [Esc, ^M];
  Dispose(Key,Done);
  DestroyDiagram;
  Refresh:=NoRefresh;
END; {GenericUnit.ProcessDiagram}


PROCEDURE GenericUnit.PreLog;
{ - Always use BEFORE PLC communication}
BEGIN
{$IFNDEF NoSerial}
  RaiseBusySign(PLCIO);
{$ENDIF}
END; {PROC GenericUnit.PreLog}

PROCEDURE GenericUnit.ProLog;
{ - Always use AFTER PLC communication}
BEGIN
{$IFNDEF NoSerial}
  DropBusySign;
{$ENDIF}
END; {PROC GenericUnit.ProLog}

PROCEDURE GenericUnit.PLCWrite;
BEGIN
  Abstract;
END; {PROC GenericUnit.PLCWrite}

PROCEDURE GenericUnit.PLCRead;
BEGIN
  Abstract;
END; {PROC GenericUnit.PLCRead}

PROCEDURE GenericUnit.ResumeProcess;
{ - Examine PLC to check for NON-PC controlled changes in kiln control
    This routine is normally used only at startup
}
VAR
  UpDates : LongInt;
BEGIN
  PreLog;

  { - Skip all "missing" samples since last update }
  Updates:=Round(SecondsSince(LastUpdate)/UpdateInterval);
 {$IFNDEF NoSerial}
  IF Updates>0
  THEN Cfg^.PLC^.SkipUpdates(UpDates);
  IncSeconds(LastUpdate,LongInt(UpdateInterval)*Updates);
 {$ELSE}
  StartWatch(LastUpdate);
 {$ENDIF}

  PLCRead;
  RefreshDue:=True;
  ProLog;
END; {PROC GenericUnit.ResumeProcess}

PROCEDURE GenericUnit.StartProcess;
{ - Execute kiln startup sequence}
VAR
  n  : Integer;
  Ok : Boolean;
BEGIN
  IF KilnMode=Stopped
  THEN BEGIN
    KilnMode:=WarmingUp;
    PreLog;
    n:=0;
    REPEAT
      PLCWrite;
      Inc(n);
      Coil(Start)^.Enable;
      Coil(Start)^.Write;
      Coil(Started)^.Read;
      {$IFDEF NoSerial} Coil(Started)^.Enable; {$ENDIF}
      WITH Coil(Started)^
      DO OK:=(Enabled) and isValid;
      IF OK
      THEN BEGIN
        StartWatch(StartTime);
        AddToLog(Cfg^.name^+' started');
      END ELSE AddToLog('Start failed, '+Cfg^.name^);
    UNTIL Ok OR (n>5);
    IF Not Ok THEN KilnMode:=Stopped
    ELSE PLCRead;
    RefreshDue:=True;
    ProLog;
  END;
END; {PROC GenericUnit.StartProcess}

PROCEDURE GenericUnit.UpdateProcess;
{ - Walk through kiln registers/coils and look for comm.requests
    Use as Last call from inheritors}
BEGIN
  PreLog;
  PLCWrite;
  PLCRead;
  IncSeconds(LastUpdate,UpdateInterval);
  RefreshDue:=True;
  ProLog;
END; {PROC GenericUnit.UpdateProcess}

PROCEDURE GenericUnit.StopProcess;
{ - Execute kiln stop sequence}
VAR
  n : Integer;
  ok : Boolean;
BEGIN
  PreLog;
  n:=0;
  PLCWrite;
  REPEAT
    Inc(n);
    Coil(Stop)^.Enable;
    Coil(Stop)^.Write;
    Coil(Started)^.Read;
    WITH Coil(Started)^
    DO OK:=(Disabled) and isValid;
    IF OK
    THEN BEGIN
      AddToLog(Cfg^.name^+' stopped');
      KilnMode:=Stopped;
    END ELSE AddToLog('Stop failed, '+Cfg^.name^);
  UNTIL Ok OR (n>5);
  RefreshDue:=True;
  ProLog;
END; {PROC GenericUnit.StopProcess}

PROCEDURE GenericUnit.Redraw;
{ - Call Refresh proc }
BEGIN
  IF not (ScreenSaveActive or HelpActive)
  THEN BEGIN
    RefreshDue:=False;
    Refresh(@Self);
  END;
END; {PROC GenericUnit.Redraw}

FUNCTION GenericUnit.UpdateDue:Boolean;
BEGIN
  Abstract;
END; {FUNC GenericUnit.UpdateDue}

FUNCTION GenericUnit.Describe:String;
{ - Return a description string }
VAR
  s : String[79];
BEGIN
  s:=PadTrailing(Cfg^.Name^,' ',10)+' '
    +PadTrailing(ModeName[KilnMode]^,' ',15)+' ';
  Describe:=s;
END; {FUNC GenericUnit.Describe}

FUNCTION GenericUnit.TotalTime:Integer;
{ - Return total time usage }
BEGIN
  TotalTime:=Model^.TotalTime;
END; {FUNC GenericUnit.TotalTime}

FUNCTION GenericUnit.Coil(ID:Word):PCoil;
VAR
  C : PCoil;
BEGIN
  C:=Cfg^.PLC^.Coil(ID);
  {$IFNDEF NoDebug}
  IF C=nil THEN BreakPoint;
  {$ENDIF}
  Coil:=C;
END; {FUNC GenericUnit.Coil}

FUNCTION GenericUnit.Register(ID:Word):PRegister;
VAR
  R:PRegister;
BEGIN
  R:=Cfg^.PLC^.Register(ID);
  {$IFNDEF NoDebug}
  IF R=nil THEN BreakPoint;
  {$ENDIF}
   Register:=R;
END; {FUNC GenericUnit.Register}


{------------------------------------------------------------- Unit init's ---
}

PROCEDURE RegisterKilnTypes;
BEGIN
  RegisterType(GenericUnit_OSR);
  RegisterType(ConnectionList_OSR);
  RegisterType(LogList_OSR);
  RegisterIntSamplers;
  RegisterBoolSamplers;
END; {PROC RegisterKilnTypes}

VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}
CONST
  P4UnitMsg = ' P4U_Gen ';

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

