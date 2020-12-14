unit ALPC_Client_Example;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;
type
THT = class(TThread)

end;
type
  TClient = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Client: TClient;

implementation
uses
ALPC_Client,Logger;
{$R *.dfm}

function sum(const a,b:Integer):Integer;
begin
ClientViewer.Marshal.count:=2;
ClientViewer.Marshal.Arg[0].isPointer:=False;
ClientViewer.Marshal.Arg[0].staticData.Integer:=a;
ClientViewer.Marshal.Arg[1].isPointer:=False;
ClientViewer.Marshal.Arg[1].staticData.Integer:=b;
ClientViewer.LoadDynamicData;
Invoke;
ServerViewer.Marshal.count:=1;
ServerViewer.LoadDynamicData;
if not ServerViewer.IsSucessful then Exit(0);
Result:=ServerViewer.Marshal.Arg[0].staticData.Integer;
end;



procedure TClient.Button1Click(Sender: TObject);
var
auth:TAuth;
a,b:Integer;
begin
a:=StrToInt(Edit1.Text);
b:=StrToInt(Edit2.Text);
Printf(sum(a,b),'result:');
end;



procedure TClient.FormCreate(Sender: TObject);
begin
Initialize('MyCoolDummyAlpcPort');
Connect(nil);
end;

end.
