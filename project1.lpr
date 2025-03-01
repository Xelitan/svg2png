program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, Classes, Graphics, SysUtils, BGRABitmap, BGRASVG, BGRAClasses, BGRABitmapTypes;

const PROG = 'svg2png';
      VERSION = '1.0';

function Convert(InName, OutName: String; UserDpi: Integer): Integer;
var Pic: TPicture;
    Img: TGraphic;
    Ext: String;
    Bmp: TBitmap;
    H: TBGRASVG;
    Dpi: TPointF;
    Bmp2: TBGRABitmap;
    Scale: Single;
begin
  Result := 0;

  if UserDpi < 10 then UserDpi := 10
  else if UserDpi > 900 then UserDpi := 900;

  Dpi := PointF(UserDpi, UserDpi);
  Scale := UserDpi/96;

  try
    H := TBGRASVG.Create;
    H.LoadFromFile(InName);

    Bmp2 := TBgraBitmap.Create;
    Bmp2.SetSize(Round(H.WidthAsPixel*Scale), Round(H.HeightAsPixel*Scale));
    H.Draw(Bmp2.Canvas2D, 0,0, Dpi);
    H.Free;

    Bmp := TBitmap.Create;
    Bmp.PixelFormat := pf32bit;
    Bmp.SetSize(Bmp2.Width, Bmp2.Height);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(0,0, Bmp.Width, Bmp.Height);

    Bmp2.Draw(Bmp.Canvas, 0,0, False);
    Bmp2.Free;

  except
    Writeln('Conversion error');
    Exit(1);
  end;

  Ext := LowerCase(ExtractFileExt(OutName));

  if Ext = '.bmp' then Img := TBitmap.Create
  else if Ext = '.jpg' then Img := TJPEGImage.Create
  else if Ext = '.ppm' then Img := TPortableAnyMapGraphic.Create
  else if Ext = '.png' then Img := TPortableNetworkGraphic.Create;

  Img.Assign(Bmp);
  Bmp.Free;

  Img.SaveToFile(OutName);
  Img.Free;
end;

var UserDpi: Integer;
begin
  if (ParamCount <> 2) and (ParamCount <> 3) then begin
    Writeln('===================================================');
    Writeln('  ', PROG, ' - .SVG to .PNG image converter');
    Writeln('  github.com/Xelitan/', PROG);
    Writeln('  version: ', VERSION);
    Writeln('  license: GNU LGPL'); //like BGRA
    Writeln('===================================================');
    Writeln('  Usage: ', PROG, ' INPUT OUTPUT DPI');
    Writeln('  Output format is guessed from extension.');
    Writeln('  Supported: bmp,jpg,png,ppm');
    Writeln('  Dpi is optional. Supported values: 10-900, default: 96.');
    ExitCode := 0;
    Exit;
  end;

  if ParamCount = 3 then UserDpi := StrToInt64Def(ParamStr(3), 96)
  else UserDpi := 96;

  ExitCode := Convert(ParamStr(1), ParamStr(2), UserDpi);
end.



