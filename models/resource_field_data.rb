require 'active_record'
require './models/resource'
require './models/resource_field'

class ResourceFieldData < ActiveRecord::Base
	belongs_to :resource
	belongs_to :resource_field
end