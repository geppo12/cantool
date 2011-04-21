unit UCanMsg;

interface

type
  TCanMsg = record
    public
    ecmID: Integer;
    ecmLen: Integer;
    ecmData: array [0..7] of Byte;
    function getNode: Integer;
  end;


implementation

{$REGION 'TCanMsg'}
// TODO 2 -cFIXME : vedere metodo per ìidentifciare il nodo
function TCanMsg.getNode: Integer;
begin
  Result := ecmID and $ff;
end;
{$ENDREGION}

end.
