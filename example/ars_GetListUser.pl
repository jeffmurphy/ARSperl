#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetListUser.pl,v 1.1 1997/07/23 18:21:29 jcmurphy Exp $
#
# NAME
#   ars_GetListUser.pl
#
# USAGE
#   ars_GetListUser.pl [server] [username] [password]
#
# DESCRIPTION
#   Demo of said function. Fetches and prints listing of
#   all currently connected users and their license info.
#
# NOTES
#   email addr and notify mech are (as far as we can tell) part of the
#   return values from the API, but are never filled in. this is not a
#   bug in arsperl. 
#
# AUTHOR
#   jeff murphy
#
# $Log: ars_GetListUser.pl,v $
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
#
#
#

use ARS;

@noteMech = ("NONE", "NOTIFIER", "EMAIL", "?");
@licType = ("NONE", "FIXED", "FLOATING", "FIXED2");
@licTag = ("", "WRITE", "FULL_TEXT", "RESERVED1");

($c = ars_Login(shift, shift, shift)) || die "login: $ars_errstr";

print "Calling GetListUser and asking for all connected users...\n";

# 0 = current user's info
# 1 = all users' info
# 2 = all connected users' info
#
# default = 0

(@h = ars_GetListUser($c, 2)) || die "ERR: $ars_errstr\n";
print "errstr=$ars_errstr\n";

print "GetListUser returned the following:\n";

foreach $userHash (@h) {
    print "userName: $userHash->{userName}\n";
    print "\tconnectTime: ".localtime($userHash->{connectTime})."\n";
    print "\tlastAccess: ".localtime($userHash->{lastAccess})."\n";
    print "\tnotify mech: $userHash->{defaultNotifyMech} (".$noteMech[$userHash->{defaultNotifyMech}].")\n";
    print "\temail addr: $userHash->{emailAddr}\n";

    for($i = 0; $i <= $#{$userHash->{licenseTag}}; $i++) {
	print "\tlicense \#$i info:\n";

	print "\t\tlicenseTag: ".@{$userHash->{licenseTag}}[$i].
	    " (".$licTag[@{$userHash->{licenseTag}}[$i]].")\n";
	print "\t\tlicenseType: ".@{$userHash->{licenseType}}[$i].
	    " (".$licType[@{$userHash->{licenseType}}[$i]].")\n";
	print "\t\tcurrentLicenseType: ".@{$userHash->{currentLicenseType}}[$i].
	    " (".$licType[@{$userHash->{currentLicenseType}}[$i]].")\n";
    }
}

ars_Logoff($c);
