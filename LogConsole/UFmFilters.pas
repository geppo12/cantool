{
	 Copyright 2011 Giuseppe Monteleone

	 This file is part of 'Ninjeppo Can Tool'

	 'Ninjeppo Can Tool' is free software: you can redistribute
	 it and/or modify it under the terms of the GNU General Public
	 License versione 2, as published by the Free Software Foundation

 	 THIS SOFTWARE IS PROVIDED BY GIUSEPPE MONTELEONE ``AS IS'' AND ANY
 	 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
	 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL GIUSEPPE MONTELEONE BE
	 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
	 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
	 OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
	 OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
	 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	 You should have received a copy of the GNU General Public License
	 along with 'Ninjeppo Can Tool'. If not, see <http://www.gnu.org/licenses/>.
}
unit UFmFilters;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids,
  UCanMsg;

resourcestring
  kMaskStr   = 'Mask ID';
  kMaskExtStr = 'XTD';
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

uses
  StrUtils;
{$R *.dfm}

function TfmFilter.parseRow(var AFilter: TCanMsgFilter; ARow: TStrings): Boolean;
begin
  Result := False;
  try
    if ARow.Strings[0] = '' then
      AFilter.MaskId := $FFFFFFFF
    else
      AFilter.MaskId    := Cardinal(StrToInt(ARow.Strings[0]));

    AFilter.Ext := (LowerCase(LeftStr(ARow.Strings[1],1)) = 'x');

    AFilter.ValueLow := Cardinal(StrToInt(ARow.Strings[2]));

    if ARow.Strings[3] = '' then
      AFilter.ValueHigh := AFilter.ValueLow
    else
      AFilter.ValueHigh := Cardinal(StrToInt(ARow.Strings[3]));
    Result := true;
  except
    on EConvertError do begin
      ARow.Strings[0] := '0';
      ARow.Strings[1] := '';
      ARow.Strings[2] := '0';
      ARow.Strings[3] := '0';
    end;
  end;
end;

procedure TfmFilter.FormCreate(Sender: TObject);
begin
  with sgFilter.Rows[0] do begin
    Add(kMaskStr);
    Add(kMaskExtStr);
    Add(kValueLow);
    Add(kValueHigh);
  end;
end;

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
    LRow.Add(IfThen(LFilter.Ext,'XTD',''));
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
