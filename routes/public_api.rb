require 'json'
require 'set'
require 'models/resource'
require 'models/reservation'
require 'models/lockout'
require 'models/event'
require 'models/service_space'
require 'models/tool'
require 'classes/intervals'
require 'classes/tool_schedule'
require 'classes/tool_utilization'
require 'classes/checkout_tool_utilization'

# Public, read-only JSON API for tool reservations and utilization
# (docs/public-api.md). No login is needed, so nothing here identifies people:
# reservations are anonymous time blocks and member activity only appears as
# counts. Everything is scoped to this deployment's service space (SS_ID).

API_LIST_DEFAULT_DAYS = 7
API_LIST_MAX_DAYS = 92
API_AVAILABILITY_MAX_DAYS = 31
API_UTILIZATION_DEFAULT_DAYS = 30
API_UTILIZATION_MAX_DAYS = 366

# Rack::Protection's JSON CSRF check refuses JSON to requests referred by
# another site without an Origin header (e.g. a link to the API). That guards
# private JSON; this API is public and read-only, so it is exempt.
set :protection, allow_if: ->(env) { env['PATH_INFO'].to_s.start_with?('/api/v1') }

before '/api/v1*' do
  content_type :json
  headers 'Access-Control-Allow-Origin' => '*'
end

# app.rb's not_found page would replace the JSON body of API 404s.
not_found do
  pass unless request.path_info.start_with?('/api/v1')
  response.body
end

helpers do
  def api_error(status, message)
    halt status, JSON.generate(error: message)
  end

  def api_date(name)
    value = params[name].to_s.strip
    return nil if value.empty?

    Date.strptime(value, '%Y-%m-%d')
  rescue ArgumentError
    api_error 400, "#{name} must be a date like 2026-01-31"
  end

  # [start_date, end_date] from ?start=&end= (inclusive). Missing values default
  # to `default_days` days starting at `default_start`, or counted from the
  # one that was given.
  def api_range(default_start, default_days, max_days)
    start_date = api_date(:start)
    end_date = api_date(:end)
    start_date ||= end_date.nil? ? default_start : end_date - (default_days - 1)
    end_date ||= start_date + (default_days - 1)
    api_error 400, 'end must not be before start' if end_date < start_date
    api_error 400, "the date range can be at most #{max_days} days" if (end_date - start_date).to_i + 1 > max_days
    [start_date, end_date]
  end

  def api_today
    Time.zone.today
  end

  def api_integer(name)
    value = params[name].to_s.strip
    return nil if value.empty?

    api_error 400, "#{name} must be a whole number" unless value =~ /\A\d+\z/
    value.to_i
  end

  def api_interval(default)
    interval = params[:interval].to_s.strip
    return default if interval.empty?

    api_error 400, "interval must be one of: #{ToolUtilization::INTERVALS.join(', ')}" unless ToolUtilization::INTERVALS.include?(interval)
    interval
  end

  # Tools of this service space, filtered by ?category= and ?reservable=.
  def api_tools
    tools = Resource.where(service_space_id: SS_ID).includes(resource_field_datas: :resource_field).order(:name, :id)
    category = api_integer(:category)
    tools = tools.where(category_id: category) unless category.nil?
    case params[:reservable]
    when nil, '' then tools
    when 'true' then tools.where(is_reservable: true)
    when 'false' then tools.where(is_reservable: [false, nil])
    else api_error 400, 'reservable must be true or false'
    end
  end

  def api_tool
    tool = Resource.where(service_space_id: SS_ID, id: params[:id].to_i).includes(resource_field_datas: :resource_field).first
    api_error 404, 'tool not found' if tool.nil?
    tool
  end

  def api_time(epoch_seconds)
    Time.at(epoch_seconds).in_time_zone.iso8601
  end

  def api_category(category_id)
    { id: category_id, name: (Resource.category_options || {})[category_id] || 'Other' }
  end

  def api_tool_summary(tool)
    { id: tool.id, name: tool.name.to_s.strip }
  end

  def api_locked_out_ids(tools)
    now = Time.now.utc
    Lockout.where(resource_id: tools.map(&:id))
           .where('started_on <= ? AND (released_on IS NULL OR released_on >= ?)', now, now)
           .pluck(:resource_id).to_set
  end

  def api_tool_status(tool, locked_out_ids)
    if tool.INOP then 'out_of_order'
    elsif locked_out_ids.include?(tool.id) then 'locked_out'
    else 'operational'
    end
  end

  def api_tool_json(tool, locked_out_ids)
    api_tool_summary(tool).merge(
      model: tool.get_field_data['model'].to_s.strip.then { |model| model.empty? ? nil : model },
      category: api_category(tool.category_id),
      description: tool.description.to_s.strip.then { |text| text.empty? ? nil : text },
      status: api_tool_status(tool, locked_out_ids),
      reservable: !!tool.is_reservable,
      requires_authorization: !!tool.needs_authorization,
      reservable_24_hours: ToolSchedule.twenty_four_hour?(tool),
      reservation_lengths_minutes: ToolSchedule.reservation_lengths(tool),
      max_upcoming_reservations_per_user: tool.user_reservation_limit
    )
  end

  # Reservations overlapping the dates, oldest first, without any user data.
  def api_reservations(tool_ids, start_date, end_date)
    from = ToolSchedule.midnight(start_date).utc
    to = ToolSchedule.midnight(end_date + 1).utc
    reservations = Reservation.where(resource_id: tool_ids).where('start_time < ? AND end_time > ?', to, from)
                              .includes(:event).order(:start_time, :id)
    reservations.map do |reservation|
      training = reservation.is_training || !reservation.event_id.nil?
      event = reservation.event
      {
        id: reservation.id,
        tool_id: reservation.resource_id,
        starts_at: api_time(reservation.start_time.to_i),
        ends_at: api_time(reservation.end_time.to_i),
        minutes: ((reservation.end_time - reservation.start_time) / 60).round,
        type: training ? 'training' : 'member',
        event: training && event && !event.is_private ? { id: event.id, title: event.title } : nil
      }
    end
  end

  def api_series_json(series)
    series.map { |first, last, stats| { start: first.iso8601, end: last.iso8601 }.merge(stats.to_h) }
  end

  def api_service_space
    space = ServiceSpace.find_by(id: SS_ID)
    { id: SS_ID, name: space && space.name }
  end
end

get '/api/v1/?' do
  JSON.generate(
    service_space: api_service_space,
    documentation: 'docs/public-api.md',
    endpoints: [
      'GET /api/v1/tools',
      'GET /api/v1/tools/:id',
      'GET /api/v1/tools/:id/reservations',
      'GET /api/v1/tools/:id/availability',
      'GET /api/v1/tools/:id/utilization',
      'GET /api/v1/reservations',
      'GET /api/v1/utilization',
      'GET /api/v1/checkout_tools',
      'GET /api/v1/checkout_tools/utilization'
    ]
  )
end

get '/api/v1/tools/?' do
  tools = api_tools.to_a
  locked_out = api_locked_out_ids(tools)
  JSON.generate(service_space: api_service_space, tools: tools.map { |tool| api_tool_json(tool, locked_out) })
end

get '/api/v1/tools/:id/?' do
  tool = api_tool
  now = Time.now.utc
  lockouts = Lockout.where(resource_id: tool.id).where('released_on IS NULL OR released_on > ?', now).order(:started_on)
  JSON.generate(
    tool: api_tool_json(tool, api_locked_out_ids([tool])).merge(
      lockouts: lockouts.map do |lockout|
        {
          starts_at: api_time(lockout.started_on.to_i),
          ends_at: lockout.released_on.nil? ? nil : api_time(lockout.released_on.to_i)
        }
      end
    )
  )
end

get '/api/v1/tools/:id/reservations/?' do
  tool = api_tool
  start_date, end_date = api_range(api_today, API_LIST_DEFAULT_DAYS, API_LIST_MAX_DAYS)
  JSON.generate(
    tool: api_tool_summary(tool),
    start: start_date.iso8601,
    end: end_date.iso8601,
    reservations: api_reservations([tool.id], start_date, end_date)
  )
end

get '/api/v1/reservations/?' do
  start_date, end_date = api_range(api_today, API_LIST_DEFAULT_DAYS, API_LIST_MAX_DAYS)
  tools = api_tools
  tool_id = api_integer(:tool_id)
  tools = tools.where(id: tool_id) unless tool_id.nil?
  JSON.generate(
    service_space: api_service_space,
    start: start_date.iso8601,
    end: end_date.iso8601,
    reservations: api_reservations(tools.ids, start_date, end_date)
  )
end

# Free time per day: open hours minus reservations and lockouts, keeping only
# gaps long enough for the tool's shortest reservation and not in the past.
get '/api/v1/tools/:id/availability/?' do
  tool = api_tool
  start_date, end_date = api_range(api_today, API_LIST_DEFAULT_DAYS, API_AVAILABILITY_MAX_DAYS)
  schedule = ToolSchedule.new(SS_ID)
  lengths = ToolSchedule.reservation_lengths(tool)
  shortest = lengths.min || tool.minutes_per_reservation || tool.min_minutes_per_reservation || 15
  bookable = !!tool.is_reservable && !tool.INOP && !lengths.empty?

  from = ToolSchedule.midnight(start_date).to_i
  to = ToolSchedule.midnight(end_date + 1).to_i
  booked = Reservation.where(resource_id: tool.id).where('start_time < ? AND end_time > ?', Time.at(to).utc, Time.at(from).utc)
                      .map { |reservation| [reservation.start_time.to_i, reservation.end_time.to_i] }
  locked = Lockout.where(resource_id: tool.id)
                  .where('started_on < ? AND (released_on IS NULL OR released_on > ?)', Time.at(to).utc, Time.at(from).utc)
                  .map { |lockout| [lockout.started_on.to_i, lockout.released_on.nil? ? Float::INFINITY : lockout.released_on.to_i] }
  now = Time.now.to_i
  twenty_four_hour = ToolSchedule.twenty_four_hour?(tool)

  days = (start_date..end_date).map do |date|
    open = schedule.open_intervals(date, twenty_four_hour)
    free = bookable ? Intervals.subtract(open, booked + locked) : []
    free = Intervals.clip(free, now, Float::INFINITY).select { |s, e| e - s >= shortest * 60 }
    {
      date: date.iso8601,
      open: open.map { |s, e| { starts_at: api_time(s), ends_at: api_time(e) } },
      free: free.map { |s, e| { starts_at: api_time(s), ends_at: api_time(e), minutes: (e - s) / 60 } }
    }
  end

  JSON.generate(
    tool: api_tool_summary(tool),
    bookable: bookable,
    reservation_lengths_minutes: lengths,
    days: days
  )
end

# Utilization of every reservable tool (filter with ?category= or ?tool_id=).
# Defaults to the last 30 full days; ?interval=day|week|month adds a series of
# the totals.
get '/api/v1/utilization/?' do
  start_date, end_date = api_range(api_today - API_UTILIZATION_DEFAULT_DAYS, API_UTILIZATION_DEFAULT_DAYS, API_UTILIZATION_MAX_DAYS)
  interval = api_interval(nil)
  tools = api_tools.where(is_reservable: true)
  tool_id = api_integer(:tool_id)
  tools = tools.where(id: tool_id) unless tool_id.nil?
  tools = tools.to_a
  locked_out = api_locked_out_ids(tools)
  utilization = ToolUtilization.new(tools, start_date, end_date, ToolSchedule.new(SS_ID))

  result = {
    service_space: api_service_space,
    start: start_date.iso8601,
    end: end_date.iso8601,
    totals: utilization.totals.to_h,
    categories: tools.group_by(&:category_id).sort_by { |category_id, _| category_id.to_i }.map do |category_id, category_tools|
      api_category(category_id).merge(tools: category_tools.size).merge(utilization.totals(category_tools).to_h)
    end,
    tools: tools.map do |tool|
      api_tool_summary(tool).merge(category_id: tool.category_id, status: api_tool_status(tool, locked_out))
                            .merge(utilization.summary(tool).to_h)
    end
  }
  result[:series] = api_series_json(utilization.series(tools, interval)) unless interval.nil?
  JSON.generate(result)
end

get '/api/v1/tools/:id/utilization/?' do
  tool = api_tool
  start_date, end_date = api_range(api_today - API_UTILIZATION_DEFAULT_DAYS, API_UTILIZATION_DEFAULT_DAYS, API_UTILIZATION_MAX_DAYS)
  interval = api_interval('day')
  utilization = ToolUtilization.new([tool], start_date, end_date, ToolSchedule.new(SS_ID))
  JSON.generate(
    tool: api_tool_summary(tool),
    start: start_date.iso8601,
    end: end_date.iso8601,
    interval: interval,
    summary: utilization.summary(tool).to_h,
    series: api_series_json(utilization.series([tool], interval))
  )
end

# Checkout-desk tools (used by the Engineering Design Hub).
get '/api/v1/checkout_tools/?' do
  tools = Tool.where(service_space_id: SS_ID).order(:tool_name, :id)
  JSON.generate(
    service_space: api_service_space,
    checkout_tools: tools.map do |tool|
      checked_out = !tool.last_checked_out.nil? && (tool.last_checked_in.nil? || tool.last_checked_out > tool.last_checked_in)
      status = if tool.INOP then 'out_of_order'
               elsif checked_out then 'checked_out'
               else 'available'
               end
      {
        id: tool.id,
        name: tool.tool_name,
        model: tool.model_number,
        category: api_category(tool.category_id),
        description: tool.description,
        status: status,
        checked_out_since: status == 'checked_out' ? api_time(tool.last_checked_out.to_i) : nil
      }
    end
  )
end

get '/api/v1/checkout_tools/utilization/?' do
  start_date, end_date = api_range(api_today - API_UTILIZATION_DEFAULT_DAYS, API_UTILIZATION_DEFAULT_DAYS, API_UTILIZATION_MAX_DAYS)
  tools = Tool.where(service_space_id: SS_ID).order(:tool_name, :id).to_a
  utilization = CheckoutToolUtilization.new(tools, start_date, end_date, ToolSchedule.new(SS_ID))
  JSON.generate(
    service_space: api_service_space,
    start: start_date.iso8601,
    end: end_date.iso8601,
    totals: utilization.totals(tools),
    checkout_tools: tools.map { |tool| { id: tool.id, name: tool.tool_name }.merge(utilization.report(tool)) }
  )
end

options '/api/v1/*' do
  headers 'Access-Control-Allow-Methods' => 'GET, OPTIONS', 'Access-Control-Allow-Headers' => 'Content-Type'
  204
end

get '/api/v1/*' do
  api_error 404, 'no such endpoint; see GET /api/v1'
end
