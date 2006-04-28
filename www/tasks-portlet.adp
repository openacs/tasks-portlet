<if @config.shaded_p@ false>

	     <include
        	src="/packages/tasks/lib/tasks"
	        object_query=@object_query@
                assignee_query=@assignee_query@
		page_size="15"
		show_filters_p="1"
                hide_elements=@hide_elements@
                package_id=@package_id@ />	

</if>
