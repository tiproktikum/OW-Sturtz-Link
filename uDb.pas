unit uDb;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Winapi.Windows,
  IBDatabase,
  IBSQL,
  uTypes,
  uConfig;

type
  TDbManager = class
  private
    FDb: TIBDatabase;
    FTrans: TIBTransaction;
    FSql: TIBSQL;
  public
    constructor Create;
    destructor Destroy; override;
    function Connect(const Config: TAppConfig): Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    function GetGroupOrders: TArray<TGroupOrder>;
    function GetOptimizedItems(const GrOrderId: Integer): TArray<TOptimizedItem>;
    function GetOptimizedDetails(const GrOrderId: Integer): TArray<TOptimizedDetail>;
  end;

implementation

function SearchDllOnPath(const DllName: string): string;
var
  Buf: array[0..MAX_PATH] of Char;
  Part: PChar;
  Found: DWORD;
begin
  Result := '';
  Part := nil;
  Found := SearchPath(nil, PChar(DllName), nil, MAX_PATH, Buf, Part);
  if Found <> 0 then
    Result := Buf;
end;

function GetLoadedFBClientPath: string;
var
  H: HMODULE;
  Buf: array[0..MAX_PATH] of Char;
begin
  Result := '';
  H := GetModuleHandle('fbclient.dll');
  if H = 0 then
    H := GetModuleHandle('gds32.dll');
  if H <> 0 then
    if GetModuleFileName(H, Buf, MAX_PATH) <> 0 then
      Result := Buf;
end;

function GetSearchDiagnostics: string;
var
  ExeDir: string;
  GdsInExe: string;
  FbInExe: string;
  GdsInPath: string;
  FbInPath: string;
begin
  ExeDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  GdsInExe := ExeDir + 'gds32.dll';
  FbInExe := ExeDir + 'fbclient.dll';
  if not FileExists(GdsInExe) then
    GdsInExe := '<не найдено>';
  if not FileExists(FbInExe) then
    FbInExe := '<не найдено>';
  GdsInPath := SearchDllOnPath('gds32.dll');
  if GdsInPath = '' then
    GdsInPath := '<не найдено>';
  FbInPath := SearchDllOnPath('fbclient.dll');
  if FbInPath = '' then
    FbInPath := '<не найдено>';

  Result :=
    'EXE\gds32.dll: ' + GdsInExe + sLineBreak +
    'EXE\fbclient.dll: ' + FbInExe + sLineBreak +
    'PATH\gds32.dll: ' + GdsInPath + sLineBreak +
    'PATH\fbclient.dll: ' + FbInPath;
end;

constructor TDbManager.Create;
begin
  inherited Create;
  FDb := TIBDatabase.Create(nil);
  FTrans := TIBTransaction.Create(nil);
  FSql := TIBSQL.Create(nil);

  FDb.LoginPrompt := False;
  FDb.DefaultTransaction := FTrans;
  FTrans.DefaultDatabase := FDb;
  FSql.Database := FDb;
  FSql.Transaction := FTrans;
end;

destructor TDbManager.Destroy;
begin
  if FTrans.InTransaction then
    FTrans.Rollback;
  FSql.Free;
  FTrans.Free;
  FDb.Free;
  inherited Destroy;
end;

function TDbManager.Connect(const Config: TAppConfig): Boolean;
begin
  if FDb.Connected then
    FDb.Connected := False;

  FDb.DatabaseName := Config.DbPath;
  FDb.Params.Clear;
  if Config.DbUser <> '' then
    FDb.Params.Add('user_name=' + Config.DbUser);
  if Config.DbPassword <> '' then
    FDb.Params.Add('password=' + Config.DbPassword);
  if Config.DbRole <> '' then
    FDb.Params.Add('sql_role_name=' + Config.DbRole);
  if Config.DbCharset <> '' then
    FDb.Params.Add('lc_ctype=' + Config.DbCharset);

  try
    FDb.Connected := True;
    Result := FDb.Connected;
  except
    on E: Exception do
      raise Exception.Create(
        'Ошибка подключения к Firebird: ' + E.Message + sLineBreak +
        'Загруженный клиент: ' + GetLoadedFBClientPath + sLineBreak +
        GetSearchDiagnostics
      );
  end;
end;

procedure TDbManager.Disconnect;
begin
  if FTrans.InTransaction then
    FTrans.Rollback;
  FDb.Connected := False;
end;

function TDbManager.IsConnected: Boolean;
begin
  Result := FDb.Connected;
end;

function TDbManager.GetGroupOrders: TArray<TGroupOrder>;
var
  Items: TArray<TGroupOrder>;
  Item: TGroupOrder;
  Count: Integer;
  Started: Boolean;
begin
  if not FDb.Connected then
    raise Exception.Create('Database is not connected.');

  Started := False;
  if not FTrans.InTransaction then
  begin
    FTrans.StartTransaction;
    Started := True;
  end;

  FSql.Close;
  FSql.SQL.Text :=
    'select o.GRORDERID, o.GRO_NAME, t.FOLDERNAME, ' +
    '(select count(*) from OPTIMIZED o2 ' +
    'join OPTARTCOLORED oac on oac.COLOREDID = o2.COLOREDID ' +
    'join OPTART oa on oa.OA_ID = oac.OA_ID ' +
    'join VIRTARTTYPES vt on vt.VIRTARTTYPEID = o2.VIRTARTTYPEID ' +
    'where o2.GRORDID = o.GRORDERID ' +
    '  and vt.DESCRIPTION in (''Профили'', ''Штапики'', ''Соединители'')) as ELEM_CNT ' +
    'from GRORDERS o ' +
    'left join TREEFOLDERS t on t.TREEFOLDERID = o.TREEFOLDERID ' +
    'where o.ISOPTIMIZED = 1 ' +
    'order by o.GRORDERID desc';
  FSql.ExecQuery;

  Count := 0;
  SetLength(Items, 0);
  while not FSql.Eof do
  begin
    Item.Id := FSql.FieldByName('GRORDERID').AsInteger;
    Item.Name := FSql.FieldByName('GRO_NAME').AsString;
    if not FSql.FieldByName('FOLDERNAME').IsNull then
      Item.FolderName := FSql.FieldByName('FOLDERNAME').AsString
    else
      Item.FolderName := '';
    Item.ElementCount := FSql.FieldByName('ELEM_CNT').AsInteger;
    SetLength(Items, Count + 1);
    Items[Count] := Item;
    Inc(Count);
    FSql.Next;
  end;
  FSql.Close;

  if Started then
    FTrans.Commit;

  Result := Items;
end;

function TDbManager.GetOptimizedItems(const GrOrderId: Integer): TArray<TOptimizedItem>;
var
  Items: TArray<TOptimizedItem>;
  Item: TOptimizedItem;
  Count: Integer;
  Started: Boolean;
begin
  if not FDb.Connected then
    raise Exception.Create('Database is not connected.');

  Started := False;
  if not FTrans.InTransaction then
  begin
    FTrans.StartTransaction;
    Started := True;
  end;

  FSql.Close;
  FSql.SQL.Text :=
    'select o.optimizedid as OPTIMIZEDID, o.grordid as GRORDERID, ' +
    'oa.OA_ID as ITEMID, oa.oa_art as OP_ARTICUL, oa.oa_name as OP_NAME, ' +
    'cast('''' as varchar(64)) as OUTCOLOR, cast('''' as varchar(64)) as INCOLOR, ' +
    'o.op_qty as OP_QTY, o.op_long as OP_LONG, ' +
    'o.op_ostat as OP_OSTAT, o.op_sumprof as OP_SUMPROF, ' +
    'o.op_isforpair as OP_ISOFPAIR, cast(1 as integer) as ITEMTYPE, ' +
    '(o.op_long - o.op_ostat) as LONG_RASPIL ' +
    'from OPTIMIZED o ' +
    'join OPTARTCOLORED oac on oac.COLOREDID = o.COLOREDID ' +
    'join OPTART oa on oa.OA_ID = oac.OA_ID ' +
    'join VIRTARTTYPES vt on vt.VIRTARTTYPEID = o.VIRTARTTYPEID ' +
    'where o.GRORDID = :GRORDERID ' +
    '  and vt.DESCRIPTION in (''Профили'', ''Штапики'', ''Соединители'') ' +
    'order by o.optimizedid';
  FSql.ParamByName('GRORDERID').AsInteger := GrOrderId;
  FSql.ExecQuery;

  Count := 0;
  SetLength(Items, 0);
  while not FSql.Eof do
  begin
    Item.OptimizedId := FSql.FieldByName('OPTIMIZEDID').AsInteger;
    Item.GrOrderId := FSql.FieldByName('GRORDERID').AsInteger;
    Item.ItemId := FSql.FieldByName('ITEMID').AsInteger;
    Item.Articul := FSql.FieldByName('OP_ARTICUL').AsString;
    Item.Name := FSql.FieldByName('OP_NAME').AsString;
    Item.OutColor := FSql.FieldByName('OUTCOLOR').AsString;
    Item.InColor := FSql.FieldByName('INCOLOR').AsString;
    Item.Qty := FSql.FieldByName('OP_QTY').AsInteger;
    Item.Length := FSql.FieldByName('OP_LONG').AsFloat;
    Item.Ostat := FSql.FieldByName('OP_OSTAT').AsFloat;
    Item.SumProf := FSql.FieldByName('OP_SUMPROF').AsFloat;
    Item.IsForPair := FSql.FieldByName('OP_ISOFPAIR').AsInteger;
    Item.ItemType := FSql.FieldByName('ITEMTYPE').AsInteger;
    Item.LongRaspil := FSql.FieldByName('LONG_RASPIL').AsFloat;
    SetLength(Items, Count + 1);
    Items[Count] := Item;
    Inc(Count);
    FSql.Next;
  end;
  FSql.Close;

  if Started then
    FTrans.Commit;

  Result := Items;
end;

function TDbManager.GetOptimizedDetails(const GrOrderId: Integer): TArray<TOptimizedDetail>;
var
  Items: TArray<TOptimizedDetail>;
  Item: TOptimizedDetail;
  Count: Integer;
  Started: Boolean;
begin
  if not FDb.Connected then
    raise Exception.Create('Database is not connected.');

  Started := False;
  if not FTrans.InTransaction then
  begin
    FTrans.StartTransaction;
    Started := True;
  end;

  FSql.Close;
  FSql.SQL.Text :=
    'select d.OD_ID, d.OPTIMIZEDID, d.OD_PARTNO, d.OD_LONG, d.OD_QTY, ' +
    'd.OD_UG1, d.OD_UG2, d.OD_ORDERID, d.OD_WINDOWID, d.OD_NUM, d.OD_SUBNUM ' +
    'from OPT_DETAIL d ' +
    'join OPTIMIZED o on o.OPTIMIZEDID = d.OPTIMIZEDID ' +
    'where o.GRORDID = :GRORDERID ' +
    'order by d.OD_ID';
  FSql.ParamByName('GRORDERID').AsInteger := GrOrderId;
  FSql.ExecQuery;

  Count := 0;
  SetLength(Items, 0);
  while not FSql.Eof do
  begin
    Item.DetailId := FSql.FieldByName('OD_ID').AsInteger;
    Item.OptimizedId := FSql.FieldByName('OPTIMIZEDID').AsInteger;
    Item.PartNo := FSql.FieldByName('OD_PARTNO').AsInteger;
    Item.Length := FSql.FieldByName('OD_LONG').AsFloat;
    Item.Qty := FSql.FieldByName('OD_QTY').AsInteger;
    Item.Ug1 := FSql.FieldByName('OD_UG1').AsFloat;
    Item.Ug2 := FSql.FieldByName('OD_UG2').AsFloat;
    Item.OrderId := FSql.FieldByName('OD_ORDERID').AsInteger;
    Item.WindowId := FSql.FieldByName('OD_WINDOWID').AsInteger;
    Item.Num := FSql.FieldByName('OD_NUM').AsInteger;
    Item.SubNum := FSql.FieldByName('OD_SUBNUM').AsInteger;
    SetLength(Items, Count + 1);
    Items[Count] := Item;
    Inc(Count);
    FSql.Next;
  end;
  FSql.Close;

  if Started then
    FTrans.Commit;

  Result := Items;
end;

end.
