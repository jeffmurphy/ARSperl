/*
$Header: /cvsroot/arsperl/ARSperl/Attic/support.h,v 1.7 1997/10/20 21:00:41 jcmurphy Exp $

    ARSperl - An ARS2.x-3.0 / Perl5.x Integration Kit

    Copyright (C) 1995,1996,1997 
	Joel Murphy, jmurphy@acsu.buffalo.edu
        Jeff Murphy, jcmurphy@acsu.buffalo.edu
 
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.
 
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
 
    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

    Comments to:  arsperl@smurfland.cit.buffalo.edu
                  (this is a *mailing list*)

    Bugs to: arsperl-bugs@smurfland.cit.buffalo.edu
 
    LOG:

$Log: support.h,v $
Revision 1.7  1997/10/20 21:00:41  jcmurphy
5203 beta. code cleanup. winnt additions. malloc/free
debugging code.

Revision 1.6  1997/10/09 15:21:33  jcmurphy
1.5201: code cleaning

Revision 1.5  1997/10/09 00:49:28  jcmurphy
1.52: uninit'd var bug fix

Revision 1.4  1997/10/07 14:29:38  jcmurphy
1.51

Revision 1.3  1997/10/02 15:39:53  jcmurphy
1.50beta

Revision 1.2  1997/09/04 00:20:47  jcmurphy
*** empty log message ***

Revision 1.1  1997/08/05 21:21:11  jcmurphy
Initial revision


*/

#ifndef __support_h_
#define __support_h_

#undef EXTERN
#ifndef __support_c_
# define EXTERN extern
#else
# define EXTERN 
#endif

#include "ar.h"
#include "arerrno.h"
#include "arextern.h"
#include "arstruct.h"
#include "arfree.h"

#include "nt.h"
#include "nterrno.h"
#include "ntfree.h"
#include "ntsextrn.h"
#if AR_EXPORT_VERSION < 3
#include "ntcextrn.h"
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>
#include <limits.h>

#ifdef PROFILE
#include <sys/time.h>
#endif

typedef struct {
  unsigned int numItems;
  void *array;
} ARList;

typedef struct {
  ARControlStruct ctrl;
  int queries;
  long startTime;
  long endTime;
} ars_ctrl;

#define TYPEMAP_LAST 0xFFFFFFFFL

static struct {
  unsigned int  number;
  char         *name;
} DataTypeMap[] = {
  { AR_DATA_TYPE_NULL,     "null" },
  { AR_DATA_TYPE_KEYWORD,  "keyword" },
  { AR_DATA_TYPE_INTEGER,  "integer" },
  { AR_DATA_TYPE_REAL,     "real" },
  { AR_DATA_TYPE_CHAR,     "char" },
  { AR_DATA_TYPE_DIARY,    "diary" },
  { AR_DATA_TYPE_ENUM,     "enum" },
  { AR_DATA_TYPE_TIME,     "time" },
  { AR_DATA_TYPE_BITMASK,  "bitmask" },
#if AR_EXPORT_VERSION >= 3
  { AR_DATA_TYPE_BYTES,    "bytes" },
  { AR_DATA_TYPE_JOIN,     "join" },
  { AR_DATA_TYPE_TRIM,     "trim" },
  { AR_DATA_TYPE_CONTROL,  "control" },
  { AR_DATA_TYPE_ULONG,    "ulong" },
  { AR_DATA_TYPE_COORDS,   "coords" },
#endif
  { TYPEMAP_LAST, "" }
};

static struct {
  unsigned long  number;
  char          *name;
} ByteListTypeMap[] = {
#if AR_EXPORT_VERSION >= 3
  { AR_BYTE_LIST_SELF_DEFINED, "self_defined" },
  { AR_BYTE_LIST_WIN30_BITMAP, "win30_bitmap" },
#endif
  { TYPEMAP_LAST, "" }
};

static struct {
  unsigned int  number;
  char         *name;
} NoMatchOptionMap[] = {
#if AR_EXPORT_VERSION >= 3
  { AR_NO_MATCH_ERROR,    "error" },
  { AR_NO_MATCH_SET_NULL, "set_null" },
#endif
  { TYPEMAP_LAST, "" }
};

static struct {
  unsigned int  number;
  char         *name;
} MultiMatchOptionMap[] = {
#if AR_EXPORT_VERSION >= 3
  { AR_MULTI_MATCH_ERROR,     "error" },
  { AR_MULTI_MATCH_SET_NULL,  "set_null" },
  { AR_MULTI_MATCH_USE_FIRST, "use_first" },
  { AR_MULTI_MATCH_PICKLIST,  "picklist" },
#endif
  { TYPEMAP_LAST, "" }
};

static struct {
  unsigned int  number;
  char         *name;
} ArithOpMap[] = {
  { AR_ARITH_OP_ADD,      "+" },
  { AR_ARITH_OP_SUBTRACT, "-" },
  { AR_ARITH_OP_MULTIPLY, "*" },
  { AR_ARITH_OP_DIVIDE,   "/" },
  { AR_ARITH_OP_MODULO,   "%" },
  { AR_ARITH_OP_NEGATE,   "-" },
  { TYPEMAP_LAST, "" }
};

static struct {
  unsigned int  number;
  char         *name;
} FunctionMap[] = {
  { AR_FUNCTION_DATE,    "date" },
  { AR_FUNCTION_TIME,    "time" },
  { AR_FUNCTION_MONTH,   "month" },
  { AR_FUNCTION_DAY,     "day" },
  { AR_FUNCTION_YEAR,    "year" },
  { AR_FUNCTION_WEEKDAY, "weekday" },
  { AR_FUNCTION_HOUR,    "hour" },
  { AR_FUNCTION_MINUTE,  "minute" },
  { AR_FUNCTION_SECOND,  "second" },
  { AR_FUNCTION_TRUNC,   "trunc" },
  { AR_FUNCTION_ROUND,   "round" },
  { AR_FUNCTION_CONVERT, "convert" },
  { AR_FUNCTION_LENGTH,  "length" },
  { AR_FUNCTION_UPPER,   "upper" },
  { AR_FUNCTION_LOWER,   "lower" },
  { AR_FUNCTION_SUBSTR,  "substr" },
  { AR_FUNCTION_LEFT,    "left" },
  { AR_FUNCTION_RIGHT,   "right" },
  { AR_FUNCTION_LTRIM,   "ltrim" },
  { AR_FUNCTION_RTRIM,   "rtrim" },
  { AR_FUNCTION_LPAD,    "lpad" },
  { AR_FUNCTION_RPAD,    "rpad" },
  { AR_FUNCTION_REPLACE, "replace" },
  { AR_FUNCTION_STRSTR,  "substr" },
  { AR_FUNCTION_MIN,     "min" },
  { AR_FUNCTION_MAX,     "max" },
  { TYPEMAP_LAST, "" }
};

static struct {
  unsigned int  number;
  char         *name;
  int           len;
} KeyWordMap[] = {
  { AR_KEYWORD_DEFAULT,   "\0default\0",    9 },
  { AR_KEYWORD_USER,      "\0user\0",       6 },
  { AR_KEYWORD_TIMESTAMP, "\0timestamp\0", 11 },
  { AR_KEYWORD_TIME_ONLY, "\0time\0",       6 },
  { AR_KEYWORD_DATE_ONLY, "\0date\0",       6 },
  { AR_KEYWORD_SCHEMA,    "\0schema\0",     8 },
  { AR_KEYWORD_SERVER,    "\0server\0",     8 },
  { AR_KEYWORD_WEEKDAY,   "\0weekday\0",    9 },
  { AR_KEYWORD_GROUPS,    "\0groups\0",     8 },
  { AR_KEYWORD_OPERATION, "\0operation\0", 11 },
  { AR_KEYWORD_HARDWARE,  "\0hardware\0",  10 },
  { AR_KEYWORD_OS,        "\0os\0",         4 },
#if AR_EXPORT_VERSION >= 3
  { AR_KEYWORD_DATABASE,  "\0database\0",  10 },
  { AR_KEYWORD_LASTID,    "\0lastid\0",     8 },
  { AR_KEYWORD_LASTCOUNT, "\0lastcount\0", 11 },
  { AR_KEYWORD_VERSION,   "\0version\0",    9 },
  { AR_KEYWORD_VUI,       "\0vui\0",        5 },
#endif
  { TYPEMAP_LAST, "", 0 }
};

static struct {
  char *name;
  int   number;
} ServerInfoMap[] = {
  { NULL,              0 },
  { "DB_TYPE",         1 },
  { "SERVER_LICENSE",  2 },
  { "FIXED_LICENSE",   3 },
  { "VERSION",         4 },
  { "ALLOW_GUESTS",    5 },
  { "USE_ETC_PASSWD",  6 },
  { "XREF_PASSWORDS",  7 },
  { "DEBUG_MODE",      8 },
  { "DB_NAME",         9 },
  { "DB_PASSWORD",    10 },
  { "HARDWARE",       11 },
  { "OS",             12 },
  { "SERVER_DIR",     13 },
  { "DBHOME_DIR",     14 },
  { "SET_PROC_TIME",  15 },
  { "EMAIL_FROM",     16 },
  { "SQL_LOG_FILE",   17 },
  { "FLOAT_LICENSE",  18 },
  { "FLOAT_TIMEOUT",  19 },
  { "UNQUAL_QUERIES", 20 },
  { "FILTER_LOG_FILE", 21 },
  { "USER_LOG_FILE",  22 },
  { "REM_SERV_ID",    23 },
  { "MULTI_SERVER",   24 },
  { "EMBEDDED_SQL",   25 },
  { "MAX_SCHEMAS",    26 },
  { "DB_VERSION",     27 },
  { "MAX_ENTRIES",   28 },
  { "MAX_F_DAEMONS",  29 },
  { "MAX_L_DAEMONS",  30 },
  { "ESCALATION_LOG_FILE", 31 },
  { "ESCL_DAEMON",    32 },
  { "SUBMITTER_MODE", 33 },
  { "API_LOG_FILE",   34 },
  { "FTEXT_FIXED",    35 },
  { "FTEXT_FLOAT",    36 },
  { "FTEXT_TIMEOUT",  37 },
  { "RESERV1_A",     38 },
  { "RESERV1_B",      39 },
  { "RESERV1_C",      40 },
  { "SERVER_IDENT",   41 },
  { "DS_SVR_LICENSE", 42 },
  { "DS_MAPPING",     43 },
  { "DS_PENDING",     44 },
  { "DS_RPC_SOCKET",  45 },
  { "DS_LOG_FILE",    46 },
  { "SUPPRESS_WARN",  47 },
  { "HOSTNAME",       48 },
  { "FULL_HOSTNAME",  49 },
  { "SAVE_LOGIN",     50 },
  { "U_CACHE_CHANGE", 51 },
  { "G_CACHE_CHANGE", 52 },
  { "STRUCT_CHANGE", 53 },
  { "CASE_SENSITIVE", 54 }
};

/* lame Win32 stuff 
 *   FIX - can't we just use the CPERLarg stuff in perl's config.h
 *         file?
 *
 *   use in function declarations:
 *      AWP  - arsperl windows paramter
 *      AWPC - same thing, but with a comma
 *   use in function calls:
 *      PPERL  - pPerl argument for no-arg functions
 *      PPERLC - pPerl arg + comma for arg functions
 */

#ifdef _WIN32
# define _AWPC_   CPerl * pPerl,
# define _AWP_    CPerl * pPerl
# define _PPERLC_ pPerl,
# define _PPERL_  pPerl
#else
# define _AWPC_ 
# define _AWP_
# define _PPERLC_
# define _PPERL_
#endif

/* typedef SV* (*ARS_fn)(void *); */
typedef void *(*ARS_fn)(_AWPC_ void *b);

EXTERN void         zeromem(void *m, int s);
EXTERN void        *mallocnn(int s);
EXTERN void        *debug_mallocnn(int s, char *file, char *func, int line);
EXTERN void         debug_free(void *p, char *file, char *func, int line);
EXTERN unsigned int strsrch(register char *s, register char c);
EXTERN char        *strappend(char *b, char *a);

EXTERN int          ARError_reset(_AWP_);
EXTERN int          ARError_add(_AWPC_ unsigned int type, long num, char *text);
EXTERN int          ARError(_AWPC_ int returncode, ARStatusList status);
EXTERN int          NTError(_AWPC_ int returncode, NTStatusList status);

EXTERN SV *perl_ARPermissionList(_AWPC_ ARPermissionList *in);
EXTERN SV *perl_ARStatusStruct(_AWPC_ ARStatusStruct *);
EXTERN SV *perl_ARInternalId(_AWPC_ ARInternalId *);
EXTERN SV *perl_ARNameType(_AWPC_ ARNameType *);
EXTERN SV *perl_ARList(_AWPC_ ARList *, ARS_fn, int);
EXTERN SV *perl_ARValueStruct(_AWPC_ ARValueStruct *);
EXTERN SV *perl_ARValueStructType(_AWPC_ ARValueStruct *in);
EXTERN SV *perl_dataType_names(_AWPC_ unsigned int *);
EXTERN SV *perl_ARStatHistoryValue(_AWPC_ ARStatHistoryValue *);
EXTERN SV *perl_ARAssignFieldStruct(_AWPC_ ARAssignFieldStruct *);
EXTERN SV *perl_ARAssignStruct(_AWPC_ ARAssignStruct *);
EXTERN SV *perl_ARFieldAssignStruct(_AWPC_ ARFieldAssignStruct *);
EXTERN SV *perl_ARDisplayStruct(_AWPC_ ARDisplayStruct *);
EXTERN SV *perl_ARMacroParmStruct(_AWPC_ ARMacroParmStruct *);
EXTERN SV *perl_ARActiveLinkMacroStruct(_AWPC_ ARActiveLinkMacroStruct *);
EXTERN SV *perl_ARFieldCharacteristics(_AWPC_ ARFieldCharacteristics *);
EXTERN SV *perl_ARDDEStruct(_AWPC_ ARDDEStruct *);
EXTERN SV *perl_ARActiveLinkActionStruct(_AWPC_ ARActiveLinkActionStruct *);
EXTERN SV *perl_ARFilterActionStruct(_AWPC_ ARFilterActionStruct *);
EXTERN SV *perl_expandARCharMenuStruct(_AWPC_ ARControlStruct *, ARCharMenuStruct *);
EXTERN SV *perl_AREntryListFieldStruct(_AWPC_ AREntryListFieldStruct *);
EXTERN SV *perl_ARIndexStruct(_AWPC_ ARIndexStruct *);
EXTERN SV *perl_ARFieldLimitStruct(_AWPC_ ARFieldLimitStruct *);
EXTERN SV *perl_ARFunctionAssignStruct(_AWPC_ ARFunctionAssignStruct *);
EXTERN SV *perl_ARArithOpAssignStruct(_AWPC_ ARArithOpAssignStruct *);
EXTERN void dup_Value(_AWPC_ ARValueStruct *, ARValueStruct *);
EXTERN ARArithOpStruct *dup_ArithOp(_AWPC_ ARArithOpStruct *);
EXTERN void dup_ValueList(_AWPC_ ARValueList *, ARValueList *);
EXTERN ARQueryValueStruct *dup_QueryValue(_AWPC_ ARQueryValueStruct *);
EXTERN void dup_FieldValueOrArith(_AWPC_ ARFieldValueOrArithStruct *,
				  ARFieldValueOrArithStruct *);
EXTERN ARRelOpStruct *dup_RelOp(_AWPC_ ARRelOpStruct *);
EXTERN ARQualifierStruct *dup_qualifier(_AWPC_ ARQualifierStruct *);
EXTERN ARQualifierStruct *dup_qualifier2(_AWPC_ ARQualifierStruct *in, ARQualifierStruct *out, int level);
EXTERN SV *perl_ARArithOpStruct(_AWPC_ ARArithOpStruct *);
EXTERN SV *perl_ARQueryValueStruct(_AWPC_ ARQueryValueStruct *);
EXTERN SV *perl_ARFieldValueOrArithStruct(_AWPC_ ARFieldValueOrArithStruct *);
EXTERN SV *perl_relOp(_AWPC_ ARRelOpStruct *);
EXTERN HV *perl_qualifier(_AWPC_ ARQualifierStruct *);
EXTERN int ARGetFieldCached(_AWPC_ ARControlStruct *, ARNameType, ARInternalId,
#if AR_EXPORT_VERSION >= 3
		     ARNameType, ARFieldMappingStruct *,
#endif
		     unsigned int *, unsigned int *,
		     unsigned int *, ARValueStruct *,
		     ARPermissionList *, ARFieldLimitStruct *,
#if AR_EXPORT_VERSION >= 3
		     ARDisplayInstanceList *,
#else
		     ARDisplayList *,
#endif
		     char **, ARTimestamp *,
		     ARNameType, ARNameType, char **,
		     ARStatusList *);
EXTERN SV *perl_ARPermissionStruct(_AWPC_ ARPermissionStruct *);
EXTERN int sv_to_ARValue(_AWPC_ SV *in, unsigned int dataType, ARValueStruct *out);
#if AR_EXPORT_VERSION >= 3
EXTERN SV *perl_ARPropStruct(_AWPC_ ARPropStruct *);
EXTERN SV *perl_ARDisplayInstanceStruct(_AWPC_ ARDisplayInstanceStruct *);
EXTERN SV *perl_ARDisplayInstanceList(_AWPC_ ARDisplayInstanceList *);
EXTERN SV *perl_ARFieldMappingStruct(_AWPC_ ARFieldMappingStruct *);
EXTERN SV *perl_ARJoinMappingStruct(_AWPC_ ARJoinMappingStruct *);
EXTERN SV *perl_ARViewMappingStruct(_AWPC_ ARViewMappingStruct *);
EXTERN SV *perl_ARJoinSchema(_AWPC_ ARJoinSchema *);
EXTERN SV *perl_ARViewSchema(_AWPC_ ARViewSchema *);
EXTERN SV *perl_ARCompoundSchema(_AWPC_ ARCompoundSchema *);
EXTERN SV *perl_ARSortList(_AWPC_ ARSortList *);
EXTERN SV *perl_ARByteList(_AWPC_ ARByteList *);
EXTERN SV *perl_ARCoordStruct(_AWPC_ ARCoordStruct *);
EXTERN int perl_BuildEntryList(_AWPC_ AREntryIdList *entryList, char *entry_id);
EXTERN SV *perl_ARAssignSQLStruct(_AWPC_ ARAssignSQLStruct *in);
#endif

#ifndef BSD
# define MEMCAST void
#else
# define MEMCAST char
#endif

#define ZEROMEM(ptr, sizetype) zeromem((MEMCAST *) ptr, sizeof(sizetype))

EXTERN int  compmem(MEMCAST *m1, MEMCAST *m2, int size);
EXTERN void zeromem(MEMCAST *m, int size);
EXTERN int  copymem(MEMCAST *m1, MEMCAST *m2, int size);

#ifndef ARSPERL_MALLOCDEBUG
# define MALLOCNN(X) mallocnn(X) 
#else /* we want to debug memory allocations */
# define MALLOCNN(X) debug_mallocnn(X, __FILE__, __FUNCTION__, __LINE__) 
#endif /* malloc debugging */

#ifndef ARSPERL_FREEDEBUG
# define FREE(X) free(X)
#else
# define FREE(X) debug_free(X, __FILE__, __FUNCTION__, __LINE__)
#endif /* free debugging */

#define CPNULL (char *)NULL

/* some useful macros: CharVaLiD and IntVaLiD .. 
 * for checking validity of paramters
 * VNAME() for all of those perl functions that want a string and
 * it's length as the next parameter.
 */

#define CVLD(X) (X && *X)
#define IVLD(X, L, H) ((X <= H) && (L >= X))

#define VNAME(X) X, strlen(X)

/* defines used by the ARError* functions */

#define ERRHASH  "ARS::ars_errhash"
#define EH_COUNT "numItems"
#define EH_TYPE  "messageType"
#define EH_NUM   "messageNum"
#define EH_TEXT  "messageText"

#define ARSPERL_TRACEBACK -1

#define AP_ERR_BAD_ARGS     80000, "Invalid number of arguments"
#define AP_ERR_BAD_EID      80001, "Invalid entry-id argument"
#define AP_ERR_EID_TYPE     80002, "Entry-id should be an array or a single scalar"
#define AP_ERR_EID_LEN      80003, "Invalid Entry-id length"
#define AP_ERR_BAD_LFLDS    80004, "Bad GetListFields"
#define AP_ERR_LFLDS_TYPE   80005, "GetListFields must be an ARRAY reference"
#define AP_ERR_USAGE        80006  /* roll your own text */
#define AP_ERR_MALLOC       80007, "mallocnn() failed to allocate space"
#define AP_ERR_BAD_EXP      80009, "Unknown export type"
#define AP_ERR_BAD_IMP      80010, "Unknown import type"
#define AP_ERR_DEPRECATED   80011  /* roll your own text */
#define AP_ERR_NO_SERVERS   80012, "No servers available"
#define AP_ERR_FIELD_TYPE   80013, "Unknown field type"
#define AP_ERR_COORD_LIST   80014, "Bad coord list"
#define AP_ERR_COORD_STRUCT 80015, "Bad coord struct"
#define AP_ERR_BYTE_LIST    80016, "Bad byte list"
#define AP_ERR_EID_SEP      80017, "Expected EID to contain a separator"
#define AP_ERR_OPT_NA       80018 /* roll your own text - option not available */
#define AP_ERR_EXPECT_PVHV  80019, "Expected argument to contain a HASH reference"
#define AP_ERR_GENERAL      80020 /* roll your own text */
#define AP_ERR_CONTINUE     80021 /* roll your own continuation text */
#define AP_ERR_NEEDKEYS     80022, "Required hash keys do not exists"
#define AP_ERR_NEEDKEYSKEYS 80023 /* specify what keys */
#define AP_ERR_PREREVFAIL   80024, "Failed to convert some perl structures to ars structures. Create/Set operation aborted."

#endif /* __support_h_ */
