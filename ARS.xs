/*
$Header: /cvsroot/arsperl/ARSperl/ARS.xs,v 1.78 2001/10/22 05:59:25 jcmurphy Exp $

    ARSperl - An ARS v2 - v4 / Perl5 Integration Kit

    Copyright (C) 1995-2000
	Joel Murphy, jmurphy@acsu.buffalo.edu
        Jeff Murphy, jcmurphy@acsu.buffalo.edu

    This program is free software; you can redistribute it and/or modify
    it under the terms as Perl itself. 
    
    Refer to the file called "Artistic" that accompanies the source 
    distribution of ARSperl (or the one that accompanies the source 
    distribution of Perl itself) for a full description.
 
    Comments to:  arsperl@smurfland.cit.buffalo.edu
                  (this is a *mailing list* and you must be
                   a subscriber before posting)

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
	  Newz(777,qual,1,ARQualifierStruct);
	  Zero(&status, 1, ARStatusList);
	  (void) ARError_reset();
	  /* this gets freed below in the ARQualifierStructPTR package */
	  ret = ARLoadARQualifierStruct(ctrl, schema, displayTag, qualstring, qual, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret, status)) {
	    RETVAL = qual;
	  } else {
	    RETVAL = NULL;
#ifndef WASTE_MEM
	    safefree(qual);
#endif
	  }
	}
	OUTPUT:
	RETVAL

void
__ars_Termination()
	CODE:
	{
	  int          ret;
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
	  int          ret;
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
ars_Login(server,username,password)
	char *		server
	char *		username
	char *		password
	CODE:
	{
		int              ret, s_ok = 1;
		ARStatusList     status;
		ARServerNameList serverList;
		ARControlStruct *ctrl;
#ifdef PROFILE
		struct timeval   tv;
#endif

		DBG( ("ars_Login(%s, %s, %s)\n", 
			SAFEPRT(server),
			SAFEPRT(username),
			SAFEPRT(password)) );

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
		ctrl->language[0] = 0;
#if AR_EXPORT_VERSION >= 4
		/* call ARInitialization */
		ret = ARInitialization(ctrl, &status);

		if(ARError(ret, status)) {
			DBG( ("ARInitialization failed %d\n", ret) );
			safefree(ctrl);
			goto ar_login_end;
		}
#endif

		if (!server || !*server) {
			DBG( ("no server give. picking one.\n") );
#if AR_EXPORT_VERSION >= 4
	  		ret = ARGetListServer(ctrl, &serverList, &status);
#else
	  		ret = ARGetListServer(&serverList, &status);
#endif
	  		if (ARError( ret, status)) {
	    			safefree(ctrl); /* invalid, cleanup */
				DBG( ("ARGetListServer failed %d\n", ret) );
	   			goto ar_login_end;
	  		}
			status.numItems = 0;
	  		if (serverList.numItems == 0) {
	     			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_NO_SERVERS);
	      			safefree(ctrl); /* invalid, cleanup */
	      			goto ar_login_end;
	    		}
	    		server = serverList.nameList[0];
			DBG( ("changing s_ok to 0, picked server %s\n",
				SAFEPRT(server)) );
	    		s_ok = 0;
	  	}
	  	strncpy(ctrl->server, server, sizeof(ctrl->server));
	 	ctrl->server[sizeof(ctrl->server)-1] = 0;

	  	/* finally, check to see if the user id is valid */

	  	ret = ARVerifyUser(ctrl, NULL, NULL, NULL, &status);
	  	if(ARError( ret, status)) {
			DBG( ("ARVerifyUser failed %d\n", ret) );
			safefree(ctrl); /* invalid, cleanup */
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
	   XPUSHs(sv_2mortal(newSVpv(ctrl->language, 0)));
	   XPUSHs(sv_2mortal(newSVpv(ctrl->server, 0)));
	}

SV *
ars_GetCurrentServer(ctrl)
	ARControlStruct *	ctrl
	CODE:
	{
	  RETVAL = NULL;
	  (void) ARError_reset();
	  if(ctrl && ctrl->server) {
	    RETVAL = newSVpv(VNAME(ctrl->server));
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
	  hv_store(RETVAL, VNAME("queries"), 
	  	   newSViv(((ars_ctrl *)ctrl)->queries), 0);
	  hv_store(RETVAL, VNAME("startTime"), 
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
		/*printf("ctrl=0x%x\n", &ctrl);*/
		ret = ARTermination(ctrl, &status);
#else
		ret = ARTermination(&status);
#endif
		(void) ARError( ret, status);
	/*		if(ctrl) safefree(ctrl); /**/
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
	  int              ret, i;
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
	  int              ret, loop;
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
	  int              ret, loop;
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

SV *
ars_CreateEntry(ctrl,schema,...)
	ARControlStruct *	ctrl
	char *			schema
	CODE:
	{
	  int               a, i, c = (items - 2) / 2, j;
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
	    Newz(777,fieldList.fieldValueList,c,ARFieldValueStruct);
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
	    if(rv == 0)
		RETVAL = newSVsv(&PL_sv_undef);
	    else
		RETVAL = newSVpv(VNAME(entryId));
#ifndef WASTE_MEM
	  safefree(fieldList.fieldValueList);
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
	  int            ret;
	  ARStatusList   status;
#if AR_EXPORT_VERSION >= 3
	  SV           **fetch_entry;
	  AREntryIdList  entryList;
	  AV            *input_list;
	  int            i;

	  RETVAL = 0; /* assume error */
	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  if(perl_BuildEntryList(ctrl, &entryList, entry_id) != 0)
		goto delete_fail;
	  ret = ARDeleteEntry(ctrl, schema, &entryList, 0, &status);
#ifndef WASTE_MEM
	  FreeAREntryIdList(&entryList, FALSE);
#endif
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
		ARBufStruct     buf;
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
			loc.u.filename = locFile;
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
			"NTTerminationClient() is only available > ARS4.x");
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
	  int               c = items - 3, i, ret;
	  ARInternalIdList  idList;
	  ARFieldValueList  fieldList;
	  ARStatusList      status;
	  char             *entryId;
#if AR_EXPORT_VERSION >= 3
	  SV              **fetch_entry;
	  AREntryIdList     entryList;
	  AV               *input_list;
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
#ifndef WASTE_MEM
	  FreeAREntryIdList(&entryList,FALSE);
#endif
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
#ifndef WASTE_MEM
	  FreeARFieldValueList(&fieldList,FALSE);
#endif
	get_entry_cleanup:;
#ifndef WASTE_MEM
	  FreeARInternalIdList(&idList, FALSE);
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
	  int              c = (items - 4) / 2, i;
	  int              field_off = 4;
	  ARSortList       sortList;
	  AREntryListList  entryList;
	  unsigned int     num_matches;
	  ARStatusList     status;
	  int              ret;
#if AR_EXPORT_VERSION >= 3
	  AREntryListFieldList getListFields, *getList = NULL;
	  AV              *getListFields_array;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  if ((items - 4) % 2) {
	    /* odd number of arguments, so argument after maxRetrieve is
	       optional getListFields (an array of hash refs) */
	    if (SvROK(ST(field_off)) &&
		(getListFields_array = (AV *)SvRV(ST(field_off))) &&
		SvTYPE(getListFields_array) == SVt_PVAV) {
	      getList = &getListFields;
	      getListFields.numItems = av_len(getListFields_array) + 1;
              Newz(777,getListFields.fieldsList, getListFields.numItems,AREntryListFieldStruct);
	      /* set query field list */
	      for (i=0; i<getListFields.numItems; i++) {
		SV **array_entry, **hash_entry;
		HV *field_hash;
		/* get hash from array */
		if ((array_entry = av_fetch(getListFields_array, i, 0)) &&
		    SvROK(*array_entry) &&
		    SvTYPE(field_hash = (HV*)SvRV(*array_entry)) == SVt_PVHV) {
		  /* get fieldId, columnWidth and separator from hash */
		  if (! (hash_entry = hv_fetch(field_hash, VNAME("fieldId"), 0))) {
		    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
#ifndef WASTE_MEM
		      safefree(getListFields.fieldsList);
#endif
		    goto getlistentry_end;
		  }
		  getListFields.fieldsList[i].fieldId = SvIV(*hash_entry);
		  if (! (hash_entry = hv_fetch(field_hash, VNAME("columnWidth"), 0))) {
		    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
#ifndef WASTE_MEM
		      safefree(getListFields.fieldsList);
#endif
		    goto getlistentry_end;
		  }
		  getListFields.fieldsList[i].columnWidth = SvIV(*hash_entry);
		  if (! (hash_entry = hv_fetch(field_hash, VNAME("separator"), 0))) {
		    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_LFLDS);
#ifndef WASTE_MEM

		      safefree(getListFields.fieldsList);
#endif
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
	  if ((items - 4) % 2) {
	    (void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	    goto getlistentry_end;
	  }
#endif /* if ARS >= 3 */
	  /* build sortList */
	  sortList.numItems = c;
          Newz(777,sortList.sortList, c,  ARSortStruct);
	  for (i=0; i<c; i++) {
	    sortList.sortList[i].fieldId = SvIV(ST(i*2+field_off));
	    sortList.sortList[i].sortOrder = SvIV(ST(i*2+field_off+1));
	  }
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListEntry(ctrl, schema, qualifier, getList, &sortList, maxRetrieve, &entryList, &num_matches, &status);
#else
	  ret = ARGetListEntry(ctrl, schema, qualifier, &sortList, maxRetrieve, &entryList, &num_matches, &status);
#endif
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (ARError( ret, status)) {
#ifndef WASTE_MEM
	    safefree(sortList.sortList);
#endif
	    goto getlistentry_end;
	  }
	  for (i=0; i < entryList.numItems; i++) {
#if AR_EXPORT_VERSION >= 3
	    AV *entryIdList;
	    
	    if (entryList.entryList[i].entryId.numItems == 1) {
	      /* only one entryId -- so just return its value to be compatible
		 with ars 2 */
	      XPUSHs(sv_2mortal(newSVpv(entryList.entryList[i].entryId.entryIdList[0], 0)));
	    } else {
	      /* more than one entry -- this must be a join schema. merge
	       * the list into a single entry-id to keep things
	       * consistent.
               */
	      int   entry;
	      char *joinId = (char *)NULL;
	      char  joinSep[2] = {AR_ENTRY_ID_SEPARATOR, 0};

	      for (entry=0; entry < entryList.entryList[i].entryId.numItems; entry++) {
	        joinId = strappend(joinId, entryList.entryList[i].entryId.entryIdList[entry]);
	        if(entry < entryList.entryList[i].entryId.numItems-1)
		    joinId = strappend(joinId, joinSep);
	      }
	      XPUSHs(sv_2mortal(newSVpv(joinId, 0)));
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
ars_GetListSchema(ctrl,changedsince=0,schemaType=AR_LIST_SCHEMA_ALL,name=NULL)
	ARControlStruct *	ctrl
	unsigned int		changedsince
	unsigned int		schemaType
	char *			name
	PPCODE:
	{
	  ARNameList   nameList;
	  ARStatusList status;
	  int          i, ret;

	  (void) ARError_reset();	  
	  Zero(&status, 1, ARStatusList);
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetListSchema(ctrl, changedsince, schemaType, name, 
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
#ifndef WASTE_MEM
	    FreeARNameList(&nameList,FALSE);
#endif
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
	  int          		i, ret;

	  (void) ARError_reset();	  
	  Zero(&status, 1, ARStatusList);
		printf("items %d\n", items);
#if AR_EXPORT_VERSION >= 4
	  if(items > 3) {
		int 			i;
	  	ARContainerTypeList	containerTypes;
		ARContainerOwnerObj 	ownerObj;
		ARContainerInfoList	conList;

		containerTypes.numItems = items - 3;
		Newz(777, containerTypes.type, 
		     containerTypes.numItems, int);
		for(i = 3 ; i < items ; i++) {
			containerTypes.type[i-3] = SvIV(ST(i));
		}

		i = ARGetListContainer(ctrl, changedSince,
					&containerTypes,
					attributes,
					&ownerObj, &conList, &status);
		if(!ARError(i, status)) {
			HV *r = newHV();				
		}
		Safefree(containerTypes.type);
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
	  int              i, ret;
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
	  int              ret;
	  unsigned int     order;
	  ARNameType       schema;
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

	  Newz(777,query,1,ARQualifierStruct);

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
		hv_store(RETVAL, VNAME("name"), newSVpv(name, 0), 0);
		hv_store(RETVAL, VNAME("order"), newSViv(order),0);
#if AR_EXPORT_VERSION >= 5
		hv_store(RETVAL, VNAME("schemaList"), /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL, VNAME("objPropList"),
			perl_ARPropList(ctrl, &objPropList), 0);
#else
		hv_store(RETVAL, VNAME("schema"), newSVpv(schema,0),0);
#endif
		hv_store(RETVAL, VNAME("groupList"),
		     perl_ARList( ctrl, 
				 (ARList *)&groupList,
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)), 0);
		hv_store(RETVAL, VNAME("executeMask"), newSViv(executeMask),0);
#if  AR_EXPORT_VERSION >= 3
		hv_store(RETVAL, VNAME("focusField"), newSViv(focusField), 0);
		hv_store(RETVAL, VNAME("controlField"), 
			newSViv(controlField), 0);
#else
		hv_store(RETVAL, VNAME("field"), newSViv(field), 0);
		hv_store(RETVAL, VNAME("displayList"), 
		     perl_ARList( ctrl, 
				 (ARList *)&displayList,
				 (ARS_fn)perl_ARDisplayStruct,
				 sizeof(ARDisplayStruct)), 0);
#endif
		hv_store(RETVAL, VNAME("enable"), newSViv(enable), 0);
		/* a bit of a hack -- makes blessed reference to qualifier */
		ref = newSViv(0);
		sv_setref_pv(ref, "ARQualifierStructPtr", (void*)query);
		hv_store(RETVAL, VNAME("query"), ref, 0);
		hv_store(RETVAL, VNAME("actionList"),
		     perl_ARList(ctrl, 
				 (ARList *)&actionList,
				 (ARS_fn)perl_ARActiveLinkActionStruct,
				 sizeof(ARActiveLinkActionStruct)), 0);
#if  AR_EXPORT_VERSION >= 3
		hv_store(RETVAL, VNAME("elseList"),
		     perl_ARList(ctrl, 
				 (ARList *)&elseList,
				 (ARS_fn)perl_ARActiveLinkActionStruct,
				 sizeof(ARActiveLinkActionStruct)), 0);
#endif
		if (helpText)
			hv_store(RETVAL, VNAME("helpText"), newSVpv(helpText,0), 0);
		hv_store(RETVAL, VNAME("timestamp"),  newSViv(timestamp), 0);
		hv_store(RETVAL, VNAME("owner"), newSVpv(owner,0), 0);
		hv_store(RETVAL, VNAME("lastChanged"), newSVpv(lastChanged,0), 0);
		if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
			ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
			ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
			if (!ARError(ret, status)) {
				hv_store(RETVAL, VNAME("changeDiary"),
					perl_ARList(ctrl, (ARList *)&diaryList,
						    (ARS_fn)perl_diary,
						    sizeof(ARDiaryStruct)), 0);
				FreeARDiaryList(&diaryList, FALSE);
			}
	    }
#ifndef WASTE_MEM
	    FreeARInternalIdList(&groupList,FALSE);
#if  AR_EXPORT_VERSION < 3
	    FreeARDisplayList(&displayList,FALSE);
#endif
	    FreeARActiveLinkActionList(&actionList,FALSE);
#if  AR_EXPORT_VERSION >= 3
	    FreeARActiveLinkActionList(&elseList,FALSE);
#endif
	    if(!CVLD(helpText)){
	      FREE(helpText);
	    }
	    if(!CVLD(changeDiary)){
	      FREE(changeDiary);
	    }
#endif
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
	  ARNameType   schema;
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

	  Newz(777,query,1,ARQualifierStruct);

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
	    hv_store(RETVAL, VNAME("name"), newSVpv(name, 0), 0);
	    hv_store(RETVAL, VNAME("order"), newSViv(order), 0);
#if AR_EXPORT_VERSION >= 5
		hv_store(RETVAL, VNAME("schemaList"), /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL, VNAME("objPropList"),
			perl_ARPropList(ctrl, &objPropList), 0);
#else
	    hv_store(RETVAL, VNAME("schema"), newSVpv(schema, 0), 0);
#endif
	    hv_store(RETVAL, VNAME("opSet"), newSViv(opSet), 0);
	    hv_store(RETVAL, VNAME("enable"), newSViv(enable), 0);
	    /* a bit of a hack -- makes blessed reference to qualifier */
	    ref = newSViv(0);
	    sv_setref_pv(ref, "ARQualifierStructPtr", (void *)query);
	    hv_store(RETVAL, VNAME("query"), ref, 0);
	    hv_store(RETVAL, VNAME("actionList"), 
		     perl_ARList(ctrl, 
				 (ARList *)&actionList,
				 (ARS_fn)perl_ARFilterActionStruct,
				 sizeof(ARFilterActionStruct)), 0);
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, VNAME("elseList"),
		     perl_ARList(ctrl, 
				 (ARList *)&elseList,
				 (ARS_fn)perl_ARFilterActionStruct,
				 sizeof(ARFilterActionStruct)), 0);
#endif
	    if(helpText)
		hv_store(RETVAL, VNAME("helpText"), newSVpv(helpText, 0), 0);
	    hv_store(RETVAL, VNAME("timestamp"), newSViv(timestamp), 0);
	    hv_store(RETVAL, VNAME("owner"), newSVpv(owner, 0), 0);
	    hv_store(RETVAL, VNAME("lastChanged"), newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL, VNAME("changeDiary"),
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
#ifndef WASTE_MEM
	    FreeARFilterActionList(&actionList,FALSE);
#if AR_EXPORT_VERSION >= 3
	    FreeARFilterActionList(&elseList,FALSE);
#endif
	    if(!CVLD(helpText)){
	      FREE(helpText);
	    }
	    if(!CVLD(changeDiary)){
	      FREE(changeDiary);
	    }
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
	  ARServerInfoList        serverInfo;
	  int                     i, ret;
	  ARStatusList            status;

	  (void) ARError_reset();
	  Zero(&status, 1, ARStatusList);
	  if(items < 1) {
		(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  } else {
		requestList.numItems = items - 1;
		Newz(777,requestList.requestList,(items-1),unsigned int);
		if(requestList.requestList) {
			for(i=1; i<items; i++) {
				requestList.requestList[i-1] = SvIV(ST(i));
			}
			ret = ARGetServerStatistics(ctrl, &requestList, &serverInfo, &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if(ARError( ret, status)) {
#ifndef WASTE_MEM
				safefree(requestList.requestList);
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
				safefree(requestList.requestList);
#endif
			}
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
		hv_store(RETVAL, VNAME("name"), newSVpv(name, 0), 0);
		if(helpText)
			hv_store(RETVAL, VNAME("helpText"), newSVpv(helpText,0), 0);
		hv_store(RETVAL, VNAME("timestamp"), newSViv(timestamp), 0);
		hv_store(RETVAL, VNAME("owner"), newSVpv(owner, 0), 0);
		hv_store(RETVAL, VNAME("lastChanged"), newSVpv(lastChanged, 0), 0);
	        if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
			ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
			ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
			if (!ARError(ret, status)) {
				hv_store(RETVAL, VNAME("changeDiary"),
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
		hv_store(RETVAL, VNAME("menuType"), 
			   /* PRE-1.68: newSViv(menuDefn.menuType) */
			newSVpv(VNAME(CharMenuTypeMap[i].name))
			, 0);
		hv_store(RETVAL, VNAME("refreshCode"), 
			perl_MenuRefreshCode2Str(ctrl, refreshCode), 0);
		switch(menuDefn.menuType) {
		case AR_CHAR_MENU_QUERY:
			hv_store(menuDef, VNAME("schema"), 
				newSVpv(menuDefn.u.menuQuery.schema, 0), 0);
			hv_store(menuDef, VNAME("server"), 
				newSVpv(menuDefn.u.menuQuery.server, 0), 0);
			hv_store(menuDef, VNAME("labelField"),
				newSViv(menuDefn.u.menuQuery.labelField), 0);
			hv_store(menuDef, VNAME("valueField"),
				newSViv(menuDefn.u.menuQuery.valueField), 0);
			hv_store(menuDef, VNAME("sortOnLabel"),
				newSViv(menuDefn.u.menuQuery.sortOnLabel), 0);
			ref = newSViv(0);
			sv_setref_pv(ref, "ARQualifierStructPtr", 
				dup_qualifier(ctrl,
					(void *)&(menuDefn.u.menuQuery.qualifier)));
			hv_store(menuDef, VNAME("qualifier"), ref, 0);
			hv_store(RETVAL, VNAME("menuQuery"), 
				newRV((SV *)menuDef), 0);
			break;
		case AR_CHAR_MENU_FILE:
			hv_store(menuDef, VNAME("fileLocation"), 
				newSViv(menuDefn.u.menuFile.fileLocation), 0);
			hv_store(menuDef, VNAME("filename"), 
				newSVpv(menuDefn.u.menuFile.filename, 0), 0);
			hv_store(RETVAL, VNAME("menuFile"),
				newRV((SV *)menuDef), 0);
			break;
#ifndef ARS20
		case AR_CHAR_MENU_SQL:
			hv_store(menuDef, VNAME("server"), 
				newSVpv(menuDefn.u.menuSQL.server, 0), 0);
			hv_store(menuDef, VNAME("sqlCommand"), 
				newSVpv(menuDefn.u.menuSQL.sqlCommand, 0), 0);
			hv_store(menuDef, VNAME("labelIndex"), 
				newSViv(menuDefn.u.menuSQL.labelIndex), 0);
			hv_store(menuDef, VNAME("valueIndex"), 
				newSViv(menuDefn.u.menuSQL.valueIndex), 0);
			hv_store(RETVAL, VNAME("menuSQL"), 
				newRV((SV *)menuDef), 0);
			break;
#endif
		}
#ifndef WASTE_MEM
		FreeARCharMenuStruct(&menuDefn, FALSE);
		if(!CVLD(helpText)){
		  FREE(helpText);
		}
		if(!CVLD(changeDiary)){
		  FREE(changeDiary);
		}
#endif
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

		RETVAL = NULL; /*PL_sv_undef;*/
		(void) ARError_reset();
		Zero(&status, 1,ARStatusList);
		ret = ARGetCharMenu(ctrl, name, NULL, &menuDefn, 
					NULL, NULL, NULL, NULL, NULL, 
#if AR_EXPORT_VERSION >= 5
			      		NULL,
#endif
			     		&status);
#ifdef PROFILE
		((ars_ctrl *)ctrl)->queries++;
#endif
		if (! ARError( ret,status)) {
			RETVAL = perl_expandARCharMenuStruct(ctrl, 
							     &menuDefn);
#ifndef WASTE_MEM
			FreeARCharMenuStruct(&menuDefn, FALSE);
#endif

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

	  (void) ARError_reset();
	  Zero(&status, 1,  ARStatusList);
	  RETVAL = newHV();
#if AR_EXPORT_VERSION >= 3
	  ret = ARGetSchema(ctrl, name, &schema, &groupList, &adminGroupList, &getListFields, 
			    &sortList, &indexList, &helpText, &timestamp, owner, 
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
		hv_store(RETVAL, VNAME("objPropList"),
			 perl_ARPropList(ctrl, &objPropList), 0);
#endif
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, VNAME("groupList"),
		     perl_ARPermissionList(ctrl, &groupList, PERMTYPE_SCHEMA), 0);
#else
	    hv_store(RETVAL, VNAME("groupList"),
		     perl_ARList(ctrl, (ARList *)&groupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
#endif
	    hv_store(RETVAL, VNAME("adminList"),
		     perl_ARList(ctrl, (ARList *)&adminGroupList, 
				 (ARS_fn)perl_ARInternalId,
				 sizeof(ARInternalId)),0);
	    hv_store(RETVAL, VNAME("getListFields"),
		     perl_ARList(ctrl, (ARList *)&getListFields,
				 (ARS_fn)perl_AREntryListFieldStruct,
				 sizeof(AREntryListFieldStruct)),0);
	    hv_store(RETVAL, VNAME("indexList"),
		     perl_ARList(ctrl, (ARList *)&indexList,
				 (ARS_fn)perl_ARIndexStruct,
				 sizeof(ARIndexStruct)), 0);
	    if (helpText)
	      hv_store(RETVAL, VNAME("helpText"), newSVpv(helpText, 0), 0);
	    hv_store(RETVAL, VNAME("timestamp"), newSViv(timestamp), 0);
	    hv_store(RETVAL, VNAME("owner"), newSVpv(owner, 0), 0);
	    hv_store(RETVAL, VNAME("lastChanged"),
		     newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL, VNAME("changeDiary"),
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, VNAME("schema"), 
			perl_ARCompoundSchema(ctrl, &schema), 0);
	    hv_store(RETVAL, VNAME("sortList"), 
			perl_ARSortList(ctrl, &sortList), 0);
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
	    if(!CVLD(helpText)){
	      FREE(helpText);
	    }
	    if(!CVLD(changeDiary)){
	      FREE(changeDiary);
	    }
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
	  ARNameList   nameList;
	  ARStatusList status;
	  int          ret, i;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret=ARGetListActiveLink(ctrl,schema,changedSince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if (! ARError( ret,status)) {
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
	  Zero(&Status, 1,ARStatusList);
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
	    hv_store(RETVAL, VNAME("fieldId"), newSViv(id), 0);
	    if (createMode == AR_FIELD_OPEN_AT_CREATE)
	      hv_store(RETVAL, VNAME("createMode"), newSVpv("open",0), 0);
	    else
	      hv_store(RETVAL, VNAME("createMode"),
		       newSVpv("protected",0), 0);
	    hv_store(RETVAL, VNAME("option"), newSViv(option), 0);
	    hv_store(RETVAL, VNAME("dataType"),
		     perl_dataType_names(ctrl, &dataType), 0);
	    hv_store(RETVAL, VNAME("defaultVal"),
		     perl_ARValueStruct(ctrl, &defaultVal), 0);
	    /* permissions below */
	    hv_store(RETVAL, VNAME("limit"), 
		     perl_ARFieldLimitStruct(ctrl, &limit), 0);
#if AR_EXPORT_VERSION >= 3
	    hv_store(RETVAL, VNAME("fieldName"), 
		     newSVpv(fieldName, 0), 0);
	    hv_store(RETVAL, VNAME("fieldMap"),
		     perl_ARFieldMappingStruct(ctrl, &fieldMap), 0);
	    hv_store(RETVAL, VNAME("displayInstanceList"),
		     perl_ARDisplayInstanceList(ctrl, &displayList), 0);
#else
	    hv_store(RETVAL, VNAME("displayList"), 
		     perl_ARList(ctrl, 
				 (ARList *)&displayList,
				 (ARS_fn)perl_ARDisplayStruct,
				 sizeof(ARDisplayStruct)), 0);
#endif
	    if (helpText)
	      hv_store(RETVAL, VNAME("helpText"),
		       newSVpv(helpText, 0), 0);
	    hv_store(RETVAL, VNAME("timestamp"), 
		     newSViv(timestamp), 0);
	    hv_store(RETVAL, VNAME("owner"),
		     newSVpv(owner, 0), 0);
	    hv_store(RETVAL, VNAME("lastChanged"),
		     newSVpv(lastChanged, 0), 0);
	    if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &Status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &Status);
#endif
		if (!ARError(ret, Status)) {
			hv_store(RETVAL, VNAME("changeDiary"),
				perl_ARList(ctrl, (ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	    }
#ifndef WASTE_MEM
	    FreeARFieldLimitStruct(&limit,FALSE);
#if AR_EXPORT_VERSION >= 3
	    FreeARDisplayInstanceList(&displayList,FALSE);
#else
	    FreeARDisplayList(&displayList,FALSE);
#endif
	    if(!CVLD(helpText)){
	      FREE(helpText);
	    }
	    if(!CVLD(changeDiary)){
	      FREE(changeDiary);
	    }
#endif
#if AR_EXPORT_VERSION >= 3
	    ret = ARGetField(ctrl, schema, id, NULL, NULL, NULL, NULL, NULL, NULL, &permissions, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &Status);
#else
	    ret = ARGetField(ctrl, schema, id, NULL, NULL, NULL, NULL, &permissions, NULL, NULL, NULL, NULL, NULL, NULL, NULL, &Status);
#endif
#ifdef PROFILE
	    ((ars_ctrl *)ctrl)->queries++;
#endif
	    if (ret == 0) {
	      hv_store(RETVAL, VNAME("permissions"), 
		       perl_ARPermissionList(ctrl, &permissions, PERMTYPE_FIELD), 0);
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
	char *			entry_id
	unsigned long		getTime
	CODE:
	{
	  int              a, i, c = (items - 4) / 2, j;
	  int              offset = 4;
	  ARFieldValueList fieldList;
	  ARStatusList     status;
	  int              ret;
	  unsigned int     dataType;
#if AR_EXPORT_VERSION >= 3
	  unsigned int     option = AR_JOIN_SETOPTION_NONE;
	  SV            **fetch_entry;
	  AREntryIdList   entryList;
	  AV             *input_list;

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
	  Newz(777,fieldList.fieldValueList,c,ARFieldValueStruct);
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
#ifndef WASTE_MEM
		safefree(fieldList.fieldValueList);
#endif
		goto set_entry_end;
	      }
	      if (sv_to_ARValue(ctrl, ST(a+1), dataType, 
			&fieldList.fieldValueList[i].value) < 0) {
#ifndef WASTE_MEM
		safefree(fieldList.fieldValueList);
#endif
		goto set_entry_end;
	      }
	    }
	  }
#if AR_EXPORT_VERSION >= 3
	  /* build entryList */
	  if(perl_BuildEntryList(ctrl, &entryList, entry_id) != 0){
#ifndef WASTE_MEM
		safefree(fieldList.fieldValueList);
#endif
		goto set_entry_end;
	  }

	  ret = ARSetEntry(ctrl, schema, &entryList, &fieldList, getTime, option, &status);
#ifndef WASTE_MEM
	  FreeAREntryIdList(&entryList, FALSE);
#endif	  
#else /* ARS2.x */
	  if(!entry_id || !*entry_id) {
		ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_EID);
#ifndef WASTE_MEM
		safefree(fieldList.fieldValueList);
#endif
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
#ifndef WASTE_MEM
	  safefree(fieldList.fieldValueList);
#endif
	set_entry_end:;
	set_entry_exit:;
	}
	OUTPUT:
	RETVAL

char *
ars_Export(ctrl,displayTag,...)
	ARControlStruct *	ctrl
	char *			displayTag
	CODE:
	{
		int              ret, i, a, c = (items - 2) / 2, ok = 1;
		ARStructItemList structItems;
		char            *buf = CPNULL;
		ARStatusList     status;
	  
		(void) ARError_reset();
		Zero(&status, 1, ARStatusList);
		RETVAL = NULL;
		if (items % 2 || c < 1) {
			(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
		} else {
			structItems.numItems = c;
			Newz(777, structItems.structItemList, c, ARStructItemStruct);
			for (i = 0 ; i < c ; i++) {
				unsigned int et = 0;
				a  = i * 2 + 2;
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
			ret = ARExport(ctrl, &structItems, displayTag, &buf, &status);
#ifdef PROFILE
			((ars_ctrl *)ctrl)->queries++;
#endif
			if (ARError(ret, status)) {
				safefree(structItems.structItemList);
				if(buf) safefree(buf);
			} else {
				RETVAL = buf;
			}
		} else {
			safefree(structItems.structItemList);
		}
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
				Newz(777, structItems, c, ARStructItemList);
				structItems->numItems = c;
				Newz(777, structItems->structItemList, c,
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
	  int          ret, i;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListFilter(control,schema,changedsince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
	    for (i=0; i < nameList.numItems; i++)
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
	  ARNameList   nameList;
	  ARStatusList status;
	  int          ret, i;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListEscalation(control,schema,changedsince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif
	  if (!ARError( ret,status)) {
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
	  ARNameList   nameList;
	  ARStatusList status;
	  int          ret, i;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListCharMenu(control,changedsince,&nameList,&status);
#ifdef PROFILE
	  ((ars_ctrl *)control)->queries++;
#endif

	  if (!ARError( ret,status)) {
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
#ifndef WASTE_MEM
	    FreeARNameList(&nameList,FALSE);
#endif
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
	  if(ctrl && name && *name) {
		ret = ARDeleteActiveLink(ctrl, name, &status);
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
		ret = ARDeleteCharMenu(ctrl, name, &status);
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
		ret = ARDeleteEscalation(ctrl, name, &status);
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
		ret = ARDeleteFilter(ctrl, name, &status);
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
#ifndef WASTE_MEM
	     FreeARInternalIdList(&fieldList, FALSE);
#endif
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
	 int          ret;

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
#ifndef WASTE_MEM
			if(!CVLD(returnString)) FREE(returnString);
#endif
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
	  	hv_store(RETVAL, VNAME("name"), newSVpv(name, 0), 0);
		hv_store(RETVAL, VNAME("groupList"),
			perl_ARList(ctrl,
				    (ARList *)&groupList, 
				    (ARS_fn)perl_ARInternalId,
				    sizeof(ARInternalId)), 0);
		hv_store(RETVAL, VNAME("command")  , newSVpv(command, 0), 0);
		hv_store(RETVAL, VNAME("timestamp"), newSViv(timestamp), 0);
		hv_store(RETVAL, VNAME("owner")    , newSVpv(owner, 0), 0);
		hv_store(RETVAL, VNAME("lastChanged"), newSVpv(lastChanged, 0), 0);
	        if(helpText)
		   hv_store(RETVAL, VNAME("helpText") , newSVpv(helpText, 0), 0);
	        if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
			ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
			ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
			if (!ARError(ret, status)) {
				hv_store(RETVAL, VNAME("changeDiary"),
					perl_ARList(ctrl, (ARList *)&diaryList,
					(ARS_fn)perl_diary,
					sizeof(ARDiaryStruct)), 0);
				FreeARDiaryList(&diaryList, FALSE);
			}
	        }
#ifndef WASTE_MEM
		FreeARInternalIdList(&groupList, FALSE);
		if(!CVLD(helpText)){
		  FREE(helpText);
		}
		if(!CVLD(changeDiary)){
		  FREE(changeDiary);
		}
#endif
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
	  ARNameType           schema;
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
	     hv_store(RETVAL, VNAME("name"), newSVpv(name, 0), 0);
#if AR_EXPORT_VERSION >= 5
		hv_store(RETVAL, VNAME("schemaList"), /* WorkflowConnectStruct */
			perl_ARNameList(ctrl, schemaList.u.schemaList), 0);
		hv_store(RETVAL, VNAME("objPropList"),
			perl_ARPropList(ctrl, &objPropList), 0);
#else
	     hv_store(RETVAL, VNAME("schema"), newSVpv(schema, 0), 0);
#endif
	     hv_store(RETVAL, VNAME("enable"), newSViv(enable), 0);
	     hv_store(RETVAL, VNAME("timestamp"), newSViv(timestamp), 0);
	     if(helpText)
	        hv_store(RETVAL, VNAME("helpText"), newSVpv(helpText, 0), 0);
	     hv_store(RETVAL, VNAME("owner"), newSVpv(owner, 0), 0);
	     hv_store(RETVAL, VNAME("lastChanged"), newSVpv(lastChanged, 0), 0);
	     if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL, VNAME("changeDiary"),
				perl_ARList(ctrl, 
				(ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	     }
	     ref = newSViv(0);
	     sv_setref_pv(ref, "ARQualifierStructPtr", (void *)query);
	     hv_store(RETVAL, VNAME("query"), ref, 0);
	     hv_store(RETVAL, VNAME("actionList"),
			perl_ARList(ctrl,
				(ARList *)&actionList,
				(ARS_fn)perl_ARFilterActionStruct,
				sizeof(ARFilterActionStruct)), 0);
#if AR_EXPORT_VERSION >= 3
	     hv_store(RETVAL, VNAME("elseList"), 
			perl_ARList( ctrl,
				(ARList *)&elseList,
				(ARS_fn)perl_ARFilterActionStruct,
				sizeof(ARFilterActionStruct)), 0);
#endif
	     hv_store(RETVAL, VNAME("TmType"), 
			newSViv(escalationTm.escalationTmType), 0);
	     switch(escalationTm.escalationTmType) {
	     case AR_ESCALATION_TYPE_INTERVAL:
		hv_store(RETVAL, VNAME("TmInterval"), 
			newSViv(escalationTm.u.interval), 0);
		break;
	     case AR_ESCALATION_TYPE_TIMEMARK:
		hv_store(RETVAL, VNAME("TmMonthDayMask"),
			newSViv(escalationTm.u.date.monthday), 0);
		hv_store(RETVAL, VNAME("TmWeekDayMask"),
			newSViv(escalationTm.u.date.weekday), 0);
		hv_store(RETVAL, VNAME("TmHourMask"),
			newSViv(escalationTm.u.date.hourmask), 0);
		hv_store(RETVAL, VNAME("TmMinute"),
			newSViv(escalationTm.u.date.minute), 0);
		break;
	     }
#ifndef WASTE_MEM
	     FreeARFilterActionList(&actionList, FALSE);
#if AR_EXPORT_VERSION >= 3
	     FreeARFilterActionList(&elseList, FALSE);
#endif
	     if(!CVLD(helpText)){
	       FREE(helpText);
	     }
	     if(!CVLD(changeDiary)){
	       FREE(changeDiary);
	     }
#endif
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
	  unsigned int rlist[] = {AR_FULLTEXTINFO_CASE_SENSITIVE_SRCH,
			 	  AR_FULLTEXTINFO_COLLECTION_DIR,
			 	  AR_FULLTEXTINFO_FTS_MATCH_OP,
			 	  AR_FULLTEXTINFO_STATE,
			 	  AR_FULLTEXTINFO_STOPWORD};

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
	     int i, v;
	     AV *a = newAV();

	     for(i = 0; i < fullTextInfo.numItems ; i++) {
	        switch(fullTextInfo.fullTextInfoList[i].infoType) {
		case AR_FULLTEXTINFO_STOPWORD:
		   for(v = 0; v < fullTextInfo.fullTextInfoList[i].u.valueList.numItems ; v++) {
		      av_push(a, perl_ARValueStruct(ctrl,
			&(fullTextInfo.fullTextInfoList[i].u.valueList.valueList[v])));
		   }
		   hv_store(RETVAL, VNAME("StopWords"), newRV((SV *)a), 0);
		   break;
		case AR_FULLTEXTINFO_CASE_SENSITIVE_SRCH:
		   hv_store(RETVAL, VNAME("CaseSensitive"),
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_COLLECTION_DIR:
		   hv_store(RETVAL, VNAME("CollectionDir"),
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_FTS_MATCH_OP:
		   hv_store(RETVAL, VNAME("MatchOp"),
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		case AR_FULLTEXTINFO_STATE:
		   hv_store(RETVAL, VNAME("State"),
			    perl_ARValueStruct(ctrl,
				&(fullTextInfo.fullTextInfoList[i].u.value)), 0);
		   break;
		}
	     }
#ifndef WASTE_MEM
             FreeARFullTextInfoList(&fullTextInfo, FALSE);
#endif
	  }
	}
	OUTPUT:
	RETVAL

HV *
ars_GetListGroup(ctrl, userName=NULL)
	ARControlStruct *	ctrl
	char *			userName
	CODE:
	{
	  ARStatusList    status;
	  ARGroupInfoList groupList;
	  int             i, v, ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = newHV();
	  ret = ARGetListGroup(ctrl, userName, &groupList, &status);
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
		av_push(gnameListList, newRV((SV *)gnameList));
	    }

	    hv_store(RETVAL, VNAME("groupId"), newRV((SV *)gidList), 0);
	    hv_store(RETVAL, VNAME("groupType"), newRV((SV *)gtypeList), 0);
	    hv_store(RETVAL, VNAME("groupName"), newRV((SV *)gnameListList), 0);
#ifndef WASTE_MEM
	    FreeARGroupInfoList(&groupList, FALSE);
#endif
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
	     int  row, col;
	     AV  *ra = newAV(), *ca;
	     RETVAL = newHV();

	     hv_store(RETVAL, VNAME("numMatches"), newSViv(numMatches), 0);
	     for(row = 0; row < valueListList.numItems ; row++) {
		ca = newAV();
		for(col = 0; col < valueListList.valueListList[row].numItems;
		    col++) 
		{
		   av_push(ca, perl_ARValueStruct(ctrl,
			&(valueListList.valueListList[row].valueList[col])));
		}
		av_push(ra, newRV((SV *)ca));
	     }
	     hv_store(RETVAL, VNAME("rows"), newRV((SV *)ra), 0);
#ifndef WASTE_MEM
	     FreeARValueListList(&valueListList, FALSE);
#endif
	  }
#else
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "Not available in pre-2.1 ARS");
#endif
	  if(RETVAL != NULL) {
			XPUSHs(sv_2mortal(newRV((SV *)RETVAL)));
	  } else {
			XPUSHs(sv_2mortal(newSViv(0)));
	  }
	}

void
ars_GetListUser(ctrl, userListType=AR_USER_LIST_MYSELF)
	ARControlStruct *	ctrl
	unsigned int		userListType
	PPCODE:
	{
	  ARStatusList   status;
	  ARUserInfoList userList;
	  int            ret;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetListUser(ctrl, userListType, &userList, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	     int i, j;
	     for(i = 0; i < userList.numItems; i++) {
	        HV *userInfo           = newHV();
		AV *licenseTag         = newAV(),
		   *licenseType        = newAV(),
		   *currentLicenseType = newAV();

	        hv_store(userInfo, VNAME("userName"), 
			newSVpv(userList.userList[i].userName, 0), 0);
		hv_store(userInfo, VNAME("connectTime"),
			newSViv(userList.userList[i].connectTime), 0);
		hv_store(userInfo, VNAME("lastAccess"),
			newSViv(userList.userList[i].lastAccess), 0);
		hv_store(userInfo, VNAME("defaultNotifyMech"),
			newSViv(userList.userList[i].defaultNotifyMech), 0);
		hv_store(userInfo, VNAME("emailAddr"),
			newSVpv(userList.userList[i].emailAddr, 0), 0);

		for(j = 0; j < userList.userList[i].licenseInfo.numItems; j++) {
		   av_push(licenseTag, newSViv(userList.userList[i].licenseInfo.licenseList[j].licenseTag));
		   av_push(licenseType, newSViv(userList.userList[i].licenseInfo.licenseList[j].licenseType));
		   av_push(currentLicenseType, newSViv(userList.userList[i].licenseInfo.licenseList[j].currentLicenseType));
		}
		hv_store(userInfo, VNAME("licenseTag"), newRV((SV *)licenseTag), 0);
		hv_store(userInfo, VNAME("licenseType"), newRV((SV *)licenseType), 0);
		hv_store(userInfo, VNAME("currentLicenseType"), newRV((SV *)currentLicenseType), 0);
	        XPUSHs(sv_2mortal(newRV((SV *)userInfo)));
	     }
#ifndef WASTE_MEM
	     FreeARUserInfoList(&userList, FALSE);
#endif
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
	  int              ret, i;

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
#ifdef WASTE_MEM
	  FreeARInternalIdList(&idList, FALSE);
#endif
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
					sprintf(buf, "unknown serverInfo value: %u", SvIV(ST(i)));
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
	  int                     ret, i, count;
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
	        for(i = 0 ; i < serverInfo.numItems ; i++) {
		/* provided we have a mapping for the operation code, 
		 * push out it's translation. else push out the code itself
		 */
		   if(serverInfo.serverInfoList[i].operation <= AR_MAX_SERVER_INFO_USED) {
	  	      XPUSHs(sv_2mortal(newSVpv(ServerInfoMap[serverInfo.serverInfoList[i].operation].name, 0)));
		   } else {
		      XPUSHs(sv_2mortal(newSViv(serverInfo.serverInfoList[i].operation)));
		   }
		      XPUSHs(sv_2mortal(perl_ARValueStruct(ctrl,
			&(serverInfo.serverInfoList[i].value))));
	        }
	     }
#ifndef WASTE_MEM
	    FreeARServerInfoList(&serverInfo, FALSE);
#endif
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
	  int          i, ret;
	  ARDiaryList      diaryList;

	  RETVAL = newHV();
	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  ret = ARGetVUI(ctrl, schema, vuiId, vuiName, &dPropList, &helpText, 
			 &timestamp, owner, lastChanged, &changeDiary, &status);
#ifdef PROFILE
	  ((ars_ctrl *)ctrl)->queries++;
#endif
	  if(!ARError( ret, status)) {
	     hv_store(RETVAL, VNAME("schema"), newSVpv(schema, 0), 0);
	     hv_store(RETVAL, VNAME("vuiId"), newSViv(vuiId), 0);
	     hv_store(RETVAL, VNAME("vuiName"), newSVpv(vuiName, 0), 0);
	     hv_store(RETVAL, VNAME("owner"), newSVpv(owner, 0), 0);
	     if(helpText)
	        hv_store(RETVAL, VNAME("helpText"), newSVpv(helpText, 0), 0);
	     hv_store(RETVAL, VNAME("lastChanged"), newSVpv(lastChanged, 0), 0);
	     if (changeDiary) {
#if AR_EXPORT_VERSION >= 4
		ret = ARDecodeDiary(ctrl, changeDiary, &diaryList, &status);
#else
		ret = ARDecodeDiary(changeDiary, &diaryList, &status);
#endif
		if (!ARError(ret, status)) {
			hv_store(RETVAL, VNAME("changeDiary"),
				perl_ARList(ctrl,
				(ARList *)&diaryList,
				(ARS_fn)perl_diary,
				sizeof(ARDiaryStruct)), 0);
			FreeARDiaryList(&diaryList, FALSE);
		}
	     }
	     hv_store(RETVAL, VNAME("timestamp"), newSViv(timestamp), 0);
	     hv_store(RETVAL, VNAME("props"),
		perl_ARList( ctrl,
			    (ARList *)&dPropList,
			    (ARS_fn)perl_ARPropStruct,
			    sizeof(ARPropStruct)), 0);
	  }
#ifndef WASTE_MEM
	  FreeARPropList(&dPropList, FALSE);
	  if(!CVLD(helpText)){
	    FREE(helpText);
	  }
	  if(!CVLD(changeDiary)){
	    FREE(changeDiary);
	  }
#endif
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
	  int               rv, ret;
	  ARNameType        name;
	  unsigned int      refreshCode;
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
		if(hv_exists(aeDef, VNAME("name")) &&
		   hv_exists(aeDef, VNAME("groupList")) &&
		   hv_exists(aeDef, VNAME("command"))) {

		   rv += strcpyHVal( aeDef, "name", name, sizeof(ARNameType));
		   rv += strmakHVal( aeDef, "command", &command);
		   if(hv_exists(aeDef, VNAME("helpText"))) 
			rv += strmakHVal( aeDef, "helpText", &helpText);
		   if(hv_exists(aeDef, VNAME("changeDiary"))) 
			rv += strmakHVal( aeDef, "changeDiary", &changeDiary);
		   if(hv_exists(aeDef, VNAME("owner"))) 
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
	  int                    ret = 0, i, rv = 0;
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
		int rv2;
		SV **qhv = hv_fetch(alDef, VNAME("query"), 0);

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

		if(hv_exists(alDef, VNAME("owner")))
			rv += strcpyHVal( alDef, "owner", owner, 
					sizeof(ARNameType));
		else
			strncpy(owner, ctrl->user, sizeof(ARNameType));

		/* these two are optional, so if the calls return warnings
		 * it probably indicates that the hash keys don't exist and
		 * we'll ignore it unless an actual failure code is returned.
		 */

		if(hv_exists(alDef, VNAME("changeDiary")))
			rv += strmakHVal( alDef, "changeDiary", &changeDiary);
		if(hv_exists(alDef, VNAME("helpText")))
			rv += strmakHVal( alDef, "helpText", &helpText);

		/* now handle the action & else (3.x) lists */

		rv += rev_ARActiveLinkActionList(ctrl, alDef, "actionList", 
						&actionList);
#if AR_EXPORT_VERSION >= 5
		if(hv_exists(alDef, VNAME("objPropList")))
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
#ifndef WASTE_MEM
	  if(!CVLD(helpText)){
	    FREE(helpText);
	  }
	  if(!CVLD(changeDiary)){
	    FREE(changeDiary);
	  }
	  safefree(groupList.internalIdList);
	  safefree(actionList.actionList);
#if AR_EXPORT_VERSION >= 3
	  safefree(elseList.actionList);
#else /* 2.x */
	  safefree(displayList.displayList);
#endif
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
	  int              a, i, c = (items - 3) / 2, j;
	  ARFieldValueList fieldList;
	  ARStatusList     status;
	  int              ret;
	  unsigned int     dataType;
	  AREntryIdType    entryId;

	  (void) ARError_reset();
	  Zero(&status, 1,ARStatusList);
	  RETVAL = "";

	  if ((items - 3) % 2 || c < 1) {
	  	(void) ARError_add( AR_RETURN_ERROR, AP_ERR_BAD_ARGS);
	  	goto merge_entry_exit;
	  }

	  fieldList.numItems = c;
	  Newz(777, fieldList.fieldValueList, c, ARFieldValueStruct);

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
				safefree(fieldList.fieldValueList);
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

	  safefree(fieldList.fieldValueList);

	merge_entry_end:;
	merge_entry_exit:;
	}
	OUTPUT:
	RETVAL

###################################################
# NT (Notifier) ROUTINES
#

int
ars_NTInitializationClient()
        CODE:
        {
          NTStatusList status;
          int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
          RETVAL = 0;
#if AR_EXPORT_VERSION < 3
          ret = NTInitializationClient(&status);
          if(!NTError( ret, status)) {
            RETVAL = 1;
          }
#else
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "NTInitializationClient() is only available in ARS2.x");
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

	  (void) ARError_reset();
	  RETVAL = 0;
	  Zero(&status, 1,NTStatusList);
#if AR_EXPORT_VERSION < 3
	  if(user && password && filename) {
	    ret = NTDeregisterClient(user, password, filename, &status);
	    if(!NTError( ret, status)) {
	      RETVAL = 1;
	    }
	  }
#else
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "NTDeregisterClient() is only available in ARS2.x");
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

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  RETVAL = 0;
#if AR_EXPORT_VERSION < 3
	  if(user && password && filename) {
	    ret = NTRegisterClient(user, password, filename, &status);
	    if(!NTError( ret, status)) {
		RETVAL = 1;
	    }
	  }
#else
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "NTRegisterClient() is only available in ARS2.x");
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

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  RETVAL = 0;
#if AR_EXPORT_VERSION < 3
	  ret = NTTerminationClient(&status);
	  if(!NTError( ret, status)) {
	    RETVAL = 1;
	  }
#else
	  (void) ARError_add( AR_RETURN_ERROR, AP_ERR_DEPRECATED, "NTTerminationClient() is only available in ARS2.x");
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
	  int          ret;
#if AR_EXPORT_VERSION < 3
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
#else
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
			ret = NTRegisterServer(serverHost, user, password, clientCommunication, clientPort, protocol, multipleClients, &status);
			if(!NTError(ret, status)) {
				RETVAL = 1;
			}
		} else 
			(void) ARError_add(AR_RETURN_ERROR, AP_ERR_INV_ARGS,
				"protocol arg invalid.");
	  } else 
		(void) ARError_add(AR_RETURN_ERROR, AP_ERR_INV_ARGS,
				"clientCommunication arg invalid.");
#endif
	ntregserver_end:;
	}
	OUTPUT:
	RETVAL

int 
ars_NTTerminationServer()
	CODE:
	{
	 int ret;
	 NTStatusList status;

	 (void) ARError_reset();
	 Zero(&status, 1, NTStatusList);
	 RETVAL = 0;
	 ret = NTTerminationServer(&status);
	 if(!NTError( ret, status)) {
	   RETVAL = 1;
	 }
	}
	OUTPUT:
	RETVAL

int
ars_NTDeregisterServer(serverHost, user, password, port=0)
	char *		serverHost
	char *		user
	char *		password
	NTPortAddr	port
	CODE:
	{
	 int ret;
	 NTStatusList status;

	 (void) ARError_reset();
	 Zero(&status, 1, NTStatusList);
	 RETVAL = 0; /* assume error */
	 if(serverHost && user && password) {
	    ret = NTDeregisterServer(serverHost, user, password,
#if AR_EXPORT_VERSION >= 4
			&port, 
#endif
			&status);
	    if(!NTError( ret, status)) {
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
	  NTStatusList     status;
	  int              ret, i;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  ret = NTGetListServer(&serverList, &status);
	  if(!NTError( ret, status)) {
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
	  int          ret;

	  (void) ARError_reset();
	  Zero(&status, 1, NTStatusList);
	  RETVAL = 0; /* error */
	  ret = NTInitializationServer(&status);
	  if(!NTError( ret, status)) {
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
# if AR_EXPORT_VERSION > 4
	  safefree(ctrl);
# endif /* AR_EXPORT_VERSION */
#endif
	}

MODULE = ARS		PACKAGE = ARQualifierStructPtr

void
DESTROY(qual)
	ARQualifierStruct *	qual
	CODE:
	{
#ifndef WASTE_MEM
	  safefree(qual);
#endif
	}
