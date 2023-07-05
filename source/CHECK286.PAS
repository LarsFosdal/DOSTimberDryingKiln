{$I CODEDEFS.PAS} {Include code generation definitions}
{$G-}{We don't want this part to contain 286 code}
(*

  Lars Fosdal, Alfsen & Gunderson A/S

    This unit should be included as the *FIRST* Unit in the main
    section of any program compiled with the {$G} directive enabled.
    If an attempt is made to run the program on an 8086/88/186 based
    machine, the following messages will be displayed:
    "This program requires an 80286 (80386/80486) processor."
    "An <CPUtype> processor was detected.  Program terminated."
    The program will then abort with exit code 1.

  Nov.23,1990 - Lars Fosdal
*)

UNIT Check286;
INTERFACE
IMPLEMENTATION
USES LFsysInf;

VAR
  CPU : Word;
BEGIN {Init Unit Check286}
  CPU:=CPUtype;
  IF (CPU<2) or (CPU=CPUtypeUnknown)
  THEN BEGIN
    Writeln('This program requires an 80286 (80386/80486) processor.');
    Write('An ');
    CASE CPUtype OF
      0 : Write('8086/88');
      1 : Write('80186/188');
      2 : Write('80286');
      3 : Write('80386');
      4 : Write('80486');
     ELSE Write('unknown');
    END;
    Writeln(' processor was detected.  Program terminated.');
    Halt(1); {Terminate program with exit code 1}
  END;
END.
