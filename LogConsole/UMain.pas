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

unit UMain;

interface

{.$DEFINE WRITE_TEST}
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  UCanMsg,
  UDbgLogger,
  UFileList,
  USqzLogCore,
  UNICanLink, ComCtrls, Grids;

type
  TfmMain = class(TForm)
    eName: TEdit;
    cbOpen: TCheckBox;
    Label1: TLabel;
    Timer1: TTimer;
    pgControl: TPageControl;
    Debug: TTabSheet;
    CanLog: TTabSheet;
    Options: TTabSheet;
    lbLogEntry: TListBox;
    eSqzLogID: TEdit;
    eNodeMask: TEdit;
    Label3: TLabel;
    eSqzLogMask: TEdit;
    Label4: TLabel;
    sgRawLog: TStringGrid;
    procedure cbOpenClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pgControlChange(Sender: TObject);
    procedure pgControlResize(Sender: TObject);
    procedure sgRawLogClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FOldPage: Integer;
    FLogger: TDbgLogger;
    FFileList: TFileNamesList;
    FLink: TNICanLink;
    FSqzLogProcessor: TSqzLogNetHandler;
    FCanSqzFilter: Cardinal;
    FCanSqzId: Cardinal;
    procedure print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
    procedure setupOptions;
    procedure showOptions;
    procedure removeGridSelection; inline;
  public
    { Public declarations }
  end;

  // menmonic for pages
  TAppPages = (
    pgDebug = 0,
    pgCanLog = 1,
    pgOptions = 2
  );

const
  kMsgSetSubpath = 'MsgSets';

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

uses
  UFileVersion;

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
  FSqzLogProcessor.OnPrint := print;

  FFileList := TFileNamesList.Create;
  FFileList.Directory := ExtractFilePath(Application.ExeName)+kMsgSetSubpath + '\';
  FFileList.Pattern := '*.mdt';
  FFileList.IncludePath := true;
  for LFile in FFileList do
    FSqzLogProcessor.AddMsgSet(LFile);

  FLogger.LogMessage('Msgsets loaded');

  Caption := Caption + VersionInformation;
  removeGridSelection;

  // startup default values
  // TODO 2 -cFEATURE : load / save options
  FCanSqzId     := $FE0000;
  FCanSqzFilter := $FFC000;
  FSqzLogProcessor.NodeMask := $3FFF;

end;

procedure TfmMain.pgControlChange(Sender: TObject);
var
  LCanOpen: Boolean;
begin
  LCanOpen := True;
  case TAppPages(pgControl.TabIndex) of
    pgDebug,
    pgCanLog: begin
        // save options
        setupOptions;
        FOldPage := pgControl.TabIndex;
      end;
    pgOptions:
      if FLink.Active then begin
        pgControl.TabIndex := FOldPage;
        MessageDlg('Cannot change setup with active link',mtError, [mbOk],0);
      end else begin
        LCanOpen := False;
        showOptions;
        FOldPage := pgControl.TabIndex;
      end;
  end;

  cbOpen.Enabled := LCanOpen;
end;

procedure TfmMain.pgControlResize(Sender: TObject);
begin
{
  if pgControl.TabIndex = Ord(pgCanLog) then
    with sgRawLog do
      ColWidths[2] := Width - (ColWidths[0]+ColWidths[1]+5);
}
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
        FSqzLogProcessor.ProcessSqzData(ecmID,ecmData,ecmLen);
      end;
    LMsg.ToStrings(sgRawLog.Rows[sgRawLog.RowCount-1]);
    sgRawLog.RowCount := sgRawLog.RowCount + 1;
  end;
  Timer1.Enabled := true;
end;

{$REGION 'Local procedures'}

procedure TfmMain.print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
var
  LMessageString: string;
begin
  LMessageString := Format('N:%d -- ',[ANodeId])+ATitle;

  lbLogEntry.Items.Add(LMessageString);
  FLogger.LogMessage('Message sqzlog: '+LMessageString);
end;

procedure TfmMain.setupOptions;
begin
  FCanSqzFilter := StrToIntDef(eSqzLogMask.Text,FCanSqzFilter);
  FCanSqzId     := StrToIntDef(eSqzLogID.Text,FCanSqzId);
  FSqzLogProcessor.NodeMask := StrToIntDef(eNodeMask.Text,FSqzLogProcessor.NodeMask);
end;

procedure TfmMain.sgRawLogClick(Sender: TObject);
begin
  removeGridSelection
end;

procedure TfmMain.showOptions;
begin
  eSqzLogMask.Text := Format('0x%.8X',[FCanSqzFilter]);
  eSqzLogID.Text   := Format('0x%.8X',[FCanSqzId]);
  eNodeMask.Text   := Format('0x%.8X',[FSqzLogProcessor.NodeMask]);
end;

procedure TfmMain.removeGridSelection;
begin
  // trick to remove selection box not used in log applications
  sgRawLog.Selection := TGridRect(Rect(-1,-1,-1,-1));
end;

{$ENDREGION}



end.
