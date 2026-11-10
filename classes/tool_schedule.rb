require 'models/space_hour'

# When tools can be reserved, following the reserve page (routes/tools.rb and
# views/reserve.erb):
#   * a day's reservable time is its "open" space-hours blocks; a one-off entry
#     for that date wins over the weekly entry for its weekday;
#   * with no hours defined for the day, or for 24-hour tools in the
#     Engineering Design Hub, the whole day is reservable.
# Times are [start, end) intervals in epoch seconds (see Intervals).
class ToolSchedule
  DESIGN_HUB_SERVICE_SPACE_ID = 8
  # Lengths the reserve form offers when a tool's time_slot_type is neither
  # "exact" nor "range".
  DEFAULT_LENGTHS = [15, 30, 45, 60, 90, 120].freeze

  def self.midnight(date)
    Time.zone.local(date.year, date.month, date.day)
  end

  def self.day_interval(date)
    [midnight(date).to_i, midnight(date + 1).to_i]
  end

  def self.local_date(epoch_seconds)
    Time.at(epoch_seconds).in_time_zone.to_date
  end

  # Reservation lengths (minutes) the reserve form offers for the tool.
  def self.reservation_lengths(tool)
    case tool.time_slot_type
    when 'exact'
      tool.minutes_per_reservation.to_i > 0 ? [tool.minutes_per_reservation.to_i] : []
    when 'range'
      min = tool.min_minutes_per_reservation
      max = tool.max_minutes_per_reservation
      step = tool.increment_minutes_per_reservation.to_i
      return [] if min.nil? || max.nil? || step <= 0

      (min..max).step(step).select(&:positive?)
    else
      DEFAULT_LENGTHS
    end
  end

  def self.twenty_four_hour?(tool)
    tool.is_24_hour && tool.service_space_id == DESIGN_HUB_SERVICE_SPACE_ID
  end

  def initialize(service_space_id)
    @space_hours = SpaceHour.where(service_space_id: service_space_id).order(:id).to_a
    @open = {}
  end

  # Reservable intervals on a local date.
  def open_intervals(date, twenty_four_hour = false)
    return [ToolSchedule.day_interval(date)] if twenty_four_hour

    @open[date] ||= begin
      space_hour = space_hour_for(date)
      if space_hour.nil?
        [ToolSchedule.day_interval(date)]
      else
        Array(space_hour.hours)
          .select { |record| value(record, :status) == 'open' }
          .map { |record| [at(date, value(record, :start)), at(date, value(record, :end))] }
      end
    end
  end

  private

  def space_hour_for(date)
    day_start = ToolSchedule.midnight(date).to_i
    one_off = @space_hours.find do |hours|
      hours.one_off && hours.day_of_week == date.wday && hours.effective_date.to_i == day_start
    end
    one_off || @space_hours
      .select { |hours| !hours.one_off && hours.day_of_week == date.wday && hours.effective_date && hours.effective_date.to_i <= day_start }
      .max_by { |hours| [hours.effective_date.to_i, hours.id] }
  end

  def at(date, minutes)
    return ToolSchedule.midnight(date + 1).to_i if minutes.to_i >= 24 * 60

    Time.zone.local(date.year, date.month, date.day, minutes.to_i / 60, minutes.to_i % 60).to_i
  end

  # Hours are stored as YAML with symbol keys; accept string keys too.
  def value(record, key)
    record[key] || record[key.to_s]
  end
end
