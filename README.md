Ninjeppo Can Tool
=================

Ninjeppo Can Tool use National Instruments NI-CAN Api to debug firmware in a network with a compressed form of Printf. 
LogCompiler exchange special crafted comments to macro that send all necessary informations.

LogCompiler and LogConsole are distribuited under GPL v2

To compile both software you need Delphi XE professional
To use LogConsole you need a National Instruments CAN card that support Ni-CAN Driver and ni-can driver installed.

Console version is tested with NI USB-8473

Why Delphi and not C++ ?

1. Delphi is beautifull
2. Create a NI-CAN driver in Delphi for people that need this. Warning: at moment I support only frame api
