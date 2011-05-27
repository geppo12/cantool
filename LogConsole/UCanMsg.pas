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

unit UCanMsg;

{$IFDEF DEBUG}
{$INLINE OFF}
{$ENDIF}

interface

Uses
  Classes,
  Graphics,
  Generics.Collections;

type
  TCanMsg = record
    private
    function formatData(AChar: Char): string;
    function getDataStr: string; inline;

    public
    ecmTime: Int64;
    ecmID: Cardinal;
    ecmExt: Boolean;
    ecmLen: Cardinal;
    ecmData: array [0..7] of Byte;
    function ToString: string;
    procedure ToStrings(AStrings: TStrings);

    property DataStr: string read getDataStr;
  end;

  TCanMsgQueue = TQueue<TCanMsg>;

  TCanMsgFilter = record
    public
    MaskId: Cardinal;
    Ext: Boolean;       // extended ID
    ValueLow: Cardinal;
    ValueHigh: Cardinal;
    function Match(AMsg: TCanMsg): Boolean;
  end;

  TCanMsgFilterList = TList<TCanMsgFilter>;

  TCanMsgList = class
    private
    FMapList: TList<Integer>;
    FMsgList: TList<TCanMsg>;
    FFilterList: TCanMsgFilterList;
    FFiltered: Boolean;

    function filterMatch(AMsg: TCanMsg): Boolean; inline;
    procedure setFiltered(AFiltered: Boolean);
    function getMessages(AIndex: Integer): TCanMsg;
    function getCount: Integer; inline;

    public
    constructor Create;
    destructor Destroy; override;
    procedure Add(ACanMsg: TCanMsg);
    //* Convert index from fitered domanin to unfiltered domain and viceversa
    function ConvertIndex(AIndex: Integer): Integer;

    property FilterList: TCanMsgFilterList read FFilterList;
    property Filtered: Boolean read FFiltered write setFiltered;
    property Messages[AIndex: Integer]: TCanMsg read getMessages;
    property Count: Integer read getCount;
  end;

  TCanMarker = record
    Name: string;
    Filter: TCanMsgFilter;
    Color: TColor;
  end;

  TMarkerList = class(TList<TCanMarker>)
    public
    procedure Assign(AMarkers: TMarkerList);
  end;

  TCanMsgView = class
    private
    FMarkers: TMarkerList;
    FList: TCanMsgList;
    FViewSize: Integer;
    FTop: Integer;

    function getMessages(AIndex: Integer): TCanMsg;
    function getColor(AIndex: Integer): TColor;
    procedure setMarkers(AMarkers: TMarkerList); inline;
    procedure setTop(ATop: Integer);
    function getCount: Integer;

    public
    constructor Create(AList: TCanMsgList);
    destructor Destroy; override;
    procedure Update;
    property Messages[AIndex: Integer]: TCanMsg read getMessages;
    property Color[AIndex: Integer]: TColor read getColor;
    property Markers: TMarkerList read FMarkers write setMarkers;
    property Top: Integer read FTop write setTop;
    property Count: Integer read getCount;
    property ViewSize: Integer read FViewSize write FViewSize;
  end;

implementation

uses
  SysUtils,
  StrUtils,
  UDbgLogger;

{$REGION 'TCanMsg'}

function TCanMsg.formatData(AChar: Char): string;
var
  I: Integer;
begin
  for I := 0 to ecmLen - 1 do
    Result := Result + Format('%.2X'+AChar,[ecmData[i]]);

  Result := LeftStr(Result,Length(Result)-1);
end;

function TCanMsg.getDataStr: string;
begin
  Result := formatData(' ');
end;

function TCanMsg.ToString: string;
var
  I: Integer;
begin
  Result := Format('ID=0x%.8X%s L=%d',[ecmId,IfThen(ecmExt,'XTD',''),ecmLen]);
  if ecmLen > 0 then
    Result := Result+' D='+formatData('.');
end;

procedure TCanMsg.ToStrings(AStrings: TStrings);
begin
  AStrings.Strings[0] := Format('0x%.8X%s',[ecmId,IfThen(ecmExt,' XTD','')]);
  AStrings.Strings[1] := IntToStr(ecmLen);
  AStrings.Strings[2] := formatData(' ');
end;
{$ENDREGION}

{$REGION 'TCanMsgFilter'}
function TCanMsgFilter.Match(AMsg: TCanMsg): Boolean;
var
  LMaskedId: Cardinal;
begin
  LMaskedId := AMsg.ecmID and MaskId;
  Result := ((LMaskedId >= ValueLow) and (LMaskedId <= ValueHigh) and (AMsg.ecmExt = Ext));
end;
{$ENDREGION}

{$REGION 'TCanMsgList'}
function TCanMsgList.filterMatch(AMsg: TCanMsg): Boolean;
var
  LFilter: TCanMsgFilter;
begin
  Result := false;
  for LFilter in FFilterList do
    if LFilter.Match(AMsg) then
      Exit(true);
end;

procedure TCanMsgList.setFiltered(AFiltered: Boolean);
var
  I: Integer;
begin
  if FFiltered <> AFiltered then begin
    FFiltered := AFiltered;
    if AFiltered then begin
      FMapList.Clear;
      for I := 0 to FMsgList.Count - 1 do
        if filterMatch(FMsgList.Items[I]) then
          FMapList.Add(I);
    end;
  end;
end;

function TCanMsgList.getMessages(AIndex: Integer): TCanMsg;
begin
  if FFiltered then
    AIndex := FMapList.Items[AIndex];

  Result := FMsgList.Items[AIndex]
end;

function TCanMsgList.getCount: Integer;
begin
  if FFiltered then
    Result := FMapList.Count
  else
    Result := FMsgList.Count;
end;


constructor TCanMsgList.Create;
begin
  inherited;
  FMsgList := TList<TCanMsg>.Create;
  FMapList := TList<Integer>.Create;
  FFilterList := TCanMsgFilterList.Create;
end;

destructor TCanMsgList.Destroy;
begin
  FFilterList.Free;
  FMapList.Free;
  FMsgList.Free;
  inherited;
end;

procedure TCanMsgList.Add(ACanMsg: TCanMsg);
var
  LRawIndex: Integer;
begin
  LRawIndex := FMsgList.Add(ACanMsg);
  if FFiltered and filterMatch(ACanMsg) then
    FMapList.Add(LRawIndex);
end;

function TCanMsgList.ConvertIndex(AIndex: Integer): Integer;
var
  LMin,
  LMax,
  LMid: Integer;
begin
  if FMapList.Count = 0 then
    Exit(0);

  LMin := 0;
  LMax := FMapList.Count - 1;

  // very fast binary search
  repeat
    LMid := (LMin + LMax) div 2;
    if AIndex > FMapList.Items[LMid] then
      LMin := LMid + 1
    else
      LMax := LMid - 1;
  until (AIndex = FMapList.Items[LMid]) or (LMin > LMax);

  Result := LMid;
end;
{$ENDREGION}


{$REGION ''}
procedure TMarkerList.Assign(AMarkers: TMarkerList);
var
  LMarker: TCanMarker;
begin
  Clear;
  for LMarker in AMarkers do
    Add(LMarker);
end;
{$ENDREGION}

{$REGION 'TCanMsgView'}
function TCanMsgView.getMessages(AIndex: Integer): TCanMsg;
begin
  Result := FList.Messages[AIndex + FTop];
end;

function TCanMsgView.getColor(AIndex: Integer): TColor;
var
  LMarker: TCanMarker;
begin
  Result := clWhite;
  for LMarker in FMarkers do
    if LMarker.Filter.Match(Messages[AIndex]) then
      Exit(LMarker.Color);
end;

procedure TCanMsgView.setMarkers(AMarkers: TMarkerList);
begin
  FMarkers.Assign(AMarkers);
end;

procedure TCanMsgView.setTop(ATop: Integer);
begin
  if FTop <> ATop then begin
    if ATop >= (FList.Count - Count) then
      ATop := FList.Count - Count;
    FTop := ATop;
  end;
end;

function TCanMsgView.getCount: Integer;
begin
  if FList.Count < FViewSize then
    Result := FList.Count
  else
    Result := FViewSize;
end;

constructor TCanMsgView.Create(AList: TCanMsgList);
begin
  FList := AList;
  FList.Filtered := false;
  FMarkers := TMarkerList.Create;
end;

destructor TCanMsgView.Destroy;
begin
  FMarkers.Free;
end;

procedure TCanMsgView.Update;
begin
  Top := FList.ConvertIndex(Top);
end;

{$ENDREGION}

end.
