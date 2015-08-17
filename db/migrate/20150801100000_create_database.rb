require 'active_record'

class CreateDatabase < ActiveRecord::Migration
	def change
		create_table :resources do |t|
			t.string :name
			t.integer :service_space_id
			t.integer :minutes_per_reservation
		end

		create_table :users do |t|
			t.string :username
			t.string :password_hash
			t.string :email
		end

		create_table :events do |t|
			t.string :title
			t.string :description
			t.datetime :start_time
			t.datetime :end_time
			t.integer :service_space_id
		end

		create_table :reservations do |t|
			t.integer :resource_id
			t.integer :event_id
			t.datetime :start_time
			t.datetime :end_time
		end

		create_table :resource_approvers do |t|
			t.integer :resource_id
			t.integer :user_id
		end

		create_table :service_spaces do |t|
			t.string :name
		end

		create_table :event_signups do |t|
			t.integer :event_id
			t.string :name
		end
	end
end