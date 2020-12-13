unit ALPC_Server;

interface
uses
ALPC_LPC_Define;
type
    ret_Offsets = array[0..$10-1] of Cardinal;
    _ViewCache = packed record
    private type
    offSet = ^TAT;
    TAT = array of Cardinal;
    private
     result:ViewDetail;
    public
    function return(const index:Cardinal):Pointer;overload;
    function return(const index:Cardinal;const data:Pointer;const size:Cardinal):Pointer;overload;
    procedure Marshal(var list:ret_Offsets);
    procedure FillCache(const index:Cardinal;const data:Pointer;const size:Cardinal);
    procedure Sign(const Signal:LongBool);inline;
   end;
     ViewCache = _ViewCache;
     PViewCache = ^ViewCache;

     PReadIn =^ReadIn;
     _ReadIn = packed record
     private type
     TMem = record
     Index:Cardinal;
     OffSet:Integer
     end;
     strict private
     dataSection:array[0..0] of Byte;
     public
     class operator Multiply(V:_ReadIn;const Index:Cardinal) : Pointer;
     class operator Divide(V:_ReadIn;const mem:TMem) : Pointer;
     public
     procedure Push(const data:PViewCache);inline;
     end;
     ReadIn = _ReadIn;
type
TInitialize = function(const serverName:WideString):LongBool of object;
TEvent = procedure of object;
TCallBack = function(const clientViewer, serverViewer: Pointer): LongBool;
//TInvoke  = function(const view:PViewCache;const reader:PReadIn):LongBool;
{$IFNDEF reference}
TPerformer = procedure(const view:PViewCache;const reader:PReadIn);
{$ELSE}
TPerformer = reference to procedure(const view:PViewCache;const reader:PReadIn);
{$ENDIF}
var
Initialize:TInitialize;
StartServer:TEvent;
StopServer:TEvent;
procedure AddFunc(const funcName:String;const FuncAddr:TPerformer);
implementation
uses
  ALPC_Base,SysUtils,HlpIHash,Classes,
  HlpHashFactory,Generics.Collections,Logger;
type

TABC = ViewDetail;

type

  TServer = class(AlpcTransportBase)
  private type
  TCaller = procedure of object;
  Tlauncher = class(TThread)
  strict private
  FN:TCaller;
    public
    constructor Create(const parent:TServer); overload;
    protected
    procedure execute;override;
  end;
  strict private
    running: LongBool;
    handleForClient: THandle;
    FfuncCaller:TCallBack ;
    launcher:Tlauncher;
  strict private
  class function callback(const user,host:Pointer):LongBool;static;
    function CreatePort:LongBool;inline;
    procedure Accept(PContext: Pointer = nil; refuse: LongBool = False);
  protected
    constructor Create; overload;
    destructor Destroy; override;
  public
    function Initialize(const serverName: WideString):LongBool;
    procedure Terminate();
  private
    procedure Listen;
  public
  procedure start;
  procedure stop;
  public
  property funcCaller:TCallBack   write FfuncCaller;
  end;

type
TFunctions = TDictionary<THashTable,TPerformer>;
var
Functions :TFunctions;
Server:TServer;

function SyncSetBool(var Target:LongBool;value:LongBool):Integer;stdcall;
external 'Kernel32.dll' Name 'InterlockedExchange';

function GetHashTable(const funcName:string):AnsiString;
var
    LHash:IHash;
  begin
    LHash:= THashFactory.TCrypto.CreateSHA1;
    Result:=LHash.ComputeString(funcName,TEncoding.UTF8).ToString();
    LHash:=nil;
  end;

procedure AddFunc(const funcName:String;const FuncAddr:TPerformer);
var
funcHash:AnsiString;
begin
  funcHash:=GetHashTable(funcName);
  functions.Add(PHashTable(@(funcHash[1]))^,FuncAddr);
end;

class function TServer.callback(const user,host:Pointer):LongBool;
var
FN:TPerformer;
begin
     Result:=False;
     FN:=Functions[(PViewCache(user).result.location.client.hashTable)];
     try
        if Assigned(FN) then
        FN(user,host);
        Result:=True;
     except
          PViewCache(user).result.location.server.onError:=True;
          Move(Exception(ExceptObject).Message[1],PViewCache(user).result.dataSection,Length(Exception(ExceptObject).Message)*2+2);
     end;
end;

  { TServer }

procedure TServer.Accept(PContext: Pointer = nil; refuse: LongBool = False);
var
  ret: NTSTATUS;
  port_Attr: AlpcPortAttributes;
begin
  handleForClient := 0;
  port_Attr := AlpcPortAttributes.Create;
  try
    port_Attr.Initialize($100, $80000);
    ret := NtAlpcAcceptConnectPort(@(Self.handleForClient), Self.fPortHandle,
      $0, nil, port_Attr.pPortAttrHeader, PContext,
      @(pReciver.Structures.pMsgHeader.Header), nil, not refuse);
  finally
    port_Attr.Terminate;
    port_Attr.Free;
  end;
end;

constructor TServer.Create;
begin
   FfuncCaller:=nil;
end;

function TServer.CreatePort: LongBool;
begin
    Result:=NtAlpcCreatePort(
    @(Self.fPortHandle),
    Self.fObjectAttr.pObjectAttrHeader,
    Self.fPortAttr.pPortAttrHeader
    ) = 0;

end;

destructor TServer.Destroy;
begin
  Self.Terminate;
  inherited;
end;

function TServer.Initialize(const serverName: WideString):LongBool;
begin
  inherited Initialize(serverName, $1000, { custmessagesize }
    $FE000000, { messageFlags }
    $0, $9000, $8, nil, nil);
    Result:=Self.CreatePort;
end;

procedure TServer.start;
begin

      if not Self.running then
      begin
       Assert(launcher = nil);
       launcher:=Tlauncher.Create(Self);
       launcher.Resume;
       Self.running:=True;
      end;
end;

procedure TServer.stop;
begin

  if Self.running then
  begin
   Assert(launcher <> nil);
    SyncSetBool(Self.running,False);
    NtClose(fPortHandle);
    launcher.Terminate;
    launcher.WaitFor;
    FreeAndNil(launcher);
    fPortHandle:=0;
  end;

end;

procedure TServer.Listen;
var
  ret: NTSTATUS;
begin
  if not Assigned(FfuncCaller) then
   FfuncCaller:= TServer.callback;

  Self.CreateCarrier;

  Self.CreateLocalView;
  self.pSender.Attributes.pAttrHeader.Head.ValidAttributes:=ALPC_MESSAGE_VIEW_ATTRIBUTE;
  Self.pSender.Attributes.AssignView(pLocalView);

  while Self.running do
  begin
    ret := NtAlpcSendWaitReceivePort(Self.fPortHandle, $0, nil, nil,
      @Self.pReciver.Structures.pMsgHeader.Header, @fMessageSize,
      Self.pReciver.Attributes.pAttrHeader, nil);
    if ret = 0 then
    begin
      case (Self.pReciver.Structures.pMsgHeader.Header.u2.s2._Type and $FFF) of
        LPC_CONNECTION_REQUEST:
          begin
            Self.Accept;
          end;
            LPC_REQUEST:
          begin
            FfuncCaller(pReciver.Attributes.pAttrContext.View.ViewBase,
              pSender.Attributes.pAttrContext.View.ViewBase);
            ret := NtAlpcSendWaitReceivePort(Self.fPortHandle, $0,
              Self.pSender.Structures.pMsgHeader,
              Self.pSender.Attributes.pAttrHeader, nil, nil, nil, nil);
            if ret <> 0 then
            begin
              { TODO : you need to save the error message}
            end;
          end;
        LPC_LOST_REPLY, LPC_PORT_CLOSED, LPC_CLIENT_DIED:
          begin
            try
              if handleForClient <> 0 then
                NtClose(handleForClient);
            except

            end;
          end;
      else
        begin

        end;
      end;
    end
   else
    begin
      if ret <> Integer($C0000700) then
      Exception.Create(Exception(ExceptObject).Message);
    end;
  end;
end;



procedure TServer.Terminate;
begin
       Self.stop;
       inherited Terminate;
end;



{ ReadIn }

class operator _ReadIn.Divide(V: _ReadIn; const mem: TMem): Pointer;
begin
   Result:= PByte(@V) + PCardinal(PByte(@V) + 4*mem.Index)^ + mem.OffSet;
end;

class operator _ReadIn.Multiply(V: _ReadIn; const Index: Cardinal): Pointer;
begin
   Result:= PByte(@V) + PCardinal(PByte(@V) + 4*Index)^;
end;

procedure _ReadIn.Push(const data: PViewCache);
begin
       Move(data.result.dataSection[0],Self.dataSection[0],Data.result.activeDataSize);
end;

{ TServer.Tlauncher }

constructor TServer.Tlauncher.Create(const parent:TServer);
begin
  inherited Create(False);
  FN:=parent.Listen;
end;

procedure TServer.Tlauncher.execute;
begin
  inherited;
  FreeOnTerminate:=False;
  FN;
end;

{ _ViewCache }

procedure _ViewCache.FillCache(const index: Cardinal; const data: Pointer;
  const size: Cardinal);
var
startAddr:PByte;
begin
   startAddr:=@(Self.result.dataSection[0]);
   PCardinal(startAddr +  offset(startAddr)^[index])^:= Self.result.activeDataSize;
   PCardinal(startAddr +  offset(startAddr)^[index] + 4)^:=size;
   Move(data^,(startAddr + Self.result.activeDataSize)^,size);
   Inc(Self.result.activeDataSize,size);
end;

procedure _ViewCache.Marshal(var list: ret_Offsets);
var
startAddr:PByte;
I:Cardinal;
begin
         startAddr:=@(Self.result.dataSection[0]);
         offset(startAddr)^[0]:=list[0]*4;
         for I := 1 to list[0] - 1 do
         begin
              offSet(startAddr)^[I]:=offSet(startAddr)^[I - 1] + list[I - 1];
         end;
         Self.result.activeDataSize:= offSet(startAddr)^[I - 1] + list[I - 1];

end;


function _ViewCache.return(const index: Cardinal): Pointer;
var
startAddr:PByte;
begin
         startAddr:=@(Self.result.dataSection[0]);
         result:=startAddr +offset(startAddr)^[index];
end;

function _ViewCache.return(const index: Cardinal; const data: Pointer;
  const size: Cardinal): Pointer;
begin
          result:= return(index);
          Move(data,result,size);
end;

procedure _ViewCache.Sign(const Signal: LongBool);
begin
     Self.result.location.server.onError:=Signal;
end;

initialization
Functions:=TFunctions.Create;
Server:=TServer.Create;
Initialize:=Server.Initialize;
StartServer:=Server.start;
StopServer:=Server.stop;
finalization
Functions.Free;
Server.Free;

end.
