require 'active_record'
require 'models/service_space'
require 'models/event_type'

class AddMoreEventTypes < ActiveRecord::Migration
	def up
		ss = ServiceSpace.find_by(
			:name => 'Innovation Studio'
		)

		EventType.create(
			:description => 'Free Event',
			:service_space_id => ss.id
		)

		EventType.create(
			:description => 'RSVP Only Event',
			:service_space_id => ss.id
		)
	end

	def down
		ss = ServiceSpace.find_by(
			:name => 'Innovation Studio'
		)

		EventType.where(:service_space_id => ss.id, :description => 'Free Event').delete
		EventType.where(:service_space_id => ss.id, :description => 'RSVP Only Event').delete
	end
end