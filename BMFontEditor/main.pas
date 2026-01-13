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
  srcPtr: PByteArray;
  bufferSize: integer;
begin
  initBuffer;
  cls($FF6495ED);

  bmp := Image1.Picture.Bitmap;
  bmp.PixelFormat := pf32bit;  { RGBA }
  bmp.SetSize(vgaWidth, vgaHeight);

  bmp.BeginUpdate;  { Important: allocate TBitmap buffer }

  srcPtr := getSurfacePtr;
  destPtr := PByte(bmp.RawImage.Data);
  bufferSize := vgaWidth * vgaHeight * 4;

  { bmp.canvas.Brush.Color := $ED9564; }  { BGR format of cornflower blue }
  { bmp.canvas.brush.Color := RGBToColor($64, $95, $ED);
  bmp.canvas.FillRect(0, 0, 320, 200); }

  move(srcPtr^, destPtr^, bufferSize);

  bmp.EndUpdate;
  image1.Invalidate
end;

end.

