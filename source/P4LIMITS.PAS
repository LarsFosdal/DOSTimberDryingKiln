{$I CODEDEFS.PAS} {Include code generation definitions}
UNIT P4Limits; {Config/setup limits for AGPro3}

INTERFACE

CONST
  anHour               = 3600;
  LoggingsPerSample    = 30;   {Number of Updates averaged into a sample}
  SamplesPerHour       = 4;
  SampleInterval {sec} = anHour DIV SamplesPerHour;
  UpdateInterval {sec} = anHour DIV (SamplesPerHour*LoggingsPerSample);

  MaxDays              = 10;
  TotalHours           = MaxDays * 24;
  TotalSamples         = TotalHours * SamplesPerHour;

  MinScale             = 250;
  MaxScale             = 800;

  KilnMaxTWet          = 600;
  KilnMaxTDry          = 800;

  TunnelMaxTWet        = 600;
  TunnelMaxTDry        = 750;

IMPLEMENTATION
END.
