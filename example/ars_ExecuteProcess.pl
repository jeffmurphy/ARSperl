#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_ExecuteProcess.pl,v 1.1 1997/07/23 18:21:29 jcmurphy Exp $
#
# NAME
#   ars_ExecuteProcess.pl
#
# USAGE
#   ars_ExecuteProcess.pl [server] [username] [password] ["process"]
# 
# EXAMPLE
#   ars_ExecuteProcess.pl arserver foobar barfoo "ls -l /"
#
# DESCRIPTION
#   Execute given command on remote arserver. Requires admin account to work.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_ExecuteProcess.pl,v $
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
#
#
#

use ARS;

$c = ars_Login(shift, shift, shift);

$b = shift;
(($num, $str) = ars_ExecuteProcess($c, $b)) || print "ERR: $ars_errstr\n";
print "gotit: $ars_errstr\n";

print "returnCode=<$num> returnString=<$str>\n";

ars_Logoff($c);
