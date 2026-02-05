unit uConfig;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  System.IOUtils;

type
  TAppConfig = class
  private
    FDbHost: string;
    FDbPath: string;
    FDbClientLib: string;
    FDbUser: string;
    FDbPassword: string;
    FDbRole: string;
    FDbCharset: string;
    FLastExportDir: string;
  public
    constructor Create;
    class function DefaultConfigPath: string;
    procedure LoadFromFile(const Path: string);
    procedure SaveToFile(const Path: string);

    property DbHost: string read FDbHost write FDbHost;
    property DbPath: string read FDbPath write FDbPath;
    property DbClientLib: string read FDbClientLib write FDbClientLib;
    property DbUser: string read FDbUser write FDbUser;
    property DbPassword: string read FDbPassword write FDbPassword;
    property DbRole: string read FDbRole write FDbRole;
    property DbCharset: string read FDbCharset write FDbCharset;
    property LastExportDir: string read FLastExportDir write FLastExportDir;
  end;

implementation

const
  CSectionDatabase = 'Database';
  CSectionUi = 'UI';

constructor TAppConfig.Create;
begin
  FDbHost := '';
  FDbPath := '';
  FDbClientLib := '';
  FDbUser := '';
  FDbPassword := '';
  FDbRole := '';
  FDbCharset := 'WIN1251';
  FLastExportDir := '';
end;

class function TAppConfig.DefaultConfigPath: string;
begin
  { Путь к ini: папка с исполняемым файлом + ow_sturtz_link.ini.
    При запуске из IDE exe лежит в Win32\Debug или Win32\Release — программа читает ini оттуда, а не из корня проекта. }
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'ow_sturtz_link.ini';
end;

procedure TAppConfig.LoadFromFile(const Path: string);

  procedure ReadIniFromStream(const Ini: TMemIniFile);
  begin
    FDbHost := Ini.ReadString(CSectionDatabase, 'Server', FDbHost);
    FDbPath := Ini.ReadString(CSectionDatabase, 'Path', FDbPath);
    FDbClientLib := Ini.ReadString(CSectionDatabase, 'ClientLib', FDbClientLib);
    FDbUser := Ini.ReadString(CSectionDatabase, 'User', FDbUser);
    FDbPassword := Ini.ReadString(CSectionDatabase, 'Password', FDbPassword);
    FDbRole := Ini.ReadString(CSectionDatabase, 'Role', FDbRole);
    FDbCharset := Ini.ReadString(CSectionDatabase, 'Charset', FDbCharset);
    FLastExportDir := Ini.ReadString(CSectionUi, 'LastExportDir', FLastExportDir);
  end;

var
  Ini: TMemIniFile;
  Enc: TEncoding;
  LBytes: TBytes;
  LContent: string;
  LTempPath: string;
begin
  if not FileExists(Path) then
  begin
    try
      SaveToFile(Path);
    except
    end;
    Exit;
  end;

  { 1) Пробуем UTF-8 без BOM (как пишет наша SaveToFile). }
  Enc := TUTF8Encoding.Create(False);
  try
    Ini := TMemIniFile.Create(Path, Enc);
    try
      ReadIniFromStream(Ini);
    finally
      Ini.Free;
    end;
  finally
    Enc.Free;
  end;

  { 2) Если Path и User пустые — возможно файл в UTF-8 с BOM (Блокнот «UTF-8») или ANSI. }
  if (FDbPath = '') and (FDbUser = '') then
  begin
    LBytes := TFile.ReadAllBytes(Path);
    { Убираем BOM UTF-8, иначе секция [Database] не находится. }
    if (Length(LBytes) >= 3) and (LBytes[0] = $EF) and (LBytes[1] = $BB) and (LBytes[2] = $BF) then
      LBytes := Copy(LBytes, 3, Length(LBytes) - 3);
    LContent := TEncoding.UTF8.GetString(LBytes);
    LTempPath := TPath.Combine(TPath.GetTempPath, 'ow_sturtz_link_' + IntToStr(TThread.GetTickCount) + '.ini');
    try
      TFile.WriteAllText(LTempPath, LContent, TUTF8Encoding.Create(False));
      Enc := TUTF8Encoding.Create(False);
      try
        Ini := TMemIniFile.Create(LTempPath, Enc);
        try
          ReadIniFromStream(Ini);
        finally
          Ini.Free;
        end;
      finally
        Enc.Free;
      end;
    finally
      if TFile.Exists(LTempPath) then
        TFile.Delete(LTempPath);
    end;
  end;

  { 3) Всё ещё пусто — пробуем ANSI (Windows-1251), как часто сохраняют пользователи. }
  if (FDbPath = '') and (FDbUser = '') then
  begin
    Enc := TEncoding.GetEncoding(1251);
    try
      Ini := TMemIniFile.Create(Path, Enc);
      try
        ReadIniFromStream(Ini);
      finally
        Ini.Free;
      end;
    finally
      Enc.Free;
    end;
  end;
end;

procedure TAppConfig.SaveToFile(const Path: string);
var
  Ini: TMemIniFile;
  Enc: TEncoding;
begin
  Enc := TUTF8Encoding.Create(False);
  Ini := TMemIniFile.Create(Path, Enc);
  try
    Ini.WriteString(CSectionDatabase, 'Server', FDbHost);
    Ini.WriteString(CSectionDatabase, 'Path', FDbPath);
    Ini.WriteString(CSectionDatabase, 'ClientLib', FDbClientLib);
    Ini.WriteString(CSectionDatabase, 'User', FDbUser);
    Ini.WriteString(CSectionDatabase, 'Password', FDbPassword);
    Ini.WriteString(CSectionDatabase, 'Role', FDbRole);
    Ini.WriteString(CSectionDatabase, 'Charset', FDbCharset);
    Ini.WriteString(CSectionUi, 'LastExportDir', FLastExportDir);
    Ini.UpdateFile;
  finally
    Ini.Free;
    Enc.Free;
  end;
end;

end.
