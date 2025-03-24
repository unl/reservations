require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'
require 'erb'
require 'models/lockout'

get '/status_page/?' do
	@breadcrumbs << {:text => 'Status Page'}

    lockout_count = Lockout.where('released_on IS NOT NULL AND released_on < ?', Time.now).select(:resource_id).distinct.count

    #Will change this later
    inop_tools = Tool.where(:INOP => 1).all.to_a
	
	erb :'/engineering_garage/status_page', :layout => :fixed, :locals => {
        :inop_tools => inop_tools,
        :lockout_count => lockout_count
    }
end