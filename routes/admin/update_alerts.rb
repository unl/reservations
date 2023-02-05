require 'models/resource'
require 'models/permission'

before '/admin/update_alerts*' do
	unless has_permission?(Permission::MANAGE_RESOURCES)
		raise Sinatra::NotFound
	end
end

get '/admin/update_alerts/?' do

    erb :'admin/update_alerts', :layout => :fixed

end