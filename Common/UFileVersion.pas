unit UFileVersion;

interface
function VersionInformation(A4Digit: boolean = false; AShowBuild: Boolean = true): string;

implementation
// if defined use four digit (major, minor, revision, build
{.$DEFINE VER4DIGIT}

uses Forms,Windows,SysUtils;

function VersionInformation(A4Digit: boolean; AShowBuild: Boolean): string;
var
  sFileName: string;
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
begin
  sFileName := Application.ExeName;
  VerInfoSize := GetFileVersionInfoSize(PChar(sFileName), Dummy);
  GetMem(VerInfo, VerInfoSize);
  GetFileVersionInfo(PChar(sFileName), 0, VerInfoSize, VerInfo);
  VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
  with VerValue^ do
  begin
    Result := IntToStr(dwFileVersionMS shr 16);
    Result := Result + '.' + IntToStr(dwFileVersionMS and $FFFF);
    if A4Digit then begin
      Result := Result + '.' + IntToStr(dwFileVersionLS shr 16);
      Result := Result + '.' + IntToStr(dwFileVersionLS and $FFFF);
    end else if AShowBuild then
      Result := Result + ' build ' + IntToStr(dwFileVersionLS and $FFFF);
  end;
  FreeMem(VerInfo, VerInfoSize);
end;



end.
