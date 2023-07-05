{$I CODEDEFS.PAS}

UNIT LFScrSav;

{
  Saves the screen as it looked before start of program
  Must be the _last_ unit in the main program's "uses" clause
}

INTERFACE
IMPLEMENTATION
USES
  Crt,LFCrt;
VAR
  OldExit : Pointer;

PROCEDURE ExitHandler; FAR;
BEGIN
  ExitProc:=OldExit;
  IF wCnt>0
  THEN BEGIN
    TextMode(LastMode);
    REPEAT wClose UNTIL wCnt=0;
  END;
END;

BEGIN
  OldExit:=ExitProc;
  ExitProc:=@ExitHandler;
END.