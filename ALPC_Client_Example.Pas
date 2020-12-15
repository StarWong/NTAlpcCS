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
    Button2: TButton;
    Edit3: TEdit;
    Edit4: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
ClientViewer.SetFuncID('sum');
ClientViewer.Marshal.Arg[0].isPointer:=False;
ClientViewer.Marshal.Arg[0].staticData.Integer:=a;
ClientViewer.Marshal.Arg[1].isPointer:=False;
ClientViewer.Marshal.Arg[1].staticData.Integer:=b;
ClientViewer.EncodeDynamicData;
Invoke;
//ClientViewer.Marshal.count:=1;
ClientViewer.DecodeDynamicData;
if not ClientViewer.IsSucessful then Exit(0);
Result:=ClientViewer.pArg(0).Integer;
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

function  getVersion(const count:Integer;out time:string):string;
begin
ClientViewer.Marshal.count:=1;
ClientViewer.SetFuncID('getVersion');
ClientViewer.Marshal.Arg[0].isPointer:=False;
ClientViewer.Marshal.Arg[0].staticData.Integer:=count;
ClientViewer.EncodeDynamicData;
Invoke;
//ClientViewer.Marshal.count:=2;
ClientViewer.DecodeDynamicData;
if not ClientViewer.IsSucessful then Exit('');
ClientViewer.pArg(0,Result);
ClientViewer.pArg(1,time);
end;

procedure TClient.Button2Click(Sender: TObject);
var
_out:string;
begin
     Client.Edit3.Text:=getVersion(123,_out);
     Client.Edit4.text:=_out;
end;

procedure TClient.FormCreate(Sender: TObject);
begin
Initialize('MyCoolDummyAlpcPort');
Connect(nil);
end;

end.
