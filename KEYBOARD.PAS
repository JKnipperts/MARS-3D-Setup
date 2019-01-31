{======================= Keyboard Handler ==========================
  Returns the scancode for any pressed key, including ALT, CTRL, SCROLL, NUM etc.

 v.0.1 - 10.09.2018 by Jan Knipperts}

Unit Keyboard;

interface
uses dos;

type

 Keycfg_type           = record
      Keyname            : string;
      Scancode           : byte;
   end;

 var
   keydown                : byte;
   keys                   : array [0..127] of boolean;
   scan,
   lastkey                : byte;

Procedure initKB;
{Initializes the keyboard handler}
Procedure deinitKB;
{Restores the original handler}
Function GetKeyName(code : byte) : string;
{Returns the key name for the given scancode as string}
Function GetanyKey : byte;
{Returns the scan code of the pressed key. Also works for special keys like ALT, CTRL etc.}


implementation
var    oldint                : pointer;


procedure INT9; interrupt;
begin
  scan := port[$60];     { Get Scancode }
  if scan > $7F then     { Key released ? }
  begin
    if keys[scan xor $80] then
      dec(keydown);
    keys[scan xor $80] := false;   {Yes !}
  end
  else
  begin
    if not keys[scan] then
      inc(keydown);
    keys[scan] := true;  {NO ! Key pressed }
    lastkey := scan;
  end;
  port[$20] := $20;  { Send EndOfInterrupt to Interruptcontroller }
end;


procedure initKB;
var
  i : byte;
begin
  for i := 0 to 127 do
    keys[i] := false;   {No keys pressed}
  keydown := 0;
  getintvec(9, oldint);
  setintvec(9, @INT9);
end;


procedure deinitKB;
begin
  setintvec(9, oldint);
end;

function GetKeyName(code : byte) : string;
begin
 case code of
   1 : GetKeyname := 'ESC';
   2 : GetKeyname := '1';
   3 : GetKeyname := '2';
   4 : GetKeyname := '3';
   5 : GetKeyname := '4';
   6 : GetKeyname := '5';
   7 : GetKeyname := '6';
   8 : GetKeyname := '7';
   9 : GetKeyname := '8';
  $A : GetKeyname := '9';
  $B : GetKeyname := '0';
  $C : GetKeyname := '-';
  $D : GetKeyname := '=';
  $E : GetKeyname := 'BACKSPACE';
  $F : GetKeyname := 'TAB';
  $10 : GetKeyname := 'Q';
  $11 : GetKeyname := 'W';
  $12 : GetKeyname := 'E';
  $13 : GetKeyname := 'R';
  $14 : GetKeyname := 'T';
  $15 : GetKeyname := 'Y';
  $16 : GetKeyname := 'U';
  $17 : GetKeyname := 'I';
  $18 : GetKeyname := 'O';
  $19 : GetKeyname := 'P';
  $1A : GetKeyname := '[';
  $1B : GetKeyname := ']';
  $1C : GetKeyname := 'ENTER';
  $1D : GetKeyname := 'CTRL';
  $1E : GetKeyname := 'A';
  $1F : GetKeyname := 'S';
  $20 : GetKeyname := 'D';
  $21 : GetKeyname := 'F';
  $22 : GetKeyname := 'G';
  $23 : GetKeyname := 'H';
  $24 : GetKeyname := 'J';
  $25 : GetKeyname := 'K';
  $26 : GetKeyname := 'L';
  $27 : GetKeyname := ';';
  $28 : GetKeyname := '''';
  $29 : GetKeyname := '`';
  $2A : GetKeyname := 'L SHIFT';
  $2B : GetKeyname := '\';
  $2C : GetKeyname := 'Z';
  $2D : GetKeyname := 'X';
  $2E : GetKeyname := 'C';
  $2F : GetKeyname := 'V';
  $30 : GetKeyname := 'B';
  $31 : GetKeyname := 'N';
  $32 : GetKeyname := 'M';
  $33 : GetKeyname := ',';
  $34 : GetKeyname := '.';
  $35 : GetKeyname := '/';
  $36 : GetKeyname := 'R SHIFT';
  $37 : GetKeyname := 'PRINT';
  $38 : GetKeyname := 'ALT';
  $39 : GetKeyname := 'SPACE';
  $3A : GetKeyname := 'CAPS';
  $3B : GetKeyname := 'F1';
  $3C : GetKeyname := 'F2';
  $3D : GetKeyname := 'F3';
  $3E : GetKeyname := 'F4';
  $3F : GetKeyname := 'F5';
  $40 : GetKeyname := 'F6';
  $41 : GetKeyname := 'F7';
  $42 : GetKeyname := 'F8';
  $43 : GetKeyname := 'F9';
  $44 : GetKeyname := 'F10';
  $45 : GetKeyname := 'NUM';
  $46 : GetKeyname := 'SCRL';
  $47 : GetKeyname := 'HOME';
  $48 : GetKeyname := 'UP';
  $49 : GetKeyname := 'PGUP';
  $4A : GetKeyname := '-';
  $4B : GetKeyname := 'LEFT';
  $4C : GetKeyname := 'CENTER';
  $4D : GetKeyname := 'RIGHT';
  $4E : GetKeyname := '+';
  $4F : GetKeyname := 'END';
  $50 : GetKeyname := 'DOWN';
  $51 : GetKeyname := 'PGDN';
  $52 : GetKeyname := 'INS';
  $53 : GetKeyname := 'DEL';
  $57 : GetKeyname := 'F11';
  $58 : GetKeyname := 'F12';
end;
end;

Function GetanyKey : byte;
var res : byte;
begin

res := 0;
repeat

    if (keydown > 0) then
    begin
        repeat;
         res := lastkey;
        until keydown = 0;
    end;

until res <> 0;
 GetanyKEy := res;

End; { ReadKey }



end.
