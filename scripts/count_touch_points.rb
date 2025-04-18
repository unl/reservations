require 'bundler/setup'

require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require_relative '../utils/config_loader'

# set up the database connection
require 'utils/database'

# script-necessary things
require 'models/attended_orientation'
require 'models/event'
require 'models/event_signup'
require 'models/project'
require 'models/project_log'
require 'models/reservation'
require 'models/resource_authorization'
require 'models/resource'
require 'models/service_space'
require 'models/tool_log'

SS_ID = ServiceSpace.where(:id => CONFIG['app']['service_space_id']).first.id

today = Date.today.all_day
total_touches = 0

# project (created_on = today)
total_touches += Project.where(created_on: today).count

# project_logs (checked_date = today)
total_touches += ProjectLog.where(checked_date: today).count

# tool_logs (checked_date = today) 
total_touches += ToolLog.where(checked_date: today).count

# reservations (start_time = today)  
total_touches += Reservation.joins(:resource).where('resources.service_space_id' => 8).where('reservations.start_time' => today).count

# attended_orientation (date_attended = today)
total_touches += AttendedOrientation.joins(:event).where('attended_orientations.date_attended' => today).where('events.service_space_id' => 8).count

# event attendance (  GET eventID where(event.start_time = today), countif(event_signups(eventID) where attended = 1)  )
total_touches += EventSignup.joins(:event).where('events.start_time' => today).where('event_signups.attended' => 1).where('events.service_space_id' => 8).count

# resource_authorizations (authorized_date = today)
total_touches += ResourceAuthorization.where(:authorized_date => today).count

puts "touch count is #{total_touches}"
