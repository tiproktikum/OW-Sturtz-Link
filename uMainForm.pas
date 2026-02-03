unit uMainForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.FileCtrl,
  uConfig,
  uDb,
  uTypes;

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
    listGroups: TListBox;
    btnExport: TButton;
    memoLog: TMemo;
    OpenDialogDb: TOpenDialog;
    pConnect: TPanel;
    pBottom: TPanel;
    pTop: TPanel;
    Image1: TImage;
    pMain: TPanel;
    lblLog: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseDbClick(Sender: TObject);
    procedure btnBrowseExportDirClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnSaveConfigClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
  private
    FConfig: TAppConfig;
    FDb: TDbManager;
    procedure LoadConfig;
    procedure SaveConfig;
    procedure Log(const Msg: string);
    procedure ClearGroupList;
    procedure RefreshGroups;
    function SelectedGroupRef: TGroupOrderRef;
  public
  end;

var
  MainForm: TMainForm;

implementation

uses
  uSturtzSob;

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FConfig := TAppConfig.Create;
  FDb := TDbManager.Create;
  LoadConfig;
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
var
  I: Integer;
begin
  for I := 0 to listGroups.Items.Count - 1 do
    listGroups.Items.Objects[I].Free;
  listGroups.Clear;
end;

procedure TMainForm.RefreshGroups;
var
  Groups: TArray<TGroupOrder>;
  Group: TGroupOrder;
  Ref: TGroupOrderRef;
begin
  ClearGroupList;
  Groups := FDb.GetGroupOrders;
  for Group in Groups do
  begin
    Ref := TGroupOrderRef.Create(Group.Id, Group.Name);
    listGroups.Items.AddObject(Format('%d - %s', [Group.Id, Group.Name]), Ref);
  end;
  Log(Format('Загружено групп: %d', [Length(Groups)]));
end;

function TMainForm.SelectedGroupRef: TGroupOrderRef;
var
  Idx: Integer;
begin
  Idx := listGroups.ItemIndex;
  if Idx < 0 then
    Exit(nil);
  Result := TGroupOrderRef(listGroups.Items.Objects[Idx]);
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
  FDb.Disconnect;
  Log('Отключено от БД.');
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
  FileName: string;
  Builder: TSturtzSobBuilder;
  OptimizedItems: TArray<TOptimizedItem>;
  OptimizedDetails: TArray<TOptimizedDetail>;
  Item: TOptimizedItem;
  Detail: TOptimizedDetail;
  SeqKs: Integer;
  SeqKt: Integer;
begin
  if not FDb.IsConnected then
    raise Exception.Create('Сначала подключитесь к БД.');

  Group := SelectedGroupRef;
  if Group = nil then
    raise Exception.Create('Сначала выберите группу оптимизации.');

  ExportDir := Trim(edtExportDir.Text);
  if ExportDir = '' then
    raise Exception.Create('Выберите папку выгрузки.');
  if not System.SysUtils.DirectoryExists(ExportDir) then
    raise Exception.Create('Папка выгрузки не существует.');

  FileName := IncludeTrailingPathDelimiter(ExportDir) + Format('GR_%d.sob', [Group.Id]);

  OptimizedItems := FDb.GetOptimizedItems(Group.Id);
  OptimizedDetails := FDb.GetOptimizedDetails(Group.Id);

  Builder := TSturtzSobBuilder.Create;
  try
    Builder.AddVerHeader('02.07');
    SeqKs := 1;
    SeqKt := 1;
    for Item in OptimizedItems do
    begin
      Builder.AddKs(Item, SeqKs);
      Inc(SeqKs);
      for Detail in OptimizedDetails do
        if Detail.OptimizedId = Item.OptimizedId then
        begin
          Builder.AddKt(Detail, Item, SeqKt);
          Inc(SeqKt);
        end;
      if Item.Ostat > 0 then
        Builder.AddKr(Item);
    end;
    Builder.SaveToFile(FileName);
  finally
    Builder.Free;
  end;

  Log('Выгружено: ' + FileName);
  Log(Format('KS: %d, KT: %d', [Length(OptimizedItems), Length(OptimizedDetails)]));
end;

end.
