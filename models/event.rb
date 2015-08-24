require 'active_record'

class Event < ActiveRecord::Base
	has_many :event_signups, :dependent => :destroy
	belongs_to :location
	belongs_to :event_type
	alias_method :type, :event_type
	alias_method :signups, :event_signups

	scope :in_week, ->(time) {
		last_sunday = time.week_start
		next_sunday = (time + 1.week).week_start
		where('(start_time >= ? AND start_time < ?) OR (end_time >= ? AND end_time < ?)', last_sunday, next_sunday, last_sunday, next_sunday)
	}

	# returns length in minutes. If start or end is nil, returns 0
	def length
		if end_time.nil? || start_time.nil?
			return 0
		end
		((end_time - start_time) / 60).to_i
	end

	def info_link
		if type.description == 'New Member Orientation'
			return "/new_members/sign_up/#{id}/"
		end
		return '#'
	end
end