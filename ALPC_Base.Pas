unit ALPC_Base;
interface
uses SysUtils,Classes,ALPC_LPC_Define;
type
{$IFDEF CPUX64}
TAignValue = UInt64;
{$ELSE}
TAignValue = Cardinal;
{$ENDIF}
TBlock = array of TAignValue;
{$REGION 'MessageStructures'}
MessageStructures = class
strict private
fBlock:TBlock;//Buffer
public
pMsgHeader:PALPC_CUSTOM_MESSAGE;
pMsgContext:PDataCache;
fMsgbufferSize,fDataCacheHeaderSize:Word;
public
function Initialize(const totalSize:ULONG):Boolean;
procedure Terminate();
function Zero(activeSize:ULONG = 0):ULONG;
end;
{$ENDREGION}

{$REGION 'AlpcMessageAttributes'}
_ALPC_MESSAGE_ATTRIBUTES_CONTEXT = record
//Flags:ULONG;
SECURITY:PALPC_SECURITY_ATTR;
View:PALPC_DATA_VIEW_ATTR;
CONTEXT:PALPC_CONTEXT_ATTR;
HANDLE:PALPC_HANDLE_ATTR;
TOKEN:PALPC_TOKEN_ATTR;
DIRECT:PALPC_DIRECT_ATTR;
WORK_ON_BEHALF:PALPC_WORK_ON_BEHALF_ATTR;
end;
PALPC_MESSAGE_ATTRIBUTES_CONTEXT = ^ALPC_MESSAGE_ATTRIBUTES_CONTEXT;
ALPC_MESSAGE_ATTRIBUTES_CONTEXT = _ALPC_MESSAGE_ATTRIBUTES_CONTEXT;
AlpcMessageAttributes = class
strict private
fBlock:TBlock;
fMsgAttrBufferSize:ULONG;
public
pAttrHeader:PALPC_MESSAGE_ATTRIBUTES;
pAttrContext:PALPC_MESSAGE_ATTRIBUTES_CONTEXT;
protected
function Initialize(const attrFlags:ULONG):Boolean;
procedure Terminate();
strict private
function AllocateFlags(const attrFlags:ULONG):Boolean;
public
procedure AssignView(const view:PALPC_DATA_VIEW_ATTR);
end;
{$ENDREGION}

{$REGION 'TAlpcCarrier'}

TAlpcCarrier = class
strict private
StructCls:MessageStructures;
AttrCls:AlpcMessageAttributes;
public
 pMsgAttrContext:PALPC_MESSAGE_ATTRIBUTES_CONTEXT;
public
constructor Create(const customMessageSize:Word;const MsgAttrAllocatedFlags:ULONG);overload;
destructor Destroy();override;
public
procedure Push(const pSenderContext:PDataCache;DataSizeOfQuotaIfNotUseView:ULONG = $100);
procedure Pop(const pReceiverContext:PDataCache);
procedure Push_V2(const pSenderContext:PViewCache); //Pure view
procedure Pop_V2(const pReceiverContext:PViewCache); //Pure view
public
property Structures:MessageStructures  read StructCls;
property Attributes:AlpcMessageAttributes read AttrCls;
end;
{$ENDREGION}

{$REGION 'AlpcPortAttributes'}
 AlpcPortAttributes = class
 public
pPortAttrHeader:PALPC_PORT_ATTRIBUTES;
 public
procedure Initialize(const messageSize:Word;const portflags:ULONG);
procedure Terminate();
 end;
{$ENDREGION}

{$REGION 'ObjectAttributes'}
ObjectAttributes = class
public
pObjectAttrHeader:POBJECT_ATTRIBUTES;
public
procedure Initialize(const portName:PUNICODE_STRING);
procedure Terminate();
end;
{$ENDREGION}

{$REGION 'AlpcTransportBase'}
AlpcTransportBase = class(TComponent)
strict private
class var fBlock:TBlock;
class var fSectionHandle:HANDLE;
class var fAllocatedSectionSize:SIZE_T;
class var fDataSizeOfQuotaIfNotUseView:Word;
class var fMsgAttrAllocatedFlags:ULONG;
protected
class var fPortAttr:AlpcPortAttributes;
class var fObjectAttr:ObjectAttributes;
protected
class var pSender:TAlpcCarrier;
class var pReciver:TAlpcCarrier;
protected
class var fPortHandle:HANDLE;
class var pPortName:PUNICODE_STRING;
class var pLocalView:PALPC_DATA_VIEW_ATTR;
class var fMessageSize:SIZE_T;
protected
class function CreateLocalView(viewFlag:ULONG = $0):NTSTATUS;
class procedure RTL_CONSTANT_STRING(const serverName:WideString;const portName:PUNICODE_STRING);
class procedure Initialize(
const serverName:WideString;
customMessageSize:Cardinal;
messageAttributesAllocatedFlags:Cardinal;
portFlags:Cardinal;
allocatedSectionSize:SIZE_T;
dataSizeOfQuotaIfNotUseView:Word;
objectAttr:POBJECT_ATTRIBUTES;
portAttr:PALPC_PORT_ATTRIBUTES
);
class procedure Terminate();
class procedure CreateCarrier();
class function Send_Recv(
const pSenderContext:PDataCache;
const pReceiverContext:PDataCache;
pTime:PLARGE_INTEGER = nil
):NTSTATUS;
class function Recv(
const pReceiverContext:PDataCache;
pTime:PLARGE_INTEGER = nil
):NTSTATUS;
class function Send(
const pSenderContext:PDataCache;
pTime:PLARGE_INTEGER
):NTSTATUS;

class function NewMem(const totalSize:ULONG;var fBlock:TBlock):Boolean;static;
end;

{$ENDREGION}

implementation

function NewMem(const totalSize:ULONG;var fBlock:TBlock):Boolean;inline;
var
arrLen,remainder,size:ULONG;
begin
        Result:=False;
        size:=  SizeOf(TAignValue);
        remainder:=totalSize mod size;
        arrLen:=Trunc((totalSize - remainder)/size);
        if remainder <> 0 then   Inc(arrLen);
        SetLength(fBlock,arrLen);
        if fBlock = nil then Exit;;
        {$IFNDEF CPUX64}
        if ((uint32_t(fBlock) mod 4) <> 0) then  Exit;
        {$ELSE}
        if ((uint64_t(fBlock) mod 8) <> 0) then  Exit;
        {$ENDIF}
        Result:=True;
end;

procedure FreeMem(var fBlock:TBlock);inline;
begin
   if fBlock <> nil then SetLength(fBlock,0);
end;

{ MessageStructures }

function MessageStructures.Initialize(const totalSize: ULONG): Boolean;
begin
       Result:=False;
       fDataCacheHeaderSize:=SizeOf(DataCache);
       if SizeOf(PORT_MESSAGE) <> PORT_MESSAGE_SIZE then Exit;
       fMsgbufferSize:=totalSize;
       if not NewMem(fMsgbufferSize,fBlock) then Exit;
       pMsgHeader:=@fBlock[0];
       pMsgContext:=@pMsgHeader.Buffer[0];
       Result:=True;
end;

procedure MessageStructures.Terminate();
begin
       FreeMem(fBlock);
end;


function MessageStructures.Zero(activeSize:ULONG = 0):ULONG;
begin
   if ((activeSize = 0) or (activeSize > fMsgbufferSize))  then Result:=fMsgbufferSize
   else
   Result:=activeSize;
   if Result < PORT_MESSAGE_SIZE then  Result:= PORT_MESSAGE_SIZE;

      FillChar(fBlock[0],Result,#0);
      pMsgHeader.Header.u1.s1.DataLength:=Result - PORT_MESSAGE_SIZE;
      pMsgHeader.Header.u1.s1.TotalLength:=Result;
end;

{ AlpcMessageAttributes }

function AlpcMessageAttributes.Initialize(const attrFlags:ULONG):Boolean;
begin
   Result:=False;
   fMsgAttrBufferSize:=AlpcGetHeaderSize(attrFlags);
   if fMsgAttrBufferSize = 0 then Exit;
   if not NewMem(fMsgAttrBufferSize,fBlock) then  Exit;
   pAttrHeader:=@fBlock[0];
   pAttrContext:=@(pAttrHeader.Buffer[0]);
   {
  if  AlpcInitializeMessageAttribute(
   attrFlags,
   pAttrHeader.Head,
   fMsgAttrBufferSize,
   fMsgAttrBufferSize
   ) <> NTSTATUS_SUCC then Exit;
   }
   //pAttrHeader.Head.ValidAttributes:=ALPC_MESSAGE_VIEW_ATTRIBUTE;
   AllocateFlags(attrFlags);
   Result:=True;
end;

procedure AlpcMessageAttributes.Terminate();
begin
   FreeMem(fBlock);
end;

procedure AlpcMessageAttributes.AssignView(const view:PALPC_DATA_VIEW_ATTR);
begin
            if pAttrContext.View <> nil then
            begin
              pAttrContext.View.Flags:=0;
              pAttrContext.View.SectionHandle:=view.SectionHandle;
              pAttrContext.View.ViewBase:=view.ViewBase;
              pAttrContext.View.ViewSize:=view.ViewSize;
            end;

end;

function AlpcMessageAttributes.AllocateFlags(const attrFlags:ULONG):Boolean;
var
current:UInt64;
begin
  pAttrHeader.Head.AllocatedAttributes:=attrFlags;
 if  AlpcInitializeMessageAttribute(attrFlags,pAttrHeader.Head,fMsgAttrBufferSize,fMsgAttrBufferSize) <> NTSTATUS_SUCC then Exit(False);
  current:=Uint64(@fBlock[0])+SizeOf(ALPC_MESSAGE_ATTRIBUTES_HEAD);
  {1:ALPC_SECURITY_ATTR}
  IF  (ALPC_MESSAGE_SECURITY_ATTRIBUTE and attrFlags) = ALPC_MESSAGE_SECURITY_ATTRIBUTE then
     begin
     pAttrContext.SECURITY:=PALPC_SECURITY_ATTR(current);
     Inc(current,SizeOf(ALPC_SECURITY_ATTR));
     end;
  {2:ALPC_DATA_VIEW_ATTR}
  IF  (ALPC_MESSAGE_VIEW_ATTRIBUTE and attrFlags) = ALPC_MESSAGE_VIEW_ATTRIBUTE then
     begin
     pAttrContext.View:=PALPC_DATA_VIEW_ATTR(current);
     Inc(current,Sizeof(ALPC_DATA_VIEW_ATTR));
     end;
  {3:ALPC_CONTEXT_ATTR}
  IF  (ALPC_MESSAGE_CONTEXT_ATTRIBUTE and attrFlags) = ALPC_MESSAGE_CONTEXT_ATTRIBUTE then
     begin
     pAttrContext.CONTEXT:=PALPC_CONTEXT_ATTR(current);
     Inc(current,Sizeof(ALPC_CONTEXT_ATTR));
     end;
  {4:ALPC_HANDLE_ATTR}
  IF  (ALPC_MESSAGE_HANDLE_ATTRIBUTE and attrFlags) = ALPC_MESSAGE_HANDLE_ATTRIBUTE then
     begin
     pAttrContext.HANDLE:=PALPC_HANDLE_ATTR(current);
     Inc(current,Sizeof(ALPC_HANDLE_ATTR));
     end;
  {5:ALPC_TOKEN_ATTR}
  IF  (ALPC_MESSAGE_TOKEN_ATTRIBUTE and attrFlags) = ALPC_MESSAGE_TOKEN_ATTRIBUTE then
     begin
     pAttrContext.TOKEN:=PALPC_TOKEN_ATTR(current);
     Inc(current,Sizeof(ALPC_TOKEN_ATTR));
     end;
  {6:ALPC_DIRECT_ATTR}
  IF  (ALPC_MESSAGE_DIRECT_ATTRIBUTE and attrFlags) = ALPC_MESSAGE_DIRECT_ATTRIBUTE then
     begin
     pAttrContext.DIRECT:=PALPC_DIRECT_ATTR(current);
     Inc(current,Sizeof(ALPC_DIRECT_ATTR));
     end;
  {7:ALPC_WORK_ON_BEHALF_ATTR}
  IF  (ALPC_MESSAGE_WORK_ON_BEHALF_ATTRIBUTE and attrFlags) = ALPC_MESSAGE_WORK_ON_BEHALF_ATTRIBUTE then
     begin
     pAttrContext.WORK_ON_BEHALF:=PALPC_WORK_ON_BEHALF_ATTR(current);
     Inc(current,Sizeof(ALPC_WORK_ON_BEHALF_ATTR));
     end;
     Result:=True;
end;


{ TAlpcCarrier }

constructor TAlpcCarrier.Create(const customMessageSize: Word;
  const MsgAttrAllocatedFlags: ULONG);
begin;
       StructCls:=MessageStructures.Create;
       StructCls.Initialize(customMessageSize);
       AttrCls:=AlpcMessageAttributes.Create;
       AttrCls.Initialize(MsgAttrAllocatedFlags);
end;



destructor TAlpcCarrier.Destroy;
begin

     StructCls.Terminate();
     Self.Structures.Free;

     AttrCls.Terminate();
     AttrCls.Free;

    inherited;
end;



procedure TAlpcCarrier.Pop(const pReceiverContext: PDataCache);
begin
     if Structures.pMsgContext.head.useview then
     begin
        Move(Structures.pMsgContext^,pReceiverContext^,Structures.fDataCacheHeaderSize);
        Move(AttrCls.pAttrContext.View.ViewBase^,pReceiverContext.buffer,Structures.pMsgContext.head.datasize);
     end
     else
     begin
        Move(Structures.pMsgContext^,pReceiverContext^,Structures.pMsgContext.head.datasize + Structures.fDataCacheHeaderSize);
     end;
end;

procedure TAlpcCarrier.Pop_V2(const pReceiverContext: PViewCache); //pure view
begin
     Move(AttrCls.pAttrContext.View.ViewBase^,pReceiverContext^,PViewCache(AttrCls.pAttrContext.View.ViewBase).activeDataSize);
end;

procedure TAlpcCarrier.Push(const pSenderContext: PDataCache;
  DataSizeOfQuotaIfNotUseView: ULONG);
begin
     FillChar(Structures.pMsgHeader^,PORT_MESSAGE_SIZE,#0);
     Structures.pMsgHeader.Header.MessageId:=pSenderContext.head.messageID;
     if pSenderContext.head.datasize > DataSizeOfQuotaIfNotUseView then
     begin
       pSenderContext.head.useview:=True;
       Structures.pMsgHeader.Header.u1.s1.DataLength:=Structures.fDataCacheHeaderSize;
       Structures.pMsgHeader.Header.u1.s1.TotalLength:=Structures.pMsgHeader.Header.u1.s1.DataLength + PORT_MESSAGE_SIZE;
       Move(pSenderContext^,Structures.pMsgContext^,Structures.fDataCacheHeaderSize);
       Move(pSenderContext.buffer,pMsgAttrContext.View.ViewBase^,pSenderContext.head.datasize);
     end
     else
     begin
        pSenderContext.head.useview:=False;
        Structures.pMsgHeader.Header.u1.s1.DataLength:=Structures.fDataCacheHeaderSize + pSenderContext.head.datasize;
        Structures.pMsgHeader.Header.u1.s1.TotalLength:=Structures.pMsgHeader.Header.u1.s1.DataLength + PORT_MESSAGE_SIZE;
        Move(pSenderContext^,Structures.pMsgContext^,Structures.fDataCacheHeaderSize + pSenderContext.head.datasize);
     end;

end;

procedure TAlpcCarrier.Push_V2(const pSenderContext:PViewCache);  //pure view
begin
    FillChar(Structures.pMsgHeader^,PORT_MESSAGE_SIZE,#0);
    Structures.pMsgHeader.Header.u1.s1.DataLength:=$0;
    Structures.pMsgHeader.Header.u1.s1.TotalLength:= Structures.pMsgHeader.Header.u1.s1.DataLength + PORT_MESSAGE_SIZE;
    {copy data to cache ,from addr:pSenderContext}
    move(pSenderContext^,AttrCls.pAttrContext.View.ViewBase^,pSenderContext.activeDataSize);

end;

{ AlpcPortAttributes }

procedure AlpcPortAttributes.Initialize(const messageSize:Word;const portflags:ULONG);
begin
    New(pPortAttrHeader);
    pPortAttrHeader.Flags:=portflags;
    pPortAttrHeader.MaxMessageLength:=messageSize;
    pPortAttrHeader.MemoryBandwidth:=$0;
    pPortAttrHeader.MaxPoolUsage:=$FF;
    pPortAttrHeader.MaxSectionSize:=$FFFFFFFF;
    pPortAttrHeader.MaxViewSize:=$FFFFFFFF;
    pPortAttrHeader.MaxTotalSectionSize:=$FFFFFFFF;
    pPortAttrHeader.DupObjectTypes:=$FFFFFFFF;
    pPortAttrHeader.SecurityQos.Length:=SizeOf(ALPC_LPC_Define.TSecurityQualityOfService);
    pPortAttrHeader.SecurityQos.ImpersonationLevel:=ALPC_LPC_Define.SecurityImpersonation;
    pPortAttrHeader.SecurityQos.EffectiveOnly:=False;
    pPortAttrHeader.SecurityQos.ContextTrackingMode:= SECURITY_STATIC_TRACKING;
end;

procedure AlpcPortAttributes.Terminate;
begin
 if pPortAttrHeader <> nil then Dispose(pPortAttrHeader);
end;

{ ObjectAttributes }

procedure ObjectAttributes.Initialize(const portName:PUNICODE_STRING);
begin
    New(pObjectAttrHeader);
    FillChar(pObjectAttrHeader^,SizeOf(OBJECT_ATTRIBUTES),#0);
    pObjectAttrHeader.Length:=SizeOf(OBJECT_ATTRIBUTES);
    pObjectAttrHeader.objectname:=portName;
end;

procedure ObjectAttributes.Terminate;
begin
    if pObjectAttrHeader <> nil  then Dispose(pObjectAttrHeader);
end;





{ AlpcTransportBase }

class procedure AlpcTransportBase.CreateCarrier;
begin
    pSender:=TAlpcCarrier.Create(
    fMessageSize,
    fMsgAttrAllocatedFlags
    );
    pReciver:=TAlpcCarrier.Create(
    fMessageSize,
    fMsgAttrAllocatedFlags
    );
   // pSender.Attributes.AssignView(pLocalView);
end;

class function AlpcTransportBase.CreateLocalView(viewFlag: ULONG):NTSTATUS;
var
size:SIZE_T;
begin

   Result:= NtAlpcCreatePortSection(
   fPortHandle,
   viewFlag,
   $0,
   fAllocatedSectionSize,
   @fSectionhandle,
   @Size
    );
    if Result = NTSTATUS_SUCC then
    begin
      pLocalView.ViewSize:=fAllocatedSectionSize;
      pLocalView.SectionHandle:=fSectionHandle;
      pLocalView.Flags:=$0;
      pLocalView.ViewBase:=nil;
      Result:=NtAlpcCreateSectionView(
      fPortHandle,
      $0,
      pLocalView
      );
    end;
end;

class procedure AlpcTransportBase.Initialize(const serverName: WideString;
  customMessageSize, messageAttributesAllocatedFlags, portFlags: Cardinal;
  allocatedSectionSize: SIZE_T; dataSizeOfQuotaIfNotUseView: Word;
  objectAttr: POBJECT_ATTRIBUTES; portAttr: PALPC_PORT_ATTRIBUTES);
begin
    New(pLocalView);
    New(pPortName);
    RTL_CONSTANT_STRING(serverName,pPortName);
    fPortAttr:=AlpcPortAttributes.Create;
    fPortAttr.Initialize(customMessageSize,portFlags);
    fObjectAttr:=ObjectAttributes.Create;
    fObjectAttr.Initialize(pPortName);
    fMessageSize:=customMessageSize;
    fDataSizeOfQuotaIfNotUseView:=dataSizeOfQuotaIfNotUseView;
    fMsgAttrAllocatedFlags:=messageAttributesAllocatedFlags;
    fAllocatedSectionSize:=allocatedSectionSize;
end;

class function AlpcTransportBase.NewMem(const totalSize: ULONG;
  var fBlock: TBlock): Boolean;
begin
Result:=ALPC_Base.NewMem(totalSize,fBlock);
end;

class function AlpcTransportBase.Recv(const pReceiverContext: PDataCache;
  pTime: PLARGE_INTEGER): NTSTATUS;
begin
     Result:=NtAlpcSendWaitReceivePort(
     fPortHandle,
     $0,
     nil,
     nil,
     pReciver.Structures.pMsgHeader,
     @fMessageSize,
     pReciver.Attributes.pAttrHeader,
     pTime
     );
     if Result = NTSTATUS_SUCC then
     begin
       pReciver.Pop(pReceiverContext);
     end;
end;

class procedure AlpcTransportBase.RTL_CONSTANT_STRING(
  const serverName: WideString; const portName: PUNICODE_STRING);
  const
  rpc_mark:WideString ='\RPC Control\';
  var
  len:Cardinal;
begin
      //$1A = SIZEOF '\RPC Control\'
      len:=Length(ServerName) * SizeOf(ServerName[1]);
      if not  NewMem(len+2+$1A,fBlock) then Exit;
      PortName.Length := len + $1A;
      PortName.MaximumLength := PortName.Length + 2;
      PortName.Buffer := @fBlock[0];
      Move(rpc_mark[1],fBlock[0],$1A);
      Move(serverName[1],(Pbyte(@fBlock[0])+$1A)^,len);
end;

class function AlpcTransportBase.Send(const pSenderContext: PDataCache;
  pTime: PLARGE_INTEGER): NTSTATUS;
begin
         pSender.Push(pSenderContext);
         Result:=NtAlpcSendWaitReceivePort(
         fPortHandle,
         $0,
         pSender.Structures.pMsgHeader,
         pSender.Attributes.pAttrHeader,
         nil,
         nil,
         nil,
         pTime
         );
end;

class function AlpcTransportBase.Send_Recv(const pSenderContext,
  pReceiverContext: PDataCache; pTime: PLARGE_INTEGER): NTSTATUS;
begin
    pSender.Push(
    pSenderContext,
    fDataSizeOfQuotaIfNotUseView
    );
    Result:=NtAlpcSendWaitReceivePort(
    fPortHandle,
    $20000,
    pSender.Structures.pMsgHeader,
    pSender.Attributes.pAttrHeader,
    pReciver.Structures.pMsgHeader,
    @fMessageSize,
    pReciver.Attributes.pAttrHeader,
    pTime
    );
    if Result = NTSTATUS_SUCC then
    begin
         pReciver.Pop(pReceiverContext);
    end;
end;

class procedure AlpcTransportBase.Terminate;
begin
       if fPortAttr<> nil then
       begin
       fPortAttr.Terminate();
       FreeAndNil(fPortAttr);
       end;
       if fObjectAttr <> nil then
       begin
       fObjectAttr.Terminate();
       FreeAndNil(fObjectAttr);
       end;
       if pSender <> nil then  FreeAndNil(pSender);
       if pReciver <> nil then FreeAndNil(pReciver);
       if pLocalView <> nil then Dispose(pLocalView);
       if pPortName <> nil then  Dispose(pPortName);
       if fPorthandle <> 0 then NtClose(fPortHandle);
end;

end.