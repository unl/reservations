require './utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require './utils/config_loader'

# set up the database connection
require 'utils/database'

# get sinatra and the app
require 'sinatra'
require 'app'
# command "bundle exec whenever"

if ENV['RACK_ENV'] == 'development'
  # weird workaround for localhost cookie things
  set :cookie_options, :domain => nil
else
  set :cookie_options, :domain => 'innovationstudio-manager.unl.edu'
end

# system("bundle exec whenever --update-crontab")
require "whenever"
require "config/schedule.rb"
# require "whenever/capistrano"

# run it
run Sinatra::Application
