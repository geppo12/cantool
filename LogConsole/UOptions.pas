unit UOptions;

interface

type
  TNCTOptions = class
    private
    class var
    FInstance: TNCTOptions;
    var
    FFilePath: string;

    procedure loadDefaults;
    procedure loadFromFile(AFile: string);
    procedure saveToFile(AFile: string);

    public
    SqueezeLogId: Cardinal;
    SqueezeLogMask: Cardinal;
    NodeMask: Cardinal;
    class constructor CreateInstance;
    class destructor DestroyInstance;
    constructor Create;
    destructor Destroy; override;
    function GetAppDataPath: string;

    class property Instance: TNCTOptions read FInstance;
  end;

implementation

uses
  Forms,
  IniFiles,
  ShlObj,
  Windows,
  SysUtils;

const
  kOptionsFileExt = '.ini';
  kDataFolder     = 'CanTool';

  // ini constants
  // section
  kIniOptions    = 'Options';
  // keys
  kIniSqzLogId   = 'SqueezeLogId';
  kIniSqzLogMask = 'SqueezeLogMask';
  kIniNodeMask   = 'NodeMask';

procedure TNCTOptions.loadDefaults;
begin
  SqueezeLogId   := $FE0000;
  SqueezeLogMask := $FFC000;
  NodeMask       := $3FFF;
end;

procedure TNCTOptions.loadFromFile(AFile: string);
var
  LIniFile: TIniFile;
begin
  LIniFile     := TIniFile.Create(AFile);
  SqueezeLogId := LIniFile.ReadInteger(kIniOptions,kIniSqzLogId,SqueezeLogId);
  SqueezeLogMask := LIniFile.ReadInteger(kIniOptions,kIniSqzLogMask,SqueezeLogMask);
  NodeMask     := LIniFile.ReadInteger(kIniOptions,kIniNodeMask,NodeMask);
  LIniFile.Free;
end;

procedure TNCTOptions.saveToFile(AFile: string);
var
  LIniFile: TIniFile;
begin
  LIniFile := TIniFile.Create(AFile);
  LIniFile.WriteInteger(kIniOptions,kIniSqzLogId,SqueezeLogId);
  LIniFile.WriteInteger(kIniOptions,kIniSqzLogMask,SqueezeLogMask);
  LIniFile.WriteInteger(kIniOptions,kIniNodeMask,NodeMask);
  LIniFile.Free;
end;

class constructor TNCTOptions.CreateInstance;
begin
  FInstance := TNCTOptions.Create;
end;

class destructor TNCTOptions.DestroyInstance;
begin
  FInstance.Free;
end;

constructor TNCTOptions.Create;
var
  LFileName: string;
begin
  loadDefaults;
  FFilePath := getAppDataPath;
  if FFilePath <> '' then begin
    LFileName := FFilePath + ExtractFileName(Application.ExeName);
    LFileName := ChangeFileExt(LFileName,kOptionsFileExt);
    if FileExists(LFileName) then
      loadFromFile(LFileName);
  end;
end;

destructor TNCTOptions.Destroy;
var
  LFileName: string;
begin
  if FFilePath <> '' then begin
    LFileName := FFilePath + ExtractFileName(Application.ExeName);
    LFileName := ChangeFileExt(LFileName,kOptionsFileExt);
    saveToFile(LFileName);
  end;
end;

function TNCTOptions.GetAppDataPath: string;
var
  LPath: array[0..MAX_PATH] of Char;
  LValid: Boolean;
begin
  LValid := false;
  if SHGetSpecialFolderPath(Application.Handle, LPath, CSIDL_COMMON_APPDATA, false) then begin
    Result := LPath;
    Result := Result + '\' + kDataFolder + '\';
    if DirectoryExists(Result) then
      LValid := true
    else
      LValid := CreateDir(Result);
  end;
  if not LValid then Result := '';
end;

end.
