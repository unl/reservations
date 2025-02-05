require 'active_record'

class Tool < ActiveRecord::Base
	def set_data(params)
		self.tool_name = params[:name]
		self.category_id = params[:category_id]
		self.description = params[:description]
		self.service_space_id = SS_ID
		self.model_number = params[:model_number]
		self.serial_number = params[:serial_number]
		self.save
	end
end