unit Main;

{$Mode ObjFPC}
{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls,
  { Shared Posit-92 units }
  VGA;

type

  { TForm1 }

  TForm1 = class(TForm)
    Image1: TImage;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  bmp: TBitmap;
  destPtr: PByte;
  srcPtr: PByte;
  bufferSize: integer;
  a: LongWord;
begin
  initBuffer;
  cls($FF6495ED);

  bmp := Image1.Picture.Bitmap;
  bmp.PixelFormat := pf32bit;  { 32-bit BGRA }
  bmp.SetSize(vgaWidth, vgaHeight);

  bmp.BeginUpdate;  { Important: allocate TBitmap buffer }

  srcPtr := PByte(getSurfacePtr);
  destPtr := PByte(bmp.RawImage.Data);
  bufferSize := vgaWidth * vgaHeight * 4;

  { move(srcPtr^, destPtr^, bufferSize); }
  a:=0;
  while a < bufferSize - 1 do begin
    destPtr[0] := srcPtr[2];
    destPtr[1] := srcPtr[1];
    destPtr[2] := srcPtr[0];
    destPtr[3] := srcPtr[3];

    inc(srcPtr, 4);
    inc(destPtr, 4);
    inc(a, 4)
  end;

  bmp.EndUpdate;
  image1.Invalidate
end;

end.

