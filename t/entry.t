#!./perl

# 
# test out creating and deleting an entry
#

use ARS;
require './t/config';

# notice the use of a custom error handler.

sub mycatch {
  my ($type, $msg) = (shift, shift);
  die "not ok ($msg)\n";
}

if(ars_APIVersion() >= 4) {
  print "1..8\n";
} else {
  print "1..7\n";
}

my $c = new ARS(-server => $SERVER, 
		-username => $USERNAME,
                -password => $PASSWORD,
                -catch => { ARS::AR_RETURN_ERROR => "main::mycatch",
                            ARS::AR_RETURN_WARNING => "main::mycatch",
                            ARS::AR_RETURN_FATAL => "main::mycatch"
                          },
		-debug => undef);
print "ok [1]\n";

my $s  = $c->openForm(-form => "ARSperl Test");
print "ok [2]\n";

# test 1:  create an entry

my $id = $s->create("-values" => { 'Submitter' => $USERNAME,
				 'Status' => 'Assigned',
				 'Short Description' => 'A test submission'
			       }
		   );
print "ok [3]\n";

# test 2: retrieve the entry to see if it really worked

my($v) = $s->get(-entry => $id, -field => [ 'Status' ] );
if($v ne "Assigned") {
  print "not ok [4 $v]\n";
} else {
  print "ok [4]\n";
}

# test 3: set the entry to something different

$s->set(-entry => $id, -values => { 'Status' => 'Rejected' });
print "ok [5]\n";

# test 4: retrieve the value and check it

$v = $s->get(-entry => $id, -field => [ 'Status' ] );
if($v ne "Rejected") {
  print "not ok [6 $v]\n";
} else {
  print "ok [6]\n";
}

# test 6: add an attachment.

if(ars_APIVersion() >= 4) {
  my $filename = "t/aptest40.def";

  $s->set(-entry => $id, 
	  "-values" => { 'Attachment Field' => 
		       { file => $filename,
		         size => (stat($filename))[7]
		       }
		     }
	 );

  # retrieve it "in core" 

  my $ic = $s->getAttachment(-entry => $id,
			     -field => 'Attachment Field');

  open(FD, $filename) || die "not ok [open $!]\n";
  my $fc;
  while(<FD>) {
    $fc .= $_;
  }
  close(FD);

  if($fc ne $ic) {
    print "not ok [attach cmp]\n";
  } else {
    print "ok [attach test]\n";
  }
}

# test 5: finally, delete the newly created entry

$s->delete(-entry => $id);
	   
print "ok [7]\n";

exit 0;

