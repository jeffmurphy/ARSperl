#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Attic/ars_GetFullTextInfo.pl,v 1.1 1997/07/23 18:21:29 jcmurphy Exp $
#
# NAME
#   ars_GetFullTextInfo.pl
#
# USAGE
#   ars_GetFullTextInfo.pl [server] [username] [password]
#
# DESCRIPTION
#   Request and print out configuration information for the Full Text Search
#   Engine.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_GetFullTextInfo.pl,v $
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
#
#
#

use ARS;

($c = ars_Login(shift, shift, shift)) || die "login: $ars_errstr";


print "Calling GetFullTextInfo..\n";

($h = ars_GetFullTextInfo($c)) || die "ERR: $ars_errstr\n";
print "errstr=$ars_errstr\n";

print "GetFullTextInfo returned:\n";

foreach $k (keys %$h) {
    print "key = <$k> value = <$$h{$k}>\n";
    if($k eq "StopWords") {
	$a1 = $$h{$k};
	@ar = @$a1;
	foreach $sw (@{$h{$k}}) {
	    print "\t$sw\n";
	}
    }
}

ars_Logoff($c);
