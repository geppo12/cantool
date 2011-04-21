{ engine agnostic logger. NOT THREAD SAFE
  (c) 2011 Ing Giuseppe 'Ninjeppo' Monteleone }
unit UDbgLogger;

interface

type
  TDbgLogClass = (
    lcInternal,
    lcFatal,
    lcError,
    lcWarning,
    lcMessage,
    lcVerbose,
    lcDebug
  );

  TDbgLoggerEngine = class abstract
    private
    FEnable: Boolean;
    procedure setEnable(AEnable: Boolean);

    protected
    FInitialized: Boolean;
    procedure enableEngine(AEnable: Boolean); virtual;

    public
    procedure Init; virtual;
    procedure Reset; virtual;
    procedure LogData(ALogLevel: TDbgLogClass; AString: string); virtual; abstract;
    procedure LogException(AString: string = ''); virtual;
    property Enable: Boolean read FEnable write setEnable;
  end;

  TDbgLoggerType = (
    leWindows,
    leSmartInspect,
    leCodeSite
  );
  TDbgLogger = class
    class var FInstance: TDbgLogger;
    var
    FEnable: Boolean;
    FLoggerEngine: TDbgLoggerEngine;

    procedure setEnable(AEnable: Boolean);
    public
    class constructor Create;
    class destructor Destroy;
    procedure InitEngine(AEngine: TDbgLoggerType);
    procedure Reset;
    procedure LogException(AString: string);
    procedure LogError(AString: string); overload;
    procedure LogError(AStringFmt: string; AArgs: array of const); overload;
    procedure LogWarning(AString: string); overload;
    procedure LogWarning(AStringFmt: string; AArgs: array of const); overload;
    procedure LogMessage(AString: string); overload;
    procedure LogMessage(AStringFmt: string; AArgs: array of const); overload;
    procedure LogVerbose(AString: string); overload;
    procedure LogVerbose(AStringFmt: string; AArgs: array of const); overload;
    procedure LogDebug(AString: string); overload;
    procedure LogDebug(AStringFmt: string; AArgs: array of const); overload;
    property Enable: boolean read FEnable write setEnable;

    class property Instance: TDbgLogger read FInstance;
  end;


implementation

uses
{$IFDEF USE_SMARTINSPECT}
  SiAuto,
  SmartInspect,
{$ENDIF}
  Forms,
  SysUtils;
type
{$REGION 'SmartInspactEngine'}
{$IFDEF USE_SMARTINSPECT}
  TDbgLoggerEngineSI = class(TDbgLoggerEngine)
    protected
    procedure enableEngine(AEnabled: Boolean); override;

    public
    procedure Init; override;
    procedure Reset; override;
    procedure LogData(AClass: TDbgLogClass; AString: string); override;
    procedure LogException(AString: string = ''); override;
  end;
{$ENDIF}
{$ENDREGION}

// trick to support real application folder in future
function GetAppDataFolder: string;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

{$REGION 'TDbgLoggerEngine'}

procedure TDbgLoggerEngine.setEnable(AEnable: Boolean);
begin
  // if engine not inizialized we suppose that is not enebled
  if FInitialized then begin
    if FEnable <> AEnable then begin
      FEnable := AEnable;
      enableEngine(AEnable);
    end;
  end;
end;

procedure TDbgLoggerEngine.enableEngine(AEnable: Boolean);
begin
  // must be redefinited form derived classes
end;

procedure TDbgLoggerEngine.Init;
begin
  // must be redefinited form derived classes
end;

procedure TDbgLoggerEngine.Reset;
begin
  // must be redefinited form derived classes
end;

procedure TDbgLoggerEngine.LogException(AString: string = '');
begin
  LogData(lcError,Format('EXCEPTION: %s',[AString]));
end;


{$ENDREGION}

{$REGION 'TDbgLogger'}

procedure TDbgLogger.setEnable(AEnable: Boolean);
begin
  if FEnable <> AEnable then begin
    if FLoggerEngine <> nil then begin
      FEnable := AEnable;
      FLoggerEngine.Enable := AEnable;
    end else
      FEnable := false;
  end;
end;

class constructor TDbgLogger.Create;
begin
  FInstance := TDbgLogger.Create;
end;

class destructor TDbgLogger.Destroy;
begin
  FInstance.Free;
end;

procedure TDbgLogger.InitEngine(AEngine: TDbgLoggerType);
begin
  // TODO 2 -cFIXME : inserire eccezioni adatte
  case AEngine of
    leWindows: ; //Exception.Create('Engine required not avaible');
    leSmartInspect:
{$IFDEF USE_SMARTINSPECT}
      FLoggerEngine := TDbgLoggerEngineSI.Create;
{$ENDIF}

    leCodeSite: ; //raise Exception.Create('Engine required not avaible');
    else
      raise Exception.Create('Engine required unknown');
  end;
  if FLoggerEngine <> nil then begin
    FLoggerEngine.Init;
    FEnable := FLoggerEngine.Enable;
  end else
    FEnable := false;
end;

procedure TDbgLogger.Reset;
begin
  if FEnable then
    FLoggerEngine.Reset;
end;


procedure TDbgLogger.LogException(AString: string);
begin
  if FEnable then try
    FLoggerEngine.LogException(AString);
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogError(AString: string);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcError,AString);
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogError(AStringFmt: string; AArgs: array of const);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcError,Format(AStringFmt,AArgs));
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogWarning(AString: string);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcWarning,AString);
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogWarning(AStringFmt: string; AArgs: array of const);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcWarning,Format(AStringFmt,AArgs));
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogMessage(AString: string);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcMessage,AString);
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogMessage(AStringFmt: string; AArgs: array of const);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcWarning,Format(AStringFmt,AArgs));
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogVerbose(AString: string);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcVerbose,AString);
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogVerbose(AStringFmt: string; AArgs: array of const);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcVerbose,Format(AStringFmt,AArgs));
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogDebug(AString: string);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcDebug,AString);
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

procedure TDbgLogger.LogDebug(AStringFmt: string; AArgs: array of const);
begin
  if FEnable then try
    FLoggerEngine.LogData(lcDebug,Format(AStringFmt,AArgs));
  except
    on E: Exception do
      FLoggerEngine.LogData(lcInternal,E.Message);
  end;
end;

{$ENDREGION}

{$REGION 'TDbgLoggerEngineSI'}
{$IFDEF USE_SMARTINSPECT}

procedure TDbgLoggerEngineSI.enableEngine(AEnabled: Boolean);
begin
  Si.Enabled := AEnabled;
end;

// TODO 2 -cLANGUAGE : tradurre in inglese i commenti
procedure TDbgLoggerEngineSI.Init;
var
  LFileNameSic: string;
  LFileNameSil: string;
  LUserDir: string;
  sicDone: Boolean;
begin
  FInitialized := false;
  { suppongo che il file *.sic esita }
  sicDone := true;
  LUserDir := GetAppDataFolder;

  { creo  il nome opportuno per il file *.sic corrente nella directory del applicativo }
  LFileNameSic := ChangeFileExt(Application.ExeName,'.sic');
  if not FileExists(LFileNameSic) then begin
    { se non esiste nella directory del programma provo nella directory utente }
    LFileNameSic := LUserDir + ExtractFileName(LFileNameSic);
    { se non esiste nemmeno qui marco non esistente }
    if not FileExists(LFileNameSic) then
      sicDone := false;
  end;

  { se l'ho trovato simposto le variabili e carico la configurazione }
  if sicDone then begin
    { filename di default (stesso path del file sic) }
    Si.SetVariable('DefFilename',ChangeFileExt(LFileNameSic,'.sil'));
    { file name con path utente }
    LFileNameSil := ChangeFileExt(LUserDir + ExtractFileName(LFileNameSic),'.sil');
    Si.SetVariable('UserFilename',LFileNameSil);
    { carico la configurazione dal file sic }
    Si.LoadConfiguration(LFileNameSic);
{$IFDEF _MICROSEC}
    Si.Resolution := crHigh;
{$ENDIF}
    SiMain.ClearAll;

    SiMain.LogVerbose('Read SmartInspect config %s',[LFileNameSic]);
{$IFNDEF EUREKALOG}
    Application.OnException := SiMain.ExceptionHandler;
{$ENDIF}
    FInitialized := true;
    // for consistency with Engine enable flag
    // TODO 1 -cFIXME : review this point
    Si.Enabled := false;
  end;
end;

procedure TDbgLoggerEngineSI.Reset;
begin
  SiMain.ClearAll;
end;

procedure TDbgLoggerEngineSI.LogData(AClass: TDbgLogClass; AString: string);
begin
  case AClass of
    lcInternal: SiMain.LogFatal('Internal [TDbgLoggerEngineSI] error: %s',[AString]);
    lcFatal: SiMain.LogFatal(AString);
    lcError: SiMain.LogError(AString);
    lcWarning: SiMain.LogWarning(AString);
    lcMessage: SiMain.LogMessage(AString);
    lcVerbose: SiMain.LogVerbose(AString);
    lcDebug: SiMain.LogDebug(AString);
  end;
end;

procedure TDbgLoggerEngineSI.LogException(AString: string);
begin
  SiMain.LogException(AString);
end;


{$ENDIF} { USE_SMARTINSPECT }
{$ENDREGION}

end.
