require 'active_record'

class AddEmailEventSignup < ActiveRecord::Migration
	def change
		add_column :event_signups, :email, :string
	end
end