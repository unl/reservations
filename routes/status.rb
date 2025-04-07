require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'
require 'erb'
require 'models/lockout'

get '/status_page/?' do
	@breadcrumbs << {:text => 'Status Page'}

    lockout_count = Lockout.where('released_on IS NOT NULL AND released_on < ?', Time.now).select(:resource_id).distinct.count
    lockouts = Lockout.where('released_on IS NOT NULL AND released_on < ?', Time.now).includes(:resource).all
    
    # Retrieve a list events ID's of events with the Garage Orientation Event Type
    orientation_ids = Event.where(event_type_id: 12).pluck(:id)
    # Retrieve a list of event signups based on the orientation ID's (ActiveRecord handles multiple inputs for SQL search)
    orientation_signups = EventSignup.where(event_id: orientation_ids)
    # Get the number of people that haven't attended Orientation from the previous query
    orientation_potentials = orientation_signups.where(attended: false).count

    # Get timeless events and their unattended signups count
    timeless_events = Event.where(start_time: nil, service_space_id: 8).where.not(event_type_id: 12).map do |event|
        {
        title: event.title,
        potential_walkins: EventSignup.where(event_id: event.id, attended: false).count
        }
    end
  
    upcoming_lockouts = Lockout.where('started_on BETWEEN ? AND ?', Time.now, Time.now + 7.days).includes(:resource)
    reservations = Reservation.select(:id, :start_time, :end_time).where.not(start_time: nil, end_time: nil)


	erb :'/engineering_garage/status_page', :layout => :fixed, :locals => {
        :lockout_count => lockout_count,
        :lockouts => lockouts,
        :orientation_potentials => orientation_potentials,
        :upcoming_lockouts => upcoming_lockouts,
        :reservations => reservations,
        :timeless_events => timeless_events
    }
end
# events > event_type = 12
# Filter event signups for all event ids for 