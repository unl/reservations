require 'models/resource'
require 'models/permission'

before '/admin/alerts*' do
	unless has_permission?(Permission::MANAGE_RESOURCES)
		raise Sinatra::NotFound
	end
end

get '/admin/alerts/?' do

    erb :'admin/alerts', :layout => :fixed

end