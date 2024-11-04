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
		"/admin/events/#{id}/edit/"
	end

	def set_data(params)
		self.title = params[:title]
		self.description = params[:description]
		self.admin_notes = params[:admin_notes]
		self.start_time = calculate_time(params[:start_date], params[:start_time_hour], params[:start_time_minute], params[:start_time_am_pm])
		self.end_time = calculate_time(params[:end_date], params[:end_time_hour], params[:end_time_minute], params[:end_time_am_pm])
		self.event_type_id = params[:type]
		self.trainer_id = params[:trainer]
		self.location_id = params[:location]
		self.max_signups = params[:limit_signups] == 'on' ? params[:max_signups].to_i : nil
		self.service_space_id = SS_ID
		if params[:is_private].nil?
			self.is_private = 0
		else
			self.is_private = params[:is_private]
		end
		if params[:hrc_feed].nil?
			self.hrc_feed = 0
		else
			self.hrc_feed = 1
		end
		if params[:hrc_parking].nil?
			self.hrc_parking = 0
		else
			self.hrc_parking = 1
		end
		self.event_code = params[:event_code]
		self.save
	end
end