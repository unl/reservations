require 'active_record'
require 'bcrypt'
require 'models/resource_authorization'
require 'models/event_signup'
require 'models/permission'
require 'models/user_has_permission'
require 'classes/emailer'

class User < ActiveRecord::Base
  has_many :resource_authorizations
  has_many :event_signups
  has_many :user_has_permissions
  has_many :permissions, through: :user_has_permissions

  def authorized_resource_ids
    self.resource_authorizations.map {|res_auth| res_auth.resource_id}
  end

  def get_authorization(resource_id)
    self.resource_authorizations.where(:resource_id => resource_id).first
  end

  def signed_up_event_ids
    self.event_signups.map {|event_signup| event_signup.event_id}
  end

  include BCrypt

  # now decides based on whether they have any admin permissions
  def is_admin?
    !self.permissions.empty?
  end
  alias_method :admin?, :is_admin?

  def is_super_user?
    self.permissions.include?(Permission.find(Permission::SUPER_USER))
  end
  alias_method :super_user?, :is_super_user?

  def has_permission?(id)
    self.permissions.include?(Permission.find(id))
  end

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def sortable_name
    "#{last_name}, #{first_name}"
  end

  def image_src
    "/images/user/#{id}/"
  end

  def set_image_data(params)
    if params[:imagedata] && !params[:imagedata].empty?
      self.imagemime = params[:imagedata][:type]
      self.imagedata = params[:imagedata][:tempfile].read if params[:imagedata][:tempfile].is_a?(Tempfile)
    end
    self.save
  end

  def remove_image_data
    self.imagemime = nil
    self.imagedata = nil
    self.save
  end

  def send_reset_password_email
    token = ''
    begin
      token = String.token
    end while User.find_by(:reset_password_token => token) != nil
    self.reset_password_token = token
    self.reset_password_expiry = Time.now + 1.day
    self.save

body = <<EMAIL
<p>We received a request to reset your Innovation Studio Manager password. Please click the link below to reset your password.</p>

<p><a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/reset_password/#{token}/">http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/reset_password/#{token}/</a></p>

<p>This link will only be active for 24 hours. If you did not request to reset your password, you may safely disregard this email.</p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, 'Nebraska Innovation Studio password reset', body)
  end
end