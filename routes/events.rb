post '/events/:event_id/remove_signup/?' do
	require_login

	# get the event
	event = Event.includes(:event_type).where(:id => params[:event_id]).first

	# check that the signup exists
	signup = EventSignup.where(:event_id => params[:event_id], :user_id => @user.id).first

	if signup.nil?
		flash :alert, 'Not Found', 'That signup was not found.'
		redirect '/home/'
	end
	signup.delete

	header = event.type.description == 'Free Event' ? 'Event Removed' : 'Signup Removed'
	message = event.type.description == 'Free Event' ? "#{event.title} has been removed from your calendar." : "Your signup for #{event.title} has been removed."

	flash :success, header, message
	redirect '/home/'
end