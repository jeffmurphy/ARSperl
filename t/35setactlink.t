#!perl

# perl -w -Iblib/lib -Iblib/arch t/35setactlink.t 

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


#my @objects = sort {lc($a) cmp lc($b)} grep {/\(copy\)/} ars_GetListActiveLink( $ctrl );
#die "ars_GetListActiveLink( ALL ): $ars_errstr\n" if $ars_errstr;
my @objects = ( 'ARSperl Test-alink1 (copy)' );


$| = 1;


foreach my $obj ( @objects ){
	modifyObject( $ctrl, $obj );
}


sub modifyObject {
	my( $ctrl, $obj ) = @_;
	print '-' x 60, "\n";
#	print "GET ACTIVE LINK $obj\n";
	my $wfObj = ars_GetActiveLink( $ctrl, $obj );
	die "ars_GetActiveLink( $obj ): $ars_errstr\n" if $ars_errstr;

	my( $name, $newName );
	$newName = $name = $wfObj->{name};
	$newName =~ s/\(copy\)/(renamed)/;


	my $ret = 1;
	print "SET ACTIVE LINK $name\n";
	$ret = ars_SetActiveLink( $ctrl, $name, {enable => 0, order => 327} );
	die "ars_SetActiveLink( $name ): $ars_errstr\n" if $ars_errstr;
	printStatus( $ret, 2, 'set active link' );
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



