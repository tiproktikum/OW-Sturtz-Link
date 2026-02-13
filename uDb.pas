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
    function GetPartWindowIdByTag(const ShortTag, ItemName: string): Integer;
    function GetReinforcementCodes(const PartWindRepId, PositionId,
      WindowId: Integer): string;
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

function BuildConnectionParamsLog(const Config: TAppConfig; const DatabaseName: string): string;
begin
  Result :=
    'Параметры подключения:' + sLineBreak +
    '  Server (хост): ' + QuotedStr(Config.DbHost) + sLineBreak +
    '  Path (путь к БД): ' + QuotedStr(Config.DbPath) + sLineBreak +
    '  DatabaseName (итог): ' + QuotedStr(DatabaseName) + sLineBreak +
    '  User: ' + QuotedStr(Config.DbUser) + sLineBreak +
    '  Role: ' + QuotedStr(Config.DbRole) + sLineBreak +
    '  Charset: ' + QuotedStr(Config.DbCharset);
end;

function TDbManager.Connect(const Config: TAppConfig): Boolean;
var
  DbName: string;
begin
  if FDb.Connected then
    FDb.Connected := False;

  if Trim(Config.DbHost) <> '' then
    DbName := Trim(Config.DbHost) + ':' + Config.DbPath
  else
    DbName := Config.DbPath;
  FDb.DatabaseName := DbName;

  FDb.Params.Clear;
  if Config.DbUser <> '' then
    FDb.Params.Add('user_name=' + Config.DbUser);
  if Config.DbPassword <> '' then
    FDb.Params.Add('password=' + Config.DbPassword);
  if Config.DbRole <> '' then
    FDb.Params.Add('sql_role_name=' + Config.DbRole);
  if Config.DbCharset <> '' then
    FDb.Params.Add('lc_ctype=' + Config.DbCharset);

  if Trim(DbName) = '' then
    raise Exception.Create(
      'Не задано имя базы данных (Firebird: Database name is missing).' + sLineBreak + sLineBreak +
      'Файл конфигурации: ' + TAppConfig.DefaultConfigPath + sLineBreak +
      'Все параметры пустые — ini отсутствовал при первом запуске или не прочитался.' + sLineBreak + sLineBreak +
      BuildConnectionParamsLog(Config, DbName) + sLineBreak + sLineBreak +
      'Скопируйте ow_sturtz_link.ini в папку с exe и заполните [Database]: Path=, User=, Password=; при удалённой БД — Server=.'
    );

  try
    FDb.Connected := True;
    Result := FDb.Connected;
  except
    on E: Exception do
      raise Exception.Create(
        'Ошибка подключения к Firebird: ' + E.Message + sLineBreak + sLineBreak +
        'Файл конфигурации: ' + TAppConfig.DefaultConfigPath + sLineBreak + sLineBreak +
        BuildConnectionParamsLog(Config, DbName) + sLineBreak + sLineBreak +
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

function TDbManager.GetPartWindowIdByTag(const ShortTag, ItemName: string): Integer;
var
  Q: TIBSQL;
  Pattern: string;
  Tag: string;
begin
  Result := -1;
  Tag := Trim(ShortTag);
  if SameText(Tag, 'Р') then
    Pattern := 'Рама'
  else if SameText(Tag, 'C') or SameText(Tag, 'С') then
    Pattern := 'Створка'
  else if SameText(Tag, 'Иг') or SameText(Tag, 'Ив') then
    Pattern := 'Импост'
  else if SameText(Tag, 'Ш') then
    Pattern := 'Штульп'
  else if SameText(Tag, 'Прг') then
    Pattern := 'Порог'
  else if SameText(Tag, 'Ц') then
    Pattern := 'Цоколь'
  else if Pos('Рама', ItemName) > 0 then
    Pattern := 'Рама'
  else if Pos('Створка', ItemName) > 0 then
    Pattern := 'Створка'
  else if Pos('Импост', ItemName) > 0 then
    Pattern := 'Импост'
  else if Pos('Штульп', ItemName) > 0 then
    Pattern := 'Штульп'
  else if Pos('Порог', ItemName) > 0 then
    Pattern := 'Порог'
  else if Pos('Цоколь', ItemName) > 0 then
    Pattern := 'Цоколь'
  else
    Pattern := '';

  if Pattern = '' then
    Exit;

  Q := TIBSQL.Create(nil);
  try
    Q.Database := FDb;
    Q.Transaction := FTrans;
    Q.SQL.Text :=
      'select first 1 rp.PARTWINDOWID ' +
      'from R_PARTWINDOW rp ' +
      'where rp.PW_NAME containing :P ' +
      'order by rp.PARTWINDOWID';
    Q.ParamByName('P').AsString := Pattern;
    Q.ExecQuery;
    if not Q.Eof then
      Result := Q.FieldByName('PARTWINDOWID').AsInteger;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TDbManager.GetReinforcementCodes(const PartWindRepId, PositionId,
  WindowId: Integer): string;
var
  Q: TIBSQL;
  ProfileArticulId: Integer;
  ShortTag: string;
  ItemName: string;
  PartWindowId: Integer;
  PratPartId: Integer;
  RsTypes: TStringList;
  InClause: string;
  I: Integer;
begin
  Result := '';
  ProfileArticulId := 0;
  ShortTag := '';
  ItemName := '';
  PartWindowId := -1;
  PratPartId := 0;

  Q := TIBSQL.Create(nil);
  RsTypes := TStringList.Create;
  try
    Q.Database := FDb;
    Q.Transaction := FTrans;

    Q.SQL.Text :=
      'select first 1 w.ARTICULID, r.SHORTTAG, r.ITEMNAME ' +
      'from WINPROFILES w ' +
      'join VIRTARTICULES va on va.ARTICULID = w.ARTICULID ' +
      'join VIRTARTTYPES vt on vt.VIRTARTTYPEID = va.VIRTARTTYPEID ' +
      'left join PARTWINDOWREP r on r.PARTWINDREPID = w.PARTWINDREPID ' +
      'where w.PARTWINDREPID = :PARTWINDREPID ' +
      '  and w.POSITIONID = :POSITIONID ' +
      '  and w.WINDOWID = :WINDOWID ' +
      '  and vt.DESCRIPTION = ''Профили''';
    Q.ParamByName('PARTWINDREPID').AsInteger := PartWindRepId;
    Q.ParamByName('POSITIONID').AsInteger := PositionId;
    Q.ParamByName('WINDOWID').AsInteger := WindowId;
    Q.ExecQuery;
    if Q.Eof then
      Exit;
    ProfileArticulId := Q.FieldByName('ARTICULID').AsInteger;
    if not Q.FieldByName('SHORTTAG').IsNull then
      ShortTag := Q.FieldByName('SHORTTAG').AsString;
    if not Q.FieldByName('ITEMNAME').IsNull then
      ItemName := Q.FieldByName('ITEMNAME').AsString;
    Q.Close;

    PartWindowId := GetPartWindowIdByTag(ShortTag, ItemName);
    if PartWindowId <= 0 then
      Exit;

    Q.SQL.Text :=
      'select first 1 PRATPARTID ' +
      'from PROFATPARTS ' +
      'where PARTWINDOWID = :PARTWINDOWID ' +
      '  and PROFPARTID = :PROFPARTID';
    Q.ParamByName('PARTWINDOWID').AsInteger := PartWindowId;
    Q.ParamByName('PROFPARTID').AsInteger := ProfileArticulId;
    Q.ExecQuery;
    if Q.Eof then
      Exit;
    PratPartId := Q.FieldByName('PRATPARTID').AsInteger;
    Q.Close;

    Q.SQL.Text :=
      'select RS_TYP ' +
      'from LINK_PARTS_STAL ' +
      'where PARTWINDOWID = :PARTWINDOWID';
    Q.ParamByName('PARTWINDOWID').AsInteger := PartWindowId;
    Q.ExecQuery;
    while not Q.Eof do
    begin
      RsTypes.Add(IntToStr(Q.FieldByName('RS_TYP').AsInteger));
      Q.Next;
    end;
    Q.Close;

    if RsTypes.Count = 0 then
      Exit;

    InClause := '';
    for I := 0 to RsTypes.Count - 1 do
    begin
      if I > 0 then
        InClause := InClause + ',';
      InClause := InClause + RsTypes[I];
    end;

    Q.SQL.Text :=
      'select distinct va.AR_ART ' +
      'from PROF_STAL ps ' +
      'join VIRTARTICULES va on va.ARTICULID = ps.RS_ID ' +
      'where ps.PRATPARTID = :PRATPARTID ' +
      '  and ps.DELETED = 0 ' +
      '  and ps.RS_TYP in (' + InClause + ') ' +
      'order by va.AR_ART';
    Q.ParamByName('PRATPARTID').AsInteger := PratPartId;
    Q.ExecQuery;
    while not Q.Eof do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + Trim(Q.FieldByName('AR_ART').AsString);
      Q.Next;
    end;
    Q.Close;
  finally
    RsTypes.Free;
    Q.Free;
  end;
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
    'select d.OD_ID, d.OPTIMIZEDID, d.PARTWINDREPID, d.POSITIONID, d.OD_PARTNO, d.OD_LONG, d.OD_LONG_AL, d.OD_QTY, ' +
    'd.OD_UG1, d.OD_UG2, d.OD_ORDERID, ord.ORDNO as ORDER_NO, d.OD_WINDOWID, win.WN_WIDTH, win.WN_HEIGHT, d.OD_NUM, d.OD_SUBNUM, ' +
    'p.SHORTNAME as POSITION_SHORTNAME, ' +
    'r.SHORTTAG as PART_SHORTTAG ' +
    'from OPT_DETAIL d ' +
    'join OPTIMIZED o on o.OPTIMIZEDID = d.OPTIMIZEDID ' +
    'left join ORDERS ord on ord.ORDERID = d.OD_ORDERID ' +
    'left join WINDOWS win on win.WINDOWID = d.OD_WINDOWID ' +
    'left join POSITIONS p on p.POSITIONID = d.POSITIONID ' +
    'left join ( ' +
    '  select w.* ' +
    '  from WINPROFILES w ' +
    '  join VIRTARTICULES va on va.ARTICULID = w.ARTICULID ' +
    '  join VIRTARTTYPES vt on vt.VIRTARTTYPEID = va.VIRTARTTYPEID ' +
    '  where vt.DESCRIPTION in (''Профили'', ''Штапики'', ''Соединители'') ' +
    ') w on w.WINDOWID = d.OD_WINDOWID ' +
    '  and w.PARTWINDREPID = d.PARTWINDREPID ' +
    '  and w.WP_PARTNO = d.OD_PARTNO ' +
    '  and w.POSITIONID = d.POSITIONID ' +
    '  and w.OUTCOLORID = o.EXTCOLORID ' +
    '  and w.INCOLORID = o.INTCOLORID ' +
    'left join PARTWINDOWREP r on r.PARTWINDREPID = w.PARTWINDREPID ' +
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
    Item.PartWindRepId := FSql.FieldByName('PARTWINDREPID').AsInteger;
    Item.PositionId := FSql.FieldByName('POSITIONID').AsInteger;
    Item.PartNo := FSql.FieldByName('OD_PARTNO').AsInteger;
    Item.Length := FSql.FieldByName('OD_LONG').AsFloat;
    Item.ArmLength := FSql.FieldByName('OD_LONG_AL').AsFloat;
    Item.Qty := FSql.FieldByName('OD_QTY').AsInteger;
    Item.Ug1 := FSql.FieldByName('OD_UG1').AsFloat;
    Item.Ug2 := FSql.FieldByName('OD_UG2').AsFloat;
    Item.OrderId := FSql.FieldByName('OD_ORDERID').AsInteger;
    if not FSql.FieldByName('ORDER_NO').IsNull then
      Item.OrderNo := Trim(FSql.FieldByName('ORDER_NO').AsString)
    else
      Item.OrderNo := '';
    Item.WindowId := FSql.FieldByName('OD_WINDOWID').AsInteger;
    if not FSql.FieldByName('WN_WIDTH').IsNull then
      Item.WindowWidth := FSql.FieldByName('WN_WIDTH').AsFloat
    else
      Item.WindowWidth := 0;
    if not FSql.FieldByName('WN_HEIGHT').IsNull then
      Item.WindowHeight := FSql.FieldByName('WN_HEIGHT').AsFloat
    else
      Item.WindowHeight := 0;
    Item.Num := FSql.FieldByName('OD_NUM').AsInteger;
    Item.SubNum := FSql.FieldByName('OD_SUBNUM').AsInteger;
    if not FSql.FieldByName('POSITION_SHORTNAME').IsNull then
      Item.PositionTag := FSql.FieldByName('POSITION_SHORTNAME').AsString
    else
      Item.PositionTag := '';
    if not FSql.FieldByName('PART_SHORTTAG').IsNull then
      Item.PartShortTag := FSql.FieldByName('PART_SHORTTAG').AsString
    else
      Item.PartShortTag := '';
    Item.ReinforcementCodes := GetReinforcementCodes(Item.PartWindRepId,
      Item.PositionId, Item.WindowId);
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
