require 'active_record'

class ResourceField < ActiveRecord::Base
	belongs_to :resource_class
end