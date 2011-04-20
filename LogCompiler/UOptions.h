//---------------------------------------------------------------------------

#ifndef UOptionsH
#define UOptionsH
//---------------------------------------------------------------------------

#include <memory>


class TLogOptions {
	private:
	static std::auto_ptr<TLogOptions> FInstance;

	__fastcall TLogOptions();
	public:
	bool Crc;
	bool DoublePar;
	static TLogOptions* __fastcall Instance();
};

#endif
