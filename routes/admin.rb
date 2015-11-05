def calculate_time(date_string, hour, minute, am_pm)
	hour ||= 0
	minute ||= 0
	am_pm ||= 'am'

	hour = hour.to_i % 12
	hour = hour + 12 if am_pm == 'pm'

	date_strings = date_string.split('/')
	date_string = "#{date_strings[2]}-#{date_strings[0]}-#{date_strings[1]}"
	date = Time.parse(date_string)
	Time.new(date.year, date.month, date.day, hour, minute, 0)
end

before '/admin*' do
	raise Sinatra::NotFound unless !@user.nil? && @user.is_admin?
end

Dir.glob("#{ROOT}/routes/admin/*.rb") { |file| require file }