unit uSturtzSob;

interface

uses
  System.SysUtils,
  System.Classes,
  uTypes,
  uTranslit;

type
  TSturtzSobBuilder = class
  private
    FLines: TStringList;
    function PadLeftNum(const Value: Int64; const Width: Integer): string;
    function PadRightText(const Value: string; const Width: Integer): string;
    function ToTenthMm(const ValueMm: Double; const Width: Integer): string;
    function ToTenthDeg(const ValueDeg: Double; const Width: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddVerHeader(const VersionStr: string);
    procedure AddKs(const Item: TOptimizedItem; const SeqNo: Integer);
    procedure AddKt(const Detail: TOptimizedDetail; const Item: TOptimizedItem; const SeqNo: Integer);
    procedure AddKr(const Item: TOptimizedItem);
    procedure SaveToFile(const FileName: string);
  end;

implementation

constructor TSturtzSobBuilder.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
  FLines.LineBreak := sLineBreak;
end;

destructor TSturtzSobBuilder.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TSturtzSobBuilder.AddVerHeader(const VersionStr: string);
begin
  FLines.Add('VER' + VersionStr + '-00');
end;

function TSturtzSobBuilder.PadLeftNum(const Value: Int64; const Width: Integer): string;
begin
  Result := Format('%.*d', [Width, Value]);
end;

function TSturtzSobBuilder.PadRightText(const Value: string; const Width: Integer): string;
var
  S: string;
begin
  S := Value;
  if Length(S) > Width then
    S := Copy(S, 1, Width);
  Result := S + StringOfChar(' ', Width - Length(S));
end;

function TSturtzSobBuilder.ToTenthMm(const ValueMm: Double; const Width: Integer): string;
var
  V: Int64;
begin
  V := Round(ValueMm * 10);
  Result := PadLeftNum(V, Width);
end;

function TSturtzSobBuilder.ToTenthDeg(const ValueDeg: Double; const Width: Integer): string;
var
  V: Int64;
begin
  V := Round(ValueDeg * 10);
  Result := PadLeftNum(V, Width);
end;

procedure TSturtzSobBuilder.AddKs(const Item: TOptimizedItem; const SeqNo: Integer);
begin
  // VER02.07: B на поз.32, O на поз.53, тело O поз.54–59 (см. temp/Позиции_кодов_SOB_наша_версия.md)
  FLines.Add(
    'KS' +
    'N' + PadLeftNum(SeqNo, 3) +
    'L' + ToTenthMm(Item.Length, 5) +
    'T' + PadRightText(CyrillicToLatin(Item.Articul), 18) +
    'B' + PadRightText(CyrillicToLatin(Item.Name), 20) +
    '0' + PadLeftNum(0, 6)
  );
end;

procedure TSturtzSobBuilder.AddKt(const Detail: TOptimizedDetail; const Item: TOptimizedItem; const SeqNo: Integer);
var
  OrderCode: string;
begin
  // VER02.07: T 19 символов, B на поз.60 (см. temp/Позиции_кодов_SOB_наша_версия.md)
  OrderCode := PadRightText(IntToStr(Detail.OrderId), 8);
  FLines.Add(
    'KT' +
    'N' + PadLeftNum(SeqNo, 4) +
    'C' + PadLeftNum(0, 3) +
    'F' + PadRightText('', 3) +
    'K' + OrderCode +
    'P' + PadRightText('', 9) +
    'E' + PadLeftNum(0, 3) +
    'U' + PadRightText('', 1) +
    'T' + PadRightText(CyrillicToLatin(Item.Articul), 19) +
    'B' + PadRightText(CyrillicToLatin(Item.Name), 20) +
    'L' + ToTenthMm(Detail.Length, 5) +
    'G' + ToTenthDeg(Detail.Ug1, 4) + ToTenthDeg(Detail.Ug2, 4) +
    'D' + PadLeftNum(1, 1) +
    'S' + PadLeftNum(0, 1) +
    'W' + PadLeftNum(0, 1) +
    'I' + PadRightText('', 25) +
    'Z' + PadRightText('', 30)
  );
end;

procedure TSturtzSobBuilder.AddKr(const Item: TOptimizedItem);
begin
  // KRLxxxxxAxDx
  FLines.Add(
    'KR' +
    'L' + ToTenthMm(Item.Ostat, 5) +
    'A' + PadLeftNum(1, 1) +
    'D' + PadLeftNum(0, 1)
  );
end;

procedure TSturtzSobBuilder.SaveToFile(const FileName: string);
begin
  FLines.SaveToFile(FileName, TEncoding.GetEncoding(1251));
end;

end.
