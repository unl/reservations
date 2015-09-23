require 'models/user'
require 'models/resource'

get '/admin/users/?' do
	@breadcrumbs << {:text => 'Admin Users'}

	users = User.includes(:resource_authorizations).where(:created_by_user_id => @user.id).all.to_a
	unless users.map{|user| user.id}.include?(@user.id)
		users = users + [@user]
	end

	erb :'admin/users', :layout => :fixed, :locals => {
		:users => users
	}
end

get '/admin/users/create/?' do
	@breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Create User'}
	erb :'admin/new_user', :layout => :fixed, :locals => {
		:user => User.new
	}
end

get '/admin/users/:user_id/edit/?' do
	user = User.where(:id => params[:user_id], :created_by_user_id => @user.id).first
	if user.nil?
		flash :alert, "Not Found", "Sorry, that user was not found"
		redirect '/admin/users/'
	end

	@breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Edit User'}
	erb :'admin/edit_user', :layout => :fixed, :locals => {
		:user => user
	}
end

post '/admin/users/:user_id/edit/?' do
	user = User.where(:id => params[:user_id], :created_by_user_id => @user.id).first
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
		:university_status => params[:university_status]
	})

	flash :success, 'User Updated', 'Your user has been updated.'
	redirect '/admin/users/'
end

post '/admin/users/:user_id/delete/' do
	user = User.where(:id => params[:user_id], :created_by_user_id => @user.id).first
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
	user = User.new(params)
	user.created_by_user_id = @user.id
	user.save

	flash :success, 'User Created', 'Your user has been created.'
	redirect '/admin/users/'
end

get '/admin/users/:user_id/manage/?' do
	@breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Manage User Permissions'}
	# check that the admin user has permission to manage this user

	user = User.includes(:resource_authorizations).find(params[:user_id])
	tools = Resource.where(:service_space_id => SS_ID).order(:name).all

	erb :'admin/manage_authorizations', :layout => :fixed, :locals => {
		:user => user,
		:tools => tools
	}
end

post '/admin/users/:user_id/manage/?' do
	# check that the admin user has permission to manage this user

	user = User.includes(:resource_authorizations).find(params[:user_id])

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
					:resource_id => id
				)
			end
		end
	end

	redirect '/admin/users/'
end