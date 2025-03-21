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
		redirect back
	end

	# only admins can schedule lockouts on currently locked out resources
	if tool.is_locked_out? && !has_permission?(Permission::MANAGE_LOCKOUT)
		flash(:alert, 'Tool Locked Out', 'That tool is already locked out.')
		redirect back
	end

	# 24 hour availability in 30 min increments
	available_start_times = []
	start = 0
	while start + 30 <= 1440
		available_start_times << start
		start += 30
	end

	erb :'lockout_resource', :layout => :fixed, :locals => {
		:tool => tool,
		:available_start_times => available_start_times,
	}
end

post '/lockout/:resource_id/create/?' do
	require_login
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end
	if tool.is_locked_out? && !has_permission?(Permission::MANAGE_LOCKOUT)
		flash(:alert, 'Tool Locked Out', 'That tool is already locked out.')
		redirect back
	end

	unless params[:start_date].to_s.strip.empty?
		start_hour = (params[:start_minutes].to_i / 60).floor
		start_am_pm = start_hour >= 12 ? 'pm' : 'am'
		start_hour = start_hour % 12
		start_hour += 12 if start_hour == 0
		start_minutes = params[:start_minutes].to_i % 60

		start_time = calculate_time(params[:start_date], start_hour, start_minutes, start_am_pm)
	end

	unless params[:end_date].to_s.strip.empty?
		end_hour = (params[:end_minutes].to_i / 60).floor
		end_am_pm = end_hour >= 12 ? 'pm' : 'am'
		end_hour = end_hour % 12
		end_hour += 12 if end_hour == 0
		end_minutes = params[:end_minutes].to_i % 60

		end_time = calculate_time(params[:end_date], start_hour, start_minutes, start_am_pm)
	end

	if tool.is_locked_out? && (start_time.nil? || end_time.nil?)
		flash(:alert, 'Invalid Time', 'You must specify a valid start and end time to schedule a lockout.')
		redirect back
	end

	params[:start_time] = start_time
	params[:end_time] = end_time

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

post '/lockout/:resource_id/release/?' do
	require_login
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end
	lockout = Lockout.where(:resource_id => tool.id).order('started_on DESC').first
	if lockout.nil?
		flash(:alert, 'Not Found', 'That tool is not locked out.')
		redirect '/admin/tools/'
	end
	lockout.release()
	flash(:success, 'Lockout Released', 'The lockout has been released.')
	redirect back
end