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
    vScrollBar: TScrollBar;
    eMask: TEdit;
    eValue: TEdit;
    lblValue: TLabel;
    lblMask: TLabel;
    cbFilter: TCheckBox;
    procedure cbFilterClick(Sender: TObject);
    procedure cbOpenClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pgControlChange(Sender: TObject);
    procedure pgControlResize(Sender: TObject);
    procedure sgRawLogDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect;
        State: TGridDrawState);
    procedure Timer1Timer(Sender: TObject);
    procedure vScrollBarChange(Sender: TObject);
  private
    { Private declarations }
    FOldPage: Integer;
    FLogger: TDbgLogger;
    FFileList: TFileNamesList;
    FLink: TNICanLink;
    FSqzLogProcessor: TSqzLogNetHandler;
    FCanSqzFilter: Cardinal;
    FCanSqzId: Cardinal;
    { can log support }
    FCanMsgList: TCanMsgList;
    FCanMsgView: TCanMsgView;
    procedure print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
    procedure setupCanView(AView: TCanMsgView);
    procedure addMsgToList(AMsg: TCanMsg);
    procedure setupOptions;
    procedure showOptions;
    procedure showFilterControls(AOnOff: Boolean);
    procedure setupLogRowCount;
    procedure updateRowSize;
    procedure updateScrollBar;
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

{$REGION 'FormEvents'}
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

  FCanMsgList := TCanMsgList.Create;
  FCanMsgView := TCanMsgView.Create(FCanMsgList);

  FLogger.LogMessage('Msgsets loaded');

  Caption := Caption + VersionInformation;
  setupLogRowCount;
  updateRowSize;

  // startup default values
  // TODO 2 -cFEATURE : load / save options
  FCanSqzId     := $FE0000;
  FCanSqzFilter := $FFC000;
  FSqzLogProcessor.NodeMask := $3FFF;
end;

procedure TfmMain.pgControlChange(Sender: TObject);
var
  LCanOpen: Boolean;

  procedure setupCase(AShow: Boolean);
  begin
    // save options
    setupOptions;
    // show filter
    showFilterControls(AShow);
    FOldPage := pgControl.TabIndex;
  end;
begin
  LCanOpen := True;
  case TAppPages(pgControl.TabIndex) of
    pgDebug: setupCase(false);
    pgCanLog: setupCase(true);

    pgOptions: begin
        showFilterControls(false);
        if FLink.Active then begin
          pgControl.TabIndex := FOldPage;
          MessageDlg('Cannot change setup with active link',mtError, [mbOk],0);
        end else begin
          LCanOpen := False;
          showOptions;
          FOldPage := pgControl.TabIndex;
        end;
      end;
  end;
  cbOpen.Enabled := LCanOpen;
end;

procedure TfmMain.pgControlResize(Sender: TObject);
begin
  setupLogRowCount;
  updateRowSize;
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
    addMsgToList(LMsg);
  end;
  Timer1.Enabled := true;
end;

procedure TfmMain.sgRawLogDrawCell(Sender: TObject; ACol, ARow: Integer; Rect:
    TRect; State: TGridDrawState);
var
  I,J: Integer;
begin
  // clear background
  sgRawLog.Canvas.FillRect(Rect);
  if ARow < FCanMsgView.Count then begin
    with FCanMsgView.Messages[ARow] do
      case ACol of
        0: sgRawLog.Canvas.TextOut(Rect.Left,Rect.Top,Format('0x%.8X',[ecmId]));
        1: sgRawLog.Canvas.TextOut(Rect.Left,Rect.Top,Format('%d',[ecmLen]));
        2: sgRawLog.Canvas.TextOut(Rect.Left,Rect.Top,DataStr);
      end;
  end;
end;

procedure TfmMain.vScrollBarChange(Sender: TObject);
begin
  FCanMsgView.Top := vScrollBar.Position;
  sgRawLog.Invalidate;
end;

{$ENDREGION}

{$REGION 'Local procedures'}

procedure TfmMain.print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
var
  LMessageString: string;
begin
  LMessageString := Format('N:%d -- ',[ANodeId])+ATitle;

  lbLogEntry.Items.Add(LMessageString);
  FLogger.LogMessage('Message sqzlog: '+LMessageString);
end;

procedure TfmMain.setupCanView(AView: TCanMsgView);
begin
  FCanMsgView.Free;
  FCanMsgView := AView;
end;

procedure TfmMain.addMsgToList(AMsg: TCanMsg);
var
  LScrollLen: Integer;
begin
  FLogger.LogDebug('AddMsgToList: %s',[AMsg.ToString]);
  FCanMsgList.Add(AMsg);
  if pgControl.TabIndex = Ord(pgCanLog) then begin
    updateScrollBar;
    sgRawLog.Invalidate;
  end;
end;

procedure TfmMain.cbFilterClick(Sender: TObject);
var
  LFilter: TCanMsgFilter;
begin
  if cbFilter.Checked then
    try
      if (eMask.Text <> '') and (eValue.Text <> '') then begin
        LFilter.MaskId := Cardinal(StrToInt(eMask.Text));
        LFilter.ValueId := Cardinal(StrToInt(eValue.Text));
        FCanMsgList.Filter := LFilter;
        FCanMsgList.Filtered := true;
        eMask.Enabled := false;
        eValue.Enabled := false;
        // resfresh control
        FCanMsgView.Update;
      end else
        cbFilter.Checked := false;
    except
      on E: EConvertError do begin
        LFilter := FCanMsgList.Filter;
        eMask.Text := Format('0x%.8X',[LFilter.MaskId]);
        eValue.Text := Format('0x%.8X',[LFilter.ValueId]);
        cbFilter.Checked := false;
      end;
    end
  else begin
    FCanMsgList.Filtered := false;
    eMask.Enabled := true;
    eValue.Enabled := true;
  end;
  updateScrollBar;
  sgRawLog.Invalidate;
end;

procedure TfmMain.setupOptions;
begin
  FCanSqzFilter := StrToIntDef(eSqzLogMask.Text,FCanSqzFilter);
  FCanSqzId     := StrToIntDef(eSqzLogID.Text,FCanSqzId);
  FSqzLogProcessor.NodeMask := StrToIntDef(eNodeMask.Text,FSqzLogProcessor.NodeMask);
end;

procedure TfmMain.showOptions;
begin
  eSqzLogMask.Text := Format('0x%.8X',[FCanSqzFilter]);
  eSqzLogID.Text   := Format('0x%.8X',[FCanSqzId]);
  eNodeMask.Text   := Format('0x%.8X',[FSqzLogProcessor.NodeMask]);
end;

procedure TfmMain.showFilterControls(AOnOff: Boolean);
begin
  cbFilter.Visible := AOnOff;
  lblMask.Visible  := AOnOff;
  eMask.Visible    := AOnOff;
  lblValue.Visible := AOnOff;
  eValue.Visible   := AOnOff;
end;

procedure TfmMain.setupLogRowCount;
begin
  sgRawLog.RowCount := sgRawLog.Height div sgRawLog.DefaultRowHeight;
  FCanMsgView.ViewSize := sgRawLog.RowCount;
end;

procedure TfmMain.updateRowSize;
begin
  with sgRawLog do
    ColWidths[2] := Width - (ColWidths[0]+ColWidths[1]+5);
end;

procedure TfmMain.updateScrollBar;
var
  LScrollLen: Integer;
begin
  // Scroll count only not visible part
  LScrollLen := FCanMsgList.Count - FCanMsgView.Count;
  if LScrollLen = 0 then
    vScrollBar.Visible := false
  else begin
    vScrollBar.Visible := true;
    vScrollBar.Max := LScrollLen;
  end;
end;

{$ENDREGION}
end.
