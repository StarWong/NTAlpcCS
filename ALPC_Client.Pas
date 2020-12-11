unit ALPC_Client;
interface
type
TAuth = record
Key:UInt64;
FnPathID:Cardinal;
end;
PAuth = ^TAuth;




    _ViewCache = packed record

     activeDataSize:Cardinal;

     location : packed record
     case Integer of
     0:
     (
      client : packed record
      functionID:Cardinal;
      end;
     );
     1:
     (
      server : packed record
      onError:LongBool;
      end;
     )
     end;
     dataSection:array[0..0] of Byte;
     {$REGION 'Methods Client'}
     procedure SetID(const functionID:Cardinal);
     procedure Push(addr:Pointer;size:Cardinal;IsPointer:LongBool = False);overload;
     procedure Initialize;
     procedure Finalize;
     {$ENDREGION}
     {$REGION 'Methods Server'}

     {$ENDREGION}
     function return(index:Cardinal):Pointer;
     end;


     ViewCache = _ViewCache;
     PViewCache = ^ViewCache;

TInitialize = procedure(const serverName:WideString) of object;
TTerminate = procedure() of object;
TConnect = function(const Auth:PAuth):Integer of object;
TViewer = function:Pointer of object;
TInvoke = procedure of object;
var
Initialize:TInitialize;
//Terminate:TTerminate;
Connect:TConnect;
ClientViewer:TViewer;
ServerViewer:TViewer;
Invoke:TInvoke;
implementation
uses ALPC_Base,ALPC_LPC_Define;
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
function ReturnClientViewAddr():Pointer;
function ReturnServerViewAddr():Pointer;
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

in_List:array[0..$F] of TDataInfo;  //Max 15 arguments with in

procedure Abort;
begin
  raise TObject.Create;
end;

function Inc_P(p:Pointer;offset:Int64):Pointer;inline;
begin
       Result:=pbyte(P) + offset;
end;

function _ViewCache.return(index:Cardinal):Pointer;
var
P:array of Cardinal;
begin
       P:=@(Self.dataSection[0]);
       Result:=PByte(P) + P[index];
end;

procedure _ViewCache.Push(addr:Pointer;size:Cardinal;IsPointer:LongBool = False);
begin
         in_List[PInteger(@in_List[0])^+1].addr:=addr;
         in_List[PInteger(@in_List[0])^+1].size:=size;
         in_List[PInteger(@in_List[0])^+1].IsPointer:=IsPointer;
         Inc(PInteger(@in_List[0])^);
end;



procedure _ViewCache.Initialize;
begin
       Self.activeDataSize:=0;
       PInteger(@in_List[0])^:=0; //reset in counts
end;

procedure _ViewCache.Finalize;
var
I:Integer;
P:array of Cardinal;
begin
if PCardinal(@in_List[0])^ > 0 then
begin
P:= @(Self.dataSection[0]);
P[0]:=PCardinal(@in_List[0])^*4;
if in_List[1].IsPointer then
begin
 Move(in_List[1].size,(PByte(P) + P[0])^,4); //move size value to cache
 Move(PPointer(in_List[1].addr)^,(PByte(P) + P[0] + 4)^,in_List[1].size); //move PPointer^'s value
 Inc(in_List[1].size,4); // add the size of pointer
end
else
Move(in_List[1].addr^,(PByte(P) + P[0])^,in_List[1].size);

for I := 1 to PInteger(@in_List[0])^ - 1 do
begin
     P[I]:=P[I-1] + in_List[I].size;
     if in_List[I].IsPointer then
     begin
     Move(in_List[I+1].size,(PByte(P) + P[I])^,4); //move size value to cache
     Move(PPointer(in_List[I+1].addr)^,(PByte(P) + P[I] + 4)^,in_List[I+1].size); //move PPointer^'s value
     Inc(in_List[I+1].size,4);    // add the size of pointer
     end
     else
     begin
     Move(in_List[I+1].addr^,(PByte(P) + P[I])^,in_List[I+1].size);
     end;
end;
    Self.activeDataSize:= P[I - 1] + in_List[I].size;
end;

end;

procedure _ViewCache.SetID(const functionID:Cardinal);
begin
  Self.location.client.functionID:=functionID;
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

function TClient.ReturnClientViewAddr: Pointer;
begin
Result:=pSender.Attributes.pAttrContext.View.ViewBase;
end;

function TClient.ReturnServerViewAddr: Pointer;
begin
Result:=pReciver.Attributes.pAttrContext.View.ViewBase;
end;

procedure TClient.Terminate;
begin
inherited Terminate();
end;

function GetBaseOffSet:Integer;
var
V:_ViewCache;
begin
  baseOffSet:=UINT64(@(V.dataSection)) - UINT64(@V);
end;


initialization
Client:=TClient.Create();
Initialize:=Client.Initialize;
//Terminate:=Client.Terminate;
Connect:=Client.Connect;
ClientViewer:=Client.ReturnClientViewAddr;
ServerViewer:=Client.ReturnServerViewAddr;
Invoke:=Client.Invoke;
GetBaseOffSet;
finalization
if Client <> nil then Client.Free();
end.