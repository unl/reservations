# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :environment, "development"

require './models/user'
require_relative '../utils/language'
require './Rakefile'

every 1.minutes do

    # command '../scripts/email_expiring_users.rb'
    rake ':email_expiring_users'
    # ruby "email_expiring_users.rb"

    # users = User.where(:email => 'jjacobs10@huskers.unl.edu').all

    # users.each do |user|
    #     user.send_membership_expiring_email
    # end
end
