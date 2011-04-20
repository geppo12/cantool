//---------------------------------------------------------------------------

#ifndef UFmMainH
#define UFmMainH
//---------------------------------------------------------------------------
#include <Classes.hpp>
#include <Controls.hpp>
#include <StdCtrls.hpp>
#include <Forms.hpp>
#include <Dialogs.hpp>
//---------------------------------------------------------------------------
class TfmMain : public TForm
{
__published:	// IDE-managed Components
	TListBox *lbFiles;
	TButton *btnAddFiles;
	TButton *btnProcess;
	TLabel *Label1;
	TEdit *eMsgSet;
	TOpenDialog *OpenDialog;
	TMemo *mError;
	TCheckBox *cbCleanOnly;
	TButton *btnProject;
	TEdit *eSetDir;
	TSaveDialog *SaveDialog;
	TCheckBox *cbCRC;
	TCheckBox *cbDoublePar;
	TButton *btnClear;
	void __fastcall btnProcessClick(TObject *Sender);
	void __fastcall eMsgSetChange(TObject *Sender);
	void __fastcall btnAddFilesClick(TObject *Sender);
	void __fastcall lbFilesMouseMove(TObject *Sender, TShiftState Shift, int X,
          int Y);
	void __fastcall lbFilesKeyDown(TObject *Sender, WORD &Key, TShiftState Shift);
	void __fastcall btnProjectClick(TObject *Sender);
	void __fastcall cbCRCClick(TObject *Sender);
	void __fastcall cbDoubleParClick(TObject *Sender);
	void __fastcall btnClearClick(TObject *Sender);
	void __fastcall eMsgSetExit(TObject *Sender);
private:	// User declarations
	TLogProcessor *FLogProcessor;
	TStringList *FFullName;
	TStringList *FOptionsList;
	int FMsgSet;
	AnsiString __fastcall readVersion();
	void __fastcall updateMsgSet();
	void __fastcall configSmartInspect();
	int __fastcall readIntProperty(AnsiString APropertyValue, int ADefault);
	void __fastcall loadOptions(TStrings *AList);
	void __fastcall loadProject(AnsiString AName);
	void __fastcall saveProject(AnsiString AName);
	void __fastcall addFile(AnsiString AName);
	void __fastcall remFile(int nameIdx);
	void __fastcall clear();
	void __fastcall defaultOpt();
public:		// User declarations
	__fastcall TfmMain(TComponent* Owner);
	__fastcall ~TfmMain();
};
//---------------------------------------------------------------------------
extern PACKAGE TfmMain *fmMain;
//---------------------------------------------------------------------------
#endif
