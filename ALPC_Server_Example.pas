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
procedure sum(const user:PStubViewer;const host:PStubViewer);
function sum(const a,b:Integer):Integer;
begin
    Result:=a + b;
end;
begin
user.FillServerCache(host);//save data to host
user.Marshal.count:=1;
user.Marshal.Arg[0].isPointer:=False;
user.Marshal.Arg[0].staticData.Integer:=sum(pinteger(host.Arg(0))^,pinteger(host.Arg(1))^);
user.LoadDynamicData;
end;

initialization
AddFunc('sum',sum);
end.
