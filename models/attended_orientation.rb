require 'active_record'

class AttendedOrientation < ActiveRecord::Base

    def self.order_by_last_name
        order(Arel.sql("SUBSTRING_INDEX(name, ' ', -1)"))
    end

end