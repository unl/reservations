require './utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require './utils/config_loader'

# set up the database connection
require 'utils/database'

# get sinatra and the app
require 'sinatra'
require 'app'

if CONFIG['app']['cookie_domain'].nil? || CONFIG['app']['cookie_domain'].empty?
  set :cookie_options, :domain => nil
else
  set :cookie_options, :domain => CONFIG['app']['cookie_domain']
end

# start scheduler on new thread so program doesn't hang waiting for it to finish
Thread.start{system("ruby config/initializers/scheduler.rb")}

# run it
run Sinatra::Application