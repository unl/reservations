require 'active_record'

class ResourceApprover < ActiveRecord::Base
	belongs_to :resource
	belongs_to :user
end