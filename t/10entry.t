#!./perl

# 
# test out creating and deleting an entry
#

use ARS;
require './t/config.cache';

# notice the use of a custom error handler.

sub mycatch {
  my ($type, $msg) = (shift, shift);
  die "not ok ($msg)\n";
}

if(ars_APIVersion() >= 4) {
  print "1..9\n";
} else {
  print "1..7\n";
}

my $c = new ARS(-server => &CCACHE::SERVER, 
		-username => &CCACHE::USERNAME,
                -password => &CCACHE::PASSWORD,
                -catch => { ARS::AR_RETURN_ERROR => "main::mycatch",
                            ARS::AR_RETURN_WARNING => "main::mycatch",
                            ARS::AR_RETURN_FATAL => "main::mycatch"
                          },
		-debug => undef);
print "ok [1 cnx]\n";

my $s  = $c->openForm(-form => "ARSperl Test");
print "ok [2 openform]\n";

# test 1:  create an entry

my $id = $s->create("-values" => { 'Submitter' => &CCACHE::USERNAME,
				 'Status' => 'Assigned',
				 'Short Description' => 'A test submission'
			       }
		   );
print "ok [3 create]\n";

# test 2: retrieve the entry to see if it really worked

my($v) = $s->get(-entry => $id, -field => [ 'Status' ] );
if($v ne "Assigned") {
  print "not ok [4 $v]\n";
} else {
  print "ok [4 get]\n";
}

# test 3: set the entry to something different

$s->set(-entry => $id, -values => { 'Status' => 'Rejected' });
print "ok [5 set]\n";

# test 4: retrieve the value and check it

$v = $s->get(-entry => $id, -field => [ 'Status' ] );
if($v ne "Rejected") {
  print "not ok [6 $v]\n";
} else {
  print "ok [6 get]\n";
}

# test 6: add an attachment to the existing entry

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
    print "not ok [attach (create) cmp]\n";
  } else {
    print "ok [attach (set) test ; fclen=", length($fc),
		" iclen=", length($ic), "]\n";
  }
}

# test 7: create a new entry with an attachment

if(ars_APIVersion() >= 4) {
  my $filename = "t/aptest40.def";

  my $nid = $s->create(
		       "-values" => { 'Attachment Field' => 
				      { file => $filename,
					size => (stat($filename))[7]
				      },
				      'Submitter' => &CCACHE::USERNAME,
				      'Status' => 'Assigned',
				      'Short Description' => 'attach-create'
				    }
		      );

  # retrieve it "in core" 

  my $ic = $s->getAttachment(-entry => $nid,
			     -field => 'Attachment Field');

  open(FD, $filename) || die "not ok [open $!]\n";
  my $fc;
  while(<FD>) {
    $fc .= $_;
  }
  close(FD);

  if($fc ne $ic) {
    print "not ok [attach (create) cmp]\n";
  } else {
    print "ok [attach (create) test ; fclen=", length($fc),
		" iclen=", length($ic), "]\n";
  }

  $s->delete(-entry => $nid);
}


# test 8: finally, delete the newly created entry

$s->delete(-entry => $id);
	   
print "ok [8 delete]\n";

exit 0;

