class Integer
  def seconds
    self
  end

  def minutes
    seconds * 60
  end

  def hours
    minutes * 60
  end

  def days
    hours * 24
  end

  def weeks
    days * 7
  end

  def amount_display
    # assumes this amount is in cents
    "$#{self / 100.0}"
  end

  alias_method :second, :seconds
  alias_method :minute, :minutes
  alias_method :hour, :hours
  alias_method :day, :days
  alias_method :week, :weeks
end

class String
  alias_method :trim, :strip
  alias_method :trim!, :strip!

  def capitalize_all
    self.split('_').map(&:capitalize).join(' ').split(' ').map(&:capitalize).join(' ')
  end

  def self.token
    return (1..20).to_a.map{(Random.rand(26) + 65).chr}.join
  end
end

class Time
  def midnight
    Time.new(self.year, self.month, self.day)
  end

  def minutes_after_midnight
    ((self - self.midnight).to_f / 60).to_i
  end

  def week_start
    time = self
    until time.sunday?
      time = time - 1.day
    end
    time.midnight
  end

  def month_start
    Time.new(self.year, self.month, 1)
  end

  def self.from_minutes(minutes)
    Time.now.midnight + minutes.minutes
  end
end