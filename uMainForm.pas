unit uMainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellAPI,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.FileCtrl,
  Vcl.Grids,
  uConfig,
  uDb,
  uTypes,
  uTranslit,
  Vcl.Imaging.pngimage;

type
  TMainForm = class(TForm)
    lblDbPath: TLabel;
    edtDbPath: TEdit;
    btnBrowseDb: TButton;
    btnConnect: TButton;
    btnDisconnect: TButton;
    lblUser: TLabel;
    edtUser: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
    lblRole: TLabel;
    edtRole: TEdit;
    lblCharset: TLabel;
    edtCharset: TEdit;
    lblExportDir: TLabel;
    edtExportDir: TEdit;
    btnBrowseExportDir: TButton;
    btnSaveConfig: TButton;
    gridGroups: TStringGrid;
    btnExport: TButton;
    memoLog: TMemo;
    OpenDialogDb: TOpenDialog;
    pConnect: TPanel;
    pBottom: TPanel;
    pTop: TPanel;
    Image1: TImage;
    pMain: TPanel;
    lblLog: TLabel;
    pGrOrders: TPanel;
    eFilter: TEdit;
    Label1: TLabel;
    pButtons: TPanel;
    pSeparator: TPanel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseDbClick(Sender: TObject);
    procedure btnBrowseExportDirClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnSaveConfigClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure eFilterChange(Sender: TObject);
    procedure pMainResize(Sender: TObject);
  private
    FConfig: TAppConfig;
    FDb: TDbManager;
    FAllGroups: TArray<TGroupOrder>;
    FFilteredGroups: TArray<TGroupOrder>;
    procedure LoadConfig;
    procedure SaveConfig;
    procedure Log(const Msg: string);
    procedure ClearGroupList;
    procedure RefreshGroups;
    procedure ApplyFilter;
    procedure InitGridColumnWidths;
    procedure SetGridGroupHeaders;
    function SelectedGroupRef: TGroupOrderRef;
    function SanitizeFileNameForWindows(const S: string): string;
  public
  end;

var
  MainForm: TMainForm;

implementation

uses
  uSturtzSob;

const
  ColName = 0;
  ColFolder = 1;
  ColId = 2;
  ColElementCount = 3;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FConfig := TAppConfig.Create;
  FDb := TDbManager.Create;
  LoadConfig;
  SetGridGroupHeaders;
  InitGridColumnWidths;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  ClearGroupList;
  FDb.Free;
  FConfig.Free;
end;

procedure TMainForm.LoadConfig;
begin
  FConfig.LoadFromFile(TAppConfig.DefaultConfigPath);
  edtDbPath.Text := FConfig.DbPath;
  edtUser.Text := FConfig.DbUser;
  edtPassword.Text := FConfig.DbPassword;
  edtRole.Text := FConfig.DbRole;
  edtCharset.Text := FConfig.DbCharset;
  edtExportDir.Text := FConfig.LastExportDir;
end;

procedure TMainForm.SaveConfig;
begin
  FConfig.DbPath := edtDbPath.Text;
  FConfig.DbUser := edtUser.Text;
  FConfig.DbPassword := edtPassword.Text;
  FConfig.DbRole := edtRole.Text;
  FConfig.DbCharset := edtCharset.Text;
  FConfig.LastExportDir := edtExportDir.Text;
  FConfig.SaveToFile(TAppConfig.DefaultConfigPath);
end;

procedure TMainForm.Log(const Msg: string);
begin
  memoLog.Lines.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '  ' + Msg);
end;

procedure TMainForm.ClearGroupList;
begin
  gridGroups.RowCount := 1;
  FFilteredGroups := nil;
end;

procedure TMainForm.ApplyFilter;
var
  Filter: string;
  Group: TGroupOrder;
  I: Integer;
begin
  ClearGroupList;
  Filter := Trim(eFilter.Text);
  SetLength(FFilteredGroups, 0);
  I := 0;
  for Group in FAllGroups do
    if (Filter = '') or (Pos(UpperCase(Filter), UpperCase(Group.Name)) > 0) then
    begin
      SetLength(FFilteredGroups, I + 1);
      FFilteredGroups[I] := Group;
      Inc(I);
    end;
  gridGroups.RowCount := Length(FFilteredGroups) + 1;
  for I := 0 to High(FFilteredGroups) do
  begin
    gridGroups.Cells[ColName, I + 1] := FFilteredGroups[I].Name;
    gridGroups.Cells[ColFolder, I + 1] := FFilteredGroups[I].FolderName;
    gridGroups.Cells[ColId, I + 1] := IntToStr(FFilteredGroups[I].Id);
    gridGroups.Cells[ColElementCount, I + 1] := IntToStr(FFilteredGroups[I].ElementCount);
  end;
end;

procedure TMainForm.InitGridColumnWidths;
begin
  gridGroups.ColWidths[ColName] := 280;         // Наименование группы
  gridGroups.ColWidths[ColFolder] := 142;       // Папка
  gridGroups.ColWidths[ColId] := 50;            // ID
  gridGroups.ColWidths[ColElementCount] := 120; // Кол-во эл.
end;

procedure TMainForm.SetGridGroupHeaders;
begin
  gridGroups.Cells[ColName, 0] := 'Наименование группы';
  gridGroups.Cells[ColFolder, 0] := 'Папка';
  gridGroups.Cells[ColId, 0] := 'ID';
  gridGroups.Cells[ColElementCount, 0] := 'Кол-во эл.';
end;

procedure TMainForm.RefreshGroups;
begin
  FAllGroups := FDb.GetGroupOrders;
  SetGridGroupHeaders;
  ApplyFilter;
  InitGridColumnWidths;
  Log(Format('Загружено групп: %d', [Length(FAllGroups)]));
end;

function TMainForm.SelectedGroupRef: TGroupOrderRef;
var
  Row: Integer;
begin
  Result := nil;
  Row := gridGroups.Row;
  if (Row < 1) or (Row > Length(FFilteredGroups)) then
    Exit;
  Result := TGroupOrderRef.Create(FFilteredGroups[Row - 1].Id, FFilteredGroups[Row - 1].Name);
end;

function TMainForm.SanitizeFileNameForWindows(const S: string): string;
const
  InvalidChars = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if not CharInSet(C, InvalidChars) and (Ord(C) >= 32) then
      Result := Result + C;
  end;
  Result := Trim(Result);
  if Result = '' then
    Result := 'Group';
end;

procedure TMainForm.btnBrowseDbClick(Sender: TObject);
begin
  OpenDialogDb.Filter := 'База Firebird (*.fdb;*.gdb)|*.fdb;*.gdb|Все файлы (*.*)|*.*';
  if OpenDialogDb.Execute then
    edtDbPath.Text := OpenDialogDb.FileName;
end;

procedure TMainForm.btnBrowseExportDirClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := Trim(edtExportDir.Text);
  if SelectDirectory('Выберите папку выгрузки', '', Dir) then
    edtExportDir.Text := Dir;
end;

procedure TMainForm.btnConnectClick(Sender: TObject);
begin
  SaveConfig;
  try
    if FDb.Connect(FConfig) then
    begin
      Log('Подключение к БД выполнено.');
      RefreshGroups;
    end
    else
      Log('Не удалось подключиться к БД.');
  except
    on E: Exception do
      Log(E.Message);
  end;
end;

procedure TMainForm.btnDisconnectClick(Sender: TObject);
begin
  ClearGroupList;
  FAllGroups := nil;
  FDb.Disconnect;
  Log('Отключено от БД.');
end;

procedure TMainForm.eFilterChange(Sender: TObject);
begin
  if Length(FAllGroups) > 0 then
    ApplyFilter;
end;

procedure TMainForm.pMainResize(Sender: TObject);
begin
  { ширина колонок таблицы групп фиксирована }
end;

procedure TMainForm.btnSaveConfigClick(Sender: TObject);
begin
  SaveConfig;
  Log('Настройки подключения сохранены.');
end;

procedure TMainForm.btnExportClick(Sender: TObject);
var
  Group: TGroupOrderRef;
  ExportDir: string;
  BaseName: string;
  FileName: string;
  SoeFileName: string;
  Builder: TSturtzSobBuilder;
  SoeBuilder: TSturtzSoeBuilder;
  ItemByOptimizedId: TDictionary<Integer, TOptimizedItem>;
  KsSeqByOptimizedId: TDictionary<Integer, Integer>;
  KtSeqByDetailId: TDictionary<Integer, Integer>;
  OptimizedItems: TArray<TOptimizedItem>;
  OptimizedDetails: TArray<TOptimizedDetail>;
  Item: TOptimizedItem;
  ItemForDetail: TOptimizedItem;
  Detail: TOptimizedDetail;
  SeqKs: Integer;
  SeqKt: Integer;
  KtSeq: Integer;
  KsSeq: Integer;
  ColorText: string;
begin
  if not FDb.IsConnected then
    raise Exception.Create('Сначала подключитесь к БД.');

  Group := SelectedGroupRef;
  if Group = nil then
    raise Exception.Create('Сначала выберите группу оптимизации.');
  try
  ExportDir := Trim(edtExportDir.Text);
  if ExportDir = '' then
    raise Exception.Create('Выберите папку выгрузки.');
  if not System.SysUtils.DirectoryExists(ExportDir) then
    raise Exception.Create('Папка выгрузки не существует.');

  BaseName := 'G' + Copy(SanitizeFileNameForWindows(CyrillicToLatin(Group.Name)), 1, 7);
  FileName := IncludeTrailingPathDelimiter(ExportDir) + BaseName + '.SOB';
  SoeFileName := IncludeTrailingPathDelimiter(ExportDir) + BaseName + '.SOE';

  OptimizedItems := FDb.GetOptimizedItems(Group.Id);
  OptimizedDetails := FDb.GetOptimizedDetails(Group.Id);

  Builder := TSturtzSobBuilder.Create;
  SoeBuilder := TSturtzSoeBuilder.Create;
  ItemByOptimizedId := TDictionary<Integer, TOptimizedItem>.Create;
  KsSeqByOptimizedId := TDictionary<Integer, Integer>.Create;
  KtSeqByDetailId := TDictionary<Integer, Integer>.Create;
  try
    Builder.AddVerHeader('02.07');
    SeqKs := 1;
    SeqKt := 1;
    for Item in OptimizedItems do
    begin
      ItemByOptimizedId.AddOrSetValue(Item.OptimizedId, Item);
      KsSeqByOptimizedId.AddOrSetValue(Item.OptimizedId, SeqKs);
      Builder.AddKs(Item, SeqKs);
      Inc(SeqKs);
      for Detail in OptimizedDetails do
        if Detail.OptimizedId = Item.OptimizedId then
        begin
          Builder.AddKt(Detail, Item, SeqKt);
          KtSeqByDetailId.AddOrSetValue(Detail.DetailId, SeqKt);
          Inc(SeqKt);
        end;
      if Item.Ostat > 0 then
        Builder.AddKr(Item);
    end;
    Builder.SaveToFile(FileName);
    for Detail in OptimizedDetails do
    begin
      if not KtSeqByDetailId.TryGetValue(Detail.DetailId, KtSeq) then
        Continue;
      if not ItemByOptimizedId.TryGetValue(Detail.OptimizedId, ItemForDetail) then
        Continue;
      SoeBuilder.AddEdnt(KtSeq, [
        'TAB-NO:' + IntToStr(Detail.OrderId),
        'IZDEL-NO:' + IntToStr(Detail.PartNo)
      ]);
      SoeBuilder.AddEdnt(KtSeq, [
        'ZAKAZCHIK:' + Group.Name,
        'KOM:' + IntToStr(Group.Id)
      ]);
      SoeBuilder.AddEdnt(KtSeq, [
        'NA POZ.:' + IntToStr(Detail.PartNo),
        'POLOZHENIE:',
        'POZ.:' + IntToStr(Detail.PartNo)
      ]);
      SoeBuilder.AddEdnt(KtSeq, [
        'PROFIL:' + ItemForDetail.Articul,
        'DLINA:' + IntToStr(Round(Detail.Length))
      ]);
    end;
    for Item in OptimizedItems do
      if Item.Ostat > 0 then
      begin
        if not KsSeqByOptimizedId.TryGetValue(Item.OptimizedId, KsSeq) then
          Continue;
        SoeBuilder.AddEdnr(KsSeq, ['OSTATOK']);
        SoeBuilder.AddEdnr(KsSeq, ['PROFIL:' + Item.Articul]);
        ColorText := Item.OutColor;
        if ColorText = '' then
          ColorText := '-';
        SoeBuilder.AddEdnr(KsSeq, ['CVET:' + ColorText]);
        SoeBuilder.AddEdnr(KsSeq, ['DLINA:' + IntToStr(Round(Item.Ostat)) + ' MM']);
      end;
    SoeBuilder.SaveToFile(SoeFileName);
  finally
    Builder.Free;
    SoeBuilder.Free;
    ItemByOptimizedId.Free;
    KsSeqByOptimizedId.Free;
    KtSeqByDetailId.Free;
  end;

  Log('Выгружено: ' + FileName);
  Log('Выгружено: ' + SoeFileName);
  Log(Format('KS: %d, KT: %d', [Length(OptimizedItems), Length(OptimizedDetails)]));
  ShellExecute(0, 'explore', PChar(ExportDir), nil, nil, SW_SHOWNORMAL);
  finally
    Group.Free;
  end;
end;

end.
