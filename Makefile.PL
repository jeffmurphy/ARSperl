#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/Makefile.PL,v 1.4 1996/11/21 20:02:26 jcmurphy Exp $
#
# ARSperl Makefile
#
# run me with "perl Makefile.PL" after tweaking things below
#
# $Log: Makefile.PL,v $
# Revision 1.4  1996/11/21 20:02:26  jcmurphy
# *** empty log message ***
#

use ExtUtils::MakeMaker;

$ARS_LDPATH = "-L/usr/ars/api/lib";
$INCLUDES = "-I/usr/ars/api/include";
$ARS_LIBS = "-lar -lnsl";

WriteMakefile(
	      'NAME'	=> 'ARS',
	      'VERSION'	=> '1.3',
	      'LIBS'	=> ["${ARS_LDPATH} ${ARS_LIBS}"],
#
# If you want to free() allocated memory, don't define WASTE_MEM
# In the past, there were some bad free() problems so we offered
# this option.
#
#	      'DEFINE'	=> '-g -DPROFILE',
	      'DEFINE'	=> '-g -DWASTE_MEM -DPROFILE',
	      'OBJECT'  => "ARS.o",
	      'INC'	=> "${INCLUDES}",
#
# if you have trouble under solaris when linking (bfd assertion 
# failures) try uncommenting the following:
#
	      'LD' => "/usr/ccs/bin/ld",
);
