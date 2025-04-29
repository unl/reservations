require 'bundler/setup'

require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'

require_relative '../utils/config_loader'
require 'utils/database'

require 'models/tool'
require 'models/tool_log'

userless_tools = Tool.where("current_user_id IS NULL AND last_checked_out > last_checked_in")

userless_tools.each do |tool|
  tool_checkouts = ToolLog.where(tool_id: tool.id, is_checking_in: 0)
  most_recent_checkout = tool_checkouts.max_by(&:checked_date)

  if most_recent_checkout
    tool.current_user_id = most_recent_checkout.checkout_user_id
    tool.save
    puts "Updated Tool ##{tool.id} with User ##{most_recent_checkout.checkout_user_id}"
  else
    puts "No valid checkouts found for Tool ##{tool.id}"
  end
end
