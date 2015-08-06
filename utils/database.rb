require 'active_record'

if ENV['RACK_ENV'] == 'development'
    # mysql connection
    ActiveRecord::Base.establish_connection({
        :adapter => 'mysql',
        :host => 'localhost',
        :username => 'root',
        :password => '',
        :database => 'reservations'
    })
elsif ENV['RACK_ENV'] == 'production'
    ActiveRecord::Base.establish_connection(ENV['DB_CONNECTION_STRING'])
end