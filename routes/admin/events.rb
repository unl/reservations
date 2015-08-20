require 'models/event'
require 'models/event_type'
require 'models/location'

get '/admin/events/?' do
	erb :'admin/events', :layout => :fixed, :locals => {
		:events => Event.includes(:event_signups).where(:service_space_id => SS_ID).all
	}
end

get '/admin/events/:event_id/signup_list/?' do
	event = Event.includes(:event_signups).find(params[:event_id])

	erb :'admin/signup_list', :layout => :fixed, :locals => {
		:event => event
	}
end

get '/admin/events/create/?' do
	erb :'admin/new_event', :layout => :fixed, :locals => {
		:event => Event.new,
		:types => EventType.where(:service_space_id => SS_ID).all,
		:locations => Location.where(:service_space_id => SS_ID).all
	}
end

post '/admin/events/create/?' do
	event = Event.new
	event = set_event_data(event, params)
	event.save

	if event.type.description == 'Machine Training'
		# need to create a reservation on the machine at that time
	end

	redirect '/admin/events/'
end

get '/admin/events/:event_id/edit/?' do
	erb :'admin/new_event', :layout => :fixed, :locals => {
		:event => Event.includes(:event_type, :location).find(params[:event_id]),
		:types => EventType.where(:service_space_id => SS_ID).all,
		:locations => Location.where(:service_space_id => SS_ID).all
	}
end

post '/admin/events/:event_id/edit/?' do
	event = Event.find(params[:event_id])
	event = set_event_data(event, params)
	event.save

	redirect '/admin/events/'
end