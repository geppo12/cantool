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
       con una sequenza non impostata pu� creare problemi o crash.

       @param AName nome della sequenza

       @returns
       successo se la sequenza � correttamente impostata.}
    function SetupSequence(AName: string): Boolean;
    procedure Clear;
    procedure LoadNames(ANameList: TStrings);
    procedure Start;
    function Terminate: TTerminateState;

    // operazioni sulle sequenze
    procedure Reset;
    function ExecuteStep: Boolean;
    procedure Trigger(ACanMsg: TCanMsg);
    function Waiting: Boolean;

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
  Generics.Collections,
  Contnrs,
  SysUtils,
  Character,
  Windows,
  UDbgLogger;

const
  kForeverStr = 'FOREVER';

  kKeywordTableSize = 17;
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
    // TODO 1 -cSEQ : inserire comando print o logwrite
  //	'PRINT',
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
    kKeyAbort,
    kKeyClearQueue,
    kKeyEndseq
  );

  TSeqEngineStatus = (
    stsIdle,
    stsStartSeq,
    stsAddMsg
  );
(*
class TEgoMsgObjSeq : public TEgoMsgObj {
	private:
	int FCmdMask;
	int FNodeMask;
	unsigned char FDataMask[8];

	bool __fastcall getHasDataMask();

	public:
	__fastcall TEgoMsgObjSeq();
	virtual bool __fastcall Match(TEgoMsgObj *AMsg);
	bool __fastcall Parse(AnsiString AString);

	__property int CmdMask = { read=FCmdMask };
	__property int NodeMask = { read=FNodeMask };
	__property bool HasDataMask = { read=getHasDataMask };
};
*)
  TSequenceEngineInternal = class(TSequenceEngine)
    public
  end;

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
    constructor Create(ACanMsgStr: string); overload;
    function Match(AMsg: TCanMsg): Boolean;
    function ToString: string; override;
    property CanMsg: TCanMsg read FCanMsg;
  end;

  // forward declaration
  TSequence = class;

  // root class per gli elementi di sequenza.
  TSeqEl = class
    private
    FMsgObj: TSeqCanMsgObj;
    // program a qui � posizionato questo elemento;
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
    // l' elemento � stato aggiunto ad una sequenza;
    procedure Compile; virtual;
    function StringEl: string; virtual;
    // di default il trigger non scatta mai
    function FireTrigger(AMsg: TCanMsg): Boolean; virtual;
  end;

(*
  class TElementStack : public TObject {
    private:
    TObjectList *FList;

    public:
    __fastcall TElementStack();
    __fastcall ~TElementStack();
    void __fastcall Clear() { FList->Clear(); }
    int __fastcall GetCount() { return FList->Count; }
    void __fastcall PushEl(TSeqEl *AElement);
    void __fastcall PopEl();
    TSeqEl* __fastcall Top();
  };
*)

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
    function FireTrigger(AMsg: TCanMsg): Boolean; override;
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
    constructor Create(AStr: string; AOwner: TSequence); //: TSeqEl(AOwner) {}
    procedure Execute; override;
  end;

  // statment EXPIRED
  TExpiredEl = class(TSeqEl)
	public
    constructor Create(AStr: string; AOwner: TSequence); //: TSeqEl(AOwner) {}
    procedure Compile; override;
  end;

  // statment DEFAULT
  TDefaultEl = class(TSeqEl)
    public
    constructor Create(AStr: string; AOwner: TSequence); //: TSeqEl(AOwner) {}
    procedure Compile; override;
  end;

  // statment ENDSEL
  TEndselEl = class(TSeqEl)
    public
    constructor Create(AStr: string; AOwner: TSequence); //: TSeqEl(AOwner) {}
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
    function FireTrigger(AMsg: TCanMsg): Boolean; override;
    procedure AddCase(ACaseEl: TCaseEl);
    procedure SetDefault(AElement: TSeqEl); { FDefaultEl = AElement; }
    procedure SetExpired(AElement: TSeqEl); { FExpiredEl = AElement; }
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
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Compile; override;
    procedure Execute; override;
  end;

  // statment EXITLOOP
  TExitLoopEl = class(TSeqEl)
    public
    constructor Create(AStr: string; AOwner: TSequence);
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

  // statment ENDSEQ
  TEndSeqEl = class(TSeqEl)
    public
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Compile; override;
  end;

  // statment CLEARQUEUE
  TClearQueueEl = class(TSeqEl)
    public
    constructor Create(AStr: string; AOwner: TSequence);
    procedure Execute; override;
  end;

  //#define kMaxLoopDepth 10

  TElementStack = class(TStack<TSeqEl>)
    private
    function getTop: TSeqEl;

    public
    property Top: TSeqEl read getTop;
  end;

  TSequence = class(TSeqObj)
    private
    FEngine: TSequenceEngine;
    FIncomingEventQueue: TQueue<TCanMsg>;
    FData: TObjectList<TSeqEl>;
    FSequenceResult: TTerminateState;
    FProgramCounter: Integer;
    FTimer: Integer;
    FTimerTrigger: TSeqEl;
    FTrigger: TSeqEl;
    FEndSequence: TSeqEl;
    FLoopStack: TElementStack;
    FSelectStack: TElementStack;

    procedure clearData;
    procedure clearTrigger;
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
    procedure Trigger(AMsg: TCanMsg);
    procedure ClearIncomingEvents;
    function Waiting: Boolean;
    function IsValid(): Boolean;
    procedure DoGoto(ANewAddress: Integer);
    procedure SetTimeout(ATrigger: TSeqEl; ATimeMS: Cardinal);
    procedure SetTrigger(ATrigger: TSeqEl);
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
    constructor Create(AError: string); {overload;}// : Exception(AnsiString("Create error ")+AError) {};
    //constructor Create(char* AError); overload; // : Exception(AnsiString("Create error ")+AError) {};
  end;
  ECompileError = class(Exception);

{$ENDREGION}
{ IMPLEMENTATION }

{$REGION 'TSeqCanMsgObj'}
procedure TSeqCanMsgObj.parse(var ACanMsg: TCanMsg; AStr: string);
var
	value: string;
	retVal: Boolean; // = true;
	i: Integer;
begin
	TDbgLogger.Instance.EnterMethod(self,'parse');
	TDbgLogger.Instance.LogVerbose('SEQ: Parse msg <%s>',[AStr]);

  FAuxStringList.CommaText := AStr;
  try
    value := FAuxStringList.Values['ID'];
    if value <> '' then
      FCanMsg.ecmId := StrToInt(value)
    else
      raise EConvertError.Create('MSG: convert ID error');

    value := FAuxStringList.Values['MASK-ID'];
    if value <> '' then
      FMaskMsg.ecmId := StrToInt(value);

    FCanMsg.ecmLen := 0;
    for i := 0 to 7 do begin
      value := FAuxStringList.Values['D'+IntToStr(i)];
      if value <> '' then begin
        if value = '*' then begin
          FMaskMsg.ecmData[i] := 0;
          FCanMsg.ecmData[i]  := 0;
          // +1 because FCanMsg.ecmLen will be inc at the end of cycle
          FMaskMsg.ecmLen := FCanMsg.ecmLen+1;
        end else
          FCanMsg.ecmData[i]  := StrToInt(value);
        Inc(FCanMsg.ecmLen);
      end else if FAuxStringList.IndexOfName('DO') > 0 then
          raise EConvertError.Create('Use zero instead O letter into D number')
      else
        Break;
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

    for I := 0 to 7 do begin
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

function TSeqEl.FireTrigger(AMsg: TCanMsg): Boolean;
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
	FOwnerSeq.SetTimeout(self,FDelay);
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
	// attendo come trigger il messaggio memorizzato in data
	FOwnerSeq.SetTrigger(self);
end;

function TWaitEl.FireTrigger(AMsg: TCanMsg): Boolean;
begin
  Result := MatchMsg(AMsg);
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
	//SI_INFO(SiMain->LogAssert(select != NULL,"SEQ: [TCaseEl::Compile()] no SELECT element"));
	if select <> nil then
		select.AddCase(self)
	else
		raise ECompileError.Create('CASE');
end;

// statment BREAK
constructor TBreakEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
end;

procedure TBreakEl.Execute;
begin
	TDbgLogger.Instance.LogVerbose('"SEQ: execute BREAK');
	// quando incontro un break vado alla alla fine del SELECT
	DoGoto(GetEndAddress(FOwnerSeq.GetSelect));
	// il break termina la select
	FOwnerSeq.EndSelect;
end;

// statment EXPIRED
constructor TExpiredEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
end;

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
constructor TDefaultEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
end;

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

// statment ENDSEL
constructor TEndselEl.Create(AStr: string; AOwner: TSequence);
begin
  inherited Create(AOwner);
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
	// la imposto anche durante il runtime perch� BREAK lavora a runtime
	FOwnerSeq.SetSelect(self);

	// imposto questo select come trigger
	FOwnerSeq.SetTrigger(self);

	if FTimeout > 0 then begin
		TDbgLogger.Instance.LogVerbose('SEQ: SELECT setup timer');
		FOwnerSeq.SetTimeout(self,FTimeout);
	end;
end;

procedure TSelectEl.Timeout();
begin
	TDbgLogger.Instance.LogVerbose('SEQ: timeout SELECT');

	if FExpiredEl <> nil then begin
		TDbgLogger.Instance.LogVerbose('SEQ: goto EXPIRED');
		DoGoto(FExpiredEl.GetAddress);
	end	else
		DoGoto(GetEndAddress);
end;

function TSelectEl.FireTrigger(AMsg: TCanMsg): Boolean;
var
	el: TCaseEl;
begin
	TDbgLogger.Instance.EnterMethod(Self,'FireTrigger');

	el := lookForCase(AMsg);

	if el <> nil then begin
		// effetto il salto verso il CASE opportuno
		TDbgLogger.Instance.LogVerbose('SEQ: goto CASE %s',[AMsg.ToString]);
		DoGoto(el.GetAddress);
		Result := true;
	end else if FDefaultEl <> nil then begin
		// non c'� un case giusto effettuo il salto verso il DEFAULT
		TDbgLogger.Instance.LogVerbose('SEQ: goto DEFAULT %s',[AMsg.ToString]);
		DoGoto(FDefaultEl.GetAddress);
		Result := true;
	end else // il trigger non ha effettuato operazioni
		Result := false;

	TDbgLogger.Instance.LeaveMethod(Self,'FireTrigger');
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
constructor TEndLoopEl.Create(AStr: string; AOwner: TSequence);
begin
  // TODO 3 -cPORTING : set to delete
  inherited Create(AOwner);
end;

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
		// se loopEl � nullo probabilmente c'� un ENDLOOP che non
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
constructor TExitLoopEl.Create(AStr: string; AOwner: TSequence);
begin
  // TODO 3 -cPORTING : set to delete
  inherited Create(AOwner);
end;

procedure TExitLoopEl.Compile;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: execute EXITLOOP');
	DoGoto(GetEndAddress(FOwnerSeq.GetLoop));
	FOwnerSeq.EndLoop();
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
constructor TEndSeqEl.Create(AStr: string; AOwner: TSequence);
begin
  // TODO 3 -cPORTING : set to delete
  inherited Create(AOwner);
end;

procedure TEndSeqEl.Compile;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: compile ENDSEQ');
	FOwnerSeq.EndSequence(self);
end;

// statment CLEARQUEUE
constructor TClearQueueEl.Create(AStr: string; AOwner: TSequence);
begin
  // TODO 3 -cPORTING : set to delete
  inherited Create(AOwner);
end;

procedure TClearQueueEl.Execute;
begin
	TDbgLogger.Instance.LogVerbose('SEQ: Execute CLEARQUEUE');
	FOwnerSeq.ClearIncomingEvents;
end;

{$ENDREGION}
{$REGION 'TSequence implementation'}

function TElementStack.getTop: TSeqEl;
begin
  Result := Pop;
  Push(Result);
end;

procedure TSequence.clearData;
begin
	FData.clear;
  Reset;
end;

procedure TSequence.clearTrigger;
begin
  FTrigger := nil;
  FTimerTrigger := nil;
  FTimer := 0;
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
	FLoopStack     := TElementStack.Create;
	FSelectStack   := TElementStack.Create;
  FData          := TObjectList<TSeqEl>.Create;
end;

destructor TSequence.Destroy;
begin
  clearData;
  FData.Free;
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
	// � messo prima perch� puo causare eccezioni
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
	ClearIncomingEvents;
	FTrigger := nil;
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
	waitTrigger := false;

	if FTrigger <> nil then
		waitTrigger := TRUE;

	if FTimerTrigger <> nil then
		if (FTimer > 0) and (Cardinal(FTimer) < GetTickCount) then begin
			TDbgLogger.Instance.LogVerbose('SEQ: timeout expired');
			FTimerTrigger.Timeout;
			{ sto attendendo dei trigger, ma undo dei trigger (il tempo) � scattato
			  quindi rimuovo la condizione di attesa }
			waitTrigger := FALSE;
		end else
			waitTrigger := TRUE;

	// if i'm not waiting a trigger i process step
	if not waitTrigger then begin
    clearTrigger();

    // if we have more step execute step and move program counter
    if FProgramCounter <> getCount then begin
      FData[FProgramCounter].Execute;
      Inc(FProgramCounter);
      result := true;
    end;
  end else
		Result := true
end;

procedure TSequence.Trigger(AMsg: TCanMsg);
var
  LMsg: TCanMsg;
  doBreak: Boolean;
begin
  FIncomingEventQueue.Enqueue(AMsg);
	if FTrigger <> nil then begin
		doBreak := FALSE;
		while FIncomingEventQueue.Count > 0 do begin
			LMsg := FIncomingEventQueue.Dequeue;
			TDbgLogger.Instance.LogVerbose('SEQ: Trigger get Obj %s',[LMsg.ToString]);
			if FTrigger.FireTrigger(LMsg) then begin
				TDbgLogger.Instance.LogVerbose('SEQ: got trigger');
				clearTrigger;
        Exit;
			end;
		end { while }
	end { if }
end;

procedure TSequence.ClearIncomingEvents;
begin
	FIncomingEventQueue.Clear;
end;

function TSequence.Waiting: Boolean;
begin
  Result := FTrigger <> nil;
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

procedure TSequence.SetTimeout(ATrigger: TSeqEl; ATimeMS: Cardinal);
begin
	FTimerTrigger := ATrigger;
	FTimer := GetTickCount + ATimeMS;
end;

procedure TSequence.SetTrigger(ATrigger: TSeqEl);
begin
  FTrigger := ATrigger;
end;

procedure TSequence.SetLoop(ALoop: TSeqEl);
begin
  FLoopStack.Push(ALoop);
end;

function TSequence.GetLoop: TLoopEl;
begin
 Result := FLoopStack.Top as TLoopEl;
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
  Result := FSelectStack.Top as TSelectEl;
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
	// se la sequenza ritorna false la sequenza � terminata
	continueRun := seq.ExecuteStep;

	// se ritorna false la sequenza termina e quindi memorizzo lo stato di terminazione
	if not continueRun then
		FTerminateState := seq.GetResult;

	Result := continueRun;
end;

// TODO 2 -cFIXME : rendere indipendenti i trigger dal tipo
procedure TSequenceEngine.Trigger(ACanMsg: TCanMsg);
var
  seq: TSequence;
begin
	seq := TSequence(FSequences.Objects[FCurrentIndex]);
	seq.Trigger(ACanMsg);
end;

function TSequenceEngine.Waiting: Boolean;
var
  seq: TSequence;
begin
	seq := TSequence(FSequences.Objects[FCurrentIndex]);
	Result := seq.Waiting();
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
                msgStr := FSplitter.GetArgument(1);
                try
                  seqEl := nil;
                  // gli elementi viengo aggiunti alla sequenza nel costruttore
                  case key of
                    kKeySendmsg: seqEl := TMsgEl.Create(msgStr,seq);
                    kKeyDelay:  seqEl := TDelayEl.Create(msgStr,seq);
                    kKeySelect: seqEl := TSelectEl.Create(msgStr,seq);
                    kKeyCase: seqEl := TCaseEl.Create(msgStr,seq);
                    kKeyBreak: seqEl := TBreakEl.Create(msgStr,seq);
                    kKeyExpired: seqEl := TExpiredEl.Create(msgStr,seq);
                    kKeyDefault: seqEl := TDefaultEl.Create(msgStr,seq);
                    kKeyEndsel: seqEl := TEndselEl.Create(msgStr,seq);
                    kKeyWaitmsg: seqEl := TWaitEl.Create(msgStr,seq);
                    kKeyLoop: seqEl := TLoopEl.Create(msgStr,seq);
                    kKeyLoopend: seqEl := TEndLoopEl.Create(msgStr,seq);
                    kKeyExitloop: seqEl :=  TExitLoopEl.Create(msgStr,seq);
      //								case kKeyPrint: seqEl := TPrintEl.Create(msgStr,seq);
                    kKeyAbort: seqEl := TAbortEl.Create(msgStr,seq);
                    kKeyClearQueue: seqEl := TClearQueueEl.Create(msgStr,seq);
                    kKeyEndseq: begin
                      seqEl := TEndSeqEl.Create(msgStr,seq);
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
                  // se l'elemento � stato creato senza problemi lo aggiungo alla lista
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

