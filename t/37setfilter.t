#!perl

# perl -w -Iblib/lib -Iblib/arch t/37setfilter.t 

use strict;
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


#my @objects = sort {lc($a) cmp lc($b)} grep {/\(copy\)/} ars_GetListFilter( $ctrl );
#die "ars_GetListFilter( ALL ): $ars_errstr\n" if $ars_errstr;
my @objects = ( 'ARSperl Test-Filter1 (copy)' );


$| = 1;


foreach my $obj ( @objects ){
	modifyObject( $ctrl, $obj );
}


sub modifyObject {
	my( $ctrl, $obj ) = @_;
	print '-' x 60, "\n";
#	print "GET FILTER $obj\n";
	my $wfObj = ars_GetFilter( $ctrl, $obj );
	die "ars_GetFilter( $obj ): $ars_errstr\n" if $ars_errstr;

	my( $name, $newName );
	$newName = $name = $wfObj->{name};
	$newName .= '_TEST';


	my $ret = 1;
	print "SET FILTER $name\n";
	$ret = ars_SetFilter( $ctrl, $wfObj->{name}, {name => $newName, enable => 0, order => 327} );
	die "ars_SetFilter( $name ): $ars_errstr\n" if $ars_errstr;
	printStatus( $ret, 2, 'set filter' );
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




