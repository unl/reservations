require 'highlander'
require 'rufus-scheduler'

scheduler = Rufus::Scheduler::singleton

# scheduler.cron '0 12 * * *' do    # Every day at 12 pm
scheduler.every '5s' do
    system("ruby ././scripts/email_expiring_users.rb")
    puts "Hello"
end

while 1 do
end
