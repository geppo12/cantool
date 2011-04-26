unit UFmMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  UFileVersion,
  UCore,
  ULogOptions,
  UDbgLogger;

type
  TfmMain = class(TForm)
      lbFiles: TListBox;
      btnAddFiles: TButton;
      btnProcess: TButton;
      Label1: TLabel;
      eMsgSet: TEdit;
      OpenDialog: TOpenDialog;
      mError: TMemo;
      cbCleanOnly: TCheckBox;
      btnProject: TButton;
      eSetDir: TEdit;
      SaveDialog: TSaveDialog;
      cbCRC: TCheckBox;
      cbDoublePar: TCheckBox;
      btnClear: TButton;
      procedure FormDestroy(Sender: TObject);
      procedure FormCreate(Sender: TObject);
    	procedure btnProcessClick(Sender: TObject);
      procedure eMsgSetChange(Sender: TObject);
      procedure eMsgSetExit(Sender: TObject);
      procedure btnAddFilesClick(Sender: TObject);
      procedure lbFilesMouseMove(Sender: TObject; Shift: TShiftState; X: Integer;
              Y: Integer);
      procedure lbFilesKeyDown(Sender: TObject; var Key: WORD; Shift: TShiftState);
      procedure btnProjectClick(Sender: TObject);
      procedure cbCRCClick(Sender: TObject);
      procedure cbDoubleParClick(Sender: TObject);
      procedure btnClearClick(Sender: TObject);

    private
      { Private declarations }
      FDbgLogger: TDbgLogger;
      FLogProcessor: TLogProcessor;
      FFullName: TStringList;
      FOptionsList: TStringList;
      FMsgSet: Integer;
      procedure updateMsgSet;
      function readIntProperty(APropertyValue: string; ADefault: Integer): Integer;
      procedure loadOptions(AList: TStrings);
      procedure loadProject(AName: string);
      procedure saveProject(AName: string);
      procedure addFile(AName: string);
      procedure remFile(ANameIdx: Integer);
      procedure clear;
      procedure defaultOpt;
    public
      { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

uses
  Math;

const
  kProjectExtStr = 'psz';

  kMsgSetProperty	= 'msgset';
  kDParProperty	  = 'doublepar';
  kUseCrcProperty = 'usecrc';

procedure TfmMain.FormDestroy(Sender: TObject);
begin
	FLogProcessor.Free;
	FFullName.Free;
	FOptionsList.Free;
	FDbgLogger.LogMessage('LogCompiler Closed');
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  FDbgLogger := TDbgLogger.Instance;
  FDbgLogger.InitEngine(leSmartInspect);
  FDbgLogger.Enable := true;

	FLogProcessor := TLogProcessor.Create;
	FFullName := TStringList.Create;
	FOptionsList := TStringList.Create;
	Caption := Caption + ' ' + VersionInformation;
	Application.Title := Caption;
	FDbgLogger.LogMessage('LogCompiler %s Started',[VersionInformation]);
	defaultOpt;
end;

procedure TfmMain.btnProcessClick(Sender: TObject);
var
  setMsgSetStr,path: string;
begin

	path := eSetDir.Text;
	if path = '' then
		path := '.';

	FLogProcessor.Reset;
	FLogProcessor.MsgSet := FMsgSet;
	mError.Clear;
	FLogProcessor.ProcessFiles(cbCleanOnly.Checked);
	mError.Lines := FLogProcessor.ParseErrors;
	mError.Lines.Add('Compilation Complete');
	setMsgSetStr := Format('%s\MsgSet_%d.mdt',[eSetDir.Text,FMsgSet]);
	FLogProcessor.GenerateMsgFile(setMsgSetStr);
end;

procedure TfmMain.eMsgSetChange(Sender: TObject);
begin
	if eMsgSet.Text <> '' then
		updateMsgSet();
end;

procedure TfmMain.eMsgSetExit(Sender: TObject);
begin
  if eMsgSet.Text = '' then begin
		eMsgSet.Text := '0';
		updateMsgSet;
	end;
end;

procedure TfmMain.btnAddFilesClick(Sender: TObject);
var
	I: Integer;
	str: string;
begin
	OpenDialog.InitialDir := ExtractFilePath(Application.ExeName);

	if OpenDialog.Execute then begin
		if CompareText(ExtractFileExt(OpenDialog.FileName),'.'+kProjectExtStr) = 0 then begin
			clear;
			loadProject(OpenDialog.FileName);
			eSetDir.Text := ExtractFilePath(OpenDialog.FileName);
			Caption := Application.Title + ' - ' + ExtractFileName(OpenDialog.FileName);
		end else
			for str in OpenDialog.Files do
				addFile(str);
	end;
end;

procedure TfmMain.lbFilesMouseMove(Sender: TObject; Shift: TShiftState; X: Integer;
        Y: Integer);
var
	lstIdx: Integer;
begin
	lstIdx := SendMessage(Handle, LB_ITEMFROMPOINT, 0, MAKELPARAM(X,Y));
	if (lstIdx >= 0) and (lstIdx < lbFiles.Items.Count) then
		lbFiles.Hint := FFullName.Strings[lstIdx]
	else
		lbFiles.Hint := '';
end;

procedure TfmMain.lbFilesKeyDown(Sender: TObject; var Key: WORD; Shift: TShiftState);
begin
	if Key = 46 then
		remFile(lbFiles.ItemIndex);
end;

procedure TfmMain.btnProjectClick(Sender: TObject);
var
	filename: string;
begin
	if SaveDialog.Execute then begin
		filename := SaveDialog.FileName;
		if Pos('.' + kProjectExtStr,filename) = 0 then
			filename := filename + '.' + kProjectExtStr;
		saveProject(filename);
		eSetDir.Text := ExtractFilePath(filename);
	end;
end;

procedure TfmMain.cbCRCClick(Sender: TObject);
begin
  TLogOptions.Instance.Crc := cbCRC.Checked;
end;

procedure TfmMain.cbDoubleParClick(Sender: TObject);
begin
	TLogOptions.Instance.DoublePar := cbDoublePar.Checked;
end;

procedure TfmMain.btnClearClick(Sender: TObject);
begin
	clear;
end;

procedure TfmMain.updateMsgSet;
begin
	try
		FMsgSet := StrToInt(eMsgSet.Text);
		if FMsgSet >= 1024 then
			raise EConvertError.Create('Out of range');

  except
  	on E: EConvertError do begin
      FDbgLogger.LogException('Wrong MsgSet');
      eMsgSet.Text := '0';
      raise;
    end;
  end;
end;

function TfmMain.readIntProperty(APropertyValue: string; ADefault: Integer): Integer;
begin
	Result := ADefault;
	if APropertyValue = '' then
		Exit(ADefault);

	try
		Result := StrToInt(APropertyValue);

	except
    on EConvertError do ;
	end
end;

procedure TfmMain.loadOptions(AList: TStrings);
var
  str: string;
begin
	FMsgSet := readIntProperty(AList.Values[kMsgSetProperty],0);
	eMsgSet.Text := IntToStr(FMsgSet);

	cbDoublePar.Checked := (readIntProperty(AList.Values[kDParProperty],1) > 0);
	cbCRC.Checked       := (readIntProperty(AList.Values[kUseCrcProperty],0) > 0);
end;

procedure TfmMain.loadProject(AName: string);
var
	i: Integer;
	str: string;
  LEnd: Boolean;
begin
	FFullName.LoadFromFile(AName);
	FOptionsList.Clear;

	// load options
  LEnd := false;
	repeat
		str := FFullName.Strings[0];
		if str <> '' then begin
			// non è una property!
			if Pos('=',str) = 0 then
				LEnd := true
			else if str <> '' then
				FOptionsList.Add(str);
		end;
    if not LEnd then
  		FFullName.Delete(0);
	until LEnd;

	loadOptions(FOptionsList);

  with FFullname do begin
    for i := 0 to Count - 1 do begin
      if FileExists(Strings[i]) then begin
        FLogProcessor.AddFile(Strings[i]);
        lbFiles.Items.Add(ExtractFileName(Strings[i]));
      end else begin
        Strings[i] := '*** DELETED';
        // TODO : do not delete
        // FPrjChanged := true;
      end;
    end;

    // rimuovo le entry marcate
    for i := Count-1 downto 0 do begin
      if Strings[i] = '*** DELETED' then
        Delete(i);
    end;
  end; { with }
end;

procedure TfmMain.saveProject(AName: string);
begin
	if FFullName.Count > 0 then
    with FOptionsList do begin
      Clear();
      Values[kMsgSetProperty] := IntToStr(FMsgSet);
      Values[kDParProperty] := IntToStr(IfThen(cbDoublePar.Checked,1,0));
      Values[kUseCrcProperty] := IntToStr(IfThen(cbCRC.Checked,1,0));

      // uso la linsta options come lista di salvataggio cosi fullname
      // rimane integra
      AddStrings(FFullName);
      SaveToFile(AName);
	  end;
end;

procedure TfmMain.addFile(AName: string);
begin
	FLogProcessor.AddFile(AName);
	FFullName.Add(AName);
	lbFiles.Items.Add(ExtractFileName(AName));
end;

procedure TfmMain.remFile(ANameIdx: Integer);
var
  LName: string;
begin
	if (ANameIdx >= 0) and (ANameIdx < lbFiles.Items.Count) then begin
		lbFiles.Items.Delete(ANameIdx);
		LName := FFullName.Strings[ANameIdx];
		FFullName.Delete(ANameIdx);
		FLogProcessor.RemFile(LName);
	end;
end;

procedure TfmMain.clear;
begin
	FLogProcessor.Clear;
	FFullName.Clear;
	lbFiles.Clear;
end;

procedure TfmMain.defaultOpt;
begin
	// l'evento sistema riflette il cambiamento all' interno dell'oggetto options
	cbDoublePar.Checked := true;
	cbCRC.Checked := false;
end;

end.
