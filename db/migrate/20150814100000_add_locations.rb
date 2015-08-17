require 'active_record'
require 'models/location'
require 'models/service_space'

class AddLocations < ActiveRecord::Migration
	def up
		create_table :locations do |t|
			t.string :name
			t.string :streetaddress
			t.string :streetaddress2
			t.string :city
			t.string :state
			t.string :zip
			t.string :additionalinfo

			t.integer :service_space_id
		end

		Location.reset_column_information

		ss = ServiceSpace.where(:name => "Innovation Studio").first
		Location.create(
			:name => 'Nebraska Innovation Studio',
			:streetaddress => "2021 Transformation Drive",
			:streetaddress2 => 'Suite 2220',
			:city => 'Lincoln',
			:state => 'NE',
			:zip => '68588-6200',
			:additionalinfo => nil,
			:service_space_id => ss.id
		)

		add_column :events, :location_id, :integer
	end

	def down
		remove_column :events, :location_id
		drop_table :locations
	end
end