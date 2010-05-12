program HTMLParser;

uses
{$IFDEF madExcept}
  madListHardware,
  madListProcesses,
  madListModules,
  madExcept,
  madLinkDisAsm,
{$ENDIF}
  Forms,
  Main in 'Main.pas' {MainForm},
  Parser2 in 'Parser2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
