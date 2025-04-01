require 'bundler/setup'

require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require_relative '../utils/config_loader'

# set up the database connection
require 'utils/database'

# script-necessary things
require 'models/user'
require 'models/service_space'
require 'sinatra'
require 'routes/new_members'

SS_ID = ServiceSpace.where(:id => CONFIG['app']['service_space_id']).first.id

users_to_set_nuid = User
  .where(service_space_id: SS_ID)
  .where("user_nuid IS NULL OR user_nuid < 0")

users_to_set_nuid.each do |user|
  if user.university_status != 'Non-NU Student (All Other Institutions)'
    if user.user_nuid.nil? || (user.user_nuid.to_i > -20 && user.user_nuid.to_i < 0)
      nuid_hash = user.fetch_nuid()
      if nuid_hash[:status]
        user.set_nuid(nuid_hash[:nuid])
      else
        user.increment_nuid_retrival_failures()
      end
    end
  end
end