#!./perl

# 
# test out importing a schema definition
#

use ARS;
require './t/config';

print "1..1\n";

my($ctrl) = ars_Login($SERVER, $USERNAME, $PASSWORD);
if(!defined($ctrl)) {
  print "not ok\n";
  exit 0;
}

my $d = "aptest.def";

# if we're compiled against 4.0, we'll import a schema
# with an attachment field so we can test that out.

if(ars_APIVersion() >= 4) {
  $d = "aptest40.def";
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

ars_Import($ctrl, $buf, "Schema", "ARSperl Test") || die "not ok\n";

ars_Logoff($ctrl);

print "ok\n";

exit 0;

