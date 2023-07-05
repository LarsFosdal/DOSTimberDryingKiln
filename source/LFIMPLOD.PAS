{$I CodeDefs.pas}
{$I-,R-,V-,S-,G+,Q-,T-}
{$DEFINE AsmSrc}
UNIT LFImplod;

INTERFACE
{
  This unit handles compression of upto 65000 bytes of data.

  For more reliable handling, the compressed data is prepended with a
  7 byte header:
  Offset  Code  Description
    0     0CBh  RETF - Far return to allow procedural far calls of
                an BINOBJ converted image linked in as an external
                procedure.  This forces loading of the image if
                declared in an overlayed unit.             (Byte)
    1   0FCxxh  Two byte signature                         (Two Bytes)
                xx is the compression method
                01 = Imploding
    3    uuuuh  Uncompressed size of data                  (Word)
    5    cccch  Compressed size of data (including header) (Word)
    7 -> cccch  The compressed data
}
                 { In buffer   Out buffer   Size of IN buffer on entry}
PROCEDURE Implode(VAR Normal; VAR Stuffed:Pointer; VAR Size:Word);
PROCEDURE Explode(VAR Stuffed; VAR Normal:Pointer; VAR NormalSize:Word);
                 { In buffer   Out buffer   Size of OUT buffer on exit}

                 { Outbuffer Pointer allocated by procedures }

FUNCTION ImplodedSize(P:Pointer; VAR NormalSize,StuffedSize:Word):Boolean;


IMPLEMENTATION
CONST
  LZSStag = $01FC;
  MaxBuf  = 65000;    { Maximum 65000 bytes }

TYPE
  pBufar = ^bufar;
  bufar = array[0..MaxBuf-1] of byte; {will be overindexed}

CONST
{ - LZSS Parameters}
  N         = 4096; {Size of string buffer}
  F         = 60;   {60 Size of look-ahead buffer}
  THRESHOLD = 2;
  NODENIL   = N;    {End of tree's node}

{ - Huffman coding parameters}
  N_CHAR    = 256-THRESHOLD+F;
                            {character code (= 0..N_CHAR-1)}
  T         = N_CHAR*2 -1;  {Size of table}
  R         = T-1;          {root position}
  MAX_FREQ  = $8000; {update when cumulative frequency reaches TO this value}

{ - Tables FOR encoding/decoding upper 6 bits of sliding dictionary pointer}
{ - Encoder table}
p_len: array[0..63] of byte =
       ($03,$04,$04,$04,$05,$05,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,
        $06,$06,$06,$06,$06,$06,$06,$06,$07,$07,$07,$07,$07,$07,$07,$07,
        $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,
        $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08);

p_code: array[0..63] of byte =
       ($00,$20,$30,$40,$50,$58,$60,$68,$70,$78,$80,$88,$90,$94,$98,$9C,
        $A0,$A4,$A8,$AC,$B0,$B4,$B8,$BC,$C0,$C2,$C4,$C6,$C8,$CA,$CC,$CE,
        $D0,$D2,$D4,$D6,$D8,$DA,$DC,$DE,$E0,$E2,$E4,$E6,$E8,$EA,$EC,$EE,
        $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF);

{ - Decoder table}
d_code: array[0..255] of byte =
       ($00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
        $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
        $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,
        $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,
        $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,
        $04,$04,$04,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$05,$05,
        $06,$06,$06,$06,$06,$06,$06,$06,$07,$07,$07,$07,$07,$07,$07,$07,
        $08,$08,$08,$08,$08,$08,$08,$08,$09,$09,$09,$09,$09,$09,$09,$09,
        $0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B,
        $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F,
        $10,$10,$10,$10,$11,$11,$11,$11,$12,$12,$12,$12,$13,$13,$13,$13,
        $14,$14,$14,$14,$15,$15,$15,$15,$16,$16,$16,$16,$17,$17,$17,$17,
        $18,$18,$19,$19,$1A,$1A,$1B,$1B,$1C,$1C,$1D,$1D,$1E,$1E,$1F,$1F,
        $20,$20,$21,$21,$22,$22,$23,$23,$24,$24,$25,$25,$26,$26,$27,$27,
        $28,$28,$29,$29,$2A,$2A,$2B,$2B,$2C,$2C,$2D,$2D,$2E,$2E,$2F,$2F,
        $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F);

d_len: array[0..255] of byte =
       ($03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,
        $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,
        $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,
        $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,
        $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,
        $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,
        $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,
        $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,
        $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,
        $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,
        $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,
        $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,
        $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,
        $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,
        $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,
        $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08);

  getbuf: word = 0;
  getlen: byte = 0;
  putbuf: word = 0;
  putlen: word = 0;

  TextSize: LongInt = 0;
  codesize: LongInt = 0;

VAR
  text_buf       : ARRAY [0..N+F-2] of Byte;
  match_position,
  match_length   : word;
  lson, dad      : ARRAY [0..N] of Word;
  rson           : ARRAY [0..N+256] of Word;

  freq           : ARRAY [0..T] of Word; {cumulative freq table}

{ - Pointing parent nodes. area [T..(T + N_CHAR - 1)] are pointers for leaves}
  prnt           : ARRAY [0..T+N_CHAR-1] of Word;

{ - Pointing children nodes (son[], son[] + 1)}
  son            : ARRAY [0..T-1] of Word;

  Inbuf, WorkBuf, OutBuf : pBufar;
  InPtr,OutPtr,MaxSize : Word;


PROCEDURE BufferInit(VAR OrgIn; Stuffing:Boolean); Near;
BEGIN
  Inbuf:=@OrgIn;
  IF Stuffing
  THEN BEGIN
    InPtr:=0;
    OutPtr:=7;
  END
  ELSE BEGIN
    InPtr:=7;
    OutPtr:=0;
  END;
  getbuf:=0;
  getlen:=0;
  putbuf:=0;
  putlen:=0;
  TextSize:=0;
  codesize:=0;
END; {PROC BufferInit}

PROCEDURE GetInfo(VAR Tag,NormalSize,StuffedSize:Word);
BEGIN
  Move(InBuf^[1],Tag,2);
  Move(InBuf^[3],NormalSize,2);
  Move(InBuf^[5],StuffedSize,2);
END; {PROC GetInfo}

PROCEDURE SetInfo(Tag,NormalSize,StuffedSize:Word);
BEGIN
  WorkBuf^[0]:=$CB; {RETF}
  Move(Tag,WorkBuf^[1],2);
  Move(NormalSize,WorkBuf^[3],2);
  Move(StuffedSize,WorkBuf^[5],2);
END; {PROC SetInfo}

FUNCTION getc:byte;     Near;
{ - Read one byte from input buffer}
BEGIN
  getc:=inbuf^[inptr];
  Inc(inptr);
  Dec(MaxSize);
END;{FUNC getc}

PROCEDURE putc(c: byte); Near;
{ - Put one byte to output buffer }
BEGIN
  Workbuf^[outptr]:= c;
  Inc(outptr);
END; {PROC putc}


PROCEDURE InitTree;
{ - Initializing tree}
VAR
  i: word;
BEGIN
  FOR i:= N+1 TO N+256
  DO rson[i]:= NODENIL; {root}
  FOR i:= 0 TO N-1
  DO dad[i]:= NODENIL; {node}
END;{PROC InitTree}


PROCEDURE InsertNode(r: word); {$IFDEF AsmSrc} ASSEMBLER; {$ENDIF}
{ - Inserting node TO the tree}
LABEL
  More,Done;
VAR
  i,p: word;
  geq: boolean;
  c: word;
{$IFDEF AsmSrc}
  ASM
  { geq:= true; }
       mov  geq,True
  { p:= N+1+text_buf[r]; }
       mov  di,r
       mov  al,byte ptr text_buf[di]
       xor  ah,ah
       add  ax,N+1
       mov  p,ax
  { rson[r]:= NODENIL; }
       shl  di,1
       mov  word ptr rson[di],NODENIL
  { lson[r]:= NODENIL; }
       mov  word ptr lson[di],NODENIL
  { match_length := 0; }
       mov word ptr match_length,0
More:
       mov  di,p
       shl  di,1
  { IF geq }
       cmp  byte ptr geq,False
       je   @@L178
  { THEN IF rson[p]=NODENIL }
       cmp  word ptr rson[di],NODENIL
       jne  @@L177
  { rson[p]:= r; }
       mov  ax,r
       mov  word ptr rson[di],ax
  { dad[r] := p; }
       mov  ax,p
       mov  di,r
       shl  di,1
       mov  word ptr dad[di],ax
  { exit }
       jmp  @@Exit
  { END }
       jmp  @@L185
@@L177:
  { ELSE p:= rson[p] }
       mov  ax,word ptr rson[di] {di=p}
       mov  p,ax
       jmp  @@L185

@@L178:
  { ELSE IF lson[p]=NODENIL }
       cmp    word ptr lson[di],NODENIL{di=p}
       jne    @@L184
  { lson[p]:= r; }
       mov ax,r
       mov word ptr lson[di],ax
  { dad[r] := p; }
       mov  ax,p
       mov  di,r
       shl  di,1
       mov  word ptr dad[di],ax
  { exit }
       jmp @@Exit
  { END }
       jmp @@L185
@@L184:
  { ELSE p:= lson[p]; }
       mov  ax,word ptr lson[di]
       mov  p,ax

@@L185:
  { i:= 1; }
       mov  bx,1
@@L186:
  { WHILE (i<F) AND (text_buf[r+i]=text_buf[p+i]) DO Inc(i); }
       mov    di,p
       mov    si,r
@@WHL: cmp  bx,F
       jnb    @@L187
       mov  dl,byte ptr text_buf[bx+di]
       mov  al,byte ptr text_buf[bx+si]
       cmp  al,dl
       jne  @@L187
       inc  bx
       jmp    @@WHL
@@L187:
  { geq:= (text_buf[r+i]>=text_buf[p+i]) or (i=F); }
       mov    dl,byte ptr text_buf[bx+di]
       mov    al,byte ptr text_buf[bx+si]
       cmp    al,dl
       jnb    @@C186
       cmp    bx,F
       je     @@C186
       mov    al,00
       jmp    @@C188
@@C186:mov    al,01
@@C188:mov    geq,al
  { IF i>THRESHOLD }
       cmp  bx,Threshold
       jbe  More
  { IF i>match_length }
       cmp  bx,match_length
       jbe  @@L197
  { match_position := (r-p) AND (N-1) -1; }
       mov  ax,si
       sub  ax,di
       and  ax,N-1
       dec  ax
       mov  match_position,ax
  { match_length:= i; }
       mov  match_length,bx
  { IF match_length>=F THEN goto done; }
       cmp  bx,F
       jb   @@L197
       jmp  Done
@@L197:
  { IF i=match_length }
       cmp  bx,match_length
       jne  More
  { c:= (r-p) AND (N-1) -1; }
       mov  ax,si
       sub  ax,di
       and  ax,N-1
       dec  ax  { ax = c }
  { IF c<match_position }
       cmp  ax,match_position
       jnb  More
  { THEN match_position:= c }
       mov  match_position,ax
  { GOTO More; }
       jmp  More
Done:
  { dad[r]:= dad[p]; }
       shl  di,1
       mov  ax,word ptr dad[di]
       shl  si,1
       mov  word ptr dad[si],ax
  { lson[r]:= lson[p]; }
       mov  ax,word ptr lson[di]
       mov  word ptr lson[si],ax
  { rson[r]:= rson[p]; }
       mov  ax,word ptr rson[di]
       mov  word ptr rson[si],ax
  { dad[lson[p]]:= r; }
       mov  ax,r
       mov  si,word ptr lson[di]
       shl  si,1
       mov  word ptr dad[si],ax
  { dad[rson[p]]:= r; }
       mov  si,word ptr rson[di]
       shl  si,1
       mov  word ptr dad[si],ax
  { IF rson[dad[p]]=p }
       mov  si,word ptr dad[di]
       shl  si,1
       mov  bx,word ptr rson[si]
       cmp  bx,p
       jne  @@L213
  { THEN rson[dad[p]]:= r }
       mov  si,word ptr dad[di]
       shl  si,1
       mov  word ptr rson[si],ax
       jmp  @@L214
@@L213:
  { ELSE lson[dad[p]]:= r; }
       mov  si,word ptr dad[di]
       shl  si,1
       mov  word ptr lson[si],ax
@@L214:
  { dad[p]:=NODENIL; (remove p) }
       mov  word ptr dad[di],NODENIL
@@Exit:
  END;
 {$ELSE}{Not AsmSrc}
BEGIN
  geq:= true;
  p:= N+1+text_buf[r];
  rson[r]:= NODENIL;
  lson[r]:= NODENIL;
  match_length := 0;
More:
    IF geq
    THEN IF rson[p]=NODENIL
    THEN BEGIN
      rson[p]:= r;
      dad[r] := p;
      exit
    END
    ELSE p:= rson[p]
    ELSE IF lson[p]=NODENIL
    THEN BEGIN
      lson[p]:= r;
      dad[r] := p;
      exit
    END
    ELSE p:= lson[p];
    i:= 1;
    WHILE (i<F) AND (text_buf[r+i]=text_buf[p+i]) DO Inc(i);
    geq:= (text_buf[r+i]>=text_buf[p+i]) or (i=F);

    IF i>THRESHOLD
    THEN BEGIN
      IF i>match_length
      THEN BEGIN
        match_position := (r-p) AND (N-1) -1;
        match_length:= i;
        IF match_length>=F THEN goto done;
      END;
      IF i=match_length
      THEN BEGIN
        c:= (r-p) AND (N-1) -1;
        IF c<match_position
        THEN match_position:= c
      END;
    END;
  GOTO More;
Done:
  dad[r]:= dad[p];
  lson[r]:= lson[p];
  rson[r]:= rson[p];
  dad[lson[p]]:= r;
  dad[rson[p]]:= r;
  IF rson[dad[p]]=p
  THEN rson[dad[p]]:= r
  ELSE lson[dad[p]]:= r;
  dad[p]:=NODENIL; {remove p}
END;{PROCEDURE InsertNode}
{$ENDIF}{Not AsmSrc}

PROCEDURE DeleteNode(p:Word);
{ - Delete node from the tree}
VAR
  q: word;
BEGIN
  IF dad[p] =NODENIL
  THEN exit; {unregistered}

  IF rson[p]=NODENIL
  THEN q:= lson[p]
  ELSE IF lson[p]=NODENIL
  THEN q:= rson[p]
  ELSE BEGIN
    q:= lson[p];
    IF rson[q]<>NODENIL
    THEN BEGIN
      REPEAT
        q:=rson[q];
      UNTIL rson[q]=NODENIL;
      rson[dad[q]]:= lson[q];
      dad[lson[q]]:= dad[q];
      lson[q]:= lson[p];
      dad[lson[p]]:= q;
    END;
    rson[q]:= rson[p];
    dad[rson[p]]:= q;
  END;
  dad[q]:= dad[p];
  IF rson[dad[p]]=p
  THEN rson[dad[p]]:= q
  ELSE lson[dad[p]]:= q;
  dad[p]:= NODENIL;
END;{PROC DeleteNode}

FUNCTION GetBit:Byte;
{ -  Get one bit (Used by decoder)}
BEGIN
  WHILE getlen<=8
  DO BEGIN
    getbuf:= getbuf OR (WORD(getc) SHL (8-getlen));
    Inc(getlen,8);
  END;
  GetBit:= getbuf SHR 15;
{///// ?}  {IF (getbuf AND $8000)>0 THEN GetBit:= 1 ELSE GetBit:= 0;}
  getbuf:= getbuf SHL 1;
  Dec(getlen);
END;{FUNC GetBit}

FUNCTION GetByte:Byte;
{ - Get a byte (used by decoder)}
BEGIN
  WHILE getlen<=8
  DO BEGIN
    getbuf:= getbuf OR (WORD(getc) SHL (8 - getlen));
    Inc(getlen,8);
  END;
  GetByte:= Hi(getbuf);
  getbuf:= getbuf SHL 8;
  Dec(getlen,8);
END;{FUNC GetByte}

PROCEDURE Putcode (l: byte; c: word);
{ - Output l bits (used by encoder)}
BEGIN
  putbuf:= putbuf OR (c SHR putlen);
  Inc(putlen,l);
  IF putlen>=8
  THEN BEGIN
    putc(Hi(putbuf));
    Dec(putlen,8);
    IF putlen>=8
    THEN BEGIN
      putc(Lo(putbuf));
      Inc(codesize,2);
      Dec(putlen,8);
      putbuf:= c SHL (l-putlen);
    END
    ELSE BEGIN
      putbuf:= Swap(putbuf AND $FF); {SHL 8;}
      Inc(codesize);
    END
  END
END;{PROC PutCode}

PROCEDURE StartHuff;
{ - Initialize freq tree}
VAR
  i,j: word;
BEGIN
  FOR i:= 0 TO N_CHAR-1
  DO BEGIN
    freq[i]:= 1;
    son[i] := i+T;
    prnt[i+T]:= i
  END;
  i:= 0; j:= N_CHAR;
  WHILE j<=R
  DO BEGIN
    freq[j]:= freq[i]+freq[i+1];
    son[j] := i;
    prnt[i]:= j;
    prnt[i+1]:= j;
    Inc(i,2); Inc(j)
  END;
  freq[T]:= $FFFF;
  prnt[R]:= 0;
END;{PROC StartHuff}

PROCEDURE ReConst;
{ - ReConstruct freq tree (called by Update)}
VAR
  i,j,k,f,l: word;
BEGIN
  { - halven cumulative freq FOR leaf nodes}
  j:= 0;
  FOR i:= 0 TO T-1
  DO IF son[i]>=T
  THEN BEGIN
    freq[j]:= (freq[i]+1) SHR 1;
    son[j] := son[i];
    Inc(j)
  END;
  { - make a tree : first, connect children nodes}
  i:= 0; j:= N_CHAR;
  WHILE j<T
  DO BEGIN
    k:= i+1;
    f:= freq[i]+freq[k];
    freq[j]:= f;
    k:= j-1;
    WHILE f<freq[k] DO Dec(k);
    Inc(k);
    l:= (j-k)*2;

    move(freq[k],freq[k+1],l);
    freq[k]:= f;
    move(son[k],son[k+1],l);
    son[k]:= i;
    Inc(i,2);
    Inc(j)
  END;
  { - connect parent nodes}
  FOR i:= 0 TO T-1
  DO BEGIN
    k:= son[i];
    prnt[k]:= i;
    IF k<T
    THEN prnt[k+1]:= i
  END
END;{PROC ReConst}

PROCEDURE Update(c: word);
{ - Update freq tree (called by EncodeChar,DecodeChar)}
VAR
  i,j,k,l: word;
BEGIN
  IF freq[R]=MAX_FREQ
  THEN reconst;
  c:= prnt[c+T];
  REPEAT
    Inc(freq[c]);
    k:= freq[c];
    { - swap nodes to keep the tree freq-ordered}
    l:= c+1;
    IF k>freq[l]
    THEN BEGIN
      WHILE k>freq[l+1] DO Inc(l);
      freq[c]:= freq[l];
      freq[l]:= k;

      i:= son[c];
      prnt[i]:= l;
      IF i<T
      THEN prnt[i+1]:= l;

      j:= son[l];
      son[l]:= i;

      prnt[j]:= c;
      IF j<T
      THEN prnt[j+1]:= c;
      son[c]:= j;

      c := l;
    END;
    c:= prnt[c]
  UNTIL c=0; {Do it until reaching the root}
END;{PROC Update}

PROCEDURE EncodeChar(c: word);
VAR
  code,len,k: word;
BEGIN
  code:= 0;
  len:= 0;
  k:= prnt[c+T];

  { - search connections from leaf node TO the root}
  REPEAT
    code:= code SHR 1;
    { - IF node's address is odd, output 1 ELSE output 0}
    IF (k AND 1)>0
    THEN Inc(code,$8000);
    Inc(len);
    k:= prnt[k];
  UNTIL k=R;
  Putcode(len,code);
  update(c)
END;{PROC EncodeChar}

PROCEDURE EncodePosition(c: word);
VAR
  i: word;
BEGIN
  { - output upper 6 bits with encoding}
  i:= c SHR 6;
  Putcode(p_len[i], WORD(p_code[i]) SHL 8);
  { - output lower 6 bits directly}
  Putcode(6, (c AND $3F) SHL 10);
END;{PROC EncodePosition}

PROCEDURE EncodeEnd;
BEGIN
  IF putlen>0
  THEN BEGIN
    putc(Hi(putbuf));
    Inc(codesize)
  END
END;{PROC EncodeEnd}


FUNCTION DecodePosition:word;
VAR
  i,j,c: word;
BEGIN
  { - decode upper 6 bits from given table}
  i:= GetByte;
  c:= WORD(d_code[i]) SHL 6;
  j:= d_len[i];
  { - input lower 6 bits directly}
  Dec(j,2);
  WHILE j>0 DO BEGIN
    Dec(j);
    i:= (i SHL 1) OR GetBit;
  END;
  DecodePosition:= c OR (i AND $3F);
END;{FUNC DecodePosition}

{############################################################################}

TYPE
  Wrd = RECORD
    L,H : Byte;
  END;

PROCEDURE Implode(VAR Normal; VAR Stuffed:Pointer; VAR Size:Word);
{ - Encoding/Compressing}
VAR
  i,c,len,r,s,last_match_length,WorkSize : word;
BEGIN
  MaxSize:=Size;
  IF Size=0 THEN exit;
  WorkSize:=Size+7;
  GetMem(WorkBuf,WorkSize);
  BufferInit(Normal,True);
  StartHuff;
  InitTree;
  s:= 0;
  r:= N-F;
  fillchar(text_buf[0],r,' ');
  len:= 0;
  WHILE (len<F) AND (MaxSize>0)
  DO BEGIN
    text_buf[r+len]:= getc;
    Inc(len)
  END;
  TextSize := len;
  FOR i:= 1 TO F DO InsertNode(r - i);
  InsertNode(r);
  REPEAT
    IF match_length>len
    THEN match_length:= len;
    IF match_length<=THRESHOLD
    THEN BEGIN
      match_length := 1;
      EncodeChar(text_buf[r])
    END
    ELSE BEGIN
      EncodeChar(255 - THRESHOLD + match_length);
      EncodePosition(match_position)
    END;
    last_match_length := match_length;
    i:= 0;
    WHILE (i<last_match_length) AND (MaxSize>0)
    DO BEGIN
      Inc(i);
      DeleteNode(s);
      c:= getc;
      text_buf[s]:= c;
      IF s<F-1 THEN text_buf[s+N]:= c;
      s:= (s+1) AND (N-1);
      r:= (r+1) AND (N-1);
      InsertNode(r);
    END;
    Inc(TextSize,i);
    WHILE i<last_match_length
    DO BEGIN
      Inc(i);
      DeleteNode(s);
      s := (s+1) AND (N-1);
      r := (r+1) AND (N-1);
      Dec(len);
      IF len>0 THEN InsertNode(r)
    END;
  UNTIL len=0;
  EncodeEnd;
  CodeSize:=CodeSize+7;
  SetInfo(LZSStag,Size,CodeSize);
  Size:=CodeSize;
  GetMem(Stuffed,CodeSize);
  Move(WorkBuf^,Stuffed^,CodeSize);
  FreeMem(WorkBuf,WorkSize);
END; {PROC Implode}


PROCEDURE Explode(VAR Stuffed; VAR Normal:Pointer; VAR NormalSize:Word);
{ - Decoding/Uncompressing}
VAR
  i,j,k,rr,c,tag : Word;
  StuffedSize   : Word;
  count         : Word;
BEGIN
  BufferInit(Stuffed,False);
  GetInfo(tag,NormalSize,StuffedSize);
  IF Tag<>LZSStag THEN exit;
  IF NormalSize=0 THEN exit;
  MaxSize:=MaxBuf;
  GetMem(Normal,NormalSize);
  WorkBuf:=Normal;

  StartHuff;
  fillchar(text_buf[0],N-F,' ');
  rr:= N-F;
  count:= 0;
  WHILE count<NormalSize
  DO BEGIN
    c:= son[R];
    { - Start searching tree from the root to leaves.
        Choose node #(son[]) if input bit = 0
        else choose #(son[]+1) (input bit = 1) }
    WHILE c<T DO c:= son[c+GetBit];
    Dec(c,T);
    Update(c);
    IF c<256
    THEN BEGIN
      putc(c);
      text_buf[rr]:= c;
      rr:= (rr+1) AND (N-1);
      Inc(count)
    END
    ELSE BEGIN
      i:= (rr-DecodePosition-1) AND (N-1);
      j:= c-255+THRESHOLD;
      FOR k:= 0 TO j-1
      DO BEGIN
        c:= text_buf[(i+k) AND (N-1)];
        putc(c);
        text_buf[rr]:= c;
        rr:= (rr+1) AND (N-1);
        Inc(count)
      END;
    END;
  END;
END; {PROC Explode}

FUNCTION ImplodedSize(P:Pointer; VAR NormalSize,StuffedSize:Word):Boolean;
VAR
  Tag : Word;
BEGIN
  Move(Bufar(p^)[1],Tag,2);
  Move(Bufar(p^)[3],NormalSize,2);
  Move(Bufar(p^)[5],StuffedSize,2);
  IF Tag=LZSStag
  THEN ImplodedSize:=True
  ELSE BEGIN
    ImplodedSize:=False;
    StuffedSize:=NormalSize;
  END;
END; {FUNC ImplodedSize}

END.
