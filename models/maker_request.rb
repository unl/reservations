require 'active_record'

class Maker_Request < ActiveRecord::Base
    CATEGORY_OTHER = 1
    CATEGORY_WOODSHOP = 2
    CATEGORY_3D_PRINTER = 3
    CATEGORY_LASER = 4

    STATUS_OPEN = 1
    STATUS_CLOSED = 2
    STATUS_CANCELED = 3

    def self.category_options
        {
            CATEGORY_WOODSHOP => 'Woodshop',
            CATEGORY_3D_PRINTER => '3D Printer',
            CATEGORY_LASER => 'Laser',
            CATEGORY_OTHER => 'Other'
        }
    end
end