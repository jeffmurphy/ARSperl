/*
$Header: /cvsroot/arsperl/ARSperl/support.c,v 1.8 1997/10/13 12:24:54 jcmurphy Exp $

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

$Log: support.c,v $
Revision 1.8  1997/10/13 12:24:54  jcmurphy
cd ..
removed debugging line

Revision 1.7  1997/10/09 15:21:33  jcmurphy
code cleaning.

Revision 1.6  1997/10/09 00:48:55  jcmurphy
1.52: uninit'd var bug fix

Revision 1.5  1997/10/07 14:29:33  jcmurphy
1.51

Revision 1.4  1997/10/06 13:39:30  jcmurphy
fix up some compilation warnings

Revision 1.3  1997/10/02 15:39:48  jcmurphy
1.50beta

Revision 1.2  1997/09/04 00:20:38  jcmurphy
*** empty log message ***

Revision 1.1  1997/08/05 21:21:05  jcmurphy
Initial revision


*/

/* NAME
 *   support.c
 *
 * DESCRIPTION
 *   this file contains routines that are useful for translating 
 *   ARS C data structures into (ars)perl "data structures" (if you will)
 */

#define __support_c_

#include "support.h"

void
zeromem(MEMCAST *m, int size)
{
  if(m && (size > 0)) {
#ifndef BSD
    (void) memset(m, 0, size);
#else
    (void) bzero(m, size);
#endif
  }
}

int
compmem(MEMCAST *m1, MEMCAST *m2, int size) 
{
  if(m1 && m2 && (size > 0)) {
#ifndef BSD
    return memcmp(m1, m2, size)?1:0;
#else
    return bcmp(m1, m2, size)?1:0;
#endif
  }
  return -1;
}

/* copy from m2 to m1 */

int
copymem(MEMCAST *m1, MEMCAST *m2, int size) 
{
  if(m1 && m2 && (size > 0)) {
#ifndef BSD
    (void) memcpy(m1, m2, size);
#else
    (void) bcopy(m2, m1, size);
#endif
    return 0;
  }
  return -1;
}

/* malloc that will never return null */
void *
mallocnn(int s) {
  void *m = malloc(s?s:1);

  if (! m)
    croak("can't malloc");

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

int
ARError_reset()
{
  SV *ni, *t2, **t1;
  AV *t3;

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

int
ARError_add(unsigned int type, long num, char *text)
{
  SV          **numItems, **messageType, **messageNum, **messageText;
  AV           *a;
  SV           *t2;
  unsigned int  ni, ret = 0;

#ifdef ARSPERL_DEBUG
  printf("ARError_add(%d, %d, %s)\n", type, num, text?text:"NULL");
#endif

/* this is used to insert 'traceback' (debugging) messages into the
 * error hash. these can be filtered out by modifying the FETCH clause
 * of the ARSERRSTR package in ARS.pm
 */

  switch(type) {
  case ARSPERL_TRACEBACK:
  case AR_RETURN_OK:
  case AR_RETURN_WARNING:
    ret = 0;
    break;
  case AR_RETURN_ERROR:
  case AR_RETURN_FATAL:
    ret = -1;
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

  return ret;
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
  int ret = 0;

  for ( item=0; item < status.numItems; item++ ) {
    if(ARError_add(status.statusList[item].messageType,
		   status.statusList[item].messageNum,
		   status.statusList[item].messageText) != 0)
      ret = 1;
  }

  if (returncode == 0)
    return ret;

#ifndef WASTE_MEM
  FreeARStatusList(&status, FALSE);
#endif
  return ret;
}

/* same as ARError, just uses the NT structures instead */
 
int 
NTError(int returncode, NTStatusList status) {
  int item, ret = 0;

  for ( item=0; item < status.numItems; item++ ) {
    if(ARError_add(status.statusList[item].messageType,
		   status.statusList[item].messageNum,
		   status.statusList[item].messageText) != 0)
      ret = 1;
  }

  if (returncode==0)
    return ret;

#ifndef WASTE_MEM
  FreeNTStatusList(&status, FALSE);
#endif
  return ret;
}

unsigned int 
strsrch(register char *s, register char c)
{
  register unsigned int n = 0;  

  if(!s || !*s) return 0;
 
  for(;*s;s++)
    if(*s == c) 
      n++;
  return n;
}

char *
strappend(char *buf, char *arg) 
{
  char *t = (char *)0;

  if(arg) {
    if(buf) {
      t = (char *)MALLOCNN(strlen(buf) + strlen(arg) + 1);
      if(t) {
        strcpy(t, buf);
        free(buf);
        strcat(t, arg);
        buf = t;
      } else
        return (char *)0;
    } else
      buf = strdup(arg);
  }
  return buf;
}

SV *
perl_ARStatusStruct(ARStatusStruct *in) {
  HV   *hash = newHV();

  hv_store(hash, VNAME("messageType"), newSViv(in->messageType), 0);
  hv_store(hash, VNAME("messageNum"), newSViv(in->messageNum), 0);
  hv_store(hash, VNAME("messageText"), newSVpv(in->messageText, 0), 0);

  return newRV((SV *)hash);
}

SV *
perl_ARInternalId(ARInternalId *in) {
  return newSViv(*in);
}

SV *
perl_ARNameType(ARNameType *in) {
  return newSVpv(*in,0);
}

SV *
perl_ARList(ARList *in, ARS_fn fn, int size) {
  int i;
  AV *array = newAV();

  for (i = 0; i < in->numItems; i++) 
    av_push(array, (*fn)((char *)in->array+(i*size)));

  return newRV((SV *)array);
}

SV *
perl_diary(ARDiaryStruct *in) {
  HV *hash = newHV();
  
  hv_store(hash, VNAME("user"), newSVpv(in->user, 0), 0);
  hv_store(hash, VNAME("timestamp"), newSViv(in->timeVal), 0);
  hv_store(hash, VNAME("value"), newSVpv(in->value, 0), 0);
  return newRV((SV *)hash);
}

SV *
perl_dataType_names(unsigned int *in) {
  int i = 0;

  while((DataTypeMap[i].number != *in) && (DataTypeMap[i].number != TYPEMAP_LAST))
    i++;

  if(DataTypeMap[i].number != TYPEMAP_LAST)
    return newSVpv(VNAME(DataTypeMap[i].name));

  return newSVpv(VNAME("NULL"));
}

SV *
perl_ARValueStructType(ARValueStruct *in) {
  return perl_dataType_names(&(in->dataType));
}

SV *
perl_ARValueStruct(ARValueStruct *in) {
  ARDiaryList  diaryList;
  ARStatusList status;
  int          ret, i;
  
  ZEROMEM(&status, ARStatusList);
  switch (in->dataType) {
  case AR_DATA_TYPE_KEYWORD:
    for(i = 0 ; KeyWordMap[i].number != TYPEMAP_LAST ; i++) {
      if(KeyWordMap[i].number == in->u.keyNum)
	break;
    }
    return newSVpv(KeyWordMap[i].name, KeyWordMap[i].len);
    break;
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

SV *
perl_ARStatHistoryValue(ARStatHistoryValue *in) {
  HV *hash = newHV();
  hv_store(hash, VNAME("userOrTime"), newSViv(in->userOrTime), 0);
  hv_store(hash, VNAME("enumVal"), newSViv(in->enumVal), 0);
  return newRV((SV *)hash);
}

SV *
perl_ARAssignFieldStruct(ARAssignFieldStruct *in) {
  HV                *hash = newHV();
  ARQualifierStruct *qual;
  SV                *ref;
  int                i;

  hv_store(hash, VNAME("server"), newSVpv(in->server,0),0);
  hv_store(hash, VNAME("schema"), newSVpv(in->schema,0),0);
  hv_store(hash, VNAME("tag"), newSViv(in->tag), 0);

#if AR_EXPORT_VERSION >= 3
  /* translate the noMatchOption value into english */

  for(i = 0 ; NoMatchOptionMap[i].number != TYPEMAP_LAST ; i++) 
    if(NoMatchOptionMap[i].number == in->noMatchOption)
      break;

  if(NoMatchOptionMap[i].number == TYPEMAP_LAST) {
    char optnum[25];
    sprintf(optnum, "%u", in->noMatchOption);
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		"perl_ARAssignFieldStruct: unknown noMatchOption value");
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, optnum);
  }

  /* if we didn't find a match, store "" */

  hv_store(hash, VNAME("noMatchOption"), newSVpv(NoMatchOptionMap[i].name, 0), 0);

  /* translate the multiMatchOption value into english */

  for(i = 0 ; MultiMatchOptionMap[i].number != TYPEMAP_LAST ; i++) 
    if(MultiMatchOptionMap[i].number == in->multiMatchOption)
      break;

  if(MultiMatchOptionMap[i].number == TYPEMAP_LAST) {
    char optnum[25];
    sprintf(optnum, "%u", in->multiMatchOption);
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		"perl_ARAssignFieldStruct: unknown multiMatchOption value");
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, optnum);
  }

  hv_store(hash, VNAME("multiMatchOption"), newSVpv(MultiMatchOptionMap[i].name, 0)
	   , 0);
#endif

  qual = dup_qualifier(&in->qualifier);
  ref = newSViv(0);
  sv_setref_pv(ref, "ARQualifierStructPtr", (void*)qual);
  hv_store(hash, VNAME("qualifier"), ref,0);

  switch (in->tag) {
  case AR_FIELD:
    hv_store(hash, VNAME("fieldId"), newSViv(in->u.fieldId),0);
    break;
  case AR_STAT_HISTORY:
    hv_store(hash, VNAME("statHistory"),
	     perl_ARStatHistoryValue(&in->u.statHistory),0);
    break;
  default:
    break;
  }
  return newRV((SV *)hash);
}

SV *
perl_ARFieldAssignStruct(ARFieldAssignStruct *in) {
  HV *hash = newHV();

  hv_store(hash, VNAME("fieldId"),
	   newSViv(in->fieldId), 0);

  hv_store(hash, VNAME("assignment"),
	   perl_ARAssignStruct(&in->assignment), 0);

  return newRV((SV *)hash);
}

SV *
perl_ARDisplayStruct(ARDisplayStruct *in) {
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

SV *
perl_ARMacroParmList(ARMacroParmList *in) {
  HV *hash = newHV();
  int i;
  for (i=0; i<in->numItems; i++) {
    hv_store(hash, in->parms[i].name, strlen(in->parms[i].name),
	     newSVpv(in->parms[0].value,0), 0);
  }
  return newRV((SV *)hash);
}

SV *
perl_ARActiveLinkMacroStruct(ARActiveLinkMacroStruct *in) {
  HV *hash = newHV();
  hv_store(hash, "macroParms", strlen("macroParms"),
	   perl_ARMacroParmList(&in->macroParms), 0);
  hv_store(hash, "macroText", strlen("macroText"),
	   newSVpv(in->macroText,0), 0);
  hv_store(hash, "macroName", strlen("macroName"),
	   newSVpv(in->macroName,0), 0);
  return newRV((SV *)hash);
}

SV *
perl_ARFieldCharacteristics(ARFieldCharacteristics *in) {
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

SV *
perl_ARDDEStruct(ARDDEStruct *in) {  /* FIX */
  return &sv_undef;
}

SV *
perl_ARActiveLinkActionStruct(ARActiveLinkActionStruct *in) {
  HV *hash = newHV();

  switch (in->action) {
  case AR_ACTIVE_LINK_ACTION_MACRO:
    hv_store(hash, VNAME("macro"),
	     perl_ARActiveLinkMacroStruct(&in->u.macro), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_FIELDS:
    hv_store(hash, VNAME("assign_fields"),
	     perl_ARList((ARList *)&in->u.fieldList,
			 (ARS_fn)perl_ARFieldAssignStruct,
			 sizeof(ARFieldAssignStruct)), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_PROCESS:
    hv_store(hash, VNAME("process"), newSVpv(in->u.process, 0), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_MESSAGE:
    hv_store(hash, VNAME("message"),
	     perl_ARStatusStruct(&in->u.message), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_SET_CHAR:
    hv_store(hash, VNAME("characteristics"),
	     perl_ARFieldCharacteristics(&in->u.characteristics), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_DDE:
    hv_store(hash, VNAME("dde"),
	     perl_ARDDEStruct(&in->u.dde), 0);
    break;
  case AR_ACTIVE_LINK_ACTION_NONE:
  default:
    hv_store(hash, VNAME("none"),
	     &sv_undef, 0);
    break;
  }
  return newRV((SV *)hash);
}

SV *
perl_ARFilterActionNotify(ARFilterActionNotify *in) {
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

SV *
perl_ARFilterActionStruct(ARFilterActionStruct *in) {
  HV *hash=newHV();

  switch (in->action) {
  case AR_FILTER_ACTION_NOTIFY:
    hv_store(hash, VNAME("notify"),
	     perl_ARFilterActionNotify(&in->u.notify), 0);
    break;
  case AR_FILTER_ACTION_MESSAGE:
    hv_store(hash, VNAME("message"), 
	     perl_ARStatusStruct(&in->u.message), 0);
    break;
  case AR_FILTER_ACTION_LOG:
    hv_store(hash, VNAME("log"), newSVpv(in->u.logFile, 0), 0);
    break;
  case AR_FILTER_ACTION_FIELDS:
    hv_store(hash, VNAME("assign_fields"),
	     perl_ARList((ARList *)&in->u.fieldList,
			 (ARS_fn)perl_ARFieldAssignStruct,
			 sizeof(ARFieldAssignStruct)), 0);
    break;
  case AR_FILTER_ACTION_PROCESS:
    hv_store(hash, VNAME("process"), newSVpv(in->u.process, 0), 0);
    break;
  case AR_FILTER_ACTION_NONE:
  default:
    hv_store(hash, VNAME("none"), &sv_undef, 0);
    break;
  }
  return newRV((SV *)hash);
}

SV *
perl_expandARCharMenuStruct(ARControlStruct *c, ARCharMenuStruct *in) {
  ARCharMenuStruct menu, *which;
  int              ret, i;
  ARStatusList     status;
  AV              *array;
  SV              *sub;
  char            *string;
  
  ZEROMEM(&status, ARStatusList);

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

SV *
perl_AREntryListFieldStruct(AREntryListFieldStruct *in) {
  HV *hash;
  hash = newHV();

  hv_store(hash, VNAME("fieldId"),
	   newSViv(in->fieldId), 0);
  hv_store(hash, VNAME("columnWidth"), 
	   newSViv(in->columnWidth), 0);
  hv_store(hash, VNAME("separator"), 
	   newSVpv(in->separator, 0), 0);
  return newRV((SV *)hash);
}

SV *
perl_ARIndexStruct(ARIndexStruct *in) { 
  HV *hash;
  AV *array;
  int i;
  hash = newHV();
  array = newAV();
  
  if (in->unique)
    hv_store(hash, VNAME("unique"), newSViv(1), 0);
  for (i=0; i < AR_MAX_INDEX_FIELDS && in->fieldIds[i] != 0; i++)
    av_push(array, perl_ARInternalId(&(in->fieldIds[i])));
  hv_store(hash, VNAME("fieldIds"), newRV((SV *)array), 0);
  
  return newRV((SV *)hash);
}

SV *
perl_ARFieldLimitStruct(ARFieldLimitStruct *in) {
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

SV *
perl_ARAssignStruct(ARAssignStruct *in) {
  HV *hash;
  hash = newHV();
  switch(in->assignType) {
  case AR_ASSIGN_TYPE_NONE:
    hv_store(hash, VNAME("none"),
	     &sv_undef, 0);
    break;
  case AR_ASSIGN_TYPE_VALUE:

  /* we will also be storing the specific AR_DATA_TYPE_* since
   * this is used in the rev_* routines to translate back.
   * we wouldnt be able to derive the datatype in any
   * other fashion.
   */

    hv_store(hash, VNAME("value"),
	     perl_ARValueStruct(&in->u.value), 0);
    hv_store(hash, VNAME("valueType"),
	     perl_ARValueStructType(&in->u.value), 0);
    break;
  case AR_ASSIGN_TYPE_FIELD:
    hv_store(hash, VNAME("field"),
	     perl_ARAssignFieldStruct(in->u.field), 0);
    break;
  case AR_ASSIGN_TYPE_PROCESS:
    hv_store(hash, VNAME("process"),
	     newSVpv(in->u.process, 0), 0);
    break;
  case AR_ASSIGN_TYPE_ARITH:
    hv_store(hash, VNAME("arith"),
	     perl_ARArithOpAssignStruct(in->u.arithOp), 0);
    break;
  case AR_ASSIGN_TYPE_FUNCTION:
    hv_store(hash, VNAME("function"),
	     perl_ARFunctionAssignStruct(in->u.function), 0);
    break;
  case AR_ASSIGN_TYPE_DDE:
    hv_store(hash, VNAME("dde"),
	     perl_ARDDEStruct(in->u.dde), 0);
    break;
#if AR_EXPORT_VERSION >= 3
  case AR_ASSIGN_TYPE_SQL:
    hv_store(hash, VNAME("sql"),
	     perl_ARAssignSQLStruct(in->u.sql), 0);
    break;
#endif /* ARS 3.x */
  default:
    hv_store(hash, VNAME("none"),
	     &sv_undef, 0);
    break;
  }
  return newRV((SV *)hash);
}

#if AR_EXPORT_VERSION >= 3
SV *
perl_ARAssignSQLStruct(ARAssignSQLStruct *in)
{
  HV *hash = newHV();
  int i;

  hv_store(hash, VNAME("server"), newSVpv(in->server, 0), 0);
  hv_store(hash, VNAME("sqlCommand"), newSVpv(in->sqlCommand, 0), 0);
  hv_store(hash, VNAME("valueIndex"), newSViv(in->valueIndex), 0);

  /* translate the noMatchOption value into english */

  for(i = 0 ; NoMatchOptionMap[i].number != TYPEMAP_LAST ; i++) 
    if(NoMatchOptionMap[i].number == in->noMatchOption)
      break;

  if(NoMatchOptionMap[i].number == TYPEMAP_LAST) {
    char optnum[25];
    sprintf(optnum, "%u", in->noMatchOption);
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		"perl_ARAssignSQLStruct: unknown noMatchOption value");
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, optnum);
  }

  /* if we didn't find a match, store "" */

  hv_store(hash, VNAME("noMatchOption"), newSVpv(NoMatchOptionMap[i].name, 0), 0);

  /* translate the multiMatchOption value into english */

  for(i = 0 ; MultiMatchOptionMap[i].number != TYPEMAP_LAST ; i++) 
    if(MultiMatchOptionMap[i].number == in->multiMatchOption)
      break;

  if(MultiMatchOptionMap[i].number == TYPEMAP_LAST) {
    char optnum[25];
    sprintf(optnum, "%u", in->multiMatchOption);
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		"perl_ARAssignFieldStruct: unknown multiMatchOption value");
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, optnum);
  }

  hv_store(hash, VNAME("multiMatchOption"), newSVpv(MultiMatchOptionMap[i].name, 0)
	   , 0);

  return newRV((SV *)hash);
}
#endif /* ARS3.x */

SV *
perl_ARFunctionAssignStruct(ARFunctionAssignStruct *in) {
  AV  *array = newAV();
  int  i;
  
  for(i = 0 ; FunctionMap[i].number != TYPEMAP_LAST ; i++) 
    if(FunctionMap[i].number == in->functionCode)
      break;

  av_push(array, newSVpv(FunctionMap[i].name, 0));

  for (i = 0 ; i < in->numItems ; i++)
    av_push(array, perl_ARAssignStruct(&in->parameterList[i]));

  return newRV((SV *)array);
}

SV *
perl_ARArithOpAssignStruct(ARArithOpAssignStruct *in) {
  HV *hash = newHV();
  int i;

  for(i = 0 ; ArithOpMap[i].number != TYPEMAP_LAST ; i++) 
    if(ArithOpMap[i].number == in->operation)
      break;

  hv_store(hash, VNAME("oper"), newSVpv(ArithOpMap[i].name, 0), 0);

  if (in->operation == AR_ARITH_OP_NEGATE) {
    hv_store(hash, VNAME("left"), perl_ARAssignStruct(&in->operandLeft), 0);
  } else {
    hv_store(hash, VNAME("right"), perl_ARAssignStruct(&in->operandRight), 0);
    hv_store(hash, VNAME("left"), perl_ARAssignStruct(&in->operandLeft), 0);
  }
  return newRV((SV *)hash);
}

SV *
perl_ARPermissionList(ARPermissionList *in) {
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

/* ROUTINE
 *   perl_BuildEntryList(eList, entry_id)
 *
 * DESCRIPTION
 *   given a scalar entry-id and an empty AREntryIdList buffer,
 *   this routine will populate the buffer with the appropriate
 *   data, taking into consideration join schema id's and such.
 *
 *   the calling routine should call FreeAREntryIdList() to 
 *   free up what this routine makes.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 */

int 
perl_BuildEntryList(AREntryIdList *entryList, char *entry_id)
{
  if(entry_id && *entry_id) {
    /* if the entry id is too long, it is probably refering to
     * a join schema. split it, and fill in the entryIdList with
     * the components. 
     */
  
    if(strlen(entry_id) > AR_MAX_ENTRYID_SIZE) {
      char *eid_dup, *eid_orig, *tok;
      char  eidSep[2] = {AR_ENTRY_ID_SEPARATOR, 0};
      int   tn;

      eid_dup  = strdup(entry_id);
      eid_orig = eid_dup; /* remember who we are */
      
      entryList->numItems = strsrch(eid_dup, AR_ENTRY_ID_SEPARATOR) + 1; 
      entryList->entryIdList = (AREntryIdType *) MALLOCNN(sizeof(AREntryIdType) * entryList->numItems);

      if((tok = strtok(eid_dup, eidSep))) {
	for(tn = 0; tn < entryList->numItems ; tn++) {
	  strcpy(entryList->entryIdList[tn], tok);
	  tok = strtok((char *)NULL, eidSep);
	}
	free(eid_orig);
	return 0;
      } else {
	ARError_add(AR_RETURN_ERROR, AP_ERR_EID_SEP);
	free(eid_orig);
	return -1;
      }    
    } else { /* "normal" entry-id */
      entryList->numItems = 1;
      entryList->entryIdList = MALLOCNN(sizeof(AREntryIdType) * 1);
      strcpy(entryList->entryIdList[0], entry_id);
      return 0;
    }
  } else
    ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EID);
  return -1;
}

SV *
perl_ARPropStruct(ARPropStruct *in) {
  HV *hash = newHV();

  hv_store(hash, VNAME("prop"), newSViv(in->prop), 0);
  hv_store(hash, VNAME("value"), perl_ARValueStruct(&in->value), 0);
  hv_store(hash, VNAME("valueType"), perl_ARValueStructType(&in->value), 0);

  return newRV((SV *)hash);
}

SV *
perl_ARDisplayInstanceStruct(ARDisplayInstanceStruct *in) {
  HV *hash = newHV();

  hv_store(hash, VNAME("vui"), newSViv(in->vui), 0);
  hv_store(hash, VNAME("props"), perl_ARList((ARList *)&in->props,
					 (ARS_fn)perl_ARPropStruct,
					 sizeof(ARPropStruct)), 0);
  return newRV((SV *)hash);
}

SV *
perl_ARDisplayInstanceList(ARDisplayInstanceList *in) {
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

SV *
perl_ARFieldMappingStruct(ARFieldMappingStruct *in) {
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

SV *
perl_ARJoinMappingStruct(ARJoinMappingStruct *in) {
  HV *hash = newHV();
  
  hv_store(hash, "schemaIndex", strlen("schemaIndex"),
	   newSViv(in->schemaIndex), 0);
  hv_store(hash, "realId", 6, newSViv(in->realId), 0);
  return newRV((SV *)hash);  
}

SV *
perl_ARViewMappingStruct(ARViewMappingStruct *in) {
  HV *hash = newHV();
  
  hv_store(hash, "fieldName", 9, newSVpv(in->fieldName, 0), 0);
  return newRV((SV *)hash);    
}

SV *
perl_ARJoinSchema(ARJoinSchema *in) {
  HV *hash = newHV();
  SV *joinQual = newSViv(0);
  
  hv_store(hash, "memberA", 7, newSVpv(in->memberA, 0), 0);
  hv_store(hash, "memberB", 7, newSVpv(in->memberB, 0), 0);
  sv_setref_pv(joinQual, "ARQualifierStructPtr", dup_qualifier(&in->joinQual));
  hv_store(hash, "joinQual", 8, joinQual, 0);
  hv_store(hash, "option", 6, newSViv(in->option), 0);
  return newRV((SV *)hash);
}

SV *
perl_ARViewSchema(ARViewSchema *in) {
  HV *hash = newHV();
  
  hv_store(hash, "tableName", 9, newSVpv(in->tableName, 0), 0);
  hv_store(hash, "keyField", 8, newSVpv(in->keyField, 0), 0);
  hv_store(hash, "viewQual", 8, newSVpv(in->viewQual, 0), 0);
  return newRV((SV *)hash);
}

SV *
perl_ARCompoundSchema(ARCompoundSchema *in) {
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

SV *
perl_ARSortList(ARSortList *in) {
  AV *array = newAV();
  int i;
  
  for (i=0; i<in->numItems; i++) {
    HV *sort = newHV();
    
    hv_store(sort, VNAME("fieldId"), newSViv(in->sortList[i].fieldId), 0);
    hv_store(sort, VNAME("sortOrder"), newSViv(in->sortList[i].sortOrder), 0);
    av_push(array, newRV((SV *)sort));
  }
  return newRV((SV *)array);
}

SV *
perl_ARByteList(ARByteList *in) {
  HV *hash = newHV();
  SV *byte_list = newSVpv((char *)in->bytes, in->numItems);
  int i;

  for(i = 0 ; ByteListTypeMap[i].number != TYPEMAP_LAST ; i++) {
    if(ByteListTypeMap[i].number == in->type)
      break;
  }
  hv_store(hash, VNAME("type"), newSVpv(VNAME(ByteListTypeMap[i].name)), 0);
  hv_store(hash, "value", 5, byte_list, 0);
  return newRV((SV *)hash);
}

SV *
perl_ARCoordStruct(ARCoordStruct *in) {
  HV *hash = newHV();
  hv_store(hash, VNAME("x"), newSViv(in->x), 0);
  hv_store(hash, VNAME("y"), newSViv(in->y), 0);
  return newRV((SV *)hash);
}

#endif /* ARS 3 */

void 
dup_Value(ARValueStruct *n, ARValueStruct *in) {
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

ARArithOpStruct *
dup_ArithOp(ARArithOpStruct *in) {
  ARArithOpStruct *n;
  if (!in)
    return NULL;
  n = MALLOCNN(sizeof(ARArithOpStruct));
  n->operation = in->operation;
  dup_FieldValueOrArith(&n->operandLeft, &in->operandLeft);
  dup_FieldValueOrArith(&n->operandRight, &in->operandRight);
  return n;
}

void 
dup_ValueList(ARValueList *n, ARValueList *in) {
  int i;
  n->numItems = in->numItems;
  n->valueList = MALLOCNN(sizeof(ARValueStruct) * in->numItems);
  for (i=0; i<in->numItems; i++)
    dup_Value(&n->valueList[0], &in->valueList[0]);
}

ARQueryValueStruct *
dup_QueryValue(ARQueryValueStruct *in) {
  ARQueryValueStruct *n;
  if (!in)
    return NULL;
  n = MALLOCNN(sizeof(ARQueryValueStruct));
  strcpy(n->schema, in->schema);
  strcpy(n->server, in->server);
  n->qualifier = dup_qualifier(in->qualifier);
  n->valueField = in->valueField;
  n->multiMatchCode = in->multiMatchCode;
  return n;
}

void 
dup_FieldValueOrArith(ARFieldValueOrArithStruct *n,
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

ARRelOpStruct *
dup_RelOp(ARRelOpStruct *in) {
  ARRelOpStruct *n;
  if (! in)
    return NULL;
  n = MALLOCNN(sizeof(ARRelOpStruct));
  n->operation = in->operation;
  dup_FieldValueOrArith(&n->operandLeft, &in->operandLeft);
  dup_FieldValueOrArith(&n->operandRight, &in->operandRight);
  return n;
}

/* assumes qual struct is pre-allocated. if level > 0 then out is
 * ignored and a new qual struct is allocated, else out is used instead
 * of allocating a new struct
 */

ARQualifierStruct *
dup_qualifier2(ARQualifierStruct *in, ARQualifierStruct *out, int level) {
  ARQualifierStruct *n;

  if (!in || !out) return (ARQualifierStruct *)NULL;
  if(level > 0) {
    n = MALLOCNN(sizeof(ARQualifierStruct));
  } else {
    n = out;
  }

  n->operation = in->operation;

  switch (in->operation) {
  case AR_COND_OP_AND:
  case AR_COND_OP_OR:
    n->u.andor.operandLeft = dup_qualifier2(in->u.andor.operandLeft, out, 1);
    n->u.andor.operandRight = dup_qualifier2(in->u.andor.operandRight, out, 1);
    break;
  case AR_COND_OP_NOT:
    n->u.not = dup_qualifier2(in->u.not, out, 1);
    break;
  case AR_COND_OP_REL_OP:
    n->u.relOp = dup_RelOp(in->u.relOp);
    break;
  case AR_COND_OP_NONE:
    break;
  }
  return n;
}

/* assumes qual struct is not pre-allocated */

ARQualifierStruct *
dup_qualifier(ARQualifierStruct *in) {
  ARQualifierStruct *n;
  if (!in) return NULL;
  n = MALLOCNN(sizeof(ARQualifierStruct));
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

SV *
perl_ARArithOpStruct(ARArithOpStruct *in) {
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

SV *
perl_ARQueryValueStruct(ARQueryValueStruct *in) {
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

SV *
perl_ARFieldValueOrArithStruct(ARFieldValueOrArithStruct *in) {
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

SV *
perl_relOp(ARRelOpStruct *in) {
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

HV *
perl_qualifier(ARQualifierStruct *in) {
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
  new_disp = MALLOCNN(sizeof(ARDisplayList));
  new_disp->numItems = disp->numItems;
  new_disp->displayList = MALLOCNN(sizeof(ARDisplayStruct)*disp->numItems);
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
		 ARStatusList *Status) 
{
  int            ret;
  HV            *cache, *server, *fields, *base;
  SV           **servers, **schema_fields, **field, **val;
  unsigned int   my_dataType;
#if AR_EXPORT_VERSION >= 3
  ARNameType     my_fieldName;
#else
  ARDisplayList  my_display, *display_copy;
  SV            *display_ref;
#endif
  char           field_string[20];

  (void) ARError_add(ARSPERL_TRACEBACK, 1, "testing");
  
#if AR_EXPORT_VERSION >= 3
  /* cache fieldName and dataType */
  if (fieldMap || option || createMode || defaultVal || perm || limit ||
      display || help || timestamp || owner || lastChanged || changeDiary) {
    (void) ARError_add(ARSPERL_TRACEBACK, 1, 
		       "ARGetFieldCached (internal error): not all parameters specified.");
    goto cache_fail;
  }
#else
  /* cache dataType and displayList */
  if (option || createMode || defaultVal || perm || limit || help ||
      timestamp || owner || lastChanged || changeDiary) {
    (void) ARError_add(ARSPERL_TRACEBACK, 1,
		       "ARGetFieldCached (internal error): not all parameters specified.");
    goto cache_fail;
  }
#endif  
  
  /* try to do lookup in cache */  

  cache = perl_get_hv("ARS::field_cache",TRUE);

  /* dereference hash with server */

  servers = hv_fetch(cache, ctrl->server, strlen(ctrl->server), TRUE);

  if (! (servers && SvROK(*servers) &&
	 SvTYPE(server = (HV *)SvRV(*servers)) == SVt_PVHV)) {
    (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached failed to deref hash w/server name");
    goto cache_fail;
  }

  /* dereference hash with schema */

  schema_fields = hv_fetch(server, schema, strlen(schema), TRUE);

  if (! (schema_fields && SvROK(*schema_fields) &&
	 SvTYPE(fields = (HV *)SvRV(*schema_fields)) == SVt_PVHV)) {
    (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached failed to deref hash w/schema name");
    goto cache_fail;
  }

  /* dereference with field id */

  sprintf(field_string, "%i", (int)id);

  field = hv_fetch(fields, field_string, strlen(field_string), TRUE);

  if (! (field && SvROK(*field) && SvTYPE(base = (HV *)SvRV(*field)))) {
    (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached failed to fetch fieldId from hash");
    goto cache_fail;
  }

  /* fetch values */

  val = hv_fetch(base, VNAME("name"), FALSE);
  if (! val) {
    (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached failed to fetch name key");
    goto cache_fail;
  }

#if AR_EXPORT_VERSION >= 3
  if (fieldName) {
    strcpy(fieldName, SvPV((*val), na));
  }
#else /* ARS 2.x */
  if (! sv_isa(*val, "ARDisplayListPtr")) {
    (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached: ARDisplayListPtr isnta sv");
    goto cache_fail;
  }

  if (display) {
    display_copy         = (ARDisplayList *)SvIV(SvRV(*val));
    display->numItems    = display_copy->numItems;
    display->displayList =
      MALLOCNN(sizeof(ARDisplayStruct)*display_copy->numItems);
    memcpy(display->displayList, display_copy->displayList,
	    sizeof(ARDisplayStruct)*display_copy->numItems);
  }
#endif

  val = hv_fetch(base, "type", strlen("type"), FALSE);

  if (! val) {
    (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached failed to fetch type key");
    goto cache_fail;
  }

  if (dataType) {
    *dataType = SvIV(*val);
  }

  return 0;
  
  /* if we don't cache one of the arguments or we couldn't find
   * field in cache.. then we need to do a query to find the
   * data. 
   */

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

  if (dataType) *dataType = my_dataType;

#if AR_EXPORT_VERSION >= 3
  if (fieldName) strcpy(fieldName, my_fieldName);
#else
  if (display)  *display = my_display;
#endif

  if (ret == 0) { /* if ARGetField was successful */

    /* get variable */

    cache = perl_get_hv("ARS::field_cache",TRUE);

    /* dereference hash with server */

    servers = hv_fetch(cache, VNAME(ctrl->server), TRUE);

    if (! servers) {
      (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached (part 2) failed to fetch/create servers key");
      return ret;
    }

    if (! SvROK(*servers) || SvTYPE(SvRV(*servers)) != SVt_PVHV) {
      sv_setsv(*servers, newRV((SV *)(server = newHV())));
    } else {
      server = (HV *)SvRV(*servers);
    }

    /* dereference hash with schema */

    schema_fields = hv_fetch(server, VNAME(schema), TRUE);

    if (! schema_fields) {
      (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached (part 2) failed to fetch/create schema key");
      return ret;
    }

    if (! SvROK(*schema_fields) || SvTYPE(SvRV(*schema_fields)) != SVt_PVHV) {
      sv_setsv(*schema_fields, newRV((SV *)(fields = newHV())));
    } else {
      fields = (HV *)SvRV(*schema_fields);
    }

    /* dereference hash with field id */

    sprintf(field_string, "%i", (int)id);

    field = hv_fetch(fields, field_string, strlen(field_string), TRUE);

    if (! field) {
      (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached (part 2) failed to fetch/create field key");
      return ret;
    }

    if (! SvROK(*field) || SvTYPE(SvRV(*field)) != SVt_PVHV) {
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
  } else {
    (void) ARError_add(ARSPERL_TRACEBACK, 1, "GetFieldCached: ARGetField call failed.");
  }
  return ret;
}

int
sv_to_ARValue(SV *in, unsigned int dataType, ARValueStruct *out) {
  AV           *array, *array2;
  HV           *hash;
  SV          **fetch, *type, *val, **fetch2;
  char         *bytelist;
  unsigned int  len, i;
  
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
	  out->u.byteListVal = MALLOCNN(sizeof(ARByteList));
	  out->u.byteListVal->type = SvIV(type);
	  bytelist = SvPV(val, len);
	  out->u.byteListVal->numItems = len;
	  out->u.byteListVal->bytes = MALLOCNN(len);
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
	out->u.coordListVal = MALLOCNN(sizeof(ARCoordList));
	out->u.coordListVal->numItems = len;
	out->u.coordListVal->coords = MALLOCNN(sizeof(ARCoordStruct)*len);
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

