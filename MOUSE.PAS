{$E-,G+,N+}
 Unit Mouse;
   Interface

   Type CursorMask = Record
                       Mask : array [1..32] of word;
                       HotX, HotY : word
                     End;

   Const ArrowMask : CursorMask =
           (Mask:(16383,8191,4095,2047,1023,511,255,127,63,31,511,4351,12543,63615,63615,64639,
                  0,16384,24576,28672,30720,31744,32256,32512,32640,31744,27648,17920,1536,768,768,0);
            HotX:0;HotY:0);
         WaitMask : CursorMask =
           (Mask:(0,0,0,0,49155,49155,57351,61455,61455,57351,49155,49155,0,0,0,0,
                  0,32766,28686,4104,5128,2768,1440,832,576,1056,2320,4808,5032,30558,32766,0);
            HotX:7;HotY:7);

   Var MouseInt         : byte;
       OldInt1, OldInt3 : pointer;
       MouseOK, Visible : Boolean;

   Function  MouseInstalled : Boolean;
   Procedure ResetMouse;
   Procedure ShowCursor;
   Procedure HideCursor;
   Function  LeftButton : Boolean;
   Function  RightButton : Boolean;
   Function  GetMouseX : integer;
   Function  GetMouseY : integer;
   Procedure SetMouseCursor (Mask:CursorMask);
   Procedure SetMouseSensitivity (X,Y:integer);
   Procedure SetMouseWindow (X1,Y1,X2,Y2:integer);

 Implementation

   Uses Dos;

   Var Regs : registers;

   Function  MouseInstalled : Boolean;
     Begin
       With Regs do
         Begin
           Visible:=False;
           AX:=$0000;
           Intr ($33,Regs);
           MouseInstalled:=not AX=0
         End
     End;

   Procedure ResetMouse;
     Begin
       If MouseOK then
         With Regs do
           Begin
             Visible:=False;
             AX:=$0000;
             Intr ($33,Regs)
           End
     End;

   Procedure ShowCursor;
     Begin
       If MouseOK and not Visible then
         With Regs do
           Begin
             Visible:=True;
             AX:=$0001;
             Intr ($33,Regs)
           End
     End;

   Procedure HideCursor;
     Begin
       If MouseOK and Visible then
         With Regs do
           Begin
             Visible:=False;
             AX:=$0002;
             Intr ($33,Regs)
           End
     End;

   Function  LeftButton : Boolean;
     Var T : Boolean;
       Begin
         T:=False;
         If MouseOK then
           With Regs do
             Begin
               AX:=$0003;
               Intr ($33,Regs);
               T:=BX in [1,3]
             End;
         LeftButton:=T
       End;

   Function  RightButton : Boolean;
     Var T : Boolean;
       Begin
         T:=False;
         If MouseOK then
           With Regs do
             Begin
               AX:=$0003;
               Intr ($33,Regs);
               T:=BX in [2,3]
             End;
         RightButton:=T
       End;

   Function  GetMouseX : integer;
     Var T : integer;
       Begin
         T:=-1;
         If MouseOK then
           With Regs do
             Begin
               AX:=$0003;
               Intr ($33,Regs);
               T:=CX
             End;
         GetMouseX:=T
       End;

   Function  GetMouseY : integer;
     Var T : integer;
       Begin
         T:=-1;
         If MouseOK then
           With Regs do
             Begin
               AX:=$0003;
               Intr ($33,Regs);
               T:=DX
             End;
         GetMouseY:=T
       End;

   Procedure SetMouseCursor (Mask:CursorMask);
     Begin
       If MouseOK then
         With Regs do
           Begin
             AX:=$0009;
             BX:=Mask.HotX;
             CX:=Mask.HotY;
             ES:=Seg (Mask.Mask);
             DX:=Ofs (Mask.Mask);
             Intr ($33,Regs)
           End
     End;

   Procedure SetMouseSensitivity (X,Y:integer);
     Begin
       If MouseOK then
         With Regs do
           Begin
             AX:=$001A;
             BX:=X;
             CX:=Y;
             DX:=0;
             Intr ($33,Regs)
           End
     End;

   Procedure SetMouseWindow (X1,Y1,X2,Y2:integer);
     Begin
       If MouseOK then
         With Regs do
           Begin
             AX:=$0007;
             CX:=X1;
             DX:=X2;
             Intr ($33,Regs);
             AX:=$0008;
             CX:=Y1;
             DX:=Y2;
             Intr ($33,Regs)
           End
     End;

 Begin
   MouseOK:=MouseInstalled
 End.

