unit ALPC_LPC_Define;
interface

uses
Windows,Logger,Classes,SysUtils,Generics.Collections,SyncObjs;
{$REGION 'Type'}
type
NTSTATUS = Integer;
ULONG = Cardinal;
uint64_t = UInt64;
uint32_t = Cardinal;
HANDLE = THandle;
ALPC_HANDLE = HANDLE;
PALPC_HANDLE =^ALPC_HANDLE;

PSIZE_T = ^SIZE_T;
SIZE_T = Cardinal;
PVOID = Pointer;

  {$MINENUMSIZE 4}
  TSecurityImpersonationLevel = (SecurityAnonymous,
  SecurityIdentification, SecurityImpersonation, SecurityDelegation);
  {$MINENUMSIZE 1}
  PSecurityQualityOfService = ^TSecurityQualityOfService;
  SECURITY_CONTEXT_TRACKING_MODE = Boolean;
  _SECURITY_QUALITY_OF_SERVICE = record
    Length: DWORD;
    ImpersonationLevel: ALPC_LPC_Define.TSecurityImpersonationLevel;
    ContextTrackingMode: ALPC_LPC_Define.SECURITY_CONTEXT_TRACKING_MODE;
    EffectiveOnly: Boolean;
  end;
  TSecurityQualityOfService = _SECURITY_QUALITY_OF_SERVICE;
  SECURITY_QUALITY_OF_SERVICE = _SECURITY_QUALITY_OF_SERVICE;

PUNICODE_STRING = ^UNICODE_STRING;

  UNICODE_STRING = record
    Length: Word;
    MaximumLength: Word;
    Buffer: pwidechar;
  end;

  _OBJECT_ATTRIBUTES = record
    Length: ULONG;
    RootDirectory: THandle;
    ObjectName: PUNICODE_STRING;
    Attributes: ULONG;
    SecurityDescriptor: PSecurityDescriptor;
    SecurityQualityOfService: PSecurityQualityOfService;
  end;

  OBJECT_ATTRIBUTES = _OBJECT_ATTRIBUTES;
  POBJECT_ATTRIBUTES = ^OBJECT_ATTRIBUTES;

  _ALPC_PORT_ATTRIBUTES = record
    Flags: ULONG;
    SecurityQos: SECURITY_QUALITY_OF_SERVICE;
    MaxMessageLength: SIZE_T;
    MemoryBandwidth: SIZE_T;
    MaxPoolUsage: SIZE_T;
    MaxSectionSize: SIZE_T;
    MaxViewSize: SIZE_T;
    MaxTotalSectionSize: SIZE_T;
    DupObjectTypes: ULONG end;

    ALPC_PORT_ATTRIBUTES = _ALPC_PORT_ATTRIBUTES;
    PALPC_PORT_ATTRIBUTES = ^ALPC_PORT_ATTRIBUTES;

    _CLIENT_ID = record UniqueProcess: THandle;
    UniqueThread: THandle;
  end;

  CLIENT_ID = _CLIENT_ID;

  PCLIENT_ID = ^CLIENT_ID;

  Ts1 = record
    DataLength: Word;
    TotalLength: Word end;

    Ts2 = record _Type: Word;
    DataInfoOffset: Word end;

    Tu1 = record
    case Integer of
      0:
        (s1: Ts1);
      1:
        (Length: ULONG);
  end;

  Tu2 = record
    case Integer of
      0:
        (s2: Ts2);
      1:
        (ZeroInit: ULONG);
  end;

  Tu3 = record
    case Integer of
      0:
        (ClientId: CLIENT_ID);
      1:
        (DoNotUseThisField: Double);
  end;

  Tu4 = record
    case Integer of
      0:
        (ClientViewSize: SIZE_T);
      1:
        (CallbackId: ULONG);
  end;

  _PORT_MESSAGE = record
    u1: Tu1;
    u2: Tu2;
    u3: Tu3;
    MessageId: ULONG;
    u4: Tu4 end;

    PORT_MESSAGE = _PORT_MESSAGE;
    PPORT_MESSAGE = ^PORT_MESSAGE;

    {$REGION 'ALPC_SECURITY_ATTR'}
    _ALPC_SECURITY_ATTR = record
    Flags:ULONG;
    QoS:PSecurityQualityOfService;
    ContextHandle:ALPC_HANDLE
    end;

    PALPC_SECURITY_ATTR = ^ALPC_SECURITY_ATTR;
    ALPC_SECURITY_ATTR = _ALPC_SECURITY_ATTR;

    {$ENDREGION}

    {$REGION 'ALPC_DATA_VIEW_ATTR'}
    _ALPC_DATA_VIEW_ATTR = record
    Flags: ULONG;
    SectionHandle: ALPC_HANDLE;
    ViewBase: PVOID;
    ViewSize: SIZE_T end;

    PALPC_DATA_VIEW_ATTR = ^ALPC_DATA_VIEW_ATTR;
    ALPC_DATA_VIEW_ATTR = _ALPC_DATA_VIEW_ATTR;

    {$ENDREGION}

    {$REGION 'ALPC_CONTEXT_ATTR'}

    _ALPC_CONTEXT_ATTR = record
      PortContext:PVOID;
      MessageContext:PVOID;
      Sequence:ULONG;
      MessageId:ULONG;
      CallbackId:ULONG
    end;

    PALPC_CONTEXT_ATTR = ^ALPC_CONTEXT_ATTR;
    ALPC_CONTEXT_ATTR = _ALPC_CONTEXT_ATTR;

    {$ENDREGION}

    {$REGION 'ALPC_HANDLE_ATTR'}

    PACCESS_MASK =^ACCESS_MASK;
    ACCESS_MASK =DWORD;
    _ALPC_HANDLE_ATTR = record
    Flags:ULONG;
    Handle:HANDLE;
    ObjectType:ULONG;
    DesiredAccess:ACCESS_MASK
    end;

    PALPC_HANDLE_ATTR = ^ALPC_HANDLE_ATTR;
    ALPC_HANDLE_ATTR = _ALPC_HANDLE_ATTR;

     {$ENDREGION}

    {$REGION 'ALPC_TOKEN_ATTR'}
    _ALPC_TOKEN_ATTR = record
    TokenId:ULONGLONG;
    AuthenticationId:ULONGLONG;
    ModifiedId:ULONGLONG
    end;

    PALPC_TOKEN_ATTR = ^ALPC_TOKEN_ATTR;
    ALPC_TOKEN_ATTR = _ALPC_TOKEN_ATTR;

    {$ENDREGION}

    {$REGION 'ALPC_DIRECT_ATTR'}
    _ALPC_DIRECT_ATTR = record
     Event:HANDLE
    end;

    PALPC_DIRECT_ATTR = ^ALPC_DIRECT_ATTR;
    ALPC_DIRECT_ATTR = _ALPC_DIRECT_ATTR;

    {$ENDREGION}

    {$REGION 'ALPC_WORK_ON_BEHALF_ATTR'}
    _ALPC_WORK_ON_BEHALF_ATTR = record
    Ticket:ULONGLONG;
    end;
    PALPC_WORK_ON_BEHALF_ATTR = ^ALPC_WORK_ON_BEHALF_ATTR;
    ALPC_WORK_ON_BEHALF_ATTR = _ALPC_WORK_ON_BEHALF_ATTR;
    {$ENDREGION}

    _ALPC_MESSAGE_ATTRIBUTES_HEAD = record
    AllocatedAttributes: ULONG;
    ValidAttributes: ULONG;
    end;

    PALPC_MESSAGE_ATTRIBUTES_HEAD = ^ALPC_MESSAGE_ATTRIBUTES_HEAD;
    ALPC_MESSAGE_ATTRIBUTES_HEAD = _ALPC_MESSAGE_ATTRIBUTES_HEAD;


    _ALPC_MESSAGE_ATTRIBUTES = record
    Head:ALPC_MESSAGE_ATTRIBUTES_HEAD; //8
    Buffer:array[0..0] of Byte;
    end;


    ALPC_MESSAGE_ATTRIBUTES = _ALPC_MESSAGE_ATTRIBUTES;
    PALPC_MESSAGE_ATTRIBUTES = ^ALPC_MESSAGE_ATTRIBUTES;


    TDUMMYSTRUCTNAME = record LowPart: DWORD;
    HighPart: Integer;
  end;

  Tu = TDUMMYSTRUCTNAME;

  _LARGE_INTEGER = record
    case Integer of
      0:
        (DUMMYSTRUCTNAME: TDUMMYSTRUCTNAME);
      1:
        (u: Tu);
      2:
        (QuadPart: Int64)
  end;

  LARGE_INTEGER = _LARGE_INTEGER;

  PLARGE_INTEGER = ^LARGE_INTEGER;


    _ALPC_CUSTOM_MESSAGE = packed record Header: PORT_MESSAGE;
    Buffer: array [0 .. 0] of Byte end;

    ALPC_CUSTOM_MESSAGE = _ALPC_CUSTOM_MESSAGE;

    PALPC_CUSTOM_MESSAGE = ^ALPC_CUSTOM_MESSAGE;

    // TBufferCache = array [0 .. MAXWORD - 1] of Byte;
    TBufferCache = array [0 .. 1024 - 1] of Cardinal;//total 4096 bytes
    TMsgAttribCache = array [0..17] of Cardinal; //full size = 72
    // fix TBufferCache to algined with 4 size


     _Arguments_Client =packed  record
     functionID:Cardinal;
     In_Arguments:PPointer;
     ref_Arguments:PPointer;
     end;
     Arguments_Client = _Arguments_Client;
     PArguments_Client = ^Arguments_Client;

     _Arguments_Server = packed record
       onError:BOOL;
       case Integer of
       0:
       (
         errorInfo:Pointer;
       );
       1:
       (
       result:Pointer;
       ref_Arguments:PPointer;
       );
     end;
      Arguments_Server = _Arguments_Server;
      PArguments_Server = Arguments_Server;

    _ViewCache = packed record
     baseAddr:Pointer;
     activeDataSize:Cardinal;
     arguments:record
     case Integer of
     0:
     (
     client:Arguments_Client;
     );
     1:
     (
     server:Arguments_Server;
     );
     end;
     offset:array[0..0] of Byte;
     end;
     ViewCache = _ViewCache;
     PViewCache = ^ViewCache;


    TArgument_ = record
     funcid:ULONG;
     do_return:BOOL
    end;
    TResult_ = record
    error:BOOL
    end;
    TAuth = record
    Key:UInt64;
    FnPathID:Cardinal;
    end;
     PAuth = ^TAuth;

    TInfo_ =record
    case integer of
    0:(argument:TArgument_);
    1:(result:TResult_);
    2:(Auth:TAuth)
    end;


     _DataHeader = record
     datasize:ULONG;
     messageID:ULONG;
     useview:Boolean;
     info:TInfo_
     end;

     PDataHeader =^DataHeader;
     DataHeader = _DataHeader;

     _DataCache = record
     head:DataHeader;
     buffer:array[0..0]of Byte
     end;

     PDataCache = ^DataCache;
     DataCache = _DataCache;
     {
     _ViewHeader = record
       DataLength:Cardinal;
     end;

     PViewHeader = ^ViewHeader;
     ViewHeader = _ViewHeader;

     _ViewCache = record
     header:DataCache;
     ViewBase:Pointer
     end;

     PViewCache = ^ViewCache;
     ViewCache = _ViewCache;
    }
{$REGION 'ViewDetail'}
     type
     PHashTable = ^THashTable;
     THashTable = array[0..40] of Byte; //sha1 39+1
    _ViewDetail = packed record

     activeDataSize:Cardinal;

     location : packed record
     case Integer of
     0:
     (
      client : packed record
      functionID:Cardinal;//
      hashTable:THashTable
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
     end;
     ViewDetail = _ViewDetail;
{$ENDREGION}

  ALPC_MESSAGE_INFORMATION_CLASS = Cardinal;


{$REGION 'REMOTE_PORT_VIEW'}
_REMOTE_PORT_VIEW = record
Length:ULONG;
ViewSize:SIZE_T;
ViewBase:PVOID;
end;

PREMOTE_PORT_VIEW = ^REMOTE_PORT_VIEW;
REMOTE_PORT_VIEW = _REMOTE_PORT_VIEW;
{$ENDREGION}

{$REGION 'PORT_VIEW'}
_PORT_VIEW = record
Length:ULONG;
SectionHandle:HANDLE;
SectionOffset:ULONG;
ViewSize:SIZE_T;
ViewBase:PVOID;
ViewRemoteBase:PVOID;
end;
PPORT_VIEW = ^PORT_VIEW;
PORT_VIEW = _PORT_VIEW;
{$ENDREGION}

{$REGION 'Const'}

const
PORT_MESSAGE_SIZE = Word(24);
LPC_REQUEST = Cardinal(1);
LPC_REPLY = Cardinal(2);
LPC_DATAGRAM = Cardinal(3);
LPC_LOST_REPLY = Cardinal(4);
LPC_PORT_CLOSED = Cardinal(5);
LPC_CLIENT_DIED = Cardinal(6);
LPC_EXCEPTION = Cardinal(7);
LPC_DEBUG_EVENT = Cardinal(8);
LPC_ERROR_EVENT = Cardinal(9);
LPC_CONNECTION_REQUEST = Cardinal(10);
ALPC_MESSAGE_NONE_ATTRIBUTE = Cardinal($0);
ALPC_MESSAGE_SECURITY_ATTRIBUTE = Cardinal($80000000);
ALPC_MESSAGE_VIEW_ATTRIBUTE = Cardinal($40000000);
ALPC_MESSAGE_CONTEXT_ATTRIBUTE = Cardinal($20000000);
ALPC_MESSAGE_HANDLE_ATTRIBUTE = Cardinal($10000000);
ALPC_MESSAGE_TOKEN_ATTRIBUTE = Cardinal($8000000);
ALPC_MESSAGE_DIRECT_ATTRIBUTE = Cardinal($4000000);
ALPC_MESSAGE_WORK_ON_BEHALF_ATTRIBUTE = Cardinal($2000000);
ALPC_MSGFLG_NONE = Cardinal($0);
ALPC_MSGFLG_REPLY_MESSAGE = Cardinal($1);
ALPC_MSGFLG_LPC_MODE = Cardinal($2);
ALPC_MSGFLG_RELEASE_MESSAGE = Cardinal($10000);
ALPC_MSGFLG_SYNC_REQUEST = Cardinal($20000);
ALPC_MSGFLG_WAIT_USER_MODE = Cardinal($100000);
ALPC_MSGFLG_WAIT_ALERTABLE = Cardinal($200000);
ALPC_MSGFLG_WOW64_CALL = Cardinal($80000000);
ALPC_PORFLG_ALLOW_LPC_REQUESTS = Cardinal($20000);
ALPC_PORFLG_WAITABLE_PORT = Cardinal($40000);
ALPC_PORFLG_SYSTEM_PROCESS = Cardinal($100000);
ALPC_CANCELFLG_TRY_CANCEL = Cardinal($1);
ALPC_CANCELFLG_NO_CONTEXT_CHECK = Cardinal($8);
ALPC_CANCELFLGP_FLUSH = Cardinal($10000);
ALPC_HANDLEFLG_DUPLICATE_SAME_ACCESS = Cardinal($10000);
ALPC_HANDLEFLG_DUPLICATE_SAME_ATTRIBUTES = Cardinal($20000);
ALPC_HANDLEFLG_DUPLICATE_INHERIT = Cardinal($80000);
ALPC_SECFLG_CREATE_HANDLE = Cardinal($20000);
ALPC_VIEWFLG_NOT_SECURE = Cardinal($40000);
ALPC_PORT_ATTRIBUTES_None = Cardinal($0);
ALPC_PORT_ATTRIBUTES_LpcPort = Cardinal($1000);
ALPC_PORT_ATTRIBUTES_AllowImpersonation = Cardinal($10000);
ALPC_PORT_ATTRIBUTES_AllowLpcRequests = Cardinal($20000);
ALPC_PORT_ATTRIBUTES_WaitablePort = Cardinal($40000);
ALPC_PORT_ATTRIBUTES_AllowDupObject = Cardinal($80000);
ALPC_PORT_ATTRIBUTES_SystemProcess = Cardinal($100000);
ALPC_PORT_ATTRIBUTES_LrpcWakePolicy1 = Cardinal($200000);
ALPC_PORT_ATTRIBUTES_LrpcWakePolicy2 = Cardinal($400000);
ALPC_PORT_ATTRIBUTES_LrpcWakePolicy3 = Cardinal($800000);
ALPC_PORT_ATTRIBUTES_DirectMessage = Cardinal($1000000);
ALPC_PORT_ATTRIBUTES_AllowMultiHandleAttribute = Cardinal($2000000);
  SECURITY_DYNAMIC_TRACKING = True;
  SECURITY_STATIC_TRACKING  = False;
  NTSTATUS_SUCC = NTSTATUS($0);
{$ENDREGION}

{$REGION 'DllCall'}
    function NtAlpcConnectPort(PortHandle: PHANDLE; PortName: PUNICODE_STRING;
      ObjectAttributes: POBJECT_ATTRIBUTES;
      PortAttributes: PALPC_PORT_ATTRIBUTES; Flags: ULONG;
      RequiredServerSid: PSID; ConnectionMessage: PPORT_MESSAGE;
      BufferLength: PULONG; OutMessageAttributes: PALPC_MESSAGE_ATTRIBUTES;
      InMessageAttributes: PALPC_MESSAGE_ATTRIBUTES; Timeout: PLARGE_INTEGER)
      : NTSTATUS; stdcall; external 'ntdll.dll' name 'NtAlpcConnectPort';

    function NtAlpcSendWaitReceivePort(PortHandle: HANDLE; Flags: ULONG;
      SendMessage: PALPC_CUSTOM_MESSAGE;
      SendMessageAttributes: PALPC_MESSAGE_ATTRIBUTES;
      ReceiveMessage: PALPC_CUSTOM_MESSAGE; BufferLength: PSIZE_T;
      ReceiveMessageAttributes: PALPC_MESSAGE_ATTRIBUTES;
      Timeout: PLARGE_INTEGER): NTSTATUS; stdcall;
      external 'ntdll.dll' name 'NtAlpcSendWaitReceivePort';

    function AlpcInitializeMessageAttribute(AttributeFlags: ULONG;
      var Buffer: ALPC_MESSAGE_ATTRIBUTES_HEAD; BufferSize: ULONG;
      var RequiredBufferSize: ULONG): NTSTATUS; stdcall;
      external 'ntdll.dll' name 'AlpcInitializeMessageAttribute';

    function NtAlpcCreatePort(PortHandle: PHANDLE;
      ObjectAttributes: POBJECT_ATTRIBUTES;
      PortAttributes: PALPC_PORT_ATTRIBUTES): NTSTATUS; stdcall;
      external 'ntdll.dll' name 'NtAlpcCreatePort';

    function NtAlpcAcceptConnectPort(PortHandle: PHANDLE; ConnectionPortHandle: HANDLE;
      Flags: ULONG; ObjectAttributes: POBJECT_ATTRIBUTES;
      PortAttributes: PALPC_PORT_ATTRIBUTES; PortContext: PVOID;
      ConnectionRequest: PPORT_MESSAGE;
      ConnectionMessageAttributes: PALPC_MESSAGE_ATTRIBUTES;
      AcceptConnection: boolean): NTSTATUS; stdcall;
      external 'ntdll.dll' name 'NtAlpcAcceptConnectPort';

    function DisconnectFromServer(PortHandle: HANDLE; Flags: ULONG): NTSTATUS;
      stdcall; external 'ntdll.dll' name 'NtAlpcDisconnectPort';

    function NtAlpcCreatePortSection(PortHandle: HANDLE; Flags: ULONG;
      SectionHandle: HANDLE; SectionSize: SIZE_T;
      AlpcSectionHandle: PALPC_HANDLE;// OUT
      ActualSectionSize: PSIZE_T // OUT
      ): NTSTATUS; stdcall; external 'ntdll.dll' name 'NtAlpcCreatePortSection';

    function NtAlpcCreateSectionView(PortHandle: HANDLE; Flags: ULONG;
      ViewAttributes: PALPC_DATA_VIEW_ATTR): NTSTATUS; stdcall;
      external 'ntdll.dll' name 'NtAlpcCreateSectionView';

    function NtAlpcDeletePortSection(PortHandle: HANDLE; Flags: ULONG;
      SectionHandle: ALPC_HANDLE): NTSTATUS; stdcall;
      external 'ntdll.dll' name 'NtAlpcDeletePortSection';

    function NtAlpcDeleteSectionView(PortHandle: HANDLE; Flags: ULONG;
      ViewBase: PVOID): NTSTATUS; stdcall;
      external 'ntdll.dll' name 'NtAlpcDeleteSectionView';

    function NtAlpcQueryInformationMessage(
    PortHandle:HANDLE;
    PortMessage:PPORT_MESSAGE;
    MessageInformationClass:ALPC_MESSAGE_INFORMATION_CLASS;
    MessageInformation:PVOID;
    Length:ULONG;
    ReturnLength:PULONG
    ):NTSTATUS;stdcall;
      external 'ntdll.dll' name 'NtAlpcQueryInformationMessage';

    function AlpcGetHeaderSize(Flags:ULONG):ULONG;
    stdcall;external 'ntdll.dll' name 'AlpcGetHeaderSize';

    function AlpcGetMessageAttribute(Buffer:PALPC_MESSAGE_ATTRIBUTES;AttributeFlag:ULONG):PVOID;
    stdcall;external 'ntdll.dll' name 'AlpcGetMessageAttribute';

    function NtListenPort(PortHandle:HANDLE;ConnectionRequest:PPORT_MESSAGE):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtListenPort';

    function NtCompleteConnectPort(PortHandle:HANDLE):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtCompleteConnectPort';

    function NtCreatePort(
    PPortHandle:PHandle;
    ObjectAttributes: POBJECT_ATTRIBUTES;
    MaxConnectionInfoLength:ULONG;
    MaxMessageLength:ULONG;
    MaxPoolUsage:ULONG
    ):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtCreatePort';

    function NtReplyWaitReceivePort(PortHandle:HANDLE;PortContext:PVOID;
    ReplyMessage:PORT_MESSAGE;ReceiveMessage:PPORT_MESSAGE):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtReplyWaitReceivePort';

    function NtRequestWaitReplyPort(PortHandle:HANDLE;
    RequestMessage:PPORT_MESSAGE;ReplyMessage:PPORT_MESSAGE):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtRequestWaitReplyPort';

    function NtCreateSection(
    SectionHandle:PHandle;
    DesiredAccess:ACCESS_MASK;
    ObjectAttributes:POBJECT_ATTRIBUTES;
    MaximumSize:PLARGE_INTEGER;
    SectionPageProtection:ULONG;
    AllocationAttributes:ULONG;
    FileHandle:HANDLE
    ):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtCreateSection';

    function NtClose(Handle:HANDLE):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtClose';

    function NtReplyPort(PortHandle:HANDLE;ReplyMessage:PPORT_MESSAGE):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtReplyPort';

    function NtAcceptConnectPort(
    PortHandle:PHandle;
    PortContext:PVOID;
    ConnectionRequest:PPORT_MESSAGE;
    AcceptConnection:Boolean;
    ServerView:PPORT_VIEW;
    ClientView:PREMOTE_PORT_VIEW
    ):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtAcceptConnectPort';

    function NtConnectPort(
    PortHandle:PHandle;
    PortName:PUNICODE_STRING;
    SecurityQos:PSecurityQualityOfService;
    ClientView:PPORT_VIEW;
    ServerView:PREMOTE_PORT_VIEW;
    MaxMessageLength:PULONG;
    ConnectionInformation:PVOID;
    ConnectionInformationLength:PULONG
    ):NTSTATUS;stdcall;
    external 'ntdll.dll' name 'NtConnectPort';

    {$ENDREGION}

implementation


end.
