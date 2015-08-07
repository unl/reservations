require 'active_record'

class Resource < ActiveRecord::Base
	has_many :reservations
	has_many :resource_approvers
	alias_method :approvers, :resource_approvers
end