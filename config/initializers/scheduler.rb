require 'rufus-scheduler'

scheduler = Rufus::Scheduler::singleton

scheduler.every '5s' do
    puts "Hello"
end

while 1 do
end
