#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetListEntry.pl,v 1.2 2000/06/01 13:45:20 jcmurphy Exp $
#
# NAME
#   ars_GetListEntry.pl [server] [username] [password]
#
# DESCRIPTION
#   Demonstration of GetListEntry().
#
# AUTHOR
#   Jeff Murphy
#   jcmurphy@buffalo.edu
#
# $Log: ars_GetListEntry.pl,v $
# Revision 1.2  2000/06/01 13:45:20  jcmurphy
# *** empty log message ***
#
# Revision 1.1  1998/03/25 22:52:51  jcmurphy
# Initial revision
#
#
#

use ARS;

($server, $username, $password) = (shift, shift, shift);

if($password eq "") {
    print "Usage: $0 [server] [username] [password]\n";
    exit 0;
}

$schema = "User";
$login_name = "Login name";
$lic_type = "License Type";

($ctrl = ars_Login($server, $username, $password)) ||
    die "ars_Login failed: $ars_errstr";

(%fids = ars_GetFieldTable($ctrl, $schema)) ||
    die "ars_GetFieldTable: $ars_errstr";

$login_name = "Login Name" if(!defined($fids{$login_name}));

($qual = ars_LoadQualifier($ctrl, $schema, "(1 = 1)")) ||
    die "ars_LoadQualifier: $ars_errstr";

# basic format: allow the server to provide sorting order
# and query list fields.

print "Testing: basic format.\n";

(@entries = ars_GetListEntry($ctrl, $schema, $qual, 0)) ||
    die "ars_GetListEntry: $ars_errstr";

for ($i = 0; $i < $#entries ; $i+=2) {
    printf("%s %s\n", $entries[$i], $entries[$i+1]);
}

# another format: specify a sorting order. 
# sort by license type, ascending.

print "Testing: basic + sorting format.\n";

(@entries = ars_GetListEntry($ctrl, $schema, $qual, 0, 
			     $fids{$lic_type}, 1)) ||
    die "ars_GetListEntry: $ars_errstr";

for ($i = 0; $i < $#entries ; $i+=2) {
    printf("%s %s\n", $entries[$i], $entries[$i+1]);
}

# another format: specify a custom query list field-list.

print "Testing: basic + sorting + custom field-list format.\n";

if(!defined($fids{$login_name}) || !defined($fids{$lic_type})) {
	print "Sorry. Either i can't find the field-id for \"$login_name\" or \"$lic_type\"\n on your \"$schema\" form. I'm skipping this test.\n";
} else {
	(@entries = ars_GetListEntry($ctrl, $schema, $qual, 0,
    [ {columnWidth => 15, separator => ' ', fieldId => $fids{$login_name} },
      {columnWidth => 10, separator => ' ', fieldId => $fids{$lic_type}   }
    ],
			     $fids{$login_name}, 1)) ||
    		die "ars_GetListEntry: $ars_errstr";

	for ($i = 0; $i < $#entries ; $i+=2) {
    		printf("%s %s\n", $entries[$i], $entries[$i+1]);
	}
}

ars_Logoff($ctrl);

exit 0;

