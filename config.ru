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


# int x = 0
# if x = 0
#   Thread.start{system("ruby config/initializers/scheduler.rb")}
#   x++
# end

# require 'actionpool'
# pool = ActionPool::Pool.new(:min_threads => 1, :max_threads => 1)
# pool.process do
#   # system("ruby config/initializers/scheduler.rb")
#   require 'config/initializers/scheduler.rb'
# end

# require 'highlander'
# require 'config/initializers/scheduler.rb'

# Thread.start{system("ruby config/initializers/scheduler.rb")}
# Thread.start(Rake::Task['start_scheduler'].invoke)
# require 'rufus-scheduler'
# scheduler = Rufus::Scheduler.new
# require 'quickstart.rb'
# Rufus::Scheduler.singleton.every '5s' { puts "Hello there" }

# run it
run Sinatra::Application