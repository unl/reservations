require 'models/resource'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'

get '/tools/?' do
	require_login

	# show tools that the user is authorized to use, as well as all those that do not require authorization
	tools = Resource.where(:service_space_id => SS_ID).all.to_a
	tools.reject! {|tool| tool.needs_authorization && !@user.authorized_resource_ids.include?(tool.id)}

	erb :tools, :layout => :fixed, :locals => {
		:available_tools => tools
	}
end

get '/tools/trainings/?' do
	require_login

	machine_training_id = EventType.find_by(:description => 'Machine Training', :service_space_id => SS_ID).id
	events = Event.where(:service_space_id => SS_ID, :event_type_id => machine_training_id).all

	erb :trainings, :layout => :fixed, :locals => {
		:events => events
	}
end

post '/tools/trainings/sign_up/:event_id/?' do
	require_login

	# check that is a valid event
	machine_training_id = EventType.find_by(:description => 'Machine Training', :service_space_id => SS_ID).id
	event = Event.find_by(:service_space_id => SS_ID, :event_type_id => machine_training_id, :id => params[:event_id])

	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/tools/trainings/'
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => @user.full_name,
		:user_id => @user.id
	)

	# flash a message that this works
	flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, #{event.title} is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}.")
	redirect '/tools/trainings/'
end

get '/tools/:resource_id/reserve/?' do
	# check that the user has authorization to reserve this tool, if tool requires auth
end

post '/tools/:resource_id/reserve/?' do
	# if the tool requires approval, note that, otherwise say reservation successful
end