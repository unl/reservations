require 'active_record'

class Reservation < ActiveRecord::Base
	belongs_to :resource
	belongs_to :event
	belongs_to :user

	MAX_MINUTES_PER_RESERVATION_LIMIT = 1440

	scope :in_day, ->(time) {
		day_start = time.in_time_zone.beginning_of_day
		day_end = day_start + 1.day

		# Any reservation that overlaps with [day_start, day_end)
		where('start_time < ? AND end_time > ?', day_end.utc, day_start.utc)
	}

	# returns length in minutes. If start or end is nil, returns 0
	def length
		if end_time.nil? || start_time.nil?
			return 0
		end
		((end_time - start_time) / 60).to_i
	end
end