/*
    ARSperl - An ARS2.0 / Perl5.0 Integration Kit

    Copyright (C) 1995 Joel Murphy, jmurphy@acsu.buffalo.edu
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
 
    Comments to: arsperl@smurfland.cit.buffalo.edu
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>

#ifdef PROFILE
#include <sys/time.h>
#endif

#include "ar.h"
#include "arerrno.h"
#include "arextern.h"
#include "arstruct.h"

char *ars_errstr = "";
char errbuf[8192];  /* that should be big enough to hold errors */

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
		     unsigned int *, unsigned int *,
		     unsigned int *, ARValueStruct *,
		     ARPermissionList *, ARFieldLimitStruct *,
		     ARDisplayList *, char **, ARTimestamp *,
		     ARNameType, ARNameType, char **,
		     ARStatusList *);

/* malloc that will never return null */
static void *mallocnn(int s) {
  void *m = malloc(s);
  if (! m)
    croak("can't malloc");
  else 
    return m;
}

/* new ARError which fixes sprintf incompatability under SUNOS
   from Mark Feit <mfeit@uunet.uu.net> */
int ARError(int returncode, ARStatusList status) {
  char *index;         /* Index into error buffer */
  int item;            /* Error item counter */
  
  ars_errstr = errbuf;
  errbuf[0] = '\0';
  if (returncode==0) {
#ifndef WASTE_MEM
/*    FreeARStatusList(&status, FALSE); */
#endif
    return 0;
  }
  index = errbuf;
  for ( item=0; item < status.numItems; item++ ) {
    if ( item > 0 ) {
      strcpy(index, "  ");
      index += 2;
    }
    strcpy( index, status.statusList[item].messageText );		 
    index += strlen(index);
  }
#ifndef WASTE_MEM
  FreeARStatusList(&status, FALSE);
#endif
  return 1;
}

SV *perl_ARStatusStruct(ARStatusStruct *in) {
  char *msg;
  SV *ret;
  msg = mallocnn(strlen(in->messageText) + 100);
  sprintf(msg, "Type %d Num %d Text [%s]\n",
	  in->messageType,
	  in->messageNum,
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
  if (in->display)
    hv_store(hash, "display", strlen("display"),
	     perl_ARDisplayStruct(in->display),0);
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
  int i;
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
/*  hv_store(hash, "fieldIdListType", strlen("fieldIdListType"),
	   newSViv(in->fieldIdListType), 0);
  */
  return newRV((SV *)hash);
}

SV *perl_ARFilterActionStruct(ARFilterActionStruct *in) {
  HV *hash=newHV();
  int i;
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
/*  case AR_FIELD_TRAN:
  case AR_FIELD_DB: */
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
		 unsigned int *dataType, unsigned int *option,
		 unsigned int *createMode, ARValueStruct *defaultVal,
		 ARPermissionList *perm, ARFieldLimitStruct *limit,
		 ARDisplayList *display, char **help, ARTimestamp *timestamp,
		 ARNameType owner, ARNameType lastChanged, char **changeDiary,
		 ARStatusList *Status) {
  int ret;
  HV *cache, *server, *fields, *base;
  SV **servers, **schema_fields, **field, **val, *display_ref;
  unsigned int my_dataType;
  ARDisplayList my_display, *display_copy;
  char field_string[20];
  
  if (option || createMode || defaultVal || perm || limit || help ||
	 timestamp || owner || lastChanged || changeDiary) 
    goto cache_fail;
  
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
  sprintf(field_string, "%i", id);
  field = hv_fetch(fields, field_string, strlen(field_string), TRUE);
  if (! (field && SvROK(*field) && SvTYPE(base = (HV *)SvRV(*field))))
    goto cache_fail;
  /* fetch values */
  val = hv_fetch(base, "name", strlen("name"), FALSE);
  if (! val) goto cache_fail;
  if (! (val && sv_isa(*val, "ARDisplayListPtr")))
    goto cache_fail;
  if (display) {
    display_copy = (ARDisplayList *)SvIV(SvRV(*val));
    display->numItems = display_copy->numItems;
    display->displayList =
      mallocnn(sizeof(ARDisplayStruct)*display_copy->numItems);
    memcpy(display->displayList, display_copy->displayList,
	    sizeof(ARDisplayStruct)*display_copy->numItems);
  }
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
  ret = ARGetField(ctrl, schema, id, &my_dataType, option, createMode,
		 defaultVal, perm, limit, &my_display, help, timestamp,
		   owner, lastChanged, changeDiary, Status);
#ifdef PROFILE
  ((ars_ctrl *)ctrl)->queries++;
#endif
  if (dataType)
    *dataType = my_dataType;
  if (display)
    *display = my_display;
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
    sprintf(field_string, "%i", id);
    field = hv_fetch(fields, field_string, strlen(field_string), TRUE);
    if (! field) return ret;
    if (! SvROK(*field) ||
	SvTYPE(SvRV(*field)) != SVt_PVHV) {
      sv_setsv(*field, newRV((SV *)(base = newHV())));
    } else {
      base = (HV *)SvRV(*field);
    }
    /* store field attributes */
    display_ref = newSViv(0);
    sv_setref_pv(display_ref, "ARDisplayListPtr",
		 (void *)dup_DisplayList(display));
    hv_store(base, "name", strlen("name"), display_ref, 0);
    hv_store(base, "type", strlen("type"), newSViv(my_dataType), 0);
  }
  return ret;
}

MODULE = ARS		PACKAGE = ARS		PREFIX = ARS

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

char *
_ars_errstr()
	CODE:
	{
	RETVAL=ars_errstr;
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
__ars_init()
	CODE:
	{
	  int ret;
	  ARStatusList status;
	
	/*  ret = ARInitialization(&status);
	  if (ARError(ret, status)) {
	    croak("unable to initialize ARS module");
	  } */
	}

ARControlStruct *
ars_Login(server,username,password)
	char *		server
	char *		username
	char *		password
	CODE:
	{
	  int ret;
	  ARStatusList status;
	  ARServerNameList serverList;
	  ARControlStruct *ctrl;
#ifdef PROFILE
	  struct timeval tv;
#endif
	  
	  ret = ARGetListServer(&serverList, &status);
	  if (ARError(ret, status)) {
	    RETVAL = NULL;
	    goto ar_login_end;
	  }
	  if (serverList.numItems < 0) {
	    ars_errstr = "no servers available";
	    RETVAL = NULL;
	    goto ar_login_end;
	  }
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
	  if (!server || !*server)
	    server = serverList.nameList[0];
	  strncpy(ctrl->server, server, sizeof(ctrl->server));
	  ctrl->server[sizeof(ctrl->server)-1] = 0;
	  RETVAL = ctrl;
#ifndef WASTE_MEM
	  FreeARServerNameList(&serverList,FALSE);
#endif
	  goto ar_login_end;
	ar_login_end:;
	}
	OUTPUT:
	RETVAL

HV *
ars_GetProfileInfo(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	RETVAL = newHV();
#ifdef PROFILE
	hv_store(RETVAL, "queries", strlen("queries"),
		 newSViv(((ars_ctrl *)ctrl)->queries), 0);
	hv_store(RETVAL, "startTime", strlen("startTime"),
		 newSViv(((ars_ctrl *)ctrl)->startTime), 0);
#else /* profiling not compiled in */
	fprintf(stderr, "arsperl: optional profiling not compiled in.\n");
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
	    if (!ctrl) return;
	    ret = XARReleaseCurrentUser(ctrl, ctrl->user, &status, a, b, c);
	    ARError(ret, status);
	    /* FIX    ret = ARTermination(&status);
	       ARError(ret, status);
	       free(ctrl); */
	}

void
ars_GetListField(control,schema,changedsince=0)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	PPCODE:
	{
	  ARInternalIdList idlist;
	  ARStatusList status;
	  int ret, i;
	  ret = ARGetListField(control,schema,changedsince,&idlist,&status);
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
	  ARDisplayList displayList;
	
	  ret = ARGetListField(control, schema, (ARTimestamp)0, &idList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (! ARError(ret, status)) {
	    for (loop=0; loop<idList.numItems; loop++) {
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], NULL, NULL, NULL, NULL, NULL, NULL, &displayList, NULL, NULL, NULL, NULL, NULL, &status);
	      if (ARError(ret, status))
	        break;
	      if (displayList.numItems < 1) {
		/* printf("No fields were returned in display list\n"); */
		break;
	      }
	      if (strcasecmp(field_name,displayList.displayList[0].label)==0){
		XPUSHs(sv_2mortal(newSViv(idList.internalIdList[loop])));
#ifndef WASTE_MEM
		FreeARDisplayList(&displayList, FALSE);
#endif
		break;
	      }
#ifndef WASTE_MEM
	      FreeARDisplayList(&displayList, FALSE);
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
	  ARDisplayList displayList;
	  
	  ret = ARGetListField(control, schema, (ARTimestamp)0, &idList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (! ARError(ret, status)) {
	    for (loop=0; loop<idList.numItems; loop++) {
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], NULL, NULL, NULL, NULL, NULL, NULL, &displayList, NULL, NULL, NULL, NULL, NULL, &status);
	      if (ARError(ret, status))
	        break;
	      if (displayList.numItems < 1) {
		/* printf("No fields were returned in display list\n"); */
		continue;
	      }
	      XPUSHs(sv_2mortal(newSVpv(displayList.displayList[0].label, strlen(displayList.displayList[0].label))));
	      XPUSHs(sv_2mortal(newSViv(idList.internalIdList[loop])));
#ifndef WASTE_MEM
	      FreeARDisplayList(&displayList, FALSE);
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
	  int a, i, c = (items - 2) / 2;
	  AREntryIdType entryId;
	  ARFieldValueList fieldList;
	  ARStatusList      status;
	  int               ret;
	  unsigned int dataType;
	  
	  RETVAL = "";
	  if (((items - 2) % 2) || c < 1) {
	    ars_errstr = "Invalid number of arguments";
	  } else {
	    fieldList.numItems = c;
	    fieldList.fieldValueList = mallocnn(sizeof(ARFieldValueStruct)*c);
	    for (i=0; i<c; i++) {
	      a = i*2+2;
	      fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
	      if (ARError(ret, status)) {	
		goto create_entry_end;
	      }
	      fieldList.fieldValueList[i].value.dataType = dataType;
	      switch (dataType) {
	      case AR_DATA_TYPE_NULL:
		break;
	      case AR_DATA_TYPE_KEYWORD:
		fieldList.fieldValueList[i].value.u.keyNum = SvIV(ST(a+1));
		break;
	      case AR_DATA_TYPE_INTEGER:
		fieldList.fieldValueList[i].value.u.intVal = SvIV(ST(a+1));
		break;
	      case AR_DATA_TYPE_REAL:
		fieldList.fieldValueList[i].value.u.realVal = SvNV(ST(a+1));
		break;
	      case AR_DATA_TYPE_CHAR:
		fieldList.fieldValueList[i].value.u.charVal = SvPV(ST(a+1),na);
		break;
	      case AR_DATA_TYPE_DIARY:
		fieldList.fieldValueList[i].value.u.diaryVal = SvPV(ST(a+1),na);
		break;
	      case AR_DATA_TYPE_ENUM:
		fieldList.fieldValueList[i].value.u.enumVal = SvIV(ST(a+1));
		break;
	      case AR_DATA_TYPE_TIME:
		fieldList.fieldValueList[i].value.u.timeVal = SvIV(ST(a+1));
		break;
	      case AR_DATA_TYPE_BITMASK:
		fieldList.fieldValueList[i].value.u.maskVal = SvIV(ST(a+1));
		break;
	      default:
		ars_errstr = "unknown field type!";
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
	char *			entry_id
	CODE:
	{
	  int ret;
	  ARStatusList status;
	  int id_len;
	  AREntryIdType pad_entry;
	  
	  /* pad left of entry_id with zeros */
	  memset(pad_entry, '0', AR_MAX_ENTRYID_SIZE);
	  id_len = strlen(entry_id);
	  if (id_len > AR_MAX_ENTRYID_SIZE) {
	    ars_errstr = "entry id is too long";
	    RETVAL=-1;
	  } else {
	    sprintf(pad_entry+(AR_MAX_ENTRYID_SIZE-id_len), "%s", entry_id);
	    
	    ret = ARDeleteEntry(ctrl, schema, pad_entry, &status);
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (ARError(ret, status))
	      RETVAL=-1;
	    else
	      RETVAL=0;
	  }
	}
	OUTPUT:
	RETVAL

void
ars_GetEntry(ctrl,schema,entry_id,...)
	ARControlStruct *	ctrl
	char *			schema
	char *			entry_id
	PPCODE:
	{
	  int c = items - 3, i, ret;
	  ARInternalIdList  idList;
	  int id_len;
	  ARFieldValueList  fieldList;
	  ARStatusList      status;
	  ARTimestamp       v;
	  
	  if (c < 1) {
	    idList.numItems = 0; /* get all fields */
	  } else {
	    idList.numItems = c;
	    if (!(idList.internalIdList = mallocnn(sizeof(ARInternalId) * c)))
	      goto get_entry_end;
	    for (i=0; i<c; i++)
	      idList.internalIdList[i] = SvIV(ST(i+3));
	  }
	  ret = ARGetEntry(ctrl, schema, entry_id, &idList, &fieldList, &status); 
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
	    XPUSHs(sv_2mortal(newSViv(fieldList.fieldValueList[i].fieldId)));
	    XPUSHs(sv_2mortal(perl_ARValueStruct(&fieldList.fieldValueList[i].value)));
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
	  ARSortList sortList;
	  AREntryListList entryList;
	  unsigned int num_matches;
	  ARStatusList status;
	  int ret;
	  unsigned long field_id;
	  
	  if ((items - 4) % 2) {
	    ars_errstr = "invalid number of arguments";
	    goto getlistentry_end;
	  }
	  sortList.numItems = c;
	  sortList.sortList = mallocnn(sizeof(ARSortStruct)*c);
	  for (i=0; i<c; i++) {
	    sortList.sortList[i].fieldId = SvIV(ST(i*2+4));
	    sortList.sortList[i].sortOrder = SvIV(ST(i*2+5));
	  }
	  ret = ARGetListEntry(ctrl, schema, qualifier, &sortList, maxRetrieve, &entryList, &num_matches, &status);
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
	    XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].entryId, 0)));
	    XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].shortDesc, 0)));
	  }
#ifndef WASTE_MEM
	  FreeAREntryListList(&entryList,FALSE);
#endif
	  getlistentry_end:;
	}

void
ars_GetListSchema(ctrl,changedsince=0)
	ARControlStruct *	ctrl
	unsigned int		changedsince
	PPCODE:
	{
	  ARNameList nameList;
	  ARStatusList status;
	  int i, ret;
	  
	  ret = ARGetListSchema(ctrl, changedsince, &nameList, &status);
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
	}

void
ars_GetListServer()
	PPCODE:
	{
	  ARServerNameList serverList;
	  ARStatusList status;
	  int i, ret;
	  
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
	  ARInternalId field;
	  ARDisplayList displayList;
	  unsigned int enable;
	  ARQualifierStruct *query=mallocnn(sizeof(ARQualifierStruct));
	  ARActiveLinkActionList actionList;
	  char *helpText;
	  ARTimestamp timestamp;
	  ARNameType owner;
	  ARNameType lastChanged;
	  char *changeDiary;
	  ARStatusList status;
	  SV *ref;
	  
	  ret = ARGetActiveLink(ctrl,name,&order,schema,&groupList,&executeMask,&field,&displayList,&enable,query,&actionList,&helpText,&timestamp,owner,lastChanged,&changeDiary,&status);
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
	    hv_store(RETVAL, "field", strlen("field"),
		     newSViv(field), 0);
	    hv_store(RETVAL, "displayList", strlen("displayList"),
		     perl_ARList((ARList *)&displayList,
				 (ARS_fn)perl_ARDisplayStruct,
				 sizeof(ARDisplayStruct)), 0);
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
	    FreeARDisplayList(&displayList,FALSE);
	    FreeARActiveLinkActionList(&actionList,FALSE);
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
	  ARTimestamp timestamp;
	  ARNameType owner;
	  ARNameType lastChanged;
	  ARStatusList status;
	  SV *ref;
	  
	  ret = ARGetFilter(ctrl, name, &order, schema, &opSet, &enable, 
			    query, &actionList, &helpText, &timestamp, 
			    owner, lastChanged, &changeDiary, &status);
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
ars_GetCharMenuItems(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  unsigned int refreshCode;
	  ARCharMenuStruct menuDefn;
      	  ARStatusList status;
	  int ret, i;
	  
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
	  ARInternalIdList groupList;
	  ARInternalIdList adminGroupList;
	  AREntryListFieldList getListFields;
	  ARIndexList indexList;
	  char *helpText;
	  ARTimestamp timestamp;
	  ARNameType owner;
	  ARNameType lastChanged;
	  char *changeDiary;
	  
	  RETVAL = newHV();
	  ret = ARGetSchema(ctrl, name, &groupList, &adminGroupList, &getListFields, &indexList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (!ARError(ret,status)) {
	    hv_store(RETVAL, "groupList", strlen("groupList"),
		     perl_ARList((ARList *)&groupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
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
#ifndef WASTE_MEM
	    FreeARInternalIdList(&groupList,FALSE);
	    FreeARInternalIdList(&adminGroupList,FALSE);
	    FreeAREntryListFieldList(&getListFields,FALSE);
	    FreeARIndexList(&indexList,FALSE);
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
ars_GetListActiveLink(ctrl,schema=NULL,changedSince=0)
	ARControlStruct *	ctrl
	char *			schema
	int			changedSince
	PPCODE:
	{
	  ARNameList nameList;
	  ARStatusList status;
	  int ret, i;
	  
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
	/*  ARPermissionList permissions; */
	  ARFieldLimitStruct limit;
	  ARDisplayList displayList;
	  char *helpText;
	  ARTimestamp timestamp;
	  ARNameType owner;
	  ARNameType lastChanged;
	  char *changeDiary;
	  
	  RETVAL = newHV();
	  ret = ARGetFieldCached(ctrl, schema, id, &dataType, &option, &createMode, &defaultVal, NULL /* &permissions */, &limit, &displayList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &Status);
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
	    /* FIX - permissions */
	    hv_store(RETVAL, "limit", strlen("limit"),
		     perl_ARFieldLimitStruct(&limit), 0);
	    hv_store(RETVAL, "displayList", strlen("displayList"),
		     perl_ARList((ARList *)&displayList,
				 (ARS_fn)perl_ARDisplayStruct,
				 sizeof(ARDisplayStruct)), 0);
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
	/*    FreeARPermissionList(&permissions,FALSE); */
	    FreeARFieldLimitStruct(&limit,FALSE);
	    FreeARDisplayList(&displayList,FALSE);
	    if(helpText)
	      free(helpText);
	    if(changeDiary)
	      free(changeDiary);
#endif
	  }
	}
	OUTPUT:
	RETVAL

int
ars_SetEntry(ctrl,schema,entry_id,getTime,...)
	ARControlStruct *	ctrl
	char *			schema
	char *			entry_id
	unsigned long		getTime
	CODE:
	{
	  int a, i, c = (items - 4) / 2;
	  AREntryIdType entryId;
	  ARFieldValueList fieldList;
	  ARStatusList      status;
	  int               ret;
	  unsigned int dataType;
	  
	  RETVAL = 0;
	  if (((items - 4) % 2) || c < 1) {
	    ars_errstr = "Invalid number of arguments";
	  } else {
	    fieldList.numItems = c;
	    fieldList.fieldValueList = mallocnn(sizeof(ARFieldValueStruct)*c);
	    for (i=0; i<c; i++) {
	      a = i*2+4;
	      fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
	      
	      if (! SvOK(ST(a+1))) {
		/* pass a NULL */
		fieldList.fieldValueList[i].value.dataType = AR_DATA_TYPE_NULL;
	/*	printf("undef,"); */
	      } else {
	/*	printf("%s,",SvPV(ST(a+1),na)); */
		/* determine data type and pass value */
		ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
		if (ARError(ret, status)) {
		  goto set_entry_end;
		}
		fieldList.fieldValueList[i].value.dataType = dataType;
		switch (dataType) {
		case AR_DATA_TYPE_NULL:
		  break;
		case AR_DATA_TYPE_KEYWORD:
		  fieldList.fieldValueList[i].value.u.keyNum = SvIV(ST(a+1));
		  break;
		case AR_DATA_TYPE_INTEGER:
		  fieldList.fieldValueList[i].value.u.intVal = SvIV(ST(a+1));
		  break;
		case AR_DATA_TYPE_REAL:
		  fieldList.fieldValueList[i].value.u.realVal = SvNV(ST(a+1));
		  break;
		case AR_DATA_TYPE_CHAR:
		  fieldList.fieldValueList[i].value.u.charVal = SvPV(ST(a+1),na);
		  break;
		case AR_DATA_TYPE_DIARY:
		  fieldList.fieldValueList[i].value.u.diaryVal = SvPV(ST(a+1),na);
		  break;
		case AR_DATA_TYPE_ENUM:
		  fieldList.fieldValueList[i].value.u.enumVal = SvIV(ST(a+1));
		  break;
		case AR_DATA_TYPE_TIME:
		  fieldList.fieldValueList[i].value.u.timeVal = SvIV(ST(a+1));
		  break;
		case AR_DATA_TYPE_BITMASK:
		  fieldList.fieldValueList[i].value.u.maskVal = SvIV(ST(a+1));
		  break;
		default:
		  ars_errstr = "unknown field type!";
		  goto set_entry_end;
		}
	      }
	    }
	    ret = ARSetEntry(ctrl, schema, entry_id, &fieldList, getTime, &status);
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (! ARError(ret, status)) {
	      RETVAL = 1;
	    }
	  set_entry_end:;
#ifndef WASTE_MEM
	    free(fieldList.fieldValueList);
#endif
	  }
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
	  char *buf, *buf_copy;
	  ARStatusList status;
	  
	  if (items % 2 || c < 1) {
	    ars_errstr = "Invalid number of arguments";
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
		ars_errstr = "Unknown export type";
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
	  
	  if (items % 2) {
	    ars_errstr = "Invalid number of arguments";
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
		  ars_errstr = "Unknown import type";
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

