require 'models/event'

get '/calendar/' do
	@breadcrumbs << {:text => 'Calendar'}

	# get all events for this week
	date = params[:date].nil? ? Time.now : Time.parse(params[:date])
	events = Event.includes(:event_type).where(:service_space_id => SS_ID).in_week(date).all
	sunday = date.in_time_zone.week_start

	erb :calendar, :layout => :fixed, :locals => {
		:date => date,
		:sunday => sunday,
		:events => events
	}
end
