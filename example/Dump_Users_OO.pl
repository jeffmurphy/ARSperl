#!/usr/local/bin/perl -w
#
# $Header: /cvsroot/arsperl/ARSperl/example/Dump_Users_OO.pl,v 1.1 1999/05/05 19:57:40 rgc Exp $
#
# NAME
#   Dump_Users_OO.pl [server] [username] [password]
#
# DESCRIPTION
#   Example of Object Oriented programming layered on top of ARSperl
#
# AUTHOR
#   Jeff Murphy
#
# $Log: Dump_Users_OO.pl,v $
# Revision 1.1  1999/05/05 19:57:40  rgc
# Initial revision
#

use strict;
use ARS;
require Carp;

sub mycatch { 
  my $type = shift;
  my $msg = shift;
  Carp::confess("caught something: type=$type msg=$msg\n"); 
  exit;
}

my $connection = new ARS (-server   => shift,
			  -username => shift, 
			  -password => shift,
			  -catch => { ARS::AR_RETURN_ERROR => "main::mycatch" },
			  -ctrl => undef,
			  -debug => 1);

print "Opening \"User\" form ..\n";

my ($u) = $connection->openForm(-form => "User");

$u->setSort("Login Name", &ARS::AR_SORT_ASCENDING);

my @entries = $u->query(); # empty query means "get everything"

printf("%-30s %-45s\n", "Login Name", "Full name");
foreach my $id (@entries) {
  my($fullname, $loginname) = $u->get($id, ['Full Name', 'Login Name'] );
  printf("%-30s %-45s\n", $loginname, $fullname);
}



exit 0;
