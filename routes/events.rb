require 'models/event'
require 'models/event_signup'

get '/events/:event_id/?' do
	# this is an event details page
	begin
		event = Event.includes(:location, :event_type, :event_signups).find(params[:event_id])
	rescue ActiveRecord::RecordNotFound => e
		not_found
	end

	@breadcrumbs << {:text => event.title}

	erb :event_details, :layout => :fixed, :locals => {
		:event => event
	}
end

post '/events/:event_id/sign_up/?' do
	require_login

	# check that is a valid event
	event = Event.includes(:event_type).find_by(:service_space_id => SS_ID, :id => params[:event_id])

	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/calendar/'
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => @user.full_name,
		:user_id => @user.id
	)

	if event.type.description != 'Free Event'
		body = <<EMAIL
<p>Thank you, #{@user.full_name} for signing up for #{event.title}. Don't forget that this training is</p>

<p><strong>#{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}</strong>.</p>

<p>We'll see you there!</p>

<p>Nebraska Innovation Studio</p>
EMAIL

		Emailer.mail(@user.email, "Nebraska Innovation Studio - #{event.title}", body)

		# flash a message that this works
		flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, #{event.title} is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}.")
		redirect back
	else
		# flash a message that this works
		flash(:success, "Event Marked", "This free event has been marked on your hoempage.")
		redirect back
	end
end

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