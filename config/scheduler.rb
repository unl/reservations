require 'rufus-scheduler'
require 'rubygems'
# require 'rake'

scheduler = Rufus::Scheduler.new
# s = Rufus::Scheduler.singleton

# scheduler.at '2030/12/12 23:30:00' do

# end

# job = scheduler.schedule_every '5s' do
scheduler.every '5s' do
# s.every '5s' do
    # require "./scripts/email_expiring_users"
    # rake task:email_expiring_users
    # ruby "./scripts/email_expiring_users"
    # system("ruby scripts/email_expiring_users.rb")
    puts "Hello"
    # job.unschedule
end

# scheduler.threads

# scheduler.job(job)

# job.call

sleep 5

# job.kill

# scheduler.join

# scheduler.stop