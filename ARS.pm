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

# Routines for grabbing the current error message "stack" 
# by simply referring to the $ars_errstr scalar.

package ARS::ERRORSTR;
sub TIESCALAR {
    bless {};
}
sub FETCH {
    my($s, $i) = (undef, undef);
    my(%mTypes) = ( 0 => "OK", 1 => "WARNING", 2 => "ERROR", 3 => "FATAL",
		    4 => "INTERNAL ERROR",
		   -1 => "TRACEBACK");
    for($i = 0; $i < $ARS::ars_errhash{numItems}; $i++) {

	# If debugging is not enabled, don't show traceback messages

	if($ARS::DEBUGGING == 1) {
	    $s .= sprintf("[%s] %s (ARERR \#%d)",
			  $mTypes{@{$ARS::ars_errhash{messageType}}[$i]},
			  @{$ARS::ars_errhash{messageText}}[$i],
			  @{$ARS::ars_errhash{messageNum}}[$i]);
	    $s .= "\n" if($i < $ARS::ars_errhash{numItems}-1);
	} else {
	    if(@{$ARS::ars_errhash{messageType}}[$i] != -1) {
		$s .= sprintf("[%s] %s (ARERR \#%d)",
			      $mTypes{@{$ARS::ars_errhash{messageType}}[$i]},
			      @{$ARS::ars_errhash{messageText}}[$i],
			      @{$ARS::ars_errhash{messageNum}}[$i]);
		$s .= "\n" if($i < $ARS::ars_errhash{numItems}-1);
	    }
	}
    }
    return $s;
}

package ARS;

require 5.000;
use strict "vars";
require Exporter;
require DynaLoader;
require Carp unless $^S;
use AutoLoader 'AUTOLOAD';
use Config;

require 'ARSar-h.pm';
require 'ARSarerrno-h.pm';
require 'ARSnt-h.pm';
require 'ARSnterrno-h.pm';
require 'ARSnparm.pm';
require 'ARSOOform.pm';
require 'ARSOOmsgs.pm';
require 'ARSOOsup.pm';

@ARS::ISA = qw(Exporter DynaLoader);
@ARS::EXPORT = qw(isa_int isa_float isa_string ars_LoadQualifier ars_Login 
ars_Logoff ars_GetListField ars_GetFieldByName ars_GetFieldTable 
ars_DeleteEntry ars_GetEntry ars_GetListEntry ars_GetListSchema 
ars_GetListServer ars_GetActiveLink ars_GetCharMenuItems ars_GetSchema 
ars_GetField ars_simpleMenu ars_GetListActiveLink ars_SetEntry 
ars_perl_qualifier ars_Export ars_GetListFilter ars_GetListEscalation 
ars_GetListCharMenu ars_GetListAdminExtension ars_padEntryid ars_GetFilter 
ars_GetProfileInfo ars_Import ars_GetCharMenu ars_GetServerStatistics 
ars_NTDeregisterServer ars_NTGetListServer ars_NTInitializationServer 
ars_NTNotificationServer ars_NTTerminationServer ars_NTDeregisterClient 
ars_NTInitializationClient ars_NTRegisterClient ars_NTTerminationClient 
ars_NTRegisterServer ars_GetCurrentServer ars_EncodeDiary 
ars_CreateEntry ars_MergeEntry ars_DeleteFilter
ars_DeleteMultipleFields ars_DeleteActiveLink
ars_DeleteAdminExtension ars_DeleteCharMenu
ars_DeleteEscalation ars_DeleteField ars_DeleteSchema
ars_DeleteVUI ars_ExecuteAdminExtension ars_ExecuteProcess
ars_GetAdminExtension ars_GetEscalation ars_GetFullTextInfo
ars_GetListGroup ars_GetListSQL ars_GetListUser
ars_GetListVUI ars_GetServerInfo ars_GetEntryBLOB
ars_CreateActiveLink ars_CreateAdminExtension
ars_GetControlStructFields ars_GetVUI
ars_GetListContainer
$ars_errstr %ARServerStats %ars_errhash
ars_decodeStatusHistory ars_APIVersion
);

$ARS::VERSION   = '1.67';
$ARS::DEBUGGING = 0;

bootstrap ARS $ARS::VERSION;
tie $ARS::ars_errstr, ARS::ERRORSTR;

# This HASH is used by the ars_GetServerStatistics call.
# Refer to your ARS API Programmer's Manual or the "ar.h"
# file for an explaination of what each of these stats are.
#
# Usage of this hash would be something like:
#
# %stats = ars_GetServerStatistics($ctrl, 
#          $ARServerStats{'START_TIME'}, 
#          $ARServerStats{'CPU'});
#

%ARS::ARServerStats = (
 'START_TIME'      ,1,
 'BAD_PASSWORD'    ,2,
 'NO_WRITE_TOKEN'  ,3,
 'NO_FULL_TOKEN'   ,4,
 'CURRENT_USERS'   ,5,
 'WRITE_FIXED'     ,6,
 'WRITE_FLOATING'  ,7,
 'WRITE_READ'      ,8,
 'FULL_FIXED'      ,9,
 'FULL_FLOATING'  ,10,
 'FULL_NONE'      ,11,
 'API_REQUESTS'   ,12,
 'API_TIME'       ,13,
 'ENTRY_TIME'     ,14,
 'RESTRUCT_TIME'  ,15,
 'OTHER_TIME'     ,16,
 'CACHE_TIME'     ,17,
 'GET_E_COUNT'    ,18,
 'GET_E_TIME'     ,19,
 'SET_E_COUNT'    ,20,
 'SET_E_TIME'     ,21,
 'CREATE_E_COUNT' ,22,
 'CREATE_E_TIME'  ,23,
 'DELETE_E_COUNT' ,24,
 'DELETE_E_TIME'  ,25,
 'MERGE_E_COUNT'  ,26,
 'MERGE_E_TIME'   ,27,
 'GETLIST_E_COUNT' ,28,
 'GETLIST_E_TIME' ,29,
 'E_STATS_COUNT'  ,30,
 'E_STATS_TIME'   ,31,
 'FILTER_PASSED'  ,32,
 'FILTER_FAILED'  ,33,
 'FILTER_DISABLE' ,34,
 'FILTER_NOTIFY'  ,35,
 'FILTER_MESSAGE' ,36,
 'FILTER_LOG'     ,37,
 'FILTER_FIELDS'  ,38,
 'FILTER_PROCESS' ,39,
 'FILTER_TIME'    ,40,
 'ESCL_PASSED'    ,41,
 'ESCL_FAILED'    ,42,
 'ESCL_DISABLE'   ,43,
 'ESCL_NOTIFY'    ,44,
 'ESCL_LOG'       ,45,
 'ESCL_FIELDS'    ,46,
 'ESCL_PROCESS'   ,47,
 'ESCL_TIME'      ,48,
 'TIMES_BLOCKED'  ,49,
 'NUMBER_BLOCKED' ,50,
 'CPU'            ,51,
 'SQL_DB_COUNT'   ,52,
 'SQL_DB_TIME'    ,53,
 'FTS_SRCH_COUNT' ,54,
 'FTS_SRCH_TIME'  ,55,
 'SINCE_START'    ,56
);


# ROUTINE
#   ars_simpleMenu(menuItems, prepend)
#
# DESCRIPTION
#   merges all sub-menus into a single level menu. good for web 
#   interfaces.
#
# RETURNS
#   array of menu items.

sub ars_simpleMenu {
    my($m) = shift;
    my($prepend) = shift;
    my(@m) = @$m;
    my(@ret, @submenu);
    my($name, $val);
    
    while (($name, $val, @m) = @m) {
	if (ref($val)) {
	    @submenu = ars_simpleMenu($val, $name);
	    @ret = (@ret, @submenu);
	} else {
	    if ($prepend) {
		@ret = (@ret, "$prepend/$name", $val);
	    } else {
		@ret = (@ret, $name, $val);
	    }
	}
    }
    @ret;
}

# ROUTINE
#   ars_padEntryid(control, schema, entry-id)
#
# DESCRIPTION
#   this routine will left-pad the entry-id with
#   zeros out to the appropriate number of place (15 max)
#   depending upon if your prefix your entry-id's with
#   anything
#
# RETURNS
#   a new scalar on success
#   undef on error

sub ars_padEntryid {
    my($c) = shift;
    my($schema) = shift;
    my($entry_id) = shift;
    my($field);

    # entry id field is field id #1
    ($field = ars_GetField($c, $schema, 1)) ||
	return undef;
    return ("0"x($field->{limit}{maxLength}-length($entry_id))).$entry_id;
}

# ROUTINE
#   ars_decodeStatusHistory(field-value)
#
# DESCRIPTION
#   this routine, when given an encoded status history field
#   (returned by GetEntry) will decode it into a hash like:
#
#   $retval[ENUM]->{USER}
#   $retval[ENUM]->{TIME}
#
#   so if you have a status field that has two states: Open and Closed,
#   where Open is enum 0 and Closed is enum 1, this routine will return:
#
#   $retval[0]->{USER} = the user to last selected this enum
#   $retval[1]->{TIME} = the time that this enum was last selected
#
#   You can map from enum values to selection words by using 
#   arsGetField().

sub ars_decodeStatusHistory {
    my ($sval) = shift;
    my ($enum) = 0;
    my ($pair, $ts, $un);
    my (@retval);

    foreach $pair (split(/\003/, $sval)) {
	if($pair ne "") {
	    ($ts, $un) = split(/\004/, $pair);
	    $retval[$enum]->{USER} = $un;
	    $retval[$enum]->{TIME} = $ts;
	} else {
	    # no value for this enumeration
	    $retval[$enum]->{USER} = undef;
	    $retval[$enum]->{TIME} = undef;
	}
	$enum++;
    }

    return @retval;
}

#define AR_DEFN_DIARY_SEP        '\03'     /* diary items separator */
#define AR_DEFN_DIARY_COMMA      '\04'     /* char between date/user/text */

# ROUTINE
#   ars_EncodeDiary(diaryhash1, diaryhash2, ...)
#
# DESCRIPTION
#   given a list of diary hashs (see ars_GetEntry), 
#   encode them into an ars-internal diary string. this can 
#   then be fed into ars_MergeEntry() in order to alter the contents
#   of an existing diary entry.
#
# RETURNS
#   an encoded diary string (scalar) on success
#   undef on failure

sub ars_EncodeDiary {
    my ($diary_string) = undef;
    my ($entry);
    foreach $entry (@_) {
	$diary_string .= $entry->{timestamp}.pack("c",4).$entry->{user}.pack("c",4).$entry->{value};
	$diary_string .= pack("c",3) if ($diary_string);
    }
    return $diary_string;
}


# As of ARS4.0, these routines (which call ARInitialization and ARTermination)
# need to pass a control struct. this means that we now must move them into
# ars_Login and ars_Logoff in order to have access to that control struct.
# the implications of this are that your script should always call ars_Logoff()
# inorder to ensure that licenses are released (i.e. ARTermination is called)
# as for ARInitialization: this is used for private servers, mostly, and shouldnt
# affect anything by moving it into the ars_Login call.

# call ARInitialization
ARS::__ars_init() if(&ARS::ars_APIVersion() < 4);


1;
__END__

