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

CONFIG = config