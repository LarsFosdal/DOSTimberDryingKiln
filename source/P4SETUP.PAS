{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT P4Setup;

INTERFACE
USES
  P4Config,PLCDrive;

PROCEDURE SetupMenu(CfgFileName:String; VAR Config:pInstallInfo; Extended:Boolean);
PROCEDURE TimeSet;
PROCEDURE ColorSet;
PROCEDURE RefreshConfig(Config:pInstallInfo);

IMPLEMENTATION
USES
  Dos,Crt,Graph,Objects,
  AGTools,LFsystem,LFTable,
  LFExtMSg,LFGraph,LFDos,LFWindow,LFGfxWin,LFString,ObjInput;

PROCEDURE RefreshConfig(Config:pInstallInfo);
BEGIN
  IF Config^.BlankInterval>0
  THEN ScreenSaveTimer:=60*Config^.BlankInterval
  ELSE ScreenSaveEnabled:=False;
END; {PROC RefreshConfig}

PROCEDURE ChangeEntity(Config:pInstallInfo; Ent:PPLCEntity);
VAR
  Win  : PGfxWin;
  AuxF : PFieldList;
  f    : PGenEdit;
  dummy : Word;
BEGIN
  New(Win,InitTxt(35,25,43,8,False));
  New(AuxF,Init);

  f:=New(PStrPInput,Init(Win^.WorkSpace,20,1,20,Ent^.Name,[#32..#127]+NorskSet,False));
  f^.Link(Msg,'ENTNAME?','ENTNAME','');
  AuxF^.Add(Ent^.Name,f);

  f:=New(PStrInput,Init(Win^.WorkSpace,20,2,8, Ent^.Address, [#32..#127], False));
  f^.Link(Msg,'ENTADR?','ENTADR','');
  AuxF^.Add(Ent^.Address,f);

  f:=new(PBooleanInput,Init(Win^.WorkSpace,20,3,4,Ent^.Installed,Msg^.FindText('YESNOSLCT')));
  f^.Link(Msg,'ENTAVAIL?','ENTAVAIL','');
  AuxF^.Add(Ent^.Installed,f);

  f:=new(PBooleanInput,Init(Win^.WorkSpace,20,4,4,Ent^.DoLog,Msg^.FindText('YESNOSLCT')));
  f^.Link(Msg,'ENTLOGGED?','ENTLOGGED','');
  AuxF^.Add(Ent^.DoLog,f);

  f:=new(PChoiceInput,Init(Win^.WorkSpace,20,5,10,Ent^.Mode,Msg^.FindText('ENTMODES')));
  f^.Link(Msg,'ENTMODE?','ENTMODE','');
  AuxF^.Add(Ent^.Mode,f);

  f:=new(PIntInput,Init(Win^.WorkSpace,20,6,2,1,Ent^.Priority,9));
  f^.Link(Msg,'ENTPRIO?','ENTPRIO','');
  AuxF^.Add(Ent^.Priority,f);



  Win^.Open;
  REPEAT
    AuxF^.Display;
    AuxF^.Edit;
    IF AuxF^.LastChar<>ESC
    THEN BEGIN
      PSDispose(Ent^.Name);
      AuxF^.Fetch(Ent^.Name);
      AuxF^.Fetch(Ent^.Address);
      AuxF^.Fetch(Ent^.Installed);
      AuxF^.Fetch(Ent^.DoLog);
      AuxF^.Fetch(Ent^.Mode);
      AuxF^.Fetch(Ent^.Priority);
    END;
  UNTIL PLCValidateAddress(Config^.Controller,Ent^.Address, dummy) or (AuxF^.LastChar=Esc);
  Win^.Close;
  Dispose(AuxF,Done);
  Dispose(Win,Done);
END; {PROC ChangeEntity}

PROCEDURE ChangeKilnParams(Config:pInstallInfo; Kln:PGenericCfg);
VAR
  Win  : PGfxWin;
  AuxF : PFieldList;
BEGIN
  New(Win,InitTxt(35,25,43,10,False));
  New(AuxF,Init);
  Kln^.CreateFields(Win^.WorkSpace,AuxF);
  AddToLog('Fields:'+IntStr(Auxf^.Count,0));
  Win^.Open;
  AuxF^.Display;
  AuxF^.Edit;
  Win^.Close;
  IF AuxF^.LastChar<>ESC
  THEN BEGIN
    Kln^.GetFields(AuxF)
  END;
  Dispose(AuxF,Done);
  Dispose(Win,Done);
END; {PROC ChangeKilnParams}

PROCEDURE SelectEntity(Config:pInstallInfo; UnitNo:Integer);
VAR
  Mnu  : PMenuInput;
  Win  : PGfxWin;
  List       : PMenuTxt;
  Hook       : PCollection;
  Kln        : PGenericCfg;
  Hooked     : Word;
  Quit       : Boolean;
  FUNCTION MatchHook(H:PHookEntry):Boolean; FAR;
  BEGIN
    MatchHook:=H^.Hook=Hooked;
  END;
  FUNCTION MatchID(P:PPLCEntity):Boolean; FAR;
  BEGIN
    MatchID:=P^.ID=Hooked;
  END;
BEGIN
  New(Win,InitTxt(40,19,30,5,False));
  Kln:=PGenericCfg(Config^.Kilns.At(UnitNo-1));
  Quit:=False;
  Hooked:=0;
  REPEAT
    New(List,Init('',''));
    New(Hook,Init(kln^.PLC^.Count,5));
    List^.AddLine(Lookup('PARAMTITLE')+Kln^.Name^);
    Hook^.Insert(New(PHookEntry,Init(0)));
    Kln^.PLC^.MakeList(List,Hook);
    New(Mnu,Init(Win,15,List));
    Mnu^.Current:=Hook^.IndexOf(Hook^.FirstThat(@MatchHook))+1;
    Mnu^.Select;
    CASE Mnu^.Choice OF
      0 : Quit:=True;
      ELSE BEGIN
        Hooked:=PHookEntry(Hook^.At(Mnu^.Choice-1))^.Hook;
        IF Hooked=0
        THEN ChangeKilnParams(Config, Kln)
        ELSE ChangeEntity(Config, Kln^.PLC^.FirstThat(@MatchID));
      END;
    END;
    Dispose(Hook,Done);
    Dispose(List,Done);
    Dispose(Mnu,Done);
  UNTIL Quit;
END; {PROC SelectEntity}

PROCEDURE SelectKiln(Config:pInstallInfo);
VAR
  Mnu      : PMenuInput;
  Kilns    : PMenuTxt;
  Win      : PGfxWin;
  Quit     : Boolean;
BEGIN
  New(Win,InitTxt(60,15,5,5,False));
  Quit:=False;
  REPEAT
    BuildKilnList(Config, Kilns);
    New(Mnu,Init(Win,10,Kilns));
    Mnu^.Select;
    CASE Mnu^.Choice OF
      0 : Quit:=True;
     ELSE SelectEntity(Config, Mnu^.Choice);
    END;
    Dispose(Kilns,Done);
    Dispose(Mnu,Done);
  UNTIL Quit;
  Dispose(Win,Done);
END;

PROCEDURE PrintSetup(Config:pInstallInfo);
VAR
  t,i      : Integer;
  Key     : PKeystroke;
  Rpt     : PReport;
BEGIN
  New(Key,Init(WorkSpace,1,1,[Esc,'P','F',^M,^E,^X,^R,^C],True));
  New(Rpt,Init);
  Config^.Print(Rpt);
  t:=1;
  REPEAT
    i:=0;
    WSClear;
    WSColor(WorkSpace^.Pane.Low);
    WHILE (i<24) and not ((t+i)>Rpt^.Count)
    DO BEGIN
      WSWrtln(Rpt^.Line(t+i-1));
      Inc(i);
    END;
    Key^.WaitForValid;
    CASE Key^.LastChar OF
      ^E : Dec(t);
      ^X : Inc(t);
      ^C,^M : Inc(t,24);
      ^R : Dec(t,24);
      'P': BEGIN
             IF PrintHeader
             THEN Rpt^.Output('PRN');
             PrintFooter;
           END;
      'F': BEGIN
             Rpt^.Output(Path+LFSystem.SystemName+'.PRN');
           END;
    END;
    IF t<1 THEN t:=1
    ELSE IF t>Rpt^.Count THEN t:=Rpt^.Count;
  UNTIL (Key^.LastChar=Esc);
  Dispose(Rpt,Done);
  Dispose(Key,Done);
END;


PROCEDURE SetupMenu(CfgFileName:String; VAR Config:pInstallInfo; Extended:Boolean);
CONST
  ParChar : String[3] = 'NEO';
VAR
  AuxF     : PFieldList;
  f        : PGenEdit;
  PLCPar,
  ModemPar : Integer;
  Mnu      : PMenuInput;
  Win      : PGfxWin;
  Quit     : Boolean;
BEGIN
  DeskTopTitle(LookUp('INSTLIST'));
  New(Win,InitTxt(55,9,30,5,False));
  New(Mnu,Init(Win,4,Msg^.FindMenu('INSTALMNU')));

  New(AuxF,Init);

  f:=New(PIntDisplay,Init(WorkSpace,5,2,2,Config^.Units));
  f^.Link(Msg,'','','CFGUNITS');
  AuxF^.Add(Config^.Units,f);

  f:=new(PChoiceInput,Init(WorkSpace,22,4,10,Config^.Language,Msg^.FindText('LANGSLCT')));
  f^.Link(Msg,'LANGUAGE?','LANGUAGE','');
  AuxF^.Add(Config^.Language,f);

  f:=new(PIntInput,Init(WorkSpace,22,5,4,0,Config^.BlankInterval,120));
  f^.Link(Msg,'BLANKINT?','BLANKINT','MINUTES');
  AuxF^.Add(Config^.BlankInterval,f);

  f:=new(PIntInput,Init(WorkSpace,22,6,4,1,Config^.BackupInterval,120));
  f^.Link(Msg,'BAKUPINT?','BAKUPINT','MINUTES');
  AuxF^.Add(Config^.BackupInterval,f);

  f:=new(PChoiceInput,Init(WorkSpace,22,7,20,Config^.PrinterType,Msg^.FindText('PRNTSLCT')));
  f^.Link(Msg,'PRNTTYPE?','PRNTTYPE','');
  AuxF^.Add(Config^.PrinterType,f);

  f:=new(PChoiceInput,Init(WorkSpace,22,9,20,Config^.Controller,Msg^.FindText('PLCSLCT')));
  f^.Link(Msg,'PLCSLCT?','PLCTYPE','');
  AuxF^.Add(Config^.Controller,f);

  f:=new(PBooleanInput,Init(WorkSpace,22,10,4,Config^.PLCLink.Installed,Msg^.FindText('YESNOSLCT')));
  f^.Link(Msg,'SERINS?','SERINS','');
  AuxF^.Add(Config^.PLCLink.Installed,f);

  f:=new(PIntInput,Init(WorkSpace,22,11,4,1,Config^.PLCLink.Port,2));
  f^.Link(Msg,'SERINS?','SER#','');
  AuxF^.Add(Config^.PLCLink.Port,f);

  f:=new(PIntInput,Init(WorkSpace,22,12,4,2400,Config^.PLCLink.bps,9600));
  f^.Link(Msg,'SERINS?','SERBPS','');
  AuxF^.Add(Config^.PLCLink.Bps,f);

  f:=new(PIntInput,Init(WorkSpace,22,13,4,1,Config^.PLCLink.Stopbits,2));
  f^.Link(Msg,'SERINS?','SERSBITS','');
  AuxF^.Add(Config^.PLCLink.StopBits,f);

  PLCPar:=Pos(Config^.PLCLink.Parity,ParChar);
  f:=new(PChoiceInput,Init(WorkSpace,22,14,5,PLCPar, Msg^.FindText('SerParSlct')));
  f^.Link(Msg,'SERINS?','SERPARITY','');
  AuxF^.Add(PLCPar,f);

  f:=new(PBooleanInput,Init(WorkSpace,60,10,4,Config^.ModemLink.Installed,Msg^.FindText('YESNOSLCT')));
  f^.Link(Msg,'MODEMLNK?','MODEMLNK','');
  AuxF^.Add(Config^.ModemLink.Installed,f);

  f:=new(PIntInput,Init(WorkSpace,60,11,4,1,Config^.ModemLink.Port,2));
  f^.Link(Msg,'SERINS?','SER#','');
  AuxF^.Add(Config^.ModemLink.Port,f);

  f:=new(PIntInput,Init(WorkSpace,60,12,4,2400,Config^.ModemLink.bps,9600));
  f^.Link(Msg,'SERINS?','SERBPS','');
  AuxF^.Add(Config^.ModemLink.Bps,f);

  f:=new(PIntInput,Init(WorkSpace,60,13,4,1,Config^.ModemLink.Stopbits,2));
  f^.Link(Msg,'SERINS?','SERSBITS','');
  AuxF^.Add(Config^.ModemLink.StopBits,f);

  ModemPar:=Pos(Config^.ModemLink.Parity,ParChar);
  f:=new(PChoiceInput,Init(WorkSpace,60,14,5,ModemPar,
                           Msg^.FindText('SerParSlct')));
  f^.Link(Msg,'SERINS?','SERPARITY','');
  AuxF^.Add(ModemPar,f);

  f:=new(PBooleanInput,Init(WorkSpace,22,16,4,Config^.NetWork,Msg^.FindText('YESNOSLCT')));
  f^.Link(Msg,'LANAVAIL?','LANAVAIL','');
  AuxF^.Add(Config^.NetWork,f);

  f:=new(PBooleanInput,Init(WorkSpace,22,17,4,Config^.RemoteCtrl,Msg^.FindText('YESNOSLCT')));
  f^.Link(Msg,'LANREMOTE?','LANREMOTE','');
  AuxF^.Add(Config^.RemoteCtrl,f);

  f:=new(PStrPInput,Init(WorkSpace,22,18,16,Config^.NodeAdr,[#32..#127],False));
  f^.Link(Msg,'LANADDR?','LANADDR','');
  AuxF^.Add(Config^.NodeAdr,f);

  Quit:=False;
  Mnu^.Current:=4;
  REPEAT
    IF Mnu^.Choice<>1
    THEN BEGIN
      WSClear;
      AuxF^.Display;
    END;
    PutMsg(LookUp('SETUPMNU'),LookUp('ESC=LOGIN'));
    Mnu^.Select;
    CASE Mnu^.Choice OF
      0,4 : BEGIN
              Quit:=True;
              RaiseBusySign(DiskIO);
              StoreCfg(CfgFileName, Config);
              RefreshConfig(Config);
              DropBusySign;
            END;
      1   : BEGIN
              PutMsg(LookUp('SETUP1'),LookUp('ESC=EXIT'));
              AuxF^.Edit;
              IF AuxF^.LastChar<>Esc
              THEN BEGIN
                AuxF^.Fetch(Config^.Units);
                AuxF^.Fetch(Config^.Language);
                AuxF^.Fetch(Config^.BlankInterval);
                AuxF^.Fetch(Config^.BackupInterval);
                AuxF^.Fetch(Config^.PrinterType);
                AuxF^.Fetch(Config^.Controller);

                AuxF^.Fetch(Config^.PLCLink.Installed);
                AuxF^.Fetch(Config^.PLCLink.Port);
                AuxF^.Fetch(Config^.PLCLink.Bps);
                AuxF^.Fetch(Config^.PLCLink.StopBits);
                AuxF^.Fetch(PLCPar);  Config^.PLCLink.Parity:=ParChar[PLCPar];

                AuxF^.Fetch(Config^.ModemLink.Installed);
                AuxF^.Fetch(Config^.ModemLink.Port);
                AuxF^.Fetch(Config^.ModemLink.Bps);
                AuxF^.Fetch(Config^.ModemLink.StopBits);
                AuxF^.Fetch(ModemPar);  Config^.ModemLink.Parity:=ParChar[ModemPar];

                AuxF^.Fetch(Config^.NetWork);
                AuxF^.Fetch(Config^.RemoteCtrl);

                AuxF^.Fetch(Config^.NodeAdr);
              END;
            END;
      2   : SelectKiln(Config);
      3   : PrintSetup(Config);
    END;
  UNTIL Quit;
  Dispose(AuxF,Done);
  Dispose(Mnu,Done);
  Dispose(Win,Done);
END; {PROC Setup}

PROCEDURE ColorSet;
CONST
  n : Byte = Brown;
  PROCEDURE Values(no:Integer);
  VAR
    i,j : Integer;
  BEGIN
    i:=no MOD 8; j:=no DIV 8;
    IF j=0 THEN j:=22 ELSE j:=42;
    WSWrtXY(j,i+3,' r:'+HexB(agpal[no].r)
                 +' g:'+HexB(agpal[no].g)
                 +' b:'+HexB(agpal[no].b));
  END;
  PROCEDURE Border(no,co:Integer);
  VAR
    j,i : Integer;
  BEGIN
    i:=no MOD 8; j:=no DIV 8;
    SetColor(co);
    Rectangle(304+j*16,96+i*16,317+j*16,109+i*16);
  END;
VAR
  i,j : Integer;
  key : KeyStroke;
BEGIN
  DeskTopTitle('Fargeinnstilling');
  WSClear;
  FOR j:=0 TO 1       {/////////////DEBUG}
  DO FOR i:=0 TO 7
   DO BEGIN
    SetFillStyle(SolidFill,j*8+i);
    Bar(304+j*16,96+i*16,317+j*16,109+i*16);
    Border(j*8+i,Black);
    Values(j*8+i);
  END;
  Border(n,White);
  Key.Init(Workspace,0,0,[^E,^X,^S,^D,'r','R','g','G','b','B',Esc],False);
  REPEAT
    Key.WaitForValid;
    j:=n;
    CASE Key.LastChar OF
      'r' : IF agpal[n].r>0 THEN Dec(agpal[n].r);
      'R' : IF agpal[n].r<$3F THEN Inc(agpal[n].r);
      'g' : IF agpal[n].g>0 THEN Dec(agpal[n].g);
      'G' : IF agpal[n].g<$3F THEN Inc(agpal[n].g);
      'b' : IF agpal[n].b>0 THEN Dec(agpal[n].b);
      'B' : IF agpal[n].b<$3F THEN Inc(agpal[n].b);
      ^S,^D : n:=(n+8) MOD 16;
      ^E  : n:=(n DIV 8)*8 + (n+7) MOD 8;
      ^X  : n:=(n DIV 8)*8 + (n+9) MOD 8;
    END;
    IF Not (Key.Lastchar in [^S,^X,^D,^E])
    THEN BEGIN
      MixPal(agPal);
      Values(n);
    END
    ELSE BEGIN
      Border(j,Black);
      Border(n,White);
    END;
  UNTIL Key.LastChar in [Esc,^J];
  Key.Done;
END;


PROCEDURE TimeSet;
{ - Adjust time and date }
VAR
  AuxF     : PFieldList;
  f        : PGenEdit;
  hour,min,sec : Word;
  year,mon,day : Word;
  dum      : Word;
  Win      : PGfxWin;
  Quit     : Boolean;
BEGIN
  New(Win,InitTxt(25,15,30,4,True));
  Win^.Title(LookUp('TimDatWin'),Lookup('ESC=EXIT'));
  New(AuxF,Init);

  ExamineTime(hour,min,sec,dum);
  ExamineDate(year,mon,day,dum);

  f:=new(PIntInput,Init(Win^.WorkSpace,6,2,2,0,hour,23));
  f^.Link(Msg,'SETHOUR?','','');
  AuxF^.Add(hour,f);

  f:=new(PIntInput,Init(Win^.WorkSpace,9,2,2,0,Min,59));
  f^.Link(Msg,'SETMIN?','','');
  AuxF^.Add(min,f);

  f:=new(PIntInput,Init(Win^.WorkSpace,13,2,2,1,Day,31));
  f^.Link(Msg,'SETDAY?','','');
  AuxF^.Add(Day,f);

  f:=new(PIntInput,Init(Win^.WorkSpace,16,2,2,1,Mon,12));
  f^.Link(Msg,'SETMNTH?','','');
  AuxF^.Add(Mon,f);

  f:=new(PIntInput,Init(Win^.WorkSpace,19,2,4,1988,Year,2049));
  f^.Link(Msg,'SETYEAR?','','');
  AuxF^.Add(Year,f);

  Win^.Open;
  WITH Win^.WorkSpace^
  DO BEGIN
    WrtTxt(6,1,Pane.Low,LookUp('TIMEINFO'));
    WrtTxt(6,2,Pane.Low,'  .      /  -');
  END;
  AuxF^.Display;
  AuxF^.Edit;
  IF AuxF^.LastChar<>Esc
  THEN BEGIN
    AuxF^.Fetch(hour);
    AuxF^.Fetch(min);
    AuxF^.Fetch(Year);
    AuxF^.Fetch(Mon);
    AuxF^.Fetch(day);
    SetTime(hour,min,sec,0);
    SetDate(Year,Mon,Day);
  END;
  Dispose(AuxF,Done);
  Dispose(Win,Done);
END; {PROC TimeSet}



VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}
CONST
  P4SetupMsg = ' P4Setup ';

PROCEDURE P4SetupExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitHandler;
  Units.Leave(P4SetupMsg,MemAvail);
END; {PROC P4SetupExitHandler}

BEGIN {Init part of P4Setup}
  PrevExitHandler:=ExitProc;
  ExitProc:=@P4SetupExitHandler;
  Units.Enter(P4SetupMsg,MemAvail,CSeg);
END.

