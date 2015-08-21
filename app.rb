require 'sinatra'
require 'models/user'
require 'models/service_space'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :domain => (ENV['RACK_ENV'] == 'development' ? nil : '.unl.edu'),
                           :secret => 'averymanteroldfatherbesseyhamilton',
                           :old_secret => 'averymanteroldfatherbesseyhamilton'

Time.zone = "America/Chicago"

# this gives the user messages
def flash(type, header, message)
  session[:notice] = {
    :type => type,
    :header => header,
    :message => message
  }
end

SS_ID = ServiceSpace.where(:name => 'Innovation Studio').first.id

before do
    # site defaults
    @title = 'Innovation Studio Manager'

    session[:init] = true

    # check if the user is currently logged in
    if session.has_key?(:user_id)
        @user = (User.find(session[:user_id]) rescue nil)
    else
        @user = nil;
    end
end

def require_login
  if @user.nil?
    flash(:alert, 'You Must Login', 'That page requires you to be logged in. If you don\'t have an account, please sign up for <a href="/new_members/">New&nbsp;Member&nbsp;Orientation</a>.')
    redirect '/login/'
  end
end

not_found do
  erb 'That page was not found.', :layout => :fixed
end

error do

end

get '/' do
    redirect '/login/'
end

get '/me/?' do
  require_login

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

  # check password matches password 2

  @user.password = params[:password]
  @user.save

  flash(:success, 'Password Changed', 'Your password has been changed.')
  redirect '/me/'
end

get '/login/?' do
    unless @user.nil?
      redirect '/me/'
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
    redirect '/me/'
end

get '/logout/?' do
  session.clear
  redirect '/'
end

Dir.glob("#{ROOT}/routes/*.rb") { |file| require file }