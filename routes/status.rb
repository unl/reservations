require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'
require 'erb'

get '/status_page/?' do
	@breadcrumbs << {:text => 'Status Page'}

    #Will change this later
    inop_tools = Tool.where(:INOP => 1).all.to_a
	
	erb :'/engineering_garage/status_page', :layout => :fixed, :locals => {
        :inop_tools => inop_tools
    }
end