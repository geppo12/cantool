program LogConsole;

uses
  Forms,
  UMain in 'UMain.pas' {fmMain},
  USqzLogCore in 'USqzLogCore.pas',
  UNICanLink in 'UNICanLink.pas',
  UNIAPI in 'UNIAPI.pas',
  UCanMsg in 'UCanMsg.pas',
  UFileList in 'UFileList.pas',
  UDbgLogger in '..\Common\UDbgLogger.pas',
  UFileVersion in '..\Common\UFileVersion.pas',
  UAbout in 'UAbout.pas' {fmAbout},
  UFmFilters in 'UFmFilters.pas' {fmFilter},
  USequences in 'USequences.pas',
  USplitterStr in 'USplitterStr.pas',
  UOptions in 'UOptions.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
