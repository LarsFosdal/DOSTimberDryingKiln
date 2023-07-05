UNIT PLCDrive; {PLC Serial Interface Driver}
{$I CODEDEFS.PAS} {Include code generation definitions}
{$X+}


{ - Pay attention to :

    * note about PLCEntities and logs
}

INTERFACE
USES Objects,LFsystem,LFtable,LFString,LFExtMsg;

CONST
  PLCIFmsg = ' PLCIF.4B (c) 920809 Lars Fosdal ';
  { - PLC model ID's }
  Simulator  = 0;
  Modicon484 = 1;
  Modicon884 = 2;
  MelsecF1   = 3;
  Telemechan = 4;
  Satt       = 5;
  IPC_620    = 6;
  Siemens6b  = 7;
  MaxPLC     = Siemens6b ;

  PLCRetryCount : Word = 5; {max. transmission retries for a PLC Entity }

CONST
  PLCname : ARRAY[1..maxPLC] OF String[30] =(
    'Gould Modicon 484',
    'Gould Modicon 884',
    'Mitsubishi F1',
    'Telemechanique',
    'SattCon COMLI 01',
    'Kl”ckner-Moeller IPC 620-14',
    'Siemens 6-byte'
    );

CONST
  { - PLC Entity ID's }
  isCoilID     = $C000;
  isRegisterID = $D000;

CONST
  pe_Read      = $0001;
  pe_Write     = $0002;
  pe_ReadWrite = pe_Read or pe_Write;
  pe_Poll      = $0004;
  pe_LogRead   = $0008;
  pe_LogWrite  = $0010;
  pe_LogRW     = pe_LogRead or pe_LogWrite;


TYPE
  AddressType = String[8];

  { - Basis object for coils/registers }
  PPLCEntity = ^PLCEntity;
  PLCEntity = OBJECT(TObject)
    ID         : Word;
    Address    : AddressType;      {Edit}
    Priority,                      {Edit}
    CurrPri,                       {Volatile}
    ErrorValue : Integer;
    Installed  : Boolean;          {Edit} {Is this coil/reg. Installed ?}
    DoLog      : Boolean;          {Edit}
    Mode       : Word;             {Edit, R/W - modes}
    Log        : PGenSampler;      {Reference to log, volatile}
    Name       : PString;          {Edit}
    CONSTRUCTOR Init(NewAddress:AddressType; NewID:Word; NewName:String; NewMode, NewPrio:Word);
    PROCEDURE   SetMode(_Mode:Word);
    CONSTRUCTOR Load(VAR S:TStream);
    DESTRUCTOR  Done;                                    VIRTUAL;
    PROCEDURE   Store(VAR S:TStream);                    VIRTUAL;
    PROCEDURE   LinkLog(OldLog:PGenSampler);             VIRTUAL;
    FUNCTION    CreateLog(AvgCount:Integer):PGenSampler; VIRTUAL;
    PROCEDURE   Read;                                    VIRTUAL;
    PROCEDURE   Write;                                   VIRTUAL;
    PROCEDURE   ReadEntity;                              VIRTUAL;
    PROCEDURE   WriteEntity;                             VIRTUAL;
    PROCEDURE   UpdateLog;                               VIRTUAL;
    FUNCTION    isValid:Boolean;                         VIRTUAL;
    FUNCTION    Print:String;                            VIRTUAL;
    FUNCTION    Error:Integer;                           VIRTUAL;
  END;

  { - PLC Coil Object }
  PCoil = ^aCoil;           
  aCoil = OBJECT(PLCEntity)
    State : Boolean;
    CONSTRUCTOR Init(NewAddress:AddressType; NewID:Word; NewName:String; NewMode, NewPrio:Word);
    CONSTRUCTOR Load(VAR S:TStream);
    DESTRUCTOR  Done;                                       VIRTUAL;
    FUNCTION    CreateLog(AvgCount:Integer):PGenSampler;    VIRTUAL;
    PROCEDURE   LinkLog(OldLog:PGenSampler);                VIRTUAL;
    PROCEDURE   ReadEntity;                                 VIRTUAL;
    PROCEDURE   WriteEntity;                                VIRTUAL;
    PROCEDURE   UpdateLog;                                  VIRTUAL;
    FUNCTION    Print:String;                               VIRTUAL;
    FUNCTION    Enabled:Boolean;                            VIRTUAL;
    FUNCTION    Disabled:Boolean;                           VIRTUAL;
    PROCEDURE   Enable;                                     VIRTUAL;
    PROCEDURE   Disable;                                    VIRTUAL;
    FUNCTION    Last:Boolean;
  END;

  { - PLC Register object }
  PRegister = ^aRegister;
  aRegister = OBJECT(PLCEntity)
    Value : Integer;
    CONSTRUCTOR Init(NewAddress:AddressType; NewID:Word; NewName:String; NewMode, NewPrio:Word);
    CONSTRUCTOR Load(VAR S:TStream);
    DESTRUCTOR  Done;                                       VIRTUAL;
    FUNCTION    CreateLog(AvgCount:Integer):PGenSampler;    VIRTUAL;
    PROCEDURE   LinkLog(OldLog:PGenSampler);                VIRTUAL;
    PROCEDURE   ReadEntity;                                 VIRTUAL;
    PROCEDURE   WriteEntity;                                VIRTUAL;
    PROCEDURE   UpdateLog;                                  VIRTUAL;
    FUNCTION    Print:String;                               VIRTUAL;
    FUNCTION    Last:Integer;
  END;


TYPE
  { - Collection of coils and reg's
  }
  PConnectionList = ^ConnectionList;
  ConnectionList = OBJECT(TSortedCollection)
    UpdateIdx : Integer;
    PassComplete : Boolean;
    LastReadMsg  : String[40];
    CONSTRUCTOR Init;
    CONSTRUCTOR Load(VAR S:TStream);
    FUNCTION  Compare(Key1, Key2:Pointer): Integer;         VIRTUAL;
    FUNCTION  Entity(PLCEntID:Word):PPLCEntity;
    FUNCTION  Coil(CoilID:Word):PCoil;
    FUNCTION  Register(RegisterID:Word):PRegister;
    PROCEDURE Print(Rpt:PReport);                           
    PROCEDURE MakeList(List:PMenuTxt; Hooks:PCollection);
    FUNCTION  ReadUpdate:Boolean;
    FUNCTION  LastRead:String;
    PROCEDURE LogUpdate;
    PROCEDURE SkipUpdates(n:LongInt);
    PROCEDURE ValidateAddresses(VAR f:Text);
  END; {OBJ ConnectionList}

  { - Collection of Connection-logs }
  PLogList = ^LogList;  
  LogList = OBJECT(TSortedCollection)
    CONSTRUCTOR Init(Connections:PConnectionList;AvgCount:Integer);
    PROCEDURE Link(Connections:PConnectionList);
    PROCEDURE CheckLinks(Connections:pConnectionList);
    PROCEDURE UnLink(Connections:PConnectionList);
    FUNCTION Compare(Key1, Key2:Pointer): Integer; VIRTUAL;
    FUNCTION Entity(PLCEntID:Word):PGenSampler;
    FUNCTION Coil(CoilID:Word):PAvgBoolSampler;
    FUNCTION Register(RegisterID:Word):PAvgIntSampler;
    PROCEDURE SetSize(Connections:PConnectionList; Points:Integer);
    PROCEDURE Reset;
  END; {OBJ LogList}



CONST
 PLCEntity_OID = 10002;
  PLCEntity_OSR: TStreamRec = (
    ObjType: PLCEntity_OID;
    VmtLink: Ofs(TypeOf(PLCEntity)^);
    Load:    @PLCEntity.Load;
    Store:   @PLCEntity.Store
  );

CONST
 aCoil_OID = 10003;
  aCoil_OSR: TStreamRec = (
    ObjType: aCoil_OID;
    VmtLink: Ofs(TypeOf(aCoil)^);
    Load:    @aCoil.Load;
    Store:   @aCoil.Store
  );

CONST
 aRegister_OID = 10004;
  aRegister_OSR: TStreamRec = (
    ObjType: aRegister_OID;
    VmtLink: Ofs(TypeOf(aRegister)^);
    Load:    @aRegister.Load;
    Store:   @aRegister.Store
  );

CONST
 ConnectionList_OID = 10005;
  ConnectionList_OSR: TStreamRec = (
    ObjType: ConnectionList_OID;
    VmtLink: Ofs(TypeOf(ConnectionList)^);
    Load:    @ConnectionList.Load;
    Store:   @ConnectionList.Store
  );

CONST
 LogList_OID = 10006;
  LogList_OSR: TStreamRec = (
    ObjType: LogList_OID;
    VmtLink: Ofs(TypeOf(LogList)^);
    Load:    @LogList.Load;
    Store:   @LogList.Store
  );

TYPE
  GuessAddress = OBJECT
    BaseAddr : Word;
    Segment  : Word;
    Offset   : Word;
    Count    : Word;
    PROCEDURE Start(NewBase,NewSeg,SegSize:Word);
    FUNCTION Addr:AddressType;
  END;

PROCEDURE ConnectPLC(Model,
                     Port:Byte;
                     BaudRate:Integer;
                     Parity:Char;
                     StopBits:Byte);
FUNCTION  PLCValidateAddress(Model:Word; sAddress:AddressType; VAR Wrd:Word):Boolean;
FUNCTION  PLCresponding:Boolean;
FUNCTION  PLCReadCoil(sAddress:AddressType):Boolean;
PROCEDURE PLCSetCoil(sAddress:AddressType; State:Boolean);
FUNCTION  PLCReadRegister(sAddress:AddressType):Word;
PROCEDURE PLCSetRegister(sAddress:AddressType; Value:Word);
FUNCTION  PLCError:Integer;
FUNCTION  PLCErrorMsg(i:Integer):String;
PROCEDURE PLCdirectControl(Hi2,Hi1,Lo2,Lo1:Byte);
PROCEDURE DisconnectPLC;

IMPLEMENTATION

USES
  Crt, AGTools, P4Limits
{$IFNDEF NoSerial}
  ,LFcomm,ModBus,Telemec,MelsecF,SattCon,IPC620,Siemens
{$ENDIF};

CONST
  WaitForMS: Word = 0;
  PLCModel : Byte = Modicon884;
  PLCErrorValue:Integer = 0;

PROCEDURE GuessAddress.Start(NewBase,NewSeg,SegSize:Word);
{ - Generate a sequence of register adresses for init's}
BEGIN
  BaseAddr:=NewBase;
  Segment:=NewSeg*SegSize;
  Offset:=0;
  Count:=0;
END; {GuessAddress.Start}

FUNCTION GuessAddress.Addr:AddressType;
BEGIN
  Addr:=IntStr(BaseAddr+Segment+Offset,0);
  Inc(Offset);
  Inc(Count);
END;


{--------------------------------------------------------------- PLCEntity ---
  Description:
    Common object base for a Register or Coil connection

    NB!  The PLCEntity _must_ be equipped with a log before use,
    either by connecting an existing log (LinkLog) or by creating
    a new log (CreateLog).
    The destruction of a PLCEntity will not destruct it's log

}

CONSTRUCTOR PLCEntity.Init(NewAddress:AddressType; NewID:Word; NewName:String; NewMode, NewPrio:Word);
{ - Init and set address/reset error}
BEGIN
  TObject.Init;
  Address:=NewAddress;
  ID:=NewID;
  ErrorValue:=0;
  PSNew(Name,NewName);
  Installed:=True;
  DoLog:=False;
  SetMode(NewMode);
  Priority:=NewPrio;
  CurrPri:=1;
  Log:=nil;
END; {CONS PLCEntity.Init}

PROCEDURE PLCEntity.SetMode(_mode:Word);
BEGIN
  Mode:=_mode;
END; {PROC PLCEntity.SetMode}

CONSTRUCTOR PLCEntity.Load(VAR S:TStream);
{ Init address from stream and set/reset other var's}
BEGIN
  S.Read(ID,SizeOf(ID));
  S.Read(Address,SizeOf(Address));
  S.Read(Installed,SizeOf(Installed));
  S.Read(DoLog,SizeOf(DoLog));
  S.Read(Mode,SizeOf(Mode));
  S.Read(Priority, SizeOf(Priority));
  Name:=S.ReadStr;
  CurrPri:=1;
  ErrorValue:=0;
  Log:=nil;
END; {CONS PLCEntity.Load}

PROCEDURE PLCEntity.Store(VAR S:TStream);
BEGIN
  S.Write(ID,SizeOf(ID));
  S.Write(Address,SizeOf(Address));
  S.Write(Installed,SizeOf(Installed));
  S.Write(DoLog,SizeOf(DoLog));
  S.Write(Mode,SizeOf(Mode));
  S.Write(Priority, SizeOf(Priority));
  S.WriteStr(Name);
END; {PROC PLCEntity.Store}

DESTRUCTOR PLCEntity.Done;
BEGIN
  PSDispose(Name);
END; {DEST PLCEntity.Done}

PROCEDURE PLCEntity.LinkLog(OldLog:PGenSampler);
BEGIN
  Log:=OldLog;
END; {PROC PLCEntity.LinkLog}

FUNCTION PLCEntity.CreateLog(AvgCount:Integer):PGenSampler;
BEGIN
  TrapAbstract;
END; {FUNC PLCEntity.CreateLog}

PROCEDURE PLCEntity.Read;
VAR
  Tries : Integer;
BEGIN
  IF Installed
  THEN BEGIN
    Dec(CurrPri);
    IF CurrPri=0
    THEN BEGIN
      CurrPri:=Priority;
      ErrorValue:=PLCError; {Clear Errorvalue}
      ErrorValue:=0;
      Tries:=0;                   {Start retry count}
      REPEAT
        Delay(WaitForMS);
        Inc(Tries);
        ReadEntity;               {Call actual Read routine}
        ErrorValue:=PLCError;
      UNTIL (Tries>=PLCRetryCount) or (ErrorValue=0);
    END;
  END;
END; {PROC PLCEntity.Read}

PROCEDURE PLCEntity.Write;
VAR
  Tries : Integer;
BEGIN
  IF Installed
  THEN BEGIN
    ErrorValue:=PLCError;       {Clear Errorvalue}
    ErrorValue:=0;
    Tries:=0;                   {Start retry count}
    REPEAT
      Delay(WaitForMS);
      Inc(Tries);
      WriteEntity;              {Call actual write routine}
      ErrorValue:=PLCError;
    UNTIL (Tries>=PLCRetryCount) or (ErrorValue=0);
    UpdateLog;
  END;
END; {PROC PLCEntity.Write}

PROCEDURE PLCEntity.ReadEntity;
{ - Read PLCEntity state/value from PLC}
BEGIN
  TrapAbstract;
END; {PROC PLCEntity.ReadEntity}

PROCEDURE PLCEntity.WriteEntity;
{ - Transfer new Entity state/value to PLC}
BEGIN
  TrapAbstract;
END; {PROC PLCEntity.WriteEntity}

PROCEDURE PLCEntity.UpdateLog;
{ - Transfer Entity state/value to log}
BEGIN
  TrapAbstract;
END; {PROC PLCEntity.UpdateLog}

FUNCTION PLCEntity.isValid:Boolean;
BEGIN
  isValid:=(ErrorValue=0);
END; {FUNC PLCEntity.isValid}

FUNCTION PLCEntity.Print;
{ - Transfer new Entity state/value to PLC}
CONST
  Lgd : ARRAY[Boolean] OF String[6] = ('      ','Logged');
  modes : ARRAY[1..4] OF String[6] = ('R   ','W   ','R/W ','Poll');
BEGIN
  Print:=PadLeading(SwapAll('O','o',Address),' ',8)+' : '+'  '+IntStr(Priority,0)+'  '+Modes[mode]+'  '+Lgd[DoLog]+' '+Name^
END; {FUNC PLCEntity.Print}

FUNCTION PLCEntity.Error:Integer;
BEGIN
  Error:=ErrorValue;
END; {FUNC PLCEntity.Error}


{-------------------------------------------------------------------- Coil ---
  Description:
   PLC coil connection routines
}

CONSTRUCTOR aCoil.Init(NewAddress:AddressType; NewID:Word; NewName:String; NewMode, NewPrio:Word);
{ - Init Coil with default values}
BEGIN
  NewID:=NewID or isCoilID;
  PLCEntity.Init(NewAddress, NewID, NewName, NewMode, NewPrio);
  State:=False;
END; {CONS aCoil.Init}

CONSTRUCTOR aCoil.Load(VAR S:TStream);
{ - Load values from stream}
BEGIN
  PLCEntity.Load(S);  {Load inherited values}
  State:=False;
END; {CONS aCoil.Load}

DESTRUCTOR aCoil.Done;
{ - Cleanup after coil}
BEGIN
  PLCEntity.Done;
END; {DEST aCoil.Done}

FUNCTION aCoil.CreateLog(AvgCount:Integer):PGenSampler;
BEGIN
  Log:=New(PAvgBoolSampler,Init(ID,AvgCount));
{  IF (Not Installed) or (Not DoLog)
  THEN} Log^.SetSize(1);
  CreateLog:=Log;
END; {FUNC aCoil.CreateLog}

PROCEDURE aCoil.LinkLog(OldLog:PGenSampler);
BEGIN
  PLCEntity.LinkLog(OldLog);
  State:=PAvgBoolSampler(Log)^.Last;
END; {PROC aCoil.LinkLog}

PROCEDURE aCoil.ReadEntity;
{ - Read coil state from PLC}
BEGIN
{$IFNDEF NoSerial}
  State:=PLCReadCoil(Address);
{$ELSE}
  IF State
  THEN State:=State and (Random>0.9)
  ELSE State:=State or (Random>0.9);
{$ENDIF}
END; {PROC aCoil.ReadEntity}

PROCEDURE aCoil.WriteEntity;
{ - Transfer new coil state to PLC}
BEGIN
  PLCSetCoil(Address,State);
END; {PROC aCoil.WriteEntity}

PROCEDURE aCoil.UpdateLog;
{ - Transfer coil state to log}
BEGIN
  IF Installed
  THEN BEGIN
    IF Not isValid
    THEN State:=PAvgBoolSampler(Log)^.Last;
    IF DoLog
    THEN PAvgBoolSampler(Log)^.Update(State)
    ELSE PAvgBoolSampler(Log)^.AtPut(0,State)
  END;
END; {PROC aCoil.UpdateLog}

FUNCTION aCoil.Print;
{ - One-line information string }
BEGIN
  IF Installed
  THEN Print:='Coil '+PLCEntity.Print
  ELSE Print:=Name^;
END; {FUNC aCoil.Print}


FUNCTION aCoil.Enabled:Boolean;
BEGIN
  Enabled:=State=True;
END; {FUNC Coil.Enabled}

FUNCTION aCoil.Disabled:Boolean;
BEGIN
  Disabled:=State=False;
END; {FUNC Coil.Disabled}

PROCEDURE aCoil.Enable;
BEGIN
  State:=True;
END; {FUNC Coil.Enable}

PROCEDURE aCoil.Disable;
BEGIN
  State:=False;
END; {FUNC Coil.Disable}

FUNCTION aCoil.Last:Boolean;
BEGIN
  IF Installed
  THEN Last:=State
  ELSE Last:=False;
END; {FUNCTION aCoil.Last}

{---------------------------------------------------------------- Register ---
  Description:
    PLC Register connection routines
}

CONSTRUCTOR aRegister.Init(NewAddress:AddressType; NewID:Word; NewName:String; NewMode, NewPrio:Word);
{ - Init Register with default values}
BEGIN
  PLCEntity.Init(NewAddress,(NewID or isRegisterID),NewName, NewMode, NewPrio);
  Value:=0;
END; {CONS aRegister.Init}

CONSTRUCTOR aRegister.Load(VAR S:TStream);
{ - Load values from stream}
BEGIN
  PLCEntity.Load(S);  {Load inherited values}
  Value:=0;
END; {CONS aRegister.Load}

DESTRUCTOR aRegister.Done;
{ - Cleanup after Register}
BEGIN
  PLCEntity.Done;
END; {DEST aRegister.Done}

FUNCTION aRegister.CreateLog(AvgCount:Integer):PGenSampler;
BEGIN
  Log:=New(PAvgIntSampler,Init(ID,AvgCount));
  {IF Not DoLog THEN} Log^.SetSize(1);
  CreateLog:=Log;
END; {FUNC aRegister.CreateLog}

PROCEDURE aRegister.LinkLog(OldLog:PGenSampler);
BEGIN
  PLCEntity.LinkLog(OldLog);
  Value:=PAvgIntSampler(Log)^.Last;
END; {PROC aRegister.LinkLog}

PROCEDURE aRegister.ReadEntity;
{ - Read Register state from PLC}
BEGIN
{$IFNDEF NoSerial}
 {$IFOPT R+} {$R-} {$DEFINE RPlus} {$ENDIF}
  Value:=PLCReadRegister(Address);
 {$IFDEF RPlus} {$R+} {$UNDEF RPlus} {$ENDIF}
{$ELSE}
  IF Random>0.5
  THEN Inc(Value)
  ELSE Dec(Value);
{$ENDIF}
END; {PROC aRegister.ReadEntity}

PROCEDURE aRegister.WriteEntity;
{ - Transfer new Register state to PLC}
BEGIN
 {$IFOPT R+} {$R-} {$DEFINE RPlus} {$ENDIF}
  PLCSetRegister(Address,Value);
 {$IFDEF RPlus} {$R+} {$UNDEF RPlus} {$ENDIF}
END; {PROC aRegister.WriteEntity}

PROCEDURE aRegister.UpdateLog;
{ - Transfer Register value to log}
BEGIN
  IF Installed
  THEN BEGIN
    IF Not isValid
    THEN Value:=PAvgIntSampler(Log)^.Last;
    IF DoLog
    THEN PAvgIntSampler(Log)^.Update(Value)
    ELSE PAvgIntSampler(Log)^.AtPut(0,Value)
  END;
END; {PROC aRegister.UpdateLog}

FUNCTION aRegister.Print;
{ - One-line information string }
BEGIN
  IF Installed
  THEN Print:='Reg. '+PLCEntity.Print
  ELSE Print:=Name^;
END; {FUNC aRegister.Print}

FUNCTION aRegister.Last:Integer;
BEGIN
  IF Installed
  THEN Last:=Value
  ELSE Last:=-1;
END; {FUNCTION aRegister.Last}

{------------------------------------------------------------- Connections ---
  Description:
    Collection of Registers and/or Coils
}

CONSTRUCTOR ConnectionList.Init;
{ - Init Collection of registers/and or coils }
BEGIN
  TCollection.Init(32,2);
  UpdateIdx:=0;
  PassComplete:=False;
END; {CONS Connection.Init}

CONSTRUCTOR ConnectionList.Load(VAR S:TStream);
BEGIN
  TSortedCollection.Load(S);
  UpdateIdx:=0;
  PassComplete:=False;
END; {CONS ConnectionList.Load}

FUNCTION ConnectionList.Compare(Key1,Key2:Pointer):Integer;
{ - Key comparator for TSortedCollection }
VAR
  K1 : PPLCEntity Absolute Key1;
  K2 : PPLCEntity Absolute Key2;
BEGIN
  IF K1^.ID=K2^.ID THEN Compare:=0
  ELSE IF K1^.ID<K2^.ID THEN Compare:=-1
  ELSE Compare:=1;
END; {FUNC ConnectionList.Compare}

FUNCTION ConnectionList.Entity(PLCEntID:Word):PPLCEntity;
VAR
  p   : Integer;
  Key : PPLCEntity;
BEGIN
  New(Key,Init('',PLCEntID,'',0,0));
  IF Search(Key,p)
  THEN Entity:=PPLCEntiTy(At(p))
  ELSE Entity:=nil;
  Dispose(Key,Done);
END; {FUNC ConnectionList.Entity}

FUNCTION ConnectionList.Coil(CoilID:Word):PCoil;
BEGIN
  Coil:=PCoil(Entity(isCoilID or CoilID));
END; {FUNC ConnectionList.Coil}

FUNCTION ConnectionList.Register(RegisterID:Word):PRegister;
BEGIN
  Register:=PRegister(Entity(isRegisterID or RegisterID));
END; {FUNC ConnectionList.Register}

PROCEDURE ConnectionList.Print(Rpt:PReport);
VAR
  n : Integer;
  PROCEDURE UsedEntity_Print(Entity:PPLCEntity); FAR;
  BEGIN
    IF Entity^.Installed
    THEN Rpt^.AddLn(Entity^.Print);
  END;
  PROCEDURE UnusedCoil_Print(Entity:PPLCEntity); FAR;
  BEGIN
    IF not Entity^.Installed and (TypeOf(Entity^)=TypeOf(aCoil))
    THEN BEGIN
      Rpt^.Add(PadTrailing(Copy(Entity^.Print,1,14),' ',15));
      Inc(n); IF n MOD 5 = 0 THEN Rpt^.NewLn;
    END;
  END;
  PROCEDURE UnusedReg_Print(Entity:PPLCEntity); FAR;
  BEGIN
    IF not Entity^.Installed and (TypeOf(Entity^)=TypeOf(aRegister))
    THEN BEGIN
      Rpt^.Add(PadTrailing(Copy(Entity^.Print,1,14),' ',15));
      Inc(n); IF n MOD 5 = 0 THEN Rpt^.NewLn;
    END;
  END;
BEGIN
  ForEach(@UsedEntity_Print);
  Rpt^.AddLn('Auxiliary coils : ');
  n:=0;
  ForEach(@UnusedCoil_Print);
  IF n MOD 5 <> 0 THEN Rpt^.NewLn;
  n:=0;
  Rpt^.AddLn('Auxiliary registers : ');
  ForEach(@UnusedReg_Print);
  IF n MOD 5 <> 0 THEN Rpt^.NewLn;
END; {PROC ConnectionList.Print}

PROCEDURE ConnectionList.MakeList(List:PMenuTxt; Hooks:PCollection);
VAR
  s : String[35];
  cond : Boolean;
  PROCEDURE Entity_AddToList(Entity:PPLCEntity); FAR;
  BEGIN
    IF Entity^.Installed=Cond
    THEN BEGIN
      IF TypeOF(Entity^)=TypeOf(aRegister)
      THEN s:=' reg.'
      ELSE s:=' coil';
      s:=Entity^.Name^+s;
      IF Cond THEN s:=s+' ['+Entity^.Address+']';
      List^.AddLine(s);
      Hooks^.Insert(New(PHookEntry,Init(Entity^.ID)));
    END;
  END;
BEGIN
  Cond:=True;
  ForEach(@Entity_AddToList);
  Cond:=False;
  ForEach(@Entity_AddToList);
END; {PROC ConnectionList.MakeList}

FUNCTION ConnectionList.ReadUpdate:Boolean;
VAR
  pE : pPLCEntity;
  ev : Integer;
BEGIN
  IF Count>0
  THEN BEGIN
    pE:=pPLCEntity(At(UpdateIdx));
    IF pE^.Installed
    and ((pE^.Mode and pe_Read) = pe_Read)
    THEN pE^.Read;
    IF UpdateIdx<Count-1
    THEN Inc(UpdateIdx)
    ELSE BEGIN
      UpdateIdx:=0;
      PassComplete:=True;
    END;
    LastReadMsg:=pE^.Name^+' ['+pE^.Address+'] : '+PLCErrorMsg(pE^.ErrorValue);
    ev:=pE^.ErrorValue;
  END ELSE ev:=0;
  ReadUpdate:=ev=0;
END; {PROC ConnectionList.ReadUpdate}

FUNCTION ConnectionList.LastRead:String;
BEGIN
  LastRead:=LastReadMsg;
END;

PROCEDURE ConnectionList.LogUpdate;
  PROCEDURE ActiveEntity_Update(Entity:PPLCEntity); FAR;
  BEGIN
    IF Entity^.Installed
    and ((Entity^.Mode and pe_Read)=pe_Read)
    THEN BEGIN
      Entity^.UpdateLog;
    END;
  END;
BEGIN
  ForEach(@ActiveEntity_Update);
END; {PROC ConnectionList.LogUpdate}

PROCEDURE ConnectionList.SkipUpdates(n:LongInt);
  PROCEDURE ActiveEntity_Skip(Entity:PPLCEntity); FAR;
  BEGIN
    IF Entity^.Installed and Entity^.doLog
    and (Entity^.Mode and pe_LogRW<>0)
    THEN Entity^.Log^.Skip(n);
  END;
BEGIN
  ForEach(@ActiveEntity_Skip);
END; {PROC ConnectionList.SkipUpdate}

PROCEDURE ConnectionList.ValidateAddresses(VAR f:Text);
  PROCEDURE Validate(p:pPLCEntity); FAR;
  VAR
    waddr : Word;
  BEGIN
    IF p^.Installed
    THEN BEGIN
      IF Not PLCValidateAddress(PLCModel, p^.Address, waddr)
      THEN Writeln(f, p^.Name^,', ',p^.Address,' is invalid');
    END
  END; {PROC Validate}
BEGIN
  ForEach(@Validate);
END; {PROC ConnectionList.ValidateAddresses}


{----------------------------------------------------------------- LogList ---
  Description
    Table of logs (histograms) for coils/registers
}

CONSTRUCTOR LogList.Init(Connections:PConnectionList; AvgCount:Integer);
{ - }
  PROCEDURE Create_Log(This:PPLCEntity); FAR;
  BEGIN
    IF This^.Installed
    THEN Insert(This^.CreateLog(AvgCount));
  END;

BEGIN
  TCollection.Init(Connections^.Count,1);
  Connections^.ForEach(@Create_Log);
END; {CONS LogList.Init}

PROCEDURE LogList.Link(Connections:PConnectionList);
{ - }
  PROCEDURE Log_FindEntity(L:PGenSampler); FAR;
  VAR
    C : PPLCEntity;
  BEGIN
    C:=Connections^.Entity(L^.ID);
    IF C<>nil
    THEN C^.LinkLog(L)
    ELSE AddToLog('Log without Entity ?');
  END; {LOCAL PROC Log_FindEntity}
BEGIN
  ForEach(@Log_FindEntity);
  CheckLinks(Connections);
END; {PROC LogList.Link}

PROCEDURE LogList.CheckLinks(Connections:PConnectionList);
  PROCEDURE CheckMissingLinks(L:pPLCEntity); FAR;
  BEGIN
    IF (L^.Installed) and (L^.Log=nil)
    THEN Insert(L^.CreateLog(LoggingsPerSample));
  END; {LOCAL PROC CheckMissingLinks}
BEGIN
  Connections^.ForEach(@CheckMissingLinks);
END; {PROC LogList.CheckLinks}

PROCEDURE LogList.UnLink(Connections:PConnectionList);
{ - }
  PROCEDURE Log_FindEntity(L:PGenSampler); FAR;
  VAR
    C : PPLCEntity;
  BEGIN
    C:=Connections^.Entity(L^.ID);
    IF C<>nil
    THEN C^.Log:=nil
    ELSE {///////////////ERROR};
  END;
BEGIN
  ForEach(@Log_FindEntity);
END; {PROC LogList.UnLink}

FUNCTION LogList.Compare(Key1, Key2:Pointer): Integer;
{ - }
VAR
  K1 : PGenSampler Absolute Key1;
  K2 : PGenSampler Absolute Key2;
BEGIN
  IF K1^.ID=K2^.ID THEN Compare:=0
  ELSE IF K1^.ID<K2^.ID THEN Compare:=-1
  ELSE Compare:=1;
END; {FUNC LogList.Compare}

FUNCTION LogList.Entity(PLCEntID:Word):PGenSampler;
VAR
  p   : Integer;
  Key : PGenSampler;
BEGIN
  New(Key,Init(PLCEntID));
  IF Search(Key,p)
  THEN Entity:=PGenSampler(At(p))
  ELSE Entity:=nil;
  Dispose(Key,Done);
END; {FUNC LogList.Entity}

FUNCTION LogList.Coil(CoilID:Word):PAvgBoolSampler;
BEGIN
  Coil:=PAvgBoolSampler(Entity(isCoilID or CoilID));
END; {FUNC LogList.Coil}

FUNCTION LogList.Register(RegisterID:Word):PAvgIntSampler;
BEGIN
  Register:=PAvgIntSampler(Entity(isRegisterID or RegisterID));
END; {FUNC LogList.Register}

PROCEDURE LogList.SetSize(Connections:PConnectionList; Points:Integer);
  PROCEDURE Log_SetSize(L:PGenSampler); FAR;
  VAR
    C : PPLCEntity;
  BEGIN
    C:=Connections^.Entity(L^.ID);
    IF C<>nil
    THEN IF C^.DoLog and C^.Installed
    THEN L^.SetSize(Points);
  END;
BEGIN
  ForEach(@Log_SetSize);
END; {PROC LogList.SetSize}

PROCEDURE LogList.Reset;
  PROCEDURE Log_Reset(L:PGenSampler); FAR;
  BEGIN
    L^.Reset;
  END;
BEGIN
  ForEach(@Log_Reset);
END; {PROC LogList.Reset}


{-------------------------------------------------------------------- Misc ---  Description:
    Generic PLC connection routines
}

PROCEDURE Check4Errors;
BEGIN
  PLCErrorValue:=0;
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Modicon484,
    Modicon884 : PLCerrorValue:=Modbus.ModBusError;
    MelsecF1   : PLCerrorValue:=MelsecF.MelsecError;
    Telemechan : PLCerrorValue:=Telemec.TelemecError;
    Satt       : PLCerrorValue:=SattCon.SattConError;
    IPC_620    : PLCerrorValue:=IPC620.IPC620Error;
    Siemens6b  : PLCerrorValue:=Siemens.SiemensError;
  END;
{$ENDIF}
END;{PROC Check4Errors}

PROCEDURE ConnectPLC(Model,Port:Byte; BaudRate:Integer; Parity:Char; StopBits:Byte);
BEGIN
  PLCModel:=Model;
  WaitForMS:=0;
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Modicon484,
    Modicon884 : BEGIN {Assumes PLC address 01 and RTU protocol}
                   ModBus.SetModBus(Port,1,RTU);
                   ModBus.ConnectModBus(BaudRate,Parity,StopBits);
                 END;
    MelsecF1   : MelsecF.ConnectPLC(Port,BaudRate);
    Telemechan : Telemec.ConnectTelemec(Port,BaudRate);
    Satt       : BEGIN {Assumes PLC address 01 and Binary protocol}
                   SattCon.SetSattCon(Port,1,Binary);
                   SattCon.ConnectSattCon(BaudRate,Parity,StopBits);
                 END;
    IPC_620    : BEGIN {Assumes PLC address 01 and RTU protocol}
                   WaitForMS:=50;
                   IPC620.SetIPC620 (Port);
                   IPC620.ConnectIPC620 (BaudRate,Parity,StopBits);
                 END;
    Siemens6b  : Siemens.ConnectSiemens(Port,BaudRate);
  END;
{$ENDIF}
  Check4Errors;
END;{PROC ConnectPLC}

FUNCTION PLCresponding:Boolean;
VAR
  Response : Boolean;
  w1,w2    : Word;
  b        : Byte;
BEGIN
  Response:=True;
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Modicon484,
    Modicon884 : Response:=Modbus.ModBusResponding;
    MelsecF1   : BEGIN
                   ReadPLCtype(b);
                   PLCerrorValue:=MelsecF.MelsecError;
                   Response:=(PLCerrorValue=0);
                 END;
    Telemechan : BEGIN
                   Telemec.GetStatus(w1,w2);
                   PLCerrorValue:=Telemec.TelemecError;
                   Response:=(PLCerrorValue=0);
                 END;
    Satt       : Response:=SattCon.SattConResponding;
    IPC_620    : Response:=IPC620.IPC620Responding;
    Siemens6b  : BEGIN
                   Siemens.GetStatus(w1,w2);
                   PLCerrorValue:=Siemens.SiemensError;
                   Response:=(PLCerrorValue=0);
                 END;
  END;
{$ENDIF}
  Check4Errors;
  PLCresponding:={$IFDEF SimReal} True {$ELSE} Response {$ENDIF};
END;{FUNC PLCresponding}

PROCEDURE StripLetters(VAR sAddress:AddressType);
VAR
  i : Integer;
BEGIN
  i:=0;
  WHILE i<Length(sAddress)
  DO BEGIN
    Inc(i);
    IF Upcase(sAddress[i]) in ['A'..'Z']
    THEN Delete(sAddress, i, 1);
  END;
END;

FUNCTION PLCValidateAddress(Model:Word; sAddress:AddressType; VAR Wrd:Word):Boolean;
{ - Returns true if address is ok}
VAR
  Valid : Boolean;
  e     : Integer;
  h,l   : Byte;
  s     : AddressType;
BEGIN
  CASE Model OF
    Modicon484, Modicon884,
    MelsecF1,   Telemechan,
    Satt,       IPC_620 : BEGIN
      StripLetters(sAddress);
      Val(sAddress,wrd,e);
      Valid:=e=0;
    END;
    Siemens6b : BEGIN
      StripLetters(sAddress);
      sAddress:=SwapAll('.', ',', sAddress);
      s:=BeforeLast(',',sAddress);
      Val(s, h, e);
      Valid:=e=0;
      s:=AfterLast(',',sAddress);
      Val(s, l, e);
      Valid:=Valid and Boolean(e=0);
      Wrd:=256*h+l;
    END;
  END;
  IF not Valid THEN Wrd:=$0000;
  PLCValidateAddress:=Valid;
END; {FUNC PLCValidateAddress}

FUNCTION PLCReadCoil(sAddress:AddressType):Boolean;
VAR
  State:Boolean;
  Dummy   : Word;
  Address : Word;
BEGIN
  PLCValidateAddress(PLCModel, sAddress, Address);
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Modicon484,
    Modicon884 : State:=ModBus.ReadOneCoil(Address);
    MelsecF1   : BEGIN
                 {- Melsec F-series PLCs have no function to read single coil,}
                 {- so this is the tricky part. Delays must perhaps be added!}
                   SetPLCMonitorAddr(1,Address,0,Dummy);
                   PLCErrorValue:=MelsecF.MelsecError;
                   Dummy:=Integer(PLCErrorValue);
                   IF PLCerrorValue=0
                   THEN BEGIN
                     MonitorPLC(State,Dummy);
                   END ELSE PLCErrorValue:=Integer(dummy);
                 END;
    Telemechan : State:=Telemec.ReadCoil(Address);
    Satt       : State:=SattCon.GetIOBIT(Address);
    IPC_620    : State:=IPC620.ReadOneCoil(Address);
    Siemens6b  : State:=Siemens.ReadCoil(Address);
  END;
{$ELSE}
  State:=Boolean(Random>0.5) and True;
{$ENDIF}
  Check4Errors;
  PLCReadCoil:=State;
END;{FUNC PLCReadCoil}

PROCEDURE PLCSetCoil(sAddress:AddressType; State:Boolean);
VAR
  Address : Word;
BEGIN
  PLCValidateAddress(PLCModel, sAddress, Address);
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Modicon484,
    Modicon884 : Modbus.ForceSingleCoil(Address,State);
    MelsecF1   : SwitchElement(Address,State);
    Telemechan : Telemec.SetCoil(Address,State);
    Satt       : SattCon.SetIOBIT(Address,State);
    IPC_620    : IPC620.ForceSingleCoil(Address,State);
    Siemens6b  : Siemens.SetCoil(Address,State);
  END;
{$ENDIF}
  Check4Errors;
END;{PROC PLCSetCoil}

FUNCTION PLCReadRegister(sAddress:AddressType):Word;
VAR
  Value : Word;
  Address : Word;
BEGIN
  PLCValidateAddress(PLCModel, sAddress, Address);
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Modicon484 : IF Address>=4000
                 THEN Value:=Modbus.ReadOneHoldReg(Address)  {4xxx}
                 ELSE Value:=Modbus.ReadOneInputReg(Address); {3xxx}
    Modicon884 : IF Address>=40000
                 THEN Value:=Modbus.ReadOneHoldReg(Address)  {4xxxx}
                 ELSE Value:=Modbus.ReadOneInputReg(Address); {3xxxx}
    MelsecF1   : MelSecF.ReadPLCreg(Address,Value);
    Telemechan : Value:=Word(Telemec.ReadRegister(Address));
    Satt       : Value:=SattCon.GetIORAM(Address);
    IPC_620    : Value:=IPC620.ReadOneHoldReg(Address);
                 (*IF Address>=4096
                 THEN Value:=IPC620.ReadOneHoldReg(Address)   {4096 ->}
                 ELSE Value:=IPC620.ReadOneInputReg(Address); {1 ->} *)
    Siemens6b  : Value:=Word(Siemens.ReadRegister(Address));
  END;
{$ELSE}
  Value:=Random(9999);
{$ENDIF}
  Check4Errors;
  PLCReadRegister:=Value;
END;{FUNC PLCReadRegister}

PROCEDURE PLCSetRegister(sAddress:AddressType; Value:Word);
VAR
  Address : Word;
BEGIN
  PLCValidateAddress(PLCModel, sAddress, Address);
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Modicon484,
    Modicon884 : Modbus.PresetSingleReg(Address,Value);
    MelsecF1   : MelsecF.WritePLCreg(Address,Value);
    Telemechan : Telemec.SetRegister(Address,Integer(Value));
    Satt       : SattCon.SetIORAM(Address,Value);
    IPC_620    : IPC620.PresetSingleReg(Address,Value);
    Siemens6b  : Siemens.SetRegister(Address,Integer(Value));
  END;
{$ENDIF}
  Check4Errors;
END;{PROC PLCSetRegister}

FUNCTION PLCError:Integer;
BEGIN
  PLCError:=PLCErrorValue;
  PLCErrorValue:=0;
END;{FUNC PLCError}

FUNCTION PLCErrorMsg(i:Integer):String;
BEGIN
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Siemens6b  : PLCErrorMsg:=SiemensErrorMsg(i);
  ELSE
{$ENDIF}

    PLCErrorMsg:='Error '+IntStr(i,0);

{$IFNDEF NoSerial}
  END;
{$ENDIF}
END; {FUNCTION PLCErrorMsg}

PROCEDURE PLCdirectControl(Hi2,Hi1,Lo2,Lo1:Byte);
BEGIN
  CASE PLCModel OF
    Modicon884,
    Modicon484 : BEGIN
                   {Not Implemented}
                 END;
    MelsecF1   : BEGIN
                   {Not Implemented}
                 END;
    Telemechan : BEGIN
                   {Not Implemented}
                 END;
    Satt       : BEGIN
                   {Not Implemented}
                 END;
    IPC_620    : BEGIN
                   {Not Implemented}
                 END;
    Siemens6b  : BEGIN
                   {Not Implemented}
                 END;
  END;
  Check4Errors;
END;{PROC PLCdirectControl}

PROCEDURE DisconnectPLC;
BEGIN
{$IFNDEF NoSerial}
  CASE PLCModel OF
    Modicon484,
    Modicon884 : Modbus.DisconnectModbus;
    MelsecF1   : MelsecF.DisconnectPLC;
    Telemechan : Telemec.DisconnectTelemec;
    Satt       : SattCon.DisconnectSattCon;
    IPC_620    : IPC620.DisconnectIPC620;
    Siemens6b  : Siemens.DisconnectSiemens;
  END;
{$ENDIF}
  PLCerrorValue:=0;
END;{PROC DisconnectPLC}

VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}

PROCEDURE PLCIFExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitHandler;
  DisconnectPLC;
  Units.Leave(PLCIFMsg,MemAvail);
END; {PROC PLCIFExitHandler}

BEGIN {Init Unit PLCIF}
  PrevExitHandler:=ExitProc;
  ExitProc:=@PLCIFExitHandler;
  Units.Enter(PLCIFMsg,MemAvail,CSeg);
END.
