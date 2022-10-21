# set :output, "#{path}/cron.log"
set :environment, "development"

# require_relative '../utils/language'
# require_relative '../utils/config_loader'

# require './models/user'
# require './utils/database'

# users = User.where(:email => 'jjacobs10@huskers.unl.edu').all

# users.each do |user|
#     user.send_membership_expiring_email
# end

require './scripts/email_expiring_users.rb'

every 1.minutes do

    # require_relative '../utils/language'
    # require_relative '../utils/config_loader'

    # require './models/user'
    # require './utils/database'

    # command "ruby '#{path}/scripts/email_expiring_users.rb'"

    # rake ":apple"

    # command "rake apple"

    # command "ruby '/Users/joshuajacobs/Documents/GitHub/reservations/scripts/email_expiring_users.rb'"
    
    # runner "email_expiring_users.send_membership_expiring_email"

    # command "ruby './scripts/email_expiring_users.rb'"

    # users = User.where(:email => 'jjacobs10@huskers.unl.edu').all

	# users.each do |user|
	# 	user.send_membership_expiring_email
	# end

    require './scripts/email_expiring_users.rb'

end