require 'active_record'
require 'models/resource'

class Tool < ActiveRecord::Base
	def get_category_name
		categories = Resource.category_options
		return categories.fetch(self.category_id, "Other")
	end

	def get_status
		if self.INOP
			return 'INOP'
		elif self.last_checked_in > self.last_checked_out
			return 'Available'
		elif self.last_checked_in.nil?
			return 'Available'
		else
			return 'Checked Out'
		end
	end

	def set_data(params)
		self.tool_name = params[:name]
		self.category_id = params[:category_id].to_i
		self.description = params[:description]
		self.service_space_id = SS_ID
		self.model_number = params[:model_number]
		self.serial_number = params[:serial_number]
		self.save
	end
end