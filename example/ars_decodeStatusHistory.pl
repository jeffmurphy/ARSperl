#!/oratest/perl/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_decodeStatusHistory.pl,v 1.1 1998/09/11 15:51:42 jcmurphy Exp $
#
# NAME
#   ars_decodeStatusHistory.pl [server] [username] [password] [schema] [eid]
#
# DESCRIPTION
#   retrieves the entryid from the given schema and decodes it's status
#   history values.
#
# AUTHOR
#   Jeff murphy
#
# $Log: ars_decodeStatusHistory.pl,v $
# Revision 1.1  1998/09/11 15:51:42  jcmurphy
# Initial revision
#
#
#

use ARS;

($c = ars_Login(shift, shift, shift)) ||
    die "login: $ars_errstr";

($S, $E) = (shift, shift);

(%f = ars_GetFieldTable($c, $S)) ||
    die "GetFieldTable: $ars_errstr";

(%e = ars_GetEntry($c, $S, $E)) ||
    die "GetEntry: $ars_errstr (no matching entry?)";

($fh = ars_GetField($c, $S, $f{'Status'})) ||
    die "GetField: $ars_errstr (no Status field in this schema?)";

if($fh->{dataType} ne "enum") {
    die "'Status' field is not an enum.\n";
}

@enumvals = @{$fh->{limit}};

print "Status values: ".join(',', @enumvals)."\n";

if(!defined($f{'Status-History'})) {
    die "no Status-History field?\n";
}

if(!defined($e{$f{'Status-History'}})) {
    die "no Status-History field values to decode.\n";
}

@sv = ars_decodeStatusHistory($e{$f{'Status-History'}});

$i = 0;
foreach (@sv) {
    print $enumvals[$i++].": \n";
    print "\tUSER: ".$_->{USER}."\n";
    print "\tTIME: ".localtime($_->{TIME})."\n";
}

ars_Logoff($c);

exit 0;


