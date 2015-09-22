require 'active_record'

class Reservation < ActiveRecord::Base
	belongs_to :resource
	belongs_to :user

	scope :in_day, ->(time) {
		today = time.midnight
		tomorrow = (time + 1.day).midnight
		where('(start_time >= ? AND start_time < ?) OR (end_time >= ? AND end_time < ?)', today, tomorrow, today, tomorrow)
	}

	# returns length in minutes. If start or end is nil, returns 0
	def length
		if end_time.nil? || start_time.nil?
			return 0
		end
		((end_time - start_time) / 60).to_i
	end
end