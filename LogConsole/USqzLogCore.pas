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

unit USqzLogCore;
interface

uses
  SysUtils,
  Generics.Collections,
  Contnrs,
  Classes;

{.$DEFINE USE_PRINTER_OBJ}

const

  kSqzLogStartFrame = $40;
  kSqzLogMoreData   = $80;
  kSqzLogTagPresent = $08;
type

{ exceptions }
  ESqzLogException = class(Exception);
  ESqzSetNotFound = class(ESqzLogException)
    private
    FSetId: Integer;

    public
    constructor Create(ASetId: Integer);
    property SetId: Integer read FSetId;
  end;

  ESqzLogSetParseError = class(ESqzLogException)
    public
    constructor Create;
  end;

  TSqzMsgEntry = class
    private
    FCode: Integer;
    FMsgSet: Integer;
    FParSpec: string;
    FTitle: string;
    public
    constructor Create(ACode: Integer; AParSpec, ATitle: string);
    property Code: Integer read FCode;
    property MsgSet: Integer read FMsgSet write FMsgSet;
    property ParSpec: string read FParSpec;
    property Title: string read FTitle;
  end;

  { forward declaration }
  TSqzMsgSet = class;

  TSqzMsgSetList = class(TObjectList)
    public
    constructor Create;
    function FindSet(ASetId: Integer): TSqzMsgSet;
  end;

  TSqzMsgSet = class
    private
    FMsgSetId: Integer;
    FMsgList: TSqzMsgSetList;
    FAuxLoadList: TStringList;
    FAuxCommaList: TStringList;

    function parseSet(AStr: string): Integer;
    function parseMsg(AStr: string): TSqzMsgEntry;

    public
    constructor Create;
    destructor Destroy; override;
    procedure Load(AName: string);
    function Size: Integer;
    function FindById(AMsgid: Integer): TSqzMsgEntry;

    property MsgSetId: Integer read FMsgSetId;
  end;

  TSqzLogParamType = (
    lpString,
    lpByte,
    lpWord,
    lpDWord
  );

  // TODO 1 -cFIXME questo tipo deve essere sostituito la stringa come array di caratteri non mi piace
  // non ha parti variabili, il delphi è meno flessibile in questo contesto
  TSqzLogParam = record
    public
    spType: TSqzLogParamType;
    spDataString: string;
    spDataInt: Cardinal;
  end;

  TParametersList = TList<TSqzLogParam>;

  TSqzFrame = class
    private
    FParameters: TParametersList;
    FTempPar: TSqzLogParam;
    FStringBuffer: array [0..255] of char;
    FMsgCode: Integer;
    FParSpec: Integer;
    FParCount: Integer;
    FParIdx: Integer;
    FStato: Integer;
    FOpen: Boolean;
    FFrameAuxBuffer: TStringList;
    FFrameSet: TSqzMsgSet;

    // convert standard C format in Delphi format
    function C2DFormat(ACString: string): string;
    function parClose(ACh: Char): Boolean;
    function getText(): string;
    function getValid(): Boolean;

    public
    constructor Create;
    destructor Destroy; override;
    procedure Clear();
    procedure InitFrame(AFrameSet: TSqzMsgSet);
    procedure AddFrameData(var AData: array of byte; ALength: Integer);
    procedure Close();

    property Valid: Boolean read getValid;
    property Text: string read getText;
    property Open: Boolean read FOpen;
  end;

  TSqzPacketOfByte = array of Byte;

  TSqzLogHandler = class
    private
    FProtoV2: Boolean;
    FNodeId: Integer;
    FMsgSets: TSqzMsgSetList;
    FFrame: TSqzFrame;
    FUnitCount: Integer;

    function checkUnitSeq(AData: Byte): Boolean;

    public
    constructor Create(ANodeId: Integer; AMsgSets: TSqzMsgSetList; AProtoV2: Boolean);
    destructor Destroy; override;
    function ProcessSqzData(const AData: array of Byte; const ASize: Integer):
        Boolean;
    function GetLogMessage(): string;

    property NodeId: Integer read FNodeId;
  end;

{$IFNDEF USE_PRINTER_OBJ}

  TSqzLogClass = (
    sqzDebug,
    sqzVerbose,
    sqzMessage,
    sqzWarning,
    sqzError,
    sqzFatal
  );

  TSqzPrintEvent = procedure(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string) of object;
{$ENDIF}

  TSqzLogNetHandler = class
    private
    FProtoV2: Boolean;
    FNodeMask: Cardinal;
    FLogHandlers: TObjectList;
{$IFDEF USE_PRINTER_OBJ}
    FLogPrinters: TSqzLogPrinterList;
{$ELSE}
    FOnPrint: TSqzPrintEvent;
{$ENDIF}
    FMsgSets: TSqzMsgSetList;

    function getNodeFromId(AMsgId: Cardinal): Integer;
    function findNode(ANodeId: Integer): TSqzLogHandler;
    procedure print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
    public
    constructor Create(AProtoV2: Boolean = false);
    destructor Destroy; override;
    procedure AddNode(ANodeId: Integer);
{$IFDEF USE_PRINTER_OBJ}
    procedure AddPrinter(APrinter: TSqzLogPrinter);
{$ENDIF}
    procedure ProcessSqzData(const AId: Cardinal; const AData: array of Byte; ASize:
        Integer);
    procedure AddMsgSet(AFileName: string);
    procedure ClearSets();
{$IFNDEF USE_PRINTER_OBJ}
    property OnPrint: TSqzPrintEvent read FOnPrint write FOnPrint;
{$ENDIF}
    property NodeMask: Cardinal read FNodeMask write FNodeMask;
  end;


implementation
uses
  StrUtils,
  UDbgLogger;

const
  kSETStr = 'SET';
  kMSGStr = 'MSG';

{$REGION 'EXCEPTION imp'}
constructor ESqzSetNotFound.Create(ASetId: Integer);
begin
  inherited CreateFmt('Msgset %d not found',[ASetId]);
  FSetId := ASetId;
end;

constructor ESqzLogSetParseError.Create;
begin
  inherited Create('Msg parse error');
end;

{$ENDREGION}

{$REGION 'TSqzMsgSet'}

function TSqzMsgSet.parseSet(AStr: string): Integer;
var
	LPos: Integer;
begin
	TDbgLogger.Instance.LogDebug('SQZLOG: parse set <%s>',[AStr]);

	LPos := Pos(kSETStr,AStr);
	if LPos = 0 then begin
		TDbgLogger.Instance.LogError('SQZLOG: parseSet Fail');
		raise ESqzLogSetParseError.Create;
	end;

	AStr := Trim(RightStr(AStr,Length(AStr)-(LPos+Length(kSETStr))));

	try
		// uso pos come retVal
		LPos := StrToInt(AStr);
  except
    on E: EConvertError do
  		TDbgLogger.Instance.LogException('SQZLOG: parseSet file format error')
  end;
  Result := LPos;
end;
// ----------------------------------------------------------------------------

function TSqzMsgSet.parseMsg(AStr: string): TSqzMsgEntry;
var
	LPos,
  LId: Integer;
	LSpec,
  LTitle: string;
	LEntry: TSqzMsgEntry;
begin
	TDbgLogger.Instance.LogDebug('SQZLOG: parse set <%s>',[AStr]);
	LPos := Pos(kMSGStr,AStr);

	if LPos = 0 then begin
		TDbgLogger.Instance.LogError('SQZLOG: parseMsg Fail');
		raise ESqzLogSetParseError.Create;
	end;

	FAuxCommaList.CommaText := Trim(RightStr(AStr,Length(AStr)-(LPos+Length(kMSGStr))));
	LEntry := nil;
	try
		LId := StrToInt(Trim(FAuxCommaList.Strings[0]));
		LSpec := Trim(FAuxCommaList.Strings[1]);
		LTitle := Trim(FAuxCommaList.Strings[2]);
		LEntry := TSqzMsgEntry.Create(LId,LSpec,LTitle);
	except
	  on EConvertError do
  		TDbgLogger.Instance.LogException('SQZLOG: parseMsg file format error')
	end;

	Result := LEntry;
end;
// ----------------------------------------------------------------------------

constructor TSqzMsgSet.Create;
begin
  inherited;
	FMsgList := TSqzMsgSetList.Create;
	FAuxLoadList := TStringList.Create;
	FAuxCommaList := TStringList.Create;
end;
// ----------------------------------------------------------------------------

destructor TSqzMsgSet.Destroy;
begin
	FMsgList.Free;
	FAuxLoadList.Free;
	FAuxCommaList.Free;
  inherited;
end;
// ----------------------------------------------------------------------------

procedure TSqzMsgSet.Load(AName: string);
var
	LStr: string;
	LEntry: TSqzMsgEntry;
begin

	FAuxLoadList.LoadFromFile(AName);
	for LStr in FAuxLoadList do begin
		if Pos(kSETStr,Trim(LStr)) = 1 then
			FMsgSetId := parseSet(LStr)
		else if Pos(kMSGStr,Trim(LStr)) = 1 then begin
			LEntry := parseMsg(LStr);
			if LEntry <> nil then begin
        LEntry.MsgSet := FMsgSetId;
				FMsgList.Add(LEntry);
      end;
		end;
	end;
	FAuxLoadList.Clear;
end;
// ----------------------------------------------------------------------------

function TSqzMsgSet.Size;
begin
	Result := FMsgList.Count;
end;
// ----------------------------------------------------------------------------

function TSqzMsgSet.FindById(AMsgId: Integer): TSqzMsgEntry;
var
	I: Integer;
	LEntry: TSqzMsgEntry;
begin
	for I := 0 to FMsgList.Count - 1 do begin
		LEntry := FMsgList.Items[I] as TSqzMsgEntry;

		// non invertire l'ordine del test
		if LEntry.Code = AMsgId then
			Exit(LEntry);
  end;
	Result := nil;
end;
{$ENDREGION}

{$REGION 'TSqzMsgEntry'}

constructor TSqzMsgEntry.Create(ACode: Integer; AParSpec, ATitle: string);
begin
  FCode := ACode;
  FParSpec := AParSpec;
  FTitle := ATitle;
end;

{$ENDREGION}

{$REGION 'TSqzMsgSetList'}

constructor TSqzMsgSetList.Create;
begin
  inherited Create(true);
end;

function TSqzMsgSetList.FindSet(ASetId: Integer): TSqzMsgSet;
var
	I: Integer;
	LSet: TSqzMsgSet;
begin

	for I := 0 to Count - 1 do begin
		LSet := Items[I] as TSqzMsgSet;
		if LSet.MsgSetId = ASetId then
			Exit(LSet);
  end;

  raise ESqzSetNotFound.Create(ASetId);
end;
{$ENDREGION}

{$REGION 'TSqzLogHandler'}
// verifica dello stat frame e
function TSqzLogHandler.checkUnitSeq(AData: Byte): Boolean;
var
  LCountMask: Cardinal;
begin
	Result := true;

  // in proto V2.0 bit 3 is flag for tag presence
  if FProtoV2 then
    LCountMask := 7
  else
    LCountmask := $F;

	if (AData and kSqzLogStartFrame) = 0 then begin
    // is not a start frame check sequence counter
		if FUnitCount <> (AData and LCountMask) then
      Result := false
		else
			FUnitCount := ((FUnitCount + 1) and LCountMask);
	end else
    // if is a start frame I not check sequence counter, simply set it
		FUnitCount := (AData+1) and LCountMask;
end;
// ----------------------------------------------------------------------------

constructor TSqzLogHandler.Create(ANodeId: Integer; AMsgSets: TSqzMsgSetList; AProtoV2: Boolean);
begin
  FProtoV2 := AProtoV2;
  FNodeId := ANodeId;
  FMsgSets := AMsgSets;
  FFrame := TSqzFrame.Create;
end;
// ----------------------------------------------------------------------------

destructor TSqzLogHandler.Destroy;
begin
  FFrame.Free;
end;
// ----------------------------------------------------------------------------

function TSqzLogHandler.ProcessSqzData(const AData: array of Byte; const ASize:
    Integer): Boolean;
var
	LSetId: Integer;
  LArray: array[0..7] of Byte;
  LDataShift,
  I: Integer;
begin
	// lo metto anche se embra inutile perche' i messaggi can possono avere lunghezza nulla
	if ASize = 0 then
		Exit(false);

	TDbgLogger.Instance.LogDebug('SQZLOG: ProcessData <%d>',[ASize]);

	// verifica della sequenza e dello start frame
	if not checkUnitSeq(AData[0]) then begin
		TDbgLogger.Instance.LogWarning('SQZLOG: Fail sequence');
		Exit(false);
	end;

	try
		// verifico start frame
		if (AData[0] and kSqzLogStartFrame) <> 0 then begin
			// se è un nuovo frame lo inizializzo
			// nota nel primo msg l'header è di due byte
			LSetId := ((AData[0] shr 4) and 3) or AData[1];
			// faccio prima clear perchè init può avere un'eccezione
			FFrame.Clear;
			FFrame.InitFrame(FMsgSets.FindSet(LSetId));
      LDataShift := 2;
		end	else
      LDataShift := 1;

    { copio i dati in un array temporaneo per rimuovere i dati inziali }
    for I := 0 to ASize - LDataShift do
      LArray[I] := AData[I+LDataShift];

    // aggiunge i dati al frame attuale
    FFrame.AddFrameData(LArray,ASize-LDataShift);

		// se il frame è terminato
		if (AData[0] and kSqzLogMoreData) = 0 then begin
			FFrame.Close;
			Exit(FFrame.Valid);
		end;
	except
    on E: ESqzSetNotFound do
      TDbgLogger.Instance.LogError('SQZLOG: Set %d not found',[E.SetId]);
    on ESqzLogException do
		  TDbgLogger.Instance.LogException('SQZLOG: TSqzLogHandler.ProcessSqzData');
	end;

	Result := false;
end;
// ----------------------------------------------------------------------------

function TSqzLogHandler.GetLogMessage: string;
begin
	Result := FFrame.Text;
end;
{$ENDREGION}

{$REGION 'TSqzLogNetHandler'}
function TSqzLogNetHandler.getNodeFromId(AMsgId: Cardinal): Integer;
var
  LMask: Cardinal;
begin
  LMask := FNodeMask;
  Result := AMsgId and LMask;
  while (LMask and 1) = 0 do begin
    Result := Result shr 1;
    LMask  := LMask shr 1;
  end;
end;

function TSqzLogNetHandler.findNode(ANodeId: Integer): TSqzLogHandler;
var
	I: Integer;
	LHandler: TSqzLogHandler;
begin
  Result := nil;
	for I := 0 to FLogHandlers.Count -1 do begin
		LHandler := FLogHandlers.Items[I] as TSqzLogHandler;
		if LHandler.NodeId = ANodeId then
			Exit(LHandler);
	end
end;
// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
{$IFDEF USE_PRINTER_OBJ}
var
	I: Integer;
	LPrinter: TSqzLogPrinter;
{$ENDIF}
begin
{$IFDEF USE_PRINTER_OBJ}
	for I := 0 to FLogPrinters.Count - 1 do begin
		LPrinter := FLogPrinters.Printers[I];
		LPrinter.PrintLog(ANodeId, AClass, ATitle);
	end;
{$ELSE}
  if Assigned(FOnPrint) then
    FOnPrint(ANodeId,AClass,ATitle);
{$ENDIF}
end;
// ----------------------------------------------------------------------------

constructor TSqzLogNetHandler.Create(AProtoV2: Boolean);
begin
{$IFDEF USE_PRINTER_OBJ}
	FLogPrinters := TSqzLogPrinterList.Create;
{$ENDIF}
	FLogHandlers := TObjectList.Create;
	FMsgSets := TSqzMsgSetList.Create;
  FProtoV2 := AProtoV2;
end;
// ----------------------------------------------------------------------------

destructor TSqzLogNetHandler.Destroy;
begin
	FMsgSets.Free;
	FLogHandlers.Free;
{$IFDEF USE_PRINTER_OBJ}
	FLogPrinters.Free;
{$ENDIF}
end;
// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.AddNode(ANodeId: Integer);
begin
	if findNode(ANodeId) = nil then
		FLogHandlers.Add(TSqzLogHandler.Create(ANodeId,FMsgSets,FProtoV2));
end;
// ----------------------------------------------------------------------------
{$IFDEF USE_PRINTER_OBJ}
procedure TSqzLogNetHandler.AddPrinter(APrinter: TSqzLogPrinter);
begin
	FLogPrinters.AddPrinter(APrinter);
end;
{$ENDIF}
// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.ProcessSqzData(const AId: Cardinal; const AData:
    array of Byte; ASize: Integer);
var
  LNode: Integer;
  LStr: string;
	LHandler: TSqzLogHandler;
begin
  LNode := getNodeFromId(AId);
	LHandler := findNode(LNode);
	if LHandler = nil then begin
		LHandler := TSqzLogHandler.Create(LNode,FMsgSets,FProtoV2);
		FLogHandlers.Add(LHandler);
	end;

	if LHandler.ProcessSqzData(AData,ASize) then begin
		LStr := LHandler.GetLogMessage;
		if LStr <> '' then
			print(LNode,sqzVerbose,LStr);
	end;
end;

// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.AddMsgSet(AFileName: string);
var
	LSet: TSqzMsgSet;
begin
	TDbgLogger.Instance.LogMessage('SQZLOG: Load set: <%s>',[AFileName]);
  LSet := TSqzMsgSet.Create;
	LSet.Load(AFileName);
	FMsgSets.Add(LSet);
end;
// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.ClearSets;
begin
	FMsgSets.Clear;
end;
{$ENDREGION}

{$REGION 'TSqzFrame'}

function TSqzFrame.C2DFormat(ACString: string): string;
var
  LCh: Char;
  LOutCh: Char;
begin
  // TODO 2 -cFIXME: this function should be more smart to interpret all kind of C formats
  Result := '';
  for LCh in ACString do begin
    if LCh = '0' then
      LOutCh := '.'
    else
      LOutCh := LCh;
    Result := Result + LOutCh;
  end;
end;

function TSqzFrame.parClose(ACh: Char): Boolean;
begin
  Result := false;
	case ACh of
		'x',
		'X',
		'd',
		's',
		'%':
			Result := true;
	end;
end;
// ----------------------------------------------------------------------------

function TSqzFrame.getText(): string;
var
	msgStr,parStr,parFmt: string;
	open: Boolean;
	ch: Char;
	parCount: Integer;
begin

	Assert(FFrameSet <> nil);
	Assert(FFrameSet.FindById(FMsgCode) <> nil);

	msgStr := FFrameSet.FindById(FMsgCode).Title;
	open := false;
	parCount := 0;

	for ch in msgStr do begin
		if not open then begin
			if ch = '%' then begin
				open := true;
				parFmt := ch;
			end else
				FFrameAuxBuffer.Add(ch);
		end	else begin
			parFmt := parFmt + ch;
			parStr := '';
			if parClose(ch) then begin
        // convert standard C format in Delphi format
        parFmt := C2DFormat(parFmt);
				case FParameters[parCount].spType of
					lpString: parStr := Format(parFmt,[FParameters[parCount].spDataString]);
					lpByte,
					lpWord,
					lpDWord: parStr := Format(parFmt,[FParameters[parCount].spDataInt]);
				end;
        if parStr <> '' then
					FFrameAuxBuffer.Add(parStr)
				else
					FFrameAuxBuffer.Add('(NULL)');
				Inc(parCount);
				open := false;
      end;
		end;
	end;

	Result := FFrameAuxBuffer.Text;
end;
// ----------------------------------------------------------------------------

function TSqzFrame.getValid: boolean;
var
  LParam: TSqzLogParam;
	LEntry: TSqzMsgEntry;
	LParSpec: string;
	I: Integer;
begin
	if FMsgCode < 0 then
		// invalid frame, i.e. never opened
		Exit(false);

	Assert(FFrameSet <> nil);
	LEntry := FFrameSet.FindById(FMsgCode);

	assert(LEntry <> nil);

	if LEntry = nil then begin
	  TDbgLogger.Instance.LogWarning('SQZLOG: SqzFrame invalid code %d',[FMsgCode]);
		Exit(false);
	end;

	LParSpec := LEntry.ParSpec;
  I := 1;
	// check parameter consistence

	for LParam in FParameters do begin
		 if (((LParSpec[I] = 'b') and (LParam.spType <> lpByte  )) or
			   ((LParSpec[I] = 'w') and (LParam.spType <> lpWord  )) or
			   ((LParSpec[I] = 'd') and (LParam.spType <> lpDWord )) or
			   ((LParSpec[I] = 's') and (LParam.spType <> lpString))) then begin
				TDbgLogger.Instance.LogWarning('SQZLOG: SqzFrame invalid parameter want:%s',[LParSpec[I]]);
				Exit(false);
     end;
     Inc(I);
     if Length(LParSpec) = I then
        Break;
	end;

    // check parameter count
	if FParameters.Count <> Length(LParSpec) then begin
		TDbgLogger.Instance.LogWarning('SQZLOG: SqzFrame invalid parameter count');
    Exit(false);
	end;

	Result := true;
end;
// ----------------------------------------------------------------------------

constructor TSqzFrame.Create;
begin
  inherited;
  FParameters := TParametersList.Create;
	FFrameAuxBuffer := TStringList.Create;
	FFrameAuxBuffer.LineBreak := '';
end;
// ----------------------------------------------------------------------------

destructor TSqzFrame.Destroy;
begin
	Clear;
	FFrameAuxBuffer.Free;
  FParameters.Free;
  inherited;
end;
// ----------------------------------------------------------------------------

procedure TSqzFrame.Clear;
begin
	FParameters.Clear;
	FFrameAuxBuffer.Clear;
	FMsgCode := -1;
end;
// ----------------------------------------------------------------------------

procedure TSqzFrame.InitFrame(AFrameSet: TSqzMsgSet);
begin
	TDbgLogger.Instance.LogDebug('SQZLOG: init frame');
	Clear;
	FFrameSet := AFrameSet;
	FStato := 0;
	FParCount := 0;
	FOpen := true;
end;
// ----------------------------------------------------------------------------

procedure TSqzFrame.AddFrameData(var AData: array of byte; ALength: Integer);
var
	i: Integer;
	complete: Boolean;
begin
	if not FOpen then
    Exit;

	TDbgLogger.Instance.LogDebug('SQZLOG: AddFrameData size=%d',[ALength]);

	for i := 0 to ALength - 1 do begin
		TDbgLogger.Instance.LogDebug('SQZLOG: frame data d[%d]=0x%.2X s=%d',[i,Cardinal(AData[i]),FStato]);
		case FStato of
			0: begin
          FMsgCode := AData[i];
          FStato := 1;
				end;

			1: begin
          FParSpec := AData[i];
          FStato := 2;
          FParCount := 0;
				end;

			2,
			3:begin
        if FStato = 2 then begin
          FTempPar.spType := TSqzLogParamType(FParSpec and 3);
          TDbgLogger.Instance.LogDebug('SQZLOG: ParDump type <%d>',[Ord(FTempPar.spType)]);
          FParSpec := FParSpec shr 2;
          FParIdx := 0;
          FStato := 3;
				end;

				complete := false;
				case FTempPar.spType of
					lpString: begin
              if AData[i] = 0 then begin
                FTempPar.spDataString := FStringBuffer[FParIdx];
                complete := true;
                TDbgLogger.Instance.LogDebug('SQZLOG: ParDump type <%s>',[FTempPar.spDataString]);
              end else begin
                FStringBuffer[FParIdx] := Char(AData[i]);
                Inc(FParIdx);
              end;
              if FParIdx > 256 then
                FParIdx := 256;
						end;

					lpByte: begin
              FTempPar.spDataInt := AData[i];
              complete := true;
              TDbgLogger.Instance.LogDebug('SQZLOG: ParDump data B:0x%.2X',[FTempPar.spDataInt]);
						end;

					lpWord:
						if FParIdx > 0 then begin
							FTempPar.spDataInt := FTempPar.spDataInt or (Cardinal(AData[i]) shl 8);
							complete := true;
							TDbgLogger.Instance.LogDebug('SQZLOG: ParDump data W:0x%.4X',[FTempPar.spDataInt]);
						end else begin
							FTempPar.spDataInt := AData[i];
							Inc(FParIdx);
						end;

					lpDWord: begin
						if FParIdx = 0 then
							FTempPar.spDataInt := AData[i]
						else
							FTempPar.spDataInt := FTempPar.spDataInt or (Cardinal(AData[i]) shl (FParIdx*8));

            Inc(FParIdx);
						if FParIdx = 4 then begin
							complete := true;
							TDbgLogger.Instance.LogDebug('SQZLOG: ParDump data DW:0x%.8X',[FTempPar.spDataInt]);
            end;
          end;
        end; { case type }
        if complete then begin
          FParameters.Add(FTempPar);
          Inc(FParCount);
          if FParCount = 4 then
            FStato := 1
          else
            FStato := 2;
        end;
      end; { case 3 }
    end; { case }
  end; { for }
  TDbgLogger.Instance.LogDebug('SQZLOG: end frame data process');
end; { procedure }

procedure TSqzFrame.Close;
begin
  FOpen := false;
end;

{$ENDREGION}
end.


