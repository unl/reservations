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
  session["notice"] = {
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
  flash(:danger, 'Sorry! There was an error.', "We apologize. A really bad error occurred and it didn't work. We're fixing this as we speak.")
  erb 'In the meantime, you can <a href="/">go back to the homepage</a>.', :layout => :fixed
end

get '/' do
    redirect '/login/'
end

Dir.glob("#{ROOT}/routes/*.rb") { |file| require file }