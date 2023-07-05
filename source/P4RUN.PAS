{$I CODEDEFS.PAS} {Include code generation definitions}
PROGRAM P4Run;

{$D P4RUN IV v.1.00  Lars Fosdal/ABB Alfsen og Gunderson a/s 1993
------------------------------------------------------------------------------
  Source : Borland Pascal v.7.0

  Short Description :
    Fourth generation process/machine control program for
    the Alfsen & Gunderson Timber drying channels/kilns.
------------------------------------------------------------------------------
}

USES
  Objects, Graph, Dos, LFCrt,
  LFSystem, LFGraph, LFGfxWin, ObjInput, LFDos, LFExtMsg, Icons, LFString,
  PLCDrive, AGTools, P4Config, P4Setup, P4U_Gen,P4Kiln, P4Remote, LFScrSav;

{--------------------------------------------- System Definition Constants ---
}
{$IFDEF NoSerial}
  {$DEFINE Demo}
{$ENDIF}

CONST
  progtitle  = 'AGPRO IV ';
  tCopyright = 'Copyright (c) 1986, 1993  AG/L.Fosdal';
  gCopyright = 'Copyright '#175' 1986, 1993  AG/L.Fosdal';
  version   : String[50] = 'v.1.01 '{$IFDEF Demo}+'DEMO '{$ENDIF};
  VerDate   : String[20] = '930413 14.30';

CONST
  MsgFileName : String[12] = 'P4RUN.MSG';
VAR
  PrimaryCfg   : pInstallInfo;

{--------------------------------------------------------------- LoginMenu ---
}

FUNCTION RemoteMenu:Boolean;
VAR
  mw : pGfxWin;
  mn : pMenuInput;
  mt : pMenuTxt;
  Rem : Boolean;
  cc   : Integer;
  Remote : pUnitList;
  SecCfg : pInstallInfo;
  Dir,
  Name   : String;
BEGIN
  Rem:=False;
  New(mw, InitTxt(57,18,23,8,True));
  New(mt, Init('',LookUp('CONTROL')));
  mt^.AddLine(LookUp('OOPS'));
  FOR cc:=0 TO RemoteSysNames.Count-1
  DO mt^.AddLine(pSysInfo(RemoteSysNames.At(cc))^.RealName);
  New(mn, Init(mw,2+cc, mt));
  Mn^.Current:=1;
  Mn^.Select;
  cc:=Mn^.Choice;
  CASE cc OF
    0,1 : ;
    ELSE BEGIN
      Name:=pSysInfo(RemoteSysNames.At(cc-2))^.FileName;
      Dir:=pSysInfo(RemoteSysNames.At(cc-2))^.ServerDir;
      IF P4Config.LoadCfg(Dir+Name+'.CFG', SecCfg, False)
      THEN BEGIN
        SecCfg^.SetRemote(True);
        IF LoadBackup(Dir+Name+'.BKU', SecCfg, Remote, False)
        THEN BEGIN
          Remote^.Link(SecCfg, Name);
          ViewMenu(Remote);
          Rem:=True;
          Dispose(Remote, Done);
        END ELSE Blip;
        Dispose(SecCfg, Done);
      END ELSE Blip;
    END;
  END;
  Dispose(mn,Done);
  Dispose(mt, Done);
  Dispose(mw,Done);
  RemoteMenu:=Rem;
END; {PROC RemoteMenu}

PROCEDURE LoginMenu;
  PROCEDURE ReInit_Time(K:PGenericUnit); FAR;
  VAR
    dtk : LongInt;
  BEGIN
    dtk:=SecondsSince(k^.LastUpdate);
    StartWatch(K^.LastUpdate);
    DecSeconds(K^.LastUpdate,dtk);
  END;
VAR
  dtb : LongInt;
  mw : pGfxWin;
  mn : pMenuInput;
  Quit : Boolean;
  logo : Pointer;
  cc   : Integer;
  Noref : Set of Byte;
BEGIN
  Quit:=False;
  New(mw,InitTxt(60,15,15,4,False));
  New(mn,Init(mw,4,Msg^.FindMenu('LOGINMNU')));
  IF RemoteSys
  THEN BEGIN
    Mn^.Mnu^.Txts.AtInsert(1, New(TabEntryPtr, Init(LookUp('CONTROL'))));
    Inc(Mn^.vLines);
    mw^.TxtAdjSize(Mn^.vColumns+2,Mn^.vLines);
  END;
  IF Monitor
  THEN BEGIN
    mn^.mnu^.LineDisable(0);
    mn^.mnu^.LineDisable(3);
  END;
  Mn^.Current:=1; cc:=1;
  REPEAT
    DeskTopTitle(LookUp('PROGTITLE'));
    PutMsg(ProgTitle+Version+VerDate,gCopyright);
    IF not (cc in [0,3,5])
    THEN BEGIN
      WSClear;
      InvFrameRelief(16,TitleH+16,450-32,WSH-32,WSLB,DarkGray,Blue);
      ECPutBlock(80,TitleH+32,AGlogo1,NormalPut);
      ECPutBlock(30,375,AlfOgGunAS,NormalPut);
      logo:=@ABB_Logo;
      PutBlock(500, 370, logo^, NormalPut);
    END;
    Kilns^.Redraw;
    mn^.Select;
    IF not RemoteSys and (mn^.Choice in [2..4])
    THEN cc:=Mn^.Choice +1
    ELSE cc:=Mn^.Choice;
    CASE cc OF
      1   : ViewMenu(Kilns);
      2   : IF RemoteSys
            THEN IF not RemoteMenu THEN cc:=0;
      3   : BEGIN
              dtb:=SecondsSince(LastBackup);
              TimeSet;
              Kilns^.ForEach(@ReInit_Time);
              StartWatch(LastBackup);
              DecSeconds(LastBackup,dtb);
              StartWatch(TimeSinceKeyPressed);
            END;
      4   : BEGIN
              SetupMenu(SystemName+'.CFG', PrimaryCfg, False);
              Kilns^.Relink(PrimaryCfg);
              P4Kiln.BackupInterval:=PrimaryCfg^.BackupInterval;
            END;
      0,5 : Quit:=ConfirmedExit;
    END;
  UNTIL Quit;
  Dispose(mn,Done);
  Dispose(mw,Done);
END; {PROC LoginMenu}

{---------------------------------------------------------- Startup checks ---
}
FUNCTION PreStartCheck:Boolean;
  FUNCTION FoundFile(Name:String):Boolean;
  BEGIN
    FoundFile:=FSearch(Name,BeforeLast('\',Path))<>'';
  END;
  FUNCTION FileOK(Name,Description:String):Boolean;
  VAR
    Found : Boolean;
  BEGIN
    Write(Description,' ');
    Found:=FoundFile(Name);
    IF Not Found
    THEN Writeln(Path+Name,' not found !')
    ELSE Writeln('OK');
    FileOK:=Found;
  END;
VAR
  Step : Integer;
  OK   : Boolean;
BEGIN
  Writeln(ProgTitle+Version+VerDate);
  Writeln(tCopyright);
  RegisterObjects;
{$IFNDEF NoSerial} InstallCADIntercept; {$ENDIF}
  MsgFileName:=ExeName+'.MSG';
  Step:=0;
  OK:=True;
  REPEAT
    Inc(Step);
    CASE Step OF
      1 : OK:=FileOK('EGAVGA.BGI','BGI file');
      2 : OK:=FileOK('AGSTD.FNT','BitmapFont file');
      3 : BEGIN
            OK:=FileOK(MsgFileName,'Message file');
            IF Monitor
            THEN BEGIN
              New(PrimaryCfg, Init(0));
              New(Kilns, Init(PrimaryCfg, 'Monitor'));
              Step:=6;
            END;
          END;
      4 : BEGIN
            OK:=P4Config.LoadCfg(Path+SystemName+'.CFG', PrimaryCfg, True);
            IF OK
            THEN PrimaryCfg^.SetRemote(False);
          END;
      5 : OK:=P4Kiln.LoadBackup(Path+SystemName+'.BKU', PrimaryCfg, Kilns, True);
      6 : BEGIN
            ConnectPLC(PrimaryCfg^.Controller,
                       PrimaryCfg^.PLCLink.Port,
                       PrimaryCfg^.PLCLink.Bps,
                       PrimaryCfg^.PLCLink.Parity,
                       PrimaryCfg^.PLCLink.StopBits);
            Write('PLC ');
            OK:=PLCResponding;
            IF OK
            THEN Writeln('response OK')
            ELSE BEGIN
              Writeln('isn''t responding !');
              BackupLoaded:=False;
            END;
          END;
      7 : BEGIN
            Write('Remote systems - ');
            IF FSearch(ExeName+'.INI', Path)=''
            THEN BEGIN
              Writeln('None');
              OK:=True;
              RemoteSys:=False;
            END
            ELSE BEGIN
              OK:=FindRemoteSystems(ExeName);
              RemoteSys:=OK and (RemoteSysNames.Count>0);
              IF OK
              THEN Writeln('OK')
              ELSE Writeln('incorrect !');
            END;
          END;
    END;
  {$IFNDEF NoDebug}
    SysHaltOnError:=Step>3;
  {$ENDIF}
  UNTIL Not OK or (Step>=10);
  PreStartCheck:=OK;
END; {FUNC PreStartCheck}

{------------------------------------------------------------ Main Program ---
}

BEGIN { - AGPRO III Main program }
  IF PreStartCheck
  THEN BEGIN
    StartGfxEngine(MsgFileName,'MAINHLP?');
    ExitMsg:=PLookUp('EXITMSG');
    P4Setup.RefreshConfig(PrimaryCfg);
    P4Model.SecondaryInit;
    P4U_Gen.SecondaryInit;
    P4Kiln.SecondaryInit(PrimaryCfg);
    IF not Monitor
    THEN HeaderString:=PrimaryCfg^.Customer
    ELSE HeaderString:=NewStr('Monitor');
    LoginMenu;
    IF not Monitor
    THEN P4Kiln.StoreBackup;
    StopGfxEngine;
  END;
END.
