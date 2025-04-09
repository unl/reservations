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
			# Get all reservations within the specified time frame
			reservations = Reservation.where('resource_id = ? AND start_time >= ? AND start_time < ?', resource.id, start_date, end_date)
		else
			# Get all reservations from now until the scheduled end of the lockout
			if self.started_on < Time.now.in_time_zone
				# Scheduled lockouts that are currently active only notify future users
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
		affected_emails = User.where(id: affected_users)

		return affected_emails
	end

	def resource_name
		Resource.find(self.resource_id).name
	end

	def initiated_by
		User.find(self.initiated_by_user_id)
	end

	def released_by
		if self.released_by_user_id.nil?
			return nil
		end
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

	# email on creation of a lockout
	def email_lockout_affected_users(start_date, end_date, notify_admins = true)

		users = self.get_affected_users(start_date, end_date, notify_admins)

		
		users.each do |user|
			if user.email && !user.email.empty?
				subject = "#{self.resource_name} Temporarily Out of Service"
				body = "<p>Hi #{user.username},\nYou have a machine reservation that's been impacted by a Lockout/Tagout (LOTO). #{self.resource_name} has been locked out and is currently unavailable for use. The reason for the LOTO is:\n\n#{self.description}\n\nYour reservation has not been deleted in the event we are able to resolve the situation before then. Note that new reservations may not be created for this machine while it's locked out.\n\nWe'll keep you updated as we learn more and will notify you when the equipment is back online.</p>"

				Emailer.mail(user.email, subject, body, '', nil)
			end
		end
	end

	def email_edit_lockout_affected_users(start_date, end_date, notify_admins = true)
		users = self.get_affected_users(start_date, end_date, notify_admins)

		users.each do |user|
			if user.email && !user.email.empty?
				subject = "#{self.resource_name} Lockout Update"
				body = "<p>Hi #{user.username},\nThe expected resolution date for the #{self.resource_name} Lockout/Tagout (LOTO) has been updated to #{self.released_on.in_time_zone.strftime('%m/%d/%Y %I:%M %p')}. We appreciate your patience and will notify you of any further changes.</p>"

				Emailer.mail(user.email, subject, body, '', nil)
			end
		end
	end

	# email on release of a lockout
	def email_release_affected_users(notify_admins = true)
		users = self.get_affected_users(Time.now.in_time_zone, Time.now.in_time_zone.midnight + 2.day, notify_admins)

		users.each do |user|
			if user.email && !user.email.empty?
				subject = "#{self.resource_name} Now Available"
				body = "<p>Hi #{user.username},\nThe Lockout/Tagout on the #{self.resource_name} has been resolved, and the equipment is now available for use. Thank you for your patience during the downtime."

				Emailer.mail(user.email, subject, body, '', nil)
			end
		end
	end
end