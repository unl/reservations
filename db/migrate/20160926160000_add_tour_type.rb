require 'active_record'
require 'models/event_type'

class AddTourType < ActiveRecord::Migration
	def up
		EventType.create({
			description: 'Tour',
			service_space_id: 1
		})
	end
end