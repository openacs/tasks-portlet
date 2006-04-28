# /pacakges/tasks-portlet/www/tasks-portlet.tcl
ad_page_contract {

} {

}

array set config $cf

# Tasks Portlet is currently only used for "My Workspace" in dotlrn
# if it ends up being used in a club or class this old code may be
# helpful
#
# Integration with contacts
#set community_id [dotlrn_community::get_community_id_from_url]
#set organization_id [lindex [application_data_link::get_linked -from_object_id $community_id -to_object_type "organization"] 0]
#
#if {[exists_and_not_null organization_id]} {
#    set contact_id $organization_id
#} else {
#    set contact_id ""
#}


# there is not yet a way for tasks-portlet to link to
# a contacts instance that is not mounted at /contacts
# if that is implemented (possibly via application data
# links the package_id should be set here
set package_id [site_node::get_element -url "/contacts" -element object_id]

set user_id [ad_conn user_id]
set object_query " select p${user_id}.party_id from parties p${user_id} "

set object_query "
select parties.party_id
  from parties,
       group_distinct_member_map
 where parties.party_id = group_distinct_member_map.member_id
   and group_distinct_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups -package_id $package_id]])
"

set assignee_query " select user_id from users "
set hide_elements ""
# if this should only show tasks asssigned to the user uncomment the following lines
# set assignee_query " '${user_id}' "
# set hide_elements "assignee"
