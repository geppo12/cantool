unit USplitterStr;

interface

uses
  Types;

type

  TSplitterStr = class
    private
    FArray: TStringDynArray;

    public
    procedure Parse(AStr: string);
    function GetArgument(AIdx: Integer): string;
    function LineFromArg(AIdx: Integer): string;
    function GetCount(): Integer;
  end;

implementation

uses
  SysUtils,
  StrUtils;


procedure TSplitterStr.Parse(AStr: string);
begin
  FArray := SplitString(AStr,' ');
end;

function TSplitterStr.GetArgument(AIdx: Integer): string;
begin
  Result := '';
	if AIdx < Length(FArray) then
		Result := Trim(FArray[AIdx]);
end;

function TSplitterStr.LineFromArg(AIdx: Integer): string;
var
  LIdx: Integer;
begin
	Result := GetArgument(AIdx);

	for LIdx := AIdx+1 to GetCount-1 do
		Result := Result + ' ' + GetArgument(LIdx);
end;


function TSplitterStr.GetCount: Integer;
begin
	Result := Length(FArray);
end;

end.
