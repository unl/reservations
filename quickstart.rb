require 'rufus-scheduler'
# require 'rake'

scheduler = Rufus::Scheduler.new

scheduler.every '5s' do
    # require "./scripts/email_expiring_users"
    # rake task:email_expiring_users
    # ruby "./scripts/email_expiring_users"
    system("ruby scripts/email_expiring_users.rb")
    puts "Hello"
end

# scheduler.join