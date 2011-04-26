program LogCompiler;

uses
  Forms,
  UFmMain in 'UFmMain.pas' {fmMain},
  UDbgLogger in 'UDbgLogger.pas',
  UFileVersion in 'UFileVersion.pas',
  UCore in 'UCore.pas',
  ULogOptions in 'ULogOptions.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
