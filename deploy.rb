# require "bundler/capistrano"
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"
# require 'config/schedule.rb'
set :environment, "development"

set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

pid_file = '/var/www/html/innovationstudio-manager.unl.edu/innovationstudio-manager.pid'

def get_exit
  $?.exitstatus
end

pid = (File.read pid_file).to_i

puts 'Starting new unicorn'
puts "Sending USR2 to #{pid}"
# send USR2 to master unicorn process; this will spawn a new unicorn master
Process.kill('USR2', pid)

puts 'Waiting for new unicorn to spawn'
sleep 3
new_pid = (File.read pid_file).to_i

puts 'Gracefully stopping old workers'
puts "Sending WINCH to #{pid}"
# send WINCH to old master process. this gracefully stops workers
Process.kill('WINCH', pid)

# decide if things are going well. 
puts 'Did it.'
puts 'Check on the website. Are new things enabled and everything looking good?'
puts '(Y) for yes, anything else for no'

response = STDIN.gets

if response.capitalize[0] == 'Y'
  # if so, send QUIT to old master. It shuts down, and finished.
  puts "Sending QUIT to old master at #{pid}"
  Process.kill('QUIT', pid)
  puts 'QUIT sent'
  puts 'We should be good! Nice job.'
  puts 'New code deployed'
else
  # if not, send HUP to old master to reload and restart workers.
  # then send QUIT to new master to stop it and workers.
  puts "Dang. Sending HUP to old master at #{pid} to restart workers."
  Process.kill('HUP', pid)
  puts "Sending QUIT to new master at #{new_pid} to shut that all down."
  Process.kill('QUIT', new_pid)
  puts 'job is done. Better luck next time!'
end
