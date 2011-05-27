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

unit UFileList;

interface

uses
  Classes;

type

  TFileNamesList = class
    private

    type
      { Enumeratore. Non può essere istanziata ma nei cicli 'for in'
        il compilatore la vede comunque }
      TFileNamesListEnumerator = class
      private
        FIndex: Integer;
        FList: TFileNamesList;
      public
        constructor Create(AList: TFileNamesList);
        function MoveNext: Boolean;
        function GetCurrent: string;
        property Current: string read GetCurrent;
      end;

    var
    FFileNames: TStringList;
    FDirectory: string;
    FPattern: string;
    FIncludePath: Boolean;
    FSync: Boolean;
    FAutoSync: Boolean;
    FError: Integer;

    procedure scanDir;
    procedure setDirectory(ADirectory: string);
    procedure setPattern(APattern: string);
    procedure setAutosync(AAutosync: Boolean);
    function getNames(AIndex: integer): string;
    function getCount: Integer;

    public
    constructor Create;
    destructor Destroy; override;
    procedure Invalidate;
    procedure AssignToStrings(AStrings: TStrings);
    procedure Rescan;
    function GetEnumerator: TFileNamesListEnumerator;
    property Directory: string read FDirectory write setDirectory;
    property Pattern: string read FPattern write setPattern;
    property AutoSync: Boolean read FAutoSync write setAutosync;
    property Error: Integer read FError;
    property IncludePath: Boolean read FIncludePath write FIncludePath;
    property Names[AIndex: Integer]: string read getNames;
    property Count: Integer read getCount;
  end;

implementation

uses
  SysUtils,
  //StrUtils,
  Windows;

{$REGION 'TFileNamesList imp'}

constructor TFileNamesList.TFileNamesListEnumerator.Create(AList: TFileNamesList);
begin
  inherited Create;
  FList := AList;
  FIndex := -1;
end;

function TFileNamesList.TFileNamesListEnumerator.MoveNext: Boolean;
begin
  FList.Rescan;
  Result := FIndex < FList.FFileNames.Count - 1;
  if Result then
    Inc(FIndex);
end;

function TFileNamesList.TFileNamesListEnumerator.GetCurrent: string;
begin
  Result := FList.Names[FIndex];
end;

{*-------------------------------------------------------------------*
 *                                                                   *
 *    SCOPO: Questa funzione isola tutte le funzionalita' windows    *
 *           di scnsione della directory                             *
 *    IN:    libName: directory padre                                *
 *           list: lista da riempire                                 *
 *           pattern: pattern da ricercare                           *
 *           flags: windows flags su cui effetturare un match        *
 *    OUT:   NONE                                                    *
 *                                                                   *
 *-------------------------------------------------------------------*}

procedure TFileNamesList.scanDir;
var
  LHFind: THandle;
  LFindData: TWin32FindData;
  LNext: Boolean;
  LOldDir: string;
begin
  if DirectoryExists(FDirectory) then begin
    if FDirectory <> '' then begin
      LOldDir := GetCurrentDir;
      SetCurrentDir(FDirectory);
    end;
  end;

  LHFind := FindFirstFile(PWideChar(FPattern),LFindData);

  { cancella la lista }
  FFileNames.Clear;

  if LHFind <> INVALID_HANDLE_VALUE then begin
     repeat
       if (LFindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
         { se non è una directory l'aggiungo }
         FFileNames.Add(LFindData.cFileName);
       LNext := FindNextFile(LHFind,LFindData);
     until not LNext;
     { nessun errore }
     FError := 0;
  end else{ INVALID_HANDLE_VALUE }
    FError := GetLastError;
  { mi sono sincronizzato }
  FSync := true;
  { reimposto la vacchia directory }
  SetCurrentDir(LOldDir);
end;

procedure TFileNamesList.setDirectory(ADirectory: string);
begin
  if FDirectory <> ADirectory then begin
    FDirectory := ADirectory;
    FSync := false;
    if FAutoSync then
      scanDir;
  end;
end;

procedure TFileNamesList.setPattern(APattern: string);
begin
  if FPattern <> APattern then begin
    FPattern := APattern;
    FSync := false;
    if FAutoSync then
      scanDir;
  end;
end;

procedure TFileNamesList.setAutosync(AAutosync: Boolean);
begin
  if FAutosync <> AAutosync then begin
    FAutosync := AAutosync;
    if FAutosync and not FSync then
      scanDir;
  end;
end;

function TFileNamesList.getNames(AIndex: integer): string;
begin
  Rescan;
  Result := FFileNames.Strings[AIndex];
  if FIncludePath then
    Result := FDirectory + Result;
end;

function TFileNamesList.getCount: Integer;
begin
  Rescan;
  Result := FFileNames.Count;
end;

constructor TFileNamesList.Create;
begin
  FFileNames := TStringList.Create;
  FSync := false;
  FAutosync := false;
end;

destructor TFileNamesList.Destroy;
begin
  FFileNames.Free;
end;

procedure TFileNamesList.Invalidate;
begin
  FSync := false;
end;

procedure TFileNamesList.AssignToStrings(AStrings: TStrings);
begin
  Rescan;
  AStrings.Clear;
  AStrings.AddStrings(FFileNames);
end;

procedure TFileNamesList.Rescan;
begin
  if not FSync then
    scanDir;
end;

function TFileNamesList.GetEnumerator: TFileNamesListEnumerator;
begin
  Result := TFileNamesListEnumerator.Create(self);
end;

{$ENDREGION}


end.
