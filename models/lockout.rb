require 'active_record'

class Lockout < ActiveRecord::Base
	# Returns all the users affected by a lockout
	def affected_users
		affected_users = User.joins(:permissions).where(permissions: { name: 'MANAGE_CHECKOUT' }).pluck(:id)
		affected_users = 
		resource = Resource.find(self.resource_id)
		if self.released_on.nil?
			reservations = Reservation.where('resource_id = ? AND start_time >= ? AND start_time < ?', resource.id, self.started_on, Time.now.in_time_zone.midnight)
		else
			reservations = Reservation.where('resource_id = ? AND start_time >= ? AND start_time < ?', resource.id, self.started_on, self.released_on)
		end
		if self.released_on.nil?
			reservations = reservations + Reservation.where('resource_id = ? AND start_time >= ? AND start_time < ?', resource.id, Time.now.in_time_zone.midnight, (Time.now.in_time_zone.midnight + 1.day))
		end
		# Get all the users for each reservation
		reservations.each do |reservation|
			affected_users << reservation.user_id
		end
		return affected_users.uniq
	end

	def initiated_by
		User.find(self.initiated_by_user_id)
	end

	def released_by
		User.find(self.released_by_user_id)
	end

	scope :in_day, ->(time) {
		today = time.in_time_zone.midnight
		tomorrow = (time.in_time_zone.midnight + 1.day + 1.hour).in_time_zone.midnight
		where('(started_on >= ? AND started_on < ?) OR (released_on >= ? AND released_on < ?)', today.getutc, tomorrow.getutc, today.getutc, tomorrow.getutc)
	}

	def length
		if released_on.nil? || started_on.nil?
			return 0
		end
		((released_on - started_on) / 60).to_i
	end

	def set_data(params)
		resource = Resource.find(params[:resource_id])
		user = User.find(params[:user_id])

		if resource && user
			self.resource_id = resource.id
			self.initiated_by_user_id = user.id
			self.description = params[:description]

			# Defaults to now
			if params[:start_time]
				self.started_on = params[:start_time]
			else
				self.started_on = Time.now
			end

			# Defaults to nil (no end time)
			if params[:end_time]
				self.released_on = params[:end_time]
			else
				self.released_on = nil
			end

			self.save
		end
		puts "Affected users: #{self.affected_users}"
	end

	def release(params)
		user = User.find(params[:user_id])
		
		self.released_on = Time.now
		self.released_by_user_id = user.id
		self.save
	end
end