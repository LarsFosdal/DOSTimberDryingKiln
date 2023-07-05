UNIT PLCDRVR;

INTERFACE
USES
  PLCTypes;

CONST
  Driver = 'PLCDRVR';

FUNCTION PLCModel:String;
FUNCTION PLCConnect (Port:Byte; BaudRate:Integer; Parity:Char; StopBits:Byte) : Boolean;
FUNCTION PLCValidateAddress (sAddress:AddressType; VAR Wrd:Word) : Boolean;
FUNCTION PLCResponding : Boolean;
FUNCTION PLCReadCoil (sAddress:AddressType) : Boolean;
FUNCTION PLCSetCoil (sAddress:AddressType; State:Boolean) : Boolean;
FUNCTION PLCReadRegister (sAddress:AddressType) : Word;
FUNCTION PLCSetRegister (sAddress:AddressType; Value:Word) : Boolean;
FUNCTION PLCError : Integer;
FUNCTION PLCErrorMsg (i:Integer) : String;
FUNCTION PLCDisconnect : Boolean;
FUNCTION PLCSimulator (P:Pointer) : Pointer;
FUNCTION PLCAttatchLog(P:Pointer):Integer;

IMPLEMENTATION

FUNCTION PLCConnect;         External Driver index ixConnect;
FUNCTION PLCDisconnect;      External Driver index ixDisconnect;
FUNCTION PLCAttatchLog;      External Driver index ixAttatchLog;
FUNCTION PLCValidateAddress; External Driver index ixValidateAddress;
FUNCTION PLCSimulator;       External Driver index ixSimulator;
FUNCTION PLCModel;           External Driver index ixModel;
FUNCTION PLCError;           External Driver index ixError;
FUNCTION PLCErrorMsg;        External Driver index ixErrorMsg;
FUNCTION PLCResponding;      External Driver index ixResponding;
FUNCTION PLCReadCoil;        External Driver index ixReadCoil;
FUNCTION PLCSetCoil;         External Driver index ixSetCoil;
FUNCTION PLCReadRegister;    External Driver index ixReadRegister;
FUNCTION PLCSetRegister;     External Driver index ixSetRegister;

END.
