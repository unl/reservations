require 'models/resource'

get '/admin/tools/?' do
	require_login

	tools = Resource.where(:service_space_id => SS_ID).order(:name).all
	erb :'admin/tools', :layout => :fixed, :locals => {
		:tools => tools
	}
end

get '/admin/tools/create/?' do
	require_login

	erb :'admin/edit_tool', :layout => :fixed, :locals => {
		:tool => Resource.new
	}
end

post '/admin/tools/create/?' do
	require_login

	tool = Resource.new
	tool.name = params[:name]
	tool.model = params[:model]
	tool.description = params[:description]
	tool.service_space_id = SS_ID
	tool.needs_authorization = true
	tool.needs_approval = false
	tool.save

	flash(:success, 'Tool Created', "Your tool #{tool.name} has been created.")
	redirect '/admin/tools/'
end

get '/admin/tools/:resource_id/edit/?' do
	require_login

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
	tool.model = params[:model]
	tool.description = params[:description]
	tool.save

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