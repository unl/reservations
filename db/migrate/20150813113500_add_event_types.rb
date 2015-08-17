require 'active_record'

class AddEventTypes < ActiveRecord::Migration
	def change
		add_column :events, :event_type_id, :integer

		create_table :event_types do |t|
			t.string :description
			t.integer :service_space_id
		end
	end
end