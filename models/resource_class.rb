require 'active_record'

class ResourceClass < ActiveRecord::Base
	has_many :resource_fields
end