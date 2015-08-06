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
  def capitalize_all
    self.split('_').map(&:capitalize).join(' ').split(' ').map(&:capitalize).join(' ')
  end

  def urlify
    self.downcase.split(' ').join('-')
  end

  alias_method :trim, :strip
  alias_method :trim!, :strip!
end

class Time
  def to_ct
    self.getlocal
  end

  def midnight
    Time.new(self.year, self.month, self.day)
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
end