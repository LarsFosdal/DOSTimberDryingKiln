{$I CODEDEFS.PAS} {Include code generation definitions}
{$X+}
UNIT LFString;

INTERFACE
USES
  LFSystem,DOS,Objects;
CONST
  LFStringMsg = ' LFstring.1 19900311 Lars Fosdal ';

TYPE
  str2    = String[2];
  str4    = String[4];
  str8    = String[8];
  str16   = String[16];
  str20   = String[20];
  Str80   = String[80];

PROCEDURE UpSt(VAR St);
PROCEDURE CaseUp(VAR s:String);
PROCEDURE CaseLow(VAR s:String);
PROCEDURE ASCIIFY(VAR s:String);
FUNCTION  Rep(Count:Integer; ch:Char):String;
FUNCTION  FillOut(L,p:Byte; fyll:Char):String;
FUNCTION  BeforeLast(Match:char; st:string):String;
FUNCTION  AfterLast(Match:char; st:string):String;
FUNCTION  BeforeFirst(Match:char; st:String):String;
FUNCTION  AfterFirst(Match:char; st:string):String;
FUNCTION  StripAll(Ch:Char; st:String):String;
FUNCTION  SwapAll(Ch,ToCh:Char; st:String):String;
PROCEDURE DeleteLeading(Ch:Char; VAR st);
PROCEDURE DeleteTrailing(Ch:Char; VAR st);
FUNCTION  PadLeading(st:String; ch:Char; max:Byte):String;
FUNCTION  PadTrailing(st:String; ch:Char; max:Byte):String;
FUNCTION  IntStr(intNum:Longint; places:byte):str20;
FUNCTION  FloatStr(FloatNum:Float; places,decimals:ShortInt):str20;
FUNCTION  PtrStr(p:Pointer):Str16;
FUNCTION  BinB(byt:byte):Str8;
FUNCTION  BinW(wrd:Word):Str16;
FUNCTION  OctB(byt:byte):Str4;
FUNCTION  OctW(wrd:Word):Str8;
FUNCTION  HexB(Byt:byte):Str2;
FUNCTION  HexBW(h,l:byte):Str4;
FUNCTION  HexW(Wrd:Word):Str4;
FUNCTION  HexL(Long:LongInt):Str8;
FUNCTION  unASCIIZ(VAR asciiz):String;

CONST
  MaxBuf = 64000;

TYPE

  PRepLine = ^RepLine;
  RepLine = OBJECT(TObject)
    Txt : PString;
    CONSTRUCTOR Init(NewEntry:String);
    DESTRUCTOR  Done;                            VIRTUAL;
  END; {OBJ RepLine}

  PReport = ^Report;
  Report = OBJECT(TCollection)
    CurrLine : String;
    CONSTRUCTOR Init;
    PROCEDURE Add(Txt:String);
    PROCEDURE Addln(Txt:String);
    PROCEDURE Newln;
    PROCEDURE Output(FileName:String);
    FUNCTION Line(n:Integer):String;
  END; {OBJ Report}

  Ch = ARRAY[0..MaxBuf-1] OF Char;
  CharSet = Set Of Char;
  TextFile = OBJECT
    Fil     : File;
    FilSize : LongInt;
    Line    : LongInt;
    Buffer  : Pointer;
    BufSize : Word;
    BufBase : LongInt;
    idx     : Word;
    Tail    : Word;
    EOF     : Boolean;
    CONSTRUCTOR OpenRead(FileName:String);
    CONSTRUCTOR OpenWrite(FileName:String);
    DESTRUCTOR  Done; VIRTUAL;
    { - read }
    FUNCTION    NextChar:Char;
    FUNCTION    GetChar:Char;
    PROCEDURE   Skip(n:LongInt);
    PROCEDURE   SkipLines(n:LongInt);
    PROCEDURE   SkipUntil(c:Char);
    PROCEDURE   SkipUntilBoth(c1,c2:Char);
    PROCEDURE   SkipUntilIn(c:CharSet);
    PROCEDURE   SkipWhile(c:Char);
    PROCEDURE   SkipWhileIn(c:CharSet);
    PROCEDURE   Target(s:String; VAR Bytes,Lines:Word);
    PROCEDURE   Copy(n:LongInt; VAR s:String);
    PROCEDURE   CopyUntil(c:Char; VAR s:String);
    PROCEDURE   CopyUntilBoth(c1,c2:Char; VAR s:String);
    PROCEDURE   CopyUntilIn(c:CharSet; VAR s:String);
    PROCEDURE   CopyWhile(c:Char; VAR s:String);
    PROCEDURE   CopyWhileIn(c:CharSet; VAR s:String);
    PROCEDURE   GetLine(VAR lin:String);
    PROCEDURE   NextLine;
    PROCEDURE   SkipEOL;
    FUNCTION    EOL:Boolean;
    FUNCTION    FilPos:LongInt;
    PROCEDURE   Seek(p:LongInt);
    PROCEDURE   BufClear;
    PROCEDURE   Clone(p,n:LongInt; VAR f:TextFile);
    PROCEDURE   MakeText(p,Lines:LongInt; VAR Rpt:PReport);
    PROCEDURE   Put(VAR Buf; bytes:Word);
    PROCEDURE   sPut(s:String);
    PROCEDURE   sPutLn(s:String);
    PROCEDURE   Flush;
  END;

IMPLEMENTATION
TYPE
  CaseTable = ARRAY[128..165] OF Char;


CONST              { €‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ ¡¢£¤¥   { Normal }
  UCT : CaseTable = '€šAŽA€EEEIIIŽ’’O™OUUY™šœžŸAIOU¥¥'; { Uppercase }
CONST
  LCT : CaseTable = '‡‚ƒ„…†‡ˆ‰Š‹Œ„†‚‘‘“”•–—˜”›œ›žŸ ¡¢£¤¤'; { Lowercase }
CONST
  ACT : CaseTable = 'cueaaaaceeeiiiaaeeeooouuyouolopfaiounn'; { ASCIIfied }
CONST
  SCT : CaseTable = 'CYEA[A]CEEEIII[]E[[O\OUUY\Y\L\PFAIOUNN'; { Sortkey }
CONST
  LFbinhex_b : Array[0..15] of Str8=
     ('0000','0001','0010','0011','0100','0101','0110','0111',
      '1000','1001','1010','1011','1100','1101','1110','1111');
CONST
  LFbinhex_hx : Array[0..15] of char =
     ('0','1','2','3','4','5','6','7',
      '8','9','A','B','C','D','E','F');


PROCEDURE UpSt(VAR st);
BEGIN
  INLINE($C4/$BE/St /$26/$8A/$0D/$FE/$C1/$FE/$C9/$74/$13/$47/$26/$80/
   $3D/$61/$72/$F5/$26/$80/$3D/$7A/$77/$EF/$26/$80/$2D/$20/$EB/$E9);
END;{UpSt}

PROCEDURE CaseUp(VAR s:String); ASSEMBLER;
ASM
   push ds
   lea  bx,UCT
   les  di,S
        mov  cl,es:[di]
        xor  ch,ch
@NxtCh: inc  di
        mov  al,es:[di]
        cmp  al,165
        ja   @Skip     { skip if > 165 (¥) }
        cmp  al,127
        ja   @Xlt      { translate if >= 127 (€) }
        cmp  al,97
        jb   @Skip     { skip if < 97 (a) }
        cmp  al,122
        ja   @Skip     { skip if > 122 (z)}
        and  al,11011111b
        jmp  @OK
@Xlt:   and  al, 07Fh
        xlat
@OK:    mov  es:[di],al
@Skip:  loop @NxtCh
   pop  ds
END; {PROC CaseUp}

PROCEDURE CaseLow(VAR s:String); ASSEMBLER;
ASM
   push ds
   lea  bx,LCT
   les  di,S
        mov  cl,es:[di]
        xor  ch,ch
@NxtCh: inc  di
        mov  al,es:[di]
        cmp  al,165
        ja   @Skip     { skip if > 165 (¥) }
        cmp  al,127
        ja   @Xlt      { translate if >= 127 (€) }
        cmp  al,65
        jb   @Skip     { skip if < 65 (A) }
        cmp  al,90
        ja   @Skip     { skip if > 90 (Z)}
        or  al,00100000b
        jmp  @OK
@Xlt:   and  al, 07Fh
        xlat
@OK:    mov  es:[di],al
@Skip:  loop @NxtCh
   pop  ds
END; {PROC CaseLow}

PROCEDURE ASCIIFY(VAR s:String); ASSEMBLER;
ASM
   push ds
   lea  bx,ACT
   les  di,S
        mov  cl,es:[di]
        xor  ch,ch
@NxtCh: inc  di
        mov  al,es:[di]
        cmp  al,165
        ja   @Skip     { skip if > 165 (¥) }
        cmp  al,127
        ja   @Xlt      { translate if >= 127 (€) }
        jmp  @Skip
@Xlt:   and  al, 07Fh
        xlat
@OK:    mov  es:[di],al
@Skip:  loop @NxtCh
   pop  ds
END; {PROC ASCIIFY}

PROCEDURE SortKey(VAR s:String); ASSEMBLER;
ASM
   push ds
   lea  bx,SCT
   les  di,S
        mov  cl,es:[di]
        xor  ch,ch
@NxtCh: inc  di
        mov  al,es:[di]
        cmp  al,165
        ja   @Skip     { skip if > 165 (¥) }
        cmp  al,127
        ja   @Xlt      { translate if >= 127 (€) }
        cmp  al,97
        jb   @Skip     { skip if < 97 (a) }
        cmp  al,122
        ja   @Skip     { skip if > 122 (z)}
        and  al,11011111b
        jmp  @OK
@Xlt:   and  al, 07Fh
        xlat
@OK:    mov  es:[di],al
@Skip:  loop @NxtCh
   pop  ds
END; {PROC SortKey}

FUNCTION Rep(Count:Integer; ch:Char):String;
{ - Create a string of length=Count composed by the character=ch }
VAR
  n : Byte;
  s : String;
BEGIN
  s:='';
  IF Count>0
  THEN FOR n:=1 TO Count DO s:=s+ch;
  Rep:=s;
END; {FUNC Rep}

FUNCTION Fillout(L,p:Byte;fyll:Char):String;
{ - Create a padding string of length L-p }
BEGIN
  FillOut:=Rep(L-p,fyll);
END; {FUNC FillOut}

FUNCTION AfterLast(Match:char;st:string):String;
{ - AfterLast("\","C:\DIR\DATA\FIL.TXT") = FIL.TXT }
VAR
  index : Word;
BEGIN
  IF pos(Match,st)<>0 THEN
  BEGIN
    index:=Byte(st[0]);
    WHILE st[index]<>Match DO dec(index);
    AfterLast:=Copy(st,index+1,succ(Byte(st[0])-index));
  END
   ELSE AfterLast:='';
END;{AfterLast}

FUNCTION BeforeLast(Match:char;st:string):String;
{ - BeforeLast('\','C:\DIR\DATA\FIL.TXT") = 'C:\DIR\DATA' }
VAR
  index : Word;
BEGIN
  IF pos(Match,st)<>0 THEN
  BEGIN
    index:=Byte(st[0]);
    WHILE st[index]<>Match DO dec(index);
    BeforeLast:=Copy(st,1,index-1);
  END
   ELSE BeforeLast:='';
END;{BeforeLast}

FUNCTION AfterFirst(Match:char;st:string):String;
{ - AfterFirst("\","C:\DIR\DATA\FIL.TXT") = "DIR\DATA\FIL.TXT" }
VAR
  index : Word;
BEGIN
  index:=pos(Match,st);
  IF index<>0
  THEN AfterFirst:=Copy(st,index+1,succ(Byte(st[0])-index))
  ELSE AfterFirst:=st;
END;{AfterFirst}

FUNCTION BeforeFirst(Match:char;st:string):String;
{ - BeforeFirst('\','C:\DIR\DATA\FIL.TXT") = 'C:' }
VAR
  index : Word;
BEGIN
  index:=pos(Match,st);
  IF index<>0
  THEN BeforeFirst:=Copy(st,1,index-1)
  ELSE BeforeFirst:=st;
END;{BeforeFirst}



FUNCTION StripAll(Ch:Char; st:String):String;
{ - StripAll('.','S.O.S.') = 'SOS' }
VAR
  index : Word;
BEGIN
  Index:=pos(Ch,st);
  WHILE Index<>0
  DO BEGIN
    Delete(st,Index,1);
    Index:=pos(Ch,st);
  END;
  StripAll:=st;
END; {FUNC StripAll}

FUNCTION SwapAll(Ch,ToCh:Char; st:String):String;
{ - SwapAll('#','$','#44#55#66') = '$44$55$66'}
VAR
  index : Word;
BEGIN
  Index:=pos(Ch,st);
  WHILE Index<>0
  DO BEGIN
    st[Index]:=ToCh;
    Index:=pos(Ch,st);
  END;
  SwapAll:=st;
END; {FUNC SwapAll}

PROCEDURE DeleteLeading(Ch:Char; VAR st);
{ - DeleteLeading('A','AAAAABCDEF') = 'BCDEF' }
BEGIN
  WHILE (String(st)[1]=ch) and (Byte(st)>0) DO Delete(String(st),1,1);
END;{DeleteLeading}

PROCEDURE DeleteTrailing(Ch:Char; VAR st);
{ - DeleteTrailing('F','ABCDEFFFF') = 'ABCDE' }
BEGIN
  WHILE (String(st)[Byte(st)]=ch) and (Byte(st)>0) DO Dec(Byte(st));
END;{DeleteTrailing}

FUNCTION PadLeading(st:String; ch:Char; max:Byte):String;
{ - PadLeading('TEST','-',10) = '------TEST' }
BEGIN
  PadLeading:=FillOut(max,Byte(st[0]),ch)+st;
END;{PadLeading}

FUNCTION PadTrailing(st:String; ch:Char; max:Byte):String;
{ - PadTrailing(' TEST','-',10) = 'TEST------' }
BEGIN
  PadTrailing:=st+FillOut(max,Byte(st[0]),ch);
END;{PadTrailing}

FUNCTION IntStr(intNum:Longint; places:byte):str20;
{ - IntStr(24,4) = '  24' }
CONST s : str20 ='';
BEGIN
  str(intNum:places,s);
  IntStr:=s;
END;{IntStr}

FUNCTION FloatStr(FloatNum:Float; places,decimals:ShortInt):str20;
{ - FloatStr(24,4) = '  24' }
VAR
  s : str20;
BEGIN
  IF (places<0) or (decimals<0) THEN Str(FloatNum,s)
   ELSE str(FloatNum:places:decimals,s);
  FloatStr:=s;
END; {FUNC FloatStr}

FUNCTION PtrStr(p:Pointer):Str16;
{$IFDEF DPMI}
VAR
  W : RECORD
    O,S : Word;
  END Absolute p;
{$ENDIF}
BEGIN
{$IFDEF DPMI}
  PtrStr:=HexW(W.S)+':'+HexW(W.O);
{$ELSE}
  PtrStr:=HexW(Seg(p^))+':'+HexW(Ofs(p^));
{$ENDIF}
END; {FUNC PtrStr}

FUNCTION BinB(byt:byte):Str8;
{ - Make bitpattern string from input byte}
BEGIN
  BinB:=LFbinhex_b[byt SHR 4]
       +LFbinhex_b[byt and $0F];
END; {FUNC BinB}

FUNCTION BinW(wrd:Word):Str16;
{ - Make bitpattern string from input word}
BEGIN
  BinW:=BinB(wrd shr 8)
       +BinB(wrd and $FF);
END; {FUNC BinW}

FUNCTION OctB(byt:byte):Str4;
{ - Make Octal string from input byte}
BEGIN
  OctB:=LFbinhex_hx[(byt SHR 6) and $07]
       +LFbinhex_hx[(byt SHR 3) and $07]
       +LFbinhex_hx[byt and $07];
END; {FUNC OctB}

FUNCTION OctW(wrd:Word):Str8;
{ - Make Octal string from input word}
BEGIN
  OctW:=LFbinhex_hx[(wrd SHR 15)]
       +LFbinhex_hx[(wrd SHR 12) and $07]
       +LFbinhex_hx[(wrd SHR 9) and $07]
       +LFbinhex_hx[(wrd SHR 6) and $07]
       +LFbinhex_hx[(wrd SHR 3) and $07]
       +LFbinhex_hx[wrd and $07];
END; {FUNC OctW}

FUNCTION HexB(Byt:byte):Str2;
{ - Make hexadecimal string from input byte}
BEGIN
  HexB:=LFbinhex_hx[Byt SHR 4]+LFbinhex_hx[Byt and $0F];
END; {FUNC hex}

FUNCTION HexBW(h,l:byte):Str4;
{ - Make hexadecimal word string from input bytes}
BEGIN
  HexBW:=HexB(h)+HexB(l);
END; {FUNC HexBW}

FUNCTION HexW(Wrd:Word):Str4;
{ - Make hexadecimal string from input word}
BEGIN
  HexW:=HexB(Wrd shr 8)+HexB(Wrd and $FF);
END; {FUNC HexW}

FUNCTION HexL(Long:LongInt):Str8;
{ - Make hexadecimal string from input longint}
BEGIN
  HexL:=HexW(Long shr 16)+HexW(Long and $FFFF);
END; {FUNC HexL}

FUNCTION unASCIIZ(VAR asciiz):String;
VAR
  s   : String;
  len : byte;
BEGIN
  move(asciiz, s[1],255);
  Len:=0;
  While (s[Len+1]<>#0) and (len<255) DO Inc(len);
  s[0]:=chr(len);
  unASCIIZ:=s;
END; {FUNC unASCIIZ}

{----------------------------------------------------------------- Report ---}

CONSTRUCTOR RepLine.Init(NewEntry:String);
{ - Insert sorted/Allocate the message}
BEGIN
  TObject.Init;
  PSNew(Txt,NewEntry);   {Set message Txt}
END; {CONS RepLine.Init}

DESTRUCTOR RepLine.Done;
{ - DeAllocate the index entry}
BEGIN
  PSDispose(Txt);
  TObject.Done;
END; {DEST RepLine.Done}




CONSTRUCTOR Report.Init;
{ - Initalize report table and clear first line}
BEGIN
  TCollection.Init(72,72);
  CurrLine:='';
END; {CONS Report.Init}

PROCEDURE Report.Add(Txt:String);
{ - Add txt to Current Line }
BEGIN
  CurrLine:=Currline+Txt;
END; {PROC Report.Add}

PROCEDURE Report.AddLn(Txt:String);
{ - Add txt to Current Line and create new empty line }
BEGIN
  Add(Txt);
  Insert(New(PRepLine,Init(CurrLine)));
  CurrLine:='';
END; {PROC Report.Addln}

PROCEDURE Report.NewLn;
{ - Create new empty line }
BEGIN
  Addln('');
END; {PROC Report.NewLn}

PROCEDURE Report.Output(FileName:String);
{ - Output report to file }
VAR
  Out : Text;
  PROCEDURE Line_Store(Line:PRepLine); FAR;
  { - Outputs a single line }
  BEGIN
    Writeln(Out,Line^.Txt^);
  END;
BEGIN
  Assign(Out,FileName);
  Rewrite(Out);
  ForEach(@Line_Store);
  Close(Out);
END; {PROC Report.Output}

FUNCTION Report.Line(n:Integer):String;
BEGIN
  Line:=PRepLine(At(n))^.Txt^;
END;


{--------------------------------------------------------------- TextFile ---}

CONSTRUCTOR TextFile.OpenRead(FileName:String);
BEGIN
  Assign(Fil,FileName);
  Reset(Fil,1);
  FilSize:=FileSize(Fil);
  IF FilSize<MaxBuf
  THEN BufSize:=FilSize
  ELSE BufSize:=MaxBuf;
  GetMem(Buffer,BufSize+255);
  BufBase:=0;
  Tail:=0;
  idx:=0;
  Line:=1;
  EOF:=idx+BufBase>=FilSize;
END; {CONS TextFile.OpenRead}

CONSTRUCTOR TextFile.OpenWrite(FileName:String);
BEGIN
  Assign(Fil,FileName);
  Rewrite(Fil,1);
  FilSize:=0;
  BufSize:=MaxBuf;
  GetMem(Buffer,BufSize+255);
  BufBase:=0;
  Tail:=0;
  idx:=0;
  Line:=1;
  EOF:=idx+BufBase>=FilSize;
END; {CONS TextFile.OpenWrite}

DESTRUCTOR TextFile.Done;
BEGIN
  FreeMem(Buffer,BufSize+255);
  Close(Fil);
END; {DEST TextFile.Done}

FUNCTION TextFile.NextChar:Char;
BEGIN
  IF (idx>=Tail)
  THEN BEGIN
    BufBase:=BufBase+Tail;
    idx:=0;
    IF Not EOF
    THEN BlockRead(Fil,Buffer^,BufSize,Tail);
  END;
  NextChar:=Ch(Buffer^)[idx];
END; {FUNC TextFile.NextChar}

FUNCTION TextFile.GetChar:Char;
VAR
  c : Char;
BEGIN
  IF (idx>=Tail)
  THEN BEGIN
    BufBase:=BufBase+Tail;
    idx:=0;
    IF Not EOF
    THEN BlockRead(Fil,Buffer^,BufSize,Tail);
  END;
  c:=Ch(Buffer^)[idx];
  Inc(idx);
  IF c=^J THEN Inc(Line);
  EOF:=idx+BufBase>=FilSize;
  GetChar:=c;
END; {FUNC TextFile.GetChar}

PROCEDURE TextFile.Skip(n:LongInt);
BEGIN
  WHILE (n>0) and not EOF
  DO BEGIN
    GetChar;
    Dec(n);
  END;
END; {PROC TextFile.Skip}

PROCEDURE TextFile.SkipLines(n:LongInt);
VAR
  p : LongInt;
BEGIN
  p:=Line;
  WHILE Not EOF and (Line-p<n)
  DO NextLine;
END; {PROC TextFile.SkipLines}

PROCEDURE TextFile.SkipUntil(c:Char);
BEGIN
  WHILE (NextChar<>c) and not EOF
  DO GetChar;
END; {PROC TextFile.SkipUntil}

PROCEDURE TextFile.SkipUntilBoth(c1,c2:Char);
VAR
  c : Char;
BEGIN
  c:=GetChar;
  WHILE ((c<>c1) or (NextChar<>c2)) and Not EOF
  DO c:=GetChar;
END; {PROC TextFile.CopyUntilBoth}

PROCEDURE TextFile.SkipUntilIn(c:CharSet);
BEGIN
  WHILE not (NextChar in c) and not EOF
  DO GetChar;
END; {PROC TextFile.SkipUntilIn}

PROCEDURE TextFile.Target(s:String; VAR Bytes,Lines:Word);
VAR
  t : String;
  i : Word;
BEGIN
  t:=s;
  i:=Length(s);
  Bytes:=0; Lines:=Line;
  Move(t[2],t[1],i);
  WHILE not EOF and (t<>s)
  DO BEGIN
    Move(t[2],t[1],i);
    t[i]:=GetChar;
    Inc(Bytes);
  END;
  Bytes:=Bytes-Length(s);
  Lines:=Line-Lines;
END;

PROCEDURE TextFile.Copy(n:LongInt; VAR s:String);
BEGIN
  s:='';
  WHILE (n>0) and not EOL
  DO BEGIN
    s:=s+GetChar;
    Dec(n);
  END;
END; {PROC TextFile.Copy}

PROCEDURE TextFile.CopyUntil(c:Char; VAR s:String);
BEGIN
  WHILE (NextChar<>c) and not EOL
  DO s:=s+GetChar;
  IF NOT EOL THEN s:=s+GetChar;
END; {PROC TextFile.CopyUntil}

PROCEDURE TextFile.CopyUntilBoth(c1,c2:Char; VAR s:String);
VAR
  c : Char;
BEGIN
  c:=GetChar;
  s:=c;
  WHILE ((c<>c1) or (NextChar<>c2)) and Not EOL
  DO BEGIN
    c:=GetChar;
    s:=s+c;
  END;
  IF NOT EOL THEN s:=s+GetChar;
END; {PROC TextFile.CopyUntilBoth}

PROCEDURE TextFile.CopyUntilIn(c:CharSet; VAR s:String);
BEGIN
  s:='';
  WHILE not (NextChar in c) and not EOL
  DO s:=s+GetChar;
  IF NOT EOL THEN s:=s+GetChar;
END; {PROC TextFile.CopyUntilIn}

PROCEDURE TextFile.SkipWhile(c:Char);
BEGIN
  WHILE (NextChar=c) and not EOF
  DO GetChar;
END; {PROC TextFile.SkipWhile}

PROCEDURE TextFile.SkipWhileIn(c:CharSet);
BEGIN
  WHILE (NextChar in c) and not EOF
  DO GetChar;
END; {PROC TextFile.SkipWhileIn}

PROCEDURE TextFile.CopyWhile(c:Char; VAR s:String);
BEGIN
  s:='';
  WHILE (NextChar=c) and not EOL
  DO s:=s+GetChar;
  IF NOT EOL THEN s:=s+GetChar;
END; {PROC TextFile.CopyWhile}

PROCEDURE TextFile.CopyWhileIn(c:CharSet; VAR s:String);
BEGIN
  s:='';
  WHILE (NextChar in c) and not EOL
  DO s:=s+GetChar;
END; {PROC TextFile.CopyWhileIn}

PROCEDURE TextFile.GetLine(VAR lin:String);
BEGIN
  lin:='';
  WHILE not EOL DO lin:=lin+GetChar;
  SkipEOL;
END; {PROC TextFile.GetLine}

PROCEDURE TextFile.SkipEOL;
VAR
  p : LongInt;
BEGIN
  p:=Line;
  WHILE (NextChar IN [^M,^J]) and (not EOF) and (p=Line)
  DO GetChar;
END; {PROC TextFile.SkipEOL}

PROCEDURE TextFile.NextLine;
BEGIN
  SkipUntilIn([^M,^J]);
  SkipEOL;
END; {PROC TextFile.NextLine}

FUNCTION TextFile.EOL:Boolean;
BEGIN
  EOL:=(NextChar IN [^M,^J]) or EOF;
END; {FUNC TextFile.EOL}

(*
FUNCTION TextFile.EOF:Boolean;
BEGIN
  EOF:=idx+BufBase>=FilSize;
END; {FUNC TextFile.EOF}
*)
FUNCTION TextFile.FilPos:LongInt;
BEGIN
  FilPos:=BufBase+Idx;
END;

PROCEDURE TextFile.Seek(p:LongInt);
BEGIN
  IF p<FilSize
  THEN BEGIN
    System.Seek(Fil,p);
    BufBase:=p;
    Tail:=0;
    idx:=0;
    Line:=1;
  END;
END;

PROCEDURE TextFile.BufClear;
BEGIN
  IF FilSize<MaxBuf
  THEN BufSize:=FilSize
  ELSE BufSize:=MaxBuf;
  BufBase:=0;
  Tail:=0;
  idx:=0;
  Line:=1;
END; {PROC TextFile.BufClear}

PROCEDURE TextFile.Clone(p,n:LongInt; VAR f:TextFile);
BEGIN
  Seek(p);
  NextChar;
  f.Put(Buffer^,n);
END; {PROC TextFile.Clone}

PROCEDURE TextFile.MakeText(p,Lines:LongInt; VAR Rpt:PReport);
VAR
  n : LongInt;
  l : String;
BEGIN
  Seek(p);
  n:=0;
  WHILE not EOF and (n<Lines)
  DO BEGIN
    GetLine(l);
    Rpt^.AddLn(l);
    Inc(n);
  END;
END;

PROCEDURE TextFile.Flush;
BEGIN
  BlockWrite(Fil, Buffer^, idx);
  BufBase:=BufBase+idx;
  idx:=0;
END;

PROCEDURE TextFile.Put(VAR Buf; Bytes:Word);
BEGIN
  IF LongInt(idx)+Bytes>=BufSize
  THEN Flush;
  Move(Buf, Ch(Buffer^)[idx], Bytes);
  idx:=idx+Bytes;
END; {FUNC TextFile.Put}

PROCEDURE TextFile.sPut(s:String);
BEGIN
  Put(s[1],Length(s));
END;

PROCEDURE TextFile.sPutLn(s:String);
BEGIN
  sPut(s);
  sPut(^M^J);
END;


BEGIN
  Units.Enter(LFStringMsg,MemAvail,CSeg);
END.
