require 'sinatra'
require 'models/user'
require 'models/service_space'
require 'models/event'
require 'rack-cas'
require 'rack/cas'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :domain => CONFIG['app']['cookie_domain'],
                           :secret => 'averymanteroldfatherbesseyhamilton',
                           :old_secret => 'averymanteroldfatherbesseyhamilton',
                           :expire_after => 30*24*60*60

use Rack::CAS, server_url: 'https://shib.unl.edu/idp/profile/cas'

Time.zone = "America/Chicago"

# this gives the user messages
def flash(type, header, message)
  session["notice"] ||= []
  session["notice"] << {
    :type => type,
    :header => header,
    :message => message
  }
end

SS_ID = ServiceSpace.where(:id => CONFIG['app']['service_space_id']).first.id

before do
    # site defaults
    @inline_body_script_content = ''
    @affiliation = 'Nebraska Innovation Campus'
    @affiliation_link = 'https://innovate.unl.edu/'
    CONFIG['app']['title'] = 'Innovation Studio Manager'
    @breadcrumbs = [
      {
        :href => 'https://www.unl.edu/',
        :text => 'Nebraska',
        :title => 'University of Nebraska&ndash;Lincoln Home'
      },
      {
        :href => 'https://innovationstudio.unl.edu/',
        :text => 'Innovation Studio'
      },
      {
        :href => '/',
        :text => CONFIG['app']['title']
      }
    ]

    if SS_ID == 8
      @inline_body_script_content = ''
      @affiliation = 'College of Engineering'
      @affiliation_link = 'https://engineering.unl.edu/'
      CONFIG['app']['title'] = 'Engineering Garage'
      @breadcrumbs = [
        {
          :href => 'https://www.unl.edu/',
          :text => 'Nebraska',
          :title => 'University of Nebraska&ndash;Lincoln Home'
        },
        {
          :href => 'https://engineering.unl.edu/',
          :text => 'College of Engineering'
        },
        {
          :href => '/',
          :text => CONFIG['app']['title']
        }
      ]
    end

    session[:init] = true

    # check if the user is currently logged in
    if session.has_key?(:user_id)
        @user = (User.includes(:permissions).find(session[:user_id]) rescue nil)
    else
        @user = nil;
    end
end

def append_script_tag(src)
    @inline_body_script_content <<  "<script type=\"text/javascript\" src=\"#{src}\"></script>\n"
end

def append_script_declaration(content)
    @inline_body_script_content <<  "<script>#{content}</script>\n"
end

def has_permission?(permission)
    !@user.nil? && @user.has_permission?(permission)
end

def check_sso
  if !session['cas'].nil? && !session['cas']['user'].nil?
    @user = User.find_by(:username => session['cas']['user'])
  else
    @user = nil
  end
end

def require_login(redirect_after_login=nil)
  if SS_ID == 8
    if session['cas'].nil? || session['cas']['user'].nil?
      halt 401
    end
  else
    if @user.nil?
      flash(:alert, 'You Must Login', 'That page requires you to be logged in. If you don\'t have an account, please sign up for <a href="/new_members/">New&nbsp;Member&nbsp;Orientation</a>.')
      if redirect_after_login.nil?
        redirect '/login/'
      else
        redirect "/login/?next_page=#{redirect_after_login}"
      end
    end
  end
end

def require_renewal(redirect_from=nil)
  if !@user.nil? 
    renewal_needed = false

    if @user.get_user_agreement_expiration_date.nil?
      renewal_needed = true
    elsif @user.get_user_agreement_expiration_date <= Date.today
      renewal_needed = true
    end

    if renewal_needed
      # Avoid a redirect loop when coming from the user_agreement view
      if !redirect_from.eql? "engineering_garage/user_agreement"
        flash(:alert, 'User Agreement Expired', 'To continue to use the Engineering Garage, please renew your User Agreement.')
        redirect '/engineering_garage/user_agreement'
      end
    end
  end
end

# TODO: Repurpose to check for orientation attendance #285
def require_active(redirect_to=nil)
  if !@user.nil? && !@user.is_active && !@user.is_super_user?
    if SS_ID == 1
      flash(:alert, 'You Must Be An Active User', 'That page requires you to be an active user. To activate your account please visit Innovation Studio.')
    elsif SS_ID == 8
      flash(:alert, 'You Must Be An Active User', 'That page requires you to be an active user. To activate your account please visit the Engineering Garage.')
    end
    if redirect_to.nil?
      redirect '/'
    else
      redirect redirect_to
    end
  end
end

def drupal_link_lookup(key)
  # Leading and Trailing Slash IMPORTANT
  nodes = {
      sop_training_doc: '/equipment/sop-training-documents/',
  }

  return nodes[key] if nodes.key?(key)
end

not_found do
  @breadcrumbs << {:text => 'Not Found'}
  erb 'That page was not found.', :layout => :fixed
end

error do
  @breadcrumbs << {:text => 'Error'}
  flash(:danger, 'Sorry! There was an error.', "We apologize. A really bad error occurred and it didn't work. We're fixing this as we speak.")
  erb 'In the meantime, you can <a href="/">go back to the homepage</a>.', :layout => :fixed
end

get '/' do
  @breadcrumbs << {:text => 'Home'}
  redirect '/login/'
end

get '/images/user/:user_id/?' do
  user = User.find_by(:id => params[:user_id], :service_space_id => SS_ID)
  if user.nil? || user.imagedata.nil?
    raise Sinatra::NotFound
  end

  return user.imagedata
end

get '/images/:event_id/?' do
  event = Event.find_by(:id => params[:event_id])
  if event.nil? || event.imagedata.nil?
    raise Sinatra::NotFound
  end

  return event.imagedata
end

Dir.glob("#{ROOT}/routes/*.rb") { |file| require file }
