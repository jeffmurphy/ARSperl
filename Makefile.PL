#!/usr/local/bin/perl

use ExtUtils::MakeMaker;

$ARS_LDPATH = "-L/usr/ars/api/lib";
$INCLUDES = "-I/usr/ars/api/include";
$ARS_LIBS = "-lar -lnsl";

WriteMakefile(
	      'NAME'	=> 'ARS',
	      'VERSION'	=> '1.2',
	      'LIBS'	=> ["${ARS_LDPATH} ${ARS_LIBS}"],
	      'DEFINE'	=> '-g',
	      'OBJECT'  => "ARS.o",
	      'INC'	=> "${INCLUDES}",
);
