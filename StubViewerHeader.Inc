type
   THandleError = procedure(const msg:string);
   PStubViewer = ^StubViewer;
   _StubViewer = packed record
   strict private
   arguments:ViewHeader;
   public
   function Marshal:PParameter;inline;
   procedure LoadDynamicData;inline;
   function Arg(const index:Cardinal):Pointer;inline;
   procedure Sign(const Signal: LongBool); inline;
   function GetFuncID:THashTable;inline;
   procedure SetFuncID(const funcName:string);
   procedure PushErrMessage(const msg:string);inline;
   function  PopErrMessage:string;inline;
   procedure FillServerCache(const serverCache:PStubViewer);inline;
   function IsSucessful(msg:THandleError = nil):LongBool;
  end;
  StubViewer = _StubViewer;