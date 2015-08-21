require 'active_record'
require 'bcrypt'
require 'models/resource_authorization'
require 'models/event_signup'

class User < ActiveRecord::Base
    has_many :resource_authorizations
    has_many :event_signups
    def authorized_resource_ids
        self.resource_authorizations.map {|res_auth| res_auth.resource_id}
    end

    def signed_up_event_ids
        self.event_signups.map {|event_signup| event_signup.event_id}
    end

    include BCrypt

    def is_admin?
    	is_admin == TRUE
    end
    alias_method :admin?, :is_admin?

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
end