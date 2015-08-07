require 'active_record'

class Event < ActiveRecord::Base
	has_many :event_signups
	alias_method :signups, :event_signups
end