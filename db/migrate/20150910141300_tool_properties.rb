require 'active_record'
require 'models/resource'

class ToolProperties < ActiveRecord::Migration
	def up
		add_column :resources, :is_reservable, :boolean
		add_column :resources, :max_reservations_per_slot, :integer

		Resource.reset_column_information
		Resource.all.each do |resource|
			resource.minutes_per_reservation = 60
			resource.max_reservations_per_slot = 5
			if resource.name == '96" x 48" CNC Router'
				resource.minutes_per_reservation = 120
				resource.max_reservations_per_slot = 3
			end
			resource.is_reservable = true 
			if resource.name == '3D Filament Desktop Printer'
				resource.is_reservable = false
			end

			resource.save
		end
	end

	def down
		drop_column :resources, :is_reservable
		drop_column :resources, :max_reservations_per_slot
	end
end