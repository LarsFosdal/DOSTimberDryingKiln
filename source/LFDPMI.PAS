{$I CODEDEFS.PAS}
UNIT LFDPMI;

INTERFACE

CONST
  ProtectedMode = {$IFDEF DPMI} True {$ELSE} False {$ENDIF};

TYPE
  DPMIHostInfo = RECORD
    Flags    : Word;  { Bit 0 = 1 if 32-bit programs are supported }
    CPU      : Byte;  {02h = 80286  03h = 80386  04h = 80486}
    MinVer   : Byte;  { DPMI minor version number }
    MajVer   : Byte;  { DPMI major version number }
    PrivData : Word;  { Number  of  paragraphs  required  for  DPMI  host
                        private data (may be 0) }
    EnterPM  : Pointer; { Address of procedure to call to enter protected mode }
  END; {REC DPMIHostInfo}


FUNCTION DPMIHostFound:Boolean;
PROCEDURE GetDPMIHostInfo(VAR HostInfo:DPMIHostInfo);
FUNCTION SegmentToSelector(RealSeg:Word):Word; {Func 2}


IMPLEMENTATION

FUNCTION DPMIHostFound:Boolean; ASSEMBLER;
ASM
  mov ax, $1686
  int $2F       {Returns: AX=0 DPMI }
  xor bx,bx
  cmp ax,ax
  jnz @End
  mov bx, 1
@End:
  mov ax, bx
END; {FUNC DPMIHostFound}

PROCEDURE GetDPMIHostInfo(VAR HostInfo:DPMIHostInfo); ASSEMBLER;
{ - Return DPMI Host Info - Doesn't work ?}
ASM
  push DS
  cld
  LES  DI, HostInfo
  push DI
  mov  ax, $1687
  int  $2F       {Returns: AX=0 => DPMI data found }
  mov  AX, DI
  pop  DI
  xchg AX, BX   { BX = Flags }
  stosw
  mov  AL, CL   { CL = Processor type }
  stosb
  mov  AX, DX   { DL = DPMI minor version number }
  stosw         { DH = DPMI major version number }
  mov  AX, SI   { SI =  Number  of  paragraphs  required  for  DPMI  host }
  stosw
  mov  AX, BX   { ES:DI = Address of procedure to call to enter prot.mode }
  stosw
  mov  AX, ES
  stosw
  pop  DS
END; {GetDPMIHostInfo}


FUNCTION SegmentToSelector(RealSeg:Word):Word; ASSEMBLER;
{FUNC 2}
ASM
  mov ax, $0002
  mov bx, RealSeg
  int $31
  jnc @end
  mov ax, $FFFF
@end:
END; {FUNC SegmentToSelector}

END.
