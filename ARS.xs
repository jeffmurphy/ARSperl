/*
$Header: /cvsroot/arsperl/ARSperl/ARS.xs,v 1.30 1997/07/02 15:52:18 jcmurphy Exp $

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

$Log: ARS.xs,v $
Revision 1.30  1997/07/02 15:52:18  jcmurphy
altered error handling routines. remove err buffer and ars_errstr
pointer from code.

Revision 1.29  1997/05/22 15:23:04  jmurphy
duh

Revision 1.28  1997/05/22 14:40:05  jmurphy
changed logic for checking for scalar values

Revision 1.27  1997/03/25 19:20:06  jmurphy
fixed ars_GetListSchema

Revision 1.26  1997/02/20 20:27:47  jcmurphy
added some minor code to handle decoding TR. and DB. values in qualifications

Revision 1.25  1997/02/19 22:39:28  jcmurphy
fixed problem with bad free() in ars_Login

Revision 1.24  1997/02/19 21:55:38  jmurphy
fixed bug in perl_ARValueStruct

Revision 1.23  1997/02/19 20:24:41  jcmurphy
*** empty log message ***

Revision 1.22  1997/02/19 15:30:25  jcmurphy
fixed bad goto

Revision 1.21  1997/02/19 14:21:48  jcmurphy
oops. fixed double call to getlistserver in ars_Login

Revision 1.20  1997/02/18 18:45:54  jcmurphy
ran thru -Wall and cleaned up some blunders and stuff

Revision 1.19  1997/02/18 16:37:32  jmurphy
a couple fixes.  added destructors for control struct, qualifier struct

Revision 1.18  1997/02/17 16:53:35  jcmurphy
commented ARTermination back out for a little bit longer.

Revision 1.17  1997/02/17 16:21:12  jcmurphy
uncommented ARTermintation(), added GetListServer to ars_Login incase
no server is specified. added ars_GetCurrentServer so you can determine
what server you connected to (if you didnt specify one).

Revision 1.16  1997/02/14 20:48:06  jcmurphy
un-commented the ARInitialization() call. this allows
you to write a perl script that connects to a private
server.

Revision 1.15  1997/02/14 20:38:49  jcmurphy
fixed phantom function call. initialized some un-inited stuff

Revision 1.14  1997/02/13 15:21:06  jcmurphy
modified comments


*/

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

/* typedef SV* (*ARS_fn)(void *); */
typedef void *(*ARS_fn)();

SV *perl_ARStatusStruct(ARStatusStruct *);
SV *perl_ARInternalId(ARInternalId *);
SV *perl_ARNameType(ARNameType *);
SV *perl_ARList(ARList *, ARS_fn, int);
SV *perl_ARValueStruct(ARValueStruct *);
SV *perl_dataType_names(unsigned int *);
SV *perl_ARStatHistoryValue(ARStatHistoryValue *);
SV *perl_ARAssignFieldStruct(ARAssignFieldStruct *);
SV *perl_ARAssignStruct(ARAssignStruct *);
SV *perl_ARFieldAssignStruct(ARFieldAssignStruct *);
SV *perl_ARDisplayStruct(ARDisplayStruct *);
SV *perl_ARMacroParmStruct(ARMacroParmStruct *);
SV *perl_ARActiveLinkMacroStruct(ARActiveLinkMacroStruct *);
SV *perl_ARFieldCharacteristics(ARFieldCharacteristics *);
SV *perl_ARDDEStruct(ARDDEStruct *);
SV *perl_ARActiveLinkActionStruct(ARActiveLinkActionStruct *);
SV *perl_ARFilterActionStruct(ARFilterActionStruct *);
SV *perl_expandARCharMenuStruct(ARControlStruct *, ARCharMenuStruct *);
SV *perl_AREntryListFieldStruct(AREntryListFieldStruct *);
SV *perl_ARIndexStruct(ARIndexStruct *);
SV *perl_ARFieldLimitStruct(ARFieldLimitStruct *);
SV *perl_ARFunctionAssignStruct(ARFunctionAssignStruct *);
SV *perl_ARArithOpAssignStruct(ARArithOpAssignStruct *);
/* int XARReleaseCurrentUser(ARControlStruct *, char *, ARStatusStruct *, int, int, int); */
void dup_Value(ARValueStruct *, ARValueStruct *);
ARArithOpStruct *dup_ArithOp(ARArithOpStruct *);
void dup_ValueList(ARValueList *, ARValueList *);
ARQueryValueStruct *dup_QueryValue(ARQueryValueStruct *);
void dup_FieldValueOrArith(ARFieldValueOrArithStruct *,ARFieldValueOrArithStruct *);
ARRelOpStruct *dup_RelOp(ARRelOpStruct *);
ARQualifierStruct *dup_qualifier(ARQualifierStruct *);
SV *perl_ARArithOpStruct(ARArithOpStruct *);
SV *perl_ARQueryValueStruct(ARQueryValueStruct *);
SV *perl_ARFieldValueOrArithStruct(ARFieldValueOrArithStruct *);
SV *perl_relOp(ARRelOpStruct *);
HV *perl_qualifier(ARQualifierStruct *);
int ARGetFieldCached(ARControlStruct *, ARNameType, ARInternalId,
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
SV *perl_ARPermissionStruct(ARPermissionStruct *);
#if AR_EXPORT_VERSION >= 3
SV *perl_ARPropStruct(ARPropStruct *);
SV *perl_ARDisplayInstanceStruct(ARDisplayInstanceStruct *);
SV *perl_ARDisplayInstanceList(ARDisplayInstanceList *);
SV *perl_ARFieldMappingStruct(ARFieldMappingStruct *);
SV *perl_ARJoinMappingStruct(ARJoinMappingStruct *);
SV *perl_ARViewMappingStruct(ARViewMappingStruct *);
SV *perl_ARJoinSchema(ARJoinSchema *);
SV *perl_ARViewSchema(ARViewSchema *);
SV *perl_ARCompoundSchema(ARCompoundSchema *);
SV *perl_ARSortList(ARSortList *);
SV *perl_ARByteList(ARByteList *);
SV *perl_ARCoordStruct(ARCoordStruct *);
#endif

/* some useful macros: CharVaLiD and IntVaLiD .. 
 * for checking validity of paramters
 */

#define CVLD(X) (X && *X)
#define IVLD(X, L, H) ((X <= H) && (L >= X))

/* malloc that will never return null */
static void *mallocnn(int s) {
  void *m = malloc(s?s:1);
  if (! m)
    croak("can't malloc");
  else 
    return m;
}

/* ROUTINE
 *   ARError_add(type, num, text)
 *   ARError_reset()
 *
 * DESCRIPTION
 *   err_hash is a hash with the following keys:
 *       {numItems}
 *       {messageType} (array reference)
 *       {messageNum}  (array reference)
 *       {messageText} (array reference)
 *   each of the array refs have exactly {numItems} elements in 
 *   them. one for each error in the list. 
 *
 *   _add will add a new error onto the error hash/array and will 
 *   incremement numItems appropriately.
 *
 *   _reset will reset the error hash to 0 elements and clear out
 *   old entries.
 *
 * RETURN
 *   0 on success
 *   negative int on failure
 */

static HV *err_hash = (HV *)NULL;

#define VNAME(X) X, strlen(X)
#define ERRHASH "ARS::arserr_hash"
#define EH_COUNT "numItems"
#define EH_TYPE  "messageType"
#define EH_NUM   "messageNum"
#define EH_TEXT  "messageText"

#define AP_ERR_BAD_ARGS     80000, "Invalid number of arguments"
#define AP_ERR_BAD_EID      80001, "Invalid entry-id argument"
#define AP_ERR_EID_TYPE     80002, "Entry-id should be an array or a single scalar"
#define AP_ERR_EID_LEN      80003, "Invalid Entry-id length"
#define AP_ERR_BAD_LFLDS    80004, "Bad GetListFields"
#define AP_ERR_LFLDS_TYPE   80005, "GetListFields must be an array reference"
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

static int
ARError_reset()
{
  SV **numItems, **messageType, **messageNum, **messageText, **t1;
  SV *ni, *t2;
  AV *mNum, *mType, *mText, *t3;

  /* lookup hash, create if necessary */

  err_hash    = perl_get_hv(ERRHASH, TRUE | 0x02);
  if(!err_hash) return -1;

  /* if keys already exist, delete them */

  if(hv_exists(err_hash, VNAME(EH_COUNT)))
	t2 = hv_delete(err_hash, VNAME(EH_COUNT), 0);

  /* the following are array refs. if the _delete call returns
   * the ref, we should remove all entries from the array and 
   * delete it as well.
   */

  if(hv_exists(err_hash, VNAME(EH_TYPE)))
	t2 = hv_delete(err_hash, VNAME(EH_TYPE), 0);

  if(hv_exists(err_hash, VNAME(EH_NUM))) 
	t2 = hv_delete(err_hash, VNAME(EH_NUM), 0);

  if(hv_exists(err_hash, VNAME(EH_TEXT)))
	t2 = hv_delete(err_hash, VNAME(EH_TEXT), 0);

  /* create numItems key, set to zero */

  ni = newSViv(0);
  if(!ni) return -2;
  t1 = hv_store(err_hash, VNAME(EH_COUNT), ni, 0);
  if(!t1) return -3;

  /* create array refs (with empty arrays) */

  t3 = newAV();
  if(!t3) return -4;
  t1 = hv_store(err_hash, VNAME(EH_TYPE), newRV((SV *)t3), 0);
  if(!t1 || !*t1) return -5;

  t3 = newAV();
  if(!t3) return -6;
  t1 = hv_store(err_hash, VNAME(EH_NUM), newRV((SV *)t3), 0);
  if(!t1 || !*t1) return -7;

  t3 = newAV();
  if(!t3) return -8;
  t1 = hv_store(err_hash, VNAME(EH_TEXT), newRV((SV *)t3), 0);
  if(!t1 || !*t1) return -9;

  return 0;
}

static int
ARError_add(unsigned int type, long num, char *text)
{
  SV          **numItems, **messageType, **messageNum, **messageText, **tmp;
  AV           *a;
  SV           *t2;
  unsigned int  ni, ret;

#ifdef ARSPERL_DEBUG
  printf("ARError_add(%d, %d, %s)\n", type, num, text?text:"NULL");
#endif

/* this is used to insert 'traceback' (debugging) messages into the
 * error hash. these can be filtered out by modifying the FETCH clause
 * of the ARSERRSTR package in ARS.pm
 */
#define ARSPERL_TRACEBACK -1

  switch(type) {
  case ARSPERL_TRACEBACK:
  case AR_RETURN_OK:
  case AR_RETURN_WARNING:
  case AR_RETURN_ERROR:
  case AR_RETURN_FATAL:
     break;
  default:
     return -1;
  }

  if(!text || !*text) return -2;

  /* fetch base hash and numItems reference, it should already exist
   * because you should call ARError_reset before using this routine.
   * if you forgot.. no big deal.. we'll do it for you.
   */

  err_hash    = perl_get_hv(ERRHASH, FALSE);
  if(!err_hash) {
     ret = ARError_reset();
     if(ret != 0) return -3;
  }
  numItems    = hv_fetch(err_hash, VNAME("numItems"), FALSE);
  if(!numItems)    return -4;
  messageType = hv_fetch(err_hash, VNAME("messageType"), FALSE);
  if(!messageType) return -5;
  messageNum  = hv_fetch(err_hash, VNAME("messageNum"), FALSE);
  if(!messageNum)  return -6;
  messageText = hv_fetch(err_hash, VNAME("messageText"), FALSE);
  if(!messageText) return -7;

  /* add the num, type and text to the appropriate arrays and 
   * then increase the counter by 1 (one).
   */

  if(!SvIOK(*numItems)) return -8;
  ni = (int) SvIV(*numItems) + 1;
  (void) sv_setiv(*numItems, ni);

  /* push type, num, and text onto each of the arrays */

  if(!SvROK(*messageType) || (SvTYPE(SvRV(*messageType)) != SVt_PVAV))
      return -9;

  if(!SvROK(*messageNum) || (SvTYPE(SvRV(*messageNum)) != SVt_PVAV))
      return -10;

  if(!SvROK(*messageText) || (SvTYPE(SvRV(*messageText)) != SVt_PVAV))
      return -11;

  a = (AV *)SvRV(*messageType);
  t2 = newSViv(type);
  (void) av_push(a, t2);

  a = (AV *)SvRV(*messageNum);
  t2 = newSViv(num);
  (void) av_push(a, t2);

  a = (AV *)SvRV(*messageText);
  t2 = newSVpv(text, strlen(text));
  (void) av_push(a, t2);

  return 0;  
}

/* ROUTINE
 *   ARError(returnCode, statusList)
 * 
 * DESCRIPTION
 *   This routine processes the given status list 
 *   and pushes any data it contains into the err_hash.
 *
 * RETURNS
 *   0 -> returnCode indicates no problems
 *   1 -> returnCode indicates failure/warning
 */

int 
ARError(int returncode, ARStatusList status) {
  int item;

  for ( item=0; item < status.numItems; item++ ) {
    ARError_add(status.statusList[item].messageType,
	status.statusList[item].messageNum,
	status.statusList[item].messageText);
  }

  if (returncode == 0)
    return 0;

#ifndef WASTE_MEM
  FreeARStatusList(&status, FALSE);
#endif
  return 1;
}

/* same as ARError, just uses the NT structures instead */
 
int NTError(int returncode, NTStatusList status) {
  int item;


  for ( item=0; item < status.numItems; item++ ) {
    ARError_add(status.statusList[item].messageType,
	status.statusList[item].messageNum,
	status.statusList[item].messageText);
  }

  if (returncode==0)
    return 0;

#ifndef WASTE_MEM
  FreeNTStatusList(&status, FALSE);
#endif
  return 1;
}

SV *perl_ARStatusStruct(ARStatusStruct *in) {
  char *msg;
  SV *ret;
  msg = mallocnn(strlen(in->messageText) + 100);
  sprintf(msg, "Type %d Num %d Text [%s]\n",
	  in->messageType,
	  (int)in->messageNum,
	  in->messageText);
  ret = newSVpv(msg, 0);
#ifndef WASTE_MEM
  free(msg);
#endif
  return ret;
}

SV *perl_ARInternalId(ARInternalId *in) {
  return newSViv(*in);
}

SV *perl_ARNameType(ARNameType *in) {
  return newSVpv(*in,0);
}

SV *perl_ARList(ARList *in, ARS_fn fn, int size) {
  int i;
  AV *array = newAV();
  for (i=0; i<in->numItems; i++)
    av_push(array, (*fn)((char *)in->array+(i*size)));
  return newRV((SV *)array);
}

SV *perl_diary(ARDiaryStruct *in) {
  HV *hash = newHV();
  
  hv_store(hash, "user", strlen("user"),
	   newSVpv(in->user, 0), 0);
  hv_store(hash, "timestamp", strlen("timestamp"),
	   newSViv(in->timeVal), 0);
  hv_store(hash, "value", strlen("value"),
	   newSVpv(in->value, 0), 0);
  return newRV((SV *)hash);
}

SV *perl_ARValueStruct(ARValueStruct *in) {
  char *s="";
  ARDiaryList diaryList;
  ARStatusList status;
  int ret;
  
  switch (in->dataType) {
  case AR_DATA_TYPE_KEYWORD:
    switch (in->u.keyNum) {
    case AR_KEYWORD_DEFAULT:
      return newSVpv("\0default\0",strlen("xdefaultx"));
      break;
    case AR_KEYWORD_USER:
      return newSVpv("\0user\0",strlen("xuserx"));
      break;
    case AR_KEYWORD_TIMESTAMP:
      return newSVpv("\0timestamp\0",strlen("xtimestampx"));
      break;
    case AR_KEYWORD_TIME_ONLY:
      return newSVpv("\0time\0",strlen("xtimex"));
      break;
    case AR_KEYWORD_DATE_ONLY:
      return newSVpv("\0date\0",strlen("xdatex"));
      break;
    case AR_KEYWORD_SCHEMA:
      return newSVpv("\0schema\0",strlen("xschemax"));
      break;
    case AR_KEYWORD_SERVER:
      return newSVpv("\0server\0",strlen("xserverx"));
      break;
    case AR_KEYWORD_WEEKDAY:
      return newSVpv("\0weekday\0",strlen("xweekdayx"));
      break;
    case AR_KEYWORD_GROUPS:
      return newSVpv("\0groups\0",strlen("xgroupsx"));
      break;
    case AR_KEYWORD_OPERATION:
      return newSVpv("\0operation\0",strlen("xoperationx"));
      break;
    case AR_KEYWORD_HARDWARE:
      return newSVpv("\0hardware\0",strlen("xhardwarex"));
      break;
    case AR_KEYWORD_OS:
      return newSVpv("\0os\0",strlen("xosx"));
      break;
    }
    return newSVpv(s,0);
  case AR_DATA_TYPE_INTEGER:
    return newSViv(in->u.intVal);
  case AR_DATA_TYPE_REAL:
    return newSVnv(in->u.realVal);
  case AR_DATA_TYPE_CHAR:
    return newSVpv(in->u.charVal, 0);
  case AR_DATA_TYPE_DIARY:
    ret = ARDecodeDiary(in->u.diaryVal, &diaryList, &status);
    if (ARError(ret, status))
      return newSVsv(&sv_undef);
    else {
      SV *array;
      array = perl_ARList((ARList *)&diaryList,
			  (ARS_fn)perl_diary,
			  sizeof(ARDiaryStruct));
#ifndef WASTE_MEM
      FreeARDiaryList(&diaryList,FALSE); 
#endif
      return array;
    }
  case AR_DATA_TYPE_ENUM:
    return newSViv(in->u.enumVal);
  case AR_DATA_TYPE_TIME:
    return newSViv(in->u.timeVal);
  case AR_DATA_TYPE_BITMASK:
    return newSViv(in->u.maskVal);
#if AR_EXPORT_VERSION >= 3
  case AR_DATA_TYPE_BYTES:
    return perl_ARByteList(in->u.byteListVal);
  case AR_DATA_TYPE_ULONG:
    return newSViv(in->u.ulongVal); /* FIX -- does perl have unsigned long? */
  case AR_DATA_TYPE_COORDS:
      return perl_ARList((ARList *)in->u.coordListVal,
			 (ARS_fn)perl_ARCoordStruct,
			 sizeof(ARCoordStruct));
#endif
  case AR_DATA_TYPE_NULL:
  default:
    return newSVsv(&sv_undef); /* FIX */
  }
}

SV *perl_dataType_names(unsigned int *in) {
  switch (*in) {
  case AR_DATA_TYPE_KEYWORD:
    return newSVpv("keyword",0);
  case AR_DATA_TYPE_INTEGER:
    return newSVpv("integer",0);
  case AR_DATA_TYPE_REAL:
    return newSVpv("real",0);
  case AR_DATA_TYPE_CHAR:
    return newSVpv("char",0);
  case AR_DATA_TYPE_DIARY:
    return newSVpv("diary",0);
  case AR_DATA_TYPE_ENUM:
    return newSVpv("enum",0);
  case AR_DATA_TYPE_TIME:
    return newSVpv("time",0);
  case AR_DATA_TYPE_BITMASK:
    return newSVpv("bitmask",0);
  case AR_DATA_TYPE_NULL:
  default:
    return newSVpv("null",0);
  }
}

SV *perl_ARStatHistoryValue(ARStatHistoryValue *in) {
  HV *hash = newHV();
  hv_store(hash, "userOrTime", strlen("userOrTime"),
	   newSViv(in->userOrTime), 0);
  hv_store(hash, "enumVal", strlen("enumVal"),
	   newSViv(in->enumVal), 0);
  return newRV((SV *)hash);
}

SV *perl_ARAssignFieldStruct(ARAssignFieldStruct *in) {
  HV *hash = newHV();
  ARQualifierStruct *qual;
  SV *ref;
  
  hv_store(hash, "server", strlen("server"),
	   newSVpv(in->server,0),0);
  hv_store(hash, "schema", strlen("schema"),
	   newSVpv(in->schema,0),0);
  qual = dup_qualifier(&in->qualifier);
  ref = newSViv(0);
  sv_setref_pv(ref, "ARQualifierStructPtr", (void*)qual);
  hv_store(hash, "qualifier", strlen("qualifier"),
	   ref,0);
  switch (in->tag) {
  case AR_FIELD:
    hv_store(hash, "fieldId", strlen("fieldId"),
	     newSViv(in->u.fieldId),0);
    break;
  case AR_STAT_HISTORY:
    hv_store(hash, "statHistory", strlen("statHistory"),
	     perl_ARStatHistoryValue(&in->u.statHistory),0);
    break;
  default:
    break;
  }
  return newRV((SV *)hash);
}

SV *perl_ARFieldAssignStruct(ARFieldAssignStruct *in) {
  HV *hash = newHV();
  hv_store(hash, "fieldId", strlen("fieldId"),
	   newSViv(in->fieldId), 0);
  hv_store(hash, "assignment", strlen("assignment"),
	   perl_ARAssignStruct(&in->assignment), 0);
  return newRV((SV *)hash);
}

SV *perl_ARDisplayStruct(ARDisplayStruct *in) {
  char *string;
  HV *hash = newHV();
  
  string = in->displayTag;
  hv_store(hash, "displayTag", strlen("displayTag"),
	   newSVpv(string,0),0);
  string = in->label;
  hv_store(hash, "label", strlen("label"),
	   newSVpv(string,0),0);
  switch (in->labelLocation) {
  case AR_DISPLAY_LABEL_LEFT:
    hv_store(hash, "labelLocation", strlen("labelLocation"),
	     newSVpv("Left",0),0);
    break;
  case AR_DISPLAY_LABEL_TOP:
    hv_store(hash, "labelLocation", strlen("labelLocation"),
	     newSVpv("Top",0),0);
    break;
  }
  switch (in->type) {
  case AR_DISPLAY_TYPE_NONE:
    hv_store(hash, "type", strlen("type"), newSVpv("NONE",0),0);
    break;
  case AR_DISPLAY_TYPE_TEXT:
    hv_store(hash, "type", strlen("type"), newSVpv("TEXT",0),0);
    break;
  case AR_DISPLAY_TYPE_NUMTEXT:
    hv_store(hash, "type", strlen("type"), newSVpv("NUMTEXT",0),0);
    break;
  case AR_DISPLAY_TYPE_CHECKBOX:
    hv_store(hash, "type", strlen("type"), newSVpv("CHECKBOX",0),0);
    break;
  case AR_DISPLAY_TYPE_CHOICE:
    hv_store(hash, "type", strlen("type"), newSVpv("CHOICE",0),0);
    break;
  case AR_DISPLAY_TYPE_BUTTON:
    hv_store(hash, "type", strlen("type"), newSVpv("BUTTON",0),0);
    break;
  }
  hv_store(hash, "length", strlen("length"),
	   newSViv(in->length),0);
  hv_store(hash, "numRows", strlen("numRows"),
	   newSViv(in->numRows),0);
  switch(in->option) {
  case AR_DISPLAY_OPT_VISIBLE:
    hv_store(hash, "option", strlen("option"),
	     newSVpv("VISIBLE",0),0);
    break;
  case AR_DISPLAY_OPT_HIDDEN:
    hv_store(hash, "option", strlen("option"),
	     newSVpv("HIDDEN",0),0);
    break;
  }
  hv_store(hash, "x", strlen("x"), newSViv(in->x),0);
  hv_store(hash, "y", strlen("y"), newSViv(in->y),0);
  return newRV((SV *)hash);
}

SV *perl_ARMacroParmList(ARMacroParmList *in) {
  HV *hash = newHV();
  int i;
  for (i=0; i<in->numItems; i++) {
    hv_store(hash, in->parms[i].name, strlen(in->parms[i].name),
	     newSVpv(in->parms[0].value,0), 0);
  }
  return newRV((SV *)hash);
}

SV *perl_ARActiveLinkMacroStruct(ARActiveLinkMacroStruct *in) {
  HV *hash = newHV();
  hv_store(hash, "macroParms", strlen("macroParms"),
	   perl_ARMacroParmList(&in->macroParms), 0);
  hv_store(hash, "macroText", strlen("macroText"),
	   newSVpv(in->macroText,0), 0);
  hv_store(hash, "macroName", strlen("macroName"),
	   newSVpv(in->macroName,0), 0);
  return newRV((SV *)hash);
}

SV *perl_ARFieldCharacteristics(ARFieldCharacteristics *in) {
  HV *hash = newHV();
  hv_store(hash, "accessOption", strlen("accessOption"),
	   newSViv(in->accessOption), 0);
  hv_store(hash, "focus", strlen("focus"),
	   newSViv(in->focus),0);
#if AR_EXPORT_VERSION < 3
  if (in->display)
    hv_store(hash, "display", strlen("display"),
	     perl_ARDisplayStruct(in->display),0);
#else
  hv_store(hash, "props", strlen("props"),
	   perl_ARList((ARList *)&in->props,
		       (ARS_fn)perl_ARPropStruct,
		       sizeof(ARPropStruct)), 0);
#endif
  if (in->charMenu)
    hv_store(hash, "charMenu", strlen("charMenu"),
	     newSVpv(in->charMenu, 0),0);
  hv_store(hash, "fieldId", strlen("fieldId"),
	   newSViv(in->fieldId),0);
  return newRV((SV *)hash);
}

SV *perl_ARDDEStruct(ARDDEStruct *in) {
  /* FIX */
  return &sv_undef;
}

SV *perl_ARActiveLinkActionStruct(ARActiveLinkActionStruct *in) {
  HV *hash=newHV();
  switch (in->action) {
  case AR_ACTIVE_LINK_ACTION_MACRO:
    hv_store(hash, "macro", strlen("macro"),
	     perl_ARActiveLinkMacroStruct(&in->u.macro), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_FIELDS:
    hv_store(hash, "assign_fields", strlen("assign_fields"),
	     perl_ARList((ARList *)&in->u.fieldList,
			 (ARS_fn)perl_ARFieldAssignStruct,
			 sizeof(ARFieldAssignStruct)), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_PROCESS:
    hv_store(hash, "process", strlen("process"),
	     newSVpv(in->u.process, 0), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_MESSAGE:
    hv_store(hash, "message", strlen("message"),
	     perl_ARStatusStruct(&in->u.message), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_SET_CHAR:
    hv_store(hash, "characteristics", strlen("characteristics"),
	     perl_ARFieldCharacteristics(&in->u.characteristics), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_DDE:
    hv_store(hash, "dde", strlen("dde"),
	     perl_ARDDEStruct(&in->u.dde), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_NONE:
  default:
    hv_store(hash, "none", strlen("none"),
	     &sv_undef, 0);
    break;
  }
  return newRV((SV *)hash);
}

SV *perl_ARFilterActionNotify(ARFilterActionNotify *in) {
  HV *hash=newHV();
  hv_store(hash, "user", strlen("user"),
 	   newSVpv(in->user, 0), 0);
  if(in->notifyText) 
	hv_store(hash, "notifyText", strlen("notifyText"),
		 newSVpv(in->notifyText, 0), 0);
  hv_store(hash, "notifyPriority", strlen("notifyPriority"),
	   newSViv(in->notifyPriority), 0);
  hv_store(hash, "notifyMechanism", strlen("notifyMechanism"),
	   newSViv(in->notifyMechanism), 0);
  hv_store(hash, "notifyMechanismXRef", strlen("notifyMechanismXRef"),
	   newSViv(in->notifyMechanismXRef), 0);
  if(in->subjectText)
	hv_store(hash, "subjectText", strlen("subjectText"),
		 newSVpv(in->subjectText, 0), 0);
  hv_store(hash, "fieldIdListType", strlen("fieldIdListType"),
	   newSViv(in->fieldIdListType), 0);
  hv_store(hash, "fieldList", strlen("fieldList"),
           perl_ARList((ARList *)&in->fieldIdList,
	   (ARS_fn)perl_ARInternalId,
           sizeof(ARInternalId)), 0);
  return newRV((SV *)hash);
}

SV *perl_ARFilterActionStruct(ARFilterActionStruct *in) {
  HV *hash=newHV();
  switch (in->action) {
  case AR_FILTER_ACTION_NOTIFY:
    hv_store(hash, "notify", strlen("notify"),
	     perl_ARFilterActionNotify(&in->u.notify), 0);
    break;
  case AR_FILTER_ACTION_MESSAGE:
    hv_store(hash, "message", strlen("message"),
	     perl_ARStatusStruct(&in->u.message), 0);
    break;
  case AR_FILTER_ACTION_FIELDS:
    hv_store(hash, "assign_fields", strlen("assign_fields"),
	     perl_ARList((ARList *)&in->u.fieldList,
			 (ARS_fn)perl_ARFieldAssignStruct,
			 sizeof(ARFieldAssignStruct)), 0);
    break;
  case AR_FILTER_ACTION_PROCESS:
    hv_store(hash, "process", strlen("process"),
	     newSVpv(in->u.process, 0), 0);
    break;
  case AR_FILTER_ACTION_NONE:
  default:
    hv_store(hash, "none", strlen("none"),
	     &sv_undef, 0);
    break;
  }
  return newRV((SV *)hash);
}

SV *perl_expandARCharMenuStruct(ARControlStruct *c, ARCharMenuStruct *in) {
  ARCharMenuStruct menu, *which;
  int ret, i;
  ARStatusList status;
  AV *array;
  SV *sub;
  char *string;
  
  if (in->menuType != AR_CHAR_MENU_LIST) {
    ret = ARExpandCharMenu(c, in, &menu, &status);
#ifdef PROFILE
    ((ars_ctrl *)c)->queries++;
#endif
    if (ARError(ret, status))
      return NULL;
    which = &menu;
  } else
    which = in;
  array = newAV();
  for (i=0; i<which->u.menuList.numItems; i++) {
    string = which->u.menuList.charMenuList[i].menuLabel;
    av_push(array, newSVpv(string, strlen(string)));
    switch(which->u.menuList.charMenuList[i].menuType) {
    case AR_MENU_TYPE_VALUE:
      string = which->u.menuList.charMenuList[i].u.menuValue;
      av_push(array, newSVpv(string, strlen(string)));
      break;
    case AR_MENU_TYPE_MENU:
      sub = perl_expandARCharMenuStruct(c, which->u.menuList.charMenuList[i].u.childMenu);
      if (!sub)
	return NULL;
      av_push(array, sub);
      break;
    case AR_MENU_TYPE_NONE:
    default:
      av_push(array, &sv_undef);
      break;
    }
  }
  return newRV((SV *)array);
}

SV *perl_AREntryListFieldStruct(AREntryListFieldStruct *in) {
  HV *hash;
  hash = newHV();

  hv_store(hash, "fieldId", strlen("fieldId"),
	   newSViv(in->fieldId), 0);
  hv_store(hash, "columnWidth", strlen("columnWidth"),
	   newSViv(in->columnWidth), 0);
  hv_store(hash, "separator", strlen("separator"),
	   newSVpv(in->separator, 0), 0);
  return newRV((SV *)hash);
}

SV *perl_ARIndexStruct(ARIndexStruct *in) {
  HV *hash;
  hash = newHV();
  
  if (in->unique) 
    hv_store(hash, "unique", strlen("unique"),
	     newSViv(1), 0);
  hv_store(hash, "fieldIds", strlen("fieldIds"),
	   perl_ARList((ARList *)in,
		       (ARS_fn)perl_ARInternalId,
		       sizeof(ARInternalId)), 0);
  return newRV((SV *)hash);
}

SV *perl_ARFieldLimitStruct(ARFieldLimitStruct *in) {
  HV *hash;
  hash = newHV();
  switch (in->dataType) {
  case AR_DATA_TYPE_INTEGER:
    hv_store(hash,"min",3,newSViv(in->u.intLimits.rangeLow),0);
    hv_store(hash,"max",3,newSViv(in->u.intLimits.rangeHigh),0);
    return newRV((SV *)hash);
  case AR_DATA_TYPE_REAL:
    hv_store(hash,"min",3,newSVnv(in->u.realLimits.rangeLow),0);
    hv_store(hash,"max",3,newSVnv(in->u.realLimits.rangeHigh),0);
    hv_store(hash,"precision",strlen("precision"),
	     newSViv(in->u.realLimits.precision),0);
    return newRV((SV *)hash);
  case AR_DATA_TYPE_CHAR:
    hv_store(hash,"maxLength",strlen("maxLength"),
	     newSViv(in->u.charLimits.maxLength), 0);
    switch(in->u.charLimits.menuStyle) {
    case AR_MENU_APPEND:
      hv_store(hash,"menuStyle",strlen("menuStyle"),
	       newSVpv("append",0),0);
      break;
    case AR_MENU_OVERWRITE:
      hv_store(hash,"menuStyle",strlen("menuStyle"),
	       newSVpv("overwrite",0),0);
      break;
    }
    switch(in->u.charLimits.qbeMatchOperation) {
    case AR_QBE_MATCH_ANYWHERE:
      hv_store(hash,"match",strlen("match"),
	       newSVpv("anywhere",0),0);
      break;
    case AR_QBE_MATCH_LEADING:
      hv_store(hash,"match",strlen("match"),
	       newSVpv("leading",0),0);
      break;
    case AR_QBE_MATCH_EQUAL:
      hv_store(hash,"match",strlen("match"),
	       newSVpv("equal",0),0);
      break;
    }
    hv_store(hash,"charMenu",strlen("charMenu"),
	     newSVpv(in->u.charLimits.charMenu,0), 0);
    hv_store(hash,"pattern",strlen("pattern"),
	     newSVpv(in->u.charLimits.pattern,0), 0);
    switch(in->u.charLimits.fullTextOptions) {
    case AR_FULLTEXT_OPTIONS_NONE:
      hv_store(hash,"fullTextOptions",strlen("fullTextOptions"),
	       newSVpv("none", 0), 0);
      break;
    case AR_FULLTEXT_OPTIONS_INDEXED:
      hv_store(hash,"fullTextOptions",strlen("fullTextOptions"),
	       newSVpv("indexed", 0), 0);
      break;
    }
    return newRV((SV *)hash);
  case AR_DATA_TYPE_DIARY:
    switch(in->u.diaryLimits.fullTextOptions) {
    case AR_FULLTEXT_OPTIONS_NONE:
      hv_store(hash,"fullTextOptions",strlen("fullTextOptions"),
	       newSVpv("none", 0), 0);
      break;
    case AR_FULLTEXT_OPTIONS_INDEXED:
      hv_store(hash,"fullTextOptions",strlen("fullTextOptions"),
	       newSVpv("indexed", 0), 0);
      break;
    }
    return newRV((SV *)hash);
  case AR_DATA_TYPE_ENUM:
    return perl_ARList((ARList *)&in->u.enumLimits,
		       (ARS_fn)perl_ARNameType, sizeof(ARNameType));
  case AR_DATA_TYPE_BITMASK:
    return perl_ARList((ARList *)&in->u.maskLimits,
		       (ARS_fn)perl_ARNameType, sizeof(ARNameType));
  case AR_DATA_TYPE_KEYWORD:
  case AR_DATA_TYPE_TIME:
  case AR_DATA_TYPE_NULL:
  default:
    /* no meaningful limits */
    return &sv_undef;
  }
}

SV *perl_ARAssignStruct(ARAssignStruct *in) {
  HV *hash;
  hash = newHV();
  switch(in->assignType) {
  case AR_ASSIGN_TYPE_NONE:
    hv_store(hash, "none", strlen("none"),
	     &sv_undef, 0);
    break;
  case AR_ASSIGN_TYPE_VALUE:
    hv_store(hash, "value", strlen("value"),
	     perl_ARValueStruct(&in->u.value), 0);
    break;
  case AR_ASSIGN_TYPE_FIELD:
    hv_store(hash, "field", strlen("field"),
	     perl_ARAssignFieldStruct(in->u.field), 0);
    break;
  case AR_ASSIGN_TYPE_PROCESS:
    hv_store(hash, "process", strlen("process"),
	     newSVpv(in->u.process, 0), 0);
    break;
  case AR_ASSIGN_TYPE_ARITH:
    hv_store(hash, "arith", strlen("arith"),
	     perl_ARArithOpAssignStruct(in->u.arithOp), 0);
    break;
  case AR_ASSIGN_TYPE_FUNCTION:
    hv_store(hash, "function", strlen("function"),
	     perl_ARFunctionAssignStruct(in->u.function), 0);
    break;
  case AR_ASSIGN_TYPE_DDE:
    hv_store(hash, "dde", strlen("dde"),
	     perl_ARDDEStruct(in->u.dde), 0);
    break;
  default:
    hv_store(hash, "none", strlen("none"),
	     &sv_undef, 0);
    break;
  }
  return newRV((SV *)hash);
}

SV *perl_ARFunctionAssignStruct(ARFunctionAssignStruct *in) {
  AV *array = newAV();
  char *fcn = "";
  int i;
  
  switch (in->functionCode) {
  case AR_FUNCTION_DATE:
    fcn = "date";
    break;
  case AR_FUNCTION_TIME:
    fcn = "time";
    break;
  case AR_FUNCTION_MONTH:
    fcn = "month";
    break;
  case AR_FUNCTION_DAY:
    fcn = "day";
    break;
  case AR_FUNCTION_YEAR:
    fcn = "year";
    break;
  case AR_FUNCTION_WEEKDAY:
    fcn = "weekday";
    break;
  case AR_FUNCTION_HOUR:
    fcn = "hour";
    break;
  case AR_FUNCTION_MINUTE:
    fcn = "minute";
    break;
  case AR_FUNCTION_SECOND:
    fcn = "second";
    break;
  case AR_FUNCTION_TRUNC:
    fcn = "trunc";
    break;
  case AR_FUNCTION_ROUND:
    fcn = "round";
    break;
  case AR_FUNCTION_CONVERT:
    fcn = "convert";
    break;
  case AR_FUNCTION_LENGTH:
    fcn = "length";
    break;
  case AR_FUNCTION_UPPER:
    fcn = "upper";
    break;
  case AR_FUNCTION_LOWER:
    fcn = "lower";
    break;
  case AR_FUNCTION_SUBSTR:
    fcn = "substr";
    break;
  case AR_FUNCTION_LEFT:
    fcn = "left";
    break;
  case AR_FUNCTION_RIGHT:
    fcn = "right";
    break;
  case AR_FUNCTION_LTRIM:
    fcn = "ltrim";
    break;
  case AR_FUNCTION_RTRIM:
    fcn = "rtrim";
    break;
  case AR_FUNCTION_LPAD:
    fcn = "lpad";
    break;
  case AR_FUNCTION_RPAD:
    fcn = "rpad";
    break;
  case AR_FUNCTION_REPLACE:
    fcn = "replace";
    break;
  case AR_FUNCTION_STRSTR:
    fcn = "substr";
    break;
  case AR_FUNCTION_MIN:
    fcn = "min";
    break;
  case AR_FUNCTION_MAX:
    fcn = "max";
    break;
  }
  av_push(array, newSVpv(fcn, 0));
  for (i=0; i<in->numItems; i++)
    av_push(array, perl_ARAssignStruct(&in->parameterList[i]));
  return newRV((SV *)array);
}

SV *perl_ARArithOpAssignStruct(ARArithOpAssignStruct *in) {
  HV *hash = newHV();
  char *oper="";
  switch(in->operation) {
  case AR_ARITH_OP_ADD:
    oper = "+";
    break;
  case AR_ARITH_OP_SUBTRACT:
    oper = "-";
    break;
  case AR_ARITH_OP_MULTIPLY:
    oper = "*";
    break;
  case AR_ARITH_OP_DIVIDE:
    oper = "/";
    break;
  case AR_ARITH_OP_MODULO:
    oper = "%";
    break;
  case AR_ARITH_OP_NEGATE:
    oper = "-";
    break;
  }
  hv_store(hash, "oper", strlen("oper"),
	   newSVpv(oper, 0), 0);
  if (in->operation == AR_ARITH_OP_NEGATE) {
    hv_store(hash, "left", strlen("left"),
	     perl_ARAssignStruct(&in->operandLeft), 0);
  } else {
    hv_store(hash, "right", strlen("right"),
	     perl_ARAssignStruct(&in->operandRight), 0);
    hv_store(hash, "left", strlen("left"),
	     perl_ARAssignStruct(&in->operandLeft), 0);
  }
  return newRV((SV *)hash);
}

SV *perl_ARPermissionList(ARPermissionList *in) {
  HV *hash = newHV();
  char groupid[20];
  int i;
  
  for (i=0; i<in->numItems; i++) {
    sprintf(groupid, "%i", (int)in->permissionList[i].groupId);
    switch (in->permissionList[i].permissions) {
    case AR_PERMISSIONS_NONE:
      hv_store(hash, groupid, strlen(groupid),
	       newSVpv("none",0), 0);
      break;
    case AR_PERMISSIONS_VIEW:
      hv_store(hash, groupid, strlen(groupid),
	       newSVpv("view",0), 0);
      break;
    case AR_PERMISSIONS_CHANGE:
      hv_store(hash, groupid, strlen(groupid),
	       newSVpv("change",0), 0);
      break;
    default:
      hv_store(hash, groupid, strlen(groupid),
	       newSVpv("unknown",0), 0);
      break;
    }
  }
  return newRV((SV *)hash);
}

#if AR_EXPORT_VERSION >= 3

SV *perl_ARPropStruct(ARPropStruct *in) {
  HV *hash = newHV();
  hv_store(hash, "prop", 3, newSViv(in->prop), 0);
  hv_store(hash, "value", 5, perl_ARValueStruct(&in->value), 0);
  return newRV((SV *)hash);
}

SV *perl_ARDisplayInstanceStruct(ARDisplayInstanceStruct *in) {
  HV *hash = newHV();
  hv_store(hash, "vui", 3, newSViv(in->vui), 0);
  hv_store(hash, "props", 4, perl_ARList((ARList *)&in->props,
					 (ARS_fn)perl_ARPropStruct,
					 sizeof(ARPropStruct)), 0);
  return newRV((SV *)hash);
}

SV *perl_ARDisplayInstanceList(ARDisplayInstanceList *in) {
  HV *hash = newHV();
  hv_store(hash, "commonProps", strlen("commonProps"),
	   perl_ARList((ARList *)&in->commonProps,
		       (ARS_fn)perl_ARPropStruct,
		       sizeof(ARPropStruct)), 0);
  /* the part of ARDisplayInstanceList after ARPropList looks like ARS's
   * other list structures, so take address of numItems field and pass
   * that to perl_ARList
   */
  hv_store(hash, "dInstanceList", strlen("dInstanceList"),
	   perl_ARList((ARList *)&in->numItems,
		       (ARS_fn)perl_ARDisplayInstanceStruct,
		       sizeof(ARDisplayInstanceStruct)), 0);
  return newRV((SV *)hash);
}

SV *perl_ARFieldMappingStruct(ARFieldMappingStruct *in) {
  HV *hash = newHV();
  hv_store(hash, "fieldType", strlen("fieldType"),
	   newSViv(in->fieldType), 0);
  switch (in->fieldType) {
  case AR_FIELD_JOIN:
    hv_store(hash, "join", 4, perl_ARJoinMappingStruct(&in->u.join), 0);
    break;
  case AR_FIELD_VIEW:
    hv_store(hash, "view", 4, perl_ARViewMappingStruct(&in->u.view), 0);
    break;
  }
  return newRV((SV *)hash);
}

SV *perl_ARJoinMappingStruct(ARJoinMappingStruct *in) {
  HV *hash = newHV();
  
  hv_store(hash, "schemaIndex", strlen("schemaIndex"),
	   newSViv(in->schemaIndex), 0);
  hv_store(hash, "realId", 6, newSViv(in->realId), 0);
  return newRV((SV *)hash);  
}

SV *perl_ARViewMappingStruct(ARViewMappingStruct *in) {
  HV *hash = newHV();
  
  hv_store(hash, "fieldName", 9, newSVpv(in->fieldName, 0), 0);
  return newRV((SV *)hash);    
}

SV *perl_ARJoinSchema(ARJoinSchema *in) {
  HV *hash = newHV();
  SV *joinQual = newSViv(0);
  
  hv_store(hash, "memberA", 7, newSVpv(in->memberA, 0), 0);
  hv_store(hash, "memberB", 7, newSVpv(in->memberB, 0), 0);
  sv_setref_pv(joinQual, "ARQualifierStructPtr", dup_qualifier(&in->joinQual));
  hv_store(hash, "joinQual", 8, joinQual, 0);
  hv_store(hash, "option", 6, newSViv(in->option), 0);
  return newRV((SV *)hash);
}

SV *perl_ARViewSchema(ARViewSchema *in) {
  HV *hash = newHV();
  
  hv_store(hash, "tableName", 9, newSVpv(in->tableName, 0), 0);
  hv_store(hash, "keyField", 8, newSVpv(in->keyField, 0), 0);
  hv_store(hash, "viewQual", 8, newSVpv(in->viewQual, 0), 0);
  return newRV((SV *)hash);
}

SV *perl_ARCompoundSchema(ARCompoundSchema *in) {
  HV *hash = newHV();
  
  switch (in->schemaType) {
  case AR_SCHEMA_JOIN:
    hv_store(hash, "join", 4, perl_ARJoinSchema(&in->u.join), 0);
    break;
  case AR_SCHEMA_VIEW:
    hv_store(hash, "view", 4, perl_ARViewSchema(&in->u.view), 0);
    break;
  }
  return newRV((SV *)hash);
}

SV *perl_ARSortList(ARSortList *in) {
  AV *array = newAV();
  int i;
  
  for (i=0; i<in->numItems; i++) {
    HV *sort = newHV();
    
    hv_store(sort, "fieldId", 7, newSViv(in->sortList[i].fieldId), 0);
    hv_store(sort, "sortOrder", 9, newSViv(in->sortList[i].sortOrder), 0);
    av_push(array, newRV((SV *)sort));
  }
  return newRV((SV *)array);
}

SV *perl_ARByteList(ARByteList *in) {
  HV *hash = newHV();
  SV *byte_list = newSVpv((char *)in->bytes, in->numItems);
  
  switch (in->type) {
  case AR_BYTE_LIST_SELF_DEFINED:
    hv_store(hash, "type", 4, newSVpv("self_defined", 0), 0);
    break;
  case AR_BYTE_LIST_WIN30_BITMAP:
    hv_store(hash, "type", 4, newSVpv("win30_bitmap", 0), 0);
    break;    
  default:
    hv_store(hash, "type", 4, newSVpv("unknown", 0), 0);
    break;
  }
  hv_store(hash, "value", 5, byte_list, 0);
  return newRV((SV *)hash);
}

SV *perl_ARCoordStruct(ARCoordStruct *in) {
  HV *hash = newHV();
  hv_store(hash, "x", 1, newSViv(in->x), 0);
  hv_store(hash, "y", 1, newSViv(in->y), 0);
  return newRV((SV *)hash);
}

#endif /* ARS 3 */

void dup_Value(ARValueStruct *n, ARValueStruct *in) {
  n->dataType = in->dataType;
  switch(in->dataType) {
  case AR_DATA_TYPE_NULL:
  case AR_DATA_TYPE_KEYWORD:
  case AR_DATA_TYPE_INTEGER:
  case AR_DATA_TYPE_REAL:
  case AR_DATA_TYPE_TIME:
  case AR_DATA_TYPE_BITMASK:
  case AR_DATA_TYPE_ENUM:
    n->u = in->u;
    break;
  case AR_DATA_TYPE_CHAR:
    n->u.charVal = strdup(in->u.charVal);
    break;
  case AR_DATA_TYPE_DIARY:
    n->u.diaryVal = strdup(in->u.diaryVal);
    break;
  }
}

ARArithOpStruct *dup_ArithOp(ARArithOpStruct *in) {
  ARArithOpStruct *n;
  if (!in)
    return NULL;
  n = mallocnn(sizeof(ARArithOpStruct));
  n->operation = in->operation;
  dup_FieldValueOrArith(&n->operandLeft, &in->operandLeft);
  dup_FieldValueOrArith(&n->operandRight, &in->operandRight);
  return n;
}

void dup_ValueList(ARValueList *n, ARValueList *in) {
  int i;
  n->numItems = in->numItems;
  n->valueList = mallocnn(sizeof(ARValueStruct) * in->numItems);
  for (i=0; i<in->numItems; i++)
    dup_Value(&n->valueList[0], &in->valueList[0]);
}

ARQueryValueStruct *dup_QueryValue(ARQueryValueStruct *in) {
  ARQueryValueStruct *n;
  if (!in)
    return NULL;
  n = mallocnn(sizeof(ARQueryValueStruct));
  strcpy(n->schema, in->schema);
  strcpy(n->server, in->server);
  n->qualifier = dup_qualifier(in->qualifier);
  n->valueField = in->valueField;
  n->multiMatchCode = in->multiMatchCode;
  return n;
}

void dup_FieldValueOrArith(ARFieldValueOrArithStruct *n,
			   ARFieldValueOrArithStruct *in) {
  n->tag = in->tag;
  switch (in->tag) {
  case AR_FIELD:
    n->u.fieldId = in->u.fieldId;
    break;
  case AR_VALUE:
    dup_Value(&n->u.value, &in->u.value);
    break;
  case AR_ARITHMETIC:
    n->u.arithOp = dup_ArithOp(in->u.arithOp);
    break;
  case AR_STAT_HISTORY:
    n->u.statHistory = in->u.statHistory;
    break;
  case AR_VALUE_SET:
    dup_ValueList(&n->u.valueSet, &in->u.valueSet);
    break;
  case AR_LOCAL_VARIABLE:
    n->u.variable = in->u.variable;
    break;
  case AR_QUERY:
    n->u.queryValue = dup_QueryValue(in->u.queryValue);
    break;
  }  
}

ARRelOpStruct *dup_RelOp(ARRelOpStruct *in) {
  ARRelOpStruct *n;
  if (! in)
    return NULL;
  n = mallocnn(sizeof(ARRelOpStruct));
  n->operation = in->operation;
  dup_FieldValueOrArith(&n->operandLeft, &in->operandLeft);
  dup_FieldValueOrArith(&n->operandRight, &in->operandRight);
  return n;
}

ARQualifierStruct *dup_qualifier(ARQualifierStruct *in) {
  ARQualifierStruct *n;
  if (!in)
    return NULL;
  n = mallocnn(sizeof(ARQualifierStruct));
  n->operation = in->operation;
  switch (in->operation) {
  case AR_COND_OP_AND:
  case AR_COND_OP_OR:
    n->u.andor.operandLeft = dup_qualifier(in->u.andor.operandLeft);
    n->u.andor.operandRight = dup_qualifier(in->u.andor.operandRight);
    break;
  case AR_COND_OP_NOT:
    n->u.not = dup_qualifier(in->u.not);
    break;
  case AR_COND_OP_REL_OP:
    n->u.relOp = dup_RelOp(in->u.relOp);
    break;
  case AR_COND_OP_NONE:
    break;
  }
  return n;
}

SV *perl_ARArithOpStruct(ARArithOpStruct *in) {
  HV *hash = newHV();
  char *oper="";
  switch(in->operation) {
  case AR_ARITH_OP_ADD:
    oper = "+";
    break;
  case AR_ARITH_OP_SUBTRACT:
    oper = "-";
    break;
  case AR_ARITH_OP_MULTIPLY:
    oper = "*";
    break;
  case AR_ARITH_OP_DIVIDE:
    oper = "/";
    break;
  case AR_ARITH_OP_MODULO:
    oper = "%";
    break;
  case AR_ARITH_OP_NEGATE:
    oper = "-";
    break;
  default:
    fprintf(stderr,"unknown arithop %i\n",in->operation);
    break;
  }
  hv_store(hash, "oper", strlen("oper"),
	   newSVpv(oper, 0), 0);
  if (in->operation == AR_ARITH_OP_NEGATE) {
    hv_store(hash, "left", strlen("left"),
	     perl_ARFieldValueOrArithStruct(&in->operandLeft), 0);
  } else {
    hv_store(hash, "right", strlen("right"),
	     perl_ARFieldValueOrArithStruct(&in->operandRight), 0);
    hv_store(hash, "left", strlen("left"),
	     perl_ARFieldValueOrArithStruct(&in->operandLeft), 0);
  }
  return newRV((SV *)hash);
}

SV *perl_ARQueryValueStruct(ARQueryValueStruct *in) {
  HV *hash = newHV();
  SV *ref;
  ARQualifierStruct *qual;
  hv_store(hash, "schema", strlen("schema"),
	   newSVpv(in->schema, 0), 0);
  hv_store(hash, "server", strlen("server"),
	   newSVpv(in->server, 0), 0);
  qual = dup_qualifier(in->qualifier);
  ref = newSViv(0);
  sv_setref_pv(ref, "ARQualifierStructPtr", (void*)qual);
  hv_store(hash, "qualifier", strlen("qualifier"),
	   ref,0);

  hv_store(hash, "valueField", strlen("valueField"),
	   newSViv(in->valueField), 0);
  switch(in->multiMatchCode) {
  case AR_QUERY_VALUE_MULTI_ERROR:
    hv_store(hash, "multi", strlen("multi"),
	     newSVpv("error", 0), 0);
    break;
  case AR_QUERY_VALUE_MULTI_FIRST:
    hv_store(hash, "multi", strlen("multi"),
	     newSVpv("first", 0), 0);
    break;
  case AR_QUERY_VALUE_MULTI_SET:
    hv_store(hash, "multi", strlen("multi"),
	     newSVpv("set", 0), 0);
   break;
  }
  return newRV((SV *)hash);
}

SV *perl_ARFieldValueOrArithStruct(ARFieldValueOrArithStruct *in) {
  HV *hash = newHV();
  switch (in->tag) {
  case AR_FIELD:
    hv_store(hash, "fieldId", strlen("fieldId"),
	     newSViv(in->u.fieldId), 0);
    break;
  case AR_VALUE:
    hv_store(hash, "value", strlen("value"),
	     perl_ARValueStruct(&in->u.value), 0);
    break;
  case AR_ARITHMETIC:
    hv_store(hash, "arith", strlen("arith"),
	     perl_ARArithOpStruct(in->u.arithOp), 0);
    break;
  case AR_STAT_HISTORY:
    hv_store(hash, "statHistory", strlen("statHistory"),
	     perl_ARStatHistoryValue(&in->u.statHistory), 0);
    break;
  case AR_VALUE_SET:
    hv_store(hash, "valueSet", strlen("valueSet"),
	     perl_ARList((ARList *)&in->u.valueSet,
			 (ARS_fn)perl_ARValueStruct,
			 sizeof(ARValueStruct)), 0);
    break;
  case AR_FIELD_TRAN:
    hv_store(hash, "TR_fieldId", strlen("TR_fieldId"),
	     newSViv(in->u.fieldId), 0);
    break;
  case AR_FIELD_DB:
    hv_store(hash, "DB_fieldId", strlen("DB_fieldId"),
	     newSViv(in->u.fieldId), 0);
    break;
  case AR_LOCAL_VARIABLE:
    hv_store(hash, "variable", strlen("variable"),
	     newSViv(in->u.variable), 0);
    break;
  case AR_QUERY:
    hv_store(hash, "queryValue", strlen("queryValue"),
	     perl_ARQueryValueStruct(in->u.queryValue), 0);
    break;
  case AR_FIELD_CURRENT:
    hv_store(hash, "queryCurrent", strlen("queryCurrent"),
	     newSViv(in->u.fieldId), 0);
    break;
  }
  return newRV((SV *)hash);
}

SV *perl_relOp(ARRelOpStruct *in) {
  HV *hash = newHV();
  char *s = "";
  switch(in->operation) {
  case AR_REL_OP_EQUAL:
    s = "==";
    break;
  case AR_REL_OP_GREATER:
    s = ">";
    break;
  case AR_REL_OP_GREATER_EQUAL:
    s = ">=";
    break;
  case AR_REL_OP_LESS:
    s = "<";
    break;
  case AR_REL_OP_LESS_EQUAL:
    s = "<=";
    break;
  case AR_REL_OP_NOT_EQUAL:
    s = "!=";
    break;
  case AR_REL_OP_LIKE:
    s = "like";
    break;
  case AR_REL_OP_IN:
    s = "in";
    break;
  }
  hv_store(hash, "oper", strlen("oper"),
	   newSVpv(s,0), 0);
  hv_store(hash, "left", strlen("left"),
	   perl_ARFieldValueOrArithStruct(&in->operandLeft), 0);
  hv_store(hash, "right", strlen("right"),
	   perl_ARFieldValueOrArithStruct(&in->operandRight), 0); 
  return newRV((SV *)hash);
}

HV *perl_qualifier(ARQualifierStruct *in) {
  HV *hash = newHV();
  char *s = "";
  
  if (in && in->operation != AR_COND_OP_NONE) {
    switch(in->operation) {
    case AR_COND_OP_AND:
      s = "and";
      hv_store(hash, "left", strlen("left"),
	       newRV((SV *)perl_qualifier(in->u.andor.operandLeft)), 0);
      hv_store(hash, "right", strlen("right"),
	       newRV((SV *)perl_qualifier(in->u.andor.operandRight)), 0);
      break;
    case AR_COND_OP_OR:
      s = "or";
      hv_store(hash, "left", strlen("left"),
	       newRV((SV *)perl_qualifier(in->u.andor.operandLeft)), 0);
      hv_store(hash, "right", strlen("right"),
	       newRV((SV *)perl_qualifier(in->u.andor.operandRight)), 0);
      break;
    case AR_COND_OP_NOT:
      s = "not";
      hv_store(hash, "not", strlen("not"),
	       newRV((SV *)perl_qualifier(in->u.not)), 0);
      break; 
    case AR_COND_OP_REL_OP:
      s = "rel_op";
      hv_store(hash, "rel_op", strlen("rel_op"),
	       perl_relOp(in->u.relOp), 0);
      break;
    }
    hv_store(hash, "oper", strlen("oper"),
	     newSVpv(s,0), 0);
  }
  return hash;
}

ARDisplayList *
dup_DisplayList(ARDisplayList *disp) {
  ARDisplayList *new_disp;
  new_disp = mallocnn(sizeof(ARDisplayList));
  new_disp->numItems = disp->numItems;
  new_disp->displayList = mallocnn(sizeof(ARDisplayStruct)*disp->numItems);
  memcpy(new_disp->displayList, disp->displayList,
	  sizeof(ARDisplayStruct)*disp->numItems);
  return new_disp;
}

int
ARGetFieldCached(ARControlStruct *ctrl, ARNameType schema, ARInternalId id,
#if AR_EXPORT_VERSION >= 3
		 ARNameType fieldName, ARFieldMappingStruct *fieldMap,
#endif
		 unsigned int *dataType, unsigned int *option,
		 unsigned int *createMode, ARValueStruct *defaultVal,
		 ARPermissionList *perm, ARFieldLimitStruct *limit,
#if AR_EXPORT_VERSION >= 3
		 ARDisplayInstanceList *display,
#else
		 ARDisplayList *display,
#endif
		 char **help, ARTimestamp *timestamp,
		 ARNameType owner, ARNameType lastChanged, char **changeDiary,
		 ARStatusList *Status) {
  int ret;
  HV *cache, *server, *fields, *base;
  SV **servers, **schema_fields, **field, **val;
  unsigned int my_dataType;
#if AR_EXPORT_VERSION >= 3
  ARNameType my_fieldName;
#else
  ARDisplayList my_display, *display_copy;
  SV *display_ref;
#endif
  char field_string[20];
  
#if AR_EXPORT_VERSION >= 3
  /* cache fieldName and dataType */
  if (fieldMap || option || createMode || defaultVal || perm || limit ||
      display || help || timestamp || owner || lastChanged || changeDiary)
    goto cache_fail;
#else
  /* cache dataType and displayList */
  if (option || createMode || defaultVal || perm || limit || help ||
	 timestamp || owner || lastChanged || changeDiary) 
    goto cache_fail;
#endif  
  
  /* try to do lookup in cache */  
  cache = perl_get_hv("ARS::field_cache",TRUE);
  /* dereference hash with server */
  servers = hv_fetch(cache, ctrl->server, strlen(ctrl->server), TRUE);
  if (! (servers && SvROK(*servers) &&
	 SvTYPE(server = (HV *)SvRV(*servers)) == SVt_PVHV))
    goto cache_fail;
  /* dereference hash with schema */
  schema_fields = hv_fetch(server, schema, strlen(schema), TRUE);
  if (! (schema_fields && SvROK(*schema_fields) &&
	 SvTYPE(fields = (HV *)SvRV(*schema_fields)) == SVt_PVHV))
    goto cache_fail;
  /* dereference with field id */
  sprintf(field_string, "%i", (int)id);
  field = hv_fetch(fields, field_string, strlen(field_string), TRUE);
  if (! (field && SvROK(*field) && SvTYPE(base = (HV *)SvRV(*field))))
    goto cache_fail;
  /* fetch values */
  val = hv_fetch(base, "name", strlen("name"), FALSE);
  if (! val) goto cache_fail;
#if AR_EXPORT_VERSION >= 3
  if (fieldName) {
    strcpy(fieldName, SvPV((*val), na));
  }
#else
  if (! sv_isa(*val, "ARDisplayListPtr"))
    goto cache_fail;
  if (display) {
    display_copy = (ARDisplayList *)SvIV(SvRV(*val));
    display->numItems = display_copy->numItems;
    display->displayList =
      mallocnn(sizeof(ARDisplayStruct)*display_copy->numItems);
    memcpy(display->displayList, display_copy->displayList,
	    sizeof(ARDisplayStruct)*display_copy->numItems);
  }
#endif
  val = hv_fetch(base, "type", strlen("type"), FALSE);
  if (! val)
    goto cache_fail;
  if (dataType) {
    *dataType = SvIV(*val);
  }
  return 0;
  
  /* we don't cache one of the arguments or we couln't find
     field in cache */
 cache_fail:;
#if AR_EXPORT_VERSION >= 3
  ret = ARGetField(ctrl, schema, id, my_fieldName, fieldMap, &my_dataType,
		   option, createMode, defaultVal, perm, limit,
		   display, help, timestamp, owner, lastChanged,
		   changeDiary, Status);
#else
  ret = ARGetField(ctrl, schema, id, &my_dataType, option, createMode,
		   defaultVal, perm, limit, &my_display, help, timestamp,
		   owner, lastChanged, changeDiary, Status);
#endif
  
#ifdef PROFILE
  ((ars_ctrl *)ctrl)->queries++;
#endif
  if (dataType)
    *dataType = my_dataType;
#if AR_EXPORT_VERSION >= 3
  if (fieldName)
    strcpy(fieldName, my_fieldName);
#else
  if (display)
    *display = my_display;
#endif
  if (ret == 0) {
    /* get variable */
    cache = perl_get_hv("ARS::field_cache",TRUE);
    /* dereference hash with server */
    servers = hv_fetch(cache, ctrl->server, strlen(ctrl->server), TRUE);
    if (! servers) return ret;
    if (! SvROK(*servers) ||
	SvTYPE(SvRV(*servers)) != SVt_PVHV) {
      sv_setsv(*servers, newRV((SV *)(server = newHV())));
    } else {
      server = (HV *)SvRV(*servers);
    }
    /* dereference hash with schema */
    schema_fields = hv_fetch(server, schema, strlen(schema), TRUE);
    if (! schema_fields) return ret;
    if (! SvROK(*schema_fields) ||
	SvTYPE(SvRV(*schema_fields)) != SVt_PVHV) {
      sv_setsv(*schema_fields, newRV((SV *)(fields = newHV())));
    } else {
      fields = (HV *)SvRV(*schema_fields);
    }
    /* dereference hash with field id */
    sprintf(field_string, "%i", (int)id);
    field = hv_fetch(fields, field_string, strlen(field_string), TRUE);
    if (! field) return ret;
    if (! SvROK(*field) ||
	SvTYPE(SvRV(*field)) != SVt_PVHV) {
      sv_setsv(*field, newRV((SV *)(base = newHV())));
    } else {
      base = (HV *)SvRV(*field);
    }
    /* store field attributes */
#if AR_EXPORT_VERSION >= 3
    hv_store(base, "name", 4, newSVpv(my_fieldName, 0), 0);
#else
    display_ref = newSViv(0);
    sv_setref_pv(display_ref, "ARDisplayListPtr",
		 (void *)dup_DisplayList(&my_display));
    hv_store(base, "name", strlen("name"), display_ref, 0);
#endif
    hv_store(base, "type", strlen("type"), newSViv(my_dataType), 0);
  }
  return ret;
}

int
sv_to_ARValue(SV *in, unsigned int dataType, ARValueStruct *out) {
  AV *array, *array2;
  HV *hash;
  SV **fetch, *type, *val, **fetch2;
  char *bytelist;
  unsigned int len, i, len2;
  
  out->dataType = dataType;
  if (! SvOK(in)) {
    /* pass a NULL */
    out->dataType = AR_DATA_TYPE_NULL;
  } else {
    switch (dataType) {
    case AR_DATA_TYPE_NULL:
      break;
    case AR_DATA_TYPE_KEYWORD:
      out->u.keyNum = SvIV(in);
      break;
    case AR_DATA_TYPE_INTEGER:
      out->u.intVal = SvIV(in);
      break;
    case AR_DATA_TYPE_REAL:
      out->u.realVal = SvNV(in);
      break;
    case AR_DATA_TYPE_CHAR:
      out->u.charVal = strdup(SvPV(in,na));
      break;
    case AR_DATA_TYPE_DIARY:
      out->u.diaryVal = strdup(SvPV(in,na));
      break;
    case AR_DATA_TYPE_ENUM:
      out->u.enumVal = SvIV(in);
      break;
    case AR_DATA_TYPE_TIME:
      out->u.timeVal = SvIV(in);
      break;
    case AR_DATA_TYPE_BITMASK:
      out->u.maskVal = SvIV(in);
      break;
#if AR_EXPORT_VERSION >= 3
    case AR_DATA_TYPE_BYTES:
      if (SvROK(in)) {
	if (SvTYPE(hash = (HV *)SvRV(in)) == SVt_PVHV) {
	  fetch = hv_fetch(hash, "type", 4, FALSE);
	  if (!fetch) {
            ARError_add(AR_RETURN_ERROR, AP_ERR_BYTE_LIST);
	    return -1;
	  }
	  type = *fetch;
	  if (! (SvOK(type) && SvTYPE(type) != SVt_RV)) {
            ARError_add(AR_RETURN_ERROR, AP_ERR_BYTE_LIST);
	    return -1;
	  }
	  fetch = hv_fetch(hash, "value", 5, FALSE);
	  if (!fetch) {
            ARError_add(AR_RETURN_ERROR, AP_ERR_BYTE_LIST);
	    return -1;
	  }
	  val = *fetch;
	  if (! (SvOK(val) && SvTYPE(val) != SVt_RV)) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BYTE_LIST);
	    return -1;
	  }
	  out->u.byteListVal = mallocnn(sizeof(ARByteList));
	  out->u.byteListVal->type = SvIV(type);
	  bytelist = SvPV(val, len);
	  out->u.byteListVal->numItems = len;
	  out->u.byteListVal->bytes = mallocnn(len);
	  memcpy(out->u.byteListVal->bytes, bytelist, len);
	  break;
	}
      }
      ARError_add(AR_RETURN_ERROR, AP_ERR_BYTE_LIST);
      return -1;
    case AR_DATA_TYPE_ULONG:
      out->u.ulongVal = SvIV(in); /* FIX -- does perl have ulong ? */
      break;
    case AR_DATA_TYPE_COORDS:
      if (SvTYPE(array = (AV *)SvRV(in)) == SVt_PVAV) {
	len = av_len(array) + 1;
	out->u.coordListVal = mallocnn(sizeof(ARCoordList));
	out->u.coordListVal->numItems = len;
	out->u.coordListVal->coords = mallocnn(sizeof(ARCoordStruct)*len);
	for (i=0; i<len; i++) {
	  fetch = av_fetch(array, i, 0);
	  if (fetch && SvTYPE(array2 = (AV *)SvRV(*fetch)) == SVt_PVAV &&
	      av_len(array2) == 1) {
	    fetch2 = av_fetch(array2, 0, 0);
	    if (! *fetch2) goto fetch_puke;
	    out->u.coordListVal->coords[i].x = SvIV(*fetch);
	    fetch2 = av_fetch(array2, 1, 0);
	    if (! *fetch2) goto fetch_puke;
	    out->u.coordListVal->coords[i].y = SvIV(*fetch);
	  } else {
	  fetch_puke:;
#ifndef WASTE_MEM
	    free(out->u.coordListVal->coords);
	    free(out->u.coordListVal);
#endif
            ARError_add(AR_RETURN_ERROR, AP_ERR_COORD_STRUCT);
	    return -1;
	  }
	}
	return 0;
      }
      ARError_add(AR_RETURN_ERROR, AP_ERR_COORD_LIST);
      return -1;
#endif
    default:
      ARError_add(AR_RETURN_ERROR, AP_ERR_FIELD_TYPE);
      return -1;
    }
  }
  return 0;
}

MODULE = ARS		PACKAGE = ARS		PREFIX = ARS

PROTOTYPES: ENABLE

int
isa_int(...)
	CODE:
	{
	  if (items != 1)
	    croak("usage: isa_int(value)");
	  RETVAL = SvIOKp(ST(0));
	}
	OUTPUT:
	RETVAL

int
isa_float(...)
	CODE:
	{
	  if (items != 1)
	    croak("usage: isa_int(value)");
	  RETVAL = SvNOKp(ST(0));
	}
	OUTPUT:
	RETVAL

int
isa_string(...)
	CODE:
	{
	  if (items != 1)
	    croak("usage: isa_int(value)");
	  RETVAL = SvPOKp(ST(0));
	}
	OUTPUT:
	RETVAL

HV *
ars_perl_qualifier(in)
	ARQualifierStruct *	in
	CODE:
	{
	  RETVAL = perl_qualifier(in);
	}
	OUTPUT:
	RETVAL

ARQualifierStruct *
ars_LoadQualifier(ctrl,schema,qualstring)
	ARControlStruct *	ctrl
	char *			schema
	char *			qualstring
	CODE:
	{
	  int ret;
	  ARQualifierStruct *qual = mallocnn(sizeof(ARQualifierStruct));
	  ARStatusList status;
	  
	  ARError_reset();
	  /* this gets freed below in the ARQualifierStructPTR package */
	  ret = ARLoadARQualifierStruct(ctrl, schema, NULL, qualstring, qual, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError(ret, status)) {
	    RETVAL = qual;
	  } else {
	    RETVAL = NULL;
#ifndef WASTE_MEM
	    free(qual);
#endif
	  }
	}
	OUTPUT:
	RETVAL

void
__ars_Termination()
	CODE:
	{
	  int ret;
	  ARStatusList status;
	  
	  ARError_reset();
	  ret = ARTermination(&status);
	  if (ARError(ret, status)) {
	    warn("failed in ARTermination\n");
	  }
	}

void
__ars_init()
	CODE:
	{
	  int ret;
	  ARStatusList status;
	
	  ARError_reset();
	  ret = ARInitialization(&status);
	  if (ARError(ret, status)) {
	    croak("unable to initialize ARS module");
	  }
	}

ARControlStruct *
ars_Login(server,username,password)
	char *		server
	char *		username
	char *		password
	CODE:
	{
	  int ret, s_ok = 1;
	  ARStatusList status;
	  ARServerNameList serverList;
	  ARControlStruct *ctrl;
#ifdef PROFILE
	  struct timeval tv;
#endif

	  RETVAL = NULL;
	  ARError_reset();  
	  /* this gets freed below in the ARControlStructPTR package */
	  ctrl = (ARControlStruct *)mallocnn(sizeof(ars_ctrl));
	  ((ars_ctrl *)ctrl)->queries = 0;
	  ((ars_ctrl *)ctrl)->startTime = 0;
	  ((ars_ctrl *)ctrl)->endTime = 0;
#ifdef PROFILE
	  if (gettimeofday(&tv, 0) != -1)
		((ars_ctrl *)ctrl)->startTime = tv.tv_sec;
	  else
		perror("gettimeofday");
#endif
	  ctrl->cacheId = 0;
	  ctrl->operationTime = 0;
	  strncpy(ctrl->user, username, sizeof(ctrl->user));
	  ctrl->user[sizeof(ctrl->user)-1] = 0;
	  strncpy(ctrl->password, password, sizeof(ctrl->password));
	  ctrl->password[sizeof(ctrl->password)-1] = 0;
	  ctrl->language[0] = 0;
	  if (!server || !*server) {
	    ret = ARGetListServer(&serverList, &status);
	    if (ARError(ret, status)) {
	      RETVAL = NULL;
	      goto ar_login_end;
	    }
	    if (serverList.numItems < 0) {
	      ARError_add(AR_RETURN_ERROR, AP_ERR_NO_SERVERS);
	      RETVAL = NULL;
	      goto ar_login_end;
	    }
	    server = serverList.nameList[0];
	    s_ok = 0;
	  }
	  strncpy(ctrl->server, server, sizeof(ctrl->server));
	  ctrl->server[sizeof(ctrl->server)-1] = 0;
	  RETVAL = ctrl;
#ifndef WASTE_MEM
	if(s_ok == 0)
	  FreeARServerNameList(&serverList,FALSE);
#endif
	ar_login_end:;
	}
	OUTPUT:
	RETVAL

SV *
ars_GetCurrentServer(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  RETVAL = NULL;
	  ARError_reset();
	  if(ctrl && ctrl->server) {
	    RETVAL = newSVpv(ctrl->server, strlen(ctrl->server));
	  } 
	}
	OUTPUT:
	RETVAL

HV *
ars_GetProfileInfo(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  RETVAL = newHV();
	  ARError_reset();
#ifdef PROFILE
	  hv_store(RETVAL, "queries", strlen("queries"),
	  	   newSViv(((ars_ctrl *)ctrl)->queries), 0);
	  hv_store(RETVAL, "startTime", strlen("startTime"),
		   newSViv(((ars_ctrl *)ctrl)->startTime), 0);
#else /* profiling not compiled in */
	  ARError_add(AR_RETURN_WARN, 10000, "optional profiling not compiled in");
#endif
	}
	OUTPUT:
	RETVAL

void
ars_Logoff(ctrl,a=0,b=0,c=1)
	ARControlStruct *	ctrl
	int			a
	int			b
	int			c
	CODE:
	{
	    int ret;
	    ARStatusList status;
	    ARError_reset();
	    if (!ctrl) return;
	    ret = XARReleaseCurrentUser(ctrl, ctrl->user, &status, a, b, c);
	    ARError(ret, status);
	}

void
ars_GetListField(control,schema,changedsince=0,fieldType=ULONG_MAX)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	unsigned long		fieldType
	PPCODE:
	{
	  ARInternalIdList idlist;
	  ARStatusList status;
	  int ret, i;
	  ARError_reset();
#if AR_EXPORT_VERSION >= 3
	  if (fieldType == ULONG_MAX)
	    fieldType = AR_FIELD_TYPE_ALL;
	  
	  ret = ARGetListField(control,schema,fieldType,changedsince,&idlist,&status);
#else
	  ret = ARGetListField(control,schema,changedsince,&idlist,&status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError(ret,status)) {
	    for (i=0; i<idlist.numItems; i++)
	      XPUSHs(sv_2mortal(newSViv(idlist.internalIdList[i])));
#ifndef WASTE_MEM
	    FreeARInternalIdList(&idlist,FALSE);
#endif
	  }
	}

void
ars_GetFieldByName(control,schema,field_name)
	ARControlStruct *	control
	char *			schema
	char *			field_name
	PPCODE:
	{
	  int ret, loop;
	  ARInternalIdList idList;
	  ARStatusList status;
#if AR_EXPORT_VERSION >= 3
	  ARNameType fieldName;
#else
	  ARDisplayList displayList;
#endif
	  ARError_reset();
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListField(control, schema, AR_FIELD_TYPE_ALL, (ARTimestamp)0, &idList, &status);
#else
	  ret = ARGetListField(control, schema, (ARTimestamp)0, &idList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (! ARError(ret, status)) {
	    for (loop=0; loop<idList.numItems; loop++) {
#if AR_EXPORT_VERSION >= 3
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], fieldName, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], NULL, NULL, NULL, NULL, NULL, NULL, &displayList, NULL, NULL, NULL, NULL, NULL, &status);
#endif
	      if (ARError(ret, status))
	        break;
#if AR_EXPORT_VERSION >= 3
	      if (strcmp(field_name, fieldName) == 0)
#else 
	      if (displayList.numItems < 1) {
		ARError_add(ARSPERL_TRACEBACK, 1, "No fields were returned in display list");
		break;
	      }
	      if (strcmp(field_name,displayList.displayList[0].label)==0)
#endif
	      {
		XPUSHs(sv_2mortal(newSViv(idList.internalIdList[loop])));
#if AR_EXPORT_VERSION < 3
#ifndef WASTE_MEM
		FreeARDisplayList(&displayList, FALSE);
#endif
#endif
		break;
	      }
#if AR_EXPORT_VERSION < 3
#ifndef WASTE_MEM
	      FreeARDisplayList(&displayList, FALSE);
#endif
#endif
	    }
#ifndef WASTE_MEM
	    FreeARInternalIdList(&idList, FALSE);
#endif
	  }
	}

void
ars_GetFieldTable(control,schema)
	ARControlStruct *	control
	char *			schema
	PPCODE:
	{
	  int ret, loop;
	  ARInternalIdList idList;
	  ARStatusList status;
#if AR_EXPORT_VERSION >= 3
	  ARNameType fieldName;
#else
	  ARDisplayList displayList;
#endif
	  ARError_reset();
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListField(control, schema, AR_FIELD_TYPE_ALL, (ARTimestamp)0, &idList, &status);
#else
	  ret = ARGetListField(control, schema, (ARTimestamp)0, &idList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (! ARError(ret, status)) {
	    for (loop=0; loop<idList.numItems; loop++) {
#if AR_EXPORT_VERSION >= 3
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], fieldName, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], NULL, NULL, NULL, NULL, NULL, NULL, &displayList, NULL, NULL, NULL, NULL, NULL, &status);
#endif
	      if (ARError(ret, status))
	        break;
#if AR_EXPORT_VERSION >= 3
	      XPUSHs(sv_2mortal(newSVpv(fieldName, 0)));
#else
	      if (displayList.numItems < 1) {
		ARError_add(ARSPERL_TRACEBACK, 1, "No fields were returned in display list");
		continue;
	      }
	      XPUSHs(sv_2mortal(newSVpv(displayList.displayList[0].label, strlen(displayList.displayList[0].label))));
#endif
	      XPUSHs(sv_2mortal(newSViv(idList.internalIdList[loop])));
#if AR_EXPORT_VERSION < 3
#ifndef WASTE_MEM
	      FreeARDisplayList(&displayList, FALSE);
#endif
#endif
	    }
#ifndef WASTE_MEM
	    FreeARInternalIdList(&idList, FALSE);
#endif
	  }
	}

char *
ars_CreateEntry(ctrl,schema...)
	ARControlStruct *	ctrl
	char *			schema
	CODE:
	{
	  int a, i, c = (items - 2) / 2, j;
	  AREntryIdType entryId;
	  ARFieldValueList fieldList;
	  ARStatusList      status;
	  int               ret;
	  unsigned int dataType;
	  
	  RETVAL = "";
	  ARError_reset();
	  if (((items - 2) % 2) || c < 1) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {
	    fieldList.numItems = c;
	    fieldList.fieldValueList = mallocnn(sizeof(ARFieldValueStruct)*c);
	    for (i=0; i<c; i++) {
	      a = i*2+2;
	      fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
#if AR_EXPORT_VERSION >= 3
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, NULL, NULL, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#endif
	      if (ARError(ret, status)) {	
		goto create_entry_end;
	      }
	      if (sv_to_ARValue(ST(a+1), dataType, &fieldList.fieldValueList[i].value) < 0) {
#ifndef WASTE_MEM
		for (j=0; j<i; j++) {
		  FreeARValueStruct(&fieldList.fieldValueList[j].value, FALSE);
		}
#endif
		goto create_entry_end;
	      }
	    }
	    ret = ARCreateEntry(ctrl, schema, &fieldList, entryId, &status);
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (! ARError(ret, status)) {
	      RETVAL = entryId;
	    }
#ifndef WASTE_MEM
	    for (j=0; j<c; j++) {
	      FreeARValueStruct(&fieldList.fieldValueList[j].value, FALSE);
	    }
#endif
	  create_entry_end:;
#ifndef WASTE_MEM
	    free(fieldList.fieldValueList);
#endif
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteEntry(ctrl,schema,entry_id)
	ARControlStruct *	ctrl
	char *			schema
	SV *			entry_id
	CODE:
	{
	  int ret;
	  ARStatusList status;
	  char *entryId;
#if AR_EXPORT_VERSION >= 3
	  SV **fetch_entry;
	  AREntryIdList entryList;
	  AV *input_list;
	  int i;
	  RETVAL=-1; /* assume error */
	  ARError_reset();
	  /* build entryList */
	  if (SvROK(entry_id)) {
	    if (SvTYPE(input_list = (AV *)SvRV(entry_id)) == SVt_PVAV) {
	      /* reference to array of entry ids */
	      entryList.numItems = av_len(input_list) + 1;
	      entryList.entryIdList = mallocnn(sizeof(AREntryIdType) *
					       entryList.numItems);
	      for (i=0; i<entryList.numItems; i++) {
		fetch_entry = av_fetch(input_list, i, 0);
		if (! fetch_entry) {
		  RETVAL=-1;
		  ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EID);
#ifndef WASTE_MEM
		  free(entryList.entryIdList);
#endif
		  goto delete_fail;
		}
		entryId = SvPV((*fetch_entry), na);
		strcpy(entryList.entryIdList[i], entryId);
	      }
	    } else {
	      /* invalid input */
	      ARError_add(AR_RETURN_ERROR, AP_ERR_EID_TYPE);
	      RETVAL=-1;
	      goto delete_fail;
	    }
	  } else if (SvOK(entry_id)) {
	    /* single scalar entry_id */
	    entryList.numItems = 1;
	    entryList.entryIdList = mallocnn(sizeof(AREntryIdType));
	    strcpy(entryList.entryIdList[0], SvPV(entry_id, na));
	  } else {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EID);
	    goto delete_fail;
	  }
	  ret = ARDeleteEntry(ctrl, schema, &entryList, 0, &status);
#ifndef WASTE_MEM
	  free(entryList.entryIdList);
#endif
#else /* ARS 2 */
	  RETVAL=-1; /* assume error */
	  entryId = SvPV(entry_id, na);
	  ret = ARDeleteEntry(ctrl, schema, entryId, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError(ret, status))
	    RETVAL=-1;
	  else
	    RETVAL=0;
	  
	  delete_fail:;
	}
	OUTPUT:
	RETVAL

void
ars_GetEntry(ctrl,schema,entry_id,...)
	ARControlStruct *	ctrl
	char *			schema
	SV *			entry_id
	PPCODE:
	{
	  int c = items - 3, i, ret;
	  ARInternalIdList  idList;
	  ARFieldValueList  fieldList;
	  ARStatusList      status;
	  char *entryId;
#if AR_EXPORT_VERSION >= 3
	  SV **fetch_entry;
	  AREntryIdList entryList;
	  AV *input_list;
#endif

	  ARError_reset();
	  if (c < 1) {
	    idList.numItems = 0; /* get all fields */
	  } else {
	    idList.numItems = c;
	    if (!(idList.internalIdList = mallocnn(sizeof(ARInternalId) * c)))
	      goto get_entry_end;
	    for (i=0; i<c; i++)
	      idList.internalIdList[i] = SvIV(ST(i+3));
	  }
#if AR_EXPORT_VERSION >= 3
	  /* build entryList */
	  if (SvROK(entry_id)) {
	    if (SvTYPE(input_list = (AV *)SvRV(entry_id)) == SVt_PVAV) {
	      /* reference to array of entry ids */
	      entryList.numItems = av_len(input_list) + 1;
	      entryList.entryIdList = mallocnn(sizeof(AREntryIdType) *
					       entryList.numItems);
	      for (i=0; i<entryList.numItems; i++) {
		fetch_entry = av_fetch(input_list, i, 0);
		if (! fetch_entry) {
		  ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EID);
#ifndef WASTE_MEM
		  free(entryList.entryIdList);
#endif
		  goto get_entry_end;
		}
		entryId = SvPV((*fetch_entry), na);
		strcpy(entryList.entryIdList[i], entryId);
	      }
	    } else {
	      /* invalid input */
	      ARError_add(AR_RETURN_ERROR, AP_ERR_EID_TYPE);
	      goto get_entry_end;
	    }
	  } else if (SvOK(entry_id)) {
	    /* single scalar entry_id */
	    entryList.numItems = 1;
	    entryList.entryIdList = mallocnn(sizeof(AREntryIdType));
	    strcpy(entryList.entryIdList[0], SvPV(entry_id, na));
	  } else {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EID);
	    goto get_entry_end;
	  }
	  ret = ARGetEntry(ctrl, schema, &entryList, &idList, &fieldList, &status);
#ifndef WASTE_MEM
	  free(entryList.entryIdList);
#endif
#else /* ARS 2 */
	  entryId = SvPV(entry_id, na);
	  ret = ARGetEntry(ctrl, schema, entryId, &idList, &fieldList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError(ret, status)) {
#ifndef WASTE_MEM
	    FreeARInternalIdList(&idList, FALSE);
#endif
	    goto get_entry_end;
	  }
	  
	  if(fieldList.numItems < 1) {
#ifndef WASTE_MEM
	    FreeARInternalIdList(&idList, FALSE);
#endif
	    goto get_entry_end;
 	  }
	  for (i=0; i<fieldList.numItems; i++) {
	    XPUSHs(newSViv(fieldList.fieldValueList[i].fieldId));
	    XPUSHs(perl_ARValueStruct(&fieldList.fieldValueList[i].value));
	  }
#ifndef WASTE_MEM
	  FreeARInternalIdList(&idList, FALSE);
	  FreeARFieldValueList(&fieldList,FALSE);
#endif
	get_entry_end:;
	}

void
ars_GetListEntry(ctrl,schema,qualifier,maxRetrieve,...)
	ARControlStruct *	ctrl
	char *			schema
	ARQualifierStruct *	qualifier
	int			maxRetrieve
	PPCODE:
	{
	  int c = (items - 4) / 2, i;
	  int field_off = 4;
	  ARSortList sortList;
	  AREntryListList entryList;
	  unsigned int num_matches;
	  ARStatusList status;
	  int ret;
#if AR_EXPORT_VERSION >= 3
	  AREntryListFieldList getListFields, *getList = NULL;
	  AV *getListFields_array;

	  ARError_reset();	  
	  if ((items - 4) % 2) {
	    /* odd number of arguments, so argument after maxRetrieve is
	       optional getListFields (an array of hash refs) */
	    if (SvROK(ST(field_off)) &&
		(getListFields_array = (AV *)SvRV(ST(field_off))) &&
		SvTYPE(getListFields_array) == SVt_PVAV) {
	      getList = &getListFields;
	      getListFields.numItems = av_len(getListFields_array) + 1;
	      getListFields.fieldsList = mallocnn(sizeof(AREntryListFieldStruct) * getListFields.numItems);
	      /* set query field list */
	      for (i=0; i<getListFields.numItems; i++) {
		SV **array_entry, **hash_entry;
		HV *field_hash;
		/* get hash from array */
		if ((array_entry = av_fetch(getListFields_array, i, 0)) &&
		    SvROK(*array_entry) &&
		    SvTYPE(field_hash = (HV*)SvRV(*array_entry)) == SVt_PVHV) {
		  /* get fieldId, columnWidth and separator from hash */
		  if (! (hash_entry = hv_fetch(field_hash, "fieldId", 7, 0))) {
		    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
#ifndef WASTE_MEM
		    free(getListFields.fieldsList);
#endif
		    goto getlistentry_end;
		  }
		  getListFields.fieldsList[i].fieldId = SvIV(*hash_entry);
		  /* printf("field_id: %i\n", getListFields.fieldsList[i].fieldId); */ /* DEBUG */
		  if (! (hash_entry = hv_fetch(field_hash, "columnWidth", 11, 0))) {
		    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
#ifndef WASTE_MEM
		    free(getListFields.fieldsList);
#endif
		    goto getlistentry_end;
		  }
		  getListFields.fieldsList[i].columnWidth = SvIV(*hash_entry);
		  if (! (hash_entry = hv_fetch(field_hash, "separator", 9, 0))) {
		    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
#ifndef WASTE_MEM
		    free(getListFields.fieldsList);
#endif
		    goto getlistentry_end;
		  }
		  strncpy(getListFields.fieldsList[i].separator,
			  SvPV(*hash_entry, na),
			  sizeof(getListFields.fieldsList[i].separator));
		}
	      }
	    } else {
	      ARError_add(AR_RETURN_ERROR, AP_ERR_LFLDS_TYPE);
	      goto getlistentry_end;
	    }
	    /* increase the offset of the first sortList field by one */
	    field_off ++;
	  }
#else  /* ARS 2 */
	  if ((items - 4) % 2) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	    goto getlistentry_end;
	  }
#endif /* if ARS >= 3 */
	  /* build sortList */
	  sortList.numItems = c;
	  sortList.sortList = mallocnn(sizeof(ARSortStruct)*c);
	  for (i=0; i<c; i++) {
	    sortList.sortList[i].fieldId = SvIV(ST(i*2+field_off));
	    sortList.sortList[i].sortOrder = SvIV(ST(i*2+field_off+1));
	  }
#if AR_EXPORT_VERSION >= 3
	  /* printf("getlist: %x\n", getList); */ /* DEBUG */
	  ret = ARGetListEntry(ctrl, schema, qualifier, getList, &sortList, maxRetrieve, &entryList, &num_matches, &status);
#else
	  ret = ARGetListEntry(ctrl, schema, qualifier, &sortList, maxRetrieve, &entryList, &num_matches, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError(ret, status)) {
#ifndef WASTE_MEM
	    FreeARSortList(&sortList,FALSE);
#endif
	    goto getlistentry_end;
	  }
	  for (i=0; i<entryList.numItems; i++) {
#if AR_EXPORT_VERSION >= 3
	    AV *entryIdList;
	    
	    if (entryList.entryList[i].entryId.numItems == 1) {
	      /* only one entryId -- so just return its value to be compatible
		 with ars 2 */
	      XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].entryId.entryIdList[0], 0)));
	    } else {
	      /* more than one entry -- we have to return a reference to an
		 array */
	      int entry;
	      entryIdList = newAV();
	      
	      for (entry=0; entry<entryList.entryList[i].entryId.numItems; entry++) {
		av_store(entryIdList, entry, newSVpv(entryList.entryList[i].entryId.entryIdList[entry], 0));
	      }
	      XPUSHs(sv_2mortal(newRV((SV *)entryIdList)));
	    }
#else /* ARS 2 */
	    XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].entryId, 0)));
#endif
	    XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].shortDesc, 0)));
	  }
#ifndef WASTE_MEM
	  FreeAREntryListList(&entryList,FALSE);
#endif
	  getlistentry_end:;
	}

void
ars_GetListSchema(ctrl,changedsince=0,...)
	ARControlStruct *	ctrl
	unsigned int		changedsince
	PPCODE:
	{
	  ARNameList nameList;
	  ARStatusList status;
	  int i, ret;
#if AR_EXPORT_VERSION >= 3
	  unsigned int schemaType=AR_LIST_SCHEMA_ALL;
	  char *name=NULL;

	  ARError_reset();	  
	  /* fetch optional arguments schemaType and name */
	  if (items == 3 || items == 4)
	    schemaType = SvIV(ST(2));
	  if (items == 4)
	    name = SvPV(ST(3), na);
	  ret = ARGetListSchema(ctrl, changedsince, schemaType, name, &nameList, &status);
#else
	  if (items != 2 && items != 1) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_USAGE, "Usage: ars_GetListSchema(ctrl, changedSince=0)");
	    goto getListSchema_end;
	  }
	  ret = ARGetListSchema(ctrl, changedsince, &nameList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError(ret, status)) {
	    for (i=0; i<nameList.numItems; i++) {
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    }
#ifndef WASTE_MEM
	    FreeARNameList(&nameList,FALSE);
#endif
	  }
	getListSchema_end:;
	}

void
ars_GetListServer()
	PPCODE:
	{
	  ARServerNameList serverList;
	  ARStatusList status;
	  int i, ret;

	  ARError_reset();	  
	  ret = ARGetListServer(&serverList, &status);
	  if (! ARError(ret, status)) {
	    for (i=0; i<serverList.numItems; i++) {
	      XPUSHs(sv_2mortal(newSVpv(serverList.nameList[i], 0)));
	    }
#ifndef WASTE_MEM
	    FreeARServerNameList(&serverList,FALSE);
#endif
	  }
	}

HV *
ars_GetActiveLink(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  int ret;
	  unsigned int order;
	  ARNameType schema;
	  ARInternalIdList groupList;
	  unsigned int executeMask;
#if AR_EXPORT_VERSION >= 3
	  ARInternalId controlField;
	  ARInternalId focusField;
#else	  
	  ARInternalId field;
	  ARDisplayList displayList;
#endif
	  unsigned int enable;
	  ARQualifierStruct *query=mallocnn(sizeof(ARQualifierStruct));
	  ARActiveLinkActionList actionList;
#if  AR_EXPORT_VERSION >= 3
	  ARActiveLinkActionList elseList;
#endif
	  char *helpText;
	  ARTimestamp timestamp;
	  ARNameType owner;
	  ARNameType lastChanged;
	  char *changeDiary;
	  ARStatusList status;
	  SV *ref;

	  ARError_reset();
#if  AR_EXPORT_VERSION >= 3
	  ret = ARGetActiveLink(ctrl,name,&order,schema,&groupList,&executeMask,&controlField,&focusField,&enable,query,&actionList,&elseList,&helpText,&timestamp,owner,lastChanged,&changeDiary,&status);
#else
	  ret = ARGetActiveLink(ctrl,name,&order,schema,&groupList,&executeMask,&field,&displayList,&enable,query,&actionList,&helpText,&timestamp,owner,lastChanged,&changeDiary,&status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  RETVAL = newHV();
	  if (!ARError(ret,status)) {
	    /* store name of active link */
	    hv_store(RETVAL, "name", strlen("name"),
		     newSVpv(name, 0), 0);
	    hv_store(RETVAL, "order", strlen("order"),
		     newSViv(order),0);
	    hv_store(RETVAL, "schema", strlen("schema"),
		     newSVpv(schema,0),0);
	    hv_store(RETVAL, "groupList", strlen("groupList"),
		     perl_ARList((ARList *)&groupList,
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)), 0);
	    hv_store(RETVAL, "executeMask", strlen("executeMask"),
		     newSViv(executeMask),0);
#if  AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, "focusField", strlen("focusField"),
		     newSViv(focusField), 0);
	    hv_store(RETVAL, "controlField", strlen("controlField"),
		     newSViv(controlField), 0);
#else
	    hv_store(RETVAL, "field", strlen("field"),
		     newSViv(field), 0);
	    hv_store(RETVAL, "displayList", strlen("displayList"),
		     perl_ARList((ARList *)&displayList,
				 (ARS_fn)perl_ARDisplayStruct,
				 sizeof(ARDisplayStruct)), 0);
#endif
	    hv_store(RETVAL, "enable", strlen("enable"),
		     newSViv(enable), 0);
	    /* a bit of a hack -- makes blessed reference to qualifier */
	    ref = newSViv(0);
	    sv_setref_pv(ref, "ARQualifierStructPtr", (void*)query);
	    hv_store(RETVAL, "query", strlen("query"),
		     ref, 0);
	    hv_store(RETVAL, "actionList", strlen("actionList"),
		     perl_ARList((ARList *)&actionList,
				 (ARS_fn)perl_ARActiveLinkActionStruct,
				 sizeof(ARActiveLinkActionStruct)), 0);
#if  AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, "elseList", strlen("elseList"),
		     perl_ARList((ARList *)&elseList,
				 (ARS_fn)perl_ARActiveLinkActionStruct,
				 sizeof(ARActiveLinkActionStruct)), 0);
#endif
	    if (helpText)
	      hv_store(RETVAL, "helpText", strlen("helpText"),
		       newSVpv(helpText,0), 0);
	    hv_store(RETVAL, "timestamp", strlen("timestamp"),
		     newSViv(timestamp), 0);
	    hv_store(RETVAL, "owner", strlen("owner"),
		     newSVpv(owner,0), 0);
	    hv_store(RETVAL, "lastChanged", strlen("lastChanged"),
		     newSVpv(lastChanged,0), 0);
	    if (changeDiary)
	      hv_store(RETVAL, "changeDiary", strlen("changeDiary"),
		       newSVpv(changeDiary,0), 0);
#ifndef WASTE_MEM
	    FreeARInternalIdList(&groupList,FALSE);
#if  AR_EXPORT_VERSION < 3
	    FreeARDisplayList(&displayList,FALSE);
#endif
	    FreeARActiveLinkActionList(&actionList,FALSE);
#if  AR_EXPORT_VERSION >= 3
	    FreeARActiveLinkActionList(&elseList,FALSE);
#endif
	    if(helpText)
	      free(helpText);
	    if(changeDiary)
	      free(changeDiary);
#endif
	  }
	}
	OUTPUT:
	RETVAL

HV *
ars_GetFilter(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  int ret;
	  unsigned int order;
	  unsigned int opSet;
	  ARNameType schema;
	  unsigned int enable;
	  char *helpText;
	  char *changeDiary;
	  ARQualifierStruct *query=mallocnn(sizeof(ARQualifierStruct));
	  ARFilterActionList actionList;
#if  AR_EXPORT_VERSION >= 3
	  ARFilterActionList elseList;
#endif
	  ARTimestamp timestamp;
	  ARNameType owner;
	  ARNameType lastChanged;
	  ARStatusList status;
	  SV *ref;

	  ARError_reset();
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetFilter(ctrl, name, &order, schema, &opSet, &enable, 
			    query, &actionList, &elseList, &helpText,
			    &timestamp, owner, lastChanged, &changeDiary,
			    &status);
#else
	  ret = ARGetFilter(ctrl, name, &order, schema, &opSet, &enable, 
			    query, &actionList, &helpText, &timestamp, 
			    owner, lastChanged, &changeDiary, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  RETVAL = newHV();
	  if (!ARError(ret,status)) {
	    hv_store(RETVAL, "name", strlen("name"),
		     newSVpv(name, 0), 0);
	    hv_store(RETVAL, "order", strlen("order"),
		     newSViv(order), 0);
	    hv_store(RETVAL, "schema", strlen("schema"),
		     newSVpv(schema, 0), 0);
	    hv_store(RETVAL, "opSet", strlen("opSet"),
		     newSViv(opSet), 0);
	    hv_store(RETVAL, "enable", strlen("enable"),
		     newSViv(enable), 0);
	    /* a bit of a hack -- makes blessed reference to qualifier */
	    ref = newSViv(0);
	    sv_setref_pv(ref, "ARQualifierStructPtr", (void *)query);
	    hv_store(RETVAL, "query", strlen("query"), ref, 0);
	    hv_store(RETVAL, "actionList", strlen("actionList"),
		     perl_ARList((ARList *)&actionList,
				 (ARS_fn)perl_ARFilterActionStruct,
				 sizeof(ARFilterActionStruct)), 0);
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, "elseList", strlen("elseList"),
		     perl_ARList((ARList *)&elseList,
				 (ARS_fn)perl_ARFilterActionStruct,
				 sizeof(ARFilterActionStruct)), 0);
#endif
	    if(helpText)
		hv_store(RETVAL, "helpText", strlen("helpText"),
			 newSVpv(helpText, 0), 0);
	    hv_store(RETVAL, "timestamp", strlen("timestamp"),
		     newSViv(timestamp), 0);
	    hv_store(RETVAL, "owner", strlen("owner"),
		     newSVpv(owner, 0), 0);
	    hv_store(RETVAL, "lastChanged", strlen("lastChanged"),
		     newSVpv(lastChanged, 0), 0);
	    if(changeDiary) 
		hv_store(RETVAL, "changeDiary", strlen("changeDiary"),
			newSVpv(changeDiary, 0), 0);
#ifndef WASTE_MEM
	    FreeARFilterActionList(&actionList,FALSE);
#if AR_EXPORT_VERSION >= 3
	    FreeARFilterActionList(&elseList,FALSE);
#endif
	    if(helpText)
	      free(helpText);
	    if(changeDiary)
	      free(changeDiary);
#endif
	  }
	}
	OUTPUT:
	RETVAL

void
ars_GetServerStatistics(ctrl,...)
	ARControlStruct *	ctrl
	PPCODE:
	{
	  ARServerInfoRequestList requestList;
	  ARServerInfoList serverInfo;
	  int i, ret;
	  ARStatusList status;

	  ARError_reset();
	  if(items < 1) {
		ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {
		requestList.numItems = items - 1;
		requestList.requestList = mallocnn(sizeof(unsigned int) * (items-1));
		if(requestList.requestList) {
			for(i=1; i<items; i++) {
				requestList.requestList[i-1] = SvIV(ST(i));
			}
			ret = ARGetServerStatistics(ctrl, &requestList, &serverInfo, &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if(ARError(ret, status)) {
#ifndef WASTE_MEM
				free(requestList.requestList);
#endif
			} else {
				for(i=0; i<serverInfo.numItems; i++) {
					XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[i].operation)));
					switch(serverInfo.serverInfoList[i].value.dataType) {
					case AR_DATA_TYPE_ENUM:
					case AR_DATA_TYPE_TIME:
					case AR_DATA_TYPE_BITMASK:
					case AR_DATA_TYPE_INTEGER:
						XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[i].value.u.intVal)));
						break;
					case AR_DATA_TYPE_REAL:
						XPUSHs(sv_2mortal(newSVnv(serverInfo.serverInfoList[i].value.u.realVal)));
						break;
					case AR_DATA_TYPE_CHAR:
						XPUSHs(sv_2mortal(newSVpv(serverInfo.serverInfoList[i].value.u.charVal,
							strlen(serverInfo.serverInfoList[i].value.u.charVal))));
						break;
					}
				}
#ifndef WASTE_MEM
				FreeARServerInfoList(&serverInfo, FALSE);
				free(requestList.requestList);
#endif
			}
		} else {
			ARError_add(AR_RETURN_ERROR, AP_ERR_MALLOC);
		} 
	  }
	}

HV *
ars_GetCharMenu(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  unsigned int       refreshCode;
	  ARCharMenuStruct   menuDefn;
	  char	            *helpText;
	  ARTimestamp	     timestamp;
	  ARNameType	     owner;
	  ARNameType	     lastChanged;
	  char		    *changeDiary;
	  ARStatusList	     status;
	  int                ret;
	  HV		    *menuDef = newHV();
	  SV		    *ref;

	  ARError_reset();
	  RETVAL = newHV();
	  ret = ARGetCharMenu(ctrl, name, &refreshCode, &menuDefn, &helpText, &timestamp, owner, lastChanged, &changeDiary, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError(ret, status)) {
		hv_store(RETVAL, "name", strlen("name"),
				newSVpv(name, 0), 0);
		if(helpText)
			hv_store(RETVAL, "helpText", strlen("helpText"),
				newSVpv(helpText,0), 0);
		hv_store(RETVAL, "timestamp", strlen("timestamp"),
			newSViv(timestamp), 0);
		hv_store(RETVAL, "owner", strlen("owner"),
			newSVpv(owner, 0), 0);
		hv_store(RETVAL, "lastChanged", strlen("lastChanged"),
			newSVpv(lastChanged, 0), 0);
		if(changeDiary)
			hv_store(RETVAL, "changeDiary", strlen("changeDiary"),
				newSVpv(changeDiary, 0), 0);
		hv_store(RETVAL, "menuType", strlen("menuType"),
			newSViv(menuDefn.menuType), 0);
		switch(menuDefn.menuType) {
		case AR_CHAR_MENU_QUERY:
			hv_store(menuDef, "schema", strlen("schema"),
				newSVpv(menuDefn.u.menuQuery.schema, 0), 0);
			hv_store(menuDef, "server", strlen("server"),
				newSVpv(menuDefn.u.menuQuery.server, 0), 0);
			hv_store(menuDef, "labelField", strlen("labelField"),
				newSViv(menuDefn.u.menuQuery.labelField), 0);
			hv_store(menuDef, "valueField", strlen("valueField"),
				newSViv(menuDefn.u.menuQuery.valueField), 0);
			hv_store(menuDef, "sortOnLabel", strlen("sortOnLabel"),
				newSViv(menuDefn.u.menuQuery.sortOnLabel), 0);
			ref = newSViv(0);
			sv_setref_pv(ref, "ARQualifierStructPtr", (void *)&(menuDefn.u.menuQuery.qualifier));
			hv_store(RETVAL, "qualifier", strlen("qualifier"), ref, 0);
			hv_store(RETVAL, "menuQuery", strlen("menuQuery"),
				newRV((SV *)menuDef), 0);
			break;
		case AR_CHAR_MENU_FILE:
			hv_store(menuDef, "fileLocation", strlen("fileLocation"),
				newSViv(menuDefn.u.menuFile.fileLocation), 0);
			hv_store(menuDef, "filename", strlen("filename"),
				newSVpv(menuDefn.u.menuFile.filename, 0), 0);
			hv_store(RETVAL, "menuFile", strlen("menuFile"),
				newRV((SV *)menuDef), 0);
			break;
#ifndef ARS20
		case AR_CHAR_MENU_SQL:
			hv_store(menuDef, "server", strlen("server"),
				newSVpv(menuDefn.u.menuSQL.server, 0), 0);
			hv_store(menuDef, "sqlCommand", strlen("sqlCommand"),
				newSVpv(menuDefn.u.menuSQL.sqlCommand, 0), 0);
			hv_store(menuDef, "labelIndex", strlen("labelIndex"),
				newSViv(menuDefn.u.menuSQL.labelIndex), 0);
			hv_store(menuDef, "valueIndex", strlen("valueIndex"),
				newSViv(menuDefn.u.menuSQL.valueIndex), 0);
			hv_store(RETVAL, "menuSQL", strlen("menuSQL"),
				newRV((SV *)menuDef), 0);
			break;
#endif
		}
#ifndef WASTE_MEM
		FreeARCharMenuStruct(&menuDefn, FALSE);
		if(helpText) free(helpText);
#endif
	  }
	}
	OUTPUT:
	RETVAL

void
ars_GetCharMenuItems(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARCharMenuStruct menuDefn;
      	  ARStatusList status;
	  int ret;

	  ARError_reset();
	  ret = ARGetCharMenu(ctrl, name, NULL, &menuDefn, NULL, NULL, NULL, NULL, NULL, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError(ret,status)) {
	    ST(0) = sv_2mortal(perl_expandARCharMenuStruct(ctrl, &menuDefn));
#ifndef WASTE_MEM
	    FreeARCharMenuStruct(&menuDefn,FALSE);
#endif
	  } else {
	    ST(0) = &sv_undef;
	  }
	}

HV *
ars_GetSchema(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList status;
	  int ret;
#if AR_EXPORT_VERSION >= 3
	  ARPermissionList groupList;
#else
	  ARInternalIdList groupList;
#endif
	  ARInternalIdList adminGroupList;
	  AREntryListFieldList getListFields;
	  ARIndexList indexList;
	  char *helpText;
	  ARTimestamp timestamp;
	  ARNameType owner;
	  ARNameType lastChanged;
	  char *changeDiary;
#if AR_EXPORT_VERSION >= 3
	  ARCompoundSchema schema;
	  ARSortList sortList;
#endif

	  ARError_reset();
	  RETVAL = newHV();
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetSchema(ctrl, name, &schema, &groupList, &adminGroupList, &getListFields, &sortList, &indexList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &status);
#else
	  ret = ARGetSchema(ctrl, name, &groupList, &adminGroupList, &getListFields, &indexList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (!ARError(ret,status)) {
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, "groupList", 9,
		     perl_ARPermissionList(&groupList), 0);
#else
	    hv_store(RETVAL, "groupList", strlen("groupList"),
		     perl_ARList((ARList *)&groupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
#endif
	    hv_store(RETVAL, "adminList", strlen("adminList"),
		     perl_ARList((ARList *)&groupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
	    hv_store(RETVAL, "getListFields", strlen("getListFields"),
		     perl_ARList((ARList *)&getListFields,
				 (ARS_fn)perl_AREntryListFieldStruct,
				 sizeof(AREntryListFieldStruct)),0);
	    hv_store(RETVAL, "indexList", strlen("indexList"),
		     perl_ARList((ARList *)&indexList,
				 (ARS_fn)perl_ARIndexStruct,
				 sizeof(ARIndexStruct)), 0);
	    if (helpText)
	      hv_store(RETVAL, "helpText", strlen("helpText"),
		       newSVpv(helpText, 0), 0);
	    hv_store(RETVAL, "timestamp", strlen("timestamp"),
		     newSViv(timestamp), 0);
	    hv_store(RETVAL, "owner", strlen("owner"),
		     newSVpv(owner, 0), 0);
	    hv_store(RETVAL, "lastChanged", strlen("lastChanged"),
		     newSVpv(lastChanged, 0), 0);
	    if (changeDiary)
	      hv_store(RETVAL, "changeDiary", strlen("changeDiary"),
		       newSVpv(changeDiary, 0), 0);
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, "schema", 6, perl_ARCompoundSchema(&schema), 0);
	    hv_store(RETVAL, "sortList", 8, perl_ARSortList(&sortList), 0);
#endif
#ifndef WASTE_MEM
#if AR_EXPORT_VERSION >= 3
	    FreeARPermissionList(&groupList,FALSE);
#else
	    FreeARInternalIdList(&groupList,FALSE);
#endif
	    FreeARInternalIdList(&adminGroupList,FALSE);
	    FreeAREntryListFieldList(&getListFields,FALSE);
	    FreeARIndexList(&indexList,FALSE);
	    if(helpText)
	      free(helpText);
	    if(changeDiary)
	      free(changeDiary);
#if AR_EXPORT_VERSION >= 3
	    FreeARCompoundSchema(&schema,FALSE);
	    FreeARSortList(&sortList,FALSE);
#endif
#endif
	  }
	}
	OUTPUT:
	RETVAL

void
ars_GetListActiveLink(ctrl,schema=NULL,changedSince=0)
	ARControlStruct *	ctrl
	char *			schema
	int			changedSince
	PPCODE:
	{
	  ARNameList nameList;
	  ARStatusList status;
	  int ret, i;

	  ARError_reset();
	  ret=ARGetListActiveLink(ctrl,schema,changedSince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError(ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i],0)));
#ifndef WASTE_MEM
	    FreeARNameList(&nameList,FALSE);
#endif
	  }
	}

HV *
ars_GetField(ctrl,schema,id)
	ARControlStruct *	ctrl
	char *			schema
	unsigned long		id
	CODE:
	{
	  int ret;
	  ARStatusList Status;
	  unsigned int dataType, option, createMode;
	  ARValueStruct defaultVal;
	  ARPermissionList permissions;
	  ARFieldLimitStruct limit;
#if AR_EXPORT_VERSION >= 3
	  ARNameType fieldName;
	  ARFieldMappingStruct fieldMap;
	  ARDisplayInstanceList displayList;
#else
	  ARDisplayList displayList;
#endif
	  char *helpText;
	  ARTimestamp timestamp;
	  ARNameType owner;
	  ARNameType lastChanged;
	  char *changeDiary;
	  
	  ARError_reset();
	  RETVAL = newHV();
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetFieldCached(ctrl, schema, id, fieldName, &fieldMap, &dataType, &option, &createMode, &defaultVal, NULL /* &permissions */, &limit, &displayList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &Status);
#else
	  ret = ARGetFieldCached(ctrl, schema, id, &dataType, &option, &createMode, &defaultVal, NULL /* &permissions */, &limit, &displayList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &Status);
#endif
	  if (! ARError(ret, Status)) {
	    /* store field id for convenience */
	    hv_store(RETVAL, "fieldId", strlen("fieldId"),
		     newSViv(id), 0);
	    if (createMode == AR_FIELD_OPEN_AT_CREATE)
	      hv_store(RETVAL, "createMode", strlen("createMode"),
		       newSVpv("open",0), 0);
	    else
	      hv_store(RETVAL, "createMode", strlen("createMode"),
		       newSVpv("protected",0), 0);
	    hv_store(RETVAL, "option", strlen("option"),
		     newSViv(option), 0);
	    hv_store(RETVAL, "dataType", strlen("dataType"),
		     perl_dataType_names(&dataType), 0);
	    hv_store(RETVAL, "defaultVal", strlen("defaultVal"),
		     perl_ARValueStruct(&defaultVal), 0);
	    /* permissions below */
	    hv_store(RETVAL, "limit", strlen("limit"),
		     perl_ARFieldLimitStruct(&limit), 0);
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, "fieldName", strlen("fieldName"),
		     newSVpv(fieldName, 0), 0);
	    hv_store(RETVAL, "fieldMap", strlen("fieldMap"),
		     perl_ARFieldMappingStruct(&fieldMap), 0);
	    hv_store(RETVAL, "displayInstanceList",
		     strlen("displayInstanceList"),
		     perl_ARDisplayInstanceList(&displayList), 0);
#else
	    hv_store(RETVAL, "displayList", strlen("displayList"),
		     perl_ARList((ARList *)&displayList,
				 (ARS_fn)perl_ARDisplayStruct,
				 sizeof(ARDisplayStruct)), 0);
#endif
	    if (helpText)
	      hv_store(RETVAL, "helpText", strlen("helpText"),
		       newSVpv(helpText, 0), 0);
	    hv_store(RETVAL, "timestamp", strlen("timestamp"),
		     newSViv(timestamp), 0);
	    hv_store(RETVAL, "owner", strlen("owner"),
		     newSVpv(owner, 0), 0);
	    hv_store(RETVAL, "lastChanged", strlen("lastChanged"),
		     newSVpv(lastChanged, 0), 0);
	    if (changeDiary)
	      hv_store(RETVAL, "changeDiary", strlen("changeDiary"),
		       newSVpv(changeDiary, 0), 0);
#ifndef WASTE_MEM
	    FreeARFieldLimitStruct(&limit,FALSE);
#if AR_EXPORT_VERSION >= 3
	    /* FreeARFieldMappingStruct(&fieldMap,FALSE); *//* doesnt exist! */
	    FreeARDisplayInstanceList(&displayList,FALSE);
#else
	    FreeARDisplayList(&displayList,FALSE);
#endif
	    if(helpText)
	      free(helpText);
	    if(changeDiary)
	      free(changeDiary);
#endif
#if AR_EXPORT_VERSION >= 3
	    ret = ARGetField(ctrl, schema, id, NULL, NULL, NULL, NULL, NULL, NULL, &permissions, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &Status);
#else
	    ret = ARGetField(ctrl, schema, id, NULL, NULL, NULL, NULL, &permissions, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &Status);
#endif
	    if (ret == 0) {
	      hv_store(RETVAL, "permissions", strlen("permissions"), perl_ARPermissionList(&permissions), 0);
#ifndef WASTE_MEM
	      FreeARPermissionList(&permissions,FALSE);
#endif
            } else {
#ifndef WASTE_MEM
	      /* We don't call ARError, so free status list manually */
	      FreeARStatusList(&Status, FALSE);
#endif
            } 
	  }
	}
	OUTPUT:
	RETVAL

int
ars_SetEntry(ctrl,schema,entry_id,getTime,...)
	ARControlStruct *	ctrl
	char *			schema
	SV *			entry_id
	unsigned long		getTime
	CODE:
	{
	  int a, i, c = (items - 4) / 2, j;
	  int offset = 4;
	  ARFieldValueList fieldList;
	  ARStatusList status;
	  int ret;
	  unsigned int dataType;
	  char *entryId;
#if AR_EXPORT_VERSION >= 3
	  unsigned int option = AR_JOIN_SETOPTION_NONE;
	  SV **fetch_entry;
	  AREntryIdList entryList;
	  AV *input_list;

	  ARError_reset();
	  RETVAL = 0; /* assume error */
	  if ((items - 4) % 2) {
	    option = SvIV(ST(offset));
	    offset ++;
	  }
	  if (c < 1) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	    goto set_entry_exit;
	  }
#else
	  ARError_reset();
	  RETVAL = 0; /* assume error */
	  if (((items - 4) % 2) || c < 1) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	    goto set_entry_exit;
	  }
#endif
	  fieldList.numItems = c;
	  fieldList.fieldValueList = mallocnn(sizeof(ARFieldValueStruct)*c);
	  for (i=0; i<c; i++) {
	    a = i*2+offset;
	    fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
	    
	    if (! SvOK(ST(a+1))) {
	      /* pass a NULL */
	      fieldList.fieldValueList[i].value.dataType = AR_DATA_TYPE_NULL;
	    } else {
	      /* determine data type and pass value */
#if AR_EXPORT_VERSION >= 3
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, NULL, NULL, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#endif
	      if (ARError(ret, status)) {
		goto set_entry_end;
	      }
	      if (sv_to_ARValue(ST(a+1), dataType, &fieldList.fieldValueList[i].value) < 0) {
#ifndef WASTE_MEM
		for (j=0; j<i; j++) {
		  FreeARValueStruct(&fieldList.fieldValueList[j].value, FALSE);
		}
#endif
		goto set_entry_end;
	      }
	    }
	  }
#if AR_EXPORT_VERSION >= 3
	  /* build entryList */
	  if (SvROK(entry_id)) {
	    if (SvTYPE(input_list = (AV *)SvRV(entry_id)) == SVt_PVAV) {
	      /* reference to array of entry ids */
	      entryList.numItems = av_len(input_list) + 1;
	      entryList.entryIdList = mallocnn(sizeof(AREntryIdType) *
					       entryList.numItems);
	      for (i=0; i<entryList.numItems; i++) {
		fetch_entry = av_fetch(input_list, i, 0);
		if (! fetch_entry) {
		  ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EID);
#ifndef WASTE_MEM
		  free(entryList.entryIdList);
#endif
		  goto set_entry_exit;
		}
		entryId = SvPV((*fetch_entry), na);
		strcpy(entryList.entryIdList[i], entryId);
	      }
	    } else {
	      /* invalid input */
	      ARError_add(AR_RETURN_ERROR, AP_ERR_EID_TYPE);
	      goto set_entry_exit;
	    }
	  } else if (SvOK(entry_id)) {
	    /* single scalar entry_id */
	    entryList.numItems = 1;
	    entryList.entryIdList = mallocnn(sizeof(AREntryIdType));
	    strcpy(entryList.entryIdList[0], SvPV(entry_id, na));
	  } else {
	    goto set_entry_exit;
	  }
	  ret = ARSetEntry(ctrl, schema, &entryList, &fieldList, getTime, option, &status);
#ifndef WASTE_MEM
	  free(entryList.entryIdList);
#endif	  
#else
	  entryId = SvPV(entry_id, na);
	  ret = ARSetEntry(ctrl, schema, SvPV(entry_id, na), &fieldList, getTime, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError(ret, status)) {
	    RETVAL = 1;
	  }
#ifndef WASTE_MEM
	  for (j=0; j<c; j++) {
	    FreeARValueStruct(&fieldList.fieldValueList[j].value, FALSE);
	  }
#endif
	set_entry_end:;
#ifndef WASTE_MEM
	  free(fieldList.fieldValueList);
#endif
	set_entry_exit:;
	}
	OUTPUT:
	RETVAL

void
ars_Export(ctrl,displayTag,...)
	ARControlStruct *	ctrl
	char *			displayTag
	PPCODE:
	{
	  int ret, i, a, c = (items - 2) / 2;
	  ARStructItemList structItems;
	  char *buf;
	  ARStatusList status;
	  
	  ARError_reset();
	  if (items % 2 || c < 1) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {
	    structItems.numItems = c;
	    structItems.structItemList = mallocnn(sizeof(ARStructItemStruct)*c);
	    for (i=0; i<c; i++) {
	      a = i*2+2;
	      if (strcmp(SvPV(ST(a),na),"Schema")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_SCHEMA;
	      else if (strcmp(SvPV(ST(a),na),"Schema_Defn")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_SCHEMA_DEFN;
	      else if (strcmp(SvPV(ST(a),na),"Schema_View")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_SCHEMA_VIEW;
	      else if (strcmp(SvPV(ST(a),na),"Schema_Mail")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_SCHEMA_MAIL;
	      else if (strcmp(SvPV(ST(a),na),"Filter")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_FILTER;
	      else if (strcmp(SvPV(ST(a),na),"Active_Link")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_ACTIVE_LINK;
	      else if (strcmp(SvPV(ST(a),na),"Admin_Ext")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_ADMIN_EXT;
	      else if (strcmp(SvPV(ST(a),na),"Char_Menu")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_CHAR_MENU;
	      else if (strcmp(SvPV(ST(a),na),"Escalation")==0)
		structItems.structItemList[i].type=AR_STRUCT_ITEM_ESCALATION;
	      else {
	        ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EXP);
#ifndef WASTE_MEM
		free(structItems.structItemList);
#endif
		goto export_end;
	      }
	      strncpy(structItems.structItemList[i].name,SvPV(ST(a+1),na), sizeof(ARNameType));
	      structItems.structItemList[i].name[sizeof(ARNameType)-1] = '\0';
	    }
	    ret = ARExport(ctrl, &structItems, displayTag, &buf, &status);
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (ARError(ret, status)) {
#ifndef WASTE_MEM
	      free(structItems.structItemList);
#endif
	      goto export_end;
	    }
	    XPUSHs(newSVpv(buf,0));
#ifndef WASTE_MEM
	    free(buf);
#endif
	  }
	export_end:;
	}

int
ars_Import(ctrl,importBuf,...)
	ARControlStruct *	ctrl
	char *			importBuf
	CODE:
	{
	  int ret = 1, i, a, c = (items - 2) / 2;
	  ARStructItemList *structItems = NULL;
	  ARStatusList status;

	  ARError_reset();	  
	  if (items % 2) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {
	    if (c > 0) {
	      structItems = mallocnn(sizeof(ARStructItemList));
	      structItems->numItems = c;
	      structItems->structItemList = mallocnn(sizeof(ARStructItemStruct)*c);
	      for (i=0; i<c; i++) {
		a = i*2+2;
		if (strcmp(SvPV(ST(a),na),"Schema")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_SCHEMA;
		else if (strcmp(SvPV(ST(a),na),"Schema_Defn")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_SCHEMA_DEFN;
		else if (strcmp(SvPV(ST(a),na),"Schema_View")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_SCHEMA_VIEW;
		else if (strcmp(SvPV(ST(a),na),"Schema_Mail")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_SCHEMA_MAIL;
		else if (strcmp(SvPV(ST(a),na),"Filter")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_FILTER;
		else if (strcmp(SvPV(ST(a),na),"Active_Link")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_ACTIVE_LINK;
		else if (strcmp(SvPV(ST(a),na),"Admin_Ext")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_ADMIN_EXT;
		else if (strcmp(SvPV(ST(a),na),"Char_Menu")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_CHAR_MENU;
		else if (strcmp(SvPV(ST(a),na),"Escalation")==0)
		  structItems->structItemList[i].type=AR_STRUCT_ITEM_ESCALATION;
		else {
	          ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_IMP);
#ifndef WASTE_MEM
		  free(structItems->structItemList);
		  free(structItems);
#endif
		  goto export_end;
		}
		strncpy(structItems->structItemList[i].name,SvPV(ST(a+1),na), sizeof(ARNameType));
		structItems->structItemList[i].name[sizeof(ARNameType)-1] = '\0';
	      }
	    }
	    ret = ARImport(ctrl, structItems, importBuf, &status);
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (ARError(ret, status)) {
#ifndef WASTE_MEM
	      if (structItems) {
		free(structItems->structItemList);
		free(structItems);
	      }
#endif
	      goto export_end;
	    }
	  }
	export_end:;
	  RETVAL = ! ret;
	}
	OUTPUT:
	RETVAL

void
ars_GetListFilter(control,schema=NULL,changedsince=0)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList nameList;
	  ARStatusList status;
	  int ret, i;

	  ARError_reset();
	  ret = ARGetListFilter(control,schema,changedsince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError(ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
#ifndef WASTE_MEM
	    FreeARNameList(&nameList,FALSE);
#endif
	  }
	}

void
ars_GetListEscalation(control,schema=NULL,changedsince=0)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList nameList;
	  ARStatusList status;
	  int ret, i;

	  ARError_reset();
	  ret = ARGetListEscalation(control,schema,changedsince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError(ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
#ifndef WASTE_MEM
	    FreeARNameList(&nameList,FALSE);
#endif
	  }
	}

void
ars_GetListCharMenu(control,changedsince=0)
	ARControlStruct *	control
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList nameList;
	  ARStatusList status;
	  int ret, i;

	  ARError_reset();
	  ret = ARGetListCharMenu(control,changedsince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif

	  if (!ARError(ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
#ifndef WASTE_MEM
	    FreeARNameList(&nameList,FALSE);
#endif
	  }
	}


void
ars_GetListAdminExtension(control,changedsince=0)
	ARControlStruct *	control
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList nameList;
	  ARStatusList status;
	  int ret, i;

	  ARError_reset();
	  ret = ARGetListAdminExtension(control,changedsince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError(ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
#ifndef WASTE_MEM
	    FreeARNameList(&nameList,FALSE);
#endif
	  }
	}

int
ars_DeleteActiveLink(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL=-1;
	  if(ctrl && name && *name) {
		ret = ARDeleteActiveLink(ctrl, name, &status);
		if(!ARError(ret, status)) {
			RETVAL = 0;
		}
	  } else {
		ARError_add(AR_RETURN_ERROR, AP_ERR_USAGE, "usage: ars_DeleteActiveLink(ctrl, name)");
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteAdminExtension(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL=-1;
	  if(ctrl && name && *name) {
		ret = ARDeleteAdminExtension(ctrl, name, &status);
		if(!ARError(ret, status)) {
			RETVAL = 0;
		}
	  } else {
		ARError_add(AR_RETURN_ERROR, AP_ERR_USAGE, "usage: ars_DeleteAdminExtension(ctrl, name)");
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteCharMenu(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL=-1;
	  if(ctrl && name && *name) {
		ret = ARDeleteCharMenu(ctrl, name, &status);
		if(!ARError(ret, status)) {
			RETVAL = 0;
		}
	  } else {
		ARError_add(AR_RETURN_ERROR, AP_ERR_USAGE, "usage: ars_DeleteCharMenu(ctrl, name)");
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteEscalation(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL=-1;
	  if(ctrl && name && *name) {
		ret = ARDeleteEscalation(ctrl, name, &status);
		if(!ARError(ret, status)) {
			RETVAL = 0;
		}
	  } else {
		ARError_add(AR_RETURN_ERROR, AP_ERR_USAGE, "usage: ars_DeleteEscalation(ctrl, name)");
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteField(ctrl, schema, fieldId, deleteOption=0)
	ARControlStruct *	ctrl
	char * 			schema
	ARInternalId		fieldId
	unsigned int		deleteOption
	CODE:
	{
	  ARStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL=-1;
	  if(ctrl && CVLD(schema) && IVLD(deleteOption, 0, 2)) {
		ret = ARDeleteField(ctrl, schema, fieldId, deleteOption, &status);
		if(!ARError(ret, status)) {
			RETVAL = 0;
		}
	  } else {
		ARError_add(AR_RETURN_ERROR, AP_ERR_USAGE, "usage: ars_DeleteField(ctrl, schema, fieldId, deleteOption=0)");
	  }
	}
	OUTPUT:
	RETVAL

char *
ars_MergeEntry(ctrl, schema, mergeType, ...)
	ARControlStruct *	ctrl
	char *			schema
	unsigned int		mergeType
	CODE:
	{
	  int a, i, c = (items - 3) / 2, j;
	  ARFieldValueList fieldList;
	  ARStatusList status;
	  int ret;
	  unsigned int dataType;
	  AREntryIdType entryId;

	  ARError_reset();
	  RETVAL = "";
	  if ((items - 3) % 2 || c < 1) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	    goto merge_entry_exit;
	  }
	  fieldList.numItems = c;
	  fieldList.fieldValueList = mallocnn(sizeof(ARFieldValueStruct)*c);
	  for (i=0; i<c; i++) {
	    a = i*2 + 3;
	    fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
	    if (! SvOK(ST(a+1))) {
	      /* pass a NULL */
	      fieldList.fieldValueList[i].value.dataType = AR_DATA_TYPE_NULL;
	    } else {
#if AR_EXPORT_VERSION >= 3
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, NULL, NULL, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#endif
	      if (ARError(ret, status)) {
		goto merge_entry_end;
	      }
	      if (sv_to_ARValue(ST(a+1), dataType, &fieldList.fieldValueList[i].value) < 0) {
#ifndef WASTE_MEM
		for (j=0; j<i; j++) {
		  FreeARValueStruct(&fieldList.fieldValueList[j].value, FALSE);
		}
#endif
		goto merge_entry_end;
	      }
	    }
	  }
	  ret = ARMergeEntry(ctrl, schema, &fieldList, mergeType, entryId, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif	  
	  if (! ARError(ret, status)) {
	    RETVAL = entryId;
	  }
#ifndef WASTE_MEM
	  for (j=0; j<c; j++) {
	    FreeARValueStruct(&fieldList.fieldValueList[j].value, FALSE);
	  }
#endif
	merge_entry_end:;
#ifndef WASTE_MEM
	  free(fieldList.fieldValueList);
#endif
	merge_entry_exit:;
	}
	OUTPUT:
	RETVAL

#
# NT (Notifier) ROUTINES
#

int
ars_NTInitializationClient()
        CODE:
        {
          NTStatusList status;
          int ret;

	  ARError_reset();
          RETVAL = 0;
#if AR_EXPORT_VERSION < 3
          ret = NTInitializationClient(&status);
          if(!NTError(ret, status)) {
            RETVAL = 1;
          }
#else
	  ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, "NTInitializationClient() is only available in ARS2.x");
#endif
        }
        OUTPUT:
        RETVAL


int 
ars_NTDeregisterClient(user, password, filename)
	char *		user
	char *		password
	char *		filename
	CODE:
	{
	  NTStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL = 0;
#if AR_EXPORT_VERSION < 3
	  if(user && password && filename) {
	    ret = NTDeregisterClient(user, password, filename, &status);
	    if(!NTError(ret, status)) {
	      RETVAL = 1;
	    }
	  }
#else
	  ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, "NTDeregisterClient() is only available in ARS2.x");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_NTRegisterClient(user, password, filename)
	char *		user
	char *		password
	char *		filename
	CODE:
	{
	  NTStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL = 0;
#if AR_EXPORT_VERSION < 3
	  if(user && password && filename) {
	    ret = NTRegisterClient(user, password, filename, &status);
	    if(!NTError(ret, status)) {
		RETVAL = 1;
	    }
	  }
#else
	  ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, "NTRegisterClient() is only available in ARS2.x");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_NTTerminationClient()
	CODE:
	{
	  NTStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL = 0;
#if AR_EXPORT_VERSION < 3
	  ret = NTTerminationClient(&status);
	  if(!NTError(ret, status)) {
	    RETVAL = 1;
	  }
#else
	  ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, "NTTerminationClient() is only available in ARS2.x");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_NTRegisterServer(serverHost, user, password, ...)
	char *		serverHost
	char *		user
	char *		password
	CODE:
	{
	  NTStatusList status;
	  int ret;
#if AR_EXPORT_VERSION < 3
	  ARError_reset();
	  RETVAL = 0;
	  if(serverHost && user && password && items == 3) {
	    ret = NTRegisterServer(serverHost, user, password, &status);
	    if(!NTError(ret, status)) {
		RETVAL = 1;
	    }
	  } else {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_USAGE, "usage: ars_NTRegisterServer(serverHost, user, password)");
	  }
#else
	  unsigned long clientPort;
	  unsigned int clientCommunication;
	  unsigned int protocol;
	  int multipleClients;

	  ARError_reset();
	  RETVAL = 0;
          if (items < 4 || items > 7) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	  clientPort = (unsigned int)SvIV(ST(4));
	  if (items < 5) {
	    clientCommunication = 2;
	  } else {
	    clientCommunication = (unsigned int)SvIV(ST(5));
	  }
	  if (items < 6) {
	    protocol = 1;
	  } else {
	    protocol = (unsigned int)SvIV(ST(6));
	  }
	  if (items < 7) {
	    multipleClients = 1;
	  } else {
	    multipleClients = (unsigned int)SvIV(ST(1));
	  }
	  
	  if(clientCommunication == NT_CLIENT_COMMUNICATION_SOCKET) {
	    if(protocol == NT_PROTOCOL_TCP) {
	      ret = NTRegisterServer(serverHost, user, password, clientCommunication, clientPort, protocol, multipleClients, &status);
	      if(!NTError(ret, status)) {
		RETVAL = 1;
	      }
	    }
	  }
#endif
	}
	OUTPUT:
	RETVAL

int 
ars_NTTerminationServer()
	CODE:
	{
	 int ret;
	 NTStatusList status;

	 ARError_reset();
	 RETVAL = 0;
	 ret = NTTerminationServer(&status);
	 if(!NTError(ret, status)) {
	   RETVAL = 1;
	 }
	}
	OUTPUT:
	RETVAL

int
ars_NTDeregisterServer(serverHost, user, password)
	char *		serverHost
	char *		user
	char *		password
	CODE:
	{
	 int ret;
	 NTStatusList status;

	 ARError_reset();
	 RETVAL = 0; /* assume error */
	 if(serverHost && user && password) {
	    ret = NTDeregisterServer(serverHost, user, password, &status);
	    if(!NTError(ret, status)) {
		RETVAL = 1; /* success */
	    }
	 }
	}
	OUTPUT:
	RETVAL

void
ars_NTGetListServer()
	PPCODE:
	{
	  NTServerNameList serverList;
	  NTStatusList status;
	  int ret,i;

	  ARError_reset();
	  ret = NTGetListServer(&serverList, &status);
	  if(!NTError(ret, status)) {
	     for(i=0; i<serverList.numItems; i++) {
	        XPUSHs(sv_2mortal(newSVpv(serverList.nameList[i], 0)));
	     }
#ifndef WASTE_MEM
	     FreeNTServerNameList(&serverList, FALSE);
#endif
	  }
	}

int
ars_NTInitializationServer()
	CODE:
	{
	  NTStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL = 0; /* error */
	  ret = NTInitializationServer(&status);
	  if(!NTError(ret, status)) {
	     RETVAL = 1; /* success */
	  }
	}
	OUTPUT:
	RETVAL

int
ars_NTNotificationServer(serverHost, user, notifyText, notifyCode, notifyCodeText)
	char *		serverHost
	char *		user
	char *		notifyText
	int		notifyCode
	char *		notifyCodeText
	CODE:
	{
	  NTStatusList status;
	  int ret;

	  ARError_reset();
	  RETVAL = 0;
	  if(serverHost && user && notifyText) {
	     ret = NTNotificationServer(serverHost, user, notifyText, notifyCode, notifyCodeText, &status);
	     if(!NTError(ret, status)) {
		RETVAL = 1;
	     }
	  }
	}
	OUTPUT:
	RETVAL

#
# test routine
#

HV *
ars_Testing(i)
	int	i
	CODE:
	{
	int ret;
	printf("resetting arerr\n");
	ret = ARError_reset();
	printf("reset return code: %d\n", ret);
	printf("adding a bogus message\n");
	ret = ARError_add(1, 2, "foo");
	printf("add return code: %d\n", ret);

	ret = ARError_add(2, 22, "foo3");
	printf("add return code: %d\n", ret);

	ret = ARError_add(1, 222, "foo4");
	printf("add return code: %d\n", ret);

	ret = ARError_add(3, 2222, "foo5");
	printf("add return code: %d\n", ret);

	printf("returning err_hash\n");
	if(!err_hash) printf("err_hash undef\n");
	RETVAL = err_hash;
	}
	OUTPUT:
	RETVAL

#
# Destructors for Blessed C structures
#

MODULE = ARS		PACKAGE = ARControlStructPtr

void
DESTROY(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
#ifndef WASTE_MEM
	  free(ctrl);
#endif
	}

MODULE = ARS		PACKAGE = ARQualifierStructPtr

void
DESTROY(qual)
	ARQualifierStruct *	qual
	CODE:
	{
#ifndef WASTE_MEM
	  FreeARQualifierStruct(qual, 1);
#endif
	}
