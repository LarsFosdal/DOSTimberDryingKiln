 (*****************************************************************************
 This is an Includefile for most LFxxxxxx-units and other sources.
 The compiler switches defined herein, controls the most important
 code generation options.

 Switches:
   {$Symbol}   Defined
   { $Symbol}  NOT defined

*****************************************************************************)

{ $DEFINE Local}
        { - Define if this file NOT should determine codegeneration}

{         Symbol      Effect when defined                         Normally}
{$DEFINE NoDebug}    {Turns off debug info and runtime checking  Defined}
{$DEFINE NoIEEE}     {Turns off IEEE FPU-lib./Emulation           Defined}
{$DEFINE Demo}       {For your convenience :-)                   Not Def.}
{$DEFINE NoSerial}   {To disable serial port access              Not Def.}
{ $DEFINE NoDisk}     {To disable disk or floppy I/O              Not Def.}
{$DEFINE NoNet}      {To disable LAN support                      Not Def.}

{ $DEFINE SimReal}    {*** must *NOT* be defined in release versions}
                     {Define when debugging only. Affects PLCIF and MelsecF}
{$IFDEF NoSerial}
  { $DEFINE FastDemo}  {To enable simulated time                 Not Def.}
{$ENDIF}

{ DEFINE Aux}        {Support for mono-crt aux output}

{$IFNDEF Local}
{Default Switches}
{ÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿}
{Switch³ Controls                  ³   +             ³     -           ³}
{ÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ}
{$A+ }{³ Data Alignment            ³ Word            ³ Byte            ³}
{$B- }{³ Boolean Evaluation        ³ Complete        ³ Shortcut        ³}
{$D+ }{³ Debug Information         ³ Include         ³ Exclude         ³}
{$E+ }{³ Emulation                 ³ IEEE 80x87 Emul.³ Pascal FP Lib.  ³}
{$F+ }{³ Force FAR Calls           ³ Far             ³ Conditional     ³}
{$G+ }{³ Generate 286 Instructions ³ 80286..80x86    ³ 8086..80x86     ³}
{$I+ }{³ Input/Output Checking     ³ Enabled         ³ Disabled        ³}
{$L+ }{³ Local Symbol Information  ³ Include         ³ Exclude         ³}
{$N+ }{³ Numeric Processing        ³ IEEE 80x87      ³ Pascal FP Lib.  ³}
{$O- }{³ Overlay Code Generation   ³ Enable          ³ Disable         ³}
{$R+ }{³ Range Checking            ³ On              ³ Off             ³}
{$S+ }{³ Stack-Overflow Checking   ³ On              ³ Off             ³}
{$V- }{³ Var-String Checking       ³ Strict          ³ Relaxed         ³}
{$T+ }{³ @ type checking           ³ Enable          ³ Disable         ³}
{$Q- }{³ Arithmetic overflow check ³ Enable          ³ Disable         ³}
{$X+ }{³ Extended Syntax           ³ Enable          ³ Disable         ³}
{ÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ}

{--- No Changes beyond this point !! ----------------------------------------}

{$IFDEF NoIEEE}      {Disable FPU library}
  {$N-,E-}
{$ENDIF}{DEF NoIEEE}

{$IFDEF NoDebug}     {Disable Debug info. / Runtime-checks}
  {$D-,L-,R-,S-,I-,T-,Q-}
{$ELSE}
  {$M 52000,0,655360}
{$ENDIF}{DEF NoDebug}

{$ENDIF}{DEF Local}
