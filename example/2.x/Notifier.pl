#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/2.x/Attic/Notifier.pl,v 1.2 1997/02/13 18:41:21 jcmurphy Exp $
#
# USAGE
#   Notifier.pl 
#
# DESCRIPTION
#   connect to the specified notification server and 
#   list pending notifications. once those are listed,
#   continue to listen for new notifications until killed.
#
#   ARServer 2.x version. (uses pipes and the ntclientd process)
#
#   be sure to run ntclientd *before* running this script.
#
# AUTHOR
#   jeff murphy

use ARS;
use FileHandle;
use Fcntl;

$SIG{PIPE} = sub {
    print "sigpipe caught. remote side died?\n";
    CleanUp();
};

$SIG{INT} = sub {
    print "control-c caught.\n";
    CleanUp();
};

$fifo = "/tmp/arntfifo.$$";

($user, $password) = @ARGV;
if(!defined($password)) {
    print "Usage: $0 <user> <password>\n";
    exit 0;
}

print "$0
Be sure to run \"ntclientd\" on this machine before running
this script or you will get an error.

Press control-c to abort.
";

# Basic script layout:
#
# create fifo
# open it (with no-delay)
# forever {
#   read from fifo
#   print messages
# }

# FIRST: setup the fifo.

print "Setting up fifo file \"$fifo\" ..\n";

unless(-p $fifo) {
    unlink $fifo;
    system('mkfifo', $fifo) && die "mkfifo: $!";
    chmod(0666, $fifo) || die "chmod: $!";

    # we open it as NDELAY so the sysopen() call wont block
    # (there wont be a writer until the RegisterClient call).
    # alternately, we could go with a two-process mode.. but
    # i'm trying to keep this simple.

    sysopen(FD, $fifo, O_NDELAY|O_RDONLY, 0666) || die "sysopen: $!";

    # reset the flags so that sysread() will block for us

    fcntl(FD, F_SETFL, O_RDONLY) || 
	die "fcntl: $!";
}

# SECOND: register with the NT server to receive notifications.

print "Initializing client ..\n";

ars_NTInitializationClient() || die "NTInitializationClient: $ars_errstr";

print "Registering Client ..\n";

ars_NTRegisterClient($user, $password, $fifo) || 
    die "\n\nars_NTRegisterClient:\n$ars_errstr\n\nDid you remember to start \"ntclientd\" before running this script?\n";

print "Registered.\n";

# THIRD: read from the fifo and print anything we get.
# the message size we will get back will be 511 bytes (NT_MAX_FULL_MESSAGE)

while(1) {
    ($rv = sysread(FD, $buf, 511)) || die "sysread: $!";
    if($rv == 511) {
	$buf =~ s/\x00.*//g;  # clear everything after first NULL

	# at the end of the message there appears to be some
	# garbage at the end that consists of 0x0AD0 but is before
	# the null .. lets get rid of it..

	$buf =~ s/\x0a\xd0.*//g;

	print "------ $rv bytes of DATA read ------\n";
	print "$buf";
	print "\n---END OF DATA---\n";
    } else {
	print "WARNING: read $rv bytes of data. expected 511.\n";
    }
}

CleanUp();

exit 0;

sub CleanUp {
    print "cleaning up.\n";
    ars_NTDeregisterClient($user, $password, $fifo) ||
	warn "ars_NTDeRegisterClient: $ars_errstr";
    ars_NTTerminationClient() ||
	warn "ars_NTTerminationClient: $ars_errstr";
    close(FD);
    unlink($fifo);
    print "exiting.\n";
    exit 0;
}

sub die {
    my $msg = shift;
    print "$msg\n";
    CleanUp();
}
