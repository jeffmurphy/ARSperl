# ROUTINE
#   Decode_QualHash($ctrl, $schema, $qualhash)
#
# DESCRIPTION
#   Takes that hash that is returned by
#   ars_perl_qualifier() and converts it
#   into something (more or less) readable
#
# NOTES
#   This routine over parenthesises, but should
#   yield correct results nonetheless.
#
# RETURNS
#   a scalar on success
#   undef on failure
#
# AUTHOR
#   jeff murphy

sub ars_Decode_QualHash {
    my $c = shift;
    my $s = shift;
    my $q = shift;
    my $fids;
    my %fids_orig;
    my $fieldName;

    print "ars_Decode_QualHash(c=$c, s=$s, q=$q)\n" if $debug;

    if($c && $s && $q) {
	(%fids_orig = ars_GetFieldTable($c, $s)) ||
	    die "GetFieldTable: $ars_errstr";
	foreach $fieldName (keys %fids_orig) {
	    $fids{$fids_orig{$fieldName}} = $fieldName;
	}
	return ars_DQH($q, %fids);
    }
    print "WARNING: ars_Decode_QualHash: invalid params\n";

    return undef;
}

sub ars_DQH {
    my $h    = shift;
    my $fids = shift;
    my $e    = undef;

    print "ars_DQH(h=$h, fids=$fids)\n" if $debug;

    if($h) {

	print "\n
    left   = $h->{left}
    oper   = $h->{oper}
    right  = $h->{right}
    not    = $h->{not}
    rel_op = $h->{rel_op}\n\n" if $debug;

	if($h->{oper} eq "and") {
	    print "handling AND\n" if $debug;
	    $e .= "(".ars_DQH($h->{left}, $fids)." AND ".ars_DQH($h->{right}, $fids).")";
	} 
	elsif($h->{oper} eq "or") {
	    $e .= "(".ars_DQH($h->{left}, $fids)." OR ".ars_DQH($h->{right}, $fids).")";
	}
	elsif($h->{oper} eq "not") {
	    $e .= "( NOT (".ars_DQH($h->{not}, $fids).") )";
	}
	elsif($h->{oper} eq "rel_op") {
	    $e .= "(".ars_DQH($h->{rel_op}, $fids).")";
	}
	else {
	    $e .= "(".Decode_FVoAS($h->{left}, $fids)." ".$h->{oper}." ".Decode_FVoAS($h->{right}, $fids).")";
	}
    } else {
	print "WARNING: ars_DQH: invalid params\n";
    }

    return $e;
}

sub Decode_FVoAS {
    my $h = shift;
    my $fids = shift;
    my $e = "";

    # a field is referenced

    if($h->{fieldId}) {
	print "\tfieldId: $h->{fieldId}\n" if $debug;
	if($fids{$h->{fieldId}} ne "") {
	    $e = "'".$fids{$h->{fieldId}}."'";
	} else {
	    $e = "'".$h->{fieldId}."'";
	}
    }

    # a transaction field reference

    elsif($h->{TR_fieldId}) {
	print "\tTR_fieldId: $h->{TR_fieldId}\n" if $debug;
	$e = "'TR.".$fids{$h->{TR_fieldId}}."'";
    }

    # a database value field reference

    elsif($h->{DB_fieldId}) {
	print "\tDB_fieldId: $h->{DB_fieldId}\n" if $debug;
	$e = "'DB.".$fids{$h->{DB_fieldId}}."'";
    }

    # a value

    elsif($h->{value}) {
	if($h->{value} =~ /\D/) {
	    $e = '"'.$h->{value}.'"';
	} else {
	    $e = $h->{value};
	}
    }

    # an arithmetic expression
    # not implemented. see code in GetField.pl for
    # example of decoding. i dont think ARS allows
    # arith in the qualification (i think aradmin will
    # give an error) so this is irrelevant to this
    # demo.

    elsif($h->{arith}) {
	$e = "arithOp";
    }

    # a set of values (used for the "IN" operator)
    # i've never really seen the "IN" keyword used 
    # either.. so i'll just flag it and dump something
    # semi-appropriate.

    elsif($h->{valueSet}) {
	$e = "valueSet(".join(',', @{$h->{valueSet}}).")";
    }

    # a local variable. this is in the API, but i dont think
    # it's a real feature that is available.. perhaps
    # something that remedy is working on? hmm..

    elsif($h->{variable}) {
	$e = "variable($h->{variable})";
    }

    # an external query on another schema. not sure
    # how this works so we'll let it go for now..
    # i can't think of how this works for a filter
    # or active link.. perhaps this is more "in development"
    # stuff at remedy? either that or this structure is also
    # used for query menus maybe..

    elsif($h->{queryValue}) {
	$e = "external_query";
    }

    # a query against a value of a field in 
    # the current schema

    elsif($h->{queryCurrent}) {
	if($fids{$h->{queryCurrent}} ne "") {
	    $e = "current('".$fids{$h->{queryCurrent}}."')";
	} else {
	    $e = "current('".$h->{queryCurrent}."')";
	}
    }
    return $e;
}

1;
