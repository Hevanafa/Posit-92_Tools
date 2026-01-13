unit Main;

{$Mode ObjFPC}
{$H-}

interface

uses
  Classes, SysUtils, Forms, Controls,
  Graphics, Dialogs, StdCtrls, ExtCtrls,
  { Shared Posit-92 units }
  BMFont, Conv, Imgref, ImgRefFast, Logger, UStrings, VGA;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnRender: TButton;
    imgCanvas: TImage;
    memoInput: TMemo;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

var
  defaultFont: TBMFont;
  defaultFontGlyphs: array[32..126] of TBMFontGlyph;

function loadImage(const filename: string): longint;
var
  png: TPortableNetworkGraphic;
  imgHandle: longint;
  src, dest: PByte;
  px, py: word;
begin
  png := TPortableNetworkGraphic.create;

  try
    png.LoadFromFile(filename);

    imgHandle := newImage(png.Width, png.Height);

    src := PByte(png.RawImage.data);
    dest := getImagePtr(imgHandle)^.dataPtr;

    for py := 0 to png.Height - 1 do
    for px := 0 to png.Width - 1 do begin
      dest[0] := src[2];
      dest[1] := src[1];
      dest[2] := src[0];
      dest[3] := src[3];
      inc(src, 4);
      inc(dest, 4);
    end;

    Result := imgHandle
  finally
    png.free
  end;
end;

{ 32 to 126: 0 to 94 }
procedure loadBMFont(const filename: string; var font: TBMFont; var fontGlyphs: array of TBMFontGlyph);
var
  f: text;
  txtLine: string;
  a: word;
  pairs: array[0..9] of string;
  pair: array[0..1] of string;
  k, v: string;
  tempGlyph: TBMFontGlyph;
  glyphCount: word;
begin
  assign(f, filename);
  {$I-} reset(f); {$I+}

  if IOResult <> 0 then begin
    writeLog('Failed to open BMFont file: ' + filename);
    exit
  end;

  glyphCount := 0;
  while not eof(f) do begin
    readln(f, txtLine);

    if startsWith(txtLine, 'info') then begin
      split(txtLine, ' ', pairs);

      for a:=0 to high(pairs) do begin
        split(pairs[a], '=', pair);
        k := pair[0]; v := pair[1];
        if k = 'face' then
          font.face := replaceAll(v, '"', '');
      end;

      { writeLog('font.face:' + font.face) }

    end else if startsWith(txtLine, 'common') then begin
      split(txtLine, ' ', pairs);

      for a:=0 to high(pairs) do begin
        split(pairs[a], '=', pair);
        k := pair[0]; v := pair[1];
        if k = 'lineHeight' then
          font.lineHeight := parseInt(v);
      end;

    end else if startsWith(txtLine, 'page') then begin
      split(txtLine, ' ', pairs);

      for a:=0 to high(pairs) do begin
        split(pairs[a], '=', pair);
        k := pair[0]; v := pair[1];
        if k = 'file' then
          font.filename := replaceAll(v, '"', '');
      end;

    end else if startsWith(txtLine, 'char') and not startsWith(txtLine, 'chars') then begin
      while contains(txtLine, '  ') do
        txtLine := replaceAll(txtLine, '  ', ' ');

      { Parse the whole nine first, then copy the record to the list of font glyphs }
      split(txtLine, ' ', pairs);

      for a:=0 to high(pairs) do begin
        split(pairs[a], '=', pair);
        k := pair[0]; v := pair[1];

        { case-of can't be used with strings in Mode TP }
        if k = 'id' then
          tempGlyph.id := parseInt(v)
        else if k = 'x' then
          tempGlyph.x := parseInt(v)
        else if k = 'y' then
          tempGlyph.y := parseInt(v)
        else if k = 'width' then
          tempGlyph.width := parseInt(v)
        else if k = 'height' then
          tempGlyph.height := parseInt(v)
        else if k = 'xoffset' then
          tempGlyph.xoffset := parseInt(v)
        else if k = 'yoffset' then
          tempGlyph.yoffset := parseInt(v)
        else if k = 'xadvance' then
          tempGlyph.xadvance := parseInt(v);
      end;

      { array of glyphs starts from 0, ends at 94 }
      { Assuming glyph.id always starts from 32 }
      if (tempGlyph.id - 32) in [low(fontGlyphs)..high(fontGlyphs)] then begin
        fontGlyphs[tempGlyph.id - 32] := tempGlyph;
        inc(glyphCount)
      end;
    end;
  end;

  close(f);

  writeLog('Loaded ' + i32str(glyphCount) + ' glyphs');

  font.imgHandle := loadImage(font.filename);

  writeLog('font.imgHandle');
  writeLogI32(font.imgHandle);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  bmp: TBitmap;
  destPtr: PByte;
  srcPtr: PByte;
  bufferSize: integer;
  a: LongWord;
begin
  { init }
  bmp := imgCanvas.Picture.Bitmap;
  bmp.PixelFormat := pf32bit;  { 32-bit BGRA }
  bmp.SetSize(vgaWidth, vgaHeight);

  initBuffer;
  loadBMFont('assets/fonts/nokia_cellphone_fc_8.txt', defaultFont, defaultFontGlyphs);

  { Begin drawing }
  cls($FF6495ED);
  spr(defaultFont.imgHandle, 10, 10);

  { Flush }
  bmp.BeginUpdate;  { Important: allocate TBitmap buffer }

  srcPtr := PByte(getSurfacePtr);
  destPtr := PByte(bmp.RawImage.Data);
  bufferSize := vgaWidth * vgaHeight * 4;

  a:=0;
  while a < bufferSize do begin
    destPtr[0] := srcPtr[2];
    destPtr[1] := srcPtr[1];
    destPtr[2] := srcPtr[0];
    destPtr[3] := srcPtr[3];

    inc(srcPtr, 4);
    inc(destPtr, 4);
    inc(a, 4)
  end;

  bmp.EndUpdate;
  imgCanvas.Invalidate
  { End flush }
end;

end.

