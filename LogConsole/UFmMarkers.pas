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
unit UFmMarkers;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,  ExtCtrls,
  Generics.Collections,
  UCanMsg;

type
  TfmMarkerEdit = class(TForm)
    lbMarkers: TListBox;
    eName: TEdit;
    eMask: TEdit;
    eHigh: TEdit;
    eLow: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    btnAdd: TButton;
    btnDel: TButton;
    btnOK: TButton;
    Label5: TLabel;
    cbColor: TComboBox;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure cbColorDrawItem(Control: TWinControl; Index: Integer; Rect: TRect;
        State: TOwnerDrawState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure lbMarkersClick(Sender: TObject);
  private
    { Private declarations }
    FMarkers: TMarkerList;
    function createMarker(var AMarker: TCanMarker): Boolean;
    procedure setMarkerList(AMarkers: TMarkerList); inline;
  public
    { Public declarations }
    property Markers: TMarkerList read FMarkers write setMarkerList;
  end;

var
  fmMarkerEdit: TfmMarkerEdit;

implementation

uses
  UDbgLogger;

{$R *.dfm}

function TfmMarkerEdit.createMarker(var AMarker: TCanMarker): Boolean;
begin
  Result := true;
  try
    AMarker.Name := eName.Text;
    AMarker.Filter.MaskId := StrToInt(eMask.Text);
    AMarker.Filter.ValueHigh := StrToInt(eHigh.Text);

    if eLow.Text <> '' then
      AMarker.Filter.ValueLow := StrToInt(eLow.Text)
    else
      AMarker.Filter.ValueLow := AMarker.Filter.ValueHigh;

    if cbColor.ItemIndex >= 0 then
      AMarker.Color := TColor(cbColor.Items.Objects[cbColor.ItemIndex])
    else
      raise EConvertError.Create('No color selected');
  except
    on E: EConvertError do begin
      TDbgLogger.Instance.LogException(E.Message);
      Result := false;
    end;
  end;
end;

procedure TfmMarkerEdit.setMarkerList(AMarkers: TMarkerList);
begin
  FMarkers.Assign(AMarkers);
end;

procedure TfmMarkerEdit.FormDestroy(Sender: TObject);
begin
  FMarkers.Free;
end;

procedure TfmMarkerEdit.FormCreate(Sender: TObject);
begin
  FMarkers := TMarkerList.Create;
  cbColor.AddItem('Color 1',TObject(clRed));
  cbColor.AddItem('Color 2',TObject(clLime));
  cbColor.AddItem('Color 3',TObject(clYellow));
  cbColor.AddItem('Color 4',TObject(clAqua));
end;

procedure TfmMarkerEdit.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then begin
    Key := #0;
    ModalResult := mrCancel;
  end;
end;

procedure TfmMarkerEdit.FormShow(Sender: TObject);
var
  LMarker: TCanMarker;
begin
  for LMarker in FMarkers do
    lbMarkers.Items.Add(LMarker.Name)
end;

procedure TfmMarkerEdit.btnAddClick(Sender: TObject);
var
  LMarker: TCanMarker;
  LIdx: Integer;
begin
  if createMarker(LMarker) then begin
    LIdx := lbMarkers.Items.IndexOf(LMarker.Name);
    if LIdx >= 0 then begin
      lbMarkers.Items.Delete(LIdx);
      FMarkers.Delete(LIdx);
    end;
    FMarkers.Add(LMarker);
    lbMarkers.Items.Add(LMarker.Name);
  end;
end;

procedure TfmMarkerEdit.btnDelClick(Sender: TObject);
var
  I: Integer;
  LMarkerName: string;
begin
  if (lbMarkers.ItemIndex >= 0) and (lbMarkers.ItemIndex < lbMarkers.Items.Count) then begin
    LMarkerName := lbMarkers.Items.Strings[lbMarkers.ItemIndex];
    for I := 0 to FMarkers.Count - 1 do
      if LMarkerName = FMarkers[I].Name then begin
        FMarkers.Delete(I);
        Exit;
      end;
  end;
end;

procedure TfmMarkerEdit.cbColorDrawItem(Control: TWinControl; Index: Integer;
    Rect: TRect; State: TOwnerDrawState);
const
  LKOffset = 16;
var
  LBrushColor: TColor;
  LPenColor: TColor;
begin
  with (Control as TComboBox).Canvas do begin
    // clear background
    FillRect(Rect);
    // save old colors
    LBrushColor := Brush.Color;
    LPenColor := Pen.Color;
    // chnege color
    Pen.Color := clBlack;
    Brush.Color := TColor(cbColor.Items.Objects[Index]);
    // draw rectangle
    Rectangle(Rect.Left+2,Rect.Top+2,Rect.Left+LKOffset,Rect.Bottom-4);
    // restore old colors
    Brush.Color := LBrushColor;
    Pen.Color := LPenColor;
    // write text
    TextOut(Rect.Left + LKOffset + 2, Rect.Top+1, (Control as TComboBox).Items[Index]);
  end;
end;

procedure TfmMarkerEdit.lbMarkersClick(Sender: TObject);
var
  LMarker: TCanMarker;
  I: Integer;
begin
  // show marker
  if lbMarkers.ItemIndex >= 0 then begin
    LMarker := FMarkers.Items[lbMarkers.ItemIndex];
    eName.Text := LMarker.Name;
    eMask.Text := Format('0x%.8X',[LMarker.Filter.MaskId]);
    eHigh.Text := Format('0x%.8X',[LMarker.Filter.ValueHigh]);
    eLow.Text  := Format('0x%.8X',[LMarker.Filter.ValueLow]);
    for I := 0 to cbColor.Items.Count - 1  do
      if TColor(cbColor.Items.Objects[I]) = LMarker.Color then begin
        cbColor.ItemIndex := I;
        Break;
      end;
  end;
end;

end.
