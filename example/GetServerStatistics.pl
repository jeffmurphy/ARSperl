#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/GetServerStatistics.pl,v 1.1 1996/11/21 20:13:53 jcmurphy Exp $
#
# NAME
#   GetServerStatistics.pl
#
# USAGE
#   GetServerStatistics.pl [username] [password]
#
# DESCRIPTION
#   Retrieve and print statistics on the arserver
#
# AUTHOR
#   Jeff Murphy
#   jcmurphy@acsu.buffalo.edu
#
# $Log: GetServerStatistics.pl,v $
# Revision 1.1  1996/11/21 20:13:53  jcmurphy
# Initial revision
#
#

use ARS;

($username, $password) = @ARGV;

if(!defined($password)) {
    print "Usage: $0 [username] [password]\n";
    exit 0;
}

($c = ars_Login("", $username, $password)) ||
    die "couldn't allocate control structure";

foreach $stype (keys %ARServerStats) {
    $rev_ServerStats[$ARServerStats{$stype}] = $stype;
}

print "requesting: START_TIME($ARServerStats{'START_TIME'}) CPU($ARServerStats{'CPU'})\n";

(%stats = ars_GetServerStatistics($c, 
				  $ARServerStats{'START_TIME'},
				  $ARServerStats{'CPU'} )) ||
    die "ars_GetServerStatistics: $ars_errstr";

foreach $stype (keys %stats) {
    if($rev_ServerStats[$stype] =~ /TIME/) {
	print $rev_ServerStats[$stype]." = ".localtime($stats{$stype})." (".$stats{$stype}.")\n";
    } else {
	print $rev_ServerStats[$stype]." = ".$stats{$stype}."\n";
    }
}

ars_Logoff($c) || die "ars_Logoff: $ars_errstr";
