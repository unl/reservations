require 'set'
require 'models/reservation'
require 'models/lockout'
require 'classes/intervals'
require 'classes/tool_schedule'

# Reservation-based utilization of reservable tools over a range of local
# dates (both inclusive). Per tool and day:
#   open_minutes        time the tool could be reserved (ToolSchedule)
#   lockout_minutes     part of the open time the tool was locked out
#   reservable_minutes  open_minutes - lockout_minutes
#   reserved_minutes    member reservations, whole length
#   training_minutes    reservations held for training events
#   utilization         share of reservable_minutes covered by any reservation
# Reservation counts and members are attributed to the day a reservation starts.
class ToolUtilization
  INTERVALS = %w[day week month].freeze

  Stats = Struct.new(:open, :lockout, :reservable, :reserved, :training, :used,
                     :reservations, :reservation_length, :trainings, :members) do
    def self.empty
      new(0, 0, 0, 0, 0, 0, 0, 0, 0, Set.new)
    end

    def add(other)
      self.class.new(open + other.open, lockout + other.lockout, reservable + other.reservable,
                     reserved + other.reserved, training + other.training, used + other.used,
                     reservations + other.reservations, reservation_length + other.reservation_length,
                     trainings + other.trainings, members | other.members)
    end

    def to_h
      {
        open_minutes: minutes(open),
        lockout_minutes: minutes(lockout),
        reservable_minutes: minutes(reservable),
        reserved_minutes: minutes(reserved),
        training_minutes: minutes(training),
        utilization: reservable.zero? ? nil : (used.to_f / reservable).round(4),
        reservations: reservations,
        average_reservation_minutes: reservations.zero? ? nil : minutes(reservation_length.to_f / reservations),
        training_sessions: trainings,
        unique_members: members.size
      }
    end

    private

    def minutes(seconds)
      (seconds / 60.0).round
    end
  end

  def self.bucket_start(date, interval)
    case interval
    when 'week' then date - ((date.wday - 1) % 7) # weeks start on Monday
    when 'month' then Date.new(date.year, date.month, 1)
    else date
    end
  end

  attr_reader :start_date, :end_date

  def initialize(tools, start_date, end_date, schedule)
    @tools = tools
    @start_date = start_date
    @end_date = end_date
    @schedule = schedule
    @range = [ToolSchedule.midnight(start_date).to_i, ToolSchedule.midnight(end_date + 1).to_i]
    from = Time.at(@range[0]).utc
    to = Time.at(@range[1]).utc
    ids = tools.map(&:id)
    @reservations = Reservation.where(resource_id: ids).where('start_time < ? AND end_time > ?', to, from)
                               .to_a.group_by(&:resource_id)
    @lockouts = Lockout.where(resource_id: ids).where('started_on < ? AND (released_on IS NULL OR released_on > ?)', to, from)
                       .to_a.group_by(&:resource_id)
    @daily = {}
  end

  def summary(tool)
    daily(tool).values.reduce(Stats.empty, :add)
  end

  def totals(tools = @tools)
    tools.map { |tool| summary(tool) }.reduce(Stats.empty, :add)
  end

  # [[bucket_start, bucket_end, Stats], ...] for the tools combined.
  def series(tools, interval)
    buckets = Hash.new { |hash, key| hash[key] = Stats.empty }
    tools.each do |tool|
      daily(tool).each do |date, stats|
        key = ToolUtilization.bucket_start(date, interval)
        buckets[key] = buckets[key].add(stats)
      end
    end
    buckets.sort.map do |bucket, stats|
      bucket_end = case interval
                   when 'week' then bucket + 6
                   when 'month' then bucket.next_month - 1
                   else bucket
                   end
      [[bucket, @start_date].max, [bucket_end, @end_date].min, stats]
    end
  end

  private

  # { date => Stats } for every date in the range.
  def daily(tool)
    @daily[tool.id] ||= begin
      booked = Hash.new { |hash, key| hash[key] = [] }
      locked = Hash.new { |hash, key| hash[key] = [] }
      days = (@start_date..@end_date).map { |date| [date, Stats.empty] }.to_h

      (@reservations[tool.id] || []).each do |reservation|
        s = reservation.start_time.to_i
        e = reservation.end_time.to_i
        next if e <= s

        training = reservation.is_training || !reservation.event_id.nil?
        each_day_piece(s, e) do |date, piece|
          booked[date] << piece
          length = piece[1] - piece[0]
          if training
            days[date].training += length
          else
            days[date].reserved += length
          end
        end

        start = days[ToolSchedule.local_date(s)]
        next if start.nil? # started before the range

        if training
          start.trainings += 1
        else
          start.reservations += 1
          start.reservation_length += e - s
          start.members << reservation.user_id unless reservation.user_id.nil?
        end
      end

      (@lockouts[tool.id] || []).each do |lockout|
        released = lockout.released_on.nil? ? Float::INFINITY : lockout.released_on.to_i
        each_day_piece(lockout.started_on.to_i, released) { |date, piece| locked[date] << piece }
      end

      twenty_four_hour = ToolSchedule.twenty_four_hour?(tool)
      days.each do |date, stats|
        open = @schedule.open_intervals(date, twenty_four_hour)
        lockout = Intervals.intersect(open, locked[date])
        reservable = Intervals.subtract(open, lockout)
        stats.open = Intervals.seconds(open)
        stats.lockout = Intervals.seconds(lockout)
        stats.reservable = Intervals.seconds(reservable)
        stats.used = Intervals.seconds(Intervals.intersect(reservable, booked[date]))
      end
      days
    end
  end

  # Splits [s, e) (clipped to the range) at local midnights.
  def each_day_piece(s, e)
    s = [s, @range[0]].max
    e = [e, @range[1]].min
    return if e <= s

    date = ToolSchedule.local_date(s)
    loop do
      day_start, day_end = ToolSchedule.day_interval(date)
      break if day_start >= e

      piece = [[s, day_start].max, [e, day_end].min]
      yield date, piece if piece[0] < piece[1]
      date += 1
    end
  end
end
