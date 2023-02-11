require 'models/permission'
require 'models/alert'

before '/admin/alerts*' do
	unless has_permission?(Permission::MANAGE_RESOURCES)
		raise Sinatra::NotFound
	end
end

get '/admin/alerts/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Alerts'}

	alerts = Alert.all.order(:category_id).to_a

	erb :'admin/alerts', :layout => :fixed, :locals => {
		:alerts => alerts
	}

end

get '/admin/alerts/create/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Alerts', :href => '/admin/alerts/'} << {:text => 'Create Alert'}

	erb :'admin/edit_alert', :layout => :fixed, :locals => {
		:alert => Alert.new
	}
end

post '/admin/alerts/create/?' do
	require_login

	if  params[:name] == ""
		flash :error, 'Error', 'Please enter alert name'
		redirect back
	end

	alert = Alert.new
	alert.name = params[:name]
	alert.category_id = params[:category_id]
	alert.description = params[:description]
	alert.save

	flash(:success, 'Alert Created', "Your Alert #{alert.name} has been created.")
	redirect '/admin/alerts/'
end