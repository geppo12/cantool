unit UUtils;

interface

procedure ShowMessage(AMessage: string);
procedure ShowErrorMessage(AMessage: string; ACause: string = '');
function QueryMessage(AMessage: string): Boolean;
procedure NotAvaible(AObj: TObject; AMsg: string);

implementation

uses
  SysUtils,
  SiAuto,
  Forms,
  Windows;

procedure ShowMessage(AMessage: string);
begin
  Application.MessageBox(PChar(AMessage),PChar(Application.Title),MB_OK or MB_ICONEXCLAMATION);
  SiMain.LogVerbose('[Message]: '+AMessage);
end;

procedure ShowErrorMessage(AMessage: string; ACause: string = '');
begin
  if ACause <> '' then
    AMessage := AMessage + ': ' +ACause;
  Application.MessageBox(PChar(AMessage),PChar(Application.Title),MB_OK or MB_ICONERROR);
  SiMain.LogWarning('[Message]: '+AMessage);
end;

function QueryMessage(AMessage: string): Boolean;
begin
  Result := Application.MessageBox(PChar(AMessage),PChar(Application.Title),MB_OKCANCEL or MB_ICONQUESTION) = IDOK;
  SiMain.LogVerbose('[Query]: '+AMessage+' '+BoolToStr(Result,true));
end;

// TODO 2 -cFIXME : da togliere al termine del debug
procedure NotAvaible(AObj: TObject; AMsg: string);
var
  LClassName: string;
begin
  LClassName := '';
  if AObj <> nil then
    LClassName := AObj.ClassName + '.';

  ShowMessage('Metodo ' + LClassName + AMsg + ' non implementato');
end;

end.



