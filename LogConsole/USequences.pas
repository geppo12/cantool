unit USequences;

interface

uses
  Classes,
  UCanMsg,
  USplitterStr;

type

  TSeqObj = class
    private
    FName: string;

    public
    constructor Create(AName: string);
    //__fastcall TSeqObj(AnsiString& AName) : FName(AName) {}
    property Name: string read FName;
  end;

  TTriggerEventType = (
    kTriggerTimeEv,
    kTriggerMsgEv
  );

  TTriggerEvent = record
    case EventType: TTriggerEventType of
      kTriggerTimeEv: (Timeout: Cardinal);
      kTriggerMsgEv: (Msg: TCanMsg);
  end;

  TSequenceParser = class;

  TTerminateState = (
    kTerminateSuccess,
    kTerminateFail
  );

  TSeqSendMsgEv = procedure(AMsg: TCanMsg) of object;
  TSeqOutTextEv = procedure(AText: string) of object;

  TSequenceEngine = class
    strict private
    FOnSendMessage: TSeqSendMsgEv;
    FOnOutText: TSeqOutTextEv;
    FRunning: Boolean;
    FTerminateState: TTerminateState;
    FCurrentIndex: Integer;
    FSequences: TStringList;
    FParser: TSequenceParser;

    function getCount: Integer; { return FSequences->Count; }
    private
    procedure SendMsg(ACanMsg: TCanMsg);
    procedure SendOutText(AText: string);

    public
    constructor Create;
    destructor Destroy; override;
    procedure AddSequence(ASequence: TSeqObj);
    {* Imposta la sequenza corrente. Chiamare le funzioni operative sulla sequenza
       con una sequenza non impostata può creare problemi o crash.

       @param AName nome della sequenza

       @returns
       successo se la sequenza è correttamente impostata.}
    function SetupSequence(AName: string): Boolean;
    procedure Clear;
    procedure LoadNames(ANameList: TStrings);
    procedure Start;
    function Terminate: TTerminateState;

    // operazioni sulle sequenze
    procedure Reset;
    function ExecuteStep: Boolean;
    procedure Trigger(AEvent: TTriggerEvent);

    property OnSendMessage: TSeqSendMsgEv read FOnSendMessage write FOnSendMessage;
    property OnOutText: TSeqOutTextEv read FOnOutText write FOnOutText;
    property TerminateState: TTerminateState read FTerminateState;
    property Running: Boolean read FRunning;
    property Count: Integer read getCount;
    property Parser: TSequenceParser read FParser;
  end;

  TSequenceParser = class
  	private
    FScript: TStringList;
    FAuxList: TStringList;
    FDefineList: TStringList;
    FSplitter: TSplitterStr;
    FSeqEngine: TSequenceEngine;

    procedure parseScript;
    //procedure parseSymbol(AStr: string); #OC
    procedure addSymbol(AName, AValue: string);
    function replaceSymbol(AStr: string): string;
    // nextPos e la prima posizione dopo la keyword
    function findKeyword(AStr: string): Integer;
    function createSequenceObj(AName: string): TSeqObj;

    public
    constructor Create(AEngine: TSequenceEngine);
    destructor Destroy; override;
    procedure LoadFromFile(AName: string);
  end;

implementation

uses
  Generics.Defaults,
  Generics.Collections,
  Contnrs,
  SysUtils,
  StrUtils,
  Character,
  Windows,
  Types,
  UDbgLogger;

const
  kForeverStr = 'FOREVER';

  kKeywordTableSize = 18;
  kKeywordTable: array [0..kKeywordTableSize-1] of string = (
    'SEQUENCE',
    'DEFINE',
    'SENDMSG',
    'WAITMSG',
    'SELECT',
    'CASE',
    'BREAK',
    'EXPIRED',
    'DEFAULT',
    'ENDSEL',
    'DELAY',
    'LOOP',
    'ENDLOOP',
    'EXITLOOP',
  	'PRINT',
    'ABORT',
    'CLEARQUEUE',
    'ENDSEQ'
  );

type
{$REGION 'Local Classes'}
  TSeqKeywordID = (
    kKeyINVALID = -1,
    kKeySequence,
    kKeyDefine,
    kKeySendmsg,
    kKeyWaitmsg,
    kKeySelect,
    kKeyCase,
    kKeyBreak,
    kKeyExpired,
    kKeyDefault,
    kKeyEndsel,
    kKeyDelay,
    kKeyLoop,
    kKeyLoopend,
    kKeyExitloop,
    kKeyPrint,
    kKeyAbort,
    kKeyClearQueue,
    kKeyEndseq
  );

  TSeqEngineStatus = (
    stsIdle,
    stsStartSeq,
    stsAddMsg
  );

  TSeqCanMsgObj = class
    strict private
    class var FAuxStringList: TStringList;

    private
    FCanMsg: TCanMsg;
    FMaskMsg: TCanMsg;
    procedure parse(var ACanMsg: TCanMsg; AStr: string);

    public
    class constructor Create;
    class destructor Destroy;
    constructor Create(ACanMsg: TCanMsg); overload;
    constructor Create(ACanMsgObj: TSeqCanMsgObj); overload;
    constructor Create(ACanMsgStr: string); overload;
    function Match(AMsg: TCanMsg): Boolean; overload;
    function ToString: string; override;
    property CanMsg: TCanMsg read FCanMsg;
  end;

  // forward declaration
  TSequence = class;
  TSeqEl = class;

  TTriggerObject = class
    private
    FOwner: TSeqEl;

    protected
    property Owner: TSeqEl read FOwner;

    public
    constructor Create(AOwner: TSeqEl);
    function Activate(AEvent: TTriggerEvent): Boolean; virtual; abstract;
    //property Owner: TSeqEl read FOwner;
  end;

  TTriggerMsg = class(TTriggerObject)
    private
    FMsgObj: TSeqCanMsgObj;
    FCanMsg: TCanMsg;


    public
    constructor Create(AEl: TSeqEl; AMsgObj: TSeqCanMsgObj);
    destructor Destroy; override;
    function Activate(AEvent: TTriggerEvent): Boolean; override;
  end;

  TSelectEl = class;

  TTriggerSelect = class(TTriggerObject)
    public
    function Activate(AEvent: TTriggerEvent): Boolean; override;
  end;

  TTriggerTime = class(TTriggerObject)
    public
    FTimeout: Cardinal;

    public
    constructor Create(AEl: TSeqEl; ADelay: Cardinal);
    function Activate(AEvent: TTriggerEvent): Boolean; override;

    property Timeout: Cardinal read FTimeout;
  end;

  TTriggerEngine = class
    private
    FTriggerList: TObjectList<TTriggerObject>;
    FTimeout: Cardinal;

    function getWaiting: Boolean; inline;

    public
    constructor Create;
    destructor Destroy; override;
    {* add a trigger object
       @param AObj trigger object to add }
    procedure AddTrigger(AObj: TTriggerObject);
    {* trigger the engine
       @param AObj object to trigger engine }
    procedure Trigger(AEvent: TTriggerEvent);
    procedure Reset;
    {* used to update time ticks }
    procedure TimeTicks; inline;
    property Waiting: Boolean read getWaiting;
  end;

  // root class per gli elementi di sequenza.
  TSeqEl = class
    private
    FMsgObj: TSeqCanMsgObj;
    // program a qui è posizionato questo elemento;
    FAddress: Integer;
    // indirizzo di salto forward utilizzato da alcuni costrutti
    FEndAddress: Integer;

    protected
    FOwnerSeq: TSequence;
    procedure InitMsgObj(AStr: string);
    procedure DoGoto(AAddress: Integer);
    procedure SetEndAddress(AElement: TSeqEl; AAddress: Integer);
    function GetEndAddress(AElement: TSeqEl): Integer; overload;
    function GetEndAddress: Integer; overload;
    function GetMsgObj: TSeqCanMsgObj;

    public
    constructor Create(AOwner: TSequence);
    function GetAddress: Integer;
    function MatchMsg(AMsg: TCanMsg): Boolean;
    // timeout viene eseguita in caso di scedenza di un timeout impostato
    procedure Timeout; virtual;
    procedure Execute; virtual;
    // chiamata da quegli elementi che defono fare operazioni subito dopo che
    // l' elemento è stato aggiunto ad una sequenza;
    procedure Compile; virtual;
    function StringEl: string; virtual;
    function TriggerCallback(AEvent: TTriggerEvent): Boolean; virtual;
  end;

  // statment MSG
  TMsgEl = class(TSeqEl)
    public
    constructor Create(AStr: string; AOwner: TSequence); //      TSeqEl(AOwner) { InitMsgObj(AStr); }
    procedure Compile; override;
    procedure Execute; override;
  end;

  // statment DELAY
  TDelayEl = class(TSeqEl)
    private
    FDelay: Integer;

    public
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Timeout; override;
    procedure Execute; override;
  end;

  // statment WAITMSG (trigger)
  TWaitEl = class(TSeqEl)
  	public
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Execute; override;
  end;

  // statment CASE
  TCaseEl = class(TSeqEl)
    public
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Compile; override;
  end;

  // statment BREAK
  TBreakEl = class(TSeqEl)
	public
    procedure Execute; override;
  end;

  // statment EXPIRED
  TExpiredEl = class(TSeqEl)
	public
    procedure Compile; override;
  end;

  // statment DEFAULT
  TDefaultEl = class(TSeqEl)
    public
    procedure Compile; override;
  end;

  // statment ENDSEL
  TEndselEl = class(TSeqEl)
    public
    procedure Compile; override;
    procedure Execute; override;
  end;

  // statment SELECT
  TSelectEl = class(TSeqEl)
    private
    FTimeout: Integer;
    FCaseList: TObjectList;
    FDefaultEl: TSeqEl;
    FExpiredEl: TSeqEl;

    function lookForCase(AMsg: TCanMsg): TCaseEl;

    public
    constructor Create(AStr: string; AOwner: TSequence);
    destructor Destroy; override;
    procedure Compile; override;
    procedure Execute; override;
    procedure Timeout(); override;
    function TriggerCallback(AEvent: TTriggerEvent): Boolean; override;
    procedure AddCase(ACaseEl: TCaseEl);
    procedure SetDefault(AElement: TSeqEl);
    procedure SetExpired(AElement: TSeqEl);
  end;

  // statment LOOP
  TLoopEl = class(TSeqEl)
    private
    FMaxCount: Integer;
    FCount: Integer;

    public
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Compile; override;
    procedure Execute; override;
    function DecCount: Boolean;
  end;

  // statment ENDLOOP
  TEndLoopEl = class(TSeqEl)
    public
    procedure Compile; override;
    procedure Execute; override;
  end;

  // statment EXITLOOP
  TExitLoopEl = class(TSeqEl)
    public
    procedure Compile; override;
  end;

  // statment ABORT
  TAbortEl = class(TSeqEl)
    private
    FTerminateResult: TTerminateState;
    public
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Execute; override;
  end;

  // statment PRINT
  TPrintEl = class(TSeqEl)
    private
    FText: string;
    public
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Execute; override;
  end;

  // statment ENDSEQ
  TEndSeqEl = class(TSeqEl)
    public
    procedure Compile; override;
  end;

  // statment CLEARQUEUE
  TClearQueueEl = class(TSeqEl)
    public
    procedure Execute; override;
  end;

  TSequence = class(TSeqObj)
    private
    FEngine: TSequenceEngine;
    FTriggerEngine: TTriggerEngine;
    FIncomingEventQueue: TQueue<TCanMsg>;
    FData: TObjectList<TSeqEl>;
    FSequenceResult: TTerminateState;
    FProgramCounter: Integer;
    FTriggerList: TObjectList<TTriggerObject>;
    FEndSequence: TSeqEl;
    FLoopStack: TStack<TSeqEl>;
    FSelectStack: TStack<TSeqEl>;

    procedure clearData;
    function getCount: Integer;

    public
    constructor Create(AName: string; AEngine: TSequenceEngine);
    destructor Destroy; override;
    procedure SendMsg(ACanMsg: TCanMsg); inline;
    procedure SendOutText(AText: string); inline;
    procedure Add(AElement: TSeqEl);
    function GetCurrentAddress: Integer;
    procedure Reset;
    procedure SetResult(AResult: TTerminateState);
    function GetResult: TTerminateState;
    function ExecuteStep: Boolean;
    procedure Trigger(AEvent: TTriggerEvent); inline;
    procedure AddTrigger(ATrigger: TTriggerObject); inline;
    procedure ClearIncomingEvents;
    function IsValid(): Boolean;
    procedure DoGoto(ANewAddress: Integer); inline;
    procedure SetLoop(ALoop: TSeqEl);
    function GetLoop: TLoopEl;
    procedure EndLoop;
    procedure SetSelect(AElement: TSeqEl);
    function GetSelect: TSelectEl;
    procedure EndSelect;
    procedure EndSequence(AElement: TSeqEl);
    function GetEndSequence: TEndSeqEl;
  end;

  ECreateError = class(Exception)
	  public
    constructor Create(AError: string);
  end;
  ECompileError = class(Exception);

{$ENDREGION}
{ IMPLEMENTATION }

{$REGION 'TSeqCanMsgObj'}
procedure TSeqCanMsgObj.parse(var ACanMsg: TCanMsg; AStr: string);
var
  LDataStr: TStringDynArray;
	value: string;
	retVal: Boolean; // = true;
	i: Integer;

  procedure setDataValue(ADataStr: string; AIndex:  Integer);
  begin
    if ADataStr = '*' then begin
      FMaskMsg.ecmData[AIndex] := 0;
      FCanMsg.ecmData[AIndex]  := 0;
      // +1 because FCanMsg.ecmLen will be inc at the end of cycle
      FMaskMsg.ecmLen := FCanMsg.ecmLen+1;
    end else
      FCanMsg.ecmData[AIndex]  := StrToInt(ADataStr);
  end;

begin
	TDbgLogger.Instance.EnterMethod(self,'parse');
	TDbgLogger.Instance.LogVerbose('SEQ: Parse msg <%s>',[AStr]);

  FAuxStringList.DelimitedText := AStr;
  try
    value := FAuxStringList.Values['ID'];
    if value <> '' then
      FCanMsg.ecmId := StrToInt(value)
    else
      raise EConvertError.Create('MSG: convert ID error');

    value := FAuxStringList.Values['MASK-ID'];
    if value <> '' then
      FMaskMsg.ecmId := StrToInt(value);

    value := FAuxStringList.Values['DATA'];
    { check for data in form 'DATA=xx,xx,xx,xx }
    if value <> '' then begin
      LDataStr := SplitString(value,',');
      FCanMsg.ecmLen := Length(LDataStr);
      for I := 0 to FCanMsg.ecmLen-1 do
        setDataValue(LDataStr[I],i)
    end else begin
      { get data in form D0=xx D1=XX }
      FCanMsg.ecmLen := 0;
      for i := 0 to 7 do begin
        value := FAuxStringList.Values['D'+IntToStr(i)];
        if value <> '' then
          setDataValue(value,i)
        else if FAuxStringList.IndexOfName('DO') > 0 then
          raise EConvertError.Create('Use zero instead O letter into D number')
        else
          Break;
      end;
    end;
  finally
  	TDbgLogger.Instance.LeaveMethod(self,'parse');
  end;
end;

class constructor TSeqCanMsgObj.Create;
begin
  FAuxStringList := TStringList.Create;
end;

class destructor TSeqCanMsgObj.Destroy;
begin
  FAuxStringList.Free;
end;

constructor TSeqCanMsgObj.Create(ACanMsg: TCanMsg);
begin
  FCanMsg := ACanMsg;
end;

constructor TSeqCanMsgObj.Create(ACanMsgObj: TSeqCanMsgObj);
begin
  FCanMsg  := ACanMsgObj.FCanMsg;
  FMaskMsg := ACanMsgObj.FMaskMsg;
end;

constructor TSeqCanMsgObj.Create(ACanMsgStr: string);
var
  I: Integer;
begin
  // reset mask
  FMaskMsg.ecmID := $FFFFFFFF;
  for I := 0 to 7 do
    FMaskMsg.ecmData[I] := $FF;

  try
    parse(FCanMsg,ACanMsgStr)
  except
    on E: EConvertError do begin
      TDbgLogger.Instance.LogWarning('TSeqMsgObj parse error: %s',[E.Message]);
      raise ECreateError.Create('obj: TSeqCanMsgObj');
    end;
    on Exception do raise ECreateError.Create('obj: TSeqCanMsgObj');
  end;
end;

function TSeqCanMsgObj.Match(AMsg: TCanMsg): Boolean;
var
  I: Integer;
begin
  Result := true;
  with FMaskMsg do begin
    if (FCanMsg.ecmID and ecmID) <> (AMsg.ecmID and ecmID) then
      Exit(false);

    if AMsg.ecmLen < ecmLen then
      Exit(false);

    for I := 0 to ecmLen - 1 do begin
        if (FCanMsg.ecmData[I] and ecmID) <> (AMsg.ecmdata[I] and ecmID) then
          Exit(false);
    end;
  end;
end;

function TSeqCanMsgObj.ToString: string;
begin
  Result := FCanMsg.ToString + ' mask: ' + FMaskMsg.ToString;
end;

{$ENDREGION}

{$REGION 'Trigger implementation'}
// trigger msg

constructor TTriggerObject.Create(AOwner: TSeqEl);
begin
  FOwner := AOwner;
end;

constructor TTriggerMsg.Create(AEl: TSeqEl; AMsgObj: TSeqCanMsgObj);
begin
  inherited Create(AEl);
  FMsgObj := AMsgObj;
end;

destructor TTriggerMsg.Destroy;
begin
  FMsgObj.Free;
end;

function TTriggerMsg.Activate(AEvent: TTriggerEvent): Boolean;
begin
  if (FMsgObj <> nil) and (AEvent.EventType = kTriggerMsgEv) then
    Result := FMsgObj.Match(AEvent.Msg)
  else
    Result := false;
end;

// trigger select
function TTriggerSelect.Activate(AEvent: TTriggerEvent): Boolean;
begin
  if AEvent.EventType = kTriggerMsgEv then
    Result := Owner.TriggerCallback(AEvent)
  else
    Result := false;
end;

// trigger time
constructor TTriggerTime.Create(AEl: TSeqEl; ADelay: Cardinal);
begin
  inherited Create(AEl);
  FTimeout := GetTickCount + ADelay;
end;

function TTriggerTime.Activate(AEvent: TTriggerEvent): Boolean;
begin
  if AEvent.EventType = kTriggerTimeEv then begin
    Result := AEvent.Timeout >= FTimeout;
    if Result then
      Owner.TriggerCallback(AEvent);
  end else
    Result := false;
end;

// Engine
function TTriggerEngine.getWaiting: Boolean;
begin
  Result := FTriggerList.Count > 0;
end;

constructor TTriggerEngine.Create;
begin
  FTriggerList := TObjectList<TTriggerObject>.Create;
  FTimeout := MaxInt;
end;


destructor TTriggerEngine.Destroy;
begin
  FTriggerList.Free;
end;

procedure TTriggerEngine.AddTrigger(AObj: TTriggerObject);
begin
  TDbgLogger.Instance.LogVerbose('SEQ: Add trigger %s',[AObj.ToString]);
  FTriggerList.Add(AObj);
  if AObj is TTriggerTime then begin
    if TTriggerTime(AObj).Timeout < FTimeout then
      FTimeout := TTriggerTime(AObj).Timeout;
  end;
end;

procedure TTriggerEngine.Trigger(AEvent: TTriggerEvent);
var
  LTrigger: TTriggerObject;
  FFound: Boolean;
begin
  FFound := false;
  for LTrigger in FTriggerList do
    if LTrigger.Activate(AEvent) then begin
      FFound := true;
      Break;
    end;

  if FFound then
    Reset;
end;

procedure TTriggerEngine.Reset;
begin
  FTriggerList.Clear;
  FTimeout := MaxInt;
end;

procedure TTriggerEngine.TimeTicks;
var
  LEvent: TTriggerEvent;
begin
  // with this trick time will generate a trigger
  if (FTimeout < MaxInt) and (GetTickCount > FTimeout) then begin
    TDbgLogger.Instance.LogVerbose('SEQ: timeout detected');
    LEvent.EventType := kTriggerTimeEv;
    LEvent.Timeout   := GetTickCount;
    Trigger(LEvent);
  end;
end;

{$ENDREGION}

{$REGION 'Statment implementation'}

procedure TSeqEl.InitMsgObj(AStr: string);
begin
  // TODO 2 -cFIXME : verificare eccezioni nei costruttori
  FMsgObj := TSeqCanMsgObj.Create(AStr);
end;

procedure TSeqEl.DoGoto(AAddress: Integer);
begin
	if AAddress >= 0 then
		FOwnerSeq.DoGoto(AAddress);
end;

procedure TSeqEl.SetEndAddress(AElement: TSeqEl; AAddress: Integer);
begin
	if AElement <> nil then
		AElement.FEndAddress := AAddress;
end;

function TSeqEl.GetEndAddress(AElement: TSeqEl): Integer;
begin
	if AElement = nil then
		Result := -1
  else
  	Result := AElement.FEndAddress;
end;

function TSeqEl.GetEndAddress: Integer; 
begin
  Result := FEndAddress;
end;

function TSeqEl.GetMsgObj: TSeqCanMsgObj;
begin
  Result := FMsgObj;
end;

constructor TSeqEl.Create(AOwner: TSequence);
begin
  FOwnerSeq :=AOwner;
  FAddress := AOwner.GetCurrentAddress;

  TDbgLogger.Instance.LogDebug('SEQ: Added element addr: %d, class: %s',
    [FAddress,self.ClassName]);
end;

function TSeqEl.GetAddress: Integer;
begin
  Result := FAddress;
end;

function TSeqEl.MatchMsg(AMsg: TCanMsg): Boolean;
begin
  Result := FMsgObj.Match(AMsg);
end;

// TODO 2 -cFIXME : inserire log print nei metodi ?
procedure TSeqEl.Timeout; 
begin
end;

procedure TSeqEl.Execute;
begin
end;

procedure TSeqEl.Compile;
begin
end;

function TSeqEl.StringEl: string;
begin
  Result := ClassName;
end;

function TSeqEl.TriggerCallback(AEvent: TTriggerEvent): Boolean;
begin
  Result := false;
end;

// statment MSG
constructor TMsgEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
  InitMsgObj(AStr);
end;

procedure TMsgEl.Compile;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile CANMSG (%s)',[GetMsgObj.ToString]);
end;

procedure TMsgEl.Execute;
begin
  FOwnerSeq.SendMsg(FMsgObj.CanMsg);
end;

// statment DELAY
constructor TDelayEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
	FDelay := StrToInt(AStr);
end;

procedure TDelayEl.Timeout;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: timeout DELAY');
end;

procedure TDelayEl.Execute; 
begin
  FOwnerSeq.AddTrigger(TTriggerTime.Create(self,FDelay));
end;

// statment WAITMSG (trigger)
constructor TWaitEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
  InitMsgObj(AStr);
end;

procedure TWaitEl.Execute; 
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute WAITMSG');
	FOwnerSeq.AddTrigger(
    TTriggerMsg.Create(
      self,
      TSeqCanMsgObj.Create(FMsgObj)
    )
  );
end;

// statment CASE
constructor TCaseEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
  InitMsgObj(AStr);
end;

procedure TCaseEl.Compile;
var
  select: TSelectEl;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile CASE (%s)',[GetMsgObj.ToString]);
	select := FOwnerSeq.GetSelect();
	if select <> nil then
		select.AddCase(self)
	else begin
    TDbgLogger.Instance.LogWarning('SEQ: CASE (%s) not found',[GetMsgObj.ToString]);
		raise ECompileError.Create('CASE');
  end;
end;

// statment BREAK
procedure TBreakEl.Execute;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute BREAK');
	// quando incontro un break vado alla alla fine del SELECT
	DoGoto(GetEndAddress(FOwnerSeq.GetSelect));
	// il break termina la select
	FOwnerSeq.EndSelect;
end;

// statment EXPIRED
procedure TExpiredEl.Compile;
var
  select: TSelectEl;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile EXPIRED');
  try
	  select := FOwnerSeq.GetSelect as TSelectEl;
		select.SetExpired(self);
	except
    on EInvalidCast do raise ECompileError.Create('EXPIRED');
  end;
end;

// statment DEFAULT
procedure TDefaultEl.Compile;
var
  select: TSelectEl;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile DEFAULT');
	select := FOwnerSeq.GetSelect;
	if select <> nil then
		select.SetDefault(self)
	else
		raise ECompileError.Create('DEFAULT');
end;

procedure TEndselEl.Compile;
var
  el: TSeqEl;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile ENDSEL');
	el := FOwnerSeq.GetSelect;
	if el = nil then
		raise ECompileError.Create('ENDSEL');
	SetEndAddress(el,GetAddress);
	FOwnerSeq.EndSelect;
end;

procedure TEndselEl.Execute; 
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute ENDSEL');
	FOwnerSeq.EndSelect;
end;

  // statment SELECT
function TSelectEl.lookForCase(AMsg: TCanMsg): TCaseEl;
var
  I: Integer;
	el: TCaseEl;
begin
  Result := nil;
	for I := 0 to FCaseList.Count-1 do begin
		el := FCaseList.Items[I] as TCaseEl;
		if el.MatchMsg(AMsg) then
			Exit(el);
	end;
end;

constructor TSelectEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
	FCaseList := TObjectList.Create(false);
	try 
		FTimeout :=  StrToInt(AStr);
  except
    on EConvertError do
      FTimeout := 0;
  end;
end;

destructor TSelectEl.Destroy;
begin
  FCaseList.Free;
end;

procedure TSelectEl.Compile;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile SELECT');
	FOwnerSeq.SetSelect(self);
end;

procedure TSelectEl.Execute;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute SELECT');
	// la imposto anche durante il runtime perchè BREAK lavora a runtime
	FOwnerSeq.SetSelect(self);

	// imposto questo select come trigger
	FOwnerSeq.AddTrigger(TTriggerSelect.Create(self));

	if FTimeout > 0 then begin
		TDbgLogger.Instance.LogVerbose('SEQ: SELECT setup timer');
    FOwnerSeq.AddTrigger(TTriggerTime.Create(self,FTimeout));
	end;
end;

procedure TSelectEl.Timeout;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: timeout SELECT');

	if FExpiredEl <> nil then begin
		TDbgLogger.Instance.LogVerbose('SEQ: goto EXPIRED');
		DoGoto(FExpiredEl.GetAddress);
	end	else
		DoGoto(GetEndAddress);
end;

function TSelectEl.TriggerCallback(AEvent: TTriggerEvent): Boolean;
var
	LElement: TCaseEl;
begin
	TDbgLogger.Instance.EnterMethod(Self,'TriggerCallback');
  Result := false;
  case AEvent.EventType of
    kTriggerMsgEv:
      with AEvent do begin
        LElement := lookForCase(Msg);

        if LElement <> nil then begin
          // effetto il salto verso il CASE opportuno
          TDbgLogger.Instance.LogVerbose('SEQ: goto CASE %s',[Msg.ToString]);
          DoGoto(LElement.GetAddress);
          Result := true;
        end else if FDefaultEl <> nil then begin
          // non c'è un case giusto effettuo il salto verso il DEFAULT
          TDbgLogger.Instance.LogVerbose('SEQ: goto DEFAULT %s',[Msg.ToString]);
          DoGoto(FDefaultEl.GetAddress);
          Result := true;
        end
      end;

    kTriggerTimeEv:
      if FExpiredEl <> nil then begin
        TDbgLogger.Instance.LogVerbose('SEQ: goto EXPIRED');
        DoGoto(FExpiredEl.GetAddress());
      end else
        DoGoto(GetEndAddress);
  end;
	TDbgLogger.Instance.LeaveMethod(Self,'TriggerCallback');
end;

procedure TSelectEl.AddCase(ACaseEl: TCaseEl);
begin
	FCaseList.Add(ACaseEl);
end;

procedure TSelectEl.SetDefault(AElement: TSeqEl);
begin
  FDefaultEl := AElement;
end;

procedure TSelectEl.SetExpired(AElement: TSeqEl);
begin
   FExpiredEl := AElement;
end;

// statment LOOP
constructor TLoopEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
	if CompareText(Astr,kForeverStr) = 0 then
		FMaxCount := -1
	else
		FMaxCount := StrToInt(AStr);
end;

procedure TLoopEl.Compile;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile LOOP');
	FOwnerSeq.SetLoop(self);
end;

procedure TLoopEl.Execute;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute LOOP');
	FCount := FMaxCount;
	FOwnerSeq.SetLoop(self);
end;

function TLoopEl.DecCount(): Boolean;
begin
	// implementazione loop infinito
	if FMaxCount < 0 then
		Exit(false);

	// questo if serve per rivolvere il caso "LOOP 0"
	if FMaxCount > 0 then
		Dec(FCount);

	TDbgLogger.Instance.LogVerbose('SEQ: [TLoopEl::DecCount] Count: %d',[FCount]);

	Result := FCount = 0;
end;

// statment ENDLOOP
procedure TEndLoopEl.Compile;
var
  el: TSeqEl;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile ENDLOOP');
	el := FOwnerSeq.GetLoop();
	if el = nil then
		raise ECompileError.Create('ENDLOOP');
	SetEndAddress(el,GetAddress);
	FOwnerSeq.EndLoop;
end;

procedure TEndLoopEl.Execute;
var
	loopEl: TLoopEl;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute ENDLOOP');

	loopEl := FOwnerSeq.GetLoop;
	if loopEl = nil then begin
		// se loopEl è nullo probabilmente c'è un ENDLOOP che non
		// fa match con un LOOP
		TDbgLogger.Instance.LogWarning('SEQ: [TEndLoopEl::Execute()] Bad ENDLOOP keyword');
		Exit;
	end;

	// decremento se non sono arrivato a zero faccio un back Jump
	if not loopEl.DecCount then begin
		TDbgLogger.Instance.LogVerbose('SEQ: [TEndLoopEl::Execute()] Jmp');
		DoGoto(loopEl.GetAddress);
	end else begin
		TDbgLogger.Instance.LogVerbose('SEQ: [TEndLoopEl::Execute()] End');
		FOwnerSeq.EndLoop;
	end;
end;

// statment EXITLOOP
procedure TExitLoopEl.Compile;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute EXITLOOP');
	DoGoto(GetEndAddress(FOwnerSeq.GetLoop));
	FOwnerSeq.EndLoop();
end;

// statment PRINT
constructor TPrintEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
  FText := AStr;
end;

procedure TPrintEl.Execute;
begin
  FOwnerSeq.SendOutText(FText);
end;

// statment ABORT
constructor TAbortEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
  FTerminateResult := kTerminateSuccess;
end;

procedure TAbortEl.Execute;
var
  LEnd: TEndSeqEl;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute ABORT');
	LEnd := FOwnerSeq.GetEndSequence;
	if LEnd <> nil then begin
		FOwnerSeq.SetResult(kTerminateFail);
		DoGoto(LEnd.GetAddress);
	end;
end;

// statment ENDSEQ
procedure TEndSeqEl.Compile;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile ENDSEQ');
	FOwnerSeq.EndSequence(self);
end;

// statment CLEARQUEUE
procedure TClearQueueEl.Execute;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: Execute CLEARQUEUE');
	FOwnerSeq.ClearIncomingEvents;
end;

{$ENDREGION}
{$REGION 'TSequence implementation'}

procedure TSequence.clearData;
begin
	FData.clear;
  Reset;
end;

function TSequence.getCount: Integer;
begin
  Result := FData.Count;
end;

constructor TSequence.Create(AName: string; AEngine: TSequenceEngine);
begin
  FName          := AName;
  FEngine        := AEngine;
	FIncomingEventQueue  := TQueue<TCanMsg>.Create;
	FLoopStack     := TStack<TSeqEl>.Create;
	FSelectStack   := TStack<TSeqEl>.Create;
  FData          := TObjectList<TSeqEl>.Create;
  FTriggerEngine := TTriggerEngine.Create;
end;

destructor TSequence.Destroy;
begin
  clearData;
  FTriggerEngine.Free;
  FData.Free;
  FTriggerList.Free;
	FLoopStack.Free;
	FSelectStack.Free;
  // TODO 1 -cFIXME : verificare interazioni con ClearMsgQueue
	FIncomingEventQueue.Free;
end;

procedure TSequence.SendMsg(ACanMsg: TCanMsg);
begin
  // unit private access
  FEngine.SendMsg(ACanMsg);
end;

procedure TSequence.SendOutText(AText: string);
begin
  // unit private access
  FEngine.SendOutText(AText);
end;

procedure TSequence.Add(AElement: TSeqEl);
begin
	// è messo prima perchè puo causare eccezioni
	AElement.Compile;
	FData.Add(AElement);
	Inc(FProgramCounter);
end;

function TSequence.GetCurrentAddress: Integer;
begin
 Result := FProgramCounter;
end;

procedure TSequence.Reset;
begin
	FProgramCounter := 0;
	FLoopStack.Clear;
	FSelectStack.Clear;
  FTriggerEngine.Reset;
	ClearIncomingEvents;
end;

procedure TSequence.SetResult(AResult: TTerminateState);
begin
  FSequenceResult := AResult;
end;

function TSequence.GetResult: TTerminateState;
begin
  Result := FSequenceResult;
end;

function TSequence.ExecuteStep: Boolean;
var
  waitTrigger: Boolean;
begin
  Result := false;

  // time base for triggers
  FTriggerEngine.TimeTicks;

	// if i'm not waiting a trigger i process step
	if not FTriggerEngine.Waiting then begin
    // if we have more step execute step and move program counter
    if FProgramCounter <> getCount then begin
      FData[FProgramCounter].Execute;
      Inc(FProgramCounter);
      result := true;
    end;
  end else
		Result := true
end;

procedure TSequence.Trigger(AEvent: TTriggerEvent);
begin
  FTriggerEngine.Trigger(AEvent);
end;

procedure TSequence.AddTrigger(ATrigger: TTriggerObject);
begin
  FTriggerEngine.AddTrigger(ATrigger);
end;

procedure TSequence.ClearIncomingEvents;
begin
	FIncomingEventQueue.Clear;
end;

function TSequence.IsValid(): Boolean;
begin
  Result := false;
	if getCount = 0 then
		TDbgLogger.Instance.LogWarning('SEQ: SynErr seq <%s> no element',[Name])
	else if FLoopStack.Count > 0 then
		TDbgLogger.Instance.LogWarning('SEQ: SynErr seq <%s> close loop missing',[Name])
  else if FSelectStack.Count > 0 then
		TDbgLogger.Instance.LogWarning('SEQ: SynErr seq <%s> close select missing',[Name])
  else
    Result := true;
end;

procedure TSequence.DoGoto(ANewAddress: Integer);
begin
  FProgramCounter := ANewAddress;
end;

procedure TSequence.SetLoop(ALoop: TSeqEl);
begin
  FLoopStack.Push(ALoop);
end;

function TSequence.GetLoop: TLoopEl;
begin
 Result := FLoopStack.Peek as TLoopEl;
end;

procedure TSequence.EndLoop;
begin
  FLoopStack.Pop;
end;

procedure TSequence.SetSelect(AElement: TSeqEl);
begin
  FSelectStack.Push(AElement);
end;

function TSequence.GetSelect: TSelectEl;
begin
  Result := FSelectStack.Peek as TSelectEl;
end;

procedure TSequence.EndSelect;
begin
  FSelectStack.Pop;
end;

procedure TSequence.EndSequence(AElement: TSeqEl);
begin
  FEndSequence := AElement;
end;

function TSequence.GetEndSequence: TEndSeqEl;
begin
  Result := FEndSequence as TEndSeqEl;
end;
{$ENDREGION}

{$REGION 'Exceptions implementation'}
constructor ECreateError.Create(AError: string);
begin
  inherited Create('Create error: '+AError);
end;
{$ENDREGION}

{$REGION 'TSeqObj'}
constructor TSeqObj.Create(AName: string);
begin
  FName := AName;
end;
{$ENDREGION}

{$REGION 'TSequenceEngine'}

function TSequenceEngine.getCount: Integer;
begin
  Result := FSequences.Count;
end;
 
procedure TSequenceEngine.SendMsg(ACanMsg: TCanMsg);
begin
  TDbgLogger.Instance.LogVerbose('SEQ: send message ''%s''',[ACanMsg.ToString]);
  if Assigned(FOnSendMessage) then
    FOnSendMessage(ACanMsg);
end;

procedure TSequenceEngine.SendOutText(AText: string);
begin
  if Assigned(FOnOutText) then
    FOnOutText(AText);
end;

constructor TSequenceEngine.Create;
begin
	FCurrentIndex := 0;
  FParser    := nil;
	FSequences := TStringList.Create(true);
  FParser    := TSequenceParser.Create(self);
end;

destructor TSequenceEngine.Destroy;
begin
	Clear;
	FSequences.Free;
	FParser.Free;
end;

procedure TSequenceEngine.AddSequence(ASequence: TSeqObj);
var
  LSeq: TSequence;
begin
	// questo trucco ci garantisce che nella lista ci siano solo oggetti di tipo TSequence
	// quindi posso fare dei static cast delle altre parti
  try
  	LSeq := ASequence as TSequence;
    TDbgLogger.Instance.LogVerbose('SEQ: Add sequence <%s> to engine',[LSeq.Name]);;
	  FSequences.AddObject(ASequence.Name,ASequence);
  except
    on EInvalidCast do
      ASequence.Free;
  end;
end;

function TSequenceEngine.SetupSequence(AName: string): Boolean;
begin
	if not Running then begin
    TDbgLogger.Instance.LogVerbose('SEQ: setup sequence <%s>',[AName]);
    FCurrentIndex := FSequences.IndexOf(AName);
    Result := FCurrentIndex >= 0;
  end else begin
		TDbgLogger.Instance.LogError('SEQ: try to run sequence while engine is running');
		Result := false;
  end;
end;

procedure TSequenceEngine.Clear;
begin
	FSequences.Clear;
end;

procedure TSequenceEngine.Start;
begin
	FRunning := true;
end;

function TSequenceEngine.Terminate: TTerminateState;
begin
	FRunning := false;
	Result := FTerminateState;
end;

procedure TSequenceEngine.LoadNames(ANameList: TStrings);
begin
	ANameList.Clear;
	ANameList.AddStrings(FSequences);
end;

procedure TSequenceEngine.Reset;
var
  seq: TSequence;
begin
	seq := TSequence(FSequences.Objects[FCurrentIndex]);
	seq.Reset();
end;

function TSequenceEngine.ExecuteStep: Boolean;
var
  seq: TSequence;
  continueRun: Boolean;
begin
	seq := TSequence(FSequences.Objects[FCurrentIndex]);
	// se la sequenza ritorna false la sequenza è terminata
	continueRun := seq.ExecuteStep;

	// se ritorna false la sequenza termina e quindi memorizzo lo stato di terminazione
	if not continueRun then
		FTerminateState := seq.GetResult;

	Result := continueRun;
end;

procedure TSequenceEngine.Trigger(AEvent: TTriggerEvent);
var
  seq: TSequence;
begin
	seq := TSequence(FSequences.Objects[FCurrentIndex]);
	seq.Trigger(AEvent);
end;

{$ENDREGION}

{$REGION 'TSequenceEngineInternal'}
{$ENDREGION}

{$REGION 'TSequenceParser'}
function TSequenceParser.createSequenceObj(AName: string): TSeqObj;
begin

	if AName <> '' then begin
		TDbgLogger.Instance.LogVerbose('SEQ: Create new sequence <%s>',[AName]);
		Result := TSequence.Create(AName,FSeqEngine)
	end else
  	Result := nil;
end;

procedure TSequenceParser.addSymbol(AName, AValue: string);
begin
  FDefineList.Values[AName] := AValue;
end;

function TSequenceParser.replaceSymbol(AStr: string): string;
var
	name, retVal: string;
	idx,i: Integer;
	open: Boolean;
	ch: Char;
begin
  open := false;
  retVal := '';

	// clamp che velocizzano la funzione in caso di ricerche inultili
	if (FDefineList.Count = 0) or (Pos('@',AStr) = 0) then
		Exit(AStr);

	for ch in Astr do begin
		if open then begin
			if IsLetterorDigit(ch) then
				name := name + ch
			else begin
				retVal := retVal + FDefineList.Values[name] + ch;
				open := false;
			end
		end	else begin
			if ch = '@' then begin
				name := '';
				open := true;
			end else
				retVal := retVal + ch;
		end
	end;

	retVal := retVal + FDefineList.Values[name];
	// funzione ricorsiva che premette di fare dei define dentro i define
	Result := replaceSymbol(retVal);
end;

function TSequenceParser.findKeyword(AStr: string): Integer;
var
	pos, key: Integer;
begin
  Result := -1;
	for key := 0 to kKeywordTableSize - 1 do
		if CompareText(AStr,kKeywordTable[key]) = 0 then
			Exit(key);
end;

{* Effettua il parsing  di uno script }
procedure TSequenceParser.parseScript;
var
	deleteSeq: Boolean;
  status: TSeqEngineStatus;
	i, pos: Integer;
  key: TSeqKeywordID;
	str, strLoop,name,msgStr,symName,symValue: string;
	seq: TSequence;
	seqEl: TSeqEl;
begin
  status := stsIdle; 
  deleteSeq := false;
  seq := nil;

	for strLoop in FScript do begin
		str := Trim(strLoop);

		// per i commenti e le linee vuote
		if (str <> '') and  (str[1] <> ';') then begin
      str := replaceSymbol(str);

      FSplitter.Parse(str);
      key := TSeqKeywordID(findKeyword(FSplitter.GetArgument(0)));

      if key <> kKeyINVALID then begin
        case TSeqKeywordID(key) of
          kKeySequence: status := stsStartSeq;
          kKeyDefine: begin
              name := FSplitter.GetArgument(1);
              str := FSplitter.LineFromArg(2);
              addSymbol(name,str);
            end
        end; { case }

        case status of
          stsIdle:;
          stsStartSeq: begin
              seq := TSequence(createSequenceObj(FSplitter.LineFromArg(1)));
              if seq <> nil then
                status := stsAddMsg
              else
                status := stsIdle;
            end;

          stsAddMsg: begin
              deleteSeq := false;
              if key <> kKeyInvalid then begin
                Assert(seq <> nil);
                // TODO 2 -cFIXME : gestire meglio i parametri relativi ad un comando
                msgStr := FSplitter.LineFromArg(1);
                try
                  seqEl := nil;
                  // gli elementi viengo aggiunti alla sequenza nel costruttore
                  case key of
                    kKeySendmsg: seqEl := TMsgEl.Create(msgStr,seq);
                    kKeyDelay:  seqEl := TDelayEl.Create(msgStr,seq);
                    kKeySelect: seqEl := TSelectEl.Create(msgStr,seq);
                    kKeyCase: seqEl := TCaseEl.Create(msgStr,seq);
                    kKeyBreak: seqEl := TBreakEl.Create(seq);
                    kKeyExpired: seqEl := TExpiredEl.Create(seq);
                    kKeyDefault: seqEl := TDefaultEl.Create(seq);
                    kKeyEndsel: seqEl := TEndselEl.Create(seq);
                    kKeyWaitmsg: seqEl := TWaitEl.Create(msgStr,seq);
                    kKeyLoop: seqEl := TLoopEl.Create(msgStr,seq);
                    kKeyLoopend: seqEl := TEndLoopEl.Create(seq);
                    kKeyExitloop: seqEl :=  TExitLoopEl.Create(seq);
                    kKeyPrint: seqEl := TPrintEl.Create(msgStr,seq);
                    kKeyAbort: seqEl := TAbortEl.Create(msgStr,seq);
                    kKeyClearQueue: seqEl := TClearQueueEl.Create(seq);
                    kKeyEndseq: begin
                      seqEl := TEndSeqEl.Create(seq);
                      if seqEl <> nil then
                        // procedura di terminazione della sequenza
                        seq.Add(seqEl);
                      seqEl := nil;
                      if seq.IsValid then
                        // aggiungo la sequanza creata nl vettore delle sequenze
                        FSeqEngine.AddSequence(seq)
                      else begin
                        TDbgLogger.Instance.LogWarning('SEQ: sequence <%s> not valid',[seq.Name]);
                        seq.Free;
                      end;
                      status := stsStartSeq;
                      seq := nil;
                    end; { end kKeyEndseq }
                  end; { end switch Key }
                  // se l'elemento è stato creato senza problemi lo aggiungo alla lista
                  if seqEl <> nil then
                    seq.Add(seqEl);
                except
                  on E: ECreateError do begin
                    TDbgLogger.Instance.LogWarning('SEQ: create error <%s>',  [e.Message]);
                    deleteSeq := true;
                  end; // end try ... catch
                  on E: ECompileError do begin
                    TDbgLogger.Instance.LogWarning('SEQ: compile error <%s>',[e.Message]);
                    deleteSeq := true;
                  end;
                end; { except }
              end else begin { key >= 0 }
                TDbgLogger.Instance.LogWarning('SEQ: unknow keyword error <%s>',[str]);
                deleteSeq := true;
              end;

              if deleteSeq then begin
                // cancello la sequenza che sto creando
                seq.Free;
                seq := nil;
                // cerco la prossima sequenza
                status := stsStartSeq;
              end
            end { end stsAddMsg }
        end { case status }
      end { main key > 0 }
    end { empty line check }
	end; { end for }
  // SMART INSPECT
	// if (status != stsStartSeq)
	//	SiMain.LogWarning("SEQ: Sequence not closed");

	// cancello gli orfani
	seq.Free;
end;

constructor TSequenceParser.Create(AEngine: TSequenceEngine);
begin
	FSeqEngine := AEngine;
	FScript := TStringList.Create;
	FAuxList := TStringList.Create;
	FDefineList := TStringList.Create;
	FSplitter := TSplitterStr.Create;
END;

destructor TSequenceParser.Destroy;
begin
	FSplitter.Free;
	FDefineList.Free;
	FAuxList.Free;
	FScript.Free;
end;

procedure TSequenceParser.LoadFromFile(AName: string);
begin
	// cancello la lista precedente
	if FileExists(AName) then begin
		FDefineList.Clear;
		FSeqEngine.Clear;
		TDbgLogger.Instance.LogMessage('SEQ: Load Sequence file (%s)',[AName]);
		FScript.LoadFromFile(AName);
		parseScript;
	end;
end;
{$ENDREGION}

end.

