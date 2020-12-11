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

function sum(const a:Integer{a = 1};const b:Integer{b = 3}):Integer;
var
P:PViewCache;
begin
        P:=ClientViewer;
        p.Initialize;
        P.SetID(1);
        P.Push(@a,4);
        p.Push(@b,4);
        p.Finalize;
        Log(IntToHex(Cardinal(P),8));
        Log(IntToHex(Cardinal(@(P.dataSection[0])),8));
        Invoke;
        P:=ServerViewer;
        if P.location.server.onError = False then
        begin
          Result:=Pinteger(P.return(0))^;
        end
        else
        begin
          Exception.Create(PAnsiChar(P.return(0)));
        end;
end;

function change(const a:Integer;var b:Integer;out c:Double):Integer;
var
P:PViewCache;
begin

end;

procedure TClient.Button1Click(Sender: TObject);
var
auth:TAuth;
a,b:Integer;
begin
a:=StrToInt(Edit1.Text);
b:=StrToInt(Edit2.Text);
ShowMessage(Edit1.Text + ' + ' + Edit2.Text + ' = ' + IntToStr(sum(a,b)));
end;



procedure TClient.FormCreate(Sender: TObject);
begin
Initialize('MyCoolDummyAlpcPort');
Connect(nil);
end;

end.
