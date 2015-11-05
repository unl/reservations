require 'active_record'

class MaxSignups < ActiveRecord::Migration
	def change
		add_column :events, :max_signups, :integer
	end
end