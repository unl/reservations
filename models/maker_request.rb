require 'active_record'

class Maker_Request < ActiveRecord::Base
    CATEGORY_OTHER = 1
    CATEGORY_WOODSHOP = 2
    CATEGORY_3D_PRINTER = 3
    CATEGORY_LASER = 4

    STATUS_OPEN = 1
    STATUS_CLOSED = 2

    EXPIRATION_DAYS = 30

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

    def self.category_options
        {
            CATEGORY_WOODSHOP => 'Woodshop',
            CATEGORY_3D_PRINTER => '3D Printer',
            CATEGORY_LASER => 'Laser',
            CATEGORY_OTHER => 'Other'
        }
    end

    def self.valid_category_id?(category_id)
        self.category_options.key?(category_id.to_i)
    end

    def self.status_options
        {
            STATUS_OPEN => 'Open',
            STATUS_CLOSED => 'Closed'
        }
    end

    def expired?
        self.created < Date.today - EXPIRATION_DAYS
    end

    def expires
        self.created.next_day(EXPIRATION_DAYS)
    end

    def form_validate(extras)
        errors = []
        compare_emails = true

        # validate name
    	if self.requestor_name.nil? || self.requestor_name.empty?
    		errors << {heading: 'Name', message: 'Please provide a name.'}
    	end

    	# validate email address
    	if self.requestor_email.nil? || self.requestor_email.empty?
    	    compare_emails = false
            errors << {heading: 'Email Address', message: 'Please provide an email address.'}
        elsif !(self.requestor_email.match(VALID_EMAIL_REGEX))
            compare_emails = false
            errors << {heading: 'Email Address', message: 'Please provide a vaild email address.'}
        end

    	# validate confirm email address
    	if extras[:confirm_email].nil? || extras[:confirm_email].empty?
    	    compare_emails = false
            errors << {heading: 'Confirm Email Address', message: 'Please provide a confirm email address.'}
        end

        if compare_emails && self.requestor_email != extras[:confirm_email]
            errors << {heading: 'Email Address', message: 'Email addresses provided do not match.'}
        end

        # validate title
    	if self.title.nil? || self.title.empty?
            errors << {heading: 'Title', message: 'Please provide a title.'}
    	end

    	# validate category id
    	if self.category_id.nil? || !self.class.valid_category_id?(self.category_id)
            errors << {heading: 'Category', message: 'Please select a category.'}
        end

    	# validate description
    	if self.description.nil? || self.description.empty?
            errors << {heading: 'Description', message: 'Please provide description.'}
        end

    	# validate category id
    	if extras[:confirm_read_disclaimer].nil? || extras[:confirm_read_disclaimer].to_i != 1
            errors << {heading: 'Disclaimer', message: 'Please accept disclaimer.'}
        end

    	errors
    end
end