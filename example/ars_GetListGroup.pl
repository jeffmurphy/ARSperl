#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_GetListGroup.pl,v 1.1 1997/07/23 18:21:29 jcmurphy Exp $
#
# NAME
#   ars_GetListGroup.pl
#
# USAGE
#   ars_GetListGroup.pl [server] [username] [password]
#
# DESCRIPTION
#   Demo of said function. See web page for details or ARS Programmers
#   Manual.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_GetListGroup.pl,v $
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
#
#
#

use ARS;

($c = ars_Login(shift, shift, shift)) || die "login: $ars_errstr";


print "Calling GetListGroup..\n";

($h = ars_GetListGroup($c)) || die "ERR: $ars_errstr\n";
print "errstr=$ars_errstr\n";

print "GetListGroup returned the following groups:\n";

$num = $#{$h->{groupId}};
printf("%4.4s %4.4s %s\n", "ID", "Type", "Names..");
for($i = 0; $i < $num; $i++) {
    printf("%4d %4d ", 
	   @{$h->{groupId}}[$i],
	   @{$h->{groupType}}[$i]);
    printf("[%d] ", $#{@{$h->{groupName}}[$i]});
    for($v=0; $v <= $#{@{$h->{groupName}}[$i]}; $v++) {
	printf("<%s> ", @{@{$h->{groupName}}[$i]}[$v]);
    }
    print "\n";
}

ars_Logoff($c);
