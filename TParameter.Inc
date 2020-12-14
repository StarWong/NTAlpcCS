  type
    TArgInfo = packed record
    isPointer: LongBool;
    case Integer of
      0:
        (
        dynamicData:
         record
          dataSize: Cardinal;
          case Integer of
          0:(addr: Pointer;);
          1:(offsetFromDataAddr:Cardinal)
          end;
           );
      1:
        (
        staticData: record //always 8 bytes
        case Integer of
        0:(U64: UInt64; );
        1:(I64: Int64; );
        2:(Byte:Byte);
        3:(ShortInt:ShortInt);
        4:(Word:Word);
        5:(SmallInt:SmallInt);
        6:(Double:Double);
        7:(Single:Single);
        8:(WideChar:WideChar);
        9:(AnsiChar:AnsiChar);
        10:(Carinal:Cardinal);
        11:(Integer:Integer);
        12:(Pointer:Pointer);
        13:(LongBool:Pointer);
        14:(unKnow:array[0..7] of Byte)
         end;
         )
    end;
    PArgs = ^TArgs;
    TArgs = array [0 .. 9] of TArgInfo;
    TParameter = packed record
    count: Cardinal;
    Arg: TArgs;
    data:array[0..0] of Byte;
    end;
    PParameter = ^TParameter;

