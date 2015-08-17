require 'active_record'
require 'bcrypt'

class User < ActiveRecord::Base
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
end