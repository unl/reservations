require 'active_record'
require 'models/resource_approver'
require 'models/resource_authorization'
require 'models/resource_class'
require 'models/resource_field'
require 'models/resource_field_data'

class Resource < ActiveRecord::Base
	has_many :reservations, dependent: :destroy
	has_many :resource_approvers, dependent: :destroy
	has_many :resource_authorizations, dependent: :destroy
	belongs_to :resource_class
	has_many :resource_field_datas, dependent: :destroy
	alias_method :approvers, :resource_approvers

	def method_missing(meth_sym)
		# check if this symbol can be associated with a field for this class
		if !self.resource_class.nil? && (field = ResourceField.find_by(:resource_class_id => self.resource_class.id, :field_name => meth_sym.to_s.downcase))
			# use this field id to retrieve the data from the resoruce field data table
			data = ResourceFieldData.find_by(:resource_id => self.id, :resource_field_id => field.id)
			unless data.nil?
				return data.data
			end	
		end
		super
	end

	def get_field_data
		{}.tap do |hash|
			self.resource_field_datas.each do |data|
				hash[data.resource_field.field_name.downcase] = data.data
			end
		end
	end

	def set_field_data(field_name, data)
		if !self.resource_class.nil? && (field = ResourceField.find_by(:resource_class_id => self.resource_class.id, :field_name => field_name.to_s.downcase))
			found_data = ResourceFieldData.find_by(:resource_id => self.id, :resource_field_id => field.id)
			if found_data.nil?
				ResourceFieldData.create(
					:resource_id => self.id,
					:resource_field_id => field.id,
					:data => data
				)
			else
				found_data.data = data
				found_data.save
			end
		end
	end
end