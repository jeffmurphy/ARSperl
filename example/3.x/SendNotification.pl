#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/3.x/Attic/SendNotification.pl,v 1.1 1999/10/03 04:10:24 jcmurphy Exp $
#
# NAME
#   SendNotification.pl [server] [user] [message]
#
# DESCRIPTION
#   Send a notification to the given user.
#
# $Log: SendNotification.pl,v $
# Revision 1.1  1999/10/03 04:10:24  jcmurphy
# Initial revision
#
#

use ARS;

ars_NTInitializationServer() || 
                die "couldn't initialize NT environment: $ars_errstr";

ars_NTNotificationServer("smurfland.cit.buffalo.edu", "jcmurphy", "hi joe!", 
			&ARS::NT_CODE_AR_SYSTEM, 
			"TEST00000000001TEST-No Such Schema          nosuchserver.foobar.com") ||
                die "ars_NTNotificationServer: $ars_errstr";

exit 0;

