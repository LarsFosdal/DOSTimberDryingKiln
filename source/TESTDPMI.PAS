{$F+}
USES
  {$IFDEF Windows}
  WinCRT,
  {$ENDIF}
  LibUnit;

VAR
  i : Integer;
BEGIN
  FOR i:=11 TO 15
  DO Writeln(GoDoIt(i));
  {$IFNDEF Windows}
  Readln;
  {$ENDIF}
END.
