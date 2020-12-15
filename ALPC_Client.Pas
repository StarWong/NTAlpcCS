unit ALPC_Client;
interface
uses
ALPC_LPC_Define;
type
TAuth = record
Key:UInt64;
FnPathID:Cardinal;
end;
PAuth = ^TAuth;

{$I TParameter.Inc}
{$I ViewHeader.Inc}
{$I StubViewerHeader.Inc}

TInitialize = procedure(const serverName:WideString) of object;
TTerminate = procedure() of object;
TConnect = function(const Auth:PAuth):Integer of object;
TViewer = function:PStubViewer of object;
TInvoke = procedure of object;
var
Initialize:TInitialize;
//Terminate:TTerminate;
Connect:TConnect;
ClientViewer:TViewer;
ServerViewer:TViewer;
Invoke:TInvoke;

implementation
uses ALPC_Base,SHA1,SysUtils,Classes;
type

TClient = class(AlpcTransportBase)
protected
constructor Create(); overload;
destructor Destroy; override;
public
procedure Initialize(const serverName:WideString);
procedure Terminate();
function Connect(const Auth:PAuth):NTSTATUS;
public
function ReturnClientViewAddr:PStubViewer;
function ReturnServerViewAddr:PStubViewer;
procedure Invoke;
end;
{ TClient }

TDataInfo = record
  addr:Pointer;
  size:Cardinal;
  IsPointer:LongBool;
end;
PDataInfo = ^TDataInfo;



const
{$J+}
baseOffSet:Integer = 0;
{$J-}
var
Client:TClient;

procedure Abort;
begin
  raise TObject.Create;
end;

function Inc_P(p:Pointer;offset:Int64):Pointer;inline;
begin
       Result:=pbyte(P) + offset;
end;



function TClient.Connect(const Auth: PAuth): NTSTATUS;
begin

    CreateCarrier();

    if Auth <> nil then
    begin
    fMessageSize:=pSender.Structures.Zero(PORT_MESSAGE_SIZE+pSender.Structures.fDataCacheHeaderSize);
     Move(Auth^,pSender.Structures.pMsgContext.head.info.Auth,SizeOf(TAuth));
     pReciver.Structures.Zero();
     Result:= NtAlpcConnectPort(
       @fPorthandle,
       pPortName,
       nil,
       fPortAttr.pPortAttrHeader,
       ALPC_MSGFLG_SYNC_REQUEST,
       nil,
       @pSender.Structures.pMsgHeader.Header,
       @fMessageSize,
       pSender.Attributes.pAttrHeader,
       pReciver.Attributes.pAttrHeader,
       nil
       );
    end
    else
    begin
    fMessageSize:=pSender.Structures.Zero(PORT_MESSAGE_SIZE);
    Result:=NtAlpcConnectPort(
    @fPorthandle,
    pPortName,
    nil,
    fPortAttr.pPortAttrHeader,
    ALPC_MSGFLG_SYNC_REQUEST,
    nil,
    @pSender.Structures.pMsgHeader.Header,{datasize must be zero!}
    @fMessageSize,
    nil,
    nil,
    nil
     );
    end;
    if Result = NTSTATUS_SUCC then
    begin
       Result:=CreateLocalView();
       pSender.Attributes.pAttrHeader.Head.ValidAttributes:=ALPC_MESSAGE_VIEW_ATTRIBUTE;
       pSender.Attributes.AssignView(pLocalView);
    end;
end;

constructor TClient.Create();
begin

end;

destructor TClient.Destroy();
begin
       Self.Terminate();
end;

procedure TClient.Initialize(const serverName: WideString);
begin
    inherited Initialize(
    serverName,
    $1000,
    $FE000000,
    $10000,
    $9000,
    $8,
    nil,
    nil
    );
end;

procedure TClient.Invoke;
var
ret:NTSTATUS;
begin
   pSender.Structures.Zero(PORT_MESSAGE_SIZE);
   pReciver.Structures.Zero(PORT_MESSAGE_SIZE);
   ret:= NtAlpcSendWaitReceivePort(
    fPortHandle,
    $20000,
    pSender.Structures.pMsgHeader,
    pSender.Attributes.pAttrHeader,
    pReciver.Structures.pMsgHeader,
    @fMessageSize,
    pReciver.Attributes.pAttrHeader,
    nil);
    if ret <> NTSTATUS_SUCC then Abort;
end;

function TClient.ReturnClientViewAddr: PStubViewer;
begin
Result:=pSender.Attributes.pAttrContext.View.ViewBase;
end;

function TClient.ReturnServerViewAddr: PStubViewer;
begin
Result:=pReciver.Attributes.pAttrContext.View.ViewBase;
end;

procedure TClient.Terminate;
begin
inherited Terminate();
end;

{$I StubViewerBody.Inc}



initialization
Client:=TClient.Create();
Initialize:=Client.Initialize;
//Terminate:=Client.Terminate;
Connect:=Client.Connect;
ClientViewer:=Client.ReturnClientViewAddr;
ServerViewer:=Client.ReturnServerViewAddr;
Invoke:=Client.Invoke;
finalization
if Client <> nil then Client.Free();
end.