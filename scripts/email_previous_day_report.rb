require 'bundler/setup'

require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require_relative '../utils/config_loader'

# set up the database connection
require 'utils/database'

# script-necessary things
require 'models/user'
require 'models/service_space'
require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'
require 'models/lockout'
require 'models/touch_point_log'

SS_ID = ServiceSpace.where(:id => CONFIG['app']['service_space_id']).first.id

# Get Newly Authorized Users
users_authrizd_today = User.joins(:attended_orientations)
        .where(users: {:service_space_id => SS_ID})
        .where(attended_orientations: { 'date_attended >= ? AND date_attended < ?', Time.now - 1.days, Time.now}).all

# Status page
# Num of Lockouts Logic
lockout_count = Lockout.where('released_on IS NOT NULL AND released_on < ?', Time.now).select(:resource_id).distinct.count

# Get lockouts Logic
lockouts = Lockout.where('released_on IS NOT NULL AND released_on < ?', Time.now).includes(:resource).all

# Logic for Orientation Potentials Logic
orientation_ids = Event.where(event_type_id: 12).pluck(:id)
orientation_signups = EventSignup.where(event_id: orientation_ids)
orientation_potentials = orientation_signups.where(attended: false).count

# Logic for Timeless Event Potentials Logic
timeless_events = Event.where(start_time: nil, service_space_id: SS_ID).where.not(event_type_id: 12).map do |event|
  {
    title: event.title,
    potential_walkins: EventSignup.where(event_id: event.id, attended: false).count
  }
end

# Upcoming Lockouts Logic
upcoming_lockouts = Lockout.where('started_on BETWEEN ? AND ?', Time.now, Time.now + 7.days).includes(:resource)

# Upcoming resource reservations Logic
reservations = Reservation.select(:id, :start_time, :end_time).where.not(start_time: nil, end_time: nil)

# Plain text
body = "Daily Orientation Status Report\n\n"

# Authorized Users
if users_authrizd_today.count > 0
    body << "Users Authorized Today:\n"
    users_authrizd_today.each do |user|
        body << "- #{user.first_name} #{user.last_name}, Email: #{user.email}, NUID: #{user.NUID}\n"
    end
else
    body << "No users were authorized today.\n"
end

# Potential orientation
body << "\nUsers Signed Up for Orientation (Not Yet Attended): #{orientation_potentials} user(s)\n"

# Timeless events
if timeless_events.any?
    body << "\nTimeless Events (No Start Time):\n"
    timeless_events.each do |event|
        body << "- #{event[:title]} — Potential Walk-ins: #{event[:potential_walkins]}\n"
    end
else
    body << "\nNo timeless events found.\n"
end

# Past lockouts
body << "\nPast Lockouts:\n"
if lockouts.any?
    lockouts.each do |lockout|
        body << "- Resource: #{lockout.resource.name}, Released On: #{lockout.released_on.strftime('%Y-%m-%d')}\n"
    end
else
    body << "No past lockouts found.\n"
end

# Upcoming lockouts
body << "\nUpcoming Lockouts (Next 7 Days):\n"
if upcoming_lockouts.any?
    upcoming_lockouts.each do |lockout|
        body << "- Resource: #{lockout.resource.name}, Starts On: #{lockout.started_on.strftime('%Y-%m-%d')}\n"
    end
else
    body << "No upcoming lockouts scheduled.\n"
end

# Reservations
body << "\nActive Reservations:\n"
if reservations.any?
    reservations.each do |res|
        body << "- Reservation ID: #{res.id}, Start: #{res.start_time}, End: #{res.end_time}\n"
    end
else
    body << "No current reservations found.\n"
end

body << "\nThis is an automated daily report."

# Send email
Emailer.mail(CONFIG['app']['email_from'], "Daily Status Report", body, '', nil)
