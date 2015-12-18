require 'active_record'
require 'models/user'
require 'models/permission'

class AddPermissions < ActiveRecord::Migration
	def up
		create_table :permissions do |t|
			t.string :name
		end

		create_table :user_has_permissions do |t|
			t.integer :user_id
			t.integer :permission_id
		end

		Permission.reset_column_information
		User.reset_column_information
		
		# add the permissions to the DB
		Permission.create(:name => 'Super User')
		Permission.create(:name => 'Manage Users')
		Permission.create(:name => 'Manage Resources')
		Permission.create(:name => 'Manage Emails')
		Permission.create(:name => 'Manage Space Hours')
		Permission.create(:name => 'Manage Events')
		Permission.create(:name => 'See Agenda')

		# give all permissions including super user to tyler & lowad
		permissions = Permission.all

		tyler = User.find_by(:username => 'tyler')
		lowad2 = User.find_by(:username => 'lowad2')
		permissions.each do |perm| 
			tyler.permissions << perm
			lowad2.permissions << perm
		end
	end

	def down
		drop_table :permissions
		drop_table :user_has_permissions
	end
end