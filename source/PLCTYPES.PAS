UNIT PLCTypes;

INTERFACE

CONST
  ixModel            =  1;
  ixConnect          =  2;
  ixValidateAddress  =  3;
  ixResponding       =  4;
  ixReadCoil         =  5;
  ixSetCoil          =  6;
  ixReadRegister     =  7;
  ixSetRegister      =  8;
  ixError            =  9;
  ixErrorMsg         = 10;
  ixDisconnect       = 11;
  ixSimulator        = 12;
  ixAttatchLog       = 13;

CONST
  MaxAddressLength = 8;

TYPE
  AddressType = String[MaxAddressLength];

IMPLEMENTATION

END.