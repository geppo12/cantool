program SqzLogConsole;

uses
  Forms,
  UMain in 'UMain.pas' {fmMain},
  USqzLogCore in 'USqzLogCore.pas',
  UNICanLink in 'UNICanLink.pas',
  UNIAPI in 'UNIAPI.pas',
  UDbgLogger in 'UDbgLogger.pas',
  UCanMsg in 'UCanMsg.pas',
  UFileList in 'UFileList.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
