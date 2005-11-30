set user_id [ad_conn user_id]

if { ![exists_and_not_null orderby] } {
    set orderby "priority,desc"
}
if { ![exists_and_not_null status_id] } {
    set status_id "1"
}

set community_id [dotlrn_community::get_community_id]

set user_space_p 1

if { ![empty_string_p $community_id] } {
    set package_id [dotlrn_community::get_package_id_from_package_key \
			-package_key "tasks" \
			-community_id $community_id]
    set user_space_p 0
} 

if { [exists_and_not_null package_id] } {
    set package_where_clause " and ao.package_id = :package_id"
} else {
    set package_where_clause " and ao.creation_user = :user_id"
}

if { ![contact::exists_p -party_id $contact_id] } {
    set contact_id $user_id
}

set party_id $contact_id
set tasks_url "tasks/"


set done_url [export_vars -url -base "${tasks_url}contact" {orderby {status_id 2} party_id}]
set not_done_url [export_vars -url -base "${tasks_url}contact" {orderby {status_id 1} party_id}]
set return_url "[ad_conn url]?[ad_conn query]"
set add_url [export_vars -base "${tasks_url}task" {return_url orderby status_id party_id}]


template::list::create \
    -name tasks \
    -multirow tasks \
    -key task_id \
    -elements {
        deleted_p {
	    label {<img src="/resources/acs-subsite/checkboxchecked.gif" alt="[_ tasks.Not_Done]" border="0" height="13" width="13">}
	    display_template {
		<if @tasks.done_p@>
 	        <img src="/resources/acs-subsite/checkboxchecked.gif" alt="[_ tasks.Done]" border=0 height="13" width="13">
		</if>
                <else>
		<a href="@tasks.complete_url@">
		<img src="/resources/acs-subsite/checkbox.gif" alt="[_ tasks.Not_Done]" border="0" height="13" width="13">
		</a>
		</else>
	    }
	}
        priority {
	    label "[_ tasks.Priority]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.priority@</span></if><else>@tasks.priority@</else>
	    }
	}
	title {
	    label "[_ tasks.Task]"
            display_template {
		<a href="@tasks.task_url@" title="@tasks.title@"<if @tasks.done_p@> class="done"</if>>@tasks.title@</a>
		<if @tasks.description@ not nil>
		<if @tasks.done_p@><div class="done"></if>
                <p style="padding: 0; margin: 0; font-size: 0.85em; padding-left: 2em;">
		@tasks.description_html;noquote@
		</p>
		<if @tasks.done_p@></div></if>
		</if>
	    }
	}
        process_title {
	    label "[_ tasks.Process]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.process_title@</span></if>
                <else>
		  <if @tasks.process_title@ not nil>@tasks.process_title@</if>
		</else>
	    }
	}
        date {
	    label "[_ tasks.Date]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.completed_date;noquote@</span></if>
                <else>
		  <if @tasks.due_date@>
		  <a href="@tasks.task_minus_url@" style="text-decoration: none; font-weight: bold;">&laquo;</a>&nbsp;
		  <if @tasks.due_date_passed_p@><span style="color: red;"></if>
                  @tasks.due_date;noquote@
                  <if @tasks.due_date_passed_p@></span></if>&nbsp;
                  <a href="@tasks.task_plus_url@" style="text-decoration: none; font-weight: bold;">&raquo;</a>
                  </if>
                </else>
	    }
	}
	creation_user {
	    label "[_ tasks.Created_By]"
	    display_template {
		<a href="@tasks.creation_user_url@"<if @tasks.done_p@> class="done"</if>>@tasks.creation_name@</a>
	    }
	}      
    } \
    -sub_class {
        narrow
    } \
    -filters {
	party_id {
	}
    } -orderby {
        default_value "priority,desc"
        date {
            label "[_ tasks.Due]"
            orderby_desc "CASE WHEN t.status_id = 1 THEN t.due_date ELSE t.completed_date END desc, 
                          t.priority, 
                          lower(t.title)"
            orderby_asc "CASE WHEN t.status_id = 1 THEN t.due_date ELSE t.completed_date END asc, 
                         t.priority, 
                         lower(t.title)"
            default_direction desc
        }
        priority {
            label "[_ tasks.Priority]"
            orderby_desc "t.status_id, 
                          t.priority desc, 
                          CASE WHEN t.status_id = 1 THEN t.due_date ELSE t.completed_date END desc, 
                          lower(t.title)"
            orderby_asc "t.status_id, 
                         t.priority asc, 
                         CASE WHEN t.status_id = 1 THEN t.due_date ELSE t.completed_date END asc, 
                         lower(t.title)"
            default_direction desc
        }
        title {
            label "[_ tasks.Task]"
            orderby_desc "lower(t.title) desc, t.priority desc, t.due_date asc"
            orderby_asc "lower(t.title) asc, t.priority desc, t.due_date asc"
            default_direction asc
        }
        process_title {
	    label "[_ tasks.Process]"
            orderby_desc "lower(p.title) desc, t.priority desc, t.due_date asc"
            orderby_asc "lower(p.title) asc, t.priority desc, t.due_date asc"
	    default_direction asc
	}
	creation_user {
	    label "[_ tasks.Created_By]"
            orderby_desc "lower(contact__name(ao.creation_user)) desc, t.due_date asc, t.priority, lower(t.title)"
            orderby_asc "lower(contact__name(ao.creation_user)) asc, t.due_date asc, t.priority, lower(t.title)"
	    default_direction asc
	}
    }


db_multirow -extend { creation_user_url contact_url complete_url done_p task_plus_url task_minus_url description_html task_url } -unclobber tasks get_tasks " " {
    set creation_user_url [contact::url -party_id $creation_user]
    regsub -all "tasks/" $creation_user_url "contacts/" creation_user_url
    set complete_url [export_vars -base "${tasks_url}mark-completed" -url {task_id orderby {party_id $contact_id} return_url}]
    if { $status_id == "2" } {
	set done_p 1
    } else {
	set done_p 0
    }
    set task_url [export_vars -base "${tasks_url}task" -url {{party_id $contact_id} orderby status_id task_id}]
    set task_plus_url  [export_vars -base "${tasks_url}task-interval" -url {{action plus}  {days 7} {party_id $contact_id} task_id status_id orderby return_url}]
    set task_minus_url [export_vars -base "${tasks_url}task-interval" -url {{action minus} {days 7} {party_id $contact_id} task_id status_id orderby return_url}]

    regsub -all "\r|\n" $description {LiNeBrEaK} description

    set description_html [ad_html_text_convert \
			      -from $mime_type \
			      -to "text/html" \
			      -truncate_len "400" \
			      -more "<a href=\"${task_url}\">[_ tasks.more]</a>" \
			      -- $description]
    regsub -all {LiNeBrEaKLiNeBrEaK} $description_html {LiNeBrEaK} description_html
    regsub -all {LiNeBrEaK} $description_html {\&nbsp;\&nbsp;\&#182;\&nbsp;} description_html

    regsub -all " " $due_date {\&nbsp;} due_date
    regsub -all " " $completed_date {\&nbsp;} completed_date
}
    