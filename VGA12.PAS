{Unit for 640x480 VGA Mode (12h)
 Version 0.2 (Oktober 2018) (c) 2018 by Jan Knipperts
 
 Fast functions for drawing lines, frames, windows, buttons etc.
 
 USE ONLY FOR MODE 12h (640x480 with 16 colors)! 
 This mode uses a different memeory organisation than other graphics modes!

- fixed a small bug in the buttons text alignment}
 


Unit VGA12;

interface
uses misc;   {Uses my misc unit}

Function detectVGA : Boolean;
{detects VGA compatible graphics cards  }

procedure Block(X1,Y1,X2,Y2:word; Color:byte);
{Fills (X1,Y1)-(X2,Y2) with the specified color. }

procedure Line(X1,Y1,X2,Y2:word; Color:byte);
{Draws a line from (X1,Y1) to (X2,Y2) in the specified color}

Procedure Rectangle(x,y,x1,y1 : word);
{Draws a rectange)

Procedure Frame(x,y,x1,y1 : word);
{Draws a double lined rectangular frame}

Procedure Button(x,y,x1,y1 : word; pressed : boolean; text : string);
{Draws a Button with text "Text" centered. If pressed is true then we button will be drawn in a darker gray}

Procedure Window(x,y,x1,y1 : word);
{Draws a Window}

Procedure Load_BIOS_font;
{Loads the system font from ROM}

Procedure Out(x,y,size,v : word; color : byte; text : string);
{draws a string in the IBM 8x8 system font}

implementation

type
   OneChar = array[1..8] of byte;       { Buffer for a 8x8 IBM-font char}

var
   charset                : array[1..256] of onechar; {Buffer for the complete code Page}


Function detectVGA : Boolean;
{detects VGA compatible graphics cards  }
assembler;
asm
  mov ah,$1a            {ah = 1Ah}
  xor al,al             {Xor al}
  int 10h               {call interrupt 10h (GFX)}
  cmp al,$1a            {is al = 1Ah ? }
  jne @NoVGAdetected    {If not then jump to "NoVGAdetected"}
  cmp bl,$08            {is bl = 08h ? }
  jne @NoVGAdetected    {If not then jump to "NoVGAdetected"}
  mov al,true           {al = true}
  jmp @Exit             {jump to "exit"}
@NoVGAdetected:
  mov al,false          {al = false}
@Exit:
end;


procedure PixelAddr; assembler;
asm
 mov cl,bl
 shr bx,3
 shl ax,6
 add bx,ax
 shr ax,2
 add bx,ax
 mov ax,0a000h
 mov es,ax
 and cl,7
 xor cl,7
 mov ah,1
end;

procedure Block(X1,Y1,X2,Y2:word; Color:byte); assembler;
{ Fill (X1,Y1)-(X2,Y1) with Color, VGA only, 640 lines, 16 color mode, PD }
asm
 inc x2                         {small fix...}
 inc y2

 cld
 mov dx,3ceh
 mov ah,Color
 mov al,0
 out dx,ax
 mov ax,0305h
 out dx,ax
 mov ax,0a000h
 mov es,ax
 mov ax,Y1
 mov si,Y2
 sub si,ax
 jz @NoLines
 shl ax,6
 mov di,ax
 shr ax,2
 add di,ax
 mov ax,X1
 mov cl,al
 shr ax,3
 mov bx,X2
 mov ch,bl
 shr bx,3
 sub bx,ax
 push bp
 mov bp,bx
 add di,ax
 and cx,707h
 mov bx,0ffffh
 shr bl,cl
 mov cl,ch
 xor cl,7
 inc cx
 shl bh,cl
 or bp,bp
 jnz @NoDub
 and bl,bh
 jz @NoLines2
@NoDub:
 mov al,8
@PutLines:
 cli
 mov al,es:[di]
 mov es:[di],bl
 sti
 inc di
 mov cx,bp
 dec cx
 js @NoPBL
 jz @NoPB
 mov al,0ffh
 rep stosb
@NoPB:
 cli
 mov al,es:[di]
 mov es:[di],bh
 sti
 inc di
@NoPBL:
 sub di,bp
 add di,80-1
 dec si
 jnz @PutLines
@NoLines2:
 pop bp
@NoLines:
 mov ax,0005h
 out dx,ax
end;



procedure Line(X1,Y1,X2,Y2:word; Color:byte); assembler;
const
 ByteOffsetShift=3;
var
 Incr1,Incr2:word;
 Routine:word;
asm
        cld
        mov si,80
        mov dx,3ceh
        mov ah,Color
        xor al,al
        out dx,ax
        mov ax,0305h
        out dx,ax
        mov cx,X2
        sub cx,X1
        jz @VertLine       { Jump if X1=X2, VertLine }
        jns @Li01          { Jump if X2>X1, no swap }
        neg cx
        mov bx,X2
        xchg bx,X1
        mov X2,bx
        mov bx,Y2
        xchg bx,Y1
        mov Y2,bx
@Li01:  mov bx,Y2
        sub bx,Y1
        jnz @Li02          { Jump if Y1<>Y2, no HorizLine }
        jmp @HorizLine
@Li02:  jns @Li03          { Jump if Y2 > Y1, no swap }
        neg bx
        neg si
@Li03:  mov routine,offset @LoSlopeLine
        cmp bx,cx
        jle @Li04
        mov routine,offset @HiSlopeLine
        xchg bx,cx
@Li04:  shl bx,1
        mov incr1,bx
        sub bx,cx
        mov di,bx
        sub bx,cx
        mov incr2,bx
        push cx
        mov ax,Y1
        mov bx,X1
        call PixelAddr
        mov al,1
        shl ax,cl
        mov dx,ax
        not dh
        pop cx
        inc cx
        jmp routine          { Var containing LoSlope/HiSlope }

@VertLine: mov ax,Y1
        mov bx,Y2
        mov cx,bx
        sub cx,ax
        jge @Li31
        neg cx
        mov ax,bx
@Li31:  inc cx
        mov bx,X1
        push cx
        call PixelAddr
        mov al,1
        shl ax,cl
        not ah
        pop cx
@Li32:  mov ah,es:[bx]
        mov es:[bx],al
        add bx,si
        loop @Li32
        jmp @Liexit

@HorizLine:
        mov ax,Y1
        mov bx,X1
        call PixelAddr
        mov di,bx
        mov dh,ah
        not dh
        mov dl,0ffh
        shl dh,cl
        not dh
        mov cx,X2
        and cl,7
        xor cl,7
        shl dl,cl
        mov ax,X2
        mov bx,X1
        mov cl,ByteOffsetShift
        shr ax,cl
        shr bx,cl
        mov cx,ax
        sub cx,bx
        mov ax,0ffffh
        or dh,dh
        js @Li43
        or cx,cx
        jnz @Li42
        and dl,dh
        jmp @Li44
@Li42:  mov ah,al
        and ah,dh
        mov bl,es:[di]
        mov es:[di],ah
        inc di
        dec cx
@Li43:  or cx,cx
        jz @Li44
@InLoop: mov bl,es:[di]
        stosb
        loop @InLoop
      {  if mode = NO_OP replace 'or cx,cx'-'loop @InLoop:' with 'rep stosb'}
@Li44:  and al,dl
        mov dl,es:[di]
        mov es:[di],al
        jmp @Liexit

@LoSlopeLine:
@Li10:  mov ah,es:[bx]
        xor ah,ah
@Li11:  or ah,dl
        ror dl,1
        ror dh,1
        jnc @Li14
        or di,di
        jns @Li12
        add di,incr1
        loop @Li11
        mov es:[bx],ah
        jmp @Liexit
@Li12:  add di,incr2
        mov es:[bx],ah
        add bx,si
        loop @Li10
        jmp @Liexit
@Li14:  mov es:[bx],ah
        inc bx
        or di,di
        jns @Li15
        add di,incr1
        loop @Li10
        jmp @Liexit
@Li15:  add di,incr2
        add bx,si
        loop @Li10
        jmp @Liexit

@HiSlopeLine:
@Li21:  mov al,es:[bx]
        mov es:[bx],dl
        add bx,si
        or di,di
        jns @Li23
        add di,incr1
        loop @Li21
        jmp @Liexit
@Li23:  add di,incr2
        ror dl,1
        ror dh,1
        cmc
        adc bx,0
        loop @Li21
@Liexit:
 mov dx,3ceh
 mov ax,5
 out dx,ax
end;




Procedure Load_BIOS_font;
var
 memcounter,               {memmory counter}
 bytecounter,              {byte counter}
 charcounter : integer;    {character counter}
begin
 memcounter := 0;
  for charcounter := 1 to 256 do
  begin
    for byteCounter:= 1 to 8 do
    begin
     charset[charcounter][Bytecounter] := Mem[$0F000:$0FA6E+memcounter];
     inc(memcounter);
    end;
   end;
end;


Procedure Out(x,y,size,v : word; color : byte; text : string);
  var
    MemPos,
    TempPos : word;
    Count,c,
    xp,yp,
    XC,YC   : integer;
    Letter  : OneChar;

  begin
    for count := 1 to length(text) do {draw the sepcified number of chars}
    begin

     letter := Charset[ord(text[count])+1]; {witch char ?}
     temppos := 0;
     mempos := 1;

     for yc := 1 to 8 do                    {Y byte}
     begin
      for xc := 8 downto 1 do
      begin
       if (getbit(letter[mempos],temppos) = 1) then
       begin
        xp := x+(xc*size);
        yp := y+(yc*size);
        if (xp < 640) and (xp > 0) and
           (yp < 480) and (yp > 0) then
        begin

            if v = 1 then
            begin
             for c := 1 to size do
             begin
              block(xp+c,yp,xp+c,yp,color);
              block(xp+c,yp+c,xp+c,yp+c,color);
             end;
            end
            else
            begin
              block(xp,yp,xp,yp,color);
            end;
        end;


       end;
       inc(temppos);
      end;
       inc(mempos);
       if mempos > 8 then mempos := 1;
       temppos := 0;
     end;
     inc(x,8*size);
    end;
  end;




Procedure Rectangle(x,y,x1,y1 : word);
begin
 Line(x,y,x1,y,0); {oben}
 Line(x,y,x,y1,0); {links}
 Line(x,y1,x1,y1,0);{unten}
 Line(x1,y,x1,y1,0);{rechts}
end;


Procedure Frame(x,y,x1,y1 : word);
begin
 Rectangle(x,y,x1,y1);
 Rectangle(x+1,y+1,x1-1,y1-1);
 Rectangle(x+3,y+3,x1-3,y1-3);
end;


Procedure ButtonFrame(x,y,x1,y1 : word; pressed : boolean);
begin
   Rectangle(x,y,x1,y1);
   if not pressed then
   begin
    line(x+1,y+1,x1-1,y+1,15);       {upper line}
    line(x+1,y+2,x1-1,y+2,15);       {second upper line}
    line(x+1,y+1,x+1,y1-1,15);       {left line}
    line(x+2,y+1,x+2,y1-1,15);       {second left line}
    line(x+1,y1-1,x1-1,y1-1,8);      {bottom line}
    line(x+1,y1-2,x1-1,y1-2,8);      {second bottom line}
    line(x1-1,y+1,x1-1,y1-1,8);      {right line}
    line(x1-2,y+1,x1-2,y1-1,8);      {second right line}
   end;
end;

Procedure Window(x,y,x1,y1 : word);
begin
   Block(x,y,x1,y1,3);
   Frame(x+2,y+2,x1-2,y1-2);
end;


Procedure Button(x,y,x1,y1 : word; pressed : boolean; text : string);
var col,col1 : byte;
    mx,my    : word;
    l        : real;
begin
  if not pressed then
  begin
   col := 7;
   col1 := 8;
  end
  else
  begin
   col := 8;
   col1 := 7;
  end;

  Block(x+1,y+1,x1-1,y1-1,col);
  ButtonFrame(x,y,x1,y1,pressed);
  mx := (x+2)+((x1-2)-(x+2)) div 2;
  my := (y+2)+((y1-2)-(y+2)) div 2;
  l := length(text) / 2;
  l := l * 8;
  Out(mx-round(l),my-4,1,0,col1,text);
end;


end.
