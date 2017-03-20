require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require_relative '../utils/config_loader'

# set up the database connection
require 'utils/database'

# script-necessary things
require 'models/user'

users = User.where('expiration_date >= ? AND expiration_date < ?', Time.now + 3.days, Time.now + 4.days).all

users.each do |user|
	user.send_membership_expiring_email
end