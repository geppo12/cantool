unit UCore;

interface

uses
  Classes,
  Contnrs,
  Generics.Collections,
  SysUtils;

type

{enum {
	lpByte=1,
	lpWord,
	lpDWord,
	lpString=8
}

  ELogError = class(Exception);
  ELogNullMessage = class(ELogError);

  TLogParSpecVector = TList<Char>;

  TLogMsg = class
    private
    FLogTitle: string;
    FParSpec: string;
    FLogCode: Integer;
    FCrc: Integer;

    public
    constructor Create(ACode: Integer; AParSpec, ATitle: string; ACrc: Integer);
    function ToString: string; override;

    property LogCode: Integer read FLogCode;
    property LogTitle: string read FLogTitle;
    property Crc: Integer read FCrc;
    property ParSpec: string read FParSpec;
  end;
//-----------------------------------------------------------------------------

  TLogEntryData = class
    protected
      // is a refernce to object in the main list
      FLogMsg: TLogMsg;
      FParameters: TStringList;

      function getParSpec: string; virtual;

    public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure Assign(AEntry: TLogEntryData); virtual;
  end;
  //-----------------------------------------------------------------------------

  TLogEntry = class(TLogEntryData)
    private
      FLine: Integer;
      FPreStr: string;
      function getLogTitle: string;
      function getLogCode: Integer;
      function getCrc: Integer;

    public
      function ToMacro: string; virtual;
      property Line: Integer read FLine write FLine;
      property PreStr: string read FPreStr write FPreStr;
  end;
//-----------------------------------------------------------------------------

  TLogEntryBuilder = class(TLogEntryData)
    private
      FParSpec: TLogParSpecVector;
      FMsgList: TStringList;
      FCodeId: Integer;
      FNewCode: Boolean;
      function getParSpec: string; override;
      function calcCrc(AStr: string): Byte;

    public
      constructor Create(AMsgList: TStringList);
      destructor Destroy; override;
      procedure Clear; override;
      procedure Reset;
      procedure SetTitle(ATitle: string);
      procedure AddParSpec(AType: Char);
      procedure AddParameter(APar: string);
      function GetEntry: TLogEntry;
  end;
//-----------------------------------------------------------------------------

  TLogEntryList = class
    private
    FEntryVector: TObjectList;
    function getLogEntry(idx: Integer): TLogEntry;
    function getCount: Integer;

    public
    constructor Create;
    destructor Destroy; override;
    procedure AddEntry(AEntry: TLogEntry);
    procedure Clear;
    property LogEntries[AIdx: Integer]: TLogEntry read getLogEntry;
    property Count: Integer read getCount;
  end;
//-----------------------------------------------------------------------------

  TLogFileProcessor = class
    private
    FEntryList: TLogEntryList;
    FEntryBuilder: TLogEntryBuilder;
    FParserErrorList: TStringList;
    FLineParserAux: TStringList;
    //*  Flag la gestione del singolo error
    FError: Boolean;
    FSrcFile: string;
    FSrcLineIdx: Integer;
    //* Contatore delle perentesi all' interno del commento
    FParCount: Integer;
    //function getLogMsg(ATitle: string): TLogMsg; #OC
    function isBlank(ACh: Char): Boolean;
    procedure parseError(AError: string);
    procedure addParameter;
    function parseLogLine(AString: string): TLogEntry;
    function canDeleteEntry(str: string): Boolean;
    function getParseErrors: TStrings;

    public
    constructor Create(AMsgList: TStringList);
    destructor Destroy; override;

    {* Pulisce dalle vecchie entry.
       @param AList lista che rappresenta il file }
    procedure Clean(AList: TStringList);
    {* Fa il parsing del file sotto forma di stringlist
       @param ALogEntryList puntatore alla lista delle entry da riempire
       @param AList lista che rappresenta il file }
    procedure Parse(ALogEntryList: TLogEntryList; AStrList: TStringList);
    {* Aggiorna il file sulla delle entry relative alla lista presente
       @param ALogEntryList lista utilizzata per aggiornare la string list
       @param AList lista da aggiornare }
    procedure Update(ALogEntryList: TLogEntryList; AList: TStringList);
    procedure Reset;

    // TODO 1 -cFIXME : sistemare i nomi della proprieta e della variabile
    property ParseErrors: TStrings read getParseErrors;
    property SrcFile: string read FSrcFile write FSrcFile;
  end;
//-----------------------------------------------------------------------------

  TSrcFile = class
    private
    FFileLines: TStringList;
    FFileName: string;
    FEntryList: TLogEntryList;

    public
    constructor Create(AName: string);
    destructor Destroy; override;
    procedure Process(AProcessor: TLogFileProcessor);
    procedure Clean(AProcessor: TLogFileProcessor);
    procedure Load;
    procedure Save;
    property Name: string read FFileName;
  end;
//-----------------------------------------------------------------------------

  TLogProcessor = class
	private
    FMsgSet: Integer;
    FFileProcessor: TLogFileProcessor;
    FSrcFileList: TStringList;
    FMsgFileList: TStringList;	// lista dei messaggi generati da salvare
    FMsgList: TStringList;		// lista dei messaggi come TLogMsg

    function getParseErrors: TStrings;

    public
    constructor Create;
    destructor Destroy; override;
    procedure AddFile(AName: string);
    procedure RemFile(AName: string);
    procedure Reset;
    procedure Clear;
    procedure ProcessFiles(cleanOnly: Boolean);
    procedure GenerateMsgFile(AFileName: string);

    property ParseErrors: TStrings read getParseErrors;
    property MsgSet: Integer read FMsgSet write FMsgSet;
  end;

implementation

uses
  StrUtils,
  ULogOptions,
  UDbgLogger;

const
  kSQZLOG_MARKER = '//@@SQZLOG';
  kSQZLOG_MATCH  = '__SQZLOG_SQUEEZE_IT';
  kSQZLOG_MACRO  = '__SQZLOG_SQUEEZE_IT__';
  kSQZLOG_MACRO_NO_PAR = '__SQZLOG_SQUEEZE_IT_NP__';

  kDefineStr = '#define';
  kUndefStr  = '#undef';
  kSETStr	   = 'SET %d';

constructor TLogMsg.Create(ACode: Integer; AParSpec, ATitle: string; ACrc: Integer);
begin
  FLogCode := ACode;
  FParSpec := AParSpec;
  FLogTitle := ATitle;
  FCrc     := ACrc;
end;

function TLogMsg.ToString: string;
begin

//	if (parSpec.IsEmpty)
//		parSpec = "";

	if TLogOptions.Instance.Crc then
		Result := Format('MSG %d,"%s","%s",%d',
			[LogCode,
			ParSpec,
			LogTitle,
			FCrc])
	else
		Result := Format('MSG %d,"%s","%s"',
			[LogCode,
			ParSpec,
			LogTitle]);
end;

{$REGION 'TLogEntryData'}
function TLogEntryData.getParSpec: string;
begin
	if FLogMsg <> nil then
		Exit(FLogMsg.ParSpec);

	raise ELogNullMessage.Create('Null message in TLogEntryData.getParSpec');
end;

constructor TLogEntryData.Create;
begin
	FParameters := TStringList.Create;
end;
// ----------------------------------------------------------------------------

destructor TLogEntryData.Destroy;
begin
	FParameters.Free;
end;

procedure TLogEntryData.Clear;
begin
  FParameters.Clear;
end;

// ----------------------------------------------------------------------------

procedure TLogEntryData.Assign(AEntry: TLogEntryData);
begin
	FParameters.AddStrings(AEntry.FParameters);
	FLogMsg := AEntry.FLogMsg;
end;
{$ENDREGION}

{$REGION 'TLogEntry'}

function TLogEntry.getLogTitle: string;
begin
	if FLogMsg <> nil then
		Exit(FLogMsg.LogTitle);

	raise ELogNullMessage.Create('Null message in TLogEntry.getLogTitle');
end;
// ----------------------------------------------------------------------------

function TLogEntry.getLogCode: Integer;
begin
	if FLogMsg <> nil then
		Exit(FLogMsg.LogCode);

	raise ELogNullMessage.Create('Null message in TLogEntry.getLogCode');
end;
// ----------------------------------------------------------------------------

function TLogEntry.getCrc: Integer;
begin
	if FLogMsg <> nil then
		Exit(FLogMsg.Crc);

	raise ELogNullMessage.Create('Null message in TLogEntry.getCrc');
end;
// ----------------------------------------------------------------------------

function TLogEntry.ToMacro: string;
var
	par,str,parSpec: string;
	i: Integer;
begin
	parSpec := getParSpec;

	if parSpec = '' then begin
		str := PreStr + kSQZLOG_MACRO_NO_PAR + '(';
		str := str + IntToStr(getLogCode) + ');';
	end	else begin
		if TLogOptions.Instance.DoublePar then
			str := PreStr + kSQZLOG_MACRO + '(('
		else
			str := PreStr + kSQZLOG_MACRO + '(';

		str := str + IntToStr(getLogCode) + ',';

		if TLogOptions.Instance.Crc then
			str := str + IntToStr(getCrc) + ',';

		str := str + '"' + parSpec + '"';

		for par in FParameters do
			str := str + ',' + par;

		if TLogOptions.Instance.DoublePar then
			str := str + '));'
		else
			str := str + ');';
	end;
	Result := str;
end;
{$ENDREGION}

{$REGION 'TLogEntryBuilder'}
function TLogEntryBuilder.getParSpec: string;
var
	str: string;
  LChar: Char;
begin
	for LChar in FParSpec do
		str := str + LChar;
	Result := str;
end;
//-----------------------------------------------------------------------------

function TLogEntryBuilder.calcCrc(AStr: string): Byte;
var
  LCh: Char;
begin
  Result := 0;
  for LCh in Astr do
		Result := Result + Ord(LCh);
end;
//-----------------------------------------------------------------------------

constructor TLogEntryBuilder.Create(AMsgList: TStringList);
begin
  inherited Create;
  FParSpec := TLogParSpecVector.Create;
	FMsgList := AMsgList;
	FCodeId  := 0;
end;
//-----------------------------------------------------------------------------

destructor TLogEntryBuilder.Destroy;
begin
  FParSpec.Free;
end;
//-----------------------------------------------------------------------------

procedure TLogEntryBuilder.Clear;
begin
	inherited;
	FParSpec.clear;
	FLogMsg := nil;
	FNewCode := false;
end;
//-----------------------------------------------------------------------------

procedure TLogEntryBuilder.Reset;
begin
	FCodeId := 0;
end;
//-----------------------------------------------------------------------------

procedure TLogEntryBuilder.SetTitle(ATitle: string);
var
	idx, crc: Integer;
begin
	idx := FMsgList.IndexOf(ATitle);
	if idx < 0 then begin
		crc := calcCrc(ATitle);
		FLogMsg := TLogMsg.Create(FCodeId,getParSpec,ATitle,crc);
		// comunque mi segno che ho generato un nuovo id;
		FNewCode := true;
		FMsgList.AddObject(ATitle,FLogMsg);
	end	else
		FLogMsg := FMsgList.Objects[idx] as TLogMsg;

end;
//-----------------------------------------------------------------------------

procedure TLogEntryBuilder.AddParSpec(AType: Char);
begin
	FParSpec.Add(AType);
end;
//-----------------------------------------------------------------------------

procedure TLogEntryBuilder.AddParameter(APar: string);
begin
	FParameters.Add(APar);
end;
//-----------------------------------------------------------------------------

function TLogEntryBuilder.GetEntry: TLogEntry;
begin
	if FNewCode then
		Inc(FCodeId);

	Result := TLogEntry.Create;
	Result.Assign(self);
end;
{$ENDREGION}

{$REGION 'TLogEntryList'}
function TLogEntryList.getLogEntry(idx: Integer): TLogEntry;
begin
	Result := FEntryVector.Items[idx] as TLogEntry;
end;
// ----------------------------------------------------------------------------

function TLogEntryList.getCount: Integer;
begin
  Result := FEntryVector.Count;
end;
// ----------------------------------------------------------------------------

constructor TLogEntryList.Create;
begin
  FEntryVector := TObjectList.Create(true);
end;
// ----------------------------------------------------------------------------

destructor TLogEntryList.Destroy;
begin
	FEntryVector.Free;
end;
// ----------------------------------------------------------------------------

procedure TLogEntryList.AddEntry(AEntry: TLogEntry) ;
begin
	FEntryVector.Add(AEntry);
end;
// ----------------------------------------------------------------------------

procedure TLogEntryList.Clear;
begin
	FEntryVector.Clear;
end;
{$ENDREGION}

{$REGION 'TLogFileProcessor'}

function TLogFileProcessor.isBlank(ACh: Char): Boolean;
begin
	Result := (ACh = #9) or (ACh = #$20) or (ACh = #10) or (ACh = #13);
end;
// ----------------------------------------------------------------------------

procedure TLogFileProcessor.parseError(AError: string);
var
	msgString: string;
begin
	msgString := Format('ERROR: file %s, line %d, %s',[FSrcFile,FSrcLineIdx+1,AError]);
	FParserErrorList.Add(msgString);
	FError := true;
end;
// ----------------------------------------------------------------------------

procedure TLogFileProcessor.addParameter;
begin
	TDbgLogger.Instance.LogDebug('PARSE_LINE: addPar(%s)',[FLineParserAux.Text]);
	FEntryBuilder.AddParameter(FLineParserAux.Text);
	FLineParserAux.Clear;
end;

function TLogFileProcessor.parseLogLine(AString: string): TLogEntry;
var
	LCh: Char;
	LStato: Integer;
	LEnd,LValid,LAddChar: Boolean;
	LEntry: TLogEntry;
  LLog: TDbgLogger;
begin
  LStato := 0;
  LEntry := nil;
  LEnd := false;
  LValid := false;
  LLog := TDbgLogger.Instance;

	FLineParserAux.Clear;
	FEntryBuilder.Clear;
	FError := false;

	LLog.LogDebug('PARSE_LINE: STR:%s',[AString]);

	for LCh in AString do begin
		LLog.LogDebug('PARSE_LINE: ST:%d, CH:%s',[LStato,LCh]);
		case LStato of
			0:
				if LCh = '(' then begin
					FParCount := 1;
					LStato := 1;
				end else if not isBlank(LCh) then begin
          LLog.LogDebug('PARSE_LINE: syntax error');
					parseError('Synatx Error');
					Break;
				end;
			1:
				if (LCh = '"') then
					LStato := 2
				else if not isBlank(LCh) then begin
          LLog.LogDebug('PARSE_LINE: syntax error');
					parseError('Synatx Error');
					Break;
        end;

			2:
				case LCh of
					'"': begin
						LStato := 3;
						FEntryBuilder.SetTitle(FLineParserAux.Text);
						FLineParserAux.Clear;
          end;

					'%': LStato := 4;

					else
						// uso TString list come StringBuffer di java xche è più veloce
						FLineParserAux.Add(LCh);
        end; { end inner case }

			// end title and parameter processing
			3:
				case LCh of
					',': LStato := 5;
					'(': Inc(FParCount);
					')': begin
              Dec(FParCount);
              if FParCount = 0 then begin
                // termine LEntry, valida
                LValid := true;
                Break;
              end;
            end;

					else
						if not isBlank(LCh) then begin
              LLog.LogDebug('PARSE_LINE: syntax error');
							parseError('Synatx Error');
							LEntry.Free;
							LEntry := nil;
							Break;
						end;
        end; {end inner case }

			// decodifica parametri
			4: begin
  				LAddChar := true;
          case LCh of
            'b',
            'w',
            'd': FLineParserAux.Add('%d');

            // string is in delphi syntax because console is written in delphi
            'B': FLineParserAux.Add('0x%.2X');
            'W': FLineParserAux.Add('0x%.4X');
            'D': FLineParserAux.Add('0x%.8X');
            's': FLineParserAux.Add('%s');
            else begin
              LLog.LogDebug('PARSE_LINE: Wrong parameter spec');
              parseError('Wrong parameter spec');
              LAddChar := false;
              Break;
            end;
          end;
          if LAddChar then begin
            LLog.LogDebug('PARSE_LINE: addParSpec(%s)',[LCh]);
            FEntryBuilder.AddParSpec(LCh);
            LStato := 2;
          end;
        end; {end status 4 }

			// inserimento di un singolo parametro
			5:
				case LCh of
					'(': begin
              Inc(FParCount);
              FLineParserAux.Add(LCh);
            end;

					',': addParameter;

					')': begin
              // se il conteggio delle parentesi e zero
              // aggiunge il parametro, atrimenti prosegue ed
              // aggiunge il carattere al parametro attuale
              Dec(FParCount);
              if FParCount = 0 then begin
                LValid := true;
                addParameter;
                Break;
              end else
                FLineParserAux.Add(LCh)
            end; { end char ')' }
					else
            FLineParserAux.Add(LCh)
        end; { end inner case }
    end; {end state case }
  end; { end for }

	if not LValid then begin
		if not FError then begin
      LLog.LogDebug('Unexpetted end of line');
			parseError('Unexpetted end of line');
    end;
		Result := nil;
	end else
	// e creo fisicamente l'entry
  	Result := FEntryBuilder.GetEntry;
end;
// ----------------------------------------------------------------------------

function TLogFileProcessor.getParseErrors: TStrings;
begin
  Result := FParserErrorList;
end;
// ----------------------------------------------------------------------------


function TLogFileProcessor.canDeleteEntry(str: string): Boolean;
begin
  Result := true;
	if Pos(kDefineStr,str) > 0 then
		Result := false
	else if Pos(kUndefStr,str) > 0 then
		Result := false;
end;
// ----------------------------------------------------------------------------

constructor TLogFileProcessor.Create(AMsgList: TStringList);
begin
	FEntryBuilder := TLogEntryBuilder.Create(AMsgList);
	FParserErrorList := TStringList.Create;
  // TODO 1 -cFIXME : Delphi XE ha TStringBuider valutare se cambiarlo
	FLineParserAux := TStringList.Create;
	// viene usata come TStringBuilder e quindi non ha senso un linebreak
	FLineParserAux.LineBreak := '';
end;
// ----------------------------------------------------------------------------

destructor TLogFileProcessor.Destroy;
begin
	FParserErrorList.Free;
	FLineParserAux.Free;
	FEntryBuilder.Free;
end;
// ----------------------------------------------------------------------------

procedure TLogFileProcessor.Clean(AList: TStringList);
var
	I: Integer;
begin
	for I := AList.Count - 1 downto 0 do begin
		if Pos(kSQZLOG_MATCH,AList.Strings[I]) > 0 then
			// che si possa cancellare
			if canDeleteEntry(AList.Strings[I]) then
				AList.Delete(I);
	end;
end;
// ----------------------------------------------------------------------------

procedure TLogFileProcessor.Parse(ALogEntryList: TLogEntryList; AStrList: TStringList);
var
	LIdx,LPos: Integer;
	LStrCycle,LStr,LPre: string;
	LEntry: TLogEntry;
begin
	FSrcLineIdx := 0;
  LIdx := 0;

	for LStrCycle in AStrList do begin
		LPos := Pos(kSQZLOG_MARKER,LStrCycle);
		if LPos > 0 then begin
      // remove the marker and process the string
      Dec(LPos);
			LPre := LeftStr(LStrCycle,LPos);
			LStr := Trim(RightStr(LStrCycle,Length(LStrCycle)-(LPos+Length(kSQZLOG_MARKER))));
			FSrcLineIdx := LIdx;
			LEntry := parseLogLine(LStr);
      // if string is valid we create an entry
			if LEntry <> nil then begin
				LEntry.Line := LIdx;
				LEntry.PreStr := LPre;
				ALogEntryList.AddEntry(LEntry);
			end;
		end;
    // increment line index
    Inc(LIdx);
	end;
end;
// ----------------------------------------------------------------------------

procedure TLogFileProcessor.Update(ALogEntryList: TLogEntryList; AList: TStringList);
var
	idx, pos, lineError: Integer;
	entry: TLogEntry;
begin
  lineError := 0;

	if FParserErrorList.Count = 0 then begin
    for idx := 0 to ALogEntryList.Count - 1 do begin
      entry := ALogEntryList.LogEntries[idx];
      AList.Insert(entry.Line+lineError+1,entry.ToMacro);
      Inc(lineError);
    end;
  end;
end;
// ----------------------------------------------------------------------------

procedure TLogFileProcessor.Reset;
begin
	FParserErrorList.Clear;
	FEntryBuilder.Reset;
end;
{$ENDREGION}

{$REGION 'TSrcFile'}
constructor TSrcFile.Create(AName: string);
begin
  FFileName := AName;
	FFileLines := TStringList.Create;
	FEntryList := TLogEntryList.Create;
end;
// ----------------------------------------------------------------------------

destructor TSrcFile.Destroy;
begin
	FFileLines.Free;
	FEntryList.Free;
end;
// ----------------------------------------------------------------------------

procedure TSrcFile.Process(AProcessor: TLogFileProcessor);
begin
  AProcessor.SrcFile := ExtractFileName(FFileName);
	AProcessor.Clean(FFileLines);
	AProcessor.Parse(FEntryList,FFileLines);
	AProcessor.Update(FEntryList,FFileLines);
end;
// ----------------------------------------------------------------------------

procedure TSrcFile.Clean(AProcessor: TLogFileProcessor);
begin
	AProcessor.Clean(FFileLines);
end;
// ----------------------------------------------------------------------------

procedure TSrcFile.Load;
begin
	FEntryList.Clear;
	if FFileName <> '' then
		FFileLines.LoadFromFile(FFileName);
end;
// ----------------------------------------------------------------------------

procedure TSrcFile.Save;
begin
	if FFileName <> '' then
		FFileLines.SaveToFile(FFileName);
end;
{$ENDREGION}

{$REGION 'TLogProcessor'}

function TLogProcessor.getParseErrors: TStrings; 
begin
  Result := FFileProcessor.ParseErrors;
end;
// ----------------------------------------------------------------------------

constructor TLogProcessor.Create;
begin
	FSrcFileList := TStringList.Create(true);
	FMsgFileList := TStringList.Create;
	FMsgList     := TStringList.Create(true);	
  FFileProcessor := TLogFileProcessor.Create(FMsgList);
end;
// ----------------------------------------------------------------------------

destructor TLogProcessor.Destroy;
begin
  // TODO 1 -cFIXME : vedere se è necessario
	Clear;
	FFileProcessor.Free;
	FMsgList.Free;
	FMsgFileList.Free;
	FSrcFileList.Free;
end;
// ----------------------------------------------------------------------------

procedure TLogProcessor.AddFile(AName: string);
begin
	FSrcFileList.AddObject(AName,TSrcFile.Create(AName));
end;
// ----------------------------------------------------------------------------

procedure TLogProcessor.RemFile(AName: string);
var
  LIdx: Integer;
begin
	LIdx := FSrcFileList.IndexOf(AName);
	FSrcFileList.Objects[LIdx].Free;
	FSrcFileList.Delete(LIdx);
end;
// ----------------------------------------------------------------------------

procedure TLogProcessor.Reset;
begin
	FMsgList.Clear;
end;
// ----------------------------------------------------------------------------

procedure TLogProcessor.Clear;
begin
	FSrcFileList.Clear;
	Reset;
end;
// ----------------------------------------------------------------------------

procedure TLogProcessor.ProcessFiles(cleanOnly: Boolean);
var
	i,j: Integer;
	str: string;
	LFile: TSrcFile;
	list: TLogEntryList;
begin
	FFileProcessor.Reset;
	for i := 0 to FSrcFileList.Count - 1 do begin
		LFile := FSrcFileList.Objects[i] as TSrcFile;
		if LFile <> nil then begin
			TDbgLogger.Instance.LogDebug('Process File %s',[LFile.Name]);
			LFile.Load;
			if cleanOnly then
				LFile.Clean(FFileProcessor)
			else
				LFile.Process(FFileProcessor);

			if FFileProcessor.ParseErrors.Count = 0 then
				LFile.Save();
		end;
	end;
end;
// ----------------------------------------------------------------------------

procedure TLogProcessor.GenerateMsgFile(AFileName: string);
var
	// N.B. se == 1 c'e' solo il comando set
	str: string;
	entry: TLogMsg;
	dbgObj: TObject;
	i: Integer;
begin
	FMsgFileList.Clear();
	str := Format(kSETStr,[MsgSet]);
	FMsgFileList.Add(str);

	for i := 0 to FMsgList.Count - 1 do begin
    entry := FMsgList.Objects[i] as TLogMsg;
		if entry <> nil then
			FMsgFileList.Add(entry.ToString());
	end;
	FMsgFileList.SaveToFile(AFileName);
end;

end.
