program OWSturtzLink;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uConfig in 'uConfig.pas',
  uDb in 'uDb.pas',
  uTypes in 'uTypes.pas',
  uSturtzSob in 'uSturtzSob.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
