#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/AddUsersToGroup.pl,v 1.2 1998/09/14 20:48:59 jcmurphy Exp $
#
# NAME
#   AddUsersToGroup server user password group user1 [user2] ...
#
# DESCRIPTION
#   add given users to specified group
#
# AUTHOR
#   jeff murphy
#
# $Log: AddUsersToGroup.pl,v $
# Revision 1.2  1998/09/14 20:48:59  jcmurphy
# changed usage, comments. fixed bug.
#
#

use ARS;

die "usage: AddUserToGroup server username password group user1 [user2] ...\n" unless ($#ARGV >= 4);

($server, $user, $pass, $group, @users) = (shift, shift, shift, shift, @ARGV);

($c = ars_Login($server, $user, $pass)) ||
    die "ars_Login: $ars_errstr";

(%uf = ars_GetFieldTable($c, "User")) ||
    die "ars_GetFieldTable(User): $ars_errstr";

(%gf = ars_GetFieldTable($c, "Group")) ||
    die "ars_GetFieldTable(Group): $ars_errstr";

($q = ars_LoadQualifier($c, "Group", "'Group name' = \"$group\"")) ||
    die "ars_LoadQualifier(Group): $ars_errstr";
@e = ars_GetListEntry($c, "Group", $q, 0);
die "No such group \"$group\"? ($ars_errstr)\n" if ($#e == -1);
(%v = ars_GetEntry($c, "Group", $e[0])) ||
    die "ars_GetEntry(Group): $ars_errstr";

$group_id = $v{$gf{'Group id'}};

foreach (@users) {
    print "Adding $_ to $group .. \n";

    ($q = ars_LoadQualifier($c, "User", "'Login name' = \"$_\"")) ||
	die "ars_LoadQualifier: $ars_errstr";
    @e = ars_GetListEntry($c, "User", $q, 0);
    die "No User record for $_? ($ars_errstr)\n" if ($#e == -1);

    (%v = ars_GetEntry($c, "User", $e[0])) ||
	die "ars_GetEntry: $ars_errstr";

    $cg = $v{$uf{'Group list'}};

    if(($cg =~ /^$group_id;/) || ($cg =~ /\s$group_id;/)) {
	print "\talready a member of $group\n";
	next;
    }

    print "\tcurrent group list: $cg\n";
    
    if($cg ne "") {
	$cg .= " $group_id;";
    } else {
	$cg = "$group_id;";
    }

    print "\tnew group list    : $cg\n";

    ars_SetEntry($c, "User", $e[0], 0, $uf{'Group list'}, $cg) || 
	die "ars_SetEntry(User): $ars_errstr";

}

ars_Logoff($c);

exit 0;
