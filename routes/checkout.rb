require "models/resource"
require "models/reservation"
require "models/event"
require "models/event_type"
require "models/event_signup"
require "models/space_hour"
require "date"
require "erb"

get "/checkout/?" do
  @breadcrumbs << { :text => "Checkout" }
  require_login

  nuid = params[:nuid]

  # This should change to select the user and their projects from the db
  # checkout_user = nuid

  # user_projects = []
  # user_checked_out = []
  user_projects = [
    { id: 1, location: "Garage A", name: "Project Alpha", last_accessed: DateTime.now - 1, description: "Building a robot" },
    { id: 2, location: "Garage B", name: "Project Beta", last_accessed: DateTime.now - 2, description: "Creating a drone" },
    { id: 3, location: "Garage C", name: "Project Gamma", last_accessed: DateTime.now - 3, description: "Developing a new app" },
    { id: 4, location: "Garage D", name: "Project Delta", last_accessed: DateTime.now - 4, description: "Designing a new car model" },
    { id: 5, location: "Garage E", name: "Project Epsilon", last_accessed: DateTime.now - 5, description: "Constructing a bridge" },
  ]
  user_checked_out = [
    { id: 1, name: "Hammer", checked_out_date: DateTime.now - 1 },
    { id: 2, name: "Screwdriver", checked_out_date: DateTime.now - 2 },
    { id: 3, name: "Wrench", checked_out_date: DateTime.now - 3 },
    { id: 4, name: "Pliers", checked_out_date: DateTime.now - 4 },
    { id: 5, name: "Saw", checked_out_date: DateTime.now - 5 },
  ]

  erb :'engineering_garage/checkout', :layout => :fixed, :locals => {
                                    :projects => user_projects,
                                    :checked_out => user_checked_out,
                                  }
end

get "/checkout/new_project/user?" do
  @breadcrumbs << { :text => "New_Project" }
  require_login

  erb :'engineering_garage/new_project_user_confirmation', :layout => :fixed, :locals => {}
end

post "/checkout/new_project/user?" do
  @breadcrumbs << { :text => "New_Project" }
  require_login
  user_by_nuid = User.where(:user_nuid => params[:nuid])
  user_by_email = User.where(:email => params[:email])

  raise "NUID: #{user_by_nuid.username}, EMAIL: #{user_by_email.username}"

  if user_by_nuid != nil && user_by_email != nil
    if user_by_nuid != user_by_email
      flash :error, 'Error', 'User by NUID and User by email do not match'
      redirect back
    end
  end
  redirect "/checkout/new_project/create?"
end

get "/checkout/new_project/create?" do
  @breadcrumbs << { :text => "New_Project" }
  require_login

  erb :'engineering_garage/new_project', :layout => :fixed, :locals => {}
end

post "/checkout/new_project/create?" do
  @breadcrumbs << { :text => "New_Project" }
  require_login
  redirect "/checkout/?"
end
