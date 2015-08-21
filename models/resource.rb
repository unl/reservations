require 'active_record'
require 'models/resource_approver'
require 'models/resource_authorization'

class Resource < ActiveRecord::Base
	has_many :reservations, dependent: :destroy
	has_many :resource_approvers, dependent: :destroy
	has_many :resource_authorizations, dependent: :destroy
	alias_method :approvers, :resource_approvers
end