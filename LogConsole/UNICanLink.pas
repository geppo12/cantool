{ National Instruments ni-can interface units }
{ (C) 2011 Ing Giuseppe 'Ninjeppo' Monteleone }

unit UNICanLink;

interface

uses
  SysUtils,
  UCanMsg,
  UNIAPI,
  UDbgLogger;

{ delphi resourcestring are like const but goes into winsows 'resource' }
resourcestring
  kNICanMsgOpenError = 'Non posso aprire la porta';

const
  kMaxAttrBuffer = 16;
type
  ENICanException = class(Exception)
    constructor Create(AMsg: string);
  end;

  ENICanOpenError = class(ENICanException)
    constructor Create;
  end;

  TNIAttributeArray = class
    private
    FAttributeIDArray: array [0..kMaxAttrBuffer-1] of NCTYPE_ATTRID;
    FAttributeValuesArray: array [0..kMaxAttrBuffer-1] of NCTYPE_UINT32;
    FIndex: Integer;

    function getAttributeIDPtr: NCTYPE_ATTRID_P;
    function getAttributeValuesPtr: NCTYPE_UINT32_P;

    public
    procedure Reset;
    procedure Add(AID: NCTYPE_ATTRID; AValue: NCTYPE_UINT32);
    property AttributeIDPtr: NCTYPE_ATTRID_P read getAttributeIDPtr;
    property AttributeValuesPtr: NCTYPE_UINT32_P read getAttributeValuesPtr;
    property Count: Integer read FIndex; // index is used as counter of parameter
  end;


  TNICanLink = class
    private
    FLogger: TDbgLogger;
    FName: string;
    FActive: Boolean;
    FAttrArray: TNIAttributeArray;
    FCanNetworkObj: NCTYPE_OBJH;
    FMsgIndex: Integer;
    FMsgCount: Integer;

    function configure: NCTYPE_STATUS;
    //procedure readFromCan;
    //procedure readMsgFromBuffer(var AMsg: TCanMsg);
    function statusToString(AStatus: NCTYPE_STATUS): string;
    procedure checkCanerror;
    procedure setName(AName: string);
    public
    constructor Create;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    //function Read(var AMsg: TCanMsg): Boolean;
    //procedure Write(AMsg: TCanMsg);

    property Name: string read FName write setName;
    property Active: Boolean read FActive;
  end;

implementation
{$REGION 'NI-Can Exceptions'}
constructor ENICanException.Create(AMsg: string);
begin
  inherited Create(AMsg);
end;

constructor ENICanOpenError.Create;
begin
  inherited Create(kNICanMsgOpenError);
end;
{$ENDREGION}

{$REGION 'TNIAttributeArray'}
(*  TNIAttributeArray = class
    private
    FAttrBufferID: TNIAttrBufferID;
    FAttrBufferValues: TNIAttrBufferID;
    FAttrBufferIndex: Integer; *)

function TNIAttributeArray.getAttributeIDPtr: NCTYPE_ATTRID_P;
begin
  Result := @FAttributeIDArray;
end;

function TNIAttributeArray.getAttributeValuesPtr: NCTYPE_UINT32_P;
begin
  Result := @FAttributeValuesArray;
end;

procedure TNIAttributeArray.Reset;
begin
  FIndex := 0;
end;

procedure TNIAttributeArray.Add(AID: NCTYPE_ATTRID; AValue: NCTYPE_UINT32);
begin
  FAttributeIDArray[FIndex] := AID;
  FAttributeValuesArray[FIndex] := AValue;
  Inc(FIndex);
end;
{$ENDREGION}

{$REGION 'TNICanLink'}
function TNICanLink.configure: NCTYPE_STATUS;
begin
	Result := ncConfig(
    PAnsiChar(AnsiString(FName)),
    FAttrArray.Count,
    FAttrArray.AttributeIDPtr,
    FAttrArray.AttributeValuesPtr);
end;

function TNICanLink.statusToString(AStatus: NCTYPE_STATUS): string;
var
  LBuffer: array [0..1023] of AnsiChar;
begin
	ncStatusToString(AStatus,1024,@LBuffer);
	Result := Trim(LBuffer); // implict conversion
end;

procedure TNICanLink.checkCanerror;
begin
  // TODO 1 -cFUNCTION : procedure TNICanLink.checkCanerror;
end;

procedure TNICanLink.setName(AName: string);
begin
  if FActive then
    raise ENICanException.Create('Cannot change name: device active');
  FName := AName;
end;

constructor TNICanLink.Create;
begin
  FLogger := TDbgLogger.Instance;
  FAttrArray := TNIAttributeArray.Create;
  FActive := false;
end;

destructor TNICanLink.Destroy;
begin
  FAttrArray.Free;
end;

procedure TNICanLink.Open;
var
  LStatus: NCTYPE_STATUS;
  simpleAttrVal: NCTYPE_UINT32;
begin
  if not FActive then begin
    FAttrArray.Reset;
    FAttrArray.Add(NC_ATTR_BAUD_RATE,100000);
    FAttrArray.Add(NC_ATTR_START_ON_OPEN,NC_FALSE);
    LStatus := configure;

    if LStatus <> 0 then begin
      FLogger.LogWarning('NI-Err: configuring Err: %s',[statusToString(LStatus)]);
      raise ENICanOpenError.Create;
    end;

    // TODO 1 -cFIXME : check NI function
    LStatus := ncOpenObject(PAnsiChar(AnsiString(FName)),@FCanNetworkObj);
    if LStatus = 0 then
      FActive := true
    else begin
      FLogger.LogWarning('NI-Err: opening Err: %s',[statusToString(LStatus)]);
      raise ENICanOpenError.Create;
    end;

    simpleAttrVal := NC_TRUE;
    ncSetAttribute(FCanNetworkObj,NC_ATTR_LOG_BUS_ERROR ,sizeof(simpleAttrVal),@simpleAttrVal);
    ncAction(FCanNetworkObj,NC_OP_START,0);

    FLogger.LogMessage('Can Open');
  end;
end;

procedure TNICanLink.Close;
begin
  if FActive then begin
    checkCanerror;
    ncAction(FCanNetworkObj,NC_OP_STOP,0);
    ncCloseObject(FCanNetworkObj);
    FCanNetworkObj := 0;
    FActive := false;
    FLogger.LogMessage('Can Closed');
  end;
end;
(*
function TNICanLink.Read(var AMsg: TCanMsg): Boolean;
begin
  Result := true;
  if FMsgIndex = FMsgCount then
    readFromCan;

  if FMsgCount > 0 then
    readMsgFromBuffer(AMsg)
  else
    Result := false;
end;

procedure TNICanLink.Write(AMsg: TCanMsg);
begin

end;
*)
{$ENDREGION}
end.
