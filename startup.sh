#!/bin/bash

export GEM_PATH=/var/www/html/innovationstudio-manager.unl.edu/gems:$GEM_PATH
export PATH=/opt/unl.edu/ruby/current/bin:$PATH
cd /var/www/html/innovationstudio-manager.unl.edu
gems/bin/bundle exec unicorn -p 9393 -E production -D -c /var/www/html/innovationstudio-manager.unl.edu/unicorn.rb

