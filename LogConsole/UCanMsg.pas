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
  Generics.Collections;

type
  TCanMsg = record
    private
    function formatData(AChar: Char): string;
    function getDataStr: string; inline;

    public
    ecmTime: Int64;
    ecmID: Cardinal;
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
    ValueId: Cardinal;
  end;

  TCanMsgList = class
    private
    FMapList: TList<Integer>;
    FMsgList: TList<TCanMsg>;
    FFilter: TCanMsgFilter;
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

    property Filter: TCanMsgFilter read FFilter write FFilter;
    property Filtered: Boolean read FFiltered write setFiltered;
    property Messages[AIndex: Integer]: TCanMsg read getMessages;
    property Count: Integer read getCount;
  end;

  // TODO 1 -cFIXME : inserire un parametro size invariante rispetto al count
  // TODO 1 -cFIXME : count (read-only) dipende dal FList.Count e da size (vedi sopra)
  TCanMsgView = class
    private
    FList: TCanMsgList;
    FCount: Integer;
    FTop: Integer;

    function getMessages(AIndex: Integer): TCanMsg;
    procedure setTop(ATop: Integer);
    procedure setCount(ACount: Integer);

    public
    constructor Create(AList: TCanMsgList);
    property Messages[AIndex: Integer]: TCanMsg read getMessages;
    property Top: Integer read FTop write setTop;
    property Count: Integer read FCount write setCount;
  end;

  TCanMsgViewFiltered = class(TCanMsgView)
    public
      constructor Create(AList: TCanMsgList; AFilter: TCanMsgFilter);
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
  Result := Format('ID=0x%08X L=%d D=',[ecmId,ecmLen]);
  Result := formatData('.');
end;

procedure TCanMsg.ToStrings(AStrings: TStrings);
begin
  AStrings.Strings[0] := Format('0x%.8X',[ecmId]);
  AStrings.Strings[1] := IntToStr(ecmLen);
  AStrings.Strings[2] := formatData(' ');
end;

{$ENDREGION}

{$REGION 'TCanMsgList'}

function TCanMsgList.filterMatch(AMsg: TCanMsg): Boolean;
begin
  Result := (AMsg.ecmID and FFilter.MaskId) = FFilter.ValueId;
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
end;

destructor TCanMsgList.Destroy;
begin
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
  LMin := 0;
  LMax := FMapList.Count - 1;

  // make veri fast binary search
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

{$REGION 'TCanMsgView'}
function TCanMsgView.getMessages(AIndex: Integer): TCanMsg;
begin
  Result := FList.Messages[AIndex + FTop];
end;

procedure TCanMsgView.setTop(ATop: Integer);
begin
  if FTop <> ATop then begin
    if ATop >= (FList.Count - FCount) then
      ATop := FList.Count - FCount;
    FTop := ATop;
  end;
end;

procedure TCanMsgView.setCount(ACount: Integer);
begin
  if FCount <> ACount then begin
    if ACount > FList.Count then
      ACount := FList.Count;
    FCount := ACount;
  end;
end;

constructor TCanMsgView.Create(AList: TCanMsgList);
begin
  FList := AList;
  FList.Filtered := false;
end;

{$ENDREGION}

{$REGION 'TCanMsgViewFiltered'}
constructor TCanMsgViewFiltered.Create(AList: TCanMsgList; AFilter: TCanMsgFilter);
begin
  FList := AList;
  FList.Filter := AFilter;
  FList.Filtered := true;
end;
{$REGION}

end.
