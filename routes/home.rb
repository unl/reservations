require 'models/reservation'
require 'models/event'

get '/home/?' do
	reservations = Reservation.joins(:resource).
		where(:resources => {:service_space_id => SS_ID}).
		where(:user_id => @user.id).
		where('end_time >= ?', Time.now).
		order(:start_time).all

	events = Event.includes(:event_type).joins(:event_signups).
		where(:event_signups => {:user_id => @user.id}).
		where('end_time >= ?', Time.now).
		order(:start_time).all

	erb :home, :layout => :fixed, :locals => {
		:reservations => reservations,
		:events => events
	}
end