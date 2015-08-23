require 'models/event'

get '/calendar/' do
	@breadcrumbs << {:text => 'Calendar'}

	# get all events for this week
	events = Event.includes(:event_type).where(:service_space_id => SS_ID).in_week(Time.now).all
	sunday = Time.now.in_time_zone.sunday

	erb :calendar, :layout => :fixed, :locals => {
		:sunday => sunday,
		:events => events
	}
end