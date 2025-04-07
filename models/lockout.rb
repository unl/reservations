require 'active_record'
require 'models/permission'

class Lockout < ActiveRecord::Base
	
	# Returns all the users affected by a lockout
	def get_affected_users(start_date, end_date, notify_admins)
		
		# All users with the MANAGE_LOCKOUT permission
		if notify_admins
			affected_users = UserHasPermission.where(permission_id: Permission::MANAGE_LOCKOUT).pluck(:user_id)
		else
			affected_users = []
		end
		resource = Resource.find(self.resource_id)

		# Default to the start of the lockout until midnight the next day
		if start_date.nil? || end_date.nil?
			start_date = self.started_on
			end_date = Time.now.in_time_zone.midnight + 1.day
		end

		if self.released_on.nil?
			# Get all reservations within the time frame
			reservations = Reservation.where('resource_id = ? AND start_time >= ? AND start_time < ?', resource.id, start_date, end_date)
		else
			# Get all reservations from now until the end of the lockout
			if self.started_on < Time.now.in_time_zone
				start_date = Time.now.in_time_zone
			else
				start_date = self.started_on
			end
			reservations = Reservation.where('resource_id = ? AND start_time >= ? AND start_time < ?', resource.id, start_date, self.released_on)
		end
		# Get all the users for each reservation
		reservations.each do |reservation|
			affected_users << reservation.user_id
		end
		# Get all the user emails for each reservation
		affected_users = affected_users.uniq
		affected_emails = User.where(id: affected_users).pluck(:email)

		return affected_emails
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
	end

	def release(params)
		user = User.find(params[:user_id])
		
		self.released_on = Time.now
		self.released_by_user_id = user.id
		self.save
	end

	# creation of a lockout
	def email_lockout_affected_users(start_date, end_date, notify_admins = true)

		users = self.get_affected_users(start_date, end_date, notify_admins)

		users.each do |user|
			if user && !user.empty?
				Emailer.mail(user, "Lockout Created", self.description, '', nil)
			end
		end
	end

	# release of a lockout
	def email_release_affected_users(notify_admins = true)
		users = self.get_affected_users(Time.now.in_time_zone, Time.now.in_time_zone.midnight + 2.day, notify_admins)

		users.each do |user|
			if user && !user.empty?
				Emailer.mail(user, "Lockout Released", self.description, '', nil)
			end
		end
	end
end