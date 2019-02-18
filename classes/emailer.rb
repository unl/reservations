require 'pony'

class Emailer
  def self.mail(to, subject, body, bcc = "", attachments = nil)
    Pony.mail({
      :to => to,
      :bcc => bcc,
      :subject => subject,
      :html_body => body,
      :from => 'innovationstudio@unl.edu',
      :via => self.method,
      :via_options => self.method_options,
      :attachments => attachments
    })
  end

  private 

  def self.method
    if ENV['RACK_ENV'] == 'development'
      :sendmail
#     :smtp
    else
      :sendmail
    end
  end

  def self.method_options
    if ENV['RACK_ENV'] == 'development'
      {
        :address => '127.0.0.1',
        :port => '1025'
      }
    else
      {}
    end
  end
end
