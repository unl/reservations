require 'active_record'
require 'models/service_space'
require 'models/event_type'

class InnovationStudioSs < ActiveRecord::Migration
	def up
		ss = ServiceSpace.create(
			:name => 'Innovation Studio'
		)

		EventType.create(
			:description => 'New Member Orientation',
			:service_space_id => ss.id
		)

		EventType.create(
			:description => 'Machine Training',
			:service_space_id => ss.id
		)

		EventType.create(
			:description => 'Advanced Skill-Based Workshop',
			:service_space_id => ss.id
		)

		EventType.create(
			:description => 'Creation Workshop',
			:service_space_id => ss.id
		)

		EventType.create(
			:description => 'General Workshop',
			:service_space_id => ss.id
		)
	end

	def down
		ss = ServiceSpace.where(:name => 'Innovation Studio').first
		EventType.where(:service_space_id => ss.id).delete_all
		ss.delete
	end
end