#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetServerInfo.pl,v 1.1 1997/07/23 18:21:29 jcmurphy Exp $
#
# NAME
#   ars_GetServerInfo.pl
# 
# USAGE
#   ars_GetServerInfo.pl [server] [username] [password]
#
# DESCRIPTION
#   Retrieve and print server configuration information.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_GetServerInfo.pl,v $
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
#
#
#

use ARS;

($c = ars_Login(shift, shift, shift)) || die "login: $ars_errstr";

print "Calling GetServerInfo ..\n";

(%h = ars_GetServerInfo($c)) || die "ERR: $ars_errstr\n";

for $it (keys %h) {
    printf("%25s %s\n", $it, $h{$it});
}

ars_Logoff($c);
