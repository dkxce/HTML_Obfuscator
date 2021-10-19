unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Menus;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    CheckBox1: TCheckBox;
    Panel2: TPanel;
    procedure RadioButton2Click(Sender: TObject);
    procedure RadioButton1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

var gtext: string;

{$R *.dfm}

procedure CvtInt;
{ IN:
    EAX:  The integer value to be converted to text
    ESI:  Ptr to the right-hand side of the output buffer:  LEA ESI, StrBuf[16]
    ECX:  Base for conversion: 0 for signed decimal, 10 or 16 for unsigned
    EDX:  Precision: zero padded minimum field width
  OUT:
    ESI:  Ptr to start of converted text (not start of buffer)
    ECX:  Length of converted text
}
asm
        OR      CL,CL
        JNZ     @CvtLoop
@C1:    OR      EAX,EAX
        JNS     @C2
        NEG     EAX
        CALL    @C2
        MOV     AL,'-'
        INC     ECX
        DEC     ESI
        MOV     [ESI],AL
        RET
@C2:    MOV     ECX,10

@CvtLoop:
        PUSH    EDX
        PUSH    ESI
@D1:    XOR     EDX,EDX
        DIV     ECX
        DEC     ESI
        ADD     DL,'0'
        CMP     DL,'0'+10
        JB      @D2
        ADD     DL,('A'-'0')-10
@D2:    MOV     [ESI],DL
        OR      EAX,EAX
        JNE     @D1
        POP     ECX
        POP     EDX
        SUB     ECX,ESI
        SUB     EDX,ECX
        JBE     @D5
        ADD     ECX,EDX
        MOV     AL,'0'
        SUB     ESI,EDX
        JMP     @z
@zloop: MOV     [ESI+EDX],AL
@z:     DEC     EDX
        JNZ     @zloop
        MOV     [ESI],AL
@D5:
end;

// 0123456789 ABCDEF GHIJ KLMNO PQRST UVWXY
function IntTo36(Value: Integer; Digits: Integer): string;
//  FmtStr(Result, '%.*x', [Digits, Value]);
asm
        CMP     EDX, 32        // Digits < buffer length?
        JBE     @A1
        XOR     EDX, EDX
@A1:    PUSH    ESI
        MOV     ESI, ESP
        SUB     ESP, 32
        PUSH    ECX            // result ptr
        MOV     ECX, 36        // base 36     EDX = Digits = field width
        CALL    SysUtils.CvtInt
        MOV     EDX, ESI
        POP     EAX            // result ptr
        CALL    System.@LStrFromPCharLen
        ADD     ESP, 32
        POP     ESI
end;

const adds: array [0..18] of string = ('+','-','&','*','!','@','#','$','%','^','(',')','~',',','.','<','>','/','?');
const enca: string = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"';

procedure TForm1.RadioButton2Click(Sender: TObject);
var s,t,u: AnsiString;
    i,k: integer;
begin
  if(RadioButton2.Checked) then gtext := Memo1.Lines.Text;

  t := '<script language="JavaScript" type="text/javascript">'#13#10 +
       '<!--'#13#10+
       '  // Copyright © 2008 Milok Zbrozek - milokz [woof woof] gmail [dot] com'#13#10+
       '  function normalize(obtext){'+
       'var ot = obtext; var ra = ["+","-","&","*","!","@","#","$","%","^","(",")","~",",",".","<",">","/","?"]; '+
       'for(var i=0;i<ra.length;i++) while(ot.indexOf(ra[i]) > -1) ot = ot.replace(ra[i],""); '+
       'var tcrb = "", enca = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"; for(var i_var = 0; i_var < '+
       'ot.length; i_var += 2) { var val = 0xFF - '+
       '(((enca.indexOf(ot.substr(i_var,1))*36+'+
       'enca.indexOf(ot.substr(i_var+1,1)))) >> 2); '+
       'var res = ""; while(val >= 0x10) { res = enca.charAt(val % '+
       '0x10) + res; val = parseInt(val / 0x10); }; if(val > 0) res = '+
       'enca.charAt(val)+res; while (res.length < 2) res = "0"+res; '+
       'tcrb+=unescape("%"+res); }return tcrb;}'#13#10;

  Randomize();
  for k := 0 to (length(gtext) div 4096) do begin
  
      u := '';
      s := Copy(gtext,1+k*4096,4096);
  
      for i := 1 to length(s) do begin
        u := u + IntTo36(((255 - ord(s[i])) shl 2),2);
        if Random(3) = 1 then u := u + adds[Random(length(adds))];
      end;
      t := t + ' document.write(normalize("'+u+'"));'#13#10;
  end;

  t := t + '-->'#13#10'</script>';

  Memo1.Lines.Text := t;
  Memo1.SetFocus();
  Memo1.SelectAll();
end;

procedure TForm1.RadioButton1Click(Sender: TObject);
begin
  if(RadioButton1.Checked) then Memo1.Lines.Text := gtext;
  Memo1.SetFocus();
  Memo1.SelectAll();
end;

function deobfuscate(text: string): string;
var tcrb,res: string;
    i,val: integer;
begin
  tcrb := '';
  i := 1;
  while i < length(text) do begin
    //L4J4J4L4
    val := 255 - (((Pos(Copy(text,i,1),enca)-1)*36+(Pos(Copy(text,i+1,1),enca)-1)) shr 2);
    res := res+char(val);
    i := i + 2;
  end;
  result := res;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
var ot: string;
     i: integer;
begin
  if not CheckBox1.Checked then exit;
  CheckBox1.Checked := False;
  ot := InputBox('Деобфускация','Введите текст','');
  if(length(ot) = 0) then exit;
  for i := 1 to length(adds) do ot := StringReplace(ot,adds[i-1],'',[rfReplaceAll]);
  RadioButton1.Checked := True;
  Memo1.Lines.Text := deobfuscate(ot);
end;

end.
