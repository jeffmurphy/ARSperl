#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/Makefile.PL,v 1.51 2003/07/03 19:01:14 jcmurphy Exp $
#
# ARSperl Makefile
#
# INSTRUCTIONS:
#    Set the following below:
#       1) path to API ($ARSAPI below)
#       2) libraries (uncomment/commentout appropriate $ARS_LIBS lines)
#       3) defines (see DEFINE OPTIONS)
#
#    run with "perl Makefile.PL" then type "make"
#

require 5.004;
use ExtUtils::MakeMaker;
use Config;

$debug = 0;

###### There are TWO (2) steps to complete. Complete both of them. ######

# STEP 1 -> Set the path to your ARS API directory

$ARSAPI     = "/usr/ar/api";
$ARSAPI     = "/u1/project/ARSperl/api/sol2/api5.1.1";
$ARSAPI     = "/u1/project/ARSperl/api/linux/5.1.1";
#$ARSAPI     = "/home/jcmurphy/arsperl/api/5.1";

# STEP 2 -> Choose your version of ARS FROM THE FOLLOWING LIST
#
#                  2.0 2.1 3.0 3.1 3.2 4.0 4.52 5.0
#
#           notes
#            - if there is a maintenace number (e.g. 4.5.2)
#              then use "4.52" NOT "4.5.2"
#            - ONLY use the choices listed above. note that
#              not all versions are on the list. specify the
#              version that is closest to yours without exceeding
#              your version (e.g. for 4.5 you would specify 4.0, NOT
#	       4.52)
#           
$ARSVERSION = 5.0;

# unless you run into problems, you shouldn't need to read any further.
# if you do run into problems, and don't really know what this file
# does, try subscribing to the mailing list and ask for help there.
# subscription information is available at http://www.arsperl.org/

$WINDOWS = ($^O eq 'MSWin32');

#        Windows NT: no "-lpthread"
#        NCR UNIX: add "-lc -lnet"
#                -DARSPDEBUG
$AUTODEFINES = " -g ";
$AUTODEFINES = "-D_WIN32" if($WINDOWS);

if($ARSVERSION >= 4.0) {
  $ARS_LIBS = "-lar -lnsl";
  $ARS_LIBS .= " -lnts" unless ($ARSVERSION >= 5.0);
  $ARS_LIBS .= " -lpthread" unless $WINDOWS;
  $AUTODEFINES .= " -DARS32 ";	
  $AUTODEFINES .= " -DARS452 " if($ARSVERSION >= 4.52);
  if ( ($ARSVERSION >= 5.0) && ($^O eq 'linux') ) {
    $AUTODEFINES .= " -malign-double ";
  }
}

elsif($ARSVERSION >= 3.0 && $ARSVERSION < 4.0) {
  $ARS_LIBS = "-lar -lnsl -lnts";
  $AUTODEFINES .= " -DARS32 " if($ARSVERSION == 3.2);
}

elsif($ARSVERSION >= 2.0 && $ARSVERSION < 3.0) {
  $ARS_LIBS = "-lar -lnsl -lnts -lntc";
  $AUTODEFINES .= " -DARS20 " if($ARSVERSION == 2.0);
}

# e.g for 5.004_03 ..
#
# baserev = 5.0 ( = PERL_REVISION as of 5.6.0)
# PATCHLEVEL = 4
# SUBVERSION = 3 ( = PERL_SUBVERSION as of 5.6.0)
#
# baserev/SUBVERSION still work in 5.6.0, but who knows for how long.

print "Building against perl $]\n";

$AUTODEFINES .= " -DPERL_PATCHLEVEL_IS=$Config{'PATCHLEVEL'} -DPERL_SUBVERSION_IS=$Config{'SUBVERSION'} -DPERL_BASEREV_IS=".($Config{'baserev'}*10)." ";

if($Config{'baserev'} == 5 &&
   $Config{'PATCHLEVEL'} == 4 &&
   $Config{'SUBVERSION'} == 3) {
	print "\n\nWARNING: Perl-5.004_03 contained a buggy 'h2ph' application.\nYou should examine line 100 of perl's 'h2ph' script and be sure that it\n
produces correct syntax (it's missing a close-parenthesis)\n";
	print "\nsleeping for 5 seconds. press control-c to abort.\n\n";
	sleep 5;
}

push(@extras, CAPI => 'TRUE') if ($] >= 5.005       &&
                                  $^O eq 'MSWin32'  && 
				  (($Config{archname} =~ /-object\b/i) ||
                                   ($Config{archname} =~ /-multi-thread\b/i))
                                 );

$ARS_LDPATH = "-L$ARSAPI/lib";
$INCLUDES   = "-I$ARSAPI/include";

GenerateSupportDotH("support-h.template", $INCLUDES);

print "Generating serverTypeInfoHints.h ..\n";

die "whoops. no file at ".$Config{'perlpath'} unless ( -f $Config{'perlpath'} );
$cmd = "$Config{'perlpath'} infra/exsi.pl < ${ARSAPI}/include/ar.h > serverTypeInfoHints.h";
$rv = system($cmd);
die "something went wrong when i ran \"$cmd\" (rv = $rv, expected 0)" unless ($rv == 0);

print "Converting C header files to perl modules ..\n";

foreach ("ar", "arerrno", "nt", "nterrno") {
	my $headerFile = "${ARSAPI}/include/${_}.h";

	# arsystem >= 5.0 doesnt have nt libs/hdrs anymore
	if( ($ARSVERSION >= 5.0) && /^nt/ ) {
		open(FD, "> ARS${_}-h.pm") || die "open: $!";
		print FD "\# as of ARSystem 5.0, the NT (notifier) routines
# are retired. so this file is just stubbed.
1;\n";
		close(FD);
		next;
	}

	die "couldn't find $headerFile" if (! -e $headerFile);

	# due to the endless confusion over h2ph, i'm including
	# a known-good copy in the arsperl distribution. the 
	# -d should make it create _h2ph_pre in the current 
	# directory incase you never ran h2ph before (as root)

	$rv = system("$Config{'perlpath'} infra/h2ph -d . < $headerFile > ARS${_}-h.pm");

	unlink ('_h2ph_pre.ph');
	open (FD, "> _h2ph_pre.ph") || die "open: $!";
	print FD "1;\n";
	close(FD);

	if((! -e "ARS${_}-h.pm") || (-z "ARS${_}-h.pm")) {
		open (FD, "> ARS${_}-h.pm") || die "open: $!";
		print FD "\# your perl installation was either missing the 'h2ph'
\# utility or it was not in your path with you ran 'perl Makefile.PL'

1;\n";
		close (FD);
	}
}

print "Configuring with options:\n";
printf "\tARSVERSION  = %.2f\n", $ARSVERSION;
print "\tARSAPI      = $ARSAPI\n";
print "\tAUTODEFINES = $AUTODEFINES\n";

WriteMakefile(
	      'NAME'	=> 'ARS',
	      'VERSION_FROM' => 'ARS.pm',
	      'LIBS'	=> ["${ARS_LDPATH} ${ARS_LIBS}"],
	      'OBJECT'  => q[ARS$(OBJ_EXT) support$(OBJ_EXT) supportrev$(OBJ_EXT)],
	      'INC'	=> "${INCLUDES}",
	      #'PM' =>{ '_h2ph_pre.ph' => '$(INST_LIBDIR)/_h2ph_pre.ph' },
	      @extras,

# DEFINE OPTIONS:
#  NOTE: these should automatically be detected and configured above.
#        see the $AUTODEFINES variable above.
#
#    -DPROFILE
#
#       Enable query profiling code (very little overhead).
#       See ars_GetProfileInfo() call for details.
#       Don't use this if you are compiling on _WIN32
#
#    -DARS20
#
#       If you are running ARS2.0.2 or anything less than 2.1, you should
#       add -DARS20 to the DEFINE line.
#
#    -DARS32
#       If you are compiling against ARS 3.2 API libraries defined this
#       because AdminExtension API routines were removed in as of
#       the 3.2 release.
#
#    -D_WIN32
#
#       If you are compiling ARSperl under windows, define this
#       and /don't/ define PROFILE.
#
#    -DSKIP_SV_ISA  (not automatically set)
#
#       If you get errors during compilation/runtime similar to 
#       "undefined symbol: sv_isa" then add this define.

	      'DEFINE'	=> ${AUTODEFINES},
#             'DEFINE'  => '-D_WIN32 ', # note: win32 -> no -DPROFILE


# if you have trouble under solaris when linking (bfd assertion 
# failures) try uncommenting the following:
#
#	      'LD' => "/usr/ccs/bin/ld",

# don't fiddle with this

              'realclean' => {
		 'FILES' => 'support.h ARSar-h.pm ARSarerrno-h.pm ARSnt-h.pm ARSnterrno-h.pm t/config.cache serverTypeInfoHints.h *~ .purify *-h.pm _h2ph_pre.ph ' 
	      } 
);

makeTestConfig();

print "
Type 'make' (windows: 'nmake') to build ARSperl.
Type 'make test' to test ARSperl before installing.
Type 'make install' to install ARSperl.

";

exit 0;

# ROUTINE
#   GenerateSupportDotH(template-file, includes-dir)
#
# DESCRIPTION
#   this routine extracts some information from the 
#   "ar.h" file and generates some "type maps" which help
#   us translate from code numbers to readable text.

sub GenerateSupportDotH {
    my ($tmpl, $incdir) = (shift, shift);
    my (@arh);

    $incdir =~ s/^-I//g;

    print "Generating support.h file..\n";

    die "not a directory ($incdir): $!" if(! -d $incdir);
    open(ARH, $incdir."/ar.h") || die "can't open $incdir/ar.h : $!";
    @arh = <ARH>;
    close(ARH);

    open(FD, "> support.h") || die "can't open temporary file: $!";
    open(TMPL, $tmpl) || die "can't open template ($tmpl): $!";

    print FD "/* THIS FILE WAS AUTOMATICALLY GENERATED BY Makefile.PL */\n";
    print FD "/*                  DO NOT EDIT                         */\n";
    print FD "\n\n";

    while(<TMPL>) {
	if(/CHARMENUREFRESHCODETYPEMAP/) {
	    print "\tProcessing AR_MENU_REFRESH codes..\n";
	    my($line, $code);
	    foreach $line (grep (/^\#define\s+AR_MENU_REFRESH.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_MENU_REFRESH_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	} 
	elsif(/CHARMENUTYPEMAP/) {
	    print "\tProcessing AR_CHAR_MENU codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_CHAR_MENU.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_CHAR_MENU_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/STATUSRETURNTYPEMAP/) {
	    print "\tProcessing AR_RETURN codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_RETURN.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_RETURN_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/SERVERSTATTYPEMAP/) {
	    print "\tProcessing AR_SERVER_STAT codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_SERVER_STAT.*/, @arh)) {
		$code = (split(/\s/, $line))[1];
		print "\t\t$code\n" if $debug;
		$code =~ /^AR_SERVER_STAT_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/SCHEMAPERMISSIONTYPEMAP/) {
	    print "\tProcessing AR_PERMISSIONS (Schema) codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_PERMISSIONS.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		# _view & _change are field permissions
		# it would be nice if AR_PERM.. differentiated between
		# schema and field.

		if($code !~ /_VIEW|_CHANGE/) {
		    print "\t\t$code\n" if $debug;
		    $code =~ /^AR_PERMISSIONS_(\w+)/;
		    print FD "  { $code, \t\t\"\L$1\E\" },\n";
		}
	    }
	}
	elsif(/FIELDPERMISSIONTYPEMAP/) {
	    print "\tProcessing AR_PERMISSIONS (Field) codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_PERMISSIONS.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		# _visible & _hidden are schema permissions
		if($code !~ /_VISIBLE|_HIDDEN/) {
		    print "\t\t$code\n" if $debug;
		    $code =~ /^AR_PERMISSIONS_(\w+)/;
		    print FD "  { $code, \t\t\"\L$1\E\" },\n";
		}
	    }
	}
	elsif(/DATATYPEMAP/) {
	    print "\tProcessing AR_DATA_TYPE codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_DATA_TYPE.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_DATA_TYPE_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
        elsif(/SCHEMATYPEMAP/) {
            print "\tProcessing AR_SCHEMA codes..\n";
            my($code, $line);
            foreach $line (grep (/^\#define\s+AR_SCHEMA.*/, @arh)) {
		# another instance of poor naming conventions
		next if $line =~ /_DELETE/;
                $code = (split(/\s/, $line))[1];

                print "\t\t$code\n" if $debug;
                $code =~ /^AR_SCHEMA_(\w+)/;
                print FD "  { $code, \t\t\"\L$1\E\" },\n";
            }
        }
        elsif(/STRUCTITEMTYPEMAP/) {
            print "\tProcessing AR_STRUCT_ITEM codes..\n";
            my($code, $line);
            foreach $line (grep (/^\#define\s+AR_STRUCT_ITEM.*/, @arh)) {
                $code = (split(/\s/, $line))[1];

                print "\t\t$code\n" if $debug;
                $code =~ /^AR_STRUCT_ITEM_(\w+)/;
                print FD "  { $code, \t\t\"\L$1\E\" },\n";
            }
        }
	elsif(/BYTELISTTYPEMAP/) {
	    print "\tProcessing AR_BYTE_LIST codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_BYTE_LIST.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_BYTE_LIST_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/NOMATCHOPTIONMAP/) {
	    print "\tProcessing AR_NO_MATCH codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_NO_MATCH.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_NO_MATCH_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/MULTIMATCHOPTIONMAP/) {
	    print "\tProcessing AR_MULTI_MATCH codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_MULTI_MATCH.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_MULTI_MATCH_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/FUNCTIONMAP/) {
	    print "\tProcessing AR_FUNCTION codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_FUNCTION.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_FUNCTION_(\w+)/;
		print FD "  { $code, \t\t\"\L$1\E\" },\n";
	    }
	}
	elsif(/KEYWORDMAP/) {
	    print "\tProcessing AR_KEYWORD codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_KEYWORD.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_KEYWORD_(\w+)/;
		printf(FD "  { %s, \t\t\"\\0\L%s\E\\0\", \t\t%d },\n",
		       $code, $1, length($1)+2);
	    }
	}
	elsif(/SERVERINFOMAP/) {
	    print "\tProcessing AR_SERVER_INFO codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_SERVER_INFO.*/, @arh)) {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_SERVER_INFO_(\w+)/;
		next if ($1 eq "MIN_AUDIT_LOG_FILE_SIZE");
		print FD "  { $code, \t\"$1\" },\n";
	    }
	}
	elsif(/ACTIVELINKACTIONTYPEMAP/) {
	    print "\tProcessing AR_ACTIVE_LINK_ACTION codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_ACTIVE_LINK_ACTION.*/, @arh))
            {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_ACTIVE_LINK_ACTION_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/COMPARMTYPEMAP/) {
	    print "\tProcessing AR_COM_PARM codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_COM_PARM.*/, @arh))
	    {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_COM_PARM_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/COMMETHODTYPEMAP/) {
	    print "\tProcessing AR_COM_METHOD codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_COM_METHOD.*/, @arh))
	    {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_COM_METHOD_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	}
	elsif(/FILTERACTIONTYPEMAP/) {
	    print "\tProcessing AR_FILTER_ACTION codes..\n";
	    my($code, $line);
	    foreach $line (grep (/^\#define\s+AR_FILTER_ACTION.*/, @arh))
	    {
		$code = (split(/\s/, $line))[1];

		print "\t\t$code\n" if $debug;
		$code =~ /^AR_FILTER_ACTION_(\w+)/;
		print FD "  { $code, \t\"\L$1\E\" },\n";
	    }
	} else {
	    print FD $_;
	}
    }
    close(TMPL);
    close(FD);

    print "\n";

}

sub makeTestConfig {
	my ($SERVER, $USERNAME, $PASSWORD);
	my ($S, $U, $P) = ("", "", "");

	if(-e "./t/config.cache") {
		do './t/config.cache';
		$S = &CCACHE::SERVER;
		$U = &CCACHE::USERNAME;
		$P = &CCACHE::PASSWORD;
	}

	print "=== ARSperl 'make test' configuration. ===

Please enter the following information. This information will be
recorded in ./t/config.cache

If you want to skip the 'make test' step, just hit ENTER
three times. You can configure it later by either re-running
'perl Makefile.PL' or by editting ./t/config.cache

Fair warning: you probably don't want to run 'make test' against a 
production ARSystem server. 

";
	
	print "Server Name [$S]: ";
	chomp($SERVER = <STDIN>);
	if($SERVER eq "") {
		$SERVER = $S if ($S ne "");
	} 

	print "Admin Username [$U]: ";
	chomp($USERNAME = <STDIN>);
        if($USERNAME eq "") {
                $USERNAME = $U if ($U ne "");
        } 

	print "Admin Password [$P]: ";
	chomp($PASSWORD = <STDIN>);
        if($PASSWORD eq "") {
                $PASSWORD = $P if ($P ne "");
        } 

	#print "Storing $SERVER / $USERNAME / $PASSWORD ..\n";
	open (FD, "> ./t/config.cache") || die "open failed: $!";
	print FD "package CCACHE;\n";
	print FD "\# enter your server, admin username and password below.\n\n";
	print FD "sub SERVER { \"$SERVER\" ; }\n";
	print FD "sub USERNAME { \"$USERNAME\" ; }\n";
	print FD "sub PASSWORD { \"$PASSWORD\" ; }\n";
	print FD "1;\n";
	close(FD);

}
