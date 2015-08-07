require 'active_record'

class Reservation < ActiveRecord::Base
	belongs_to :resource
end