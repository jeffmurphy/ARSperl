#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/GetField.pl,v 1.2 1997/05/07 15:38:19 jcmurphy Exp $
#
# EXAMPLE
#    GetField.pl [server] [username] [password] [schema] [fieldname]
#
# DESCRIPTION
#    Connect to the server and fetch information about the
#    named field. Print the information out.
# 
# NOTES
#    We'll be looking up the field names in the Default Admin View.
#
# AUTHOR
#    jeff murphy
#
# 02/19/97
#
# $Log: GetField.pl,v $
# Revision 1.2  1997/05/07 15:38:19  jcmurphy
# fixed incorrect hash usage
#
# Revision 1.1  1997/02/19 22:41:16  jcmurphy
# Initial revision
#
#
#

use ARS;

# Parse command line parameters

($server, $username, $password, $schema, $fieldname) = @ARGV;
if(!defined($password)) {
    print "usage: $0 [server] [username] [password] [schema] [fieldname]\n";
    exit 1;
}

# Log onto the ars server specified

print "Logging in ..\n";

($ctrl = ars_Login($server, $username, $password)) || 
    die "can't login to the server";

# Fetch all of the fieldnames/ids for the specified schema

print "Fetching field table ..\n";

(%fids = ars_GetFieldTable($ctrl, $schema)) ||
    die "GetFieldTable: $ars_errstr";

# See if the specified field exists.

if(!defined($fids{$fieldname})) {
    print "ERROR: I couldn't find a field called \"$fieldname\" in the 
Default Admin View of schema \"$schema\"\n";
    exit 0;
}

# Get the field info

print "Fetching field information ..\n";

($fieldInfo = ars_GetField($ctrl, $schema, $fids{$fieldname})) ||
    die "GetField: $ars_errstr";

print "Here are some of the field attributes. More are available.

fieldId: $fieldInfo->{fieldId}
createMode: $fieldInfo->{createMode}
dataType: $fieldInfo->{dataType}
defaultVal: $fieldInfo->{defaultVal}
owner: $fieldInfo->{owner}
";

ars_Logoff($ctrl);
