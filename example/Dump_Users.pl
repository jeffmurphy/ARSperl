#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Dump_Users.pl,v 1.1 1996/11/21 20:13:51 jcmurphy Exp $
#
# EXAMPLE
#    Dump_Users.pl
#
# DESCRIPTION
#    Log onto the server and dump all users in the "User" schema. 
# 
# NOTES
#    This might require special permission for the username you login
#    as, depending upon how the ar admininstrator has the User schema
#    configured. 
#
# AUTHOR
#    jeff murphy
#
# 01/12/96
#
# $Log: Dump_Users.pl,v $
# Revision 1.1  1996/11/21 20:13:51  jcmurphy
# Initial revision
#
#

use ARS;

$SCHEMA = "User";

# Parse command line parameters

($server, $username, $password) = @ARGV;
if(!defined($password)) {
    print "usage: $0 [server] [username] [password]\n";
    exit 1;
}

# Log onto the ars server specified

($ctrl = ars_Login($server, $username, $password)) || 
    die "can't login to the server";

# Load the qualifier structure with a dummy qualifier.

($qual = ars_LoadQualifier($ctrl,$SCHEMA,"(1 = 1)")) ||
    die "error in ars_LoadQualifier";

# Retrieve all of the entry-id's for the schema.

%entries = ars_GetListEntry($ctrl, $SCHEMA, $qual, 0);

# Retrieve the fieldid's for the "Login name" and "Full name" fields.

$loginname_fid = ars_GetFieldByName($ctrl, $SCHEMA, "Login name") ||
    die "no such field in this schema: 'Login name'";

$fullname_fid = ars_GetFieldByName($ctrl, $SCHEMA, "Full name") ||
    die "no such field in this schema: 'Full name'";

# Loop over all of the entries (in ascending order)

printf("%-30s %-45s\n", "Login name", "Full name");

foreach $entry_id (sort keys %entries) {

    # Retrieve the (fieldid, value) pairs for this entry

    %e_vals = ars_GetEntry($ctrl, $SCHEMA, $entry_id);

    # Print out the Login name and Full name for each record

    printf("%-30s %-45s\n", $e_vals{$loginname_fid}, $e_vals{$fullname_fid});
}

# Log out of the server.

$profile = ars_GetProfileInfo($ctrl);

ars_Logoff($ctrl);

$endTime = time();
print "startTime = ".localtime($profile->{startTime})."\n";
print "endTime   = ".localtime(time())."\n";
print "run time  = ".($endTime - $profile->{startTime})." (secs)\n";
print "queries   = ".$profile->{queries}."\n";
print "rate      = ".($profile->{queries}/($endTime-$profile->{startTime}))." Q/S\n";

