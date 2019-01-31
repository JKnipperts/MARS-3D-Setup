{ Setup program for the Game "MARS"
  v.1.1 - 05th October 2018
  by Jan Knipperts

  Changes to 1.0:
  - Added network level selector and
    option to start a network game directly from setup
  - Changed Buttontext "Abort" to "Cancel"
  - Changed Buttontext "Accept" in Keymenu to "OK"
  - Changed Copyright Message
  - Spared some memory by reducing string sizes
  - Fixed some smaller bugs in button handling
     - text alignment
     - show button pressed until mousebutton is released
  - Fixed ESC-Bug. Now ESC will return to main menu when pressed in a submenu
    instead of quitting completely
  - Fixed missalignment of main menu buttons
  - Some smaller speedups in menu drawing}


Program Setup;
uses dos,misc,miles,mouse,vga12,keyboard;
type

   Soundcarddata         = record
   IO                    : word;
   IRQ                   : word;
   DMA                   : word;
   DMA2                  : word;
   end;

   Drivercfg             = record
   NAME                  : string[70];
   DRIVER                : string[3];
   IO                    : string[3];
   IRQ                   : string[3];
   DMA_8_BIT             : string[3];
   DMA_16_BIT            : string[3];
   end;

var
   kf,df,mf               : text;
   clicked,quit,gomain    : Boolean;
   pressed,cnt            : byte;
   keycfg                 : array[1..12] of Keycfg_type;
   marked,
   old,px,
   pos_ls,opos_ls         : word;
   Music                  : SoundCardData;
   Audio                  : SoundCardData;
   DIG                    : Drivercfg;
   MDI                    : Drivercfg;
   selected_mid,
   selected_dig,
   selected_lvl,
   lvl_start, opos_lvl    : byte;
   s,m,d,lvl              : string;
   error                  : integer;


const
  num_lvl               = 20;
  Sound                 = 3;
  Midi                  = 2;
  ID                    = ';Miles Design Audio Interface Library V3.03 of 7-Nov-95';
  DigCFG                = 'DIG.INI';
  MdiCFG                = 'MDI.INI';
  KeyFile               = 'DEFAULT.CFG';

  MText                 : array[1..4] of string[8] = (
  ('Keyboard'),
  ('Music'),
  ('Audio'),
  ('Network'));

  KText                 : array[1..12] of string[12] = (
  ('Up'),
  ('Down'),
  ('Left'),
  ('Right'),
  ('Strafe'),
  ('Strafe left'),
  ('Strafe right'),
  ('Speed'),
  ('Use'),
  ('Fire'),
  ('Jump'),
  ('Duck'));


  Title  : string = 'MARS Setup';
  Ver    : string = 'Version 1.1 - 10/05/2018';
  Author : string = 'by Jan Knipperts';

  Level  : array[1..20] of string[20] = (
  ('E1M1 (Singleplayer)'),
  ('E1M2 (Singleplayer)'),
  ('E1M3 (Singleplayer)'),
  ('E1M4 (Singleplayer)'),
  ('E1M5 (Singleplayer)'),
  ('E1M6 (Singleplayer)'),
  ('E1M7 (Singleplayer)'),
  ('E2M1 (Multiplayer)'),
  ('E2M2 (Multiplayer)'),
  ('E2M3 (Multiplayer)'),
  ('E2M4 (Multiplayer)'),
  ('E2M5 (Multiplayer)'),
  ('E2M6 (Multiplayer)'),
  ('E2M7 (Multiplayer)'),
  ('E2M8 (Multiplayer)'),
  ('E2M9 (Multiplayer)'),
  ('E3M1 (Multiplayer)'),
  ('E3M2 (Multiplayer)'),
  ('E3M3 (Multiplayer)'),
  ('E3M4 (Multiplayer)'));


{================================= Additional stuff ================================}

Procedure DosShell(command : string);
var
 OldHeapEnd,
 NewHeapEnd     : Word;
begin
 Error:=0;
 If MemAvail < $1000 then Error := 8;

 If Error = 0 then
 begin
   NewHeapEnd:=Seg(HeapPtr^)-PrefixSeg;
   OldHeapEnd:=Seg(HeapEnd^)-PrefixSeg;
   asm
    mov ah,4Ah
    mov bx,NewHeapEnd
    mov es,PrefixSeg
    Int 21h
    jnc @EXIT
    mov Error,ax
    @EXIT:
   end; {asm}

  If Error=0 then
  begin
   SwapVectors;
   Exec(GetEnv('COMSPEC'),command);
   SwapVectors;
    asm
     mov ah,4Ah
     mov bx,OldHeapEnd
     mov es,PrefixSeg
     Int 21h
     jnc @EXIT
     mov Error,ax
     @EXIT:
    end; {asm}
  end;   {If}
 end;    {If}
end;     {Function}


Procedure Wait4Mouse;
begin
  showcursor;
  while leftButton do begin end;
  hidecursor;
end;

{====================== Save Settings =========================}



Procedure SaveKeyFile;
var cnt : byte;
begin
   assign(kf,keyfile);
   {$I-}
   rewrite(kf);
    for cnt := 1 to 12 do
    writeln(kf,keycfg[cnt].keyname,' ',keycfg[cnt].scancode);
  close(kf);
  {$I+}
  if IOResult <> 0 then
  begin
    asm
     mov ax,0003h
     int 10h
    end;
    writeln;
    writeln(' ERROR: Can''t create configuration file!');
    writeln;
    halt(1);
  end;

end;


Procedure SaveSoundConfig(t : byte);
begin

if t = Midi then

begin
 assign(df,mdicfg);
 {$I-}
 rewrite(df);
    writeln(df,';');
    writeln(df,id);
    writeln(df,';');
    writeln(df);
    write(df,'DEVICE      ');
    writeln(df,mids[selected_mid].name);
    write(df,'DRIVER      ');
    s := uppercase(mids[selected_mid].drvfile);
    delete(s,1,1);
    delete(s,length(s),1);
    writeln(df,s);
    write(df,'IO_ADDR     ');
    s := hexw(music.io);
    delete(s,1,1);
    s := s + 'h';
    writeln(df,s);
    write(df,'IRQ         ');
    if music.irq = 0 then
    begin
     s := '-1';
    end
    else
    begin
     str(music.irq,s);
    end;
    writeln(df,s);
    write(df,'DMA_8_BIT   ');
    if music.dma = 0 then
    begin
     s := '-1';
    end
    else
    begin
     str(music.dma,s);
    end;
    writeln(df,s);
    write(df,'DMA_16_BIT  ');
    if music.dma2 = 0 then
    begin
     s := '-1';
    end
    else
    begin
     str(music.dma2,s);
    end;
    writeln(df,s);
 close(df);
 {$I+}
  if IOResult <> 0 then
  begin
    asm
     mov ax,0003h
     int 10h
    end;
    writeln;
    writeln(' ERROR: Can''t save to configuration file!');
    writeln;
    halt(1);
  end;


end
else
begin
{$I-}
 assign(df,digcfg);
 rewrite(df);
    writeln(df,';');
    writeln(df,id);
    writeln(df,';');
    writeln(df);
    write(df,'DEVICE      ');
    writeln(df,digs[selected_dig].name);
    write(df,'DRIVER      ');
    s := uppercase(digs[selected_dig].drvfile);
    delete(s,1,1);
    delete(s,length(s),1);
    writeln(df,s);
    write(df,'IO_ADDR     ');
    s := hexw(audio.io);
    delete(s,1,1);
    s := s + 'h';
    writeln(df,s);
    write(df,'IRQ         ');
    if audio.irq = 0 then
    begin
     s := '-1';
    end
    else
    begin
     str(audio.irq,s);
    end;
    writeln(df,s);
    write(df,'DMA_8_BIT   ');
    if audio.dma = 0 then
    begin
     s := '-1';
    end
    else
    begin
     str(audio.dma,s);
    end;
    writeln(df,s);
    write(df,'DMA_16_BIT  ');
    if audio.dma2 = 0 then
    begin
     s := '-1';
    end
    else
    begin
     str(audio.dma2,s);
    end;
    writeln(df,s);
 close(df);
 {$I+}
  if IOResult <> 0 then
  begin
    asm
     mov ax,0003h
     int 10h
    end;
    writeln;
    writeln(' ERROR: Can''t save to configuration file!');
    writeln;
    halt(1);
  end;

end;
end;


{====================================== Load Settings ========================}

function Lowercase(s : string) : string;
var scnt : byte;
    bs   : string;
begin
bs := '';
for scnt := 1 to length(s) do
begin
 if s[scnt] in ['A'..'Z'] then
 begin
  bs := bs + char(ord(s[scnt])+32);
 end
 else
 begin
  bs := bs + s[scnt];
 end;
end;
 Lowercase := bs;
end;



Procedure Create_new_keyfile;
var cnt : byte;
begin
   for cnt := 1 to 12 do
   begin
    keycfg[cnt].keyname := 'key_'+Lowercase(KText[cnt]);
   end;
   keycfg[1].scancode := 72;
   keycfg[2].scancode := 80;
   keycfg[3].scancode := 75;
   keycfg[4].scancode := 77;
   keycfg[5].scancode := 56;
   keycfg[6].scancode := 51;
   keycfg[7].scancode := 52;
   keycfg[8].scancode := 54;
   keycfg[9].scancode := 57;
   keycfg[10].scancode := 29;
   keycfg[11].scancode := 30;
   keycfg[12].scancode := 44;

   SaveKeyFile;
end;



Procedure LoadSoundConfig;
var i : string;
    dc : byte;
    c  : integer;
begin
 if not fileexist(digcfg) then
 begin
  writeln;
  writeln('ERROR: File ',digcfg,' not found!');
  writeln;
  halt(1);
 end;
 if not fileexist(mdicfg) then
 begin
  writeln;
  writeln('ERROR: File ',mdicfg,' not found!');
  writeln;
  halt(1);
 end;

 assign(df,digcfg);
 reset(df);
  readln(df,s);
  readln(df,i);
  readln(df,s);
  readln(df,s);
  readln(df,s);

  if (i <> id) or (s[1] <> 'D') then
  begin
    writeln;
    writeln('ERROR: File ',digcfg,' is corrupted!');
    writeln;
    close(df);
    halt(1);
  end;

  dig.name := s;
  readln(df,dig.driver);
  readln(df,dig.io);
  readln(df,dig.irq);
  readln(df,dig.dma_8_bit);
  readln(df,dig.dma_16_bit);
 close(df);

 assign(mf,mdicfg);
 reset(mf);
  readln(mf,s);
  readln(mf,i);
  readln(mf,s);
  readln(mf,s);
  readln(mf,s);

  if (i <> id) or (s[1] <> 'D') then
  begin
    writeln;
    writeln('ERROR: File ',mdicfg,' is corrupted!');
    writeln;
    close(mf);
    halt(1);
  end;

  mdi.name := s;
  readln(mf,mdi.driver);
  readln(mf,mdi.io);
  readln(mf,mdi.irq);
  readln(mf,mdi.dma_8_bit);
  readln(mf,mdi.dma_16_bit);
  close(mf);

  s := mdi.driver;
  delete(s,1,12);
  s := '['+s+']';
  s := uppercase(s);

  for dc := 0 to nummid+1 do
  begin
   if dc <= nummid then
   begin
   if uppercase(mids[dc].drvfile) = s then
   begin
    selected_mid := dc;
    break;
   end;
   end;
  end;


  if selected_mid = nummid+1 then
  begin
   selected_mid := $FF;
   m := 'Music device: None';
  end
  else
  begin
   m := 'Music device: '+mids[selected_mid].name;
  end;

  s := mdi.io;
  delete(s,1,length(s)-4);
  delete(s,4,1);
  val('$'+s,music.io,c);
  if c <> 0 then music.io := 0;
  s := mdi.irq;
  delete(s,1,length(s)-2);
  if s = '-1' then
  begin
    music.irq := 0;
  end
  else
  begin
   val(s,music.irq,c);
   if c <> 0 then music.irq := 0;
  end;
  s := mdi.dma_8_bit;
  delete(s,1,length(s)-2);
  if s = '-1' then
  begin
    music.dma := 0;
  end
  else
  begin
   val(s,music.dma,c);
   if c <> 0 then music.dma := 0;
  end;
  s := mdi.dma_16_bit;
  delete(s,1,length(s)-2);
  if s = '-1' then
  begin
    music.dma2 := 0;
  end
  else
  begin
   val(s,music.dma2,c);
   if c <> 0 then music.dma2 := 0;
  end;

  s := dig.io;
  delete(s,1,length(s)-4);
  delete(s,4,1);
  val('$'+s,audio.io,c);
  if c <> 0 then audio.io := 0;
  s := dig.irq;
  delete(s,1,length(s)-2);
  if s = '-1' then
  begin
    audio.irq := 0;
  end
  else
  begin
   val(s,audio.irq,c);
   if c <> 0 then audio.irq := 0;
  end;
  s := dig.dma_8_bit;
  delete(s,1,length(s)-2);
  if s = '-1' then
  begin
    audio.dma := 0;
  end
  else
  begin
   val(s,audio.dma,c);
   if c <> 0 then audio.dma := 0;
  end;
  s := dig.dma_16_bit;
  delete(s,1,length(s)-2);
  if s = '-1' then
  begin
    audio.dma2 := 0;
  end
  else
  begin
   val(s,audio.dma2,c);
   if c <> 0 then audio.dma2 := 0;
  end;

  s := dig.driver;
  delete(s,1,12);
  s := '['+s+']';
  for dc := 0 to numdig+1 do
  begin
   if dc <= numdig then
   begin
   if uppercase(digs[dc].drvfile) = uppercase(s) then
   begin
    selected_dig := dc;
    break;
   end;
   end;
  end;

  if selected_dig = numdig+1 then
  begin
   selected_dig := $FF;
   d := 'Sound device: None';
  end
  else
  begin
   d := 'Sound device: '+digs[selected_dig].name;
  end;

end;



Procedure LoadKeyFile;
var cnt,strc : byte;
    ec       : integer;
    l,n   : string;
begin
   if fileexist(keyfile) then
   begin
     assign(kf,keyfile);
     reset(kf);
     for cnt := 1 to 12 do
     begin
      readln(kf,l);

      strc := length(l);
      while (strc > 0) and (l[strc] <> ' ') do
      begin
       dec(strc);
      end;

      if strc = 0 then
      begin
       close(kf);
       Create_new_keyfile;
       exit;
      end
      else
      begin
       n := copy(l,strc+1,length(l)-strc);
       delete(l,strc+1,length(l)-(strc-1));
       keycfg[cnt].keyname := copy(l,1,strc-1);
       val(n,keycfg[cnt].scancode,ec);
      end;
     end;

     close(kf);

   end
   else
   begin
    Create_new_keyfile;
   end;



end;




{=============================== Additional GFX =============================}

Procedure Keyfield(x,y,x1,y1 : word; Text : string);
var cx,cy,mx,my : word;
begin
  Block(x,y,x1,y1,15);
  rectangle(x,y,x1,y1);
  mx := x+(x1-x) div 2;
  my := y+(y1-y) div 2;
  px := mx-((length(text) div 2)*8);
  Out(px,my-4,1,0,4,text);
end;

Function GetEntry(x,y,x1,y1 : word; num : byte) : string;
var entry         : string;
    c             : byte;
    key           : char;
begin
      hidecursor;
      Keyfield(x,y,x1,y1,'   ');
      line(px,y1-4,px+8,y1-4,4);

      c := 1;
      entry := '';
      while iskeypressed do getkey;

      repeat;

      key := Getkey;
      if Key in ['0'..'9'] then
      begin
        entry := entry + key;
        Keyfield(x,y,x1,y1,entry);
        inc(c);
        if c < num+1 then line((px+(length(entry)*8)),y1-4,(px+(length(entry)*8))+8,y1-4,4);
      end
      else
      begin
       if (key <> #13) and (key <> #27) then
       begin
         SpkSound(500);
         xdelay(100);
         SpkNosound;
       end;
      end;

      until (c = num+1)
         or (key = #13)
         or (key = #27)
         or (leftbutton)
         or (rightbutton);
      showcursor;
      GetEntry := Entry;
end;


Procedure LevelNameScroller(start : byte);
begin
   hidecursor;
   Block(80,180,320,408,15);
   rectangle(80,180,320,408);
   rectangle(305,181,320,407);
   button(305,180,320,195,false,'');
   button(305,393,320,408,false,'');

   for cnt := 1 to 16 do
   begin
      if (start+(cnt-1)) = selected_lvl then
      begin
        out(100,185+((cnt-1)*14),1,0,4,level[start+(cnt-1)]);
      end
      else
      begin
        out(100,185+((cnt-1)*14),1,0,8,level[start+(cnt-1)]);
      end;
   end;

   pos_ls := (start-1)*(393-195) div num_lvl;
   block(306,195+pos_ls,319,195+pos_ls+159,7);
   rectangle(305,195+pos_ls,320,195+pos_ls+159);
   showcursor;
end;

Procedure UpdateLevelNameScroller(start : byte);
begin
   hidecursor;
   Block(81,181,304,407,15); {clear text}

   for cnt := 1 to 16 do
   begin
      if (start+(cnt-1)) = selected_lvl then
      begin
        out(100,185+((cnt-1)*14),1,0,4,level[start+(cnt-1)]);
      end
      else
      begin
        out(100,185+((cnt-1)*14),1,0,8,level[start+(cnt-1)]);
      end;
   end;

   showcursor;
end;



{==========================  Draw Menus =======================================}






Procedure DrawButtons_Main;
begin
 hidecursor;
 Button(266,250,374,275,false,Mtext[1]);
 Button(266,277,374,302,false,Mtext[2]);
 Button(266,304,374,329,false,Mtext[3]);
 Button(266,331,374,356,false,Mtext[4]);
 Button(266,358,374,383,false,'Quit');
 showcursor;
end;

Procedure DrawButtons;
begin
   Window(250,235,390,400);
   DrawButtons_main;
end;


Procedure DrawConfig;
begin
  if selected_mid = $FF then
  begin
   m := 'Music: None';
  end
  else
  begin
   m := 'Music: '+mids[selected_mid].name;
  end;

  if selected_dig = $FF then
  begin
   d := 'Digital audio: None';
  end
  else
  begin
   d := 'Digital audio: '+digs[selected_dig].name;
  end;
   Window(10,110,630,225);
   out(320-((length('Configuration:') div 2)*15),130,2,1,4,'Configuration:');
   out(320-((length(d) div 2)*8),164,1,0,1,d);
   out(320-((length(m) div 2)*8),184,1,0,1,m);
end;


Procedure DrawMainMenu;
begin
   Window(100,10,540,100);
   out(320-((length(Title) div 2)*15),28,2,1,4,Title);
   out(320-((length(Ver) div 2)*8),58,1,0,4,Ver);
   out(320-((length(Author) div 2)*8),73,1,0,1,Author);
end;

Procedure DrawSoundMenu(t : byte);
var dc : byte;
begin
   hidecursor;
   Window(10,235,630,480);
   Button(322,448,430,473,false,'Accept');
   Button(211,448,319,473,false,'Cancel');
   Block(30,270,610,440,15);
   rectangle(30,270,610,440);

   if t = Midi then
   begin
    out(320-((length('Available music drivers:') div 2)*16),245,2,1,4,'Available music drivers:');

    for dc := 0 to nummid do
    begin
      out(320-(((length(mids[dc].name)) div 2)*8),274+(dc*14),1,0,8,mids[dc].name);
    end;
     marked := selected_mid;
       old  := selected_mid;

      if marked <> $FF then
      out(320-(((length(mids[marked].name)) div 2)*8),274+(marked*14),1,0,4,mids[marked].name);
   end
   else
   begin
    out(320-((length('Available digital audio drivers:') div 2)*16),245,2,1,4,'Available digital audio drivers:');

    for dc := 0 to numdig do
    begin
      out(320-(((length(digs[dc].name)) div 2)*8),274+(dc*14),1,0,8,digs[dc].name);
    end;
     marked := selected_dig;
       old  := selected_dig;

     if marked <> $FF then
     out(320-(((length(digs[marked].name)) div 2)*8),274+(marked*14),1,0,4,digs[marked].name);
   end;
   showcursor;
end;


Procedure Draw_Sound_config(t : byte);
var ponly,hdma,blaster : boolean;
    p,i,d,d2           : word;
begin
   ponly := false;
   hdma := false;
   blaster := false;
   hidecursor;
   Window(10,235,630,480);
   out(320-(((length('Configure')) div 2)*8),250,1,1,4,'Configure');
   if t = Midi then
   begin
    ponly := PortOnly(mids[marked]);
    hdma := highDMA(mids[marked]);
    blaster := useBLASTER(mids[marked]);
    if blaster then
    begin
     GetBLASTERSettings(music.io,music.irq,music.dma,music.dma2);
    end;
    p := music.io;
    i := music.irq;
    d := music.dma;
    d2 := music.dma2;
    out(320-(((length(mids[marked].name)) div 2)*8),260,1,1,4,mids[marked].name);
   end
   else
   begin
    ponly := PortOnly(digs[marked]);
    hdma := highDMA(digs[marked]);
    blaster := useBLASTER(digs[marked]);
    if blaster then
    begin
     GetBLASTERSettings(audio.io,audio.irq,audio.dma,audio.dma2);
    end;
    p := audio.io;
    i := audio.irq;
    d := audio.dma;
    d2 := audio.dma2;
    out(320-(((length(digs[marked].name)) div 2)*8),260,1,1,4,digs[marked].name);
   end;




   out(247,292,1,0,4,'I/O Port:');
   Keyfield(332,292,432,302,hexw(p));

   if not ponly then
   begin
     out(240,312,1,0,4,'Interrupt:');
     Keyfield(332,312,432,322,hexb(i));
     out(288,332,1,0,4,'DMA:');
     Keyfield(332,332,432,342,hexb(d));
     if hdma then
     begin
       out(280,352,1,0,4,'HDMA:');
       Keyfield(332,352,432,362,hexb(d2));
     end;
   end;
   Button(266,438,374,463,false,'OK');
   showcursor;
end;


Procedure Draw_Network_Menu;
begin
   hidecursor;
   block(1,110,640,480,0);
   Window(50,110,590,440);
   out(320-((length('Network Settings') div 2)*16),125,2,1,4,'Network Settings');
   Button(350,190,438,215,false,'Start Game');
   Button(350,230,438,255,false,'Cancel');
   out(200-((length('Select level:') div 2)*8),165,1,0,4,'Select level:');
   selected_lvl := 1;
   lvl_start := 1;
   LevelNameScroller(1);
   hidecursor;
   out(340,320,1,0,4,'Note:');
   out(340,340,1,0,4,'- Only two player game');
   out(340,360,1,0,4,'- Both player have to ');
   out(356,368,1,0,4,'select the same level');
   showcursor;
end;


Procedure Draw_Key_Menu;
begin
   hidecursor;
   Window(160,20,480,460);
   out(320-((length(Mtext[1]) div 2)*16),50,2,1,4,Mtext[1]);
      {Button: 108x25}
   Button(200, 90,308,115,false,Ktext[1]);
   Keyfield(332,92,432,113,Getkeyname(KeyCfg[1].scancode));
   Button(200,117,308,142,false,Ktext[2]);
   Keyfield(332,119,432,140,Getkeyname(KeyCfg[2].scancode));
   Button(200,144,308,169,false,Ktext[3]);
   Keyfield(332,146,432,167,Getkeyname(KeyCfg[3].scancode));
   Button(200,171,308,196,false,Ktext[4]);
   Keyfield(332,173,432,194,Getkeyname(KeyCfg[4].scancode));
   Button(200,198,308,223,false,Ktext[5]);
   Keyfield(332,200,432,221,Getkeyname(KeyCfg[5].scancode));
   Button(200,225,308,250,false,Ktext[6]);
   Keyfield(332,227,432,248,Getkeyname(KeyCfg[6].scancode));
   Button(200,252,308,277,false,Ktext[7]);
   Keyfield(332,254,432,275,Getkeyname(KeyCfg[7].scancode));
   Button(200,279,308,304,false,Ktext[8]);
   Keyfield(332,281,432,302,Getkeyname(KeyCfg[8].scancode));
   Button(200,306,308,331,false,Ktext[9]);
   Keyfield(332,308,432,329,Getkeyname(KeyCfg[9].scancode));
   Button(200,333,308,358,false,Ktext[10]);
   Keyfield(332,335,432,356,Getkeyname(KeyCfg[10].scancode));
   Button(200,360,308,385,false,Ktext[11]);
   Keyfield(332,362,432,383,Getkeyname(KeyCfg[11].scancode));
   Button(200,387,308,412,false,Ktext[12]);
   Keyfield(332,389,432,410,Getkeyname(KeyCfg[12].scancode));
   Button(266,425,374,450,false,'OK');
   showcursor;
end;



{============================== Mouse Click handling ===================}

Procedure MouseClicks_Main;
begin
 hidecursor;

 if (GetMouseX >= 266) and (GetMouseX <= 374) and
    (GetMouseY >= 250) and (GetMouseY <= 275) then
 begin
  Button(266,250,374,275,true,Mtext[1]);
  pressed := 1;
 end;

 if (GetMouseX >= 266) and (GetMouseX <= 374) and
    (GetMouseY >= 277) and (GetMouseY <= 302) then
 begin
  Button(266,277,374,302,true,Mtext[2]);
  pressed := 2;
 end;


 if (GetMouseX >= 266) and (GetMouseX <= 374) and
    (GetMouseY >= 304) and (GetMouseY <= 329) then
 begin
  Button(266,304,374,329,true,Mtext[3]);
  pressed := 3;
 end;


 if (GetMouseX >= 266) and (GetMouseX <= 374) and
    (GetMouseY >= 331) and (GetMouseY <= 356) then
 begin
  Button(266,331,374,356,true,Mtext[4]);
  pressed := 4;
 end;

 if (GetMouseX >= 266) and (GetMouseX <= 374) and
    (GetMouseY >= 358) and (GetMouseY <= 383) then
 begin
  Button(266,358,374,383,true,'Quit');
  pressed := 5;
 end;
  showcursor;
end;




Procedure MouseClicks_Keys;
begin
 hidecursor;

 if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 90) and (GetMouseY <= 115) then
 begin
  Button(200, 90,308,115,true,Ktext[1]);
  pressed := 1;
 end;

 if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 117) and (GetMouseY <= 142) then
 begin
  Button(200,117,308,142,true,Ktext[2]);
  pressed := 2;
 end;

 if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 144) and (GetMouseY <= 169) then
 begin
  Button(200,144,308,169,true,Ktext[3]);
  pressed := 3;
 end;

  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 171) and (GetMouseY <= 196) then
 begin
  Button(200,171,308,196,true,Ktext[4]);
  pressed := 4;
 end;

  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 198) and (GetMouseY <= 223) then
 begin
  Button(200,198,308,223,true,Ktext[5]);
  pressed := 5;
 end;

  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 225) and (GetMouseY <= 250) then
 begin
  Button(200,225,308,250,true,Ktext[6]);
  pressed := 6;
 end;


  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 252) and (GetMouseY <= 277) then
 begin
  Button(200,252,308,277,true,Ktext[7]);
  pressed := 7;
 end;


  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 279) and (GetMouseY <= 304) then
 begin
  Button(200,279,308,304,true,Ktext[8]);
  pressed := 8;
 end;


  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 306) and (GetMouseY <= 331) then
 begin
  Button(200,306,308,331,true,Ktext[9]);
  pressed := 9;
 end;


  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 333) and (GetMouseY <= 358) then
 begin
  Button(200,333,308,358,true,Ktext[10]);
  pressed := 10;
 end;


  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 360) and (GetMouseY <= 385) then
 begin
  Button(200,360,308,385,true,Ktext[11]);
  pressed := 11;
 end;


  if (GetMouseX >= 200) and (GetMouseX <= 308) and
    (GetMouseY >= 387) and (GetMouseY <= 412) then
 begin
  Button(200,387,308,412,true,Ktext[12]);
  pressed := 12;
 end;


 if (GetMouseX >= 266) and (GetMouseX <= 374) and
    (GetMouseY >= 425) and (GetMouseY <= 450) then
 begin
  Button(266,425,374,450,true,'OK');
  pressed := 13;
  SaveKeyfile;
 end;

 showcursor;
end;


Procedure MouseClicks_Sound(t : byte);
begin
 hidecursor;

 if (GetMouseX >= 30) and (GetMouseX <= 610) and
    (GetMouseY >= 270) and (GetMouseY <= 440) then
 begin
   if marked <> $FF then old := marked;
   marked := (GetMouseY - 274)  div 14;

   if t = Midi then
   begin
      if marked > nummid then marked := old;
      if old < $FF then out(320-(((length(mids[old].name)) div 2)*8),274+(old*14),1,0,8,mids[old].name);
      out(320-(((length(mids[marked].name)) div 2)*8),274+(marked*14),1,0,4,mids[marked].name);
   end
   else
   begin
      if marked > numdig then marked := old;
      if old < $FF then out(320-(((length(digs[old].name)) div 2)*8),274+(old*14),1,0,8,digs[old].name);
      out(320-(((length(digs[marked].name)) div 2)*8),274+(marked*14),1,0,4,digs[marked].name);
   end;

 end;

 if (GetMouseX >= 211) and (GetMouseX <= 319) and
    (GetMouseY >= 448) and (GetMouseY <= 473) then
 begin
  Button(211,448,319,473,true,'Cancel');
  pressed := 1;
 end;

 if (GetMouseX >= 322) and (GetMouseX <= 430) and
    (GetMouseY >= 448) and (GetMouseY <= 473) then
 begin
  Button(322,448,430,473,true,'Accept');
  pressed := 2;
 end;


 showcursor;
end;


Procedure MouseClicks_Network;
begin
 hidecursor;

 if (GetMouseX >= 350) and (GetMouseX <= 438) and
    (GetMouseY >= 230) and (GetMouseY <= 255) then
 begin
  Button(350,230,438,255,true,'Cancel');
  Wait4Mouse;
  Button(350,230,438,255,false,'Cancel');
  pressed := 1;
 end;

 if (GetMouseX >= 350) and (GetMouseX <= 438) and
    (GetMouseY >= 190) and (GetMouseY <= 215) then
 begin
  Button(350,190,438,215,true,'Start Game');
  Wait4Mouse;
  Button(350,190,438,215,false,'Start Game');
  pressed := 2;
 end;


 if (GetMouseX >= 305) and (GetMouseX <= 320) and
    (GetMouseY >= 180) and (GetMouseY <= 195) then
 begin
  button(305,180,320,195,true,'');
  Wait4Mouse;
  button(305,180,320,195,false,'');
  pressed := 3;
 end;

 if (GetMouseX >= 305) and (GetMouseX <= 320) and
    (GetMouseY >= 393) and (GetMouseY <= 408) then
 begin
  button(305,393,320,408,true,'');
  Wait4Mouse;
  button(305,393,320,408,false,'');
  pressed := 4;
 end;


 if (GetMouseX >= 81) and (GetMouseX <= 304) and
    (GetMouseY >= 181) and (GetMouseY <= 407) then
 begin
   if (selected_lvl >= lvl_start) and (selected_lvl <= lvl_start+15) then
   out(100,185+((selected_lvl-1)*14),1,0,8,level[selected_lvl]);

   selected_lvl := lvl_start+(GetMouseY-185) div 14;
   out(100,185+((selected_lvl-lvl_start)*14),1,0,4,level[selected_lvl]);
  end;



 showcursor;
end;






{=================================== Buttons and sub routines ========================}


{============================  Keyboard =====================}
Procedure Get_new_key(nr : byte);
var s : string;
    mx : word;
    sc : byte;
begin
  InitKB;
  hidecursor;
  Window(160,150,480,300);
  mx := 165+(475-165) div 2;
  out(mx-(8*15),200,2,1,4,'Press a key for');
  s := '"'+ Ktext[nr] + '"';
  Out(mx-((length(s) div 2)*16),225,2,1,4,s);
  showcursor;
  while iskeypressed do getkey;
  sc := GetAnyKey;
  KeyCfg[nr].scancode := sc;
  hidecursor;
  block(160,150,480,300,0);
  Draw_Key_Menu;
  showcursor;
  DeinitKB;
end;

Procedure DoButtons_Keys;
begin

  if pressed in [1..12] then
  begin
   Get_new_Key(pressed);
  end;

  if pressed = 13 then
  begin
    gomain := true;
  end;

end;


Procedure Key_bindings;
begin
  pressed := 0;
  clicked := false;
  gomain := false;
  Draw_Key_Menu;
 repeat

    if (Catchkey = #27) then
    begin
     clicked := true;
     pressed := 13;
     Button(266,425,374,450,true,'OK');
     while iskeypressed do getkey;
    end;

    if LeftButton then
    begin
     if not clicked then
     begin
      clicked := true;
      MouseClicks_Keys;
     end;

    end
    else
    begin
     if clicked then
     begin
      DoButtons_Keys;
      pressed := 0;
      clicked := false;
     end;
    end;


  until gomain;
  gomain := false;
   hidecursor;
   Block(160,20,480,460,0);
   DrawMainMenu;
   DrawConfig;
   DrawButtons;
end;


{============================  Sound =====================}
Procedure DoButtons_Sound(t : byte);
var detected,cfg,sel,ponly,hdma,blaster : boolean;
    mx,p       : word;
    d,d1,i     : byte;
    error      : integer;
begin

  if pressed = 2 then {Accept}
  begin
    hidecursor;
    Button(322,448,430,473,false,'Accept');

    if t = Midi then
    begin
      detected := detectHardware(mids[marked]);
      cfg := Configureable(mids[marked]);
      sel := Selectable(mids[marked]);
      hdma := highDMA(mids[marked]);
      blaster := useBLASTER(mids[marked]);
      ponly   := PortOnly(mids[marked]);

      if not cfg then
      begin
       if (mids[marked].drvfile = '[adlib.mdi]') or
          (mids[marked].drvfile = '[opl3.mdi]') then
       begin
        music.io := $388;
        music.irq := 0;
        music.dma := 0;
        music.dma2 := 0;
       end;
        if (mids[marked].drvfile = '[mt32mpu.mdi]') or
        (mids[marked].drvfile = '[mpu401.mdi]') then
       begin
        music.io := $330;
        music.irq := 0;
        music.dma := 0;
        music.dma2 := 0;
       end;
      end;

    end
    else
    begin
      detected := detectHardware(digs[marked]);
      cfg := Configureable(digs[marked]);
      sel := Selectable(digs[marked]);
      hdma := highDMA(digs[marked]);
      blaster := useBLASTER(digs[marked]);
      ponly   := PortOnly(digs[marked]);

      if not cfg then
      begin
       if (digs[marked].drvfile = '[rap10.dig]') or
          (digs[marked].drvfile = '[jammer.dig]') or
          (digs[marked].drvfile = '[[adrv688.dig]') then
       begin
        audio.io := $388;
        audio.irq := 0;
        audio.dma := 0;
        audio.dma2 := 0;
       end;
       if (digs[marked].drvfile = '[sndsys.dig]') then
       begin
        audio.io := $510;
        audio.irq := 0;
        audio.dma := 0;
        audio.dma2 := 0;
       end;

      end;
    end;


    if not detected then
    begin
      Window(100,150,540,300);
      out(140,200,2,1,4,'Sound device not found!');
      Button(266,248,374,273,false,'OK');
      showcursor;
      repeat;
      until (LeftButton) and (GetMouseX >= 266) and (GetMouseX <= 374) and
            (GetMouseY >= 248) and (GetMouseY <= 273);
      Button(266,248,374,273,true,'OK');
      Wait4Mouse;
      hidecursor;
      block(100,150,540,300,0);
      Window(10,110,630,225);
      DrawConfig;
      DrawSoundMenu(t);
      showcursor;
     end
     else
     begin

       if (cfg = true) and (sel = true) and (blaster = false) then
       begin
         Draw_Sound_config(t);
         gomain := false;
         repeat

           if (LeftButton) and
              (GetMouseX >= 332) and (GetMouseX <= 432) and
              (GetMouseY >= 292) and (GetMouseY <= 302) then
           begin
             val('$'+GetEntry(332,292,432,302,3),p,error);
             Keyfield(332,292,432,302,hexw(p));
           end;

           if not ponly then
           begin

              if (LeftButton) and
              (GetMouseX >= 332) and (GetMouseX <= 432) and
              (GetMouseY >= 312) and (GetMouseY <= 322) then
              begin
                val('$'+GetEntry(332,312,432,322,2),i,error);
                Keyfield(332,292,432,302,hexb(i));
              end;

              if (LeftButton) and
              (GetMouseX >= 332) and (GetMouseX <= 432) and
              (GetMouseY >= 332) and (GetMouseY <= 342) then
              begin
                val(GetEntry(332,332,432,342,2),d,error);
                Keyfield(332,292,432,302,hexb(d));
              end;


           if hdma then
           begin
                if (LeftButton) and
                (GetMouseX >= 332) and (GetMouseX <= 432) and
                (GetMouseY >= 352) and (GetMouseY <= 362) then
                begin
                  val(GetEntry(332,352,432,362,2),d1,error);
                  Keyfield(332,352,432,362,hexb(d1));
                end;
           end;
          end;

            if (LeftButton) and (GetMouseX >= 266) and (GetMouseX <= 374) and
            (GetMouseY >= 438) and (GetMouseY <= 463) or (Catchkey = #27) then
             begin
               hidecursor;
               Button(266,438,374,463,true,'OK');
               Wait4Mouse;
               Button(266,438,374,463,false,'OK');
               showcursor;
               while iskeypressed do getkey;
               gomain := true;
             end;

          until gomain;
          if t = Midi then
          begin
           music.io := p;
           music.irq := i;
           music.dma := d;
           music.dma2 := d1;
          end
          else
          begin
           audio.io := p;
           audio.irq := i;
           audio.dma := d;
           audio.dma2 := d1;
          end;

       end
       else
       begin
        gomain := true;
       end;

      end;


      if t = midi then selected_mid := marked else selected_dig := marked;
      SaveSoundConfig(t);
     end;

  if pressed = 1 then
  begin
    gomain := true;
  end;

end;



{============================  Network =====================}
Procedure DoButtons_Network;
begin
  if pressed = 1 then
  begin
    gomain := true;
  end;
  if pressed = 2 then
  begin
    lvl := '-warp '+copy(level[selected_lvl],1,4);
    block(1,1,640,480,0);  {For DOSBox compabilty}
    HideCursor;
    asm
     mov ax,0003h
     int 10h
    end;
    if not fileexist('IPXSETUP.EXE') then
    begin
     writeln('ERROR: File IPXSETUP.EXE not found!');
     writeln;
     halt(1);
    end
    else
    begin
     writeln(Title,' ',author);
     writeln('Selected level for network game: ',level[selected_lvl]);
     DosShell('/C IPXSETUP.EXE '+lvl);
     if error <> 0 then
     begin
      writeln;
      writeln('ERROR: Error ',error,' during execution of IPXSETUP.EXE');
      writeln;
      ResetMouse;
      halt(1);
     end;
     ResetMouse;
     halt(0);
    end;
  end;

  if pressed = 3 then
  begin
   if lvl_start  > 1 then  dec(lvl_start);
   if lvl_start <> opos_lvl then
   begin
    UpdateLevelNameScroller(lvl_start);
    hidecursor;
    opos_ls := pos_ls;
    pos_ls := (lvl_start-1)*(393-195) div num_lvl;
    block(306,195+pos_ls,319,195+pos_ls+158,7);
    block(306,195+pos_ls+159,319,195+opos_ls+158,15);
    rectangle(305,195+pos_ls,320,195+pos_ls+158);
    opos_lvl := lvl_start;
    showcursor;
   end;
  end;

  if pressed = 4 then
  begin
   if lvl_start  < num_lvl-15 then  inc(lvl_start);
   if lvl_start <> opos_lvl then
   begin
    UpdateLevelNameScroller(lvl_start);
    hidecursor;
    opos_ls := pos_ls;
    pos_ls := (lvl_start-1)*(393-195) div num_lvl;
    block(306,195+pos_ls,319,195+pos_ls+158,7);
    block(306,195+opos_ls,319,195+pos_ls,15);
    rectangle(305,195+pos_ls,320,195+pos_ls+158);
    opos_lvl := lvl_start;
    showcursor;
   end;

  end;

end;



Procedure Music_Device;
begin
pressed := 0;
clicked := false;
gomain := false;

DrawSoundMenu(Midi);

 repeat

   if (Catchkey = #27) then
    begin
     clicked := true;
     pressed := 1;
     Button(211,448,319,473,true,'Cancel');
     while iskeypressed do getkey;
    end;

    if LeftButton then
    begin
     if not clicked then
     begin
      clicked := true;
      MouseClicks_Sound(Midi);
     end;

    end
    else
    begin
     if clicked then
     begin
      DoButtons_Sound(Midi);
      pressed := 0;
      clicked := false;
     end;
    end;


  until gomain;
   gomain := false;
   hidecursor;
   Block(10,235,630,480,0);
   DrawConfig;
   DrawButtons;
end;

Procedure Audio_Device;
begin
pressed := 0;
clicked := false;
gomain := false;

DrawSoundMenu(Sound);
repeat

   if (Catchkey = #27) then
    begin
     clicked := true;
     pressed := 1;
     Button(211,448,319,473,true,'Cancel');
     while iskeypressed do getkey;
    end;

    if LeftButton then
    begin
     if not clicked then
     begin
      clicked := true;
      MouseClicks_Sound(Sound);
     end;

    end
    else
    begin
     if clicked then
     begin
      DoButtons_Sound(Sound);
      pressed := 0;
      clicked := false;
     end;
    end;


  until gomain;
   gomain := false;
   hidecursor;
   Block(10,235,630,480,0);
   DrawConfig;
   DrawButtons;

end;

Procedure Network_Game;
begin
pressed := 0;
clicked := false;
gomain := false;

Draw_Network_Menu;
repeat

   if (Catchkey = #27) then
    begin
     clicked := true;
     pressed := 1;
     Button(211,448,319,473,true,'Cancel');
     while iskeypressed do getkey;
    end;

    if LeftButton then
    begin
     if not clicked then
     begin
      clicked := true;
      MouseClicks_Network;
     end;

    end
    else
    begin
     if clicked then
     begin
      DoButtons_Network;
      pressed := 0;
      clicked := false;
     end;
    end;


  until gomain;
   gomain := false;
   hidecursor;
   block(1,110,640,480,0);
   DrawConfig;
   DrawButtons;
end;





Procedure DoButtons_Main;
begin
 HideCursor;
 case pressed of
  1:
     begin
     Button(256,250,364,275,false,Mtext[1]);
     Key_bindings;
     end;
  2:
     begin
     Button(256,277,364,302,false,Mtext[2]);
     Music_Device;
     end;
  3:
     begin
     Button(256,304,364,329,false,Mtext[3]);
     Audio_Device;
     end;

  4:                                        {Network}
     begin
     Button(256,331,364,356,false,Mtext[4]);
     Network_Game;
     end;

  5:
     begin
     Button(256,358,364,383,false,'Quit');
     Quit := true;
     end;

 end;
   ShowCursor;
end;





begin
  writeln;
  writeln(title,' ',ver);
  writeln;
  if not detectVGA then
  begin
   writeln(' ERROR: No VGA compatible graphics adapter found! ');
   writeln;
   halt(1);
  end;

  if not MouseInstalled then
  begin
   writeln(' ERROR: No mousedriver installed! ');
   writeln;
   halt(1);
  end;

   write('Loading audio drivers...');

   FindDigitalAudoDrivers;
   FindMidiAudoDrivers;

   if (numdig = 0) or (nummid = 0) then
   begin
    writeln;
    writeln;
    writeln('ERROR: Miles Design Audio Interface Library not found!');
    writeln;
    halt(1);
   end;

   writeln('OK');


   LoadSoundConfig;
   LoadKeyFile;
  asm
   mov ax,0012h
   int 10h
  end;

   Load_BIOS_font;
   ResetMouse;
   DrawMainMenu;
   DrawConfig;
   DrawButtons;

   ShowCursor;

   while iskeypressed do Getkey;
 repeat


    if (Catchkey = #27) then
    begin
     clicked := true;
     Button(256,358,364,383,true,'Quit');
     pressed := 5;
     while iskeypressed do getkey;
    end;


    if LeftButton then
    begin
     if not clicked then
     begin
      clicked := true;
      MouseClicks_Main;
     end;

    end
    else
    begin
     if clicked then
     begin
      DoButtons_Main;
      pressed := 0;
      clicked := false;
     end;
    end;

   until quit;
   block(1,1,640,480,0);  {Needed for DOSBox compatibility because it does not clear the vmem like original hardware}
   HideCursor;
  asm
   mov ax,0003h
   int 10h
  end;
  ResetMouse;
  writeln('Type ''MARS'' to play the game...');
end.


