require 'sinatra'
require 'models/user'

enable :sessions

# this gives the user messages
def flash(type, message)
  session[:notice][type] ||= []
  session[:notice][type] << message
end

before do
    # site defaults
    @title = 'Innovation Studio Manager'

    session[:init] = true
    session[:notice] ||= {}

    # check if the user is currently logged in
    if session.has_key?(:user_id)
        @user ||= (User.find(session[:user_id]) rescue nil)
    else
        @user = nil;
    end
end

get '/' do
    erb :home, :layout => :fixed
end

get '/login/?' do
    erb :login, :layout => :fixed
end

post '/login/?' do
    user = User.where(:username => params[:username]).first

    # check user existence and password correctness
    if user.nil? || user.password != params[:password]
        flash(:danger, 'Username/password combination is incorrect.')
        redirect '/'
    end

    # it is the user, hooray
    session[:user_id] = user.id
    redirect '/home/'
end