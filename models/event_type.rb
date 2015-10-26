require 'active_record'

class EventType < ActiveRecord::Base
	def name
		description
	end
end