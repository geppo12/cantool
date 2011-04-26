program LogCompiler;

uses
  Forms,
  UFmMain in 'UFmMain.pas' {fmMain},
  UCore in 'UCore.pas',
  ULogOptions in 'ULogOptions.pas',
  UDbgLogger in '..\Common\UDbgLogger.pas',
  UFileVersion in '..\Common\UFileVersion.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
