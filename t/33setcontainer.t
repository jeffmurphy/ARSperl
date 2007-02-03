#!perl

# perl -w -Iblib/lib -Iblib/arch t/33setcontainer.t 

use strict;
use warnings;
use ARS;
require './t/config.cache';

print "1..2\n";


my $ctrl = ars_Login( &CCACHE::SERVER, &CCACHE::USERNAME, &CCACHE::PASSWORD );
if (defined($ctrl)) {
	print "ok [1] (login)\n";
} else {
	print "not ok [1] (login $ars_errstr)\n";
	exit(0);
}


#my @containers = sort {lc($a) cmp lc($b)} grep {/\(copy\)/} map {$_->{containerName}} grep {$_->{type} =~ /guide/} ars_GetListContainer( $ctrl, 0, &ARS::AR_HIDDEN_INCREMENT, &ARS::ARCON_ALL );
#die "ars_GetListContainer( ALL ): $ars_errstr\n" if $ars_errstr;
my @containers = ( 'ARSperl Test-FilterGuide1 (copy)' );


$| = 1;


foreach my $ctnr ( @containers ){
	addReferences( $ctrl, $ctnr );
}


sub addReferences {
	my( $ctrl, $ctnr ) = @_;
	print '-' x 60, "\n";
#	print "GET CONTAINER $ctnr\n";
	my $ctnrObj = ars_GetContainer( $ctrl, $ctnr );
	die "ars_GetContainer( $ctnr ): $ars_errstr\n" if $ars_errstr;
#	my $ctnrType = $ctnrObj->{containerType};

	my( $name, $newName );
	$newName = $name = $ctnrObj->{name};
	$newName =~ s/\(copy\)/(renamed)/;
	my @refList = @{$ctnrObj->{referenceList}}; 

	unshift @refList, makeRef(
		dataType => 1,
		type     => 32774,
		label    => '=== BEGIN ===', 
	);

	push @refList, makeRef(
		dataType => 1,
		type     => 32774,
		label    => '-------------', 
	);
	
	if( $ctnrObj->{type} eq 'guide' ){ 
		push @refList, makeRef(
			dataType => 0,
			type     => 5,
			name     => 'ARSperl Test-alink1',
		);
	}elsif( $ctnrObj->{type} eq 'filter_guide' ){ 
		push @refList, makeRef(
			dataType => 0,
			type     => 3,
			name     => 'ARSperl Test-Filter1',
		);
	}

	push @refList, makeRef(
		dataType => 1,
		type     => 32774,
		label    => '==== END ====',
	);

	my $ret = 1;
	print "SET CONTAINER $name\n";
	$ret = ars_SetContainer( $ctrl, $ctnrObj->{name}, {name => $newName, referenceList => \@refList} );
	die "ars_SetContainer( $name ): $ars_errstr\n" if $ars_errstr;
	printStatus( $ret, 2, 'set container' );
}

sub printStatus {
	my( $ret, $num, $text, $err ) = @_;
	if( $ret ){
		print "ok [$num] ($text)\n";
	} else {
		print "not ok [$num] ($text $err)\n";
		exit(0);
	}
}

sub makeRef {
	my( %args ) = @_;
	$args{label} = ''       if !exists $args{label};
	$args{description} = '' if !exists $args{description};
	if( $args{dataType} == 1 ){
		$args{permittedGroups} = [] if !exists $args{permittedGroups};
		$args{value}          = undef  if !exists $args{value};
		$args{value_dataType} = 'null' if !exists $args{value_dataType};
	}
	return \%args;	
}


#ars_Logoff($ctrl);
exit(0);



