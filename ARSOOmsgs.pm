#
#    ARSperl - An ARS v2-v4 / Perl5 Integration Kit
#
#    Copyright (C) 1995-1999 Joel Murphy, jmurphy@acsu.buffalo.edu
#                            Jeff Murphy, jcmurphy@acsu.buffalo.edu
# 
#    This program is free software; you can redistribute it and/or modify
#    it under the terms as Perl itself. 
#    
#    Refer to the file called "Artistic" that accompanies the source distribution 
#    of ARSperl (or the one that accompanies the source distribution of Perl
#    itself) for a full description.
#
#    Official Home Page: 
#    http://arsinfo.cit.buffalo.edu/perl
#
#    Mailing List (must be subscribed to post):
#    arsperl@arsinfo.cit.buffalo.edu
#

# .catch is a hash ref

sub internalDie {
  my $this = shift;
  my $msg = shift;

  if(defined(&Carp::confess)) {
    Carp::confess($msg."\n");
  } 
  die $msg;
}

sub internalWarn {
  my $this = shift;
  my $msg = shift;

  if(defined(&Carp::confess)) {
    Carp::cluck($msg."\n");
  } else {
    warn $msg;
  }
}

sub initCatch {
  my $this = shift;

  $this->setCatch(ARS::AR_RETURN_WARNING => "internalWarn");
  $this->setCatch(ARS::AR_RETURN_ERROR   => "internalDie");
  $this->setCatch(ARS::AR_RETURN_FATAL   => "internalDie");
}

sub setCatch {
  my $this = shift;
  my $type = shift;
  my $func = shift;

  $this->{'.catch'}->{$type} = $func;
}

sub tryCatch {
  my $this = shift;

  if(defined($this->{'.catch'}) && ref($this->{'.catch'}) eq "HASH") {
    foreach (ARS::AR_RETURN_WARNING, ARS::AR_RETURN_ERROR, 
	     ARS::AR_RETURN_FATAL) {
      if(defined($this->{'.catch'}->{$_}) && $this->hasMessageType($_)) {
	&{$this->{'.catch'}->{$_}}($_, $this->messages());
      }
    }
  }
}

sub messages {
  my(%mTypes) = ( 0 => "OK", 1 => "WARNING", 2 => "ERROR", 3 => "FATAL",
		  4 => "INTERNAL ERROR",
		  -1 => "TRACEBACK");
  my ($this, $type, $str) = (shift, shift, undef);

  return $ars_errstr if(!defined($type));

  for(my $i = 0; $i < $ARS::ars_errhash{numItems}; $i++) {
    if(@{$ARS::ars_errhash{'messageType'}}[$i] == $type) {
      $s .= sprintf("[%s] %s (ARERR \#%d)", 
		    $mTypes{@{$ARS::ars_errhash{messageType}}[$i]}, 
		    @{$ARS::ars_errhash{messageText}}[$i], 
		    @{$ARS::ars_errhash{messageNum}}[$i]); 
      $s .= "\n" if($i < $ARS::ars_errhash{numItems}-1); 
    }
  }
  return $s;
}


sub errors {
  my $this = shift;
  return $this->messages(&ARS::AR_RETURN_ERROR);
}

sub warnings {
  my $this = shift;
  return $this->messages(&ARS::AR_RETURN_WARNING);
}

sub fatals {
  my $this = shift;
  return $this->messages(&ARS::AR_RETURN_FATAL);
}

sub hasMessageType {
  my ($this, $t) = (shift, shift);
  return $t if !defined($t);
  for(my $i = 0; $i < $ARS::ars_errhash{numItems}; $i++) {
    return 1 
      if(@{$ARS::ars_errhash{'messageType'}}[$i] == $t);
  }
  return 0;
}

sub hasFatals {
  my $this = shift;
  return $this->hasMessageType(&ARS::AR_RETURN_FATAL);
}

sub hasErrors {
  my $this = shift;
  return $this->hasMessageType(&ARS::AR_RETURN_ERROR);
}

sub hasWarnings {
  my $this = shift;
  return $this->hasMessageType(&ARS::AR_RETURN_WARNING);
}

1;
