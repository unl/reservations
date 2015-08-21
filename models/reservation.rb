require 'active_record'

class Reservation < ActiveRecord::Base
	belongs_to :resource

	scope :in_day, ->(time) {
		today = time.midnight
		tomorrow = (time + 1.day).midnight
		where('(start_time >= ? AND start_time < ?) OR (end_time >= ? AND end_time < ?)', today, tomorrow, today, tomorrow)
	}
end