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
    function ToEgoString: string;
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
  Result := Format('ID=0x%08X (N=%d) L=%d',[ecmId,getNode,ecmLen]);

  for I := 0 to ecmLen - 1 do begin
    Result := Result + Format(' D[%d]=0x%.2X',[I,ecmData[I]]);
  end;
end;

// #DEBUG
// TODO 1 -cFIXME: rimuovere prima del rilascio
function TCanMsg.ToEgoString: string;
var
  I: Integer;
  LCmd: Integer;
  LNode: Integer;
begin

  LCmd  := ((ecmId shr 14) and $3FF);
	LNode := GetNode;

	Result := Format('-- -- P:- C:%.4X N:%d L:%d Data:',
		[LCmd,
		 LNode,
	   ecmLen]);

  for I := 0 to ecmLen - 1 do
    Result := Result + Format('%.2X.',[ecmData[i]]);

  Result := LeftStr(Result,Length(Result)-1);
end;
{$ENDREGION}

end.
