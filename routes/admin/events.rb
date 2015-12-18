require 'rest-client'
require 'models/event'
require 'models/event_type'
require 'models/location'
require 'models/resource'

before '/admin/events*' do
	unless @user.has_permission?(Permission::MANAGE_EVENTS)
		raise Sinatra::NotFound
	end
end

def set_event_data(event, params)
	event.title = params[:title]
	event.description = params[:description]
	event.start_time = calculate_time(params[:start_date], params[:start_time_hour], params[:start_time_minute], params[:start_time_am_pm])
	event.end_time = calculate_time(params[:end_date], params[:end_time_hour], params[:end_time_minute], params[:end_time_am_pm])
	event.event_type_id = params[:type]
	event.location_id = params[:location]
	event.max_signups = params[:limit_signups] == 'on' ? params[:max_signups].to_i : nil
	event.service_space_id = SS_ID

	event
end

get '/admin/events/?' do
	@breadcrumbs << {:text => 'Admin Events'}
	page = params[:page]
	page = page.to_i >= 1 ? page.to_i : 1
	page_size = 10
	tab = ['upcoming', 'past'].include?(params[:tab]) ? params[:tab] : 'upcoming'

	case tab
	when 'past'
		where_clause = 'start_time < ?', Time.now
		order_clause = {:start_time => :desc}
	else
		where_clause = 'start_time >= ?', Time.now
		order_clause = {:start_time => :asc}
	end

	iterator = Event.includes(:event_signups).where(:service_space_id => SS_ID).where(where_clause)

	erb :'admin/events', :layout => :fixed, :locals => {
		:events => iterator.order(order_clause).limit(page_size).offset((page-1)*page_size).all,
		:total_pages => (iterator.count.to_f / page_size).ceil,
		:page => page,
		:tab => tab
	}
end

get '/admin/events/:event_id/signup_list/?' do
	@breadcrumbs << {:text => 'Admin Events', :href => '/admin/events/'} << {text: 'Signup List'}
	event = Event.includes(:event_signups).find_by(:id => params[:event_id], :service_space_id => SS_ID)
	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end

	erb :'admin/signup_list', :layout => :fixed, :locals => {
		:event => event
	}
end

get '/admin/events/create/?' do
	@breadcrumbs << {:text => 'Admin Events', :href => '/admin/events/'} << {text: 'Create Event'}
	erb :'admin/new_event', :layout => :fixed, :locals => {
		:event => Event.new,
		:types => EventType.where(:service_space_id => SS_ID).all,
		:locations => Location.where(:service_space_id => SS_ID).all,
		:tools => Resource.where(:service_space_id => SS_ID, :is_reservable => true).all
	}
end

post '/admin/events/create/?' do
	event = Event.new
	event = set_event_data(event, params)
	event.save

	if params.has_key?('reserve_tool') && params['reserve_tool'] == 'on'
		# we need to create a reservation for the tool on the appropriate time
		Reservation.create(
			:resource_id => params[:tool],
			:event_id => event.id,
			:start_time => event.start_time,
			:end_time => event.end_time,
			:is_training => true,
			:user_id => nil
		)
	end

	if params.has_key?('export_to_unl_events') && params['export_to_unl_events'] == 'on'
		post_params = {
			:title => params[:title],
			:description => params[:description],
			:location => CONFIG['unl_events_location_id'],
			:start_time => event.start_time.in_time_zone.strftime('%Y-%m-%d %H:%M:%S'),
			:end_time => event.end_time.in_time_zone.strftime('%Y-%m-%d %H:%M:%S'),
			:api_token => CONFIG['unl_events_api_token']
		}

		if params.has_key?('consider_for_unl_main') && params['consider_for_unl_main'] == 'on'
			post_params['send_to_main'] =  'yes'
		end

		RestClient.post("#{CONFIG['unl_events_api_url']}#{CONFIG['unl_events_api_calendar']}/create/", post_params) do |response, request, result, &block|
			case response.code
			when 200
				flash(:success, 'Event Posted to UNL Events', "The event can now be found on the NIS UNL Events calendar.")
			end
		end
	end

	# notify that it worked
	flash(:success, 'Event Created', "Your #{event.type.description}: #{event.title} has been created.")
	redirect '/admin/events/'
end

get '/admin/events/:event_id/edit/?' do
	@breadcrumbs << {:text => 'Admin Events', :href => '/admin/events/'} << {text: 'Edit Event'}
	event = Event.includes(:event_type, :location, :reservation => :resource).find_by(:id => params[:event_id], :service_space_id => SS_ID)
	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end

	erb :'admin/new_event', :layout => :fixed, :locals => {
		:event => event,
		:types => EventType.where(:service_space_id => SS_ID).all,
		:locations => Location.where(:service_space_id => SS_ID).all,
		:tools => Resource.where(:service_space_id => SS_ID, :is_reservable => true).all
	}
end

post '/admin/events/:event_id/edit/?' do
	event = Event.find_by(:id => params[:event_id], :service_space_id => SS_ID)
	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end
	event = set_event_data(event, params)
	event.save

	# check the tool reservation for this
	checked = params.has_key?('reserve_tool') && params['reserve_tool'] == 'on'
	if event.has_reservation && checked
		# update the reservation
		event.reservation.update(
			:resource_id => params[:tool],
			:event_id => event.id,
			:start_time => event.start_time,
			:end_time => event.end_time,
			:is_training => true,
			:user_id => nil
		)
	elsif event.has_reservation && !checked
		# remove the reservation
		event.reservation.delete
	elsif !event.has_reservation && checked
		# create the reservation
		Reservation.create(
			:resource_id => params[:tool],
			:event_id => event.id,
			:start_time => event.start_time,
			:end_time => event.end_time,
			:is_training => true,
			:user_id => nil
		)
	end

	# notify that it worked
	flash(:success, 'Event Updated', "Your #{event.type.description}: #{event.title} has been updated.")
	redirect '/admin/events/'
end

post '/admin/events/:event_id/delete/?' do
	event = Event.find_by(:id => params[:event_id], :service_space_id => SS_ID)
	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end

	event.destroy

	flash(:success, 'Event Deleted', "Your event #{event.title} has been deleted. All signups on this event have also been removed, and if a reservation was attached, it also has been removed.")
	redirect '/admin/events/'
end