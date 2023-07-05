{$I CODEDEFS.PAS}

UNIT P4Remote;

INTERFACE
USES
  Objects;

TYPE
  pSysInfo = ^TSysInfo;
  TSysInfo = OBJECT(TOBJECT)
    FileName  : String[8];
    RealName  : String[32];
    ServerDir : FNameStr;
    CONSTRUCTOR Init(_FileName, _RealName, _ServerDir:String);
  END;

VAR
  Monitor   : Boolean;
  RemoteSys : Boolean;
  RemoteSysNames : TCollection;


FUNCTION FindRemoteSystems(FileName:String):Boolean;

IMPLEMENTATION
USES
  P4Config, LFSystem, LFString, Dos,AGTools;

CONSTRUCTOR TSysInfo.Init(_FileName, _RealName, _ServerDir:String);
BEGIN
  FileName:=_FileName;
  RealName:=_RealName;
  ServerDir:=_ServerDir;
END; {CONS TSysInfo.Init}

FUNCTION FindRemoteSystems(FileName:String):Boolean;
VAR
  F : Text;
  N,ID,Dir,dummy  : String;
  fm,i      : Byte;
  BadFile : Boolean;
BEGIN
  LANdir:='';
  fm:=Filemode;
  FileMode:=0;
  BadFile:=False;
  Writeln(Path+FileName+'.INI');
  Assign(F, Path+FileName+'.INI');
{$IFOPT I+}{$DEFINE Iplus}{$I-}{$ENDIF}
  Reset(F);
  RemoteSysNames.Init(4,2);
  IF IOResult=0
  THEN BEGIN
    WHILE not EOF(F)
    DO BEGIN
      Readln(F, N);
      N:=BeforeFirst(';',N);
      DeleteTrailing(' ',N);
      DeleteLeading(' ', N);
      IF not (N[1] in [';','['])
      THEN BEGIN
        ID:=BeforeFirst('=',N);
        DeleteTrailing(' ',ID);
        FOR i:=1 TO Length(ID) DO Id[i]:=Upcase(ID[i]);
        N:=AfterFirst('=', N);   DeleteLeading(' ',N);
        Dir:=BeforeFirst(',',N); DeleteTrailing(' ',Dir);
        FSplit(Dir+'\', Dir, dummy, dummy);
        While (Length(Dir)>1)
          and (Dir[Length(Dir)]='\') and (Dir[Length(Dir)-1]='\')
        DO Dec(Dir[0]);
        N:=AfterFirst(',',N);    DeleteLeading(' ',N);
        IF ID<>SystemName
        THEN BEGIN
          Write(Dir+ID);
          RemoteSysNames.Insert(New(pSysInfo, Init(ID, N, Dir)));
          IF FSearch(Dir+ID+'.CFG', Path)=''
          THEN BEGIN
           { BadFile:=True;}
            Write('?');
          END;
          Write(' - ');
        END
        ELSE LANdir:=Dir;
      END;
    END;
    Close(F);
    fm:=IOResult;
  END
  ELSE BEGIN
    AddToLog(FileName+'.INI not found!');
    Halt;
  END;
{$IFOPT I+}{$DEFINE Iplus}{$I-}{$ENDIF}
  FileMode:=fm;
  FindRemoteSystems:=Not BadFile;
END; {FUNC FindRemoteSystems}

BEGIN
  Monitor:=SystemName=ExeName;
END.