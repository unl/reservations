get '/admin/agenda/' do
	date = params[:date].nil? ? Time.now.midnight : Time.parse(params[:date])

	reservations = Reservation.includes(:user, :resource, :event).in_day(date).order(:start_time)
	events = Event.includes(:event_type).in_day(date).order(:start_time)

	# get the hours for this day to show
	hours = SpaceHour.where(:service_space_id => SS_ID)
		.where('effective_date <= ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
		.order(:effective_date => :desc, :id => :desc).all.to_a

	correct_hour = nil

	hours.each do |space_hour|
		if date.wday == space_hour.day_of_week && (space_hour.effective_date.in_time_zone.midnight == date.in_time_zone.midnight || (!space_hour.one_off && space_hour.effective_date.in_time_zone.midnight <= date.in_time_zone.midnight))
			correct_hour = space_hour
			break
		end
	end

	erb :'admin/agenda', :layout => :fixed, :locals => {
		:reservations => reservations,
		:events => events,
		:date => date,
		:space_hour => correct_hour
	}
end