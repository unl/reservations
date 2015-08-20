require 'models/user'
require 'models/resource'

get '/admin/users/?' do
	erb :'admin/users', :layout => :fixed, :locals => {
		:users => User.includes(:resource_authorizations).where(:created_by_user_id => @user.id).all
	}
end

get '/admin/users/create/?' do
	erb :'admin/new_user', :layout => :fixed
end

post '/admin/users/create/?' do
	# check that username is not taken

	# check password is at least 8 characters

	# check that password matches confirmation

	params.delete('password2')
	user = User.new(params)
	user.created_by_user_id = @user.id
	user.save

	redirect '/admin/users/'
end

get '/admin/users/:user_id/manage/?' do
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