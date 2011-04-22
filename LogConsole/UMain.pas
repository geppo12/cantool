unit UMain;

interface

{.$DEFINE WRITE_TEST}
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  UDbgLogger,
  UFileList,
  USqzLogCore,
  UNICanLink;

type
  TfmMain = class(TForm)
    Memo1: TMemo;
    eName: TEdit;
    cbOpen: TCheckBox;
    Label1: TLabel;
    Timer1: TTimer;
    procedure cbOpenClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FLogger: TDbgLogger;
    FFileList: TFileNamesList;
    FLink: TNICanLink;
    FSqzLogProcessor: TSqzLogNetHandler;
    FCanSqzFilter: Cardinal;
    FCanSqzId: Cardinal;

  public
    { Public declarations }
  end;

const
  kMsgSetSubpath = 'MsgSets';

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

uses
  UCanMsg;

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
  FSqzLogProcessor.Free;
  FLink.Free;
end;

procedure TfmMain.FormCreate(Sender: TObject);
var
  LFile: string;
begin
  FLogger := TDbgLogger.Instance;
  FLogger.InitEngine(leSmartInspect);
  FLogger.Enable := true;

  FLink := TNICanLink.Create;
  FLogger.LogMessage('Link inizialized');

  FSqzLogProcessor := TSqzLogNetHandler.Create;

  FFileList := TFileNamesList.Create;
  FFileList.Directory := ExtractFilePath(Application.ExeName)+kMsgSetSubpath + '\';
  FFileList.Pattern := '*.mdt';
  FFileList.IncludePath := true;
  for LFile in FFileList do
    FSqzLogProcessor.AddMsgSet(LFile);

  FLogger.LogMessage('Msgsets loaded');

  FCanSqzFilter := $FFC000;
  FCanSqzId     := $FE0000;
end;

procedure TfmMain.Timer1Timer(Sender: TObject);
var
  LMsg: TCanMsg;
begin
  Timer1.Enabled := False;

  while FLink.Active and FLink.Read(LMsg) do begin
    with LMsg do
      if (FCanSqzFilter and ecmID) = FCanSqzId then begin
        FLogger.LogDebug('Process msg: %s',[ToString]);
        FSqzLogProcessor.ProcessSqzData(GetNode,ecmData,ecmLen);
      end;
  end;

{ per debug. Simula un messaggio Egodom cmd 0xF della scheda 6
  tenerlo per le prove di trasmissione 'write' }
{$IFDEF WRITE_TEST}
  LMsg.ecmID := $2F03C006;
  LMsg.ecmLen := 6;
  LMsg.ecmData[0] := 2;
  LMsg.ecmData[1] := 0;
  LMsg.ecmData[2] := 0;
  LMsg.ecmData[3] := 0;
  LMsg.ecmData[4] := 0;
  LMsg.ecmData[5] := 0;
  FLink.Write(LMsg);
{$ENDIF}

  Timer1.Enabled := true;
end;

{$REGION 'Local procedures'}
{$ENDREGION}



end.
