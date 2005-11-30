# /pacakges/tasks-portlet/www/tasks-portlet.tcl
ad_page_contract {

} {

}

array set config $cf

# Integration with contacts
set community_id [dotlrn_community::get_community_id_from_url]
set organization_id [lindex [application_data_link::get_linked -from_object_id $community_id -to_object_type "organization"] 0]

if {[exists_and_not_null organization_id]} {
    set contact_id $organization_id
} else {
    set contact_id ""
}

set user_id [ad_conn user_id]
