//---------------------------------------------------------------------------

#include <assert.h>
#include <classes.hpp>
#include <ctype.h>
#pragma hdrstop

#include "sidebug.h"
#include "UCore.h"
#include "UOptions.h"

//---------------------------------------------------------------------------

#pragma package(smart_init)

#define kSQZLOG_MARKER "//\@\@SQZLOG"
#define kSQZLOG_MATCH "__SQZLOG_SQUEEZE_IT"
#define kSQZLOG_MACRO "__SQZLOG_SQUEEZE_IT__"
#define kSQZLOG_MACRO_NO_PAR "__SQZLOG_SQUEEZE_IT_NP__"

#define kDefineStr "#define"
#define kUndefStr  "#undef"
#define kSETStr	   "SET %d"


AnsiString __fastcall TLogMsg::ToString() {
	AnsiString str;
	AnsiString parSpec = ParSpec;

//	if (parSpec.IsEmpty())
//		parSpec = "";

	if (TLogOptions::Instance()->Crc) {
		str.printf("MSG %d,\"%s\",\"%s\",%d",
			LogCode,
			ParSpec.c_str(),
			LogTitle.c_str(),
			FCrc
		);
	}
	else {
		str.printf("MSG %d,\"%s\",\"%s\"",
			LogCode,
			ParSpec.c_str(),
			LogTitle.c_str()
		);
	}
	return str;
}

// TLogMsgList ================================================================

 void __fastcall TLogMsgList::Clear() {
	int i;

	for (i = 0; i < Count; i++)
		delete Objects[i];

	TStringList::Clear();
}

// TLogEntryData ==============================================================

AnsiString __fastcall TLogEntryData::getParSpec() {
	if (FLogMsg != NULL)
		return FLogMsg->ParSpec;

	throw ELogNullMessage("Null message in TLogEntryData::getParSpec()");
}

__fastcall TLogEntryData::TLogEntryData() {
	FParameters = new TStringList;
	FLogMsg = NULL;
}
// ----------------------------------------------------------------------------

__fastcall TLogEntryData::~TLogEntryData() {
	delete FParameters;
}
// ----------------------------------------------------------------------------

void __fastcall TLogEntryData::Assign(TLogEntryData *AEntry) {
	FParameters->AddStrings(AEntry->FParameters);
	FLogMsg = AEntry->FLogMsg;
}

// TLogEntry ==================================================================

AnsiString __fastcall TLogEntry::getLogTitle() {
	if (FLogMsg != NULL)
		return FLogMsg->LogTitle;

	throw ELogNullMessage("Null message in TLogEntry::getLogTitle()");
}
// ----------------------------------------------------------------------------

int __fastcall TLogEntry::getLogCode() {
	if (FLogMsg != NULL)
		return FLogMsg->LogCode;

	throw ELogNullMessage("Null message in TLogEntry::getLogCode()");
}
// ----------------------------------------------------------------------------

int __fastcall TLogEntry::getCrc() {
	if (FLogMsg != NULL)
		return FLogMsg->Crc;

	throw ELogNullMessage("Null message in TLogEntry::getCrc()");
}
// ----------------------------------------------------------------------------

void __fastcall TLogEntry::Clear() {
	FParameters->Clear();
}
// ----------------------------------------------------------------------------

AnsiString __fastcall TLogEntry::ToMacro() {
	AnsiString str,parSpec;
	int i;

	parSpec = getParSpec();

	if (parSpec.IsEmpty()) {
		str = PreStr + kSQZLOG_MACRO_NO_PAR "(";
		str += AnsiString(getLogCode());
		str += ");";
	}
	else {

		if (TLogOptions::Instance()->DoublePar)
			str = PreStr + kSQZLOG_MACRO "((";
		else
			str = PreStr + kSQZLOG_MACRO "(";

		str += AnsiString(getLogCode())+ ",";

		if (TLogOptions::Instance()->Crc)
			str += AnsiString(getCrc())+",";

		str += AnsiString("\"") + parSpec + "\"";

		for (i = 0; i < FParameters->Count; i++) {
			str += ",";
			str += FParameters->Strings[i];
		}

		if (TLogOptions::Instance()->DoublePar)
			str += "));";
		else
			str += ");";
	}

	return str;
}

// TLogEntryBuilder ===========================================================

AnsiString __fastcall TLogEntryBuilder::getParSpec() {
	AnsiString str;
	TLogParSpecVector::iterator itor;

	for (itor = FParSpec.begin(); itor != FParSpec.end(); itor++)
		str += (char)tolower(*itor);

	return str;
}
//-----------------------------------------------------------------------------

int __fastcall TLogEntryBuilder::calcCrc(char *AStr) {
	int retVal = 0;

	while(*AStr != 0)
		retVal += *AStr++;

	return (retVal & 0xFF);
}
//-----------------------------------------------------------------------------

__fastcall TLogEntryBuilder::TLogEntryBuilder(TLogMsgList *AMsgList) {
	FMsgList = AMsgList;
	FCodeId = 0;
}
//-----------------------------------------------------------------------------

void __fastcall TLogEntryBuilder::Clear() {
	FParameters->Clear();
	FParSpec.clear();
	FLogMsg = NULL;
	FNewCode = false;
}
//-----------------------------------------------------------------------------

void __fastcall TLogEntryBuilder::Reset() {
	FCodeId = 0;
}
//-----------------------------------------------------------------------------

void __fastcall TLogEntryBuilder::SetTitle(AnsiString ATitle) {
	int idx, crc;
	idx = FMsgList->IndexOf(ATitle);

	if (idx < 0) {
		crc = calcCrc(ATitle.c_str());
		FLogMsg = new TLogMsg(FCodeId,getParSpec(),ATitle,crc);
		// comunque mi segno che ho generato un nuovo id;
		FNewCode = true;
		FMsgList->AddObject(ATitle,FLogMsg);
	}
	else
		FLogMsg = dynamic_cast<TLogMsg *>(FMsgList->Objects[idx]);

}
//-----------------------------------------------------------------------------

void __fastcall TLogEntryBuilder::AddParSpec(char type) {
	FParSpec.push_back(type);
}
//-----------------------------------------------------------------------------

void __fastcall TLogEntryBuilder::AddParameter(AnsiString APar) {
	FParameters->Add(APar);
}
//-----------------------------------------------------------------------------

TLogEntry* __fastcall TLogEntryBuilder::GetEntry() {
	TLogEntry *entry;
	if (FNewCode)
		FCodeId++;

	entry = new TLogEntry();
	entry->Assign(this);
	return entry;
}

// TLogEntryList ==============================================================

TLogEntry* __fastcall TLogEntryList::getLogEntry(int idx) {
	return FEntryVector[idx];
}
// ----------------------------------------------------------------------------

__fastcall TLogEntryList::~TLogEntryList() {
	Clear();
}
// ----------------------------------------------------------------------------

void __fastcall TLogEntryList::AddEntry(TLogEntry *AEntry) {
	FEntryVector.push_back(AEntry);
}
// ----------------------------------------------------------------------------

void __fastcall TLogEntryList::Clear() {
	TLogEntryVector::iterator itor;
	for (itor = FEntryVector.begin(); itor != FEntryVector.end(); itor++) {
		delete (*itor);
	}
	FEntryVector.clear();
}


// TLogFileProcessor ==========================================================

bool __fastcall TLogFileProcessor::isBlank(char ch) {
	// DONE 1 : void __fastcall TLogFileProcessor::isBlank(char ch) {
	return (ch == '\t' || ch == ' ' || ch == '\n' || ch == '\r');
}
// ----------------------------------------------------------------------------

void __fastcall TLogFileProcessor::parseError(char *AError) {
	AnsiString msgString;
	msgString.printf("ERROR: line %d, %s",FSrcLineIdx+1,AError);
	FParserErrorList->Add(msgString);
	FError = true;
}
// ----------------------------------------------------------------------------

void __fastcall TLogFileProcessor::addParameter() {
	SI(SiMain->LogDebug("PARSE_LINE: addPar(%s)",
		ARRAYOFCONST((FLineParserAux->Text.c_str()))));
	FEntryBuilder->AddParameter(FLineParserAux->Text);
	FLineParserAux->Clear();
}

TLogEntry* __fastcall TLogFileProcessor::parseLogLine(AnsiString& string) {
	// DONE 1 : TLogEntry* __fastcall TLogFileProcessor::parseLogLine(AnsiString& string) {
	char ch;
	int i,stato = 0;
	bool end = false, valid = false, addChar;
	TLogEntry *entry = NULL;

	FLineParserAux->Clear();
	FEntryBuilder->Clear();
	FError = false;

	SI(SiMain->LogDebug("PARSE_LINE: STR:%s",ARRAYOFCONST((string.c_str()))));


	for (i = 1; i <= string.Length() && !end; i++) {
		ch = string[i];
		SI(SiMain->LogDebug("PARSE_LINE: ST:%d, CH:%s",ARRAYOFCONST((stato,ch))));
		switch(stato) {
			case 0:
				if (ch == '(') {
					FParCount = 1;
					stato = 1;
				}
				else if (!isBlank(ch)) {
					parseError("Synatx Error");
					end = true;
				}
				break;

			case 1:
				if (ch == '\"')
					stato = 2;
				else if (!isBlank(ch)) {
					parseError("Synatx Error");
					end = true;
				}
				break;

			case 2:
				switch(ch) {
					case '\"':
						stato = 3;
						FEntryBuilder->SetTitle(FLineParserAux->Text);
						FLineParserAux->Clear();
						break;

					case '%':
						stato = 4;
						break;

					default:
						// uso TString list come StringBuffer di java xche è più veloce
						FLineParserAux->Add(ch);

				}
				break;

				// termine titolo e inserimento parametri
			case 3:
				switch(ch) {
					case ',':
						stato = 5;
						break;

					case '(':
						FParCount++;
						break;

					case ')':
						if (--FParCount ==  0) {
							// termine entry, valida
							valid = true;
							end = true;
						}
						break;

					default:
						if (!isBlank(ch)) {
							parseError("Synatx Error");
							delete entry;
							entry = NULL;
							end = true;
						}
						break;
				}
				break;

			// decodifica parametri
			case 4:
				addChar = true;
				switch(ch) {
					case 'b':
					case 'w':
					case 'd':
						FLineParserAux->Add("%d");
						break;

					case 'B':

						FLineParserAux->Add("0x%02X");
						break;

					case 'W':
						FLineParserAux->Add("0x%04X");
						break;

					case 'D':
						FLineParserAux->Add("0x%08X");
						break;

					case 's':
						FLineParserAux->Add("%s");
						break;

					default:
						parseError("Wrong parameter spec");
						addChar = false;
						end = true;
				}
				if (addChar) {
					SI(SiMain->LogDebug("PARSE_LINE: addParSpec(%s)",ARRAYOFCONST((ch))));
					FEntryBuilder->AddParSpec(ch);
					stato = 2;
				}
				break;

			// inserimento di un singolo parametro
			case 5:
				switch(ch) {
					case '(':
						FParCount++;
						FLineParserAux->Add(ch);
						break;

					case ',':
						addParameter();
						break;

					case ')':
						// se il conteggio delle parentesi e zero
						// aggiunge il parametro, atrimenti prosegue ed
						// aggiunge il carattere al parametro attuale
						if (--FParCount == 0) {
							valid = true;
							end   = true;
							addParameter();
						}
						// NO BREAK

					default:
						FLineParserAux->Add(ch);
						break;
				}
		}
	}

	if (!valid) {
		if (!FError)
			parseError("Unexpetted end of line");
		return NULL;
	}

	// e creo fisicamente l'entry
	return FEntryBuilder->GetEntry();

}
// ----------------------------------------------------------------------------

bool __fastcall TLogFileProcessor::canDeleteEntry(AnsiString str) {
	if (str.Pos(kDefineStr) > 0)
		return false;
	if (str.Pos(kUndefStr) > 0)
		return false;

	return true;
}
// ----------------------------------------------------------------------------

__fastcall TLogFileProcessor::TLogFileProcessor(TLogMsgList *AMsgList) {
	FEntryBuilder = new TLogEntryBuilder(AMsgList);
	FParserErrorList = new TStringList;
	FLineParserAux = new TStringList;
	// viene usata come TStringBuilder e quindi non ha senso un linebreak
	FLineParserAux->LineBreak = "";
}
// ----------------------------------------------------------------------------

__fastcall TLogFileProcessor::~TLogFileProcessor() {
	delete FParserErrorList;
	delete FLineParserAux;
	delete FEntryBuilder;
}
// ----------------------------------------------------------------------------

void __fastcall TLogFileProcessor::Clean(TStringList *AList) {
	int i;
	for (i = AList->Count-1; i >= 0; i--) {
		if (AList->Strings[i].Pos(kSQZLOG_MATCH) > 0) {
			// che si possa cancellare
			if (canDeleteEntry(AList->Strings[i]))
				AList->Delete(i);
		}
	}
}
// ----------------------------------------------------------------------------

void __fastcall TLogFileProcessor::Parse(TLogEntryList *ALogEntryList, TStringList *AStrList) {
	int idx,pos;
	AnsiString str,pre;
	TLogEntry *entry;

	FSrcLineIdx = 0;

	for (idx = 0; idx < AStrList->Count; idx++) {
		pos = AStrList->Strings[idx].Pos(kSQZLOG_MARKER);
		if (pos > 0) {
			pre = AStrList->Strings[idx].SubString(1,pos-1);
			str = AStrList->Strings[idx].SubString(pos+strlen(kSQZLOG_MARKER),999).Trim();
			FSrcLineIdx = idx;
			entry = parseLogLine(str);
			if (entry != NULL) {
				entry->Line = idx;
				entry->PreStr = pre;
				// la lista che possiede l'oggetto
				ALogEntryList->AddEntry(entry);
			}
		}
	}
}
// ----------------------------------------------------------------------------

void __fastcall TLogFileProcessor::Update(TLogEntryList *ALogEntryList, TStringList *AList) {
	// DONE 1 : void __fastcall TLogFileProcessor::Update(TStringList *AList)
	int idx, pos, lineError=0;
	TLogEntry *entry;

	if (FParserErrorList->Count != 0)
		return;

	for (idx = 0; idx < ALogEntryList->Count; idx++) {
		entry = ALogEntryList->LogEntries[idx];
		AList->Insert(entry->Line+lineError+1,entry->ToMacro());
		lineError++;
	}
}
// ----------------------------------------------------------------------------

void __fastcall TLogFileProcessor::Reset() {
	FParserErrorList->Clear();
	FEntryBuilder->Reset();
}

// TSrcFile ===================================================================

__fastcall TSrcFile::TSrcFile(AnsiString& AName) : FFileName(AName) {
	FFileLines = new TStringList;
	FEntryList = new TLogEntryList;
}
// ----------------------------------------------------------------------------

__fastcall TSrcFile::~TSrcFile() {
	delete FFileLines;
	delete FEntryList;
}
// ----------------------------------------------------------------------------

void __fastcall TSrcFile::Process(TLogFileProcessor *AProcessor) {
	AProcessor->Clean(FFileLines);
	AProcessor->Parse(FEntryList,FFileLines);
	AProcessor->Update(FEntryList,FFileLines);
}
// ----------------------------------------------------------------------------

void __fastcall TSrcFile::Clean(TLogFileProcessor *AProcessor) {
	AProcessor->Clean(FFileLines);
}
// ----------------------------------------------------------------------------

void __fastcall TSrcFile::Load() {
	FEntryList->Clear();
	if (!FFileName.IsEmpty())
		FFileLines->LoadFromFile(FFileName);
}
// ----------------------------------------------------------------------------

void __fastcall TSrcFile::Save() {
	if (!FFileName.IsEmpty())
		FFileLines->SaveToFile(FFileName);
}
// TLogProcessor ==============================================================

__fastcall TLogProcessor::TLogProcessor() {
	FSrcFileList = new TStringList;
	FMsgFileList = new TStringList;
	FMsgList = new TLogMsgList;
	FFileProcessor = new TLogFileProcessor(FMsgList);
}
// ----------------------------------------------------------------------------

__fastcall TLogProcessor::~TLogProcessor() {
	Clear();
	delete FFileProcessor;
	delete FMsgList;
	delete FMsgFileList;
	delete FSrcFileList;
}
// ----------------------------------------------------------------------------

void __fastcall TLogProcessor::AddFile(AnsiString AName) {
	TSrcFile *file = new TSrcFile(AName);
	FSrcFileList->AddObject(AName,file);
}
// ----------------------------------------------------------------------------

void __fastcall TLogProcessor::RemFile(AnsiString AName) {
	int idx = FSrcFileList->IndexOf(AName);
	delete FSrcFileList->Objects[idx];
	FSrcFileList->Delete(idx);
}
// ----------------------------------------------------------------------------

void __fastcall TLogProcessor::Reset() {
	FMsgList->Clear();
}
// ----------------------------------------------------------------------------

void __fastcall TLogProcessor::Clear() {
	int i;
	for (i = 0; i < FSrcFileList->Count; i++)
		delete FSrcFileList->Objects[i];
	FSrcFileList->Clear();
	Reset();
}
// ----------------------------------------------------------------------------

void __fastcall TLogProcessor::ProcessFiles(bool cleanOnly) {
	int i,j;
	AnsiString str;
	TSrcFile *file;
	TLogEntryList *list;
	FFileProcessor->Reset();
	for (i = 0; i < FSrcFileList->Count; i++) {
		file = dynamic_cast<TSrcFile *>(FSrcFileList->Objects[i]);
		if (file != NULL) {
			SI(SiMain->LogDebug("Process File %s",ARRAYOFCONST((file->Name.c_str()))));
			file->Load();
			if (cleanOnly)
				file->Clean(FFileProcessor);
			else
				file->Process(FFileProcessor);

			if (!FFileProcessor->ParseErrors->Count != 0)
				file->Save();
		}
	}
}
// ----------------------------------------------------------------------------

void __fastcall TLogProcessor::GenerateMsgFile(AnsiString AFileName) {
	// N.B. se == 1 c'e' solo il comando set
	AnsiString str;
	TLogMsg *entry;
	TObject *dbgObj;
	int  i;

	FMsgFileList->Clear();
	str.printf(kSETStr,MsgSet);
	FMsgFileList->Add(str);

	for (i = 0; i < FMsgList->Count; i++) {		entry = dynamic_cast<TLogMsg *>(FMsgList->Objects[i]);
		if (entry != NULL)
			FMsgFileList->Add(entry->ToString());
	}

	FMsgFileList->SaveToFile(AFileName);
}


