require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'

get '/tools/?' do
	@breadcrumbs << {:text => 'Tools'}
	require_login
	check_membership

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
	check_membership

	machine_training_id = EventType.find_by(:description => 'Machine Training', :service_space_id => SS_ID).id
	events = Event.includes(:event_signups).where(:service_space_id => SS_ID, :event_type_id => machine_training_id).
					where('start_time >= ?', Time.now).all

	erb :trainings, :layout => :fixed, :locals => {
		:events => events
	}
end

post '/tools/trainings/sign_up/:event_id/?' do
	require_login
	check_membership

	# check that is a valid event
	machine_training_id = EventType.find_by(:description => 'Machine Training', :service_space_id => SS_ID).id
	event = Event.find_by(:service_space_id => SS_ID, :event_type_id => machine_training_id, :id => params[:event_id])

	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/tools/trainings/'
	end

	if !event.max_signups.nil? && event.signups.count >= event.max_signups
		# that event is full
		flash(:danger, 'Event Full', 'Sorry, that event is full.')
		redirect '/tools/trainings/'
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => @user.full_name,
		:user_id => @user.id,
		:email => @user.email
	)

	body = <<EMAIL
<p>Thank you, #{@user.full_name} for signing up for #{event.title}. Don't forget that this training is</p>

<p><strong>#{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}</strong>.</p>

<p>We'll see you there!</p>

<p>Nebraska Innovation Studio</p>
EMAIL

	Emailer.mail(@user.email, "Nebraska Innovation Studio - #{event.title}", body)

	# flash a message that this works
	flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, #{event.title} is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}.")
	redirect '/tools/trainings/'
end

get '/tools/:resource_id/reserve/?' do
	@breadcrumbs << {:text => 'Tools', :href => '/tools/'} << {:text => 'Reserve'}
	require_login
	check_membership

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

	date = params[:date].nil? ? Time.now.midnight.in_time_zone : Time.parse(params[:date]).midnight.in_time_zone
	# get the studio's hours for this day
	# is there a one_off
	space_hour = SpaceHour.where(:service_space_id => SS_ID)
		.where('effective_date = ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
		.where(:day_of_week => date.wday).where(:one_off => true).first
	if space_hour.nil?
		space_hour = SpaceHour.where(:service_space_id => SS_ID)
			.where('effective_date <= ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
			.where(:day_of_week => date.wday).where(:one_off => false)
			.order(:effective_date => :desc, :id => :desc).first
	end

	available_start_times = []
	# calculate the available start times for reservation
	if space_hour.nil?
		start = 0
		while start + tool.minutes_per_reservation <= 1440
			available_start_times << start
			start += tool.minutes_per_reservation
		end
	else
		space_hour.hours.sort{|x,y| x[:start] <=> y[:start]}.each do |record|
			if record[:status] == 'open'
				start = record[:start]
				while start + tool.minutes_per_reservation <= record[:end]
					available_start_times << start
					start += tool.minutes_per_reservation
				end
			end
		end
	end

	# filter out times when tool is reserved
	reservations = Reservation.includes(:event).where(:resource_id => tool.id).in_day(date).all
	available_start_times = available_start_times - reservations.map{|res|res.start_time.in_time_zone.minutes_after_midnight}

	erb :reserve, :layout => :fixed, :locals => {
		:tool => tool,
		:reservations => reservations,
		:available_start_times => available_start_times,
		:space_hour => space_hour,
		:day => date,
		:reservation => nil
	}
end

get '/tools/:resource_id/edit_reservation/:reservation_id/?' do
	@breadcrumbs << {:text => 'Tools', :href => '/tools/'} << {:text => 'Edit Reservation'}
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

	# check that this reservation exists
	reservation = Reservation.find(params[:reservation_id])
	if reservation.nil?
		flash(:alert, 'Not Found', 'That reservation does not exist.')
		redirect back
	end

	date = params[:date].nil? ? reservation.start_time.in_time_zone.midnight : Time.parse(params[:date]).midnight.in_time_zone
	# get the studio's hours for this day
	# is there a one_off
	space_hour = SpaceHour.where(:service_space_id => SS_ID)
		.where('effective_date = ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
		.where(:day_of_week => date.wday).where(:one_off => true).first
	if space_hour.nil?
		space_hour = SpaceHour.where(:service_space_id => SS_ID)
			.where('effective_date <= ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
			.where(:day_of_week => date.wday).where(:one_off => false)
			.order(:effective_date => :desc, :id => :desc).first
	end

	available_start_times = []
	# calculate the available start times for reservation
	if space_hour.nil?
		start = 0
		while start + tool.minutes_per_reservation <= 1440
			available_start_times << start
			start += tool.minutes_per_reservation
		end
	else
		space_hour.hours.sort{|x,y| x[:start] <=> y[:start]}.each do |record|
			if record[:status] == 'open'
				start = record[:start]
				while start + tool.minutes_per_reservation <= record[:end]
					available_start_times << start
					start += tool.minutes_per_reservation
				end
			end
		end
	end

	# filter out times when tool is reserved
	reservations = Reservation.includes(:event).where(:resource_id => tool.id).in_day(date).all
	available_start_times = (available_start_times - reservations.map{|res|res.start_time.in_time_zone.minutes_after_midnight})
	if date == reservation.start_time.in_time_zone.midnight
		available_start_times = available_start_times + [reservation.start_time.in_time_zone.minutes_after_midnight]
	end
	available_start_times.sort!

	erb :reserve, :layout => :fixed, :locals => {
		:tool => tool,
		:reservations => reservations,
		:available_start_times => available_start_times,
		:space_hour => space_hour,
		:day => date,
		:reservation => reservation
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
	check_membership

	# check that the user has authorization to reserve this tool, if tool requires auth
	tool = Resource.find_by(:service_space_id => SS_ID, :id => params[:resource_id])
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/tools/'
	end

	if params[:start_minutes].nil?
		flash(:alert, 'Please specify a start time', 'Please specify a start time for your reservation.')
		redirect back
	end

	hour = (params[:start_minutes].to_i / 60).floor
	am_pm = hour >= 12 ? 'pm' : 'am'
	hour = hour % 12
	hour += 12 if hour == 0
	minutes = params[:start_minutes].to_i % 60

	start_time = calculate_time(params[:date], hour, minutes, am_pm)
	end_time = start_time + params[:length].to_i.minutes

	date = start_time.midnight
	# validate that the requested time slot falls within the open hours of the day
	# get the studio's hours for this day
	# is there a one_off
	space_hour = SpaceHour.where(:service_space_id => SS_ID)
		.where('effective_date = ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
		.where(:day_of_week => date.wday).where(:one_off => true).first
	if space_hour.nil?
		space_hour = SpaceHour.where(:service_space_id => SS_ID)
			.where('effective_date <= ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
			.where(:day_of_week => date.wday).where(:one_off => false)
			.order(:effective_date => :desc, :id => :desc).first
	end

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

	# check for possible other reservations during this time period
	other_reservations = Reservation.where(:resource_id => params[:resource_id]).in_day(date).all
	other_reservations.each do |reservation|
		if (start_time >= reservation.start_time && start_time < reservation.end_time) ||
				(end_time > reservation.start_time && end_time <= reservation.end_time) ||
				(start_time < reservation.start_time && end_time > reservation.end_time)
			flash :alert, "Tool is being used.", "Sorry, that tool is reserved during that time period. Please try another time slot."
			redirect back
		elsif reservation.user_id == @user.id
			flash :alert, "Over Limit", "Sorry, you can only reserve this tool once per day. Please try reserving another time slot on another day."
			redirect back
		end
	end

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

post '/tools/:resource_id/edit_reservation/:reservation_id/?' do
	require_login

	# check that the user has authorization to reserve this tool, if tool requires auth
	tool = Resource.find_by(:service_space_id => SS_ID, :id => params[:resource_id])
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/tools/'
	end

	# check that this reservation exists
	reservation = Reservation.find(params[:reservation_id])
	if reservation.nil?
		flash(:alert, 'Not Found', 'That reservation does not exist.')
		redirect back
	end

	hour = (params[:start_minutes].to_i / 60).floor
	am_pm = hour >= 12 ? 'pm' : 'am'
	hour = hour % 12
	hour += 12 if hour == 0
	minutes = params[:start_minutes].to_i % 60

	start_time = calculate_time(params[:date], hour, minutes, am_pm)
	end_time = start_time + params[:length].to_i.minutes

	date = start_time.midnight
	# validate that the requested time slot falls within the open hours of the day
	# get the studio's hours for this day
	# is there a one_off
	space_hour = SpaceHour.where(:service_space_id => SS_ID)
		.where('effective_date = ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
		.where(:day_of_week => date.wday).where(:one_off => true).first
	if space_hour.nil?
		space_hour = SpaceHour.where(:service_space_id => SS_ID)
			.where('effective_date <= ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
			.where(:day_of_week => date.wday).where(:one_off => false)
			.order(:effective_date => :desc, :id => :desc).first
	end

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

	# check for possible other reservations during this time period
	other_reservations = Reservation.where(:resource_id => params[:resource_id]).where.not(:id => reservation.id).in_day(date).all
	other_reservations.each do |reservation|
		if (start_time >= reservation.start_time && start_time < reservation.end_time) ||
				(end_time >= reservation.start_time && end_time < reservation.end_time) ||
				(start_time < reservation.start_time && end_time > reservation.end_time)
			flash :alert, "Tool is being used.", "Sorry, that tool is reserved during that time period. Please try another time slot."
			redirect back
		elsif reservation.user_id == @user.id
			flash :alert, "Over Limit", "Sorry, you can only reserve this tool once per day. Please try reserving another time slot on another day."
			redirect back
		end
	end

	reservation.update(
		:start_time => start_time,
		:end_time => end_time
	)

	flash(:success, 'Reservation Updated', "You have successfully updated your reservation for #{tool.name}: it is now for #{params[:length]} minutes at #{start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}")
	redirect back
end

post '/tools/:resource_id/cancel/:reservation_id/?' do
	require_login

	# check that the user requesting cancel is the same as the one on the reservation
	reservation = Reservation.find(params[:reservation_id])
	if reservation.nil?
		flash :alert, 'Not Found', 'That reservation was not found.'
		redirect back
	end

	if reservation.user_id != @user.id
		flash :alert, 'Unauthorized', 'That is not your reservation.'
		redirect back
	end

	reservation.delete

	flash :success, 'Reservation Cancelled', 'Your reservation has been removed.'
	redirect back
end


