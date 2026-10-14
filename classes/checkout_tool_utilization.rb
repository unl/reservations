require 'set'
require 'models/tool_log'
require 'classes/intervals'
require 'classes/tool_schedule'

# Usage of checkout-desk tools (the `tools` table, checked out and in at
# /checkout/) from tool_logs, over a range of local dates (both inclusive).
# A checkout lasts until the next check-in of the same tool; one never checked
# back in lasts until now. Per tool (and for all tools together):
#   checkouts                 checkouts that started in the range
#   checked_out_minutes       time checked out within the range
#   average_checkout_minutes  mean length of finished checkouts started in range
#   unique_borrowers          people with a checkout overlapping the range
#   open_minutes              the space's open hours in the range
#   utilization               share of open_minutes the tool was checked out
class CheckoutToolUtilization
  def initialize(tools, start_date, end_date, schedule, now = Time.now)
    @range = [ToolSchedule.midnight(start_date).to_i, ToolSchedule.midnight(end_date + 1).to_i]
    @now = now.to_i
    logs = ToolLog.where(tool_id: tools.map(&:id)).order(:checked_date, :id).to_a.group_by(&:tool_id)
    @sessions = tools.map { |tool| [tool.id, sessions(logs[tool.id] || [])] }.to_h
    @open = (start_date..end_date).flat_map { |date| schedule.open_intervals(date) }
  end

  def report(tool)
    summarize([raw(tool)])
  end

  def totals(tools)
    summarize(tools.map { |tool| raw(tool) })
  end

  private

  def raw(tool)
    sessions = @sessions[tool.id] || []
    overlapping = sessions.select { |session| session[:start] < @range[1] && (session[:end] || @now) > @range[0] }
    started = sessions.select { |session| session[:start] >= @range[0] && session[:start] < @range[1] }
    finished = started.reject { |session| session[:end].nil? }
    checked_out = Intervals.clip(overlapping.map { |session| [session[:start], session[:end] || @now] }, *@range)
    {
      checkouts: started.size,
      finished: finished.size,
      finished_seconds: finished.sum { |session| session[:end] - session[:start] },
      checked_out: Intervals.seconds(checked_out),
      checked_out_open: Intervals.seconds(Intervals.intersect(@open, checked_out)),
      borrowers: overlapping.map { |session| session[:user_id] }.compact.to_set
    }
  end

  def summarize(raws)
    open = Intervals.seconds(@open)
    finished = raws.sum { |r| r[:finished] }
    {
      checkouts: raws.sum { |r| r[:checkouts] },
      checked_out_minutes: minutes(raws.sum { |r| r[:checked_out] }),
      average_checkout_minutes: finished.zero? ? nil : minutes(raws.sum { |r| r[:finished_seconds] }.to_f / finished),
      unique_borrowers: raws.map { |r| r[:borrowers] }.reduce(Set.new, :|).size,
      open_minutes: minutes(open),
      utilization: open.zero? || raws.empty? ? nil : (raws.sum { |r| r[:checked_out_open] }.to_f / (open * raws.size)).round(4)
    }
  end

  def sessions(logs)
    result = []
    current = nil
    logs.each do |log|
      next if log.checked_date.nil?

      time = log.checked_date.to_i
      if log.is_checking_in
        next if current.nil?

        result << current.merge(end: time)
        current = nil
      else
        # A checkout with no check-in before the next checkout ends there.
        result << current.merge(end: time) unless current.nil?
        current = { start: time, end: nil, user_id: log.checkout_user_id }
      end
    end
    result << current unless current.nil?
    result
  end

  def minutes(seconds)
    (seconds / 60.0).round
  end
end
