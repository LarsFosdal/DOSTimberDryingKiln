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
{컴컴컴쩡컴컴컴컴컴컴컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴�}
{Switch� Controls                  �   +             �     -           �}
{袴袴袴妄袴袴袴袴袴袴袴袴袴袴袴袴袴妄袴袴袴袴袴袴袴袴妄袴袴袴袴袴袴袴袴�}
{$A+ }{� Data Alignment            � Word            � Byte            �}
{$B- }{� Boolean Evaluation        � Complete        � Shortcut        �}
{$D+ }{� Debug Information         � Include         � Exclude         �}
{$E+ }{� Emulation                 � IEEE 80x87 Emul.� Pascal FP Lib.  �}
{$F+ }{� Force FAR Calls           � Far             � Conditional     �}
{$G+ }{� Generate 286 Instructions � 80286..80x86    � 8086..80x86     �}
{$I+ }{� Input/Output Checking     � Enabled         � Disabled        �}
{$L+ }{� Local Symbol Information  � Include         � Exclude         �}
{$N+ }{� Numeric Processing        � IEEE 80x87      � Pascal FP Lib.  �}
{$O- }{� Overlay Code Generation   � Enable          � Disable         �}
{$R+ }{� Range Checking            � On              � Off             �}
{$S+ }{� Stack-Overflow Checking   � On              � Off             �}
{$V- }{� Var-String Checking       � Strict          � Relaxed         �}
{$T+ }{� @ type checking           � Enable          � Disable         �}
{$Q- }{� Arithmetic overflow check � Enable          � Disable         �}
{$X+ }{� Extended Syntax           � Enable          � Disable         �}
{컴컴컴좔컴컴컴컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴�}

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
