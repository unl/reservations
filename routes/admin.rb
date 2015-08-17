require 'models/event'
require 'models/event_type'
require 'models/location'

def calculate_time(date_string, hour, minute, am_pm)
	hour ||= 0
	minute ||= 0
	am_pm ||= 'am'

	hour = hour.to_i + 12 if am_pm == 'pm'

	date_strings = date_string.split('/')
	date_string = "#{date_strings[2]}-#{date_strings[0]}-#{date_strings[1]}"
	date = Time.parse(date_string)
	Time.new(date.year, date.month, date.day, hour, minute, 0)
end

before '/admin*' do
	raise Sinatra::NotFound unless !@user.nil? && @user.is_admin?
end

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
	Event.create(
		:title => params[:title],
		:description => params[:description],
		:start_time => calculate_time(params[:start_date], params[:start_time_hour], params[:start_time_minute], params[:start_time_am_pm]),
		:end_time => calculate_time(params[:end_date], params[:end_time_hour], params[:end_time_minute], params[:end_time_am_pm]),
		:service_space_id => SS_ID,
		:event_type_id => params[:type],
		:location_id => params[:location]
	)

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

	event.title = params[:title]
	event.description = params[:description]
	event.start_time = calculate_time(params[:start_date], params[:start_time_hour], params[:start_time_minute], params[:start_time_am_pm])
	event.end_time = calculate_time(params[:end_date], params[:end_time_hour], params[:end_time_minute], params[:end_time_am_pm])
	event.event_type_id = params[:type]
	event.location_id = params[:location]

	event.save

	redirect '/admin/events/'
end



