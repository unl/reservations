require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'

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

	date = Time.now.midnight.in_time_zone
	# get the studio's hours for this day
	space_hour = SpaceHour.where(:service_space_id => SS_ID)
		.where('effective_date <= ?', date.utc.strftime('%Y-%m-%d %H:%M:%S')).where(:day_of_week => date.wday)
		.order(:effective_date => :desc, :id => :desc).first

	erb :reserve, :layout => :fixed, :locals => {
		:tool => tool,
		:reservations => Reservation.where(:resource_id => tool.id).in_day(date).all,
		:space_hour => space_hour,
		:day => date
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

	start_time = calculate_time(params[:date], params[:start_time_hour], params[:start_time_minute], params[:start_time_am_pm])
	end_time = start_time + params[:length].to_i.minutes

	date = start_time.midnight
	# validate that the requested time slot falls within the open hours of the day
	# get the studio's hours for this day
	space_hour = SpaceHour.where(:service_space_id => SS_ID)
		.where('effective_date <= ?', date.utc.strftime('%Y-%m-%d %H:%M:%S')).where(:day_of_week => date.wday)
		.order(:effective_date => :desc, :id => :desc).first

	unless space_hour.nil?
		# figure out where the closed sections need to be
        # we can assume that all records in this space_hour are non-intertwined
        closed_start = 0
        closed_end = 0
        starts = space_hour.hours.map{|record| record[:start]}
        ends = space_hour.hours.map{|record| record[:end]}
        closeds = []
        (0..1439).each do |j|
            if starts.include?(j)
                closed_end = j
                closeds << {:status => 'closed', :start => closed_start, :end => closed_end}
                closed_start = 0
                closed_end = 0
            end
            if ends.include?(j)
                closed_start = j
            end
        end 
        closed_end = 1440
        closeds << {:status => 'closed', :start => closed_start, :end => closed_end}

		# for each record, ensure that the time does not overlap if the record is not "open"
		(space_hour.hours + closeds).each do |record|
			if record[:status] != 'open'
				start_time_minutes = 60 * start_time.hour + start_time.min
				end_time_minutes = 60 * end_time.hour + end_time.min
				if (record[:start]+1..record[:end]-1).include?(start_time_minutes) || (record[:start]+1..record[:end]-1).include?(end_time_minutes) ||
						(start_time_minutes < record[:start] && end_time_minutes > record[:end])
					# there is an overlap, this time is invalid
					flash :alert, 'Invalid Time Slot', 'Sorry, that time slot is invalid for reservations.'
					redirect back
				end
			end
		end
	end
	# if no record studio is open

	Reservation.create(
		:resource_id => tool.id,
		:event_id => nil,
		:start_time => start_time,
		:end_time => end_time,
		:is_training => false,
		:user_id => @user.id
	)

	flash(:success, 'Reservation Created', "You have successfully reserved #{tool.name} for #{params[:length]} minutes at #{start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}")
	redirect '/tools/'
end



