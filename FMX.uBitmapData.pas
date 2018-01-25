unit FMX.uBitmapData;

interface

uses
  SysUtils, System.UITypes, Classes, FMX.Types, FMX.Graphics, FMX.Surfaces;

type
  TRyuBitmapData = class
  private
    FData : pointer;
  private
    FWidth: integer;
    FHeight: integer;
    FChanged: boolean;
    FPixelFormat: TPixelFormat;
    FSize: integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AssignFromBitmap(ABitmap:TBitmap);
    function GetToBitmap(ABitmap:TBitmap):boolean;
    //
    function Assign(ABitmap:TBitmap):boolean;
    function GetTo(ABitmap:TBitmap):boolean;
    //
    procedure Clear;
    procedure SaveToStream(AStream:TStream);
    function SaveToFile(const AFileName:string):boolean;
    function LoadFromStream(AStream:TStream):boolean;
    procedure AssignParams(ARBMData:TRyuBitmapData);
    function GetColor(aX,aY:integer):TAlphaColor;
  public
    property Changed : boolean read FChanged;
    property Width : integer read FWidth;
    property Height : integer read FHeight;
    property PixelFormat : TPixelFormat read FPixelFormat;
    property Size : integer read FSize;
  end;

implementation

  uses FMX.Utils;

{ TBitmapData }

function TRyuBitmapData.Assign(ABitmap: TBitmap):boolean;
var aSurf:TBitmapSurface;
    LBM:TBitmap;
    aMemStream:TMemoryStream;
    i:integer;
begin
 aMemStream := TMemoryStream.Create();
 aSurf := TBitmapSurface.Create();
  try
    aSurf.Assign(ABitmap);
    TBitmapCodecManager.SaveToStream(aMemStream, aSurf, '.bmp');
    LBM:=FMX.Graphics.TBitmap.CreateFromStream(aMemStream);
    try
     /// LBM.SaveToFile('FFF.bmp');
      aMemStream.Clear;
      AssignFromBitmap(LBM);
    finally
      FreeAndNil(LBM);
    end;
  finally
    FreeAndNil(aMemStream);
    aSurf.Free;
  end;
end;

procedure TRyuBitmapData.AssignFromBitmap(ABitmap: TBitmap);
var
  i,iBitmapSize, iPixelSize : integer;
  bitData: TBitmapData;
  p: Pointer;//PAlphaColorArray;
begin
  if ABitmap = nil then begin
    FChanged := false;
    FWidth  := 0;
    FHeight := 0;
    FPixelFormat :=TPixelFormat.RGBA;
    FSize := 0;
    if FData <> nil then FreeMem(FData);
    FData := nil;
    Exit;
  end;
  FPixelFormat := ABitmap.PixelFormat;
 // Assert(FPixelFormat=TPixelFormat.RGBA,'FMX> TRyuBitmapData.Assign Bitmap format not RGBA!');
  if ABitmap.Map(TMapAccess.ReadWrite,bitData) then
  try
     iPixelSize := 4;
    // i:=bitData.BytesPerPixel;
    // i:=bitData.BytesPerLine;
     FWidth :=bitData.Width;
     FHeight :=bitData.Height;
     iBitmapSize := iPixelSize * FWidth * FHeight;
     if (FData = nil) or (iBitmapSize <> FSize) then begin
        if FData <> nil then FreeMem(FData);
        GetMem(FData, iBitmapSize);
     end;
     FSize := iBitmapSize;
     for I := 0 to bitData.Height - 1 do
       begin
        p:=Pointer(NativeInt(FData) + I*bitData.BytesPerLine);
        Move(bitData.GetScanline(I)^, p^,bitData.BytesPerLine);
       end;
     //  Move(p^,FData^,FSize);
   finally
    ABitmap.Unmap(bitData);
  end;
  FChanged := true;
end;

procedure TRyuBitmapData.AssignParams(ARBMData: TRyuBitmapData);
begin
 FWidth:=ARBMData.Width;
 FHeight:=ARBMData.Height;
 FPixelFormat:=ARBMData.PixelFormat;
 FChanged := true;
end;

procedure TRyuBitmapData.Clear;
begin
 if FData <> nil then FreeMem(FData);
 FData := nil;
  FChanged :=true;
  FWidth  := 0;
  FHeight := 0;
  FPixelFormat :=TPixelFormat.RGBA;
  FSize := 0;
end;

constructor TRyuBitmapData.Create;
begin
  inherited;
  FData := nil;
  FChanged := false;
  FWidth  := 0;
  FHeight := 0;
  FPixelFormat :=TPixelFormat.RGBA;
  FSize := 0;
end;

destructor TRyuBitmapData.Destroy;
begin
  if FData <> nil then FreeMem(FData);
  FData := nil;
  inherited;
end;

function TRyuBitmapData.GetTo(ABitmap: TBitmap): boolean;
begin

end;

function TRyuBitmapData.GetToBitmap(ABitmap: TBitmap): boolean;
var bitData: TBitmapData;
  {  LSr:TBitmapSurface;
    LMStr:TMemoryStream;
    }
    i:integer;
    p:pointer;
begin
  Result := FChanged;
  FChanged := false;
  if not Result then Exit;
  if (FData = nil) or (FSize <= 0) then Exit;
{ if ABitmap.PixelFormat <> FPixelFormat then
     ABitmap.PixelFormat:= FPixelFormat;
  LSr:=TBitmapSurface.Create;
  LMStr:=TMemoryStream.Create;
  LMStr.Write(FData^,FSize);
  LMStr.Position:=0;
  LMStr.SaveToFile('ttt123.bmp');
  LMStr.Position:=0;
 // i:=LMStr.Size;
  LSr.SetSize(FWidth,FHeight);
  TBitmapCodecManager.LoadFromStream(LMStr,LSr);
  if ABitmap.Width  <> FWidth  then ABitmap.Width := FWidth;
  if ABitmap.Height <> FHeight then ABitmap.Height := FHeight;
  ABitmap.Assign(LSr);
  LSr.Free;
  LMStr.Free;
  }
 //  Assert(ABitmap.PixelFormat=TPixelFormat.RGBA,'FMX> TRyuBitmapData.GetBitmap - Bitmap format not RGBA!');
  if ABitmap.Map(TMapAccess.ReadWrite,bitData) then
  try
   // bitData.Copy(Ldata);
   { i:=bitData.BytesPerPixel;
    i:=bitData.BytesPerLine*bitData.Height;
    }
    for I := 0 to FHeight - 1 do
       begin
        p:=Pointer(NativeInt(FData) + I*bitData.BytesPerLine);
        Move(p^,bitData.GetScanline(I)^,bitData.BytesPerLine);
       end;
    Result:=true;
   // Move(FData^,bitData.Data^,FSize);
   finally
    ABitmap.Unmap(bitData);
  end;
end;

function TRyuBitmapData.GetColor(aX,aY:integer):TAlphaColor;
var i:integer;
    LPB:PAlphaColorArray;
   // LRec:TAlphaColorRec;
begin
 Result:=TAlphaColorRec.Alpha;
 if (FData <> nil) and (aX>0) and (aY>0) and (aX<=FWidth) and (aY<=FHeight) then
  begin
    LPB:=PAlphaColorArray(FData);
    if FPixelFormat=TPixelFormat.BGRA then
       begin
         i:=(aX-1)+(aY-1)*FWidth;
         LPB:=PAlphaColorArray(FData);
         Result:=LPB^[i];
       end;
  end;
end;

function TRyuBitmapData.LoadFromStream(AStream: TStream): boolean;
begin
  Result:=false;
  if FData <> nil then FreeMem(FData);
  FSize:=0;
  if (AStream is TMemoryStream) and (AStream.Size>0) then
    begin
     GetMem(FData,AStream.Size);
     FSize:=AStream.Size;
     Move(TMemoryStream(AStream).Memory^,FData^,AStream.Size);
     Result:=true;
    end;
end;

function TRyuBitmapData.SaveToFile(const AFileName: string):boolean;
var LOutBm:TBitmap;
begin
 Result:=false;
 LOutBm:=TBitmap.Create(FWidth,FHeight); //FromFile('D:\Execute\Work_temp\rgbProj\test_images\test_red\testR1.png');// (FWidth,FHeight);
// LOutBm.PixelFormat
 try
  if GetToBitmap(LOutBm) then
   begin
     LOutBm.SaveToFile(AFileName);
     Result:=true;
   end;
  // except
   //  Result:=false;
  // end;
 finally
  LOutBm.Free;
 end;
end;

procedure TRyuBitmapData.SaveToStream(AStream: TStream);
begin
 AStream.WriteBuffer(FData^,FSize);
end;

end.
