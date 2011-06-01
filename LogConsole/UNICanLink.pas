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
	 
	 =====================================
	 EXCEPTION FOR THIS UNIT.
	 =====================================
	 
	 This unit can be used in other project under the followin BSD like licence
	 
	 Redistribution and use in source and binary forms, with or without
	 modification, are permitted provided that the following conditions are met:
	  * Redistributions of source code must retain the above copyright
		notice, this list of conditions and the following disclaimer.
	  * Redistributions in binary form must reproduce the above copyright
		notice, this list of conditions and the following disclaimer in the
		documentation and/or other materials provided with the distribution.
	  * Neither the name of the <organization> nor the
		names of its contributors may be used to endorse or promote products
		derived from this software without specific prior written permission.	 
}

{ National Instruments ni-can interface units }

unit UNICanLink;

{ here we use untyped pointer. The operator @ return an untyped porinter that is
  casted as required }
{$T-}

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
  kNumObject     = 16;
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

  TNICanBaudrate = (
    canBaudInvalid = -1,
    canBaud10K,
    canBaud100K,
    canBaud125K,
    canBaud250K,
    canBaud500K,
    canBaud1000K
  );

  TNICanLink = class
    private
    FLogger: TDbgLogger;
    FName: string;
    FActive: Boolean;
    FAttrArray: TNIAttributeArray;
    FErrorStringBuf: array [0..1023] of AnsiChar;
    FNICanBuffer: array [0..kNumObject-1] of NCTYPE_CAN_STRUCT;
    FBaudRate: TNICanBaudrate;

    FReadMsgQueue: TCanMsgQueue;
    FWriteMsgQueue: TCanMsgQueue;
    FCanNetworkObj: NCTYPE_OBJH;
    FLastStatus: Integer;

    function int64NI2D(AInt64: NCTYPE_UINT64): Int64;
    function baudrateD2NI(ABaudRate: TNICanBaudrate): NCTYPE_UINT32;
    function configure: NCTYPE_STATUS;
    function readFromCan: NCTYPE_STATUS;
    function statusToString(AStatus: NCTYPE_STATUS): string;
    procedure checkCanerror;
    procedure setName(AName: string);
    procedure setBaudrate(ABaudRate: TNICanBaudrate);
    public
    constructor Create;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    function Read(var AMsg: TCanMsg): Boolean;
    function Write(AMsg: TCanMsg): Boolean;
    function WriteQueued(AMsg: TCanMsg): Boolean;
    function FlushWriteQueue: Boolean;

    property Name: string read FName write setName;
    property Active: Boolean read FActive;
    property BaudRate: TNICanBaudrate read FBaudRate write setBaudrate;
    property LastStatus: Integer read FLastStatus;
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

function TNICanLink.int64NI2D(AInt64: NCTYPE_UINT64): Int64;
begin
  Result := AInt64.LowPart + (Int64(AInt64.HighPart) shl 32);
end;

function TNICanLink.baudrateD2NI(ABaudRate: TNICanBaudrate): NCTYPE_UINT32;
begin
  case ABaudRate of
    canBaud10K: Result := NC_BAUD_10K;
    canBaud100K: Result := NC_BAUD_100K;
    canBaud125K: Result := NC_BAUD_125K;
    canBaud250K: Result := NC_BAUD_250K;
    canBaud500K: Result := NC_BAUD_500K;
    canBaud1000K: Result := NC_BAUD_1000K;
    else
      Result := 0;
  end;
end;

function TNICanLink.configure: NCTYPE_STATUS;
begin
	Result := ncConfig(
    PAnsiChar(AnsiString(FName)),
    FAttrArray.Count,
    FAttrArray.AttributeIDPtr,
    FAttrArray.AttributeValuesPtr);
end;

function TNICanLink.readFromCan: NCTYPE_STATUS;
var
  LInvalidCount,
  LErrorCount: Integer;
  LValidRead: Boolean;
  LCanMsg: TCanMsg;
  LActualRead: Integer;
  LNumMsg: Integer;
  I: Integer;
begin
  LInvalidCount := 0;
  LErrorCount   := 0;
  repeat
    Result := ncReadMult(
                FCanNetworkObj,
                sizeof(NCTYPE_CAN_STRUCT)*kNumObject,
                @FNICanBuffer,
                @LActualRead);

    LNumMsg := LActualRead div sizeof(NCTYPE_CAN_STRUCT);

    // if we don't have any massage this an empty *VALID* read
    LValidRead := (LNumMsg = 0);

    for I := 0 to LNumMsg-1 do begin
      // TODO 2 -cFEATURE : insert error control
      // normal can frame
      if FNICanBuffer[I].FrameType = 0 then begin
        LCanMsg.ecmTime := int64NI2D(FNICanBuffer[I].Timestamp);
        LCanMsg.ecmID  := FNICanBuffer[I].ArbitrationId and $1FFFFFFF;
        LCanMsg.ecmExt := (FNICanBuffer[I].ArbitrationId and $20000000) <> 0;
        LCanMsg.ecmLen := FNICanBuffer[I].DataLength;
        // copy CAN data buffer
        Move(FNICanBuffer[I].Data,LCanMsg.ecmData,8);
        FReadMsgQueue.Enqueue(LCanMsg);
        LValidRead := true;
      end else if FNICanBuffer[I].FrameType = 6 then
        Inc(LErrorCount)
      else
        Inc(LInvalidCount);
    end;
  until LValidRead;

  if (LErrorCount > 0) then
    FLogger.LogDebug('NICAN: %d Error frame',[LErrorCount]);

  if (LInvalidCount > 0) then
    FLogger.LogDebug('NICAN: %d Invalid frame',[LInvalidCount]);
end;

function TNICanLink.statusToString(AStatus: NCTYPE_STATUS): string;
begin
	ncStatusToString(AStatus,1024,@FErrorStringBuf);
	Result := Trim(string(FErrorStringBuf));
end;

procedure TNICanLink.checkCanerror;
begin
  // TODO 2 -cFUNCTION : procedure TNICanLink.checkCanerror;
  // this function should be check errors when we close interface
end;

procedure TNICanLink.setName(AName: string);
begin
  if FActive then
    raise ENICanException.Create('Cannot change name: device active');
  FName := AName;
end;

procedure TNICanLink.setBaudrate(ABaudRate: TNICanBaudrate);
begin
  if FActive then
    raise ENICanException.Create('Cannot change speed: device active');

  if (FBaudRate <> ABaudRate) then begin
    if (baudrateD2NI(ABaudRate) <> 0) then
      FBaudRate := ABaudRate
    else
      raise ENICanException.Create('Cannot change speed: wrong speed');
  end;
end;

constructor TNICanLink.Create;
begin
  FLogger := TDbgLogger.Instance;
  FReadMsgQueue := TCanMsgQueue.Create;
  FWriteMsgQueue := TCanMsgQueue.Create;
  FAttrArray := TNIAttributeArray.Create;
  FBaudrate := canBaud100K;
  FActive := false;
end;

destructor TNICanLink.Destroy;
begin
  FAttrArray.Free;
  FReadMsgQueue.Free;
  FWriteMsgQueue.Free;
end;

procedure TNICanLink.Open;
var
  LSimpleAttrVal: NCTYPE_UINT32;
begin
  if not FActive then begin
    FAttrArray.Reset;
    FAttrArray.Add(NC_ATTR_BAUD_RATE,baudrateD2NI(FBaudRate));
    FAttrArray.Add(NC_ATTR_START_ON_OPEN,NC_FALSE);
    FLastStatus := configure;

    if FLastStatus <> 0 then begin
      FLogger.LogWarning('NICAN: Err: configuring Err: %s',[statusToString(FLastStatus)]);
      raise ENICanOpenError.Create;
    end;

    FLastStatus := ncOpenObject(PAnsiChar(AnsiString(FName)),@FCanNetworkObj);
    if FLastStatus <> 0 then begin
      FLogger.LogWarning('NICAN: Err: opening Err: %s',[statusToString(FLastStatus)]);
      raise ENICanOpenError.Create;
    end;

    LSimpleAttrVal := NC_TRUE;
    ncSetAttribute(FCanNetworkObj,NC_ATTR_LOG_BUS_ERROR ,sizeof(LSimpleAttrVal),@LSimpleAttrVal);
    FLastStatus := ncAction(FCanNetworkObj,NC_OP_START,0);

    if FLastStatus <> 0 then begin
      FLogger.LogWarning('NICAN: Err: opening rr: %s',[statusToString(FLastStatus)]);
      ncCloseObject(FCanNetworkObj);
      FCanNetworkObj := 0;
      raise ENICanOpenError.Create;
    end;

    FActive := true;
    FLogger.LogMessage('NICAN: Can Open');
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
    FLogger.LogMessage('NICAN: Can Closed');
  end;
end;

function TNICanLink.Read(var AMsg: TCanMsg): Boolean;
var
  LStatus: NCTYPE_STATUS;
begin
  Result := true;
  LStatus := 0;
  if FReadMsgQueue.Count = 0 then
    LStatus := readFromCan;

  if LStatus = 0 then begin
    if FReadMsgQueue.Count > 0 then
      AMsg := FReadMsgQueue.Dequeue
    else
      Result := false;
  end else begin
    FLogger.LogWarning('NICAN: Err: read error: %s',[statusToString(LStatus)]);
    Result := False;
  end;
end;

function TNICanLink.Write(AMsg: TCanMsg): Boolean;
var
  LNICanFrame: NCTYPE_CAN_FRAME;
begin
  Result := true;
  LNICanFrame.ArbitrationId := AMsg.ecmID;
  LNICanFrame.IsRemote      := 0;
  LNICanFrame.DataLength    := AMsg.ecmLen;

  Move(AMsg.ecmData,LNICanFrame.Data,8);
  FLastStatus := ncWrite(FCanNetworkObj,sizeof(LNICanFrame),@LNICanFrame);

  if FLastStatus <> 0 then begin
    FLogger.LogWarning('NICAN: Err: write error: %s',[statusToString(FLastStatus)]);
    Result := False;
  end;
end;

function TNICanLink.WriteQueued(AMsg: TCanMsg): Boolean;
begin
  Result := true;
  FWriteMsgQueue.Enqueue(AMsg);
  if FWriteMsgQueue.Count = kNumObject then
    Result := FlushWriteQueue;
end;

function TNICanLink.FlushWriteQueue: Boolean;
var
  LCanMsg: TCanMsg;
  I: Integer;
  LDataSize: Integer;
begin
  Result := true;
  for I := 0 to FWriteMsgQueue.Count - 1 do begin
    LCanMsg := FWriteMsgQueue.Dequeue;
    FNICanBuffer[I].ArbitrationId := LCanMsg.ecmID;
    FNICanBuffer[I].FrameType     := 0;
    FNICanBuffer[I].DataLength    := LCanMsg.ecmLen;
    Move(LCanMsg.ecmData,FNICanBuffer[I].Data,8);
  end;

  LDataSize := sizeof(NCTYPE_CAN_STRUCT) * FWriteMsgQueue.Count;
  FLastStatus := ncWriteMult(FCanNetworkObj,LDataSize,@FNICanBuffer);

  if FLastStatus <> 0 then begin
    FLogger.LogWarning('NICAN: Err: write error: %s',[statusToString(FLastStatus)]);
    Result := False;
  end;
end;


{$ENDREGION}
end.
