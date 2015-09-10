require 'active_record'

class SpaceHour < ActiveRecord::Base
	serialize :hours, Array
end