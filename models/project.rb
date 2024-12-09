require 'active_record'

class Project < ActiveRecord::Base
	# has_many :event_signups, :dependent => :destroy
	# has_many :reservation, :dependent => :destroy
	# has_many :event_authorizations, :dependent => :destroy
	# belongs_to :location
	# belongs_to :event_type
	# alias_method :type, :event_type
	# alias_method :signups, :event_signups

	def edit_link
		"/checkout/#{id}/edit/"
	end

	def set_data(params)
		self.owner_user_id = params[:user].id
		self.title = params[:title]
		self.description = params[:description]
		self.bin_id = params[:bin_id]
		self.last_checked_in = Time.now
		self.save
	end

	def update_last_checked_in()
		self.last_checked_in = Time.now
		self.save
	end

	def update_last_checked_out()
		self.last_checked_out = Time.now
		self.save
	end
end