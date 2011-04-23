//---------------------------------------------------------------------------

#include <stdio.h>
#include <vcl.h>
#pragma hdrstop
#include "sidebug.h"
#include "UCore.h"
#include "UFmMain.h"
#include "UOptions.h"
//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma resource "*.dfm"

#ifdef USE_SMARTINSPECT
#pragma link "SmartInspectDXE.lib"
#pragma link "dbrtl.lib"
#endif

#define kProjectExtStr	"psz"

//
#define kMsgSetProperty	"msgset"
#define kDParProperty	"doublepar"
#define kUseCrcProperty "usecrc"

TfmMain *fmMain;

AnsiString __fastcall TfmMain::readVersion() {
   DWORD VersionHandle;
   DWORD VersionSize;
   AnsiString oldVer, fileVersion,major,minor,build, release,aux;
   int pos, buildNewVal,buildOldVal,buildVal;
   void *pBuffer;
   unsigned int buflen,i,pt;
   VersionSize = GetFileVersionInfoSize(AnsiString(Application->ExeName).c_str(), &VersionHandle);

   if (VersionSize)
   {
	  pBuffer = (char *)malloc(VersionSize);
	  if (GetFileVersionInfo(AnsiString(Application->ExeName).c_str(),
			VersionHandle,VersionSize,pBuffer))
	  {
		 char *b;
		 WORD *country;
		 char buf[80];

		if (VerQueryValue(pBuffer,
			   TEXT("\\VarFileInfo\\Translation"),
			   (void** )&country, &buflen))
		{
			sprintf(buf,"\\StringFileInfo\\%04X%04X\\FileVersion",country[0],country[1]);

			if (VerQueryValue(pBuffer,buf,(void** )&b,&buflen)) {
				fileVersion = b;
				oldVer = fileVersion;
				pos = fileVersion.Pos(".");
				major = fileVersion.SubString(1,pos-1);
				aux = fileVersion.SubString(pos+1,999);
				pos = aux.Pos(".");
				minor = aux.SubString(1,pos-1);
				aux = aux.SubString(pos+1,999);
				pos = aux.Pos(".");
				// la terza cifra e la build
				release = aux.SubString(1,pos-1);
				// la quarta cifra e' la buildOld, vecchio stile
				build = aux.SubString(pos+1,999);
				try {
					// formato corto tipo micosoft
					fileVersion.printf("%d.%d.%d",
						major.ToInt(),
						minor.ToInt(),
						build.ToInt());
				}
				catch(EConvertError &e) {
					fileVersion = oldVer;
				}
			}
		}

	  }
	  free(pBuffer);
   }

   return fileVersion;
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::updateMsgSet() {
	try {
		FMsgSet = eMsgSet->Text.ToInt();
		if (FMsgSet >= 1024) {
			throw new EConvertError("Out of range");
		}

	} catch (EConvertError& e) {
		SI(SiMain->LogException("Wrong MsgSet"));
		eMsgSet->Text = "0";
		throw;
	}
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::configSmartInspect() {
#ifdef USE_SMARTINSPECT
	AnsiString sicName;
	int pos;
	pos = Application->ExeName.Pos(".exe");
	sicName = Application->ExeName.SubString(1,pos-1) + ".sic";
	if (!FileExists(sicName)) {
		Si->Enabled = true;
		Si->DefaultLevel = lvDebug;
		Si->Level = lvDebug;
	}
	else
		Si->LoadConfiguration(sicName);
#endif
}
//---------------------------------------------------------------------------

int __fastcall TfmMain::readIntProperty(AnsiString APropertyValue,int ADefault) {
	int retVal = ADefault;
	if (APropertyValue.IsEmpty())
		return ADefault;
		
	try {
		retVal = APropertyValue.ToInt();

	} catch (EConvertError &e) {
	}

	return retVal;
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::loadOptions(TStrings *AList) {
	AnsiString str;
	FMsgSet = readIntProperty(AList->Values[kMsgSetProperty],0);
	eMsgSet->Text = FMsgSet;

	cbDoublePar->Checked = (readIntProperty(AList->Values[kDParProperty],1) > 0);
	cbCRC->Checked = (readIntProperty(AList->Values[kUseCrcProperty],0) > 0);
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::loadProject(AnsiString AName) {
	int i;
	AnsiString str;
	FFullName->LoadFromFile(AName);
	FOptionsList->Clear();

	// load options
	while(1) {
		str = FFullName->Strings[0];
		if (!str.IsEmpty()) {
			// non è una property!
			if (str.Pos("=") == 0)
				break;

			if (!str.IsEmpty())
				FOptionsList->Add(str);
		}
		FFullName->Delete(0);
	}

	loadOptions(FOptionsList);

	for (i = 0; i < FFullName->Count; i++) {
		if (FileExists(FFullName->Strings[i])) {
			FLogProcessor->AddFile(FFullName->Strings[i]);
			lbFiles->Items->Add(ExtractFileName(FFullName->Strings[i]));
		}
		else {
			FFullName->Strings[i] = "*** DELETED";
			// TODO : do not delete 
			//FPrjChanged = true;
		}
	}

	// rimuovo le entry marcate
	for (i = FFullName->Count-1; i >= 0; i--) {
		if (AnsiString(FFullName->Strings[i]).AnsiCompare("*** DELETED") == 0)
			FFullName->Delete(i);
	}
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::saveProject(AnsiString AName) {
	if (FFullName->Count > 0) {
		FOptionsList->Clear();
		FOptionsList->Values[kMsgSetProperty] = FMsgSet;
		FOptionsList->Values[kDParProperty] = cbDoublePar->Checked ? 1 : 0;
		FOptionsList->Values[kUseCrcProperty] = cbCRC->Checked ? 1 : 0;

		// uso la linsta options come lista di salvataggio cosi fullname
		// rimane integra
		FOptionsList->AddStrings(FFullName);
		FOptionsList->SaveToFile(AName);
	}
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::addFile(AnsiString AName) {
	FLogProcessor->AddFile(AName);
	FFullName->Add(AName);
	lbFiles->Items->Add(ExtractFileName(AName));
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::remFile(int nameIdx) {
	AnsiString name;
	if (nameIdx >= 0 && nameIdx < lbFiles->Items->Count) {
		lbFiles->Items->Delete(nameIdx);
		name = FFullName->Strings[nameIdx];
		FFullName->Delete(nameIdx);
		FLogProcessor->RemFile(name);
	}
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::clear() {
	FLogProcessor->Clear();
	FFullName->Clear();
	lbFiles->Clear();
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::defaultOpt() {
	// l'evento sistema riflette il cambiamento all' interno dell'oggetto options
	cbDoublePar->Checked = true;
	cbCRC->Checked = false;
}
//---------------------------------------------------------------------------

__fastcall TfmMain::TfmMain(TComponent* Owner)
	: TForm(Owner)
{
	FLogProcessor = new TLogProcessor();
	FFullName = new TStringList();
	FOptionsList = new TStringList;
	configSmartInspect();
	Caption = Caption + " " + readVersion();
	Application->Title = Caption;
	SI(SiMain->LogMessage("LogCompiler %s Started",ARRAYOFCONST((readVersion().c_str()))));
	defaultOpt();
}
//---------------------------------------------------------------------------

__fastcall TfmMain::~TfmMain() {
	delete FLogProcessor;
	delete FFullName;
	delete FOptionsList;
	SI(SiMain->LogMessage("LogCompiler Closed"));
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::btnProcessClick(TObject *Sender)
{
	AnsiString setMsgSetStr,path;

	path = eSetDir->Text;
	if (path.IsEmpty())
		path = ".";

	FLogProcessor->Reset();
	FLogProcessor->MsgSet = FMsgSet;
	mError->Clear();
	FLogProcessor->ProcessFiles(cbCleanOnly->Checked);
	mError->Lines = FLogProcessor->ParseErrors;
	mError->Lines->Add("Compilation Complete");
	setMsgSetStr.printf("%s\\MsgSet_%d.mdt",eSetDir->Text.c_str(),FMsgSet);
	FLogProcessor->GenerateMsgFile(setMsgSetStr);
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::eMsgSetChange(TObject *Sender)
{
	if (!eMsgSet->Text.IsEmpty()) {
		updateMsgSet();
	}
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::eMsgSetExit(TObject *Sender)
{
	if (eMsgSet->Text.IsEmpty()) {
		eMsgSet->Text = "0";
		updateMsgSet();
	}
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::btnAddFilesClick(TObject *Sender)
{
	// DONE 1 : TfmMain::btnAddFilesClick(TObject *Sender)
	int i;
	AnsiString str;

	OpenDialog->InitialDir = ExtractFilePath(Application->ExeName);

	if (OpenDialog->Execute()) {
		if (AnsiString(ExtractFileExt(OpenDialog->FileName)).AnsiCompareIC("."kProjectExtStr)==0) {
			clear();
			loadProject(OpenDialog->FileName);
			eSetDir->Text = ExtractFilePath(OpenDialog->FileName);
			Caption = Application->Title + " - " + ExtractFileName(OpenDialog->FileName);
		}
		else {
			for (i = 0; i < OpenDialog->Files->Count; i++)
				addFile(OpenDialog->Files->Strings[i]);
		}
	}
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::btnClearClick(TObject *Sender)
{
	clear();
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::lbFilesMouseMove(TObject *Sender, TShiftState Shift,
	  int X, int Y)
{
	int lstIdx;
	lstIdx = SendMessage(Handle, LB_ITEMFROMPOINT, 0, MAKELPARAM(X,Y));
	if (lstIdx >= 0 && lstIdx < lbFiles->Items->Count)
		lbFiles->Hint = FFullName->Strings[lstIdx];
	else
		lbFiles->Hint = "";
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::lbFilesKeyDown(TObject *Sender, WORD &Key,
	  TShiftState Shift)
{
	if (Key == 46)
		remFile(lbFiles->ItemIndex);
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::btnProjectClick(TObject *Sender)
{
	AnsiString filename;
	if (SaveDialog->Execute()) {
		filename = SaveDialog->FileName;
		if (filename.Pos("."kProjectExtStr) == 0)
			filename += "."kProjectExtStr;
		saveProject(filename);
		eSetDir->Text = ExtractFilePath(filename);
	}
}
//---------------------------------------------------------------------------
void __fastcall TfmMain::cbCRCClick(TObject *Sender)
{
	TLogOptions::Instance()->Crc = cbCRC->Checked;
}
//---------------------------------------------------------------------------

void __fastcall TfmMain::cbDoubleParClick(TObject *Sender)
{
	TLogOptions::Instance()->DoublePar = cbDoublePar->Checked;
}
//---------------------------------------------------------------------------



