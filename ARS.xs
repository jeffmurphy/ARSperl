/*
$Header: /cvsroot/arsperl/ARSperl/ARS.xs,v 1.100 2005/03/31 16:22:17 jeffmurphy Exp $

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


    http://www.arsperl.org

*/

#include "support.h"
#include "supportrev.h"

#if AR_EXPORT_VERSION < 3
#define AR_LIST_SCHEMA_ALL 1 
#endif

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
ars_perl_qualifier(ctrl, in)
	ARControlStruct *	ctrl
	ARQualifierStruct *	in
	CODE:
	{
	  RETVAL = perl_qualifier(ctrl, in);
	}
	OUTPUT:
	RETVAL

ARQualifierStruct *
ars_LoadQualifier(ctrl,schema,qualstring,displayTag=NULL)
	ARControlStruct *	ctrl
	char *			schema
	char *			qualstring
	char *			displayTag
	CODE:
	{
		int                ret;
		ARStatusList       status;
		ARQualifierStruct *qual;
		AMALLOCNN(qual, 1, ARQualifierStruct);
		Zero(&status, 1, ARStatusList);
		(void) ARError_reset();
		ret = ARLoadARQualifierStruct(ctrl, schema, displayTag, qualstring, qual, &status);
#ifdef PROFILE
		((ars_ctrl *)ctrl)->queries++;
#endif
		if (! ARError( ret, status)) {
			RETVAL = qual;
		} else {
			RETVAL = NULL;
			FreeARQualifierStruct(qual, TRUE);
		}
	}
	OUTPUT:
	RETVAL

void
__ars_Termination()
	CODE:
	{
#if AR_EXPORT_VERSION <= 3
	  int          ret;
#endif
	  ARStatusList status;
	  
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_reset();
#if AR_EXPORT_VERSION <= 3
	  ret = ARTermination(&status);
	  if (ARError( ret, status)) {
	    warn("failed in ARTermination\n");
	  }
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, "__ars_Termination() is only available when compiled against ARS <= 3.2");
#endif
	}

void
__ars_init()
	CODE:
	{
#if AR_EXPORT_VERSION <= 3
	  int          ret;
#endif
	  ARStatusList status;
	
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_reset();
#if AR_EXPORT_VERSION <= 3
	  ret = ARInitialization(&status);
	  if (ARError( ret, status)) {
	    croak("unable to initialize ARS module");
	  }
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, "__ars_init() is only available when compiled against ARS <= 3.2");
#endif
	}

int
ars_APIVersion()
	CODE:
	{
		RETVAL = AR_EXPORT_VERSION;
	}
	OUTPUT:
	RETVAL

int
ars_SetServerPort(ctrl, name, port, progNum)
	ARControlStruct *	ctrl
	char *			name
	int			port
	int			progNum
	CODE:
	{
		int 		ret;
		ARStatusList	status;

		RETVAL = 0;
		Zero(&status, 1, ARStatusList);
		(void) ARError_reset();
#if AR_EXPORT_VERSION >= 4
		ret = ARSetServerPort(ctrl, name, port, progNum, &status);
		if (! ARError(ret, status)) {
			RETVAL = 1;
		}
#else
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
		"ars_SetServerPort() is only available in ARS >= 4.x");
#endif
	}
	OUTPUT:
	RETVAL

ARControlStruct *
ars_Login(server, username, password, lang=NULL, authString=NULL, tcpport=0, rpcnumber=0)
	char *		server
	char *		username
	char *		password
	char *		lang
	char *		authString
	unsigned int  	tcpport
	unsigned int  	rpcnumber
	CODE:
	{
		int              ret, s_ok = 1;
		ARStatusList     status;
		ARServerNameList serverList;
		ARControlStruct *ctrl;
#ifdef PROFILE
		struct timeval   tv;
#endif

		DBG( ("ars_Login(%s, %s, %s, %s, %s, %d, %d)\n", 
			SAFEPRT(server),
			SAFEPRT(username),
			SAFEPRT(password),
			SAFEPRT(lang),
			SAFEPRT(authString),
			tcpport,
			rpcnumber) 
		    );

		RETVAL = NULL;
		Zero(&status, 1, ARStatusList);
		Zero(&serverList, 1, ARServerNameList);
		(void) ARError_reset();  
#ifdef PROFILE
	  /* XXX
	     This is something of a hack... a safemalloc will always
	     complain about differing structures.  However, it's 
	     pretty deep into the code.  Perhaps a static would be cleaner?
	  */
		ctrl = (ARControlStruct *)MALLOCNN(sizeof(ars_ctrl));
		Zero(ctrl, 1, ars_ctrl);
		((ars_ctrl *)ctrl)->queries = 0;
		((ars_ctrl *)ctrl)->startTime = 0;
		((ars_ctrl *)ctrl)->endTime = 0;
#else
		DBG( ("safemalloc ARControlStruct\n") );
		ctrl = (ARControlStruct *)safemalloc(sizeof(ARControlStruct));
		Zero(ctrl, 1, ARControlStruct);
#endif
#ifdef PROFILE
		if (gettimeofday(&tv, 0) != -1)
			((ars_ctrl *)ctrl)->startTime = tv.tv_sec;
		else
			perror("gettimeofday");
#endif
		ctrl->cacheId = 0;
#if AR_EXPORT_VERSION >= 4
	 	ctrl->sessionId = 0;
#endif
		ctrl->operationTime = 0;
		strncpy(ctrl->user, username, sizeof(ctrl->user));
		ctrl->user[sizeof(ctrl->user)-1] = 0;
		strncpy(ctrl->password, password, sizeof(ctrl->password));
		ctrl->password[sizeof(ctrl->password)-1] = 0;
#ifndef AR_MAX_LOCALE_SIZE
		/* 6.0.1 and 6.3 are AR_EXPORT_VERSION = 8L but 6.3 does not
	         * contain the language field
	         */
		ctrl->language[0] = 0;
		if ( CVLD(lang) ) {
			strncpy(ctrl->language, lang, AR_MAX_LANG_SIZE);
		}
#else 
		ctrl->localeInfo.locale[0] = 0;
		if ( CVLD(lang) ) {
			strncpy(ctrl->localeInfo.locale, lang, AR_MAX_LANG_SIZE);
		}
#endif
#if AR_EXPORT_VERSION >= 7L
		ctrl->authString[0] = 0;
		if ( CVLD(authString) ) {
			strncpy(ctrl->authString, authString, AR_MAX_NAME_SIZE);
		}
#endif
#if AR_EXPORT_VERSION >= 4
		/* call ARInitialization */
		ret = ARInitialization(ctrl, &status);

		if(ARError(ret, status)) {
			DBG( ("ARInitialization failed %d\n", ret) );
			ARTermination(ctrl, &status);
			ARError(ret, status);
			AP_FREE(ctrl);
			goto ar_login_end;
		}
#endif

		if (!server || !*server) {
			DBG( ("no server given. picking one.\n") );
#if AR_EXPORT_VERSION >= 4
	  		ret = ARGetListServer(ctrl, &serverList, &status);
#else
	  		ret = ARGetListServer(&serverList, &status);
#endif
	  		if (ARError( ret, status)) {
				ARTermination(ctrl, &status);
				ARError(ret, status);
	    			AP_FREE(ctrl); /* invalid, cleanup */
				DBG( ("ARGetListServer failed %d\n", ret) );
	   			goto ar_login_end;
	  		}
			status.numItems = 0;
	  		if (serverList.numItems == 0) {
				DBG( ("serverList is empty.\n") );
	     			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_NO_SERVERS);
				ARTermination(ctrl, &status);
				ARError(ret, status);
	      			AP_FREE(ctrl); /* invalid, cleanup */
	      			goto ar_login_end;
	    		}
	    		server = serverList.nameList[0];
			DBG( ("changing s_ok to 0, picked server %s\n",
				SAFEPRT(server)) );
	    		s_ok = 0;
	  	}
	  	strncpy(ctrl->server, server, sizeof(ctrl->server));
	 	ctrl->server[sizeof(ctrl->server)-1] = 0;

		/* set the tcp/rpc port if given */

		ret = ARSetServerPort(ctrl, ctrl->server, tcpport, rpcnumber,
					&status);
		if (ARError(ret, status)) {
			DBG( ("ARSetServerPort failed %d\n", ret) );
			ARTermination(ctrl, &status);
			ARError(ret, status);
			AP_FREE(ctrl);
			RETVAL = NULL;
		}

	  	/* finally, check to see if the user id is valid */

	  	ret = ARVerifyUser(ctrl, NULL, NULL, NULL, &status);
	  	if(ARError( ret, status)) {
			DBG( ("ARVerifyUser failed %d\n", ret) );
			ARTermination(ctrl, &status);
			ARError(ret, status);
			AP_FREE(ctrl); /* invalid, cleanup */
			RETVAL = NULL;
	  	} else {
	  		RETVAL = ctrl; /* valid, return ctrl struct */
	  	}

	  	if(s_ok == 0) {
			DBG( ("s_ok == 0, cleaning ServerNameList\n") );
	  		FreeARServerNameList(&serverList, FALSE);
	  	}
	ar_login_end:;
		DBG( ("finished.\n") );
	}
	OUTPUT:
	RETVAL

int
ars_VerifyUser(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
		int ret = 0;
		ARBoolean	adminFlag,
				subAdminFlag,
				customFlag;
		ARStatusList status;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		RETVAL = 0;

		ret = ARVerifyUser(ctrl, &adminFlag, 
					 &subAdminFlag, 
					 &customFlag, 
				   &status);

		if(! ARError(ret, status)) {
			RETVAL = 1;
		}
	}
	OUTPUT:
	RETVAL

void
ars_GetControlStructFields(ctrl)
	ARControlStruct *	ctrl
	PPCODE:
	{
	   (void) ARError_reset();
	   if(!ctrl) return;
	   XPUSHs(sv_2mortal(newSViv(ctrl->cacheId)));
	   XPUSHs(sv_2mortal(newSViv(ctrl->operationTime)));
	   XPUSHs(sv_2mortal(newSVpv(ctrl->user, 0)));
	   XPUSHs(sv_2mortal(newSVpv(ctrl->password, 0)));
#ifndef AR_MAX_LOCALE_SIZE
	   XPUSHs(sv_2mortal(newSVpv(ctrl->language, 0)));
#else
	   XPUSHs(sv_2mortal(newSVpv(ctrl->localeInfo.locale, 0)));
#endif
	   XPUSHs(sv_2mortal(newSVpv(ctrl->server, 0)));
	   XPUSHs(sv_2mortal(newSViv(ctrl->sessionId)));
#if AR_EXPORT_VERSION >= 7
	   XPUSHs(sv_2mortal(newSVpv(ctrl->authString, 0)));
#endif
	}

SV *
ars_GetCurrentServer(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  RETVAL = NULL;
	  (void) ARError_reset();
	  if(ctrl && ctrl->server) {
	    RETVAL = newSVpv( ctrl->server, strlen(ctrl->server) );
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
	  (void) ARError_reset();
#ifdef PROFILE
	  hv_store(RETVAL,  "queries", strlen("queries") , 
	  	   newSViv(((ars_ctrl *)ctrl)->queries), 0);
	  hv_store(RETVAL,  "startTime", strlen("startTime") , 
		   newSViv(((ars_ctrl *)ctrl)->startTime), 0);
#else /* profiling not compiled in */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_OPT_NA, 
			     "Optional profiling code not compiled into this build of ARSperl");
#endif
	}
	OUTPUT:
	RETVAL

void
ars_Logoff(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
		int          ret;
		ARStatusList status;
		Zero(&status, 1, ARStatusList);
		(void) ARError_reset();
		if (!ctrl) return;
#if AR_EXPORT_VERSION >= 4
		ret = ARTermination(ctrl, &status);
#else
		ret = ARTermination(&status);
#endif
		(void) ARError( ret, status);
		/*AP_FREE(ctrl); let DESTROY free it*/
	}

void
ars_GetListField(control,schema,changedsince=0,fieldType=AR_FIELD_TYPE_ALL)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	unsigned long		fieldType
	PPCODE:
	{
	  ARInternalIdList idlist;
	  ARStatusList     status;
	  int              ret;
	  unsigned int     i;
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListField(control,schema,fieldType,changedsince,&idlist,&status);
#else
	  ret = ARGetListField(control,schema,changedsince,&idlist,&status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
	    for (i=0; i<idlist.numItems; i++)
	      XPUSHs(sv_2mortal(newSViv(idlist.internalIdList[i])));
	    FreeARInternalIdList(&idlist,FALSE);
	  }
	}

void
ars_GetFieldByName(control,schema,field_name)
	ARControlStruct *	control
	char *			schema
	char *			field_name
	PPCODE:
	{
	  int              ret;
	  unsigned int     loop;
	  ARInternalIdList idList;
	  ARStatusList     status;
#if AR_EXPORT_VERSION >= 3
	  ARNameType       fieldName;
#else
	  ARDisplayList    displayList;
#endif
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListField(control, schema, AR_FIELD_TYPE_ALL, (ARTimestamp)0, &idList, &status);
#else
	  ret = ARGetListField(control, schema, (ARTimestamp)0, &idList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (! ARError( ret, status)) {
	    for (loop=0; loop<idList.numItems; loop++) {
#if AR_EXPORT_VERSION >= 3
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], fieldName, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], NULL, NULL, NULL, NULL, NULL, NULL, &displayList, NULL, NULL, NULL, NULL, NULL, &status);
#endif
	      if (ARError( ret, status))
	        break;
#if AR_EXPORT_VERSION >= 3
	      if (strcmp(field_name, fieldName) == 0)
#else 
	      if (displayList.numItems < 1) {
		(void) ARError_add( ARSPERL_TRACEBACK, 1, "No fields were returned in display list");
		break;
	      }
	      if (strcmp(field_name,displayList.displayList[0].label)==0)
#endif
	      {
		XPUSHs(sv_2mortal(newSViv(idList.internalIdList[loop])));
#if AR_EXPORT_VERSION < 3
		FreeARDisplayList(&displayList, FALSE);
#endif
		break;
	      }
#if AR_EXPORT_VERSION < 3
	      FreeARDisplayList(&displayList, FALSE);
#endif
	    }
	    FreeARInternalIdList(&idList, FALSE);
	  }
	}

void
ars_GetFieldTable(control,schema)
	ARControlStruct *	control
	char *			schema
	PPCODE:
	{
	  int              ret;
	  unsigned int     loop;
	  ARInternalIdList idList;
	  ARStatusList     status;
#if AR_EXPORT_VERSION >= 3
	  ARNameType       fieldName;
#else
	  ARDisplayList    displayList;
#endif
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListField(control, schema, AR_FIELD_TYPE_ALL, (ARTimestamp)0, &idList, &status);
#else
	  ret = ARGetListField(control, schema, (ARTimestamp)0, &idList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (! ARError( ret, status)) {
	    for (loop=0; loop<idList.numItems; loop++) {
#if AR_EXPORT_VERSION >= 3
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], fieldName, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(control, schema, idList.internalIdList[loop], NULL, NULL, NULL, NULL, NULL, NULL, &displayList, NULL, NULL, NULL, NULL, NULL, &status);
#endif
	      if (ARError( ret, status))
	        break;
#if AR_EXPORT_VERSION >= 3
	      XPUSHs(sv_2mortal(newSVpv(fieldName, 0)));
#else
	      if (displayList.numItems < 1) {
		(void) ARError_add( ARSPERL_TRACEBACK, 1, "No fields were returned in display list");
		continue;
	      }
	      XPUSHs(sv_2mortal(newSVpv(displayList.displayList[0].label, strlen(displayList.displayList[0].label))));
#endif
	      XPUSHs(sv_2mortal(newSViv(idList.internalIdList[loop])));
#if AR_EXPORT_VERSION < 3
	      FreeARDisplayList(&displayList, FALSE);
#endif
	    }
	    FreeARInternalIdList(&idList, FALSE);
	  }
	}

SV *
ars_CreateEntry(ctrl,schema,...)
	ARControlStruct *	ctrl
	char *			schema
	CODE:
	{
	  int               a, i, c = (items - 2) / 2;
	  AREntryIdType     entryId;
	  ARFieldValueList  fieldList;
	  ARStatusList      status;
	  int               ret, rv = 0;
	  unsigned int      dataType;
	  
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  if (((items - 2) % 2) || c < 1) {
	    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {
	    fieldList.numItems = c;
	    AMALLOCNN(fieldList.fieldValueList,c,ARFieldValueStruct);
	    for (i=0; i<c; i++) {
	      a = i*2+2;
	      fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
#if AR_EXPORT_VERSION >= 3
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId,	
			NULL, NULL, &dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
			NULL, NULL, NULL, NULL, &status);
#else
	      ret = ARGetFieldCached(ctrl, schema, fieldList.fieldValueList[i].fieldId, 
			&dataType, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
			NULL, NULL, &status);
#endif
	      if (ARError( ret, status)) {
		goto create_entry_end;
	      }
	      if (sv_to_ARValue(ctrl, ST(a+1), dataType, 
		  	        &fieldList.fieldValueList[i].value) < 0) {
		goto create_entry_end;
	      }
	    }
	    ret = ARCreateEntry(ctrl, schema, &fieldList, entryId, &status);
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (! ARError( ret, status)) rv = 1;

	  create_entry_end:;
	    if(rv == 0) {
		RETVAL = newSVsv(&PL_sv_undef);
	    } else {
		RETVAL = newSVpv( entryId, strlen(entryId) );
	    }
	  FreeARFieldValueList(&fieldList, FALSE);
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
	  int            ret;
	  ARStatusList   status;
#if AR_EXPORT_VERSION >= 3
	  AREntryIdList  entryList;

	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  if(perl_BuildEntryList(ctrl, &entryList, entry_id) != 0)
		goto delete_fail;
	  ret = ARDeleteEntry(ctrl, schema, &entryList, 0, &status);
	  FreeAREntryIdList(&entryList, FALSE);
#else /* ARS 2 */
	  RETVAL = 0; /* assume error */
	  if(!entry_id || !*entry_id) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID);
		goto delete_fail;
	  }
	  ret = ARDeleteEntry(ctrl, schema, entry_id, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError(ret, status))
	    RETVAL = 0;
	  else
	    RETVAL = 1;
	delete_fail:;
	}
	OUTPUT:
	RETVAL

void
ars_GetEntryBLOB(ctrl,schema,entry_id,field_id,locType,locFile=NULL)
	ARControlStruct *	ctrl
	char *			schema
	char *			entry_id
	ARInternalId		field_id
	int 			locType
	char *			locFile
	PPCODE:
	{
		ARStatusList    status;
		AREntryIdList   entryList;
#if AR_EXPORT_VERSION >= 4
		ARLocStruct     loc;
#endif
		int		ret;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 4
		/* build entryList */
	 	ret = perl_BuildEntryList(ctrl, &entryList, entry_id);
		if(ret)
			goto get_entryblob_end;
		switch(locType) {
		case AR_LOC_FILENAME:
			if(locFile == NULL) {
				ARError_add(AR_RETURN_ERROR,
					AP_ERR_USAGE,
					"locFile parameter required when specifying AR_LOC_FILENAME");
				goto get_entryblob_end;
			}
			loc.locType    = AR_LOC_FILENAME;
			loc.u.filename = locFile; /* strdup(locFile) ? i'm not completely sure
							which to use. will FreeARLocStruct call
							free(loc.locType)? i'm assuming it will.
							Purify doesnt complain, so i'm going 
							to leave this alone. */
			break;
		case AR_LOC_BUFFER:
			loc.locType       = AR_LOC_BUFFER;
			loc.u.buf.bufSize = 0;
			break;
		default:
			ARError_add(AR_RETURN_ERROR,
				AP_ERR_USAGE,
				"locType parameter is required.");
			goto get_entryblob_end;
			break;
		}
		ret = ARGetEntryBLOB(ctrl, schema, &entryList, field_id, 
				     &loc, &status);
		if(!ARError(ret, status)) {
			if(locType == AR_LOC_BUFFER)
#if PERL_PATCHLEVEL_IS >= 6
				XPUSHs(sv_2mortal(newSVpv((const char *)
					loc.u.buf.buffer, 
					loc.u.buf.bufSize)));
#else
				XPUSHs(sv_2mortal(newSVpv(
					loc.u.buf.buffer, 
					loc.u.buf.bufSize)));
#endif
			else
				XPUSHs(sv_2mortal(newSViv(1)));
		} else
			XPUSHs(&PL_sv_undef);
		FreeAREntryIdList(&entryList, FALSE);
		FreeARLocStruct(&loc, FALSE);
#else /* pre ARS-4.0 */
		(void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"ars_GetEntryBLOB() is only available > ARS4.x");
		XPUSHs(&PL_sv_undef);
#endif
	get_entryblob_end:;
	}

void
ars_GetEntry(ctrl,schema,entry_id,...)
	ARControlStruct *	ctrl
	char *			schema
	char *			entry_id
	PPCODE:
	{
	  int               ret;
	  unsigned int      c = items - 3, i;
	  ARInternalIdList  idList;
	  ARFieldValueList  fieldList;
	  ARStatusList      status;
#if AR_EXPORT_VERSION >= 3
	  AREntryIdList     entryList;
#endif

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  if (c < 1) {
	    idList.numItems = 0; /* get all fields */
	  } else {
	    idList.numItems = c;
	    idList.internalIdList = MALLOCNN(sizeof(ARInternalId) * c);
	    if (!idList.internalIdList)
	      goto get_entry_end;
	    for (i=0; i<c; i++)
	      idList.internalIdList[i] = SvIV(ST(i+3));
	  }
#if AR_EXPORT_VERSION >= 3
	  /* build entryList */
	  if(perl_BuildEntryList(ctrl, &entryList, entry_id) != 0)
		goto get_entry_end;

	  ret = ARGetEntry(ctrl, schema, &entryList, &idList, &fieldList, &status);
	  FreeAREntryIdList(&entryList,FALSE);
#else /* ARS 2 */
	  if(!entry_id || !*entry_id) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID);
		goto get_entry_cleanup;
	  }
	  ret = ARGetEntry(ctrl, schema, entry_id, &idList, &fieldList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError( ret, status)) {
	    goto get_entry_cleanup;
	  }
	  
	  if(fieldList.numItems < 1) {
	    goto get_entry_cleanup;
 	  }
	  for (i=0; i<fieldList.numItems; i++) {
	    XPUSHs(sv_2mortal(newSViv(fieldList.fieldValueList[i].fieldId)));
	    XPUSHs(sv_2mortal(perl_ARValueStruct(ctrl,
		&fieldList.fieldValueList[i].value)));
	  }
	  FreeARFieldValueList(&fieldList,FALSE);
	get_entry_cleanup:;
	  FreeARInternalIdList(&idList, FALSE);
	get_entry_end:;
	}

void
ars_GetListEntry(ctrl,schema,qualifier,maxRetrieve=0,firstRetrieve=0,...)
	ARControlStruct *	ctrl
	char *			schema
	ARQualifierStruct *	qualifier
	int			maxRetrieve
	int			firstRetrieve
	PPCODE:
	{
	  unsigned int     c = (items - 5) / 2;
	  unsigned int     i;
	  int              field_off    = 5;
	  int              staticParams = field_off;
	  ARSortList       sortList;
	  AREntryListList  entryList;
	  ARStatusList     status;
	  int              ret;
#if AR_EXPORT_VERSION >= 3
	  AREntryListFieldList getListFields, *getList = NULL;
	  AV              *getListFields_array;
	
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  Zero(&entryList, 1, AREntryListList);
	  Zero(&sortList, 1, ARSortList);

	  if ((items - staticParams) % 2) {
		/* odd number of arguments, so argument after maxRetrieve is
		optional getListFields (an array of hash refs) */
	
		if (SvROK(ST(field_off)) &&
			(getListFields_array = (AV *)SvRV(ST(field_off))) &&
			SvTYPE(getListFields_array) == SVt_PVAV) {
	
			getList                = &getListFields;
			getListFields.numItems = av_len(getListFields_array) + 1;
			AMALLOCNN(getListFields.fieldsList, getListFields.numItems,
				AREntryListFieldStruct);
	
			/* set query field list */
			for (i = 0 ; i < getListFields.numItems ; i++) {
				SV **array_entry, **hash_entry;
				HV *field_hash;
	
				/* get hash from array */
				if ((array_entry = av_fetch(getListFields_array, i, 0)) &&
					SvROK(*array_entry) &&
					SvTYPE(field_hash = (HV*)SvRV(*array_entry)) == SVt_PVHV) {
	
					/* get fieldId, columnWidth and separator from hash */
					if (! (hash_entry = hv_fetch(field_hash, "fieldId", strlen("fieldId"), 0))) {
						(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
						FreeAREntryListFieldList(&getListFields, FALSE);
						goto getlistentry_end;
					}
	
					getListFields.fieldsList[i].fieldId = SvIV(*hash_entry);
					if (! (hash_entry = hv_fetch(field_hash, "columnWidth",
							strlen("columnWidth"), 0))) {
						(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
						FreeAREntryListFieldList(&getListFields, FALSE);
						goto getlistentry_end;
					}
	
					getListFields.fieldsList[i].columnWidth = SvIV(*hash_entry);
					if (! (hash_entry = hv_fetch(field_hash,  "separator",
							strlen("separator"), 0))) {
						(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
						FreeAREntryListFieldList(&getListFields, FALSE);
						goto getlistentry_end;
					}
	
					strncpy(getListFields.fieldsList[i].separator,
						SvPV(*hash_entry, PL_na),
						sizeof(getListFields.fieldsList[i].separator));
				}
			}
		} else {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_LFLDS_TYPE);
			goto getlistentry_end;
		}
		/* increase the offset of the first sortList field by one */
		field_off ++;
	  }
#else  /* ARS 2 */
	  Zero(&status, 1,ARStatusList);
	  (void) ARError_reset();
	  if ((items - staticParms) % 2) {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
		goto getlistentry_end;
	  }
#endif /* if ARS >= 3 */
	
	  /* build sortList */
	  Zero(&sortList, 1, ARSortList);
	  if (c) {
	  	sortList.numItems = c;
          	AMALLOCNN(sortList.sortList, c,  ARSortStruct);
	  	for ( i = 0 ; i < c ; i++) {
			sortList.sortList[i].fieldId   = SvIV(ST(i*2+field_off));
			sortList.sortList[i].sortOrder = SvIV(ST(i*2+field_off+1));
	  	}
	  }
#if AR_EXPORT_VERSION >= 8L
	  ret = ARGetListEntry(ctrl, schema, qualifier, getList, &sortList, 
				firstRetrieve, maxRetrieve, FALSE, &entryList, 
				NULL, &status);
#elif AR_EXPORT_VERSION >= 6
	  ret = ARGetListEntry(ctrl, schema, qualifier, getList, &sortList, 
				firstRetrieve, maxRetrieve, &entryList, 
				NULL, &status);
#elif AR_EXPORT_VERSION >= 3
	  ret = ARGetListEntry(ctrl, schema, qualifier, getList, &sortList, 
				maxRetrieve, &entryList, NULL, &status);
#else
	  ret = ARGetListEntry(ctrl, schema, qualifier, &sortList, 
				maxRetrieve, &entryList, NULL, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError( ret, status)) {
		goto getlistentry_end;
	  }
	  for (i = 0 ; i < entryList.numItems ; i++) {
#if AR_EXPORT_VERSION >= 3
		if (entryList.entryList[i].entryId.numItems == 1) {
			/* only one entryId -- so just return its value to be compatible
			   with ars 2 */
			XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].entryId.entryIdList[0], 0)));
		} else {
			/* more than one entry -- this must be a join schema. merge
			 * the list into a single entry-id to keep things
			 * consistent.
			 */
			unsigned int   entry;
			char *joinId     = (char *)NULL;
			char  joinSep[2] = {AR_ENTRY_ID_SEPARATOR, 0};
	
			for ( entry = 0 ; entry < entryList.entryList[i].entryId.numItems ; entry++) {
				joinId = strappend(joinId, 
					entryList.entryList[i].entryId.entryIdList[entry]);
				if(entry < entryList.entryList[i].entryId.numItems-1)
					joinId = strappend(joinId, joinSep);
			}
			XPUSHs(sv_2mortal(newSVpv(joinId, 0)));
			AP_FREE(joinId);
		}
#else /* ARS 2 */
		XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].entryId, 0)));
#endif
		XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].shortDesc, 0)));
	  }
	getlistentry_end:;
	  FreeARSortList(&sortList, FALSE);
	  FreeAREntryListList(&entryList,FALSE);
	}

void ars_GetListSchema(ctrl,changedsince=0,schemaType=AR_LIST_SCHEMA_ALL,fieldPropList=NULL,name=NULL,fieldIdList=NULL)
	ARControlStruct *	ctrl
	unsigned int		changedsince
	unsigned int		schemaType
	char *			name
	AV *			fieldIdList
	ARPropList *		fieldPropList
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
	  unsigned int i;
	  int          ret;
#if AR_EXPORT_VERSION >= 8L
	  ARPropList propList;
#endif
#if AR_EXPORT_VERSION >= 6
	  ARInternalIdList idList;

	  Zero(&idList, 1, ARInternalIdList);	  
#endif

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 6
	  if (fieldIdList && (SvTYPE(fieldIdList) == SVt_PVAV)) {
		idList.numItems = av_len(fieldIdList) + 1;
		AMALLOCNN(idList.internalIdList, idList.numItems, ARInternalId);
		for (i = 0 ; i < idList.numItems ; i++ ) {
			SV **array_entry;
			if ((array_entry = av_fetch(fieldIdList, i, 0)) &&
			    SvROK(*array_entry)                         &&
		 	    (SvTYPE(*array_entry) == SVt_PVIV) ) {
				idList.internalIdList[i] = (unsigned long) (SvIV(*array_entry));
			} 
		}
	  }
#endif
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListSchema(ctrl, changedsince, schemaType, name, 
# if AR_EXPORT_VERSION >= 8L
				&idList, &propList,
# elif AR_EXPORT_VERSION >= 6 && AR_EXPORT_VERSION < 8L
				&idList,
# endif
				&nameList, &status);
#else
	  ret = ARGetListSchema(ctrl, changedsince, 
				&nameList, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret, status)) {
	    for (i=0; i<nameList.numItems; i++) {
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    }
	    FreeARNameList(&nameList,FALSE);
	  }
	}

void
ars_GetListContainer(ctrl,changedSince=0,attributes=0,...)
	ARControlStruct *	ctrl
	ARTimestamp		changedSince
	unsigned int		attributes
	PPCODE:
	{
	  ARStatusList 		status;

	  (void) ARError_reset();	  
	  Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 4
	  if(items > 3) {
		int 			i;
	  	ARContainerTypeList	containerTypes;
# if AR_EXPORT_VERSION >= 6
		ARContainerOwnerObjList ownerObjList;
# else
		ARContainerOwnerObj 	ownerObj;
# endif
# if AR_EXPORT_VERSION >= 8L
		ARPropList		propList;
# endif
		ARContainerInfoList	conList;

		containerTypes.numItems = items - 3;
		AMALLOCNN(containerTypes.type, 
		     containerTypes.numItems, int);
		for(i = 3 ; i < items ; i++) {
			containerTypes.type[i-3] = SvIV(ST(i));
		}

		i = ARGetListContainer(ctrl, changedSince,
					&containerTypes,
					attributes,
# if AR_EXPORT_VERSION >= 6
					&ownerObjList,
# else
					&ownerObj, 
# endif
# if AR_EXPORT_VERSION >= 8L
                                        &propList,
# endif

					&conList, &status);
		if(!ARError(i, status)) {
			HV *r = newHV();				
		}
		FreeARContainerTypeList(&containerTypes, FALSE);
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
#else
#endif
	}

void
ars_GetListServer()
	PPCODE:
	{
	  ARServerNameList serverList;
	  ARStatusList     status;
	  int              ret;
          unsigned int     i;
	  ARControlStruct  ctrl;

	  (void) ARError_reset();  
	  Zero(&status, 1, ARStatusList);
	  Zero(&ctrl, 1, ARControlStruct);
#if AR_EXPORT_VERSION >= 4
	  /* this function can be called without a control struct 
	   * (or even before a control struct is available).
	   * we will create a bogus control struct, initialize it
	   * and execute the function. this seems to work fine.
	   */
	  ARInitialization(&ctrl, &status);
	  ret = ARGetListServer(&ctrl, &serverList, &status);
#else
	  ret = ARGetListServer(&serverList, &status);
#endif
	  if (! ARError( ret, status)) {
	    for (i=0; i<serverList.numItems; i++) {
	      XPUSHs(sv_2mortal(newSVpv(serverList.nameList[i], 0)));
	    }
	    FreeARServerNameList(&serverList,FALSE);
	  }
	}

HV *
ars_GetActiveLink(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  int              ret;
	  unsigned int     order;
#if AR_EXPORT_VERSION < 5
	  ARNameType       schema;
#endif
	  ARInternalIdList groupList;
	  unsigned int     executeMask;
#if AR_EXPORT_VERSION >= 3
	  ARInternalId     controlField;
	  ARInternalId     focusField;
#else	  
	  ARInternalId     field;
	  ARDisplayList    displayList;
#endif
	  unsigned int     enable;
	  ARActiveLinkActionList actionList;
#if  AR_EXPORT_VERSION >= 3
	  ARActiveLinkActionList elseList;
#endif
#if  AR_EXPORT_VERSION >= 5
	  ARWorkflowConnectStruct  schemaList;
	  ARPropList       objPropList;
#endif
	  char            *helpText = CPNULL;
	  ARTimestamp      timestamp;
	  ARNameType       owner;
	  ARNameType       lastChanged;
	  char            *changeDiary = CPNULL;
	  ARStatusList     status;
	  SV              *ref;
	  ARQualifierStruct *query;
	  ARDiaryList      diaryList;

	  AMALLOCNN(query,1,ARQualifierStruct);

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 5 
	  ret = ARGetActiveLink(ctrl, name, &order, 
				&schemaList,  /* new in 4.5 */
				&groupList,
				&executeMask, &controlField, &focusField,
				&enable, query, &actionList, &elseList, &helpText,
				&timestamp, owner, lastChanged, &changeDiary, 
				&objPropList, /* new in 4.5 */
				&status);
#elif  AR_EXPORT_VERSION >= 3 
	  ret = ARGetActiveLink(ctrl,name,&order,schema,&groupList,
				&executeMask,&controlField,&focusField,&enable,
				query,&actionList,&elseList,&helpText,&timestamp,
				owner,lastChanged,&changeDiary,&status);
#else
	  ret = ARGetActiveLink(ctrl,name,&order,schema,&groupList,&executeMask,&field,&displayList,&enable,query,&actionList,&helpText,&timestamp,owner,lastChanged,&changeDiary,&status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  RETVAL = newHV();
	  if (!ARError( ret,status)) {
		/* store name of active link */
		hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
		hv_store(RETVAL,  "order", strlen("order") , newSViv(order),0);
#if AR_EXPORT_VERSION >= 5
		hv_store(RETVAL,  "schemaList", strlen("schemaList") , /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			perl_ARPropList(ctrl, &objPropList), 0);
#else
		hv_store(RETVAL,  "schema", strlen("schema") , newSVpv(schema,0),0);
#endif
		hv_store(RETVAL,  "groupList", strlen("groupList") ,
		     perl_ARList( ctrl, 
				 (ARList *)&groupList,
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)), 0);
		hv_store(RETVAL,  "executeMask", strlen("executeMask") , newSViv(executeMask),0);
#if  AR_EXPORT_VERSION >= 3
		hv_store(RETVAL,  "focusField", strlen("focusField") , newSViv(focusField), 0);
		hv_store(RETVAL,  "controlField", strlen("controlField") , 
			newSViv(controlField), 0);
#else
		hv_store(RETVAL,  "field", strlen("field") , newSViv(field), 0);
		hv_store(RETVAL,  "displayList", strlen("displayList") , 
		     perl_ARList( ctrl, 
				 (ARList *)&displayList,
				 (ARS_fn)perl_ARDisplayStruct,
				 sizeof(ARDisplayStruct)), 0);
#endif
		hv_store(RETVAL,  "enable", strlen("enable") , newSViv(enable), 0);
		/* a bit of a hack -- makes blessed reference to qualifier */
		ref = newSViv(0);
		sv_setref_pv(ref, "ARQualifierStructPtr", (void*)query);
		hv_store(RETVAL,  "query", strlen("query") , ref, 0);
		hv_store(RETVAL,  "actionList", strlen("actionList") ,
		     perl_ARList(ctrl, 
				 (ARList *)&actionList,
				 (ARS_fn)perl_ARActiveLinkActionStruct,
				 sizeof(ARActiveLinkActionStruct)), 0);
#if  AR_EXPORT_VERSION >= 3
		hv_store(RETVAL,  "elseList", strlen("elseList") ,
		     perl_ARList(ctrl, 
				 (ARList *)&elseList,
				 (ARS_fn)perl_ARActiveLinkActionStruct,
				 sizeof(ARActiveLinkActionStruct)), 0);
#endif
		if (helpText)
			hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText,0), 0);
		hv_store(RETVAL,  "timestamp", strlen("timestamp") ,  newSViv(timestamp), 0);
		hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner,0), 0);
		hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged,0), 0);
		if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
			ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
			ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
			if (!ARError(ret, status)) {
				hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
					perl_ARList(ctrl, (ARList *)&diaryList,
						    (ARS_fn)perl_diary,
						    sizeof(ARDiaryStruct)), 0);
				FreeARDiaryList(&diaryList, FALSE);
			}
	    }
	    FreeARInternalIdList(&groupList,FALSE);
#if  AR_EXPORT_VERSION < 3
	    FreeARDisplayList(&displayList,FALSE);
#endif
	    FreeARActiveLinkActionList(&actionList,FALSE);
#if  AR_EXPORT_VERSION >= 3
	    FreeARActiveLinkActionList(&elseList,FALSE);
#endif
#if  AR_EXPORT_VERSION >= 5
	    FreeARWorkflowConnectStruct(&schemaList, FALSE);
	    FreeARPropList(&objPropList, FALSE);
#endif
	    if(helpText) AP_FREE(helpText);
	    if(changeDiary) AP_FREE(changeDiary);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_SetFilter(ctrl,filterDefRef)
	ARControlStruct *	ctrl
	SV		*	filterDefRef
	CODE:
	{
		ARStatusList       status;
		ARFilterActionList actionList;
#if AR_EXPORT_VERSION >= 3
		ARFilterActionList  elseList;
#endif
		RETVAL = 1;
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		Zero(&actionList, 1, ARFilterActionList);
#if AR_EXPORT_VERSION >= 3
		Zero(&elseList, 1, ARFilterActionList);
#endif
	/*
	char *name
	char *newName
	unsigned int order
	char *schema
	unsigned int opSet
	unsigned int enabled
	ARQualifierStruct *query
	ARFilterActionList *actionList
	ARFilterActionList *elseList
	char *helpText
	char *owner
	char *changeDiary
	*/
	}
	OUTPUT:
	RETVAL

HV *
ars_GetFilter(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  int          ret;
	  unsigned int order;
	  unsigned int opSet;
#if AR_EXPORT_VERSION < 5
	  ARNameType       schema;
#endif
	  unsigned int enable;
	  char        *helpText = CPNULL;
	  char        *changeDiary = CPNULL;
	  ARFilterActionList actionList;
#if  AR_EXPORT_VERSION >= 3
	  ARFilterActionList elseList;
#endif
	  ARTimestamp timestamp;
	  ARNameType  owner;
	  ARNameType  lastChanged;
	  ARStatusList status;
	  SV         *ref;
	  ARQualifierStruct *query;
	  ARDiaryList      diaryList;
#if  AR_EXPORT_VERSION >= 5
	  ARWorkflowConnectStruct  schemaList;
	  ARPropList       objPropList;
#endif

	  AMALLOCNN(query,1,ARQualifierStruct);

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
#if AR_EXPORT_VERSION >= 5
	  ret = ARGetFilter(ctrl, name, &order, 
			    &schemaList,
			    &opSet, &enable, 
			    query, &actionList, &elseList, &helpText,
			    &timestamp, owner, lastChanged, &changeDiary,
			    &objPropList,
			    &status);
#elif AR_EXPORT_VERSION >= 3
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
	  if (!ARError( ret,status)) {
	    hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
	    hv_store(RETVAL,  "order", strlen("order") , newSViv(order), 0);
#if AR_EXPORT_VERSION >= 5
		hv_store(RETVAL,  "schemaList", strlen("schemaList") , /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			perl_ARPropList(ctrl, &objPropList), 0);
#else
	    hv_store(RETVAL,  "schema", strlen("schema") , newSVpv(schema, 0), 0);
#endif
	    hv_store(RETVAL,  "opSet", strlen("opSet") , newSViv(opSet), 0);
	    hv_store(RETVAL,  "enable", strlen("enable") , newSViv(enable), 0);
	    /* a bit of a hack -- makes blessed reference to qualifier */
	    ref = newSViv(0);
	    sv_setref_pv(ref, "ARQualifierStructPtr", (void *)query);
	    hv_store(RETVAL,  "query", strlen("query") , ref, 0);
	    hv_store(RETVAL,  "actionList", strlen("actionList") , 
		     perl_ARList(ctrl, 
				 (ARList *)&actionList,
				 (ARS_fn)perl_ARFilterActionStruct,
				 sizeof(ARFilterActionStruct)), 0);
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL,  "elseList", strlen("elseList") ,
		     perl_ARList(ctrl, 
				 (ARList *)&elseList,
				 (ARS_fn)perl_ARFilterActionStruct,
				 sizeof(ARFilterActionStruct)), 0);
#endif
	    if(helpText)
		hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	    hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	    hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	    hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
	    FreeARFilterActionList(&actionList,FALSE);
#if AR_EXPORT_VERSION >= 3
	    FreeARFilterActionList(&elseList,FALSE);
#endif
#if AR_EXPORT_VERSION >= 5
	    FreeARWorkflowConnectStruct(&schemaList, FALSE);
	    FreeARPropList(&objPropList, FALSE);
#endif
	    if(helpText) {
	      	AP_FREE(helpText);
	    }
	    if(changeDiary) {
	      	AP_FREE(changeDiary);
	    }
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
	  ARServerInfoList        serverInfo;
	  int                     i, ret;
          unsigned int            ui;
	  ARStatusList            status;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  if(items < 1) {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {
		requestList.numItems = items - 1;
		AMALLOCNN(requestList.requestList,(items-1),unsigned int);
		if(requestList.requestList) {
			for(i=1; i<items; i++) {
				requestList.requestList[i-1] = SvIV(ST(i));
			}
			ret = ARGetServerStatistics(ctrl, &requestList, &serverInfo, &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if (!ARError(ret, status)) {
				for(ui=0; ui<serverInfo.numItems; ui++) {
					XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[ui].operation)));
					switch(serverInfo.serverInfoList[ui].value.dataType) {
					case AR_DATA_TYPE_ENUM:
					case AR_DATA_TYPE_TIME:
					case AR_DATA_TYPE_BITMASK:
					case AR_DATA_TYPE_INTEGER:
						XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[ui].value.u.intVal)));
						break;
					case AR_DATA_TYPE_REAL:
						XPUSHs(sv_2mortal(newSVnv(serverInfo.serverInfoList[ui].value.u.realVal)));
						break;
					case AR_DATA_TYPE_CHAR:
						XPUSHs(sv_2mortal(newSVpv(serverInfo.serverInfoList[ui].value.u.charVal,
							strlen(serverInfo.serverInfoList[ui].value.u.charVal))));
						break;
					}
				}
			}
			FreeARServerInfoList(&serverInfo, FALSE);
			FreeARServerInfoRequestList(&requestList, FALSE);
		} else {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_MALLOC);
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
	  char	            *helpText = CPNULL;
	  ARTimestamp	     timestamp;
	  ARNameType	     owner;
	  ARNameType	     lastChanged;
	  char		    *changeDiary = CPNULL;
	  ARStatusList	     status;
	  int                ret, i;
	  HV		    *menuDef = newHV();
	  SV		    *ref;
	  ARDiaryList        diaryList;
#if AR_EXPORT_VERSION >= 5
	  ARPropList         objPropList;
#endif

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = newHV();
	  ret = ARGetCharMenu(ctrl, name, &refreshCode, &menuDefn, &helpText, 
			      &timestamp, owner, lastChanged, &changeDiary, 
#if AR_EXPORT_VERSION >= 5
			      &objPropList,
#endif
			      &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
		hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
		if(helpText)
			hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText,0), 0);
		hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
		hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
		hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	        if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
			ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
			ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
			if (!ARError(ret, status)) {
				hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
					perl_ARList(ctrl, (ARList *)&diaryList,
					(ARS_fn)perl_diary,
					sizeof(ARDiaryStruct)), 0);
				FreeARDiaryList(&diaryList, FALSE);
			}
	        }
		for(i = 0; CharMenuTypeMap[i].number != TYPEMAP_LAST; i++) {
			if (CharMenuTypeMap[i].number == menuDefn.menuType)
				break;
		}
		hv_store(RETVAL,  "menuType", strlen("menuType") , 
			   /* PRE-1.68: newSViv(menuDefn.menuType) */
			newSVpv( CharMenuTypeMap[i].name, strlen(CharMenuTypeMap[i].name) )
			, 0);
		hv_store(RETVAL,  "refreshCode", strlen("refreshCode") , 
			perl_MenuRefreshCode2Str(ctrl, refreshCode), 0);
		switch(menuDefn.menuType) {
		case AR_CHAR_MENU_QUERY:
			hv_store(menuDef,  "schema", strlen("schema") , 
				newSVpv(menuDefn.u.menuQuery.schema, 0), 0);
			hv_store(menuDef,  "server", strlen("server") , 
				newSVpv(menuDefn.u.menuQuery.server, 0), 0);
#if AR_EXPORT_VERSION >= 6
			{
				int lfn = 0;
				AV *a = newAV();
				while (lfn < 6) {
					if ( menuDefn.u.menuQuery.labelField[lfn] ) {
						av_push(a, newSViv(menuDefn.u.menuQuery.labelField[lfn]));
					} else {
						av_push(a, newSVsv(&PL_sv_undef));
					}
					lfn++;
				}
				hv_store(menuDef, "labelField", strlen("labelField"),
					 newRV_noinc((SV *) a), 0);
			}
#else
			{
				AV *a = newAV();
				av_push(a, newSViv(menuDefn.u.menuQuery.labelField));
				hv_store(menuDef, "labelField", strlen("labelField"),
					newRV_noinc((SV *)a), 0);
			}
#endif
			hv_store(menuDef,  "valueField", strlen("valueField") ,
				newSViv(menuDefn.u.menuQuery.valueField), 0);
			hv_store(menuDef,  "sortOnLabel", strlen("sortOnLabel") ,
				newSViv(menuDefn.u.menuQuery.sortOnLabel), 0);
			ref = newSViv(0);
			sv_setref_pv(ref, "ARQualifierStructPtr", 
				dup_qualifier(ctrl,
					(void *)&(menuDefn.u.menuQuery.qualifier)));
			hv_store(menuDef,  "qualifier", strlen("qualifier") , ref, 0);
			hv_store(RETVAL,  "menuQuery", strlen("menuQuery") , 
				newRV_noinc((SV *)menuDef), 0);
			break;
		case AR_CHAR_MENU_FILE:
			hv_store(menuDef,  "fileLocation", strlen("fileLocation") , 
				newSViv(menuDefn.u.menuFile.fileLocation), 0);
			hv_store(menuDef,  "filename", strlen("filename") , 
				newSVpv(menuDefn.u.menuFile.filename, 0), 0);
			hv_store(RETVAL,  "menuFile", strlen("menuFile") ,
				newRV_noinc((SV *)menuDef), 0);
			break;
#ifndef ARS20
		case AR_CHAR_MENU_SQL:
			hv_store(menuDef,  "server", strlen("server") , 
				newSVpv(menuDefn.u.menuSQL.server, 0), 0);
			hv_store(menuDef,  "sqlCommand", strlen("sqlCommand") , 
				newSVpv(menuDefn.u.menuSQL.sqlCommand, 0), 0);
#if AR_EXPORT_VERSION >= 6
			{
				int lfn = 0;
				AV *a = newAV();
				while (lfn < 6) {
					if ( menuDefn.u.menuSQL.labelIndex[lfn] ) {
						av_push(a, newSViv(menuDefn.u.menuSQL.labelIndex[lfn]));
					} else {
						av_push(a, newSVsv(&PL_sv_undef));
					}
					lfn++;
				}
				hv_store(menuDef, "labelIndex", strlen("labelIndex"),
					 newRV_noinc((SV *) a), 0);
			}
#else
			hv_store(menuDef,  "labelIndex", strlen("labelIndex") , 
				newSViv(menuDefn.u.menuSQL.labelIndex), 0);
#endif
			hv_store(menuDef,  "valueIndex", strlen("valueIndex") , 
				newSViv(menuDefn.u.menuSQL.valueIndex), 0);
			hv_store(RETVAL,  "menuSQL", strlen("menuSQL") , 
				newRV_noinc((SV *)menuDef), 0);
			break;
#endif
		}
#if AR_EXPORT_VERSION >= 5
		FreeARPropList(&objPropList, FALSE);
#endif
		FreeARCharMenuStruct(&menuDefn, FALSE);
		if (helpText) {
		  	AP_FREE(helpText);
		}
		if (changeDiary) {
		  	AP_FREE(changeDiary);
		}
	  }
	}
	OUTPUT:
	RETVAL

SV *
ars_ExpandCharMenu2(ctrl,name,qual=NULL)
	ARControlStruct *	ctrl
	char *			name
	ARQualifierStruct *     qual
	CODE:
	{
		ARCharMenuStruct menuDefn;
		ARStatusList     status;
		int              ret;

		RETVAL = &PL_sv_undef;
		(void) ARError_reset();
		Zero(&status, 1,ARStatusList);
		DBG( ("-> ARGetCharMenu\n") );
		ret = ARGetCharMenu(ctrl, name, NULL, &menuDefn, 
					NULL, NULL, NULL, NULL, NULL, 
#if AR_EXPORT_VERSION >= 5
			      		NULL,
#endif
			     		&status);
		DBG( ("<- ARGetCharMenu\n") );
#ifdef PROFILE
		((ars_ctrl *)ctrl)->queries++;
#endif
		if (! ARError(ret, status)) {
			DBG( ("-> perl_expandARCharMenuStruct\n") );
			RETVAL = perl_expandARCharMenuStruct(ctrl, 
							     &menuDefn);
			DBG( ("<- perl_expandARCharMenuStruct\n") );
			FreeARCharMenuStruct(&menuDefn, FALSE);
			DBG( ("after Free\n") );
		}
	}
	OUTPUT:
	RETVAL

HV *
ars_GetSchema(ctrl,name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList         status;
	  int                  ret;
#if AR_EXPORT_VERSION >= 3
	  ARPermissionList     groupList;
#else
	  ARInternalIdList     groupList;
#endif
#if AR_EXPORT_VERSION >= 8L
	  ARSchemaInheritanceList inheritanceList;
	  ARArchiveInfoStruct infoStruct;
#endif
	  ARInternalIdList     adminGroupList;
	  AREntryListFieldList getListFields;
	  ARIndexList          indexList;
	  char                *helpText = CPNULL;
	  ARTimestamp          timestamp;
	  ARNameType           owner;
	  ARNameType           lastChanged;
	  char                *changeDiary = CPNULL;
	  ARDiaryList          diaryList;
#if AR_EXPORT_VERSION >= 3
	  ARCompoundSchema     schema;
	  ARSortList           sortList;
#endif
#if AR_EXPORT_VERSION >= 5
	  ARPropList           objPropList;
#endif
#if AR_EXPORT_VERSION >= 6
	  ARNameType           defaultVui;
#endif

	  (void) ARError_reset();
	  Zero(&status, 1,  ARStatusList);
#if AR_EXPORT_VERSION >= 6
	  Zero(&defaultVui, 1, ARNameType);
#endif
	  RETVAL = newHV();
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetSchema(ctrl, name, &schema, 
#if AR_EXPORT_VERSION >= 8L
                            &inheritanceList,
#endif
			    &groupList, &adminGroupList, &getListFields, 
			    &sortList, &indexList, 
#if AR_EXPORT_VERSION >= 8L
                            &infoStruct,
#endif
# if AR_EXPORT_VERSION >= 6
			    defaultVui,
# endif
			    &helpText, &timestamp, owner, 
			    lastChanged, &changeDiary, 
# if AR_EXPORT_VERSION >= 5
			    &objPropList,
# endif
			    &status);
#else
	  ret = ARGetSchema(ctrl, name, &groupList, &adminGroupList, &getListFields, &indexList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (!ARError( ret,status)) {
#if AR_EXPORT_VERSION >= 5
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			 perl_ARPropList(ctrl, &objPropList), 0);
#endif
#if AR_EXPORT_VERSION >= 6
		hv_store(RETVAL, "defaultVui", strlen("defaultVui"),
			newSVpv(defaultVui, 0), 0);			
#endif
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL,  "groupList", strlen("groupList") ,
		     perl_ARPermissionList(ctrl, &groupList, PERMTYPE_SCHEMA), 0);
#else
	    hv_store(RETVAL,  "groupList", strlen("groupList") ,
		     perl_ARList(ctrl, (ARList *)&groupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
#endif
	    hv_store(RETVAL,  "adminList", strlen("adminList") ,
		     perl_ARList(ctrl, (ARList *)&adminGroupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
	    hv_store(RETVAL,  "getListFields", strlen("getListFields") ,
		     perl_ARList(ctrl, (ARList *)&getListFields,
				 (ARS_fn)perl_AREntryListFieldStruct,
				 sizeof(AREntryListFieldStruct)),0);
	    hv_store(RETVAL,  "indexList", strlen("indexList") ,
		     perl_ARList(ctrl, (ARList *)&indexList,
				 (ARS_fn)perl_ARIndexStruct,
				 sizeof(ARIndexStruct)), 0);
	    if (helpText)
	      hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	    hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	    hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	    hv_store(RETVAL,  "lastChanged", strlen("lastChanged") ,
		     newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL,  "schema", strlen("schema") , 
			perl_ARCompoundSchema(ctrl, &schema), 0);
	    hv_store(RETVAL,  "sortList", strlen("sortList") , 
			perl_ARSortList(ctrl, &sortList), 0);
#endif
#if AR_EXPORT_VERSION >= 3
	    FreeARPermissionList(&groupList,FALSE);
#else
	    FreeARInternalIdList(&groupList,FALSE);
#endif
	    FreeARInternalIdList(&adminGroupList,FALSE);
	    FreeAREntryListFieldList(&getListFields,FALSE);
	    FreeARIndexList(&indexList,FALSE);
	    if(helpText) {
	      	AP_FREE(helpText);
	    }
	    if(changeDiary) {
	      	AP_FREE(changeDiary);
	    }
#if AR_EXPORT_VERSION >= 3
	    FreeARCompoundSchema(&schema,FALSE);
	    FreeARSortList(&sortList,FALSE);
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
	  ARNameList   nameList;
	  ARStatusList status;
          ARPropList   propList;
	  int          ret;
          unsigned int i;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret=ARGetListActiveLink(ctrl,schema,changedSince,
#if AR_EXPORT_VERSION >= 8L
                     &propList,
#endif
                     &nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i],0)));
	    FreeARNameList(&nameList,FALSE);
	  }
	}

HV *
ars_GetField(ctrl,schema,id)
	ARControlStruct *	ctrl
	char *			schema
	unsigned long		id
	CODE:
	{
	  int                   ret;
	  ARStatusList          Status;
	  unsigned int          dataType, option, createMode;
	  ARValueStruct         defaultVal;
	  ARPermissionList      permissions;
	  ARFieldLimitStruct    limit;
#if AR_EXPORT_VERSION >= 3
	  ARNameType            fieldName;
	  ARFieldMappingStruct  fieldMap;
	  ARDisplayInstanceList displayList;
#else
	  ARDisplayList         displayList;
#endif
	  char                 *helpText = CPNULL;
	  ARTimestamp           timestamp;
	  ARNameType            owner;
	  ARNameType            lastChanged;
	  char                 *changeDiary = CPNULL;
	  ARDiaryList           diaryList;

	  (void) ARError_reset();
	  Zero(&Status,      1, ARStatusList);
	  Zero(&defaultVal,  1, ARValueStruct);
	  Zero(&permissions, 1, ARPermissionList);
	  Zero(&limit,       1, ARFieldLimitStruct);
	  RETVAL = newHV();
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetFieldCached(ctrl, schema, id, fieldName, &fieldMap, &dataType, &option, &createMode, &defaultVal, NULL /* &permissions */, &limit, &displayList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &Status);
#else
	  ret = ARGetFieldCached(ctrl, schema, id, &dataType, &option, &createMode, &defaultVal, NULL /* &permissions */, &limit, &displayList, &helpText, &timestamp, owner, lastChanged, &changeDiary, &Status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret, Status)) {
	    /* store field id for convenience */
	    hv_store(RETVAL,  "fieldId", strlen("fieldId") , newSViv(id), 0);
	    if (createMode == AR_FIELD_OPEN_AT_CREATE)
	      hv_store(RETVAL,  "createMode", strlen("createMode") , newSVpv("open",0), 0);
	    else
	      hv_store(RETVAL,  "createMode", strlen("createMode") ,
		       newSVpv("protected",0), 0);
	    hv_store(RETVAL,  "option", strlen("option") , newSViv(option), 0);
	    hv_store(RETVAL,  "dataType", strlen("dataType") ,
		     perl_dataType_names(ctrl, &dataType), 0);
	    hv_store(RETVAL,  "defaultVal", strlen("defaultVal") ,
		     perl_ARValueStruct(ctrl, &defaultVal), 0);
	    /* permissions below */
	    hv_store(RETVAL,  "limit", strlen("limit") , 
		     perl_ARFieldLimitStruct(ctrl, &limit), 0);
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL,  "fieldName", strlen("fieldName") , 
		     newSVpv(fieldName, 0), 0);
	    hv_store(RETVAL,  "fieldMap", strlen("fieldMap") ,
		     perl_ARFieldMappingStruct(ctrl, &fieldMap), 0);
	    hv_store(RETVAL,  "displayInstanceList", strlen("displayInstanceList") ,
		     perl_ARDisplayInstanceList(ctrl, &displayList), 0);
#else
	    hv_store(RETVAL,  "displayList", strlen("displayList") , 
		     perl_ARList(ctrl, 
				 (ARList *)&displayList,
				 (ARS_fn)perl_ARDisplayStruct,
				 sizeof(ARDisplayStruct)), 0);
#endif
	    if (helpText)
	      hv_store(RETVAL,  "helpText", strlen("helpText") ,
		       newSVpv(helpText, 0), 0);
	    hv_store(RETVAL,  "timestamp", strlen("timestamp") , 
		     newSViv(timestamp), 0);
	    hv_store(RETVAL,  "owner", strlen("owner") ,
		     newSVpv(owner, 0), 0);
	    hv_store(RETVAL,  "lastChanged", strlen("lastChanged") ,
		     newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &Status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &Status);
#endif
		if (!ARError(ret, Status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
	    FreeARFieldLimitStruct(&limit,FALSE);
#if AR_EXPORT_VERSION >= 3
	    FreeARDisplayInstanceList(&displayList,FALSE);
#else
	    FreeARDisplayList(&displayList,FALSE);
#endif
	    if(helpText) {
	      	AP_FREE(helpText);
	    }
	    if(changeDiary) {
	      	AP_FREE(changeDiary);
	    }
#if AR_EXPORT_VERSION >= 3
	    ret = ARGetField(ctrl, schema, id, NULL, NULL, NULL, NULL, NULL, NULL, &permissions, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &Status);
#else
	    ret = ARGetField(ctrl, schema, id, NULL, NULL, NULL, NULL, &permissions, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &Status);
#endif
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (ret == 0) {
	      hv_store(RETVAL,  "permissions", strlen("permissions") , 
		       perl_ARPermissionList(ctrl, &permissions, PERMTYPE_FIELD), 0);
	      FreeARPermissionList(&permissions,FALSE);
            } else {
	      FreeARStatusList(&Status, FALSE);
            } 
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
	  int              a, i, c = (items - 4) / 2;
	  int              offset = 4;
	  ARFieldValueList fieldList;
	  ARStatusList     status;
	  int              ret;
	  unsigned int     dataType;
#if AR_EXPORT_VERSION >= 3
	  unsigned int     option = AR_JOIN_SETOPTION_NONE;
	  AREntryIdList   entryList;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&fieldList, 1, ARFieldValueList);
	  Zero(&entryList, 1,AREntryIdList);
	  RETVAL = 0; /* assume error */
	  if ((items - 4) % 2) {
	    option = SvIV(ST(offset));
	    offset ++;
	  }
	  if (c < 1) {
	    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	    goto set_entry_exit;
	  }
#else
	  (void) ARError_reset();
	  RETVAL = 0; /* assume error */
	  if (((items - 4) % 2) || c < 1) {
	    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	    goto set_entry_exit;
	  }
#endif
	  fieldList.numItems = c;
	  AMALLOCNN(fieldList.fieldValueList,c,ARFieldValueStruct);
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
	      if (ARError( ret, status)) {
		FreeARFieldValueList(&fieldList, FALSE);
		goto set_entry_end;
	      }
	      if (sv_to_ARValue(ctrl, ST(a+1), dataType, 
			&fieldList.fieldValueList[i].value) < 0) {
		FreeARFieldValueList(&fieldList, FALSE);
		goto set_entry_end;
	      }
	    }
	  }
#if AR_EXPORT_VERSION >= 3
	  /* build entryList */
	  if(perl_BuildEntryList(ctrl, &entryList, entry_id) != 0){
		FreeARFieldValueList(&fieldList, FALSE);
		goto set_entry_end;
	  }

	  ret = ARSetEntry(ctrl, schema, &entryList, &fieldList, getTime, option, &status);
	  FreeAREntryIdList(&entryList, FALSE);
#else /* ARS2.x */
	  if(!entry_id || !*entry_id) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID);
		FreeARFieldValueList(&fieldList, FALSE);
		goto set_entry_end;
	  }
	  ret = ARSetEntry(ctrl, schema, entry_id, &fieldList, getTime, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret, status)) {
	    RETVAL = 1;
	  }
	  FreeARFieldValueList(&fieldList, FALSE);
	set_entry_end:;
	set_entry_exit:;
	}
	OUTPUT:
	RETVAL

SV *
ars_Export(ctrl,displayTag,vuiType,...)
	ARControlStruct *	ctrl
	char *			displayTag
	unsigned int		vuiType
	CODE:
	{
		int              ret, i, a, c = (items - 3) / 2, ok = 1;
		ARStructItemList structItems;
		char            *buf = CPNULL;
		ARStatusList     status;
#if AR_EXPORT_VERSION >= 8L
                ARWorkflowLockStruct workflowLockStruct;
#endif
	  
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		Zero(&structItems, 1, ARStructItemList);
		RETVAL = &PL_sv_undef;
		if ( (items % 2 == 0) || (c < 1) ) {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
		} else {
			structItems.numItems = c;
			AMALLOCNN(structItems.structItemList, c, ARStructItemStruct);
			for (i = 0 ; i < c ; i++) {
				unsigned int et = 0;
				a  = i * 2 + 3;
				et = caseLookUpTypeNumber((TypeMapStruct *) 
							     StructItemTypeMap,
							   SvPV(ST(a), PL_na) 
							 );
				if(et == TYPEMAP_LAST) {
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_EXP);
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
						SvPV(ST(a), PL_na) );
					ok = 0;
				} else {
					structItems.structItemList[i].type = et;
					strncpy(structItems.structItemList[i].name,
						SvPV(ST(a+1), PL_na), 
						sizeof(ARNameType) );
					structItems.structItemList[i].name[sizeof(ARNameType)-1] = '\0';
				}
			}
		}

		if(ok) {
			ret = ARExport(ctrl, &structItems, displayTag, 
#if AR_EXPORT_VERSION >= 6
				       vuiType,
#endif
#if AR_EXPORT_VERSION >= 8L
                                       &workflowLockStruct,
#endif
				       &buf, &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if (! ARError(ret, status) ) {
				RETVAL = newSVpv(buf, 0);
			}
		} 
		if(buf) free(buf);
		FreeARStructItemList(&structItems, FALSE);
	}
	OUTPUT:
	RETVAL

int
ars_Import(ctrl,importOption=AR_IMPORT_OPT_CREATE,importBuf,...)
	ARControlStruct *	ctrl
	char *			importBuf
	unsigned int            importOption
	CODE:
	{
		int               ret = 1, i, a, c = (items - 2) / 2, ok =1;
		ARStructItemList *structItems = NULL;
		ARStatusList      status;

		(void) ARError_reset();	  
		Zero(&status, 1,ARStatusList);
		RETVAL = 0;
		if ((items-3) % 2) {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
		} else {
			if (c > 0) {
				AMALLOCNN(structItems, c, ARStructItemList);
				structItems->numItems = c;
				AMALLOCNN(structItems->structItemList, c,
				     ARStructItemStruct);
				for (i = 0; i < c; i++) {
					unsigned int et = 0;
					a  = i*2+3;
					et = caseLookUpTypeNumber((TypeMapStruct *) 
								     StructItemTypeMap,
								   SvPV(ST(a), PL_na) 
								 );
					if(et == TYPEMAP_LAST) {
						(void) ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_IMP);
						(void) ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
								   SvPV(ST(a), PL_na) );
						ok = 0;
					} else {
						structItems->structItemList[i].type = et;
						strncpy(structItems->structItemList[i].name,
							SvPV(ST(a+1), PL_na), 
							sizeof(ARNameType) );
						structItems->structItemList[i].name[sizeof(ARNameType)-1] = '\0';
					}
				}
			}
		}

		if(ok) {
			ret = ARImport(ctrl, structItems, importBuf, 
#if AR_EXPORT_VERSION >= 5
				       importOption,
#endif
				       &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if (ARError(ret, status)) {
				RETVAL = 0;
			} else {
				RETVAL = 1;
			}
		} else {
			RETVAL = 1;
		}
		FreeARStructItemList(structItems, TRUE);
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
	  ARNameList   nameList;
	  ARStatusList status;
	  ARPropList   propList;
	  int          ret;
          unsigned int i;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListFilter(control,schema,changedsince,
#if AR_EXPORT_VERSION >= 8L
                               &propList,
#endif
                               &nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
	    for (i=0; i < nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    FreeARNameList(&nameList,FALSE);
	  }
	}

void
ars_GetListEscalation(control,schema=NULL,changedsince=0)
	ARControlStruct *	control
	char *			schema
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
	  ARPropList   propList;
	  int          ret;
          unsigned int i;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListEscalation(control,schema,changedsince,
#if AR_EXPORT_VERSION >= 8L
                                    &propList,
#endif
                                    &nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    FreeARNameList(&nameList,FALSE);
	  }
	}

void
ars_GetListCharMenu(control,changedsince=0)
	ARControlStruct *	control
	unsigned long		changedsince
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
          ARPropList   propList;
          ARNameList   schemaNameList;
          ARNameList   actLinkNameList;
	  int          ret;
          unsigned int i;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListCharMenu(control,changedsince,
#if AR_EXPORT_VERSION >= 8L
                                  &schemaNameList, &actLinkNameList, &propList,
#endif
                                  &nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif

	  if (!ARError( ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    FreeARNameList(&nameList,FALSE);
	  }
	}


void
ars_GetListAdminExtension(control,changedsince=0)
	ARControlStruct *	control
	unsigned long		changedsince
	PPCODE:
	{
#if !defined(ARS32) && (AR_EXPORT_VERSION < 4)
	  ARNameList   nameList;
	  ARStatusList status;
	  int          ret, i;

	  (void) ARError_reset();
	  Zero(&status,1, ARStatusList);
	  ret = ARGetListAdminExtension(control,changedsince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
	    for (i=0; i<nameList.numItems; i++)
	      XPUSHs(sv_2mortal(newSVpv(nameList.nameList[i], 0)));
	    FreeARNameList(&nameList,FALSE);
	  }
#else /* ARS32 or later */
	(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "ars_GetListAdminExtension() is not available in ARS3.2 or later.");
#endif /* ARS32 or later */
	}

int
ars_DeleteActiveLink(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList status;
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && CVLD(name)) {
		ret = ARDeleteActiveLink(ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                         0,
#endif
                                         &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif		
	        if(!ARError(ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteVUI(ctrl, schema, vuiId)
	ARControlStruct *	ctrl
	char *			schema
	ARInternalId		vuiId
	CODE:
	{
	  ARStatusList status;
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
#if AR_EXPORT_VERSION >= 3
	  if(ctrl && CVLD(schema)) {
		ret = ARDeleteVUI(ctrl, schema, vuiId, &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
#else /* 2.x */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "DeleteVUI() is only available in ARS3.x");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_DeleteAdminExtension(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
#if !defined(ARS32) && (AR_EXPORT_VERSION < 4)
	  ARStatusList status;
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && name && *name) {
		ret = ARDeleteAdminExtension(ctrl, name, &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
	        if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
#else /* ARS32 or later */
	RETVAL = 0;
	(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "ars_DeleteAdminExtension() is not available in ARS3.2 or later.");
#endif /* ARS32 */
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
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && name && *name) {
		ret = ARDeleteCharMenu(ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                       0,
#endif
                                       &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
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
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && name && *name) {
		ret = ARDeleteEscalation(ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                         0,
#endif
                                         &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
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
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && CVLD(schema) && IVLD(deleteOption, 0, 2)) {
		ret = ARDeleteField(ctrl, schema, fieldId, deleteOption, &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteFilter(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList status;
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = 0;
	  if(ctrl && name && *name) {
		ret = ARDeleteFilter(ctrl, name, 
#if AR_EXPORT_VERSION >= 8L
                                     0,
#endif
                                     &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	}
	OUTPUT:
	RETVAL

int
ars_DeleteSchema(ctrl, name, deleteOption)
	ARControlStruct *	ctrl
	char *			name
	unsigned int 		deleteOption
	CODE:
	{
	  ARStatusList status;
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  RETVAL = 0;
	  if(ctrl && CVLD(name)) {
		ret = ARDeleteSchema(ctrl, name, deleteOption, &status);
#ifdef PROFILE
	        ((ars_ctrl *)ctrl)->queries++;
#endif
		if(!ARError( ret, status))
			RETVAL = 1;
	  } else
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	}
	OUTPUT:
	RETVAL

int
ars_DeleteMultipleFields(ctrl, schema, deleteOption, ...)
	ARControlStruct	*	ctrl
	char *			schema
	unsigned int		deleteOption
	CODE:
	{
	  int              i, ret, c = (items - 3);
	  ARStatusList     status;
	  ARInternalIdList fieldList;

	  RETVAL = 0; /* assume error */
	  Zero(&status, 1,ARStatusList);
	  (void) ARError_reset();
#if AR_EXPORT_VERSION >= 3
	  if(items < 4)
	     (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  else {
	     /* slurp in each fieldId and put it in a list */
	     fieldList.numItems = c;
	     fieldList.internalIdList = MALLOCNN(sizeof(ARInternalId) * c);
	     for(i = 0; i < c; i++) {
		fieldList.internalIdList[i] = SvIV(ST(i + 3));
	     }
	     ret = ARDeleteMultipleFields(ctrl, schema, &fieldList, deleteOption, &status);
#ifdef PROFILE
	     ((ars_ctrl *)ctrl)->queries++;
#endif
	     if(!ARError( ret, status))
		RETVAL = 1;
	     FreeARInternalIdList(&fieldList, FALSE);
	  }
#else /* 2.x */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in 2.x");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_ExecuteAdminExtension(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
#if !defined(ARS32) && (AR_EXPORT_VERSION < 4)
	 ARStatusList status;
	 int          ret;

	 RETVAL = 0;
	 Zero(&status, 1,ARStatusList);
	 (void) ARError_reset();
	 if(ctrl && CVLD(name))
		ret = ARExecuteAdminExtension(ctrl, name, &status);
#ifdef PROFILE
	 ((ars_ctrl *)ctrl)->queries++;
#endif
	 if(!ARError( ret, status))
		RETVAL = 1;
#else /* ARS32 or later */
	RETVAL = 0;
	(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "ars_ExecuteAdminExtension() is not available in ARS3.2 or later.");
#endif /* ARS32 */
	}
	OUTPUT:
	RETVAL

void
ars_ExecuteProcess(ctrl, command, runOption=0)
	ARControlStruct *	ctrl
	char *			command
	int			runOption
	PPCODE:
	{
	 ARStatusList status;
	 int          returnStatus;
	 char        *returnString;
	 int          ret = 0;

	 (void) ARError_reset();
	 Zero(&status, 1,ARStatusList);
#if AR_EXPORT_VERSION >= 3
	 if(ctrl && CVLD(command)) {
		if(runOption == 0)
			ret = ARExecuteProcess(ctrl, command, &returnStatus, &returnString, &status);
		else
			ret = ARExecuteProcess(ctrl, command, NULL, NULL, &status);
	 }
#ifdef PROFILE
	 ((ars_ctrl *)ctrl)->queries++;
#endif
	 /* if all went well, and user requested synchronous processing 
	  * then we push the returnStatus and returnString back out to them.
	  * if they requested async, then we just push a 1 to indicate that the
	  * command to the API was successfully handled (and foo || die constructs
	  * will work correctly).
	  */
	 if(!ARError( ret, status)) {
		if(runOption == 0) {
			XPUSHs(sv_2mortal(newSViv(returnStatus)));
			XPUSHs(sv_2mortal(newSVpv(returnString, 0)));
			if(returnString) AP_FREE(returnString);
		} else {
			XPUSHs(sv_2mortal(newSViv(1)));
		}
	 }
#else /* 2.x */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in 2.x");
#endif
	}

HV *
ars_GetAdminExtension(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
#if !defined(ARS32) && (AR_EXPORT_VERSION < 4)
	 ARStatusList  status;
	 ARInternalIdList groupList;
	 char          command[AR_MAX_COMMAND_SIZE];
	 char         *helpText = CPNULL;
	 ARTimestamp   timestamp;
	 ARNameType    owner;
	 ARNameType    lastChanged;
	 char         *changeDiary = CPNULL;
	 int           ret;
	 ARDiaryList      diaryList;

	 (void) ARError_reset();
	 Zero(&status, 1,ARStatusList);
	 RETVAL = newHV();
	 ret = ARGetAdminExtension(ctrl, name, &groupList, command, &helpText, &timestamp, owner, lastChanged, &changeDiary, &status);
#ifdef PROFILE
	 ((ars_ctrl *)ctrl)->queries++;
#endif
	 if(!ARError( ret, status)) {
	  	hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
		hv_store(RETVAL,  "groupList", strlen("groupList") ,
			perl_ARList(ctrl,
				    (ARList *)&groupList, 
				    (ARS_fn)perl_ARInternalId,
				    sizeof(ARInternalId)), 0);
		hv_store(RETVAL,  "command", strlen("command")   , newSVpv(command, 0), 0);
		hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
		hv_store(RETVAL,  "owner", strlen("owner")     , newSVpv(owner, 0), 0);
		hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	        if(helpText)
		   hv_store(RETVAL,  "helpText", strlen("helpText")  , newSVpv(helpText, 0), 0);
	        if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
			ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
			ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
			if (!ARError(ret, status)) {
				hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
					perl_ARList(ctrl, (ARList *)&diaryList,
					(ARS_fn)perl_diary,
					sizeof(ARDiaryStruct)), 0);
				FreeARDiaryList(&diaryList, FALSE);
			}
	        }
		FreeARInternalIdList(&groupList, FALSE);
		if(helpText) {
		  	AP_FREE(helpText);
		}
		if(changeDiary) {
		  	AP_FREE(changeDiary);
		}
	 }
#else /* ARS32 or later */
	 RETVAL = 0;
	 (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "ars_GetAdminExtension() is not available in ARS3.2 or later.");
#endif /* ARS32 */
	}
	OUTPUT:
	RETVAL

HV *
ars_GetEscalation(ctrl, name)
	ARControlStruct *	ctrl
	char *			name
	CODE:
	{
	  ARStatusList         status;
	  AREscalationTmStruct escalationTm;
#if AR_EXPORT_VERSION < 5
	  ARNameType           schema;
#endif
	  unsigned int         enable;
	  ARFilterActionList   actionList;
#if AR_EXPORT_VERSION >= 3
	  ARFilterActionList   elseList;
#endif
	  char                *helpText = CPNULL;
	  ARTimestamp          timestamp;
	  ARNameType           owner;
	  ARNameType           lastChanged;
          char                *changeDiary = CPNULL;
	  SV                  *ref;
	  int                  ret;
	  ARQualifierStruct   *query = MALLOCNN(sizeof(ARQualifierStruct));
	  ARDiaryList          diaryList;
#if AR_EXPORT_VERSION >= 5
	  ARWorkflowConnectStruct schemaList;
	  ARPropList              objPropList;
#endif

	  RETVAL = newHV();
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&actionList, 1,ARFilterActionList);
#if AR_EXPORT_VERSION >= 5
	  Zero(&elseList, 1,ARFilterActionList);
	  Zero(&schemaList, 1, ARWorkflowConnectStruct);
	  ret = ARGetEscalation(ctrl, name, &escalationTm, &schemaList, &enable,
			query, &actionList, &elseList, &helpText, &timestamp,
			owner, lastChanged, &changeDiary, &objPropList, &status);
#elif AR_EXPORT_VERSION >= 3
	  Zero(&elseList, 1,ARFilterActionList);
	  ret = ARGetEscalation(ctrl, name, &escalationTm, schema, &enable,
			query, &actionList, &elseList, &helpText, &timestamp,
			owner, lastChanged, &changeDiary, &status);
#else
	  ret = ARGetEscalation(ctrl, name, &escalationTm, schema, &enable,
			query, &actionList,            &helpText, &timestamp,
			owner, lastChanged, &changeDiary, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	     hv_store(RETVAL,  "name", strlen("name") , newSVpv(name, 0), 0);
#if AR_EXPORT_VERSION >= 5
		hv_store(RETVAL,  "schemaList", strlen("schemaList") , /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL,  "objPropList", strlen("objPropList") ,
			perl_ARPropList(ctrl, &objPropList), 0);
#else
	     hv_store(RETVAL,  "schema", strlen("schema") , newSVpv(schema, 0), 0);
#endif
	     hv_store(RETVAL,  "enable", strlen("enable") , newSViv(enable), 0);
	     hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	     if(helpText)
	        hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	     hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	     hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	     if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl, 
				(ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	     }
	     ref = newSViv(0);
	     sv_setref_pv(ref, "ARQualifierStructPtr", (void *)query);
	     hv_store(RETVAL,  "query", strlen("query") , ref, 0);
	     hv_store(RETVAL,  "actionList", strlen("actionList") ,
			perl_ARList(ctrl,
				(ARList *)&actionList,
				(ARS_fn)perl_ARFilterActionStruct,
				sizeof(ARFilterActionStruct)), 0);
#if AR_EXPORT_VERSION >= 3
	     hv_store(RETVAL,  "elseList", strlen("elseList") , 
			perl_ARList( ctrl,
				(ARList *)&elseList,
				(ARS_fn)perl_ARFilterActionStruct,
				sizeof(ARFilterActionStruct)), 0);
#endif
	     hv_store(RETVAL,  "TmType", strlen("TmType") , 
			newSViv(escalationTm.escalationTmType), 0);
	     switch(escalationTm.escalationTmType) {
	     case AR_ESCALATION_TYPE_INTERVAL:
		hv_store(RETVAL,  "TmInterval", strlen("TmInterval") , 
			newSViv(escalationTm.u.interval), 0);
		break;
	     case AR_ESCALATION_TYPE_TIMEMARK:
		hv_store(RETVAL,  "TmMonthDayMask", strlen("TmMonthDayMask") ,
			newSViv(escalationTm.u.date.monthday), 0);
		hv_store(RETVAL,  "TmWeekDayMask", strlen("TmWeekDayMask") ,
			newSViv(escalationTm.u.date.weekday), 0);
		hv_store(RETVAL,  "TmHourMask", strlen("TmHourMask") ,
			newSViv(escalationTm.u.date.hourmask), 0);
		hv_store(RETVAL,  "TmMinute", strlen("TmMinute") ,
			newSViv(escalationTm.u.date.minute), 0);
		break;
	     }
	     FreeARFilterActionList(&actionList, FALSE);
#if AR_EXPORT_VERSION >= 3
	     FreeARFilterActionList(&elseList, FALSE);
#endif
#if AR_EXPORT_VERSION >= 5
	     FreeARWorkflowConnectStruct(&schemaList, FALSE);
	     FreeARPropList(&objPropList, FALSE);
#endif
	     if(helpText) {
	       	AP_FREE(helpText);
	     }
	     if(changeDiary) {
	       	AP_FREE(changeDiary);
	     }
	  }
	}
	OUTPUT:
	RETVAL

HV *
ars_GetFullTextInfo(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  ARFullTextInfoRequestList requestList;
	  ARFullTextInfoList        fullTextInfo;
	  ARStatusList              status;
	  int                       ret;
	  unsigned int rlist[] = {AR_FULLTEXTINFO_COLLECTION_DIR,
			 	  AR_FULLTEXTINFO_STOPWORD,
				  AR_FULLTEXTINFO_CASE_SENSITIVE_SRCH,
			 	  AR_FULLTEXTINFO_STATE,
			 	  AR_FULLTEXTINFO_FTS_MATCH_OP };

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = newHV();
	  requestList.numItems = 5;
	  requestList.requestList = rlist;
	  ret = ARGetFullTextInfo(ctrl, &requestList, &fullTextInfo, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
             unsigned int i, v;
	     AV *a = newAV();

	     for(i = 0; i < fullTextInfo.numItems ; i++) {
	        switch(fullTextInfo.fullTextInfoList[i].infoType) {
		case AR_FULLTEXTINFO_STOPWORD:
		   for(v = 0; v < fullTextInfo.fullTextInfoList[i].u.valueList.numItems ; v++) {
		      av_push(a, perl_ARValueStruct(ctrl,
			&(fullTextInfo.fullTextInfoList[i].u.valueList.valueList[v])));
		   }
		   hv_store(RETVAL,  "StopWords", strlen("StopWords") , newRV_noinc((SV *)a), 0);
		   break;
		case AR_FULLTEXTINFO_CASE_SENSITIVE_SRCH:
		   hv_store(RETVAL,  "CaseSensitive", strlen("CaseSensitive") ,
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_COLLECTION_DIR:
		   hv_store(RETVAL,  "CollectionDir", strlen("CollectionDir") ,
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_FTS_MATCH_OP:
		   hv_store(RETVAL,  "MatchOp", strlen("MatchOp") ,
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_STATE:
		   hv_store(RETVAL,  "State", strlen("State") ,
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		}
	     }
             FreeARFullTextInfoList(&fullTextInfo, FALSE);
	  }
	}
	OUTPUT:
	RETVAL

HV *
ars_GetListGroup(ctrl, userName=NULL,password=NULL)
	ARControlStruct *	ctrl
	char *			userName
	char *			password
	CODE:
	{
	  ARStatusList    status;
	  ARGroupInfoList groupList;
	  int             ret;
          unsigned int    i, v;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = newHV();
	  ret = ARGetListGroup(ctrl, userName, 
#if AR_EXPORT_VERSION >= 6
			       password,
#endif
			       &groupList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	    AV *gidList = newAV(), *gtypeList = newAV(), 
	       *gnameListList = newAV(), *gnameList;

	    for(i = 0; i < groupList.numItems; i++) {
		av_push(gidList, newSViv(groupList.groupList[i].groupId));
		av_push(gtypeList, newSViv(groupList.groupList[i].groupType));
		gnameList = newAV();
		for(v = 0; v < groupList.groupList[i].groupName.numItems ; v++) {
		   av_push(gnameList, newSVpv(groupList.groupList[i].groupName.nameList[v], 0));
		}
		av_push(gnameListList, newRV_noinc((SV *)gnameList));
	    }

	    hv_store(RETVAL,  "groupId", strlen("groupId") , newRV_noinc((SV *)gidList), 0);
	    hv_store(RETVAL,  "groupType", strlen("groupType") , newRV_noinc((SV *)gtypeList), 0);
	    hv_store(RETVAL,  "groupName", strlen("groupName") , newRV_noinc((SV *)gnameListList), 0);
	 
	    FreeARGroupInfoList(&groupList, FALSE);
	  }
	}
	OUTPUT:
	RETVAL

HV *
ars_GetListSQL(ctrl, sqlCommand, maxRetrieve=AR_NO_MAX_LIST_RETRIEVE)
	ARControlStruct *	ctrl
	char *			sqlCommand
	unsigned int		maxRetrieve
	PPCODE:
	{
	  ARStatusList    status;
	  ARValueListList valueListList;
	  unsigned int    numMatches;
	  int             ret;

	  (void) ARError_reset();
	  RETVAL = NULL;
	  Zero(&status, 1, ARStatusList);
#ifndef ARS20
	  ret = ARGetListSQL(ctrl, sqlCommand, maxRetrieve, &valueListList, 
			     &numMatches, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	     unsigned int  row, col;
	     AV  *ra = newAV(), *ca;
	     RETVAL = newHV();

	     hv_store(RETVAL,  "numMatches", strlen("numMatches") , newSViv(numMatches), 0);
	     for(row = 0; row < valueListList.numItems ; row++) {
		ca = newAV();
		for(col = 0; col < valueListList.valueListList[row].numItems;
		    col++) 
		{
		   av_push(ca, perl_ARValueStruct(ctrl,
			&(valueListList.valueListList[row].valueList[col])));
		}
		av_push(ra, newRV_noinc((SV *)ca));
	     }
	     hv_store(RETVAL,  "rows", strlen("rows") , newRV_noinc((SV *)ra), 0);
	     FreeARValueListList(&valueListList, FALSE);
	  }
#else
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in pre-2.1 ARS");
#endif
	  if(RETVAL != NULL) {
			XPUSHs(sv_2mortal(newRV_noinc((SV *)RETVAL)));
	  } else {
			XPUSHs(sv_2mortal(newSViv(0)));
	  }
	}

void
ars_GetListUser(ctrl, userListType=AR_USER_LIST_MYSELF,changedSince=0)
	ARControlStruct *	ctrl
	unsigned int		userListType
	ARTimestamp		changedSince
	PPCODE:
	{
	  ARStatusList   status;
	  ARUserInfoList userList;
	  int            ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListUser(ctrl, userListType, 
#if AR_EXPORT_VERSION >= 6
				changedSince,
#endif
				&userList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	     unsigned int i, j;
	     for(i = 0; i < userList.numItems; i++) {
	        HV *userInfo           = newHV();
		AV *licenseTag         = newAV(),
		   *licenseType        = newAV(),
		   *currentLicenseType = newAV();

	        hv_store(userInfo,  "userName", strlen("userName") , 
			newSVpv(userList.userList[i].userName, 0), 0);
		hv_store(userInfo,  "connectTime", strlen("connectTime") ,
			newSViv(userList.userList[i].connectTime), 0);
		hv_store(userInfo,  "lastAccess", strlen("lastAccess") ,
			newSViv(userList.userList[i].lastAccess), 0);
		hv_store(userInfo,  "defaultNotifyMech", strlen("defaultNotifyMech") ,
			newSViv(userList.userList[i].defaultNotifyMech), 0);
		hv_store(userInfo,  "emailAddr", strlen("emailAddr") ,
			newSVpv(userList.userList[i].emailAddr, 0), 0);

		for(j = 0; j < userList.userList[i].licenseInfo.numItems; j++) {
		   av_push(licenseTag, newSViv(userList.userList[i].licenseInfo.licenseList[j].licenseTag));
		   av_push(licenseType, newSViv(userList.userList[i].licenseInfo.licenseList[j].licenseType));
		   av_push(currentLicenseType, newSViv(userList.userList[i].licenseInfo.licenseList[j].currentLicenseType));
		}
		hv_store(userInfo,  "licenseTag", strlen("licenseTag") , newRV_noinc((SV *)licenseTag), 0);
		hv_store(userInfo,  "licenseType", strlen("licenseType") , newRV_noinc((SV *)licenseType), 0);
		hv_store(userInfo,  "currentLicenseType", strlen("currentLicenseType") , newRV_noinc((SV *)currentLicenseType), 0);
	        XPUSHs(sv_2mortal(newRV_noinc((SV *)userInfo)));
	     }
	     FreeARUserInfoList(&userList, FALSE);
	  }
	}

void
ars_GetListVUI(ctrl, schema, changedSince=0)
	ARControlStruct *	ctrl
	char *			schema
	unsigned int		changedSince
	PPCODE:
	{
#if AR_EXPORT_VERSION >= 3
	  ARStatusList     status;
	  ARInternalIdList idList;
	  int              ret;
          unsigned int     i;

	  ret = ARGetListVUI(ctrl, schema, changedSince, &idList, &status);
	  Zero(&status, 1,ARStatusList);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	    for(i = 0 ; i < idList.numItems ; i++) {
		XPUSHs(sv_2mortal(newSViv(idList.internalIdList[i])));
	    }
	  }
	  FreeARInternalIdList(&idList, FALSE);
#else /* ars 2.x */
	  (void) ARError_reset();
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in 2.x");
#endif
	}

void
ars_SetServerInfo(ctrl, ...)
	ARControlStruct *	ctrl
	PPCODE:
	{
		ARStatusList     status;
		ARServerInfoList serverInfo;
		int		 ret, i, count = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		Zero(&serverInfo, 1, ARServerInfoList);

		if((items == 1) || ((items % 2) == 0)) { 
			(void) ARError_add(AR_RETURN_ERROR, 
					   AP_ERR_BAD_ARGS);
		} else {
			unsigned int infoType;
			char         buf[64];

			serverInfo.numItems = (items - 1) / 2;
			serverInfo.serverInfoList = MALLOCNN(serverInfo.numItems * sizeof(ARServerInfoStruct));
			Zero(serverInfo.serverInfoList, 1, ARServerInfoStruct);

			for(i = 1 ; i < items ; i += 2) {
				/*printf("[%d] ", i);
				printf("k=%d v=%s\n",
					SvIV(ST(i)),
					SvPV(ST(i+1), PL_na)
				);*/
				infoType = lookUpServerInfoTypeHint(SvIV(ST(i)));
				serverInfo.serverInfoList[i-1].operation = SvIV(ST(i));
				serverInfo.serverInfoList[i-1].value.dataType = infoType;

				switch(infoType) {
				case AR_DATA_TYPE_CHAR:
					serverInfo.serverInfoList[i-1].value.u.charVal = strdup(SvPV(ST(i+1), PL_na));
					break;
				case AR_DATA_TYPE_INTEGER:
					serverInfo.serverInfoList[i-1].value.u.intVal = SvIV(ST(i+1));
					break;
				default:
					(void) ARError_add(AR_RETURN_ERROR, AP_ERR_INV_ARGS, 
						buf);
					FreeARServerInfoList(&serverInfo, FALSE);
					XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
					goto SetServerInfo_fail;
				}
			}
			ret = ARSetServerInfo(ctrl, &serverInfo, &status);
			FreeARServerInfoList(&serverInfo, FALSE);
			if(ARError(ret, status)) {
				XPUSHs(sv_2mortal(newSViv(0))); /* ERR */
			} else {
				XPUSHs(sv_2mortal(newSViv(1))); /* OK */
			}
		}
	SetServerInfo_fail:;
	}

void
ars_GetServerInfo(ctrl, ...)
	ARControlStruct *	ctrl
	PPCODE:
	{
	  ARStatusList            status;
	  ARServerInfoRequestList requestList;
	  ARServerInfoList        serverInfo;
	  int                     ret;
          int                     i;
          unsigned int            ui, count;
	  unsigned int            rlist[AR_MAX_SERVER_INFO_USED];

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  count = 0;
	  if(items == 1) { /* none specified.. fetch all */
	     for(i = 0; i < AR_MAX_SERVER_INFO_USED ; i++) {
	        /* we'll exclude ones that can't be retrieved to avoid errors */
	        switch(i+1) {
	        case AR_SERVER_INFO_DB_PASSWORD:
		   break;
	        default:
	           rlist[count++] = i+1;
	        }
             }
	  } 
	  else if(items > AR_MAX_SERVER_INFO_USED + 1) {
	    ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  }
	  else { /* user has asked for specific ones */
	     for(i = 1 ; i < items ; i++) {
		rlist[count++] = SvIV(ST(i));
	     }
	  }
	  if(count > 0) {
	     requestList.numItems = count;
	     requestList.requestList = rlist;
	     ret = ARGetServerInfo(ctrl, &requestList, &serverInfo, &status);
#ifdef PROFILE
	     ((ars_ctrl *)ctrl)->queries++;
#endif
	     if(!ARError( ret, status)) {
	        for(ui = 0 ; ui < serverInfo.numItems ; ui++) {
		/* provided we have a mapping for the operation code, 
		 * push out it's translation. else push out the code itself
		 */
		   if(serverInfo.serverInfoList[ui].operation <= AR_MAX_SERVER_INFO_USED) {
	  	      XPUSHs(sv_2mortal(newSVpv(ServerInfoMap[serverInfo.serverInfoList[ui].operation].name, 0)));
		   } else {
		      XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[ui].operation)));
		   }
		      XPUSHs(sv_2mortal(perl_ARValueStruct(ctrl,
			&(serverInfo.serverInfoList[ui].value))));
	        }
	     }
	    FreeARServerInfoList(&serverInfo, FALSE);
	  }
	}

HV *
ars_GetVUI(ctrl, schema, vuiId)
	ARControlStruct *	ctrl
	char *			schema
	ARInternalId		vuiId
	CODE:
	{
#if AR_EXPORT_VERSION >= 3
	  ARStatusList status;
	  ARNameType   vuiName;
	  ARPropList   dPropList;
	  char        *helpText = CPNULL;
	  ARTimestamp  timestamp;
	  ARNameType   owner;
	  ARNameType   lastChanged;
	  char        *changeDiary = CPNULL;
	  int          ret;
	  ARDiaryList      diaryList;
# if AR_EXPORT_VERSION >= 6
	  unsigned int vuiType = 0;
	  ARLocaleType locale;
	  Zero(locale, 1, ARLocaleType);
# endif
	  RETVAL = newHV();
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetVUI(ctrl, schema, vuiId, vuiName,
# if AR_EXPORT_VERSION >= 6
			 locale, &vuiType,
# endif
			 &dPropList, &helpText, 
			 &timestamp, owner, lastChanged, &changeDiary, &status);
# ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
# endif
	  if(!ARError( ret, status)) {
# if AR_EXPORT_VERSION >= 6
	     hv_store(RETVAL, "locale", strlen("locale"), newSVpv(locale, 0), 0);
	     hv_store(RETVAL, "vuiType", strlen("vuiType"), newSViv(vuiType), 0);
# endif
	     hv_store(RETVAL,  "schema", strlen("schema") , newSVpv(schema, 0), 0);
	     hv_store(RETVAL,  "vuiId", strlen("vuiId") , newSViv(vuiId), 0);
	     hv_store(RETVAL,  "vuiName", strlen("vuiName") , newSVpv(vuiName, 0), 0);
	     hv_store(RETVAL,  "owner", strlen("owner") , newSVpv(owner, 0), 0);
	     if(helpText)
	        hv_store(RETVAL,  "helpText", strlen("helpText") , newSVpv(helpText, 0), 0);
	     hv_store(RETVAL,  "lastChanged", strlen("lastChanged") , newSVpv(lastChanged, 0), 0);
	     if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL,  "changeDiary", strlen("changeDiary") ,
				perl_ARList(ctrl,
				(ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	     }
	     hv_store(RETVAL,  "timestamp", strlen("timestamp") , newSViv(timestamp), 0);
	     hv_store(RETVAL,  "props", strlen("props") ,
		perl_ARList( ctrl,
			    (ARList *)&dPropList,
			    (ARS_fn)perl_ARPropStruct,
			    sizeof(ARPropStruct)), 0);
	  }
	  FreeARPropList(&dPropList, FALSE);
	  if(helpText) {
	    	AP_FREE(helpText);
	  }
	  if(changeDiary) {
	    	AP_FREE(changeDiary);
	  }
#else /* ars 2.x */
	  (void) ARError_reset();
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in 2.x");
	  RETVAL = newHV();
#endif

	}
	OUTPUT:
	RETVAL

int
ars_CreateCharMenu(ctrl, cmDefRef)
	ARControlStruct *	ctrl
	SV *			cmDefRef
	CODE:
	{
	  ARNameType        name;
	  ARCharMenuStruct  menuDefn;
	  char             *helptext = CPNULL;
	  ARNameType        owner;
	  char             *changeDiary = CPNULL;
	  ARStatusList      status;

	  (void) ARError_reset();
	  RETVAL = 0;
	  Zero(&status, 1, ARStatusList);
	  Zero(&menuDefn, 1, ARCharMenuStruct);
	  Zero(&owner, 1, ARNameType);
	  Zero(&name, 1, ARNameType);

	  if(SvTYPE((SV *)SvRV(cmDefRef)) != SVt_PVHV) {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
		printf("ars_CreateCharMenu: not implemented");
	  } else {
		HV *cmDef = (HV *)SvRV(cmDefRef);
		printf("ars_CreateCharMenu: not implemented");
	  }
	}
	OUTPUT:
	RETVAL

int 
ars_CreateAdminExtension(ctrl, aeDefRef)
	ARControlStruct *	ctrl
	SV *			aeDefRef
	CODE:
	{
#if !defined(ARS32) && (AR_EXPORT_VERSION < 4)
	  int               rv = 0, ret = 0;
	  ARNameType        name, owner;
	  ARInternalIdList  groupList;
	  char             *command     = CPNULL, 
			   *helpText    = CPNULL, 
			   *changeDiary = CPNULL;
	  ARStatusList      status;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  Zero(&groupList, 1, ARInternalIdList);
	  Zero(&name, 1, ARNameType);
	  Zero(&owner, 1, ARNameType);
	  RETVAL = 0;

	  if(SvTYPE((SV *)SvRV(aeDefRef)) != SVt_PVHV) {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *aeDef = (HV *)SvRV(aeDefRef);
		if(hv_exists(aeDef,  "name", strlen("name") ) &&
		   hv_exists(aeDef,  "groupList", strlen("groupList") ) &&
		   hv_exists(aeDef,  "command", strlen("command") )) {

		   rv += strcpyHVal( aeDef, "name", name, sizeof(ARNameType));
		   rv += strmakHVal( aeDef, "command", &command);
		   if(hv_exists(aeDef,  "helpText", strlen("helpText") )) 
			rv += strmakHVal( aeDef, "helpText", &helpText);
		   if(hv_exists(aeDef,  "changeDiary", strlen("changeDiary") )) 
			rv += strmakHVal( aeDef, "changeDiary", &changeDiary);
		   if(hv_exists(aeDef,  "owner", strlen("owner") )) 
			rv += strcpyHVal( aeDef, "owner", owner, 
					sizeof(ARNameType));
		   else
			strncpy(owner, ctrl->user, sizeof(ARNameType));

		   rv += rev_ARInternalIdList(ctrl, aeDef, "groupList", &groupList);

		   if(rv == 0) {
			ret = ARCreateAdminExtension(ctrl, name, &groupList,
					command, helpText, owner, changeDiary,
					&status);
			if(!ARError( ret, status)) RETVAL = 1;
		   } else
			ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
		} else {
		   ARError_add( AR_RETURN_ERROR, AP_ERR_NEEDKEYS);
		   ARError_add( AR_RETURN_ERROR, AP_ERR_NEEDKEYSKEYS,
			"name, groupList, command");
		}
	  }
#else /* ARS32 or later */
	  RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "ars_CreateAdminExtension() is not available in ARS3.2 or later.");
#endif /* ARS32 */

	}
	OUTPUT:
	RETVAL

int
ars_CreateActiveLink(ctrl, alDefRef)
	ARControlStruct *	ctrl
	SV *			alDefRef
	CODE:
	{
	  int                    ret = 0, rv = 0;
	  ARNameType             schema, name;
	  ARInternalIdList       groupList;
	  unsigned int           executeMask, order;
#if AR_EXPORT_VERSION >= 3
	  ARInternalId           controlField = 0;
	  ARInternalId           focusField = 0;
#else /* 2.x */
	  ARInternalId           field = 0;
	  ARDisplayList          displayList;
#endif
	  unsigned int           enable = 0;
	  ARQualifierStruct     *query;
	  ARActiveLinkActionList actionList;
#if AR_EXPORT_VERSION >= 3
	  ARActiveLinkActionList elseList;
#endif
	  char                  *helpText = CPNULL;
	  ARNameType             owner;
	  char                  *changeDiary = CPNULL;
	  ARStatusList           status;
#if AR_EXPORT_VERSION >= 5
	  ARWorkflowConnectStruct schemaList;
	  ARPropList              objPropList;
#endif
	  
	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  Zero(&groupList, 1,ARInternalIdList);
	  Zero(&actionList, 1,ARActiveLinkActionList);
#if AR_EXPORT_VERSION >= 3
	  Zero(&elseList, 1,ARActiveLinkActionList);
#else
	  Zero(&displayList, 1,ARDisplayList);
#endif
#if AR_EXPORT_VERSION >= 5
	  Zero(&objPropList, 1, ARPropList);
	  Zero(&schemaList, 1, ARWorkflowConnectStruct);
#endif
	  if(SvTYPE((SV *)SvRV(alDefRef)) != SVt_PVHV) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_EXPECT_PVHV);
	  } else {
		HV *alDef = (HV *)SvRV(alDefRef);
		SV **qhv = hv_fetch(alDef,  "query", strlen("query") , 0);

		/* dereference the qual pointer */

		if(qhv && *qhv && SvROK(*qhv)) {
			query = (ARQualifierStruct *)SvIV((SV *)SvRV(*qhv));
		} else {
			query = (ARQualifierStruct *)NULL;
		}
		/* copy the various hash entries into the appropriate
		 * data structure. if any are missing, we fail.
		 */

		rv  = 0;
		rv += strcpyHVal( alDef, "name", name, sizeof(ARNameType));
		rv += strcpyHVal( alDef, "schema", schema, sizeof(ARNameType));
		rv += uintcpyHVal( alDef, "order", &order);
		rv += rev_ARInternalIdList(ctrl, alDef, "groupList", &groupList);
		rv += uintcpyHVal( alDef, "executeMask", &executeMask);
		rv += uintcpyHVal( alDef, "enable", &enable);

		if(hv_exists(alDef,  "owner", strlen("owner") ))
			rv += strcpyHVal( alDef, "owner", owner, 
					sizeof(ARNameType));
		else
			strncpy(owner, ctrl->user, sizeof(ARNameType));

		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(alDef,  "changeDiary", strlen("changeDiary") ))
			rv += strmakHVal( alDef, "changeDiary", &changeDiary);
		if(hv_exists(alDef,  "helpText", strlen("helpText") ))
			rv += strmakHVal( alDef, "helpText", &helpText);

		/* now handle the action & else (3.x) lists */

		rv += rev_ARActiveLinkActionList(ctrl, alDef, "actionList", 
						&actionList);
#if AR_EXPORT_VERSION >= 5
		if(hv_exists(alDef,  "objPropList", strlen("objPropList") ))
			rv += rev_ARPropList(ctrl, alDef, "objPropList",
					     &objPropList);
#endif
#if AR_EXPORT_VERSION >= 3
		rv += rev_ARActiveLinkActionList(ctrl, alDef, "elseList", 
						&elseList);
		if((executeMask & AR_EXECUTE_ON_RETURN) || 
		   (executeMask & AR_EXECUTE_ON_MENU_CHOICE))
			rv += ulongcpyHVal( alDef, "focusField", 
					&focusField);
		if(executeMask & AR_EXECUTE_ON_BUTTON) 
			rv += ulongcpyHVal( alDef, "controlField",
					&controlField);
#else /* 2.x */
		if((executeMask & AR_EXECUTE_ON_RETURN) || 
		   (executeMask & AR_EXECUTE_ON_MENU_CHOICE))
			rv += ulongcpyHVal( alDef, "field", &field);
		if(executeMask & AR_EXECUTE_ON_BUTTON)
			rv += rev_ARDisplayList(ctrl,  alDef, "displayList", 
					&displayList);
#endif
		/* at this point all datastructures (hopefully) are 
		 * built. we can call the api routine to create the
		 * active link.
		 */
		if(rv == 0) {
#if AR_EXPORT_VERSION >= 5
		   ret = ARCreateActiveLink(ctrl, name, order, &schemaList, 
					    &groupList, executeMask,
					    &controlField, &focusField, 
					    enable, query,
					    &actionList, &elseList, 
					    helpText, owner, changeDiary, 
					    &objPropList, &status);
#elif AR_EXPORT_VERSION >= 3
		   ret = ARCreateActiveLink(ctrl, name, order, schema, 
					    &groupList, executeMask,
					    &controlField, &focusField, 
					    enable, query,
					    &actionList, &elseList, 
					    helpText, owner, changeDiary, &status);
#else /* 2.x */
#endif
		   if(!ARError( ret, status))
			   RETVAL = 1;
		} else 
		   ARError_add( AR_RETURN_ERROR, AP_ERR_PREREVFAIL);
	  }
	  if (helpText) {
	    	AP_FREE(helpText);
	  }
	  if (changeDiary) {
	    	AP_FREE(changeDiary);
	  }
	  FreeARInternalIdList(&groupList, FALSE);
	  FreeARActiveLinkActionList(&actionList, FALSE);
#if AR_EXPORT_VERSION >= 3
	  FreeARActiveLinkActionList(&elseList, FALSE);
#else /* 2.x */
	  FreeARDisplayList(&displayList, FALSE);
#endif
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
	  int              a, i, c = (items - 3) / 2;
	  ARFieldValueList fieldList;
	  ARStatusList     status;
	  int              ret;
	  unsigned int     dataType;
	  AREntryIdType    entryId;

	  (void) ARError_reset();
	  Zero(&status,    1, ARStatusList);
	  Zero(&fieldList, 1, ARFieldValueList);
	  RETVAL = "";

	  if ((items - 3) % 2 || c < 1) {
	  	(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  	goto merge_entry_exit;
	  }

	  fieldList.numItems = c;
	  AMALLOCNN(fieldList.fieldValueList, c, ARFieldValueStruct);

	  for (i = 0; i < c; i++) {
	  	a = i*2 + 3;
	  	fieldList.fieldValueList[i].fieldId = SvIV(ST(a));
	  	if (! SvOK(ST(a+1))) {
	  		/* pass a NULL */
	  		fieldList.fieldValueList[i].value.dataType = 
				AR_DATA_TYPE_NULL;
	  	} else {
#if AR_EXPORT_VERSION >= 3
	  		ret = ARGetFieldCached(ctrl, schema, 
				fieldList.fieldValueList[i].fieldId, 
				NULL, NULL, &dataType, NULL, NULL, NULL, NULL, 
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, &status);
#else
	  		ret = ARGetFieldCached(ctrl, schema, 
				fieldList.fieldValueList[i].fieldId, &dataType,
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
				NULL, NULL, NULL, &status);
#endif
	  		if (ARError( ret, status)) {
				DBG( ("GetFieldCached failed %d\n", ret) );
				goto merge_entry_end;
	   		}
	   		if (sv_to_ARValue(ctrl, ST(a+1), dataType, 
				&fieldList.fieldValueList[i].value) < 0) {
				DBG( ("failed to convert to ARValue struct stack %d\n", a+1) );
				goto merge_entry_end;
	  		}
	  	}
	  }

	  ret = ARMergeEntry(ctrl, schema, &fieldList, mergeType, entryId, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif	  
	  if (! ARError( ret, status)) {
		DBG( ("MergeEntry returned %d\n", ret) );
		DBG( ("entryId %s\n", SAFEPRT(entryId)) );
	  	RETVAL = entryId;
	  }

	merge_entry_end:;
	FreeARFieldValueList(&fieldList, FALSE);
	merge_entry_exit:;
	}
	OUTPUT:
	RETVAL

void
ars_GetMultipleEntries(ctrl,schema,...)
	ARControlStruct *       ctrl
	char *                  schema
	PPCODE:
	{
#if AR_EXPORT_VERSION >= 4
	int               ret;
        unsigned int      c = items - 3, i;
	AREntryIdListList entryList;
	ARInternalIdList  idList;
	ARFieldValueListList  fieldList;
	ARBooleanList     existList;
	ARStatusList      status;
	AV               *entryList_array;

	entryList.entryIdList = NULL;
	idList.internalIdList = NULL;
	fieldList.valueListList = NULL;
	existList.booleanList = NULL;
	(void) ARError_reset();
	Zero(&status, 1, ARStatusList);
	/*
	 * build list of field Id's
	 */
	if (c < 1) {
		idList.numItems = 0; /* get all fields */
	} else {
		idList.numItems = c;
		idList.internalIdList = MALLOCNN(sizeof(ARInternalId) * c);
		for (i=0; i<c; i++)
			idList.internalIdList[i] = SvIV(ST(i+3));
	}
	/*
	 * build list of entry Id's
	 */
	if ( SvROK(ST(2)) &&
		(entryList_array = (AV *)SvRV(ST(2))) &&
		(SvTYPE(entryList_array) == SVt_PVAV) ) {

		entryList.numItems = av_len(entryList_array) + 1;
		/* Newz(777,entryList.entryIdList,entryList.numItems,AREntryIdList); */
		entryList.entryIdList = 
			MALLOCNN( entryList.numItems * sizeof(AREntryIdList) );

		for (i=0; i<entryList.numItems; i++) {
			SV **array_entry;
			if (! (array_entry = av_fetch(entryList_array, i, 0))) {
				(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID);
				FreeAREntryIdListList(&entryList,FALSE);
				goto get_mentry_cleanup;
			}
			if( perl_BuildEntryList(ctrl, 
				&entryList.entryIdList[i],
				SvPV(*array_entry, PL_na)) != 0 ) {

				FreeAREntryIdListList(&entryList,FALSE);
				goto get_mentry_cleanup;
			}
		}
	} else {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID );
		goto get_mentry_cleanup;
	}
	/*
	 * do API call
	 */
	ret = ARGetMultipleEntries(ctrl, schema, &entryList, &idList, 
				   &existList, &fieldList, &status);
#ifdef PROFILE
	((ars_ctrl *)ctrl)->queries++;
#endif
	if (ARError( ret, status)) {
		goto get_mentry_cleanup;
	}
	if(fieldList.numItems < 1) {
		goto get_mentry_cleanup;
	}
	/*
	 * build PERL copy of returned entries
	 */
	for (i=0; i < entryList.numItems; i++) {
		HV * fieldValue_hash;
		unsigned int field;
		char intstr[12];
		/*
		 * push entryID onto list
		 */
		if (entryList.entryIdList[i].numItems == 1) {
			/* only one entryId -- so just return its value to be compatible
			with ars 2 */
			XPUSHs(sv_2mortal(newSVpv(entryList.entryIdList[i].entryIdList[0], 0)));
		} else {
			/* more than one entry -- this must be a join schema. merge
			 * the list into a single entry-id to keep things
			 * consistent. */
			unsigned int   entry;
			char *joinId = (char *)NULL;
			char  joinSep[2] = {AR_ENTRY_ID_SEPARATOR, 0};
			for (entry=0; entry < entryList.entryIdList[i].numItems; entry++) {
				joinId = strappend(joinId, entryList.entryIdList[i].entryIdList[entry]);
				if(entry < entryList.entryIdList[i].numItems-1)
				joinId = strappend(joinId, joinSep);
			}
			XPUSHs(sv_2mortal(newSVpv(joinId, 0)));
		}
		/*
		 * push field/value hash reference onto list
		 */
		if ( existList.booleanList[i] ) {
			fieldValue_hash = newHV();
			for (field=0; field < fieldList.valueListList[i].numItems; field++) {
				sprintf(intstr,"%ld",fieldList.valueListList[i].fieldValueList[field].fieldId);
				hv_store( fieldValue_hash,
					intstr, strlen(intstr),
					perl_ARValueStruct(ctrl,&fieldList.valueListList[i].fieldValueList[field].value),
					0 );
			}
			XPUSHs(newRV_noinc((SV *)fieldValue_hash));
		} else {
			XPUSHs(&PL_sv_undef);
		}
	}
	get_mentry_cleanup:;
	FreeARInternalIdList(&idList, FALSE);
	FreeAREntryIdListList(&entryList, FALSE);
	FreeARFieldValueListList(&fieldList, FALSE);
	FreeARBooleanList(&existList, FALSE);
#else /* prior to ARS 4.0 */
	(void) ARError_reset();
	Zero(&status, 1, ARStatusList);
	(void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED,
		"ars_GetMultipleEntries() is only available in ARS >= 4.x");
#endif
	}


void
ars_GetListEntryWithFields(ctrl,schema,qualifier,maxRetrieve=0,firstRetrieve=0,...)
	ARControlStruct *       ctrl
	char *                  schema
	ARQualifierStruct *     qualifier
	unsigned int            firstRetrieve
	unsigned int            maxRetrieve
	PPCODE:
	{
	  ARStatusList     status;
#if AR_EXPORT_VERSION >= 4
	  unsigned int              c = (items - 5) / 2, i;
	  int              field_off = 5;
	  ARSortList       sortList;
	  AREntryListFieldValueList  entryFieldValueList;
	  int              ret;
	  AREntryListFieldList getListFields, *getList = NULL;
	  AV              *getListFields_array;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  sortList.sortList = NULL;
	  getListFields.fieldsList = NULL;
	  entryFieldValueList.entryList = NULL;
	  if ((items - 5) % 2) {
	    /* odd number of arguments, so argument after maxRetrieve is
	       optional getListFields (an array of hash refs) */
	    if ( SvROK(ST(field_off)) &&
	         (getListFields_array = (AV *)SvRV(ST(field_off))) &&
	         (SvTYPE(getListFields_array) == SVt_PVAV) ) {
	      getList = &getListFields;
	      getListFields.numItems = av_len(getListFields_array) + 1;
	      DBG( ("getListFields.numItems=%d\n", getListFields.numItems) );
	      /* Newz(777,getListFields.fieldsList, getListFields.numItems,AREntryListFieldStruct); */
	      getListFields.fieldsList = MALLOCNN( sizeof(AREntryListFieldStruct) * getListFields.numItems );
	      /* set query field list */
	      for (i=0; i<getListFields.numItems; i++) {
	        SV **array_entry;
	        /* get fieldID from array */
	        if (! (array_entry = av_fetch(getListFields_array, i, 0))) {
	          (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
	          goto getlistentry_end;
	        }
	        getListFields.fieldsList[i].fieldId = SvIV(*array_entry);
	        getListFields.fieldsList[i].columnWidth = 1;
	        strncpy(getListFields.fieldsList[i].separator, " ", 2 );
	        DBG( ("i=%d, fieldId=%d, columnWidth=%d, separator=\"%s\"\n", i,
	             getListFields.fieldsList[i].fieldId,
	             getListFields.fieldsList[i].columnWidth,
	             getListFields.fieldsList[i].separator) );
	      }
	    } else {
	      (void) ARError_add( AR_RETURN_ERROR, AP_ERR_LFLDS_TYPE);
	      goto getlistentry_end;
	    }
	    /* increase the offset of the first sortList field by one */
	    field_off ++;
	  }
	  /* build sortList */
	  sortList.numItems = c;
	  /* Newz(777,sortList.sortList, c,  ARSortStruct); */
	  sortList.sortList = MALLOCNN( sizeof(ARSortStruct) * c );
	  for (i=0; i<c; i++) {
	    sortList.sortList[i].fieldId = SvIV(ST(i*2+field_off));
	    sortList.sortList[i].sortOrder = SvIV(ST(i*2+field_off+1));
	  }
	  ret = ARGetListEntryWithFields(ctrl, schema, qualifier, 
		getList, &sortList, 
#if AR_EXPORT_VERSION >= 6
		firstRetrieve,
#endif
		maxRetrieve, 
#if AR_EXPORT_VERSION >= 8L
                FALSE,
#endif
		&entryFieldValueList, NULL, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError( ret, status)) {
	    goto getlistentry_end;
	  }
	  for (i=0; i < entryFieldValueList.numItems; i++) {
	    HV * fieldValue_hash = newHV();
	    unsigned int field;
	    char intstr[12];
	    if (entryFieldValueList.entryList[i].entryId.numItems == 1) {
	      /* only one entryId -- so just return its value to be compatible
	         with ars 2 */
	      XPUSHs(sv_2mortal(newSVpv(entryFieldValueList.entryList[i].entryId.entryIdList[0], 0)));
	    } else {
	      /* more than one entry -- this must be a join schema. merge
	       * the list into a single entry-id to keep things
	       * consistent. */
	      unsigned int   entry;
	      char *joinId = (char *)NULL;
	      char  joinSep[2] = {AR_ENTRY_ID_SEPARATOR, 0};
	      for (entry=0; entry < entryFieldValueList.entryList[i].entryId.numItems; entry++) {
	        joinId = strappend(joinId, entryFieldValueList.entryList[i].entryId.entryIdList[entry]);
	        if(entry < entryFieldValueList.entryList[i].entryId.numItems-1)
	        joinId = strappend(joinId, joinSep);
	      }
	      XPUSHs(sv_2mortal(newSVpv(joinId, 0)));
	    }
	    for (field=0; field < entryFieldValueList.entryList[i].entryValues->numItems; field++) {
	      sprintf(intstr,"%ld",entryFieldValueList.entryList[i].entryValues->fieldValueList[field].fieldId);
	      hv_store( fieldValue_hash,
	                intstr, strlen(intstr),
	                perl_ARValueStruct(ctrl,&entryFieldValueList.entryList[i].entryValues->fieldValueList[field].value),
	                0 );
	    }
	    XPUSHs(newRV_noinc((SV *)fieldValue_hash));
	  }
	  getlistentry_end:
	  FreeAREntryListFieldValueList( &entryFieldValueList,FALSE );
	  FreeARSortList( &sortList, FALSE );
	  FreeAREntryListFieldList( &getListFields, FALSE );
#else	/* prior to ARS 4.0 */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED,
	  "ars_GetListEntryWithFields() is only available in ARS >= 4.x");
#endif
	}



###################################################
# ALERT ROUTINES. as of 5.x, these replace the 
# Notifier routines found below.
#

int
ars_RegisterForAlerts(ctrl, clientPort, registrationFlags=0)
	ARControlStruct *	ctrl
	int			clientPort
	unsigned int		registrationFlags
	CODE:
	{
		ARStatusList status;
		int          ret;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		RETVAL = 0;
#if AR_EXPORT_VERSION >= 6
		ret = ARRegisterForAlerts(ctrl, clientPort, 
				registrationFlags, &status);
		if( !ARError(ret, status) ) {
			RETVAL = 1;
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"RegisterForAlerts() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_DeregisterForAlerts(ctrl,clientPort)
	ARControlStruct *	ctrl
	int			clientPort
	CODE:
	{
		ARStatusList status;
		int          ret;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		RETVAL = 0;
#if AR_EXPORT_VERSION >= 6
		ret = ARDeregisterForAlerts(ctrl, clientPort, 
					    &status);
		if( !ARError(ret, status) ) {
			RETVAL = 1;
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"DeregisterForAlerts() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

void
ars_GetListAlertUser(ctrl)
	ARControlStruct *	ctrl
	PPCODE:
	{
#if AR_EXPORT_VERSION >= 6
		ARStatusList     status;
		ARAccessNameList userList;
		int              ret;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		ret = ARGetListAlertUser(ctrl, &userList,
					 &status);
		if( !ARError(ret, status) ) {
			if (userList.numItems > 0) {
				unsigned int i = 0;
				while(i < userList.numItems) {
					XPUSHs(sv_2mortal(newSVpvn(userList.nameList[i++], 
							AR_MAX_NAME_SIZE)));
				}
			}
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"GetListAlertUser() is only available in ARSystem >= 5.0");
	  XPUSHs(sv_2mortal(&PL_sv_undef));
#endif
	}

SV *
ars_GetAlertCount(ctrl,qualifier)
	ARControlStruct *	ctrl
	ARQualifierStruct *	qualifier
	CODE:
	{
		ARStatusList     status;
		int              ret;
		unsigned int	 count = 0;

		RETVAL=newSVsv(&PL_sv_undef);
#if AR_EXPORT_VERSION >= 6
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		ret = ARGetAlertCount(ctrl, qualifier, &count,
				      &status);
		if( !ARError(ret, status) ) {
			RETVAL=sv_2mortal(newSViv(count));
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"GetAlertCount() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

HV *
ars_DecodeAlertMessage(ctrl,message,messageLen)
	ARControlStruct *	ctrl
	unsigned char *		message
	unsigned int		messageLen
	CODE:
	{
		ARStatusList     status;
		int              ret;
		ARTimestamp      timestamp;
		unsigned int	 sourceType;
		unsigned int	 priority;
		char 		*alertText  = CPNULL;
		char		*sourceTag  = CPNULL;
		char		*serverName = CPNULL;
		char		*serverAddr = CPNULL;
		char		*formName   = CPNULL;
		char 		*objId      = CPNULL;

		RETVAL=newHV();
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 6
		ret = ARDecodeAlertMessage(ctrl, message, messageLen,
					&timestamp,
					&sourceType,
					&priority,
					&alertText,
					&sourceTag,
					&serverName,
					&serverAddr,
					&formName,
					&objId,
					&status);

		if( !ARError(ret, status) ) {
			hv_store(RETVAL, "timestamp", strlen("timestamp"),
				newSViv(timestamp), 0);
			hv_store(RETVAL, "sourceType", strlen("sourceType"),
				newSViv(sourceType), 0);
			hv_store(RETVAL, "priority", strlen("priority"),
				newSViv(priority), 0);

			hv_store(RETVAL, "alertText", strlen("alertText"),
				newSVpv(alertText, 0), 0);
			hv_store(RETVAL, "sourceTag", strlen("sourceTag"),
				newSVpv(sourceTag, 0), 0);
			hv_store(RETVAL, "serverName", strlen("serverName"),
				newSVpv(serverName, 0), 0);
			hv_store(RETVAL, "serverAddr", strlen("serverAddr"),
				newSVpv(serverAddr, 0), 0);
			hv_store(RETVAL, "formName", strlen("formName"),
				newSVpv(formName, 0), 0);
		}

		if (alertText)  AP_FREE(alertText);
		if (sourceTag)  AP_FREE(sourceTag);
		if (serverName) AP_FREE(serverName);
		if (serverAddr) AP_FREE(serverAddr);
		if (formName)   AP_FREE(formName);
		if (objId)	AP_FREE(objId);
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"GetAlertCount() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

SV *
ars_CreateAlertEvent(ctrl,user,alertText,priority,sourceTag,serverName,formName,objectId)
	ARControlStruct *	ctrl
	char            *	user
	char *			alertText
	int			priority
	ARNameType		sourceTag
	ARServerNameType	serverName
	ARNameType		formName
	char *			objectId
	CODE:
	{
		ARStatusList     status;
		int              ret;
		AREntryIdType	 entryId;

		RETVAL=newSVsv(&PL_sv_undef);
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 6
		ret = ARCreateAlertEvent(ctrl, 
					user,
					alertText,
					priority,
					sourceTag,
					serverName,
					formName,
					objectId,
					entryId,
					&status);

		if( !ARError(ret, status) ) {
			RETVAL=newSVpvn(entryId, AR_MAX_ENTRYID_SIZE);
		}
#else
	  (void) ARError_add(AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"CreateAlertEvent() is only available in ARSystem >= 5.0");
#endif
	}
	OUTPUT:
	RETVAL

###################################################
# NT (Notifier) ROUTINES. 
# when compiled against a 5.x API or greater,
# these routines are stubbed to return
# errors.
#

int
ars_NTInitializationClient()
        CODE:
        {
#if AR_EXPORT_VERSION < 6
          NTStatusList status;
          int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
          RETVAL = 0;
# if AR_EXPORT_VERSION < 3
          ret = NTInitializationClient(&status);
          if(!NTError( ret, status)) {
          	RETVAL = 1;
          }
# else
          RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTInitializationClient() is only available in ARS2.x");
# endif
#else /* >=5.0 */
          RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTInitializationClient() is only available in ARSystem < 5.0");
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
#if AR_EXPORT_VERSION < 6
	  NTStatusList status;
	  int ret;

	  (void) ARError_reset();
	  RETVAL = 0;
	  Zero(&status, 1,NTStatusList);
# if AR_EXPORT_VERSION < 3
	  if(user && password && filename) {
		ret = NTDeregisterClient(user, password, filename, &status);
		if(!NTError( ret, status)) {
			RETVAL = 1;
		}
	  }
# else
	  RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTDeregisterClient() is only available in ARS2.x");
# endif
#else /* >= 5.0 */
	  RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTDeregisterClient() is only available in ARSystem < 5.0");
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
#if AR_EXPORT_VERSION < 6
	  NTStatusList status;
	  int ret;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  RETVAL = 0;
# if AR_EXPORT_VERSION < 3
	  if(user && password && filename) {
	  	ret = NTRegisterClient(user, password, filename, &status);
		if(!NTError( ret, status)) {
			RETVAL = 1;
		}
	  }
# else
	  RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTRegisterClient() is only available in ARS2.x");
# endif
#else /* >= 5.0 */
	  RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTRegisterClient() is only available in ARSystem < 5.0");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_NTTerminationClient()
	CODE:
	{
#if AR_EXPORT_VERSION < 6
	  NTStatusList status;
	  int ret;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  RETVAL = 0;
# if AR_EXPORT_VERSION < 3
	  ret = NTTerminationClient(&status);
	  if(!NTError( ret, status)) {
	 	RETVAL = 1;
	  }
# else
	  RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTTerminationClient() is only available in ARS2.x");
# endif
#else /* >= 5.0 */
	  RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTTerminationClient() is only available in ARSystem < 5.0");
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
#if AR_EXPORT_VERSION < 6
	  NTStatusList status;
	  int          ret;
# if AR_EXPORT_VERSION < 3
	  Zero(&status, 1, NTStatusList);
	  (void) ARError_reset();
	  RETVAL = 0;
	  if(serverHost && user && password && items == 3) {
		ret = NTRegisterServer(serverHost, user, password, &status);
		if(!NTError(ret, status)) {
			RETVAL = 1;
		}
	  } else {
		(void) ARError_add(AR_RETURN_ERROR, AP_ERR_USAGE,
			"usage: ars_NTRegisterServer(serverHost, user, password)");
	  }
# else /* >= 3 */
	  NTPortAddr    clientPort;
	  unsigned int  clientCommunication;
	  unsigned int  protocol;
	  int           multipleClients;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  RETVAL = 0;
	
          if (items < 4 || items > 7) {
		(void) ARError_add(AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
		goto ntregserver_end;
	  }
	
	  clientPort = (unsigned int)SvIV(ST(3));
	
	  if (items < 5) {
		clientCommunication = NT_CLIENT_COMMUNICATION_SOCKET;
	  } else {
		clientCommunication = (unsigned int)SvIV(ST(4));
	  }
	
	  if (items < 6) {
		protocol = NT_PROTOCOL_TCP;
	  } else {
		protocol = (unsigned int)SvIV(ST(5));
	  }
	
	  if (items < 7) {
		multipleClients = 1;
	  } else {
		multipleClients = (unsigned int)SvIV(ST(6));
	  }

	  if(clientCommunication == NT_CLIENT_COMMUNICATION_SOCKET) {
		if(protocol == NT_PROTOCOL_TCP) {
			ret = NTRegisterServer(serverHost, user, password, 
						clientCommunication, clientPort, protocol, 
						multipleClients, &status);
			if(!NTError(ret, status)) {
				RETVAL = 1;
			}
		} else 
			(void) ARError_add(AR_RETURN_ERROR, AP_ERR_INV_ARGS,
				"protocol arg invalid.");
	  } else 
		(void) ARError_add(AR_RETURN_ERROR, AP_ERR_INV_ARGS,
				"clientCommunication arg invalid.");
# endif /* pre/post 3.0 selection */
	ntregserver_end:;
#else /* >= 5.0 */
	  RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTRegisterServer() is only available in ARSystem < 5.0");
#endif
	}
	OUTPUT:
	RETVAL

int 
ars_NTTerminationServer()
	CODE:
	{
#if AR_EXPORT_VERSION < 6
	 int ret;
	 NTStatusList status;

	 (void) ARError_reset();
	 Zero(&status, 1, NTStatusList);
	 RETVAL = 0;
	 ret = NTTerminationServer(&status);
	 if(!NTError( ret, status)) {
		RETVAL = 1;
	 }
#else /* >= 5.0 */
	 RETVAL = 0;
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTTerminationServer() is only available in ARSystem < 5.0");
#endif
	}
	OUTPUT:
	RETVAL

int
ars_NTDeregisterServer(serverHost, user, password, port=0)
	char *		serverHost
	char *		user
	char *		password
	unsigned long	port
	CODE:
	{
#if AR_EXPORT_VERSION < 6
	 int ret;
	 NTStatusList status;

	 (void) ARError_reset();
	 Zero(&status, 1, NTStatusList);
	 RETVAL = 0; /* assume error */
	 if(serverHost && user && password) {
		ret = NTDeregisterServer(serverHost, user, password,
# if AR_EXPORT_VERSION >= 4
			&port, 
# endif /* < 4 */
			&status);
	    if(!NTError( ret, status)) {
		RETVAL = 1; /* success */
	    }
	 }
#else /* >= 5.0 */
         RETVAL = 0; /* assume error */
         (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
                             "NTDeregisterServer() is only available in ARSystem < 5.0");
#endif
	}
	OUTPUT:
	RETVAL

void
ars_NTGetListServer()
	PPCODE:
	{
#if AR_EXPORT_VERSION < 6
	  NTServerNameList serverList;
	  NTStatusList     status;
	  int              ret, i;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  ret = NTGetListServer(&serverList, &status);
	  if(!NTError( ret, status)) {
		for(i=0; i<serverList.numItems; i++) {
			XPUSHs(sv_2mortal(newSVpv(serverList.nameList[i], 0)));
		}
		FreeNTServerNameList(&serverList, FALSE);
	  }
#else /* >= 5.0 */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTGetListServer() is only available in ARSystem < 5.0");
#endif
	}

int
ars_NTInitializationServer()
	CODE:
	{
#if AR_EXPORT_VERSION < 6
	  NTStatusList status;
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  RETVAL = 0; /* error */
	  ret = NTInitializationServer(&status);
	  if(!NTError( ret, status)) {
	     RETVAL = 1; /* success */
	  }
#else /* >= 5.0 */
	  RETVAL = 0; /* error */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTInitializationServer() is only available in ARSystem < 5.0");
#endif
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
#if AR_EXPORT_VERSION < 6
	  NTStatusList status;
	  int ret;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  RETVAL = 0;
	  if(serverHost && user && notifyText) {
	     ret = NTNotificationServer(serverHost, user, notifyText, notifyCode, 
					notifyCodeText, &status);
	     if(!NTError( ret, status)) {
		RETVAL = 1;
	     }
	  }
#else
	  RETVAL = 0; /* error */
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, 
			"NTNotificationServer() is only available in ARSystem < 5.0");
#endif
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
		ARStatusList status;
		int rv = 0;

		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		DBG( ("control struct destructor\n") );
# if AR_EXPORT_VERSION >= 4
		rv = ARTermination(ctrl, &status);
# else
		rv = ARTermination(&status);
# endif /* AR_EXPORT_VERSION */
		(void) ARError(rv, status);
		free(ctrl);
	}

MODULE = ARS		PACKAGE = ARQualifierStructPtr

void
DESTROY(qual)
	ARQualifierStruct *	qual
	CODE:
	{
		DBG( ("arqualifierstruct destructor\n") );
		FreeARQualifierStruct(qual, TRUE);
	}
