//
//--------------------------------------------------------------------------------------------------
//
{Dallas CRC utilities}
function CRC16(CRC_Prev: word; X: Byte) : word;

{
This function calculates the new CRC16 value
given the previous value and the incoming X byte
}

Var
  I : Byte;
  CRC : word;
  F : Boolean;

begin
  CRC := CRC_Prev;
  For I := 1 to 8 do
    begin
      F := Odd(X xor CRC);
      CRC := CRC shr 1;
      X := X shr 1;
      If F then CRC := CRC xor $A001;
    end;
  Result := CRC;
end; {CRC16}

function CRC8(CRC_Prev: byte; X: Byte) : byte;

{
This function calculates the new CRC8 value
given the previous value and the incoming X byte
}

var
   I : byte;
   CRC : byte;
   F : boolean;

begin
  CRC := CRC_Prev;
  for I := 1 to 8 do
    begin
      F := odd(X xor CRC);
      X := X shr 1;
      CRC := CRC shr 1;
      if F then CRC := CRC xor $8C; // decimal: 140
    end;
  Result := CRC;
end;{CRC8}

//
//--------------------------------------------------------------------------------------------------
//
