require 'active_record'

class AddResetPasswordColumns < ActiveRecord::Migration
  def change
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_expiry, :datetime
  end
end