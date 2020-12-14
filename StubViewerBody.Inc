{ _StubViewer }

function GetHashTable(const funcName: string): AnsiString;
var
  LHash: IHash;
begin
  LHash := THashFactory.TCrypto.CreateSHA1;
  result := LHash.ComputeString(funcName, TEncoding.UTF8).ToString();
  LHash := nil;
end;

function _StubViewer.Arg(const index: Cardinal): Pointer;
begin
  if  Self.Marshal.Arg[index].isPointer then
  Result:=PByte(@(Self.Marshal.data[0])) + Self.Marshal.Arg[index].dynamicData.offsetFromDataAddr
  else
  Result:=@(Self.Marshal.Arg[index].staticData);
end;

function _StubViewer.GetFuncID: THashTable;
begin
    result:=Self.arguments.location.client.hashTable;
end;

function _StubViewer.IsSucessful(msg:THandleError = nil): LongBool;
begin
Result:=arguments.location.server.onError;
if not Result then
begin
  if Assigned(msg) then
  msg(PopErrMessage);
end;
end;



procedure _StubViewer.LoadDynamicData;
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

function _StubViewer.Marshal: PParameter;
begin
   result:=@(Self.arguments.dataSection[0]);
end;

procedure _StubViewer.FillServerCache(const serverCache: PStubViewer);
begin
    Move(Self.arguments.dataSection[0], serverCache^,Self.arguments.activeDataSize);
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
    Self.arguments.location.Server.onError := Signal;
end;