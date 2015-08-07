require 'active_record'

class EventSignup < ActiveRecord::Base
	belongs_to :event
end