require 'cuba'
require 'logger'
require 'mote'
require 'rest-more'
require 'time'
require 'yaml'

Log = Logger.new('debug.log')

IO.read('env.sh').scan(/(.*?)="?(.*)"?$/).each do |key, value|
  ENV[key] ||= value
end

Cuba.define do
  on 'facebook' do
    require_relative './facebook'
    run Facebook
  end
end
