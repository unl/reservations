# env 'PATH', ENV['PATH']
# env :PATH, ENV['PATH']
# env :PATH, ENV['PATH']
# env :GEM_PATH, ENV['GEM_PATH']
# env :PATH, ENV['PATH']
# ENV.each { |k, v| env(k, v) }
# set :env_path, ''
# env :PATH, @env_path if @env_path.present?
require "whenever/cron.rb"
set :environment, "production"
set :output, "./cron_log.log"
# require 'rake'

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

# Rake:Task['email_expiring_users'].invoke
# Rake:Task['email_expiring_users'].execute
# Rake:Task[':email_expiring_users'].invoke
# Rake:Task[':email_expiring_users'].execute
# rake "email_expiring_users"
# :rake "Rakefile:email_expiring_users"
# rake 'task:email_expiring_users'


# require './scripts/email_expiring_users.rb'
# runner "user.email_expiration_test"

# rake "rake:email_expiring_users"
# command "ruby ./scripts/email_expiring_users.rb"
# ruby "./scripts/email_expiring_users.rb"

every 1.minutes do

    # rake "rake:environment"
    # require './scripts/email_expiring_users.rb'
    # runner "user.email_expiration_test"
    # rake "rake:email_expiring_users"
    # ruby "./scripts/email_expiring_users.rb"
    puts "Hello there"
    # command "ruby ./scripts/email_expiring_users.rb"
    # command "ruby /scripts/email_expiring_users.rb"

    # rake 'task:email_expiring_users'
    # rake ':email_expiring_users'



    require './scripts/email_expiring_users.rb'

end