require 'active_record'

class ResourceAuthorization < ActiveRecord::Base
	belongs_to :resource
end