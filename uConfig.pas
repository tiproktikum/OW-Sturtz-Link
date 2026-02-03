unit uConfig;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles;

type
  TAppConfig = class
  private
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
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'ow_sturtz_link.ini';
end;

procedure TAppConfig.LoadFromFile(const Path: string);
var
  Ini: TMemIniFile;
  Enc: TEncoding;
begin
  if not FileExists(Path) then
    Exit;
  Enc := TUTF8Encoding.Create(False);
  Ini := TMemIniFile.Create(Path, Enc);
  try
    FDbPath := Ini.ReadString(CSectionDatabase, 'Path', FDbPath);
    FDbClientLib := Ini.ReadString(CSectionDatabase, 'ClientLib', FDbClientLib);
    FDbUser := Ini.ReadString(CSectionDatabase, 'User', FDbUser);
    FDbPassword := Ini.ReadString(CSectionDatabase, 'Password', FDbPassword);
    FDbRole := Ini.ReadString(CSectionDatabase, 'Role', FDbRole);
    FDbCharset := Ini.ReadString(CSectionDatabase, 'Charset', FDbCharset);
    FLastExportDir := Ini.ReadString(CSectionUi, 'LastExportDir', FLastExportDir);
  finally
    Ini.Free;
    Enc.Free;
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
