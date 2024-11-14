require 'active_record'

class Project < ActiveRecord::Base
	# has_many :event_signups, :dependent => :destroy
	# has_many :reservation, :dependent => :destroy
	# has_many :event_authorizations, :dependent => :destroy
	# belongs_to :location
	# belongs_to :event_type
	# alias_method :type, :event_type
	# alias_method :signups, :event_signups

	def edit_link
		"/checkout/#{id}/edit/"
	end

	def set_data(params)
		self.owner_user_id = params[:user].id
		self.title = params[:title]
		self.description = params[:description]
		self.bin_id = params[:bin_id]
=begin
		self.last_checked_in = calculate_time(params[:last_checked_in_date], params[:last_checked_in_hour], params[:last_checked_in_minute], params[:last_checked_in_time_am_pm])
		self.last_checked_out = calculate_time(params[:last_checked_out_date], params[:last_checked_out_hour], params[:last_checked_out_minute], params[:last_checked_out_time_am_pm])
=end
		self.save
	end

	def set_last_checked_in(params)
		self.last_checked_in = calculate_time(params[:last_checked_in_date], params[:last_checked_in_hour], params[:last_checked_in_minute], params[:last_checked_in_time_am_pm])
		self.updated_on = calculate_time(params[:last_checked_in_date], params[:last_checked_in_hour], params[:last_checked_in_minute], params[:last_checked_in_time_am_pm])
		self.save
	end

	def set_last_checked_out(params)
		self.last_checked_out = calculate_time(params[:last_checked_out_date], params[:last_checked_out_hour], params[:last_checked_out_minute], params[:last_checked_out_time_am_pm])
		self.updated_on = calculate_time(params[:last_checked_out_date], params[:last_checked_out_hour], params[:last_checked_out_minute], params[:last_checked_out_time_am_pm])
		self.save
	end
end