#!/usr/local/bin/perl

use ExtUtils::MakeMaker;

$ARS_LDPATH = "-L/ware/ars/api/lib";
$INCLUDES = "-I/ware/ars/api/include";
$ARS_LIBS = "-lar -lnsl";

WriteMakefile(
	      'NAME'	=> 'ARS',
	      'VERSION'	=> '1.1beta',
	      'LIBS'	=> ["${ARS_LDPATH} ${ARS_LIBS}"],
	      'DEFINE'	=> '-g',
	      'OBJECT'  => "ARS.o",
	      'INC'	=> "${INCLUDES}",
);
