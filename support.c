/*
$header: /u1/project/ARSperl/ARSperl/RCS/support.c,v 1.25 1999/01/04 21:04:27 jcmurphy Exp jcmurphy $

    ARSperl - An ARS v2 - v5 / Perl5 Integration Kit

    Copyright (C) 1995-2003
	Joel Murphy, jmurphy@acsu.buffalo.edu
        Jeff Murphy, jcmurphy@acsu.buffalo.edu

    This program is free software; you can redistribute it and/or modify
    it under the terms as Perl itself.

    Refer to the file called "Artistic" that accompanies the source 
    distribution of ARSperl (or the one that accompanies the source 
    distribution of Perl itself) for a full description.

    Comments to:  arsperl@arsperl.org
                  (this is a *mailing list* and you must be
                   a subscriber before posting)

    Home Page: http://www.arsperl.org

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

int
compmem(MEMCAST * m1, MEMCAST * m2, int size)
{
	if (m1 && m2 && (size > 0)) {
#ifndef BSD
		return memcmp(m1, m2, size) ? 1 : 0;
#else
		return bcmp(m1, m2, size) ? 1 : 0;
#endif
	}
	return -1;
}

/* copy from m2 to m1 */

int
copymem(MEMCAST * m1, MEMCAST * m2, int size)
{
	if (m1 && m2 && (size > 0)) {
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
void           *
mallocnn(int s)
{
	void           *m = malloc(s ? s : 1);

	if (!m)
		croak("can't malloc");

	memset(m, 0, s ? s : 1);

	return m;
}

void           *
debug_mallocnn(int s, char *file, char *func, int line)
{
	printf("mallocnn(%d) called from %s::%s(), line %d\n", s,
	       file ? file : "UNKNOWN",
	       func ? func : "UNKNOWN",
	       line);
	return mallocnn(s);
}

void
debug_free(void *p, char *file, char *func, int line)
{
	printf("free(0x%X) called from %s::%s(), line %d\n", p,
	       file ? file : "UNKNOWN",
	       func ? func : "UNKNOWN",
	       line);
	free(p);
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

static HV      *err_hash = (HV *) NULL;

int
ARError_reset()
{
	SV             *ni, *t2, **t1;
	AV             *t3;

	/* lookup hash, create if necessary */

	err_hash = perl_get_hv(ERRHASH, TRUE | 0x02);
	if (!err_hash)
		return -1;

	/* if keys already exist, delete them */

	if (hv_exists(err_hash,  EH_COUNT, strlen(EH_COUNT) ))
		t2 = hv_delete(err_hash,  EH_COUNT, strlen(EH_COUNT) , 0);

	/*
	 * the following are array refs. if the _delete call returns the ref,
	 * we should remove all entries from the array and delete it as well.
	 */

	if (hv_exists(err_hash,  EH_TYPE, strlen(EH_TYPE) ))
		t2 = hv_delete(err_hash,  EH_TYPE, strlen(EH_TYPE) , 0);

	if (hv_exists(err_hash,  EH_NUM, strlen(EH_NUM) ))
		t2 = hv_delete(err_hash,  EH_NUM, strlen(EH_NUM) , 0);

	if (hv_exists(err_hash,  EH_TEXT, strlen(EH_TEXT) ))
		t2 = hv_delete(err_hash,  EH_TEXT, strlen(EH_TEXT) , 0);

	/* create numItems key, set to zero */

	ni = newSViv(0);
	if (!ni)
		return -2;
	t1 = hv_store(err_hash,  EH_COUNT, strlen(EH_COUNT) , ni, 0);
	if (!t1)
		return -3;

	/* create array refs (with empty arrays) */

	t3 = newAV();
	if (!t3)
		return -4;
	t1 = hv_store(err_hash,  EH_TYPE, strlen(EH_TYPE) , newRV_noinc((SV *) t3), 0);
	if (!t1 || !*t1)
		return -5;

	t3 = newAV();
	if (!t3)
		return -6;
	t1 = hv_store(err_hash,  EH_NUM, strlen(EH_NUM) , newRV_noinc((SV *) t3), 0);
	if (!t1 || !*t1)
		return -7;

	t3 = newAV();
	if (!t3)
		return -8;
	t1 = hv_store(err_hash,  EH_TEXT, strlen(EH_TEXT) , newRV_noinc((SV *) t3), 0);
	if (!t1 || !*t1)
		return -9;

	return 0;
}

int
ARError_add(unsigned int type, long num, char *text)
{
	SV            **numItems, **messageType, **messageNum, **messageText;
	AV             *a;
	SV             *t2;
	unsigned int    ni, ret = 0;

#ifdef ARSPERL_DEBUG
	printf("ARError_add(%d, %d, %s)\n", type, num, text ? text : "NULL");
#endif

/* this is used to insert 'traceback' (debugging) messages into the
 * error hash. these can be filtered out by modifying the FETCH clause
 * of the ARSERRSTR package in ARS.pm
 */

	switch (type) {
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

	if (!text || !*text)
		return -2;

	/*
	 * fetch base hash and numItems reference, it should already exist
	 * because you should call ARError_reset before using this routine.
	 * if you forgot.. no big deal.. we'll do it for you.
	 */

	err_hash = perl_get_hv(ERRHASH, FALSE);
	if (!err_hash) {
		ret = ARError_reset();
		if (ret != 0)
			return -3;
	}
	numItems = hv_fetch(err_hash,  "numItems", strlen("numItems") , FALSE);
	if (!numItems)
		return -4;
	messageType = hv_fetch(err_hash,  "messageType", strlen("messageType") , FALSE);
	if (!messageType)
		return -5;
	messageNum = hv_fetch(err_hash,  "messageNum", strlen("messageNum") , FALSE);
	if (!messageNum)
		return -6;
	messageText = hv_fetch(err_hash,  "messageText", strlen("messageText") , FALSE);
	if (!messageText)
		return -7;

	/*
	 * add the num, type and text to the appropriate arrays and then
	 * increase the counter by 1 (one).
	 */

	if (!SvIOK(*numItems))
		return -8;
	ni = (int) SvIV(*numItems) + 1;
	(void) sv_setiv(*numItems, ni);

	/* push type, num, and text onto each of the arrays */

	if (!SvROK(*messageType) || (SvTYPE(SvRV(*messageType)) != SVt_PVAV))
		return -9;

	if (!SvROK(*messageNum) || (SvTYPE(SvRV(*messageNum)) != SVt_PVAV))
		return -10;

	if (!SvROK(*messageText) || (SvTYPE(SvRV(*messageText)) != SVt_PVAV))
		return -11;

	a = (AV *) SvRV(*messageType);
	t2 = newSViv(type);
	(void) av_push(a, t2);

	a = (AV *) SvRV(*messageNum);
	t2 = newSViv(num);
	(void) av_push(a, t2);

	a = (AV *) SvRV(*messageText);
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

/* GetListSQL cores for 4.0 in this routine */

int
ARError(int returncode, ARStatusList status)
{
	int             item;
	int             ret = 0;

	for (item = 0; item < status.numItems; item++) {
#if AR_EXPORT_VERSION >= 4
	        char *messageText = (char *)safemalloc(strlen(status.statusList[item].messageText) + 
					     strlen(status.statusList[item].appendedText) + 4);
		sprintf(messageText, "%s (%s)", 
			status.statusList[item].messageText,
			status.statusList[item].appendedText);
#endif
		if (ARError_add(status.statusList[item].messageType,
				status.statusList[item].messageNum,
#if AR_EXPORT_VERSION < 4
				status.statusList[item].messageText
#else
				messageText
#endif
				) != 0)
			ret = 1;
#if AR_EXPORT_VERSION >= 4
		safefree(messageText);
#endif
	}

	if(status.numItems > 0)  {
		FreeARStatusList(&status, FALSE);
		status.numItems = 0;
	}

	return ret;
}


#if AR_EXPORT_VERSION < 6
/* same as ARError, just uses the NT structures instead */

int
NTError(int returncode, NTStatusList status)
{
	int             item, ret = 0;

	for (item = 0; item < status.numItems; item++) {
#if AR_EXPORT_VERSION >= 4
	        char *messageText = (char *)safemalloc(strlen(status.statusList[item].messageText) + 
					     strlen(status.statusList[item].appendedText) + 4);
		sprintf(messageText, "%s (%s)", 
			status.statusList[item].messageText,
			status.statusList[item].appendedText);
#endif
		if (ARError_add(status.statusList[item].messageType,
				status.statusList[item].messageNum,
#if AR_EXPORT_VERSION < 4
				status.statusList[item].messageText
#else
				messageText
#endif
				) != 0)
			ret = 1;
#if AR_EXPORT_VERSION >= 4
		safefree(messageText);
#endif
	}

        if(status.numItems > 0)  {
		FreeNTStatusList(&status, FALSE);
                status.numItems = 0;
        }

	return ret;
}
#endif /* NT routines gone in ars 5.x */


unsigned int
caseLookUpTypeNumber(TypeMapStruct *t, char *s)
{
	int i = 0;
	if(!t || !CVLD(s)) return TYPEMAP_LAST;

	while(strcasecmp(s, t[i].name) && t[i].number != TYPEMAP_LAST)
		i++;

	return t[i].number;
}

char *
lookUpTypeName(TypeMapStruct *t, unsigned int v)
{
	int i = 0;

	if(!t) return "[unknown]";

	while(t[i].number != v && t[i].number != TYPEMAP_LAST)
		i++;
	if(t[i].number == v)
		return t[i].name;
	return "[unknown]";
}

unsigned int
lookUpServerInfoTypeHint(unsigned int itn)
{
	int i = 0;

	while((ServerInfoTypeHints[i].infoTypeNum != itn) &&
	      (ServerInfoTypeHints[i].infoTypeNum != TYPEMAP_LAST))
		i++;

        return ServerInfoTypeHints[i].infoTypeType;
}

unsigned int
strsrch(register char *s, register char c)
{
	register unsigned int n = 0;

	if (!s || !*s)
		return 0;

	for (; *s; s++)
		if (*s == c)
			n++;
	return n;
}

char           *
strappend(char *b, char *a)
{
	char           *t = (char *) 0;

	if (a) {
		if (b) {
			t = (char *) MALLOCNN(strlen(b) + strlen(a) + 1);
			if (t) {
				strcpy(t, b);
				FREE(b);
				strcat(t, a);
				b = t;
			} else
				return (char *) 0;
		} else
			b = strdup(a);
	}
	return b;
}

#if AR_EXPORT_VERSION >= 4
SV             *
perl_ARMessageStruct(ARControlStruct * ctrl, ARMessageStruct * in)
{
	HV             *hash = newHV();

	/*hv_store(hash,  "messageType", strlen("messageType") , newSViv(in->messageType), 0); */
	hv_store(hash,  "messageType", strlen("messageType") , 
		 newSVpv(lookUpTypeName((TypeMapStruct *)StatusReturnTypeMap, 
					in->messageType), 0), 0); 
	hv_store(hash,  "messageNum", strlen("messageNum") , newSViv(in->messageNum), 0);
	hv_store(hash,  "messageText", strlen("messageText") , newSVpv(in->messageText, 0), 0);
	if (in->usePromptingPane)
		hv_store(hash,  "usePromptingPane", strlen("usePromptingPane") , newSViv(1), 0);
	else
		hv_store(hash,  "usePromptingPane", strlen("usePromptingPane") , newSViv(0), 0);

	return newRV_noinc((SV *) hash);
}
#endif

#if AR_EXPORT_VERSION >= 7L
SV             *
perl_AREnumItemStruct(ARControlStruct * ctrl, AREnumItemStruct * in)
{
	HV            *hash = newHV();

	hv_store(hash, "itemName", strlen("itemName"),
		 perl_ARNameType(ctrl, &(in->itemName)), 0);
	hv_store(hash, "itemNumber", strlen("itemNumber"),
		 newSViv(in->itemNumber), 0); /* unsigned long */

	return newRV_noinc((SV *) hash);
}

SV             *
perl_AREnumQueryStruct(ARControlStruct * ctrl, AREnumQueryStruct * in)
{
	HV            *hash = newHV();

	hv_store(hash, "schema", strlen("schema"),
		 perl_ARNameType(ctrl, &(in->schema)), 0);
	hv_store(hash, "server", strlen("server"),
		 newSVpv(in->server, 0), 0);
	hv_store(hash, "qualifier", strlen("qualifier"),
		 newRV_noinc((SV *) perl_qualifier(ctrl,
						   &(in->qualifier))
			     )
		 ,0
		 );
	hv_store(hash, "nameField", strlen("nameField"),
		 perl_ARInternalId(ctrl, &(in->nameField)), 0);
	hv_store(hash, "numberField", strlen("numberField"),
		 perl_ARInternalId(ctrl, &(in->numberField)), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_AREnumLimitsStruct(ARControlStruct * ctrl, AREnumLimitsStruct * in)
{
	HV            *hash = newHV();

	switch (in->listStyle) {
	case AR_ENUM_STYLE_REGULAR:
		hv_store(hash, "regularList", strlen("regularList"),
			 perl_ARList(ctrl, 
				     (ARList *) & in->u.regularList,
				     (ARS_fn) perl_ARNameType,
				     sizeof(ARNameType)
				     )
			 ,0
			 );
		break;
	case AR_ENUM_STYLE_CUSTOM:
		hv_store(hash, "customList", strlen("customList"),
			 perl_ARList(ctrl,
				     (ARList *) & in->u.customList,
				     (ARS_fn) perl_AREnumItemStruct,
				     sizeof(AREnumItemStruct)
				     )
			 ,0
			 );
		break;
	case AR_ENUM_STYLE_QUERY:
		hv_store(hash, "queryList", strlen("queryList"),
			 perl_AREnumQueryStruct(ctrl, &(in->u.queryList)), 0);
		break;
	default:
		hv_store(hash, "error", 5,
			 newSVpv("unknown listStyle", 0), 0);
		hv_store(hash, "listStyle", strlen("listStyle"),
			 newSViv(in->listStyle), 0);
		ARError_add(AR_RETURN_ERROR, AP_ERR_ENUM_LISTSTYLE);
	}
	return newRV_noinc((SV *) hash);
}
#endif

#ifdef ARS452
SV             *
perl_ARFilterStatusStruct(ARControlStruct * ctrl, ARFilterStatusStruct * in)
{
	HV             *hash = newHV();

	DBG( ("enter\n") );

	hv_store(hash,  "messageType", strlen("messageType") , newSViv(in->messageType), 0); 
	hv_store(hash,  "messageNum", strlen("messageNum") , newSViv(in->messageNum), 0);
	hv_store(hash,  "messageText", strlen("messageText") , newSVpv(in->messageText, 0), 0);

	return newRV_noinc((SV *) hash);
}
#endif

SV             *
perl_ARStatusStruct(ARControlStruct * ctrl, ARStatusStruct * in)
{
	HV             *hash = newHV();

	DBG( ("enter\n") );

	hv_store(hash,  "messageType", strlen("messageType") , newSViv(in->messageType), 0); 
	hv_store(hash,  "messageNum", strlen("messageNum") , newSViv(in->messageNum), 0);
	hv_store(hash,  "messageText", strlen("messageText") , newSVpv(in->messageText, 0), 0);

#if AR_EXPORT_VERSION >= 4
	DBG( ("doing appendedText [0x%x : %s]\n", 
	      in->appendedText, 
	      SAFEPRT(in->appendedText) ) );

	if( CVLD((in->appendedText)) ) {
	  hv_store(hash,  "appendedText", strlen("appendedText") , newSVpv(in->appendedText, 0), 0);
	} else {
	  hv_store(hash,  "appendedText", strlen("appendedText") , &PL_sv_undef, 0);
	}

	DBG( ("done appendedText\n") );
#endif

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARInternalId(ARControlStruct * ctrl, ARInternalId * in)
{
	return newSViv(*in);
}

SV             *
perl_ARNameType(ARControlStruct * ctrl, ARNameType * in)
{
  /*
	STRLEN len = AR_MAX_NAME_SIZE;
	return newSVpvn(*in, len);
	not clear if the above always allocates max_name_size or 
	of that simply caps the amount of mem it will allocate.

	5.004 doesnt have pvn.. here's equiv..
	SV *value = newSV(StringLength);
	sv_setpvn(value,pStringParam->String,StringLength);
  */
	return newSVpv(*in, 0); 
}

SV             *
perl_ARList(ARControlStruct * ctrl, ARList * in, ARS_fn fn, int size)
{
	int             i;
	AV             *array = newAV();

	for (i = 0; i < in->numItems; i++)
		av_push(array, (*fn) (ctrl, (char *) in->array + (i * size)));

	return newRV_noinc((SV *) array);
}

SV             *
perl_diary(ARControlStruct * ctrl, ARDiaryStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "user", strlen("user") , newSVpv(in->user, 0), 0);
	hv_store(hash,  "timestamp", strlen("timestamp") , newSViv(in->timeVal), 0);
	hv_store(hash,  "value", strlen("value") , newSVpv(in->value, 0), 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_dataType_names(ARControlStruct * ctrl, unsigned int *in)
{
	int             i = 0;

	while ((DataTypeMap[i].number != *in) && (DataTypeMap[i].number != TYPEMAP_LAST))
		i++;

	if (DataTypeMap[i].number != TYPEMAP_LAST)
		return newSVpv( DataTypeMap[i].name, strlen(DataTypeMap[i].name) );

	return newSVpv( "NULL", strlen("NULL") );
}

/* this one is for decoding assign (set) field actions in active links
 * and/or filters.
 */

SV             *
perl_ARValueStructType_Assign(ARControlStruct * ctrl, ARValueStruct * in)
{
	return perl_dataType_names(ctrl, &(in->dataType));
}

SV             *
perl_ARValueStructType(ARControlStruct * ctrl, ARValueStruct * in)
{
	return perl_dataType_names(ctrl, &(in->dataType));
}

/* this one is for decoding assign (set) field actions in active links
 * and/or filters.
 */

SV             *
perl_ARValueStruct_Assign(ARControlStruct * ctrl, ARValueStruct * in)
{
	ARDiaryList     diaryList;
	ARStatusList    status;
	int             ret, i;

	Zero(&status, 1, ARStatusList);

	switch (in->dataType) {
	case AR_DATA_TYPE_KEYWORD:
		for (i = 0; KeyWordMap[i].number != TYPEMAP_LAST; i++) {
			if (KeyWordMap[i].number == in->u.keyNum)
				break;
		}
		return newSVpv(KeyWordMap[i].name, KeyWordMap[i].len);
		break;
	case AR_DATA_TYPE_INTEGER:
		return newSViv(in->u.intVal);
	case AR_DATA_TYPE_REAL:
		return newSVnv(in->u.realVal);
	case AR_DATA_TYPE_DIARY:	/* this is the set-fields special
					 * case */
	case AR_DATA_TYPE_CHAR:
		return newSVpv(in->u.charVal, 0);
	case AR_DATA_TYPE_ENUM:
		return newSViv(in->u.enumVal);
	case AR_DATA_TYPE_TIME:
		return newSViv(in->u.timeVal);
	case AR_DATA_TYPE_BITMASK:
		return newSViv(in->u.maskVal);
#if AR_EXPORT_VERSION >= 3
	case AR_DATA_TYPE_BYTES:
		return perl_ARByteList(ctrl, in->u.byteListVal);
	case AR_DATA_TYPE_ULONG:
		return newSViv(in->u.ulongVal);	/* FIX -- does perl have
						 * unsigned long? */
	case AR_DATA_TYPE_COORDS:
		return perl_ARList(ctrl,
				   (ARList *) in->u.coordListVal,
				   (ARS_fn) perl_ARCoordStruct,
				   sizeof(ARCoordStruct));
#endif
#if AR_EXPORT_VERSION >= 4
	case AR_DATA_TYPE_ATTACH:
		return perl_ARAttach(ctrl, in->u.attachVal);
        case AR_DATA_TYPE_DECIMAL:
                return newSVpv(in->u.decimalVal, 0);
#endif
	case AR_DATA_TYPE_NULL:
	default:
		return newSVsv(&PL_sv_undef);	/* FIX */
	}
}

/* this one is for "normal" field/value decoding */

SV             *
perl_ARValueStruct(ARControlStruct * ctrl, ARValueStruct * in)
{
	ARDiaryList     diaryList;
	ARStatusList    status;
	int             ret, i;

	Zero(&status, 1, ARStatusList);

	switch (in->dataType) {
	case AR_DATA_TYPE_KEYWORD:
		for (i = 0; KeyWordMap[i].number != TYPEMAP_LAST; i++) {
			if (KeyWordMap[i].number == in->u.keyNum)
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
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, in->u.diaryVal, &diaryList, &status);
#else
		ret = ARDecodeDiary(in->u.diaryVal, &diaryList, &status);
#endif
		if (ARError(ret, status)) {
			return newSVsv(&PL_sv_undef);
		} else {
			SV             *array;
			array = perl_ARList(ctrl,
					    (ARList *) & diaryList,
					    (ARS_fn) perl_diary,
					    sizeof(ARDiaryStruct));
#ifndef WASTE_MEM
			FreeARDiaryList(&diaryList, FALSE);
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
		return perl_ARByteList(ctrl, in->u.byteListVal);
	case AR_DATA_TYPE_ULONG:
		return newSViv(in->u.ulongVal);	/* FIX -- does perl have
						 * unsigned long? */
	case AR_DATA_TYPE_COORDS:
		return perl_ARList(ctrl,
				   (ARList *) in->u.coordListVal,
				   (ARS_fn) perl_ARCoordStruct,
				   sizeof(ARCoordStruct));
#endif
#if AR_EXPORT_VERSION >= 4
	case AR_DATA_TYPE_ATTACH:
		return perl_ARAttach(ctrl, in->u.attachVal);
        case AR_DATA_TYPE_DECIMAL:
		return newSVpv(in->u.decimalVal, 0);
#endif
	case AR_DATA_TYPE_NULL:
	default:
		return newSVsv(&PL_sv_undef);	/* FIX */
	}
}

SV             *
perl_ARStatHistoryValue(ARControlStruct * ctrl, ARStatHistoryValue * in)
{
	HV             *hash = newHV();
	hv_store(hash,  "userOrTime", strlen("userOrTime") , newSViv(in->userOrTime), 0);
	hv_store(hash,  "enumVal", strlen("enumVal") , newSViv(in->enumVal), 0);
	return newRV_noinc((SV *) hash);
}

#if AR_EXPORT_VERSION >= 4
SV             *
perl_ARPushFieldsStruct(ARControlStruct * ctrl, ARPushFieldsStruct * in)
{
	HV             *hash = newHV();
	hv_store(hash,  "field", strlen("field") , 
		 perl_ARAssignFieldStruct(ctrl, &(in->field)), 0);
	hv_store(hash,  "assign", strlen("assign") ,
		 perl_ARAssignStruct(ctrl, &(in->assign)), 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARAutomationStruct(ARControlStruct * ctrl, ARAutomationStruct * in)
{
	HV            *hash = newHV();
	hv_store(hash,  "autoServerName", strlen("autoServerName") ,
		 newSVpv(in->autoServerName, 0), 0);
	hv_store(hash,  "clsId", strlen("clsId") ,
		 newSVpv(in->clsId, 0), 0);
	hv_store(hash,  "action", strlen("action") , 
		 newSVpv(in->action, 0), 0);
	if(in->isVisible)
		hv_store(hash,  "isVisible", strlen("isVisible") , 
			 newSVpv("true", 0), 0);
	else 
		hv_store(hash,  "isVisible", strlen("isVisible") , 
			 newSVpv("false", 0), 0);
	hv_store(hash,  "methodList", strlen("methodList") ,
		 perl_ARList(ctrl, 
			     (ARList *)& in->methodList,
			     (ARS_fn) perl_ARCOMMethodStruct,
			     sizeof(ARCOMMethodStruct)), 0);
	return newRV_noinc((SV *)hash);
}

SV             *
perl_ARCOMMethodStruct(ARControlStruct * ctrl, ARCOMMethodStruct * in)
{
	HV            *hash = newHV();
	hv_store(hash,  "methodName", strlen("methodName") ,
		 newSVpv(in->methodName, 0), 0);
	hv_store(hash,  "methodIId", strlen("methodIId") ,
		 newSVpv(in->methodIId, 0), 0);
	hv_store(hash,  "methodType", strlen("methodType") ,
		 newSViv(in->methodType), 0);
	hv_store(hash,  "methodValue", strlen("methodValue") ,
		 perl_ARCOMValueStruct(ctrl, &in->methodValue), 0);
	hv_store(hash,  "parameterList", strlen("parameterList") ,
		 perl_ARList(ctrl,
			     (ARList *)& in->parameterList,
			     (ARS_fn) perl_ARCOMMethodParmStruct,
			     sizeof(ARCOMMethodParmStruct)), 0);
	return newRV_noinc((SV *)hash);
}

SV              *
perl_ARCOMValueStruct(ARControlStruct * ctrl, ARCOMValueStruct * in)
{
	HV           *hash = newHV();
	hv_store(hash,  "valueIId", strlen("valueIId") ,
		 newSVpv(in->valueIId, 0), 0);
	hv_store(hash,  "transId", strlen("transId") ,
		 newSViv(in->transId), 0);
	hv_store(hash,  "valueType", strlen("valueType") ,
		 newSVpv(lookUpTypeName((TypeMapStruct *)ComParmTypeMap,
					in->valueType), 0), 
		 0);
	switch(in->valueType) {
	case AR_COM_PARM_FIELDID:
		hv_store(hash,  "fieldId", strlen("fieldId") ,
			 newSViv(in->u.fieldId), 0);
		break;
	case AR_COM_PARM_VALUE:
		hv_store(hash,  "value", strlen("value") ,
			 perl_ARValueStruct(ctrl,
					    &(in->u.value)), 0);
		break;
	}
	return newRV_noinc((SV *)hash);
}

SV             *
perl_ARCOMMethodParmStruct(ARControlStruct * ctrl, ARCOMMethodParmStruct * in)
{
	HV           *hash = newHV();
	hv_store(hash,  "parmName", strlen("parmName") ,
		 newSVpv(in->parmName, 0), 0);
	hv_store(hash,  "parmType", strlen("parmType") ,
		 newSVpv(lookUpTypeName((TypeMapStruct *)ComParmTypeMap,
					in->parmType), 0), 0);
	hv_store(hash,  "parmValue", strlen("parmValue") ,
		 perl_ARCOMValueStruct(ctrl,
				       &in->parmValue), 0);
	return newRV_noinc((SV *)hash);
}

SV             *
perl_AROpenDlgStruct(ARControlStruct * ctrl, AROpenDlgStruct * in)
{
	HV          *hash = newHV();
	hv_store(hash,  "serverName", strlen("serverName") ,
		 newSVpv(in->serverName, 0), 0);
	hv_store(hash,  "schemaName", strlen("schemaName") ,
		 newSVpv(in->schemaName, 0), 0);
	hv_store(hash,  "vuiLabel", strlen("vuiLabel") ,
		 newSVpv(in->vuiLabel, 0), 0);
	if(in->closeBox)
		hv_store(hash,  "closeBox", strlen("closeBox") ,
			 newSVpv("true", 0), 0);
	else 
		hv_store(hash,  "closeBox", strlen("closeBox") ,
			 newSVpv("false", 0), 0);
	hv_store(hash,  "inputValueFieldPairs", strlen("inputValueFieldPairs") ,
		 perl_ARList(ctrl,
			     (ARList *)& in->inputValueFieldPairs,
			     (ARS_fn) perl_ARFieldAssignStruct,
			     sizeof(ARFieldAssignStruct)), 0);
	hv_store(hash,  "outputValueFieldPairs", strlen("outputValueFieldPairs") ,
		 perl_ARList(ctrl,
			     (ARList *)& in->outputValueFieldPairs,
			     (ARS_fn) perl_ARFieldAssignStruct,
			     sizeof(ARFieldAssignStruct)), 0);
	return newRV_noinc((SV *)hash);
}
#endif

SV             *
perl_ARAssignFieldStruct(ARControlStruct * ctrl, ARAssignFieldStruct * in)
{
	HV             *hash = newHV();
	ARQualifierStruct *qual;
	SV             *ref;
	int             i;

	hv_store(hash,  "server", strlen("server") , newSVpv(in->server, 0), 0);
	hv_store(hash,  "schema", strlen("schema") , newSVpv(in->schema, 0), 0);
	hv_store(hash,  "tag", strlen("tag") , newSViv(in->tag), 0);

#if AR_EXPORT_VERSION >= 3
	/* translate the noMatchOption value into english */

	for (i = 0; NoMatchOptionMap[i].number != TYPEMAP_LAST; i++)
		if (NoMatchOptionMap[i].number == in->noMatchOption)
			break;

	if (NoMatchOptionMap[i].number == TYPEMAP_LAST) {
		char            optnum[25];
		sprintf(optnum, "%u", in->noMatchOption);
		ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		   "perl_ARAssignFieldStruct: unknown noMatchOption value");
		ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, optnum);
	}
	/* if we didn't find a match, store "" */

	hv_store(hash,  "noMatchOption", strlen("noMatchOption") , newSVpv(NoMatchOptionMap[i].name, 0), 0);

	/* translate the multiMatchOption value into english */

	for (i = 0; MultiMatchOptionMap[i].number != TYPEMAP_LAST; i++)
		if (MultiMatchOptionMap[i].number == in->multiMatchOption)
			break;

	if (MultiMatchOptionMap[i].number == TYPEMAP_LAST) {
		char            optnum[25];
		sprintf(optnum, "%u", in->multiMatchOption);
		ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		"perl_ARAssignFieldStruct: unknown multiMatchOption value");
		ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, optnum);
	}
	hv_store(hash,  "multiMatchOption", strlen("multiMatchOption") ,
		 newSVpv(MultiMatchOptionMap[i].name, 0),
		 0);
#endif

	qual = dup_qualifier(ctrl, &in->qualifier);
	ref = newSViv(0);
	sv_setref_pv(ref, "ARQualifierStructPtr", (void *) qual);
	hv_store(hash,  "qualifier", strlen("qualifier") , ref, 0);

	switch (in->tag) {
	case AR_FIELD:
		hv_store(hash,  "fieldId", strlen("fieldId") , newSViv(in->u.fieldId), 0);
		break;
	case AR_STAT_HISTORY:
		hv_store(hash,  "statHistory", strlen("statHistory") ,
		      perl_ARStatHistoryValue(ctrl, &in->u.statHistory), 0);
		break;
	default:
		break;
	}
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARFieldAssignStruct(ARControlStruct * ctrl, ARFieldAssignStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "fieldId", strlen("fieldId") , newSViv(in->fieldId), 0);

	hv_store(hash,  "assignment", strlen("assignment") ,
		 perl_ARAssignStruct(ctrl, &in->assignment), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARDisplayStruct(ARControlStruct * ctrl, ARDisplayStruct * in)
{
	char           *string;
	HV             *hash = newHV();

	/* FIX. use typeMap array? */
	string = in->displayTag;
	hv_store(hash,  "displayTag", strlen("displayTag") , newSVpv(string, 0), 0);
	string = in->label;
	hv_store(hash,  "label", strlen("label") , newSVpv(string, 0), 0);
	switch (in->labelLocation) {
	case AR_DISPLAY_LABEL_LEFT:
		hv_store(hash,  "labelLocation", strlen("labelLocation") , newSVpv("Left", 0), 0);
		break;
	case AR_DISPLAY_LABEL_TOP:
		hv_store(hash,  "labelLocation", strlen("labelLocation") , newSVpv("Top", 0), 0);
		break;
	}
	switch (in->type) {
	case AR_DISPLAY_TYPE_NONE:
		hv_store(hash,  "type", strlen("type") , newSVpv("NONE", 0), 0);
		break;
	case AR_DISPLAY_TYPE_TEXT:
		hv_store(hash,  "type", strlen("type") , newSVpv("TEXT", 0), 0);
		break;
	case AR_DISPLAY_TYPE_NUMTEXT:
		hv_store(hash,  "type", strlen("type") , newSVpv("NUMTEXT", 0), 0);
		break;
	case AR_DISPLAY_TYPE_CHECKBOX:
		hv_store(hash,  "type", strlen("type") , newSVpv("CHECKBOX", 0), 0);
		break;
	case AR_DISPLAY_TYPE_CHOICE:
		hv_store(hash,  "type", strlen("type") , newSVpv("CHOICE", 0), 0);
		break;
	case AR_DISPLAY_TYPE_BUTTON:
		hv_store(hash,  "type", strlen("type") , newSVpv("BUTTON", 0), 0);
		break;
	}
	hv_store(hash,  "length", strlen("length") , newSViv(in->length), 0);
	hv_store(hash,  "numRows", strlen("numRows") , newSViv(in->numRows), 0);
	switch (in->option) {
	case AR_DISPLAY_OPT_VISIBLE:
		hv_store(hash,  "option", strlen("option") , newSVpv("VISIBLE", 0), 0);
		break;
	case AR_DISPLAY_OPT_HIDDEN:
		hv_store(hash,  "option", strlen("option") , newSVpv("HIDDEN", 0), 0);
		break;
	}
	hv_store(hash,  "x", strlen("x") , newSViv(in->x), 0);
	hv_store(hash,  "y", strlen("y") , newSViv(in->y), 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARMacroParmList(ARControlStruct * ctrl, ARMacroParmList * in)
{
	HV             *hash = newHV();
	int             i;

	for (i = 0; i < in->numItems; i++)
		hv_store(hash,  in->parms[i].name, strlen(in->parms[i].name) , newSVpv(in->parms[i].value, 0), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARActiveLinkMacroStruct(ARControlStruct * ctrl, ARActiveLinkMacroStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "macroParms", strlen("macroParms") ,
		 perl_ARMacroParmList(ctrl, &in->macroParms), 0);
	hv_store(hash,  "macroText", strlen("macroText") , newSVpv(in->macroText, 0), 0);
	hv_store(hash,  "macroName", strlen("macroName") , newSVpv(in->macroName, 0), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARFieldCharacteristics(ARControlStruct * ctrl, ARFieldCharacteristics * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "accessOption", strlen("accessOption") , newSViv(in->accessOption), 0);
	hv_store(hash,  "focus", strlen("focus") , newSViv(in->focus), 0);
#if AR_EXPORT_VERSION < 3
	if (in->display)
		hv_store(hash,  "display", strlen("display") ,
			 perl_ARDisplayStruct(ctrl, in->display), 0);
#else
	hv_store(hash,  "props", strlen("props") ,
		 perl_ARList(ctrl,
			     (ARList *) & in->props,
			     (ARS_fn) perl_ARPropStruct,
			     sizeof(ARPropStruct)), 0);
#endif
	if (in->charMenu)
		hv_store(hash,  "charMenu", strlen("charMenu") , newSVpv(in->charMenu, 0), 0);

	hv_store(hash,  "fieldId", strlen("fieldId") , newSViv(in->fieldId), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARDDEStruct(ARControlStruct * ctrl, ARDDEStruct * in)
{				/* FIX */
	return &PL_sv_undef;
}

SV             *
perl_ARActiveLinkActionStruct(ARControlStruct * ctrl, ARActiveLinkActionStruct * in)
{
	HV             *hash = newHV();
	int             i = 0;

	switch (in->action) {
	case AR_ACTIVE_LINK_ACTION_MACRO:
		hv_store(hash,  "macro", strlen("macro") ,
		       perl_ARActiveLinkMacroStruct(ctrl, &in->u.macro), 0);
		break;
	case AR_ACTIVE_LINK_ACTION_FIELDS:
		hv_store(hash,  "assign_fields", strlen("assign_fields") ,
			 perl_ARList(ctrl,
				     (ARList *) & in->u.fieldList,
				     (ARS_fn) perl_ARFieldAssignStruct,
				     sizeof(ARFieldAssignStruct)), 0);
		break;
	case AR_ACTIVE_LINK_ACTION_PROCESS:
		hv_store(hash,  "process", strlen("process") , newSVpv(in->u.process, 0), 0);
		break;
	case AR_ACTIVE_LINK_ACTION_MESSAGE:
#if AR_EXPORT_VERSION >= 4
		hv_store(hash,  "message", strlen("message") ,
			 perl_ARMessageStruct(ctrl, &(in->u.message)), 0);
#else
		hv_store(hash,  "message", strlen("message") ,
			 perl_ARStatusStruct(ctrl, &(in->u.message)), 0);
#endif
		break;
	case AR_ACTIVE_LINK_ACTION_SET_CHAR:
		hv_store(hash,  "characteristics", strlen("characteristics") ,
			 perl_ARFieldCharacteristics(ctrl, &in->u.characteristics), 0);
		break;
        case AR_ACTIVE_LINK_ACTION_DDE:
	        hv_store(hash,  "dde", strlen("dde") ,
			 perl_ARDDEStruct(ctrl, &in->u.dde), 0);
		break;
#if AR_EXPORT_VERSION >= 4
        case AR_ACTIVE_LINK_ACTION_FIELDP:
		/*ARPushFieldsList;*/
		hv_store(hash,  "fieldp", strlen("fieldp") ,
			 perl_ARList(ctrl, 
				     (ARList *)& in->u.pushFieldsList,
				     (ARS_fn) perl_ARPushFieldsStruct,
				     sizeof(ARPushFieldsStruct)), 0);
		break;
        case AR_ACTIVE_LINK_ACTION_SQL:
		/*ARSQLStruct;*/
		hv_store(hash,  "sqlCommand", strlen("sqlCommand") ,
			 perl_ARSQLStruct(ctrl, &(in->u.sqlCommand)), 0);
		break;
        case AR_ACTIVE_LINK_ACTION_AUTO:
		/*ARAutomationStruct;*/
		hv_store(hash,  "automation", strlen("automation") ,
			 perl_ARAutomationStruct(ctrl,
						 &in->u.automation), 0);
		break;
        case AR_ACTIVE_LINK_ACTION_OPENDLG:
		/*AROpenDlgStruct;*/
		hv_store(hash,  "openDlg", strlen("openDlg") ,
			 perl_AROpenDlgStruct(ctrl,
					      &in->u.openDlg), 0);
		break;
        case AR_ACTIVE_LINK_ACTION_COMMITC:
		/*ARCommitChangesStruct;*/
        case AR_ACTIVE_LINK_ACTION_CLOSEWND:
		/*ARCloseWndStruct;*/
        case AR_ACTIVE_LINK_ACTION_CALLGUIDE:
		/*ARCallGuideStruct;*/
        case AR_ACTIVE_LINK_ACTION_EXITGUIDE:
		/*ARExitGuideStruct;*/
        case AR_ACTIVE_LINK_ACTION_GOTOGUIDELABEL:
		/*ARGotoGuideLabelStruct;*/
        case AR_ACTIVE_LINK_ACTION_WAIT:
		/*ARWaitStruct;*/
        case AR_ACTIVE_LINK_ACTION_GOTOACTION:
		/*ARGotoActionStruct;*/
#endif
        case AR_ACTIVE_LINK_ACTION_NONE:
		hv_store(hash,  "none", strlen("none") , &PL_sv_undef, 0);
		break;
	default:
		hv_store(hash,  "[unknown]", strlen("[unknown]") , &PL_sv_undef, 0);
		break;
	}
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARFilterActionNotify(ARControlStruct * ctrl, ARFilterActionNotify * in)
{
	HV             *hash = newHV();

	DBG( ("enter\n") );

	hv_store(hash,  "user", strlen("user") , newSVpv(in->user, 0), 0);
	if (in->notifyText)
		hv_store(hash,  "notifyText", strlen("notifyText") ,
			 newSVpv(in->notifyText, 0), 0);
	hv_store(hash,  "notifyPriority", strlen("notifyPriority") ,
		 newSViv(in->notifyPriority), 0);
	hv_store(hash,  "notifyMechanism", strlen("notifyMechanism") ,
		 newSViv(in->notifyMechanism), 0);
	hv_store(hash,  "notifyMechanismXRef", strlen("notifyMechanismXRef") ,
		 newSViv(in->notifyMechanismXRef), 0);
	if (in->subjectText)
		hv_store(hash,  "subjectText", strlen("subjectText") ,
			 newSVpv(in->subjectText, 0), 0);
	hv_store(hash,  "fieldIdListType", strlen("fieldIdListType") ,
		 newSViv(in->fieldIdListType), 0);
	hv_store(hash,  "fieldList", strlen("fieldList") ,
		 perl_ARList(ctrl,
			     (ARList *) & in->fieldIdList,
			     (ARS_fn) perl_ARInternalId,
			     sizeof(ARInternalId)), 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARFilterActionStruct(ARControlStruct * ctrl, ARFilterActionStruct * in)
{
	HV             *hash = newHV();

	DBG( ("enter\n") );

	DBG( ("action %d\n", in->action) );

	switch (in->action) {
	case AR_FILTER_ACTION_NOTIFY:
		hv_store(hash,  "notify", strlen("notify") ,
			 perl_ARFilterActionNotify(ctrl, &in->u.notify), 0);
		break;
	case AR_FILTER_ACTION_MESSAGE:
#ifdef ARS452
		DBG( ("452+ message action\n") );
		hv_store(hash,  "message", strlen("message") ,
			 perl_ARFilterStatusStruct(ctrl, &in->u.message), 0);
#else
		DBG( ("pre-452 message action\n") );
                hv_store(hash,  "message", strlen("message") ,
			 perl_ARStatusStruct(ctrl, &in->u.message), 0);
#endif
		break;
	case AR_FILTER_ACTION_LOG:
		hv_store(hash,  "log", strlen("log") , newSVpv(in->u.logFile, 0), 0);
		break;
	case AR_FILTER_ACTION_FIELDS:
		hv_store(hash,  "assign_fields", strlen("assign_fields") ,
			 perl_ARList(ctrl,
				     (ARList *) & in->u.fieldList,
				     (ARS_fn) perl_ARFieldAssignStruct,
				     sizeof(ARFieldAssignStruct)), 0);
		break;
	case AR_FILTER_ACTION_PROCESS:
		hv_store(hash,  "process", strlen("process") , newSVpv(in->u.process, 0), 0);
		break;
#if AR_EXPORT_VERSION >= 4
 /* added cases for new ACTIONS in ARS v4.0 API, Geoff Endresen, 6/28/2000
    copied from AR_ACTIVE_LINK_ACTION_FIELP */
         case AR_FILTER_ACTION_FIELDP:
                 /*ARPushFieldsList;*/
                 hv_store(hash,  "fieldp", strlen("fieldp") ,
                          perl_ARList(ctrl,
                                      (ARList *)& in->u.pushFieldsList,
                                      (ARS_fn) perl_ARPushFieldsStruct,
                                      sizeof(ARPushFieldsStruct)),0);
                 break;
         case AR_FILTER_ACTION_SQL:
                 /*ARSQLStruct;*/
                 hv_store(hash,  "sqlCommand", strlen("sqlCommand") ,
                          perl_ARSQLStruct(ctrl, &(in->u.sqlCommand)),0);
                 break;
         case AR_FILTER_ACTION_GOTOACTION:
                 /*ARGotoActionStruct;*/
 
#endif
	case AR_FILTER_ACTION_NONE:
	default:
		hv_store(hash,  "none", strlen("none") , &PL_sv_undef, 0);
		break;
	}

	DBG( ("leave\n") );

	return newRV_noinc((SV *) hash);
}

SV             *
perl_expandARCharMenuStruct(ARControlStruct * ctrl,
			    ARCharMenuStruct * in)
{
	ARCharMenuStruct menu, *which;
	int             ret, i;
	ARStatusList    status;
	AV             *array;
	SV             *sub;
	char           *string;

	DBG( ("enter\n") );

	Zero(&status, 1, ARStatusList);
	Zero(&menu,   1, ARCharMenuStruct);

	if (in->menuType != AR_CHAR_MENU_LIST) {
		DBG( ("input menu is not a LIST, calling ARExpandCharMenu\n") );
		ret = ARExpandCharMenu(ctrl, in, &menu, &status);
		DBG( ("ARECM ret=%d\n", ret) );
		if (ARError(ret, status)) {
			FreeARCharMenuStruct(&menu, FALSE);
			return &PL_sv_undef;
		}
		which = &menu;
	} else {
		DBG( ("input menu is a LIST, just using that\n") );
		which = in;
	}

	array = newAV();

	DBG( ("expanded menu has %d items\n", 
	      which->u.menuList.numItems) );

	for (i = 0; i < which->u.menuList.numItems; i++) {
		string = which->u.menuList.charMenuList[i].menuLabel;
		av_push(array, newSVpv(string, strlen(string)));
		switch (which->u.menuList.charMenuList[i].menuType) {
		case AR_MENU_TYPE_VALUE:
			string = which->u.menuList.charMenuList[i].u.menuValue;
			av_push(array, newSVpv(string, strlen(string)));
			break;
		case AR_MENU_TYPE_MENU:
			sub = perl_expandARCharMenuStruct(ctrl,
			     which->u.menuList.charMenuList[i].u.childMenu);
			if (!sub) {
				FreeARCharMenuStruct(&menu, FALSE);
				return &PL_sv_undef;
			}
			av_push(array, sub);
			break;
		case AR_MENU_TYPE_NONE:
		default:
			av_push(array, &PL_sv_undef);
			break;
		}
	}

	FreeARCharMenuStruct(&menu, FALSE);
	return newRV_noinc((SV *) array);
}

SV             *
perl_MenuRefreshCode2Str(ARControlStruct * ctrl, unsigned int rc)
{
	int             i;

	for (i = 0;
	     CharMenuRefreshCodeTypeMap[i].number != TYPEMAP_LAST &&
	     CharMenuRefreshCodeTypeMap[i].number != rc;
	     i++);

	return newSVpv(CharMenuRefreshCodeTypeMap[i].name, 0);
}


SV             *
perl_AREntryListFieldStruct(ARControlStruct * ctrl, AREntryListFieldStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "fieldId", strlen("fieldId") , newSViv(in->fieldId), 0);
	hv_store(hash,  "columnWidth", strlen("columnWidth") , newSViv(in->columnWidth), 0);
	hv_store(hash,  "separator", strlen("separator") , newSVpv(in->separator, 0), 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARIndexStruct(ARControlStruct * ctrl, ARIndexStruct * in)
{
	HV             *hash = newHV();
	AV             *array = newAV();
	int             i;

	if (in->unique)
		hv_store(hash,  "unique", strlen("unique") , newSViv(1), 0);
	for (i = 0; i < in->numFields; i++)
		av_push(array, perl_ARInternalId(ctrl, &(in->fieldIds[i])));
	hv_store(hash,  "fieldIds", strlen("fieldIds") , newRV_noinc((SV *) array), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARFieldLimitStruct(ARControlStruct * ctrl, ARFieldLimitStruct * in)
{
	HV             *hash = newHV();

	DBG( ("FLS dt=%d\n", in->dataType) );
	switch (in->dataType) {
	case AR_DATA_TYPE_KEYWORD:
	  return &PL_sv_undef;

	case AR_DATA_TYPE_INTEGER:
		hv_store(hash,  "min", strlen("min") , newSViv(in->u.intLimits.rangeLow), 0);
		hv_store(hash,  "max", strlen("max") , newSViv(in->u.intLimits.rangeHigh), 0);
		return newRV_noinc((SV *) hash);

	case AR_DATA_TYPE_REAL:
		hv_store(hash,  "min", strlen("min") , newSVnv(in->u.realLimits.rangeLow), 0);
		hv_store(hash,  "max", strlen("max") , newSVnv(in->u.realLimits.rangeHigh), 0);
		hv_store(hash,  "precision", strlen("precision") ,
			 newSViv(in->u.realLimits.precision), 0);
		return newRV_noinc((SV *) hash);

	case AR_DATA_TYPE_CHAR:
		hv_store(hash,  "maxLength", strlen("maxLength") ,
			 newSViv(in->u.charLimits.maxLength), 0);

		switch (in->u.charLimits.menuStyle) {
		case AR_MENU_APPEND:
			hv_store(hash,  "menuStyle", strlen("menuStyle") , newSVpv("append", 0), 0);
			break;
		case AR_MENU_OVERWRITE:
			hv_store(hash,  "menuStyle", strlen("menuStyle") , newSVpv("overwrite", 0), 0);
			break;
		}

		switch (in->u.charLimits.qbeMatchOperation) {
		case AR_QBE_MATCH_ANYWHERE:
			hv_store(hash,  "match", strlen("match") , newSVpv("anywhere", 0), 0);
			break;
		case AR_QBE_MATCH_LEADING:
			hv_store(hash,  "match", strlen("match") , newSVpv("leading", 0), 0);
			break;
		case AR_QBE_MATCH_EQUAL:
			hv_store(hash,  "match", strlen("match") , newSVpv("equal", 0), 0);
			break;
		}

		hv_store(hash,  "charMenu", strlen("charMenu") ,
			 newSVpv(in->u.charLimits.charMenu, 0), 0);
		if(in->u.charLimits.pattern) {
			hv_store(hash,  "pattern", strlen("pattern") ,
				 newSVpv(in->u.charLimits.pattern, 0), 0);
		} else {
			hv_store(hash, "pattern", strlen("pattern"),
				 &PL_sv_undef, 0);
		}

		switch (in->u.charLimits.fullTextOptions) {
		case AR_FULLTEXT_OPTIONS_NONE:
			hv_store(hash,  "fullTextOptions", strlen("fullTextOptions") , newSVpv("none", 0), 0);
			break;
		case AR_FULLTEXT_OPTIONS_INDEXED:
			hv_store(hash,  "fullTextOptions", strlen("fullTextOptions") , newSVpv("indexed", 0), 0);
			break;
		}

		return newRV_noinc((SV *) hash);

	case AR_DATA_TYPE_DIARY:
		switch (in->u.diaryLimits.fullTextOptions) {
		case AR_FULLTEXT_OPTIONS_NONE:
			hv_store(hash,  "fullTextOptions", strlen("fullTextOptions") , newSVpv("none", 0), 0);
			break;
		case AR_FULLTEXT_OPTIONS_INDEXED:
			hv_store(hash,  "fullTextOptions", strlen("fullTextOptions") , newSVpv("indexed", 0), 0);
			break;
		}
		return newRV_noinc((SV *) hash);

	case AR_DATA_TYPE_ENUM:
		/*
		 * as of 5.x, eunmLimits went from a list of ARNameType
		 * to an AREnumLimitsStruct (true for 5.0.1 and beyond - 
		 * 5.0beta still had it as a list of NameTypes)
		 */

#if AR_EXPORT_VERSION >= 7L
		DBG( ("case ENUM api v7+\n") );
		hv_store(hash,  "enumLimits", strlen("enumLimits") ,
			 perl_AREnumLimitsStruct(ctrl,
						 &(in->u.enumLimits))
			 ,0
			 );
#else
		DBG( ("case ENUM api v-6\n") );
		hv_store(hash,  "enumLimits", strlen("enumLimits") ,
			 perl_ARList(ctrl, (ARList *) & (in->u.enumLimits),
				     (ARS_fn) perl_ARNameType, 
				     sizeof(ARNameType)),
			 0);
#endif
		return newRV_noinc((SV *) hash);


	case AR_DATA_TYPE_TIME:
	  return &PL_sv_undef;

	case AR_DATA_TYPE_BITMASK:

		DBG( ("case BITMASK\n") );
#if AR_EXPORT_VERSION >= 7L
		hv_store(hash,  "maskLimits", strlen("maskLimits") ,
			 perl_AREnumLimitsStruct(ctrl,
						 &(in->u.enumLimits))
			 ,0
			 );
#else
		hv_store(hash,  "maskLimits", strlen("maskLimits") ,
			 perl_ARList(ctrl, (ARList *) & (in->u.enumLimits),
				     (ARS_fn) perl_ARNameType, 
				     sizeof(ARNameType)),
			 0);
#endif
		return newRV_noinc((SV *) hash);

	case AR_DATA_TYPE_BYTES:
	case AR_DATA_TYPE_DECIMAL:
	case AR_DATA_TYPE_ATTACH:
	case AR_DATA_TYPE_CURRENCY:
	case AR_DATA_TYPE_DATE:
	case AR_DATA_TYPE_TIME_OF_DAY:

	case AR_DATA_TYPE_NULL:
	default:
		/* no meaningful limits */
		return &PL_sv_undef;
	}
}

SV             *
perl_ARAssignStruct(ARControlStruct * ctrl, ARAssignStruct * in)
{
	HV             *hash = newHV();

	switch (in->assignType) {
	case AR_ASSIGN_TYPE_NONE:
		hv_store(hash,  "none", strlen("none") , &PL_sv_undef, 0);
		break;
	case AR_ASSIGN_TYPE_VALUE:

		/*
		 * we will also be storing the specific AR_DATA_TYPE_* since
		 * this is used in the rev_* routines to translate back. we
		 * wouldnt be able to derive the datatype in any other
		 * fashion.
		 */

		/*
		 * 1998-03-12 patch the assign struct stores assign field
		 * actions on diary fields as character assignments (makes
		 * sense). but this means we can't use the standard
		 * perl_ARValueStruct call to decode. we need to have a
		 * 'special' one that will decode DIARY or CHAR types as if
		 * they are both CHAR types.
		 */

		hv_store(hash,  "value", strlen("value") ,
			 perl_ARValueStruct_Assign(ctrl, &in->u.value), 0);
		hv_store(hash,  "valueType", strlen("valueType") ,
		      perl_ARValueStructType_Assign(ctrl, &in->u.value), 0);
		break;
	case AR_ASSIGN_TYPE_FIELD:
		hv_store(hash,  "field", strlen("field") ,
			 perl_ARAssignFieldStruct(ctrl, in->u.field), 0);
		break;
	case AR_ASSIGN_TYPE_PROCESS:
		hv_store(hash,  "process", strlen("process") , newSVpv(in->u.process, 0), 0);
		break;
	case AR_ASSIGN_TYPE_ARITH:
		hv_store(hash,  "arith", strlen("arith") ,
			 perl_ARArithOpAssignStruct(ctrl, in->u.arithOp), 0);
		break;
	case AR_ASSIGN_TYPE_FUNCTION:
		hv_store(hash,  "function", strlen("function") ,
		      perl_ARFunctionAssignStruct(ctrl, in->u.function), 0);
		break;
	case AR_ASSIGN_TYPE_DDE:
		hv_store(hash,  "dde", strlen("dde") , perl_ARDDEStruct(ctrl, in->u.dde), 0);
		break;
#if AR_EXPORT_VERSION >= 3
	case AR_ASSIGN_TYPE_SQL:
		hv_store(hash,  "sql", strlen("sql") , perl_ARAssignSQLStruct(ctrl, in->u.sql), 0);
		break;
#endif				/* ARS 3.x */
	default:
		hv_store(hash,  "none", strlen("none") , &PL_sv_undef, 0);
		break;
	}
	return newRV_noinc((SV *) hash);
}

#if AR_EXPORT_VERSION >= 4
SV             *
perl_ARSQLStruct(ARControlStruct * ctrl, ARSQLStruct * in)
{
	HV             *hash = newHV();
	hv_store(hash,  "server", strlen("server") , newSVpv(in->server, 0), 0);
	hv_store(hash,  "command", strlen("command") , newSVpv(in->command, 0), 0);
	return newRV_noinc((SV *) hash);
}
#endif

#if AR_EXPORT_VERSION >= 3
SV             *
perl_ARAssignSQLStruct(ARControlStruct * ctrl, ARAssignSQLStruct * in)
{
	HV             *hash = newHV();
	int             i;

	hv_store(hash,  "server", strlen("server") , newSVpv(in->server, 0), 0);
	hv_store(hash,  "sqlCommand", strlen("sqlCommand") , newSVpv(in->sqlCommand, 0), 0);
	hv_store(hash,  "valueIndex", strlen("valueIndex") , newSViv(in->valueIndex), 0);

	/* translate the noMatchOption value into english */

	for (i = 0; NoMatchOptionMap[i].number != TYPEMAP_LAST; i++)
		if (NoMatchOptionMap[i].number == in->noMatchOption)
			break;

	if (NoMatchOptionMap[i].number == TYPEMAP_LAST) {
		char            optnum[25];
		sprintf(optnum, "%u", in->noMatchOption);
		ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		     "perl_ARAssignSQLStruct: unknown noMatchOption value");
		ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, optnum);
	}
	/* if we didn't find a match, store "" */

	hv_store(hash,  "noMatchOption", strlen("noMatchOption") , newSVpv(NoMatchOptionMap[i].name, 0), 0);

	/* translate the multiMatchOption value into english */

	for (i = 0; MultiMatchOptionMap[i].number != TYPEMAP_LAST; i++)
		if (MultiMatchOptionMap[i].number == in->multiMatchOption)
			break;

	if (MultiMatchOptionMap[i].number == TYPEMAP_LAST) {
		char            optnum[25];
		sprintf(optnum, "%u", in->multiMatchOption);
		ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		"perl_ARAssignFieldStruct: unknown multiMatchOption value");
		ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, optnum);
	}
	hv_store(hash,  "multiMatchOption", strlen("multiMatchOption") ,
		 newSVpv(MultiMatchOptionMap[i].name, 0), 0);

	return newRV_noinc((SV *) hash);
}
#endif				/* ARS3.x */

SV             *
perl_ARFunctionAssignStruct(ARControlStruct * ctrl, ARFunctionAssignStruct * in)
{
	AV             *array = newAV();
	int             i;

	for (i = 0; FunctionMap[i].number != TYPEMAP_LAST; i++)
		if (FunctionMap[i].number == in->functionCode)
			break;

	av_push(array, newSVpv(FunctionMap[i].name, 0));

	for (i = 0; i < in->numItems; i++)
		av_push(array, perl_ARAssignStruct(ctrl, &in->parameterList[i]));

	return newRV_noinc((SV *) array);
}

SV             *
perl_ARArithOpAssignStruct(ARControlStruct * ctrl, ARArithOpAssignStruct * in)
{
	HV             *hash = newHV();
	int             i;

	for (i = 0; ArithOpMap[i].number != TYPEMAP_LAST; i++)
		if (ArithOpMap[i].number == in->operation)
			break;

	hv_store(hash,  "oper", strlen("oper") , newSVpv(ArithOpMap[i].name, 0), 0);

	if (in->operation == AR_ARITH_OP_NEGATE) {
		hv_store(hash,  "left", strlen("left") , perl_ARAssignStruct(ctrl, &in->operandLeft), 0);
	} else {
		hv_store(hash,  "right", strlen("right") , perl_ARAssignStruct(ctrl, &in->operandRight), 0);
		hv_store(hash,  "left", strlen("left") , perl_ARAssignStruct(ctrl, &in->operandLeft), 0);
	}
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARPermissionList(ARControlStruct * ctrl, ARPermissionList * in, int permType)
{
	HV             *hash = newHV();
	char            groupid[20];
	int             i, j;
	TypeMapStruct  *tmap;

	switch (permType) {
	case PERMTYPE_SCHEMA:
		tmap = (TypeMapStruct *) SchemaPermissionTypeMap;
		break;
	case PERMTYPE_FIELD:
	default:
		tmap = (TypeMapStruct *) FieldPermissionTypeMap;
	}

	for (i = 0; i < in->numItems; i++) {
		sprintf(groupid, "%i", (int) in->permissionList[i].groupId);
		for (j = 0; tmap[j].number != TYPEMAP_LAST; j++) {
			if (tmap[j].number == in->permissionList[i].permissions)
				break;
		}
		hv_store(hash,  groupid, strlen(groupid) , newSVpv( tmap[j].name, strlen(tmap[j].name) ), 0);
	}

	return newRV_noinc((SV *) hash);
}

#if AR_EXPORT_VERSION >= 3

/* ROUTINE
 *   my_strtok(string, token-buffer, token-buffer-length, separator)
 *
 * DESCRIPTION
 *   since strtok doesn't handle things like:
 *     "a||b" -> "a" "" "b"
 *   well, i wrote this tokenizer which behaves more like
 *   the perl "split" command.
 *
 * RETURNS
 *   non-NULL char pointer on success (more string to process)
 *   NULL char ptr on end-of-string
 *
 * AUTHOR
 *   jeff murphy
 */

static char    *
my_strtok(char *str, char *tok, int tlen, char sep)
{
	char           *p = str;
	int             i;

	/* str is NULL, we're done */

	if (!str && !*str)
		return NULL;

	for (i = 0; i < tlen; i++)
		*(tok + i) = 0;

	/* if p is sep, then tok is null */

	if (*p == sep) {
		*tok = 0;
		return p;
	}
	/* else copy p to tok until end of string or sep */

	while (*p && (*p != sep)) {
		*tok = *p;
		p++;
		tok++;
	}

	*(tok) = 0;
	return p;
}

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
perl_BuildEntryList(ARControlStruct * ctrl, AREntryIdList * entryList, char *entry_id)
{
	if (entry_id && *entry_id) {
		/*
		 * if the entry id is too long, it is probably refering to a
		 * join schema. split it, and fill in the entryIdList with
		 * the components.
		 */

		if (strlen(entry_id) > AR_MAX_ENTRYID_SIZE) {
			char           *eid_dup, *eid_orig, *tok;
			int             tn = 0, len = 0;

			if (strchr(entry_id, AR_ENTRY_ID_SEPARATOR) == (char *) NULL) {
				ARError_add(AR_RETURN_ERROR, AP_ERR_EID_SEP);
				return -1;
			}
			eid_dup = strdup(entry_id);
			eid_orig = eid_dup;	/* remember who we are */
			tok = strdup(entry_id);
			len = strlen(tok);

			if (!eid_dup || !tok)
				croak("perl_BuildEntryList out of memory: can't strdup entry-id buffer.");

			entryList->numItems = strsrch(eid_dup, AR_ENTRY_ID_SEPARATOR) + 1;
			entryList->entryIdList = (AREntryIdType *) MALLOCNN(sizeof(AREntryIdType) *
						       entryList->numItems);

			if (!entryList->entryIdList)
				croak("perl_BuildEntryList out of memory: can't allocate entryIdList buffer(s).");

			/*
			 * now, foreach separate entry-id in the conglomerate
			 * entry-id, stick them into the entryIdList fields.
			 */

			tn = 0;
			eid_dup = my_strtok(eid_dup, tok, len, AR_ENTRY_ID_SEPARATOR);
			while (*eid_dup) {
				(void) strncpy(entryList->entryIdList[tn], tok, sizeof(AREntryIdType));
				*(entryList->entryIdList[tn++] + AR_MAX_ENTRYID_SIZE + 1) = 0;
				eid_dup = my_strtok(eid_dup + 1, tok, len, AR_ENTRY_ID_SEPARATOR);
			}

			(void) strncpy(entryList->entryIdList[tn], tok, sizeof(AREntryIdType));
			*(entryList->entryIdList[tn++] + AR_MAX_ENTRYID_SIZE + 1) = 0;

			FREE(eid_orig);
			FREE(tok);
			return 0;
		} else {	/* "normal" entry-id */
			entryList->numItems = 1;
			entryList->entryIdList = MALLOCNN(sizeof(AREntryIdType) * 1);
			strcpy(entryList->entryIdList[0], entry_id);

			return 0;
		}
	} else
		ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EID);
	return -1;
}

SV             *
perl_ARPropStruct(ARControlStruct * ctrl, ARPropStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "prop", strlen("prop") , newSViv(in->prop), 0);
	hv_store(hash,  "value", strlen("value") , perl_ARValueStruct(ctrl, &in->value), 0);
	hv_store(hash,  "valueType", strlen("valueType") ,
		 perl_ARValueStructType(ctrl, &in->value), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARPropList(ARControlStruct * ctrl, ARPropList * in) 
{
	AV             *array = newAV();
	int             i;

	for(i = 0 ; i < in->numItems ; i++) 
		av_push(array, 
			perl_ARPropStruct(ctrl, &(in->props[i]) ));

	return newRV_noinc((SV *)array);
}

SV             *
perl_ARDisplayInstanceStruct(ARControlStruct * ctrl, ARDisplayInstanceStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "vui", strlen("vui") , newSViv(in->vui), 0);
	hv_store(hash,  "props", strlen("props") ,
		 perl_ARList(ctrl,
			     (ARList *) & in->props,
			     (ARS_fn) perl_ARPropStruct,
			     sizeof(ARPropStruct)), 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARDisplayInstanceList(ARControlStruct * ctrl, ARDisplayInstanceList * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "commonProps", strlen("commonProps") ,
		 perl_ARList(ctrl,
			     (ARList *) & in->commonProps,
			     (ARS_fn) perl_ARPropStruct,
			     sizeof(ARPropStruct)), 0);

	/*
	 * the part of ARDisplayInstanceList after ARPropList looks like
	 * ARS's other list structures, so take address of numItems field and
	 * pass that to perl_ARList
	 */

	hv_store(hash,  "dInstanceList", strlen("dInstanceList") ,
		 perl_ARList(ctrl,
			     (ARList *) & in->numItems,
			     (ARS_fn) perl_ARDisplayInstanceStruct,
			     sizeof(ARDisplayInstanceStruct)), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARFieldMappingStruct(ARControlStruct * ctrl, ARFieldMappingStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "fieldType", strlen("fieldType") , newSViv(in->fieldType), 0);
	switch (in->fieldType) {
	case AR_FIELD_JOIN:
		hv_store(hash,  "join", strlen("join") , perl_ARJoinMappingStruct(ctrl, &in->u.join), 0);
		break;
	case AR_FIELD_VIEW:
		hv_store(hash,  "view", strlen("view") , perl_ARViewMappingStruct(ctrl, &in->u.view), 0);
		break;
	}
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARJoinMappingStruct(ARControlStruct * ctrl, ARJoinMappingStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "schemaIndex", strlen("schemaIndex") , newSViv(in->schemaIndex), 0);
	hv_store(hash,  "realId", strlen("realId") , newSViv(in->realId), 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARViewMappingStruct(ARControlStruct * ctrl, ARViewMappingStruct * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "fieldName", strlen("fieldName") , newSVpv(in->fieldName, 0), 0);

	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARJoinSchema(ARControlStruct * ctrl, ARJoinSchema * in)
{
	HV             *hash = newHV();
	SV             *joinQual = newSViv(0);

	hv_store(hash,  "memberA", strlen("memberA") , newSVpv(in->memberA, 0), 0);
	hv_store(hash,  "memberB", strlen("memberB") , newSVpv(in->memberB, 0), 0);
	sv_setref_pv(joinQual, "ARQualifierStructPtr", dup_qualifier(ctrl,
							    &in->joinQual));
	hv_store(hash,  "joinQual", strlen("joinQual") , joinQual, 0);
	hv_store(hash,  "option", strlen("option") , newSViv(in->option), 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARViewSchema(ARControlStruct * ctrl, ARViewSchema * in)
{
	HV             *hash = newHV();

	hv_store(hash,  "tableName", strlen("tableName") , newSVpv(in->tableName, 0), 0);
	hv_store(hash,  "keyField", strlen("keyField") , newSVpv(in->keyField, 0), 0);
#if AR_EXPORT_VERSION < 6
	hv_store(hash,  "viewQual", strlen("viewQual") , newSVpv(in->viewQual, 0), 0);
#endif
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARCompoundSchema(ARControlStruct * ctrl, ARCompoundSchema * in)
{
	HV             *hash = newHV();

        hv_store(hash,  "schemaType", strlen("schemaType") ,
                 newSVpv(lookUpTypeName((TypeMapStruct *)SchemaTypeMap,
                                        in->schemaType), 0), 0);

	switch (in->schemaType) {
	case AR_SCHEMA_JOIN:
		hv_store(hash,  "join", strlen("join") , perl_ARJoinSchema(ctrl, &in->u.join), 0);
		break;
	case AR_SCHEMA_VIEW:
		hv_store(hash,  "view", strlen("view") , perl_ARViewSchema(ctrl, &in->u.view), 0);
		break;
	}
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARSortList(ARControlStruct * ctrl, ARSortList * in)
{
	AV             *array = newAV();
	int             i;

	for (i = 0; i < in->numItems; i++) {
		HV             *sort = newHV();

		hv_store(sort,  "fieldId", strlen("fieldId") , newSViv(in->sortList[i].fieldId), 0);
		hv_store(sort,  "sortOrder", strlen("sortOrder") , newSViv(in->sortList[i].sortOrder), 0);
		av_push(array, newRV_noinc((SV *) sort));
	}
	return newRV_noinc((SV *) array);
}
  
#if AR_EXPORT_VERSION >= 4
SV             *
perl_ARAttach(ARControlStruct * ctrl, ARAttachStruct * in)
{
	HV             *hash = newHV();
	SV             *buffer;
	SV             *name;
	SV             *size;
	SV             *csize;
	char           *str = "Use ars_GetEntryBLOB or OO->getAttachment to extract the attachment";

	/*
	 * at this point, the loc structure is not actually used ...
	 */

	buffer = newSVpv( str, strlen(str) );
	name = newSVpv( in->name, strlen(in->name) );
	size = newSViv(in->origSize);
	csize = newSViv(in->compSize);

	hv_store(hash,  "name", strlen("name") , name, 0);
	hv_store(hash,  "value", strlen("value") , buffer, 0);
	hv_store(hash,  "origSize", strlen("origSize") , size, 0);
	hv_store(hash,  "compSize", strlen("compSize") , csize, 0);

	return newRV_noinc((SV *) hash);
}
#endif

SV             *
perl_ARByteList(ARControlStruct * ctrl, ARByteList * in)
{
	HV             *hash = newHV();
	SV             *byte_list = newSVpv((char *) in->bytes, in->numItems);
	int             i;

	for (i = 0; ByteListTypeMap[i].number != TYPEMAP_LAST; i++) {
		if (ByteListTypeMap[i].number == in->type)
			break;
	}
	hv_store(hash,  "type", strlen("type") , newSVpv( ByteListTypeMap[i].name, strlen(ByteListTypeMap[i].name) ), 0);
	hv_store(hash,  "value", strlen("value") , byte_list, 0);
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARCoordStruct(ARControlStruct * ctrl, ARCoordStruct * in)
{
	HV             *hash = newHV();
	hv_store(hash,  "x", strlen("x") , newSViv(in->x), 0);
	hv_store(hash,  "y", strlen("y") , newSViv(in->y), 0);
	return newRV_noinc((SV *) hash);
}

#endif				/* ARS 3 */

void
dup_Value(ARControlStruct * ctrl, ARValueStruct * n, ARValueStruct * in)
{
	n->dataType = in->dataType;

	switch (in->dataType) {
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
dup_ArithOp(ARControlStruct * ctrl, ARArithOpStruct * in)
{
	ARArithOpStruct *n;

	if (!in)
		return NULL;
	n = MALLOCNN(sizeof(ARArithOpStruct));
	n->operation = in->operation;
	dup_FieldValueOrArith(ctrl, &n->operandLeft, &in->operandLeft);
	dup_FieldValueOrArith(ctrl, &n->operandRight, &in->operandRight);
	return n;
}

void
dup_ValueList(ARControlStruct * ctrl, ARValueList * n, ARValueList * in)
{
	int             i;

	n->numItems = in->numItems;
	n->valueList = MALLOCNN(sizeof(ARValueStruct) * in->numItems);
	for (i = 0; i < in->numItems; i++)
		dup_Value(ctrl, &n->valueList[0], &in->valueList[0]);
}

ARQueryValueStruct *
dup_QueryValue(ARControlStruct * ctrl, ARQueryValueStruct * in)
{
	ARQueryValueStruct *n;

	if (!in)
		return NULL;
	n = MALLOCNN(sizeof(ARQueryValueStruct));
	strcpy(n->schema, in->schema);
	strcpy(n->server, in->server);
	n->qualifier = dup_qualifier(ctrl, in->qualifier);
	n->valueField = in->valueField;
	n->multiMatchCode = in->multiMatchCode;
	return n;
}

void
dup_FieldValueOrArith(ARControlStruct * ctrl,
		      ARFieldValueOrArithStruct * n,
		      ARFieldValueOrArithStruct * in)
{
	n->tag = in->tag;

	switch (in->tag) {
	case AR_FIELD_CURRENT:
	case AR_FIELD_TRAN:
	case AR_FIELD_DB:
	case AR_FIELD:
		n->u.fieldId = in->u.fieldId;
		break;
	case AR_VALUE:
		dup_Value(ctrl, &n->u.value, &in->u.value);
		break;
	case AR_ARITHMETIC:
		n->u.arithOp = dup_ArithOp(ctrl, in->u.arithOp);
		break;
	case AR_STAT_HISTORY:
		n->u.statHistory = in->u.statHistory;
		break;
	case AR_VALUE_SET:
		dup_ValueList(ctrl, &n->u.valueSet, &in->u.valueSet);
		break;
	case AR_LOCAL_VARIABLE:
		n->u.variable = in->u.variable;
		break;
	case AR_QUERY:
		n->u.queryValue = dup_QueryValue(ctrl, in->u.queryValue);
		break;
	}
}

ARRelOpStruct  *
dup_RelOp(ARControlStruct * ctrl, ARRelOpStruct * in)
{
	ARRelOpStruct  *n;

	if (!in)
		return NULL;
	n = MALLOCNN(sizeof(ARRelOpStruct));
	n->operation = in->operation;
	dup_FieldValueOrArith(ctrl, &n->operandLeft, &in->operandLeft);
	dup_FieldValueOrArith(ctrl, &n->operandRight, &in->operandRight);
	return n;
}

/* assumes qual struct is pre-allocated. if level > 0 then out is
 * ignored and a new qual struct is allocated, else out is used instead
 * of allocating a new struct
 */

ARQualifierStruct *
dup_qualifier2(ARControlStruct * ctrl, ARQualifierStruct * in,
	       ARQualifierStruct * out, int level)
{
	ARQualifierStruct *n;

	if (!in || !out)
		return (ARQualifierStruct *) NULL;
	if (level > 0) {
		n = MALLOCNN(sizeof(ARQualifierStruct));
	} else {
		n = out;
	}

	n->operation = in->operation;

	switch (in->operation) {
	case AR_COND_OP_AND:
	case AR_COND_OP_OR:
		n->u.andor.operandLeft = dup_qualifier2(ctrl,
					   in->u.andor.operandLeft, out, 1);
		n->u.andor.operandRight = dup_qualifier2(ctrl,
					  in->u.andor.operandRight, out, 1);
		break;
	case AR_COND_OP_NOT:
		n->u.not = dup_qualifier2(ctrl, in->u.not, out, 1);
		break;
	case AR_COND_OP_REL_OP:
		n->u.relOp = dup_RelOp(ctrl, in->u.relOp);
		break;
	case AR_COND_OP_NONE:
		break;
	}
	return n;
}

/* assumes qual struct is not pre-allocated */

ARQualifierStruct *
dup_qualifier(ARControlStruct * ctrl, ARQualifierStruct * in)
{
	ARQualifierStruct *n;

	if (!in)
		return NULL;
	n = MALLOCNN(sizeof(ARQualifierStruct));
	n->operation = in->operation;
	switch (in->operation) {
	case AR_COND_OP_AND:
	case AR_COND_OP_OR:
		n->u.andor.operandLeft = dup_qualifier(ctrl, in->u.andor.operandLeft);
		n->u.andor.operandRight = dup_qualifier(ctrl, in->u.andor.operandRight);
		break;
	case AR_COND_OP_NOT:
		n->u.not = dup_qualifier(ctrl, in->u.not);
		break;
	case AR_COND_OP_REL_OP:
		n->u.relOp = dup_RelOp(ctrl, in->u.relOp);
		break;
	case AR_COND_OP_NONE:
		break;
	}
	return n;
}

SV             *
perl_ARArithOpStruct(ARControlStruct * ctrl, ARArithOpStruct * in)
{
	HV             *hash = newHV();
	char           *oper = "";

	switch (in->operation) {
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
		{
			char _em[80];
			(void) sprintf(_em,
			 "Unknown arith operation in ARArithOpStruct: %8.8i\n",
			               in->operation);
                        (void) ARError_add(AR_RETURN_ERROR, AP_ERR_INV_ARITH, 
					   _em);
		}
		break;
	}
	hv_store(hash,  "oper", strlen("oper") , newSVpv(oper, 0), 0);
	if (in->operation == AR_ARITH_OP_NEGATE) {
		hv_store(hash,  "left", strlen("left") ,
		 perl_ARFieldValueOrArithStruct(ctrl, &in->operandLeft), 0);
	} else {
		hv_store(hash,  "right", strlen("right") ,
		perl_ARFieldValueOrArithStruct(ctrl, &in->operandRight), 0);
		hv_store(hash,  "left", strlen("left") ,
		 perl_ARFieldValueOrArithStruct(ctrl, &in->operandLeft), 0);
	}
	return newRV_noinc((SV *) hash);
}

SV             *
perl_ARQueryValueStruct(ARControlStruct * ctrl, ARQueryValueStruct * in)
{
	HV             *hash = newHV();
	SV             *ref;

	ARQualifierStruct *qual;
	hv_store(hash,  "schema", strlen("schema") , newSVpv(in->schema, 0), 0);
	hv_store(hash,  "server", strlen("server") , newSVpv(in->server, 0), 0);
	qual = dup_qualifier(ctrl, in->qualifier);
	ref = newSViv(0);
	sv_setref_pv(ref, "ARQualifierStructPtr", (void *) qual);
	hv_store(hash,  "qualifier", strlen("qualifier") , ref, 0);

	hv_store(hash,  "valueField", strlen("valueField") , newSViv(in->valueField), 0);
	switch (in->multiMatchCode) {
	case AR_QUERY_VALUE_MULTI_ERROR:
		hv_store(hash,  "multi", strlen("multi") , newSVpv("error", 0), 0);
		break;
	case AR_QUERY_VALUE_MULTI_FIRST:
		hv_store(hash,  "multi", strlen("multi") , newSVpv("first", 0), 0);
		break;
	case AR_QUERY_VALUE_MULTI_SET:
		hv_store(hash,  "multi", strlen("multi") , newSVpv("set", 0), 0);
		break;
	}
	return newRV_noinc((SV *) hash);
}

#if AR_EXPORT_VERSION >= 5
SV             *
perl_ARWorkflowConnectStruct(ARControlStruct * ctrl, ARWorkflowConnectStruct * in)
{
	HV *hash = newHV();
	switch (in->type) {
	case AR_WORKFLOW_CONN_SCHEMA_LIST:
		hv_store(hash,  "type", strlen("type") , 
			 newSVpv("WORKFLOW_CONN_SCHEMA_LIST", 0), 0);
		hv_store(hash,  "schemaList", strlen("schemaList") ,
			 perl_ARList(ctrl, 
				     (ARList *)  in->u.schemaList,
				     (ARS_fn) perl_ARNameList,
				     sizeof(ARNameList)), 0);
		break;
	}
	return newRV_noinc((SV *) hash);
}

SV *
perl_ARNameList(ARControlStruct * ctrl, ARNameList * in) {
	AV *array = newAV();
	int i;

	for(i = 0 ; i < in->numItems ; i++) {
		av_push(array, newSVpv(in->nameList[i], 0));
	}
	return newRV_noinc((SV *)array);
}

#endif

SV             *
perl_ARFieldValueOrArithStruct(ARControlStruct * ctrl, ARFieldValueOrArithStruct * in)
{
	HV             *hash = newHV();

	switch (in->tag) {
	case AR_FIELD:
		hv_store(hash,  "fieldId", strlen("fieldId") , newSViv(in->u.fieldId), 0);
		break;
	case AR_VALUE:
		hv_store(hash,  "value", strlen("value") ,
			 perl_ARValueStruct(ctrl, &in->u.value), 0);
		break;
	case AR_ARITHMETIC:
		hv_store(hash,  "arith", strlen("arith") ,
			 perl_ARArithOpStruct(ctrl, in->u.arithOp), 0);
		break;
	case AR_STAT_HISTORY:
		hv_store(hash,  "statHistory", strlen("statHistory") ,
		      perl_ARStatHistoryValue(ctrl, &in->u.statHistory), 0);
		break;
	case AR_VALUE_SET:
		hv_store(hash,  "valueSet", strlen("valueSet") ,
			 perl_ARList(ctrl,
				     (ARList *) & in->u.valueSet,
				     (ARS_fn) perl_ARValueStruct,
				     sizeof(ARValueStruct)), 0);
		break;
	case AR_FIELD_TRAN:
		hv_store(hash,  "TR_fieldId", strlen("TR_fieldId") , newSViv(in->u.fieldId), 0);
		break;
	case AR_FIELD_DB:
		hv_store(hash,  "DB_fieldId", strlen("DB_fieldId") , newSViv(in->u.fieldId), 0);
		break;
	case AR_LOCAL_VARIABLE:
		hv_store(hash,  "variable", strlen("variable") , newSViv(in->u.variable), 0);
		break;
	case AR_QUERY:
		hv_store(hash,  "queryValue", strlen("queryValue") ,
			 perl_ARQueryValueStruct(ctrl, in->u.queryValue), 0);
		break;
	case AR_FIELD_CURRENT:
		hv_store(hash,  "queryCurrent", strlen("queryCurrent") ,
			 newSViv(in->u.fieldId), 0);
		break;
	}
	return newRV_noinc((SV *) hash);
}

SV             *
perl_relOp(ARControlStruct * ctrl, ARRelOpStruct * in)
{
	HV             *hash = newHV();
	char           *s = "";

	switch (in->operation) {
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
	hv_store(hash,  "oper", strlen("oper") , newSVpv(s, 0), 0);
	hv_store(hash,  "left", strlen("left") ,
		 perl_ARFieldValueOrArithStruct(ctrl, &in->operandLeft), 0);
	hv_store(hash,  "right", strlen("right") ,
		 perl_ARFieldValueOrArithStruct(ctrl, &in->operandRight), 0);
	return newRV_noinc((SV *) hash);
}

HV             *
perl_qualifier(ARControlStruct * ctrl, ARQualifierStruct * in)
{
	HV             *hash = newHV();
	char           *s = "";

	if (in && in->operation != AR_COND_OP_NONE) {
		switch (in->operation) {
		case AR_COND_OP_AND:
			s = "and";
			hv_store(hash,  "left", strlen("left") ,
				 newRV_noinc((SV *) perl_qualifier(ctrl, in->u.andor.operandLeft)), 0);
			hv_store(hash,  "right", strlen("right") ,
				 newRV_noinc((SV *) perl_qualifier(ctrl, in->u.andor.operandRight)), 0);
			break;
		case AR_COND_OP_OR:
			s = "or";
			hv_store(hash,  "left", strlen("left") ,
				 newRV_noinc((SV *) perl_qualifier(ctrl, in->u.andor.operandLeft)), 0);
			hv_store(hash,  "right", strlen("right") ,
				 newRV_noinc((SV *) perl_qualifier(ctrl, in->u.andor.operandRight)), 0);
			break;
		case AR_COND_OP_NOT:
			s = "not";
			hv_store(hash,  "not", strlen("not") ,
			  newRV_noinc((SV *) perl_qualifier(ctrl, in->u.not)), 0);
			break;
		case AR_COND_OP_REL_OP:
			s = "rel_op";
			hv_store(hash,  "rel_op", strlen("rel_op") ,
				 perl_relOp(ctrl, in->u.relOp), 0);
			break;
		}
		hv_store(hash,  "oper", strlen("oper") , newSVpv(s, 0), 0);
	}
	return hash;
}

ARDisplayList  *
dup_DisplayList(ARControlStruct * ctrl, ARDisplayList * disp)
{
	ARDisplayList  *new_disp;

	new_disp = MALLOCNN(sizeof(ARDisplayList));
	new_disp->numItems = disp->numItems;
	new_disp->displayList = MALLOCNN(sizeof(ARDisplayStruct) * disp->numItems);
	memcpy(new_disp->displayList, disp->displayList,
	       sizeof(ARDisplayStruct) * disp->numItems);

	return new_disp;
}

int
ARGetFieldCached(ARControlStruct * ctrl, ARNameType schema, ARInternalId id,
#if AR_EXPORT_VERSION >= 3
		 ARNameType fieldName, ARFieldMappingStruct * fieldMap,
#endif
		 unsigned int *dataType, unsigned int *option,
		 unsigned int *createMode, ARValueStruct * defaultVal,
		 ARPermissionList * perm, ARFieldLimitStruct * limit,
#if AR_EXPORT_VERSION >= 3
		 ARDisplayInstanceList * display,
#else
		 ARDisplayList * display,
#endif
		 char **help, ARTimestamp * timestamp,
	       ARNameType owner, ARNameType lastChanged, char **changeDiary,
		 ARStatusList * Status)
{
	int             ret;
	HV             *cache, *server, *fields, *base;
	SV            **servers, **schema_fields, **field, **val;
	unsigned int    my_dataType;
#if AR_EXPORT_VERSION >= 3
	ARNameType      my_fieldName;
#else
	ARDisplayList   my_display, *display_copy;
	SV             *display_ref;
#endif
	char            field_string[20];

#if AR_EXPORT_VERSION >= 3
	/* cache fieldName and dataType */
	if (fieldMap || option || createMode || defaultVal || perm || limit ||
	    display || help || timestamp || owner || lastChanged || changeDiary) {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
			 "ARGetFieldCached: uncached parameter requested.");
		goto cache_fail;
	}
#else
	/* cache dataType and displayList */
	if (option || createMode || defaultVal || perm || limit || help ||
	    timestamp || owner || lastChanged || changeDiary) {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
			 "ARGetFieldCached: uncached parameter requested.");
		goto cache_fail;
	}
#endif

	/* try to do lookup in cache */

	cache = perl_get_hv("ARS::field_cache", TRUE);

	/* dereference hash with server */

	servers = hv_fetch(cache,  ctrl->server, strlen(ctrl->server) , TRUE);

	if (!(servers && SvROK(*servers) &&
	      SvTYPE(server = (HV *) SvRV(*servers)) == SVt_PVHV)) {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
		       "GetFieldCached failed to deref hash w/server name");
		goto cache_fail;
	}
	/* dereference hash with schema */

	schema_fields = hv_fetch(server,  schema, strlen(schema) , TRUE);

	if (!(schema_fields && SvROK(*schema_fields) &&
	      SvTYPE(fields = (HV *) SvRV(*schema_fields)) == SVt_PVHV)) {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
		       "GetFieldCached failed to deref hash w/schema name");
		goto cache_fail;
	}
	/* dereference with field id */

	sprintf(field_string, "%i", (int) id);

	field = hv_fetch(fields,  field_string, strlen(field_string) , TRUE);

	if (!(field && SvROK(*field) && SvTYPE(base = (HV *) SvRV(*field)))) {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
			"GetFieldCached failed to fetch fieldId from hash");
		goto cache_fail;
	}
	/* fetch values */

	val = hv_fetch(base,  "name", strlen("name") , FALSE);
	if (!val) {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
				 "GetFieldCached failed to fetch name key");
		goto cache_fail;
	}
#if AR_EXPORT_VERSION >= 3
	if (fieldName) {
		strcpy(fieldName, SvPV((*val), PL_na));
	}
#else				/* ARS 2.x */
#ifndef SKIP_SV_ISA
	if (!sv_isa(*val, "ARDisplayListPtr")) {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
		     "GetFieldCached: field value isnt'a ARDisplayListPtr");
		goto cache_fail;
	}
#endif				/* SKIP_SV_ISA */

	if (display) {
		display_copy = (ARDisplayList *) SvIV(SvRV(*val));
		display->numItems = display_copy->numItems;
		display->displayList =
			MALLOCNN(sizeof(ARDisplayStruct) * display_copy->numItems);
		memcpy(display->displayList, display_copy->displayList,
		       sizeof(ARDisplayStruct) * display_copy->numItems);
	}
#endif

	val = hv_fetch(base,  "type", strlen("type") , FALSE);

	if (!val) {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
				 "GetFieldCached failed to fetch type key");
		goto cache_fail;
	}
	if (dataType) {
		*dataType = SvIV(*val);
	}
	return 0;

	/*
	 * if we don't cache one of the arguments or we couldn't find field
	 * in cache.. then we need to do a query to find the data.
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
	((ars_ctrl *) ctrl)->queries++;
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

	if (ret == 0) {		/* if ARGetField was successful */

		/* get variable */

		cache = perl_get_hv("ARS::field_cache", TRUE);

		/* dereference hash with server */

		servers = hv_fetch(cache,  ctrl->server, strlen(ctrl->server) , TRUE);

		if (!servers) {
			(void) ARError_add(ARSPERL_TRACEBACK, 1,
					   "GetFieldCached (part 2) failed to fetch/create servers key");
			return ret;
		}
		if (!SvROK(*servers) || SvTYPE(SvRV(*servers)) != SVt_PVHV) {
			sv_setsv(*servers, newRV_noinc((SV *) (server = newHV())));
		} else {
			server = (HV *) SvRV(*servers);
		}

		/* dereference hash with schema */

		schema_fields = hv_fetch(server,  schema, strlen(schema) , TRUE);

		if (!schema_fields) {
			(void) ARError_add(ARSPERL_TRACEBACK, 1,
					   "GetFieldCached (part 2) failed to fetch/create schema key");
			return ret;
		}
		if (!SvROK(*schema_fields) || SvTYPE(SvRV(*schema_fields)) != SVt_PVHV) {
			sv_setsv(*schema_fields, newRV_noinc((SV *) (fields = newHV())));
		} else {
			fields = (HV *) SvRV(*schema_fields);
		}

		/* dereference hash with field id */

		sprintf(field_string, "%i", (int) id);

		field = hv_fetch(fields,  field_string, strlen(field_string) , TRUE);

		if (!field) {
			(void) ARError_add(ARSPERL_TRACEBACK, 1,
					   "GetFieldCached (part 2) failed to fetch/create field key");
			return ret;
		}
		if (!SvROK(*field) || SvTYPE(SvRV(*field)) != SVt_PVHV) {
			sv_setsv(*field, newRV_noinc((SV *) (base = newHV())));
		} else {
			base = (HV *) SvRV(*field);
		}

		/* store field attributes */

#if AR_EXPORT_VERSION >= 3
		hv_store(base,  "name", strlen("name") , newSVpv(my_fieldName, 0), 0);
#else

		display_ref = newSViv(0);

		sv_setref_pv(display_ref, "ARDisplayListPtr",
			     (void *) dup_DisplayList(ctrl, &my_display));

		hv_store(base,  "name", strlen("name") , display_ref, 0);
		FreeARDisplayList(&my_display, FALSE);
#endif

		hv_store(base,  "type", strlen("type") , newSViv(my_dataType), 0);
	} else {
		(void) ARError_add(ARSPERL_TRACEBACK, 1,
				 "GetFieldCached: ARGetField call failed.");
	}
	return ret;
}

int
sv_to_ARValue(ARControlStruct * ctrl, SV * in, unsigned int dataType,
	      ARValueStruct * out)
{
	AV             *array, *array2;
	HV             *hash;
	SV            **fetch, *type, *val, **fetch2;
	char           *bytelist;
	unsigned int    len, i;

	out->dataType = dataType;
	if (!SvOK(in)) {
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
			out->u.charVal = strdup(SvPV(in, PL_na));
			break;
		case AR_DATA_TYPE_DIARY:
			out->u.diaryVal = strdup(SvPV(in, PL_na));
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
				if (SvTYPE(hash = (HV *) SvRV(in)) == SVt_PVHV) {
					fetch = hv_fetch(hash, "type", 4, FALSE);
					if (!fetch) {
						ARError_add(AR_RETURN_ERROR, AP_ERR_BYTE_LIST);
						return -1;
					}
					type = *fetch;
					if (!(SvOK(type) && SvTYPE(type) != SVt_RV)) {
						ARError_add(AR_RETURN_ERROR, AP_ERR_BYTE_LIST);
						return -1;
					}
					fetch = hv_fetch(hash,  "value", strlen("value") , FALSE);
					if (!fetch) {
						ARError_add(AR_RETURN_ERROR, AP_ERR_BYTE_LIST);
						return -1;
					}
					val = *fetch;
					if (!(SvOK(val) && SvTYPE(val) != SVt_RV)) {
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
			out->u.ulongVal = SvIV(in);	/* FIX -- does perl have
							 * ulong ? */
			break;
#if AR_EXPORT_VERSION >= 4
		case AR_DATA_TYPE_DECIMAL:
		        out->u.decimalVal = strdup(SvPV(in, PL_na)); 
			break;
		case AR_DATA_TYPE_ATTACH:
			/* value must be a hash reference */
			if (SvROK(in)) {
				if (SvTYPE(hash = (HV *) SvRV(in)) == SVt_PVHV) {
					ARAttachStruct *attachp = MALLOCNN(sizeof(ARAttachStruct));
					ARLocStruct    *locp = &(attachp->loc);
					long            size = 0;
					SV             *name = NULL;

					/*
					 * the hash should contain keys: 
					 * file (a filename) or 
					 * buffer (a buffer)
					 * and all of: 
					 * size (length of file or buffer)
					 * name (the name to give the attachment)
					 * name defaults to the filename or "Anonymous Incore Buffer"
					 */

					/* first: decode the size key */

					fetch = hv_fetch(hash,  "size", strlen("size") , FALSE);
					if (!fetch) {
						safefree(attachp);
						ARError_add(AR_RETURN_ERROR, AP_ERR_ATTACH,
						"Must specify 'size' key.");
						return -1;
					}
					if (!(SvOK(*fetch) && SvTYPE(*fetch) != SVt_RV)) {
						safefree(attachp);
						ARError_add(AR_RETURN_ERROR, AP_ERR_ATTACH,
							    "'size' key does not map to scalar value.");
						return -1;
					}
					size = SvIV(*fetch);

					/* now get the name, if any */

					fetch = hv_fetch(hash,  "name", strlen("name") , FALSE);
					if( !fetch)
						name = NULL;
					else
						name = *fetch;

					/*
					 * next: determine if we are dealing
					 * with an in core buffer or a
					 * filename and setup the
					 * AttachStruct.name field
					 * accordingly
					 */

					fetch = hv_fetch(hash,  "file", strlen("file") , FALSE);
					fetch2 = hv_fetch(hash,  "buffer", strlen("buffer") , FALSE);

					/*
					 * either/or must be specifed: not
					 * both and not neither
					 */

					if ((!fetch && !fetch2) || (fetch && fetch2)) {
						safefree(attachp);
						ARError_add(AR_RETURN_ERROR, AP_ERR_ATTACH,
							    "Must specify one either 'file' or 'buffer' key.");
						return -1;
					}
					/* we've been given a filename */

					if (fetch) {
						char           *filename;
						STRLEN          filenamelen;

						if (!(SvOK(*fetch) && SvTYPE(*fetch) != SVt_RV)) {
							safefree(attachp);
							ARError_add(AR_RETURN_ERROR, AP_ERR_ATTACH,
								    "'file' key does not map to scalar value.");
							return -1;
						}
						locp->locType = AR_LOC_FILENAME;

						filename = SvPV(*fetch, filenamelen);

						/* if we have an explicitly set name, use it, else use the filename */

						if (name) {
							STRLEN __len; /* because some perls have "na" and others "PL_na" */
							attachp->name = strdup(SvPV(name, __len));
						} else {
							attachp->name = MALLOCNN(filenamelen + 1);
							memcpy(attachp->name, filename, filenamelen);
						}

						locp->u.filename      = MALLOCNN(filenamelen + 1);
						memcpy(locp->u.filename, filename, filenamelen);

						attachp->origSize     = size;
					}
					/* else we've been given a buffer */

					else {
					        STRLEN __len; /* dummy variable */
						if (!(SvOK(*fetch2) && SvTYPE(*fetch2) != SVt_RV)) {
							safefree(attachp);
							ARError_add(AR_RETURN_ERROR, AP_ERR_ATTACH,
								    "'buffer' key does not map to scalar value.");
							return -1;
						}
						if (name) 
							attachp->name = strdup(SvPV(name, __len));
						else 
							attachp->name = strdup("Anonymous In-core Buffer");

						locp->locType         = AR_LOC_BUFFER;
						locp->u.buf.bufSize   = size;
						locp->u.buf.buffer    = MALLOCNN(size);
						memcpy(locp->u.buf.buffer, SvPV(*fetch2, __len), size);
					}

					out->u.attachVal = attachp;
					break;
				}
			}
			ARError_add(AR_RETURN_ERROR, AP_ERR_ATTACH,
			  "Non hash-reference passed as attachment value.");
			return -1;
			break;
#endif

		case AR_DATA_TYPE_COORDS:
			if (SvTYPE(array = (AV *) SvRV(in)) == SVt_PVAV) {
				len = av_len(array) + 1;
				out->u.coordListVal = MALLOCNN(sizeof(ARCoordList));
				out->u.coordListVal->numItems = len;
				out->u.coordListVal->coords = MALLOCNN(sizeof(ARCoordStruct) * len);
				for (i = 0; i < len; i++) {
					fetch = av_fetch(array, i, 0);
					if (fetch && SvTYPE(array2 = (AV *) SvRV(*fetch)) == SVt_PVAV &&
					    av_len(array2) == 1) {
						fetch2 = av_fetch(array2, 0, 0);
						if (!*fetch2)
							goto fetch_puke;
						out->u.coordListVal->coords[i].x = SvIV(*fetch);
						fetch2 = av_fetch(array2, 1, 0);
						if (!*fetch2)
							goto fetch_puke;
						out->u.coordListVal->coords[i].y = SvIV(*fetch);
					} else {
				fetch_puke:	;
#ifndef WASTE_MEM
						FREE(out->u.coordListVal->coords);
						FREE(out->u.coordListVal);
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

