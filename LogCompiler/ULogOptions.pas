unit ULogOptions;

interface

type
  TLogOptions = class
	  private
    class var FInstance: TLogOptions;
    var
    FCrc: Boolean;
    FDoublePar: Boolean;

    public
    class constructor Create;
    class destructor Destroy;
    class property Instance: TLogOptions read FInstance;
    property Crc: Boolean read FCrc write FCrc;
    property DoublePar: Boolean read FDoublePar write FDoublePar;
  end;

implementation

class constructor TLogOptions.Create;
begin
  FInstance := TLogOptions.Create;
  FInstance.FCrc := false;
  FInstance.FDoublePar := false;
end;

class destructor TLogOptions.Destroy;
begin
  FInstance.Free;
end;

end.
