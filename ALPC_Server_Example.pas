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
host.DecodeDynamicData;
user.Marshal.count:=1;
user.Marshal.Arg[0].isPointer:=False;
user.Marshal.Arg[0].staticData.Integer:=sum(host.pArg(0).Integer,host.pArg(1).Integer);
user.EncodeDynamicData;
end;

procedure getVersion(const user:PStubViewer;const host:PStubViewer);
function  getVersion(const count:Integer;out time:string):string;
begin
   Result:='sucessful';
   time:=IntToStr(count);
end;
var
ret:string;
_out:string;
begin
user.FillServerCache(host);//save data to host
host.DecodeDynamicData;
user.Marshal.count:=2;
ret:=getVersion(host.pArg(0).Integer,_out);
user.Marshal.Arg[0].isPointer:=True;
user.Marshal.Arg[0].dynamicData.addr:=@ret[1];
user.Marshal.Arg[0].dynamicData.dataSize:=(Length(ret)+1)*2;
user.Marshal.Arg[1].isPointer:=True;
user.Marshal.Arg[1].dynamicData.addr:=@_out[1];
user.Marshal.Arg[1].dynamicData.dataSize:=(Length(_out)+1)*2;
user.EncodeDynamicData;
end;


initialization
AddFunc('sum',sum);
AddFunc('getVersion',getVersion);
end.
