require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'

get '/tools/?' do
	@breadcrumbs << {:text => 'Tools'}
	require_login

	# show tools that the user is authorized to use, as well as all those that do not require authorization
	tools = Resource.where(:service_space_id => SS_ID).all.to_a
	tools.reject! {|tool| tool.needs_authorization && !@user.authorized_resource_ids.include?(tool.id)}

	erb :tools, :layout => :fixed, :locals => {
		:available_tools => tools
	}
end

get '/tools/trainings/?' do
	@breadcrumbs << {:text => 'Tools', :href => '/tools/'} << {:text => 'Upcoming Trainings'}
	require_login

	machine_training_id = EventType.find_by(:description => 'Machine Training', :service_space_id => SS_ID).id
	events = Event.where(:service_space_id => SS_ID, :event_type_id => machine_training_id).all

	erb :trainings, :layout => :fixed, :locals => {
		:events => events
	}
end

post '/tools/trainings/sign_up/:event_id/?' do
	@breadcrumbs << {:text => 'Tools', :href => '/tools/'} << {:text => 'Upcoming Trainings', :href => '/tools/trainings/'} << {text: 'Sign Up'}
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
	@breadcrumbs << {:text => 'Tools', :href => '/tools/'} << {:text => 'Reserve'}
	require_login

	# check that the user has authorization to reserve this tool, if tool requires auth
	tool = Resource.find_by(:service_space_id => SS_ID, :id => params[:resource_id])
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/tools/'
	end

	unless @user.authorized_resource_ids.include?(tool.id)
		flash(:alert, 'Not Authorized', 'Sorry, you have not yet been authorized to reserve time on this machine.')
		redirect '/tools/'
	end

	erb :reserve, :layout => :fixed, :locals => {
		:tool => tool,
		:reservations => Reservation.where(:resource_id => tool.id).in_day(Time.now).all
	}
end

get '/tools/:resource_id/reservations.json' do
	# check that the tool exists
	tool = Resource.find_by(:service_space_id => SS_ID, :id => params[:resource_id])
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/tools/'
	end

	time = params[:time]
	if time.nil?
		time = Time.now
	else
		time = Time.parse(time)
	end

	Reservation.where(:resource_id => tool.id).in_day(time).all.to_json
end

post '/tools/:resource_id/reserve/?' do
	require_login

	# check that the user has authorization to reserve this tool, if tool requires auth
	tool = Resource.find_by(:service_space_id => SS_ID, :id => params[:resource_id])
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/tools/'
	end

	start = calculate_time(params[:date], params[:start_time_hour], params[:start_time_minute], params[:start_time_am_pm])

	Reservation.create(
		:resource_id => tool.id,
		:event_id => nil,
		:start_time => start,
		:end_time => start + params[:length].to_i.minutes,
		:is_training => false,
		:user_id => @user.id
	)

	flash(:success, 'Reservation Created', "You have successfully reserved #{tool.name} for #{params[:length]} minutes at #{start.in_time_zone.strftime('%A, %B %d at %l:%M %P')}")
	redirect '/tools/'
end



