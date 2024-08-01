require 'active_record'
require 'bcrypt'
require 'models/resource_authorization'
require 'models/event_signup'
require 'models/permission'
require 'models/resource'
require 'models/vehicle'
require 'models/user_has_permission'
require 'classes/emailer'

class User < ActiveRecord::Base
  has_many :resource_authorizations, dependent: :destroy
  has_many :event_signups, dependent: :destroy
  has_many :user_has_permissions, dependent: :destroy
  has_many :permissions, through: :user_has_permissions
  has_many :alert_signups, dependent: :destroy
  
  def authorized_resource_ids
    self.resource_authorizations.map {|res_auth| res_auth.resource_id}
  end

  def meets_resource_reservation_limit?(resource_id)
    # no limit for super user
    return true if self.is_super_user?

    # get resource to lookup limit
    resource = Resource.find(resource_id)

    # at limit if invalid resource
    return false if resource.nil?

    # no limit if limit is nil
    return true if resource.user_reservation_limit.nil?

    # check if user over reservation limit for resource and return boolean
    Reservation.joins(:resource).includes(:event).
        where(:resources => {:id => resource_id}).
        where(:user_id => id).
        where('end_time >= ?', Time.now).count < resource.user_reservation_limit.to_i
  end

  def get_authorization(resource_id)
    self.resource_authorizations.where(:resource_id => resource_id).first
  end

  def signed_up_event_ids
    self.event_signups.map {|event_signup| event_signup.event_id}
  end

  def is_current?
    !self.get_expiration_date.nil? && self.get_expiration_date >= Date.today
  end

  include BCrypt

  # now decides based on whether they have any admin permissions
  def is_admin?
    !self.permissions.empty?
  end
  alias_method :admin?, :is_admin?

  def is_real_super_user?
    self.permissions.include?(Permission.find(Permission::SUPER_USER))
  end
  alias_method :real_super_user?, :is_real_super_user?

  def is_super_user?
    self.permissions.include?(Permission.find(Permission::SUPER_USER)) || self.permissions.include?(Permission.find(Permission::SUB_SUPER_USER))
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

  def get_expiration_date
    expiration_date
  end

  def set_expiration_date(exp)
    if !exp.nil?
      if self.get_expiration_date.nil? && exp >= Date.today
        self.send_vehicle_information_update
        self.send_activation_email
      end
      if !self.get_expiration_date.nil? && self.get_expiration_date < Date.today && exp >= Date.today
        self.send_vehicle_information_update
      end
    end
    self.expiration_date = exp
    self.save
  end

  def date_of_birth
    date_of_birth
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def get_username
    username
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

  def make_trainer_status
    self.is_trainer = 1
    self.save
  end

  def remove_trainer_status
    self.is_trainer = 0
    self.save
  end

  def send_membership_expiring_email
    if self.email && !self.email.empty?
      @user = self

      template_path = "#{ROOT}/views/innovationstudio/email_templates/expiring_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/expiring_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      Emailer.mail(self.email, "#{CONFIG['app']['title']} Membership Expiring", body)
    end
  end

  def send_reset_password_email
    token = ''
    begin
      token = String.token
    end while User.find_by(:reset_password_token => token, :service_space_id => SS_ID) != nil

    self.reset_password_token = token
    self.reset_password_expiry = Time.now + 1.day
    self.save

    @token = token

    if self.email && !self.email.empty?
      template_path = "#{ROOT}/views/innovationstudio/email_templates/password_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/password_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      Emailer.mail(self.email, "#{CONFIG['app']['title']} Password Reset", body)
    end
  end

  def notify_trainer_of_new_event(event)
    if self.email && !self.email.empty?
      @user = self
      @event = event

      template_path = "#{ROOT}/views/innovationstudio/email_templates/new_event_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/new_event_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      Emailer.mail(self.email, "#{CONFIG['app']['title']} - Assigned as Trainer for #{event.title}", body)
    end
  end

  def notify_trainer_of_modified_event(event)
    if self.email && !self.email.empty?
      @user = self
      @event = event

      template_path = "#{ROOT}/views/innovationstudio/email_templates/modified_event_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/modified_event_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      Emailer.mail(self.email, "#{CONFIG['app']['title']} - Event Modified: #{event.title}", body)
    end
  end

  def notify_trainer_of_removal_from_event(event)
    if self.email && !self.email.empty?
      @user = self
      @event = event

      template_path = "#{ROOT}/views/innovationstudio/email_templates/removed_event_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/removed_event_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      Emailer.mail(self.email, "#{CONFIG['app']['title']} - Event Modified: #{event.title}", body)
    end
  end

  def notify_trainer_of_deleted_event(event)
    if self.email && !self.email.empty?
      @user = self
      @event = event

      template_path = "#{ROOT}/views/innovationstudio/email_templates/deleted_event_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/deleted_event_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      Emailer.mail(self.email, "#{CONFIG['app']['title']} - Event Deleted: #{event.title}", body)
    end
  end

  def send_trainer_confirmation_reminder
    if self.email && !self.email.empty?
      @user = self

      template_path = "#{ROOT}/views/innovationstudio/email_templates/confirmation_reminder_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/confirmation_reminder_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      Emailer.mail(self.email, "#{CONFIG['app']['title']} - Unconfirmed Training", body)
    end
  end

  def send_vehicle_information_update
    if self.email && !self.email.empty?
      vehicles = Vehicle.where(:user_id => self.id).all
      if vehicles.count > 0
        @summary = ""
        @user = self
        vehicles.each do |vehicle|
          @summary = @summary + "<p>License Plate: #{vehicle.license_plate}, State: #{vehicle.state}, Make: #{vehicle.make}, Model: #{vehicle.model}</p>"
        end

        template_path = "#{ROOT}/views/innovationstudio/email_templates/vehicle_info_email.erb"
        if SS_ID == 8
          template_path = "#{ROOT}/views/engineering_garage/email_templates/vehicle_info_email.erb"
        end
        template = File.read(template_path)
        body = ERB.new(template).result(binding)

        Emailer.mail(self.email, "#{CONFIG['app']['title']} - Vehicle Information Update", body, CONFIG['app']['email_from'])
      end
    end
  end

  def send_vehicle_information_deleted
    if self.email && !self.email.empty?
      vehicles = Vehicle.where(:user_id => self.id).all
      @summary = "<p>You no longer have any vehicles associated with your account.</p>"
      @user = self
      if vehicles.count > 0
        @summary = ""
        vehicles.each do |vehicle|
          @summary = @summary + "<p>License Plate: #{vehicle.license_plate}, State: #{vehicle.state}, Make: #{vehicle.make}, Model: #{vehicle.model}</p>"
        end
      end

      template_path = "#{ROOT}/views/innovationstudio/email_templates/vehicle_info_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/vehicle_info_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)
      
      Emailer.mail(self.email, "#{CONFIG['app']['title']} - Vehicle Information Update", body, CONFIG['app']['email_from'])
    end
  end

  def send_activation_email
    if self.email && !self.email.empty?
      @user = self
      template_path = "#{ROOT}/views/innovationstudio/email_templates/activation_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/activation_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      attachments = {}
      if SS_ID == 1
        attachments = {
          "new-member-orientation-parking-map.pdf" => File.read(File.expand_path("../public/pdf/new-member-orientation-parking-map.pdf", File.dirname(__FILE__)))
        }
      end

      Emailer.mail(self.email, "#{CONFIG['app']['title']} - Getting Started", body, '', attachments)
    end
  end

  def notify_user_of_broken_equipment(reservation)
    if self.email && !self.email.empty?
      @reservation = reservation
      @resource = Resource.find(reservation.resource_id)
      @user = self
      template_path = "#{ROOT}/views/innovationstudio/email_templates/broken_equipment_email.erb"
      if SS_ID == 8
        template_path = "#{ROOT}/views/engineering_garage/email_templates/broken_equipment_email.erb"
      end
      template = File.read(template_path)
      body = ERB.new(template).result(binding)

      Emailer.mail(self.email, "#{CONFIG['app']['title']} - Reservation Canceled for #{@reservation.start_time.strftime('%m-%d-%Y')}", body)
    end
  end

end