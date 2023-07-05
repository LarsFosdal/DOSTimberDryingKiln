{$I CodeDefs.Pas}

{$DEFINE UsePrintSpooler}

UNIT AGTools;

INTERFACE
USES
  Graph,Objects,LFGraph,LFWindow,LFGfxWin,OBJinput,LFExtMsg,Icons;
CONST
  AGToolsMSg = ' AGTools.1 910927 Fosdal/AG ';

CONST
  { - Sizes }
  WSH    = (24 * 16) + 8;
  TitleH = (480-WSH) DIV 2;
  MsgH   = TitleH;

CONST
  { - Colors }
  AGPal : PaletteMix =
  ((r:$00; g:$00; b:$00),  {Black}
   (r:$02; g:$02; b:$25),  {Blue}
        { Substituted by Violet (r:$02; g:$25; b:$02),  {Green}
   (r:$2E; g:$00; b:$1E),  {Violet}
   (r:$00; g:$25; b:$25),  {Cyan}
   (r:$25; g:$02; b:$02),  {Red}
   (r:$18; g:$18; b:$25),  {PaleBlue (Magenta)}
   (r:$3f; g:$3f; b:$33),  {PaleYellow (Brown)}
   (r:$2A; g:$2A; b:$2A),  {LightGray}
   (r:$18; g:$18; b:$18),  {DarkGray}
   (r:$00; g:$00; b:$3c),  {LightBlue}
   (r:$00; g:$3c; b:$00),  {LightGreen}
   (r:$00; g:$3c; b:$3c),  {LightCyan}
   (r:$34; g:$00; b:$00),  {LightRed}
   (r:$20; g:$20; b:$30),  {LightPaleBlue (LightMagenta)}
   (r:$3f; g:$3f; b:$00),  {Yellow}
   (r:$3e; g:$3e; b:$3e)); {White}

CONST
  Violet     = Green;
  PaleYellow = Brown;
  PaleBlue   = Magenta;
  LightPaleBlue = LightMagenta;

CONST
  Enabled = True;
  Disabled = False;

CONST
  DTLB  : Word = LightCyan;      {Desktop, light border color}
  DTBG  : Word = Cyan;           {Desktop, background color}
  DTTC  : Word = Yellow;         {Desktop, Title color}
  WSLB  : Word = White;          {Workspace, light border color}
  WSBG  : Word = LightGray;      {Workspace, background color}
  DWGFG : Word = Black;          {Drawing, foreground color}
  ForcedRedraw      : Boolean = Disabled;
  HelpAvailable     : Boolean = Disabled;
  HelpActive        : Boolean = False;
CONST
  ScreenSaveActive  : Boolean = False;
  ScreenSaveEnabled : Boolean = Enabled;
  SavMsg : String[79] = 'ABB Alfsen og Gunderson Trelastt›rker';
  ScreenSaveTimer   : Word = 5*60; {x*60 seconds = x minutes keyboard inactivity }
CONST
  DiskIO   = 1;
  PLCIO    = 2;
  Calculus = 3;
  Printing = 4;

PROCEDURE StartGfxEngine(MsgFileName:String; MainHelp:String);
PROCEDURE AddToLog(ErrorMsg:String);
FUNCTION  Lookup(Tag:String):String;
FUNCTION  PLookup(Tag:String):PString;
FUNCTION  PrinterOK:Boolean;
PROCEDURE Print(Txt:String);
PROCEDURE PrintLine(Txt:String);
FUNCTION  PrintHeader:Boolean;
PROCEDURE PrinterError;
PROCEDURE PrintFooter;
PROCEDURE PrintWorkspace(BGColors : ByteSet);
PROCEDURE WSClear;
PROCEDURE WSWrt(Txt:String);
PROCEDURE WSWrtLn(Txt:String);
PROCEDURE WSColor(NewC:SingleColor);
PROCEDURE WSWrtXY(x,y:Integer; Txt:String);
PROCEDURE DeskTopTime;
PROCEDURE DeskTopTitle(Title:String);
PROCEDURE DeskTopHelp;
PROCEDURE DeskTopHeap;
PROCEDURE ClearMsg;
PROCEDURE PutMsg(m1,m2:String);
PROCEDURE ClearDeskTop(TC:Word; Title:String);
PROCEDURE RaiseBusySign(Op:Word);
PROCEDURE WaitForAnyKey(HelpTag:String);
PROCEDURE DropBusySign;
PROCEDURE HelpIs(TrueIfEnabled:Boolean);
FUNCTION YesNo(QT,QQ:String):Boolean;
PROCEDURE StopGfxEngine;
FUNCTION ConfirmedExit:Boolean;
FUNCTION CopyFile(SrcFile,TgtFile:FNameStr):Integer;

VAR
  WorkSpace,WS : PGfxWS;
  HeaderString : PString;
  DTTitle      : String[50];
  WSC          : SingleColor;
  Normal       : SingleColor;
  Bold         : SingleColor;
  Help         : PHyperText;
  HelpWin      : PGfxWin;
  ExitMsg      : PString;
{$IFDEF Aux}
  Aux : Text;
{$ENDIF}


IMPLEMENTATION

USES
  Crt, Dos, LFSystem, LFString, LFCrt, LFDos, LFprint, Bitfont1;

CONST
  MsgInit : Boolean = False;
  GfxInit : Boolean = False;
CONST
  ErrorLogName : String[12] = 'AGERROR.LOG';
VAR
  DefaultHelpTag : String;
  ErrorLog       : Text;
  PrinterWasOK   : Boolean;

PROCEDURE LogAppend(Msg:String);
BEGIN
  Append(ErrorLog);
  Writeln(ErrorLog,Msg);
  Close(ErrorLog);
END;

PROCEDURE AddToLog(ErrorMsg:String);
BEGIN
  LogAppend('³ '+Date+' '+Time+' : '+ErrorMsg);
END;


PROCEDURE ExtMsgErrors(MsgID,ErrorMsg:String); FAR;
BEGIN
  IF MsgID<>NoID
  THEN AddToLog('Msg Error - "'+MsgID+'" '+ErrorMsg);
END; {PROC ExtMsgErrors}

FUNCTION Lookup(Tag:String):String;
{ - Return tag-string or error msg if not found }
VAR
  S : PString;
BEGIN
  S:=PLookup(Tag);
  IF S=Nil
  THEN Lookup:=Tag
  ELSE Lookup:=S^;
END; {FUNC Lookup}

FUNCTION PLookup(Tag:String):PString;
{ - Return pointer to tag-string, nil if not found }
VAR
  M : PMsgTxt;
BEGIN
  M:=Msg^.FindMsg(Tag);
  IF M<>nil
  THEN PLookup:=M^.MesText
  ELSE PLookup:=nil;
END; {FUNC PLookup}

{$IFDEF UsePrintSpooler}
VAR
  Prn : PrintQueue;
{$ENDIF}

FUNCTION PrinterOK:Boolean;
VAR
  Prnstat : Byte;
  NotBusy, Selected : Boolean;
  NoPaper, IOerror, TimeOut : Boolean;
BEGIN
{$IFDEF UsePrintSpooler}
  PrinterOK:=Not Prn.Error;
{$ELSE}
  PrnStat:=LFPrint.CurrentPrintStat and $F9;
  NotBusy:=Boolean(PrnStat and PrtNotBusy) or True;
  Selected:=Boolean(PrnStat and PrtSelect);
  NoPaper:=Boolean(PrnStat and PrtNoPaper) and False;
  IOError:=Boolean(PrnStat and PrtIOerror);
  TimeOut:=Boolean(PrnStat and PrtTimeOut);
  PrinterOK:=(NotBusy and Selected) and not (NoPaper or IOerror or TimeOut);
{$ENDIF}
END; {FUNC PrinterOK}

PROCEDURE Print(Txt:String);
BEGIN
{$IFDEF UsePrintSpooler}
  Prn.Print(Txt);
{$ELSE}
  LFPrint.Print(Txt);
{$ENDIF}
END;

PROCEDURE PrintLine(Txt:String);
BEGIN
{$IFDEF UsePrintSpooler}
  Prn.PrintLn(Txt);
{$ELSE}
  LFPrint.PrintLn(Txt);
{$ENDIF}
END;

FUNCTION PrintHeader:Boolean;
VAR
  OK : Boolean;
BEGIN
  RaiseBusySign(Printing);
{$IFDEF UsePrintSpooler}
  Prn.Init('LPT1',False);
  Prn.Print(' '^H);
{$ELSE}
  LFPrint.LPTn:=1;
  OK:=LFPrint.CurrentPrintStat=0;
{$ENDIF}
  delay(1000);
  OK:=PrinterOK;
  IF OK
  THEN BEGIN
    PrintLine(Rep(80,'Ä'));
    PrintLine(' '+so+esc+'E'+DTTitle+esc+'F');
    PrintLine(' '+so+si+Date+' '+Time+' : '+HeaderString^+dc2);
    PrintLine(Rep(80,'Ä'));
    PrintLine('');
  END;
  PrinterWasOK:=OK;
  PrintHeader:=OK;
END; {FUNC PrintHeader}

PROCEDURE PrinterError;
VAR
  win : PGfxWin;
  ww  : Integer;
  QQ  : String;
BEGIN
  ww:=40;
{$IFDEF UsePrintSpooler}
  QQ:=Prn.Port+' dos error: '+IntStr(Prn.ErrorCode,0);
{$ELSE}
  QQ:='LPT'+IntStr(LFPrint.LPTn,0)+' BIOS status: '+BinB(LFPrint.PrintStat);
{$ENDIF}
  AddToLog('Printer error - '+QQ);
  New(Win, InitTxt(38-(ww DIV 2),20,ww+4,3,True));
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  Win^.Title('Printer error !','Escape');
  Win^.Open;
  Win^.WorkSpace^.Center(LineSpacing,PGfxWS(Win^.WorkSpace)^.CC, QQ);
  WaitForAnyKey({$IFDEF UsePrintSpooler} 'DOSErr' {$ELSE} 'BIOSerr' {$ENDIF});
  Win^.Close;
  Dispose(Win,Done);
END;


PROCEDURE PrintFooter;
BEGIN
  delay(1000);
  IF PrinterWasOK
  THEN BEGIN
    PrintLine('');
    PrintLine(Rep(80,'Ä'));
    PrintLine(' '+so+esc+'E'+LookUp('Company')+esc+'F');
    PrintLine(' '+so+si+LookUp('ProgTitle')+dc2);
    PrintLine(' '+so+si+LookUp('Address')+dc2);
    PrintLine(Rep(80,'Ä'));
  END;
  DropBusySign;
{$IFDEF UsePrintSpooler}
  Prn.Done;
{$ENDIF}
  IF Not PrinterWasOK
  THEN PrinterError;
END; {PROC PrintFooter}

PROCEDURE PrintWorkSpace(BGColors:ByteSet);
CONST
  exp2 : ARRAY[0..7] OF byte = (128,64,32,16,8,4,2,1);
VAR
  c    : byte;
  l,
  xx,
  yy,z : word;
  y    : ARRAY[0..7] OF Word;
  x    : ARRAY[0..960] OF Word;
  s    : String;
  ddx  : Float;
BEGIN
  {$IFDEF UsePrintSpooler}
    Write(Prn.Spool, #27#51#24);
  {$ELSE}
    Print(#27#51#24);               { LineSpacing 24/216" = 8/72" }
  {$ENDIF}
  ddx:=640/960;
  yy:=0;
  FOR xx:=0 TO 959 DO x[xx]:=Round(xx*ddx);
  REPEAT
  {$IFDEF UsePrintSpooler}
    Write(Prn.Spool, #27#89#192#03);
  {$ELSE}
    Print(#27#89#192#03); { GraphMode 120*72 DPI = 960 dots pr.line}
  {$ENDIF}
    FOR z:=0 TO 7
    DO y[z]:=Round(TitleH+(yy*8)+z);
    xx:=0; s:='';
    REPEAT
      c:=0;
      FOR z:=0 TO 7
      DO IF Not (GetPixel(x[xx],y[z]) IN BGColors)
        THEN c:=c+exp2[z];
      s:=s+char(c);
      IF s[0]=#250
      THEN BEGIN
  {$IFDEF UsePrintSpooler}
        Write(Prn.Spool, s);
  {$ELSE}
        Print(s);
  {$ENDIF}
        s:='';
      END;
      inc(xx);
    UNTIL (xx=960);
  {$IFDEF UsePrintSpooler}
    WriteLn(Prn.Spool, s);
  {$ELSE}
    PrintLn(s);
  {$ENDIF}
    Inc(yy)
  UNTIL (yy=49);
  {$IFDEF UsePrintSpooler}
    Write(Prn.Spool, #27#50);
  {$ELSE}
    Print(#27#50);
  {$ENDIF}
END;{PROC PrtScr}

VAR
  WSX,WSY : Integer;

PROCEDURE WSClear;
{ - Clear workspace }
BEGIN
  FrameRelief(0,TitleH,640,WSH,WSLB,DarkGray,WSBG);
  WorkSpace^.Clear;
  WSX:=0;  WSY:=0;
  WSC:=WorkSpace^.Pane.Norm;
END; {PROC WSClear}

PROCEDURE WSWrt(Txt:String);
BEGIN
  WorkSpace^.WrtTxt(WSX,WSY,WSC,Txt);
  WSX:=WSX+Length(Txt);
END; {PROC WSWrt}

PROCEDURE WSWrtLn(Txt:String);
BEGIN
  WorkSpace^.WrtTxt(WSX,WSY,WSC,Txt);
  WSX:=0;
  Inc(WSY);
END; {PROC WSWrtLn}

PROCEDURE WSColor(NewC:SingleColor);
BEGIN
  WSC:=NewC;
END; {PROC WSColor}

PROCEDURE WSFG(Color:Integer);
BEGIN
  WSC.SetFG(Color);
END; {PROC WSColor}

PROCEDURE WSWrtXY(x,y:Integer; Txt:String);
BEGIN
  WSX:=x;
  WSY:=y;
  WSWrt(Txt);
END; {PROC WSWrtXY}


PROCEDURE DeskTopDate;
{ - Update date }
CONST
  Prev : String[8]='99/99/99';
  TT = TitleH DIV 2;
BEGIN
  IF (Prev<>Date) or ForcedRedraw
  THEN BEGIN
    Prev:=Date;
    BasRelief(560,TT,80,TT,DTLB,DarkGray,DTBG);
    Shadow(gWrt,568,TT+4,DTTC,Prev);
  END;
END; {PROC DeskTopDate}

PROCEDURE DeskTopTime;
{ - Update time }
CONST
  Prev : String[5] = '99.99';
  TT = TitleH DIV 2;
BEGIN
  IF (Prev<>Time) or ForcedRedraw
  THEN BEGIN
    Prev:=Time;
    BasRelief(560,0,80,TT,DTLB,DarkGray,DTBG);
    Shadow(gWrt,580,4,DTTC,Prev);
    DeskTopDate;
  END;
END; {PROC DeskTopTime}

PROCEDURE DeskTopTitle(Title:String);
{ - Redraw title, update time/date }
CONST
  TT = ((TitleH - 36) DIV 2) + 12;
VAR
  PrevMode : TextSettingsType;
  pc : Word;
  e  : Integer;
BEGIN
  BasRelief(0,0,560,TitleH,DTLB,DarkGray,DTBG);
  IF Title<>''
  THEN BEGIN
    pc:=GetColor;
{    GetTextSettings(PrevMode);}
    SetTextStyle(TriplexFont, HorizDir,4);
    e:=GraphResult;
    SetTextJustify(LeftText,CenterText);
    SetColor(Black);  OutTextXY(10, TT+2, Title);
    SetColor(DTTC);   OutTextXY( 8, TT, Title);
{    WITH PrevMode
    DO BEGIN
      SetTextStyle(Font,Direction,CharSize);
      SetTextJustify(Horiz,Vert);
    END; }
    SetColor(pc);
    DTTitle:=Title;
  END;
  ForcedRedraw:=True;
  DeskTopTime;
  ForcedRedraw:=False;
END; {PROC DeskTopTitle}

PROCEDURE DeskTopHelp;
CONST
  TT = MsgH DIV 2;
BEGIN
  BasRelief(560,480-2*TT,80,TT,DTLB,DarkGray,DTBG);
  Shadow(gWrt,568,480-2*TT+4,DTTC,LookUp('F1HELP'));
  IF Not HelpAvailable
  THEN gWrt(568,480-2*TT+4,DTBG,'±±±±±±±±');
END;

PROCEDURE DeskTopHeap;
CONST
  Prev : LongInt = 0;
  TT = MsgH DIV 2;
BEGIN
  IF (Prev<>MemAvail) or ForcedRedraw
  THEN BEGIN
    Prev:=MemAvail;
    BasRelief(560,480-TT,80,TT,DTLB,DarkGray,DTBG);
    Shadow(gWrt,576,480-TT+4,DTTC,IntStr(Prev,6));
  END;
END;

PROCEDURE ClearMsg;
BEGIN
  BasRelief(0,480-MsgH,560,MsgH,DTLB,DarkGray,DTBG);
  ForcedRedraw:=True;
  DeskTopHelp;
  DeskTopHeap;
  ForcedRedraw:=False;
END;

PROCEDURE PutMsg(m1,m2:String);
BEGIN
  ClearMsg;
  Shadow(gWrt,24,480-MsgH+6,DTTC,m1);
  Shadow(gWrt,24,480-(MsgH DIV 2),DTTC,m2);
END;

PROCEDURE ClearDeskTop(TC:Word; Title:String);
{ - Clear entire Screen }
BEGIN
  SetFillStyle(SolidFill,DTBG);
  Bar(0,0,639,479);
  DTTC:=TC;
  DeskTopTitle(Title);
  WSClear;
  ClearMsg;
END;

PROCEDURE HelpHandler(HelpTag:InfoIDtype); FAR;
BEGIN
  IF HelpAvailable
  THEN BEGIN
    HelpActive:=True;
    IF HelpTag='' THEN HelpTag:=DefaultHelpTag;
    Help^.LookUp(HelpTag);
    HelpActive:=False;
  END ELSE Blip;
END; {PROC HelpHandler}

PROCEDURE HelpIs(TrueIfEnabled:Boolean);
BEGIN
  HelpAvailable:=TrueIfEnabled;
  DeskTopHelp;
END;

PROCEDURE RaiseBusySign(Op:Word);
VAR
  n : Integer;
BEGIN
  IF not ScreenSaveActive
  THEN BEGIN
    BasRelief(560,480-MsgH,80,MsgH,LightRed,DarkGray,Red);
    CASE Op OF
        DiskIO : BEGIN
                   ECPutBlock(583,449,HD3Icon,NormalPut);
                 END;
         PLCIO : BEGIN
                   Shadow(gWrt,570,450,White,'PC'#26#27'PLS');
                 END;
      Calculus : BEGIN
                   Shadow(gWrt,570,450,White,'2+2 = ?');
                 END;
      Printing : BEGIN
                   Shadow(gWrt,570,450,White,'Printer');
                 END;
    END;
  END;
END;

PROCEDURE DropBusySign;
BEGIN
  IF Not ScreenSaveActive
  THEN BEGIN
    ForcedRedraw:=True;
    DeskTopHeap;
    DeskTopHelp;
    ForcedRedraw:=False;
  END;
END;

PROCEDURE WaitForAnyKey(HelpTag:String);
VAR
  Key : PKeyStroke;
BEGIN
  New(Key,Init(WorkSpace,0,0,[#1..#255],True));
  Key^.Link(msg,helpTag,'','');
  Key^.WaitForValid;
  Dispose(Key,Done);
END; {WaitForAnyKey}

PROCEDURE MessageInit(MsgFileName:String; MainHelp:String);
{$IFNDEF NoDebug}
VAR
  PrevStat : Boolean;
{$ENDIF}
BEGIN
{$IFNDEF NoDebug}
  PrevStat:=SysHaltOnError;
  SysHaltOnError:=False;
{$ENDIF}
  IF MsgFileName<>''
  THEN BEGIN
    New(Msg,Load(Path+MsgFileName));
    IF MainHelp<>''
    THEN BEGIN
      DefaultHelpTag:=MainHelp;
      New(HelpWin,InitTxt(12,10,10,10,True));
      HelpWin^.C.Frame.SetAllBG(PaleBlue);
      HelpWin^.C.Frame.High.SetFG(LightPaleBlue);
      HelpWin^.WorkSpace^.Pane.SetAllBG(PaleBlue);
      HelpWin^.WorkSpace^.SelBar.SetAllBG(PaleYellow);
      HelpWin^.WorkSpace^.SelBar.High.SetFG(Blue);
      HelpWin^.WorkSpace^.SelBar.Norm.SetFG(Red);
      HelpWin^.WorkSpace^.SelBar.Low.SetFG(Black);

      New(Help,Init(HelpWin,Msg,MainHelp));
      CallHelp:=HelpHandler;
      HelpAvailable:=Enabled;
    END ELSE HelpAvailable:=Disabled;
  END;
{$IFNDEF NoDebug}
  SysHaltOnError:=PrevStat;
{$ENDIF}
END; {PROC MessageInit}

PROCEDURE MessageDone;
BEGIN
  IF Help<>nil THEN Dispose(Help,Done);
  Help:=nil;
  IF HelpWin<>nil THEN Dispose(HelpWin,Done);
  HelpWin:=nil;
  IF Msg<>nil THEN Dispose(Msg,Done);
  Msg:=nil;
END;

PROCEDURE StartGfxEngine(MsgFileName:String; MainHelp:String);
{ - Save text screen, initialize graphics mode }
VAR
  Fnt : FontSet;
BEGIN
  wOpen(w80x25);  {Closed by LFScrSav unit}
  MessageInit(MsgFileName,MainHelp);
  IF OpenGraph
  THEN BEGIN
    MixPal(AGPal);
    New(WorkSpace,Init(8,TitleH+4,640-16,WSH-8));
    WS:=WorkSpace;
    WorkSpace^.Pane.SetAllBG(WSBG);
    WorkSpace^.Pane.Low.SetFG(PaleYellow);
    Normal:=WorkSpace^.Pane.Norm;
    Bold:=WorkSpace^.Pane.High;
    SetOverScan(DTBG);
    FetchDiskFont(Path+'AGSTD.FNT',Fnt);
    SetFont(@Fnt,8,16);
    ClearDeskTop(PaleYellow,'');
  END;
END; {PROC StartGfxEngine}

PROCEDURE StopGfxEngine;
{ - Terminate graphics mode, restore text screen }
BEGIN
  IF WorkSpace<>nil
  THEN Dispose(WorkSpace,Done);
  WorkSpace:=nil;
  CloseGraph;
  MessageDone;
END; {PROC StopGfxEngine}

FUNCTION YesNo(QT,QQ:String):Boolean;
VAR
  win : PGfxWin;
  Key : PKeyStroke;
  ww  : Integer;
BEGIN
  ww:=Length(QQ);
  IF ww<Length(QT)
  THEN ww:=Length(QT);
  New(Win, InitTxt(38-(ww DIV 2),20,ww+4,3,True));
  New(Key, Init(Win^.WorkSpace, 0,0,[F9, Esc], True));
  Win^.C.Frame.SetDefault(AltGfxWin.Frame);
  Win^.WorkSpace^.Pane.SetDefault(AltGfxWin.Pane);
  Win^.Title(QT,LookUp('YesNo'));
  Win^.Open;
  Win^.WorkSpace^.Center(LineSpacing,PGfxWS(Win^.WorkSpace)^.CC, QQ);
  Key^.WaitForValid;
  Win^.Close;
  YesNo:=Key^.LastChar=F9;
  Dispose(Key, Done);
  Dispose(Win,Done);
END;


PROCEDURE AGToolsIdle(VAR Inp:Word); FAR;
BEGIN
  IF Not ScreenSaveActive
  THEN BEGIN
    DeskTopTime;
    DeskTopHeap;
  END;
END;

CONST
  qx = 100;
  qy = 480-32;

PROCEDURE QuitHandler(VAR Inp:Word); FAR;
CONST
  Prev : LongInt = 0;
  blc  : Word = White;
VAR
  tick : LongInt Absolute $0040:$006C;
BEGIN
  IF Not ScreenSaveActive
  THEN IF Abs(tick-Prev)>3
  THEN BEGIN
    Prev:=Tick;
    gWrt(qx,qy,blc,ExitMsg^);
    IF blc=LightRed THEN blc:=White ELSE Blc:=LightRed;
  END;
END; {PROC QuitHandler}

FUNCTION ConfirmedExit:Boolean;
VAR
  Key  : Keystroke;
BEGIN
  SetOverscan(LightRed);
  DeskTopTitle(LookUp('ExitNow'));
  ClearMsg;
  Key.Init(WorkSpace,0,0,[F9,Esc],True);
  HelpIs(Disabled);
  gWrt(qx+1,qy+1,Black,ExitMsg^);
  Idle.Add(QuitHandler);
  Idle.Enable(QuitHandler);
  Key.WaitforValid;
  ConfirmedExit:=Key.LastChar=F9;
  Idle.Remove(QuitHandler);
  SetOverscan(DTBG);
  HelpIs(Enabled);
  Key.Done;
END; {FUNC ConfirmedExit}

FUNCTION CopyFile(SrcFile,TgtFile:FNameStr):Integer;
CONST
  MaxBuf = 64000;
VAR
  fm       : Byte;
  res      : Integer;
  InBuf    : Word;
  Src, Tgt : File;
  Buffer   : ^Byte;
BEGIN
  fm:=FileMode;
  GetMem(Buffer, MaxBuf);
  {$IFOPT I+} {$DEFINE Iplus} {$I-} {$ENDIF}
  FileMode:=0;
  Assign(Src, SrcFile);
  Reset(Src, 1);
  Res:=IOResult;
  IF Res=0
  THEN BEGIN
    FileMode:=1;
    Assign(Tgt, TgtFile);
    Rewrite(Tgt, 1);
    Res:=IOResult;
  END;
  FileMode:=fm;
  WHILE (Res=0) and not EOF(Src)
  DO BEGIN
    BlockRead(Src, Buffer^, MaxBuf, InBuf);
    BlockWrite(Tgt, Buffer^, InBuf);
    Res:=IOResult;
  END;
  {$IFDef Iplus} {$UNDEF Iplus} {$I+} {$ENDIF}
  Close(Tgt);
  Close(Src);
  FreeMem(Buffer, MaxBuf);
  CopyFile:=Res;
END; {FUNC CopyFile}

PROCEDURE ScreenSave(VAR Inp:Word); FAR;
CONST
  ScrSavExt = '.$AG';
  PROCEDURE Save;
  VAR
    Buf : Pointer;
    f   : File;
    Siz,i : Word;
  BEGIN
    SetOverScan(Red);
    Siz:=PlaneSize(0,0,639,479);
    Assign(f,Path+SystemName+ScrSavExt);
    Rewrite(f,siz);
    GetMem(Buf,Siz);
    FOR i:=0 TO 3
    DO BEGIN
      GetPlane(i,0,0,639,479,Buf^);
      Blockwrite(f,Buf^,1);
    END;
    FreeMem(Buf,Siz);
    Close(f);
    SetOverScan(Black);
  END; {PROC Save}

  PROCEDURE Restore;
  VAR
    Buf : Pointer;
    f   : File;
    Siz,i : Word;
  BEGIN
    Siz:=PlaneSize(0,0,639,479);
    Assign(f,Path+SystemName+ScrSavExt);
    Reset(f,siz);
    GetMem(Buf,Siz);
    BlendPal(AGPal,12);
    FOR i:=0 TO 3
    DO BEGIN
      BlockRead(f,Buf^,1);
      PutPlane(i,0,0,Buf^,NormalPut);
    END;
    SetOverScan(Cyan);
    MixPal(AGPal);
    FreeMem(Buf,Siz);
    Close(f);
  END; {PROC Restore}

CONST
  LastPutMode : Word = 0;
VAR
  PrevCsr : CursorSize;
  Prev    : LongInt;
  tick    : LongInt Absolute $0040:$006C;
  rx,ry   : Integer;
  Key     : Keystroke;
BEGIN
  IF  Not ScreenSaveActive and ScreenSaveEnabled
  THEN IF SecondsSince(TimeSinceKeypressed)
          > {$IFDEF FastDemo} 2*3600 {$ELSE} ScreenSaveTimer  {$ENDIF}
  THEN BEGIN
    ScreenSaveActive:=True;
    Save;
    SetFillStyle(SolidFill,Black);  Bar(0,0,639,479);
    LastPutMode:=PutMode;  PutMode:=xOrPut;
    PrevCsr:=Workspace^.Cursor^.State;
    Workspace^.Cursor^.ChangeState(HiddenCsr);
    Key.Init(WorkSpace,WhereX,WhereY,[^M],True);
    ry:=232 DIV Linespacing;
    rx:=320-(CharSpacing*Length(SavMsg) DIV 2);
    gWrt(rx,ry*LineSpacing,White,SavMsg);
    Prev:=0;
    REPEAT
      Key.Edit;
      IF Abs(tick-Prev)>18
      THEN BEGIN
        Prev:=Tick;
        gWrt(rx,ry*LineSpacing,White,SavMsg);
        REPEAT
          ry:=Random(480 DIV LineSpacing);
        UNTIL ry*LineSpacing<460;
        rx:=Random(639-CharSpacing*Length(SavMsg));
        gWrt(rx,ry*LineSpacing,White,SavMsg);
      END;
    UNTIL Key.Valid;
    Workspace^.Cursor^.ChangeState(PrevCsr);
    PutMode:=LastPutMode;
    Restore;
    StartWatch(TimeSinceKeypressed);
    ScreenSaveActive:=False;
  END;
END;

VAR
  PrevExitHandler : Pointer;

PROCEDURE ExitHandler; FAR;
{ - Abnormal termination handler }
VAR
  U : PMemEntry;
  n : String[34];
  s : String;
  i : Integer;
BEGIN
  ExitProc:=PrevExitHandler;
{$IFDEF Aux}
  Close(Aux);
{$ENDIF}
  IF ErrorAddr<>nil
  THEN BEGIN
    FOR i:=10 DownTo 0
    DO BEGIN
      Delay(25);
      Sound((100*i)+1);
    END;
    Delay(100);
    NoSound;
    AddToLog('Abnormal Termination');
    s:=RTError(ExitCode);
    LogAppend('Ô Error '+IntStr(ExitCode,0)+' at '+PtrStr(ErrorAddr)+' ('+s+')');
 {$IFNDEF NoDebug}
   Writeln(s);
   BreakPoint;
 {$ENDIF}
  END ELSE LogAppend('Ô '+Date+' '+Time+' : Shutdown');
  StopGfxEngine;
  Idle.Remove(ScreenSave);
  Idle.Remove(AGToolsIdle);
  Units.Leave(AGToolsMsg,MemAvail);
END;

PROCEDURE EntryHandler;
VAR
  s : String;
BEGIN
  Idle.Add(AGToolsIdle);
  Idle.Enable(AGToolsIdle);
  Idle.Add(ScreenSave);
  Idle.Enable(ScreenSave);
  Msg:=nil;
  Help:=nil;
  HelpWin:=nil;
  WorkSpace:=nil;
  ErrorLogName:=LFSystem.SystemName+'.LOG';
  ExtMsgError:=ExtMsgErrors;
  Assign(ErrorLog,Path+ErrorLogName);
  IF FSearch(ErrorLogName,BeforeLast('\',Path)) <> Path+ErrorLogName
  THEN BEGIN
    Rewrite(ErrorLog);
    Writeln(ErrorLog,'þ '+LFSystem.SystemName+' system log');
    Close(ErrorLog);
  END;
  LogAppend(^M^J'Õ '+Date+' '+Time+' : Startup');
{$IFDEF Aux}
  Assign(Aux,'AUX');
  Rewrite(Aux);
{$ENDIF}
END;

BEGIN
  PrevExitHandler:=ExitProc;
  ExitProc:=@ExitHandler;
  Units.Enter(AGToolsMsg,MemAvail,CSeg);
  EntryHandler;
END.

