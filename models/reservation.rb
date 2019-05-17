require 'active_record'

class Reservation < ActiveRecord::Base
	belongs_to :resource
	belongs_to :event
	belongs_to :user

	MAX_MINUTES_PER_RESERVATION_LIMIT = 1440

	scope :in_day, ->(time) {
		today = time.in_time_zone.midnight
		tomorrow = (time.in_time_zone.midnight + 1.day + 1.hour).in_time_zone.midnight
		where('(start_time >= ? AND start_time < ?) OR (end_time >= ? AND end_time < ?)', today.getutc, tomorrow.getutc, today.getutc, tomorrow.getutc)
	}

	# returns length in minutes. If start or end is nil, returns 0
	def length
		if end_time.nil? || start_time.nil?
			return 0
		end
		((end_time - start_time) / 60).to_i
	end
end