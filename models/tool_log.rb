require 'active_record'

class ToolLog < ActiveRecord::Base

	def get_tools_by_user(user_id)
		user_logs = ToolLog.where(checkout_user_id: user_id)
		used_tools = Tool.where(id: user_logs.pluck(:tool_id), last_checked_out: user_logs.pluck(:checked_date))
	end

	def has_user_checked_out_tool(user_id, tool_id)
	
	end

	def set_data(params)
		self.checkout_user_id = params[:user].id
		self.tool_id = params[:tool].id
		self.tool_name = params[:tool].title
		self.checked_date = Time.now
		self.is_checking_in = params[:is_checking_in]
		self.save
	end
end