require 'erb'
require 'json'
require 'net/http'
require 'models/user'

get '/engineering_garage/user_agreement/?' do
    require_login
    @breadcrumbs << {:text => 'Agreement Renewal'}
	
    erb :'/engineering_garage/user_agreement', :layout => :fixed
end

post '/engineering_garage/user_agreement/?' do
    #On form submit, update user agreement expiration date
    @user.set_user_agreement_expiration_date(Date.today.next_year)
	redirect '/home/'

end
