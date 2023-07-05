{$F+}

LIBRARY TestLib;

{The export procedure directive prepares Min and Max for exporting}

FUNCTION GoDoIt(Num:Integer):String; EXPORT;
VAR
  s : String[10];
BEGIN
  Str(Num:5, s);
  GoDoit:=s;
END;


EXPORTS
  GoDoIt index 1;

begin
end.
