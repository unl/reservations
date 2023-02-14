require 'active_record'
require 'bcrypt'

class Vehicle < ActiveRecord::Base
    belongs_to :vehicles
end