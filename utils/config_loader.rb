ROOT = File.expand_path(File.dirname(__FILE__)) << '/..'
$LOAD_PATH.unshift(ROOT)

require 'json'

config = Hash.new

# read a base config file
config.merge!(JSON.parse(File.read("#{ROOT}/config/config.json")))

# read a server/env-specific config file if one exists
if File.exist?("#{ROOT}/config/server.json")
    config.merge!(JSON.parse(File.read("#{ROOT}/config/server.json")))    
end

if ENV['RACK_ENV'] == 'development'
    if !ENV['STRIPE_SECRET'] 
        ENV['STRIPE_SECRET'] = config['stripe_test_secret']
    end
    if !ENV['STRIPE_KEY'] 
        ENV['STRIPE_KEY'] = config['stripe_test_key']
    end
elsif ENV['RACK_ENV'] == 'production'
    if !ENV['STRIPE_SECRET'] 
        ENV['STRIPE_SECRET'] = config['stripe_live_secret']
    end
    if !ENV['STRIPE_KEY'] 
        ENV['STRIPE_KEY'] = config['stripe_live_key']
    end
end

Stripe.api_key = ENV['STRIPE_SECRET']

ENV['AIRGRAM_KEY'] = config['airgram_key']
ENV['AIRGRAM_SECRET'] = config['airgram_secret']