require 'models/user'
require 'models/resource'
require 'models/permission'
require 'csv'
require 'date'

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

EXPIRATION_DATE_SEARCH_OPERATIONS = [
    '<',
    '&le;',
    '>',
    '&ge;',
    '='
]

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

    first_name = params[:first_name]
    last_name = params[:last_name]
    email = params[:email]
    studio_status = params[:studio_status]
    tool_authorization = params[:tool_authorization]
    expiration_date = params[:expiration_date]
    expiration_date_operation = params[:expiration_date_operation]
    page = params[:page]
    users_per_page = params[:users_per_page]

    # get all the users that this admin has created
    users = User.includes(:resource_authorizations => :resource)
                .where(:service_space_id => SS_ID)
    
    unless first_name.nil? || first_name.length == 0
        users = users.where("first_name LIKE ?", "%#{first_name}%")
    end

    unless last_name.nil? || last_name.length == 0
        users = users.where("last_name LIKE ?", "%#{last_name}%")
    end

    unless email.nil? || email.length == 0
        users = users.where("email LIKE ?", "%#{email}%")
    end

    unless studio_status.nil? || studio_status.length == 0
        users = users.where(:university_status => studio_status)
    end

    unless expiration_date.nil? || expiration_date.length == 0 || expiration_date_operation.nil? || expiration_date_operation.to_i < 1
        # need to convert the date string so it is in a format the database can easily understand
        converted_date = Date.strptime(expiration_date, "%m/%d/%Y").strftime("%Y-%m-%d")
        case expiration_date_operation.to_i
        when 1
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') < ?", converted_date)
        when 2
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') <= ?", converted_date)
        when 3
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') > ?", converted_date)
        when 4
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') >= ?", converted_date)
        else
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') = ?", converted_date)
        end
    end

    users = users.order(:last_name, :first_name).all.to_a

    # filtering the search results by tool authorization after ordering the names because it complicates the logic to do the ordering last
    unless tool_authorization.nil? || tool_authorization.length == 0
        users = users.select { |user| user.authorized_resource_ids.include?(tool_authorization.to_i) }
    end

    # page length is variable but defaults to 10
    users_per_page = users_per_page.to_i
    if users_per_page.nil? || users_per_page == 0
        users_per_page = 10
    end

    # only grab the specified page of users that we want for pagination
    page = page.to_i
    start_of_page = (page - 1) * users_per_page
    user_count = users.count

    # can't call drop on users if start_of_page is 0 otherwise an error is thrown
    if start_of_page > 1
        users = users.drop(start_of_page)
    end

    # make sure if we don't have a full last page we don't miss users
    max_page = (user_count / users_per_page).round()
    if max_page * users_per_page < user_count
        max_page = max_page + 1
    end

    # only display the number of users we want to show on a page
    users = users.first(users_per_page)
    if page == 0
        page = 1
    end

    # figure out which pages the pagination should start and end on
    pagination_start = page - 2
    pagination_end = page + 2
    # this logic is here to make sure that we always show 5 pages if we can
    if page - 2 < 1
        pagination_end = pagination_end + (3 - page)
    elsif page + 2 > max_page
        pagination_start = pagination_start - (page + 2 - max_page)
    end
    pagination_start = pagination_start < 1 ? 1 : pagination_start
    pagination_end = pagination_end > max_page ? max_page : pagination_end

    # we need all the tools for the searching
    tools = Resource.where(:service_space_id => SS_ID).order(:name).all

    erb :'admin/users', :layout => :fixed, :locals => {
        :users => users,
        :tools => tools,
        :first_name => first_name,
        :last_name => last_name,
        :email => email,
        :studio_status => studio_status,
        :tool_authorization => tool_authorization,
        :expiration_date => expiration_date,
        :expiration_date_operation => expiration_date_operation,
        :page => page,
        :max_page => max_page,
        :pagination_start => pagination_start,
        :pagination_end => pagination_end,
        :users_per_page => users_per_page
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