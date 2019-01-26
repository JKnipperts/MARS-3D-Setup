Unit Misc;

{Diese Unit enthÑlt nÅtzliche Proceduren zum Zerlegen von Standartvariablen,
 dem Ansteuern von einzelnen Bits und dem Ausgeben von Zahlenwerten.

{Version 1.43 - 07.01.02 (Version 1.0 wurde am 19.09.00 erstellt)   }






interface
uses crt;


const
 copyright : string = #10+#13+' Misc routines v1.43 (c) 2000/2001 by Jan Knipperts '+#10+#13;


type
 {FÅr Bitoperationen :}
  bit = 0..1;
  bitnum = 0..7;
  bitnumw = 0..15;
  bitnumL = 0..31;



{Variablen }

Procedure Crackpointer(p : pointer;var segnum,ofsnum : word);


{Bit }

Function getBit(b : Byte; n : bitNum) : bit;
Function setBit(b : Byte; n : bitNum) : Byte;
Function clrBit(b : Byte; n : bitNum) : Byte;

Function getBitw(b : word; n : bitNumw) : bit;
Function setBitW(b : word; n : bitNumw) : word;
Function clrBitW(b : word; n : bitNumw) : word;

Function getBitL(b : Longint; n : bitNuml) : bit;
Function setBitL(b : Longint; n : bitNuml) : Longint;
Function clrBitL(b : Longint; n : bitNuml) : Longint;

function lonib(bt : byte) : byte;  {Gibt die unteren 4 Bit eines Byte}
function hinib(bt : byte) : byte;  {Gibt die oberen 4 Bit eines Byte}


{Hexadezimal und Mathematik}

function hexn(h:byte) :string;
function hexb(h:byte) :string;
function hexw(h:word) :string;


Function hoch(z1,z2 : word) : longint;
Function addzero(b : byte) : string;
Function addspace (b : byte) : string;


{Datei}
Function fileexist(name : string) : boolean;

{Tastertur}
Procedure  Keybon;   {Tastertur an/aus}
Procedure  Keyboff;

Function  Getkey : char;
Function  Catchkey : char;
Function  IsKeypressed : boolean;
Procedure WaitKey;

{Soundausgabe}

Procedure SpkSound(Hz : word);
Procedure SpkNosound;

{Zeitverzîgerung}

Procedure Xdelay(ms : word);








implementation


Function getBit(b : Byte; n : bitNum) : bit;
{liefert den Zustand eines Bit}
begin
  getBit := bit(odd(b shr n));
end;

Function setBit(b : Byte; n : bitNum) : Byte;
{setzt ein Bit}
begin
  setBit := b or (1 shl n);
end;

Function clrBit(b : Byte; n : bitNum) : Byte;
{lîscht ein Bit}
begin
  clrBit := b and hi($FE shl n);
end;

{Und fÅr Word...}

Function getBitw(b : word; n : bitNumw) : bit;
{liefert den Zustand eines Bit}
begin
  getBitw := bit(odd(b shr n));
end;

Function setBitw( b : word; n : bitNumw) : word;
{setzt ein Bit}
begin
  setBitw := b or (1 shl n);
end;

Function clrBitw(b : word; n : bitNumw) : word;
{lîscht ein Bit}
begin
  clrBitw := b and hi($FEFF shl n);
end;


{Und fÅr Longint...}

Function getBitL(b : longint; n : bitNumL) : bit;
{liefert den Zustand eines Bit}
begin
  getBitL := bit(odd(b shr n));
end;

Function setBitL( b : Longint; n : bitNumL) : longint;
{setzt ein Bit}
begin
  setBitL := b or (1 shl n);
end;

Function clrBitL(b : Longint; n : bitNumL) : longint;
{lîscht ein Bit}
begin
  clrBitL := b and hi($FEFF shl n);
end;





function lonib(bt : byte) : byte;  {Gibt die unteren 4 Bit eines Byte}
var res,bitc : byte;
begin
  res := 0;
  for bitc := 0 to 3 do
  begin
   if getbit(bt,bitc) = 1 then
   begin
    res := setbit(res,bitc);
   end;
  end;
  lonib := res;
end;

function hinib(bt : byte) : byte;  {Gibt die oberen 4 Bit eines Byte}
var res,bitc : byte;
begin
  res := 0;
  for bitc := 3 to 7 do
  begin
   if getbit(bt,bitc) = 1 then
   begin
    res := setbit(res,bitc);
   end;
  end;
  hinib := res;
end;








function hexn(h:byte):string;   {Gibt ein Halbbeit (Nibble) als HEX-string aus}
const
  hexChars: array [0..$F] of Char =
    '0123456789ABCDEF';
begin
  hexn := hexChars[h and $F];

end;



function hexb(h:byte):string;   {Gibt ein Byte als HEX-string aus}
const
  hexChars: array [0..$F] of Char =
    '0123456789ABCDEF';
begin
 if hexChars[hi(h) shr 4] <> '0' then
  begin
   hexb := hexChars[h shr 4]+
           hexChars[h and $F];
  end
  else
  begin
    hexb := hexChars[h and $F];
  end;
end;


function hexw(h:word):string;   {Gibt ein Word als HEX-string aus}
const
  hexChars: array [0..$F] of Char =
    '0123456789ABCDEF';
begin
  if hexChars[hi(h) shr 4] <> '0' then
  begin
    hexw := hexChars[hi(h) shr 4]+
            hexChars[hi(h) and $F]+
            hexChars[Lo(h) shr 4]+
            hexChars[Lo(h) and $F];
  end
  else
  begin
    hexw := hexChars[hi(h) and $F]+
            hexChars[Lo(h) shr 4]+
            hexChars[Lo(h) and $F];
  end;

end;






Procedure Crackpointer(p : pointer;var segnum,ofsnum : word);
{Zerlegt einen Pointer in Segment:Offset}
var size    : longint;
    counter : byte;
begin
segnum := 0;
ofsnum := 0;


move(p,size,sizeof(pointer));
for counter := 0 to 15 do
begin
 if getbitL(size,counter) = 1 then
 begin
  ofsnum := setbitw(ofsnum,counter);
 end;
end;

for counter := 16 to 31 do
begin
 if getbitL(size,counter) = 1 then
 begin
  segnum := setbitw(segnum,counter-16);
 end;
end;



end;




Function hoch(z1,z2 : word) : longint;
{Berechnet Hochzahlen}
var d,d1 : word;
begin


 d1 := z1;

 for d := 1 to z2 do
 begin
  d1 := d1*z1;
 end;

 hoch := d1;
end;



Function fileexist(name : string) : boolean;
var tf : file;
begin
 fileexist := true;
{$I-}
 assign(tf,name);
 reset(tf,1);
 close(tf);
{$I+}
 If IOResult <> 0 then fileexist := false;
end;

function addspace (b : byte) : string;
var
  c2 : string[3];
begin
  STR (b, c2);
   if b < 10 then
   begin
    c2 := '  ' + c2;
   end
   else
   begin
    if (b >= 10) and (b < 100) then
    c2 := ' ' + c2;
   end;

  addspace := c2
end; {addspace}



function addzero (b : byte) : string;
var
  c2 : string[3];
begin
  STR (b, c2);
   if b < 10 then
   begin
    c2 := '00' + c2;
   end
   else
   begin
    if (b >= 10) and (b < 100) then
    c2 := '0' + c2;
   end;

  addzero := c2
end; {addzero}



{ KEYBOARD }

procedure KeybOn;
assembler;
asm
  in al,21h
  and al,11111101b
  out 21h,al
end;

procedure KeybOff;
assembler;
asm
  in al,21h
  or al,00000010b
  out 21h,al
end;

function IsKeyPressed:boolean;
begin
  asm
    mov        ah,1
    int        16h
    jnz        @true
    mov        [@result],false
    jmp        @end
@true:
    mov        [@result],true
@end:
  end;
end;

function GetKey:char;assembler;
asm   {OK}
  xor ah,ah
  int 16h
end;


function Catchkey : char;
begin
 if iskeypressed then Catchkey := getkey;
end;


Procedure WaitKey;
begin
 while iskeypressed do getkey;
 repeat until iskeypressed;
end;

{ PC SPEAKER }

procedure SpkNoSound;
assembler;
asm
  in al,61h
  and al,0fch
  out 61h,al
end;

procedure SpkSound(hz:word);
assembler;
asm
  mov bx,hz
  mov ax,34ddh
  mov dx,0012h
  cmp dx,bx
  jnc @2
  div bx
  mov bx,ax
  in al,61h
  test al,3
  jnz @1
  or al,3
  out 61h,al
  mov al,0b6h
  out 43h,al
@1:
  mov al,bl
  out 42h,al
  mov al,bh
  out 42h,al
@2:
end;

{ MISCELANEOUS }

procedure XDelay(ms:word);
assembler;
asm
  mov ax,1000
  mul ms
  mov cx,dx
  mov dx,ax
  mov ah,86h
  int 15h
end;







end.