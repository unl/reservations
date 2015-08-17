require 'active_record'

class Event < ActiveRecord::Base
	has_many :event_signups
	belongs_to :location
	belongs_to :event_type
	alias_method :type, :event_type
	alias_method :signups, :event_signups
end