#!/oratest/perl/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/del_all.pl,v 1.1 1997/09/04 17:51:14 jcmurphy Exp $
#
# NAME
#   del_all.pl [server] [user] [password] [pattern]
#
# DESCRIPTION
#   delete all ars objects (*all*!) that match "pattern".
#   be careful!! if you want to delete "HD:.*" items BE SURE
#   to use "^HD:.*" as the pattern.
#
#   BACKUP ALL OBJECTS BEFORE USING THIS SCRIPT!
#
# AUTHOR
#   jeff murphy


use ARS;

($c = ars_Login(shift, shift, shift)) ||
    die "login: $ars_errstr";

$pat = shift;
if($pat eq "") {
    print "Usage: $0 [server] [user] [pwd] [pattern]\n";
    exit 0;
}

print "Fetching..\n";
print "\tActiveLinks\n"; @al = ars_GetListActiveLink($c);
print "\tAdminExtensions\n"; @ae = ars_GetListAdminExtension($c);
print "\tCharMenus\n"; @cm = ars_GetListCharMenu($c);
print "\tEscalations\n"; @es = ars_GetListEscalation($c);
print "\tFilters\n"; @fi = ars_GetListFilter($c);
print "\tSchemas\n"; @sc = ars_GetListSchema($c);

print "Sleeping for 5 seconds. control-c to abort!\n";
sleep(5);

print "\nDeleting Activelinks:\n";

foreach (@al) { 
    if($_ =~ /$pat/) {
	print "\t$_\n"; 
	ars_DeleteActiveLink($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting AdminExtensions:\n";

foreach (@ae) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteAdminExtension($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting CharMenus:\n";

foreach (@cm) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteCharMenu($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting Escalations:\n";

foreach (@es) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteEscalation($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting Filters:\n";

foreach (@fi) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteFilter($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting Schemas:\n";

foreach (@sc) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteSchema($c, $_, 2) || die "$ars_errstr";
    }
}

ars_Logoff($c);

