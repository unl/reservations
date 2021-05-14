require 'models/user'
require 'models/resource'
require 'models/permission'
require 'csv'

USER_STATII = [
    'None',
    'UNL Undergrad',
    'UNL Grad',
    'Other Student',
    'UNL Staff',
    'UNL Faculty',
    'UNL Alumni',
    'Emeritus UNL Faculty',
    'NIC Partner',
    'Community Member'
]

STUDIO_STATII = {
    'Membership Current' => 'current',
    'Membership Expired' => 'expired',
    'Membership Expired (opted out of emails)' => 'expired_no_email'
}

before '/admin/users*' do
    unless has_permission?(Permission::MANAGE_USERS) || has_permission?(Permission::SUPER_USER)
        raise Sinatra::NotFound
    end
end

get '/admin/users/download/?' do
    # load up a CSV with the data
    users = User.where(:service_space_id => SS_ID)
    csv_string = CSV.generate do |csv|
        csv << ["User ID", "Username", "Email", "First Name", "Last Name", "University Status", "Date Created", "Space Status", "Expiration Date"]
        users.each do |user|
            csv << [user.id, user.username, user.email, user.first_name, user.last_name, user.university_status, (user.date_created.strftime('%Y-%m-%d') rescue ''), user.space_status, (user.expiration_date.strftime('%Y-%m-%d') rescue '')]
        end
    end

    content_type 'application/csv'
    attachment 'users.csv'
    csv_string
end

get '/admin/users/?' do
    @breadcrumbs << {:text => 'Admin Users'}

    studio_status = params[:studio_status]
    selected_tool = params[:selected_tool]

    # get all the users that this admin has created
    users = User.includes(:resource_authorizations => :resource)
                .where(:service_space_id => SS_ID)
    unless studio_status.nil?
        users = users.where(:university_status => studio_status)
    end
    users = users.order(:last_name, :first_name).all.to_a

    unless selected_tool.nil?
        users.select! do |user|
            user.authorized_resource_ids.include?(selected_tool.to_i)
        end
    end

    # we need all the tools for the searching
    tools = Resource.where(:service_space_id => SS_ID).order(:name).all

    erb :'admin/users', :layout => :fixed, :locals => {
        :users => users,
        :tools => tools,
        :studio_status => studio_status,
        :selected_tool => selected_tool
    }
end

get '/admin/users/create/?' do
    @breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Create User'}
    erb :'admin/new_user', :layout => :fixed, :locals => {
        :user => User.new
    }
end

get '/admin/users/:user_id/edit/?' do
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:permissions).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found"
        redirect '/admin/users/'
    end

    @breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Edit User'}
    erb :'admin/edit_user', :layout => :fixed, :locals => {
        :user => user,
        :permissions => Permission.where.not(:id => Permission::SUPER_USER).all,
        :su_permission => Permission.find(Permission::SUPER_USER)
    }
end

post '/admin/users/:user_id/edit/?' do
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:permissions).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found"
        redirect '/admin/users/'
    end

    # check that username is not taken
    name_user = User.find_by(:username => params[:username])
    unless name_user.nil? || name_user == user
        flash(:alert, 'Username Taken', 'Sorry, another user has already taken that username.')
        redirect back
    end

    user.update({
        :first_name => params[:first_name],
        :last_name => params[:last_name],
        :email => params[:email],
        :username => params[:username],
        :university_status => params[:university_status],
        :space_status => params[:studio_status],
        :expiration_date => params[:expiration_date].nil? || params[:expiration_date].empty? ? nil : calculate_time(params[:expiration_date], 0, 0, 'am')
    })

    if params.checked?('remove_image')
        user.remove_image_data
    else
        user.set_image_data(params)
    end

    # check the permissions, check for new ones
    params.select {|k,v| k =~ /permission_*/}.each do |k,v|
        if params.checked?(k)
            perm_id = k.split('permission_')[1].to_i
            unless user.has_permission?(perm_id)
                user.permissions << Permission.find(perm_id)
            end
        end
    end

    # check for any removed
    user.permissions.each do |perm|
        unless params.checked?("permission_#{perm.id}")
            user.permissions.delete(perm)
        end
    end

    flash :success, 'User Updated', 'Your user has been updated.'
    redirect '/admin/users/'
end

post '/admin/users/:user_id/delete/?' do
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found."
        redirect '/admin/users/'
    end

    user.destroy

    flash :success, 'User Deleted', 'That user has been deleted.'
    redirect '/admin/users/'
end

post '/admin/users/create/?' do
    # check that username is not taken
    unless User.find_by(:username => params[:username]).nil?
        flash(:alert, 'Username Taken', 'Sorry, another user has already taken that username.')
        redirect back
    end

    # check password is at least 8 characters
    unless params[:password].length >= 8
        flash(:alert, 'Password too short', 'Sorry, your password must be at least 8 characters.')
        redirect back
    end

    # check that password matches confirmation
    unless params[:password] == params[:password2]
        flash(:alert, 'Passwords do not match', 'Sorry, your passwords do not match.')
        redirect back
    end

    params.delete('password2')
    params[:expiration_date] = params[:expiration_date].nil? || params[:expiration_date].empty? ? nil : calculate_time(params[:expiration_date], 0, 0, 'am')
    user = User.new(params)
    user.created_by_user_id = @user.id
    user.space_status = 'current'
    user.service_space_id = SS_ID
    user.save

    user.set_image_data(params)

    flash :success, 'User Created', 'Your user has been created.'
    redirect '/admin/users/'
end

get '/admin/users/:user_id/manage/?' do
    @breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Manage User Permissions'}
    # check that the admin user has permission to manage this user
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:resource_authorizations).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found."
        redirect '/admin/users/'
    end

    # Get user tool options
    tools = Resource.where(:service_space_id => SS_ID).order(:name).all.to_a
    tools.sort_by! {|tool| tool.category_name.downcase + tool.name.downcase + tool.model.downcase}

    erb :'admin/manage_authorizations', :layout => :fixed, :locals => {
        :user => user,
        :tools => tools
    }
end

post '/admin/users/:user_id/manage/?' do
    # check that the admin user has permission to manage this user
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:resource_authorizations).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found."
        redirect '/admin/users/'
    end

    # check for removed permissions
    user.authorized_resource_ids.each do |resource_id|
        unless params.has_key?("permission_#{resource_id}") && params["permission_#{resource_id}"] == 'on'
            ResourceAuthorization.find_by(:user_id => user.id, :resource_id => resource_id).delete
        end
    end

    # now add new permissions that are checked
    params.each do |key, value|
        if key.start_with?('permission_') && value == 'on'
            id = key.split('permission_')[1].to_i
            # check if the user already has permission for this tool
            unless user.authorized_resource_ids.include?(id)
                ResourceAuthorization.create(
                    :user_id => user.id,
                    :resource_id => id,
                    :authorized_date => Time.now
                )
            end
        end
    end

    flash :success, 'User Authorizations Updated', "User #{user.username}'s authorizations have been updated."
    redirect '/admin/users/'
end