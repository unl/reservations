require 'models/resource'

get '/tools/?' do
	# show tools that the user is authorized to use, as well as all those that do not require authorization
	tools = Resource.where(:service_space_id => SS_ID).all.to_a
	tools.reject! {|tool| tool.needs_authorization && !@user.authorized_resource_ids.include?(tool.id)}

	erb :tools, :layout => :fixed, :locals => {
		:available_tools => tools
	}
end

get '/tools/:resource_id/reserve/?' do
	# check that the user has authorization to reserve this tool, if tool requires auth
end

post '/tools/:resource_id/reserve/?' do
	# if the tool requires approval, note that, otherwise say reservation successful
end