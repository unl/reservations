require 'active_record'
require 'models/location'

class AddUnlEventsDetails < ActiveRecord::Migration
	def change
		add_column :events, :unl_events_id, :integer
		add_column :locations, :unl_events_id, :integer

		Location.reset_column_information
		nis = Location.find_by(name: 'Nebraska Innovation Studio')
		nis.unl_events_id = 11632
		nis.save
	end
end