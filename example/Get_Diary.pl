#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Get_Diary.pl,v 1.2 1998/03/31 15:44:00 jcmurphy Exp $
#
# EXAMPLE
#    Get_Diary.pl
#
# DESCRIPTION
#    Log onto the server and dump all diary entries for a particular 
#    qualification
# 
# AUTHOR
#    jeff murphy
#
# 03/06/96
# 
# $Log: Get_Diary.pl,v $
# Revision 1.2  1998/03/31 15:44:00  jcmurphy
# nada
#
# Revision 1.1  1996/11/21 20:13:54  jcmurphy
# Initial revision
#
#

use ARS;

# Parse command line parameters

($server, $username, $password, $schema, $qualifier, $diaryfield) = @ARGV;
if(!defined($diaryfield)) {
    print "usage: $0 [server] [username] [password] [schema] [qualifier]\n";
    print "       [diaryfieldname]\n";
    exit 1;
}

# Log onto the ars server specified

($ctrl = ars_Login($server, $username, $password)) || 
    die "can't login to the server";

# Load the qualifier structure with a dummy qualifier.

($qual = ars_LoadQualifier($ctrl, $schema, $qualifier)) ||
    die "error in ars_LoadQualifier:\n$ars_errstr";

# Retrieve all of the entry-id's for the qualification.

%entries = ars_GetListEntry($ctrl, $schema, $qual, 0);

# Retrieve the fieldid for the diary field

($diaryfield_fid = ars_GetFieldByName($ctrl, $schema, $diaryfield)) ||
    die "no such field in this schema: '$diaryfield'";

foreach $entry_id (sort keys %entries) {

    print "Entry-id: $entry_id\n";

    # Retrieve the (fieldid, value) pairs for this entry

    %e_vals = ars_GetEntry($ctrl, $schema, $entry_id);

    # Print out the diary entries for this entry-id

    foreach $diary_entry (@{$e_vals{$diaryfield_fid}}) {
	print "\t$diary_entry->{timestamp}\t$diary_entry->{user}\n";
	print "\t$diary_entry->{value}\n";
    }
}

# Log out of the server.

ars_Logoff($ctrl);
