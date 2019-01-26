{This Unit provides functions to collect driver information from Miles Design Audio Interface Library
 Sound driver files.

 v0.1 - 2018/07/09 by Jan Knipperts
       Note: does not read the driver description}

Unit Miles;

interface
uses misc,dos;

const
 maxdrv    = 31;             {maximum number of drivers}


type
 milesdrvinfo = record
     drvfile  : string;                    {name of driver files}
     option   : array[0..9] of string[20]; {options}
     numopt   : byte;                      {number of options}
     name     : string;                    {name of soundcard / driver}
 end;

var
 digs      : array[0..maxdrv] of milesdrvinfo;     {List of digital drivers with options}
 mids      : array[0..maxdrv] of milesdrvinfo;     {List of midi drivers with options}
 numdig    : byte;  {number of digital sound drivers}
 nummid    : byte;  {number of midi sound drivers}

Function LowerCase(up : string) : string;
{Converts a string to lowercase chars}

Function UpperCase(low : string) : string;
{Converts a string to uppercase chars}

Procedure FindDigitalAudoDrivers;
{find all digital audio driver files and reads the options for them from
 AILDRVR.LST. All information are stored in "digs"}

Procedure FindMidiAudoDrivers;
{find all midi audio driver files and reads the options for them from
 AILDRVR.LST. All information are stored in "mids"}

Function DetectHardware(device : milesdrvinfo) : Boolean;

Function Selectable(device : milesdrvinfo) : Boolean;
{Can driver be selected as default?}

Function Configureable(device : milesdrvinfo) : Boolean;
{Driver configuraeble by user?}

Function useBLASTER(device : milesdrvinfo) : Boolean;
{Use BLASTER variable to configure?}

Function highDMA(device : milesdrvinfo) : Boolean;
{Uses a second DMA address?}

Function PortOnly(device : milesdrvinfo) : Boolean;
{Uses only I/O address?}

 function GetBLASTERSettings(var BaseIO, IRQ, DMA, DMA16: word): boolean;
 {Get settings from BLASTER environment var}

implementation


const
 title     = 'Miles Design Audio Interface Library Sound driver information - by Jan Knipperts';
 digid     = 'AIL3DIG';
 mdiid     = 'AIL3MDI';
 listfile  = 'AILDRVR.LST';
 DescBegin = '.SPECIAL_TEXT';
 DescEnd   = '.END_SPECIAL_TEXT';


var
 a,list    : text;
   f       : file;
 info      : milesdrvinfo;
 dummy     : string;
 name      : string;
 dc,oc     : byte;


Function LowerCase(up : string) : string;
{Converts a string to lowercase chars}
var low : string;
    sz  : byte;
begin
  low := '';
  for sz := 1 to length(up) do
  begin
    if up[sz] in ['A'..'Z'] then
    begin
     low := low + char( ( ord(up[sz]) + 32) );
    end
    else
    begin
      low := low + up[sz];
    end;
  end;
   LowerCase := low;
end;


Function UpperCase(low : string) : string;
{Converts a string to uppercase chars}
var up : string;
    sz  : byte;
begin
  up := '';
  for sz := 1 to length(low) do
  begin
   up := up+upcase(low[sz]);
  end;
   UpperCase := up;
end;

  function GetSetting(BLASTER: string; Letter: char; Hex: boolean; var Value: word): boolean;
            var
                EnvStr: string;
                NumStr: string;
                ErrorCode: integer;
            begin
                EnvStr := BLASTER + ' ';
                Delete(EnvStr, 1, Pos(Letter, EnvStr));
                NumStr := Copy(EnvStr, 1, Pos(' ', EnvStr)-1);
                if Hex
                    then Val('$' + NumStr, Value, ErrorCode)
                    else Val(NumStr, Value, ErrorCode);
                if ErrorCode <> 0
                    then GetSetting := false
                    else GetSetting := true;
            end;


  function GetBLASTERSettings(var BaseIO, IRQ, DMA, DMA16: word): boolean;
            var
                EnvStr: string;
                i: byte;
            begin
                EnvStr := GetEnv('BLASTER');
                for i := 1 to Length(EnvStr) do EnvStr[i] := UpCase(EnvStr[i]);
                GetBLASTERSettings := true;
                if EnvStr = ''
                    then
                        GetBLASTERSettings := false
                    else
                        begin
                            if not(GetSetting(EnvStr, 'A', true, BaseIO))
                                then GetBLASTERSettings := false;
                            if not(GetSetting(EnvStr, 'I', false, IRQ))
                                then GetBLASTERSettings := false;
                            if not(GetSetting(EnvStr, 'D', false, DMA))
                                then GetBLASTERSettings := false;

                            GetSetting(EnvStr, 'H', false, DMA16);

                        end;
            end;

 Function GetRealName(filename : string) : string;
 {Reads the name directly from the driver file
  (and checks the file by the way)}
 var Idstring : array[1..7] of char;
     c,c1     : byte;
     name     : string;
 begin
  name := '';
  assign(f,filename);
  reset(f,1);
   blockread(f,idstring,sizeof(idstring));

   if (idstring = DIGID) or (idstring = MDIID) then
   begin
     seek(f,186);
     blockread(f,c,1);
     blockread(f,c1,1);

     if ( upcase(chr(c)) in ['A'..'Z']) and
        ( upcase(chr(c1)) in ['A'..'Z']) then
     begin
      name := name + chr(c);
      name := name + chr(c1);
     end
     else
     begin
      seek(f,1888);
     end;


     while (c > 0) and (filepos(f) < filesize(f)) do
     begin
       blockread(f,c,1);
       name := name + chr(c);
     end;
   end;

  close(f);
  GetRealName := name;
 end;

 Function FindA(search : string) : boolean;
 var autoexec,s : string;
 begin
   autoexec := copy(GetEnv('COMSPEC'),1,3);
   autoexec := autoexec + 'AUTOEXEC.BAT';
   search := uppercase(search);

   if fileexist(autoexec) then
   begin
    assign(a,autoexec);
    reset(a);
     while not eof(a) do
     begin
      readln(a,s);
      if pos(search,uppercase(s)) > 0 then
      begin
       close(a);
       FindA := true;
       exit;
      end;
     end;
    close(a);
   end;
   FindA := false;
 end;

 Function FindC(search : string) : boolean;
 var config,s : string;
 begin
   config := copy(GetEnv('COMSPEC'),1,3);
   config := config + 'CONFIG.SYS';
   search := uppercase(search);

   if fileexist(config) then
   begin
    assign(a,config);
    reset(a);
     while not eof(a) do
     begin
      readln(a,s);
      if pos(search,uppercase(s)) > 0 then
      begin
       close(a);
       FindC := true;
       exit;
      end;
     end;
    close(a);
   end;
   FindC := false;
 end;



Procedure SkipCommentBlock;
{skips empty lines and comments in the AILDRVR.LST file}
begin
 readln(list,dummy);
 while (dummy[1] = ';') or
       (dummy = '') or
       (dummy[1] = ' ') do
  readln(list,dummy);
end;

Procedure SkipDescriptionBlock;
{skips the driver description in the AILDRVR.LST file}
begin
 readln(list,dummy);
 while dummy <> DescEnd do
 begin
  readln(list,dummy);
 end;
end;

Procedure ReadDriverBlock;
{Reads the information and options for the driver.
 outputs them in "info"}
begin
       info.drvfile := dummy;
       readln(list,dummy);
       SkipCommentBlock;

       oc := 0;
       while (dummy[1] = '.') and
             (dummy <> '.NAME') and
             (dummy <> DescBegin) do
       begin
         info.option[oc] := dummy;
         readln(list,dummy);
         if dummy = '' then readln(list,dummy);
         inc(oc);
       end;

       info.numopt := oc;

       if dummy = '.NAME' then
       begin
        readln(list,dummy);
        info.name := dummy;
        readln(list,dummy);
       end;

       if (dummy = '') or (dummy[1] = ';') then SkipCommentBlock;
       if dummy =  DescBegin then SkipDescriptionBlock;
end;

Procedure LookupInfo(search : string);
{looks for a specific driverinformation in the AILDRVR.LST and reads them}
begin
  fillchar(info,sizeof(info),0);
  assign(list,listfile);
  reset(list);
    while not eof(list) do
    begin
     readln(list,dummy);
     if dummy = search then
     begin
      ReadDriverBlock;
      break;
     end;
    end;
  close(list);
end;

Function Selectable(device : milesdrvinfo) : Boolean;
{Can driver be selected as default?}
var option, param, s : string;

begin
 if device.numopt > 0 then
 begin

  for oc := 0 to device.numopt-1 do
  begin

     if pos(' ',device.option[oc]) > 0 then
     begin
      option := copy(device.option[oc],1,pos(' ',device.option[oc])-1);
      param := copy(device.option[oc],pos(' ',device.option[oc])+1,length(device.option[oc]));
     end
     else
     begin
      option := device.option[oc];
      param := '';
     end;


      if option = '.ND' then
      begin
         Selectable := FALSE;
         exit;
      end;
   end;
 end;

end;

Function PortOnly(device : milesdrvinfo) : Boolean;
{Uses only I/O address?}
var option, param, s : string;

begin

 if device.numopt > 0 then
 begin

  for oc := 0 to device.numopt-1 do
  begin

     if pos(' ',device.option[oc]) > 0 then
     begin
      option := copy(device.option[oc],1,pos(' ',device.option[oc])-1);
      param := copy(device.option[oc],pos(' ',device.option[oc])+1,length(device.option[oc]));
     end
     else
     begin
      option := device.option[oc];
      param := '';
     end;


      if option = '.IOA' then
      begin
         PortOnly := True;
         exit;
      end;

   end;

 end;

  PortOnly := false;
end;


Function Configureable(device : milesdrvinfo) : Boolean;
{Driver configuraeble by user?}
var option, param, s : string;

begin
 if device.numopt > 0 then
 begin

  for oc := 0 to device.numopt-1 do
  begin

     if pos(' ',device.option[oc]) > 0 then
     begin
      option := copy(device.option[oc],1,pos(' ',device.option[oc])-1);
      param := copy(device.option[oc],pos(' ',device.option[oc])+1,length(device.option[oc]));
     end
     else
     begin
      option := device.option[oc];
      param := '';
     end;


      if option = '.ION' then
      begin
         Configureable := FALSE;
         exit;
      end;
   end;
 end;

end;

Function highDMA(device : milesdrvinfo) : Boolean;
{Uses a second DMA address?}
var option, param, s : string;

begin
 if device.numopt > 0 then
 begin

  for oc := 0 to device.numopt-1 do
  begin

     if pos(' ',device.option[oc]) > 0 then
     begin
      option := copy(device.option[oc],1,pos(' ',device.option[oc])-1);
      param := copy(device.option[oc],pos(' ',device.option[oc])+1,length(device.option[oc]));
     end
     else
     begin
      option := device.option[oc];
      param := '';
     end;


      if option = '.IOL' then
      begin
         highDMA := false;
         exit;
      end;

   end;
 end;
end;


Function useBLASTER(device : milesdrvinfo) : Boolean;
{Use BLASTER variable to configure?}
var option, param, s : string;

begin
 if device.numopt > 0 then
 begin

  for oc := 0 to device.numopt-1 do
  begin

     if pos(' ',device.option[oc]) > 0 then
     begin
      option := copy(device.option[oc],1,pos(' ',device.option[oc])-1);
      param := copy(device.option[oc],pos(' ',device.option[oc])+1,length(device.option[oc]));
     end
     else
     begin
      option := device.option[oc];
      param := '';
     end;


      if option = '.IOB' then
      begin
         useBlaster := true;
         exit;
      end;

   end;
 end;
 useBlaster := false;
end;

Procedure FindDigitalAudoDrivers;
{find all digital audio driver files and reads the options for them from
 AILDRVR.LST. All information are stored in "digs"}

 var fileinfo : SearchRec;
     search   : string;
     name     : string;
     z        : byte;
     dignum   : byte;
begin

  if not fileexist(listfile) then
   begin
    nummid := 0;
    exit;
   end;

   dignum := 0;
   fillchar(digs,sizeof(digs),0);
   FindFirst('*.DIG', Archive, FileInfo); { Same as DIR *.DIG }

   while (DosError = 0) and (dignum <= maxdrv) do
   begin
    search := '['+LowerCase(FileInfo.Name)+']';
    Lookupinfo(search);
    name := GetRealName(FileInfo.Name);
    if (info.drvfile <> '') and (name <> '') then
    begin
     digs[dignum] := info;
     digs[dignum].name := name;
     inc(dignum);
    end;
    FindNext(FileInfo);
  end;
  if dignum > 0 then numdig := dignum - 1;
end;

Procedure FindMidiAudoDrivers;
{same for the midi drivers...}

 var fileinfo : SearchRec;
     search   : string;
     name     : string;
     z        : byte;
     midnum   : byte;
begin

   if not fileexist(listfile) then
   begin
    nummid := 0;
    exit;
   end;

   midnum := 0;

   FindFirst('*.MDI', Archive, FileInfo); { Same as DIR *.MDI }
   fillchar(mids,sizeof(mids),0);

   while (DosError = 0) and (midnum <= maxdrv) do
   begin
    search := '['+LowerCase(FileInfo.Name)+']';
    Lookupinfo(search);

      name := GetRealName(FileInfo.Name);

      if (info.drvfile <> '') and (name <> '') then
      begin
        mids[midnum] := info;
        mids[midnum].name := name;
        inc(midnum);
      end;

      FindNext(FileInfo);
   end;

  if midnum > 0 then nummid := midnum - 1;
end;




Function DetectHardware(device : milesdrvinfo) : Boolean;
var option, param, s : string;

begin
 if device.numopt > 0 then
 begin

  for oc := 0 to device.numopt-1 do
  begin

     if pos(' ',device.option[oc]) > 0 then
     begin
      option := copy(device.option[oc],1,pos(' ',device.option[oc])-1);
      param := copy(device.option[oc],pos(' ',device.option[oc])+1,length(device.option[oc]));
     end
     else
     begin
      option := device.option[oc];
      param := '';
     end;


      if option = '.E' then
      begin
       if getenv(param) = '' then
       begin
         DetectHardware := FALSE;
         exit;
       end;
      end;

      if option = '.T1' then
      begin
       s := uppercase(getenv('BLASTER'));

       if (pos(s,'T') > 0) then
       begin
         s := copy(s,pos(s,'T'),2);

         if (s <> 'T1') or (s <> 'T3') then
         begin
           DetectHardware := FALSE;
           exit;
         end;
       end;

      end;

      if option = '.T2' then
      begin
       s := uppercase(getenv('BLASTER'));
       if (pos(s,'T') > 0) then
       begin
         s := copy(s,pos(s,'T'),2);

         if (s <> 'T2') or (s <> 'T4') or (s <> 'T5') then
         begin
           DetectHardware := FALSE;
           exit;
         end;
       end;

      end;

      if option = '.T3' then
      begin
       s := uppercase(getenv('BLASTER'));

       if (pos(s,'T') > 0) then
       begin
         s := copy(s,pos(s,'T'),2);

         if (s <> 'T6') or (s <> 'T7') then
         begin
           DetectHardware := FALSE;
           exit;
         end;
       end;

      end;


      if option = '.NE' then
      begin
       if getenv(param) <> '' then
       begin
         DetectHardware := FALSE;
         exit;
       end;
      end;

      if option = '.A' then
      begin
       if FindA(param) = false then
       begin
         DetectHardware := FALSE;
         exit;
       end;
      end;

      if option = '.NA' then
      begin
       if FindA(param) = true then
       begin
         DetectHardware := FALSE;
         exit;
       end;
      end;


      if option = '.C' then
      begin
       if FindC(param) = false then
       begin
         DetectHardware := FALSE;
         exit;
       end;
      end;

      if option = '.NC' then
      begin
       if FindC(param) = true then
       begin
         DetectHardware := FALSE;
         exit;
       end;
      end;


     end;
   end;
  end;







end.






