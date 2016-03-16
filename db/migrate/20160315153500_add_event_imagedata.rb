require 'active_record'

class AddEventImagedata < ActiveRecord::Migration
	def change
		add_column :events, :imagedata, :longblob, :default => nil
		add_column :events, :imagemime, :string, :default => nil
	end
end