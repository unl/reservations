require 'models/resource'
require 'models/permission'

NIS_TOOL_RESOURCE_CLASS_ID = 1

before '/admin/tools*' do
	unless @user.has_permission?(Permission::MANAGE_RESOURCES)
		raise Sinatra::NotFound
	end
end

get '/admin/tools/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Tools'}

	tools = Resource.where(:service_space_id => SS_ID).order(:name).all
	erb :'admin/tools', :layout => :fixed, :locals => {
		:tools => tools
	}
end

get '/admin/tools/create/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Tools', :href => '/admin/tools/'} << {:text => 'Create Tool'}

	erb :'admin/edit_tool', :layout => :fixed, :locals => {
		:tool => Resource.new
	}
end

post '/admin/tools/create/?' do
	require_login

	tool = Resource.new
	tool.resource_class_id = NIS_TOOL_RESOURCE_CLASS_ID
	tool.name = params[:name]
	tool.description = params[:description]
	tool.service_space_id = SS_ID
	tool.needs_authorization = true
	tool.is_reservable = params.checked?('is_reservable')
	tool.time_slot_type = params[:time_slot_type]
	tool.minutes_per_reservation = params[:minutes_per_reservation]
	tool.min_minutes_per_reservation = params[:min_minutes_per_reservation]
	tool.max_minutes_per_reservation = params[:max_minutes_per_reservation]
	tool.increment_minutes_per_reservation = params[:increment_minutes_per_reservation]
	tool.needs_approval = false
	tool.max_reservations_per_slot = 5
	tool.save
	tool.set_field_data('model', params[:model])


	flash(:success, 'Tool Created', "Your tool #{tool.name} has been created.")
	redirect '/admin/tools/'
end

get '/admin/tools/:resource_id/edit/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Tools', :href => '/admin/tools/'} << {:text => 'Edit Tool'}

	# check that this is a valid tool
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end

	erb :'admin/edit_tool', :layout => :fixed, :locals => {
		:tool => tool
	}
end

post '/admin/tools/:resource_id/edit/?' do
	require_login

	# check that this is a valid tool
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end

	tool.name = params[:name]
	tool.description = params[:description]
	tool.is_reservable = params.checked?('is_reservable')
	tool.time_slot_type = params[:time_slot_type]
	tool.minutes_per_reservation = params[:minutes_per_reservation]
	tool.min_minutes_per_reservation = params[:min_minutes_per_reservation]
	tool.max_minutes_per_reservation = params[:max_minutes_per_reservation]
	tool.increment_minutes_per_reservation = params[:increment_minutes_per_reservation]
	tool.save
	tool.set_field_data('model', params[:model])

	flash(:success, 'Tool Updated', "Your tool #{tool.name} has been updated.")
	redirect '/admin/tools/'
end

post '/admin/tools/:resource_id/delete/?' do
	require_login

	# check that this is a valid tool
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end

	tool.destroy

	flash(:success, 'Tool Deleted', "Your tool #{tool.name} has been deleted. All reservations and permissions on this tool have also been removed.")
	redirect '/admin/tools/'
end