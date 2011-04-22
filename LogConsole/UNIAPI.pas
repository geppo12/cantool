{ nican api in Delphi              }
{ (c) 2011 Ing Giuseppe Monteleone }
{ Only FRAME API for now           }
unit UNIAPI;

{$I DVERSIONS.INC}

interface

{$IFNDEF NO_FRAME_API}
{*****************************************************************************}
{******************** N I - C A N   F R A M E    A P I ***********************}
{*****************************************************************************}

{***********************************************************************
                            D A T A   T Y P E S
***********************************************************************}

{$IFNDEF NC_NOINC_type}
type
  NCTYPE_INT8  = Shortint;
  NCTYPE_INT16 = Smallint;
  NCTYPE_INT32 = Integer;
  NCTYPE_UINT8 = Byte;
  NCTYPE_UINT16 = Word;
  NCTYPE_UINT32 = Cardinal;
  NCTYPE_REAL   = Real;
  NCTYPE_LREAL  = double;

{ This two-part declaration is required for compilers which do not
  provide support for native 64-bit integers.  }

  NCTYPE_UINT64 = packed record
   LowPart: NCTYPE_UINT32;
   HighPart: NCTYPE_UINT32;
  end;

{ Boolean value is encoded as an unsigned 8-bit integer in which
  bit 0 is used to indicate true or false, and the upper 7 bits
  are always zero.  }
  NCTYPE_BOOL = Byte;

{ ASCII string is encoded like all C language strings: as an array
  of characters with zero (the NULL character) used to indicate
  end-of-string.  This is known as an ASCIIZ string. }

{$IFDEF DELPHI2009_OR_HIGHER}
  NCTYPE_STRING = PAnsiChar;
{$ELSE}
  NCTYPE_STRING = PChar;
{$ENDIF}


  NCTYPE_STATUS   = NCTYPE_INT32;
  NCTYPE_OBJH     = NCTYPE_UINT32;
  NCTYPE_VERSION  = NCTYPE_UINT32;
  NCTYPE_DURATION = NCTYPE_UINT32;
  NCTYPE_ATTRID   = NCTYPE_UINT32;
  NCTYPE_OPCODE   = NCTYPE_UINT32;
  NCTYPE_PROTOCOL = NCTYPE_UINT32;
  NCTYPE_BAUD_RATE = NCTYPE_UINT32;
  NCTYPE_STATE    = NCTYPE_UINT32;

  { Pointer to a variable of any type }
  NCTYPE_ANY_P    = ^Pointer;

  { Pointers (used for function prototypes) }
  NCTYPE_INT8_P  = ^NCTYPE_INT8;
  NCTYPE_INT16_P = ^NCTYPE_INT16;
  NCTYPE_INT32_P = ^NCTYPE_INT32;
  NCTYPE_UINT8_P = ^NCTYPE_UINT8;
  NCTYPE_UINT16_P = ^NCTYPE_UINT16;
  NCTYPE_UINT32_P = ^NCTYPE_UINT32;
  NCTYPE_REAL_P   = ^NCTYPE_REAL;
  NCTYPE_LREAL_P  = ^NCTYPE_LREAL;
  NCTYPE_UINT64_P = ^NCTYPE_UINT64;
  NCTYPE_BOOL_P   = ^NCTYPE_BOOL;
  NCTYPE_STATUS_P = ^NCTYPE_STATUS;
  NCTYPE_OBJH_P   = ^NCTYPE_OBJH;
  NCTYPE_VERSION_P = ^NCTYPE_VERSION;
  NCTYPE_DURATION_P = ^NCTYPE_DURATION;
  NCTYPE_ATTRID_P  = ^NCTYPE_ATTRID;
  NCTYPE_OPCODE_P = ^NCTYPE_OPCODE;
  NCTYPE_PROTOCOL_P = ^NCTYPE_PROTOCOL;
  NCTYPE_BAUD_RATE_P = ^NCTYPE_BAUD_RATE;
  NCTYPE_STATE_P = ^NCTYPE_STATE;



{$IFNDEF NC_NOINC_createnotif}

{ This is the prototype for callback function passed to
  ncCreateNotification (cannot be used to declare your callback). }
{typedef  NCTYPE_STATE (_NCFUNC_ * NCTYPE_NOTIFY_CALLBACK) (}

  NCTYPE_NOTIFY_CALLBACK = function(
                              ObjHandle:    NCTYPE_OBJH;
                              CurrentState: NCTYPE_STATE;
                              Status:       NCTYPE_STATUS;
                              RefData:      NCTYPE_ANY_P): NCTYPE_STATE; stdcall;

{$ENDIF} { __NC_NOINC_createnotif }

  NCTYPE_COMM_TYPE = NCTYPE_UINT32;
  NCTYPE_RTSI_MODE = NCTYPE_UINT32;
  NCTYPE_RTSI_SIG_BEHAV = NCTYPE_UINT32;

{ This type can be typecasted to/from the Microsoft
  Win32 type FILETIME (see MSVC 4.x WINBASE.H).  When
  your host computer powers up, NC_ATTR_ABS_TIME is loaded
  with the system time of the host computer (value obtained
  using Win32 GetSystemTimeAsFileTime).  Thus, the timestamps
  obtained using ncRead can be converted to local time zone
  format using Win32 FileTimeToLocalFileTime, then can be
  converted to SYSTEMTIME (with year, month, day, and so on)
  using Win32 FileTimeToSystemTime.  }
  NCTYPE_ABS_TIME = NCTYPE_UINT64;

{ CAN arbitration ID (used for both standard and extended IDs).
  The bit NC_FL_CAN_ARBID_XTD (0x20000000) indicates extended ID.  }
  NCTYPE_CAN_ARBID = NCTYPE_UINT32;

{ Type for ncWrite of CAN Network Interface Object }
  NCTYPE_CAN_FRAME = packed record
   ArbitrationId:  NCTYPE_CAN_ARBID;
   IsRemote:       NCTYPE_BOOL;
   DataLength:     NCTYPE_UINT8;
   Data:           array [0..7] of NCTYPE_UINT8;
  end;

{ Type for ncRead of CAN Network Interface Object }
  NCTYPE_CAN_FRAME_TIMED = packed record
   Timestamp:      NCTYPE_ABS_TIME;
   ArbitrationId:  NCTYPE_CAN_ARBID;
   IsRemote:       NCTYPE_BOOL;
   DataLength:     NCTYPE_UINT8;
   Data:           array [0..7] of NCTYPE_UINT8;
  end;


{ Type for ncRead of CAN Network Interface Object (using FrameType instead of IsRemote).
  Type for ncWrite of CAN Network Interface Object when timed transmission is enabled. }

  NCTYPE_CAN_STRUCT = packed record
   Timestamp:      NCTYPE_ABS_TIME;
   ArbitrationId:  NCTYPE_CAN_ARBID;
   FrameType:      NCTYPE_UINT8;
   DataLength:     NCTYPE_UINT8;
   Data:           array [0..7] of NCTYPE_UINT8;
  end;

{ Type for ncWrite of CAN Object }
  NCTYPE_CAN_DATA = packed record
    Data:          array [0..7] of NCTYPE_UINT8;
  end;

{ Type for ncRead of CAN Object }
  NCTYPE_CAN_DATA_TIMED = packed record
   Timestamp: NCTYPE_ABS_TIME;
   Data: array [0..7] of NCTYPE_UINT8;
  end;

{ Pointers (used for function prototypes) }
  NCTYPE_COMM_TYPE_P  = ^NCTYPE_COMM_TYPE;
  NCTYPE_ABS_TIME_P   = ^NCTYPE_ABS_TIME;
  NCTYPE_CAN_ARBID_P  = ^NCTYPE_CAN_ARBID;
  NCTYPE_CAN_FRAME_P  = ^NCTYPE_CAN_FRAME;
  NCTYPE_CAN_FRAME_TIMED_P = ^NCTYPE_CAN_FRAME_TIMED;
  NCTYPE_CAN_STRUCT_P = ^NCTYPE_CAN_STRUCT;
  NCTYPE_CAN_DATA_P   = ^NCTYPE_CAN_DATA;
  NCTYPE_CAN_DATA_TIMED_P = ^NCTYPE_CAN_DATA_TIMED;
  NCTYPE_RTSI_MODE_P  = ^NCTYPE_RTSI_MODE;
  NCTYPE_RTSI_SIG_BEHAV_P = ^NCTYPE_RTSI_SIG_BEHAV;

{ Included for backward compatibility with older versions of NI-CAN }
  NCTYPE_BKD_TYPE = NCTYPE_UINT32;
  NCTYPE_BKD_WHEN = NCTYPE_UINT32;
  NCTYPE_BKD_TYPE_P = ^NCTYPE_BKD_TYPE;
  NCTYPE_BKD_WHEN_P = ^NCTYPE_BKD_WHEN;

{$ENDIF} { NC_NOINC_type }


{***********************************************************************
                              S T A T U S
***********************************************************************}

{$IFNDEF NC_NOINC_status}
const
   { NCTYPE_STATUS

   NI-CAN and NI-DNET use the standard NI status format.
   This status format does not use bit-fields, but rather simple
   codes in the lower byte, and a common base for the upper bits.
   This standard NI status format ensures that all NI-CAN errors are located
   in a specific range of codes.  Since this range does not overlap with
   errors reported from other NI products, NI-CAN is supported within
   environments such as LabVIEW and MeasurementStudio.

   If your application currently uses the NI-CAN legacy error codes,
   you must change to the standard NI error codes.  For instructions on updating
   your code, refer to KnowledgeBase article # 2BBD8JHR on www.ni.com.

   If you shipped an executable to your customers that uses the legacy
   NI-CAN error codes, and you must upgrade those customers to the
   newest version of NI-CAN, contact National Instruments Technical
   Support to obtain instructions for re-enabling the legacy status format. }

NICAN_WARNING_BASE         = $3FF62000;
NICAN_ERROR_BASE           = $BFF62000;

{ Success values (you can simply use zero as well)  }
CanSuccess                 = 0;
DnetSuccess                = 0;

{ Numbers 0x001 to 0x0FF are used for status codes defined prior to
  NI-CAN v1.5.  These codes can be mapped to/from the legacy status format.  }
CanErrFunctionTimeout      = NICAN_ERROR_BASE or $001;    // was NC_ERR_TIMEOUT
CanErrWatchdogTimeout      = NICAN_ERROR_BASE or $021;    // was NC_ERR_TIMEOUT
DnetErrConnectionTimeout   = NICAN_ERROR_BASE or $041;    // was NC_ERR_TIMEOUT
DnetWarnConnectionTimeout  = NICAN_WARNING_BASE or $041;
CanErrScheduleTimeout      = NICAN_ERROR_BASE or $0A1;    // was NC_ERR_TIMEOUT
CanErrDriver               = NICAN_ERROR_BASE or $002;    // was NC_ERR_DRIVER
CanWarnDriver              = NICAN_WARNING_BASE or $002;    // was NC_ERR_DRIVER
CanErrBadNameSyntax        = NICAN_ERROR_BASE or $003;    // was NC_ERR_BAD_NAME
CanErrBadIntfName          = NICAN_ERROR_BASE or $023;    // was NC_ERR_BAD_NAME
CanErrBadCanObjName        = NICAN_ERROR_BASE or $043;    // was NC_ERR_BAD_NAME
CanErrBadParam             = NICAN_ERROR_BASE or $004;    // was NC_ERR_BAD_PARAM
CanErrBadHandle            = NICAN_ERROR_BASE or $024;    // was NC_ERR_BAD_PARAM
CanErrBadAttributeValue    = NICAN_ERROR_BASE or $005;    // was NC_ERR_BAD_ATTR_VALUE
CanErrAlreadyOpen          = NICAN_ERROR_BASE or $006;    // was NC_ERR_ALREADY_OPEN
CanWarnAlreadyOpen         = NICAN_WARNING_BASE or $006;  // was NC_ERR_ALREADY_OPEN
DnetErrOpenIntfMode        = NICAN_ERROR_BASE or $026;    // was NC_ERR_ALREADY_OPEN
DnetErrOpenConnType        = NICAN_ERROR_BASE or $046;    // was NC_ERR_ALREADY_OPEN
CanErrNotStopped           = NICAN_ERROR_BASE or $007;    // was NC_ERR_NOT_STOPPED
CanErrOverflowWrite        = NICAN_ERROR_BASE or $008;    // was NC_ERR_OVERFLOW
CanErrOverflowCard         = NICAN_ERROR_BASE or $028;    // was NC_ERR_OVERFLOW
CanErrOverflowChip         = NICAN_ERROR_BASE or $048;    // was NC_ERR_OVERFLOW
CanErrOverflowRxQueue      = NICAN_ERROR_BASE or $068;    // was NC_ERR_OVERFLOW
CanWarnOldData             = NICAN_WARNING_BASE or $009;  // was NC_ERR_OLD_DATA
CanErrNotSupported         = NICAN_ERROR_BASE or $00A;    // was NC_ERR_NOT_SUPPORTED
CanWarnComm                = NICAN_WARNING_BASE or $00B;  // was NC_ERR_CAN_COMM
CanErrComm                 = NICAN_ERROR_BASE or $00B;    // was NC_ERR_CAN_COMM
CanWarnCommStuff           = NICAN_WARNING_BASE or $02B;  // was NC_ERR_CAN_COMM
CanErrCommStuff            = NICAN_ERROR_BASE or $02B;    // was NC_ERR_CAN_COMM
CanWarnCommFormat          = NICAN_WARNING_BASE or $04B;  // was NC_ERR_CAN_COMM
CanErrCommFormat           = NICAN_ERROR_BASE or $04B;    // was NC_ERR_CAN_COMM
CanWarnCommNoAck           = NICAN_WARNING_BASE or $06B;  // was NC_ERR_CAN_COMM
CanErrCommNoAck            = NICAN_ERROR_BASE or $06B;    // was NC_ERR_CAN_COMM
CanWarnCommTx1Rx0          = NICAN_WARNING_BASE or $08B;  // was NC_ERR_CAN_COMM
CanErrCommTx1Rx0           = NICAN_ERROR_BASE or $08B;    // was NC_ERR_CAN_COMM
CanWarnCommTx0Rx1          = NICAN_WARNING_BASE or $0AB;  // was NC_ERR_CAN_COMM
CanErrCommTx0Rx1           = NICAN_ERROR_BASE or $0AB;    // was NC_ERR_CAN_COMM
CanWarnCommBadCRC          = NICAN_WARNING_BASE or $0CB;  // was NC_ERR_CAN_COMM
CanErrCommBadCRC           = NICAN_ERROR_BASE or $0CB;    // was NC_ERR_CAN_COMM
CanWarnCommUnknown         = NICAN_WARNING_BASE or $0EB;  // was NC_ERR_CAN_COMM
CanErrCommUnknown          = NICAN_ERROR_BASE or $0EB;    // was NC_ERR_CAN_COMM
CanWarnTransceiver         = NICAN_WARNING_BASE or $00C;  // was NC_ERR_CAN_XCVR
CanWarnRsrcLimitQueues     = NICAN_WARNING_BASE or $02D;  // was NC_ERR_RSRC_LIMITS
CanErrRsrcLimitQueues      = NICAN_ERROR_BASE or $02D;    // was NC_ERR_RSRC_LIMITS
DnetErrRsrcLimitIO         = NICAN_ERROR_BASE or $04D;    // was NC_ERR_RSRC_LIMITS
DnetErrRsrcLimitWriteSrvc  = NICAN_ERROR_BASE or $06D;    // was NC_ERR_RSRC_LIMITS
DnetErrRsrcLimitReadSrvc   = NICAN_ERROR_BASE or $08D;    // was NC_ERR_RSRC_LIMITS
DnetErrRsrcLimitRespPending = NICAN_ERROR_BASE or $0AD;   // was NC_ERR_RSRC_LIMITS
DnetWarnRsrcLimitRespPending = NICAN_WARNING_BASE or $0AD;
CanErrRsrcLimitRtsi        = NICAN_ERROR_BASE or $0CD;    // was NC_ERR_RSRC_LIMITS
DnetErrNoReadAvail         = NICAN_ERROR_BASE or $00E;    // was NC_ERR_READ_NOT_AVAIL
DnetErrBadMacId            = NICAN_ERROR_BASE or $00F;    // was NC_ERR_BAD_NET_ID
DnetErrDevInitOther        = NICAN_ERROR_BASE or $010;    // was NC_ERR_DEVICE_INIT
DnetErrDevInitIoConn       = NICAN_ERROR_BASE or $030;    // was NC_ERR_DEVICE_INIT
DnetErrDevInitInputLen     = NICAN_ERROR_BASE or $050;    // was NC_ERR_DEVICE_INIT
DnetErrDevInitOutputLen    = NICAN_ERROR_BASE or $070;    // was NC_ERR_DEVICE_INIT
DnetErrDevInitEPR          = NICAN_ERROR_BASE or $090;    // was NC_ERR_DEVICE_INIT
DnetErrDevInitVendor       = NICAN_ERROR_BASE or $0B0;    // was NC_ERR_DEVICE_INIT
DnetErrDevInitDevType      = NICAN_ERROR_BASE or $0D0;    // was NC_ERR_DEVICE_INIT
DnetErrDevInitProdCode     = NICAN_ERROR_BASE or $0F0;    // was NC_ERR_DEVICE_INIT
DnetErrDeviceMissing       = NICAN_ERROR_BASE or $011;    // was NC_ERR_DEVICE_MISSING
DnetWarnDeviceMissing      = NICAN_WARNING_BASE or $011;  // was NC_ERR_DEVICE_MISSING
DnetErrFragmentation       = NICAN_ERROR_BASE or $012;    // was NC_ERR_FRAGMENTATION
DnetErrIntfNotOpen         = NICAN_ERROR_BASE or $033;    // was NC_ERR_NO_CONFIG
DnetErrErrorResponse       = NICAN_ERROR_BASE or $014;    // was NC_ERR_DNET_ERR_RESP
CanWarnNotificationPending = NICAN_WARNING_BASE or $015;    // was NC_ERR_NOTIF_PENDING
CanErrConfigOnly           = NICAN_ERROR_BASE or $017;    // was NC_ERR_CONFIG_ONLY
CanErrPowerOnSelfTest      = NICAN_ERROR_BASE or $018;    // PowerOn self test Failure


LinErrCommBit              = NICAN_ERROR_BASE or $1A0;    // Detected incorrect bit value
LinErrCommFraming          = NICAN_ERROR_BASE or $1A1;    // Detected incorrect stop bit of the frame
LinErrCommResponseTimout   = NICAN_ERROR_BASE or $1A2;    // Detected a timeout for a field of the LIN frame.
LinErrCommWakeup           = NICAN_ERROR_BASE or $1A3;    // Detected unexpected behavior when attempting to wake, or be awakened by, the LIN.
LinErrCommForm             = NICAN_ERROR_BASE or $1A4;    // Detected that the form of a LIN frame was incorrect.
LinErrCommBusNoPowered     = NICAN_ERROR_BASE or $1A5;    // Did not detect power on the LIN.

//The percent difference between the passed in baud rate and the actual baud rate was greater than or equal to 0.5%.  LIN 2.0 specifies a clock tolerance of less than 0.5% for a master and less than 1.5% for a slave.
LinWarnBaudRateOutOfTolerance = NICAN_WARNING_BASE or $1A6;

   // Numbers $100 to $1FF are used for the NI-CAN Frame API, the NI-DNET API, and LIN.
   // Numbers $1A0 to $1DF are used for the NI-CAN Frame API for LIN .
   // Numbers $200 to $2FF are used for the NI-CAN Channel API.
   // Numbers $300 to $3FF are reserved for future use.
CanErrMaxObjects           = NICAN_ERROR_BASE or $100;
CanErrMaxChipSlots         = NICAN_ERROR_BASE or $101;
CanErrBadDuration          = NICAN_ERROR_BASE or $102;
CanErrFirmwareNoResponse   = NICAN_ERROR_BASE or $103;
CanErrBadIdOrOpcode        = NICAN_ERROR_BASE or $104;
CanWarnBadSizeOrLength     = NICAN_WARNING_BASE or $105;
CanErrBadSizeOrLength      = NICAN_ERROR_BASE or $105;
CanErrNotifAlreadyInUse    = NICAN_ERROR_BASE or $107;
CanErrOneProtocolPerCard   = NICAN_ERROR_BASE or $108;
CanWarnPeriodsTooFast      = NICAN_WARNING_BASE or $109;
CanErrDllNotFound          = NICAN_ERROR_BASE or $10A;
CanErrFunctionNotFound     = NICAN_ERROR_BASE or $10B;
CanErrLangIntfRsrcUnavail  = NICAN_ERROR_BASE or $10C;
CanErrRequiresNewHwSeries  = NICAN_ERROR_BASE or $10D;
CanErrHardwareNotSupported = CanErrRequiresNewHwSeries;
CanErrSeriesOneOnly        = NICAN_ERROR_BASE or $10E;  //depreciated error code
CanErrSetAbsTime           = NICAN_ERROR_BASE or $10F;
CanErrBothApiSameIntf      = NICAN_ERROR_BASE or $110;
CanErrWaitOverlapsSameObj  = NICAN_ERROR_BASE or $111;
CanErrNotStarted           = NICAN_ERROR_BASE or $112;
CanErrConnectTwice         = NICAN_ERROR_BASE or $113;
CanErrConnectUnsupported   = NICAN_ERROR_BASE or $114;
CanErrStartTrigBeforeFunc  = NICAN_ERROR_BASE or $115;
CanErrStringSizeTooLarge   = NICAN_ERROR_BASE or $116;
CanErrQueueReqdForReadMult = NICAN_ERROR_BASE or $117;
CanErrHardwareInitFailed   = NICAN_ERROR_BASE or $118;
CanErrOldDataLost          = NICAN_ERROR_BASE or $119;
CanErrOverflowChannel      = NICAN_ERROR_BASE or $11A;
CanErrUnsupportedModeMix   = NICAN_ERROR_BASE or $11C;
CanErrNoNetIntfConfig      = NICAN_ERROR_BASE or $11D;
CanErrBadTransceiverMode   = NICAN_ERROR_BASE or $11E;
CanErrWrongTransceiverAttr = NICAN_ERROR_BASE or $11F;
CanErrRequiresXS           = NICAN_ERROR_BASE or $120;
CanErrDisconnected         = NICAN_ERROR_BASE or $121;
CanErrNoTxForListenOnly    = NICAN_ERROR_BASE or $122;
CanErrSetOnly              = NICAN_ERROR_BASE or $123;
CanErrBadBaudRate          = NICAN_ERROR_BASE or $124;
CanErrOverflowFrame        = NICAN_ERROR_BASE or $125;
CanWarnRTSITooFast         = NICAN_WARNING_BASE or $126;
CanErrNoTimebase           = NICAN_ERROR_BASE or $127;
CanErrTimerRunning         = NICAN_ERROR_BASE or $128;
DnetErrUnsupportedHardware = NICAN_ERROR_BASE or $129;
CanErrInvalidLogfile       = NICAN_ERROR_BASE or $12A;
CanErrMaxPeriodicObjects   = NICAN_ERROR_BASE or $130;
CanErrUnknownHardwareAttribute = NICAN_ERROR_BASE or $131;
CanErrDelayFrameNotSupported = NICAN_ERROR_BASE or $132;
CanErrVirtualBusTimingOnly = NICAN_ERROR_BASE or $133;

CanErrVirtualNotSupported  = NICAN_ERROR_BASE or $135;
CanErrWriteMultLimit       = NICAN_ERROR_BASE or $136;   // WriteMult does not allow write more that 512 frames at a time
CanErrObsoletedHardware    = NICAN_ERROR_BASE or $137;
CanErrVirtualBusTimingMismatch   = NICAN_ERROR_BASE or $138;
CanErrVirtualBusOnly       = NICAN_ERROR_BASE or $139;
CanErrConversionTimeRollback   = NICAN_ERROR_BASE or $13A;
CanErrInterFrameDelayExceeded = NICAN_ERROR_BASE or $140;
CanErrLogConflict             = NICAN_ERROR_BASE or $141;
CanErrBootLoaderUpdated = NICAN_ERROR_BASE or $142;// Error, bootloader not compatible with firmware.

{ Included for backward compatibility with older versions of NI-CAN }
CanWarnLowSpeedXcvr        = CanWarnTransceiver;   // applies to HS as well as LS
CanErrOverflowRead         = CanErrOverflowCard;   // overflow in card memory now lower level

{$ENDIF} // NC_NOINC_status


{$IFNDEF NC_NOINC_attrid}
const
{***********************************************************************
                          A T T R I B U T E   I D S
***********************************************************************}

   { Attributes of the NI driver (NCTYPE_ATTRID values)
      For every attribute ID, its full name, datatype,
      permissions, and applicable objects are listed in the comment. }

{ Current State, NCTYPE_STATE, Get, CAN Interface/Object }
NC_ATTR_STATE = $80000009;

{Status, NCTYPE_STATUS, Get, CAN Interface/Object }
NC_ATTR_STATUS = $8000000A;

{ Baud Rate, Set, CAN Interface
  Note that in addition to standard baud rates like 125000,
  this attribute also allows you to program non-standard
  or otherwise uncommon baud rates.  If bit 31 ($80000000)
  is set, the low 16 bits of this attribute are programmed
  directly into the bit timing registers of the CAN
  communications controller.  The low byte is programmed as
  BTR0 of the Intel 82527 chip (8MHz clock), and the high byte
  as BTR1, resulting in the following bit map:
     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
     sam (tseg2 - 1) (  tseg1 - 1   ) (sjw-1) (     presc - 1     )
  For example, baud rate $80001C03 programs the CAN communications
  controller for 125000 baud (same baud rate 125000 decimal).
  For more information, refer to the reference manual for
  any CAN communications controller chip.  }
NC_ATTR_BAUD_RATE = $80000007;

{ Start On Open, NCTYPE_BOOL, Set, CAN Interface }
NC_ATTR_START_ON_OPEN      = $80000006;
{ Absolute Time, NCTYPE_ABS_TIME, Get, CAN Interface }
NC_ATTR_ABS_TIME           = $80000008;
{ Period, NCTYPE_DURATION, Set, CAN Object }
NC_ATTR_PERIOD             = $8000000F;
{ Timestamping, NCTYPE_BOOL, Set, CAN Interface }
NC_ATTR_TIMESTAMPING       = $80000010;
{ Read Pending, NCTYPE_UINT32, Get, CAN Interface/Object }
NC_ATTR_READ_PENDING       = $80000011;
{ Write Pending, NCTYPE_UINT32, Get, CAN Interface/Object }
NC_ATTR_WRITE_PENDING      = $80000012;
{ Read Queue Length, NCTYPE_UINT32, Set, CAN Interface/Object }
NC_ATTR_READ_Q_LEN         = $80000013;
{ Write Queue Length, NCTYPE_UINT32, Set, CAN Interface/Object }
NC_ATTR_WRITE_Q_LEN        = $80000014;
{ Receive Changes Only, NCTYPE_BOOL, Set, CAN Object }
NC_ATTR_RX_CHANGES_ONLY    = $80000015;
{ Communication Type, NCTYPE_COMM_TYPE, Set, CAN Object }
NC_ATTR_COMM_TYPE          = $80000016;
{ RTSI Mode, NCTYPE_RTSI_MODE, Set, CAN Interface/Object }
NC_ATTR_RTSI_MODE          = $80000017;
{ RTSI Signal, NCTYPE_UINT8, Set, CAN Interface/Object }
NC_ATTR_RTSI_SIGNAL        = $80000018;
{ RTSI Signal Behavior, NCTYPE_RTSI_SIG_BEHAV, Set, CAN Interface/Object }
NC_ATTR_RTSI_SIG_BEHAV     = $80000019;
{ RTSI Frame for CAN Object, NCTYPE_UINT32, Get/Set, CAN Object }
NC_ATTR_RTSI_FRAME         = $80000020;
{ RTSI Skip Count, NCTYPE_UINT32, Set, CAN Interface/Object }
NC_ATTR_RTSI_SKIP          = $80000021;
{ Standard Comparator, NCTYPE_CAN_ARBID, Set, CAN Interface }
NC_ATTR_COMP_STD           = $80010001;
{ Standard Mask (11 bits), NCTYPE_UINT32, Set, CAN Interface }
NC_ATTR_MASK_STD           = $80010002;
{ Extended Comparator (29 bits), NCTYPE_CAN_ARBID, Set, CAN Interface }
NC_ATTR_COMP_XTD           = $80010003;
{ Extended Mask (29 bits), NCTYPE_UINT32, Set, CAN Interface }
NC_ATTR_MASK_XTD           = $80010004;
{ Transmit By Response, NCTYPE_BOOL, Set, CAN Object }
NC_ATTR_TX_RESPONSE        = $80010006;
{ Data Frame Length, NCTYPE_UINT32, Set, CAN Object }
NC_ATTR_DATA_LEN           = $80010007;
{ Log Comm Errors, NCTYPE_BOOL, Get/Set, CAN Interface (Low-speed boards only) }
NC_ATTR_LOG_COMM_ERRS      = $8001000A;
{ Notify Multiple Length, NCTYPE_UINT32, Get/Set, CAN Interface/Object }
NC_ATTR_NOTIFY_MULT_LEN    = $8001000B;
{ Receive Queue Length, NCTYPE_UINT32, Set, CAN Interface }
NC_ATTR_RX_Q_LEN           = $8001000C;
{ Is bus timing enabled on virtual hardware,
  NC_FALSE: Used in case of frame-channel conversion
  NC_TRUE: NI-CAN will simluate the bus timing on TX, set timestamp
  of the frame when it is received,default behavior,NCTYPE_UINT32,Get/Set,
  CAN Interface   }
NC_ATTR_VIRTUAL_BUS_TIMING  = $A0000031;
{ Transmit mode,NCTYPE_UINT32,Get/Set,
  0 (immediate) [default],
  1 (timestamped) CAN Interface }
NC_ATTR_TRANSMIT_MODE      = $80020029;
{ Log start trigger in the read queue,NCTYPE_UINT32,Get/Set, CAN Interface}
NC_ATTR_LOG_START_TRIGGER     = $80020031;
{ Timestamp format in absolute or relative mode, NCTYPE_UINT32, Get/Set, CAN Interface .}
NC_ATTR_TIMESTAMP_FORMAT   = $80020032;
{ Rate of the incoming clock pulses.Rate can either be 10(M Series DAQ)
  or 20(E series DAQ) Mhz,NCTYPE_UINT32,Get/Set, CAN Interface }
NC_ATTR_MASTER_TIMEBASE_RATE  = $80020033;
{ Number of frames that can be written without overflow,NCTYPE_UINT32, Get,CAN Interface}
NC_ATTR_WRITE_ENTRIES_FREE        = $80020034;
{ Timeline recovery,NCTYPE_UINT32,Get/Set,
  Valid only in timestamped transmit mode (NC_ATTR_TRANSMIT_MODE = 1)
  0 (false) [default],
  1 (true)CAN Interface .}
NC_ATTR_TIMELINE_RECOVERY  = $80020035;
{ Log Bus Errors, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  0 (false) [default],
  1 (true)}
NC_ATTR_LOG_BUS_ERROR  = $80020037;
{ Log Transceiver Faults, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  Log NERR into NI read queue
  0 (false) [default],
  1 (true)}
NC_ATTR_LOG_TRANSCEIVER_FAULT  = $80020038;
{ Termination Select, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  CAN HS - Not Selectable
  CAN LS - 0 (1k ohm) [default], 1 (5k ohm)
  LIN - 0 (disabled) [default], 1 (enabled) }
NC_ATTR_TERMINATION  = $80020041;
{** LIN Attributes *}
{ LIN - Sleep, NCTYPE_UINT32, Get/Set,0 (False) [default], 1 (true) }
NC_ATTR_LIN_SLEEP  = $80020042;
{ LIN - Check Sum Type, NCTYPE_UINT32, Get/Set, 0 (classic) [default], 1 (enhanced) }
NC_ATTR_LIN_CHECKSUM_TYPE  = $80020043;
{ LIN - Response Timeout, NCTYPE_UINT32, Get/Set, 0 [default],
  1 - 65535 (in 50 us increments for LIN specific frame response timing) }
NC_ATTR_LIN_RESPONSE_TIMEOUT  = $80020044;
{ LIN - Enable DLC Check, NCTYPE_UINT32, Get/Set, 0 (false) [default], 1 (true) }
NC_ATTR_LIN_ENABLE_DLC_CHECK  = $80020045;
{ LIN - Log Wakeup, NCTYPE_UINT32, Get/Set, 0 (false) [default], 1 (true) }
NC_ATTR_LIN_LOG_WAKEUP  = $80020046;

{ Attributes specific to Series 2 hardware (not supported on Series 1). }

{ Enable Listen Only on SJA1000, NCTYPE_UINT32, Get/Set 0 (false) [default], 1 (enable)}
NC_ATTR_LISTEN_ONLY        = $80010010;
{ Returns Receive Error Counter from SJA1000, NCTYPE_UINT32, Get, CAN Interface/Object }
NC_ATTR_RX_ERROR_COUNTER   = $80010011;
{ Returns Send Error Counter from SJA1000, NCTYPE_UINT32, Get, CAN Interface/Object }
NC_ATTR_TX_ERROR_COUNTER   = $80010012;
{ Series 2 Comparator, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  11 bits or 29 bits depending on NC_ATTR_SERIES2_FILTER_MODE
  0 [default] }
NC_ATTR_SERIES2_COMP       = $80010013;
{ Series 2 Mask, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  11 bits or 29 bits depending on NC_ATTR_SERIES2_FILTER_MODE
  $FFFFFFFF [default] }
NC_ATTR_SERIES2_MASK       = $80010014;
{ Series 2 Filter Mode, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  NC_FILTER_SINGLE_STANDARD [default], NC_FILTER_SINGLE_EXTENDED,
  NC_FILTER_DUAL_EXTENDED, NC_FILTER_SINGLE_STANDARD}
NC_ATTR_SERIES2_FILTER_MODE = $80010015;
{ Self Reception, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  Echo transmitted frames in read queue
  0 (false) [default], 1 (true) }
NC_ATTR_SELF_RECEPTION     = $80010016;
{ Single Shot Transmit, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  Single Shot = No retry on error transmissions
  0 (false) [default]. 1 (true) }
NC_ATTR_SINGLE_SHOT_TX     = $80010017;
NC_ATTR_BEHAV_FINAL_OUT    = $80010018;
{ Transceiver Mode, NCTYPE_UINT32, Get/Set, CAN Interface/Object
  NC_TRANSCEIVER_MODE_NORMAL [default], NC_TRANSCEIVER_MODE_SLEEP,
  NC_TRANSCEIVER_MODE_SW_HIGHSPEED, NC_TRANSCEIVER_MODE_SW_WAKEUP}
NC_ATTR_TRANSCEIVER_MODE   = $80010019;
{ Transceiver External Out, NCTYPE_UINT32, Bitmask, Get/Set, CAN Interface
  on XS cards and external transceivers, it sets MODE0 and MODE1 pins on CAN port,
  and sleep of CAN controller chip
  NC_TRANSCEIVER_OUT_MODE0 and NC_TRANSCEIVER_OUT_MODE1 [default]
  NC_TRANSCEIVER_OUT_MODE0,
  NC_TRANSCEIVER_OUT_MODE1,
  NC_TRANSCEIVER_OUT_SLEEP}
NC_ATTR_TRANSCEIVER_EXTERNAL_OUT = $8001001A;
{ Transceiver External In, NCTYPE_UINT32, Get, CAN Interface
  on XS cards, reads STATUS pin on CAN port}
NC_ATTR_TRANSCEIVER_EXTERNAL_IN = $8001001B;
{ Error Code Capture and Arbitration Lost Capture, NCTYPE_UINT32, Get, CAN Interface/Object
  Returns Error Code Capture and Arbitration Lost Capture registers }
NC_ATTR_SERIES2_ERR_ARB_CAPTURE = $8001001C;
{ Transceiver Type, NCTYPE_UINT32, Get/Set, CAN Interface
  NC_TRANSCEIVER_TYPE_DISC (disconnect), NC_TRANSCEIVER_TYPE_EXT (external),
  NC_TRANSCEIVER_TYPE_HS (high speed), NC_TRANSCEIVER_TYPE_LS (low speed),
  NC_TRANSCEIVER_TYPE_SW (single wire)}
NC_ATTR_TRANSCEIVER_TYPE   = $80020007;

{ Informational attributes (hardware and version info).  Get, CAN Interface only
  These attribute IDs can be used with ncGetHardwareInfo and ncGetAttribute.  }
NC_ATTR_NUM_CARDS          = $80020002;     // Number of Cards present in system.
NC_ATTR_HW_SERIAL_NUM      = $80020003;     // Serial Number of card
NC_ATTR_HW_FORMFACTOR      = $80020004;     // Formfactor of card - NC_HW_FORMFACTOR_???
NC_ATTR_HW_SERIES          = $80020005;     // Series of Card - NC_HW_SERIES_???
NC_ATTR_NUM_PORTS          = $80020006;     // Number of Ports present on card
NC_ATTR_HW_TRANSCEIVER     = NC_ATTR_TRANSCEIVER_TYPE; // NC_HW_TRANSCEIVER_???
NC_ATTR_INTERFACE_NUM      = $80020008;     // 0 for CAN0, 1 for CAN1, etc...
NC_ATTR_VERSION_MAJOR      = $80020009;     // U32 major version (X in X.Y.Z)
NC_ATTR_VERSION_MINOR      = $8002000A;     // U32 minor version (Y in X.Y.Z)
NC_ATTR_VERSION_UPDATE     = $8002000B;     // U32 minor version (Z in X.Y.Z)
NC_ATTR_VERSION_PHASE      = $8002000C;     // U32 phase (1=alpha, 2=beta, 3=release)
NC_ATTR_VERSION_BUILD      = $8002000D;     // U32 build (primarily useful for beta)
NC_ATTR_VERSION_COMMENT    = $8002000E;     // String comment on version (max 80 chars)

{ Included for backward compatibility with older versions of NI-CAN }
{ NCTYPE_ATTRID values, CAN Interface/Object }
NC_ATTR_PROTOCOL           = $80000001;
NC_ATTR_PROTOCOL_VERSION   = $80000002;
NC_ATTR_SOFTWARE_VERSION   = $80000003;
NC_ATTR_BKD_READ_SIZE      = $8000000B;
NC_ATTR_BKD_WRITE_SIZE     = $8000000C;
NC_ATTR_BKD_TYPE           = $8000000D;
NC_ATTR_BKD_WHEN_USED      = $8000000E;
NC_ATTR_BKD_PERIOD         = $8000000F;
NC_ATTR_BKD_CHANGES_ONLY   = $80000015;
NC_ATTR_SERIAL_NUMBER      = $800000A0;
NC_ATTR_CAN_BIT_TIMINGS    = $80010005;
NC_ATTR_BKD_CAN_RESPONSE   = $80010006;
NC_ATTR_CAN_DATA_LENGTH    = $80010007;
NC_ATTR_CAN_COMP_STD       = $80010001;
NC_ATTR_CAN_MASK_STD       = $80010002;
NC_ATTR_CAN_COMP_XTD       = $80010003;
NC_ATTR_CAN_MASK_XTD       = $80010004;
NC_ATTR_CAN_TX_RESPONSE    = $80010006;
NC_ATTR_NOTIFY_MULT_SIZE   = $8001000B;
NC_ATTR_RESET_ON_START     = $80010008;
NC_ATTR_NET_SYNC_COUNT     = $8001000D;
NC_ATTR_IS_NET_SYNC        = $8001000E;
NC_ATTR_START_TRIG_BEHAVIOR = $80010023;
{ NCTYPE_BKD_TYPE values }
NC_BKD_TYPE_PEER2PEER      = $00000001;
NC_BKD_TYPE_REQUEST        = $00000002;
NC_BKD_TYPE_RESPONSE       = $00000003;
{ NCTYPE_BKD_WHEN values }
NC_BKD_WHEN_PERIODIC       = $00000001;
NC_BKD_WHEN_UNSOLICITED    = $00000002;
{ Special values for background read/write data
  sizes (NC_ATTR_BKD_READ_SIZE and NC_ATTR_BKD_WRITE_SIZE). }
NC_BKD_CAN_ZERO_SIZE       = $00008000;

{$ENDIF} // NC_NOINC_attrid

{**********************************************************************
                    O T H E R   C O N S T A N T S
**********************************************************************}

{$IFNDEF NC_NOINC_other}
{ NCTYPE_BOOL (true/false values) }
const
NC_TRUE    = 1;
NC_FALSE   = 0;

{ NCTYPE_DURATION (values in one millisecond ticks) }
NC_DURATION_NONE           = 0;              { zero duration }
NC_DURATION_INFINITE       = $FFFFFFFF;      { infinite duration }
NC_DURATION_1MS            = 1;              { one millisecond }
NC_DURATION_10MS           = 10;
NC_DURATION_100MS          = 100;
NC_DURATION_1SEC           = 1000;           { one second }
NC_DURATION_10SEC          = 10000;
NC_DURATION_100SEC         = 100000;
NC_DURATION_1MIN           = 60000;          { one minute }

{ NCTYPE_PROTOCOL (values for supported protocols) }
NC_PROTOCOL_CAN            = 1;              { Controller Area Net }
NC_PROTOCOL_DNET           = 2;              { DeviceNet }
NC_PROTOCOL_LIN            = 3;              { LIN }

{ NCTYPE_STATE (bit masks for states).
  Refer to other NC_ST values below for backward compatibility. }

{ Any object }
NC_ST_READ_AVAIL           = $00000001;
      { Any object }
NC_ST_WRITE_SUCCESS        = $00000002;

{$IFNDEF NC_NOINC_other}
   { Expl Msg object only }
   NC_ST_ESTABLISHED       = $00000008;
{$ENDIF}
   { Included for backward compatibility with older versions of NI-CAN }
      { NCTYPE_STATE (bit masks for states): Prior to NI-CAN 2.0,
      the Stopped state emabled detection of the Bus Off condition,
      which stopped communication independent of NI-CAN functions such as ncAction(Stop).
      Since the Bus Off condition is an error, and errors are detected automatically
      in v2.0 and later, this state is now obsolete. For compatibility, it may be
      returned as the DetectedState of ncWaitForState, but this bit should be
      ignored by new NI-CAN applications. }
  NC_ST_STOPPED           = $00000004;
      { NCTYPE_STATE (bit masks for states): Prior to NI-CAN 2.0,
      the Error state emabled detection of background errors (such as the Bus Off condition).
      For v2.0 and later, the ncWaitForState function returns automatically when any
      error occurs, so this state is now obsolete. For compatibility, it may be
      returned as the DetectedState of ncWaitForState, but this bit should be
      ignored by new NI-CAN applications. }
  NC_ST_ERROR             = $00000010;
      { NCTYPE_STATE (bit masks for states): Prior to NI-CAN 2.0,
      the Warning state emabled detection of background warnings (such as Error Passive).
      For v2.0 and later, the ncWaitForState function will not abort when a warning occurs,
      but it will return the warning, so this state is now obsolete. For compatibility,
      it may be returned as the DetectedState of ncWaitForState, but this bit should be
      ignored by new NI-CAN applications. }
  NC_ST_WARNING           = $00000020;


      { Any object }
  NC_ST_READ_MULT         = $00000008;
      { State to detect when a CAN port has been woken up remotely.}
  NC_ST_REMOTE_WAKEUP     = $00000040;

       { NI only }
  NC_ST_WRITE_MULT        = $00000080;

   { NCTYPE_OPCODE values }
      { Interface object }
  NC_OP_START             = $80000001;
      { Interface object }
  NC_OP_STOP              = $80000002;
      { Interface object }
  NC_OP_RESET             = $80000003;

{$IFNDEF NC_NOINC_other}
      { Interface object only }
  NC_OP_ACTIVE            = $80000004;
      { Interface object only }
  NC_OP_IDLE              = $80000005;
{$ENDIF}
      { Interface object, Param is used }
  NC_OP_RTSI_OUT          = $80000004;

   { NCTYPE_BAUD_RATE (values for baud rates) }
  NC_BAUD_10K              = 10000;
  NC_BAUD_100K             = 100000;
  NC_BAUD_125K             = 125000;
  NC_BAUD_250K             = 250000;
  NC_BAUD_500K             = 500000;
  NC_BAUD_1000K            = 1000000;

   { NCTYPE_COMM_TYPE values }
  NC_CAN_COMM_RX_UNSOL     = $00000000;  { rx unsolicited data }
  NC_CAN_COMM_TX_BY_CALL   = $00000001;  { tx data by call }
  NC_CAN_COMM_RX_PERIODIC  = $00000002;  { rx periodic using remote }
  NC_CAN_COMM_TX_PERIODIC  = $00000003;  { tx data periodically }
  NC_CAN_COMM_RX_BY_CALL   = $00000004;  { rx by call using remote }
  NC_CAN_COMM_TX_RESP_ONLY = $00000005; { tx by response only }
  NC_CAN_COMM_TX_WAVEFORM  = $00000006; { tx periodic "waveform" }

   { NCTYPE_RTSI_MODE values }
  NC_RTSI_NONE             = 0;         { no RTSI usage }
  NC_RTSI_TX_ON_IN         = 1;         { transmit on input pulse }
  NC_RTSI_TIME_ON_IN       = 2;         { timestamp on in pulse }
  NC_RTSI_OUT_ON_RX        = 3;         { output on receive }
  NC_RTSI_OUT_ON_TX        = 4;         { output on transmit cmpl }
  NC_RTSI_OUT_ACTION_ONLY  = 5;         { output by ncAction only }

   { NCTYPE_RTSI_SIG_BEHAV values }
  NC_RTSISIG_PULSE         = 0;           { pulsed input / output }
  NC_RTSISIG_TOGGLE        = 1;           { toggled output }

   { NC_ATTR_START_TRIG_BEHAVIOUR values }
  NC_START_TRIG_NONE       = 0;
  NC_RESET_TIMESTAMP_ON_START  = 1;
  NC_LOG_START_TRIG        = 2;

{ NCTYPE_CAN_ARBID (bit masks)
  When frame type is data (NC_FRMTYPE_DATA) or remote (NC_FRMTYPE_REMOTE),
  this bit in ArbitrationId is interpreted as follows:
  If this bit is clear, the ArbitrationId is standard (11-bit).
  If this bit is set, the ArbitrationId is extended (29-bit).  }
  NC_FL_CAN_ARBID_XTD      = $20000000;

{ NCTYPE_CAN_ARBID (special values)
  Special value used to disable comparators. }
  NC_CAN_ARBID_NONE        = $CFFFFFFF;

{ Values for the FrameType (IsRemote) field of CAN frames.  }
  NC_FRMTYPE_DATA          = 0;
  NC_FRMTYPE_REMOTE        = $01;
{ NI only }
  NC_FRMTYPE_COMM_ERR      = $02;     // Communication warning/error (NC_ATTR_LOG_COMM_ERRS)
  NC_FRMTYPE_RTSI          = $03;     // RTSI pulse (NC_ATTR_RTSI_MODE=NC_RTSI_TIME_ON_IN)

{ Status for Driver NetIntf (and Driver CanObjs):
  ArbID=0
  DataLength=0
  Timestamp=<time of start trigger> }

  NC_FRMTYPE_TRIG_START    = $04;
  NC_FRMTYPE_DELAY         = $05;    // Adds a delay between 2 timestamped frames.

{ CAN Frame to indicate Bus Error. Format: Byte 0:CommState,Byte1:Tx Err Ctr,
  Byte2: Rx Err Ctr, Byte 3: ECC register. Byte 4-7: Don't care.}
  NC_FRMTYPE_BUS_ERR       = $06;
  { Frame to indicate status of Nerr. Byte 0: 1 = NERR , 0 = No Fault.}
  NC_FRMTYPE_TRANSCEIVER_ERR = $07;

  //Response frame for LIN communication
  NC_FRMTYPE_LIN_RESPONSE_ENTRY = $10;
  //Header frame for LIN communication
  NC_FRMTYPE_LIN_HEADER    = $11;
  //Full frame for LIN communication
  NC_FRMTYPE_LIN_FULL      = $12;
  //Wakeup frame for LIN communication
  NC_FRMTYPE_LIN_WAKEUP_RECEIVED = $13;
  //Sleep frame for LIN communication
  NC_FRMTYPE_LIN_BUS_INACTIVE = $14;
  //Bus error frame for LIN communication
  NC_FRMTYPE_LIN_BUS_ERR   = $15;

   { Special values for CAN mask attributes (NC_ATTR_MASK_STD/XTD) }
  NC_MASK_STD_MUSTMATCH    = $000007FF;
  NC_MASK_XTD_MUSTMATCH    = $1FFFFFFF;
  NC_MASK_STD_DONTCARE     = $00000000;     // recommended for Series 2
  NC_MASK_XTD_DONTCARE     = $00000000;     // recommended for Series 2
  NC_SERIES2_MASK_MUSTMATCH = $00000000;
  NC_SERIES2_MASK_DONTCARE = $FFFFFFFF;

// Values for NC_ATTR_HW_SERIES attribute
  NC_HW_SERIES_1           = 0;        // Intel 82527 CAN chip, legacy RTSI
  NC_HW_SERIES_2           = 1;        // Phillips SJA1000 CAN chip, updated RTSI
  NC_HW_SERIES_847X        = 2;        // Low-cost USB without sync
  NC_HW_SERIES_847X_SYNC   = 3;        // Low-cost USB with sync


// Values for SourceTerminal of ncConnectTerminals.
  NC_SRC_TERM_RTSI0        = 0;
  NC_SRC_TERM_RTSI1        = 1;
  NC_SRC_TERM_RTSI2        = 2;
  NC_SRC_TERM_RTSI3        = 3;
  NC_SRC_TERM_RTSI4        = 4;
  NC_SRC_TERM_RTSI5        = 5;
  NC_SRC_TERM_RTSI6        = 6;
  NC_SRC_TERM_RTSI_CLOCK   = 7;
  NC_SRC_TERM_PXI_STAR     = 8;
  NC_SRC_TERM_INTF_RECEIVE_EVENT = 9;
  NC_SRC_TERM_INTF_TRANSCEIVER_EVENT = 10;
  NC_SRC_TERM_PXI_CLK10    = 11;
  NC_SRC_TERM_20MHZ_TIMEBASE = 12;
  NC_SRC_TERM_10HZ_RESYNC_CLOCK = 13;
  NC_SRC_TERM_START_TRIGGER = 14;

// Values for DestinationTerminal of ncConnectTerminals.
  NC_DEST_TERM_RTSI0       = 0;
  NC_DEST_TERM_RTSI1       = 1;
  NC_DEST_TERM_RTSI2       = 2;
  NC_DEST_TERM_RTSI3       = 3;
  NC_DEST_TERM_RTSI4       = 4;
  NC_DEST_TERM_RTSI5       = 5;
  NC_DEST_TERM_RTSI6       = 6;
  NC_DEST_TERM_RTSI_CLOCK  = 7;
  NC_DEST_TERM_MASTER_TIMEBASE = 8;
  NC_DEST_TERM_10HZ_RESYNC_CLOCK = 9;
  NC_DEST_TERM_START_TRIGGER = 10;

// Values for NC_ATTR_HW_FORMFACTOR attribute
  NC_HW_FORMFACTOR_PCI     = 0;
  NC_HW_FORMFACTOR_PXI     = 1;
  NC_HW_FORMFACTOR_PCMCIA  = 2;
  NC_HW_FORMFACTOR_AT      = 3;
  NC_HW_FORMFACTOR_USB     = 4;

// Values for NC_ATTR_TRANSCEIVER_TYPE attribute
  NC_TRANSCEIVER_TYPE_HS   = 0;  // High-Speed
  NC_TRANSCEIVER_TYPE_LS   = 1;  // Low-Speed / Fault-Tolerant
  NC_TRANSCEIVER_TYPE_SW   = 2;  // Single-Wire
  NC_TRANSCEIVER_TYPE_EXT  = 3;  // External connection
  NC_TRANSCEIVER_TYPE_DISC = 4;  // Disconnected
  NC_TRANSCEIVER_TYPE_LIN  = 5;  // LIN
  NC_TRANSCEIVER_TYPE_UNKNOWN = $FF;  // Unknown (Get for Series 1 PCMCIA HS dongle)

// Values for legacy NC_ATTR_HW_TRANSCEIVER attribute
  NC_HW_TRANSCEIVER_HS     = NC_TRANSCEIVER_TYPE_HS;
  NC_HW_TRANSCEIVER_LS     = NC_TRANSCEIVER_TYPE_LS;
  NC_HW_TRANSCEIVER_SW     = NC_TRANSCEIVER_TYPE_SW;
  NC_HW_TRANSCEIVER_EXT    = NC_TRANSCEIVER_TYPE_EXT;
  NC_HW_TRANSCEIVER_DISC   = NC_TRANSCEIVER_TYPE_DISC;

// Values for NC_ATTR_TRANSCEIVER_MODE attribute.
  NC_TRANSCEIVER_MODE_NORMAL     = 0;
  NC_TRANSCEIVER_MODE_SLEEP      = 1;
  NC_TRANSCEIVER_MODE_SW_WAKEUP  = 2;  // Single-Wire Wakeup
  NC_TRANSCEIVER_MODE_SW_HIGHSPEED = 3;  // Single-Wire High Speed

// Values for NC_ATTR_BEHAV_FINAL_OUT attribute (CAN Objs of type NC_CAN_COMM_TX_PERIODIC)
  NC_OUT_BEHAV_REPEAT_FINAL      = 0;
  NC_OUT_BEHAV_CEASE_TRANSMIT    = 1;

// Values for NC_ATTR_SERIES2_FILTER_MODE
  NC_FILTER_SINGLE_STANDARD = 0;
  NC_FILTER_SINGLE_EXTENDED = 1;
  NC_FILTER_DUAL_STANDARD   = 2;
  NC_FILTER_DUAL_EXTENDED   = 3;

// Values for SourceTerminal of ncConnectTerminals.
  NC_SRC_TERM_10HZ_RESYNC_EVENT  = NC_SRC_TERM_10HZ_RESYNC_CLOCK;
  NC_SRC_TERM_START_TRIG_EVENT   = NC_SRC_TERM_START_TRIGGER;

// Values for DestinationTerminal of ncConnectTerminals.
  NC_DEST_TERM_10HZ_RESYNC       = NC_DEST_TERM_10HZ_RESYNC_CLOCK;
  NC_DEST_TERM_START_TRIG        = NC_DEST_TERM_START_TRIGGER;

{ NCTYPE_VERSION (NC_ATTR_SOFTWARE_VERSION); ncGetHardwareInfo preferable }
  NC_MK_VER_MAJOR          = $FF000000;
  NC_MK_VER_MINOR          = $00FF0000;
  NC_MK_VER_SUBMINOR       = $0000FF00;
  NC_MK_VER_BETA           = $000000FF;

{ ArbitrationId; use IsRemote or FrameType to determine RTSI frame. }
  NC_FL_CAN_ARBID_INFO     = $40000000;
  NC_ARBID_INFO_RTSI_INPUT = $00000001;

{ NC_ATTR_STD_MASK and NC_ATTR_XTD_MASK }
  NC_CAN_MASK_STD_MUSTMATCH = NC_MASK_STD_MUSTMATCH;
  NC_CAN_MASK_XTD_MUSTMATCH = NC_MASK_XTD_MUSTMATCH;
  NC_CAN_MASK_STD_DONTCARE  = NC_MASK_STD_DONTCARE;
  NC_CAN_MASK_XTD_DONTCARE  = NC_MASK_XTD_DONTCARE;

{ Values for NC_ATTR_TRANSMIT_MODE(Immediate or timestamped).}
  NC_TX_MODE_IMMEDIATE      = 0;
  NC_TX_MODE_TIMESTAMPED    = 1;

{ Values for NC_ATTR_TIMESTAMP_FORMAT.}
  NC_TIME_FORMAT_ABSOLUTE   = 0;
  NC_TIME_FORMAT_RELATIVE   = 1;
{ Values for NC_ATTR_MASTER_TIMEBASE_RATE.Rate can either be
10(M Series DAQ) or 20(E series DAQ) Mhz.
This attribute is applicable only to PCI/PXI.}
  NC_TIMEBASE_RATE_10       = 10;
  NC_TIMEBASE_RATE_20       = 20;

{$ENDIF} { __NC_NOINC_other }

{**********************************************************************
                F U N C T I O N   P R O T O T Y P E S
**********************************************************************}

{$IFNDEF NC_NOINC_func}
{ Naming conventions for sizes:
   Sizeof?        Indicates size of buffer passed in, and has no relation to
                  the number of bytes sent/received on the network (C only).
   ?Length        Indicates number of bytes to send on network.
   Actual?Length  Indicates number of bytes received from network.
}

function ncAction(ObjHandle: NCTYPE_OBJH;
                  Opcode:    NCTYPE_OPCODE;
                  Param:     NCTYPE_UINT32): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncCloseObject(ObjHandle: NCTYPE_OBJH): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncConfig(ObjName :      NCTYPE_STRING;
                  NumAttrs:      NCTYPE_UINT32;
                  AttrIdList:    NCTYPE_ATTRID_P;
                  AttrValueList: NCTYPE_UINT32_P): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncConnectTerminals(ObjHandle:           NCTYPE_OBJH;
                            SourceTerminal:      NCTYPE_UINT32;
                            DestinationTerminal: NCTYPE_UINT32;
                            Modifiers:           NCTYPE_UINT32): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncDisconnectTerminals(ObjHandle:        NCTYPE_OBJH;
                               SourceTerminal:   NCTYPE_UINT32;
                               DestinationTerminal: NCTYPE_UINT32;
                               Modifiers: NCTYPE_UINT32): NCTYPE_STATUS; stdcall; external 'nican.dll';

{$IFNDEF NC_NOINC_createnotif}

function ncCreateNotification(ObjHandle:    NCTYPE_OBJH;
                              DesiredState: NCTYPE_STATE;
                              Timeout:      NCTYPE_DURATION;
                              RefData:      NCTYPE_ANY_P;
                              Callback:     NCTYPE_NOTIFY_CALLBACK): NCTYPE_STATUS; stdcall; external 'nican.dll';

{$ENDIF} { NC_NOINC_createnotif }

function ncGetAttribute(ObjHandle:    NCTYPE_OBJH;
                        AttrId:       NCTYPE_ATTRID;
                        SizeofAttr:   NCTYPE_UINT32;
                        Attr:         NCTYPE_ANY_P): NCTYPE_STATUS; stdcall; external 'nican.dll';


function ncGetHardwareInfo(CardIndex: NCTYPE_UINT32;
                           PortIndex: NCTYPE_UINT32;
                           AttrId: NCTYPE_ATTRID;
                           AttrSize: NCTYPE_UINT32;
                           Attr: NCTYPE_ANY_P): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncOpenObject(ObjName:   NCTYPE_STRING;
                      ObjHandle: NCTYPE_OBJH_P): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncRead(ObjHandle:  NCTYPE_OBJH;
                SizeofData: NCTYPE_UINT32;
                Data:       NCTYPE_ANY_P): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncReadMult(ObjHandle:  NCTYPE_OBJH;
                    SizeofData: NCTYPE_UINT32;
                    Data:       NCTYPE_ANY_P;
                    ActualDataSize: NCTYPE_UINT32_P): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncReset(IntfName:  NCTYPE_STRING;
                 Param:     NCTYPE_UINT32): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncSetAttribute(ObjHandle:  NCTYPE_OBJH;
                        AttrId:     NCTYPE_ATTRID;
                        SizeofAttr: NCTYPE_UINT32;
                        Attr:       NCTYPE_ANY_P): NCTYPE_STATUS; stdcall; external 'nican.dll';


procedure ncStatusToString(Status:          NCTYPE_STATUS;
                           SizeofString:    NCTYPE_UINT32;
                           ErrorString:     NCTYPE_STRING); stdcall; external 'nican.dll';

function ncWaitForState(ObjHandle:    NCTYPE_OBJH;
                        DesiredState: NCTYPE_STATE;
                        Timeout:      NCTYPE_DURATION;
                        CurrentState: NCTYPE_STATE_P): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncWrite(ObjHandle:  NCTYPE_OBJH;
                 SizeofData: NCTYPE_UINT32;
                 Data:       NCTYPE_ANY_P): NCTYPE_STATUS; stdcall; external 'nican.dll';

function ncWriteMult(ObjHandle: NCTYPE_OBJH;
                     SizeofData: NCTYPE_UINT32;
                     FrameArray: NCTYPE_CAN_STRUCT_P): NCTYPE_STATUS; stdcall; external 'nican.dll';

{$ENDIF} { NC_NOINC_func }

{$ENDIF NO_FRAME_API}

implementation

end.
