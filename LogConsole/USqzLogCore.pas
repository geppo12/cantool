unit USqzLogCore;
interface

uses
  Generics.Collections,
  Contnrs,
  Classes,
  UCanMsg,
  USqzLogPrint;

type

  // TODO 2 -cFIXME : creare classe generale
  TSqzByteArray = class
    private
    FArray: array of Byte;
    FSize: Integer;
    FLength: Integer;

    function getData(AIndex: Integer): Byte;

    public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure AddByte(AByte: Byte);
    procedure AddByteArray(AArray: array of Byte; ALen: Integer);

    property Data[AIndex: Integer]: Byte read getData; default;
    property Length: Integer read FLength;
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
    spDataInt: Integer;
  end;

//typedef std::vector<TSqzLogParam> TSqzLogParamVect;
  TSqzLogParamVect = TList<TSqzLogParam>;

  TSqzFrame = class
    private
    FParameters: TSqzLogParamVect;
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

    function parClose(ACh: Char): Boolean;
    function getNextParam(AParam: TSqzLogParam): Boolean;
    function getText(): string;
    function getValid(): Boolean;

    public
    constructor Create;
    destructor Destroy; override;
    procedure Clear();
    procedure InitFrame(AFrameSet: TSqzMsgSet);
    procedure AddFrameData(AData: array of byte; ALength: Integer);
    procedure Close();

    property Valid: Boolean read getValid;
    property Text: string read getText;
  end;

  TSqzLogHandler = class
    private
    FNodeId: Integer;
    FMsgSets: TSqzMsgSetList;
    FFrame: TSqzFrame;
    FUnitCount: Integer;
    FSyncLost: Boolean;

    function checkUnitSeq(AData: Byte): Boolean;

    public
    constructor Create(ANodeId: Integer; AMsgSets: TSqzMsgSetList);
    function ProcessSqzMsg(AMsg: TCanMsg): Boolean;
    function ProcessSqzData(AData: array of Byte; LSize: Integer): Boolean;
    function GetLogMessage(): string;

    property NodeId: Integer read FNodeId;
  end;

  TSqzLogNetHandler = class
    private
    FLogHandlers: TObjectList;
    FLogPrinters: TSqzLogPrinterList;
    FMsgSets: TSqzMsgSetList;

    function findNode(ANodeId: Integer): TSqzLogHandler;
    procedure print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
    public
    constructor Create;
    destructor Destroy; override;
    procedure AddNode(ANodeId: Integer);
    procedure AddPrinter(APrinter: TSqzLogPrinter);
    procedure ProcessSqzMsg(AMsg: TCanMsg);
    procedure AddMsgSet(AFileName: string);
    // TODO 1 -cFEATURE : 	implementare procedure SetProtoV2(bool AProtoV2)
    //procedure SetProtoV2(AProtoV2: Boolean); {}
    procedure ClearSets();
  end;


implementation
uses
  StrUtils,
  SysUtils,
  UDbgLogger;

const
  kSETStr = 'SET';
  kMSGStr = 'MSG';

{$REGION 'TSqzByteArray'}
function TSqzByteArray.getData(AIndex: Integer): Byte;
begin
  Result := FArray[AIndex];
end;

constructor TSqzByteArray.Create;
begin
  Clear;
end;

destructor TSqzByteArray.Destroy;
begin
  // TODO 3 -cCHECK: cancella l'array, non sono sicuro che serva
  SetLength(FArray,0);
end;

procedure TSqzByteArray.Clear;
begin
  // TODO 1 -cFIXME : togliere costante hardcoded
  FSize := 8;
  FLength := 0;
  SetLength(FArray,FSize);
end;

procedure TSqzByteArray.AddByte(AByte: Byte);
begin
  if FLength = FSize then begin
    FSize := FSize * 2;
    SetLength(Farray,FSize);
  end;
  FArray[FLength] := AByte;
  Inc(FLength);
end;

procedure TSqzByteArray.AddByteArray(AArray: array of Byte; ALen: Integer);
var
  I: Integer;
begin
  for I := 0 to ALen - 1 do
    AddByte(AArray[I]);
end;
{$ENDREGION}

{$REGION 'TSqzMsgSet'}

function TSqzMsgSet.parseSet(AStr: string): Integer;
var
	LPos: Integer;
  LStr: string;
begin
	TDbgLogger.Instance.LogDebug('SQZLOG: parse set <%s>',[AStr]);

	LPos := Pos(kSETStr,AStr);
	if LPos = 0 then begin
		TDbgLogger.Instance.LogError('SQZLOG parseSet Fail');
		// TODO -cFIXME  2 : mettere eccezione + specifica
		raise Exception.Create('parseSet fail');
	end;

  // TODO 1 -cFIXME : verificare  la stringa risultante
	LStr := Trim(RightStr(AStr,Length(AStr)-(LPos+Length(kSETStr))));

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
{$IFDEF USE_SMARTINSPECT}
	TDbgLogger.Instance.LogDebug('SQZLOG: parse set <%s>',[AStr]);
{$ENDIF}
  Result := nil;
	LPos := Pos(kMSGStr,AStr);

	if LPos = 0 then begin
{$IFDEF USE_SMARTINSPECT}
		TDbgLogger.Instance.LogError('SQZLOG parseMsg Fail');
{$ENDIF}
		// TODO -cFIXME  2 : mettere eccezione + specifica
		raise Exception.Create('parseMsg fail');
	end;

  // TODO 1 -cFIXME : verificare  la stringa risultante
	FAuxCommaList.CommaText := Trim(RightStr(AStr,Length(AStr)-(LPos+Length(kMSGStr))));
	LEntry := nil;
	try
		LId := StrToInt(Trim(FAuxCommaList.Strings[0]));
		LSpec := Trim(FAuxCommaList.Strings[1]);
		LTitle := Trim(FAuxCommaList.Strings[2]);
		LEntry := TSqzMsgEntry.Create(LId,LSpec,LTitle);
	except
	  on EConvertError do
{$IFDEF USE_SMARTINSPECT}
  		TDbgLogger.Instance.LogException('SQZLOG: parseMsg file format error')
{$ENDIF};
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

  // TODO 1 -cFIXME : creare eccezione
	//raise ESetNotFound.Create(ASetId);
  raise Exception.Create(Format('ESetNotFound %d',[ASetId]));
end;
{$ENDREGION}

{$REGION 'TSqzLogHandler'}
// verifica dello stat frame e
function TSqzLogHandler.checkUnitSeq(AData: Byte): Boolean;
begin
	Result := true;

	if (AData and $40) <> 0 then begin
		FSyncLost := false;
		FUnitCount := (AData+1) and  $0f;
	end else begin
		if FUnitCount <> (AData and $0f) then
			FSyncLost := true
		else
			FUnitCount := ((FUnitCount + 1) and $0F);

    if FSyncLost then
      Result := false;
  end;
end;
// ----------------------------------------------------------------------------

constructor TSqzLogHandler.Create(ANodeId: Integer; AMsgSets: TSqzMsgSetList);
begin
  FNodeId := ANodeId;
  FMsgSets := AMsgSets;
end;
// ----------------------------------------------------------------------------

function TSqzLogHandler.ProcessSqzMsg(AMsg: TCanMsg): Boolean;
begin
	Result := ProcessSqzData(AMsg.ecmData,AMsg.ecmLen);
end;
// ----------------------------------------------------------------------------

function TSqzLogHandler.ProcessSqzData(AData: array of Byte; LSize: Integer): Boolean;
var
	LSet: TSqzMsgSet;
	LSetId: Integer;
  LArray: array[0..7] of Byte;
  LDataShift,
  I: Integer;
begin
	// lo metto anche se embra inutile perche' i messaggi can possono avere lunghezza nulla
	if LSize = 0 then
		Exit(false);

	TDbgLogger.Instance.LogDebug('SQZLOG: ProcessData <%d>',[LSize]);

	// verifica della sequenza e dello start frame
	if not checkUnitSeq(AData[0]) then begin
		TDbgLogger.Instance.LogWarning('SQZLOG: Fail sequence');
		Exit(false);
	end;

	try
		// verifico start frame
		if (AData[0] and $40) <> 0 then begin
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
    for I := 0 to LSize - LDataShift do
      LArray[I] := AData[I+LDataShift];

    // aggiunge i dati al frame attuale
    FFrame.AddFrameData(LArray,LSize-LDataShift);

		// se il frame è terminato
		if (AData[0] and $80) = 0 then begin
			FFrame.Close;
			Exit(FFrame.Valid);
		end;
	except
    // TODO 1 -cFIXME : creare eccezione
    //on E: ESetNotFound do
    on E: Exception do
		  TDbgLogger.Instance.LogWarning(E.Message)
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
var
	I: Integer;
	LPrinter: TSqzLogPrinter;
begin
	for I := 0 to FLogPrinters.Count - 1 do begin
		LPrinter := FLogPrinters.Printers[I];
		LPrinter.PrintLog(ANodeId, AClass, ATitle);
	end;
end;
// ----------------------------------------------------------------------------

constructor TSqzLogNetHandler.Create;
begin
	FLogPrinters := TSqzLogPrinterList.Create;
	FLogHandlers := TObjectList.Create;
	FMsgSets := TSqzMsgSetList.Create;
end;
// ----------------------------------------------------------------------------

destructor TSqzLogNetHandler.Destroy;
begin
	FMsgSets.Free;
	FLogHandlers.Free;
	FLogPrinters.Free;
end;
// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.AddNode(ANodeId: Integer);
begin
	if findNode(ANodeId) = nil then
		FLogHandlers.Add(TSqzLogHandler.Create(ANodeId,FMsgSets));
end;
// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.AddPrinter(APrinter: TSqzLogPrinter);
begin
	FLogPrinters.AddPrinter(APrinter);
end;
// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.ProcessSqzMsg(AMsg: TCanMsg);
var
	LNodeId: Integer;
	LStr: string;
	LHandler: TSqzLogHandler;
begin
  LNodeId := AMsg.getNode;
	LHandler := findNode(LNodeId);
	if LHandler = nil then begin
		LHandler := TSqzLogHandler.Create(LNodeId,FMsgSets);
		FLogHandlers.Add(LHandler);
	end;

	if LHandler.ProcessSqzMsg(AMsg) then begin
		LStr := LHandler.GetLogMessage;
		if LStr <> '' then
			print(LNodeId,sqzVerbose,LStr);
	end;
end;

// ----------------------------------------------------------------------------

procedure TSqzLogNetHandler.AddMsgSet(AFileName: string);
var
	LSet: TSqzMsgSet;
begin
{$IFDEF USE_SMARTINSPECT}
	TDbgLogger.Instance.LogMessage('SQZLOG: Load set: <%s>',[AFileName]);
{$ENDIF}
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

function TSqzFrame.getNextParam(AParam: TSqzLogParam): Boolean;
begin
  // TODO 1 -cFUNCTION : function TSqzFrame.getNextParam(AParam: TSqzLogParam): Boolean;
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
	FFrameAuxBuffer := TStringList.Create;
	FFrameAuxBuffer.LineBreak := '';
end;
// ----------------------------------------------------------------------------

destructor TSqzFrame.Destroy;
begin
	Clear;
	FFrameAuxBuffer.Free;
  inherited;
end;
// ----------------------------------------------------------------------------

procedure TSqzFrame.Clear;
var
  LParam: TSqzLogParam;
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

procedure TSqzFrame.AddFrameData(AData: array of byte; ALength: Integer);
var
	i: Integer;
	s: string;
	complete: Boolean;
begin
	if not FOpen then begin
		TDbgLogger.Instance.LogDebug('SQZLOG: add data to a closed frame');
		Exit;
	end;

	TDbgLogger.Instance.LogDebug('SQZLOG: AddFrameData size=%d',[ALength]);

	for i := 0 to ALength - 1 do begin
    // TODO 1 -cCHECK : verificare cast
		TDbgLogger.Instance.LogDebug('SQZLOG: frame data d[%d]=0x%.2X s=%d',[i,Integer(AData[i]),FStato]);
		case FStato of
			0: begin
          // TODO 1 -cCHECK : verificare cast
          FMsgCode := Integer(AData[i]);
          FStato := 1;
				end;

			1: begin
          // TODO 1 -cCHECK : verificare cast
          FParSpec := Integer(AData[i]);
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
                // TODO 1 -cCHECK : verificare cast
                FTempPar.spDataString := string(FStringBuffer[FParIdx]);
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
              // TODO 1 -cCHECK : verificare cast
              FTempPar.spDataInt := Integer(AData[i]);
              complete := true;
              TDbgLogger.Instance.LogDebug('SQZLOG: ParDump data B:0x%.2X',[FTempPar.spDataInt]);
						end;

					lpWord:
						if FParIdx > 0 then begin
							FTempPar.spDataInt := FTempPar.spDataInt or (Integer(AData[i]) shl 8);
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
							FTempPar.spDataInt := FTempPar.spDataInt or (Integer(AData[i]) shl (FParIdx*8));

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
end; { procedure }

procedure TSqzFrame.Close;
begin
  FOpen := false;
end;

{$ENDREGION}
end.


