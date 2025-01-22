require 'bundler/setup'

require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require_relative '../utils/config_loader'

# set up the database connection
require 'utils/database'

# script-necessary things
require 'models/user'
require 'models/service_space'
require 'models/maker_request'
require 'models/permission'

SS_ID = ServiceSpace.where(:id => CONFIG['app']['service_space_id']).first.id
SITE_URL = CONFIG['app']['URL']

# Gets all maker requests expiring tomorrow
maker_requests_expiring_tomorrow = Maker_Request
    .where(status_id: Maker_Request::STATUS_OPEN)
    .where("created BETWEEN DATE_SUB(NOW(), INTERVAL #{Maker_Request::EXPIRATION_DAYS} DAY) AND DATE_SUB(NOW(), INTERVAL #{Maker_Request::EXPIRATION_DAYS - 1} DAY)")
    .order(created: :asc)
    .all

# Gets all the super and sub super users
super_permissions = [Permission::SUPER_USER, Permission::SUB_SUPER_USER]
super_users = User
    .joins(:permissions) # Join the permissions table through user_has_permissions
    .where(:service_space_id => SS_ID)
    .where(permissions: { id: super_permissions }) # Filter for the specific permissions
    .distinct

# If we have expiring maker requests
if maker_requests_expiring_tomorrow.count > 0

    # Build the body of the email
    body = '<p>The following Maker Request(s) expires tomorrow.</p><hr>'
    maker_requests_expiring_tomorrow.each do | single_request |
        body = body + "<p>Title: #{single_request.title} (<a href='#{SITE_URL + 'maker_request/' + single_request.uuid + '/manage/'}'>Manage</a>)</p>"
    end

    # Send email to all super users
    super_users.each do |user|
        if !user.email.empty?
            Emailer.mail(user.email, "Expiring Maker Requests", body, '', nil)
        end
    end
end