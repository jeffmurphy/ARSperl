#
#    ARSperl - An ARS2.0-3.x / Perl5.0 Integration Kit
#
#    Copyright (C) 1995 Joel Murphy, jmurphy@acsu.buffalo.edu
#                       Jeff Murphy, jcmurphy@acsu.buffalo.edu
# 
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
# 
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
# 
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
#    Comments to: arsperl@smurfland.cit.buffalo.edu
#
# $Log: ARS.pm,v $
# Revision 1.13  1997/08/05 21:20:04  jcmurphy
# 1.50 dev1
#
# Revision 1.12  1997/07/02 15:51:45  jcmurphy
# changed ars_errstr, added arserr_hash to exports, remove tie to main
# on ars_errstr
#
# Revision 1.11  1997/02/18 16:38:20  jmurphy
# added a END block to call ARTermination
#
# Revision 1.10  1997/02/17 16:21:57  jcmurphy
# added ars_GetCurrentServer so you can determine what server you connected to (if you didnt specify one)
#
# Revision 1.9  1997/02/13 15:06:43  jcmurphy
# added NT* routines
#
# Revision 1.8  1996/11/21 20:03:42  jcmurphy
# GetFilter(), GetServerStatistics(), GetCharMenu() added.
# ARServerStats hash added to make using GetServerStatistics
# easier.
#
# Revision 1.7  1996/10/31  16:43:59  jmurphy
# ars_Import
#
# Revision 1.6  1996/10/31  16:42:53  jmurphy
# *** empty log message ***
#
# Revision 1.5  1996/03/29  20:15:08  jcmurphy
# added ars_padEntryid to export list
#
# Revision 1.4  1996/03/28 02:14:37  jcmurphy
# renamed pad_entryid to ars_padEntryid and added rcs log field.
#
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
	$s .= sprintf("[%s] %s (ARERR \#%d)",
		      $mTypes{@{$ARS::ars_errhash{messageType}}[$i]},
		      @{$ARS::ars_errhash{messageText}}[$i],
		      @{$ARS::ars_errhash{messageNum}}[$i]);
	if($i < $ARS::ars_errhash{numItems}-1) {
	    $s .= "\n";
	}
    }
    return $s;
}

package ARS;

require Exporter;
require DynaLoader;
require AutoLoader;
require Config;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(isa_int isa_float isa_string ars_LoadQualifier ars_Login 
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
ars_GetListVUI ars_GetServerInfo
ars_CreateActiveLink
$ars_errstr %ARServerStats %ars_errhash
);

$VERSION = '1.50';

bootstrap ARS $VERSION;
tie $ars_errstr, ARS::ERRORSTR;

$AR_EXECUTE_ON_NONE =          0;
$AR_EXECUTE_ON_BUTTON =        1;
$AR_EXECUTE_ON_RETURN =        2;
$AR_EXECUTE_ON_SUBMIT =        4;
$AR_EXECUTE_ON_MODIFY =        8;
$AR_EXECUTE_ON_DISPLAY =      16;
$AR_EXECUTE_ON_MODIFY_ALL =   32;
$AR_EXECUTE_ON_MENU =         64;
$AR_EXECUTE_ON_MENU_CHOICE = 128;
$AR_EXECUTE_ON_LOOSE_FOCUS = 256;
$AR_EXECUTE_ON_SET_DEFAULT = 512;
$AR_EXECUTE_ON_QUERY =      1024;

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

%ARServerStats = (
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
#   AR_DAY(mask, dayNumber)
#   AR_HOUR(mask, hourNumber)
#
# DESCRIPTION
#   Used to analyze bitmask returned by ars_GetEscalation()
#
# RETURNS
#   1 if that day or hour is set in the mask
#   0 if that day or hour is not set in the mask

sub AR_DAY {
    my($x, $y) = (shift, shift);
    return (($x >> $y) & 0x1);
}

sub AR_HOUR {
    my($x, $y) = (shift, shift);
    return (($x >> $y) & 0x1);
}

$field_entryId = 1;

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
    
    ($field = ars_GetField($c, $schema, $field_entryId)) ||
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

    foreach $pair (split(/\003/, $sval)) {
	print $enum++.": ";
	if($pair ne "") {
	    ($ts, $un) = split(/\004/, $pair);
	    print localtime($ts)." - $un\n";
	} else {
	    print "no value for this enumeration\n";
	}
    }
}

#define AR_DEFN_DIARY_SEP        '\03'     /* diary items separator */
#define AR_DEFN_DIARY_COMMA      '\04'     /* char between date/user/text */

# ROUTINE
#   ars_EncodeDiary(timestamp, username, value, timestamp, username, value, ...)
#
# DESCRIPTION
#   given a list of timestamp, username and value triplets, 
#   encode them into an ars-internal diary string. this can 
#   then be fed into ars_MergeEntry() in order to alter the contents
#   of an existing diary entry.
#
# RETURNS
#   an encoded diary string (scalar) on success
#   undef on failure

sub ars_EncodeDiary {
    my ($diary_string) = undef;
    foreach $entry (@_) {
	$diary_string .= pack("c",4) if ($diary_string);
	$diary_string .= $entry->{timestamp}.pack("c",3).$entry->{user}.pack("c",3).$entry->{value}
    }
    return $diary_string;
}


# call ARInitialization
ARS::__ars_init();

# call ARTermination when the package is terminated
END {
  ARS::__ars_Termination();
}

1;
__END__

