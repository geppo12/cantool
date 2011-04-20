//---------------------------------------------------------------------------


#pragma hdrstop

#include "UOptions.h"

//---------------------------------------------------------------------------

#pragma package(smart_init)

std::auto_ptr<TLogOptions> TLogOptions::FInstance;

__fastcall TLogOptions::TLogOptions() {
	Crc = false;
	DoublePar = false;
}

TLogOptions* __fastcall TLogOptions::Instance() {
	if (FInstance.get() == NULL)
		FInstance.reset(new TLogOptions());

	return FInstance.get();
}
