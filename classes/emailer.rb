require 'pony'

class Emailer

  TYPE_GENERAL = 1
  TYPE_PROMOTIONAL = 2

  def self.type_options
      {
        TYPE_GENERAL => 'General',
        TYPE_PROMOTIONAL => 'Promotional',
      }
  end

  def type_name
    return self.class.type_options[type_id] if self.class.type_options.include?(type_id)
    'Other'
  end

  RECIPIENT_BYTE_LIMIT = 2048

  def self.mail(to, subject, body, bcc = "", attachments = nil)
    if (bcc.bytesize > RECIPIENT_BYTE_LIMIT)
      bcc_groups = self.breakup_recipient(bcc)
      bcc_groups.each do |bcc_group|
        Pony.mail({
          :to => to,
          :bcc => bcc_group,
          :subject => subject,
          :html_body => body,
          :from => CONFIG['app']['email_from'],
          :via => self.method,
          :via_options => self.method_options,
          :attachments => attachments
        })
      end
    else
      Pony.mail({
        :to => to,
        :bcc => bcc,
        :subject => subject,
        :html_body => body,
        :from => CONFIG['app']['email_from'],
        :via => self.method,
        :via_options => self.method_options,
        :attachments => attachments
      })
    end
  end

  def self.breakup_recipient(recipient)
    recipients = recipient.split(',').uniq
    recipient_groups = Array.new
    list = test_list = ''
    recipients.each do |r|
      test_list << "#{r.strip},"
      if test_list.bytesize > RECIPIENT_BYTE_LIMIT
        recipient_groups.push(list.chomp(','))
        list = test_list = ''
      else
        list = test_list
      end
    end
    recipient_groups.push(list.chomp(',')) unless list.empty?
    recipient_groups
  end

  private 

  def self.method
    if ENV['RACK_ENV'] == 'development'
      if CONFIG['email']['via'] == ":smtp"
        :smtp
      else
        :sendmail
      end
    else
      :sendmail
    end
  end

  def self.method_options
    if ENV['RACK_ENV'] == 'development' && !CONFIG['email']['via_address'].empty?
      {
        :address => CONFIG['email']['via_address'],
        :port => CONFIG['email']['via_port']
      }
    else
      {}
    end
  end
end
