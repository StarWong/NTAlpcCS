program FServer;

uses
{$IFNDEF DEBUG}
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
{$ENDIF}
  Forms,
  ALPC_Server_Example in 'ALPC_Server_Example.pas' {MainForm},
  ALPC_Base in 'ALPC_Base.Pas',
  ALPC_LPC_Define in 'ALPC_LPC_Define.Pas',
  ALPC_Server in 'ALPC_Server.Pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
