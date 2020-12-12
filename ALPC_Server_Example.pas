unit ALPC_Server_Example;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, RzEdit;

type
  TMainForm = class(TForm)
    RzMemo1: TRzMemo;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
uses
ALPC_Server;
{$R *.dfm}

procedure TMainForm.Button1Click(Sender: TObject);
begin
if not Initialize('MyCoolDummyAlpcPort') then ShowMessage('faile');
StartServer;
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
StopServer;
end;

end.
