{ _StubViewer }

//function GetHashTable(const funcName: string): AnsiString;
//var
//  LHash: IHash;
//begin
//  LHash := THashFactory.TCrypto.CreateSHA1;
//  result := LHash.ComputeString(funcName, TEncoding.UTF8).ToString();
//  LHash := nil;
//end;

function GetHashTable(const funcName: AnsiString): AnsiString;
begin
Result:=GetSha1(@funcName[1],Length(funcName));
end;



function _StubViewer.pArg(const index: Cardinal;const data:Pointer): Cardinal;
begin
   Result:=0;
  if  Self.Marshal.Arg[index].isPointer then
  begin
  result:=Self.Marshal.Arg[index].dynamicData.dataSize;
  Move(
  (PByte(@(Self.Marshal.data[0])) + Self.Marshal.Arg[index].dynamicData.offsetFromDataAddr)^,
  data^,
  result
  );
  end;
end;

function _StubViewer.pArg(const index: Cardinal;Out Str:string): Cardinal;
begin
  Result:=0;
  if  Self.Marshal.Arg[index].isPointer then
  begin
  result:=Self.Marshal.Arg[index].dynamicData.dataSize;
  SetString(
  str,
  PWideChar(PByte(@(Self.Marshal.data[0])) + Self.Marshal.Arg[index].dynamicData.offsetFromDataAddr),
  result
  );
  end;
end;

function _StubViewer.pArg(const index: Cardinal;var bytes:TByteArray): Cardinal;
begin
  Result:=0;
  if  Self.Marshal.Arg[index].isPointer then
  begin
  result:=Self.Marshal.Arg[index].dynamicData.dataSize;
  SetLength(bytes,result);
  Move(
  (PByte(@(Self.Marshal.data[0])) + Self.Marshal.Arg[index].dynamicData.offsetFromDataAddr)^,
  bytes[0],
  result
  );
  end;
end;

function _StubViewer.pArg(const index: Cardinal): TStaticData;
begin
    Move(Self.Marshal.Arg[index].StaticData,Result,8);
end;



function _StubViewer.GetFuncID: THashTable;
begin
    result:=Self.arguments.location.client.hashTable;
end;

function _StubViewer.IsSucessful(msg:THandleError = nil): LongBool;
begin
Result:= Not arguments.location.server.onError;
if Not Result then
begin
  if Assigned(msg) then
  msg(PopErrMessage);
end;
end;



procedure _StubViewer.EncodeDynamicData;
var
pStorage:PByte;
I:Cardinal;
totalDynDataSize:Cardinal;//offset from TParameter.data
begin
Self.arguments.activeDataSize:=0;
totalDynDataSize:=0;
if Self.Marshal.count = 0 then  Exit;
Self.arguments.activeDataSize:=SizeOf(ViewHeader) - 1 + SizeOf(TParameter) - 1;
pStorage:=@(Marshal.data[0]);

    for I := 0 to Self.Marshal.count - 1 do
    begin
        if Not Self.Marshal.Arg[I].isPointer then Continue;
       Move(Marshal.Arg[I].dynamicData.addr^,pStorage^,Marshal.Arg[I].dynamicData.dataSize);
       Inc(pStorage,Marshal.Arg[I].dynamicData.dataSize);
       Marshal.Arg[I].dynamicData.offsetFromDataAddr:=totalDynDataSize;
       Inc(totalDynDataSize,Marshal.Arg[I].dynamicData.dataSize);
       Inc(Self.arguments.activeDataSize,Marshal.Arg[I].dynamicData.dataSize);
    end;

end;

procedure _StubViewer.DecodeDynamicData;
var
pStorage:PByte;
I:Cardinal;
begin
   if Self.Marshal.count = 0 then  Exit;
   pStorage:=@(Marshal.data[0]);
       for I := 0 to Self.Marshal.count - 1 do
    begin
        if Not Self.Marshal.Arg[I].isPointer then Continue;
        Marshal.Arg[I].dynamicData.Addr:=pStorage + Marshal.Arg[I].dynamicData.offsetFromDataAddr;
    end;
end;


function _StubViewer.Marshal: PParameter;
begin
   result:=@(Self.arguments.dataSection[0]);
end;

procedure _StubViewer.FillServerCache(const serverCache: PStubViewer);
begin
    Move(Self, serverCache^,Self.arguments.activeDataSize);
end;

function _StubViewer.PopErrMessage:string;
begin
    Result:=PWideChar(@(Self.arguments.dataSection[0]));
end;

procedure _StubViewer.PushErrMessage(const msg: string);
begin
     Move(msg[1],Self.arguments.dataSection[0],Length(msg) * 2 + 2);
end;

procedure _StubViewer.SetFuncID(const funcName: string);
var
hash:AnsiString;
begin
      hash:=GetHashTable(funcName);
      Move(hash[1],Self.arguments.location.Client.hashTable[0],Length(hash)+1);
end;

procedure _StubViewer.Sign(const Signal: LongBool);
begin
    Self.arguments.location.Server.onError := Not Signal;
end;