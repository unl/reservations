require 'models/user'
require 'models/resource'
require 'models/permission'
require 'models/event'
require 'csv'
require 'date'

get '/export/?' do
    not_found if SS_ID != 1

    require_login
    user_events = Event.includes(:event_type).joins(:event_signups).
        where(:event_signups => {:user_id => @user.id}).
        where('end_time >= ?', Time.now)
    trainer_events = Event
        .where('end_time >= ?', Time.now)
        .where('trainer_id = ? OR trainer_2_id = ? OR trainer_3_id = ?', @user.id, @user.id, @user.id)
    csv_string = CSV.generate do |csv|
        csv << ["Subject", "Start Date", "Start Time", "End Date", "End Time", "All Day Event", "Description", "Location", "Private"]
        if !user_events.nil?
            user_events.each do |event|
                csv << [event.title, event.start_time.localtime.strftime("%D"), event.start_time.localtime.strftime("%r"), event.end_time.localtime.strftime("%D"), event.end_time.localtime.strftime("%r"), "FALSE", event.description, "Nebraska Innovation Studio", "TRUE"]
            end
        end
        if !trainer_events.nil?
            trainer_events.each do |event|
                csv << [event.title, event.start_time.localtime.strftime("%D"), event.start_time.localtime.strftime("%r"), event.end_time.localtime.strftime("%D"), event.end_time.localtime.strftime("%r"), "FALSE", event.description, "Nebraska Innovation Studio", "TRUE"]
            end
        end
    end

    content_type 'application/csv'
    attachment 'NIS_Trainings_and_Events.csv'
    csv_string
end