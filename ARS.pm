#
#    ARSperl - An ARS2.0 / Perl5.0 Integration Kit
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
# Revision 1.4  1996/03/28 02:14:37  jcmurphy
# renamed pad_entryid to ars_padEntryid and added rcs log field.
#
#

package ARS::ERRORSTR;
sub TIESCALAR {
    bless {};
}
sub FETCH {
    ARS::_ars_errstr();
}

package ARS;

require Exporter;
require DynaLoader;
require AutoLoader;
require Config;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(isa_int isa_float isa_string ars_LoadQualifier ars_Login ars_Logoff ars_GetListField ars_GetFieldByName ars_GetFieldTable ars_CreateEntry ars_DeleteEntry ars_GetEntry ars_GetListEntry ars_GetListSchema ars_GetListServer ars_GetActiveLink ars_GetCharMenuItems ars_GetSchema ars_GetField ars_simpleMenu ars_GetListActiveLink ars_SetEntry ars_perl_qualifier ars_Export ars_GetListFilter ars_GetListEscalation ars_GetListCharMenu ars_GetListAdminExtension);

bootstrap ARS;
tie $main::ars_errstr, ARS::ERRORSTR;

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

$field_entryId = 1;

sub ars_simpleMenu {
    # merges all sub-menus into a single level menu
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

sub ars_padEntryid {
    my($c) = shift;
    my($schema) = shift;
    my($entry_id) = shift;
    my($field);
    
    ($field = ars_GetField($c, $schema, $field_entryId)) ||
	return undef;
    return ("0"x($field->{limit}{maxLength}-length($entry_id))).$entry_id;
}

ARS::__ars_init();

1;
__END__

