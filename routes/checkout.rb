require "models/project"
require "date"
require "erb"

get "/checkout" do
  @breadcrumbs << { :text => "Checkout" }
  require_login

  erb :'engineering_garage/checkout', :layout => :fixed, locals: {}
end

get "/checkout/user?" do
  @breadcrumbs << { :text => "Checkout" }
  require_login

  nuid = params[:nuid]

  if nuid.nil? || nuid.strip.empty?
    redirect "/checkout"
  else
    checkout_user = User.find_by(user_nuid: nuid)
    if checkout_user.nil?
      flash :error, "Error", "User with that NUID not found"
      redirect back
    else
      user_projects = Project.where(owner_user_id: checkout_user.id)
    end
    # Preload the project list
    # Preload the tool list
  end

  # user_projects = [
  #   { id: 1, location: "Garage A", name: "Project Alpha", last_accessed: (DateTime.now - 1).strftime("%m/%d/%Y %H:%M"), description: "Building a robot" },
  #   { id: 2, location: "Garage B", name: "Project Beta", last_accessed: (DateTime.now - 2).strftime("%m/%d/%Y %H:%M"), description: "Creating a drone" },
  #   { id: 3, location: "Garage C", name: "Project Gamma", last_accessed: (DateTime.now - 3).strftime("%m/%d/%Y %H:%M"), description: "Developing a new app" },
  #   { id: 4, location: "Garage D", name: "Project Delta", last_accessed: (DateTime.now - 4).strftime("%m/%d/%Y %H:%M"), description: "Designing a new car model" },
  #   { id: 5, location: "Garage E", name: "Project Epsilon", last_accessed: (DateTime.now - 5).strftime("%m/%d/%Y %H:%M"), description: "Constructing a bridge" },
  # ]
  user_checked_out = [
    { id: 1, name: "Hammer", checked_out_date: (DateTime.now - 1).strftime("%m/%d/%Y %H:%M") },
    { id: 2, name: "Screwdriver", checked_out_date: (DateTime.now - 2).strftime("%m/%d/%Y %H:%M") },
    { id: 3, name: "Wrench", checked_out_date: (DateTime.now - 3).strftime("%m/%d/%Y %H:%M") },
    { id: 4, name: "Pliers", checked_out_date: (DateTime.now - 4).strftime("%m/%d/%Y %H:%M") },
    { id: 5, name: "Saw", checked_out_date: (DateTime.now - 5).strftime("%m/%d/%Y %H:%M") },
  ]

  erb :"engineering_garage/checkout_user", :layout => :fixed, locals: {
                                             :user => checkout_user,
                                             :checked_out => user_checked_out,
                                             :projects => user_projects,
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
  user_by_nuid = User.find_by(user_nuid: params[:nuid])
  user_by_email = User.find_by(email: params[:email])
  user = nil

  if user_by_nuid != nil && user_by_email != nil
    if user_by_nuid != user_by_email
      flash :error, "Error", "User by NUID and User by email do not match"
      redirect back
    end
  elsif user_by_nuid == nil && user_by_email == nil
    flash :error, "Error", "User not found"
    redirect back
  elsif user_by_nuid != nil
    user = user_by_nuid
  else
    user = user_by_email
  end
  session[:user_id] = user.id if user
  redirect "/checkout/new_project/create?"
end

get "/checkout/new_project/create?" do
  @breadcrumbs << { :text => "New_Project" }
  require_login
  user = User.find(session[:user_id]) if session[:user_id]
  erb :'engineering_garage/new_project', :layout => :fixed, :locals => {
                                           :user => user,
                                         }
end

post "/checkout/new_project/create?" do
  @breadcrumbs << { :text => "New_Project" }
  require_login
  project = Project.new
  params[:user] = User.find(session[:user_id]) if session[:user_id]
  project.set_data(params)
  redirect "/checkout/?"
end
