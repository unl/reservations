require 'active_record'

class Event < ActiveRecord::Base
	has_many :event_signups, :dependent => :destroy
	has_one :reservation, :dependent => :destroy
	belongs_to :location
	belongs_to :event_type
	alias_method :type, :event_type
	alias_method :signups, :event_signups

	scope :in_day, ->(time) {
		today = time.in_time_zone.midnight
		tomorrow = (time.in_time_zone.midnight + 1.day + 1.hour).in_time_zone.midnight
		where('(start_time >= ? AND start_time < ?) OR (end_time >= ? AND end_time < ?)', today.getutc, tomorrow.getutc, today.getutc, tomorrow.getutc)
	}

	scope :in_week, ->(time) {
		last_sunday = time.in_time_zone.week_start
		next_sunday = (time.in_time_zone.week_start + 1.week + 1.hour).in_time_zone.week_start
		where('(start_time >= ? AND start_time < ?) OR (end_time >= ? AND end_time < ?)', last_sunday.getutc, next_sunday.getutc, last_sunday.getutc, next_sunday.getutc)
	}

	# returns length in minutes. If start or end is nil, returns 0
	def length
		if end_time.nil? || start_time.nil?
			return 0
		end
		((end_time - start_time) / 60).to_i
	end

	def info_link
		case type.description
		when 'New Member Orientation'
			"/new_members/sign_up/#{id}/"
		else
			"/events/#{id}/"
		end
	end

	def edit_link
		"/admin/events/#{id}/edit/"
	end

	def has_reservation
		!self.reservation.nil?
	end
end