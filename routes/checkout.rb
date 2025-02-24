require "models/project"
require "models/project_teammate"
require "models/project_log"
require "models/tool_log"
require "date"
require "erb"

before "/checkout*" do
	unless has_permission?(Permission::MANAGE_CHECKOUT)
		raise Sinatra::NotFound
	end
end

# Check out scan pages
get "/checkout/?" do
  @breadcrumbs << { :text => "Checkout" }
  require_login
  erb :'engineering_garage/checkout', :layout => :fixed, locals: {}
end

# Check out page
get "/checkout/user/?" do
  @breadcrumbs << { :text => "Checkout" }
  require_login
  nuid = params[:nuid]
	search_project_id = params[:search_project_id]
	search_tool_id = params[:search_tool_id]

  if nuid.nil? || nuid.strip.empty?
    redirect "/checkout/"
  else
    
    #If the nuid length is 8, it was manually input and should be correct
    #If not, it'll be nuid+issue code from a barcode scan
    if nuid.length != 8 
      #pre-pends with zeroes if the input is not 13 characters long 
      nuid = nuid.rjust(13, "0")
      #extracts the NUID portion from the scanned input
      nuid = nuid[0, 8]
    end

    checkout_user = User.find_by(user_nuid: nuid)
    if checkout_user.nil?
      flash :danger, "Error", "User with that NUID not found"
      redirect "/checkout/"
    else
			# Preload the project list
      projects = Project.where(owner_user_id: checkout_user.id)

      team_project_ids = ProjectTeammate.where(teammate_id: checkout_user.id).pluck(:project_id)
      team_projects = Project.where(id: team_project_ids)

      projects = projects.or(team_projects)

      if search_project_id && !search_project_id.strip.empty?
        projects = projects.where(bin_id: search_project_id.strip)
      end
    end
  end

	# select the checked in tools
	available_tools = Tool.all.select { |tool| tool.last_checked_out.nil? || tool.last_checked_in > tool.last_checked_out}
	
	# select the logs from tool logs where the user is checkout_user and the is_checking_in is false and is the most recent log for each tool id
  user_checked_out = ToolLog.where(checkout_user_id: checkout_user.id, is_checking_in: false)
	
	if user_checked_out.nil?
		user_checked_out = []
	end
	
	tools_checked_out = Tool.where(id: user_checked_out.pluck(:tool_id))
	tools_checked_out = tools_checked_out.select { |tool| tool.last_checked_out > tool.last_checked_in }
	if search_tool_id && !search_tool_id.strip.empty?
		available_tools = available_tools.select { |tool| tool.serial_number == search_tool_id }
		tools_checked_out = tools_checked_out.select { |tool| tool.serial_number == search_tool_id }
	end

  user_event_signups = EventSignup.where(user_id: checkout_user.id, attended: 0)

  user_events =  Event.where(id: user_event_signups.select(:event_id))

  erb :"engineering_garage/checkout_user", :layout => :fixed, locals: {
                                             :user => checkout_user,
																						 :nuid => nuid,
                                             :checked_out => tools_checked_out,
                                             :projects => projects,
																						 :tools => available_tools,
                                             :events => user_events,
                                           }
end

post '/checkout/events/:event_id/:user_id/' do
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id
  tool_training_event_id = EventType.find_by(:description => 'Machine Training', :service_space_id => SS_ID).id
	event = Event.find_by(:id => params[:event_id])
	tool = EventAuthorization.find_by(:event_id => params[:event_id])
  user = User.find_by(:id => params[:user_id])

	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end

  signup_record = EventSignup.find_by(:event_id => event.id, :user_id => user.id)

  unless signup_record == nil
    if signup_record.attended == 0
      signup_record.attended = 1
      signup_record.save
    end
  end

  if !user.nil?
    if event.event_type_id == new_member_orientation_id
      unless AttendedOrientation.exists?(user_id: user.id)
        AttendedOrientation.create(
          :user_id => user.id,
          :name => user.full_name,
          :date_attended => event.end_time,
          :university_status => user.university_status,
          :user_email => user.email,
          :event_id => event.id
        )
        user.send_attended_orientation_email
      end
    end

    if !tool.nil?
      unless user.authorized_resource_ids.include?(tool.resource_id)
        ResourceAuthorization.create(
          :user_id => user.id,
          :resource_id => tool.resource_id,
          :authorized_date => Time.now,
          :authorized_event => signup_record.event_id
        )
      end
    end
  end

	flash :success, 'Event attendence confirmed', "#{user.username}'s attendence confirmed for #{event.title}."
	redirect '/checkout/'
end

# Check Out Project 
post "/checkout/project_checkout/?" do
	bin_id = params[:bin_id]
	nuid = params[:nuid]

	if bin_id != nil && nuid != nil
		project = Project.find_by(bin_id: bin_id)
		user = User.find_by(user_nuid: nuid)
		if project != nil && user != nil
			project.update_last_checked_out
			project_log = ProjectLog.new
			project_log.set_data(user: user, project: project, is_checking_in: false)
			flash :success, 'Success', 'Project checked out'
			redirect "/checkout/?"
		else
			flash :error, 'Error', 'Project not found'
			redirect "/checkout/"
		end
	else
		flash :error, 'Error', 'Bin ID not found'
		redirect "/checkout/"
	end
end

# Check In Project
post "/checkout/project_checkin/?" do
	bin_id = params[:bin_id]
	nuid = params[:nuid]

	if bin_id != nil && nuid != nil
		project = Project.find_by(bin_id: bin_id)
		user = User.find_by(user_nuid: nuid)
		if project != nil
			project.update_last_checked_in
			project_log = ProjectLog.new
			project_log.set_data(user: user, project: project, is_checking_in: true)
			flash :success, 'Success', 'Project checked in'
			redirect "/checkout/?"
		else
			flash :error, 'Error', 'Project not found'
			redirect "/checkout/"
		end
	else
		flash :error, 'Error', 'Bin ID not found'
		redirect "/checkout/"
	end
end

# Delete Project
post "/checkout/project_delete/?" do
	bin_id = params[:bin_id]

	if bin_id != nil
		project = Project.find_by(bin_id: bin_id)
		if project != nil
			project.delete
			flash :success, 'Success', 'Project deleted'
			redirect "/checkout/?"
		else
			flash :error, 'Error', 'Project not found'
			redirect "/checkout/"
		end
	else
		flash :error, 'Error', 'Bin ID not found'
		redirect "/checkout/"
	end
end

# Create Project Page
get "/checkout/project/:nuid/create" do
  @breadcrumbs << { :text => "New Project" }
  require_login
  user = User.find_by(user_nuid: params[:nuid])
  erb :'engineering_garage/new_project', :layout => :fixed, :locals => {
                                           :user => user,
                                         }
end

# Create Project
post "/checkout/project/:nuid/create" do
  @breadcrumbs << { :text => "New Project" }
  require_login

  if  params[:title].blank?
		flash :error, 'Error', 'Please enter a title'
		redirect back
	end 

  if  params[:bin_id].blank?
		flash :error, 'Error', 'Please enter a bin code'
		redirect back
	end 

  if Project.find_by(bin_id: params[:bin_id]) != nil
    flash :error, 'Error', "A project with that Bin ID already exists. If you believe this to be an error, please contact an administrator."
		redirect back
  end

  params[:user] = User.find_by(user_nuid: params[:nuid])
  project = Project.new
  project.set_data(params)
  project.update_last_checked_in

  teammates = ProjectTeammate.new
  params[:project_id] = project.id
  params[:teammate_id] = User.find_by(user_nuid: params[:nuid]).id
  params[:user] = @user
  params[:is_owner] = 1
  teammates.set_data(params)

  flash :success, 'Success', 'Project created'
  redirect "/checkout"
end

# Project Edit Page
get "/checkout/project/:project_id/edit" do
  @breadcrumbs << { :text => "Edit Project" }
  require_login
  project = Project.find_by(id: params[:project_id])
  user = User.find_by(id: project.owner_user_id)
  teammates = ProjectTeammate.where("project_id = ?", params[:project_id])
  params[:previous_nuid] = user.user_nuid

  erb :'engineering_garage/edit_project', :layout => :fixed, :locals => {
                                           :user => user,
                                           :title => project.title,
                                           :description => project.description,
                                           :bin_id => project.bin_id,
                                           :teammates => teammates,
                                           :project_id => project.id,
                                         }
end

# Edit Project
post "/checkout/project/:project_id/edit" do
  @breadcrumbs << { :text => "Edit Project" }
  require_login
  project = Project.find_by(id: params[:project_id])
  params[:user] = User.find_by(user_nuid: params[:nuid])

  if  params[:title].blank?
		flash :error, 'Error', 'Please enter a title'
		redirect back
	end 

  if  params[:bin_id].blank?
		flash :error, 'Error', 'Please enter a bin code'
		redirect back
	end

  if  params[:user].nil?
		flash :error, 'Error', 'User with provided NUID not found'
		redirect back
	end 

  project_by_bin = Project.find_by(bin_id: params[:bin_id])
  if project_by_bin != nil
    if project_by_bin.id != project.id
      flash :error, 'Error', "A project with that Bin ID already exists. If you believe this to be an error, please contact an administrator."
      redirect back
    end
  end

  if project.owner_user_id != params[:user].id
    user_team_profile = ProjectTeammate.find_by(project_id: project.id, teammate_id: params[:user].id)
    if user_team_profile == nil
      user_team_profile = ProjectTeammate.new
      params[:teammate_id] = params[:user].id
      params[:is_owner] = 0
      user_team_profile.set_data(params)
    end
    user_team_profile.set_owner
  end

  project.set_data(params)

  flash :success, 'Success', 'Project updated'
  redirect "/checkout"
end

# Delete Project
post "/checkout/project/:project_id/edit/delete/" do
  project = Project.find_by(id: params[:project_id])

  if project != nil
    project.delete
    flash :success, 'Success', 'Project deleted'
    redirect "/checkout/?"
  else
    flash :error, 'Error', 'Project not found'
    redirect "/checkout/"
  end
end

# add teammate
post "/checkout/project/:project_id/edit/teammates/" do
  nuid = params[:nuid]
  if nuid.nil? || nuid.strip.empty?
    flash :danger, "Error", "NUID empty."
    redirect back
  end

  teammate_user = User.find_by(user_nuid: nuid)
  if teammate_user.nil?
    flash :danger, "Error", "User with that NUID not found."
    redirect back
  end

  # Check if user is already a teammate
  existing_teammate = ProjectTeammate.find_by(teammate_id: teammate_user.id, project_id: params[:project_id])
  unless existing_teammate.nil?
    flash :danger, "Error", "User already listed as a teammate."
    redirect back
  end

  teammate = ProjectTeammate.new
  params[:teammate_id] = teammate_user.id
  params[:user] = @user
  params[:is_owner] = 0
  teammate.set_data(params)

  flash :success, "Teammate Added", "#{teammate_user.full_name} was added as a teammate."
  redirect back
end

# Remove teammate
post "/checkout/project/:project_id/edit/teammates/:teammate_id/remove" do
  teammate_user = ProjectTeammate.find_by(id: params[:teammate_id])
  if teammate_user.nil?
    flash :danger, "Error", "Could not locate user."
    redirect back
  end

  # Prevent project owner deletion
  if teammate_user.is_owner
    flash :danger, "Error", "Cannot remove project owner."
    redirect back
  end

  teammate_user.delete
  flash :success, "Teammate Removed", "User was removed from teammates."
  redirect back
end

# Tool Checkout
post "/checkout/tool_checkout/?" do
  nuid = params[:nuid]
	tool_id = params[:tool_id]
	if nuid.nil? || tool_id.nil?
		flash :danger, "Error", "NUID or Tool ID not found"
		redirect "/checkout/"
	end

	tool = Tool.find_by(id: tool_id)
	user = User.find_by(user_nuid: nuid)
	if tool.nil?
		flash :danger, "Error", "Tool not found"
		redirect "/checkout/"
	elsif user.nil?
		flash :danger, "Error", "User not found"
		redirect "/checkout/"
	end

	previous_log = ToolLog.where(tool_id: tool.id, checkout_user_id: user.id, is_checking_in: false).order(checked_date: :desc).first
	if previous_log.nil?
		flash :danger, "Training", "This user has not checked out this tool before! Please give them a walkthrough."
	end

	tool.update_last_checked_out
	tool_log = ToolLog.new
	tool_log.set_data(user: user, tool: tool, is_checking_in: false)

	flash :success, "Success", "Tool checked out"
	redirect "/checkout/"
end

# Tool Checkin
post "/checkout/tool_checkin/?" do
	nuid = params[:nuid]
	tool_id = params[:tool_id]
	if nuid.nil? || tool_id.nil?
		flash :danger, "Error", "NUID or Tool ID not found"
		redirect "/checkout/"
	end

	tool = Tool.find_by(id: tool_id)
	user = User.find_by(user_nuid: nuid)
	if tool.nil?
		flash :danger, "Error", "Tool not found"
		redirect "/checkout/"
	elsif user.nil?
		flash :danger, "Error", "User not found"
		redirect "/checkout/"
	end

	tool.update_last_checked_in
	tool_log = ToolLog.new
	tool_log.set_data(user: user, tool: tool, is_checking_in: true)
	flash :success, "Success", "Tool checked in"
	
	redirect "/checkout/"
end