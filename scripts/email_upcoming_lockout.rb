require 'bundler/setup'

require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require_relative '../utils/config_loader'

# set up the database connection
require 'utils/database'

# script-necessary things
require 'models/lockout'
require 'models/permission'
require 'models/user_has_permission'
require 'models/resource'
require 'models/reservation'
require 'models/user'

# Gets all lockouts without a release date
lockouts = Lockout.where(released_on: nil).to_a

lockouts.each do |lockout|
	lockout.email_lockout_affected_users(Time.now.in_time_zone.midnight + 1.day, Time.now.in_time_zone.midnight + 2.day, false)
end