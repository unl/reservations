require 'models/user'

get '/admin/email/?' do
	erb :'admin/emails', :layout => :fixed
end

get '/admin/email/send/?' do
	users = User.all

	erb :'admin/send_email', :layout => :fixed, :locals => {
		:users => users
	}
end

post '/admin/email/send/?' do
	if params[:to] == 'all'
		# send to all users in bcc
		users = User.all
		bcc = users.map(&:email).join(',')
		Emailer.mail('', params[:subject], params[:body], bcc)
	else
		user = User.find_by(:id => params[:to])
		Emailer.mail(user.email, params[:subject], params[:body])
	end

	flash :success, 'Email sent', 'Your email was sent.'
	redirect '/admin/email/'
end