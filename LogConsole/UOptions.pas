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
