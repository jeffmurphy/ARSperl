#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetListSQL.pl,v 1.1 1997/07/23 18:21:29 jcmurphy Exp $
#
# NAME
#   ars_GetListSQL.pl
#
# USAGE
#   ars_GetListSQL.pl [server] [username] [password]
#
# DESCRIPTIONS
#   Log into the ARServer with the given username and password and
#   request that the SQL command (hardcoded below) be executed. Dump
#   output to stdout.
#
# NOTES
#   Requires Administrator privs to work.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_GetListSQL.pl,v $
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
#
#


use ARS;

($c = ars_Login(shift, shift, shift)) || die "login: $ars_errstr";

# The arschema table contains information about what schemas are
# in the system. We'll grab some of the columns and dump them.

$sql = "select name, schemaid, nextid from arschema";

print "Calling GetListSQL with:\n\t$sql\n\n";

($h = ars_GetListSQL($c, $sql)) || die "ERR: $ars_errstr\n";
print "errstr=$ars_errstr\n";

print "GetListSQL returned the following rows:\n";

print "rows fetched: $h->{numMatches}\n";
print "name\t\tschemaid\t\tnextid\n";
for($col = 0; $col < $h->{numMatches}; $col++) {
    for($row = 0 ; $row <= $#{@{$h->{rows}}[$col]}; $row++) {
	print @{@{$h->{rows}}[$col]}[$row]."\t\t";
    }
    print "\n";
}

ars_Logoff($c);
