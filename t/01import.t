#!./perl

# 
# test out importing a schema definition
#

use ARS;
require './t/config.cache';

print "1..1\n";

my($ctrl) = ars_Login(&CCACHE::SERVER, &CCACHE::USERNAME, &CCACHE::PASSWORD);
if(!defined($ctrl)) {
  print "not ok (login $ars_errstr)\n";
  exit 0;
}

my $d = "aptest.def";

# if we're compiled against 4.0, we'll import a schema
# with an attachment field so we can test that out.

if(ars_APIVersion() >= 4) {
  $d = "aptest45.def";
}
if(ars_APIVersion() >= 7) {
  $d = "aptest50.def";
}


#  delete the schema (assuming it already exists). if it doesnt,
#  we ignore the error.

ars_DeleteSchema($ctrl, "ARSperl Test", ARS::AR_SCHEMA_FORCE_DELETE); 

# read in the schema definition

my $buf = "";
open(FD, "./t/".$d) || die "not ok (open $!)\n";
while(<FD>) {
  $buf .= $_;
}
close(FD);

# import it

my $rv = ars_Import($ctrl,
	   &ARS::AR_IMPORT_OPT_CREATE,
	   $buf, "Schema", "ARSperl Test",
	   "Filter", "ARSperl Test-Filter1"
	);


if(defined($rv) && ($rv == 1)) {
	print "ok\n";
} else {
	print "not ok [$ars_errstr]\n";
}

ars_Logoff($ctrl);

exit 0;

