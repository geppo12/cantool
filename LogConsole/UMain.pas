unit UMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  UDbgLogger,
  UNICanLink;

type
  TfmMain = class(TForm)
    Memo1: TMemo;
    eName: TEdit;
    cbOpen: TCheckBox;
    Label1: TLabel;
    procedure cbOpenClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FLogger: TDbgLogger;
    FLink: TNICanLink;
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.cbOpenClick(Sender: TObject);
begin
  if cbOpen.Checked then begin
    try
      FLink.Name := eName.Text;
      FLink.Open;
    except
      on ENICanOpenError do
        cbOpen.Checked := false
    end;
  end else
    FLink.Close;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
  FLink.Free;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  FLogger := TDbgLogger.Instance;
  FLogger.InitEngine(leSmartInspect);
  FLogger.Enable := true;
  FLink := TNICanLink.Create;
  FLogger.LogMessage('Link inizialized');
end;



end.
