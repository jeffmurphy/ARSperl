/*
$Header: /cvsroot/arsperl/ARSperl/supportrev.h,v 1.1 1997/08/05 21:21:24 jcmurphy Exp $

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
EXTERN int rev_ARDisplayStruct(HV *h, char *k, ARDisplayList *d);
EXTERN int rev_ARInternalIdList(HV *h, char *k, ARInternalIdList *il);

#endif /* __supportrev_h_ */
