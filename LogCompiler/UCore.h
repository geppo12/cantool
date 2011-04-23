//---------------------------------------------------------------------------

#ifndef UCoreH
#define UCoreH
//---------------------------------------------------------------------------

#include <vector>

enum {
	lpByte=1,
	lpWord,
	lpDWord,
	lpString=8
};

class ELogError : public Exception {
	public:
	__fastcall ELogError(const AnsiString AStr) : Exception(AStr) {}
};
//-----------------------------------------------------------------------------

class ELogNullMessage : public ELogError {
	public:
	__fastcall ELogNullMessage(const AnsiString AStr) : ELogError(AStr) {}
};
//-----------------------------------------------------------------------------

typedef std::vector<char> TLogParSpecVector;

class TLogMsg : public TObject {
	private:
	AnsiString FLogTitle;
	AnsiString FParSpec;
	int FLogCode;
	int FCrc;

	public:
	__fastcall TLogMsg(int ACode, AnsiString AParSpec, AnsiString ATitle, int ACrc) :
		FLogCode(ACode), FParSpec(AParSpec), FLogTitle(ATitle), FCrc(ACrc) {}

	virtual String  __fastcall ToString();

	__property int LogCode = { read=FLogCode };
	__property AnsiString LogTitle = { read=FLogTitle };
	__property int Crc = { read=FCrc };
	__property AnsiString ParSpec = { read=FParSpec };
};
//-----------------------------------------------------------------------------

class TLogMsgList : public TStringList {
	public:
	virtual void __fastcall Clear();
};
//-----------------------------------------------------------------------------

class TLogEntryData {
	protected:
	TLogMsg *FLogMsg;	// e' un riferimento di un oggetto che sta nell TMsgList globale
	TStringList *FParameters;

	virtual AnsiString __fastcall  getParSpec();

	public:
	__fastcall TLogEntryData();
	virtual __fastcall ~TLogEntryData();
	virtual void __fastcall Clear() = 0;
	virtual void __fastcall Assign(TLogEntryData *AData);
};
//-----------------------------------------------------------------------------

class TLogEntry  : public TLogEntryData {
	private:
	AnsiString __fastcall getLogTitle();
	int __fastcall getLogCode();
	int __fastcall getCrc();

	public:
	int Line;
	AnsiString PreStr;
	virtual void __fastcall Clear();
	AnsiString __fastcall ToMacro();
};
//-----------------------------------------------------------------------------

class TLogEntryBuilder : public TLogEntryData {
	private:
	TLogParSpecVector FParSpec;
	TLogMsgList *FMsgList;
	int FCodeId;
	bool FNewCode;
	AnsiString __fastcall getParSpec();
	int __fastcall calcCrc(char *AStr);


	public:
	__fastcall TLogEntryBuilder(TLogMsgList *AMsgList);
	virtual void __fastcall Clear();
	void __fastcall Reset();
	void __fastcall SetTitle(AnsiString ATitle);
	void __fastcall AddParSpec(char AType);
	void __fastcall AddParameter(AnsiString APar);
	TLogEntry* __fastcall GetEntry();
};
//-----------------------------------------------------------------------------

typedef std::vector<TLogEntry *> TLogEntryVector;

class TLogEntryList {
	private:
	TLogEntryVector FEntryVector;
	TLogEntry* __fastcall getLogEntry(int AIdx);
	int __fastcall getCount() { return FEntryVector.size(); }
	public:
	__fastcall ~TLogEntryList();
	void __fastcall AddEntry(TLogEntry *AEntry);
	void __fastcall Clear();
	__property TLogEntry* LogEntries[int AIdx] = { read=getLogEntry };
	__property int Count = { read=getCount };
};
//-----------------------------------------------------------------------------

class TLogFileProcessor : public TObject {
	private:
	TLogEntryList *FEntryList;
	TLogEntryBuilder *FEntryBuilder;
	TStringList *FParserErrorList;
	TStringList *FLineParserAux;
	/*$$ SHORT:
		 Flag la gestione del singolo error */
	bool FError;
	int FSrcLineIdx;
	/*$$ SHORT:
         Contatore delle perentesi all' interno del commento */
	int FParCount;
	TLogMsg* __fastcall getLogMsg(AnsiString ATitle);
	bool __fastcall isBlank(char ch);
	void __fastcall parseError(char *AError);
	void __fastcall addParameter();
	TLogEntry* __fastcall parseLogLine(AnsiString& string);
	bool __fastcall canDeleteEntry(AnsiString AStr);
	TStrings* __fastcall getParseErrors() { return FParserErrorList; }

	public:
	__fastcall TLogFileProcessor(TLogMsgList *AMsgList);
	__fastcall ~TLogFileProcessor();
	/*$$
	  SHORT:
	  Pulisce dalle vecchie entry

	  PARAMETERS:
	  AList: lista che rappresenta il file
	*/
	void __fastcall Clean(TStringList *AList);
	/*$$
	  SHORT:
	  Fa il parsing del file sotto forma di stringlist

	  PARAMETERS:
	  ALogEntryList: puntatore alla lista delle entry da riempire
	  AList: lista che rappresenta il file

	*/

	void __fastcall Parse(TLogEntryList *ALogEntryList, TStringList *AList);
	/*$$
	  SHORT:
	  Aggiorna il file sulla delle entry relative alla lista presente

	  PARAMETERS:
	  ALogEntryList: lista utilizzata per aggiornare la string list
	  AList: lista da aggiornare
	*/
	void __fastcall Update(TLogEntryList *ALogEntryList,TStringList *AList);

	void __fastcall Reset();

	__property TStrings* ParseErrors = { read=getParseErrors };
};
//-----------------------------------------------------------------------------

class TSrcFile : public TObject {
	private:
	TStringList *FFileLines;
	AnsiString FFileName;
	TLogEntryList *FEntryList;

	public:
	__fastcall TSrcFile(AnsiString& AName);
	__fastcall ~TSrcFile();
	void __fastcall Process(TLogFileProcessor *AProcessor);
	void __fastcall Clean(TLogFileProcessor *AProcessor);
	void __fastcall Load();
	void __fastcall Save();
	__property AnsiString Name = { read=FFileName };
};
//-----------------------------------------------------------------------------

class TLogProcessor {
	private:
	TLogFileProcessor *FFileProcessor;
	TStringList *FSrcFileList;
	TStringList	*FMsgFileList;	// lista dei messaggi generati da salvare
	TLogMsgList *FMsgList;		// lista dei messaggi come TLogMsg

	TStrings* __fastcall getParseErrors() { return FFileProcessor->ParseErrors; }

	public:
	int MsgSet;
	__fastcall TLogProcessor();
	__fastcall ~TLogProcessor();
	void __fastcall AddFile(AnsiString AName);
	void __fastcall RemFile(AnsiString AName);
	void __fastcall Reset();
	void __fastcall Clear();
	void __fastcall ProcessFiles(bool cleanOnly);
	void __fastcall GenerateMsgFile(AnsiString AName);

	__property TStrings* ParseErrors = { read=getParseErrors };
};

#endif
