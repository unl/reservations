require 'active_record'

ActiveRecord::Base.establish_connection({
    :adapter => CONFIG['database']['adapter'],
    :host => CONFIG['database']['host'],
    :username => CONFIG['database']['username'],
    :password => CONFIG['database']['password'],
    :database => CONFIG['database']['database']
})
