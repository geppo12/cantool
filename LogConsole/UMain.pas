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

// read 1M message for void :-)
{$UNDEF STRESS_TEST}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Grids,
  UCanMsg,
  UDbgLogger,
  UFileList,
  USqzLogCore,
  USequences,
  UNICanLink;

type
  TfmMain = class(TForm)
    cbOpen: TCheckBox;
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
    cbFilterEnable: TCheckBox;
    btnFilterEdit: TButton;
    TabSheet1: TTabSheet;
    cbSequence: TComboBox;
    btnSeqLoad: TButton;
    btnSeqGo: TButton;
    sSequenceResult: TShape;
    btnSeqCancel: TButton;
    odSequence: TOpenDialog;
    lbSeqOutText: TListBox;
    btnMarkerEdit: TButton;
    cbSqzLog20: TCheckBox;
    eName: TEdit;
    Label5: TLabel;
    Label1: TLabel;
    cbSpeed: TComboBox;
    btnClear: TButton;
    procedure btnClearClick(Sender: TObject);
    procedure btnSeqCancelClick(Sender: TObject);
    procedure btnFilterEditClick(Sender: TObject);
    procedure btnMarkerEditClick(Sender: TObject);
    procedure btnSeqGoClick(Sender: TObject);
    procedure btnSeqLoadClick(Sender: TObject);
    procedure cbFilterEnableClick(Sender: TObject);
    procedure cbOpenClick(Sender: TObject);
    procedure cbSpeedChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
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
    FLastPage: Integer;
    FSeqTerminate: Boolean;
    FLogger: TDbgLogger;
    FSequenceEngine: TSequenceEngine;
    FFileList: TFileNamesList;
    FLink: TNICanLink;
    FSqzLogProcessor: TSqzLogNetHandler;
    { can log support }
    FCanMsgList: TCanMsgList;
    FCanMsgView: TCanMsgView;

    procedure print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
    procedure seqPrint(AString: string);
    procedure sendMsg(AMsg: TCanMsg);
    procedure setupCanView(AView: TCanMsgView);
    procedure addMsgToList(AMsg: TCanMsg);
    procedure setupOptions;
    procedure showOptions;
    procedure showFilterControls(AOnOff: Boolean);
    procedure setupLogRowCount;
    procedure updateRowSize;
    procedure updateScrollBar;
    procedure changeLinkStatus(AActive: Boolean);
  public
    { Public declarations }
  end;

  // menmonic for pages
  TAppPages = (
    pgDebug    = 0,
    pgCanLog   = 1,
    pgSequences = 2,
    pgOptions  = 3
  );

const
  kMsgSetSubpath = 'MsgSets';

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

uses
  StrUtils,
  UAbout,
  UUtils,
  UOptions,
  UFmFilters,
  UFmMarkers,
  UFileVersion;

{$IFDEF STRESS_TEST}
var
  GetTestMsgCount: Integer;

function GetTestMsg(var AMsg: TCanMsg): Boolean;
begin
  Inc(GetTestMsgCount);
  AMsg.ecmID := GetTestMsgCount;
  AMsg.ecmLen := 8;
  AMsg.ecmExt := True;
  Result := (GetTestMsgCount < 1000000);
end;
{$ENDIF}

{$REGION 'FormEvents'}
procedure TfmMain.cbOpenClick(Sender: TObject);
begin
  if eName.Text = '' then
    cbOpen.Checked := false
  else if cbOpen.Checked then begin
    try
      FLink.Name := TNCTOptions.Instance.CanDevice;
      FLink.BaudRate := TNCTOptions.Instance.CanSpeed;
      FLink.Open;
      changeLinkStatus(true);
    except
      on ENICanOpenError do
        cbOpen.Checked := false
    end;
  end else begin
    FLink.Close;
    changeLinkStatus(false);
  end;
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
  // get the logger intstance and initialize it
  FLogger := TDbgLogger.Instance;
  FLogger.InitEngine(leSmartInspect);
  FLogger.Enable := true;

  FLink := TNICanLink.Create;
  FLink.Name     := TNCTOptions.Instance.CanDevice;
  FLink.BaudRate := TNCTOptions.Instance.CanSpeed;
  FLogger.LogMessage('Link inizialized');

  // initialize sequence engine
	FSequenceEngine := TSequenceEngine.Create;
  FSequenceEngine.OnSendMessage := sendMsg;
  FSequenceEngine.OnOutText := seqPrint;

  // initialize log processor engine
  FSqzLogProcessor := TSqzLogNetHandler.Create(TNCTOptions.Instance.SqueezeLogV20);
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

{$IFDEF STRESS_TEST}
  Caption := Caption + ' <Stress Test Variant>';
{$ENDIF}

  setupLogRowCount;
  updateRowSize;

  FSqzLogProcessor.NodeMask := TNCTOptions.Instance.NodeMask;
  showOptions;
  FLastPage := Ord(pgCanLog);
  pgControl.TabIndex := FLastPage;
  showFilterControls(true);
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  LAbout: TForm;
begin
  setupOptions;
  FSeqTerminate := true;
  LAbout := TfmAbout.Create(self);
  LAbout.ShowModal;
end;

procedure TfmMain.pgControlChange(Sender: TObject);
var
  LCanOpen: Boolean;
  LBtnClear: Boolean;
begin
  LCanOpen := True;
  LBtnClear := True;
  case TAppPages(pgControl.TabIndex) of
    pgDebug: showFilterControls(false);
    pgCanLog: begin
        showFilterControls(true);
        updateScrollBar;
        sgRawLog.Invalidate;
      end;

    pgSequences:
        showFilterControls(false);

    pgOptions: begin
        showFilterControls(false);
        LBtnClear := false;
        if FLink.Active then begin
          // Override: cannot select this page
          pgControl.TabIndex := FLastPage;
          MessageDlg('Cannot change setup with active link',mtError, [mbOk],0);
        end else
          LCanOpen := False;
      end;
  end;
  cbOpen.Enabled := LCanOpen;
  // TODO -cFIXME 1 : gestire meglio visualizzazione dei controlli
  btnClear.Visible := LBtnClear;

  // save option on exit of setup page
  if FLastPage = Ord(pgOptions) then
    setupOptions;

  FLastPage := pgControl.TabIndex;
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

{$IFDEF STRESS_TEST}
  while GetTestMsg(LMsg) do begin
{$ELSE}
  while FLink.Active and FLink.Read(LMsg) do begin
    with LMsg, TNCTOptions.Instance do
      if (SqueezeLogMask and ecmID) = SqueezeLogId then begin
        FLogger.LogDebug('Process msg: %s',[ToString]);
        FSqzLogProcessor.ProcessSqzData(ecmID,ecmData,ecmLen);
      end;
{$ENDIF}
    addMsgToList(LMsg);
  end;
  Timer1.Enabled := true;
end;

procedure TfmMain.sgRawLogDrawCell(Sender: TObject; ACol, ARow: Integer; Rect:
    TRect; State: TGridDrawState);
var
  I,J: Integer;
  LOldColor: TColor;
begin
  // clear background
  if ARow < FCanMsgView.Count then begin
    LOldColor := sgRawLog.Canvas.Brush.Color;
    sgRawLog.Canvas.Brush.Color := FCanMsgView.Color[ARow];
    sgRawLog.Canvas.FillRect(Rect);
    with FCanMsgView.Messages[ARow] do
      case ACol of
        0: sgRawLog.Canvas.TextOut(Rect.Left,Rect.Top,Format('0x%.8X%s',[ecmId,IfThen(ecmExt,' XTD','')]));
        1: sgRawLog.Canvas.TextOut(Rect.Left,Rect.Top,Format('%d',[ecmLen]));
        2: sgRawLog.Canvas.TextOut(Rect.Left,Rect.Top,DataStr);
      end;
    sgRawLog.Canvas.Brush.Color := LOldColor;
  end else
    sgRawLog.Canvas.FillRect(Rect);
end;

procedure TfmMain.vScrollBarChange(Sender: TObject);
begin
  FCanMsgView.Top := vScrollBar.Position;
  sgRawLog.Invalidate;
end;

procedure TfmMain.cbFilterEnableClick(Sender: TObject);
var
  LFilter: TCanMsgFilter;
begin
  if cbFilterEnable.Checked then begin
    if FCanMsgList.FilterList.Count > 0 then begin
      FCanMsgList.Filtered := true;
      // resfresh control
      FCanMsgView.Update;
    end else begin
      cbFilterEnable.Checked := false;
      MessageDlg('No filters avaible' + #10#13 + 'Please edit',mtError, [mbOk],0);
    end;
  end else
    FCanMsgList.Filtered := false;
  updateScrollBar;
  sgRawLog.Invalidate;
end;

procedure TfmMain.btnFilterEditClick(Sender: TObject);
var
  LFilterForm: TFmFilter;
begin
  LFilterForm := TFmFilter.Create(self);
  LFilterForm.ShowFilterList(FCanMsgList.FilterList);
  if LFilterForm.ShowModal = mrOk then
    LFilterForm.UpdateFilterList(FCanMsgList.FilterList);

  LFilterForm.Free;
end;

procedure TfmMain.btnMarkerEditClick(Sender: TObject);
var
  LForm: TfmMarkerEdit;
begin
  LForm := TfmMarkerEdit.Create(self);
  LForm.Markers := FCanMsgView.Markers;
  if LForm.ShowModal = mrOk then begin
    FCanMsgView.Markers := LForm.Markers;
    sgRawLog.Invalidate;
  end;
  LForm.Free;
end;

procedure TfmMain.btnSeqLoadClick(Sender: TObject);
begin
  if odSequence.Execute then begin
    FSequenceEngine.Parser.LoadFromFile(odSequence.FileName);
    FSequenceEngine.LoadNames(cbSequence.Items);
    if cbSequence.Items.Count > 0 then
      cbSequence.ItemIndex := 0;
  end;
end;

procedure TfmMain.btnSeqGoClick(Sender: TObject);
var
  LMsg: TCanMsg;
  LEvent: TTriggerEvent;
  LStepValid: Boolean;
  seqName: string;

  procedure enableSeqControl(AOnOff: Boolean);
  begin
    btnSeqCancel.Enabled := not AOnOff;
    btnSeqGo.Enabled   := AOnOff;
    btnSeqLoad.Enabled := AOnOff;
    Timer1.Enabled     := AOnOff;
  end;
begin
  // TODO 2 -cFEATURE : move this code inside a thread
  seqName := cbSequence.Items.Strings[cbSequence.ItemIndex];
  try
    if FSequenceEngine.SetupSequence(seqName) then begin
      FSeqTerminate := false;
      FSequenceEngine.Reset;
      FSequenceEngine.Start;
      enableSeqControl(false);
      Timer1.Enabled := false;
      LStepValid := true;

      //
      while FLink.Active and LStepValid and not FSeqTerminate do begin
        // process windows events
        Application.ProcessMessages;
        // process Can messages as triggers
        if FLink.Read(LMsg) then begin
          LEvent.EventType := kTriggerMsgEv;
          LEvent.Msg       := LMsg;
          FSequenceEngine.Trigger(LEvent);
          addMsgToList(LMsg);
        end;
        // execute program step
        LStepValid := FSequenceEngine.ExecuteStep;
      end;

      // termino la sequenza ed in base al risultato segno lo stato
      case FSequenceEngine.Terminate of
        kTerminateFail: sSequenceResult.Brush.Color := clRed;
        kTerminateSuccess: sSequenceResult.Brush.Color := clGreen;
      end;
    end;
  finally
    enableSeqControl(true);
  end;
end;

procedure TfmMain.btnSeqCancelClick(Sender: TObject);
begin
  FSeqTerminate := true;
end;

procedure TfmMain.btnClearClick(Sender: TObject);
begin
  case TAppPages(pgControl.TabIndex) of
    pgCanLog: begin
        FCanMsgList.ClearMsg;
        sgRawLog.Invalidate;
      end;
    else
      UUtils.ShowMessage('Not implemented');
  end;
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

procedure TfmMain.seqPrint(AString: string);
begin
  lbSeqOutText.Items.Add(AString);
end;

procedure TfmMain.sendMsg(AMsg: TCanMsg);
begin
  if FLink.Active then
    FLink.Write(AMsg);
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

procedure TfmMain.cbSpeedChange(Sender: TObject);
begin
  TNCTOptions.Instance.CanSpeed := TNICanBaudrate(cbSpeed.ItemIndex);
end;

procedure TfmMain.setupOptions;
begin
  with TNCTOptions.Instance do begin
    SqueezeLogMask := StrToIntDef(eSqzLogMask.Text,SqueezeLogMask);
    SqueezeLogId   := StrToIntDef(eSqzLogID.Text,SqueezeLogId);
    SqueezeLogV20  := cbSqzLog20.Checked;
    NodeMask := StrToIntDef(eNodeMask.Text,NodeMask);
    FSqzLogProcessor.NodeMask := NodeMask;
    CanDevice      := eName.Text;
    CanSpeed       := TNICanBaudrate(cbSpeed.ItemIndex);
  end;
end;

procedure TfmMain.showOptions;
begin
  with TNCTOptions.Instance do begin
    eSqzLogMask.Text := Format('0x%.8X',[SqueezeLogMask]);
    eSqzLogID.Text   := Format('0x%.8X',[SqueezeLogId]);
    cbSqzLog20.Checked := SqueezeLogV20;
    eNodeMask.Text   := Format('0x%.8X',[NodeMask]);
    // can info
    eName.Text       := CanDevice;
    cbSpeed.ItemIndex := Ord(CanSpeed);
  end;
end;

procedure TfmMain.showFilterControls(AOnOff: Boolean);
begin
  btnFilterEdit.Visible := AOnOff;
  btnMarkerEdit.Visible := AOnOff;
  cbFilterEnable.Visible  := AOnOff;
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

procedure TfmMain.changeLinkStatus(AActive: Boolean);
begin
  btnSeqGo.Enabled := AActive;
  btnSeqCancel.Enabled := AActive;
  pgControl.TabIndex := FLastPage;
end;

{$ENDREGION}
end.
