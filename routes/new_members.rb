require 'models/event'
require 'models/event_signup'

get '/new_members/?' do
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id

    erb :new_members, :layout => :fixed, :locals => {
    	:events => Event.where(:service_space_id => SS_ID, :event_type_id => new_member_orientation_id).all
    }
end

get '/new_members/sign_up/:event_id/?' do
	erb :new_member_signup, :layout => :fixed
end

post '/new_members/sign_up/:event_id/?' do
	EventSignup.create(
		:event_id => params[:event_id],
		:name => params[:name]
	)

	redirect '/new_members/'
end

