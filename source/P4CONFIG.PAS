{$I CODEDEFS.PAS} {Include code generation definitions}

UNIT P4Config; {Config.objects for Pro4}

INTERFACE
USES
  Objects,LFsystem,LFString,LFExtMsg,LFWindow,ObjInput,PLCDrive;

TYPE
  VersionRec = RECORD
    CASE Boolean OF
      False : ( Signature : ARRAY [1..3] OF Char;
                Version   : Byte );
      True  : ( Units : Integer;
                Language : Word );
  END;

CONST
  {These constants must be updated when adding items to the InstallInfo object}
  InstallInfoVersion = 1;
  ConfigVersion      = 3;

CONST
  VersionID : VersionRec = (Signature:'VER'; Version:0);

CONST{ - Coil Reference ID's }
       Start            =  1;  {Set True to Start Kiln}
       Stop             =  2;  {Set True to Stop Kiln}
       StartedManually  =  3;  {Read True if Kiln Panel-started}
       Started          =  4;  {Read True if Start Acknowledged}
       DryingPhaseFlag  =  5;  {Read True if kiln in drying phase}
CONST  CondPhaseFlag    =  6;  {Write True if kiln in conditioning phase}
       Basing           =  7;  {Read True if kiln is basing}
       MainFanDir       =  8;  {Read True if fans are reversed}
       MainFanRun       =  9;  {Read True if fan is running}
       MainFanFault     = 10;  {Read True if fan has fault}
       VentFan1Run      = 11;  {Read True if vent.fan is running}
       VentFan1Fault    = 12;  {Read True if vent.fan has fault}
CONST  VentFan2Run      = 13;  {Read True if vent.fan is running}
       VentFan2Fault    = 14;  {Read True if vent.fan has fault}
CONST  Pump1Run         = 15;  {Read True if water pump is running}
       Pump1Fault       = 16;  {Read True if water pump has fault}
CONST  Pump2Run         = 17;  {Read True if water pump is running}
       Pump2Fault       = 18;  {Read True if water pump has fault}
CONST  MotorFault       = 19;  {Read True if thermal or electrical error}
       ProcessFault     = 20;  {Read True if regulation fails}
       MF1Run           = 21;  {---}
       MF2Run           = 22;    {\}
       MF3Run           = 23;      {\}
       MF4Run           = 24;        {\}
       MF5Run           = 25;  {Read True if main fan is running}
       MF6Run           = 26;        {/}
       MF7Run           = 27;      {/}
       MF8Run           = 28;    {/}
       MF9Run           = 29;  {---}
       SkipRead         = 30;  {Read True if invalid temperatures}
       MF1Fault         = 31;  {---}
       MF2Fault         = 32;    {\}
       MF3Fault         = 33;      {\}
       MF4Fault         = 34;        {\}
       MF5Fault         = 35;  {Read True if thermal or electrical error}
       MF6Fault         = 36;        {/}
       MF7Fault         = 37;      {/}
       MF8Fault         = 38;    {/}
       MF9Fault         = 39;  {---}

CONST{ - Register Reference ID's }
       tvSet            =  1;  {Set tv SetPoint in 1/10 øC}
       tvRead           =  2;  {Read adjusted tv Setpoint in 1/10 øC}
       ttSet            =  3;  {Set tv SetPoint in 1/10 øC}
       ttRead           =  4;  {Read adjusted tv Setpoint in 1/10 øC}
       TempDiffCond     =  5;  {Set Temp.diff, cond. in 1/10 øC}
       DryingTime       =  6;  {Set drying time in hours}
       CondTime         =  7;  {Set conditioning time in hours}
       tt1              =  8;  {Read tt1 temp. in 1/10 øC}
       tt2              =  9;  {Read tt2 temp. in 1/10 øC}
       MainFanEff       = 10;  {Read Main Fan effect in % (0-100)}
       Damper1Pos       = 11;  {Read damper % open (0-100)}
       Damper2Pos       = 12;  {Read damper % open (0-100)}
       WaterTmpIn       = 13;  {Read water-In temp. in 1/10 øC}
       WaterTmpOut      = 14;  {Read water-Out temp. in 1/10 øC}
       tv1              = 15;  {Read tv1 temp. in 1/10 øC}
       tv2              = 16;  {Read tv2 temp. in 1/10 øC}
       tt3              = 17;  {Read tt3 temp. in 1/10 øC}
       tt4              = 18;  {Read tt4 temp. in 1/10 øC}
       delta_t          = 19;  {Set delta_t in 1/10 øC}
       WarmupTime       = 20;  {Set Warmup-time in minutes}
       MF1eff           = 21;  {---}
       MF2eff           = 22;   {\}
       MF3eff           = 23;    {\}
       MF4eff           = 24;     {\}
       MF5eff           = 25;  {Read effect in % (0-100)}
       MF6eff           = 26;     {/}
       MF7eff           = 27;    {/}
       MF8eff           = 28;   {/}
       MF9eff           = 29;  {---}
       ProgramNumber    = 30;  {Set Program Number}
       Valve1Pos        = 31;  {Read % open (0-100)}
       Valve2Pos        = 32;  {Read % open (0-100)}
       CoolTime         = 33;  {Write number of cooling hours}

       AuxFlag          = $800;

TYPE
  PGenericCfg = ^GenericCfg;
  GenericCfg = OBJECT(TObject)
    IsVersion     : Byte;  {DON'T save this variable !!!
                            Will tell which version the file is when loaded }
    Version        : VersionRec;       {Version Signature}
    Number   : Integer;
    Name     : PString;           {Edit}
    Remote   : Boolean;           {Volatile}
    MaxTDry  : Integer;           {Edit}
    MaxTWet  : Integer;           {Edit}
    PLC      : PConnectionList;
    CONSTRUCTOR Init(NewNumber:Integer; NewName:String);
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE Store(VAR S:LFStream);                          VIRTUAL;
    PROCEDURE CreateFields(WS:PWorkSpace; Fields:PFieldList); VIRTUAL;
    PROCEDURE SetFields(VAR Fields:PFieldList);               VIRTUAL;
    PROCEDURE GetFields(VAR Fields:PFieldList);               VIRTUAL;
    DESTRUCTOR Done;                                          VIRTUAL;
    PROCEDURE PrintHeader(Rpt:PReport);                       VIRTUAL;
    PROCEDURE Print(Rpt:PReport);                             VIRTUAL;
    FUNCTION MakeCoil(ID:Word; Description:String; Log:Boolean; Mde,Prio:Word):PCoil;
    FUNCTION MakeReg(ID:Word; Description:String; Log:Boolean; Mde,Prio:Word):PRegister;
  END; {OBJ GenericCfg}

  PKilnCfg = ^KilnCfg;
  KilnCfg = OBJECT(GenericCfg)
    CoolLimit  : Word;
    CircVolume : Float;
    AirSpeed   : Float; {Ver.2}
    Spacer     : Float; {Ver.2}
    BlowDepth  : Float; {Ver.2}
    CONSTRUCTOR Init(NewNumber:Integer; NewName:String);
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE Store(VAR S:LFStream);                           VIRTUAL;
    PROCEDURE CreateFields(WS:PWorkSpace; Fields:PFieldList); VIRTUAL;
    PROCEDURE SetFields(VAR Fields:PFieldList);               VIRTUAL;
    PROCEDURE GetFields(VAR Fields:PFieldList);               VIRTUAL;
    DESTRUCTOR Done;                                          VIRTUAL;
    PROCEDURE PrintHeader(Rpt:PReport);                       VIRTUAL;
    PROCEDURE Print(Rpt:PReport);                             VIRTUAL;
  END; {OBJ KilnCfg}

  PMdlCfg = ^MdlCfg;
  MdlCfg = OBJECT(KilnCfg)
    CONSTRUCTOR Init(NewNumber:Integer; NewName:String);
    PROCEDURE PrintHeader(Rpt:PReport);                       VIRTUAL;
  END;

  PTunnelCfg = ^TunnelCfg;
  TunnelCfg = OBJECT(GenericCfg)
    NumberOfZones : Integer;
    UseRankList   : Boolean;     {Ver.1}
    MaxEnterRanks,               {Ver.1}
    MaxTunnelRanks,              {Ver.1}
    MaxExitRanks  : Integer;     {Ver.1}
    CONSTRUCTOR Init(NewNumber:Integer; NewName:String; Zones:Integer);
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE Store(VAR S:LFStream);                          VIRTUAL;
    PROCEDURE CreateFields(WS:PWorkSpace; Fields:PFieldList); VIRTUAL;
    PROCEDURE SetFields(VAR Fields:PFieldList);               VIRTUAL;
    PROCEDURE GetFields(VAR Fields:PFieldList);               VIRTUAL;
    DESTRUCTOR Done;                                          VIRTUAL;
    PROCEDURE PrintHeader(Rpt:PReport);                       VIRTUAL;
    PROCEDURE Print(Rpt:PReport);                             VIRTUAL;
  END; {OBJ TunnelCfg}

  InstList = OBJECT(TCollection)
    CONSTRUCTOR Init(Units:Integer);
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE Store(VAR S:LFStream);
    PROCEDURE Add(NewKiln:PGenericCfg);
    PROCEDURE Print(Rpt:PReport);
  END; {OBJ InstList}

  SerialDeviceInfo = RECORD
    Installed : Boolean;
    Port      : Byte;
    bps       : Word;
    Stopbits  : Byte;
    Parity    : Char;
  END;

  pInstallInfo = ^InstallInfo;
  InstallInfo = OBJECT(TObject)
    IsVersion     : Byte;  {DON'T save this variable !!!
                            Will tell which version the file is when loaded }
    Version        : VersionRec;       {Version Signature}
    Remote         : Boolean;          {Volatile}
    Units          : Integer;          {Number of installed kilns/tunnels}
    Language       : Word;             {Nationality}
    BlankInterval  : Word;             {time before blackout in minutes}
    BackupInterval : Word;             {In minutes}
    Controller     : Word;             {Type of PLC}
    PLCLink,                           {PLC Port info}
    ModemLink      : SerialDeviceInfo; {Modem Port info}
    PrinterType    : Word;             {Type of printer installed}
    NetWork        : Boolean;          {NetBIOS available ?}
    RemoteCtrl     : Boolean;          {Allow LAN remote control ?}
    NodeAdr,                           {Node address name}
    Customer,                          {Name of installation site}
    DateBy         : PString;          {Installed <date> by <Name>}
    Kilns          : InstList;         {Installed Kiln parameter list}
    CONSTRUCTOR Init(HowManyUnits:Integer);
    DESTRUCTOR  Done;                     VIRTUAL;
    CONSTRUCTOR Load(VAR S:LFStream);
    PROCEDURE   SetRemote(TrueIfRemote:Boolean);
    PROCEDURE   Edit(OwnerWS:PWorkSpace); VIRTUAL;
    PROCEDURE   Store(VAR S:LFStream);     VIRTUAL;
    PROCEDURE   Print(Rpt:PReport);       VIRTUAL;
  END; {OBJ InstallInfo}

{--------------------------------------------- Stream Registration Records ---
  Description
    Records containing Object ID and pointers to Object Load/Store methods
    Used with RegisterType to identify objects for the stream system
}

CONST
  InstallInfo_OID = 10000;
  InstallInfo_OSR: TStreamRec = (
    ObjType: InstallInfo_OID;
    VmtLink: Ofs(TypeOf(InstallInfo)^);
    Load:    @InstallInfo.Load;
    Store:   @InstallInfo.Store
  );

  InstList_OID = 10001;
  InstList_OSR: TStreamRec = (
    ObjType: InstList_OID;
    VmtLink: Ofs(TypeOf(InstList)^);
    Load:    @InstList.Load;
    Store:   @InstList.Store
  );

  GenericCfg_OID = 10010;
  GenericCfg_OSR: TStreamRec = (
    ObjType: GenericCfg_OID;
    VmtLink: Ofs(TypeOf(GenericCfg)^);
    Load:    @GenericCfg.Load;
    Store:   @GenericCfg.Store
  );

  KilnCfg_OID = 10011;
  KilnCfg_OSR: TStreamRec = (
    ObjType: KilnCfg_OID;
    VmtLink: Ofs(TypeOf(KilnCfg)^);
    Load:    @KilnCfg.Load;
    Store:   @KilnCfg.Store
  );

  TunnelCfg_OID = 10012;
  TunnelCfg_OSR: TStreamRec = (
    ObjType: TunnelCfg_OID;
    VmtLink: Ofs(TypeOf(TunnelCfg)^);
    Load:    @TunnelCfg.Load;
    Store:   @TunnelCfg.Store
  );

  MdlCfg_OID = 10009;
  MdlCfg_OSR: TStreamRec = (
    ObjType: MdlCfg_OID;
    VmtLink: Ofs(TypeOf(MdlCfg)^);
    Load:    @MdlCfg.Load;
    Store:   @MdlCfg.Store
  );

{-------------------------------------------------- Public Unit Variables ---}
VAR
  CfgLoaded : Boolean;
  LANDir    : FNameStr;

FUNCTION  LoadCfg(CfgFileName:String; VAR Config:pInstallInfo; Verbose:Boolean):Boolean;
PROCEDURE StoreCfg(CfgFileName:String; VAR Config:pInstallInfo);
PROCEDURE BuildKilnList(VAR Config:pInstallInfo; VAR list:PMenuTxt);

IMPLEMENTATION {%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
USES
  LFCrt,Dos,AGTools;

CONST
  CfgChanged : Boolean = False;



FUNCTION LoadCfg(CfgFileName:String; VAR Config:pInstallInfo; Verbose:Boolean):Boolean;
VAR
  CfgFile : LFStream;
BEGIN
    CfgLoaded:=False;
  IF Verbose
  THEN Write('Configuration file ');
  CfgFile.Init(CfgFileName,stOpenRead,StreamBufSize);
  IF CfgFile.Status=stOK
  THEN BEGIN
    New(Config, Load(CfgFile));
    CfgFile.Done;
    CfgLoaded:=True;
    IF Verbose
    THEN Writeln('OK');
  END
  ELSE IF Verbose
  THEN Writeln('not found !');
  LoadCfg:=CfgLoaded;
END;

PROCEDURE StoreCfg(CfgFileName:String; VAR Config:pInstallInfo);
VAR
  CfgFile : LFStream;
BEGIN
  CfgFile.Init(Path+CfgFileName,stCreate,StreamBufSize);
  Config^.Store(CfgFile);
  CfgFile.Done;
  CfgLoaded:=True;
  CfgChanged:=False;
  IF LANdir<>''
  THEN CopyFile(Path+CfgFileName, LANdir+CfgFileName);
END;


PROCEDURE BuildKilnList(VAR Config:pInstallInfo; VAR list:PMenuTxt);
VAR
  n : Integer;
  k : PGenericCfg;
BEGIN
  New(list,Init('',''));
  FOR n:=1 TO Config^.Units
  DO BEGIN
    k:=PGenericCfg(Config^.Kilns.At(n-1));
    list^.AddLine(PadTrailing(IntStr(k^.Number,0),' ',2)+': '+k^.Name^);
  END;
END; {PROC BuildKilnList}



{---------------------------------------------------------------- InstList ---
  Description:
    Contains a dynamic size collection of any type of kilns
    Each kiln contains it's respective PLC address info,
    and more.
}

CONSTRUCTOR InstList.Init(Units:Integer);
BEGIN
  TCollection.Init(Units,1);
END; {CONS InstList.Init}

CONSTRUCTOR InstList.Load(VAR S:LFStream);
BEGIN
  TCollection.Load(S);
END; {CONS InstList.Load}

PROCEDURE InstList.Store(VAR S:LFStream);
BEGIN
  TCollection.Store(S);
END; {PROC InstList.Store}

PROCEDURE InstList.Add(NewKiln:PGenericCfg);
BEGIN
  Insert(NewKiln);
END; {PROC InstList.Add}

PROCEDURE InstList.Print(Rpt:PReport);
  PROCEDURE PrintInfo(Kiln:PGenericCfg); FAR;
  BEGIN
    Rpt^.NewLn;
    Rpt^.AddLn(Rep(77,'-'));
    Rpt^.Add('Unit '+IntStr(Kiln^.Number,0)+' : ');
    IF Kiln^.Name<>Nil THEN Rpt^.Add(Kiln^.Name^) ELSE Rpt^.Add('?');
    Kiln^.PrintHeader(Rpt);
    Rpt^.NewLn;
    Kiln^.Print(Rpt);
  END;
BEGIN
  ForEach(@PrintInfo);
END; {PROC InstList.Add}

{------------------------------------------------------------- InstallInfo ---
  Description:
    Contains the actual number of installed kilns
    Type of PLC controller, serial port info, Network info,
    kiln/tunnel-list, misc. configuration info.
}

CONSTRUCTOR InstallInfo.Init(HowManyUnits:Integer);
{ - Initialize installation info}
BEGIN
  TObject.Init;
  Version        := VersionID;
  Version.Version:= InstallInfoVersion;
  IsVersion      := Version.Version;
  Units          := HowManyUnits;
  Language       := 047;  {Nationality}
  BlankInterval  := 5;    {minutes}
  BackupInterval := 60;   { -"- }
  Controller     := 2;    {Modicon}
  WITH PLCLink
  DO BEGIN
    Installed:=True;
    Port     :=1;
    bps      :=9600;
    Stopbits :=2;
    Parity   :='N';
  END;
  WITH ModemLink
  DO BEGIN
    Installed:=False;
    Port     :=2;
    bps      :=2400;
    Stopbits :=2;
    Parity   :='N';
  END;
  PrinterType:=0;
  Network    :=False;
  RemoteCtrl :=False;
  PSNew(NodeAdr,'');
  PSNew(Customer,'');
  PSNew(DateBy,'');
  Kilns.Init(Units);
END; {CONS InstallInfo.Init}

DESTRUCTOR InstallInfo.Done;
{ - Deallocate/Cleanup after installation info}
BEGIN
  Kilns.Done;
  PSDispose(DateBy);
  PSDispose(Customer);
  PSDispose(NodeAdr);
  TObject.Done;
END; {DEST InstallInfo.Done}

CONSTRUCTOR InstallInfo.Load(VAR S:LFStream);
{ - Initialize installation info from stream}
VAR
  VerID : Byte;
BEGIN
  S.Read(Version, SizeOf(Version));
  IF Version.Signature<>VersionID.Signature
  THEN BEGIN
    Units:=Version.Units;
    Language:=Version.Language;
    Version:=VersionID;
    Version.Version:=InstallInfoVersion;
    IsVersion:=0;
  END
  ELSE BEGIN
    IsVersion:=Version.Version;
    S.Read(Units,SizeOf(Units));
    S.Read(Language,SizeOf(Language));
  END;
  S.Read(BlankInterval,SizeOf(BlankInterval));
  S.Read(BackupInterval,SizeOf(BackupInterval));
  S.Read(Controller,SizeOf(Controller));
  S.Read(PLCLink,SizeOf(PLCLink));
  S.Read(ModemLink,SizeOf(ModemLink));
  S.Read(PrinterType,SizeOf(PrinterType));
  S.Read(NetWork,SizeOf(NetWork));
  S.Read(RemoteCtrl,SizeOf(RemoteCtrl));
  NodeAdr:=S.ReadStr;
  Customer:=S.ReadStr;
  DateBy:=S.ReadStr;
  Kilns.Load(S);

  IF IsVersion<InstallInfoVersion    {If updating an old version of the cfg file}
  THEN BEGIN
    CfgChanged:=True;
    Write('Updated from Ver.', IsVersion,' to ver.',InstallInfoVersion,' - ');
    FOR VerID:=IsVersion TO InstallInfoVersion
    DO BEGIN
      CASE VerID OF
        0 : {Do nothing};
        1 : ;
      END;
    END;
  END;
END; {CONS InstallInfo.Load}

PROCEDURE InstallInfo.SetRemote(TrueIfRemote:Boolean);
  PROCEDURE SubSetRemote(p:pGenericCfg); FAR;
  BEGIN
    p^.Remote:=TrueIfRemote;
  END;
BEGIN
  Remote:=TrueIfRemote;
  Kilns.ForEach(@SubSetRemote);
END; {InstallInfo.SetRemote}

PROCEDURE InstallInfo.Edit(OwnerWS:PWorkSpace);
{ - User changes of installation info}
BEGIN
END; {PROC InstallInfo.Edit}

PROCEDURE InstallInfo.Store(VAR S:LFStream);
{ - Write installation info to stream}
BEGIN
  S.Write(Version, SizeOf(Version));
  S.Write(Units,SizeOf(Units));
  S.Write(Language,SizeOf(Language));
  S.Write(BlankInterval,SizeOf(BlankInterval));
  S.Write(BackupInterval,SizeOf(BackupInterval));
  S.Write(Controller,SizeOf(Controller));
  S.Write(PLCLink,SizeOf(PLCLink));
  S.Write(ModemLink,SizeOf(ModemLink));
  S.Write(PrinterType,SizeOf(PrinterType));
  S.Write(NetWork,SizeOf(NetWork));
  S.Write(RemoteCtrl,SizeOf(RemoteCtrl));
  S.WriteStr(NodeAdr);
  S.WriteStr(Customer);
  S.WriteStr(DateBy);
  Kilns.Store(S);
END; {PROC InstallInfo.Store}

CONST
  YesNo : ARRAY[Boolean] OF String[3] = ('No','Yes');

PROCEDURE InstallInfo.Print(Rpt:PReport);
{ - Print installation info to a file (disk/con/prn) }
BEGIN
  Rpt^.AddLn('Units     : '+IntStr(Units,0));
  Rpt^.AddLn('Language  : '+IntStr(Language,0));
  Rpt^.AddLn('Blank Scr.: Every '+IntStr(BlankInterval,0)+' min.');
  Rpt^.AddLn('Backup    : Every '+IntStr(BackupInterval,0)+' min.');
  Rpt^.AddLn('Printer   : Type '+IntStr(PrinterType,0));
  Rpt^.Add('PLC model : '+PLCname[Controller]+' (COM');
  Rpt^.Add(IntStr(PLCLink.Port,0)+':');
  Rpt^.Add(IntStr(PLCLink.bps,0)+',');
  Rpt^.Add(IntStr(PLCLink.Stopbits,0)+',');
  Rpt^.AddLn(PLCLink.Parity+')');
  Rpt^.Add('Modem     : '+YesNo[ModemLink.Installed]+' (COM');
  Rpt^.Add(IntStr(ModemLink.Port,0)+':');
  Rpt^.Add(IntStr(ModemLink.bps,0)+',');
  Rpt^.Add(IntStr(ModemLink.Stopbits,0)+',');
  Rpt^.AddLn(ModemLink.Parity+')');
  Rpt^.AddLn('Network   : '+YesNo[NetWork]);
  Rpt^.AddLn('  Remote       : '+YesNo[RemoteCtrl]);
  Rpt^.Add('  Node adresse : ');
  IF NodeAdr<>nil THEN Rpt^.AddLn(NodeAdr^) ELSE Rpt^.AddLn('?');
  Rpt^.Add('Company   : ');
  IF Customer<>nil THEN Rpt^.AddLn(Customer^) ELSE Rpt^.AddLn('?');
  Rpt^.Add('Inst.     : ');
  IF Dateby<>nil THEN Rpt^.AddLn(DateBy^) ELSE Rpt^.AddLn('?');
  Kilns.Print(Rpt);
END; {PROC InstallInfo.Print}

{-------------------------------------------------------------- GenericCfg ---
  Description:
    Contains information common to both kilns and tunnels
    Start/Stop, Temperatures, acknowledge/status flags.
}

VAR
  Next : GuessAddress;

FUNCTION GenericCfg.MakeCoil(ID:Word; Description:String; Log:Boolean; Mde,Prio:Word):PCoil;
VAR
  C : PCoil;
BEGIN
  C:=New(PCoil,Init(Next.Addr,ID,Description,Mde,Prio));
  C^.DoLog:=Log;
  PLC^.Insert(C);
  MakeCoil:=C;
END; {PROC GenericCfg.MakeCoil}

FUNCTION GenericCfg.MakeReg(ID:Word; Description:String; Log:Boolean; Mde,Prio:Word):PRegister;
VAR
  R : PRegister;
BEGIN
  R:=New(PRegister,Init(Next.Addr,ID,Description,Mde,Prio));
  R^.DoLog:=Log;
  PLC^.Insert(R);
  MakeReg:=R;
END; {PROC GenericCfg.MakeReg}

CONSTRUCTOR GenericCfg.Init(NewNumber:Integer; NewName:String);
{ - Init with default values}
BEGIN
  TObject.Init;
  Version        := VersionID;
  Version.Version:= InstallInfoVersion;
  IsVersion      := Version.Version;
  Number         := NewNumber;
  MaxTDry        :=750;
  MaxTWet        :=750;
  PSNew(Name,NewName);
 New(PLC,Init);
  Next.Start(1000,Number,100);
  MakeCoil(Start           ,'Start',         False, pe_Write, 1);
  MakeCoil(Stop            ,'Stop',          False, pe_Write, 1);
  MakeCoil(Started         ,'Started',       False, pe_Poll,  1);
  MakeCoil(ProcessFault    ,'ProcessFault',  True,  pe_Read,  2);
  MakeCoil(MotorFault      ,'Motor fault',   False, pe_Read,  2);
  MakeCoil(DryingPhaseFlag ,'Drying Phase',  False, pe_Read,  1);
  MakeCoil(SkipRead        ,'Skip Read',     False, pe_Poll,  1);
END; {CONS GenericCfg.Init}


CONSTRUCTOR GenericCfg.Load(VAR S:LFStream);
{ - Load init values from stream}
VAR
  VerID : Byte;
BEGIN
  S.Read(Version.Units, SizeOf(Version.Units));
  IF (Version.Signature[1]<>VersionID.Signature[1])
  or (Version.Signature[2]<>VersionID.Signature[2])
  THEN BEGIN
    Number:=Version.Units;
    Version:=VersionID;
    Version.Version:=ConfigVersion;
    IsVersion:=0;
  END
  ELSE BEGIN
    S.Read(Version.Language, SizeOf(Version.Language));
    IsVersion:=Version.Version;
    S.Read(Number,SizeOf(Number));
  END;
  Name:=S.ReadStr;
  New(PLC,Load(S));

  IF IsVersion<ConfigVersion    {If updating an old version of the cfg file}
  THEN BEGIN
    Writeln(^M' Updating ', Name^, ' from ver.',IsVersion, ' to ver.',ConfigVersion);
    CfgChanged:=True;
    FOR VerID:=IsVersion TO ConfigVersion
    DO BEGIN
      CASE VerID OF
        3 : BEGIN
              MaxTWet:=750;       {Ver.3}
              MaxTDry:=750;       {Ver.3}
            END;
      END;
    END;
  END;
  IF IsVersion>=3
  THEN BEGIN
    S.Read(MaxTWet, SizeOf(MaxTWet));
    S.Read(MaxTDry, SizeOf(MaxTDry));
  END;
END; {CONS GenericCfg.Load}

PROCEDURE GenericCfg.Store(VAR S:LFStream);
{ - Store info to stream }
BEGIN
  Version.Version:=ConfigVersion;
  S.Write(Version, SizeOf(Version));
  S.Write(Number,SizeOf(Number));
  S.WriteStr(Name);
  PLC^.Store(S);
  S.Write(MaxTWet, SizeOf(MaxTWet));
  S.Write(MaxTDry, SizeOf(MaxTDry));
END; {PROC GenericCfg.Store}

PROCEDURE GenericCfg.CreateFields(WS:PWorkSpace; Fields:PFieldList);
{ - Build Edit field list}
VAR
  f : PGenEdit;
BEGIN
  f:=New(PStrPInput,Init(WS,20,1,20,Name,[#32..#127]+NorskSet,False));
  f^.Link(Msg,'KILNNAME?','KILNNAME','');
  Fields^.Add(Name,f);
  f:=new(PFloatInput,Init(WS,20,2,4,1,       30,MaxTWet/10,90));
  f^.Link(Msg,'WET-TEMP?','MAX-WET','CELSIUS');
  Fields^.Add(MaxTWet,f);
  f:=new(PFloatInput,Init(WS,20,3,4,1,       30,MaxTDry/10,100));
  f^.Link(Msg,'DRY-TEMP?','MAX-DRY','CELSIUS');
  Fields^.Add(MaxTDry,f);
END; {PROC GenericCfg.CreateFields}

CONST
  GenFields = 3;

PROCEDURE GenericCfg.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
VAR
  f : PGenEdit;
BEGIN
  f:=Fields^.Using(Name);       PStrPInput(f)^.Assign(Name^);
  f:=Fields^.Using(MaxTWet);    PFloatInput(f)^.Assign(MaxTWet/10);
  f:=Fields^.Using(MaxTDry);    PFloatInput(f)^.Assign(MaxTDry/10);
END; {PROC GenericCfg.SetFields}

PROCEDURE GenericCfg.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
VAR
  f : PGenEdit;
BEGIN
  PSDispose(Name);
  Fields^.Fetch(Name);
  f:=Fields^.Using(MaxTDry);     MaxTDry:=Round(PFloatInput(f)^.Value*10);
  f:=Fields^.Using(MaxTWet);     MaxTWet:=Round(PFloatInput(f)^.Value*10);
END; {PROC GenericCfg.GetFields}

DESTRUCTOR GenericCfg.Done;
{ - Cleanup after basic dryer}
BEGIN
  Dispose(PLC,Done);
  PSDispose(Name);
END; {DEST GenericCfg.Done}

PROCEDURE GenericCfg.PrintHeader(Rpt:PReport);
{ - Print type of kiln (for installation report)}
BEGIN
  Rpt^.AddLn('  (Generic)');
END; {PROC GenericCfg.PrintHeader}

PROCEDURE GenericCfg.Print(Rpt:PReport);
{ - Print installation report info}
BEGIN
  PLC^.Print(Rpt);
  Rpt^.AddLn(LookUp('MAX-WET')+FloatStr(MaxTWet/10,4,1)+LookUp('CELSIUS'));
  Rpt^.AddLn(LookUp('MAX-DRY')+FloatStr(MaxTDry/10,4,1)+LookUp('CELSIUS'));
END; {PROC GenericCfg.Print}


{----------------------------------------------------------------- KilnCfg ---
  Description:
    General kiln (as in PRO2)
}

CONSTRUCTOR KilnCfg.Init(NewNumber:Integer; NewName:String);
{ - Init with default values}
VAR
 n : Word;
BEGIN
  GenericCfg.Init(NewNumber,NewName);           {Init inherited values}
  CoolLimit:=12;
  CircVolume:=1;
  AirSpeed:=4;  {Ver.3}
  Spacer:=10;   {Ver.3}
  BlowDepth:=6; {Ver.3}
  MakeCoil(StartedManually ,'StartedManually',False, pe_Read, 1);
  MakeCoil(CondPhaseFlag   ,'CondPhaseFlag'  ,False, pe_Write, 2);
  MakeCoil(Basing          ,'Basing'         ,False, pe_Read, 2);
  MakeCoil(MainFanDir      ,'MainFanDir'     ,False, pe_Read, 2);
  MakeCoil(VentFan1Run     ,'VentFan1Run'    ,False, pe_Read, 2);
  MakeCoil(VentFan1Fault   ,'VentFan1Fault'  ,False, pe_Read, 3);
  MakeCoil(VentFan2Run     ,'VentFan2Run'    ,False, pe_Read, 2);
  MakeCoil(VentFan2Fault   ,'VentFan2Fault'  ,False, pe_Read, 3);
  MakeCoil(MF1Run          ,'Fan 1 Run'      ,False, pe_Read, 2);
  MakeCoil(MF1Fault        ,'Fan 1 Fault'    ,False, pe_Read, 3);
  MakeCoil(MF2Run          ,'Fan 2 Run'      ,False, pe_Read, 2);
  MakeCoil(MF2Fault        ,'Fan 2 Fault'    ,False, pe_Read, 3);
  MakeCoil(MF3Run          ,'Fan 3 Run'      ,False, pe_Read, 2);
  MakeCoil(MF3Fault        ,'Fan 3 Fault'    ,False, pe_Read, 3);
  MakeCoil(Pump1Run        ,'Pump1Run'       ,False, pe_Read, 2);
  MakeCoil(Pump1Fault      ,'Pump1Fault'     ,False, pe_Read, 3);
  { - Create aux coils }
  FOR n:=1 TO 8
  DO BEGIN
    MakeCoil(AuxFlag+n,'Aux '+IntStr(n,0), False, pe_Read, 9);
    PLC^.Coil(AuxFlag+n)^.Installed:=False;
  END;
  Next.Start(40000,Number,100);
  MakeReg(tvSet        ,'tvSet'        ,True, pe_Write, 1);
  MakeReg(tvRead       ,'tvRead'       ,True, pe_Read,  1);
  MakeReg(ttSet        ,'ttSet'        ,True, pe_Write, 1);
  MakeReg(ttRead       ,'ttRead'       ,True, pe_Read,  1);
  MakeReg(TempDiffCond ,'TempDiffCond' ,False, pe_Write, 1);
  MakeReg(DryingTime   ,'DryingTime'   ,False, pe_Write, 1);
  MakeReg(CondTime     ,'CondTime'     ,False, pe_Write, 1);
  MakeReg(CoolTime     ,'CoolTime'     ,False, pe_Write, 1);
  MakeReg(tt1          ,'tt'           ,True, pe_Read, 1);
  MakeReg(tv1          ,'tv'           ,True, pe_Read, 1);
  MakeReg(tt2          ,'tt1'          ,True, pe_Read, 1);
  MakeReg(tt3          ,'tt2'          ,True, pe_Read, 1);
  MakeReg(MainFanEff   ,'MainFanEff'   ,False, pe_Read, 3);
  MakeReg(Valve1Pos    ,'Valve1Pos'    ,False, pe_Read, 2);
  MakeReg(Damper1Pos   ,'Damper1Pos'   ,False, pe_Read, 2);
  MakeReg(Damper2Pos   ,'Damper2Pos'   ,False, pe_Read, 2);
  MakeReg(WaterTmpIn   ,'WaterTmpIn'   ,False, pe_Read, 3);
  MakeReg(WaterTmpOut  ,'WaterTmpOut'  ,False, pe_Read, 3);
  MakeReg(ProgramNumber,'Prog.ID.'     ,False, pe_Read, 2);
  { - Create aux Registers }
  FOR n:=1 TO 4
  DO BEGIN
    MakeReg(AuxFlag+n,'Aux '+IntStr(n,0), False, pe_Read, 9);
    PLC^.Register(AuxFlag+n)^.Installed:=False;
  END;
END; {CONS KilnCfg.Init}

CONSTRUCTOR KilnCfg.Load(VAR S:LFStream);
{ - Load values from stream}
VAR
  VerID : Byte;
BEGIN
  GenericCfg.Load(S);                        {Load inherited values}
  S.Read(CoolLimit,SizeOf(CoolLimit));
  S.Read(CircVolume,SizeOf(CircVolume));
  IF IsVersion<ConfigVersion    {If updating an old version of the cfg file}
  THEN BEGIN
    CfgChanged:=True;
    FOR VerID:=IsVersion TO ConfigVersion
    DO BEGIN
      CASE VerID OF
        0 : {Do nothing};
        2 : MakeReg(CoolTime, 'CoolTime' ,False, pe_Write, 1); {Ver.2}
        3 : BEGIN
              AirSpeed:=4;
              Spacer:=10;
              BlowDepth:=6;
            END;
      END;
    END;
  END;
  IF IsVersion>=3
  THEN BEGIN
    S.Read(AirSpeed,  SizeOf(AirSpeed));
    S.Read(Spacer,    SizeOf(Spacer));
    S.Read(BlowDepth, SizeOf(BlowDepth));
  END;

END; {CONS KilnCfg.Load}

PROCEDURE KilnCfg.Store(VAR S:LFStream);
{ - Store values to stream}
BEGIN
  GenericCfg.Store(S);                        {Store inherited values}
  S.Write(CoolLimit,SizeOf(CoolLimit));
  S.Write(CircVolume,SizeOf(CircVolume));
  S.Write(AirSpeed,  SizeOf(AirSpeed));
  S.Write(Spacer,    SizeOf(Spacer));
  S.Write(BlowDepth, SizeOf(BlowDepth));
END; {PROC KilnCfg.Store}

PROCEDURE KilnCfg.CreateFields(WS:PWorkSpace; Fields:PFieldList);
{ - Build Edit field list}
VAR
  f : PGenEdit;
BEGIN
  GenericCfg.CreateFields(WS,Fields);

  f:=New(PIntInput,Init(WS,20, GenFields+1 ,4,      0,CoolLimit,48));
  f^.Link(Msg,'COOL-LIM?','COOL-LIM','HOURS');
  Fields^.Add(CoolLimit,f);

  f:=New(PFloatInput,Init(WS,20, GenFields+2, 5,2,  0,CircVolume,999.99));
  f^.Link(Msg,'CIRCVOL?','CIRCVOL','VOLMEAS');
  Fields^.Add(CircVolume,f);

  f:=New(PFloatInput,Init(WS,20, GenFields+3, 5,2,  0,AirSpeed,999.99));
  f^.Link(Msg,'','AIRSPEED','SPEEDMEAS');
  Fields^.Add(AirSpeed,f);
  f:=New(PFloatInput,Init(WS,20, GenFields+4, 5,1,  0,Spacer,999.99));
  f^.Link(Msg,'','SPACER','MILLIMET');
  Fields^.Add(Spacer,f);
  f:=New(PFloatInput,Init(WS,20, GenFields+5, 5,2,  0,BlowDepth,999.99));
  f^.Link(Msg,'','BLOWDEPTH','METER');
  Fields^.Add(BlowDepth,f);
END; {PROC KilnCfg.CreateFields}

CONST
  KilnFields = 5;

PROCEDURE KilnCfg.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
VAR
  f : PGenEdit;
BEGIN
  GenericCfg.SetFields(Fields);
  f:=Fields^.Using(CoolLimit);   PIntInput(f)^.Assign(CoolLimit);
  f:=Fields^.Using(CircVolume);  PFloatInput(f)^.Assign(CircVolume);
  f:=Fields^.Using(AirSpeed);    PFloatInput(f)^.Assign(AirSpeed);
  f:=Fields^.Using(Spacer);      PFloatInput(f)^.Assign(Spacer);
  f:=Fields^.Using(BlowDepth);   PFloatInput(f)^.Assign(BlowDepth);
END; {PROC KilnCfg.SetFields}

PROCEDURE KilnCfg.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
BEGIN
  GenericCfg.GetFields(Fields);
  Fields^.Fetch(CoolLimit);
  Fields^.Fetch(CircVolume);
  Fields^.Fetch(AirSpeed);
  Fields^.Fetch(Spacer);
  Fields^.Fetch(BlowDepth);
END; {PROC KilnCfg.GetFields}

DESTRUCTOR KilnCfg.Done;
{ - Cleanup after use}
BEGIN
  GenericCfg.Done;    {Cleanup inherited values}
END; {DEST KilnCfg.Done}

PROCEDURE KilnCfg.PrintHeader(Rpt:PReport);
{ - Print type of kiln (for installation report)}
BEGIN
  Rpt^.AddLn('  (Basic Kiln)');
END; {PROC KilnCfg.PrintHeader}

PROCEDURE KilnCfg.Print(Rpt:PReport);
{ - Print installation report info}
BEGIN
  GenericCfg.Print(Rpt);            {Print inherited info}
  Rpt^.AddLn('Cooling time limit :'+IntStr(CoolLimit,3)+' h');
  Rpt^.AddLn('Circ. water volume :'+RealStr(CircVolume,6,2)+' kg/h');
  Rpt^.AddLn(LookUp('AIRSPEED')+RealStr(AirSpeed,6,2)+LOOKUP('SPEEDMEAS'));
  Rpt^.AddLn(LookUp('SPACER')+RealStr(Spacer,6,1)+LOOKUP('MILLIMET'));
  Rpt^.AddLn(LookUp('BLOWDEPTH')+RealStr(BlowDepth,6,2)+LOOKUP('METER'));
END; {PROC KilnCfg.Print}

{----------------------------------------------------------------- MdlCfg ---
  Description:
    Model kiln
}

CONSTRUCTOR MdlCfg.Init(NewNumber:Integer; NewName:String);
{ - Init with default values}
VAR
 n : Word;
BEGIN
  KilnCfg.Init(NewNumber,NewName);           {Init inherited values}
  Dispose(PLC, Done);
  New(PLC, Init);
END; {CONS MdlCfg.Init}

PROCEDURE MdlCfg.PrintHeader(Rpt:PReport);
{ - Print type of kiln (for installation report)}
BEGIN
  Rpt^.AddLn('  (Model Kiln)');
END; {PROC MdlCfg.PrintHeader}

{-------------------------------------------------------------- TunnelCfg ---
  Description:
    Contains tunnel information
}

CONSTRUCTOR TunnelCfg.Init(NewNumber:Integer; NewName:String; Zones:Integer);
{ - Init with default values}
VAR
 n : Word;
 R : PRegister;
BEGIN
  GenericCfg.Init(NewNumber,NewName);
  NumberOfZones:=Zones;
  MakeCoil(MF1Run      ,'Fan 1 Run'   ,False, pe_Read, 2);
  MakeCoil(MF1Fault    ,'Fan 1 Fault' ,False, pe_Read, 3);
  MakeCoil(MF2Run      ,'Fan 2 Run'   ,False, pe_Read, 2);
  MakeCoil(MF2Fault    ,'Fan 2 Fault' ,False, pe_Read, 3);
  MakeCoil(MF3Run      ,'Fan 3 Run'   ,False, pe_Read, 2);
  MakeCoil(MF3Fault    ,'Fan 3 Fault' ,False, pe_Read, 3);
  MakeCoil(MF4Run      ,'Fan 4 Run'   ,False, pe_Read, 2);
  MakeCoil(MF4Fault    ,'Fan 4 Fault' ,False, pe_Read, 3);
  MakeCoil(MF5Run      ,'Fan 5 Run'   ,False, pe_Read, 2);
  MakeCoil(MF5Fault    ,'Fan 5 Fault' ,False, pe_Read, 3);
  MakeCoil(MF6Run      ,'Fan 6 Run'   ,False, pe_Read, 2);
  MakeCoil(MF6Fault    ,'Fan 6 Fault' ,False, pe_Read, 3);
  MakeCoil(VentFan1Run   ,'Vent Fan 1 Run'   ,False, pe_Read, 2);
  MakeCoil(VentFan1Fault ,'Vent Fan 1 Fault' ,False, pe_Read, 3);

  MakeCoil(Pump1Run    ,'Pump 1 Run'     ,False, pe_Read, 2);
  MakeCoil(Pump1Fault  ,'Pump 1 Fault'   ,False, pe_Read, 3);
  MakeCoil(Pump2Run    ,'Pump 2 Run'     ,False, pe_Read, 2);
  MakeCoil(Pump2Fault  ,'Pump 2 Fault'   ,False, pe_Read, 3);


  { - Create aux coils }
  FOR n:=1 TO 4
  DO BEGIN
    MakeCoil(AuxFlag+n,'Aux '+IntStr(n,0), False, pe_Read, 9);
    PLC^.Coil(AuxFlag+n)^.Installed:=False;
  END;


  Next.Start(4100,Number,100);
  MakeReg(tvSet        ,'tvSet'   ,True, pe_Write, 1);
  MakeReg(ttSet        ,'ttSet'   ,True, pe_Write, 1);
  MakeReg(tvRead       ,'tvRead'  ,True, pe_Read, 1);
  MakeReg(ttRead       ,'ttRead'  ,True, pe_Read, 1);
  MakeReg(tt1          ,'tt1'     ,True, pe_Read, 1);
  MakeReg(tv1          ,'tv1'     ,True, pe_Read, 1);
  MakeReg(tt2          ,'tt2'     ,True, pe_Read, 1);
  MakeReg(tv2          ,'tv2'     ,True, pe_Read, 1);
  MakeReg(tt3          ,'tt3'     ,True, pe_Read, 1);
  MakeReg(tt4          ,'tt4'     ,True, pe_Read, 1);
  MakeReg(delta_t      ,'delta t' ,False, pe_Write, 1);
  MakeReg(WarmupTime   ,'Warm up time' ,False, pe_Write, 1);
  MakeReg(Damper1Pos   ,'Damper 1 Pos' ,False, pe_Read, 2);
  MakeReg(Damper2Pos   ,'Damper 2 Pos' ,False, pe_Read, 2);
  MakeReg(Valve1Pos    ,'Valve  1 Pos' ,False, pe_Read, 2);
  MakeReg(Valve2Pos    ,'Valve  2 Pos' ,False, pe_Read, 2);


  { - Create aux Registers }
  FOR n:=1 TO 4
  DO BEGIN
    MakeReg(AuxFlag+n,'Aux '+IntStr(n,0), False, pe_Read, 9);
    PLC^.Register(AuxFlag+n)^.Installed:=False;
  END;

  UseRankList   := False;                     {Ver.1}
  MaxEnterRanks := 0;                         {Ver.1}
  MaxTunnelRanks  := 0;                       {Ver.1}
  MaxExitRanks  := 0;                         {Ver.1}

END; {CONS TunnelCfg.Init}

CONSTRUCTOR TunnelCfg.Load(VAR S:LFStream);
{ - Load init values from stream}
VAR
  VerID : Byte;
BEGIN
  GenericCfg.Load(S);
  S.Read(NumberOfZones,SizeOf(NumberOfZones));
  IF IsVersion<ConfigVersion    {If updating an old version of the cfg file}
  THEN BEGIN
    CfgChanged:=True;
    FOR VerID:=IsVersion TO ConfigVersion
    DO BEGIN
      CASE VerID OF
        0 : {Do nothing};
        1 : BEGIN
              UseRankList   := False;         {Ver.1}
              MaxEnterRanks := 0;             {Ver.1}
              MaxTunnelRanks  := 0;           {Ver.1}
              MaxExitRanks  := 0;             {Ver.1}
            END;
      END;
    END;
  END;
  IF IsVersion >= 1
  THEN BEGIN
    S.Read(UseRankList, SizeOf(UseRankList));       {Ver.1}
    S.Read(MaxEnterRanks, SizeOf(MaxEnterRanks));   {Ver.1}
    S.Read(MaxTunnelRanks, SizeOf(MaxTunnelRanks)); {Ver.1}
    S.Read(MaxExitRanks, SizeOf(MaxExitRanks));     {Ver.1}
  END;
END; {CONS TunnelCfg.Load}

PROCEDURE TunnelCfg.Store(VAR S:LFStream);
{ - Store info to stream }
BEGIN
  GenericCfg.Store(S);
  S.Write(NumberOfZones,SizeOf(NumberOfZones));
  S.Write(UseRankList, SizeOf(UseRankList));       {Ver.1}
  S.Write(MaxEnterRanks, SizeOf(MaxEnterRanks));   {Ver.1}
  S.Write(MaxTunnelRanks, SizeOf(MaxTunnelRanks)); {Ver.1}
  S.Write(MaxExitRanks, SizeOf(MaxExitRanks));     {Ver.1}
END; {PROC TunnelCfg.Store}

PROCEDURE TunnelCfg.CreateFields(WS:PWorkSpace; Fields:PFieldList);
{ - Build Edit field list}
VAR
  f : PGenEdit;
BEGIN
  GenericCfg.CreateFields(WS,Fields);
  f:=New(PIntInput,Init(WS,20,4,4,             1,NumberOfZones,2));
  f^.Link(Msg,'ZONE#?','ZONE#','');
  Fields^.Add(NumberOfZones,f);

  f:=new(PBooleanInput,Init(WS,20,5,3,UseRankList ,Msg^.FindText('YESNOSLCT')));
  f^.Link(Msg,'USERANK?','USERANK','');
  Fields^.Add(UseRankList,f);

  f:=New(PIntInput,Init(WS,20,6,3,             0,MaxEnterRanks,10));
  f^.Link(Msg,'MAXERANK?','MAXERANK','');
  Fields^.Add(MaxEnterRanks,f);

  f:=New(PIntInput,Init(WS,20,7,3,             0,MaxTunnelRanks,50));
  f^.Link(Msg,'MAXTRANK?','MAXTRANK','');
  Fields^.Add(MaxTunnelRanks,f);

  f:=New(PIntInput,Init(WS,20,8,3,             0,MaxExitRanks,10));
  f^.Link(Msg,'MAXXRANK?','MAXXRANK','');
  Fields^.Add(MaxExitRanks,f);

END; {PROC TunnelCfg.CreateFields}

PROCEDURE TunnelCfg.SetFields(VAR Fields:PFieldList);
{ - Put new values into fields }
VAR
  f : PGenEdit;
BEGIN
  GenericCfg.SetFields(Fields);
  f:=Fields^.Using(NumberOfZones);   PIntInput(f)^.Assign(NumberOfZones);
  f:=Fields^.Using(UseRankList);     PBooleanInput(f)^.Assign(UseRankList);
  f:=Fields^.Using(MaxEnterRanks);   PIntInput(f)^.Assign(MaxEnterRanks);
  f:=Fields^.Using(MaxTunnelRanks);  PIntInput(f)^.Assign(MaxTunnelRanks);
  f:=Fields^.Using(MaxExitRanks);    PIntInput(f)^.Assign(MaxExitRanks);
END; {PROC TunnelCfg.SetFields}

PROCEDURE TunnelCfg.GetFields(VAR Fields:PFieldList);
{ - Extract values from fields }
BEGIN
  GenericCfg.GetFields(Fields);
  Fields^.Fetch(NumberOfZones);
  Fields^.Fetch(UseRankList);
  Fields^.Fetch(MaxEnterRanks);
  Fields^.Fetch(MaxTunnelRanks);
  Fields^.Fetch(MaxExitRanks);
END; {PROC TunnelCfg.GetFields}


DESTRUCTOR TunnelCfg.Done;
{ - Cleanup after basic dryer}
BEGIN
  GenericCfg.Done;
END; {DEST TunnelCfg.Done}

PROCEDURE TunnelCfg.PrintHeader(Rpt:PReport);
{ - Print type of kiln (for installation report)}
BEGIN
  Rpt^.AddLn('  (Tunnel)');
END; {PROC TunnelCfg.PrintHeader}

PROCEDURE TunnelCfg.Print(Rpt:PReport);
{ - Print installation report info}
BEGIN
  Rpt^.AddLn('Zones        : '+IntStr(NumberOfZones,0));
  Rpt^.AddLn('Use Ranklist : '+YesNo[UseRankList]);
  Rpt^.AddLn('  Max Enter ranks  : '+IntStr(MaxEnterRanks,0));
  Rpt^.AddLn('  Max Tunnel ranks : '+IntStr(MaxTunnelRanks,0));
  Rpt^.AddLn('  Max Exit ranks   : '+IntStr(MaxExitRanks,0));
  PLC^.Print(Rpt);
END; {PROC TunnelCfg.Print}

{---------------------------------------------------------- Initialization ---

}

PROCEDURE RegisterKilnConfig;
BEGIN
  RegisterType(InstallInfo_OSR);
  RegisterType(InstList_OSR);
  RegisterType(PLCEntity_OSR);  {From PLCIF unit}
  RegisterType(aCoil_OSR);      {From PLCIF unit}
  RegisterType(aRegister_OSR);  {From PLCIF unit}
  RegisterType(GenericCfg_OSR);
  RegisterType(KilnCfg_OSR);
  RegisterType(TunnelCfg_OSR);
  RegisterType(MdlCfg_OSR);
END; {PROC RegisterKilnConfig}


{------------------------------------------------------------ Exit handler ---
  Description
    The Exithandler cleans up after normal or abnormal termination
}

VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}
CONST
  P3ConfigMsg = ' P3Config ';

PROCEDURE P3SetupExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitHandler;
{  IF CfgLoaded
  THEN BEGIN
    IF CfgChanged
    THEN StoreCfg;
    Config.Done;
  END;           }
  Units.Leave(P3ConfigMsg,MemAvail);
END; {PROC P3SetupExitHandler}

BEGIN
  PrevExitHandler:=ExitProc;
  ExitProc:=@P3SetupExitHandler;
  Units.Enter(P3ConfigMsg,MemAvail,CSeg);
  CfgLoaded:=False;
  RegisterKilnConfig;
END.

