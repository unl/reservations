require './utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require './utils/config_loader'

# set up the database connection
require 'utils/database'

# get sinatra and the app
require 'sinatra'
require 'app'

if ENV['RACK_ENV'] == 'development'
  # weird workaround for localhost cookie things
  set :cookie_options, :domain => nil
else
  set :cookie_options, :domain => 'innovationstudio-manager.unl.edu'
end

# system("ruby config/scheduler.rb")
# require 'rufus-scheduler'
# scheduler = Rufus::Scheduler.new
# require 'quickstart.rb'
# Rufus::Scheduler.singleton.every '5s' { puts "Hello there" }

# run it
run Sinatra::Application
