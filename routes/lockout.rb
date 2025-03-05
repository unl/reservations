require 'models/resource'

get '/lockout/' do
	require_login
	@breadcrumbs << {:text => 'Lockout'}

	workshop_category = params[:workshop_category]

	# show tools that the user is authorized to use, as well as all those that do not require authorization
	tools = Resource.where(:service_space_id => SS_ID).all.to_a

	# Redefine the tools variable if there is a workshop category filter applied
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
		redirect '/admin/tools/'
	end

	erb :'lockout_resource', :layout => :fixed, :locals => {
		:tool => tool
	}
end