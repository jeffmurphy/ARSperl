#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/3.x/Attic/SendNotification.pl,v 1.3 2000/07/03 15:01:44 jcmurphy Exp $
#
# NAME
#   SendNotification.pl [server] [user] [message]
#
# DESCRIPTION
#   Send a notification to the given user.
#
# $Log: SendNotification.pl,v $
# Revision 1.3  2000/07/03 15:01:44  jcmurphy
# *** empty log message ***
#
# Revision 1.2  2000/07/03 14:58:30  jcmurphy
# *** empty log message ***
#
# Revision 1.1  1999/10/03 04:10:24  jcmurphy
# Initial revision
#
#

use ARS;

if($#ARGV != 2) {
	die "usage: SendNotification.pl [server] [user] [message]\nIf your message contains space, surround it with quotes so it appears\nas a single argument.\n";
}

ars_NTInitializationServer() || 
                die "couldn't initialize NT environment: $ars_errstr";

ars_NTNotificationServer(shift, shift, shift, 
			&ARS::NT_CODE_AR_SYSTEM, 
			"TEST00000000001TEST-No Such Schema          nosuchserver.foobar.com") ||
                die "ars_NTNotificationServer: $ars_errstr";

exit 0;

