require './utils/language'
ENV['RACK_ENV'] = ENV['RACK_ENV'] || 'development'
require './utils/config_loader'

require 'active_record'

task :default => :migrate

desc "Migrate the database through scripts in db/migrate. Target specific version with VERSION=x"
task :migrate => :environment do
    ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
end
 
task :environment do
    # set up the database
    require 'utils/database'
end
