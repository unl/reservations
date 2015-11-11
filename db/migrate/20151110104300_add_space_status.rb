require 'active_record'
require 'models/user'

class AddSpaceStatus < ActiveRecord::Migration
  def up
    add_column :users, :space_status, :string

    User.reset_column_information
    User.all.each do |user|
    	user.space_status = 'current'
    	user.save
    end
  end

  def down
  	drop_column :users, :space_status, :string
  end
end