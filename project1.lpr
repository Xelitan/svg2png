program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, Classes, Graphics, SysUtils, BGRABitmap, BGRASVG, BGRAClasses, BGRABitmapTypes, ZStream;

const PROG = 'svg2png';
      VERSION = '1.1';

type THead = packed record
       Magic: Word;
       Method: Byte;
       Flag: Byte;
       DateTime: Cardinal;
       XFlag: Byte;
       Host: Byte;
     end;

function UnGzip(InStr, OutStr: TStream): Boolean;
var Head: THead;
    ExtraLen: Word;
    Crc16: Word;
    Zero: Byte;
    Deflate: TDecompressionStream;
    i: Integer;
    Buff: array of Byte;
    Len: Integer;
begin
  Result := False;
  InStr.Read(Head, SizeOf(THead));

  if (Head.Magic <> $8b1f) or (Head.Method <> 8) then Exit;

  if (Head.Flag and 4) = 4 then begin
    InStr.Read(ExtraLen, 2);
    InStr.Position := InStr.Position + ExtraLen;
  end;
  if (Head.Flag and 8) = 8 then begin
    for i:=InStr.Position to InStr.Size do begin
      InStr.Read(Zero, 1);
      if Zero = 0 then break;
    end;
  end;
  if (Head.Flag and 16) = 16 then begin
    for i:=InStr.Position to InStr.Size do begin
      InStr.Read(Zero, 1);
      if Zero = 0 then break;
    end;
  end;
  if (Head.Flag and 2) = 2 then begin
    InStr.Read(Crc16, 2);
  end;

  Deflate := TDecompressionStream.Create(InStr, True);
  SetLength(Buff, 4096);

  try
    while True do begin
      Len := Deflate.Read(Buff[0], 4096);
      OutStr.Write(Buff[0], Len);
      if Len < 4096 then break;
    end;
  finally
    Deflate.Free;
    Result := True;
  end;
end;

function Convert(InName, OutName: String; UserDpi: Integer): Integer;
var Pic: TPicture;
    Img: TGraphic;
    Ext: String;
    Bmp: TBitmap;
    H: TBGRASVG;
    Dpi: TPointF;
    Bmp2: TBGRABitmap;
    Scale: Single;
    InMem, OutMem: TStream;
begin
  Result := 0;

  Ext := LowerCase(ExtractFileExt(InName));

  if (Ext = '.gz') or (Ext = '.svgz') then begin
    InMem := TFileStream.Create(InName, fmOpenRead or fmShareDenyWrite);
    OutMem := TMemoryStream.Create;
    Ungzip(InMem, OutMem);
    InMem.Free;
    OutMem.Position := 0;
  end
  else begin
    OutMem := TFileStream.Create(InName, fmOpenRead or fmShareDenyWrite);
  end;

  if UserDpi < 10 then UserDpi := 10
  else if UserDpi > 900 then UserDpi := 900;

  Dpi := PointF(UserDpi, UserDpi);
  Scale := UserDpi/96;

  try
    H := TBGRASVG.Create;
    H.LoadFromStream(OutMem);

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
    OutMem.Free;
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
    Writeln('  Supported input: svg,svgz,svg.gz');
    Writeln('  Dpi is optional. Supported values: 10-900, default: 96.');
    ExitCode := 0;
    Exit;
  end;

  if ParamCount = 3 then UserDpi := StrToInt64Def(ParamStr(3), 96)
  else UserDpi := 96;

  ExitCode := Convert(ParamStr(1), ParamStr(2), UserDpi);
end.



