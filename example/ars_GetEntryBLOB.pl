#!/oratest/perl/bin/perl

use ARS;

$id = "000000000000002";
$S  = "ARSperl Test";

$c = ars_Login(shift, shift, shift);
%f = ars_GetFieldTable($c, $S);
foreach (keys %f) {
  $r{$f{$_}} = $_;
}
%v = ars_GetEntry($c, $S, $id);
foreach (keys %v) {
  print "$r{$_} = $v{$_}\n";
  dh($v{$_}) if $r{$_} =~ /Attachment/;
  ra($_) if $r{$_} =~ /Attachment/;
}

ars_Logoff($c);

exit 0;

#sub AR_LOC_FILENAME { 1;}
#sub AR_LOC_BUFFER { 2;}

sub ra {
  my $fid = shift;

  print "\t[Retrieving attachment.]\n";

  
  # file: $a = 0 || 1
  # buff: $a = undef || attachment


  unlink('/tmp/attachtest', '/tmp/attachtest2');

  ars_GetEntryBLOB($c, $S, $id,
		   $fid, 
		   ARS::AR_LOC_FILENAME,
		   "/tmp/attachtest") || 
		     die ("GetEntryBLOB: $ars_errstr");

  my $a = ars_GetEntryBLOB($c, $S, $id,
			   $fid, 
			   ARS::AR_LOC_BUFFER);

  die "GetEntryBLOB: $ars_errstr" if(!defined($a));
  print "\tattachment size = ".length($a)."\n";
  open(FD, ">/tmp/attachtest2") || die "open: $!";
  print FD $a;
  close(FD);
}

sub dh {
  my $h = shift;
  foreach (keys %$h) {
    print "\t$_ = $h->{$_}\n";
  }
}
