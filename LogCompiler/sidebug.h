#ifndef _SIDEBUG
#define _SIDEBUG

#include <SiAuto.hpp>

#ifdef USE_SMARTINSPECT
#define SI(a)	a
#else
#define SI(a)	do {} while (0)
#endif

#endif