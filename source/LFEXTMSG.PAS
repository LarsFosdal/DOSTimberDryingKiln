(*
 *** External Message-file Format ********************************************
 *
 * @-Block commands must start in first column.
 * Parameters within square brackets [] are optional
 *
 * |-mark (Delimiter char) in texts must be @#-coded (@#124) !
 * Last |-mark on line is Optional
 * Exception: Line with remarks must have last |-mark
 * Example:
 *  |Text line without Remark
 *  |This is a Text line which have a| remark.
 *
 * - Change of Delimiter char (Default = |)
 * @DELIMITER [char]
 * "char" may be any printable char like "|","\","/",""","'" etc.,
 * except "@" and ";"
 * IF "char" is omitted, the delimiter is reset to "|".
 * Example:
 *   @DELIMITER :
 *   will change delimiter char to ":"
 * Remember that the ":"-chars after this point must be @# coded in the text.
 *
 * - Message buffering: How to keep message for retrieval
 * @BUFFER [BufferType]
 * "BufferType" may be one of the following: Memory (Default), or Disk
 * When memory buffering is used, all message info is kept in memory.
 * When disk buffering is used, only indexes are kept in memory.
 * Message info. will then be retrieved from disk upon request.
 *
 * - One-line messages (Prompts etc.)
 * @PROMPTS
 * ID1 | Message Text 1|
 * ID2 | Message Text 2|
 * ID3 | Message Text 3|
 * @END
 *
 * - Multi-line messages (Descriptions e.a.)
 * @TXT ID
 * | Message Text |
 * | Another Line |
 * ||                    Blank Line
 * | ... Last Line |
 * @END
 *
 * - Multi-line Help entries with references
 * [HelpID] = Optional Group reference
 * @HLP ID [HelpID] | Title |
 * | Help Text |
 * | Another Line @{helpID,|Ref.text|} with a reference |
 * | ... Last Line |
 * @END
 *
 * - Multi-line Menus
 * @MNU ID | Title |
 * | First Choice |
 * | Second Choice |
 * | ... Last Choice |
 * @END
 *
 * - End of definitions
 * @STOP
 *   Everything after the @STOP-command is ignored
 *
 * Remarks on separate lines must start with a semicolon (;).
 * Remarks are also allowed after last | on each line within a block.
 *
 * @#Decimal will be replaced with its character (@#13 = CR)
 * Empty lines, leading and trailing spaces of line and ID, will be ignored.
 *
 * ID's may contain any characters except |{} (pipe,curly brackets)
 * and spaces.
 * ID's are not case-sensitive, but must be Unique !
 * Exception: HELP ID's may have the same ID's as PROMPTS,TEXTS and MENUS.
 *
 * @-block commands are not case sensitive.
 * Also, you don't need to complete them, first letter is sufficient
 * (although completion is recommended as this may change in the future).
 ****************************************************************************
 *)

{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT LFextmsg; {.1.5 910318}

INTERFACE
USES
  LFsystem,Dos,Objects,LFString;

CONST
  ExtMsgHeader : String = 'LFExtMsg v1.5 - (c) 1991 Lars Fosdal '+^M^J+
                          'External Message System.'^M^J^Z; {TStream header}
CONST
  NoID     = '@@NOID@@';

TYPE
  TablePtr = ^Table;           { - Generic Table}
  Table = OBJECT(TCollection)
    CONSTRUCTOR Init;
    PROCEDURE   Dump(Rprt:PReport);
    FUNCTION    Empty:Boolean;
    PROCEDURE   Store(VAR S:TStream);
    FUNCTION    IsActive(ix:Integer):Boolean;
    PROCEDURE   Enable(ix:Integer);
    PROCEDURE   Disable(ix:Integer);
  END; {OBJ Table}

  TabEntryPtr = ^TableEntry;   { - Text Table Entry}
  TableEntry = OBJECT(TObject)
    Txt : PString;
    Active : Boolean;
    CONSTRUCTOR Init(TheTxt:String);
    DESTRUCTOR  Done;                 VIRTUAL;
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream); VIRTUAL;
    PROCEDURE   Dump(Rprt:PReport);   VIRTUAL;
    PROCEDURE   Enable;
    PROCEDURE   Disable;
  END;{OBJ TableEntry}

  RefEntryPtr = ^RefTableEntry;  { - Text w/Reference Table Entry}
  RefTableEntry = OBJECT(TableEntry)
    Ref : TablePtr;
    CONSTRUCTOR Init(TheTxt:String; TheRef:TablePtr);
    DESTRUCTOR  Done;                            VIRTUAL;
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);             VIRTUAL;
    PROCEDURE   Dump(Rprt:PReport);                            VIRTUAL;
  END;{OBJ RefTableEntry}

  PMsgNode = ^MsgNode;
  MsgNode = OBJECT(TObject)
    ID : PString;
    CONSTRUCTOR Init(NewEntry:String);
    DESTRUCTOR  Done;                            VIRTUAL;
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);            VIRTUAL;
    PROCEDURE   Dump(Rprt:PReport);              VIRTUAL;
  END; {OBJ MsgNode}

  RefLstPtr = ^RefLstEntry;    { - Reference Table Entry}
  RefLstEntry = OBJECT(MsgNode)
    Starts : Integer;
    Length : Integer;
    CONSTRUCTOR Init(NewTag:String; p,w:Integer);
    DESTRUCTOR  Done;                            VIRTUAL;
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);            VIRTUAL;
    PROCEDURE   Dump(Rprt:PReport);                            VIRTUAL;
  END;{OBJ HlpRefEntry}

  RefChkPtr = ^RefChkEntry;    { - Compile Reference check Table Entry}
  RefChkEntry = OBJECT(MsgNode)
    Hlp  : PString;
    Line : LongInt;
    CONSTRUCTOR Init(HlpTag,RefTag:String; AtLine:LongInt);
    DESTRUCTOR  Done;                            VIRTUAL;
  END;{OBJ HlpRefEntry}

  EntryPtr = ^IndexEntry;      { - Basic External text index entry}
  IndexEntry = OBJECT(MsgNode)
    Extern    : Boolean; {True if message must be loaded from TStream}
    StreamPos : LongInt; {Position of message in TStream (if external)}
    CONSTRUCTOR Init(NewEntry:String);
    DESTRUCTOR  Done;                            VIRTUAL;
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);             VIRTUAL;
    PROCEDURE   Dump(Rprt:PReport);                            VIRTUAL;
  END;{OBJ IndexEntry}

  PMsgTxt = ^MsgTxt;          { - One-liner message}
  MsgTxt = OBJECT(IndexEntry)
    MesText : PString;     {Msg text}
    CONSTRUCTOR Init(NewEntry,Msg:String);
    DESTRUCTOR  Done;                            VIRTUAL;
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);             VIRTUAL;
    FUNCTION    Message:String;
    PROCEDURE   Dump(Rprt:PReport);                            VIRTUAL;
  END;{OBJ MsgTxt}

  PTextTxt = ^TextTxt;          { - Multi-line text message }
  TextTxt = OBJECT(IndexEntry)
    Txts     : Table;
    CONSTRUCTOR Init(NewEntry:String);
    DESTRUCTOR  Done;                            VIRTUAL;
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);             VIRTUAL;
    PROCEDURE   AddLine(Txt:String);             VIRTUAL;
    FUNCTION    AtLine(Num:Integer):EntryPtr;
    FUNCTION    TextAtLine(Num:Integer):String;
    FUNCTION    PTextAtLine(Num:Integer):PString;
    FUNCTION    LineIsActive(ix:Integer):Boolean;
    PROCEDURE   LineEnable(ix:Integer);
    PROCEDURE   LineDisable(ix:Integer);
    PROCEDURE   BreakLine;                       VIRTUAL;
    FUNCTION    Lines:Integer;
    PROCEDURE   Dump(Rprt:PReport);                            VIRTUAL;
  END;{OBJ TextTxt}

  PMenuTxt = ^MenuTxt;          { - Multi-line Menu w/title Message}
  MenuTxt = OBJECT(TextTxt)
    Title : PString;
    CONSTRUCTOR Init(NewEntry,TheTitle:String);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);             VIRTUAL;
    DESTRUCTOR  Done;                            VIRTUAL;
    PROCEDURE   BreakLine;                       VIRTUAL;
    PROCEDURE   Dump(Rprt:PReport);                            VIRTUAL;
  END;{OBJ MenuTxt}

  PHelpTxt = ^HelpTxt;          { - Multi-line Help w/Ref Message}
  HelpTxt = OBJECT(MenuTxt)
    GroupRef : PString;
    CONSTRUCTOR Init(NewEntry,Group,TheTitle:String);
    CONSTRUCTOR Load(VAR S:TStream);
    PROCEDURE   Store(VAR S:TStream);             VIRTUAL;
    DESTRUCTOR  Done;                            VIRTUAL;
    PROCEDURE   BreakLine;                       VIRTUAL;
    PROCEDURE   AddLineRef(TheLine:String; TheRef:TablePtr);
    PROCEDURE   Dump(Rprt:PReport);                            VIRTUAL;
  END;{OBJ MenuTxt}

  PMsgIndex = ^MsgIndex;     { - External Message Index }
  MsgIndex = OBJECT(TSortedCollection)
    Rprt    : PReport;
    CONSTRUCTOR Compile(SourceName,StreamName,ListName:PathStr);
    CONSTRUCTOR Load(StreamName:PathStr);
    DESTRUCTOR  Done;                           VIRTUAL;
    FUNCTION    Compare(A,B:Pointer):Integer;   VIRTUAL;
    PROCEDURE   Save(StreamName:PathStr);       VIRTUAL;
    FUNCTION    Find(WhatEntry:String):EntryPtr;
    FUNCTION    FindMsg(WhatEntry:String):PMsgTxt;
    FUNCTION    FindText(WhatEntry:String):PTextTxt;
    FUNCTION    FindMenu(WhatEntry:String):PMenuTxt;
    FUNCTION    FindHelp(WhatEntry:String):PHelpTxt;
    FUNCTION    Connect(WhatEntry:String;VAR ConnectTo:EntryPtr):Boolean;
    PROCEDURE   Dump; VIRTUAL;
  END;{OBJ MsgIndex}

TYPE
  ExtMsgErrorProc = PROCEDURE (MsgID,ErrorMsg:String);

PROCEDURE RegisterExtMsg;

VAR
  Msg : PMsgIndex;
  ExtMsgError : ExtMsgErrorProc;

{############################################################################}

IMPLEMENTATION
USES
  Crt,LFdos,LFcrt,LFTable;

CONST
  Indent = 16;

CONST
  MsgIndex_OID      = 9000;
  MsgIndex_OSR: TStreamRec = (
    ObjType: MsgIndex_OID;
    VmtLink: Ofs(TypeOf(MsgIndex)^);
    Load:    @MsgIndex.Load;
    Store:   @MsgIndex.Store
  );

CONST
  Table_OID         = 9001;
  Table_OSR: TStreamRec = (
    ObjType: Table_OID;
    VmtLink: Ofs(TypeOf(Table)^);
    Load:    @TCollection.Load;
    Store:   @Table.Store
  );

CONST
  TableEntry_OID    = 9002;
  TableEntry_OSR: TStreamRec = (
    ObjType: TableEntry_OID;
    VmtLink: Ofs(TypeOf(TableEntry)^);
    Load:    @TableEntry.Load;
    Store:   @TableEntry.Store
  );

CONST
  RefTableEntry_OID = 9003;
  RefTableEntry_OSR: TStreamRec = (
    ObjType: RefTableEntry_OID;
    VmtLink: Ofs(TypeOf(RefTableEntry)^);
    Load:    @RefTableEntry.Load;
    Store:   @RefTableEntry.Store
  );

CONST
  MsgNode_OID = 9004;
  MsgNode_OSR: TStreamRec = (
    ObjType: MsgNode_OID;
    VmtLink: Ofs(TypeOf(MsgNode)^);
    Load:    @MsgNode.Load;
    Store:   @MsgNode.Store
  );

CONST
  RefLstEntry_OID   = 9005;
  RefLstEntry_OSR: TStreamRec = (
    ObjType: RefLstEntry_OID;
    VmtLink: Ofs(TypeOf(RefLstEntry)^);
    Load:    @RefLstEntry.Load;
    Store:   @RefLstEntry.Store
  );

CONST
  IndexEntry_OID    = 9006;
  IndexEntry_OSR: TStreamRec = (
    ObjType: IndexEntry_OID;
    VmtLink: Ofs(TypeOf(IndexEntry)^);
    Load:    @IndexEntry.Load;
    Store:   @IndexEntry.Store
  );

CONST
  MsgEntry_OID      = 9007;
  MsgEntry_OSR: TStreamRec = (
    ObjType: MsgEntry_OID;
    VmtLink: Ofs(TypeOf(MsgTxt)^);
    Load:    @MsgTxt.Load;
    Store:   @MsgTxt.Store
  );

CONST
  TxtEntry_OID      = 9008;
  TxtEntry_OSR: TStreamRec = (
    ObjType: TxtEntry_OID;
    VmtLink: Ofs(TypeOf(TextTxt)^);
    Load:    @TextTxt.Load;
    Store:   @TextTxt.Store
  );

CONST
  MnuEntry_OID      = 9009;
  MnuEntry_OSR: TStreamRec = (
    ObjType: MnuEntry_OID;
    VmtLink: Ofs(TypeOf(MenuTxt)^);
    Load:    @MenuTxt.Load;
    Store:   @MenuTxt.Store
  );

CONST
  HlpEntry_OID      = 9010;
  HlpEntry_OSR: TStreamRec = (
    ObjType: HlpEntry_OID;
    VmtLink: Ofs(TypeOf(HelpTxt)^);
    Load:    @HelpTxt.Load;
    Store:   @HelpTxt.Store
  );


{--- Stream Object Registration ---------------------------------------------}

PROCEDURE RegisterExtMsg;
{ - Register object types to be stored in IndexStream
 IMPORTANT !!!
 ! If you change the objects themselves or the Registration order,
 ! any old ObjectStream file will not be readable.
}
BEGIN
  RegisterType(MsgIndex_OSR);
  RegisterType(TableEntry_OSR);
  RegisterType(RefTableEntry_OSR);
  RegisterType(MsgNode_OSR);
  RegisterType(RefLstEntry_OSR);
  RegisterType(IndexEntry_OSR);
  RegisterType(MsgEntry_OSR);
  RegisterType(TxtEntry_OSR);
  RegisterType(MnuEntry_OSR);
  RegisterType(HlpEntry_OSR);
END; {PROC RegisterExtMsg}

{=== Lookup/Referenceing objects ============================================}

{--- Methods for object : TableEntry / Table --------------------------------}
{*
 *  Text list objects, used by Text and Menu message index objects
 *}

CONSTRUCTOR TableEntry.Init(TheTxt:String);
{ - Prepare text table entry}
BEGIN
  TObject.Init;
  Active:=True;
  PSNew(Txt,TheTxt);
END; {CONS TableEntry.Init}

CONSTRUCTOR TableEntry.Load(VAR S:TStream);
{ - Load Text table Entry from TStream}
BEGIN
  TObject.Init;
  Active:=True;
  Txt:=S.ReadStr;
  IF S.Status<>0 THEN Fail;
END; {CONS TableEntry.Load}

DESTRUCTOR TableEntry.Done;
{ - DeAllocate text table entry}
BEGIN
  PSDispose(Txt);   {Release Allocated message space}
  TObject.Done;
END; {DEST TableEntry.Done}

PROCEDURE TableEntry.Store(VAR S:TStream);
{ - Store Text table entry to TStream}
BEGIN
  S.WriteStr(Txt);
END; {PROC TableEntry.Store}

PROCEDURE TableEntry.Dump(Rprt:PReport);
BEGIN
  IF Txt=nil
  THEN Rprt^.AddLn(Rep(Indent,' ')+'*NIL')
  ELSE Rprt^.AddLn(Rep(Indent,' ')+'"'+Txt^+'"');
END; {PROC TableEntry.Dump}

PROCEDURE TableEntry.Enable;
BEGIN
  Active:=True;
END; {PROC TableEntry.Enable}

PROCEDURE TableEntry.Disable;
BEGIN
  Active:=False;
END; {PROC TableEntry.Disable}

{--- Methods for object : RefTableEntry -------------------------------------}
{*
 *  Referenced text-list object
 *}

CONSTRUCTOR RefTableEntry.Init(TheTxt:String; TheRef:TablePtr);
{ - Prepare text table entry w/references }
BEGIN
  TObject.Init;
  TableEntry.Init(TheTxt);
  Ref:=TheRef;
END; {CONS RefTableEntry.Init}

CONSTRUCTOR RefTableEntry.Load(VAR S:TStream);
{ - Load Text table Entry from TStream}
VAR
  Any : Boolean;
BEGIN
  TObject.Init;
  TableEntry.Load(S);
  S.Read(Any,1);
  IF Any
  THEN New(Ref,Load(S))
  ELSE New(Ref,Init);
  IF S.Status<>0 THEN Fail;
END; {CONS RefTableEntry.Load}

DESTRUCTOR RefTableEntry.Done;
{ - DeAllocate text table entry}
BEGIN
  Dispose(Ref,Done);
  TableEntry.Done;
END; {DEST RefTableEntry.Done}

PROCEDURE RefTableEntry.Store(VAR S:TStream);
{ - Store Text table entry to TStream}
VAR
  Any : Boolean;
BEGIN
  TableEntry.Store(S);
  Any:=(Ref^.Count<>0);
  S.Write(Any,1);
  IF Any
  THEN Ref^.Store(S);
END; {PROC RefTableEntry.Store}

PROCEDURE RefTableEntry.Dump(Rprt:PReport);
BEGIN
  Rprt^.Add(Rep(Indent,' ')+'"'+Txt^+'"');
  IF Not Ref^.Empty
  THEN BEGIN
    Rprt^.Add('  Ref:');
    Ref^.Dump(Rprt);
  END;
  Rprt^.NewLn;
END; {PROC RefTableEntry.Dump}

{--- Methods for object : RefEntry / RefTable -------------------------------}
{*
 *  Help reference list object, used by RefTableEntry
 *}

CONSTRUCTOR RefLstEntry.Init(NewTag:String; p,w:Integer);
{ - Prepare text Ref entry}
BEGIN
  UpSt(NewTag);
  MsgNode.Init(NewTag);
  Starts:=p;
  Length:=w;
END; {CONS RefLstEntry.Init}

CONSTRUCTOR RefLstEntry.Load(VAR S:TStream);
{ - Load Help Ref. Entry from TStream}
VAR
  Bytes : Byte;
BEGIN
  MsgNode.Load(S);
  S.Read(Starts,SizeOf(Starts));
  S.Read(Length,SizeOf(Length));
  IF S.Status<>0 THEN Fail;
END; {CONS RefLstEntry.Load}

DESTRUCTOR RefLstEntry.Done;
{ - DeAllocate Help Ref. entry}
BEGIN
  MsgNode.Done;
END; {DEST RefLstEntry.Done}

PROCEDURE ReflstEntry.Store(VAR S:TStream);
{ - Store Help Ref. entry to TStream}
BEGIN
  MsgNode.Store(S);
  S.Write(Starts,SizeOf(Starts));
  S.Write(Length,SizeOf(Length));
END; {PROC RefLstEntry.Store}

PROCEDURE RefLstEntry.Dump(Rprt:PReport);
BEGIN
  Rprt^.Add(' '+ID^);
END; {PROC RefLstEntry.Dump}

{--- Methods for object : RefChkEntry ---------------------------------------}
{*
 *  Help reference list object, used by MsgIndex.Compile
 *  to look for missing references
 *}

CONSTRUCTOR RefChkEntry.Init(HlpTag,RefTag:String; AtLine:LongInt);
{ - Prepare text Ref entry}
BEGIN
  MsgNode.Init(RefTag);
  PSNew(Hlp,HlpTag); UpSt(Hlp^); {Allocate and convert to uppercase}
  Line:=AtLine;
END; {CONS RefChkEntry.Init}

DESTRUCTOR RefChkEntry.Done;
{ - DeAllocate Help Ref. entry}
BEGIN
  PSDispose(Hlp);
  MsgNode.Done;
END; {DEST RefChkEntry.Done}

{--- Methods for object : Table ---- ----------------------------------------}
{*
 * This is a generic list-table object
 *}

CONSTRUCTOR Table.Init;
{ - Prepare text table }
BEGIN
  TCollection.Init(5,5);
END; {CONS Table.Init}

PROCEDURE Table.Store(VAR S:TStream);
BEGIN
  Pack;
  SetLimit(Count);
  TCollection.Store(S);
END; {PROC Table.Store}

PROCEDURE Table.Dump(Rprt:PReport);
  PROCEDURE Entry_Dump(E:TabEntryPtr); FAR;
  BEGIN
    E^.Dump(Rprt);
  END; {LOCAL PROC Entry_Dump}
BEGIN
  ForEach(@Entry_Dump);
END; {PROC Table.Dump}

FUNCTION Table.Empty:Boolean;
{ - Returns true no entries in table }
BEGIN
  Empty:=Count=0;
END; {FUNC Table.Empty}

FUNCTION Table.IsActive(ix:Integer):Boolean;
BEGIN
  IF (ix>=0) and (ix<Count) and (Count>0)
  THEN IsActive:=TabEntryPtr(At(ix))^.Active
  ELSE IsActive:=True;
END; {FUNC Table.IsActive}

PROCEDURE Table.Enable(ix:Integer);
BEGIN
  IF (ix>=0) and (ix<Count) and (Count>0)
  THEN TabEntryPtr(At(ix))^.Enable;
END; {PROC Table.Enable}

PROCEDURE Table.Disable(ix:Integer);
BEGIN
  IF (ix>=0) and (ix<Count) and (Count>0)
  THEN TabEntryPtr(At(ix))^.Disable;
END; {PROC Table.Disable}

{--- Methods for object : MsgNode -------------------------------------------}
{*
 * This is a generic message entry object
 * which contains only a message ID
 *}

CONSTRUCTOR MsgNode.Init(NewEntry:String);
{ - Insert sorted/Allocate the message}
BEGIN
  TObject.Init;
  PSNew(ID,NewEntry);   {Set message ID}
END; {CONS MsgNode.Init}

CONSTRUCTOR MsgNode.Load(VAR S:TStream);
{ - Load MsgNode ID from TStream}
BEGIN
  TObject.Init;
  ID:=S.ReadStr;
END; {CONS MsgNode.Load}

DESTRUCTOR MsgNode.Done;
{ - DeAllocate the index entry}
BEGIN
  PSDispose(ID);
  TObject.Done;
END; {DEST MsgNode.Done}

PROCEDURE MsgNode.Store(VAR S:TStream);
{ - Store MsgNode ID to file}
BEGIN
  S.WriteStr(ID);
END; {PROC MsgNode.Store}

PROCEDURE MsgNode.Dump(Rprt:PReport);
{ - Print Entry ID to Dump-file}
BEGIN
  Rprt^.Add('####');
END; {PROC MsgNode.Dump}


{--- Methods for object : IndexEntry ----------------------------------------}
{*
 * This is the basic message entry object
 * which contain the message ID, External-flag and StreamPos
 *}

CONSTRUCTOR IndexEntry.Init(NewEntry:String);
{ - Insert sorted/Allocate the message}
BEGIN
  UpSt(NewEntry);
  MsgNode.Init(NewEntry);
  Extern:=False;
  StreamPos:=-1;
END; {CONS IndexEntry.Init}

CONSTRUCTOR IndexEntry.Load(VAR S:TStream);
{ - Load IndexEntry ID from TStream}
BEGIN
  MsgNode.Load(S);
  S.Read(Extern,SizeOf(Extern));
  StreamPos:=S.GetPos;
END; {CONS IndexEntry.Load}

DESTRUCTOR IndexEntry.Done;
{ - DeAllocate the index entry}
BEGIN
  MsgNode.Done;
END; {DEST IndexEntry.Done}

PROCEDURE IndexEntry.Store(VAR S:TStream);
{ - Store IndexEntry ID to file}
BEGIN
  MsgNode.Store(S);
  S.Write(Extern,SizeOf(Extern));
END; {PROC IndexEntry.Store}

PROCEDURE IndexEntry.Dump(Rprt:PReport);
{ - Print Entry ID to Dump-file}
BEGIN
  Rprt^.Add(PadTrailing(#39+ID^+#39,' ',Indent-1)+' ');
END; {PROC IndexEntry.Dump}

{--- Methods for object : MsgTxt ------------------------------------------}
{*
 *  One-line text message index object
 *}

CONSTRUCTOR MsgTxt.Init(NewEntry:String; Msg:String);
{ - Insert sorted/Allocate the message}
BEGIN
  IndexEntry.Init(NewEntry); {Set message ID}
  PSNew(MesText,Msg);
END; {CONS MsgTxt.Init}

CONSTRUCTOR MsgTxt.Load(VAR S:TStream);
{ - Load Entry from TStream}
VAR
  Bytes : Byte;
BEGIN
  IndexEntry.Load(S);
  MesText:=S.ReadStr;
  IF S.Status<>0 THEN Fail;
END; {CONS MsgTxt.Load}

DESTRUCTOR MsgTxt.Done;
{ - DeAllocate the message}
BEGIN
  PSDispose(MesText);  {Release reserved message space}
  IndexEntry.Done;
END; {DEST MsgTxt.Done}

PROCEDURE MsgTxt.Store(VAR S:TStream);
{ - Store Message to TStream}
BEGIN
  IndexEntry.Store(S);
  S.WriteStr(MesText);
END; {PROC MsgTxt.Store}

FUNCTION MsgTxt.Message:String;
{ - Return message text}
BEGIN
  Message:=MesText^;         {Copy message text from reserved space}
END; {FUNC MsgTxt.Message}

PROCEDURE MsgTxt.Dump(Rprt:PReport);
{ - Print Instance of Msg to Dump-file }
BEGIN
  IndexEntry.Dump(Rprt);
  Rprt^.AddLn('"'+Message+'"');
END; {PROC MsgTxt.Dump}

{--- Methods for object : TextTxt ------------------------------------------}
{*
 *  Multi-line text message index object
 *}

CONSTRUCTOR TextTxt.Init(NewEntry:String);
{ - Initialize a new Text block entry}
BEGIN
  IndexEntry.Init(NewEntry); {Set message ID}
  Txts.Init;                 {Prepare text table}
END; {CONS TextTxt.Init}

CONSTRUCTOR TextTxt.Load(VAR S:TStream);
{ - Load Text Entry from TStream}
BEGIN
  IndexEntry.Load(S);
  Txts.Load(S);
END; {CONS TextTxt.Load}

DESTRUCTOR TextTxt.Done;
{ - Deallocate the text block entry}
BEGIN
  Txts.Done;                 {Remove text table}
  IndexEntry.Done;           {Remove the index entry}
END; {DEST TextTxt.Done}

PROCEDURE TextTxt.Store(VAR S:TStream);
{ - Store Text object to TStream}
BEGIN
  IndexEntry.Store(S);
  Txts.Store(S);
END; {PROC TextTxt.Store}

PROCEDURE TextTxt.AddLine(Txt:String);
{ - Add a new line to the text block}
VAR
 t : TabEntryPtr;
BEGIN
  New(t,Init(Txt));            {Create new text table entry}
  Txts.Insert(t);              {...and append it to the table}
END; {PROC TextTxt.AddLine}

PROCEDURE TextTxt.BreakLine;
{ - Add a PageBreak to the text block}
BEGIN
  {Haven't decided about this one yet}
END; {PROC TextTxt.BreakLine}

FUNCTION TextTxt.atLine(Num:Integer):EntryPtr;
{ - Return pointer to line number <Num>}
BEGIN
  atLine:=Txts.At(Num);                          {Return the line pointer}
END; {FUNC TextTxt.atLine}

FUNCTION TextTxt.TextAtLine(Num:Integer):String;
{ - Return text line number <Num>}
VAR
  PS : PString;
BEGIN
  PS:=PTextAtLine(Num);
  IF PS=nil
  THEN TextAtLine:=''
  ELSE TextAtLine:=PS^;                          {Return the text string}
END; {FUNC TextTxt.TextAtLine}

FUNCTION TextTxt.PTextAtLine(Num:Integer):PString;
{ - Return pointer to text line number <Num>}
BEGIN
  PTextAtLine:=TabEntryPtr(atLine(Num))^.txt;       {Return ptr to string}
END; {FUNC TextTxt.PTextAtLine}

FUNCTION TextTxt.LineIsActive(ix:Integer):Boolean;
BEGIN
  LineIsActive:=Txts.IsActive(ix);
END; {FUNC TextTxt.LineIsActive}

PROCEDURE TextTxt.LineEnable(ix:Integer);
BEGIN
  Txts.Enable(ix);
END; {PROC TextTxt.LineEnable}

PROCEDURE TextTxt.LineDisable(ix:Integer);
BEGIN
  Txts.Disable(ix);
END; {PROC TextTxt.LineDisable}

FUNCTION TextTxt.Lines:Integer;
{ - Return number of lines in text block}
BEGIN
  Lines:=Txts.Count;         {The number of lines is ... Collection.Count}
END; {FUNC TextTxt.Lines}

PROCEDURE TextTxt.Dump(Rprt:PReport);
{ - Dump Instance of text message index entry to file}
VAR
  i : Integer;
BEGIN
  Rprt^.NewLn;
  IndexEntry.Dump(Rprt);                       {First, dump the ID}
  Rprt^.AddLn('('+IntStr(Lines,0)+' lines)');  {Then: # of lines}
  Txts.Dump(Rprt);
END; {PROC TextTxt.Dump}

{--- Methods for object : MenuTxt ------------------------------------------}
{*
 *  Multi-line Menu message index object (w/Menu title)
 *}

CONSTRUCTOR MenuTxt.Init(NewEntry:String; TheTitle:String);
{ - Initialize a new Menu block entry}
BEGIN
  TextTxt.Init(NewEntry);          {Init the inherited part}
  PSNew(Title,TheTitle);
END; {CONS MenuTxt.Init}

CONSTRUCTOR MenuTxt.Load(VAR S:TStream);
{ - Load Entry from TStream}
VAR
  Bytes : Byte;
BEGIN
  TextTxt.Load(S);
  Title:=S.ReadStr;
  IF S.Status<>0 THEN Fail;
END; {CONS MenuTxt.Load}

DESTRUCTOR MenuTxt.Done;
{ - Deallocate the text block entry}
BEGIN
  PSDispose(Title);  {Release the title space}
  TextTxt.Done;     {DeAllocated the inherited part}
END; {DEST MenuTxt.Done}

PROCEDURE MenuTxt.Store(VAR S:TStream);
{ - Store entry to TStream}
BEGIN
  TextTxt.Store(S);
  S.WriteStr(Title);
END; {PROC MenuTxt.Store}

PROCEDURE MenuTxt.BreakLine;
{ - Add a PageBreak to the text block}
BEGIN
  {Haven't decided about this one either}
END; {PROC MenuTxt.BreakLine}

PROCEDURE MenuTxt.Dump(Rprt:PReport);
{ - Dump Instance of text message index entry to file}
VAR
  i : Integer;
BEGIN
  Rprt^.NewLn;
  IndexEntry.Dump(Rprt);               {Dump the ID, then Type,Title and # of lines}
  Rprt^.AddLn('"'+title^+'"  ('+IntStr(Lines,0)+' lines)');
  Txts.Dump(Rprt);
END; {PROC MenuTxt.Dump}

{--- Methods for object : HelpTxt ------------------------------------------}
{*
 *  Multi-line Help message index object (w/Help title)
 *}

CONSTRUCTOR HelpTxt.Init(NewEntry,Group:String; TheTitle:String);
{ - Initialize a new Menu block entry}
BEGIN
  MenuTxt.Init(NewEntry,TheTitle);    {Init the inherited part}
  UpSt(Group);
  PSNew(GroupRef,Group);               {Store the GroupRef}
END; {CONS HelpTxt.Init}

CONSTRUCTOR HelpTxt.Load(VAR S:TStream);
{ - Load Entry from TStream}
BEGIN
  MenuTxt.Load(S);
  GroupRef:=S.ReadStr;
  IF S.Status<>0 THEN Fail;
END; {CONS HelpTxt.Load}

DESTRUCTOR HelpTxt.Done;
{ - Deallocate the text block entry}
BEGIN
  PSDispose(GroupRef);
  MenuTxt.Done;                    {DeAllocated the inherited part}
END; {DEST HelpTxt.Done}

PROCEDURE HelpTxt.Store(VAR S:TStream);
{ - Store entry to TStream}
BEGIN
  MenuTxt.Store(S);
  S.WriteStr(GroupRef);
END; {PROC HelpTxt.Store}

PROCEDURE HelpTxt.BreakLine;
{ - Add a PageBreak to the text block}
BEGIN
  {Haven't decided about this one either}
END; {PROC HelpTxt.BreakLine}

PROCEDURE HelpTxt.AddLineRef(TheLine:String; TheRef:TablePtr);
{ - Add the text line and help references}
VAR
  r : RefEntryPtr;
BEGIN
  New(r,Init(TheLine,TheRef));
  Txts.Insert(r);
END;{PROC HelpTxt.AddRef}

PROCEDURE HelpTxt.Dump(Rprt:PReport);
{ - Dump Instance of text message index entry to file}
VAR
  i : Integer;
  r : RefEntryPtr;
BEGIN
  Rprt^.NewLn;
  IndexEntry.Dump(Rprt);              {Dump the ID, then Type,Title and # of lines}
  Rprt^.AddLn('"'+title^+'"  ('+IntStr(Lines,0)+' lines)');
  Txts.Dump(Rprt);
END; {PROC HelpTxt.Dump}


{--- Methods for object : MsgIndex ------------------------------------------}
{*
 *  Message index routines
 *}

CONST
  DelimCh : Char = '|';

PROCEDURE ReplaceCodes(VAR Line:String);
{ - Extract text between |-marks and replace @#-codes with ASCII codes}
VAR
  p,n,err,Value : Integer;
  st  : String[8];
  NewLine : String;
BEGIN
  DeleteLeading(' ',Line);   { Remove all except text between ||}
  p:=Pos(DelimCh,Line);
  IF p<>0
  THEN BEGIN
    System.Delete(Line,1,p);
    p:=Pos(DelimCh,Line);
    IF p=0 THEN p:=Length(Line) ELSE p:=p-1;
    Line:=Copy(Line,1,p);
  END;
  NewLine:='';               { Prepare new line}
  p:=pos('@#',Line);
  WHILE p<>0 DO
  BEGIN
    NewLine:=NewLine+Copy(Line,1,p-1); { Copy unchanged text to new line}
    System.Delete(Line,1,p+1);
    n:=0;                              { Pick out @#code }
    WHILE (Line[n+1] in ['0'..'9']) and (n<=3) DO inc(n);
    st:=Copy(Line,1,n);
    VAL(st,value,err);
    IF err=0 THEN         { Ignore @# and @#<illegal number>}
    BEGIN
      delete(Line,1,n);
      NewLine:=NewLine+chr(Value and $FF); {Add ASCII code to new line}
    END;
    p:=pos('@#',Line); { Find next code }
  END;
  Line:=NewLine+Line; {Return new line}
END; {PROC ReplaceCodes}

TYPE
  PCrossRef = ^CrossRef;
  CrossRef = OBJECT(TSortedCollection)
    FUNCTION Compare(A,B:Pointer):Integer; VIRTUAL;
  END;

FUNCTION CrossRef.Compare(A,B:Pointer):Integer;
VAR
  EntryA : RefChkPtr Absolute A;
  EntryB : RefChkPtr Absolute B;
BEGIN
  IF EntryA^.ID^<EntryB^.ID^
  THEN Compare:=-1                                  { Entry ID A<B }
  ELSE IF EntryA^.ID^>EntryB^.ID^
  THEN Compare:=1                                   { Entry ID A>B }
  ELSE Compare:=0;                                  { Entry ID A=B }
END; {FUNC CrossRef.Compare}


FUNCTION MsgIndex.Compare(A,B:Pointer):Integer;
{*
 * Compare two Msg ID's, Return  -1: A<B,  0: A=B,  1: A>B
 * Used for sorted insertion and tree searching.
 *}
VAR
  EntryA : EntryPtr Absolute A;
  EntryB : EntryPtr Absolute B;
BEGIN
  IF EntryA^.ID^<EntryB^.ID^
  THEN Compare:=-1                                  { Entry ID A<B }
  ELSE IF EntryA^.ID^>EntryB^.ID^
  THEN Compare:=1                                   { Entry ID A>B }
  ELSE Compare:=0;                                  { Entry ID A=B }
END; {FUNC MsgIndex.Compare}

CONSTRUCTOR MsgIndex.Compile(SourceName,StreamName,ListName:PathStr);
{ - "Compiles" messages from <SourceName>, checks for redefinitions and
    missing cross-references (Errors to <ListFile>).
    Dumps an alphabetized list to <ListFile> and saves the message index
    to <StreamName>}
CONST
  Extern   = $0001;
  EndMark  = $0002;
  StopMark = $0004;
VAR
  mFile   : Text;    { Text File containing messages (assigned to "filename")}
  eFile   : Text;    { Text file to receive "compile" errors }
  mID     : String;  { "Global" for MsgIndex.Compile: Message ID}
  m       : PMsgTxt;      { General purpose Msg pointer}
VAR
  Flag    : FlagGroup;   { Flags, End, stop, external, etc}
  IOres   : Integer;     { Result of last file I/O}
  LineCnt : LongInt;     { Number of lines read from file}
  ErrorCnt: LongInt;     { Error counter }
  xref    : PCrossRef;   { Help-Reference cross-ref. list }

  PROCEDURE CompMsg(msg:String);
  { - Display progress both on screen and to dumpfile}
  BEGIN
    Writeln(msg); Rprt^.AddLn(msg);
  END;{PROC CompMsg}

  FUNCTION GetLine(VAR Line:String):Boolean; Near;
  { - Get and "Cleanup" line, return True if line is not empty}
  BEGIN
  {$I-}
    ReadLn(mFile,Line);
  {$I+}
    IOres:=IOResult;    { Check for file errors }
    IF IOres<>0
    THEN BEGIN
      Line:='';
      Flag.Enable(StopMark);  {Stop sourcefile analysis }
    END
    ELSE Inc(LineCnt);
    DeleteLeading(' ',Line);  {Remove leading and trailing spaces}
    DeleteTrailing(' ',Line);
    IF Line[1]=';'            {Ignore Comment line}
    THEN Line:='';
    GetLine:=Line<>'';        {Return True for lines that need processing}
  END; {FUNC GetLine}

  PROCEDURE ParseDelim(VAR Line:String); Near;
  { - Change Text delimitor, Default = '|'}
  VAR
   p : Byte;
  BEGIN
    DeleteTrailing(' ',Line); { Remove all except command parameter }
    p:=Pos(' ',Line+' ');
    System.Delete(Line,1,p);
    DeleteLeading(' ',Line);
    IF (Length(Line)=0) or (Line[1]='@') { Which char is it ? }
    THEN DelimCh:='|'       { Default = | }
    ELSE DelimCh:=Line[1];
  END; {PROC ParseDelim}

  PROCEDURE ParseBuffer(VAR Line:String); Near;
  { - Change Message buffering method, Memory (Def.) or Disk}
  VAR
   p : Byte; { String index working variable }
  BEGIN
    DeleteTrailing(' ',Line); { Remove all except command parameter }
    p:=Pos(' ',Line+' ');
    System.Delete(Line,1,p);
    DeleteLeading(' ',Line);
    IF (Length(Line)<>0) and (UpCase(Line[1])='D') {D)isk buffering}
    THEN Flag.Enable(Extern)    {Enable disk-buffering}
    ELSE Flag.Disable(Extern);  {Disable disk-buffering (default)}
  END; {PROC ParseBuffer}

  PROCEDURE CheckCommand(VAR Line:String); Near;
  { - Check for other short @-commands }
  BEGIN
    IF Line[1]='@'             { else check for @-commands}
    THEN CASE upCase(Line[2]) OF
      'B' : ParseBuffer(Line);     {@BUFFER}
      'D' : ParseDelim(Line);      {@DELIMITOR}
      'E' : Flag.Enable(EndMark);  {@END}
      'S' : Flag.Enable(StopMark); {@STOP}
    END;
  END; {PROC CheckCommand}

  PROCEDURE CheckID(VAR id : String); Near;
  { - Detect redefinitions }
  BEGIN
    IF Find(id)<>nil  { If ID found, it's a redefinition }
    THEN BEGIN        { Write error msg to report and screen }
      CompMsg(IntStr(LineCnt,5)+' : "'+ID+'" redefined');
      Inc(ErrorCnt);  { add another error }
    END;
  END; {PROC CheckID}

  PROCEDURE CrossRefCheck;
  VAR
    Index : Integer;    { Message-index Search pointer }
    Ref   : RefChkPtr;
    Entry : EntryPtr;
  BEGIN
    FOR Index:=0 TO xRef^.Count-1
    DO BEGIN
      Ref:=xRef^.At(Index);
      Entry:=Find(Ref^.ID^);
      IF Entry<>nil
      THEN BEGIN
        IF TypeOf(Entry^)<>TypeOf(HelpTxt)  { Wrong message type ref'ed }
        THEN BEGIN                         { Write error msg to ListFile }
          CompMsg(IntStr(Ref^.Line,5)+' : ('+Ref^.Hlp^+') - Ref. "'+Ref^.ID^+'" illegal');
          Inc(ErrorCnt);           { Add another error }
        END;
      END
      ELSE BEGIN
        CompMsg(IntStr(Ref^.Line,5)+' : ('+Ref^.Hlp^+
                ') - Ref. "'+Ref^.ID^+'" not found');
        Inc(ErrorCnt);         { Add another error }
      END;
    END;
  END;{LOCAL PROC CrossRefCheck}

  PROCEDURE ParsePrompts(VAR Line:String); Near;
  { - Add Prompts to message tree }
  VAR
    p         : Byte;
  BEGIN
    Flag.Disable(EndMark);  { @END mark not found}
    WHILE not (EOF(mFile) or Flag.AnyEnabledOf(StopMark+EndMark))
    DO BEGIN
      IF GetLine(Line)
      THEN BEGIN
        p:=Pos(DelimCh,Line);     { Lines containing |-marks are valid}
        IF p>1
        THEN BEGIN
          mID:=Copy(Line,1,p-1);        { Extract ID}
          DeleteTrailing(' ',mID);
          ReplaceCodes(Line);           { Extract text}
          CheckID(mID);
          New(m,Init(mID,Line));        { Create Message node and...}
          m^.Extern:=Flag.State(Extern);
          Insert(m); {...insert it in tree}
        END
        ELSE CheckCommand(Line);
      END;
    END;
  END; {PROC ParsePrompts}

  PROCEDURE ParseTxt(Line:String); Near;
  { - Adds Text Block to message tree}
  VAR
    p         : Byte;
    t         : PTextTxt;
  BEGIN
    p:=Pos(' ',Line);
    IF p<>0
    THEN BEGIN
      System.Delete(Line,1,p);     { - Pick out Txt ID }
      DeleteLeading(' ',Line);
      mID:=Copy(Line,1,SizeOf(mID));
      CheckID(mID);
      New(t,Init(mID));                 { Create Text node...}
      t^.Extern:=Flag.State(Extern);
      Insert(t); {...and insert it in tree}
      WHILE not (EOF(mFile) or Flag.AnyEnabledOf(StopMark or EndMark)) { Now, get text lines}
      DO BEGIN
        IF GetLine(Line)
        THEN BEGIN
          p:=Pos(DelimCh,Line);              { | found, valid line}
          IF p>0
          THEN BEGIN
            ReplaceCodes(Line);
            t^.AddLine(Line);                { Add line to Text node}
          END
          ELSE CheckCommand(Line);
        END;
      END;
    END;
  END; {PROC ParseTxt}

  PROCEDURE ParseMnu(Line:String); Near;
  { - Add Menu to Message tree}
  VAR
    p         : Byte;
    m         : PMenuTxt;
  BEGIN
    p:=Pos(' ',Line);
    IF p<>0
    THEN BEGIN
      System.Delete(Line,1,p);     { - Pick out Txt ID }
      DeleteLeading(' ',Line);
      p:=Pos(' ',Line+' ');
      mID:=Copy(Line,1,p-1);
      ReplaceCodes(Line);          { Pick out menu title }
      CheckID(mID);
      New(m,Init(mID,Line));       { Create Menu node... }
      m^.Extern:=Flag.State(Extern);
      Insert(m); {...and add it to the tree}
      WHILE not (EOF(mFile) or Flag.AnyEnabledOf(StopMark or EndMark))
      DO BEGIN                     { Now, find all menu lines}
        IF GetLine(Line)
        THEN BEGIN
          p:=Pos(DelimCh,Line);    { Line with | marks is a valid menu line}
          IF p>0
          THEN BEGIN
            ReplaceCodes(Line);    {Extract text}
            m^.AddLine(Line);
          END
          ELSE CheckCommand(Line);
        END;
      END;
    END;
  END; {PROC ParseMnu}

  PROCEDURE ParseHlp(Line:String); Near;
  { - Add Help object to Message tree}
  VAR
    p,w     : Byte;
    gID       : String;
    h         : PHelpTxt;
    xr        : RefChkPtr;
    RefList   : TablePtr;
    Reference : RefLstPtr;
  BEGIN
    p:=Pos(' ',Line);
    IF p<>0
    THEN BEGIN
      System.Delete(Line,1,p);     { - Pick out Help ID }
      DeleteLeading(' ',Line);
      p:=Pos(' ',Line+' ');
      mID:=Copy(Line,1,p-1);
      System.Delete(Line,1,p);
      DeleteLeading(' ',Line);     { - Pick out Help Group ID }
      p:=Pos(DelimCh,Line);
      gID:=Copy(Line,1,p-1);
      DeleteTrailing(' ',gID);
      IF gID<>'' THEN xRef^.Insert(New(RefChkPtr,Init(mID,gID,LineCnt)));
      ReplaceCodes(Line);          { Pick out Help title }
      New(h,Init(mID,gID,Line));   { Create Help node... }
      CheckID(mID);
      h^.Extern:=Flag.State(Extern);
      Insert(h); {...and add it to the tree}
      WHILE not (EOF(mFile) or Flag.AnyEnabledOf(StopMark or EndMark))
      DO BEGIN                     {Now, find all menu lines}
        IF GetLine(Line)
        THEN BEGIN
          p:=Pos(DelimCh,Line);    { Line with | marks is a valid menu line}
          IF p>0
          THEN BEGIN
            New(RefList,Init);       { Create reference list }
            p:=Pos('@{',Line);
            WHILE p<>0
            DO BEGIN
              w:=0;
              WHILE (p+2+w<=Length(Line)) and (Line[p+2+w]<>'|') DO Inc(w);
              gID:=copy(Line,p+2,w);
              DeleteTrailing(' ',gID);
              System.Delete(Line,p,w+3);
              w:=0;
              WHILE (p+w<=Length(Line)) and not (Line[p+w] in [DelimCh,'}'])
              DO Inc(w);
              Dec(w);
              IF gID<>'' THEN xRef^.Insert(New(RefChkPtr,Init(mID,gID,LineCnt)));
              New(Reference,Init(gID,p,w));
              RefList^.Insert(Reference);
              p:=p+w+1;
              IF Line[p]=DelimCh THEN System.Delete(Line,p,1);
              IF Line[p]='}' THEN System.Delete(Line,p,1);
              p:=Pos('@{',Line);
            END;
            ReplaceCodes(Line);    {Extract text}
            h^.AddLineRef(Line,RefList);
          END
          ELSE CheckCommand(Line);
        END;
      END;
    END;
  END; {PROC ParseHlp}

VAR
  mLine : String;
  ec    : LongInt;
BEGIN { Body of MsgIndex.Compile }
  TSortedCollection.Init(100,100);
  New(xRef,Init(100,20));
  New(Rprt,Init);
  Flag.Init(0);
  DelimCh:='|';
  new(m,Init(NoID,'Unknown Msg'));  {Create "unknown" entry for root}
  Assign(mFile,SourceName);
{$I-}                               {Open definition file for read}
  Reset(mFile);
{$I+}
  IOres:=IOresult;                  {Check for file I/O error}
  Flag.Assign(StopMark,IOres<>0);
  LineCnt:=0; ErrorCnt:=0;          {Zero line/error counters}
  IF ListName='' THEN ListName:='NUL';  {Prepare list-file}
  Rprt^.AddLn(^M^J' þ External Message Stream Compiler'^M^J);
  CompMsg('Reading message definition file: "'+SourceName+'"');
  CompMsg('Checking for Redefined messages...');
  WHILE not (EOF(mFile) or Flag.isEnabled(StopMark))    {Scan file}
  DO BEGIN
    IF GetLine(mLine)               {Look for @-block commands}
    THEN BEGIN
      IF mLine[1]='@'
      THEN BEGIN
        Flag.Disable(EndMark);
        CASE upCase(mLine[2]) OF
          'H' : ParseHlp(mLine);       {@HELP}
          'M' : ParseMnu(mLine);       {@MENU}
          'P' : ParsePrompts(mLine);   {@PROMPTS}
          'T' : ParseTxt(mLine);       {@TEXT}
           ELSE CheckCommand(mLine);
        END;
      END;
    END;
  END;
{$I-}
  Close(mFile);                      {Close definition file}
{$I+}
  CompMsg('Sourcefile errors detected: '+IntStr(ErrorCnt,0));
  CompMsg('Checking for Missing/Illegal Help-references...');
  ec:=ErrorCnt;       { Save # of redef. errors }
  ErrorCnt:=0;
  CrossRefCheck; { Check for missing/illegal cross-ref's }
  Dispose(xRef,Done);
  CompMsg('Sourcefile errors detected: '+IntStr(ErrorCnt,0));
  ec:=ec+ErrorCnt;    { Add cross-ref. errors }
  IF ec<>0            { Write Error reminder to Listfile }
  THEN BEGIN
    CompMsg('');
    CompMsg('WARNING: Messages are inconsistent !  ('+IntStr(ec,0)+' errors detected)');
    CompMsg('');
  END;
  IF StreamName<>''   { Save message TStream if filename given }
  THEN BEGIN
    CompMsg('Writing target message TStream  : "'+StreamName+'"');
    Save(StreamName);
  END;
  CompMsg('Writing message reference list : "'+ListName+'"');
  Rprt^.NewLn;
  Dump;         { Write alphabetized message index to Listfile }
  Rprt^.Output(ListName);
END; {CONS MsgIndex.Compile}

VAR
  EMHsize : Byte Absolute ExtMsgHeader;   {Length of TStream header}

CONSTRUCTOR MsgIndex.Load(StreamName:PathStr);
{ - Load Message Index from TStream}
VAR
  S : LFStream;
BEGIN
  New(Rprt,Init);
  S.Init(StreamName,StOpenRead,4096); {Reset TStream}
  S.Seek(EMHsize);                   {Skip header}
  TSortedCollection.Load(S);         {Load tree from TStream}
  S.Done;                            {Close TStream}
END; {CONS Entry.Load}

DESTRUCTOR MsgIndex.Done;
BEGIN
  Dispose(Rprt,Done);
  TSortedCollection.Done;
END;

PROCEDURE MsgIndex.Save(StreamName:Pathstr);
{ - Store Message Index to TStream}
VAR
  S : LFStream;
BEGIN
  Pack;
  SetLimit(Count);
  S.Init(StreamName,StCreate,4096);  {Rewrite TStream}
  S.Write(ExtMsgHeader[1],EMHsize); {Write header}
  TSortedCollection.Store(S);                    {Store tree}
  S.Flush;                          {Flush TStream write buffer}
  S.Done;                           {Close TStream}
END; {PROC MsgIndex.Save}

FUNCTION MsgIndex.Find(WhatEntry:String):EntryPtr;
{ - Look up <WhatEntry> and return pointer to message}
VAR
  Index : Integer;
  Key   : EntryPtr;
BEGIN
  IF WhatEntry<>''
  THEN BEGIN
    UpSt(WhatEntry);               { ID's are not Case sensitive}
    New(Key,Init(WhatEntry));      { Create Search Key}
    IF Search(Key,Index)
    THEN Find:=At(Index)           { Point to Found node }
    ELSE BEGIN
      Find:=Nil;                   { Nil if not found }
      ExtMsgError(WhatEntry,'not found');
    END;
    Dispose(Key,Done);             { Get rid of search key}
  END ELSE Find:=nil;
END; {FUNC MsgIndex.Find}

FUNCTION MsgIndex.FindMsg(WhatEntry:String):PMsgTxt;
{ - As Find, but returns a Message Ptr (or nil if illegal ref.)}
VAR
  f : EntryPtr;
BEGIN
  f:=Find(WhatEntry);
  IF f<>nil
  THEN BEGIN
    IF TypeOf(f^)<>TypeOf(MsgTxt) {Don't allow illegal lookup's }
    THEN BEGIN
      f:=nil;
      ExtMsgError(WhatEntry,'is not a Msg text');
    END;
  END;
  FindMsg:=PMsgTxt(f);
END; {FUNC MsgIndex.FindMsg}

FUNCTION MsgIndex.FindText(WhatEntry:String):PTextTxt;
{ - As Find, but returns a Text Ptr (or nil if illegal ref.)}
VAR
  f : EntryPtr;
BEGIN
  f:=Find(WhatEntry);
  IF f<>nil
  THEN BEGIN
    IF TypeOf(f^)<>TypeOf(TextTxt) {Don't allow illegal lookup's }
    THEN BEGIN
      f:=nil;
      ExtMsgError(WhatEntry,'is not a Txt text');
    END;
  END;
  FindText:=PTextTxt(f);
END; {FUNC MsgIndex.FindText}

FUNCTION MsgIndex.FindMenu(WhatEntry:String):PMenuTxt;
{ - As Find, but returns a Menu Ptr (or nil if illegal ref.)}
VAR
  f : EntryPtr;
BEGIN
  f:=Find(WhatEntry);
  IF f<>nil
  THEN BEGIN
    IF TypeOf(f^)<>TypeOf(MenuTxt) {Don't allow illegal lookup's }
    THEN BEGIN
      f:=nil;
      ExtMsgError(WhatEntry,'is not a Mnu text');
    END;
  END;
  FindMenu:=PMenuTxt(f);
END; {FUNC MsgIndex.FindMenu}

FUNCTION MsgIndex.FindHelp(WhatEntry:String):PHelpTxt;
{ - As Find, but returns a Help Ptr (or nil if illegal ref.)}
VAR
  h : EntryPtr;
BEGIN
  h:=Find(WhatEntry);
  IF h<>nil
  THEN BEGIN
    IF TypeOf(h^)<>TypeOf(HelpTxt) {Don't allow illegal lookup's }
    THEN BEGIN
      h:=nil;
      ExtMsgError(WhatEntry,'is not a Hlp text');
    END;;
  END;
  FindHelp:=PHelpTxt(h);
END; {FUNC MsgIndex.FindHelp}

FUNCTION MsgIndex.Connect(WhatEntry:String; VAR ConnectTo:EntryPtr):Boolean;
{ - Look up <WhatEntry> and return pointer to message and True if Found}
VAR
  Found : EntryPtr;
BEGIN
  Found:=Find(WhatEntry);{Lookup Entry}
  Connect:=Found<>nil;   {Return true if found}
  ConnectTo:=Found;      {Return pointer anyway}
END;{FUNCTION MsgIndex.Connect}

PROCEDURE MsgIndex.Dump;
VAR
  Target : Pointer;
  PROCEDURE TargetHit_Dump(Entry:EntryPtr); FAR;
  BEGIN
    IF TypeOF(Entry^)=Target
    THEN Entry^.Dump(Rprt);
  END;
BEGIN
  Rprt^.AddLn(^M^J' þ Prompt texts (Msg)'^M^J);
  Target:=TypeOF(MsgTxt);
  ForEach(@TargetHit_Dump);
  Rprt^.AddLn(^M^J^M^J' þ Multiline texts (Txt)');
  Target:=TypeOF(TextTxt);
  ForEach(@TargetHit_Dump);
  Rprt^.AddLn(^M^J^M^J' þ Menu texts (Mnu)');
  Target:=TypeOF(MenuTxt);
  ForEach(@TargetHit_Dump);
  Rprt^.AddLn(^M^J^M^J' þ Help texts (Hlp)');
  Target:=TypeOF(HelpTxt);
  ForEach(@TargetHit_Dump);
  Rprt^.AddLn(^M^J' þ End');
END;{PROC MsgIndex.Dump}

PROCEDURE NoExtMsgError(MsgID,ErrorMsg:String); FAR;
BEGIN
  { Dummy Error Proc }
END;

VAR
  PrevExitProc : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitProc;
  Units.Leave(ExtMsgHeader,MemAvail);
END;

BEGIN {Init Unit LFExtMsg}
  ExtMsgError:=NoExtMsgError;
  PrevExitProc:=ExitProc;
  ExitProc:=@ExitHandler;
  RegisterExtMsg;
  Units.Enter(ExtMsgHeader,MemAvail,CSeg);
END.

