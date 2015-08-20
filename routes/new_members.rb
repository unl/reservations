require 'models/event'
require 'models/event_signup'

get '/new_members/?' do
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id

    erb :new_members, :layout => :fixed, :locals => {
    	:events => Event.where(:service_space_id => SS_ID, :event_type_id => new_member_orientation_id).all
    }
end

get '/new_members/sign_up/:event_id/?' do
	# check if this is a new member signup orientation
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id
	event = Event.find_by(:service_space_id => SS_ID, :id => params[:event_id])
	if event.nil? || event.event_type_id != new_member_orientation_id
		# that event does not exist
	end

	erb :new_member_signup, :layout => :fixed, :locals => {
		:event => event
	}
end

post '/new_members/sign_up/:event_id/?' do
	if params[:signup_password] != 'makerspace'
		# error
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => params[:name],
		:email => params[:email]
	)

	# flash a message that this works
	redirect '/new_members/'
end

