unit UCanMsg;

interface

Uses
  Generics.Collections;

type
  TCanMsg = record
    public
    ecmTime: Int64;
    ecmID: Cardinal;
    ecmLen: Cardinal;
    ecmData: array [0..7] of Byte;
    function GetNode: Cardinal;
    // for debug
    function ToString: string;
  end;

  TCanMsgQueue = TQueue<TCanMsg>;

implementation

uses
  SysUtils,
  StrUtils;

{$REGION 'TCanMsg'}
// TODO 2 -cFIXME : vedere metodo per ìidentifciare il nodo
function TCanMsg.GetNode: Cardinal;
begin
  Result := ecmID and $3FFF;
end;

function TCanMsg.ToString: string;
var
  I: Integer;
begin
  Result := Format('ID=0x%08X (N=%d) L=%d D=',[ecmId,getNode,ecmLen]);

  for I := 0 to ecmLen - 1 do
    Result := Result + Format('%.2X.',[ecmData[i]]);

  Result := LeftStr(Result,Length(Result)-1);
end;

{$ENDREGION}

end.
