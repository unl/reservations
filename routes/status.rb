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
    lockouts = Lockout.where('released_on IS NOT NULL AND released_on < ?', Time.now).includes(:resource).all
    upcoming_lockouts = Lockout.where('started_on BETWEEN ? AND ?', Time.now, Time.now + 7.days).includes(:resource)

	erb :'/engineering_garage/status_page', :layout => :fixed, :locals => {
        :lockout_count => lockout_count,
        :lockouts => lockouts,
        :upcoming_lockouts => upcoming_lockouts
    }
end