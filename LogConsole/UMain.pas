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
  UDbgLogger,
  UFileList,
  USqzLogCore,
  UNICanLink;

type
  TfmMain = class(TForm)
    eName: TEdit;
    cbOpen: TCheckBox;
    Label1: TLabel;
    Timer1: TTimer;
    lbLogEntry: TListBox;
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
    procedure print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);

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
  UFileVersion,
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
  FSqzLogProcessor.OnPrint := print;

  FFileList := TFileNamesList.Create;
  FFileList.Directory := ExtractFilePath(Application.ExeName)+kMsgSetSubpath + '\';
  FFileList.Pattern := '*.mdt';
  FFileList.IncludePath := true;
  for LFile in FFileList do
    FSqzLogProcessor.AddMsgSet(LFile);

  FLogger.LogMessage('Msgsets loaded');

  Caption := Caption + VersionInformation;

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

procedure TfmMain.print(ANodeId: Integer; AClass: TSqzLogClass; ATitle: string);
var
  LMessageString: string;
begin
  LMessageString := Format('N:%d -- ',[ANodeId])+ATitle;

  lbLogEntry.Items.Add(LMessageString);
  FLogger.LogMessage('Message sqzlog: '+LMessageString);
end;

{$ENDREGION}



end.
