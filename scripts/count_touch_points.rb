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
require 'models/touch_point_log'

SS_ID = ServiceSpace.where(:id => CONFIG['app']['service_space_id']).first.id

today = Date.today.all_day

# project (created_on = today)
# unique_touches = Project.distinct.where(created_on: today).pluck(:owner_user_id)
unique_touches = Project.distinct.pluck(:owner_user_id)

# project_logs (checked_date = today)
# unique_touches |= ProjectLog.distinct.where(checked_date: today).pluck(:checkout_user_id)
unique_touches |= ProjectLog.distinct.pluck(:checkout_user_id)

# tool_logs (checked_date = today) 
# unique_touches |= ToolLog.distinct.where(checked_date: today).pluck(:checkout_user_id)
unique_touches |= ToolLog.distinct.pluck(:checkout_user_id)

# reservations (start_time = today)  
# unique_touches |= Reservation.distinct.joins(:resource).where('resources.service_space_id' => 8).where('reservations.start_time' => today).pluck(:user_id)
unique_touches |= Reservation.distinct.joins(:resource).pluck(:user_id)

# attended_orientation (date_attended = today)
# unique_touches |= AttendedOrientation.distinct.joins(:event).where('attended_orientations.date_attended' => today).where('events.service_space_id' => 8).pluck(:user_id)
unique_touches |= AttendedOrientation.distinct.joins(:event).where('events.service_space_id' => 8).pluck(:user_id)

# event attendance (  GET eventID where(event.start_time = today), countif(event_signups(eventID) where attended = 1)  )
# unique_touches |= EventSignup.distinct.joins(:event).where('events.start_time' => today).where('event_signups.attended' => 1).where('events.service_space_id' => 8).pluck(:user_id)
unique_touches |= EventSignup.distinct.joins(:event).where('events.service_space_id' => 8).pluck(:user_id)

# resource_authorizations (authorized_date = today)
# unique_touches |= ResourceAuthorization.distinct.where(:authorized_date => today).pluck(:user_id)
unique_touches |= ResourceAuthorization.distinct.pluck(:user_id)

# Log count in db
TouchPointLog.create(
  :touch_point_count => unique_touches.count,
  :created_on => Time.now
)
