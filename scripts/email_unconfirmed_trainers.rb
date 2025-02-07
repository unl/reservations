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

trainers_to_notify = User.
    where(:service_space_id => SS_ID).
    where('is_trainer = 1').where('
    EXISTS(SELECT *
        FROM events
        WHERE service_space_id = ?
        AND start_time > ?
        AND trainer_id > 0
        AND trainer_confirmed = 0
        AND events.trainer_id = users.id)', SS_ID, Time.now).all

trainers_to_notify.each do |user|
    user.send_trainer_confirmation_reminder
end

trainers_2_to_notify = User.
    where(:service_space_id => SS_ID).
    where('is_trainer = 1').where('
    EXISTS(SELECT *
        FROM events
        WHERE service_space_id = ?
        AND start_time > ?
        AND trainer_2_id > 0
        AND trainer_2_confirmed = 0
        AND events.trainer_2_id = users.id)', SS_ID, Time.now).all

trainers_2_to_notify.each do |user|
    user.send_trainer_confirmation_reminder
end

trainers_3_to_notify = User.
    where(:service_space_id => SS_ID).
    where('is_trainer = 1').where('
    EXISTS(SELECT *
        FROM events
        WHERE service_space_id = ?
        AND start_time > ?
        AND trainer_3_id > 0
        AND trainer_3_confirmed = 0
        AND events.trainer_3_id = users.id)', SS_ID, Time.now).all

trainers_3_to_notify.each do |user|
    user.send_trainer_confirmation_reminder
end