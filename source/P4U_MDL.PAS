{$I CODEDEFS.PAS} {Include code generation definitions}
{$X+}
UNIT P4U_MDL;

INTERFACE
USES
  Dos,Objects, LFCrt,
  LFsystem, LFExtMsg, LFDraw, PLCDrive, LFWindow, LFGfxWin,
  P4Config, P4Model, P4U_Gen, P4U_Kiln;

TYPE
  PMdlUnit = ^MdlUnit;
  MdlUnit = OBJECT(KilnUnit)
    FUNCTION    MakeOpMenu:PMenuTxt;      VIRTUAL;
    FUNCTION    StartOK:Boolean;          VIRTUAL;
    FUNCTION    SelectOp:Integer;         VIRTUAL;
    PROCEDURE   Operation;                VIRTUAL;
    PROCEDURE   PLCWrite;                 VIRTUAL;
    PROCEDURE   PLCRead;                  VIRTUAL;
    PROCEDURE   ResumeProcess;            VIRTUAL;
    PROCEDURE   StartProcess;             VIRTUAL;
    PROCEDURE   UpdateProcess;            VIRTUAL;
    PROCEDURE   StopProcess;              VIRTUAL;
    FUNCTION    UpdateDue:Boolean;        VIRTUAL;
    FUNCTION    Describe:String;          VIRTUAL;
  END; {OBJ MdlUnit}

CONST
  MdlUnit_OID = 10008;
  MdlUnit_OSR: TStreamRec = (
    ObjType: MdlUnit_OID;
    VmtLink: Ofs(TypeOf(MdlUnit)^);
    Load:    @MdlUnit.Load;
    Store:   @MdlUnit.Store
  );

IMPLEMENTATION
USES
  Crt,Graph,LFGraph, LFtable,LFString,LFDos,
  ObjInput,AGTools,P4Limits;

{------------------------------------------------------------- MdlUnit ---
  Description

}


FUNCTION MdlUnit.MakeOpMenu:PMenuTxt;
BEGIN
  MakeOpMenu:=Msg^.FindMenu('MDLSLCT');
END; {FUNC MdlUnit.MakeOpMenu}

FUNCTION MdlUnit.StartOK:Boolean;
BEGIN
  StartOK:=(ParamEdit(nil)=F9)
END; {FUNC MdlUnit.StartOK}

FUNCTION MdlUnit.SelectOp:Integer;
BEGIN
  KilnMode:=Stopped;
  SelectOp:=KilnUnit.SelectOp;
END; {FUNC SelectOp}

PROCEDURE MdlUnit.Operation;
VAR
  OldModel : PKilnModel;
  op       : Integer;
BEGIN
  OldModel:=pKilnModel(Model);
  op:=SelectOp;
  CASE Op OF
   1 : Model:=New(pModelM1, InitCopy(OldModel));
   2 : Model:=New(pModel3, InitCopy(OldModel));
   3 : Model:=New(pOwnModel, InitCopy(OldModel));
  END;
  IF op in [1..3]
  THEN BEGIN
    Dispose(OldModel, Done);
    ParamEdit(nil);
  END;
END; {PROC MdlUnit.Operation}

PROCEDURE MdlUnit.PLCWrite;
BEGIN
END; {PROC MdlUnit.PLCWrite}

PROCEDURE MdlUnit.PLCRead;
BEGIN
END; {PROC MdlUnit.PLCRead}

PROCEDURE MdlUnit.ResumeProcess;
{ - Examine PLC to check for NON-PC controlled changes in kiln control}
BEGIN
END; {PROC MdlUnit.ResumeProcess}

PROCEDURE MdlUnit.StartProcess;
{ - Execute kiln startup sequence}
BEGIN
END; {PROC MdlUnit.StartProcess}

PROCEDURE MdlUnit.UpdateProcess;
{ - Walk through kiln registers/coils and look for comm.requests
    Use as Last call from inheritors}
BEGIN
END; {PROC MdlUnit.UpdateProcess}

PROCEDURE MdlUnit.StopProcess;
{ - Execute kiln stop sequence}
BEGIN
END; {PROC MdlUnit.StopProcess}

FUNCTION MdlUnit.UpdateDue:Boolean;
BEGIN
  UpdateDue:=False;
END; {FUNC MdlUnit.UpdateDue}

FUNCTION MdlUnit.Describe:String;
BEGIN
  Describe:='Modell';
END; {FUNC MdlUnit.Describe}


{------------------------------------------------------------- Unit init's ---
}

PROCEDURE RegisterKilnTypes;
BEGIN
  RegisterType(MdlUnit_OSR);
END; {PROC RegisterKilnTypes}

VAR
  PrevExitHandler : Pointer; {Stores the previous exithandler for chain}
CONST
  P4UnitMsg = ' P4U_MDL ';

PROCEDURE P4UnitExitHandler; FAR;
BEGIN
  ExitProc:=PrevExitHandler;
  Units.Leave(P4UnitMsg,MemAvail);
END; {PROC P4UnitExitHandler}

BEGIN
  PrevExitHandler:=ExitProc;
  ExitProc:=@P4UnitExitHandler;
  Units.Enter(P4UnitMsg,MemAvail,CSeg);
  RegisterKilnTypes;
END.

