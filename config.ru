require './ccct'
require './model/comment'
require './model/comic'
require './helper/basic_auth'

set :environment, ENV['RACK_ENV'].to_sym
set :app_file,     'ccct.rb'
disable :run

run Sinatra::Application
