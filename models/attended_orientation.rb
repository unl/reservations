require 'active_record'

class AttendedOrientation < ActiveRecord::Base
    belongs_to :event

    def self.order_by_last_name
        order(Arel.sql("SUBSTRING_INDEX(name, ' ', -1)"))
    end

end