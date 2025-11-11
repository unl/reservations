require 'active_record'

class CheckIn < ActiveRecord::Base

    scope :in_day, ->(time) {
		day_start = time.in_time_zone.beginning_of_day
		day_end = day_start + 1.day
		where('datetime >= ? AND datetime < ?', day_start.utc, day_end.utc)
	}

end