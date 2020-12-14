    type
     PHashTable = ^THashTable;
     THashTable = array[0..40] of Byte; //sha1 39+1
    _ViewHeader = packed record
     activeDataSize:Cardinal;
     location : packed record
     case Integer of
     0:
     (
      client : packed record
      hashTable:THashTable;
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
     ViewHeader = _ViewHeader;