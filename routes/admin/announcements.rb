require 'models/announcements'

before '/admin/announcements*' do
	unless has_permission?(Permission::SUPER_USER)
		raise Sinatra::NotFound
	end
end

get '/admin/announcements/?' do
	require_login
	@breadcrumbs << {:text => 'Admin', :href => '/admin/'}
	@breadcrumbs << {:text => 'Announcements'}
	announcements = Announcements.all

	erb :'admin/announcements', :layout => :fixed_61, :locals => {
		:announcements => announcements
	}
end