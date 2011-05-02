unit UFmFilters;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids,
  UCanMsg;

resourcestring
  kMaskStr   = 'Mask ID';
  kValueLow  = 'Value Low';
  kValueHigh = 'Value High';

type
  TfmFilter = class(TForm)
    sgFilter: TStringGrid;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    function parseRow(var AFilter: TCanMsgFilter; ARow: TStrings): Boolean;
  public
    { Public declarations }
    procedure ShowFilterList(AList: TCanMsgFilterList);
    procedure UpdateFilterList(AList: TCanMsgFilterList);
  end;

var
  fmFilter: TfmFilter;

implementation

{$R *.dfm}

function TfmFilter.parseRow(var AFilter: TCanMsgFilter; ARow: TStrings): Boolean;
begin
  Result := False;
  try
    if ARow.Strings[0] = '' then
      AFilter.MaskId := $FFFFFFFF
    else
      AFilter.MaskId    := Cardinal(StrToInt(ARow.Strings[0]));
    AFilter.ValueLow  := Cardinal(StrToInt(ARow.Strings[1]));

    if ARow.Strings[2] = '' then
      AFilter.ValueHigh := AFilter.ValueLow
    else
      AFilter.ValueHigh := Cardinal(StrToInt(ARow.Strings[2]));
    Result := true;
  except
    on EConvertError do begin
      ARow.Strings[0] := '0';
      ARow.Strings[1] := '0';
      ARow.Strings[2] := '0';
    end;
  end;
end;

procedure TfmFilter.FormCreate(Sender: TObject);
begin
  with sgFilter.Rows[0] do begin
    Add(kMaskStr);
    Add(kValueLow);
    Add(kValueHigh);
  end;
end;

// TODO 2 -cFIXME : include decimal rapresentation
procedure TfmFilter.ShowFilterList(AList: TCanMsgFilterList);
var
  I: Integer;
  LFilter: TCanMsgFilter;
  LRow: TStrings;
begin
  I := 1;
  for LFilter in AList do begin
    LRow := sgFilter.Rows[I];
    LRow.Add(Format('0x%.8X',[LFilter.MaskId]));
    LRow.Add(Format('0x%.8X',[LFilter.ValueLow]));
    LRow.Add(Format('0x%.8X',[LFilter.ValueHigh]));
    Inc(I);
  end;
end;

procedure TfmFilter.UpdateFilterList(AList: TCanMsgFilterList);
var
  I: Integer;
  LFilter: TCanMsgFilter;
begin
  AList.Clear;
  // we start from 1. Row number 0 is title row
  for I := 1 to sgFilter.RowCount - 1 do begin
    // LFilter is a record not an TObject so we pass as reference
    if parseRow(LFilter,sgFilter.Rows[I]) then
      AList.Add(LFilter);
  end;
end;

end.
