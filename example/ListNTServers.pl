#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Attic/ListNTServers.pl,v 1.1 1997/02/13 15:49:45 jcmurphy Exp $
#
# USAGE
#   ListNTServers.pl 
#
# DESCRIPTION
#   list all available notification servers.
#
# AUTHOR
#   jeff murphy

use ARS;

@servers = ars_NTGetListServer();
if($#servers == -1) {
    print "No NT servers available.\n";
    exit 0;
}

print "NT Server List:\n";

foreach $s (@servers) {
    print "\t$s\n";
}

exit 0;
