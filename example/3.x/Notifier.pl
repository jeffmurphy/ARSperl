#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/3.x/Attic/Notifier.pl,v 1.1 1997/02/13 15:52:43 jcmurphy Exp $
#
# USAGE
#   notifier.pl 
#
# DESCRIPTION
#   connect to the specified notification server and 
#   list pending notifications. once those are listed,
#   continue to listen for new notifications until killed.
#
# AUTHOR
#   jeff murphy

use ARS;
use Socket;

$SIG{INT} = sub {
    print "control-c caught.\n";
    print "cleaning up.\n";
    ars_NTDeregisterServer($server, $user, $password) ||
	warn "ars_NTDeRegisterServer: $ars_errstr";
    ars_NTTerminationServer() ||
	warn "ars_NTTerminationServer: $ars_errstr";
    close(Server);
    print "exitting.\n";
    exit 0;
};

$port = 2468;

($user, $password, $server) = @ARGV;
if(!defined($password)) {
    print "Usage: $0 <user> <password> [server]\n";
    exit 0;
}

print "$0\nPress control-c to abort.\n";

# Basic script layout:
#
# create socket
# attach to server
# loop forever:
#   listen on socket for incoming messages
#   print messages
# end

# FIRST: setup the socket and listen for incoming connections.

print "Setting up server socket on port $port..\n";

socket(Server, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
    || die "socket: $!";
setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1))
    || die "setsockopt: $!";
bind(Server, sockaddr_in($port, INADDR_ANY))
    || die "bind: $!";
listen(Server,SOMAXCONN)
    || die "listen: $!";

# SECOND: register with the NT server to receive notifications.

# ars_NTRegisterServer(server, username, password, communications, port, protocol);
#
# where 
#    communications is currently always 2 (sockets)
#    port is an arbitrary number > 1024 that is not already in use
#    protocol is currently always 1 (tcp)

ars_NTInitializationServer() || die "NTInitializationServer: $ars_errstr";

print "Registering with NTServer on host $server ..\n";

ars_NTRegisterServer($server, $user, $password, 2, $port, 1) || 
    die "ars_NTRegisterServer: $ars_errstr";

print "Registered.\n";


# THIRD: poll for incoming connections and handle them. note: this
# is done synchronously.. no sub processes are forked. see the "perlipc"
# man page for an asynchronous model script.

while(1) {
    my $name = gethostbyaddr($iaddr,AF_INET);
    my $done;
    my $igot;

    # we are listening on Server. we accept to Client.

    print "Server: waiting for incoming connection\n";

    $paddr = accept(Client,Server);

    my($port,$iaddr) = sockaddr_in($paddr);

    if(!defined($paddr)) {
	print "accept error: $!\n";
	ars_NTTerminationServer();
	close(Server);
	exit(-1);
    }

    print "connection from $name [", inet_ntoa($iaddr), "] at port $port\n";
    
    sysread(Client, $buf, 1024) || print "sysread: $!";
    print "------DATA------\n";
    print "$buf\n";
    syswrite(Client,"ack",3) || print "syswrite: $!\n";
    print "\n---END OF DATA---\n";
}

exit 0;

