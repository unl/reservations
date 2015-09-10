require 'active_record'

class AddHours < ActiveRecord::Migration
	def change
		create_table :space_hours do |t|
			t.integer :service_space_id
			t.integer :day_of_week # 0 = Sunday, 6 = Saturday
			t.datetime :effective_date # date to begin using these hours
			t.boolean :one_off # is this all of this day moving forward or a special day
			t.string :hours # encoded string describing the hours 
		end
	end
end