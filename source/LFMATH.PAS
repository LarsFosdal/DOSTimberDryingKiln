{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT LFmath; {(c) 04 DEC 1987 Lars Fosdal}

INTERFACE
  Uses LFsystem,Objects,LFCrt;


TYPE
  rComplex = RECORD
              re,im : Float;
            END;

  pComplex = ^Complex;
  Complex = OBJECT(TObject)
              re,im :Float;
              CONSTRUCTOR Init(r,i:Float);
              PROCEDURE Assign(r,i:Float);
              PROCEDURE Copy(c:Complex);
              PROCEDURE Add(c:Complex);
              PROCEDURE Subtract(c:Complex);
              PROCEDURE Multiply(c:Complex);
              PROCEDURE Square;
              PROCEDURE Divide(c:Complex);
              PROCEDURE Conjugate;
              FUNCTION Modul:Float;
              FUNCTION Phase:Float;
              FUNCTION asString(des:Integer):String;
            END;
CONST
  null:rComplex =(RE:0;IM:0);


PROCEDURE cAdd(VAR z : rComplex; x,y : rComplex);

PROCEDURE cSub(VAR z : rComplex; x,y : rComplex);

PROCEDURE cMul(VAR z : rComplex; x,y : rComplex);

FUNCTION ZeroDiv(divisor:rComplex):boolean;

PROCEDURE cDiv(VAR z : rComplex; x,y : rComplex);

PROCEDURE Conjugate(VAR z : rComplex; x : rComplex);

FUNCTION Modul(z : rComplex):Float;

FUNCTION Phase(z : rComplex):Float;

PROCEDURE cWrite(z : rComplex; des:byte);

FUNCTION Log(a : Float):Float;

FUNCTION AntiLog(a : Float):Float;

FUNCTION gauss(my,sigma:Float):Float;
               { Gaussian White Noise Generator  sigma = 1/(S/N-ratio) }

FUNCTION Raise(x,y:Float):Float;

IMPLEMENTATION

CONST
  LFmathMsg = ' LFmath.1 19871204 Lars Fosdal ';

CONSTRUCTOR Complex.Init(r,i:Float);
BEGIN
  TObject.Init;
  Assign(r,i);
END; {CONS Complex.Init}

PROCEDURE Complex.Assign(r,i:Float);
BEGIN
  re:=r;
  im:=i;
END; {PROC Complex.Assign}

PROCEDURE Complex.Copy(c:Complex);
BEGIN
  Assign(c.re,c.im);
END; {PROC Complex.Copy}

PROCEDURE Complex.Add(c:Complex);
BEGIN
  re:=re+c.re;
  im:=im+c.im;
END; {PROC Complex.Add}

PROCEDURE Complex.Subtract(c:Complex);
BEGIN
  re:=re-c.re;
  im:=im-c.im;
END; {PROC Complex.Subtract}

PROCEDURE Complex.Multiply(c:Complex);
BEGIN
  re:=(re*c.re)-(im*c.im);
  im:=(re*c.im)+(c.re*im);
END; {PROC Complex.Multiply}

PROCEDURE Complex.Square;
BEGIN
  re:=sqr(re)-sqr(im);
  im:=2*(re*im);
END; {PROC Complex.Square}

PROCEDURE Complex.Divide(c:Complex);
VAR
  w : Float;
BEGIN
  w:=1/(sqr(c.re)+sqr(c.im));
  re:=((re*c.re)+(im*c.im))*w;
  im:=((-re*c.im)+(im*c.re))*w;
END; {PROC Complex.Divide}

PROCEDURE Complex.Conjugate;
BEGIN
  im:=-im;
END; {PROC Complex.Conjugate}

FUNCTION Complex.Modul:Float;
BEGIN
  Modul:=Sqrt(sqr(re)+sqr(im));
END; {FUNC Complex.Modul}

FUNCTION Complex.Phase:Float;
BEGIN
  IF re=0 THEN
  BEGIN
    IF im>0 THEN phase:=pi/2 ELSE phase:=3*pi/2;
  END
   ELSE Phase:=ArcTan(im/re);
END; {FUNC Complex.Phase}

FUNCTION Complex.asString(des:Integer):String;
VAR
  s : String;
BEGIN
  s:=RealStr(re,0,des);
  IF im>=0 THEN s:=s+'+';
  s:=s+RealStr(im,0,des)+'j';
  asString:=s;
END; {FUNC Complex.asString}


PROCEDURE cAdd;
BEGIN
  z.re:=x.re+y.re; z.im:=x.im+y.im;
END;

PROCEDURE cSub;
BEGIN
  z.re:=x.re-y.re; z.im:=x.im-y.im;
END;

PROCEDURE cMul;
BEGIN
  z.re:=(x.re*y.re)-(x.im*y.im);
  z.im:=(x.re*y.im)+(y.re*x.im);
END;

FUNCTION ZeroDiv;
BEGIN
  ZeroDiv:=sqr(divisor.re)+sqr(divisor.im)=0;
END;

PROCEDURE cDiv;
VAR
  w : Float;
BEGIN
  w:=1/(sqr(y.re)+sqr(y.im));
  z.re:=((x.re*y.re)+(x.im*y.im))*w;
  z.im:=((-x.re*y.im)+(x.im*y.re))*w;
END;

PROCEDURE Conjugate;
BEGIN
  z.re:=x.re; z.im:=-x.im;
END;

FUNCTION Modul;
BEGIN
  Modul:=Sqrt(sqr(z.re)+sqr(z.im));
END;

FUNCTION Phase;
BEGIN
  IF z.re=0 THEN
  BEGIN
    IF z.im>0 THEN phase:=pi/2 ELSE phase:=3*pi/2;
  END
   ELSE Phase:=ArcTan(z.im/z.re);
END;

PROCEDURE cWrite;
BEGIN
  write(z.re:0:des);
  IF z.im>=0 THEN write('+');
  write(z.im:0:des,'j');
END;

FUNCTION Log;
BEGIN
  Log:=Ln(a)/2.302585093;
END;

FUNCTION AntiLog;
BEGIN
  AntiLog:=EXP(2.302585093*a);
END;

FUNCTION gauss(my,sigma:Float):Float;
               { Gaussian White Noise Generator  sigma = 1/(S/N-ratio) }

VAR
  t,u : Float;
BEGIN
  t:=sigma*sqrt(-2*ln(random));
  u:=2*pi*random;
  gauss:=my+t*sin(u);
END;{gauss}

FUNCTION Raise(x,y:Float):Float;
{ - Ex.: Raise(3,4) = 3^4 = 3*3*3*3 = 81
    Limitation : Doesn't handle x<0 (infinite or Complex) !!}
VAR result : Float;
BEGIN
  IF x>0   THEN Raise:=EXP(y*LN(x))
  ELSE IF x=0
  THEN BEGIN
    IF y=0 THEN Raise:=1       { 0^0 = 1  per def.}
           ELSE Raise:=0;      { 0^y }
       END ELSE RunError(207); { (x<0)^y -> may be Complex or infinite }
END; {FUNC Raise}



BEGIN
  Units.Enter(LFmathMsg,MemAvail,CSeg);
END.