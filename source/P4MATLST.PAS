UNIT P4MatLst; {Tunnel Material List}
{$I CODEDEFS.PAS}
{$X+}

INTERFACE
USES
  Dos, P4Config, Objects, LFString;

TYPE
  DimStr = String[7];

TYPE
  pPacket = ^Packet;
  Packet = OBJECT(TObject)
    PacketNo : LongInt;
    Dim      : DimStr;
    CONSTRUCTOR Init(VAR NewPackNo:LongInt; NewDim:DimStr);
    PROCEDURE Assign(VAR NewPackNo:LongInt; NewDim:DimStr);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE Store(VAR S:TStream); VIRTUAL;
    FUNCTION asString:String;
  END; {OBJ Packet}

CONST
  PacketsPerRank = 3;
  in_LoadZone   = -1;
  in_InZone     = 1;
  in_UnLoadZone = 0;

TYPE
  pRank = ^Rank;
  Rank = OBJECT(TCollection)
    Date : DateTime;
    Empty : Boolean;
    CONSTRUCTOR Init(Pack1, Pack2, Pack3 : pPacket; _Empty:Boolean);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE Store(VAR S:TStream); VIRTUAL;
    FUNCTION  asString:String;
    FUNCTION  Edit(VAR CurrPackNum:LongInt; VAR CurrDim:String):Boolean;
  END; {OBJ Rank}

CONST
  LoadingZone   = 1;
  DryingZone    = 2;
  UnloadingZone = 3;

TYPE
  pRankZone = ^RankZone;
  RankZone = OBJECT(TCollection)
    ZoneType,
    Max : Integer;
    CONSTRUCTOR Init(NewMax,NewZoneType:Integer);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE Store(VAR S:TStream); VIRTUAL;
    FUNCTION  LoadIn(n:pRank):pRank;
    FUNCTION  Unload:pRank;
    PROCEDURE BuildReport(VAR Rpt:pReport);
    PROCEDURE SetMax(NewMax:Integer);
  END;

TYPE
  pRankList = ^RankList;
  RankList = OBJECT(TObject)
    Rpt : pReport;        {Volatile}
    LoadZone,
    InZone,
    UnLoadZone : pRankZone;
    PacketNo  : LongInt;
    CONSTRUCTOR Init(Cfg:pTunnelCfg);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE SetZoneCount(Cfg:pTunnelCfg);
    PROCEDURE Store(VAR S:TStream); VIRTUAL;
    PROCEDURE LoadZoneAdd(n:pRank);
    PROCEDURE InZoneAdd(n:pRank);
    PROCEDURE UnloadZoneAdd(n:pRank);
    PROCEDURE DescribeNewPacket;
    PROCEDURE LoadPacketInTunnel;
    PROCEDURE AdvanceInTunnel;
    PROCEDURE RemoveFromUnload;
    PROCEDURE BuildReport;
    PROCEDURE Edit;
  END; {OBJ RankList}



IMPLEMENTATION

USES
  AGTools, LFDos, ObjInput, LFGfxWin;

CONST
  Rank_OID = 10040;
  Rank_OSR: TStreamRec = (
    ObjType: Rank_OID;
    VmtLink: Ofs(TypeOf(Rank)^);
    Load:    @Rank.Load;
    Store:   @Rank.Store
  );

  Packet_OID = 10041;
  Packet_OSR: TStreamRec = (
    ObjType: Packet_OID;
    VmtLink: Ofs(TypeOf(Packet)^);
    Load:    @Packet.Load;
    Store:   @Packet.Store
  );



{---------------------------------------------------------- Packet ---}

CONSTRUCTOR Packet.Init(VAR NewPackNo:LongInt; NewDim:DimStr);
BEGIN
  TObject.Init;
  Assign(NewPackNo, NewDim);
END; {CONS Packet.Init}

CONSTRUCTOR Packet.Load(VAR S:TStream);
BEGIN
  TObject.Init;
  S.Read(PacketNo, SizeOf(PacketNo));
  S.Read(Dim, SizeOf(Dim));
END; {CONS Packet.Load}

PROCEDURE Packet.Store(VAR S:TStream);
BEGIN
  S.Write(PacketNo, SizeOf(PacketNo));
  S.Write(Dim, SizeOf(Dim));
END; {PROC Packet.Store}

PROCEDURE Packet.Assign(VAR NewPackNo:LongInt; NewDim:DimStr);
BEGIN
  PacketNo:=NewPackNo;
  Inc(NewPackNo);
  Dim:=NewDim;
END; {PROC Packet.Assign}

FUNCTION Packet.AsString:String;
BEGIN
  AsString:=IntStr(PacketNo,6)+PadLeading(Dim,' ',10);
END; {FUNCTION Packet.AsString}


{-------------------------------------------------------------- Rank ---}

CONSTRUCTOR Rank.Init(Pack1, Pack2, Pack3 : pPacket; _Empty:Boolean);
BEGIN
  TCollection.Init(PacketsPerRank,0);
  Empty:=_Empty;
  IF not Empty
  THEN BEGIN
    Insert(Pack1);
    Insert(Pack2);
    Insert(Pack3);
  END;
END; {CONS Rank.Init}

FUNCTION Rank.Edit(VAR CurrPackNum:LongInt; VAR CurrDim:String):Boolean;
VAR
  i      : Integer;
  Fields : pFieldList;
  Win    : PGfxWin;

  PROCEDURE CreFields(p:pPacket); FAR;
  VAR
     n  : pIntInput;
     s  : pStrInput;
  BEGIN
    New(n, Init(Win^.WorkSpace, 8, i, 5, 1, p^.PacketNo, 65000));
    Fields^.Add(p^.PacketNo, n);
    New(s, Init(Win^.WorkSpace, 15, i, 7, p^.Dim,[#32..#127],False));
    Fields^.Add(p^.Dim, s);
    Inc(i);
  END;

  PROCEDURE FetchField(p:pPacket); FAR;
  BEGIN
    Fields^.Fetch(p^.PacketNo);
    CurrPackNum:=p^.PacketNo;
    Fields^.Fetch(p^.Dim);
    CurrDim:=p^.Dim;
  END;
VAR
  PrevExit : CharSet;
BEGIN
  New(Win, InitTxt(27,14,30,6,True));
  Win^.Title(Lookup('PACKEDIT1'), Lookup('ESC=EXIT'));
  New(Fields,Init);
  Fields^.Add(i, New(pStrDisplay, Init(Win^.WorkSpace, 8,1,20,'Nr.    Dimensjon')));
  i:=2;
  ForEach(@CreFields);

  Win^.Open;
  Fields^.Display;
  PrevExit:=EdExitSet;
  EdExitSet:=[Esc, F9];
  Fields^.Edit;
  EdExitSet:=PrevExit;
  Win^.Close;
  CASE Fields^.LastChar OF
    Esc : Edit:=False;
    ELSE BEGIN
      ForEach(@FetchField);
      Edit:=True;
    END;
  END;
  Dispose(Fields, Done);
  Dispose(Win, Done);
END; {PROC Rank.Edit}

CONSTRUCTOR Rank.Load(VAR S:TStream);
BEGIN
  TCollection.Load(S);
  S.Read(Date, SizeOf(Date));
  S.Read(Empty, SizeOf(Empty));
END; {CONS Rank.Load}

PROCEDURE Rank.Store(VAR S:TStream); 
BEGIN
  TCollection.Store(S);
  S.Write(Date, SizeOf(Date));
  S.Write(Empty, SizeOf(Empty));
END; {PROC Rank.Store}

FUNCTION Rank.AsString:String;
VAR
  S : String;
  PROCEDURE AddString(P:pPacket); FAR;
  BEGIN
    IF S<>''
    THEN S:=S+'   ';
    S:=S+P^.asString
  END;
BEGIN
  IF Empty
  THEN S:=''
  ELSE BEGIN
    S:='';
    ForEach(@AddString);
    IF Date.Month=0
    THEN S:='            '+S
    ELSE S:=LookWatch(Date)+' '+S;
  END;
  AsString:=S;
END; {PROC Rank.AsString}


{---------------------------------------------------------- RankZone ---}

CONSTRUCTOR RankZone.Init(NewMax,NewZoneType:Integer);
BEGIN
  TCollection.Init(20,10);
  ZoneType:=NewZoneType;
  SetMax(NewMax);
END; {CONS RankZone.Init}

CONSTRUCTOR RankZone.Load(VAR S:TStream);
BEGIN
  TCollection.Load(S);
  S.Read(ZoneType, SizeOf(ZoneType));
  S.Read(Max, SizeOf(Max));
END; {CONS RankZone.Load}

PROCEDURE RankZone.Store(VAR S:TStream);
BEGIN
  TCollection.Store(S);
  S.Write(ZoneType, SizeOf(ZoneType));
  S.Write(Max, SizeOf(Max));
END; {PROC RankZone.Store}

PROCEDURE RankZone.BuildReport(VAR Rpt:pReport);
VAR
  i : Integer;
  PROCEDURE AddLine(P:pRank); FAR;
  VAR
    sn : String[3];
  BEGIN
    CASE ZoneType OF
      LoadingZone,
      DryingZone    : sn:=IntStr(i,3);
      UnloadingZone : sn:='   ';
    END;
    Rpt^.AddLn(sn+' :  '+P^.AsString);
    Inc(i);
  END; {LOCAL PROC AddLine}
BEGIN
  i:=-Max;
  IF (ZoneType = LoadingZone)
  THEN BEGIN
    IF (Count<max)
    THEN WHILE i<-Count DO
    BEGIN
      Rpt^.AddLn(IntStr(i,3)+' : ');
      Inc(i);
    END
  END ELSE i:=1;
  ForEach(@AddLine);
END; {PROC RankZone.BuildReport}

PROCEDURE RankZone.SetMax(NewMax:Integer);
VAR
  i : Integer;
BEGIN
  Max:=NewMax;
  IF Max<0 THEN Max:=0
  ELSE IF Max>50 THEN Max:=50;
{$IFNDEF NoDebug}
{  AddToLog('SetMax: '+IntStr(NewMax,3)+IntStr(max,6));}
{$ENDIF}
  WHILE Count>Max
  DO AtFree(Count-1);
  IF ZoneType = DryingZone
  THEN BEGIN
    i:=Max-Count;
    WHILE i>0
    DO BEGIN
      Insert(New(pRank, Init(nil,nil,nil, True)));
      Dec(i);
    END;
  END;
END; {PROC RankZone.SetMax}

FUNCTION RankZone.LoadIn(n:pRank):pRank;
VAR
  p : pRank;
BEGIN
  IF (ZoneType<>LoadingZone) and (not n^.Empty)
  THEN StartWatch(n^.Date);
  IF Count=Max
  THEN BEGIN
    p:=At(Count-1);
    AtDelete(Count-1);
  END
  ELSE p:=nil;
  AtInsert(0, n);
  LoadIn:=p;
END; {FUNCTION RankZone.LoadIn}

FUNCTION RankZone.UnLoad:pRank;
VAR
  p : pRank;
BEGIN
  IF Count>0
  THEN BEGIN
    p:=At(Count-1);
    AtDelete(Count-1);
  END
  ELSE p:=nil;
  UnLoad:=p;
END; {FUNC RankZone.UnLoad}

{---------------------------------------------------------- RankList ---}

CONSTRUCTOR RankList.Init(Cfg:pTunnelCfg);
BEGIN
  TObject.Init;
  New(LoadZone, Init(Cfg^.MaxEnterRanks, LoadingZone));
  New(InZone, Init(Cfg^.MaxTunnelRanks, DryingZone));
  New(UnLoadZone, Init(Cfg^.MaxExitRanks, UnloadingZone));
  PacketNo:=1;
END; {CONS RankList.Init}

CONSTRUCTOR RankList.Load(VAR S:TStream);
BEGIN
  TObject.Init;
  New(LoadZone, Load(S));
  New(InZone, Load(S));
  New(UnLoadZone, Load(S));
  S.Read(PacketNo, SizeOf(PacketNo));
END; {CONS RankList.Load}

PROCEDURE RankList.SetZoneCount(Cfg:pTunnelCfg);
BEGIN
  LoadZone^.SetMax(Cfg^.MaxEnterRanks);
  InZone^.SetMax(Cfg^.MaxTunnelRanks);
  UnLoadZone^.SetMax(Cfg^.MaxExitRanks);
END; {PROC RankList.SetZoneCount}

PROCEDURE RankList.Store(VAR S:TStream);
BEGIN
  LoadZone^.Store(S);
  InZone^.Store(S);
  UnLoadZone^.Store(S);
  S.Write(PacketNo, SizeOf(PacketNo));
END; {PROC RankList.Store}

PROCEDURE RankList.LoadZoneAdd(n:pRank);
VAR
  p : pRank;
BEGIN
  p:=LoadZone^.LoadIn(n);
  IF p<>nil
  THEN InZoneAdd(p);
END; {PROC RankList.LoadZoneAdd}

PROCEDURE RankList.InZoneAdd(n:pRank);
VAR
  p : pRank;
BEGIN
  p:=InZone^.LoadIn(n);
  IF p<>nil
  THEN UnLoadZoneAdd(p);
END; {PROC RankList.InZoneAdd}

PROCEDURE RankList.UnloadZoneAdd(n:pRank);
VAR
  p : pRank;
BEGIN
  IF Not n^.Empty
  THEN BEGIN
    p:=UnloadZone^.LoadIn(n);
    IF p<>nil
    THEN Dispose(p, Done);
  END ELSE Dispose(n, Done);
END; {PROC RankList.UnloadZoneAdd}


PROCEDURE RankList.DescribeNewPacket;
CONST
  LastText : String[7] = '150x100';
VAR
  PrevPacketNo : LongInt;
  nr : pRank;
  p1,p2,p3 : pPacket;
BEGIN
  PrevPacketNo:=PacketNo;
  New(p1, Init(PacketNo, LastText));
  New(p2, Init(PacketNo, LastText));
  New(p3, Init(PacketNo, LastText));

  New(nr, Init(p1,p2,p3,False));
  IF nr^.Edit(PacketNo, LastText)
  THEN BEGIN
    LoadZoneAdd(nr);
    Inc(PacketNo);
  END
  ELSE BEGIN
    Dispose(nr, Done);
    PacketNo:=PrevPacketNo;
  END;
  BuildReport;
END; {PROC RankList.DescribeNewPacket}

PROCEDURE RankList.LoadPacketInTunnel;
VAR
  p : pRank;
BEGIN
  p:=LoadZone^.Unload;
  IF p=nil
  THEN p:=New(pRank, Init(nil,nil,nil,True));
  InZoneAdd(p);
  BuildReport;
END; {PROC RankList.LoadPacketInTunnel}

PROCEDURE RankList.AdvanceInTunnel;
BEGIN
  InZoneAdd(New(pRank, Init(nil, nil, nil, True)));
  BuildReport;
END; {PROC RankList.AdvanceInTunnel}

PROCEDURE RankList.RemoveFromUnload;
VAR
  p : pRank;
BEGIN
  p:=UnloadZone^.Unload;
  IF p<>nil
  THEN Dispose(p, Done);
  BuildReport;
END; {PROC RankList.RemoveFromUnload}

PROCEDURE RankList.BuildReport;
BEGIN
  IF Rpt<>nil
  THEN Dispose(Rpt, Done);
  New(Rpt, Init);
  Rpt^.AddLn('Ranke  Dato   Kl.     Nr.   Dim.         Nr.   Dim.         Nr.   Dim.');
  Rpt^.AddLn(Rep(76, 'Í'));
  LoadZone^.BuildReport(Rpt);
  Rpt^.AddLn(Rep(76, 'Ä'));
  InZone^.BuildReport(Rpt);
  Rpt^.AddLn(Rep(76, 'Ä'));
  UnLoadZone^.BuildReport(Rpt);
  Rpt^.AddLn(Rep(76, 'Í'));
END; {PROC RankList.BuildReport}

PROCEDURE RankList.Edit;
VAR
  t,i      : Integer;
  Key     : PKeystroke;
BEGIN
  PutMsg(LookUp('MATRCMD1'), LookUp('MATRCMD2'));
  New(Key,Init(WorkSpace,1,1,[Esc,'P',^M,^E,^X,^R,^C,F7..F10],True));
  BuildReport;
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
      F7 : DescribeNewPacket;
      F8 : LoadPacketInTunnel;
      F9 : AdvanceInTunnel;
      F10 : RemoveFromUnload;
      'P': BEGIN
             IF PrintHeader
             THEN Rpt^.Output('PRN');
             PrintFooter;
           END;
    END;
    IF t<1 THEN t:=1
    ELSE IF t>Rpt^.Count THEN t:=Rpt^.Count;
  UNTIL (Key^.LastChar=Esc);
  Dispose(Rpt, Done);
  Rpt:=nil;
  Dispose(Key,Done);
END; {PROC RankList.Edit}

BEGIN
  RegisterType(Rank_OSR);
  RegisterType(Packet_OSR);
END.
