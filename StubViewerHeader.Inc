type
   TByteArray = array of Byte;
   THandleError = procedure(const msg:string);
   PStubViewer = ^StubViewer;
   _StubViewer = packed record
   strict private
   arguments:ViewHeader;
   public
   function Marshal:PParameter;inline;
   procedure EncodeDynamicData;
   procedure DecodeDynamicData;
   procedure Sign(const Signal: LongBool); inline;
   function GetFuncID:THashTable;inline;
   procedure SetFuncID(const funcName:string);
   procedure PushErrMessage(const msg:string);inline;
   function  PopErrMessage:string;inline;
   procedure FillServerCache(const serverCache:PStubViewer);inline;
   function IsSucessful(msg:THandleError = nil):LongBool;
   function pArg(const index: Cardinal;Out Str:string): Cardinal;overload;
   function pArg(const index: Cardinal;var bytes:TByteArray): Cardinal;overload;
   function pArg(const index: Cardinal;const data:Pointer): Cardinal;overload;
   function pArg(const index: Cardinal): TStaticData;overload;
  end;
  StubViewer = _StubViewer;