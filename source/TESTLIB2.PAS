{$F+}

LIBRARY TestLib;

{The export procedure directive prepares Min and Max for exporting}

FUNCTION GoDoIt(Num:Integer):String; EXPORT;
VAR
  s,s2 : String[10];
  i,l : Integer;
BEGIN
  Str(Num:5, s);
  s2:=s;
  l:=Length(s);
  FOR i:=1 TO l
  DO s[i]:=s2[l-i+1];
  GoDoit:=s;
END;


EXPORTS
  GoDoIt index 1;

begin
end.
