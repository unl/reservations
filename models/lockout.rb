require 'active_record'

class Lockout < ActiveRecord::Base
	def initiated_by
		User.find(self.initiated_by_user_id)
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

	def release()
		self.released_on = Time.now
		self.save
	end
end