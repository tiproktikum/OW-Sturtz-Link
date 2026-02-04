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
    FPositionSeq: Integer;
    function PadLeftNum(const Value: Int64; const Width: Integer): string;
    function PadRightText(const Value: string; const Width: Integer): string;
    function ToTenthMm(const ValueMm: Double; const Width: Integer): string;
    function ToTenthDeg(const ValueDeg: Double; const Width: Integer): string;
    function BuildPositionCode(const Detail: TOptimizedDetail; const PositionSeq: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddVerHeader(const VersionStr: string);
    procedure AddKs(const Item: TOptimizedItem; const SeqNo: Integer);
    procedure AddKt(const Detail: TOptimizedDetail; const Item: TOptimizedItem;
      const SeqNo: Integer; const GroupName: string);
    procedure AddKr(const Item: TOptimizedItem);
    procedure SaveToFile(const FileName: string);
  end;

  TSturtzSoeBuilder = class
  private
    FLines: TStringList;
    function PadLeftNum(const Value: Int64; const Width: Integer): string;
    function PadRightText(const Value: string; const Width: Integer): string;
    function BlockLenForCount(const Count: Integer): Integer;
    function BuildBlocksLine(const Blocks: array of string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddEdnt(const SeqNo: Integer; const Blocks: array of string);
    procedure AddEdnr(const SeqNo: Integer; const Blocks: array of string);
    procedure SaveToFile(const FileName: string);
  end;

implementation

function ElementCodeFromShortTag(const ShortTag: string): Integer;
var
  Tag: string;
begin
  Tag := Trim(ShortTag);
  if SameText(Tag, 'Иг') or SameText(Tag, 'Ив') then
    Exit(300);
  if SameText(Tag, 'Ш') then
    Exit(400);
  if SameText(Tag, 'C') or SameText(Tag, 'С') then
    Exit(1);
  Result := 100;
end;

function PositionCodeFromShortName(const ShortName: string): string;
var
  FirstChar: string;
begin
  FirstChar := Trim(ShortName);
  if FirstChar <> '' then
    FirstChar := Copy(FirstChar, 1, 1);
  if SameText(FirstChar, 'Л') then
    Exit('L');
  if SameText(FirstChar, 'П') then
    Exit('R');
  if SameText(FirstChar, 'В') then
    Exit('O');
  Result := 'U';
end;

function PositionPrefixFromShortTag(const ShortTag: string): string;
var
  Tag: string;
begin
  Tag := Trim(ShortTag);
  if SameText(Tag, 'Иг') or SameText(Tag, 'Ив') then
    Exit('I');
  if SameText(Tag, 'C') or SameText(Tag, 'С') then
    Exit('C');
  Result := 'P';
end;

constructor TSturtzSobBuilder.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
  FLines.LineBreak := sLineBreak;
  FPositionSeq := 0;
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

function TSturtzSobBuilder.BuildPositionCode(const Detail: TOptimizedDetail;
  const PositionSeq: Integer): string;
var
  Prefix: string;
  Xxx: string;
begin
  Prefix := PositionPrefixFromShortTag(Detail.PartShortTag);
  if SameText(Prefix, 'I') then
    Xxx := 'I11'
  else if SameText(Prefix, 'C') then
    Xxx := 'C21'
  else
    Xxx := 'P01';
  Result := Xxx + '010' + PadLeftNum(PositionSeq, 3);
end;

procedure TSturtzSobBuilder.AddKs(const Item: TOptimizedItem; const SeqNo: Integer);
begin
  // VER02.07: B на поз.32, O (англ. буква) на поз.53, тело O с поз.54 (см. temp/Позиции_кодов_SOB_наша_версия.md)
  FLines.Add(
    'KS' +
    'N' + PadLeftNum(SeqNo, 3) +
    'L' + ToTenthMm(Item.Length, 5) +
    'T' + PadRightText(CyrillicToLatin(Item.Articul), 14) + 'ohne' +
    'B' + PadRightText('weiss', 20) +
    'O' + PadLeftNum(0, 6)
  );
end;

procedure TSturtzSobBuilder.AddKt(const Detail: TOptimizedDetail; const Item: TOptimizedItem;
  const SeqNo: Integer; const GroupName: string);
var
  OrderCode: string;
  ElementCode: Integer;
  ElementCodeStr: string;
  PositionCode: string;
begin
  // VER02.07: T 18 символов, B на поз.60, L на 81, Z на 128 (см. temp/Позиции_кодов_SOB_наша_версия.md)
  ElementCode := ElementCodeFromShortTag(Detail.PartShortTag);
  ElementCodeStr := PadLeftNum(ElementCode, 3);
  OrderCode := PadRightText(Copy(ElementCodeStr, 1, 1) + CyrillicToLatin(GroupName), 8);
  Inc(FPositionSeq);
  PositionCode := BuildPositionCode(Detail, FPositionSeq);
  FLines.Add(
    'KT' +
    'N' + PadLeftNum(SeqNo, 4) +
    'C' + PadLeftNum(1, 3) +
    'F' + PadLeftNum(0, 3) +
    'K' + OrderCode +
    'P' + PadRightText(PositionCode, 9) +
    'E' + ElementCodeStr +
    'U' + PadRightText(CyrillicToLatin(PositionCodeFromShortName(Detail.PositionTag)), 1) +
    'T' + PadRightText(CyrillicToLatin(Item.Articul), 14) + 'ohne' +
    'B' + PadRightText('weiss', 20) +
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

constructor TSturtzSoeBuilder.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
  FLines.LineBreak := sLineBreak;
end;

destructor TSturtzSoeBuilder.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TSturtzSoeBuilder.PadLeftNum(const Value: Int64; const Width: Integer): string;
begin
  Result := Format('%.*d', [Width, Value]);
end;

function TSturtzSoeBuilder.PadRightText(const Value: string; const Width: Integer): string;
var
  S: string;
begin
  S := Value;
  if Length(S) > Width then
    S := Copy(S, 1, Width);
  Result := S + StringOfChar(' ', Width - Length(S));
end;

function TSturtzSoeBuilder.BlockLenForCount(const Count: Integer): Integer;
begin
  case Count of
    1: Result := 84;
    2: Result := 41;
    3: Result := 27;
    4: Result := 20;
  else
    Result := 84;
  end;
end;

function TSturtzSoeBuilder.BuildBlocksLine(const Blocks: array of string): string;
var
  I: Integer;
  BlockLen: Integer;
  Part: string;
begin
  Result := '';
  if Length(Blocks) = 0 then
    Exit;
  BlockLen := BlockLenForCount(Length(Blocks));
  for I := 0 to High(Blocks) do
  begin
    Part := PadRightText(CyrillicToLatin(Blocks[I]), BlockLen);
    if I > 0 then
      Result := Result + '#';
    Result := Result + Part;
  end;
end;

procedure TSturtzSoeBuilder.AddEdnt(const SeqNo: Integer; const Blocks: array of string);
begin
  FLines.Add('EDNT' + PadLeftNum(SeqNo, 4) + 'T' + BuildBlocksLine(Blocks));
end;

procedure TSturtzSoeBuilder.AddEdnr(const SeqNo: Integer; const Blocks: array of string);
begin
  FLines.Add('EDNR' + PadLeftNum(SeqNo, 3) + 'T' + BuildBlocksLine(Blocks));
end;

procedure TSturtzSoeBuilder.SaveToFile(const FileName: string);
begin
  FLines.SaveToFile(FileName, TEncoding.GetEncoding(1251));
end;

end.
