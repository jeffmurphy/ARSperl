/*
$Header: /cvsroot/arsperl/ARSperl/supportrev.c,v 1.5 1997/10/07 14:29:44 jcmurphy Exp $

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

$Log: supportrev.c,v $
Revision 1.5  1997/10/07 14:29:44  jcmurphy
1.51

Revision 1.4  1997/10/06 13:39:40  jcmurphy
fix up some compilation warnings

Revision 1.3  1997/10/02 15:40:00  jcmurphy
1.50beta

Revision 1.2  1997/09/04 00:20:51  jcmurphy
*** empty log message ***

Revision 1.1  1997/08/05 21:21:17  jcmurphy
Initial revision


*/

/* NAME
 *   supportrev.c
 *
 * DESCRIPTION
 *   this file contains routines that are useful for translating 
 *   (ars)perl "data structures" (if you will) back into ARS C data structures.
 *   since we'll be working on converting user-supplied data (versus server
 *   supplied data) about half of all the code in this file is error checking
 *   code.
 */

#define __supportrev_c_

#include "support.h"
#include "supportrev.h"

static int rev_ARActiveLinkActionList_helper(HV *h, 
					     ARActiveLinkActionList *al, 
					     int idx);
static int rev_ARDisplayStruct_helper(HV *h, char *k, ARDisplayStruct *d);
static int rev_ARValueStructStr2Type(char *type, unsigned int *n);
static int rev_ARValueStructKW2KN(char *keyword, unsigned int *n);
static int rev_ARValueStructDiary(HV *h, char *k, char **d);
static int rev_ARAssignFieldStruct_helper(HV *h, ARAssignFieldStruct *m);
static int rev_ARAssignFieldStructStr2NMO(char *s, unsigned int *nmo);
static int rev_ARAssignFieldStructStr2MMO(char *s, unsigned int *mmo);
static int rev_ARStatHistoryValue_helper(HV *h, ARStatHistoryValue *s);
static int rev_ARArithOpAssignStruct_helper(HV *h, ARArithOpAssignStruct *s);
static int rev_ARArithOpAssignStructStr2OP(char *c, unsigned int *o);
static int rev_ARFunctionAssignStructStr2FCODE(char *c, unsigned int *o);
static int rev_ARAssignStruct_helper(HV *h, ARAssignStruct *m);
static int rev_ARActiveLinkMacroStruct_helper(HV *h, 
					      ARActiveLinkMacroStruct *m);
#if AR_EXPORT_VERSION >= 3
static int rev_ARByteListStr2Type(char *ts, unsigned long *tv);
static int rev_ARCoordList_helper(HV *h, ARCoordList *m, int idx);
static int rev_ARPropList_helper(HV *h, ARPropList *m, int idx);
#endif

/* ROUTINE
 *   strcpyHVal(hash, key, buffer, bufferLen)
 *
 * DESCRIPTION
 *   given a hash (HV *), a key, a pre-allocated buffer and
 *   the length of that buffer, retrieve the value from the hash
 *   (assuming it is a string value [PV]) and place it in the buffer.
 * 
 * NOTES
 *   if value of hash is truncate at len bytes if it exceeds len.
 *   b, once filled in, will be null terminated.
 *
 * RETURNS
 *    0 on success
 *   -1 on failure and pushes some info in the error hash
 *   -2 on warning and pushes some info into the error hash
 *
 */

int
strcpyHVal(HV *h, char *k, char *b, int len)
{
  SV **val;

  if(! b) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"strcpyHVal: char buffer parameter is NULL");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {
	if(SvPOK(*val)) {
	  strncpy(b, SvPV(*val, na), len);
	  b[len] = 0;
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "strcpyHVal: hash value is not a string");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "strcpyHVal: hv_fetch returned null. key:");
	ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE, 
		    k ? k : "n/a");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "strcpyHVal: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"strcpyHVal: first argument is not a hash");
  return -1;
}

/* same as above routine, but it will allocate (malloc()) the appropriate
 * amount of memory. calling routine is responsible for free()ing it later on
 */

int
strmakHVal(HV *h, char *k, char **b)
{
  /* b must be a pointer to a pointer */

  if(! b && ! *b) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"strmakHVal: char buffer parameter is invalid");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV     **val = hv_fetch(h, VNAME(k), 0);
      STRLEN   len;

      if(val && *val) {
	if(SvPOK(*val)) {
	  char *pvchar = SvPV(*val, len);
	  *b = MALLOCNN(SvCUR(*val) + 1);
	  strcpy(*b, pvchar);
	  *(b+len) = 0;
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "strmakHVal: hash value is not a string");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "strmakHVal: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "strmakHVal: key doesn't exist. key:");
      ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE, 
		  k ? k : "n/a");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"strmakHVal: first argument is not a hash");
  return -1;
}

/* ROUTINE
 *   intcpyHVal(hash, key, buffer)
 *
 * DESCRIPTION
 *   given a hash (HV *), a key, and a pre-allocated buffer,
 *   retrieve the value from the hash
 *   (assuming it is a integer value [IV]) and place it in the buffer.
 * 
 * RETURNS
 *    0 on success
 *   -1 on failure and pushes some info in the error hash
 *   -2 on warning and pushes some info into the error hash
 */

int
intcpyHVal(HV *h, char *k, int *b)
{
  SV **val;

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {
	if(SvIOK(*val)) {
	  *b = (int)SvIV(*val);
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "intcpyHVal: hash value is not an integer");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "intcpyHVal: hv_fetch returned null");
	return -2;
      }
    } else 
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "intcpyHVal: key doesn't exist");
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"intcpyHVal: first argument is not a hash");
  return -1;
}

/* ROUTINE
 *   uintcpyHVal(hash, key, buffer)
 *
 * DESCRIPTION
 *   given a hash (HV *), a key, and a pre-allocated buffer,
 *   retrieve the value from the hash
 *   (assuming it is a integer value [IV]) and place it in the buffer.
 * 
 * RETURNS
 *    0 on success
 *   -1 on failure and pushes some info in the error hash
 *   -2 on warning and pushes some info into the error hash
 */

int
uintcpyHVal(HV *h, char *k, unsigned int *b)
{
  SV **val;

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {
	if(SvIOK(*val)) {
	  *b = (unsigned int)SvIV(*val);
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "uintcpyHVal: hash value is not an integer");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "uintcpyHVal: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "uintcpyHVal: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"uintcpyHVal: first argument is not a hash");
  return -1;
}

/* ROUTINE
 *   longcpyHVal(hash, key, buffer)
 *
 * DESCRIPTION
 *   given a hash (HV *), a key, and a pre-allocated buffer,
 *   retrieve the value from the hash
 *   (assuming it is a integer value [IV]) and place it in the buffer.
 * 
 * RETURNS
 *    0 on success
 *   -1 on failure and pushes some info in the error hash
 *   -2 on warning and pushes some info into the error hash
 */

int
longcpyHVal(HV *h, char *k, long *b)
{
  SV **val;

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {
	if(SvIOK(*val)) {
	  *b = (long)SvIV(*val);
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "longcpyHVal: hash value is not an integer");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "longcpyHVal: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "longcpyHVal: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"longcpyHVal: first argument is not a hash");
  return -1;
}

int
ulongcpyHVal(HV *h, char *k, unsigned long *b)
{
  SV **val;

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {
	if(SvIOK(*val)) {
	  *b = (unsigned long)SvIV(*val);
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "ulongcpyHVal: hash value is not an integer");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "ulongcpyHVal: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "ulongcpyHVal: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"ulongcpyHVal: first argument is not a hash");
  return -1;
}

/* ROUTINE
 *   rev_ARDisplayList(hash, key, displayStruct)
 *
 * DESCRIPTION
 *   Given a hash and key whose corresponding value is
 *   what perl_ARList() constructed, deconstruct it back
 *   into a displayList.
 *
 *   perl_ARList should have constructed a list of hash references
 *   each containing keys: displayTag, x, y, option, label and type.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARDisplayList(HV *h, char *k, ARDisplayList *d)
{
  SV **val;
  int  i;

  if(! d) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARDisplayList: DisplayList param is NULL");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be an array reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVAV) {
	  AV *ar = (AV *)SvRV((SV *)*val);

	  /* allocate space for display structure list */

	  d->numItems = av_len(ar)+1;
	  if(d->numItems == 0)
	    return 0; /* nothing to do */
	  d->displayList = MALLOCNN(sizeof(ARDisplayStruct) * d->numItems);

	  /* iterate over the array, grabbing each hash reference out of it
	   * and passing that to a helper routine to fill in the DisplayList
	   * structure 
	   */

	  for(i = 0 ; i <= av_len(ar) ; i++) {
	    SV **av_hv = av_fetch(ar, i, 0);

	    if(av_hv && *av_hv && (SvTYPE(SvRV(*av_hv)) == SVt_PVHV)) {
	      if(rev_ARDisplayStruct((HV *)SvRV(*av_hv), &(d->displayList[i])) != 0)
		return -1;
	    } else 
	      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
			  "rev_ARDisplayList: inner array value is not a hash reference");
	  }
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARDisplayList: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARDisplayList: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARDisplayList: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARDisplayList: first argument is not a hash");
  return -1;
}

/* ROUTINE
 *   rev_ARDisplayStruct_helper(hv, key, displayStruct)
 *
 * DESCRIPTION
 *   a helper routine (wrapper)
 */

static int
rev_ARDisplayStruct_helper(HV *h, char *k, ARDisplayStruct *d) 
{
  SV **val;
  int  i;

  if(! d) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARDisplayStruct_helper: DisplayList param is NULL");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be an hash reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVHV) {
	  if(rev_ARDisplayStruct((HV *)SvRV(*val), d) != 0)
	    return -1;
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARDisplayStruct_helper: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARDisplayStruct_helper: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARDisplayStruct_helper: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARDisplayStruct_helper: first argument is not a hash");
  return -1;
}

/* ROUTINE
 *   rev_ARDisplayStruct(hv, displayStruct)
 *
 * DESCRIPTION
 *   given a hash that contains displaystruct keys
 *   and an empty (preallocated) displaystruct, fill
 *   in the display struct.
 */

int 
rev_ARDisplayStruct(HV *h, ARDisplayStruct *d)
{
  int  rv = 0, rv2 = 0;
  char buf[1024];

  rv += strcpyHVal(h, "displayTag", d->displayTag, sizeof(ARNameType));
  rv += strcpyHVal(h, "label", d->label, sizeof(ARNameType));
  rv += intcpyHVal(h, "x",       &(d->x));
  rv += intcpyHVal(h, "y",       &(d->y));
  rv += uintcpyHVal(h, "length",  &(d->length));
  rv += uintcpyHVal(h, "numRows", &(d->numRows));

  /* variables that need some decoding before we store them */

  /* "option" will be either "VISIBLE" or "HIDDEN"
   *  default: Visible
   */

  if((rv2 = strcpyHVal(h, "option", buf, sizeof(buf))) == 0) {
    if(strncasecmp(buf, "HIDDEN", sizeof(buf)) == 0) 
      d->option = AR_DISPLAY_OPT_HIDDEN;
    else 
      d->option = AR_DISPLAY_OPT_VISIBLE;
  } else 
    rv += rv2;

  /* "labelLocation" will be either "Left" or "Top"
   * default: Left
   */

  if((rv2 = strcpyHVal(h, "labelLocation", buf, sizeof(buf))) == 0) {
    if(strncasecmp(buf, "Top", sizeof(buf)) == 0)
      d->labelLocation = AR_DISPLAY_LABEL_TOP;
    else
      d->labelLocation = AR_DISPLAY_LABEL_LEFT;
  } else
    rv += rv2;

  /* "type" will be one of: NONE, TEXT, NUMTEXT, CHECKBOX, CHOICE, BUTTON
   * default: NONE
   */

  if((rv2 = strcpyHVal(h, "type", buf, sizeof(buf))) == 0) {
    if(strncasecmp(buf, "TEXT", sizeof(buf)) == 0)
      d->type = AR_DISPLAY_TYPE_TEXT;
    else if(strncasecmp(buf, "NUMTEXT", sizeof(buf)) == 0)
      d->type = AR_DISPLAY_TYPE_NUMTEXT;
    else if(strncasecmp(buf, "CHECKBOX", sizeof(buf)) == 0)
      d->type = AR_DISPLAY_TYPE_CHECKBOX;
    else if(strncasecmp(buf, "CHOICE", sizeof(buf)) == 0)
      d->type = AR_DISPLAY_TYPE_CHOICE;
    else if(strncasecmp(buf, "BUTTON", sizeof(buf)) == 0)
      d->type = AR_DISPLAY_TYPE_BUTTON;
    else
      d->type = AR_DISPLAY_TYPE_NONE;
  } else
    rv += rv2;

  return rv;
}

/* ROUTINE
 *   rev_ARInternalIdList(hv, key, idliststruct)
 *
 * DESCRIPTION
 *   given a hash, a key and an empty idliststruct, 
 *   pull out the hash value and populate the structure.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARInternalIdList(HV *h, char *k, ARInternalIdList *il)
{

  if(! il || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARInternalIdList: required param is NULL");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be an array reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVAV) {
	  AV *ar = (AV *)SvRV((SV *)*val);
	  int i;

	  /* allocate space for display structure list */

	  il->numItems = av_len(ar)+1;
	  if(il->numItems == 0)
	    return 0; /* nothing to do */
	  il->internalIdList = MALLOCNN(sizeof(ARInternalId) * il->numItems);

	  /* iterate over the array, grabbing each integer out of it and
	   * placing into the idlist.
	   */

	  for(i = 0 ; i <= av_len(ar) ; i++) {
	    SV **aval = av_fetch(ar, i, 0);
	    if(aval && *aval && SvIOK(*aval)) {
	      il->internalIdList[i] = SvIV(*aval);
	    } else {
	      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
			  "rev_ARInternalIdList: array value is not an integer.");
	      return -1;
	    }
	  }
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARInternalIdList: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARInternalIdList: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARInternalIdList: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARInternalIdList: first argument is not a hash");
  return -1;
}

/* ROUTINE
 *   rev_ARActiveLinkActionList(hv, key, actionliststruct)
 *
 * DESCRIPTION
 *   given a hash, a key and an empty actionlist, 
 *   pull out the hash value and populate the structure.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARActiveLinkActionList(HV *h, char *k, ARActiveLinkActionList *al)
{
  SV **val;
  int  i;

  if(! al) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARActiveLinkActionList: DisplayList param is NULL");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be an array reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVAV) {
	  AV *ar = (AV *)SvRV((SV *)*val);

	  /* allocate space for action structure list */

	  al->numItems = av_len(ar)+1;
	  if(al->numItems == 0)
	    return 0; /* nothing to do */

	  al->actionList = MALLOCNN(sizeof(ARActiveLinkActionStruct) * al->numItems);

	  /* iterate over the array, grabbing each hash reference out of it
	   * and passing that to a helper routine to fill in the ActionList
	   * structure. one action per array item.
	   */

	  for(i = 0 ; i <= av_len(ar) ; i++) {
	    SV **av_hv = av_fetch(ar, i, 0);

	    if(av_hv && *av_hv && (SvTYPE(SvRV(*av_hv)) == SVt_PVHV)) {
	      if(rev_ARActiveLinkActionList_helper((HV *)SvRV(*av_hv), al, i) != 0)
		return -1;
	    } else 
	      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
			  "rev_ARActiveLinkActionList: inner array value is not a hash reference");
	  }
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARActiveLinkActionList: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARActiveLinkActionList: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARActiveLinkActionList: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARActiveLinkActionList: first argument is not a hash");
  return -1;
}

/* helper routine to above routine. does the actual data copying once 
 * main routine has verified that everything is OK.
 */

static int
rev_ARActiveLinkActionList_helper(HV *h, ARActiveLinkActionList *al, int idx)
{
  int  rv = 0, rv2 = 0;
  char buf[1024];

  /* test each has value in turn, first one that is defined, copy in 
   * and return. DDE: not implemented.
   */

  if(hv_exists(h, VNAME("process"))) {
    al->actionList[idx].action = AR_ACTIVE_LINK_ACTION_PROCESS;
    rv += strmakHVal(h, "process", &(al->actionList[idx].u.process));
  }  
  else if(hv_exists(h, VNAME("macro"))) {
    al->actionList[idx].action = AR_ACTIVE_LINK_ACTION_MACRO;
    rv += rev_ARActiveLinkMacroStruct(h, "macro", 
			    &(al->actionList[idx].u.macro));
  }
  else if(hv_exists(h, VNAME("assign_fields"))) {
    al->actionList[idx].action = AR_ACTIVE_LINK_ACTION_FIELDS;
    rv += rev_ARFieldAssignList(h, "assign_fields",
			    &(al->actionList[idx].u.fieldList));
  }
  else if(hv_exists(h, VNAME("message"))) {
    al->actionList[idx].action = AR_ACTIVE_LINK_ACTION_MESSAGE;
    rv += rev_ARStatusStruct(h, "message",
			    &(al->actionList[idx].u.message));
  }
  else if(hv_exists(h, VNAME("characteristics"))) {
    al->actionList[idx].action = AR_ACTIVE_LINK_ACTION_SET_CHAR;
    rv += rev_ARFieldCharacteristics(h, "characteristics",
			    &(al->actionList[idx].u.characteristics));
  }
  else if(hv_exists(h, VNAME("none"))) {
    al->actionList[idx].action = AR_ACTIVE_LINK_ACTION_NONE;
  }
  else {
    rv = -1;
  }

  return rv;
}

/* ROUTINE
 *   rev_ARFieldAssignList(hash, key, assignList)
 *
 * DESCRIPTION
 *   the hash value is an array of hashes. interate over them
 *   and fill in the assignList structure.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARFieldAssignList(HV *h, char *k, ARFieldAssignList *m)
{
  SV **val;
  int  i;

  if(! m) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARFieldAssignList: FieldAssignList param is NULL");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be an array reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVAV) {
	  AV *ar = (AV *)SvRV((SV *)*val);

	  /* allocate space for field assign structure list */

	  m->numItems        = av_len(ar)+1;
	  if(m->numItems == 0)
	    return 0; /* nothing to do */
	  m->fieldAssignList = MALLOCNN(sizeof(ARFieldAssignStruct) * m->numItems);

	  /* iterate over the array, grabbing each hash reference out of it
	   * and passing that to a helper routine to fill in the ActionList
	   * structure. one action per array item.
	   */

	  for(i = 0 ; i <= av_len(ar) ; i++) {
	    SV **av_hv = av_fetch(ar, i, 0);

	    if(av_hv && *av_hv && (SvTYPE(SvRV(*av_hv)) == SVt_PVHV)) {
	      if(rev_ARAssignList_helper((HV *)SvRV(*av_hv), m, i) != 0)
		return -1;
	    } else 
	      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
			  "rev_ARFieldAssignList: inner array value is not a hash reference");
	  }
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARFieldAssignList: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARFieldAssignList: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARFieldAssignList: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARFieldAssignList: first argument is not a hash");
  return -1;
}

int
rev_ARAssignList_helper(HV *h, ARFieldAssignList *m, int i) 
{
  int rv = 0;

  rv += ulongcpyHVal(h, "fieldId", &(m->fieldAssignList[i].fieldId));
  rv += rev_ARAssignStruct(h, "assignment", &(m->fieldAssignList[i].assignment));

  return rv;
}

int
rev_ARAssignStruct(HV *h, char *k, ARAssignStruct *m)
{
  if(! m || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARFunctionAssignStruct: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be a hash reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVHV) {
	  HV  *a = (HV *)SvRV((SV *)*val);
	  return rev_ARAssignStruct_helper(a, m);
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARFunctionAssignStruct: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARFunctionAssignStruct: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARFunctionAssignStruct: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARFunctionAssignStruct: first argument is not a hash");
  return -1;  
}

static int
rev_ARAssignStruct_helper(HV *h, ARAssignStruct *m)
{
  int  rv = 0, rv2 = 0;

  /* test each key in turn, first one that is defined, copy in 
   * and return. DDE: not implemented.
   */

  if(hv_exists(h, VNAME("process"))) {
    m->assignType = AR_ASSIGN_TYPE_PROCESS;
    rv += strmakHVal(h, "process", &(m->u.process));
  }  
  else if(hv_exists(h, VNAME("value"))) {
    m->assignType = AR_ASSIGN_TYPE_VALUE;
    rv += rev_ARValueStruct(h, "value", "valueType", &(m->u.value));
  }

  /* note. the below union members are pointers. so we will
   * allocate space for them and then call the subroutine
   * to populate them with data. (with the exception of 'process'
   * whose subroutine will do the allocating for us)
   */

  else if(hv_exists(h, VNAME("field"))) {
    m->assignType = AR_ASSIGN_TYPE_FIELD;
    m->u.field = MALLOCNN(sizeof(ARAssignFieldStruct));
    rv += rev_ARAssignFieldStruct(h, "field", m->u.field);
  }
  else if(hv_exists(h, VNAME("arith"))) {
    m->assignType = AR_ASSIGN_TYPE_ARITH;
    m->u.arithOp = MALLOCNN(sizeof(ARArithOpAssignStruct));
    rv += rev_ARArithOpAssignStruct(h, "arith", m->u.arithOp);
  }
  else if(hv_exists(h, VNAME("function"))) {
    m->assignType = AR_ASSIGN_TYPE_FUNCTION;
    m->u.function = MALLOCNN(sizeof(ARFunctionAssignStruct));
    rv += rev_ARFunctionAssignStruct(h, "function", m->u.function);
  }
#if AR_EXPORT_VERSION >= 3
  else if(hv_exists(h, VNAME("sql"))) {
    m->assignType = AR_ASSIGN_TYPE_SQL;
    m->u.sql = MALLOCNN(sizeof(ARAssignSQLStruct));
    rv += rev_ARAssignSQLStruct(h, "sql", m->u.sql);
  }
#endif
  else if(hv_exists(h, VNAME("none"))) {
    m->assignType = AR_ASSIGN_TYPE_NONE;
  }
  else {
    rv = -1;
  }

  return rv;  
}

#if AR_EXPORT_VERSION >= 3
int
rev_ARAssignSQLStruct(HV *h, char *k, ARAssignSQLStruct *s)
{
  SV   **h_sv = hv_fetch(h, VNAME(k), 0);
  SV   **svp;
  HV    *hr;
  int    rv = 0;
  STRLEN len;


  /* dereference the hash key and extract it */

  if(SvROK(*h_sv) && SvTYPE(SvRV(*h_sv)) == SVt_PVHV) {
    hr = (HV *)SvRV(*h_sv);
  } else {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARAssignSQLStruct: hash key 'sql' doesn't contain a hash reference.");
    return -1;
  }

  /* make sure the hash contains the keys we need */

  if(!(hv_exists(hr, "server", 0) &&
       hv_exists(hr, "sqlCommand", 0) &&
       hv_exists(hr, "valueIndex", 0) &&
       hv_exists(hr, "noMatchOption", 0) &&
       hv_exists(hr, "multiMatchOption", 0))) {

    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARAssignSQLStruct: required hash key not found");
    return -1;
  } 

  /* copy the key values into the buffer */

  rv += strcpyHVal(hr, "server", s->server, AR_MAX_SERVER_SIZE + 1);

  svp = hv_fetch(hr, VNAME("sqlCommand"), 0);
  SvPV(*svp, len);

  rv += strcpyHVal(hr, "sqlCommand", s->sqlCommand, len); /* FIX */

  rv += uintcpyHVal(hr, "valueIndex", &(s->valueIndex));
  svp = hv_fetch(hr, VNAME("noMatchOption"), 0);
  if(svp && *svp) {
    char *c = SvPV(*svp, na);
    if(rev_ARAssignFieldStructStr2NMO(c, &(s->noMatchOption)) != 0) {
      s->noMatchOption = AR_NO_MATCH_ERROR;
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARAssignSQLStruct: unknown noMatchOption string:");
      ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE, 
		  c);
    }
  }
 
  svp = hv_fetch(hr, VNAME("multiMatchOption"), 0);
  if(svp && *svp) {
    char *c = SvPV(*svp, na);
    if(rev_ARAssignFieldStructStr2MMO(c, &(s->multiMatchOption)) != 0) {
      s->multiMatchOption = AR_MULTI_MATCH_ERROR;
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARAssignSQLStruct: unknown multiMatchOption string:");
      ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE, 
		  c);
    }
  }

  return rv;
}
#endif /* ARS 3.x */

/* ROUTINE
 *   rev_ARValueStruct(hash, value-key, type-key, valueStruct)
 *
 * DESCRIPTION
 *   given a hash that contains a key that points to a list of values
 *   and a key that contains a value and another key that describes
 *   the (ars) datatype of that value, populate the given valueStruct.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARValueStruct(HV *h, char *k, char *t, ARValueStruct *m)
{
  int    rv = 0;
  SV   **val, **type;
  char  *ts;

  if(! m || ! h || ! k || ! t) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARValueStruct: invalid (NULL) parameter");
    return -1;
  }

  /* extract the value of the key, determine what datatype it is
   * and fill in the value struct. 
   */

  val  = hv_fetch(h, VNAME(k), 0);
  type = hv_fetch(h, VNAME(t), 0);
  if(val && *val && type && *type && SvPOK(*type)) {
    char *tp = SvPV(*type, na), *vp = SvPV(*val, na);

    (void) rev_ARValueStructStr2Type(tp, &(m->dataType));
    switch(m->dataType) {
    case AR_DATA_TYPE_NULL:
      m->u.intVal = 0;
      break;
    case AR_DATA_TYPE_KEYWORD:
      if(rev_ARValueStructKW2KN(vp, &(m->u.keyNum)) == -1)
	return -1;
      break;
    case AR_DATA_TYPE_INTEGER:
      m->u.intVal = SvIV(*val);
      break;
    case AR_DATA_TYPE_REAL:
      m->u.realVal = SvNV(*val);
      break;
    case AR_DATA_TYPE_CHAR:
      if(strmakHVal(h, k, &(m->u.charVal)) == -1)
	return -1;
      break;
    case AR_DATA_TYPE_DIARY:
      if(rev_ARValueStructDiary(h, k, &(m->u.diaryVal)) == -1)
	return -1;
      break;
    case AR_DATA_TYPE_ENUM:
      m->u.enumVal = (unsigned long)SvIV(*val);
      break;
    case AR_DATA_TYPE_TIME:
      m->u.timeVal = (ARTimestamp)SvIV(*val);
      break;
    case AR_DATA_TYPE_BITMASK: 
      m->u.maskVal = (unsigned long)SvIV(*val);
      break;
#if AR_EXPORT_VERSION >= 3
    case AR_DATA_TYPE_BYTES:
      m->u.byteListVal = (ARByteList *)MALLOCNN(sizeof(ARByteList));
      if(rev_ARByteList(h, k, m->u.byteListVal) == -1)
	return -1;
      break;
    case AR_DATA_TYPE_JOIN:
      return -1; /* FIX: implement */
      break;
    case AR_DATA_TYPE_TRIM:
      return -1; /* FIX: implement */
      break;
    case AR_DATA_TYPE_CONTROL:
      return -1; /* FIX: implement */
      break;
    case AR_DATA_TYPE_COORDS:
      m->u.coordListVal = (ARCoordList *)MALLOCNN(sizeof(ARCoordList));
      if(rev_ARCoordList(h, k, m->u.coordListVal) == -1)
	return -1;
      break;
    case AR_DATA_TYPE_ULONG:
      m->u.ulongVal = (unsigned long)SvIV(*val);
      break;
#endif
    default:
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		  "rev_ARValueStruct: unknown data type:");
      ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
		  tp);
      return -2;
    }
    return 0;
  }

  ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
	      "rev_ARValueStruct: hash value(s) were invalid for keys:");
  ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE, k);
  ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE, t);
  return -2;
}

static int 
rev_ARValueStructStr2Type(char *type, unsigned int *n)
{
  int i = 0;

  if(type && *type) {
    for(i = 0; DataTypeMap[i].number != -1; i++)
      if(strncasecmp(type, VNAME(DataTypeMap[i].name)) == 0)
	break;
    if(DataTypeMap[i].number != -1) {
      *n = DataTypeMap[i].number;
      return 0;
    }
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARValueStructStr2Type: type given is unknown:");
    ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
		type);
  } else
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARValueStructStr2Type: type param is NULL");
  return -1;
}

static int
rev_ARValueStructKW2KN(char *keyword, unsigned int *n)
{
  int i;

  if(keyword && *keyword) {
    for(i = 0 ; KeyWordMap[i].number != -1 ; i++) {
      if(compmem(keyword, KeyWordMap[i].name, KeyWordMap[i].len) == 0)
	break;
    }
    if(KeyWordMap[i].number != -1) {
      *n = KeyWordMap[i].number;
      return 0;
    }
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARValueStructKW2KN: keyword given is unknown:");
    ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
		keyword);
  } else
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARValueStructKW2KN: keyword param is NULL");

  return -1;
}

static int
rev_ARValueStructDiary(HV *h, char *k, char **d)
{
  if(! h || ! k || ! d) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARValueStructDiary: invalid (NULL) parameter");
    return -1;
  }

  if(hv_exists(h, VNAME(k))) {
    SV **hr = hv_fetch(h, VNAME(k), 0);
    if(hr && *hr && SvROK(*hr) && (SvTYPE(*hr) == SVt_PVHV)) {
      HV   *h2 = (HV *)SvRV(*hr);
      char *user = (char *)NULL, *value = (char *)NULL;
      ARTimestamp timestamp = 0;
      int   rv = 0;

      /* fetch the keys: timestamp, user and value */

      rv += strmakHVal(h2, "user", &user);
      rv += strmakHVal(h2, "value", &value);
      rv += longcpyHVal(h2, "timestamp", &timestamp);

      if(rv == 0) {
	int   blen = strlen(user) + strlen(value) + 2 + 12;
	char *buf  = (char *)MALLOCNN(blen);
	sprintf(buf, "%d\003%s\003%s", timestamp, user, value);
	*d = buf;
#ifndef WASTE_MEM
	if(user) free(user);
	if(value) free(value);
#endif
	return 0;
      } 
    } else {
      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		  "rev_ARValueStructDiary: hash value is not hash ref for key:");
      ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
		  k);
    }
  } else {
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		"rev_ARValueStructDiary: hash key doesn't exist:");
    ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
		k);
    return -2;
  }
  return -1;
}

#if AR_EXPORT_VERSION >= 3
int
rev_ARByteList(HV *h, char *k, ARByteList *b)
{
  if(! h || ! k || ! b) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARByteList: invalid (NULL) parameter");
    return -1;
  }

  if(hv_exists(h, VNAME(k))) {
    SV **hr = hv_fetch(h, VNAME(k), 0);
    if(hr && *hr && SvROK(*hr) && (SvTYPE(*hr) == SVt_PVHV)) {
      HV   *h2 = (HV *)SvRV(*hr);
      char *bytes = (char *)NULL;

      if(hv_exists(h2, VNAME("type")) && hv_exists(h2, VNAME("value"))) {
	SV **tv = hv_fetch(h2, VNAME("type"), 0);
	SV **vv = hv_fetch(h2, VNAME("value"), 0);

	/* we are expecting two PV's */

	if(SvPOK(*tv) && SvPOK(*vv)) {
	  char *typeString = SvPV(*tv, na); /* SvPV is a macro */
	  char *byteString = SvPV(*vv, na);
	  int   byteLen    = SvCUR(*vv);

	  if(rev_ARByteListStr2Type(typeString, &(b->type)) == -1)
	    return -1;
	  b->numItems = byteLen;
	  b->bytes = MALLOCNN(byteLen + 1); /* don't want FreeAR.. to whack us */
	  copymem(b->bytes, byteString, byteLen);
	  return 0;
	}
      } else {
	ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		    "rev_ARByteList: required keys (type and value) not found in inner hash.");
      }
    } else {
      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		  "rev_ARByteList: hash value is not hash ref for key:");
      ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE,
		  k);
    }
  } else {
    ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL,
		"rev_ARByteList: hash key doesn't exist:");
    ARError_add(AR_RETURN_WARNING, AP_ERR_CONTINUE,
		k);
    return -2;
  }
  return -1;
}

static int 
rev_ARByteListStr2Type(char *ts, unsigned long *tv)
{
  int i = 0;

  if(ts && *ts && tv) {
    for(i = 0 ; ByteListTypeMap[i].number != -1 ; i++) 
      if(strncasecmp(ts, VNAME(ByteListTypeMap[i].name)) == 0)
	break;
    if(ByteListTypeMap[i].number != -1) {
      *tv = ByteListTypeMap[i].number;
      return 0;
    }
  }

  return -1;
}

int
rev_ARCoordList(HV *h, char *k, ARCoordList *m)
{
  SV **val;
  int  i;

  if(! m) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARCoordList: FieldAssignList param is NULL");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be an array reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVAV) {
	  AV *ar = (AV *)SvRV((SV *)*val);

	  /* allocate space for field assign structure list */

	  m->numItems = av_len(ar)+1;
	  if(m->numItems == 0)
	    return 0; /* nothing to do */
	  m->coords   = MALLOCNN(sizeof(ARCoordStruct) * m->numItems);

	  /* iterate over the array, grabbing each hash reference out of it
	   * and passing that to a helper routine to fill in the Coord
	   * structure.
	   */

	  for(i = 0 ; i <= av_len(ar) ; i++) {
	    SV **av_hv = av_fetch(ar, i, 0);

	    if(av_hv && *av_hv && (SvTYPE(SvRV(*av_hv)) == SVt_PVHV)) {
	      if(rev_ARCoordList_helper((HV *)SvRV(*av_hv), m, i) != 0)
		return -1;
	    } else 
	      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
			  "rev_ARCoordList: inner array value is not a hash reference");
	  }
	  return 0;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARCoordList: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARCoordList: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARCoordList: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARCoordList: first argument is not a hash");
  return -1;
}

static int
rev_ARCoordList_helper(HV *h, ARCoordList *m, int idx)
{
  if(hv_exists(h, VNAME("x")) && hv_exists(h, VNAME("y"))) {
    SV **xv = hv_fetch(h, VNAME("x"), 0);
    SV **yv = hv_fetch(h, VNAME("y"), 0);

    if(SvIOK(*xv) && SvIOK(*yv)) {
      m->coords[idx].x = (long) SvIV(*xv);
      m->coords[idx].y = (long) SvIV(*yv);
      return 0;
    } else
      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		  "rev_ARCoordList_helper: coord values are not IV's");
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARCoordList_helper: hash keys (x and y) do not exist.");

  return -1;
}
#endif /* 3.x */

/* ROUTINE
 *   rev_ARAssignFieldStruct(hash, key, assignfieldstruct)
 *
 * DESCRIPTION
 *   hash{key} = hash ref to "assign field struct" (ds_afs.html)
 *   extract info from hash ref, populate struct, return.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARAssignFieldStruct(HV *h, char *k, ARAssignFieldStruct *m)
{
  int rv = 0;

  if(! m || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARAssignFieldStruct: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be a hash reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVHV) {
	  HV *h2 = (HV *)SvRV((SV *)*val);
	  /* extract vals from hash ref and populate structure */
	  return rev_ARAssignFieldStruct_helper(h2, m);
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARAssignFieldStruct: hash value is not a hash reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARAssignFieldStruct: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARAssignFieldStruct: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARAssignFieldStruct: first argument is not a hash");
  return -1;
}

static int 
rev_ARAssignFieldStruct_helper(HV *h, ARAssignFieldStruct *m) 
{
  ARQualifierStruct  *qp;
  SV                **qpsv, **svp;

  if(!(hv_exists(h, "server", 0) &&
       hv_exists(h, "schema", 0) &&
       hv_exists(h, "qualifier", 0) &&
#if AR_EXPORT_VERSION >= 3
       hv_exists(h, "noMatchOption", 0) &&
       hv_exists(h, "multiMatchOption", 0) &&
#endif
       (hv_exists(h, "fieldId", 0) ||
	hv_exists(h, "statHistory", 0)))
     ) {

    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARAssignFieldStruct_helper: required hash key not found");
    return -1;
  }

  strcpyHVal(h, "server", m->server, AR_MAX_SERVER_SIZE + 1);
  strcpyHVal(h, "schema", m->schema, sizeof(ARNameType));

  if(hv_exists(h, "fieldId", 0)) {
    if(ulongcpyHVal(h, "fieldId", &(m->u.fieldId)) != 0)
      return -1;
  } 
  else if(hv_exists(h, "statHistory", 0)) {
    if(rev_ARStatHistoryValue(h, "statHistory", &(m->u.statHistory)) != 0)
      return -1;
  }

#if AR_EXPORT_VERSION >= 3
  svp = hv_fetch(h, VNAME("noMatchOption"), 0);
  if(svp && *svp) {
    char *c = SvPV(*svp, na);
    if(rev_ARAssignFieldStructStr2NMO(c, &(m->noMatchOption)) != 0)
      m->noMatchOption = AR_NO_MATCH_ERROR;
  }

  svp = hv_fetch(h, VNAME("multiMatchOption"), 0);
  if(svp && *svp) {
    char *c = SvPV(*svp, na);
    if(rev_ARAssignFieldStructStr2MMO(c, &(m->multiMatchOption)) != 0) 
      m->multiMatchOption = AR_MULTI_MATCH_ERROR;
  }
#endif

  /* extract and duplicate the qualifier struct. if we don't duplicate
   * it and simply reference it, FreeARyaddayadda() will free what the
   * reference points to and this could lead to badness if the user tries
   * to access the qual struct later on.
   */

  qpsv = hv_fetch(h, VNAME("qualifier"), 0);
  if(qpsv && *qpsv && SvROK(*qpsv)) {
    if(sv_derived_from(*qpsv, "ARQualifierStructPtr")) {
      qp = (ARQualifierStruct *)SvIV((SV *)SvRV(*qpsv));

      if(dup_qualifier2(qp, &(m->qualifier), 0) != (ARQualifierStruct *)NULL) {
	ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		    "rev_ARAssignFieldStruct_helper: dup_qualifier2() failed");
	return 0;
      }

    } else 
      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		  "rev_ARAssignFieldStruct_helper: qualifier key of type ARQualifierStructPtr");

  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARAssignFieldStruct_helper: qualifier key is not a reference");

  return -1;
}

static int 
rev_ARAssignFieldStructStr2NMO(char *s, unsigned int *nmo) 
{
  if(s && *s) {
    int i;
    for(i = 0 ; NoMatchOptionMap[i].number != -1 ; i++) 
      if(strcasecmp(NoMatchOptionMap[i].name, s) == 0)
	break;
    if(NoMatchOptionMap[i].number != -1) {
      *nmo = NoMatchOptionMap[i].number;
      return 0;
    }
  }
  return -1;
}

static int 
rev_ARAssignFieldStructStr2MMO(char *s, unsigned int *mmo)
{
  if(s && *s) {
    int i;
    for(i = 0 ; MultiMatchOptionMap[i].number != -1 ; i++)
      if(strcasecmp(MultiMatchOptionMap[i].name, s) == 0)
	break;
    if(MultiMatchOptionMap[i].number != -1) {
      *mmo = MultiMatchOptionMap[i].number;
      return 0;
    }
  }
  return -1;
}

/* ROUTINE
 *   rev_ARStatHistoryValue(hash, key, stathistvaluestruct)
 *
 * DESCRIPTION
 *   given a hash/key that contains a ref to a status history hash structure,
 *   extract the info from the hash ref and populate the give stathist struct.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARStatHistoryValue(HV *h, char *k, ARStatHistoryValue *s)
{
  int rv = 0;

  if(! s || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARStatHistoryValue: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be a hash reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVHV) {
	  HV *h2 = (HV *)SvRV((SV *)*val);
	  /* extract vals from hash ref and populate structure */
	  return rev_ARStatHistoryValue_helper(h2, s);
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARStatHistoryValue: hash value is not a hash reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARStatHistoryValue: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARStatHistoryValue: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARStatHistoryValue: first argument is not a hash");
  return -1;  
}

static int 
rev_ARStatHistoryValue_helper(HV *h, ARStatHistoryValue *s)
{
  if(hv_exists(h, "userOrTime", 0) && hv_exists(h, "enumVal", 0)) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARAssignFieldStruct_helper: required hash key not found");
    return -1;
  }

  if(ulongcpyHVal(h, "enumVal", &(s->enumVal)) != 0)
    return -1;
  if(uintcpyHVal(h, "userOrTime", &(s->userOrTime)) != 0)
    return -1;

  return 0;
}

/* ROUTINE
 *   rev_ARArithOpAssignStruct(hash, key, arithopstruct)
 *
 * DESCRIPTION
 *   this routine will populate the arithopstruct with the information
 *   contained in the hash ref that is the value of the hash/key given.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARArithOpAssignStruct(HV *h, char *k, ARArithOpAssignStruct *s)
{
  int rv = 0;

  if(! s || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARArithOpAssignStruct: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be a hash reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVHV) {
	  HV *h2 = (HV *)SvRV((SV *)*val);
	  /* extract vals from hash ref and populate structure */
	  return rev_ARArithOpAssignStruct_helper(h2, s);
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARArithOpAssignStruct: hash value is not a hash reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARArithOpAssignStruct: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARArithOpAssignStruct: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARArithOpAssignStruct: first argument is not a hash");
  return -1;  
}

static int
rev_ARArithOpAssignStruct_helper(HV *h, ARArithOpAssignStruct *s)
{
  SV **svp;
  
  if(!hv_exists(h, "oper",0)) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARArithOpAssignStruct_helper: hash does not contain required key 'oper'.");
    return -1;
  }

  /* decode the operation type */
  
  svp = hv_fetch(h, VNAME("oper"), 0);
  if(svp && *svp) {
    char *c = SvPV(*svp, na);
    if(rev_ARArithOpAssignStructStr2OP(c, &(s->operation)) != 0)
      return -1;
  }

  /* if oper is 'negate' then we only are interested in the 'left' side. else
   * we expect to get both side. call rev_ARAssignStruct() to fill it the
   * structure.
   */

  if(s->operation == AR_ARITH_OP_NEGATE) {
    if(hv_exists(h, "left", 0)) 
      return rev_ARAssignStruct(h, "left", &(s->operandLeft));
    else {
      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		  "rev_ARArithOpAssignStructStr2OP: operation 'negate' ('-') requires 'left' key.");
      return -1;
    }
  }

  /* other operations require both left and right */

  if(!(hv_exists(h, "left", 0) && hv_exists(h, "right", 0))) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARArithOpAssignStruct_helper: 'left' AND 'right' keys are required.");
    return -1;
  }

  if(rev_ARAssignStruct(h, "left", &(s->operandLeft)) == -1)
    return -1;
  return rev_ARAssignStruct(h, "right", &(s->operandRight));
}

static int
rev_ARArithOpAssignStructStr2OP(char *c, unsigned int *o)
{
  int i;
  for(i = 0 ; ArithOpMap[i].number != -1 ; i++) 
    if(strcasecmp(ArithOpMap[i].name, c) == 0)
      break;
  if(ArithOpMap[i].number == -1) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARArithOpAssignStructStr2OP: unknown operation word:");
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, c);
    return -1;
  }
  *o = ArithOpMap[i].number;
  return 0;
}

/* ROUTINE
 *   rev_ARFunctionAssignStruct(hash, key, functionassignstruct)
 *
 * DESCRIPTION
 *   unpack the function assign perl structure from the hash/key pair
 *   (it will be a hash ref) and populate the functionassignstruct
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARFunctionAssignStruct(HV *h, char *k, ARFunctionAssignStruct *s)
{
  int rv = 0;

  if(! s || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARFunctionAssignStruct: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be an array reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVAV) {
	  AV  *a = (AV *)SvRV((SV *)*val);
	  SV **aval;
	  int  i;

	  if(av_len(a) < 0) {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
			"rev_ARFunctionAssignStruct: array must have at least 1 element.");
	    return -1;
	  }

	  aval = av_fetch(a, 0, 0); /* fetch function name */
	  if(aval && *aval && SvPOK(*aval)) { /* must be a string */
	    char *fn = SvPV(*aval, na);
	    if(rev_ARFunctionAssignStructStr2FCODE(fn, &(s->functionCode)) == -1)
	      return -1;
	  } else {
	    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
			"rev_ARFunctionAssignStruct: first element of array must be a string function name.");
	    return -1;
	  }

	  /* loop over remaining array elements and populate the parameterList */

	  s->numItems = av_len(a); /* no +1 in this case */
	  if(s->numItems == 0)
	    return 0; /* nothing to do */
	  s->parameterList = (ARAssignStruct *)MALLOCNN(sizeof(ARAssignStruct) * s->numItems);

	  for(i = 1 ; i <= av_len(a) ; i++) {
	    SV **hvr = av_fetch(a, i, 0);
	    if(hvr && *hvr && (SvTYPE(SvRV(*hvr)) == SVt_PVHV))
	      if(rev_ARAssignStruct_helper((HV *)SvRV(*hvr), &(s->parameterList[i])) == -1)
		return -1;
	  }

	  return 0;

	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARFunctionAssignStruct: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARFunctionAssignStruct: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARFunctionAssignStruct: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARFunctionAssignStruct: first argument is not a hash");
  return -1;  
}

static int
rev_ARFunctionAssignStructStr2FCODE(char *c, unsigned int *o)
{
  int i;
  for(i = 0 ; FunctionMap[i].number != -1 ; i++) 
    if(strcasecmp(FunctionMap[i].name, c) == 0)
      break;
  if(FunctionMap[i].number == -1) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARFunctionAssignStructStr2FCODE: unknown function name:");
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, c);
    return -1;
  }
  *o = FunctionMap[i].number;
  return 0;
}

/* ROUTINE
 *   rev_ARStatusStruct(hash, key, statusstruct)
 * 
 * DESCRIPTION
 *   take hash ref from hash/key and extract status struct fields
 *   from that. populate status struct.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARStatusStruct(HV *h, char *k, ARStatusStruct *m)
{
  if(! m || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARStatusStruct: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be a hash reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVHV) {
	  HV  *a = (HV *)SvRV((SV *)*val);
	  int  rv = 0;

	  rv += strmakHVal(a, "messageText", &(m->messageText));
	  rv += uintcpyHVal(a, "messageType", &(m->messageType));
	  rv += longcpyHVal(a, "messageNum", &(m->messageNum));

	  return rv;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARStatusStruct: hash value is not a hash reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARStatusStruct: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARStatusStruct: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARStatusStruct: first argument is not a hash");
  return -1;  
}

/* ROUTINE
 *   rev_ARFieldCharacteristics(hash, key, fieldcharstruct)
 *
 * DESCRIPTION
 *   just like all the rest, only different.
 *
 * RETURNS
 *   0 on success
 *  -1 on failure
 *  -2 on warning
 */

int
rev_ARFieldCharacteristics(HV *h, char *k, ARFieldCharacteristics *m)
{
  if(! m || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARFieldCharacteristics: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be a hash reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVHV) {
	  HV  *a = (HV *)SvRV((SV *)*val);
	  int  rv = 0; 

	  rv += uintcpyHVal(a, "accessOption", &(m->accessOption));
	  rv += uintcpyHVal(a, "focus", &(m->focus));
	  rv += ulongcpyHVal(a, "fieldId", &(m->fieldId));
	  rv += strmakHVal(a, "charMenu", &(m->charMenu));
#if AR_EXPORT_VERSION >= 3
	  if(rev_ARPropList(a, "props", &(m->props)) == -1)
	    return -1;
#else /* 2.x */
	  m->display = (ARDisplayStruct *)MALLOCNN(sizeof(ARDisplayStruct));
	  if(rev_ARDisplayStruct_helper(a, "display", m->display) == -1)
	    return -1;
#endif
	  return rv;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARFieldCharacteristics: hash value is not a hash reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARFieldCharacteristics: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARFieldCharacteristics: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARFieldCharacteristics: first argument is not a hash");
  return -1;  
}

#if AR_EXPORT_VERSION >= 3
int
rev_ARPropList(HV *h, char *k, ARPropList *m)
{
  if(! m || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARPropList: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be an array reference. each hash
	 * will be a Prop Struct hash
	 */

	if(SvTYPE(SvRV(*val)) == SVt_PVAV) {
	  AV  *a = (AV *)SvRV((SV *)*val);
	  int  i;

	  /* allocate space for field assign structure list */

	  m->numItems = av_len(a)+1;
	  if(m->numItems == 0)
	    return 0; /* nothing to do */

	  m->props    = (ARPropStruct *)MALLOCNN(sizeof(ARPropStruct) * m->numItems);

	  /* iterate over the array, grabbing each hash reference out of it
	   * and passing that to a helper routine to fill in the Prop
	   * structure.
	   */

	  for(i = 0 ; i <= av_len(a) ; i++) {
	    SV **av_hv = av_fetch(a, i, 0);

	    if(av_hv && *av_hv && (SvTYPE(SvRV(*av_hv)) == SVt_PVHV)) {
	      if(rev_ARPropList_helper((HV *)SvRV(*av_hv), m, i) != 0)
		return -1;
	    } else 
	      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
			  "rev_ARPropList: inner array value is not a hash reference");
	  }
	  return 0;

	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARPropList: hash value is not an array reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARPropList: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARPropList: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARPropList: first argument is not a hash");
  return -1;  
}

static int 
rev_ARPropList_helper(HV *h, ARPropList *m, int idx)
{
  int rv = 0;

  if(hv_exists(h, VNAME("prop")) && 
     hv_exists(h, VNAME("value")) &&
     hv_exists(h, VNAME("valueType"))) {

    rv += ulongcpyHVal(h, "prop", &(m->props[idx].prop));
    rv += rev_ARValueStruct(h, "value", "valueType", &(m->props[idx].value));

    return rv;
  }
  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
	      "rev_ARPropList_helper: required hash keys not present (prop, value, valueType).");
  return -1;
}
#endif /* 3.x */

int
rev_ARActiveLinkMacroStruct(HV *h, char *k, ARActiveLinkMacroStruct *m)
{
  int rv = 0;

  if(! m || ! h || ! k) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		"rev_ARActiveLinkMacroStruct: invalid (NULL) parameter");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {

	/* hash value should be a hash reference */

	if(SvTYPE(SvRV(*val)) == SVt_PVHV) {
	  HV  *a = (HV *)SvRV((SV *)*val);
	  return rev_ARActiveLinkMacroStruct_helper(a, m);
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARActiveLinkMacroStruct: hash value is not a hash reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARActiveLinkMacroStruct: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARActiveLinkMacroStruct: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARActiveLinkMacroStruct: first argument is not a hash");
  return -1;  
}

static int
rev_ARActiveLinkMacroStruct_helper(HV *h, ARActiveLinkMacroStruct *m)
{
  int rv = 0;

  if(hv_exists(h, VNAME("macroParms")) &&
     hv_exists(h, VNAME("macroText")) &&
     hv_exists(h, VNAME("macroName"))) {

    rv += strcpyHVal(h, "macroName", m->macroName, sizeof(ARNameType));
    rv += strmakHVal(h, "macroText", &(m->macroText));
    rv += rev_ARMacroParmList(h, "macroParms", &(m->macroParms));

    return 0;
  }
  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
	      "rev_ARActiveLinkMacroStruct_helper: required keys not present in hash (macroParms, macroText, macroName)");
  return -1;
}

int
rev_ARMacroParmList(HV *h, char *k, ARMacroParmList *m)
{
  if(!h || !k || !*k || !m) {
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARMacroParmList: invalid parameter(s).");
    return -1;
  }

  if(SvTYPE((SV *)h) == SVt_PVHV) {
    if(hv_exists(h, VNAME(k))) {
      SV **val = hv_fetch(h, VNAME(k), 0);
      if(val && *val) {
	
	/* hash value should be a hash reference */
	
	if(SvTYPE(SvRV(*val)) == SVt_PVAV) {
	  HV   *a = (HV *)SvRV((SV *)*val);
	  int   rv = 0, i, i2;
	  SV   *hval;
	  char *hkey;
	  I32   klen;

	  /* the hash's keys are the names of the macroparm
	   * and the values are the value of the macroparm.
	   * both are pv's. so iterate over every key in
	   * the hash and populate the parms list with them.
	   */

	  (void) hv_iterinit(a);
	  for(i = 0 ; hv_iternext(a) != (HE *)NULL ; i++);
	  m->numItems = i;
	  m->parms = (ARMacroParmStruct *)MALLOCNN(sizeof(ARMacroParmStruct)
						   * m->numItems);
	  (void) hv_iterinit(a);
	  i2 = 0;
	  while(hval = hv_iternextsv(a, &hkey, &klen)) {
	    if(hval && SvPOK(hval)) {
	      char *vv = SvPV(hval, na);
	      int   vl = SvCUR(hval);

	      if(i2 <= i) {
		(void) strncpy(m->parms[i2].name, hkey, sizeof(ARNameType));
		(void) copymem(m->parms[i2].value, vv, vl);
		i2++;
	      } else {
		ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
			    "rev_ARMacroParmList: oops! more parms than i thought!");
		return -1;
	      }
	    } else {
	      ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, "rev_ARMacroParmList: value for macro param is not a string. macro param name:");
	      ARError_add(AR_RETURN_ERROR, AP_ERR_CONTINUE, hkey);
	      rv = -1;
	    }
	  }
	  return rv;
	} else 
	  ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL, 
		      "rev_ARMacroParmList: hash value is not a hash reference");
      } else {
	ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		    "rev_ARMacroParmList: hv_fetch returned null");
	return -2;
      }
    } else {
      ARError_add(AR_RETURN_WARNING, AP_ERR_GENERAL, 
		  "rev_ARMacroParmList: key doesn't exist");
      return -2;
    }
  } else 
    ARError_add(AR_RETURN_ERROR, AP_ERR_GENERAL,
		"rev_ARMacroParmList: first argument is not a hash");
  return -1;  
} 

