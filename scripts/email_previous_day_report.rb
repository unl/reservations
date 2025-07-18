require 'bundler/setup'

require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'

# Load config and database connection
require_relative '../utils/config_loader'
require 'utils/database'

# Load models
require 'models/user'
require 'models/service_space'
require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'
require 'models/lockout'
require 'models/touch_point_log'
require 'models/user_has_permission'

# Set service space ID
SS_ID = ServiceSpace.where(id: CONFIG['app']['service_space_id']).first.id

# =====================
# Data Queries
# =====================

# Newly Authorized Users (today)
users_authorized_today = User
  .joins("INNER JOIN attended_orientations ON attended_orientations.user_id = users.id")
  .where(users: { service_space_id: SS_ID })
  .where('date_attended >= ? AND date_attended < ?', Time.now - 1.days, Time.now)


# Lockouts
lockout_count = Lockout.where('released_on IS NOT NULL AND released_on < ?', Time.now).select(:resource_id).distinct.count
lockouts = Lockout.where('released_on IS NOT NULL AND released_on BETWEEN ? AND ?', Time.now, Time.now - 7.days).includes(:resource)

# Orientation Potentials
orientation_ids = Event.where(event_type_id: 12).pluck(:id)
orientation_signups = EventSignup.where(event_id: orientation_ids)
orientation_potentials = orientation_signups.where(attended: false).count

# Timeless Events
timeless_events = Event.where(start_time: nil, service_space_id: SS_ID)
  .where.not(event_type_id: 12)
  .map do |event|
    {
      title: event.title,
      potential_walkins: EventSignup.where(event_id: event.id, attended: false).count
    }
  end

# Upcoming Lockouts (next 7 days)
upcoming_lockouts = Lockout.where('started_on BETWEEN ? AND ?', Time.now, Time.now + 7.days).includes(:resource)

# Reservations
reservations = Reservation.joins(:resource)
  .where("resource.service_space_id" => SS_ID)
  .where('reservations.start_time >= ? AND reservations.end_time < ?', Time.now, Time.now + 7.days)

# Forecasting Logic (today + 6 more days = 7 days total)
forecasts_by_day = {}
changes_by_day = {}

(0..6).each do |i|
  forecast_day = Date.today + i
  day_name = forecast_day.strftime('%a')

  # Historical dates always relative to the forecasted day
  dates = [21, 14, 7].map { |days_ago| forecast_day - days_ago }

  touchdata = dates.map do |target_date|
    TouchPointLog
      .where("DATE(created_on) = ?", target_date)
      .order(:created_on)
      .first
  end.compact

  if touchdata.size == 3
    x_values = [3, 2, 1]
    y_values = touchdata.map(&:touch_point_count)

    x_mean = x_values.sum.to_f / x_values.size
    y_mean = y_values.sum.to_f / y_values.size

    numerator = x_values.zip(y_values).map { |x, y| (x - x_mean) * (y - y_mean) }.sum
    denominator = x_values.map { |x| (x - x_mean)**2 }.sum

    slope = numerator / denominator
    intercept = y_mean - slope * x_mean
    forecast = intercept.round

    forecasts_by_day[day_name] = forecast
    changes_by_day[day_name] = forecast - y_values.last
  else
    forecasts_by_day[day_name] = nil
    changes_by_day[day_name] = nil
  end
end

body = "<h1>Daily Status Report</h1>"

# Authorized Users
body << "<h2>Users Authorized Today</h2>"
if users_authorized_today.any?
  body << "<table><thead><tr><th>Name</th><th>Email</th><th>NUID</th></tr><thead><tbody>"
  users_authorized_today.map do |user|
    body << "<tr><td>#{user.first_name} #{user.last_name}</td><td>#{user.email}</td><td>#{user.user_nuid}</td></tr>"
  end.join
  body << "</tbody></table>"
else
  body << "<p>No users were authorized today.</p>"
end

# Potential Orientation
body << "<h2>Users Signed Up for Orientation (Not Yet Attended)</h2>"
body << "<p>#{orientation_potentials} user(s)</p>"

# Timeless Events
body << "<h2>Timeless Events (No Start Time)</h2>"
if timeless_events.any?
  body << "<table><thead><tr><th>Event</th><th>Potentials</th></tr></thead><tbody>"
  timeless_events.map do |event|
    body << "<tr><td>#{event[:title]}</td><td style='text-align:right;'>#{event[:potential_walkins]}</td><tr>"
  end.join
  body << "</tbody></table>"
else
  body << "<p>No timeless events found.</p>"
end

# Past Lockouts
body << "<h2>Past Lockouts (Previous 7 Days)</h2>"
if lockouts.any?
body << "<table><thead><tr><th>Resource Name</th><th>Released On</th></tr></thead><tbody>"
  lockouts.map do |lockout|
    body << "<tr><td>#{lockout.resource.name}</td><td>#{lockout.released_on.strftime('%Y-%m-%d')}</td></tr>"
  end.join
  body << "</tbody></table>"
else
  body << "<p>No past lockouts found.</p>"
end

# Upcoming Lockouts
body << "<h2>Upcoming Lockouts (Next 7 Days)</h2>"
if upcoming_lockouts.any?
  body << "<table><thead><tr><th>Resource Name</th><th>Starts On</th></tr></thead><tbody>"
  upcoming_lockouts.map do |lockout|
    body << "<tr><td>#{lockout.resource.name}</td><td>#{lockout.started_on.strftime('%Y-%m-%d')}</td></tr>"
  end.join
  body << "</tbody></table>"
else
  body << "<p>No upcoming lockouts scheduled.</p>"
end

# Reservations
body << "<h2>Active Reservations</h2>"
if reservations.any?
  body << "<table><thead><tr><th>Reservation ID</th><th>Start</th><th>End</th></tr></thead><tbody>"
  reservations.map do |res|
    body << "<tr><td>#{res.id}</td><td>#{res.start_time}</td><td>#{res.end_time}</td></tr>"
  end.join
  body << "</tbody></table>"
else
  body << "<p>No current reservations found.</p>"
end

# Forecasting Section
body << "<h2>Touchpoint Forecasts (Next 7 Days)</h2>"
body << "<ul>"
forecasts_by_day.each do |day, forecast|
  if forecast
    change = changes_by_day[day]
    change_text = change.positive? ? "(+#{change})" : "(#{change})"
    body << "<li><b>#{day}:</b> #{forecast} touchpoints #{change_text}</li>"
  else
    body << "<li><b>#{day}:</b> Insufficient data for forecast</li>"
  end
end
body << "</ul>"

body << "<p><small><i>This is an automated daily report.</i></small></p>"

# Get list of users with RECEIVE_PREVIOUS_DAY_REPORT permission
pdr_permission = Permission.find(Permission::RECEIVE_PREVIOUS_DAY_REPORT)
users_to_email = User.joins(:user_has_permissions).where(:service_space_id => SS_ID).where("user_has_permissions.permission_id = ?", pdr_permission).pluck(:email)

users_to_email.each do |user|
  Emailer.mail(user, "Daily Status Report", body, '', nil)  
end
