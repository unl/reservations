require 'active_record'

class Lockout < ActiveRecord::Base
	def set_data(params)
		resource = Resource.find(params[:resource_id])
		user = User.find(params[:user_id])

		if resource && user
			self.resource_id = resource.id
			self.initiated_by_user_id = user.id
			self.description = params[:description]

			if params[:start_date] && params[:start_time]
				self.started_on = DateTime.parse("#{params[:start_date]} #{params[:start_time]}")
			end
			if params[:end_date] && params[:end_time]
				self.released_on = DateTime.parse("#{params[:end_date]} #{params[:end_time]}")
			end
			self.save
		end
	end

	def update(params)
		self.description = params[:description]
		self.save
	end

	def release(params)
		self.released_on = Time.now
		self.save
	end
end