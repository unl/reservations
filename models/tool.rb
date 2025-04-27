require 'active_record'
require 'models/resource'

class Tool < ActiveRecord::Base

	def get_tool_user 
		if self.last_checked_out.nil?
			return nil
		elsif self.last_checked_in > self.last_checked_out
			return nil
		else
			return ToolLog.where(tool_id: self.id).order(created_at: :desc).first.user
		end
	end

	def get_category_name
		categories = Resource.category_options
		return categories.fetch(self.category_id, "Other")
	end

	def get_status
		if self.INOP
			return 'INOP'
		elsif self.last_checked_out.nil?
			return 'Available'
		elsif self.last_checked_in > self.last_checked_out
			return 'Available'
		else
			return 'Checked Out'
		end
	end

	def is_checked_out
		if self.last_checked_out.nil?
			return false
		elsif self.last_checked_out > self.last_checked_in
			return true
		else
			return false
		end
	end

	def update_last_checked_in()
		self.last_checked_in = Time.now
		self.save
	end

	def update_last_checked_out()
		self.last_checked_out = Time.now
		self.save
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