{$I CODEDEFS.PAS}

UNIT LFOvrIni;
INTERFACE
USES Overlay;
IMPLEMENTATION
USES
  Dos;
VAR
  Path    : PathStr;
  OvrFile : NameStr;
  Dummy   : String[2];


FUNCTION OvrErrorMsg(ErrCode:Integer):String;
VAR
  Msg : String;
BEGIN
  Msg:='Overlay error ';
  CASE ErrCode OF
    ovrOK          : Msg:=Msg+': None';
    ovrError       : Msg:=Msg+'-1 : Error in overlay file';
    ovrNotFound    : Msg:=Msg+'-2 : Overlay file not found';
    ovrNoMemory    : Msg:=Msg+'-3 : Not enough memory';
    ovrIOError     : Msg:=Msg+'-4 : File I/O error';
    ovrNoEMSDriver : Msg:=Msg+'-5 : No EMS driver installed';
    ovrNoEMSMemory : Msg:=Msg+'-6 : Not enough EMS memory';
                ELSE Msg:=Msg+': Unknown overlay error';
  END;
  OvrErrorMsg:=Msg;
END;


BEGIN
  Path:=ParamStr(0);
  FSplit(ParamStr(0),Path,OvrFile,Dummy);
  OvrInit(Path+OvrFile+'.OVR');
  IF OvrResult <> ovrOk
  THEN BEGIN
    Writeln(OvrErrorMsg(OvrResult));
    WriteLn('Overlay manager init failed.');
    Writeln('(',Path+OvrFile,')');
    Halt(1);
  END
  ELSE Writeln('Overlay manager installed.');
  Write('Expanding buffer from ',OvrGetBuf);
  OvrSetBuf(OvrGetBuf+32*1024);
  Writeln(' to ',OvrGetBuf,' bytes.');
{$IFDEF UseEMS}
  OvrInitEMS;
  IF OvrResult <> ovrOk
  THEN BEGIN
    Writeln(OvrErrorMsg(OvrResult));
    WriteLn('EMS overlay manager init failed.');
    Writeln('Using conventional memory.');
  END
  ELSE WriteLn('Using EMS for faster overlay swapping.');
{$ENDIF}
END.
