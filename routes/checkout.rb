require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'
require 'date'
require 'erb'

get '/checkout/?' do
	@breadcrumbs << {:text => 'Checkout'}
	require_login

  nuid = params[:nuid]

  # This should change to select the user and their projects from the db
  # checkout_user = nuid

  # user_projects = []
  # user_checked_out = []
  user_projects = [
    { id: 1, location: 'Garage A', name: 'Project Alpha', last_accessed: DateTime.now - 1 },
    { id: 2, location: 'Garage B', name: 'Project Beta', last_accessed: DateTime.now - 2 },
    { id: 3, location: 'Garage C', name: 'Project Gamma', last_accessed: DateTime.now - 3 },
    { id: 4, location: 'Garage D', name: 'Project Delta', last_accessed: DateTime.now - 4 },
    { id: 5, location: 'Garage E', name: 'Project Epsilon', last_accessed: DateTime.now - 5 }
  ]
  user_checked_out = [
    { id: 1, name: 'Hammer', checked_out_date: DateTime.now - 1 },
    { id: 2, name: 'Screwdriver', checked_out_date: DateTime.now - 2 },
    { id: 3, name: 'Wrench', checked_out_date: DateTime.now - 3 },
    { id: 4, name: 'Pliers', checked_out_date: DateTime.now - 4 },
    { id: 5, name: 'Saw', checked_out_date: DateTime.now - 5 }
  ]

	erb :'engineering_garage/checkout', :layout => :fixed, :locals => {
    :projects => user_projects,
    :checked_out => user_checked_out
  }
end


