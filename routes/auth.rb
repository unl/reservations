require 'models/user'
require 'scripts/email_expiring_users'

get '/me/?' do
  require_login
  @breadcrumbs << {:text => 'My Account'}

  erb :me, :layout => :fixed
end

post '/me/?' do
  require_login

  @user.email = params[:email]
  @user.first_name = params[:first_name]
  @user.last_name = params[:last_name]
  @user.save

  flash(:success, 'Account Updated', 'Your user account has been updated.')
  redirect '/me/'
end

post '/change-password/?' do
  require_login

  # check password is at least 8 characters
  unless params[:password].length >= 8
    flash(:alert, 'Password too short', 'Sorry, your password must be at least 8 characters.')
    redirect '/me/'
  end

  # check that password matches confirmation
  unless params[:password] == params[:password2]
    flash(:alert, 'Passwords do not match', 'Sorry, your passwords do not match.')
    redirect '/me/'
  end

  @user.password = params[:password]
  @user.save

  flash(:success, 'Password Changed', 'Your password has been changed.')
  redirect '/me/'
end

get '/login/?' do
    @breadcrumbs << {:text => 'Login'}
    unless @user.nil?
      redirect '/home/'
    end
    erb :login, :layout => :fixed
end

post '/login/?' do
    user = User.where(:username => params[:username]).first

    # check user existence and password correctness
    if user.nil? || user.password != params[:password]
        flash(:danger, 'Incorrect Password', 'Username/password combination is incorrect.')
        redirect '/login/'
    end

    # it is the user, hooray
    session[:user_id] = user.id
    redirect '/home/'
end

get '/forgot_password/' do
  erb :forgot_password, :layout => :fixed
end

post '/forgot_password/' do
  user = User.find_by(:username => params[:username].trim)
  unless user.nil?
    user.send_reset_password_email
  end

post '/' do 
  users = User.where(:email => 'jjacobs10@huskers.unl.edu').all

  users.each do |user|
    user.send_membership_expiring_email
  end
end

  flash :success, 'Email sent', 'An email containing instructions to reset your password has been sent.'
  redirect '/login/'
end

get '/reset_password/:token/?' do
  user = User.find_by(:reset_password_token => params[:token])
  not_found if user.nil? || user.reset_password_expiry < Time.now

  @section = nil
  erb :reset_password, :layout => :fixed, :locals => {
    :token => params[:token]
  }
end

post '/reset_password/?' do
  user = User.find_by(:reset_password_token => params[:token])
  not_found if user.nil? || user.reset_password_expiry + 5.minutes < Time.now

  # check password is at least 8 characters
  unless params[:password].length >= 8
    flash(:alert, 'Password too short', 'Sorry, your password must be at least 8 characters.')
    redirect "/reset_password/#{params[:token]}"
  end

  if (params[:password] != params[:password2])
    flash :danger, 'Password mismatch', 'Your passwords do not match.'
    redirect "/reset_password/#{params[:token]}"
  end

  user.password = params[:password]
  user.reset_password_token = nil
  user.reset_password_expiry = nil
  user.save

  flash :success, 'Password Reset', 'Your password has been reset.'
  redirect '/login/'
end

get '/logout/?' do
  session.clear
  redirect '/'
end
