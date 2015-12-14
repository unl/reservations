require 'active_record'
require 'models/user'

class AddServiceSpaceToUsers < ActiveRecord::Migration
	def up
		add_column :users, :service_space_id, :integer

		User.reset_column_information
		User.all.each do |user|
			user.service_space_id = 1
			user.save
		end
	end

	def down
		drop_column :users, :service_space_id
	end
end