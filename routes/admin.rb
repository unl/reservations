def calculate_time(date_string, hour, minute, am_pm)
	hour ||= 0
	minute ||= 0
	am_pm ||= 'am'

	hour = hour.to_i + 12 if am_pm == 'pm'

	date_strings = date_string.split('/')
	date_string = "#{date_strings[2]}-#{date_strings[0]}-#{date_strings[1]}"
	date = Time.parse(date_string)
	Time.new(date.year, date.month, date.day, hour, minute, 0)
end

def set_event_data(event, params)
	event.title = params[:title]
	event.description = params[:description]
	event.start_time = calculate_time(params[:start_date], params[:start_time_hour], params[:start_time_minute], params[:start_time_am_pm])
	event.end_time = calculate_time(params[:end_date], params[:end_time_hour], params[:end_time_minute], params[:end_time_am_pm])
	event.event_type_id = params[:type]
	event.location_id = params[:location]
	event.service_space_id = SS_ID

	event
end

before '/admin*' do
	raise Sinatra::NotFound unless !@user.nil? && @user.is_admin?
end

Dir.glob("#{ROOT}/routes/admin/*.rb") { |file| require file }