require './ccct'
#require 'comment'
#require 'comic'

set :environment, ENV['RACK_ENV'].to_sym
set :app_file,     'ccct.rb'
disable :run

run Sinatra::Application
