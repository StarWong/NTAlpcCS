program FClient;

uses
  Forms,
  ALPC_Client_Example in 'ALPC_Client_Example.Pas' {Client},
  ALPC_Base in 'ALPC_Base.Pas',
  ALPC_Client in 'ALPC_Client.Pas',
  ALPC_LPC_Define in 'ALPC_LPC_Define.Pas',
  Logger in 'Logger.pas',
  Base64 in 'Base64.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TClient, Client);
  Application.Run;
end.
