#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/Makefile.PL,v 1.5 1997/10/06 13:43:26 jcmurphy Exp $
#
# ARSperl Makefile
#
# INSTRUCTIONS:
#    Set the following below:
#       1) paths to API ($ARS_LDPATH and $INCLUDES)
#       2) libraries (uncomment/commentout appropriate $ARS_LIBS lines)
#       3) defines (see DEFINE OPTIONS)
#
#    run with "perl Makefile.PL" then type "make"
#
# $Log: Makefile.PL,v $
# Revision 1.5  1997/10/06 13:43:26  jcmurphy
# *** empty log message ***
#
# Revision 1.4  1996/11/21 20:02:26  jcmurphy
# *** empty log message ***
#

use ExtUtils::MakeMaker;

# There are three steps to complete. 

# STEP 1 -> Set the path to your ARS API directory

$ARSAPI     = "/usr/ars/api";

#$ARSAPI     = "/u1/project/ARSperl/api/sol2/api2.1";
$ARS_LDPATH = "-L$ARSAPI/lib";
$INCLUDES   = "-I$ARSAPI/include";

# STEP 2 -> Choose your version of ARS

# 3.0 libraries:

$ARS_LIBS = "-lar -lnsl -lnts";

# 2.x libraries:

#$ARS_LIBS = "-lar -lnsl -lnts -lntc";

WriteMakefile(
	      'NAME'	=> 'ARS',
	      'VERSION_FROM' => 'ARS.pm',
	      'LIBS'	=> ["${ARS_LDPATH} ${ARS_LIBS}"],
	      'OBJECT'  => q[ARS$(OBJ_EXT) support$(OBJ_EXT) supportrev$(OBJ_EXT)],
	      'INC'	=> "${INCLUDES}",

# STEP 3 -> DEFINE OPTIONS:
#
#    -DWASTE_MEM
#
#       If you want to free() allocated memory, don't define WASTE_MEM
#       In the past, there were some bad free() problems so we offered
#       this option.
#
#    -DPROFILE
#
#       Enable query profiling code (very little overhead).
#       See ars_GetProfileInfo() call for details.
#
#    -DARS20
#
#       If you are running ARS2.0.2 or anything less than 2.1, you should
#       add -DARS20 to the DEFINE line.
#
	      'DEFINE'	=> '-DPROFILE ',
#
# if you have trouble under solaris when linking (bfd assertion 
# failures) try uncommenting the following:
#
#	      'LD' => "/usr/ccs/bin/ld"
);
