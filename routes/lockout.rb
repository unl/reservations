require 'models/resource'
require 'models/lockout'

get '/lockout/' do
    require_login
    @breadcrumbs << {:text => 'Lockout'}

    workshop_category = params[:workshop_category]

    tools = Resource.where(:service_space_id => SS_ID).all.to_a
    unless workshop_category.nil? || workshop_category.length == 0
			tools = Resource.where(:service_space_id => SS_ID).where(:category_id => workshop_category).all.to_a
		end

		

		tools.reject {|tool| tool.is_locked_out }

    tools.sort_by! do |tool|
        [
            tool.category_name.to_s.downcase,
            tool.name.to_s.downcase,
            tool.model.to_s.downcase
        ]
    end

    erb :'lockout', :layout => :fixed, :locals => {
        :workshop_category => workshop_category,
        :tools => tools
    }
end

get '/lockout/:resource_id/create/?' do
	require_login
	@breadcrumbs << {:text => 'Lockout', :href => '/lockout/'} << {:text => 'Lockout Tool'}

	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end

	erb :'lockout_resource', :layout => :fixed, :locals => {
		:tool => tool
	}
end

post '/lockout/:resource_id/create/?' do
	require_login
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end

	# Validate that start time is before end time
	if params[:start_date] && params[:start_time] && params[:end_date] && params[:end_time]
		start_time = DateTime.parse("#{params[:start_date]} #{params[:start_time]}")
		end_time = DateTime.parse("#{params[:end_date]} #{params[:end_time]}")
		if start_time >= end_time
			flash(:alert, 'Invalid Dates', 'The start time must be before the end time.')
			redirect back
		end
	end

	lockout = Lockout.new
	lockout.set_data(params)
	flash(:success, 'Lockout Created', 'The lockout has been created.')
	redirect '/lockout/'
end

get '/lockout/:resource_id/edit/?' do
	require_login
	@breadcrumbs << {:text => 'Lockout', :href => '/lockout/'} << {:text => 'Edit Lockout'}

	erb :'lockout_resource', :layout => :fixed, :locals => {
		:tool => tool
	}
end