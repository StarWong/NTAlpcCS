unit ALPC_Server;

interface

uses
  ALPC_LPC_Define;

{$I TParameter.Inc}
{$I ViewHeader.Inc}
{$I StubViewerHeader.Inc}

  type
    TInitialize = function(const serverName: WideString): LongBool of object;
    TEvent = procedure of object;
    TCallBack = function(const clientViewer, ServerArgSenderer: Pointer): LongBool;
    // TInvoke  = function(const view:PServerArgSender;const reader:PReadIn):LongBool;
{$IFNDEF reference}
    TPerformer = procedure(const view: PStubViewer; const reader: PStubViewer);
{$ELSE}
    TPerformer = reference to procedure(const view: PServerArgSender;
      const reader: PReadIn);
{$ENDIF}

  var
    Initialize: TInitialize;
    StartServer: TEvent;
    StopServer: TEvent;
    procedure AddFunc(const funcName: String; const FuncAddr: TPerformer);

procedure Register;

implementation

uses
  ALPC_Base, SysUtils, Classes,
  SHA1, Generics.Collections, Logger;



type

  TServer = class(AlpcTransportBase)
  private type
    TCaller = procedure of object;

    Tlauncher = class(TThread)
    strict private
      FN: TCaller;
    public
      constructor Create(const parent: TServer); overload;
    protected
      procedure execute; override;
    end;
  strict private
    running: LongBool;
    handleForClient: THandle;
    FfuncCaller: TCallBack;
    launcher: Tlauncher;
  strict private
    class function callback(const user, host: Pointer): LongBool; static;
    function CreatePort: LongBool; inline;
    procedure Accept(PContext: Pointer = nil; refuse: LongBool = False);
  protected
    constructor Create; overload;
    destructor Destroy; override;
  public
    function Initialize(const serverName: WideString): LongBool;
    procedure Terminate();
  private
    procedure Listen;
  public
    procedure start;
    procedure stop;
  public
    property funcCaller: TCallBack write FfuncCaller;
  end;

type
  TFunctions = TDictionary<THashTable, TPerformer>;

var
  Functions: TFunctions;
  Server: TServer;

function SyncSetBool(var Target: LongBool; value: LongBool): Integer; stdcall;
external 'Kernel32.dll' Name 'InterlockedExchange';

class function TServer.callback(const user, host: Pointer): LongBool;
var
  FN: TPerformer;
begin
  result := False;
  //PStubViewer(user).Sign(False);
  try
   if Functions.ContainsKey(PStubViewer(user).GetFuncID) then
   FN := Functions[PStubViewer(user).GetFuncID]
   else
   begin
   PStubViewer(user).PushErrMessage('func not found!');
   PStubViewer(user).Sign(False);
   Exit;
   end;
    if Assigned(FN) then
    begin
      FN(user, host);
    result := True;
    PStubViewer(user).Sign(True);
    Exit;
    end
    else
    begin
     PStubViewer(user).PushErrMessage('func addr is nil!');
     PStubViewer(user).Sign(False);
     Exit;
    end;
  except
    PStubViewer(user).PushErrMessage(Exception(ExceptObject).Message[1]);
    PStubViewer(user).Sign(False);
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
   // Printf('accpet');
  finally
    port_Attr.Terminate;
    port_Attr.Free;
  end;
end;

constructor TServer.Create;
begin
  FfuncCaller := nil;
end;

function TServer.CreatePort: LongBool;
begin
  result := NtAlpcCreatePort(@(Self.fPortHandle),
    Self.fObjectAttr.pObjectAttrHeader, Self.fPortAttr.pPortAttrHeader) = 0;

end;

destructor TServer.Destroy;
begin
  Self.Terminate;
  inherited;
end;

function TServer.Initialize(const serverName: WideString): LongBool;
begin
  inherited Initialize(serverName, $1000, { custmessagesize }
    $FE000000, { messageFlags }
    $0, $9000, $8, nil, nil);
  result := Self.CreatePort;
end;

procedure TServer.start;
begin

  if not Self.running then
  begin
    Assert(launcher = nil);
    launcher := Tlauncher.Create(Self);
    launcher.Resume;
    Self.running := True;
  end;
end;

procedure TServer.stop;
begin

  if Self.running then
  begin
    Assert(launcher <> nil);
    SyncSetBool(Self.running, False);
    NtClose(fPortHandle);
    launcher.Terminate;
    launcher.WaitFor;
    FreeAndNil(launcher);
    fPortHandle := 0;
  end;

end;

procedure TServer.Listen;
var
  ret: NTSTATUS;
begin
  if not Assigned(FfuncCaller) then
    FfuncCaller := TServer.callback;

  Self.CreateCarrier;

  Self.CreateLocalView;
  Self.pSender.Attributes.pAttrHeader.Head.ValidAttributes := $0;
   // ALPC_MESSAGE_VIEW_ATTRIBUTE;
  Self.pSender.Attributes.AssignView(pLocalView);
  Self.pSender.Structures.Zero(PORT_MESSAGE_SIZE);
  while Self.running do
  begin
    ret := NtAlpcSendWaitReceivePort(Self.fPortHandle, $0, nil, nil,
      Self.pReciver.Structures.pMsgHeader, @fMessageSize,
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
            FfuncCaller(pReciver.Attributes.pAttrContext.view.ViewBase,
              pSender.Attributes.pAttrContext.view.ViewBase);
              pSender.Structures.pMsgHeader.Header.MessageId:=
              pReciver.Structures.pMsgHeader.Header.MessageId;
              ret := NtAlpcSendWaitReceivePort(Self.fPortHandle, $0,
              Self.pSender.Structures.pMsgHeader,
              Self.pSender.Attributes.pAttrHeader, nil, nil, nil, nil);
            if ret <> 0 then
            begin
              Printf(ret, 8, 'failed->ret:');
            end;
          end;
        LPC_LOST_REPLY, LPC_PORT_CLOSED, LPC_CLIENT_DIED:
          begin
            try
             // Printf('close');
              if handleForClient <> 0 then
              begin
                NtClose(handleForClient);
                handleForClient := 0;
              end;
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



{ TServer.Tlauncher }

constructor TServer.Tlauncher.Create(const parent: TServer);
begin
  inherited Create(False);
  FN := parent.Listen;
end;

procedure TServer.Tlauncher.execute;
begin
  inherited;
  FreeOnTerminate := False;
  FN;
end;

{$I StubViewerBody.Inc}

procedure AddFunc(const funcName: String; const FuncAddr: TPerformer);
var
  funcHash: AnsiString;
begin
  funcHash := GetHashTable(funcName);
  Functions.Add(PHashTable(@(funcHash[1]))^, FuncAddr);
end;

procedure Register;
begin
  Classes.RegisterComponents('NtAlpc', [TServer]);
end;

initialization

Functions := TFunctions.Create;
Server := TServer.Create;
Initialize := Server.Initialize;
StartServer := Server.start;
StopServer := Server.stop;

finalization

Functions.Free;
Server.Free;

end.

