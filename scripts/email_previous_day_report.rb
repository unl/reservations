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

SS_ID = ServiceSpace.where(:id => CONFIG['app']['service_space_id']).first.id

users_authrizd_today = User.joins(:attended_orientations)
        .where(users: {:service_space_id => SS_ID})
        .where(attended_orientations: { 'date_attended >= ? AND date_attended < ?', Time.now - 1.days, Time.now}).all
        
if users_authrizd_today.count > 0
    body = "<p>Here is the list of users that were newly authorized (attended orientation) today: </p>"
    users_authrizd_today.each do |user|
        body = body << "<p>Full Name: #{user.first_name} #{user.last_name}, Email: #{user.email}, NUID: #{user.NUID}</p>"
    end
    Emailer.mail(CONFIG['app']['email_from'], "Previous Day Report", body, '', nil)
end    
    