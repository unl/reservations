require 'models/user'
require 'models/permission'
require 'models/expiration_reminder'

before '/admin/email*' do
	unless has_permission?(Permission::MANAGE_EMAILS)
		raise Sinatra::NotFound
	end
end

get '/admin/email/?' do
	@breadcrumbs << {:text => 'Admin Emails'}
	erb :'admin/emails', :layout => :fixed
end

get '/admin/email/expiration_email/?' do

	reminder = ExpirationReminder.first

	erb :'admin/manage_expiration_email', :layout => :fixed, :locals => {
		:firstReminder => reminder.first_reminder,
		:secondReminder => reminder.second_reminder,
	}
end

post '/admin/email/expiration_email/?' do
	new_first_reminder = params[:days_before_sending_first_reminder].to_i
	new_second_reminder = params[:days_before_sending_second_reminder].to_i
	
	if new_second_reminder >= new_first_reminder
		flash :error, 'Error', 'Please ensure the second reminder happens after the first and is not on the same day'
		redirect back
	end

	reminder = ExpirationReminder.first

	reminder.first_reminder = new_first_reminder
	reminder.second_reminder = new_second_reminder

	reminder.save

	reminder = ExpirationReminder.first

	if reminder.first_reminder != new_first_reminder && reminder.second_reminder != new_second_reminder
		flash :error, 'Error', 'Failed to update preferences please try again'
		redirect back
	end

	flash :success, 'Success', 'Your preferences have been updated!'

	erb :'admin/manage_expiration_email', :layout => :fixed, :locals => {
		:firstReminder => reminder.first_reminder,
		:secondReminder => reminder.second_reminder,
	}

end

get '/admin/email/send/?' do
	@breadcrumbs << {:text => 'Admin Emails', :href => '/admin/email/'}
	@breadcrumbs << {:text => 'Send Email'}
	users = User.all

	erb :'admin/send_email', :layout => :fixed, :locals => {
		:users => users
	}
end

post '/admin/email/send/?' do
	users_to_send_to = []

	# compile the list based on what was checked
	if params.checked?('send_to_all_non_admins')
		users = User.where(:service_space_id => SS_ID, :is_admin => false).where.not(:space_status => 'expired_no_email').all
		users_to_send_to += users
	end
	if params.checked?('send_to_all_users')
		users = User.where(:service_space_id => SS_ID).where.not(:space_status => 'expired_no_email').all
		users_to_send_to += users
	end
	if params.checked?('send_to_all_students')
		users = User.where(:service_space_id => SS_ID, :university_status => ['UNL Undergrad','UNL Grad','Other Student']).where.not(:space_status => 'expired_no_email').all
		users_to_send_to += users
	end
	if params.checked?('send_to_all_facstaff')
		users = User.where(:service_space_id => SS_ID, :university_status => ['UNL Staff','UNL Faculty','Emeritus UNL Faculty']).where.not(:space_status => 'expired_no_email').all
		users_to_send_to += users
	end
	if params.checked?('send_to_specific_user')
		params[:specific_user].each do |id|
			user = User.find_by(:service_space_id => SS_ID, :id => id)
			users_to_send_to << user unless user.nil?
		end
	end

	# compact and uniqify the list
	users_to_send_to = users_to_send_to.compact.uniq do |user|
		user.id
	end

	# check on attachments
 	attachments = {}
 	params.select {|k,v| k.start_with?('file_')}.each do |key, file_hash|
 		attachments[file_hash[:filename]] = file_hash[:tempfile].read
 	end
 	attachments = nil if attachments.empty?

	# correctly choose how to send
	if users_to_send_to.count == 1
		Emailer.mail(users_to_send_to[0].email, params[:subject], params[:body], '', attachments)
		output = users_to_send_to[0].full_name
	elsif users_to_send_to.count > 1
		bcc = users_to_send_to.map(&:email).join(',')
		Emailer.mail('', params[:subject], params[:body], bcc, attachments)
		output = "#{users_to_send_to.count} users"
	else
		flash :error, 'No Users Selected', 'This email was not sent to any users'
		redirect back
	end

	flash :success, 'Email sent', "Your email was sent to #{output}."
	redirect '/admin/email/send/'
end