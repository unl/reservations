require 'models/announcements'

before '/admin/announcements/create*' do
	unless has_permission?(Permission::SUPER_USER)
		raise Sinatra::NotFound
	end
end

get '/admin/announcements/create/?' do
	require_login
	@breadcrumbs << {:text => 'Admin', :href => '/admin/'}
	@breadcrumbs << {:text => 'Announcements', :href => '/admin/announcements/'}
	@breadcrumbs << {:text => 'Create Announcement'}
	erb :'admin/announcement_create', :layout => :fixed_61
end

post '/admin/announcements/create/post/?' do
	require_login

	announcement = Announcements.new
	announcement.text = params[:text]
	if announcement.text.empty?
		flash :error, 'Error', 'Please enter the text for the announcement'
		redirect back
	end
	announcement.header = params[:header]
	if announcement.header.empty?
		flash :error, 'Error', 'Please enter the header for the announcement'
		redirect back
	end
	announcement.status = !params[:status].nil?
	announcement.save

	flash :success, 'Success', 'Your announcement has been created!'
	redirect '/admin/announcements/'
end