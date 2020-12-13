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
procedure sum(const user:PViewCache;const host:PReadIn);
function sum(const a,b:Integer):Integer;
begin
    Result:=a + b;
end;
var
list:ret_Offsets;
begin
list[0]:=1;
list[1]:=4;
host.Push(user);
user.Marshal(list);
PInteger(user.return(0))^:=sum(PInteger(host^*0)^ ,PInteger(host^*1)^);
user.Sign(True);
end;
initialization
AddFunc('sum',sum);
end.
