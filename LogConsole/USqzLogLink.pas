unit USqzLogLink;

interface

type
  TSqzLogLink = class
    private
    FName: string;

    protected
    FActive: Boolean;

    public
    procedure Open;
    procedure Close;

    property Writer: TBinaryWriter read getBinaryWriter;
    property


  end;

implementation



end.
