/*
$Header: /cvsroot/arsperl/ARSperl/supportrev.h,v 1.5 1997/10/07 14:29:49 jcmurphy Exp $

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

$Log: supportrev.h,v $
Revision 1.5  1997/10/07 14:29:49  jcmurphy
1.51

Revision 1.4  1997/10/06 13:39:48  jcmurphy
fix up some compilation warnings

Revision 1.3  1997/10/02 15:40:06  jcmurphy
1.50beta

Revision 1.2  1997/09/04 00:20:56  jcmurphy
*** empty log message ***

Revision 1.1  1997/08/05 21:21:24  jcmurphy
Initial revision


*/

#ifndef __supportrev_h_
#define __supportrev_h_

#undef EXTERN
#ifndef __supportrev_c_
# define EXTERN extern
#else
# define EXTERN 
#endif

EXTERN int strcpyHVal(HV *h, char *k, char *b, int len);
EXTERN int strmakHVal(HV *h, char *k, char **b);
EXTERN int intcpyHVal(HV *h, char *k, int *b);
EXTERN int uintcpyHVal(HV *h, char *k, unsigned int *b);
EXTERN int longcpyHVal(HV *h, char *k, long *b);
EXTERN int ulongcpyHVal(HV *h, char *k, unsigned long *b);
EXTERN int rev_ARDisplayList(HV *h, char *k, ARDisplayList *d);
EXTERN int rev_ARDisplayStruct(HV *h, ARDisplayStruct *d);
EXTERN int rev_ARInternalIdList(HV *h, char *k, ARInternalIdList *il);
EXTERN int rev_ARActiveLinkActionList(HV *h, char *k, ARActiveLinkActionList *al);
EXTERN int rev_ARFieldAssignList(HV *h, char *k, ARFieldAssignList *m);
EXTERN int rev_ARAssignStruct(HV *h, char *k, ARAssignStruct *m);
EXTERN int rev_ARValueStruct(HV *h, char *k, char *t, ARValueStruct *m);
EXTERN int rev_ARAssignFieldStruct(HV *h, char *k, ARAssignFieldStruct *m);
EXTERN int rev_ARStatHistoryValue(HV *h, char *k, ARStatHistoryValue *s);
EXTERN int rev_ARArithOpAssignStruct(HV *h, char *k, ARArithOpAssignStruct *s);
EXTERN int rev_ARFunctionAssignStruct(HV *h, char *k, ARFunctionAssignStruct *s);
EXTERN int rev_ARStatusStruct(HV *h, char *k, ARStatusStruct *m);
EXTERN int rev_ARFieldCharacteristics(HV *h, char *k, ARFieldCharacteristics *m);
EXTERN int rev_ARActiveLinkMacroStruct(HV *h, char *k, ARActiveLinkMacroStruct *m);
EXTERN int rev_ARMacroParmList(HV *h, char *k, ARMacroParmList *m);

#if AR_EXPORT_VERSION >= 3
EXTERN int rev_ARByteList(HV *h, char *k, ARByteList *b);
EXTERN int rev_ARCoordList(HV *h, char *k, ARCoordList *m);
EXTERN int rev_ARPropList(HV *h, char *k, ARPropList *m);
EXTERN int rev_ARAssignSQLStruct(HV *h, char *k, ARAssignSQLStruct *s);
#endif

#endif /* __supportrev_h_ */
