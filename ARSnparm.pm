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

# the following two routines 
#            make_attributes()
#            rearrange()
# were borrowed from the CGI module. these routines implement
# named parameters.
# (http://stein.cshl.org/WWW/software/CGI/cgi_docs.html) 
# Copyright 1995-1997 Lincoln D. Stein.  All rights reserved.

sub make_attributes {
    my($attr) = @_;
    return () unless $attr && ref($attr) && ref($attr) eq 'HASH';
    my(@att);
    foreach (keys %{$attr}) {
        my($key) = $_;
        $key=~s/^\-//;     # get rid of initial - if present
        $key=~tr/a-z_/A-Z-/; # parameters are upper case, use dashes
        push(@att,$attr->{$_} ne '' ? qq/$key="$attr->{$_}"/ : qq/$key/);
    }
    return @att;
}

sub rearrange {
  my($order,@param) = @_;
  return () unless @param;
  my($param);

  unless (ref($param[0]) eq 'HASH') {
    return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');
    $param = {@param};                # convert into associative array
  } else {
    $param = $param[0];
  }
  
  foreach (keys %{$param}) {
    my $old = $_;
    s/^\-//;     # get rid of initial - if present
    tr/a-z/A-Z/; # parameters are upper case
    next if $_ eq $old;
    $param->{$_} = $param->{$old};
    delete $param->{$old};
  }
  
  my(@return_array);
  my($key)='';
  foreach $key (@$order) {
    my($value);
    # this is an awful hack to fix spurious warnings when the
    # -w switch is set.
    if (ref($key) && ref($key) eq 'ARRAY') {
      foreach (@$key) {
	last if defined($value);
	$value = $param->{$_};
	delete $param->{$_};
      }
    } else {
      $value = $param->{$key};
      delete $param->{$key};
    }
    push(@return_array,$value);
  }
  push (@return_array,make_attributes($param)) if %{$param};
  return (@return_array);
}

1;
