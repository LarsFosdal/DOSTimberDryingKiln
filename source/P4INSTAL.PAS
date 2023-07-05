{$I CODEDEFS.PAS}
{$X+}
PROGRAM AGInstall;

USES
  LFSystem, Crt, LFcrt, Dos, LFDos, P4Config, PLCDrive,
  P4Setup, P4Remote, AGTools, LFScrSav;

VAR
  Kammer,Kanaler,Modeller,i,Soner : Integer;
  CfgFileName,dir,name,ext : String;
  Config      : pInstallInfo;
  s : String;
BEGIN
  Writeln;
  Write('Config-filnavn : ');
  IF ParamCount=1
  THEN BEGIN
    CfgFileName:=ParamStr(1);
    Writeln(CfgFileName);
    Delay(500);
  END
  ELSE Readln(CfgFileName);
  Writeln('--------------------------------------------------');

  FSplit(CfgFileName, Dir, name, ext);
  CfgFileName:=Name;
  IF Ext=''
  THEN Ext:='.CFG';
  CfgFileName:=CfgFileName+Ext;

  FindRemoteSystems('P4RUN');

  IF FSearch(CfgFileName,BeforeLast('\',Path))=''
  THEN BEGIN
    Write('Kundens navn   : '); Readln(s);
    Write('Antall Kammer  : '); Readln(Kammer);
    Write('Antall Kanaler : '); Readln(Kanaler);
    IF Kammer>0
    THEN Modeller:=1
    ELSE Modeller:=0;
    New(Config,Init(Kammer+Kanaler+Modeller));
    PSNew(Config^.Customer,s);
    PSNew(Config^.DateBy,Date+' '+Time);
    FOR i:=1 TO Kammer
    DO Config^.Kilns.Add(New(PKilnCfg,Init(i,'Kammer '+IntStr(i,0))));
    FOR i:=1 TO Kanaler
    DO BEGIN
      Write('Soner, Kanal ',i,' : '); Readln(Soner);
      Config^.Kilns.Add(New(PTunnelCfg,Init(Kammer+i,'Kanal '+IntStr(i,0),Soner)));
    END;
    IF Modeller <> 0
    THEN Config^.Kilns.Add(New(PMdlCfg, Init(Kammer+Kanaler+Modeller,'Kammermodell')));
  END
  ELSE LoadCfg(Path+CfgFileName, Config, True);
  Config^.SetRemote(False);
  StartGfxEngine('P4RUN.MSG','CFGHLP?');
  HeaderString:=Config^.Customer;
  SetupMenu(CfgFileName, Config, True);
  Dispose(Config, Done);
  StopGfxEngine;
END.
