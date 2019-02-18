require 'active_record'

class UserHasPermission < ActiveRecord::Base
	belongs_to :user
 	belongs_to :permission
end