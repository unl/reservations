require 'active_record'

class AddResourceAuthorizationAuthorizedDate < ActiveRecord::Migration
	def change
		add_column :resource_authorizations, :authorized_date, :datetime
	end
end