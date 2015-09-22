require 'models/user'

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

get '/logout/?' do
  session.clear
  redirect '/'
end